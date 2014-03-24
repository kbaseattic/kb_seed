#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;
use gjoseqlib;

use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;
use Digest::MD5 'md5_hex';

use GenomeTypeObject;
use URI::Escape;
use Bio::FeatureIO;
use Bio::SeqIO;
use Bio::Seq;
use Bio::Location::Split;
use Bio::Location::Simple;
use Bio::SeqFeature::Generic;
use Bio::SeqFeature::Annotated;
use Getopt::Long;

my $help;
my $input_file;
my $output_file;
my $temp_dir;
my $id_prefix;
my $id_server;
my @feature_type;

my @formats = (gff => "GFF format",
	       protein_fasta => "Protein translations in fasta format",
	       contig_fasta => "Contig DNA in fasta format",
	       genbank => "Genbank format",
	       genbank_merged => "Genbank format as single merged locus, suitable for Artemis",
	       embl => "EMBL format");

my $rc = GetOptions('help'        => \$help,
		    'input=s'     => \$input_file,
		    'output=s'    => \$output_file,
		    'feature-type=s' => \@feature_type,
		    );

if (!$rc || $help || @ARGV != 1) {
    die "Bad ARGV";
}

my $feature_type_ok;
if (@feature_type)
{
    my $feature_type = { map { $_ => 1 } @feature_type };
    $feature_type_ok = sub {
	my($feat) = @_;
	return $feature_type->{$feat->{type}} ? 1 : 0;
    };
}
else
{
    $feature_type_ok = sub { 1 };
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
GenomeTypeObject->initialize($genomeTO);

#
# For each protein, if the function is blank, make it hypothetical protein.
for my $f (@{$genomeTO->{features}})
{
    next unless &$feature_type_ok($f);
    if (!defined($f->{function}) || $f->{function} eq '')
    {
	$f->{function} = "hypothetical protein";
    }
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
elsif ($format eq 'feature_data')
{
    export_feature_data($genomeTO, $out_fh);
    exit;
}
elsif ($format eq 'feature_dna')
{
    export_feature_dna($genomeTO, $out_fh);
    exit;
}

my $bio = {};
my $bio_list = [];

my $gs = $genomeTO->{scientific_name};
my $genome = $genomeTO->{id};

my $offset = 0;
my %contig_offset;

#
# code is similar but subtly different for the
# merged/non-merged cases.
#

if ($format eq 'genbank_merged')
{
    my $dna = '';

    my @feats;
    for my $c (@{$genomeTO->{contigs}})
    {
	my $contig = $c->{id};
	$dna .= $c->{dna};
	
	my $contig_start = $offset + 1;
	my $contig_end   = $offset + length($c->{dna});
	
	$contig_offset{$contig} = $offset;
	
	my $feature = Bio::SeqFeature::Generic->new(-start => $contig_start,
						    -end => $contig_end,
						    -tag => {
							organism => $gs,
							mol_type => "genomic DNA",
							note => $genome,
							note => $contig,
						    },
						    -primary => 'source');
	my $fa_record = Bio::SeqFeature::Generic->new(-start => $contig_start,
						      -end => $contig_end,
						      -tag => {
							  label => $contig,
							  note => $contig,
						      },
						      -primary => 'fasta_record');
	push(@feats, $feature, $fa_record);
	
	$offset += length($c->{dna});
    }
    my $bseq = Bio::Seq->new(-id => $genome, -seq => $dna);

    for my $c (@{$genomeTO->{contigs}})
    {
	my $contig = $c->{id};
	$bio->{$contig} = $bseq;
    }

    $bseq->add_SeqFeature($_) foreach @feats;
    @$bio_list = $bseq;
}
else
{
    for my $c (@{$genomeTO->{contigs}})
    {
	my $contig = $c->{id};
	$bio->{$contig} = Bio::Seq->new(-id => $contig,
					-seq => $c->{dna});
	$bio->{$contig}->desc("Contig $contig from $gs");
	push(@$bio_list, $bio->{$contig});
	
	my $contig_start = $offset + 1;
	my $contig_end   = $offset + length($c->{dna});
	
	$contig_offset{$contig} = $offset;
	
	my $feature = Bio::SeqFeature::Generic->new(-start => $contig_start,
						    -end => $contig_end,
						    -tag => {
							organism => $gs,
							mol_type => "genomic DNA",
							note => $genome,
						    },
						    -primary => 'source');
	$bio->{$contig}->add_SeqFeature($feature);
	
	my $fa_record = Bio::SeqFeature::Generic->new(-start => $contig_start,
						      -end => $contig_end,
						      -tag => {
							  label => $contig,
							  note => $contig,
						      },
						      -primary => 'fasta_record');
	$bio->{$contig}->add_SeqFeature($fa_record);
	
	if ($format eq 'genbank_merged')
	{
	    $offset += length($c->{dna});
	}
    }
}
#
# Reset format to genbank since we've computed offsets.
#
$format = 'genbank' if $format eq 'genbank_merged';

my %protein_type = (CDS => 1, peg => 1);
my $strip_ec;
my $gff_export = [];

for my $f (@{$genomeTO->{features}})
{
    next unless &$feature_type_ok($f);
    my $peg = $f->{id};
    my $note = {};
    my $contig;

    my $func = "";
    if (defined($f->{function}) && $f->{function} ne '')
    {
	$func = $f->{function};
    }
    elsif ($protein_type{$f->{type}})
    {
	$func = "hypothetical protein";
    }

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
	my $offset = $contig_offset{$contig};
	my $end = $strand eq '+' ? ($start + $len - 1) : ($start - $len + 1);

	my $bstrand = 0;
	if ($protein_type{$f->{type}})
	{
	    $bstrand = ($strand eq '+') ? 1 : -1;
	}

	$start += $offset;
	$end += $offset;
	my $sloc = new Bio::Location::Simple(-start => $start, -end => $end, -strand => $strand);
	push(@loc_obj, $sloc);

	#
	# Compute loc_info for GFF stuff.
	#
	my $frame = $start % 3;
	($start, $end) = ($end, $start) if $strand eq '-';
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
	} elsif ( $func =~ /(Ribosomal RNA|5S RNA|rRNA)/ ) {
	    $primary = 'rRNA';
	} else {
	    $primary = 'misc_RNA';
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
	}
	# work around to get annotations into gff
	for my $l (@loc_info)
	{
	    my($contig, $start, $stop, $strand, $frame) = @$l;
	    push @$gff_export, "$contig\t$source\t$primary\t$start\t$stop\t.\t$strand\t.\tID=$peg;Name=$func_ok\n";
	}
	
    } elsif ($type eq "crispr_repeat") {
	my $primary = "repeat_region";
	$feature = Bio::SeqFeature::Generic->new(-location => $loc,
						 -primary  => $primary,
						 -tag      => {
						     product => $func,
						 },
						 
						);
	$feature->add_tag_value("rpt_type", "direct");
	$func_ok =~ s/ #.+//;
	$func_ok =~ s/;/%3B/g;
	$func_ok =~ s/,/%2C/g;
	$func_ok =~ s/=//g;
	foreach my $tagtype (keys %$note) {
	    $feature->add_tag_value($tagtype, @{$note->{$tagtype}});
	}
	# work around to get annotations into gff
	for my $l (@loc_info)
	{
	    my($contig, $start, $stop, $strand, $frame) = @$l;
	    push @$gff_export, "$contig\t$source\t$primary\t$start\t$stop\t.\t$strand\t.\tID=$peg;Name=$func_ok\n";
	}
	
    } else {
	my $primary = "misc_feature";
	$feature = Bio::SeqFeature::Generic->new(-location => $loc,
						 -primary  => $primary,
						 -tag      => {
						     product => $func,
						     note => $type,
						 },
						 
						);
	$func_ok =~ s/ #.+//;
	$func_ok =~ s/;/%3B/g;
	$func_ok =~ s/,/%2C/g;
	$func_ok =~ s/=//g;
	foreach my $tagtype (keys %$note) {
	    $feature->add_tag_value($tagtype, @{$note->{$tagtype}});
	}
	# work around to get annotations into gff
	for my $l (@loc_info)
	{
	    my($contig, $start, $stop, $strand, $frame) = @$l;
	    push @$gff_export, "$contig\t$source\t$primary\t$start\t$stop\t.\t$strand\t.\tID=$peg;Name=$func_ok\n";
	}
	

    }
    
    my $bc = $bio->{$contig};
    if (ref($bc))
    {
	$bc->add_SeqFeature($feature) if $feature;
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

    foreach my $seq (@$bio_list)
    {
	$sio->write_seq($seq);
    }
}

sub export_protein_fasta
{
    my($genomeTO, $out_fh) = @_;

    for my $f (@{$genomeTO->{features}})
    {
	next unless &$feature_type_ok($f);
	my $peg = $f->{id};
	if ($f->{protein_translation})
	{
	    print_alignment_as_fasta($out_fh, [$peg, $f->{function}, $f->{protein_translation}]);
	}
    }
}

sub export_feature_dna
{
    my($genomeTO, $out_fh) = @_;

    for my $f (@{$genomeTO->{features}})
    {
	next unless &$feature_type_ok($f);
	my $id = $f->{id};
	print_alignment_as_fasta($out_fh, [$id, $f->{function}, $genomeTO->get_feature_dna($id)]);
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

sub export_feature_data
{
    my($genomeTO, $out_fh) = @_;
    
    my $features = $genomeTO->{features};
    foreach my $feature (@$features)
    {
	next unless &$feature_type_ok($feature);
	my $fid = $feature->{id};
	my $loc = join(",",map { my($contig,$beg,$strand,$len) = @$_; 
				 "$contig\_$beg$strand$len" 
			       } @{$feature->{location}});
	my $type = $feature->{type};
	my $func = $feature->{function};
	my $md5 = "";
	$md5 = md5_hex(uc($feature->{protein_translation})) if $feature->{protein_translation};
	my $aliases = ref($feature->{aliases}) ? join(",",@{$feature->{aliases}}) : "";

	print $out_fh join("\t", $fid,$loc,$type,$func,$aliases,$md5), "\n";
    }
}
