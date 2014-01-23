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

Identify the drug resistance proteins in one or more genomes.

Usage: svr_drug_resistance_proteins    [options] < genome_ids         > proteins_found
       svr_drug_resistance_proteins -q [options]   aa_query_file ...  > proteins_found
       svr_drug_resistance_proteins -g [options] [ genome_id ... ]    > proteins_found

Output:

       sequence_id \t function_of_most_similar_ref_protein \t sequence \t tag

Options:

    -a 'role'  #  Proposed assignment for sequences whose closest referece match has no assignment
    -b         #  Add a blank line between genomes (D = no blank)
    -c min-cov #  Min coverage (D = defined in the module of representatives)
    -d domains #  One or more of the letters A, B and/or E, run together
    -e e-value #  Max e-value for calling proteins (D = defined in the module of representatives)
    -f         #  Fasta output format
    -g         #  Parameters are genome ids. No ids gives all complete genomes.
    -i ident   #  Min percent identity (D = defined in module of representatives)
    -m module  #  Perl module with reference sequences for the RNA type
    -p         #  Include partial Sapling genomes
    -q         #  Parameters are query file names (D = genome ids from STDIN)
    -r reffile #  File of reference sequences for the protein type
    -s         #  Do not show sequence
    -t 'tag'   #  A short tage to identify the nature of the feature; allows
               #      mixing of different types; empty string supresses the
               #      field (D = '')
    -u url     #  url of the desired sapling server
    -v         #  Send some progress information to STDERR

The reference sequence perl modules have common internal variable names. For
example, Prot_reps_drug_resistance begins with:

    package Prot_reps;
    use strict;
    use gjoseqlib;
    
    our @prot_reps       = gjoseqlib::read_fasta( \*DATA );
    our $assignment      = 'Protein matching drug resistance reference sequences';
    our $feature_type    = 'protein';
    our $max_expect      = 1e-10;
    our $max_extrapolate = 10;
    our $max_rep_sim     = 0.87;    # identity below which a new rep is needed
    our $min_coverage    = 0.70;
    our $min_identity    = 0.30;
    our $tag             = 'drug_resistance';

User-supplied command options will override the default values.

End_of_Usage

use SeedEnv;
use strict;
use find_homologs;
use gjoseqlib;
use gjoalignment;
use Data::Dumper;

my $assignment  = '';
my $blank       =  0;
my $complete    =  1;
my $queryfiles  =  0;
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
    if ( s/^c// ) { $coverage    = /\S/ ? $_ : shift; next }
    if ( s/^d// ) { $domains     = /\S/ ? $_ : shift; next }
    if ( s/^e// ) { $expect      = /\S/ ? $_ : shift; next }
    if ( s/^i// ) { $identity    = /\S/ ? $_ : shift; next }
    if ( s/^m// ) { $module      = /\S/ ? $_ : shift; next }
    if ( s/^r// ) { $reffile     = /\S/ ? $_ : shift; next }
    if ( s/^t// ) { $tag         = /\S/ ? $_ : shift; next }
    if ( s/^u// ) { $url         = /\S/ ? $_ : shift; next }

    if ( s/b//g ) { $blank       = 1 }
    if ( s/q//g ) { $queryfiles  = 1 }
    if ( s/g//g ) { $genomeids   = 1 }
    if ( s/s//g ) { $no_seq      = 1 }
    if ( s/v//g ) { $verbose     = 1 }
    if ( s/f//g ) { $fasta       = 1 }

    if ( m/\S/ )
    {
        print STDERR "Bad flag '$_'\n", $usage;
        exit;
    }
}

my @prot;

if ( $reffile )
{
    -f $reffile
        or print STDERR "Invalid reference sequence file '$reffile'.\n", $usage
            and exit;
    @prot = gjoseqlib::read_fasta( $reffile )
        or print STDERR "No sequences found in '$reffile'.\n", $usage
            and exit;
    $assignment ||= "Protein based on similarity to $reffile data";
}
else
{
    $module ||= 'Prot_reps_drug_resistance';
    $module =~ s/\.pm$//;
    eval { require "$module.pm" };
    if ( $@ )
    {
        print STDERR "Failed in require '$module'.\n$@\n", $usage
            and exit;
    }

    @prot        = @Prot_reps::prot_reps;
    $assignment  = $Prot_reps::assignment      if ! $assignment          && $Prot_reps::assignment;
    $tag         = $Prot_reps::tag             if ! $tag                 && $Prot_reps::tag;

    $coverage    = $Prot_reps::min_coverage    if ! defined $coverage    && $Prot_reps::min_coverage;
    $identity    = $Prot_reps::min_identity    if ! defined $identity    && $Prot_reps::min_identity;
    $expect      = $Prot_reps::max_expect      if                           $Prot_reps::max_expect;
    $extrapolate = $Prot_reps::max_extrapolate if ! defined $extrapolate && $Prot_reps::max_extrapolate;
}

ensure_defined( $assignment,  'Protein matching reference data' );
ensure_defined( $coverage,     0.7 );
ensure_defined( $extrapolate, 20 );
ensure_defined( $identity,     0.3 );

my $sapObject = $queryfiles ? '' : SAPserver->new( $url ? ( url => $url ) : () );

my @genomes = @ARGV;
if ( ! $genomeids && ! @genomes )
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

my $pegsH;
if ( ! $queryfiles )
{
    $pegsH = $sapObject->all_features( -ids => \@genomes, -type => [ 'peg' ] );
}

my $options = { description => $assignment,
                extrapolate => $extrapolate,
                refseq      => \@prot
              };
$options->{ coverage }    = $coverage     if $coverage;
$options->{ identity }    = $identity     if $identity;
$options->{ seedexp }     = $expect       if $expect;
$options->{ loc_format }  = $loc_format   if $loc_format;

print STDERR "    @{[scalar @genomes]} genomes to process\n" if $verbose;
foreach my $genome ( @genomes )
{
    print STDERR "Processing $genome.\n" if $verbose;
    my @aaseqs;
    if ( $queryfiles )
    {
        -f $genome
            or print STDERR "Could not find query sequence file '$genome'. Skipping.\n"
                and next;
        @aaseqs = gjoseqlib::read_fasta( $genome )
            or print STDERR "No sequences found in '$genome'. Skipping.\n"
                and next;
    }
    else
    {
        my $fids = $pegsH->{ $genome } || [];
        @$fids
            or print STDERR "Could not find pegs for genome '$genome'. Skipping.\n"
                and next;
        my $seqH = $sapObject->ids_to_sequences( -ids => $fids, -protein => 1 );
        @aaseqs = map { [ $_, '', $seqH->{ $_ } ] } @$fids
            or print STDERR "No sequences found for '$genome'. Skipping.\n"
                and next;
    }
    print STDERR "    @{[scalar @aaseqs]} proteins\n" if $verbose;

    my $instances = find_protein_homologs( \@aaseqs, $options );
    my @instances = map { my $qid = $_->{ query_id };
                          my $seq = $_->{ sequence };
                          my $def = $_->{ reference_def } || $assignment;
                          my $sid = $_->{ reference_id };
                          [ $qid, $def, $seq, $sid ] 
                        } 
                    @$instances;

    print STDERR "    @{[scalar @instances]} proteins found\n" if $verbose;
    foreach ( @instances )
    {
        if ( ! $fasta )
        {
            print join( "\t", @$_[0..1],
                              $_->[3],
                              ( !$no_seq ? $_->[2] : () ),
                              ( $tag     ? $tag    : () )
                      ), "\n"
        }
        else
        {
            gjoseqlib::print_seq_as_fasta( @{$_} );
        }
    }

    print "\n" if @instances && $blank;  #  Blank line between genomes
}

exit;

sub ensure_defined { $_[0] = $_[1] if ! defined $_[0] }

sub next_fasta_seq
{
    my ( $seqs, $n ) = @_;
    return $seqs->[ $n || 0 ] if ref $seqs eq 'ARRAY';
    gjoseqlib::read_next_fasta_seq( $seqs );
}


sub find_protein_homologs
{
    my ( $aaseqs, $options ) = @_;
    -f $aaseqs && -s $aaseqs
       or ref $aaseqs eq 'ARRAY' && ref $aaseqs->[0] eq 'ARRAY'
       or print STDERR "find_nucleotide_homologs called with bad \\\@aaseqs\n"
          and return [];
    ref $options eq 'HASH'
       or print STDERR "find_nucleotide_homologs called with bad \\%options\n"
          and return [];

    my $blastall  = $options->{ blastall }   ||= SeedAware::executable_for( 'blastall' );
    my $min_cover = $options->{ coverage }   ||=    0.70;  # Minimum fraction of reference covered
    my $max_exp   = $options->{ expect }     ||=    0.01;  # Maximum e-value for blast
    my $extrapol  = $options->{ extrapol }   ||= $options->{ extrapolate } || 0;  # Max to extrapolate ends of subj seq
    my $formatdb  = $options->{ formatdb }   ||= SeedAware::executable_for( 'formatdb' );
    my $ftr_type  = $options->{ ftrtype } if exists $options->{ ftrtype };
    my $descr     = $options->{ descript }   ||= $options->{ description } || "";
    my $loc_form  = $options->{ loc_format } ||= 'seed';
    my $min_ident = $options->{ identity }   ||=    0.60;  # Minimum fraction sequence identity
    my $max_split = $options->{ maxsplit }   ||=    0;
    my $max_gap   = $options->{ maxgap }     ||= 5000;     # Maximum gap in genome match
    my $prefix    = $options->{ prefix }     ||=   "";
    my $ref_file  = $options->{ reffile };
    my $ref_seq   = $options->{ refseq };
    my $seed_exp  = $options->{ seedexp }    ||=    1e-20; # Maximum e-value to nucleate match
    my $verbose   = $options->{ verbose }    ||=    0;

    my ( $tmp_dir, $save_tmp ) = SeedAware::temporary_directory( $options );

    #  Build the blast database of reference sequences:
    #
    #  Four cases:
    #     "$ref_file.nsq" exists
    #         use it
    #     "$ref_file.nsq" and $ref_seq do not exist, but "$ref_file" exists
    #         run formatdb -i $ref_file -n "$tmp_dir/$tmp_name"
    #     "$ref_file.nsq" does not exist, but $ref_seq exists
    #         write a temp file in $tmp_dir and run formatdb -i "$tmp_dir/$tmp_name"
    #     nothing exists
    #         bail

    my $db;
    if ( $ref_file && -f "$ref_file.psq" )
    {
        $db = $ref_file;
    }
    elsif ( ref $ref_seq eq 'ARRAY' && ref $ref_seq->[0] eq 'ARRAY' )
    {
        $db = "$tmp_dir/ref_seqs";
        print_alignment_as_fasta( $db, $ref_seq );
        my @cmd = ( $formatdb, -p => 'T', -i => $db );
        system( @cmd ) and die join( ' ', 'Failed', @cmd );
    }
    elsif ( -f $ref_file && -s $ref_file )
    {
        my $name = $ref_file;
        $name =~ s/^.*\///;    # Remove leading path
        $db = "$tmp_dir/$name";
        my @cmd = ( $formatdb, -p => 'T', -i => $ref_file, -n => $db );
        system( @cmd ) and die join( ' ', 'Failed', @cmd );
    }
    else
    {
        print STDERR "find_protein_homologs cannot locate reference sequence data\n";
        return [];
    }

    $options->{ db } = $db;
    $options->{ seqtype } = 'p';

    #  There are two ways to go for the aaseqs:
    #
    #     $aaseqs is a file of aaseqs
    #         use it
    #     $aaseqs is a reference to an array of sequences
    #         write them to a file

    my $qfile;
    if ( ref $aaseqs eq 'ARRAY' )
    {
        return [] if ! @$aaseqs;
        return [] if ! ref $aaseqs->[0] eq 'ARRAY';   #  Could do better diagnosis
        $qfile   = "$tmp_dir/query";
        print_alignment_as_fasta( $qfile, $aaseqs );  #  Write them all
    }
    else
    {
        -f $aaseqs
            or print STDERR "Bad aaseqs file '$aaseqs'\n"
            and return [];
        $qfile = $aaseqs;
    }

    my @cmd = ( $blastall,
                -p => 'blastp',
                -d => $db,
                -i => $qfile,
                -r =>  1,
                -q => -1,
                -F => 'f',
                -e => $max_exp,
                -v =>  5,
                -b =>  5,
                -a =>  8
              );

    my $redirect = { stderr => '/dev/null' };
    my $blastFH = SeedAware::read_from_pipe_with_redirect( @cmd, $redirect )
        or die join( ' ', 'Failed:', @cmd );

    #  Process blast results one sequence at a time

    my @out;
    my $aaseq;  #  AA sequence data
    my $n = 0;

    while ( $aaseq = next_fasta_seq( $aaseqs, $n++ ) )
    {
        my $query_results = find_homologs::next_blast_query( $blastFH ) or next;
        my ( $qid, $qdef, $qlen, $q_matches ) = @$query_results;

        #  Check the framing between aaseqs and blast queries:

        if ( $qid ne $aaseq->[0] )
        {
            die "Sequence data ($aaseq->[0]) and blastp output ($qid) are out of phase.\n";
        }

        #  A given query may hit zero or more reference sequences

        my @matches = ();
        foreach my $subject_results ( @$q_matches )
        {
            my ( $sid, $sdef, $slen, $s_matches ) = @$subject_results;

            # Future work: merge aa hsps 
            # For now: only consider the hsp with the highest bit score

            my @by_score = sort { $b->[0] <=> $a->[0] }
                           grep { $_->[1] <=  $max_exp
                                  && ($_->[10] - $_->[9] + 1) >= $min_cover * $qlen
                                  && gjoalignment::fraction_aa_identity( @$_[11,14] ) >= $min_ident
                                }
                    @$s_matches;

            my ($scr) = @by_score or next;
            push @matches, [ $sid, $sdef, $slen, $scr ];
        }
        
        @matches = sort { $b->[3] <=> $a->[3] } @matches;
        my ($best_match) = @matches or next;

        push @out, { query_id      => $qid,
                     query_def     => $qdef,
                     reference_id  => $best_match->[0],
                     reference_def => $best_match->[1],
                     sequence      => $aaseq->[2]
                   };
    }

    close( $blastFH );
    system( '/bin/rm', '-r', $tmp_dir ) if ! $save_tmp;

    wantarray ? @out : \@out;
}
