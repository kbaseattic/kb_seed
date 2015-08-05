#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use File::Copy;
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
use Getopt::Long::Descriptive;
use Spreadsheet::Write;
use File::Temp;

my $temp_dir;
my @feature_type;

#
# Master list of supported formats. When changes happen here please propagate them to
# the rast2-export-genome script and to the documentation in the API spec.
#   

my @formats = ([genbank => "Genbank format"],
	       [genbank_merged => "Genbank format as single merged locus, suitable for Artemis"],
	       [spreadsheet_txt => "Spreadsheet (tab-separated text format)"],
	       [spreadsheet_xls => "Spreadsheet (Excel XLS format)"],
	       [feature_data => "Tabular form of feature data"],
	       [protein_fasta => "Protein translations in fasta format"],
	       [contig_fasta => "Contig DNA in fasta format"],
	       [feature_dna => "Feature DNA sequences in fasta format"],
	       [seed_dir => "SEED directory"],
	       [gff => "GFF format"],
	       [embl => "EMBL format"]);

my($opt, $usage) = describe_options("%c %o format",
				    ["feature-type=s@", 'Select a feature type to dump'],
				    ["input|i=s", "Input file"],
				    ["output|o=s", "Output file"],
				    ["with-headings", "For downloads with optional headings (feature_data) include headings"],
				    ["help|h", "Show this help message"],
				    [],
				    ["Supported formats:\n"],
				    map { [ "$_->[0]  : $_->[1]" ] } @formats,
				   );

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if @ARGV != 1;

my $feature_type_ok;
if (ref($opt->feature_type))
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
if ($opt->input) {
    open($in_fh, "<", $opt->input) or die "Cannot open " . $opt->input . ": $!";
} else { $in_fh = \*STDIN; }

my $out_fh;
if ($opt->output) {
    open($out_fh, ">", $opt->output) or die "Cannot open " . $opt->output . ": $!";
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
    export_feature_data($genomeTO, $opt->with_headings, $out_fh);
    exit;
}
elsif ($format =~ /spreadsheet_(xls|txt)/)
{
    export_spreadsheet($genomeTO, $1, $out_fh);
    exit;
}
elsif ($format eq 'seed_dir')
{
    export_seed_dir($genomeTO, $out_fh);
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

    my($creation_event, $annotation_event, $annotation_tool) = $genomeTO->get_creation_info($f);

    $annotation_tool ||= $annotation_event->{tool_name};
    push(@{$note->{note}}, "rasttk_feature_creation_tool=$creation_event->{tool_name}") if $creation_event;
    push(@{$note->{note}}, "rasttk_feature_annotation_tool=$annotation_tool") if $annotation_tool;

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

	($start, $end) = ($end, $start) if $strand eq '-';

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
	
    } elsif ($type eq "crispr_repeat" || $type eq 'repeat') {
	my $primary = "repeat_region";
	$feature = Bio::SeqFeature::Generic->new(-location => $loc,
						 -primary  => $primary,
						 -tag      => {
						     product => $func,
						 },
						 
						);
	$feature->add_tag_value("rpt_type",
				($type eq 'crispr_repeat' ? "direct" : "other"));
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
	    print_alignment_as_fasta($out_fh, [$peg,
					       "$f->{function} [$genomeTO->{scientific_name} | $genomeTO->{id}]",
					       $f->{protein_translation}]);
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
	print_alignment_as_fasta($out_fh, [$id,
					   "$f->{function} [$genomeTO->{scientific_name} | $genomeTO->{id}]",
					   $genomeTO->get_feature_dna($id)]);
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
    my($genomeTO, $with_headings, $out_fh) = @_;

    if ($with_headings)
    {
	print $out_fh join("\t", qw(feature_id location type function aliases protein_md5)), "\n";
    }

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

sub export_seed_dir
{
    my($genomeTO, $out_fh) = @_;

    my $td = File::Temp::tempdir(CLEANUP => 1);
    my $dir = "$td/$genomeTO->{id}";
    mkdir($dir) or die "Cannot mkdir $dir: $@";
    $genomeTO->write_seed_dir($dir);

    my $fh;
    open($fh, "cd $td; tar czf - '$genomeTO->{id}' |") or die "cannot open tar: $!";
    copy($fh, $out_fh);
    close($fh);
}

sub export_spreadsheet
{
    my($genomeTO, $suffix, $out_fh) = @_;
    
    my $features = $genomeTO->{features};

    my @cols = qw(contig_id feature_id type location start stop strand
		  function aliases figfam evidence_codes nucleotide_sequence aa_sequence);

    my $tmp;
    my $ss;
    
    if ($suffix eq 'xls')
    {	
	$tmp = File::Temp->new(SUFFIX => ".$suffix");
	close($tmp);
	
	my $sheetname = substr("Features in $genomeTO->{scientific_name}", 0, 31);

	$ss = Spreadsheet::Write->new(file => "$tmp",
				      format => 'xls',
				      sheet => $sheetname,
				      styles  => {
					  header => { font_weight => 'bold' },
				      });

	$ss->addrow(map { { content => $_, style => 'header' } } @cols);
    }
    else
    {
	print $out_fh join("\t", @cols), "\n";
    }

    foreach my $feature (@$features)
    {
	next unless &$feature_type_ok($feature);
	my %dat;

	my $fid = $feature->{id};

	$dat{feature_id} = $fid;

	my($contig, $min, $max, $dir) = SeedUtils::boundaries_of(map { my($c,$s,$d,$l) = @$_; "${c}_$s$d$l" } @{$feature->{location}});
	if (!$contig)
	{
	    die Dumper($feature);
	}
	$dat{contig_id} = $contig;
	($dat{start}, $dat{stop}) = ($dir eq '+') ? ($min, $max) : ($max, $min);
	$dat{strand} = $dir;
	
	$dat{location} = join(",",map { my($contig,$beg,$strand,$len) = @$_; 
				 "$contig\_$beg$strand$len" 
			       } @{$feature->{location}});

	$dat{type} = $feature->{type};
	$dat{function} = $feature->{function};

	$dat{aa_sequence} = $feature->{protein_translation} ? $feature->{protein_translation} : '';
	$dat{nucleotide_sequence} = $genomeTO->get_feature_dna($fid);

	$dat{evidence_codes} = '';
	$dat{figfam} = '';
	$dat{aliases} = ref($feature->{aliases}) ? join(",",@{$feature->{aliases}}) : "";

	if ($ss)
	{
	    $ss->addrow(@dat{@cols});
	}
	else
	{
	    print $out_fh join("\t", @dat{@cols}), "\n";
	}
    }

    if ($ss)
    {
	undef $ss;
	copy("$tmp", $out_fh);
    }
}
