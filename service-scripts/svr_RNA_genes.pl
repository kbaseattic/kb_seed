#
# This is a SAS Component
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

my $usage = <<'End_of_Usage';

Identify the RNA genes in one or more genomes.

Usage: svr_RNA_genes    [options] < genome_ids       > RNAs_found
       svr_RNA_genes -c [options]   contig_file ...  > RNAs_found
       svr_RNA_genes -g [options] [ genome_id ... ]  > RNAs_found

Output:

    genome_id \t type \t location \t tag \t proposed_assignment \t sequence

    where type is always rna.

Options:

    -a 'role'  #  Proposed assignment; empty string supresses the field
    -b         #  Add a blank line between genomes (D = no blank)
    -c         #  Parameters are contig file names (D = genome ids from STDIN)
    -d domains #  One or more of the letters A, B and/or E, run together
    -e dist    #  Maximum number of unmatched nucleotides at end of a match
               #      to extrapolate the end points (D = 20)
    -f         #  Fasta output format
    -g         #  Parameters are genome ids. No ids gives all complete genomes.
    -j nt      #  Just show the first and last nt nucleotides (D = full seq)
    -l locform #  Location format: SEED (D) or Sapling
    -m module  #  Perl module with reference sequences for the RNA type
               #      (D = RNA_reps_SSU_rRNA; excludes -r)
    -p         #  Include partial Sapling genomes
    -q         #  Provide four more output fields with quality control info:
               #      uncovered reference nt at 5' end
               #      distance from 5' end to contig end
               #      uncovered reference nt at 3' end
               #      distance from 3' end to contig end
    -r reffile #  File of reference sequences for the RNA type (excludes -m)
    -s         #  Do not show sequence (excludes -j)
    -t 'tag'   #  A short tag to identify the nature of the feature; allows
               #      mixing of different types; empty string supresses the
               #      field (D = '', but modules may include a tag)
    -u url     #  url of the desired sapling server
    -v         #  Send some progress information to STDERR

The reference sequence perl modules have common internal variable names. For
example, RNA_reps_SSU_rRNA begins with:

    package RNA_reps;
    use strict;
    use gjoseqlib;

    our @RNA_reps        = gjoseqlib::read_fasta( \*DATA );
    our $assignment      = 'SSU rRNA ## 16S rRNA, small subunit ribosomal RNA';
    our $tag             = 'SSU_rRNA';
    our $max_expect      = 1e-20;
    our $max_extrapolate = 10;
    our $min_coverage    = 0.20;

User-supplied command options will override the default values.

End_of_Usage

use SeedEnv;
use strict;
use find_homologs;
use gjoseqlib;
use Data::Dumper;

my $assignment  = '';
my $blank       =  0;
my $complete    =  1;
my $contigfiles =  0;
my $coverage    =  undef;
my $domains     = '';
my $expect      =  1e-5;
my $extrapolate =  undef;
my $fasta       =  0;
my $genomeids   =  0;
my $identity    =  undef;
my $just_ends   =  0;
my $loc_format  = 'SEED';
my $module      = '';
my $no_seq      =  0;
my $quality     =  0;
my $reffile     = '';
my $tag;
my $url;
my $verbose     =  0;

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    local $_ = shift;
    if ( s/^a// ) { $assignment  = /\S/ ? $_ : shift; next }
    if ( s/^d// ) { $domains     = /\S/ ? $_ : shift; next }
    if ( s/^e// ) { $extrapolate = /\S/ ? $_ : shift; next }
    if ( s/^i// ) { $identity    = /\S/ ? $_ : shift; next }
    if ( s/^j// ) { $just_ends   = /\S/ ? $_ : shift; next }
    if ( s/^l// ) { $loc_format  = /\S/ ? $_ : shift; next }
    if ( s/^m// ) { $module      = /\S/ ? $_ : shift; next }
    if ( s/^r// ) { $reffile     = /\S/ ? $_ : shift; next }
    if ( s/^t// ) { $tag         = /\S/ ? $_ : shift; next }
    if ( s/^u// ) { $url         = /\S/ ? $_ : shift; next }

    if ( s/b//g ) { $blank       = 1 }
    if ( s/c//g ) { $contigfiles = 1 }
    if ( s/f//g ) { $fasta       = 1 }
    if ( s/g//g ) { $genomeids   = 1 }
    if ( s/p//g ) { $complete    = 0 }
    if ( s/q//g ) { $quality     = 1 }
    if ( s/s//g ) { $no_seq      = 1 }
    if ( s/v//g ) { $verbose     = 1 }

    if ( m/\S/ )
    {
        print STDERR "Bad flag '$_'\n", $usage;
        exit;
    }
}

my @rna;
if ( $reffile )
{
    -f $reffile
        or print STDERR "Invalid reference sequence file '$reffile'.\n", $usage
            and exit;
    @rna = gjoseqlib::read_fasta( $reffile )
        or print STDERR "No sequences found in '$reffile'.\n", $usage
            and exit;
    $assignment ||= "RNA based on similarity to $reffile data";
}
else
{
    $module ||= 'RNA_reps_SSU_rRNA';
    $module =~ s/\.pm$//;
    eval { require "$module.pm" };
    if ( $@ )
    {
        print STDERR "Failed in require '$module'.\n$@\n", $usage
            and exit;
    }

    @rna         = @RNA_reps::RNA_reps;
    $assignment  = $RNA_reps::assignment      if ! $assignment          && $RNA_reps::assignment;
    $tag         = $RNA_reps::tag             if ! $tag                 && $RNA_reps::tag;

    $coverage    = $RNA_reps::min_coverage    if ! defined $coverage    && $RNA_reps::min_coverage;
    $identity    = $RNA_reps::min_identity    if ! defined $identity    && $RNA_reps::min_identity;
    $expect      = $RNA_reps::max_expect      if                           $RNA_reps::max_expect;
    $extrapolate = $RNA_reps::max_extrapolate if ! defined $extrapolate && $RNA_reps::max_extrapolate;
}

ensure_defined( $assignment,  'RNA matching reference data' );
ensure_defined( $coverage,     0.7 );
ensure_defined( $extrapolate, 20 );
ensure_defined( $identity,     0.5 );

my $sapObject = $contigfiles ? '' : SAPserver->new( $url ? ( url => $url ) : () );

my @genomes = @ARGV;
if ( $contigfiles )
{
}
elsif ( ! $genomeids && ! @genomes )
{
    @genomes = map { /(\d+\.\d+)/ ? $1 : () }
               map { chomp; ( split /\t/ )[-1] }
               <>;
}
elsif ( $genomeids && ! @genomes )
{
    my $prok = $domains =~ m/E/i ? 0 : 1;
    my $genomeH = $sapObject->all_genomes( -complete => $complete, -prokaryotic => $prok );
    @genomes = map  { $_->[0] }
               sort { $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] }
               map  { [ $_, split /\./ ] }   # [ genome_id, taxon_id, instance ]
               keys %$genomeH;
}

my $contigsH;
if ( ! $contigfiles )
{
   $contigsH = $sapObject->genome_contigs( -ids => \@genomes );
}

my $options = { description => $assignment,
                extrapolate => $extrapolate,
                refseq      => \@rna
              };
$options->{ coverage }    = $coverage     if $coverage;
$options->{ identity }    = $identity     if $identity;
$options->{ seedexp }     = $expect       if $expect;
$options->{ loc_format }  = $loc_format   if $loc_format;

my $pat;
$pat = qr/^(.{$just_ends})....+(.{$just_ends})$/o if $just_ends;

print STDERR "    @{[scalar @genomes]} genomes to process\n" if $verbose;
foreach my $genome ( @genomes )
{
    print STDERR "Processing $genome.\n" if $verbose;
    my @contigs;
    if ( $contigfiles )
    {
        -f $genome
            or print STDERR "Could not find contig file '$genome'. Skipping.\n"
                and next;
        @contigs = gjoseqlib::read_fasta( $genome )
            or print STDERR "No sequences found in '$genome'. Skipping.\n"
                and next;
    }
    else
    {
        my $locs = $contigsH->{ $genome } || [];
        @$locs
            or print STDERR "Could not find contigs for genome '$genome'. Skipping.\n"
                and next;
        my $seqH = $sapObject->locs_to_dna( -locations => { map { $_ => $_ } @$locs } );
        @contigs = map { [ $_, '', $seqH->{ $_ } ] } @$locs
            or print STDERR "No sequences found for '$genome'. Skipping.\n"
                and next;
    }
    print STDERR "    @{[scalar @contigs]} contigs\n" if $verbose;

    my $instances = find_homologs::find_nucleotide_homologs( \@contigs, $options );

    my @instances = map  { $_->[2] }
                    sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
                    map  { my $loc =   $_->{ location };
                           my $seq =   $_->{ sequence };
                           my @qc  = ( $_->{ uncover5 }, $_->{ from_end5 },
                                       $_->{ uncover3 }, $_->{ from_end3 } );
                           my ( $c, $b, $e ) = $loc =~ /^(.*)_(\d+)_(\d+)$/;
                           $seq =~ s/$pat/$1...$2/ if $just_ends;
                           [ $c, $b+$e, [ $genome, 'rna', $loc, lc $seq, @qc ] ]
                         }
                    @$instances;

    print STDERR "    @{[scalar @instances]} RNAs found\n" if $verbose;
    foreach ( @instances )
    {
        if ( ! $fasta )
        {
            print join( "\t", @$_[0..2],
                              ( $tag        ? $tag        : () ),
                              ( $assignment ? $assignment : () ),
                              $_->[3],
                              ( $quality    ? @$_[4..7]   : () )
                      ), "\n"
        }
        else
        {
            #  Note that sapling contig ids include the genome id
            #  >location assignment
            #  sequence...
            #
            gjoseqlib::print_seq_as_fasta( "$_->[2]", $assignment, $_->[3] );
        }
    }

    print "\n" if @instances && $blank;  #  Blank line between genomes
}

exit;

sub ensure_defined { $_[0] = $_[1] if ! defined $_[0] }

