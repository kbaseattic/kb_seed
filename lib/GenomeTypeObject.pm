# -*- perl -*-

package GenomeTypeObject;

#
# This is a SAS component.
#

########################################################################
# Copyright (c) 2003-2013 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
########################################################################

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;
use File::Temp;
use File::Slurp;
use JSON::XS;
use gjoseqlib;
use Time::HiRes 'gettimeofday';


our $have_UUID;
our $have_Data_UUID;
eval {
    require UUID;
    $have_UUID = 1;
};
eval {
    require Data::UUID;
    $have_Data_UUID = 1;
};

# my new {
#     my ($class, $self) = @_;
#    
#     $self ||= {};
#    
#     return bless $self, $class;
# }

sub create_from_file
{
    my($class, $file) = @_;
    my $txt = read_file($file);
    my $self = decode_json($txt);
    return bless $self, $class;
}

sub initialize
{
    my($class, $self) = @_;

    bless $self, $class;

    $self->update_indexes();
}

sub prepare_for_return
{
    my($self) = @_;

    delete $self->{$_} foreach  grep { /^_/ } keys %$self;
}

sub update_indexes
{
    my($self) = @_;

    #
    # Create feature index.
    #

    my $feature_index = {};
    $self->{_feature_index} = $feature_index;
    for my $feature ($self->features)
    {
	$feature_index->{$feature->{id}} = $feature;
    }

    #
    # Create contig index.
    #
    my $contig_index = {};
    $self->{_contig_index} = $contig_index;
    for my $contig ($self->contigs)
    {
	$contig_index->{$contig->{id}} = $contig;
    }
    
    return $self;
}

sub features
{
    my($self) = @_;
    return @{$self->{features}};
}

sub contigs
{
    my($self) = @_;
    return @{$self->{contigs}};
}

sub add_feature {
    my ($self, $parms) = @_;
    my $genomeTO = $self;
    print STDERR (Dumper($parms), qq(\n\n)) if $ENV{DEBUG};
    
    my $id = $parms->{-id};
    my $id_client   = $parms->{-id_client};
    my $id_prefix   = $parms->{-id_prefix};
    my $type        = $parms->{-type}       or die "No feature-type -type";
    my $location    = $parms->{-location}   or die "No feature location -location";
    my $function    = $parms->{-function};
    my $annotator   = $parms->{-annotator}  || q(Nobody);
    my $annotation  = $parms->{-annotation} || q(Add feature);
    my $translation = $parms->{-protein_translation};
    my $event_id    = $parms->{-analysis_event_id};
    my $quality     = $parms->{-quality_measure};

    if (!defined($id))
    {
	if (!defined($id_client) || !defined($id_prefix))
	{
	    die "No id or id_client/id_prefix provided";
	}
	my $typed_prefix = "$id_prefix.$type";
	my $next_num     = $id_client->allocate_id_range($typed_prefix, 1);
	# print STDERR Dumper($typed_prefix, $next_num);
	
	if (defined($next_num)) {
	    print STDERR "Allocated id for typed-prefix \'$typed_prefix\' starting from $next_num\n" if $ENV{DEGUG};
	}
	else {
	    die "Could not get a new ID with typed-prefix \"$typed_prefix\"" unless $next_num;
	}
	$id = join(".", $typed_prefix, $next_num);
    }    
    
    if (not defined $genomeTO->{features}) {
	$genomeTO->{features} = [];
    }
    my $features  = $genomeTO->{features};
    
    my $feature =  { id   => $id,
		     type => $type,
		     location => $location,
		     annotations => [[ $annotation, 
				       $annotator,
				       time(),
				       ]],
    };

    $feature->{quality} = $quality if $quality;
    $feature->{feature_creation_event} = $event_id if $event_id;

    if ($function) {
	$feature->{function} = $function;
	push @ { $feature->{annotations} }, [ "Set function to $function",
					      $annotator,
					      time(),
	                                      ];
    }
    
    if ($translation) {
	$feature->{protein_translation} = $translation;
    }
    
    push @$features, $feature;
    
    return;
}

sub extract_protein_sequences_to_temp_file
{
    my($self) = @_;

    my($fh, $fn) = tmpnam();

    for my $feature (@{$self->{features}})
    {
	my $trans = $feature->{protein_translation};
	if ($trans)
	{
	    write_fasta($fh, [$feature->{id}, undef, $trans]);
	}
    }
    close($fh);
    return $fn;
}

sub extract_contig_sequences_to_temp_file
{
    my($self) = @_;

    my($fh, $fn) = tmpnam();

    for my $ctg (@{$self->{contigs}})
    {
	write_fasta($fh, [$ctg->{id}, undef, $ctg->{dna}]);
    }
    close($fh);
    return $fn;
}

sub write_temp_seed_dir
{
    my($genomeTO) = @_;

    my $tmp = File::Temp->newdir(undef, CLEANUP => 1);

    open(C, ">", "$tmp/contigs") or die "Cannot create $tmp/contigs: $!";
    for my $contig (@{$genomeTO->{contigs}})
    {
	print C ">$contig->{id}\n";
	print C "$contig->{dna}\n";
    }
    close(C);
    open(F, ">", "$tmp/assigned_functions") or die "Cannot create $tmp/assigned_functions: $!";
    mkdir("$tmp/Features");
    mkdir("$tmp/Features/peg");
    mkdir("$tmp/Features/CDS");
    mkdir("$tmp/Features/rna");
    open(PT, ">", "$tmp/Features/peg/tbl") or die "Cannot write $tmp/Features/peg/tbl: $!";
    open(CT, ">", "$tmp/Features/CDS/tbl") or die "Cannot write $tmp/Features/CDS/tbl: $!";
    open(RT, ">", "$tmp/Features/rna/tbl") or die "Cannot write $tmp/Features/rna/tbl: $!";
    open(PF, ">", "$tmp/Features/peg/fasta") or die "Cannot write $tmp/Features/peg/fasta: $!";
    open(CF, ">", "$tmp/Features/CDS/fasta") or die "Cannot write $tmp/Features/CDS/fasta: $!";
    #     "location" : [
    #        [
    #           "kb|g.140.c.0",
    #           "631472",
    #           "+",
    #           3216
    #        ]
    #     ],
    
    for my $feature (@{$genomeTO->{features}})
    {
	my $function = $feature->{function} || "hypothetical protein";
	print F "$feature->{id}\t$function\n";
	my $loc = $feature->{location};
	
	#
	# Fix this - we may have multipart locations.
	#
	my($ctg, $start, $strand, $len) = @{$loc->[0]};
	my $stop;
	if ($strand eq '+')
	{
	    $stop = $start + $len - 1;
	}
	else
	{
	    $stop = $start - $len + 1;
	}
	my $sloc = join("_", $ctg, $start, $stop);
	if ($feature->{type} eq 'CDS' || $feature->{type} eq 'peg')
	{
	    print CT join("\t", $feature->{id}, $sloc), "\n" if $feature->{type} eq 'CDS';
	    print PT join("\t", $feature->{id}, $sloc), "\n";
	    print CF ">$feature->{id}\n$feature->{protein_translation}\n" if $feature->{type} eq 'CDS';
	    print PF ">$feature->{id}\n$feature->{protein_translation}\n";
	}
	else
	{
	    print RT join("\t", $feature->{id}, $sloc), "\n";
	}
    }
    close(F);
    close(RT);
    close(PT);
    close(CT);
    close(PF);
    close(CF);
    return $tmp;
}

sub add_analysis_event
{
    my($self, $event) = @_;

    if (ref($event) ne 'HASH')
    {
	die "GenomeTypeObject::add_analysis_event: event must be a hash reference";
    }

    my $uuid_str = create_uuid();

    $event->{id} = $uuid_str;

    push(@{$self->{analysis_events}}, $event);
    return $uuid_str;
}

sub update_function
{
    my($self, $user, $fid, $function, $event_id) = @_;

    my $feature = $self->find_feature($fid);

    my $annotation = ["Function updated to $function", $user, scalar gettimeofday, $event_id];
    # print STDERR Dumper($fid, $feature, $annotation);
    
    push(@{$feature->{annotations}}, $annotation);
    $feature->{function} = $function;
}

sub find_feature
{
    my($self, $fid) = @_;

    return $self->{_feature_index}->{$fid};
}

sub find_contig
{
    my($self, $contig) = @_;

    return $self->{_contig_index}->{$contig};
}

sub get_feature_dna
{
    my($self, $feature) = @_;

    my @seq;

    if (!ref($feature))
    {
	$feature = $self->find_feature($feature);
    }

    foreach my $loc (@{$feature->{location}})
    {
	my($contig, $beg, $strand, $len) = @$loc;

	my $cobj = $self->find_contig($contig);
	
	if ($strand eq '+' || $len == 1)
	{
	    
	    push(@seq, substr($cobj->{dna}, $beg - 1, $len));
	}
	else
	{
	    push(@seq, &SeedUtils::reverse_comp(substr($cobj->{dna}, $beg - $len, $len)));
	}
    }
    return join("", @seq);

}

sub create_uuid
{
    if ($have_UUID)
    {
	my($uuid, $uuid_str);
	UUID::generate($uuid);
	UUID::unparse($uuid, $uuid_str);
	return $uuid_str;
    }
    elsif ($have_Data_UUID)
    {
	return Data::UUID->new->create_str();
    }
    else
    {
	die "No UUID generator found";
    }
}

    
1;
