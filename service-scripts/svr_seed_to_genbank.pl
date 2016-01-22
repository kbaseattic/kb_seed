#!/usr/bin/env perl

#
# This is a SAS component.
#

use SeedUtils;
use WriteGenbank;

#########################################################################
# Copyright (c) 2003-2008 University of Chicago and Fellowship
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
#########################################################################

use strict;
use warnings;

use Data::Dumper;

$0 =~ m/([^\/]+)$/;
my $self = $1;

# my $usage = qq(usage: $self  LocusTag_Prefix  SEED_OrgDir > genbank.output);
my $usage = qq(usage: $self  [--help] [--map_funcs=mapfile.2c] [--locus_tag=LocusTag_Prefix] [--project=project_number] [--org_dir=SEED_OrgDir] > genbank.output);



my $trouble;

use Getopt::Long;
my $help;
my $org_dir;
my $project_ID;
my $func_map_file;
my $locus_tag_prefix;
my $rc = GetOptions(
		    "help!"         => \$help,
		    "map_funcs:s"   => \$func_map_file,
		    "org_dir:s"     => \$org_dir,
		    "project:i"     => \$project_ID,
		    "locus_tag:s"   => \$locus_tag_prefix,
		    );
print STDERR qq(\nrc=$rc\n\n) if $ENV{VERBOSE};

if (!$rc || $help) {
    warn qq(\n   usage: $usage\n\n);
    exit(0);
}



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Insert code to grandfather in old syntax here...
#-----------------------------------------------------------------------
if ((@ARGV == 2) && !$locus_tag_prefix && !$org_dir) {
    ($locus_tag_prefix, $org_dir) = @ARGV;
}

$org_dir =~ s/\/$//;
if (!-d $org_dir) {
    die "Organism directory $org_dir does not exist" unless (-d $org_dir);
}

my $genome_ID;
my $taxon_ID;
if ($org_dir =~ m/((\d+)\.\d+)\D*$/) {
    $genome_ID = $1;
    $taxon_ID  = $2;
}
else {
    die qq(Organism directory $org_dir does not end in a taxonomy ID (e.g., \'123456.7\'));
}

my $genome;
if (open(GENOME, "<$org_dir/GENOME")) {
    $genome = <GENOME>;
    chomp $genome;
    close(GENOME);
}
else {
    die "could not read-open $org_dir/GENOME";
}

my $taxonomy;
if (open(TAXONOMY, "<$org_dir/TAXONOMY")) {
    @_ = <TAXONOMY>;  chomp @_;
    $taxonomy =  join("", @_);
    $taxonomy =~ s/\s+/ /sgo;
    close(TAXONOMY);
}
else {
    die "could not read-open $org_dir/TAXONOMY";
}


my $strain;
if ((not $strain) && ($genome =~ m/^\S+\s+\S+\s+(.*)/)) {
    $strain = $1;
}


my $defline;
if (not $defline) {
    $defline = $genome;
}


my $project;
if (open(PROJECT, "<$org_dir/PROJECT")) {
    @_ = <PROJECT>;  chomp @_;
    $project =  join("", @_);
    $project =~ s/\s+/ /go;
    close(PROJECT);
}
else {
    die "could not read-open $org_dir/PROJECT";
}



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Load contigs files...
#-----------------------------------------------------------------------
opendir(ORG_DIR, $org_dir) || die "Could not opendir $org_dir";
my @contig_files = map { "$org_dir/$_" } grep { m/^contigs\d*$/ } readdir(ORG_DIR);
closedir(ORG_DIR) || die "Could not closedir $org_dir";



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Load tbl and function files...
#-----------------------------------------------------------------------
use constant FID    =>  0;
use constant LOCUS  =>  1;
use constant CONTIG =>  2;
use constant LEFT   =>  3;
use constant RIGHT  =>  4;
use constant LEN    =>  5;
use constant STRAND =>  6;
use constant TYPE   =>  7;
use constant FUNC   =>  8;
use constant EC_NUM =>  9;

my %map_func_to;
if ($func_map_file) {
    if (-s $func_map_file) {
	my $line;
	open(FUNC_MAP, q(<), $func_map_file)
	    or die "COuld not read-open \'$func_map_file\'";
	while (defined($line = <FUNC_MAP>)) {
	    chomp $line;
	    if ($line =~ m/^([^\t]+)\t([^\t]+)/o) {
		$map_func_to{$1} = $2;
	    }
	    else {
		$trouble = 1;
		warn "Could not parse line: \'$line\'";
	    }
	}
    }
}
die "\nCould not parse function map \'$func_map_file\' --- aborting" if $trouble;

my $EC_of = {};
my $function_of = {};
foreach my $assgn (qw(assigned_functions proposed_non_ff_functions proposed_functions)) {
    my $file = qq($org_dir/$assgn);
    if (-s $file) {
	my $fh;
	my $line;
	open($fh, qq(<$file)) || die qq(Could not read-open file \'$file\');
	while (defined($line = <$fh>)) {
	    chomp $line;
	    my ($fid, $func) = split /\t/, $line;
	    
	    my @ECs = ();
	    while ($func =~ s/\(EC\s+([^\)]+)\)//) {
		push @ECs, $1;
	    }
	    $EC_of->{$fid} = [@ECs]; 
	    
	    $func =~ s/\s+/ /sgo;
	    my @roles = map { defined($map_func_to{$_})
				  ? $map_func_to{$_} : $_
			      } split /\s*;\s+|\s+[\@\/]\s+/, $func;
	    $func = join( q( / ), @roles);
	    
	    if ($func) { $function_of->{$fid} = $func; }
	}
	close($fh);
    }
}

my ($seq_of,  $len_of)  = &load_fasta(@contig_files);
my ($peg_seq, $peg_len) = &load_fasta("$org_dir/Features/peg/fasta");

my @tbls = ("$org_dir/Features/peg/tbl");
if (-s "$org_dir/Features/rna/tbl")  { push @tbls, "$org_dir/Features/rna/tbl"; }

my ($tbl) = &load_tbls($function_of, $EC_of, @tbls);


use Time::localtime;
my $time = localtime;
my $date = sprintf "%02d-%3s-%04d"
    , $time->mday
    , (qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC))[$time->mon]
    , (1900+$time->year);

foreach my $contig (sort keys %$len_of)
{
    my $tmp;
    &form_header($contig, $len_of->{$contig}, $defline, $genome, $strain, $taxonomy, $taxon_ID);
    
    my $features = $tbl->{$contig};
    foreach my $feature (@$features) {
	
	my $locus = $feature->[LOCUS];
	my ($gene_locus, $feature_locus) = &to_ncbi_locus($feature);
	
	my $feature_num;
	if ($feature->[FID] =~ m/\.(\d+)$/) {
	    $feature_num = $1;
	}
	else {
	    die qq(Could not extract feature-number from FIG=\'$feature->[FID]\');
	}
	
	my $ltag;
	my $db_xref;
        if ($feature->[TYPE] eq 'peg') {
	    $ltag = $locus_tag_prefix . q(_) . &zero_pad(4, $feature_num);
	    $db_xref = q(SEED:).$feature->[FID];
	    
	    &form_feature(q(gene), $gene_locus);
	    &form_feature(q(CDS), $feature_locus, $ltag, $db_xref);
	    
            if ($feature->[FUNC]) {
		&form_multiline('product', $feature->[FUNC]);
	    }
	    
	    if ($feature->[EC_NUM]) {
		foreach my $EC_num (@ { $feature->[EC_NUM] }) {
		    &form_multiline(q(EC_number), $EC_num);
		}
	    }
	    
	    &form_multiline('translation', $peg_seq->{$feature->[FID]});
	}
	elsif ($feature->[TYPE] eq 'rRNA') {
	    $ltag = $locus_tag_prefix . q(_r) . &zero_pad(3, $feature_num);
	    
	    &form_feature(q(gene), $gene_locus, $ltag);
	    &form_feature(q(rRNA), $feature_locus, $ltag);
	    
            if ($feature->[FUNC]) {
		&form_multiline('product', $feature->[FUNC]);
	    }
	}
	elsif ($feature->[TYPE] eq 'tRNA') {
	    $ltag = $locus_tag_prefix . q(_r) . &zero_pad(3, $feature_num);
	    
	    &form_feature(q(gene), $gene_locus, $ltag);
	    &form_feature(q(tRNA), $feature_locus, $ltag);
	    
            if ($feature->[FUNC]) {
		&form_multiline('product', $feature->[FUNC]);
	    }
	}
	elsif ($feature->[TYPE] eq 'misc_RNA') {
	    $ltag = $locus_tag_prefix . q(_r) . &zero_pad(3, $feature_num);
	    
	    &form_feature(q(gene),     $gene_locus, $ltag);
	    &form_feature(q(misc_RNA), $feature_locus, $ltag);
	    
            if ($feature->[FUNC]) {
		&form_multiline('product', $feature->[FUNC]);
	    }
	}
	else {
	    warn "Skipping unknown feature: ", join(", ", @$feature), "\n";
	}
	
	print STDOUT $^A;
	$^A = q();
    }
    
    &write_contig($contig);
    
    print "//\n";
}





sub load_fasta {
    my (@files) = @_;
    my ($file, $id, $seqP, $len);
    
    my $seq_of = {};
    my $len_of = {};
    
    foreach $file (@files)
    {
	print STDERR "Loading $file\n" if $ENV{VERBOSE};
	
	open (FILE, "<$file") or die "could not read-open $file";
	while (($id, $seqP) = &read_fasta_record(\*FILE))
	{
	    $len = $len_of->{$id} = length($$seqP);
#	    print STDERR "\tSeq $id ($len chars)\n";
	    
	    if (($$seqP =~ tr/acgtACGT//) > 0.9*$len) {
		$$seqP  =~ tr/A-Z/a-z/;
	    } else {
		$$seqP  =~ tr/a-z/A-Z/;
	    }
	    $seq_of->{$id} = $$seqP;
	}
	close(FILE) or die "could not close $file";
    }
    
    return ($seq_of, $len_of);
}


sub load_tbls {
    my ($function_of, $EC_of, @files) = @_;
    my ($file, $entry, $fid, $locus, $alias, $contig, $left, $right, $len, $strand, $type, $func);
    my $x;
    my $tbl = {};
    
    foreach $file (@files) {
	print STDERR "Loading $file ...\n" if $ENV{VERBOSE};
	
	open(TBL, "<$file") || die "Could not read-open $file";
	while (defined($entry = <TBL>)) {
	    chomp $entry;
	    
	    ($fid, $locus, $alias) = split /\t/, $entry;
	    $fid  =~ m/^[^\|]+\|\d+\.\d+\.([^\.]+)/;
	    $type =  $1;
	    
	    if ((($contig, $left, $right, $len, $strand) = &from_locus($locus)) 
		&& defined($contig) && $contig
		&& defined($left)   && $left
		&& defined($right)  && $right
		&& defined($len)    && $len
		&& defined($strand) && $strand
		)
	    {
		if (not defined($tbl->{$contig})) { $tbl->{$contig} = []; }
		$x = $tbl->{$contig};
		
		$func = undef;
		if ($type eq 'peg') {
		    $func = $function_of->{$fid} || q();
		}
		elsif ($type eq 'rna') {
		    $func = $function_of->{$fid} || q();
		    if (($func !~ m/\S+/o) && $alias) {
			$func = $alias;
		    }
		    
		    if ($func =~ m/tRNA/o) {
			$type = 'tRNA';
		    }
		    elsif ($func =~ m/ribosomal/io) {
			$type = 'rRNA';
		    }
		    else {
			$type = 'misc_RNA';
		    }
		}
		else {
		    warn "$fid has unknown feature type $type";
		    next;
		}
		
		my $ECs = $EC_of->{$fid};
		push @$x, [ $fid, $locus, $contig, $left, $right, $len, $strand, $type, $func, $ECs ];
	    }
	    else {
		warn "INVALID ENTRY in $file:\t$entry\n";
	    }
	}
	close(TBL) || die "Could not close $file";
    }
    
    foreach $contig (keys %$tbl)
    {
	$x  = $tbl->{$contig};
	@$x = sort by_locus @$x;
    }
    
    return $tbl;
}


sub from_locus {
    my ($locus) = @_;
    
    my ($contig, $left, $right, $strand) = &SeedUtils::boundaries_of($locus);

    if ($contig && $left && $right && $strand) {
	return ($contig, $left, $right, (1+abs($right-$left)), $strand)
    }
    else {
	die "Invalid locus $locus";
    }
    
    return ();
}

sub to_ncbi_locus {
    my ($feature) = @_;
    my ($gene_locus, $feature_locus);
    
    my $locus = $feature->[LOCUS];
    my @exons = split(/,/, $locus);
    if ($feature->[STRAND] eq '+') {
	$gene_locus = "$feature->[LEFT]\.\.$feature->[RIGHT]";
	
	$feature_locus = join(q(,), map { m/^\S+_(\d+)_(\d+)$/ ? $1.q(..).$2 : () } @exons);
	if (@exons > 1) {
	    $feature_locus = 'join(' . $feature_locus . ')';
	} 
    }
    else {
	$gene_locus = "complement($feature->[LEFT]\.\.$feature->[RIGHT])";
	
	@exons = reverse @exons;
	$feature_locus = 'complement(' . join(q(,), map { m/^\S+_(\d+)_(\d+)$/ ? $2.q(..).$1 : () } @exons) . ')';
    }
    
    return ($gene_locus, $feature_locus);
}


sub zero_pad {
    my ($width, $num) = @_;
    return ((q(0) x ($width - length($num))) . $num);
}


sub by_locus {
    my (undef, undef, $A_contig, $A_left, $A_right, $A_len, $A_strand) = @$a;
    my (undef, undef, $B_contig, $B_left, $B_right, $B_len, $B_strand) = @$b;
    
    return (  ($A_contig cmp $B_contig) 
	   || ($A_left <=> $B_left)
	   || ($B_len  <=> $A_len)
	   || ($A_strand cmp $B_strand)
	   );
}


sub read_fasta_record {

    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($file_handle) = @_;
    my ($old_end_of_record, $fasta_record, @lines, $head, $sequence, $seq_id, $comment, @parsed_fasta_record);

    if (not defined($file_handle))  { $file_handle = \*STDIN; }

    $old_end_of_record = $/;
    $/ = "\n>";

    if (defined($fasta_record = <$file_handle>)) {
        chomp $fasta_record;
        @lines  =  split( /\n/, $fasta_record );
        $head   =  shift @lines;
        $head   =~ s/^>?//;
        $head   =~ m/^(\S+)/;
        $seq_id = $1;
        if ($head  =~ m/^\S+\s+(.*)$/)  { $comment = $1; } else { $comment = ""; }
        $sequence  =  join( "", @lines );
        @parsed_fasta_record = ( $seq_id, \$sequence, $comment );
    } else {
        @parsed_fasta_record = ();
    }

    $/ = $old_end_of_record;

    return @parsed_fasta_record;
}

sub form_header {
    my ($contig, $contig_len, $defline, $genome, $strain, $taxonomy, $taxon_ID) = @_;

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Build up header in the Format Accumulator...
#-------------------------------------------------------------------------------

    formline <<END, $contig, $contig_len, $date;
LOCUS       @<<<<<<<<<<<<<<<<<<<@####### bp    DNA     circular BCT @<<<<<<<<<<<
END

    formline <<END, $defline;
DEFINITION  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    formline <<END, $defline;
~~          ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    formline <<END, $genome;
ACCESSION   $contig .
VERSION     $contig.1  .
KEYWORDS    WGS.
SOURCE      @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    formline <<END, $genome, $taxonomy;
  ORGANISM  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END, $taxonomy;
~~          ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    formline <<END, $contig_len, $contig_len;
REFERENCE   1  (bases 1 to @#######)
  AUTHORS   [Insert Names here]
  TITLE     Direct Submission
  JOURNAL   [Insert paper submission information here]
COMMENT     [Insert project information here]
FEATURES             Location/Qualifiers
     source          1..@<<<<<<<
END

    &form_multiline('organism', $genome);
    &form_multiline('mol_type', 'genomic DNA');
    &form_multiline('strain', $strain) if $strain;
    &form_multiline('db_xref', "taxon:$taxon_ID");

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Print header and clear Format-Accumulator...
#===============================================================================
    print $^A;  $^A = ""; 
#-------------------------------------------------------------------------------
    
    return;
}



sub form_feature {
    my ($type, $locus, $ltag, $db_xref) = @_;
    
    my $break_old;
    ($break_old, $:) = ($:, q(,));
    
    formline <<END, $type, $locus;
     @<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    formline <<END, $locus;
~~                   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    &form_field(q(locus_tag), $ltag)    if ($ltag);
    &form_field(q(db_xref),   $db_xref) if ($db_xref);
    
    $: = $break_old;
    return;
}

sub form_field {
    my ($field, $text) = @_;
    
    my $tmp = "/$field=\"$text\"";
    formline <<END, $tmp;
                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END

    return;
}
   


sub form_multiline {
    my ($field, $text) = @_;
    
    my $tmp = "/$field=\"$text\"";
    
    formline <<END, $tmp;
                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
	
    formline <<END, $tmp;
~~                   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    
    return;
}



sub write_contig {
    my ($contig) = @_;
    
    my $tmp = $seq_of->{$contig};
    
    formline <<END;
ORIGIN
END

    my $charcount = 1;
    while ($tmp)
    {
	formline <<END, $charcount, $tmp, $tmp, $tmp, $tmp, $tmp, $tmp;
@######## ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<<
END
        $charcount += 60;
    }
    
    print $^A;   $^A = "";
    
    return;
}
