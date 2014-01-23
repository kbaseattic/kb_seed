#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;
use gjoseqlib;

use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

use GenomeTypeObject;
use URI::Escape;
use Bio::FeatureIO;
use Bio::SeqIO;
use Bio::Seq;
use Bio::Location::Split;
use Bio::Location::Simple;
use Bio::SeqFeature::Generic;
use Bio::SeqFeature::Annotated;

my $help;
my $input_file;
my $output_file;
my $temp_dir;
my $id_prefix;
my $id_server;

use Getopt::Long;
my $rc = GetOptions('help'        => \$help,
		    'input=s'     => \$input_file,
		    'output=s'    => \$output_file,
		    );

if (!$rc || $help || @ARGV != 1) {
    die "Bad ARGV";
}

my $format = shift;

if (lc($format) eq 'gff')
{
    $format = 'GTF';
}

my $in_fh;
if ($input_file) {
    open($in_fh, "<", $input_file) or die "Cannot open $input_file: $!";
} else { $in_fh = \*STDIN; }

my $out_fh;
if ($output_file) {
    open($out_fh, ">", $output_file) or die "Cannot open $output_file: $!";
} else { $out_fh = \*STDOUT; }

my $json = JSON::XS->new;

my $genomeTO;
{
    local $/;
    undef $/;
    my $genomeTO_txt = <$in_fh>;
    $genomeTO = $json->decode($genomeTO_txt);
}

#
# Simple exports.
#

if ($format eq 'protein_fasta')
{
    export_protein_fasta($genomeTO, $out_fh);
    exit;
}
elsif ($format eq 'contig_fasta')
{
    export_contig_fasta($genomeTO, $out_fh);
    exit;
}

my $bio;

my $gs = $genomeTO->{scientific_name};
my $genome = $genomeTO->{id};

for my $c (@{$genomeTO->{contigs}})
{
    my $contig = $c->{id};
    $bio->{$contig} = Bio::Seq->new(-id => $contig,
				    -seq => $c->{dna});
    $bio->{$contig}->desc("Contig $contig from $gs");

    my $feature = Bio::SeqFeature::Generic->new(-start => 1,
						-end => length($c->{dna}),
						-tag => {
						    organism => $gs,
						    mol_type => "genomic DNA",
						    genome_id => $genome,
						},
						-primary => 'source');
    $bio->{$contig}->add_SeqFeature($feature);
}

my %protein_type = (CDS => 1, peg => 1);
my $strip_ec;
my $gff_export = [];

for my $f (@{$genomeTO->{features}})
{
    my $peg = $f->{id};
    my $note = {};
    my $contig;

    my $func = $f->{function} || "";

    push @{$note->{db_xref}}, "RAST2:$peg";

    my %ecs;
    if ($func)
    {
	foreach my $role (SeedUtils::roles_of_function($func))
	{
	    my ($ec) = ($role =~ /\(EC (\d+\.\d+\.\d+\.\d+)\)/);
	    $ecs{$ec} = 1 if ($ec);
	}
	
	# add ECs
	push @{$note->{"EC_number"}}, keys(%ecs);
    }

    my $loc;

    my @loc_obj;
    my @loc_info;
    for my $l (@{$f->{location}})
    {
	my($ctg, $start, $strand, $len) = @$l;
	$contig = $ctg;
	my $end = $strand eq '+' ? ($start + $len - 1) : ($start - $len + 1);

	my $bstrand = 0;
	if ($protein_type{$f->{type}})
	{
	    $bstrand = ($strand eq '+') ? 1 : -1;
	}
	my $sloc = new Bio::Location::Simple(-start => $start, -end => $end, -strand => $strand);
	push(@loc_obj, $sloc);

	#
	# Compute loc_info for GFF stuff.
	#
	my $frame = $start % 3;
	push(@loc_info, [$ctg, $start, $end, (($len == 0) ? "." : $strand), $frame]);
    }

    if (@loc_obj == 1)
    {
	$loc = $loc_obj[0];
    }
    elsif (@loc_obj > 1)
    {
	$loc = new Bio::Location::Split();
	$loc->add_sub_Location($_) foreach @loc_obj;
    }

    my $feature;
    my $source = "rast2_export";
    my $type = $f->{type};
	
    # strip EC from function
    my $func_ok = $func;
    
    if ($strip_ec) {
	$func_ok =~ s/\s+\(EC \d+\.(\d+|-)\.(\d+|-)\.(\d+|-)\)//g;
	$func_ok =~ s/\s+\(TC \d+\.(\d+|-)\.(\d+|-)\.(\d+|-)\)//g;
    }
    
    if ($protein_type{$f->{type}})
    {
	$feature = Bio::SeqFeature::Generic->new(-location => $loc,
						 -primary  => 'CDS',
						 -tag      => {
						     product     => $func_ok,
						     translation => $f->{protein_translation},
						 },
						);
	
	foreach my $tagtype (keys %$note) {
	    $feature->add_tag_value($tagtype, @{$note->{$tagtype}});
	}
	
	# work around to get annotations into gff
	# this is probably still wrong for split locations.
	$func_ok =~ s/ #.+//;
	$func_ok =~ s/;/%3B/g;
	$func_ok =~ s/,/%2C/g;
	$func_ok =~ s/=//g;
	for my $l (@loc_info)
	{
	    my $ec = "";
	    my @ecs = ($func =~ /[\(\[]*EC[\s:]?(\d+\.[\d-]+\.[\d-]+\.[\d-]+)[\)\]]*/ig);
	    if (scalar(@ecs)) {
		$ec = ";Ontology_term=".join(',', map { "KEGG_ENZYME:" . $_ } @ecs);
	    }
	    my($contig, $start, $stop, $strand, $frame) = @$l;
	    push @$gff_export, "$contig\t$source\tCDS\t$start\t$stop\t.\t$strand\t$frame\tID=".$peg.";Name=".$func_ok.$ec."\n";
	}
    } elsif ($type eq "rna") {
	my $primary;
	if ( $func =~ /tRNA/ ) {
	    $primary = 'tRNA';
	} elsif ( $func =~ /(Ribosomal RNA|5S RNA)/ ) {
	    $primary = 'rRNA';
	} else {
	    $primary = 'RNA';
	}
	
	$feature = Bio::SeqFeature::Generic->new(-location => $loc,
						 -primary  => $primary,
						 -tag      => {
						     product => $func,
						 },
						 
						);
	$func_ok =~ s/ #.+//;
	$func_ok =~ s/;/%3B/g;
	$func_ok =~ s/,/%2C/g;
	$func_ok =~ s/=//g;
	foreach my $tagtype (keys %$note) {
	    $feature->add_tag_value($tagtype, @{$note->{$tagtype}});
	    
	    # work around to get annotations into gff
	    for my $l (@loc_info)
	    {
		my($contig, $start, $stop, $strand, $frame) = @$l;
		push @$gff_export, "$contig\t$source\t$primary\t$start\t$stop\t.\t$strand\t.\tID=$peg;Name=$func_ok\n";
	    }
	}
	
    } else {
	print STDERR "unhandled feature type: $type\n";
    }
    
    my $bc = $bio->{$contig};
    if (ref($bc))
    {
	$bc->add_SeqFeature($feature);
    }
    else
    {
	print STDERR "No contig found for $contig on $feature\n";
    }
}

# check for FeatureIO or SeqIO
if ($format eq "GTF") {
    #my $fio = Bio::FeatureIO->new(-file => ">$filename", -format => "GTF");
    #foreach my $feature (@$bio2) {
    #$fio->write_feature($feature);
    #}
    print $out_fh "##gff-version 3\n";
    foreach (@$gff_export) {
	print $out_fh $_;
    }
    
} else {
#	my $sio = Bio::SeqIO->new(-file => ">$filename", -format => $format);

    #
    # bioperl writes lowercase dna. We want uppercase for biophython happiness.
    #
#    my $sio = Bio::SeqIO->new(-file => ">tmpout", -format => $format);
    my $sio = Bio::SeqIO->new(-fh => $out_fh, -format => $format);

    foreach my $seq (keys %$bio) {
	$sio->write_seq($bio->{$seq});
    }
}

sub export_protein_fasta
{
    my($genomeTO, $out_fh) = @_;

    for my $f (@{$genomeTO->{features}})
    {
	my $peg = $f->{id};
	if ($f->{protein_translation})
	{
	    print_alignment_as_fasta($out_fh, [$peg, $f->{function}, $f->{protein_translation}]);
	}
    }
}

sub export_contig_fasta
{
    my($genomeTO, $out_fh) = @_;

    for my $c (@{$genomeTO->{contigs}})
    {
	my $contig = $c->{id};
	print_alignment_as_fasta($out_fh, [$contig, undef, $c->{dna}]);
    }
}

