package StrepRepeats;

# This is a SAS component.

use strict;
use warnings;

use File::Temp qw/ :seekable /;
use Data::Dumper;
use Carp;

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::IDServer::Client;
use Bio::KBase::Utilities::ScriptThing;

use gjoseqlib;
use SeedUtils;

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Helper functions for the Strep repeats methods
#-----------------------------------------------------------------------
sub parse_repeat_output {
    my ($fh) = @_;
    
    my $line;
    my $block  = [];
    my $parsed = [];
    my $result = [];
    while (defined($line = <$fh>)) {
	if (@$block && ($line =~ m/^FT\s+repeat_unit\s+/o)) {
	    $parsed = &parse_strep_repeat_block($block);
	    if (keys %$parsed) {
		push @$result, $parsed;
	    }
	    @$block = ();
	}
	push @$block, $line;
    }
    
    #...Parse last block
    $parsed = &parse_strep_repeat_block($block);
    if (keys %$parsed) {
	push @$result, $parsed;
    }
    print STDERR "Returning from parse_repeat_output\n";
    return $result;
}

sub parse_strep_repeat_block {
    my ($block) = @_;
    
    if (@$block) {
	my $function = '';
	my $annotation = '';
	
	my $head  = shift @$block;
	my ($region_string) = ($head =~ m/^FT\s+repeat_unit\s+(\S.*\S)/o);
	
	my $loc = [];
	if ($region_string =~ m/order\(([^\)]+)\)/) {
	    $region_string = $1;
	    @$loc = map { [ $_->[0], q(+), (1 + $_->[1] - $_->[0]) ]
			  } map { ($_->[0] > $_->[1]) ? [ reverse @$_ ] : $_
				  } map { [ split(/\.\./, $_) ]
					  } split(/,\s*/o, $region_string);
	    print STDERR (q(order: ), &SeedUtils::flatten_dumper($loc), qq(\n));
	}
	elsif ($region_string =~ m/complement\(([^\)]+)\)/) {
	    $region_string = $1;
	    @$loc = map { [ $_->[0], q(-), (1 + $_->[0] - $_->[1]) ]
			  } map { ($_->[0] < $_->[1]) ? [ reverse @$_ ] : $_ 
				  } map { [ split(/\.\./, $_) ]
					  } reverse split(/,\s*/o, $region_string);
	    print STDERR (q(compl: ),  &SeedUtils::flatten_dumper($loc), qq(\n));
	}
	elsif ($region_string =~ m/^(\d+)\.\.(\d+)$/) {
	    @$loc = ([ $1, (($2 > $1) ? q(+) : q(-)), (1 + abs($2 - $1)) ]);
	    print STDERR (q(simpl: ), &SeedUtils::flatten_dumper($loc), qq(\n));
	}
	else {
	    print STDERR ("Could not parse location for following block:\n",
			  $head,
			  @$block,
			  "\n"
			  );
	    return {};
	}
	
	foreach my $line (@$block) {
	    chomp $line;
	    $line =~ s/\s+$//;
	    if ($line =~ m/^FT\s+\/label=(.*)$/) {
		warn "label=$1\n" if $ENV{DEBUG};
		$function = ($function eq '') ? $1 : $function."\; $1";
	    }
	    
	    if ($line =~ m/^FT\s+\/note=(.*)$/) {
		warn "note=$1\n" if $ENV{DEBUG};
		$annotation = ($annotation eq '') ? $1 : $annotation."\n$1";
	    }
	}
	
	return { location => $loc,
		 function => $function,
		 annotation => $annotation
		 };
    }
    
    return {};  #...Nothing to parse.
}

sub prepend_contig_id {
    my ($contig_id, $parsed_data) = @_;
    
    foreach my $entry (@$parsed_data) {
	foreach my $loc (@ { $entry->{location} }) {
	    unshift( @$loc, $contig_id);
	}
    }
}

sub get_strep_suis_repeats {
    my ($genomeTO) = @_;
    
    foreach my $contigO (@ { $genomeTO->{contigs} }) {
	use File::Temp qw/ :seekable /;
	my $tmp_contigO  = File::Temp->new(DIR => q(/tmp), TEMPLATE => q(tmp_contig_XXXXXX),  SUFFIX => q(.fna));
	my $tmp_contig_filename = $tmp_contigO->filename;
	$tmp_contigO->unlink_on_destroy(0);
	print STDERR "contig=$tmp_contig_filename\n";
	
#     	my $tmp_repeatsO = File::Temp->new(DIR => q(/tmp), TEMPLATE => q(tmp_repeats_XXXXXX), SUFFIX => q(.out));
# 	my $tmp_repeats_filename = $tmp_repeatsO->filename;
# 	$tmp_repeatsO->unlink_on_destroy(0);
#	print STDERR "contig=$tmp_contig_filename, repeats=$tmp_repeats_filename\n";
	
	SeedUtils::display_id_and_seq($contigO->{id}, \$contigO->{dna}, $tmp_contigO);
	
	my $repeats_fh;
	open($repeats_fh, "/kb/deployment/bin/suis_repeat_annotation $tmp_contig_filename |")
	    || die "Cannot pipe-out /kb/deployment/bin/suis_repeat_annotation: $!";
	
	my $parsed_results = &parse_repeat_output($repeats_fh);
	&prepend_contig_id( $contigO->{id}, $parsed_results);
	
	foreach my $entry (@$parsed_results) {
	    &add_feature($genomeTO,
			 'repeat_unit',
			 '/kb/deployment/bin/suis_repeat_annotation',
			 $entry->{location},
			 $entry->{function},
			 "Initial call by /kb/deployment/bin/suis_repeat_annotation\n"
			 . "Set function to " . $entry->{function} . "\n"
			 . $entry->{annotation}
			 );
	}
    }
    return $genomeTO;
}

sub get_raw_repeats
{
    my($genomeTO, $prog) = @_;

    my $out = [];
    for my $contig (@{$genomeTO->{contigs}})
    {
	my $tmp = File::Temp->new();
	print $tmp ">$contig->{id}\n$contig->{dna}\n";
	close($tmp);
	my $fh;
	open($fh, "-|", $prog, $tmp) or die "cannot run $prog $tmp: $!";
	my $parsed = parse_repeat_output($fh);
	for my $obj (@$parsed)
	{
	    for my $lchunk (@{$obj->{location}})
	    {
		unshift(@$lchunk, $contig->{id});
	    }

	    push(@$out, $obj);
	}
	close($fh);
    }
    return $out;
}

sub get_strep_pneumo_repeats {
    my ($genomeTO) = @_;
    
    foreach my $contigO (@ { $genomeTO->{contigs} }) {
	my $tmp_contigO  = File::Temp->new(DIR => q(/tmp), TEMPLATE => q(tmp_contig_XXXXXX),  SUFFIX => q(.fna));
	my $tmp_contig_filename = $tmp_contigO->filename;
	$tmp_contigO->unlink_on_destroy(0);
	print STDERR "contig=$tmp_contig_filename\n";
	
#     	my $tmp_repeatsO = File::Temp->new(DIR => q(/tmp), TEMPLATE => q(tmp_repeats_XXXXXX), SUFFIX => q(.out));
# 	my $tmp_repeats_filename = $tmp_repeatsO->filename;
# 	$tmp_repeatsO->unlink_on_destroy(0);
#	print STDERR "contig=$tmp_contig_filename, repeats=$tmp_repeats_filename\n";
	
	SeedUtils::display_id_and_seq($contigO->{id}, \$contigO->{dna}, $tmp_contigO);
	
	my $repeats_fh;
	open($repeats_fh, "/kb/deployment/bin/pneumococcal_repeat_annotation $tmp_contig_filename |")
	    || die "Cannot pipe-out /kb/deployment/bin/pneumococcal_repeat_annotation: $!";
	
	my $parsed_results = &parse_repeat_output($repeats_fh);
        &prepend_contig_id( $contigO->{id}, $parsed_results);
	
	foreach my $entry (@$parsed_results) {
	    &add_feature($genomeTO,
			 'repeat_unit',
			 '/kb/deployment/bin/pneumococcal_repeat_annotation',
			 $entry->{location},
			 $entry->{function},
			 "Initial call by /kb/deployment/bin/pneumococcal_repeat_annotation\n"
			 . "Set function to " . $entry->{function} . "\n"
			 . $entry->{annotation}
			 );
	}
    }
    return $genomeTO;
}

sub add_feature {
    my ($genomeTO, $type, $tool_string, $loc, $func, $annotation) = @_;
    
    if (not defined $genomeTO->{features}) {
	$genomeTO->{features} = [];
    }
    my $features = $genomeTO->{features};

    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');
    my $id_prefix = "$genomeTO->{id}.$type";
    my $next_id   = $id_server->allocate_id_range($id_prefix, 1);
    print STDERR "Allocated id for type  \'$type\' starting from $next_id\n";
    
    push @$features, { id   => "$id_prefix.$next_id",
		       type => $type,
		       location => $loc,
		       function => $func,
		       annotations => [[ $annotation, 
					 $tool_string,
					 time() 
					 ]]
		       };
    return;
}

sub add_annotation {
    my ($genomeTO, $annotation) = @_;
}
1;
