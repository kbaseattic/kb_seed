package gjocodonlib;

#
# This is a SAS Component
#

#===============================================================================
#  Hash of counts (keys are uppercase DNA triplets):
#
#     $countH = entry_codon_count( [ $countH, ] @seq_entrys )
#     $countH = seq_codon_count(   [ $countH, ] $sequence )
#
#  Flat list of counts (yuk, but it can be used to make packaged counts, etc.):
#
#     @counts = codon_count_list( $countH )
#     @counts = codon_count_list( $countH,  @codon_order )
#     @counts = codon_count_list( $countH, \@codon_order )
#
#  Packaged counts, a hierarchical list of counts:
#     Used by most routines, so usually just called $counts, $cnt or $cnts
#
#     $counts = [ [ n(GCA), n(GCG), n(GCT), n(GCC) ], # A
#                 [ n(TGT), n(TGC) ],                 # C
#                 [ n(GAT), n(GAC) ],                 # D
#                  .
#                  .
#                  .
#                 [ n(TAT), n(TAC) ],                 # Y
#                 [ n(ATG) ],                         # M  (_20 versions)
#                 [ n(TGG) ]                          # W  (_20 versions)
#               ];
#
#     $counts = [ map { [ codon_count_list( $countH, $amino_acid_codons_DNA{ $_ } ) ] }
#                 qw( A C D E F G H I K L N P Q R S T V Y )
#               ];
#
#   from hash:
#
#     $counts = codon_count_package(    $countH )
#     $counts = codon_count_package_20( $countH )
#
#   from string:
#
#     $counts           = split_counts( $codon_count_string )
#   ( $counts, $label ) = split_counts( $codon_count_string )
#
#   from DNA:
#
#     @count_sets = entry_codon_count_package(    @seq_entrys )
#     @count_sets = entry_codon_count_package_20( @seq_entrys )
#
#     @count_sets = seq_codon_count_package(    @seqs )
#     @count_sets = seq_codon_count_package_20( @seqs )
#
#  Count-label pairs:  [ $counts, $label ]
#
#     @labeled_cnts = entry_labeled_codon_count_package(    @seq_entrys )
#     @labeled_cnts = entry_labeled_codon_count_package_20( @seq_entrys )
#
#  Count the total codons in a gene.
#
#     $n_codon = n_codon( $counts )         # packaged counts
#     $n_codon = n_codon( $labeled_cnts )   # labeled counts
#     $n_codon = n_codon( $countH )         # count hash
#
#  Sum multiple sets of counts:
#
#     $total_counts = sum_counts(  @count_sets )
#     $total_counts = sum_counts( \@count_sets )
#
#     $total_countH = sum_counts(  @countH )
#     $total_countH = sum_counts( \@countH )
#
#  Get codon usage counts for genes from a count file
#
#     @cnts = labeled_counts_from_file( $file, \%opts )
#    \@cnts = labeled_counts_from_file( $file, \%opts )
#     @cnts = labeled_counts_from_file(  \*FH, \%opts )
#    \@cnts = labeled_counts_from_file(  \*FH, \%opts )
#     @cnts = labeled_counts_from_file(        \%opts )  # $opts{cntfile} || STDIN
#    \@cnts = labeled_counts_from_file(        \%opts )  # $opts{cntfile} || STDIN
#
#  Get codon usage counts for coding sequences in a fasta file
#
#     @cnts = labeled_counts_from_ffn( $file, \%opts )
#    \@cnts = labeled_counts_from_ffn( $file, \%opts )
#     @cnts = labeled_counts_from_ffn(  \*FH, \%opts )
#    \@cnts = labeled_counts_from_ffn(  \*FH, \%opts )
#     @cnts = labeled_counts_from_ffn(        \%opts )  # $opts{ffn} || STDIN
#    \@cnts = labeled_counts_from_ffn(        \%opts )  # $opts{ffn} || STDIN
#
#  Get codon usage counts for genes from the sapling server.
#  Requires SAPserver.pm, or a SAPserver object.
#
#     @cnts = labeled_counts_from_sapling( $gid, \%opts )
#    \@cnts = labeled_counts_from_sapling( $gid, \%opts )
#
#  Get codon usage counts for genes from the KBase server
#  Requires Bio::KBase.pm, or a Bio::KBase::CDMI::Client object.
#
#     @cnts = labeled_counts_from_kbase( $gid, \%opts )
#    \@cnts = labeled_counts_from_kbase( $gid, \%opts )
#
#  Get codon usage counts for genes from the a local SEED
#  Requires FIG.pm, or a FIG object.
#
#     @cnts = labeled_counts_from_seed( $gid, \%opts )
#    \@cnts = labeled_counts_from_seed( $gid, \%opts )
#
#  Get codon usage counts for genes from the sapling server.
#  Requires SAPserver.pm, or a SAPserver object.
#
#     @cnts = labeled_counts_from_sapling( $gid, \%opts )
#    \@cnts = labeled_counts_from_sapling( $gid, \%opts )
#
#  Get codon usage counts for genes from the KBase server
#  Requires Bio::KBase.pm, or a Bio::KBase::CDMI::Client object.
#
#     @cnts = labeled_counts_from_kbase( $gid, \%opts )
#    \@cnts = labeled_counts_from_kbase( $gid, \%opts )
#
#  Get codon usage counts for genes from the a local SEED
#  Requires FIG.pm, or a FIG object.
#
#     @cnts = labeled_counts_from_seed( $gid, \%opts )
#    \@cnts = labeled_counts_from_seed( $gid, \%opts )
#
#  Print counts:
#     One space between synonymous codons, two spaces between amino acids
#     Counts can be followed by a tab and a label.
#
#     report_counts(       $cnts )
#     report_counts(       $cnts, $label )
#     report_counts( \*FH, $cnts )
#     report_counts( \*FH, $cnts, $label )
#
#-------------------------------------------------------------------------------
#  Functions that deal with codon usage frequencies.
#-------------------------------------------------------------------------------
#  Codon usage frequencies (always 18 amino acids):
#
#     $freq = count_to_freq( $counts )
#     $freq = count_to_freq( $counts, $pseudocount )
#     $freq = count_to_freq( $countH )
#     $freq = count_to_freq( $countH, $pseudocount )
#
#     $freq = average_freq( \@count_sets )
#     $freq = average_freq( \@count_sets, $pseudocount )
#     $freq = average_freq( \@count_hashes )
#     $freq = average_freq( \@count_hashes, $pseudocount )
#
#  Set the minimum codon usage frequencies value in a set of frequencies.
#  (avoid those divide by zero errors):
#
#     $freq = set_minimum_frequency( $freq, $min_codon_frequency )
#
#-------------------------------------------------------------------------------
#  Parsing and formatting frequencies data.
#
#  Formatted frequencies data:
#     Comma between synonymous codons, and vertical bar between amino acids.
#     Frequencies can be preceded by a numeric score and tab.
#     Frequencies can be followed by a tab and text label.
#-------------------------------------------------------------------------------
#  Basic splitting:
#
#     $freq                 = split_frequencies( $codon_freq_string )
#   ( $freq, $scr, $label ) = split_frequencies( $codon_freq_string )
#
#  Convert text frequencies to a 4 or 5 part structure by further splitting
#  the label. The score, if present, is discarded.
#
#  [ $gid, $gdesc, $type,              $freq ] = structure_freq_text_4( $freq_text_line );
#  [ $gid, $gdesc, $stdtype, $subtype, $freq ] = structure_freq_text_5( $freq_text_line );
#
#      $gid     is the first word in the codon frequencies description
#      $gdesc   is the rest of the description, up to a ' -- ' delimiter
#      $type    is the text after a ' -- ' delimiter, if present
#      $stdtype is is a fixed vocabulary codon usage type
#      $subtype is a possible qualifier of the type
#
#  Current types are:
#
#      average
#      high_expr  (*)
#      modal
#      nonnative  (*)
#
#  The types followed by (*) can include a subtype (generally related to the
#  iterations in their calculation).
#
#  Format frequencies data:
#
#     $codon_freq_string = frequencies_as_string( $freq )
#
#  Print frequencies. $score and $label are both optional.
#
#     report_frequencies(               $freq, $label )
#     report_frequencies(       $score, $freq, $label )
#     report_frequencies( \*FH,         $freq, $label )
#     report_frequencies( \*FH, $score, $freq, $label )
#
#  Read all frequencies from a file:
#
#     @freqs = read_frequencies( )        # D = STDIN
#    \@freqs = read_frequencies( )        # D = STDIN
#     @freqs = read_frequencies( $file )
#    \@freqs = read_frequencies( $file )
#     @freqs = read_frequencies( \*FH )
#    \@freqs = read_frequencies( \*FH )
#
#  Read all frequencies with scores and labels from a file:
#
#     @freq_scr_lbl = read_frequencies_scr_label( )        # D = STDIN
#    \@freq_scr_lbl = read_frequencies_scr_label( )        # D = STDIN
#     @freq_scr_lbl = read_frequencies_scr_label( $file )
#    \@freq_scr_lbl = read_frequencies_scr_label( $file )
#     @freq_scr_lbl = read_frequencies_scr_label( \*FH )
#    \@freq_scr_lbl = read_frequencies_scr_label( \*FH )
#
#  Read one set of frequencies from an open file handle:
#
#    $freq                 = read_next_frequencies( )       # D = STDIN
#  ( $freq, $scr, $descr ) = read_next_frequencies( )       # D = STDIN
#    $freq                 = read_next_frequencies( \*FH )
#  ( $freq, $scr, $descr ) = read_next_frequencies( \*FH )
#
#-------------------------------------------------------------------------------
#  Raw codon usages are typed codon usages, intended for a robust exchange.
#  Current type / subtype combinations are:
#  -------------------------------------------------------------------------
#  Type          Subtype   Description
#  -------------------------------------------------------------------------
#  average                 average codon usage of genome
#  modal                   modal codon usage of genome
#  high_expr        0      modal codon usage of candidate highly expressed genes
#  high_expr        1      modal codon usage of candidate highly expressed genes
#                               differing from mode
#  high_expr        2      iterated modal codon usage of candidate highly
#                               expressed genes differing from mode
#  nonnative               modal codon usage of nonnative genes
#  -------------------------------------------------------------------------
#  Anticipated types
#  -------------------------------------------------------------------------
#  genome                  modal codon usage of genome (=modal)
#  genome_avg              average codon usage of genome (=average)
#  genome_mode             modal codon usage of genome (=modal)
#  high_expr               modal codon usage of candidate highly expressed genes
#  high_expr_avg           average codon usage of candidate highly expressed genes
#  high_expr_mode          modal codon usage of candidate highly expressed genes
#  mito                    modal codon usage of mitochondrial genes
#  mito_avg                average codon usage of mitochondrial genes
#  mito_mode               modal codon usage of mitochondrial genes
#  nonnative               modal codon usage of nonnative genes (=nonnative)
#  nonnative_avg           average codon usage nonnative genes
#  nonnative_mode          modal codon usage of nonnative genes (=nonnative)
#  plasmid         id      modal codon usage of plasmid genes (with optional plasmid id)
#  plasmid_avg     id      average codon usage of plasmid genes (with optional plasmid id)
#  plasmid_mode    id      modal codon usage of plasmid genes (with optional plasmid id)
#  plastid                 modal codon usage of plastid genes
#  plastid_avg             average codon usage of plastid genes
#  plastid_mode            modal codon usage of plastid genes
#  prophage        id      modal codon usage of prophage genes (with optional prophage id)
#  prophage_avg    id      average codon usage of prophage genes (with optional prophage id)
#  prophage_mode   id      modal codon usage of prophage genes (with optional prophage id)
#  region          id      modal codon usage of gene region (with optional region id)
#  region_avg      id      average codon usage of gene region (with optional region id)
#  region_mode     id      modal codon usage of gene region (with optional region id)
#  shared                  modal codon usage for core genes of species
#  shared_avg              average codon usage of core genes of species
#  shared_mode             modal codon usage for core genes of species
#  unique                  modal codon usage for strain-specific genes of species
#  unique_avg              average codon usage of strain-specific genes of species
#  unique_mode             modal codon usage for strain-specific genes of species
#-------------------------------------------------------------------------------
#
#  Raw codon usages file format (file extension .rawcu)
#
#      "$freqstr\t$gencode\t$gid\t$type\t$subtype\t$gname\n"
#
#  Read and write raw usages:
#
#       @usages = read_genome_codon_usages( $file )
#      \@usages = read_genome_codon_usages( $file )
#       @usages = read_genome_codon_usages( )          # STDIN
#      \@usages = read_genome_codon_usages( )          # STDIN
#
#      $n_written = write_genome_codon_usages( $file,  @usages )
#      $n_written = write_genome_codon_usages( $file, \@usages )
#      $n_written = write_genome_codon_usages(         @usages )   # STDOUT
#      $n_written = write_genome_codon_usages(        \@usages )   # STDOUT
#
#  $file can be a filename, a filehandle, a string reference, '', or undef
#
#  @usages = ( [ $gid, $gname, $type, $subtype, $freqs, $gencode ], ... )
#
#-------------------------------------------------------------------------------
#  Evaluating counts versus frequencies.
#-------------------------------------------------------------------------------
#  Evaluating one set of counts versus frequencies:
#
#    @chisqr_df_n       = codon_usage_chi_sqr( $freqH, @count_hashes )
#
#  ( $chisqr, $df, $n ) = count_vs_count_chi_sqr( $cnt_1,    $cnt_2 )
#  ( $chisqr, $df, $n ) = count_vs_count_chi_sqr( $countH_1, $countH_2 )
#
#  ( $chisqr, $df, $n ) = count_vs_freq_chi_sqr( $cnts,   $freq )
#  ( $chisqr, $df, $n ) = count_vs_freq_chi_sqr( $countH, $freq )
#
#    $p_value = count_vs_freq_p_value( $cnts, $freq, $max_len )
#
#    @scores = codon_usage_p_values( $cnts, \@freq_sets )
#    @scores = codon_usage_p_values( $cnts, \@freq_sets, $max_len )
#
#  Function that evaluates the total score for counts of multiple genes against
#  a single set of frequencies.  Do it entirely in perl:
#
#    $score = codon_freq_score( $freq, \@cnt_sets, \%options )
#    $score = codon_freq_score( $freq, \%cnt_sets, \%options )
#
#    $score = codon_freq_score_0( $freq, \@cnt_sets, $p_val, $expon, $max_l )
#
#  Evaluate mulitple sets of frequencies using an external evalution process.
#  Counts can be in file, arg list, or options.
#
#    @scored_freqs = score_codon_frequencies( \@freq_sets, \@cnt_sets, \%options )
#   \@scored_freqs = score_codon_frequencies( \@freq_sets, \@cnt_sets, \%options )
#    @scored_freqs = score_codon_frequencies( \@freq_sets,             \%options )
#   \@scored_freqs = score_codon_frequencies( \@freq_sets,             \%options )
#
# Other functions:
#
#    @aa_cnt_sets        = codon_counts_2_aa_counts( @codon_cnt_sets )
#
#    @sim_codon_cnt_sets = simulate_genome( $codon_freqs, @aa_cnt_sets )
#
#-------------------------------------------------------------------------------
# Modal codon usage.
#-------------------------------------------------------------------------------
#            \@modal_freqs   = modal_codon_usage( \@cnt_sets, \%options )
#  ( $score, \@modal_freqs ) = modal_codon_usage( \@cnt_sets, \%options )
#
#-------------------------------------------------------------------------------
# Distances between codon usage frequencies.
#-------------------------------------------------------------------------------
#   $distance = codon_freq_distance(   $freq1, $freq2, $type )   # D = type 2
#   $distance = codon_freq_distance_1( $freq1, $freq2 )  # Euclidian over all codons
#   $distance = codon_freq_distance_2( $freq1, $freq2 )  # Manhattan within aa, and Euclidian over aas (recommended)
#   $distance = codon_freq_distance_3( $freq1, $freq2 )  # Manhattan over all codons
#
#-------------------------------------------------------------------------------
# Functions that deal with codon usage lines (linear).
#-------------------------------------------------------------------------------
# Project a codong usage point on straight line passing through freq_0 and
# freq_1.  The projection is Euclidian.  Projections beyond these points may
# be limited by a frequency going less than 0 or greatter than 1.
#
#   @projections = project_on_freq_vector_by_dist( \@freq_0, \@freq_1,   \@freq1, \@freq2, ...   )
#   @projections = project_on_freq_vector_by_dist( \@freq_0, \@freq_1, [ \@freq1, \@freq2, ... ] )
#               # each projection is [ $position, $distance_from_axis ]
#
# Project on straight line passing through freq_0 and freq_1.  The projection
# is on the point that minimizes the resulting chi-square.  Projections
# beyond these points may be limited by a frequency going less than 0 or
# greatter than 1.
#
#   @projections = project_on_freq_vector_by_chi_sqr( \@freq_0, \@freq_1,   \@cnts1, \@cnts2, ...   )
#   @projections = project_on_freq_vector_by_chi_sqr( \@freq_0, \@freq_1, [ \@cnts1, \@cnts2, ... ] )
#               # each projection is [ $position, $chi_sqr, $df, $ncodon ]
#
#-------------------------------------------------------------------------------
# Functions that deal with codon usage axes (as in Kloster and Tang 2008,
# and Davis and Olsen 2010).
#-------------------------------------------------------------------------------
# Project frequencies on an axis passing through freq_0 and freq_1.  The
# projection is to the point on the line that minimizes the resulting
# distance. The line is not straight; as the projection coordinate goes
# to minus or plus infinity, frequencies remain between 0 and 1.
#
#     @projections = project_freq_on_axis_by_dist( \@freq_0, \@freq_1,   \@freq1, \@freq2, ...   )
#     @projections = project_freq_on_axis_by_dist( \@freq_0, \@freq_1, [ \@freq1, \@freq2, ... ] )
#
# Each projection is:
#
#     [ $pos_along_axis, $dist_from_axis, $freq_at_pos ]
#
# Project codon counts on an axis passing through freq_0 and freq_1.  The
# projection is to the point on the line that minimizes the resulting
# chi-square. The line is not straight; as the projection coordinate goes
# to minus or plus infinity, frequencies remain between 0 and 1.
#
#   @projections = project_on_axis_by_chi_sqr( \@freq_0, \@freq_1,   \@cnts1, \@cnts2, ...   )
#   @projections = project_on_axis_by_chi_sqr( \@freq_0, \@freq_1, [ \@cnts1, \@cnts2, ... ] )
#
# Each projection is:
#
#     [ $pos_along_axis, $chi_sqr, $df, $ncodon ]
#
#-------------------------------------------------------------------------------
# Evaluate codon usages in terms of p-value of chi square match to an axis.
#
#   @x_p = codon_counts_x_and_p( $f0, $f1, \%opts,   $cnt, $cnt, ... );
#  \@x_p = codon_counts_x_and_p( $f0, $f1, \%opts,   $cnt, $cnt, ... );
#   @x_p = codon_counts_x_and_p( $f0, $f1, \%opts, \@$cnts );
#  \@x_p = codon_counts_x_and_p( $f0, $f1, \%opts, \@$cnts );
#
#-------------------------------------------------------------------------------
#  If two sets of frequencies were drawn from the same distribution, what would
#  be the expected distance between them?  Found by analysis of random suffles
#  of the members between the two input sets.
#
#      $distance            = null_distance( \@cnt1, \@cnt2, \%options )
#    ( $distance, $stddev ) = null_distance( \@cnt1, \@cnt2, \%options )
#
#===============================================================================
#  Some earlier routines:
#
#  \@freqs             = packaged_count_to_freq( \@counts [, $pseudocount ] )
#  \@total_counts      = sum_packaged_counts( \@per_gene_pakaged_counts )
# ( $chisqr, $df, $n ) = codon_usage_pairwise_chi_sqr( \%cnt1, \%cnt2 )
# ( $chisqr, $df, $n ) = count_package_chi_sqr( \@cnt_pkg1, \@cnt_pkg2 )
# ( $chisqr, $df, $n ) = packaged_codon_usage_chi_sqr( \@freqs, \@cnt )
#
#   @projections = project_on_freq_vector_by_chi_sqr_2( \@freq_0, \@freq_1,   \@cnts1, \@cnts2, ...   )
#   @projections = project_on_freq_vector_by_chi_sqr_2( \@freq_0, \@freq_1, [ \@cnts1, \@cnts2, ... ] )
#
#===============================================================================

use strict;
use Carp qw( croak );
use Data::Dumper;

use IPC::Open2 qw( open2 );

use SeedAware  qw(
        executable_for
        location_of_tmp
        open_tmp_file
        run_gathering_output
        );

use gjoseqlib qw(
        to_DNA_seq
        pack_seq
        @aa_n_codon_order
        %genetic_code
        %n_codon_for_aa
        %amino_acid_codons_DNA
        );

use gjostat qw(
        chi_square
        contingency_chi_sqr_2
        );

#  Functions used for simulating codon usage.  If is loaded only if needed.
#
# use gjosegmentlib qw(
#        segment_new_tree
#        segment_by_coord
#        );

our @aa_package_order    = qw( A C D E F G H I K L N P Q R S T V Y );
our @aa_package_order_20 = qw( A C D E F G H I K L N P Q R S T V Y M W );
our @aa_order            = @aa_package_order_20;

our @codon_order_64 = map { @{ $gjoseqlib::amino_acid_codons_DNA{ $_ } } } @aa_order, '*';
our @codon_order_61 = @codon_order_64[ 0 .. 60 ];
our @codon_order_59 = @codon_order_64[ 0 .. 58 ];
our @codon_order    = @codon_order_64;

our @codon_packages_20 = map { $gjoseqlib::amino_acid_codons_DNA{ $_ } } @aa_order;
our @codon_packages_18 = @codon_packages_20[ 0 .. 17 ];
our @codon_packages    = @codon_packages_20;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
        entry_codon_count
        seq_codon_count
        codon_count_list

        codon_count_package
        codon_count_package_20
        entry_codon_count_package
        entry_codon_count_package_20
        seq_codon_count_package
        seq_codon_count_package_20

        entry_labeled_codon_count_package
        entry_labeled_codon_count_package_20

        labeled_counts_from_file
        labeled_counts_from_ffn
        labeled_counts_from_sapling
        labeled_counts_from_kbase
        labeled_counts_from_seed

        report_counts
        split_counts
        
        n_codon
        sum_counts

        count_vs_count_chi_sqr
        count_vs_freq_chi_sqr
        count_vs_freq_p_value
        codon_usage_chi_sqr
        count_to_freq
        average_freq
        codon_usage_p_values
        report_frequencies
        frequencies_as_string
        split_frequencies
        codon_counts_2_aa_counts
        simulate_genome

        read_genome_codon_usages
        write_genome_codon_usages

        genome_axes_from_usages

        modal_codon_usage
        score_codon_frequencies
        codon_freq_score
        codon_freq_score_0

        codon_freq_distance
        codon_freq_distance_1
        codon_freq_distance_2
        codon_freq_distance_3

        project_on_freq_vector_by_dist
        project_on_freq_vector_by_chi_sqr

        project_freq_on_axis_by_dist
        project_on_axis_by_chi_sqr
        codon_counts_x_and_p

        null_distance

        packaged_count_to_freq
        sum_packaged_counts
        codon_usage_pairwise_chi_sqr
        count_package_chi_sqr
        packaged_codon_usage_chi_sqr
        project_on_freq_vector_by_chi_sqr_2
        );

our @EXPORT_OK = qw(
        @aa_package_order
        @aa_package_order_20
        @aa_order
        @codon_order_64
        @codon_order_61
        @codon_order_59
        @codon_order
        );


#===============================================================================
#  Codon usage counts routines
#===============================================================================
#  Compile codon usage of one or more sequence entries.  Skip initiator, and
#  the last codon, if it is a terminator.  If the routine is passed a hash,
#  add to it.  If it is not, create a new hash.  This is cumulative over
#  the entries (not per entry counts).
#
#     \%counts = entry_codon_count( [ \%counts, ] @seq_entrys )
#
#-----------------------------------------------------------------------------
sub entry_codon_count
{
    my $cnt = ( ref( $_[0] ) eq 'HASH' ) ? shift : {};
    my $seq;

    foreach ( @_ ) {
        ( ref( $_ ) eq 'ARRAY' ) && defined( $seq = $_->[2] ) || next;
        seq_codon_count( $cnt, $seq );
    }

    return $cnt;
}


#-----------------------------------------------------------------------------
#  Compile codon usage for a sequence.  Skip initiator, and the last codon
#  if it is a terminator.  If the routine is passed a hash, add to it.
#  Otherwise, create a new hash.
#
#     \%counts = seq_codon_count( [ \%counts, ] $sequence )
#
#-----------------------------------------------------------------------------
sub seq_codon_count
{
    my $cnt = ( ref( $_[0] ) eq 'HASH' ) ? shift : {};

    my $seq = shift;
    return $cnt if ( ! $seq ) || ( length( $seq ) < 6 );

    #  Pack, convert to upper case, convert U to T, split into triplets,
    #  dump first triple, filter for unambiguous

    $seq = uc pack_seq( $seq );
    $seq =~ tr/U/T/;
    my @codons = ( $seq =~ m/(...)/g );
    return $cnt if @codons < 2;

    shift @codons;  # initiator
    @codons = grep { /^[ACGT][ACGT][ACGT]$/ } @codons;
    return $cnt if ! @codons;

    #  Dump last codon if terminator:

    pop @codons if ( $genetic_code{ $codons[ -1 ] } eq "*" );

    #  Compile the codons:

    foreach ( @codons ) { $cnt->{ $_ }++ }

    return $cnt;
}


#-----------------------------------------------------------------------------
#  Make lists in order of codons per amino acid:
#

@codon_order = map { @{ $amino_acid_codons_DNA{ $_ } } } @aa_order;

#-----------------------------------------------------------------------------
#  Convert a codon count in a hash to a list in standard order.
#
#     @counts = codon_count_list( \%counts [,  @order ] )
#     @counts = codon_count_list( \%counts [, \@order ] )
#
#-----------------------------------------------------------------------------
sub codon_count_list
{
    ( ref( $_[0] ) eq 'HASH' ) || return undef;
    my $hash = shift;
    if ( ( @_ == 1 ) && ref( $_[0] ) eq 'ARRAY' ) { @_ = @{ $_[0] } }
    if   ( @_ <  2 )                              { @_ = @codon_order }

    map { defined( $hash->{ $_ } ) ? $hash->{ $_ } : 0 } @_;
}


#-----------------------------------------------------------------------------
#  Convert a codon count hash to a list of counts bundled by amino acid.
#  In the first form, M and W are skipped; in the second form they are included.
#
#     \@counts = codon_count_package( \%counts )
#     \@counts = codon_count_package_20( \%counts )
#
#  \@counts = [ [ n(GCA), n(GCG), n(GCT), n(GCC) ], # A
#               [ n(TGT), n(TGC) ],                 # C
#               [ n(GAT), n(GAC) ],                 # D
#               .
#               .
#               .
#               [ n(TAT), n(TAC) ]                  # Y
#             ];
#
#  or
#
#  \@counts = [ [ n(GCA), n(GCG), n(GCT), n(GCC) ], # A
#               [ n(TGT), n(TGC) ],                 # C
#               [ n(GAT), n(GAC) ],                 # D
#               .
#               .
#               .
#               [ n(TAT), n(TAC) ]                  # Y
#               [ n(ATG) ]                          # M
#               [ n(TGA) ]                          # W
#             ];
#-----------------------------------------------------------------------------
sub codon_count_package
{
    my $cnts = shift;
    ref( $cnts ) eq 'HASH' or return undef;

    [ map { [ map { $cnts->{ $_ } || 0                  # map codon to counts
                  } @{ $amino_acid_codons_DNA{ $_ } }   # for each codon
            ]
          } @aa_package_order   # for 18 amino acids
    ]
}


sub codon_count_package_20
{
    my $cnts = shift;
    ref( $cnts ) eq 'HASH' or return undef;

    [ map { [ map { $cnts->{ $_ } || 0                  # map codon to counts
                  } @{ $amino_acid_codons_DNA{ $_ } }   # for each codon
            ]
          } @aa_package_order_20                        # for 20 amino acids
    ]
}


#-----------------------------------------------------------------------------
#  Compile and package codon usage of one or more sequence entries.
#  In the first form, M and W are skipped; in the second form they are included.
#
#     @count_sets = entry_codon_count_package( @seq_entrys )
#     @count_sets = entry_codon_count_package_20( @seq_entrys )
#
#-----------------------------------------------------------------------------
sub entry_codon_count_package
{
    map { ref $_ eq 'ARRAY' ? codon_count_package( seq_codon_count( $_->[2] ) ) : undef } @_;
}


sub entry_codon_count_package_20
{
    map { ref $_ eq 'ARRAY' ? codon_count_package_20( seq_codon_count( $_->[2] ) ) : undef } @_;
}


#-----------------------------------------------------------------------------
#  Compile and package codon usage of one or more sequences.
#  In the first form, M and W are skipped; in the second form they are included.
#
#     @count_sets = seq_codon_count_package( @seqs )
#     @count_sets = seq_codon_count_package_20( @seqs )
#
#-----------------------------------------------------------------------------
sub seq_codon_count_package
{
    map { codon_count_package( seq_codon_count( $_ ) ) } @_;
}


sub seq_codon_count_package_20
{
    map { codon_count_package_20( seq_codon_count( $_ ) ) } @_;
}


#-----------------------------------------------------------------------------
#  Compile and package codon usage of one or more sequence entries.
#  In the first form, M and W are skipped; in the second form they are included.
#
#     @labeled_count_sets = entry_labeled_codon_count_package( @seq_entrys )
#     @labeled_count_sets = entry_labeled_codon_count_package_20( @seq_entrys )
#
#  To make a hash of the counts:
#
#     %count_package = map { $_->[1] => $_->[0] } entry_labeled_codon_count_package( @seq_entrys );
#     %count_package = map { $_->[1] => $_->[0] } entry_labeled_codon_count_package_20( @seq_entrys );
#
#-----------------------------------------------------------------------------
sub entry_labeled_codon_count_package
{
    return map { [ seq_codon_count_package( $_->[2] ), $_->[1] ? "$_->[0] $_->[1]" : $_->[0] ] }
           grep { $_ && ref $_ eq 'ARRAY' }
           @_;
}


sub entry_labeled_codon_count_package_20
{
    return map { [ seq_codon_count_package_20( $_->[2] ), $_->[1] ? "$_->[0] $_->[1]" : $_->[0] ] }
           grep { $_ && ref $_ eq 'ARRAY' }
           @_;
}


#===============================================================================
#  Support for gathering information for display of codon usages in a genome.
#  Not everything is implemented.
#===============================================================================
#
#  Option keys:
#
#      axes    => \@axes          # [ [ f0, f1, label ], [ f0, f2, label ], ... ]
#      cntdir  =>  $countfiledir  # place to put count file
#      cntfile =>  $countfile     # path to file with cds counts
#      counts  => \@counts        # counts are cached in the options hash
#      expon   =>  $mode_exp      # exponent in match to mode calculation
#      ffn     =>  $ffnfile       # path to file with cds sequences
#      fig     =>  $FIGObject
#      freqs   => \@frequencies   # [ f0, f1, f2 ... ]
#      gid     =>  $genome_id
#      gname   =>  $genome_name
#      he2     =>  $bool          # require successful iteration of high expression for axis
#      labels  => \@freq_lbls     # [ 'mode', 'high expression', 'nonnative', ... ]
#      max_len =>  $max_length    # maximum length in P-value calculation
#      sap     =>  $saplingObject
#
#-------------------------------------------------------------------------------
#  Get codon usage counts for genes from a count file
#
#   @cnts = labeled_counts_from_file( $file, \%opts )
#  \@cnts = labeled_counts_from_file( $file, \%opts )
#   @cnts = labeled_counts_from_file(  \*FH, \%opts )
#  \@cnts = labeled_counts_from_file(  \*FH, \%opts )
#   @cnts = labeled_counts_from_file(        \%opts )  # $opts{cntfile} || STDIN
#  \@cnts = labeled_counts_from_file(        \%opts )  # $opts{cntfile} || STDIN
#
#  Options:
#
#    cntfile => $countfile  # Alternative to supplying the file name in arg list
#
#-------------------------------------------------------------------------------
sub labeled_counts_from_file
{
    my $opts = $_[ 0] && ref($_[ 0]) eq 'HASH' ? shift :
               $_[-1] && ref($_[-1]) eq 'HASH' ? pop   : {};

    my $cntfile = shift || ( $opts->{ cntfile } ||= $opts->{ countfile } );

    my @cnts;
    my ( $cntFH, $close ) = input_handle( $cntfile );
    if ( $cntFH )
    {
        @cnts = map { [ split_counts( $_ ) ] } <$cntFH>;
        close $cntFH if $close;
    }

    $opts->{ counts } = \@cnts;
    wantarray ? @cnts : \@cnts;
}


#-------------------------------------------------------------------------------
#  Get codon usage counts for genes from a sequence file
#
#   @cnts = labeled_counts_from_ffn( $file, \%opts )
#  \@cnts = labeled_counts_from_ffn( $file, \%opts )
#   @cnts = labeled_counts_from_ffn(  \*FH, \%opts )
#  \@cnts = labeled_counts_from_ffn(  \*FH, \%opts )
#   @cnts = labeled_counts_from_ffn(        \%opts )  # $opts{ffn} || STDIN
#  \@cnts = labeled_counts_from_ffn(        \%opts )  # $opts{ffn} || STDIN
#
#  Options:
#
#    ffn => $ffnfile  # Alternative to supplying the file name or
#                     #       file handle in the arg list
#
#-------------------------------------------------------------------------------
sub labeled_counts_from_ffn
{
    my $opts = $_[ 0] && ref($_[ 0]) eq 'HASH' ? shift :
               $_[-1] && ref($_[-1]) eq 'HASH' ? pop   : {};

    my $ffn = shift || $opts->{ ffn } || \*STDIN;

    my @seqs = gjoseqlib::read_fasta( $ffn );
    my @cnts = entry_labeled_codon_count_package( @seqs );

    $opts->{ dna }    = \@seqs;
    $opts->{ counts } = \@cnts;

    wantarray ? @cnts : \@cnts;
}


#-------------------------------------------------------------------------------
#  These access routings should not be usad. Go straight to SaplingCodonUsage.pm
#  Get codon usage counts for genes from the Sapling server.
#
#   @cnts = labeled_counts_from_sapling( $gid, \%opts )
#  \@cnts = labeled_counts_from_sapling( $gid, \%opts )
#
#  Get coding sequences from the Sapling server.
#
#   @seqs = coding_sequences_from_sapling( $gid, \%opts )
#  \@seqs = coding_sequences_from_sapling( $gid, \%opts )
#
#  Options:
#
#    gid => $gid        # Alternative to supplying the gid in arg list
#    sap => $SAPserver  # Supply the server object
#
#-------------------------------------------------------------------------------
sub labeled_counts_from_sapling
{
    eval { require SaplingCodonUsage; } ? SaplingCodonUsage::labeled_counts( @_ )
                                        : wantarray ? () : [];
}


sub coding_sequences_from_sapling
{
    eval { require SaplingCodonUsage; } ? SaplingCodonUsage::coding_sequences( @_ )
                                        : wantarray ? () : [];
}


#-------------------------------------------------------------------------------
#  These access routings should not be usad. Go straight to KBaseCodonUsage.pm
#  Get codon usage counts for genes from the KBase server.
#
#   @cnts = labeled_counts_from_kbase( $gid, \%opts )
#  \@cnts = labeled_counts_from_kbase( $gid, \%opts )
#
#  Get coding sequences from the KBase server.
#
#   @seqs = coding_sequences_from_kbase( $gid, \%opts )
#  \@seqs = coding_sequences_from_kbase( $gid, \%opts )
#
#  Options:
#
#    gid   => $gid          # Alternative to supplying the gid in arg list
#    kbase => $KBaseClient  # Supply the client object
#
#-------------------------------------------------------------------------------
sub labeled_counts_from_kbase
{
    eval { require KBaseCodonUsage; } ? KBaseCodonUsage::labeled_counts( @_ )
                                      : wantarray ? () : [];
}


sub coding_sequences_from_kbase
{
    eval { require KBaseCodonUsage; } ? KBaseCodonUsage::coding_sequences( @_ )
                                      : wantarray ? () : [];
}


#-------------------------------------------------------------------------------
#  These access routings should not be usad. Go straight to SeedCodonUsage.pm
#  Get codon usage counts for genes from the a local SEED.
#
#   @cnts = labeled_counts_from_seed( $gid, \%opts )
#  \@cnts = labeled_counts_from_seed( $gid, \%opts )
#
#  Get coding sequences from the local SEED.
#
#   @seqs = coding_sequences_from_seed( $gid, \%opts )
#  \@seqs = coding_sequences_from_seed( $gid, \%opts )
#
#  Options:
#
#    fig => $figObject  # This will be used if set
#    gid => $gid        # Alternative to supplying the gid in arg list
#
#-------------------------------------------------------------------------------
sub labeled_counts_from_seed
{
    eval { require SeedCodonUsage; } ? SeedCodonUsage::labeled_counts( @_ )
                                     : wantarray ? () : [];
}


sub coding_sequences_from_seed
{
    eval { require SeedCodonUsage; } ? SeedCodonUsage::coding_sequences( @_ )
                                     : wantarray ? () : [];
}


#-----------------------------------------------------------------------------
#  Format counts with amino acids separated by 2 spaces, and codons within the
#  amino acid separated by 1 space.  If an id is present, it is separated by a
#  tab.
#
#  naa1c1 naa1c2 naa1c3 naa1c4  naa2c1 naa2c2 ...  naa3c1 naa3c2 ...
#
#     report_counts(       $cnts )
#     report_counts(       $labeled_cnts )
#     report_counts(       $cnts, $label )
#     report_counts( \*FH, $cnts )
#     report_counts( \*FH, $labeled_cnts )
#     report_counts( \*FH, $cnts, $label )
#
#-----------------------------------------------------------------------------
sub report_counts
{
    my $fh = ( ref( $_[0] ) eq 'GLOB' ) ? shift : \*STDOUT;
    my ( $cnts, $label ) = @_;
    $cnts && ref( $cnts ) eq 'ARRAY' or return;
    if ( @$cnts == 2 )
    {
        $label = $cnts->[1] unless defined $label;
        $cnts  = $cnts->[0];
    }

    print $fh join( '  ', map { join( ' ', map { $_ || 0 } @$_ ) } @$cnts ),
              ( defined $label ? "\t$label" : () ),
              "\n";
}


#-----------------------------------------------------------------------------
#  Split counts with amino acids separated by 2 spaces, and codons within the
#  amino acid separated by 1 space.  If an id is present, it is separated by a
#  tab.
#
#       \@counts           = split_counts( $codon_count_string )
#     ( \@counts, $label ) = split_counts( $codon_count_string )
#
#-----------------------------------------------------------------------------
sub split_counts
{   my ( $string ) = shift;
    chomp $string;
    my ( $data, $label ) = split /\t/, $string;

    my $cnts = [ map { [ map { $_ + 0 } split / / ] } split /  /, $data ];

    wantarray ? ( $cnts, $label ) : $cnts;
}


#-----------------------------------------------------------------------------
#  Count the total codons in a gene.
#
#     $n_codon = n_codon(   \@counts )
#     $n_codon = n_codon( [ \@counts, $id ] )
#     $n_codon = n_codon(   \%counts )
#
#-----------------------------------------------------------------------------
sub n_codon
{
    my $cnts = shift;
    $cnts = codon_count_package( $cnts ) if ( ref $cnts eq 'HASH' );  # Form 3
    return undef if ( ref $cnts ne 'ARRAY' );
    $cnts = $cnts->[0] if ( ! ref $cnts->[1] );                       # Form 2
    my $n = 0; foreach ( @$cnts ) { foreach ( @$_ ) { $n += $_ } }

    $n;
}


#-----------------------------------------------------------------------------
#  Sum codon counts across genes.
#
#     \@total_counts = sum_counts( \@per_gene_count_arrays )
#     \@total_counts = sum_counts( \@gene_1_counts, \@gene_2_counts, ... )
#
#     \%total_counts = sum_counts( \@per_gene_count_hashes )
#     \%total_counts = sum_counts( \%gene_1_counts, \%gene_2_counts, ... )
#
#-----------------------------------------------------------------------------
sub sum_counts
{
    return undef unless @_;

    #  Are counts in arrays?

    if ( ref $_[0] eq 'ARRAY' && ref $_[0]->[0] eq 'ARRAY' )
    {
        my @ttl_cnt;
        foreach my $gene_data ( ref $_[0]->[0]->[0] eq 'ARRAY' ? @{$_[0]} : @_ )
        {
            my $i = 0;
            foreach my $gene_aa_data ( @$gene_data )
            {
                my $ttl_aa_cnts = $ttl_cnt[ $i++ ] ||= [ (0) x @$gene_aa_data ];
                my $j = 0;
                foreach my $gene_codon_cnt ( @$gene_aa_data )
                {
                    $ttl_aa_cnts->[ $j++ ] += $gene_codon_cnt;
                }
            }
        }
        return \@ttl_cnt;
    }

    #  Are counts in hash?

    if ( ref $_[0] eq 'HASH' || ref $_[0]->[0] eq 'HASH' )
    {
        my %ttl_cnt;
        foreach my $gene_data ( ref $_[0] eq 'HASH' ? $_ : @{$_[0]} )
        {
            foreach ( keys %$gene_data ) { $ttl_cnt{ $_ } += $gene_data->{ $_ } }
        }
        return \%ttl_cnt;
    }

    #  I don't understand args

    return undef;
}


#-----------------------------------------------------------------------------
#---------------------------- Use sum_counts() -------------------------------
#-----------------------------------------------------------------------------
#  Sum codon counts across genes.  Handles any nested arrays of counts.
#
#     \@total_counts = sum_packaged_counts( \@per_gene_pakaged_counts )
#
#-----------------------------------------------------------------------------
sub sum_packaged_counts
{
    my $gene_counts = shift;
    ref( $gene_counts ) eq 'ARRAY'                     # array of genes
        and ref( $gene_counts->[0] ) eq 'ARRAY'        # array of amino acids
        and ref( $gene_counts->[0]->[0] ) eq 'ARRAY'   # array of codons
        or return undef;

    my @ttl_cnt;
    my $gene_data;
    foreach $gene_data ( @$gene_counts )
    {
        my $i = 0;
        my $gene_aa_data;
        foreach $gene_aa_data ( @$gene_data )
        {
             my $ttl_aa_cnts = $ttl_cnt[ $i++ ] ||= [];
             my $j = 0;
             my $gene_codon_cnt;
             foreach $gene_codon_cnt ( @$gene_aa_data )
             {
                 $ttl_aa_cnts->[ $j++ ] += $gene_codon_cnt;
             }
        }
    }

    \@ttl_cnt;
}


#===============================================================================
#  Codon usage frequencies routines
#===============================================================================
#  Convert counts to packaged frequencies.  
#  Optionally add a pseudocount (e.g., 1) to each group.
#  The number of amino acids is trimmed to 18.
#
#     $freqs = count_to_freq( $counts [, $pseudocount ] )
#     $freqs = count_to_freq( $countH [, $pseudocount ] )
#
#        \@counts = [ [ n1, n2, n3, n4 ], [ n5, n6 ], ... [ nn1, nn2 ] ]
#        \%counts = { codon => count, ... }
#        \@freqs  = [ [ f1, f2, f3, f4 ], [ nf, f6 ], ... [ fn1, fn2 ] ]
#-----------------------------------------------------------------------------
sub count_to_freq
{
    my ( $cnts, $pseudocnt ) = @_;
    $cnts or return undef;
    $cnts = codon_count_package( $cnts ) if ref $cnts eq 'HASH';
    ref $cnts eq 'ARRAY' && @$cnts >= 18 or return undef;
    $pseudocnt ||= 0;

    [ map { my $n = $pseudocnt;
            foreach ( @$_ ) { $n += $_ }          # total count in group
            $n ||= 1;                             #   or 1
            my $pci = @$_ ? $pseudocnt / @$_ : 0; # and per element pseudocount
            [ map { ( $_ + $pci ) / $n } @$_ ]    # used to make frequencies
          }
      @$cnts[ 0 .. 17 ]                           # for each group of counts
    ]
}


#-----------------------------------------------------------------------------
#--------------------------- Use count_to_freq() -----------------------------
#-----------------------------------------------------------------------------
#
#  Convert packaged counts to packaged frequencies.
#  Optionally add a pseudocount (e.g., 1) to each amino acid.
#  The number of amino acids is trimmed to 18.
#
#     \@freqs = packaged_count_to_freq( \@counts [, $pseudocount ] )
#
#     \@counts = [ [ n1, n2, n3, n4 ], [ n5, n6 ], ... [ nn1, nn2 ] ];
#     \@freqs  = [ [ f1, f2, f3, f4 ], [ nf, f6 ], ... [ fn1, fn2 ] ];
#-----------------------------------------------------------------------------
sub packaged_count_to_freq
{
    my ( $cnts, $pseudocnt ) = @_;
    ref( $cnts ) eq 'ARRAY' or return undef;
    $pseudocnt ||= 0;

    [ map { my $n = $pseudocnt;
            foreach ( @$_ ) { $n += $_ }          # total count in group
            $n ||= 1;                             #   or 1
            my $pci = @$_ ? $pseudocnt / @$_ : 0; # and per element pseudocount
            [ map { ( $_ + $pci ) / $n } @$_ ]    # used to make frequencies
          } @$cnts[ 0 .. 17 ]                     # for each group of counts
    ]
}


#-----------------------------------------------------------------------------
#  Sum codon counts and find average codon usage frequencies.
#
#     \@freqs = average_freq( [ \@counts, ... ] )
#     \@freqs = average_freq( [ \@counts, ... ], $pseudocount )
#     \@freqs = average_freq( [ \%counts, ... ] )
#     \@freqs = average_freq( [ \%counts, ... ], $pseudocount )
#
#-----------------------------------------------------------------------------
sub average_freq
{
    my ( $cnts_sets, $pseudocnt ) = @_;
    return undef unless $cnts_sets && ref $cnts_sets  eq 'ARRAY' && @$cnts_sets;

    my $sum = sum_counts( $cnts_sets );
    $sum ? count_to_freq( $sum, $pseudocnt ) : undef;
}


#-----------------------------------------------------------------------------
#  Split frequencies with amino acids separated by vertical bars, and
#  codons within the amino acid separated by commas:
#
#  faa1c1,faa1c2,faa1c3,faa1c4|faa2c1,faa2c2,...|faa3c1,faa3c2,...
#
#      \@freqs                         = split_frequencies( $codon_freq_string )
#    ( \@freqs, $score, $description ) = split_frequencies( $codon_freq_string )
#
#-----------------------------------------------------------------------------
sub split_frequencies
{
    local $_ = shift;
    s/\s+$//;
    s/^\s+//;
    my ( undef, $scr, $freq, undef, $descr ) = m/^(([\d.]*)\t)?(\d[\d.]*,\d[^\t]*)(\t([^\t]*))?$/;
    return wantarray ? ( undef, undef, undef ) : undef if ! $freq;
    my $freq2 = [ map { [ map { $_ + 0 } split /,/ ] } split /\|/, $freq ];
    wantarray ? ( $freq2, $scr, $descr ) : $freq2
}


#-----------------------------------------------------------------------------
#  Normalize codon usage frequencies in place
#
#      normalize_freq( $freq )
#      normalize_freq( $freq, $min_freq )
#
#   $freq can be \@freq or [ \@freq, description, ... ]
#-----------------------------------------------------------------------------
sub normalize_freq
{
    my $freq = ref $_[0]->[1] ? $_[0] : $_[0]->[0];
    my $min_freq = $_[1] || 0;

    for ( @$freq )
    {
        my $sum = 0;
        foreach ( @$_ ) { $_ = $min_freq if $_ < $min_freq; $sum += $_ }
        if ( $sum && $sum != 1 ) { foreach ( @$_ ) { $_ /= $sum } }
    }

    $_[0];
}


#-----------------------------------------------------------------------------
#  Copy a set of codon usage frequencies, enforcing a minimum frequency value.
#
#       $freq = set_minimum_frequency( $freq, $min_codon_frequency )
#
#   $freq can be \@freq or [ \@freq, description, ... ]
#   Output form matches input form.
#
#-----------------------------------------------------------------------------
sub set_minimum_frequency
{
    my ( $infreq, $min_f ) = @_;
    $min_f = 0.0001 if ! defined $min_f;
    my $freq = ( ref $infreq->[1] ) ? $infreq : $infreq->[0];
    my @f = ();
    for ( @$freq )
    {
        my @fi = @$_;  #  Work on a copy
        my $sum_fi = 0;
        foreach ( @fi ) { $_ = $min_f if $_ < $min_f; $sum_fi += $_ }
        if ( $sum_fi && $sum_fi != 1 ) { foreach ( @fi ) { $_ /= $sum_fi } }
        push @f, \@fi;
    }

    ref $infreq->[1] ? \@f : [ \@f, @$infreq[ 1 .. (@$infreq-1) ] ];
}


#-----------------------------------------------------------------------------
#  Format frequencies with amino acids separated by vertical bars, and
#  codons within the amino acid separated by commas:
#
#  faa1c1,faa1c2,faa1c3,faa1c4|faa2c1,faa2c2,...|faa3c1,faa3c2,...
#
#   $codon_freq_string = frequencies_as_string( \@freqs )
#
#-----------------------------------------------------------------------------
sub frequencies_as_string
{
    join( "|", map { join( ",", map { sprintf "%7.5f", $_ } @$_ ) } @{$_[0]} );
}


#-----------------------------------------------------------------------------
#  Format frequencies with amino acids separated by vertical bars, and
#  codons within the amino acid separated by commas:
#
#  faa1c1,faa1c2,faa1c3,faa1c4|faa2c1,faa2c2,...|faa3c1,faa3c2,...
#
#     report_frequencies(               \@freqs [, $title] )
#     report_frequencies( \*FH,         \@freqs [, $title] )
#     report_frequencies(       $score, \@freqs [, $title] )
#     report_frequencies( \*FH, $score, \@freqs [, $title] )
#
#-----------------------------------------------------------------------------
sub report_frequencies
{
    my $fh    = ( ref( $_[0] ) eq 'GLOB' ) ? shift : \*STDOUT;

    my @parts = ( ( ! ref( $_[0] ) ? shift : () ),
                  frequencies_as_string( shift ),
                  ( $_[0]          ? shift : () )
                );
    print $fh join( "\t", @parts ), "\n";
}


#-------------------------------------------------------------------------------
#  Read all frequencies from a file:
#
#     @$freq = read_frequencies( $file )
#    \@$freq = read_frequencies( $file )
#     @$freq = read_frequencies( \*FH )
#    \@$freq = read_frequencies( \*FH )
#     @$freq = read_frequencies( )        # D = STDIN
#    \@$freq = read_frequencies( )        # D = STDIN
#-------------------------------------------------------------------------------
sub read_frequencies
{
    my ( $fh, $close ) = input_handle( @_ );
    $fh or print STDERR "gjocodonlib::read_frequencies called with bad file: '$_[0]'\n"
           and return undef;
    my @freq = map { scalar split_frequencies( $_ ) } <$fh>;
    close $fh if $close;
    wantarray ? @freq : \@freq;
}


#-------------------------------------------------------------------------------
#  Read all frequencies with scores and labels from a file:
#
#     @$freq_scr_lbl = read_frequencies_scr_label( $file )
#    \@$freq_scr_lbl = read_frequencies_scr_label( $file )
#     @$freq_scr_lbl = read_frequencies_scr_label( \*FH )
#    \@$freq_scr_lbl = read_frequencies_scr_label( \*FH )
#     @$freq_scr_lbl = read_frequencies_scr_label( )        # D = STDIN
#    \@$freq_scr_lbl = read_frequencies_scr_label( )        # D = STDIN
#-------------------------------------------------------------------------------
sub read_frequencies_scr_label
{
    my ( $fh, $close ) = input_handle( @_ );
    $fh or print STDERR "gjocodonlib::read_frequencies_scr_label called with bad file: '$_[0]'\n"
           and return undef;
    my @freq = map { [ split_frequencies( $_ ) ] } <$fh>;
    close $fh if $close;
    wantarray ? @freq : \@freq;
}


#-------------------------------------------------------------------------------
#  Read one set of frequencies from an open file handle:
#
#      $freq                 = read_next_frequencies( $fh )
#      $freq                 = read_next_frequencies( )       # D = STDIN
#    ( $freq, $scr, $descr ) = read_next_frequencies( $fh )
#    ( $freq, $scr, $descr ) = read_next_frequencies( )       # D = STDIN
#-------------------------------------------------------------------------------
sub read_next_frequencies
{
    my ( $fh ) = @_;
    $fh ||= \*STDIN;
    split_frequencies( scalar <$fh> );
}


#-------------------------------------------------------------------------------
#  The following collection of functions is for a structured representation of
#  codon usage frequencies text, particularly as output by native_codon_usage().
#  They standardize the terms for some codon usage types and subtypes.
#-------------------------------------------------------------------------------
#  Convert text frequencies to a 4 or 5 part structure. I am converging on the
#  5-part form, plus a sixth field for genetic code (which is not currently
#  supported by anything, but should be).
#
#  [ $gid, $gdesc, $type,              $freq ] = structure_freq_text_4( $freq_text_line );
#  [ $gid, $gdesc, $stdtype, $subtype, $freq ] = structure_freq_text_5( $freq_text_line );
#
#      $gid     is the first word in the codon frequencies description
#      $gdesc   is the rest of the description, up to a ' -- ' delimiter
#      $type    is the text after a ' -- ' delimiter, if present
#      $stdtype is is a fixed vocabulary codon usage type
#      $subtype is a possible qualifier of the type
#
#  Type / subtype combinations are:
#  -------------------------------------------------------------------------
#  Type          Subtype   Description
#  -------------------------------------------------------------------------
#  Current types
#  -------------------------------------------------------------------------
#  average                 genome avearge codon usage
#  modal                   genome modal codon usage
#  high_expr        0      modal usage of high expression candidates
#  high_expr        1      modal usage of high expression candidates
#                               differing from mode
#  high_expr        2      iterated modal usage of high expression
#                               candidates differing from mode
#  nonnative               modal usage of nonnative genes
#  -------------------------------------------------------------------------
#  Anticipated types
#  -------------------------------------------------------------------------
#  genome        average   genome avearge codon usage (synonym)
#  genome         modal    genome modal codon usage (synonym)
#  mito          average   mitochondion
#  mito           modal    mitochondion
#  nonnative     average   average usage of nonnative genes
#  nonnative      modal    modal usage of nonnative genes (synonym)
#  plasmid:id    average   plasmid (with optional element id)
#  plasmid:id     modal    plasmid (with optional element id)
#  plastid       average   plastid
#  plastid        modal    plastid
#  prophage:id   average   prophage (with optional element id)
#  prophage:id    modal    prophage (with optional element id)
#  region:id     average   genomic region (with optional element id)
#  region:id      modal    genomic region (with optional element id)
#  shared        average   average usage for core genes of species
#  shared         modal    modal usage for core genes of species
#  unique        average   average usage for genes unique to a strain
#  unigue         modal    modal usage for genes unique to a strain
#-------------------------------------------------------------------------------
sub structure_freq_text_4
{
    my ( $freq, undef, $desc ) = $_[0] ? gjocodonlib::split_frequencies( $_[0] ) : ();
    $freq ? [ split_mode_description_3( $desc ), $freq ] : ();
}


sub structure_freq_text_5
{
    my ( $freq, undef, $desc ) = $_[0] ? gjocodonlib::split_frequencies( $_[0] ) : ();
    $freq ? [ split_mode_description_4( $desc ), $freq ] : ();
}


sub split_mode_description_3
{
    local $_ = shift;
    $_ = '' unless defined $_;
    # ( gen_id, gen_desc, usage_type )
    my @desc = /^\s*(\S+)(\s+(.*\S))? +-- +(.+)$/  ? ( $1, $3, $4 )
             : /^\s*(\S+)(\s+(.*\S))?$/            ? ( $1, $2, undef )
             :                                       ( $_, undef, undef );
    #  Just in case
    $desc[2] =~ s/^Alien/Nonnative/ if $desc[2];

    wantarray ? @desc : \@desc;
}


sub split_mode_description_4
{
    my @desc = split_mode_description_3( $_[0] );
    splice @desc, 2, 1, stdtype_subtype( $desc[2] );

    wantarray ? @desc : \@desc;
}


#-------------------------------------------------------------------------------
#  Make standard [ stdtype, subtype ] pairs from the type text produced by
#  native_codon_usage. The stdtype is the key for storing the corresponding
#  frequencies, as in:
#
#      $data->{ $stdtype } = $freq;
#
#  The subtype is a value that is keyed according to the stdtype, as in:
#
#      $data->{ $subtype_key{ $stdtype } } = $subtype;
#
#-------------------------------------------------------------------------------
sub stdtype_subtype
{
    local $_ = shift;

    return ! defined $_   ? ( ''        => undef         )
         : /^Genome mode/ ? ( modal     => undef         )
         : /^Genome av/   ? ( average   => undef         )
         : /^High expr/   ? ( high_expr => subtype( $_ ) )
         : /^Nonnative/   ? ( nonnative => subtype( $_ ) )
         : /^Alien/       ? ( nonnative => subtype( $_ ) )
         :                  ( $_        => undef         );
}


#-------------------------------------------------------------------------------
#  Function to find numeric subtype code:
#-------------------------------------------------------------------------------
sub subtype
{
    local $_ = shift;

    return ( ! $_ )          ? undef
         : /those matching/  ? 0
         : /mode 0/          ? 1
         : /mode [12]/       ? 2
         :                     undef;
}


#-------------------------------------------------------------------------------
#  Genome codon usages are typed codon usages, intended for simple exchange and
#  text file storage of codon usage frequencies. Note that the order in a file
#  is NOT the same as the order in the array. The file will tend to do a better
#  job of lining up the columns for viewing. The array order has more of a
#  logical hierarchy to it.
#
#  Genome codon usage array:
#
#      $usage = [ $gid, $gname, $type, $subtype, $freqs, $gencode ]
#
#  Genome codon usage file format (file extension .gcu) has lines of the form:
#
#      "$freqstr\t$gencode\t$gid\t$type\t$subtype\t$gname\n"
#
#  A type should always be specified.
#  An undef or empty string subtype is allowed. Note that subtype 0 can have a
#      specific meaning and is not necessarily that same as '' or undef.
#  A missing, blank or undefined genetic code is 1 or 11.
#
#  Functions to read and write genome codon usages:
#
#      @usages = read_genome_codon_usages( $file )
#     \@usages = read_genome_codon_usages( $file )
#      @usages = read_genome_codon_usages( )          #  STDIN
#     \@usages = read_genome_codon_usages( )          #  STDIN
#
#      $n_written = write_genome_codon_usages( $file,  @usages )
#      $n_written = write_genome_codon_usages( $file, \@usages )
#      $n_written = write_genome_codon_usages(         @usages )  #  STDOUT
#      $n_written = write_genome_codon_usages(        \@usages )  #  STDOUT
#
#  $file can be a filename, a filehandle, a string reference, '', or undef
#-------------------------------------------------------------------------------
sub read_genome_codon_usages
{
    my $file = ( ( ! defined( $_[0] ) ) || ( ref( $_[0] ) ne 'HASH' ) ) ? shift : undef;
    my ( $fh, $close ) = input_handle( $file );
    my @usages;
    while ( <$fh> )
    {
        chomp;
        my ( $freqstr, $gencode, $gid, $type, $subtype, $gname ) = split /\t/;
        next unless $freqstr && $type;
        my $freq = gjocodonlib::split_frequencies( $freqstr );
        $freq and @$freq 
           or next;
        push @usages, [ $gid, $gname, $type, $subtype, $freq, $gencode ];
    }

    close( $fh ) if $close;

    wantarray ? @usages : \@usages;
}


sub write_genome_codon_usages
{
    my $file = ( ! defined( $_[0] ) || ( ref( $_[0] ) ne 'ARRAY' ) ) ? shift : undef;
    my ( $fh, $close ) = output_handle( $file );
    $fh or return 0;

    my $n = 0;
    foreach ( is_array_of_cnts_or_freqs($_[0]) ? @{$_[0]} : @_ )
    {
        my ( $gid, $gname, $type, $subtype, $freq, $gencode ) = @$_;
        $freq && ref( $freq ) eq 'ARRAY' && @$freq
            or next;
        my $freqstr = frequencies_as_string( $freq )
            or next;
        my @data = map { defined $_ ? $_ : '' }
                   ( $freqstr, $gencode, $gid, $type, $subtype, $gname );
        print $fh join( "\t", @data ), "\n";
        $n++;
    }

    close( $fh ) if $close;

    $n;
}


#===============================================================================
#  Codon usages axes (modal, high_expression, nonnative) from various sources
#
#     @axes = ( $gname, $mode, $md_subtype, $high_expr, $he_subtype, $nonnative, $nn_subtype )
#
#===============================================================================
#  Get available codon usages for a genome from GenomeCodonUsages.pm
#
#     @axes = genome_axes_from_module( $gid );
#    \@axes = genome_axes_from_module( $gid );
#
#-------------------------------------------------------------------------------

sub genome_axes_from_module
{
    eval { require GenomeCodonUsages } ? GenomeCodonUsages::genome_axes(@_)
                                       : wantarray ? () : [];
}


#===============================================================================
#  Build a description of codon usage axes from a list of codon usages. If
#  modal codon usage is not available, the average codon usage will be used.
#
#      @axes = genome_axes_from_usages(  @usages, \%opts );
#      @axes = genome_axes_from_usages( \@usages, \%opts );
#     \@axes = genome_axes_from_usages(  @usages, \%opts );
#     \@axes = genome_axes_from_usages( \@usages, \%opts );
#
#  Where:
#
#      @axes = ( $gname, $mode,      $md_subtype,
#                        $high_expr, $he_subtype,
#                        $nonnative, $nn_subtype
#              )
#
#      @usages = ( [ $gid, $gname, $type, $subtype, $freqs, $gencode ], ... )
#
#  Options:
#
#      genus_species => $gname     #  Supply the genome name
#      gname         => $gname     #  Supply the genome name
#-------------------------------------------------------------------------------
sub genome_axes_from_usages
{
    my $opts = ( $_[ 0] && ( ref( $_[ 0] ) eq 'HASH' ) ) ? shift
             : ( $_[-1] && ( ref( $_[-1] ) eq 'HASH' ) ) ? pop
             :                                             {};

    @_ or return wantarray ? () : [];

    my $name = $opts->{ gname } || $opts->{ genus_species } || undef;
    my ( $modal,     $md_subtype,
         $high_expr, $he_subtype,
         $nonnative, $nn_subtype
       );

    foreach ( is_array_of_cnts_or_freqs($_[0]) ? @{$_[0]} : @_ )
    {
        $_ && ref( $_ ) eq 'ARRAY' or next;

        my ( $gid, $gname, $type, $subtype, $freq ) = @$_;
        $type && $freq or next;

        if    ( $type =~ /^modal/i )
        {
            $modal      = $freq;
            $md_subtype = defined( $subtype ) ? $subtype : '';
        }
        elsif ( $type =~ /^high_?expr/i )
        {
            $high_expr  = $freq;
            $he_subtype = defined( $subtype ) ? $subtype : '';
        }
        elsif ( $type =~ /^non-?native/i )
        {
            $nonnative  = $freq;
            $nn_subtype = defined( $subtype ) ? $subtype : '';
        }
        elsif ( $type =~ /^average/i && ! $modal )
        {
            $modal      = $freq;
            $md_subtype = 'average';
        }
        $name ||= $gname || $gid;
    }


    my @axes  = ( $name, $modal,     $md_subtype,
                         $high_expr, $he_subtype,
                         $nonnative, $nn_subtype
                );

    wantarray ? @axes : \@axes;
}


#===============================================================================
#  Chi square based evaluation of counts
#===============================================================================
#  Compare codon usage(s) to expected frequencies by chi-square.
#
#    @chisqr_df_n = codon_usage_chi_sqr( $freqH, @count_hashes )
#
#-----------------------------------------------------------------------------
sub codon_usage_chi_sqr
{
    my $freqH = shift;
    $freqH && ref( $freqH ) eq 'HASH' && @_ or return ();

    my @out = ();

    foreach my $cnts ( @_ )
    {
        ref( $cnts ) eq 'HASH' or push @out, [] and next;
        my ( $chisqr, $df, $total ) = (0, 0, 0);

        foreach my $aa ( @aa_package_order )
        {
            my @codons = @{ $amino_acid_codons_DNA{ $aa } };
            my ($c, $d, $n) = gjostat::chi_square( [ map { $freqH->{ $_ } } @codons ],
                                                   [ map { $cnts->{ $_ }  } @codons ]
                                                 );
            if ( $d > 0 ) { $chisqr += $c; $df += $d; $total += $n }
        }

        push @out, [ $chisqr, $df, $total ];
    }

    @out;
}


#-----------------------------------------------------------------------------
#  Compare packaged codon usage(s) to expected frequencies by chi-square.
#
#     ( $chisqr, $df, $n ) = packaged_codon_usage_chi_sqr( $freq, $cnts )
#
#-----------------------------------------------------------------------------
sub packaged_codon_usage_chi_sqr
{
    my ( $freq, $cnt ) = @_;
    $freq && ref( $freq ) eq 'ARRAY' && @$freq >= 18 or return ();
    $cnt  && ref( $cnt )  eq 'ARRAY' && @$cnt  >= 18 or return ();

    my ( $chisqr, $df, $total ) = (0, 0, 0);

    for ( my $i = 0; $i < 18; $i++ )
    {
        my ($c, $d, $n) = gjostat::chi_square( $freq->[$i], $cnt->[$i] );
        if ( $d && $n ) { $chisqr += $c; $df += $d; $total += $n }
    }

    ( $chisqr, $df, $total );
}


#-----------------------------------------------------------------------------
#  Compare two codon counts by chi-square.
#
#     ( $chisqr, $df, $n ) = count_vs_count_chi_sqr( \@cnt_1, \@cnt_2 )
#     ( $chisqr, $df, $n ) = count_vs_count_chi_sqr( \%cnt_1, \%cnt_2 )
#
#-----------------------------------------------------------------------------
sub count_vs_count_chi_sqr
{
    my ( $cnt1, $cnt2 ) = @_;
    $cnt1 && $cnt2 or return ();

    $cnt1 = codon_count_package( $cnt1 ) if ref $cnt1 eq 'HASH';
    $cnt2 = codon_count_package( $cnt2 ) if ref $cnt2 eq 'HASH';

    return () if ref $cnt1 ne 'ARRAY' || ref $cnt2 ne 'ARRAY' || ( @$cnt1 != @$cnt2 );

    my ( $chisqr, $df, $total ) = (0, 0, 0);
    for ( my $i = 0; $i <= 17; $i++ )
    {
        my ( $c, $d, $n ) = contingency_chi_sqr_2( $cnt1->[$i], $cnt2->[$i] );
        if ( $d && $n ) { $chisqr += $c; $df += $d; $total += $n }
    }

    ( $chisqr, $df, $total );
}


#-----------------------------------------------------------------------------
#----------------------- Use count_vs_count_chi_sqr() ------------------------
#-----------------------------------------------------------------------------
#  Compare two codon usages by chi-square.
#
#     ( $chisqr, $df, $n ) = codon_usage_pairwise_chi_sqr( $cntH_1, $cntH_2 )
#
#-----------------------------------------------------------------------------
sub codon_usage_pairwise_chi_sqr { count_vs_count_chi_sqr( @_ ) }


#-----------------------------------------------------------------------------
#----------------------- Use count_vs_count_chi_sqr() ------------------------
#-----------------------------------------------------------------------------
#  Compare two codon usages by chi-square.
#
#     ( $chisqr, $df, $n ) = count_package_chi_sqr( $cnts_1, $cnts_2 )
#
#-----------------------------------------------------------------------------
sub count_package_chi_sqr { count_vs_count_chi_sqr( @_ ) }


#-----------------------------------------------------------------------------
#  Compare codon counts to expected frequencies by chi-square.
#
#     ( $chisqr, $df, $n ) = count_vs_freq_chi_sqr( $cnts,        $freqs )
#     ( $chisqr, $df, $n ) = count_vs_freq_chi_sqr( $labled_cnts, $freqs )
#     ( $chisqr, $df, $n ) = count_vs_freq_chi_sqr( $countH,      $freqs )
#
#-----------------------------------------------------------------------------
sub count_vs_freq_chi_sqr
{
    my ( $cnt, $freq ) = @_;
    $cnt && $freq or return ();

    $cnt  = codon_count_package( $cnt  ) if ref $cnt  eq 'HASH';
    $freq = codon_count_package( $freq ) if ref $freq eq 'HASH';  # Silly, but would work

    ref( $cnt ) eq 'ARRAY' && ref( $freq ) eq 'ARRAY' && @$freq >= 18 or return ();

    if ( @$cnt == 2 )    # Remove label of labeled counts
    {
        $cnt = $cnt->[0];
        $cnt && ref( $cnt ) eq 'ARRAY' or return ();
    }
    @$cnt >= 18 or return ();

    my ( $chisqr, $df, $total ) = ( 0, 0, 0 );
    for ( my $i = 0; $i <= 17; $i++ )
    {
        my ( $c, $d, $n ) = gjostat::chi_square( $freq->[$i], $cnt->[$i] );
        if ( $d && $n ) { $chisqr += $c; $df += $d; $total += $n }
    }

    ( $chisqr, $df, $total );
}


#-------------------------------------------------------------------------------
#  Compare codon counts to expected frequencies by chi-square.
#
#     $p_value = count_vs_freq_p_value( $cnts,        $freq )
#     $p_value = count_vs_freq_p_value( $cnts,        $freq, $max_len )
#     $p_value = count_vs_freq_p_value( $labled_cnts, $freq )
#     $p_value = count_vs_freq_p_value( $labled_cnts, $freq, $max_len )
#
#-------------------------------------------------------------------------------
sub count_vs_freq_p_value
{
    my ( $cnts, $freq, $max_len ) = @_;
    my ( $chisqr, $df, $n ) = gjocodonlib::count_vs_freq_chi_sqr( $cnts, $freq );
    $n or return undef;
    $chisqr *= ( $max_len / $n ) if ( $max_len && $n > $max_len );
    ( $df > 1 ) ? gjostat::chisqr_prob( $chisqr, $df ) : 1;
}


#-----------------------------------------------------------------------------
#  Score a gene's codon usage against one or more sets of frequencies:
#
#     @scores = codon_usage_p_values( $cnts,        \@freq_sets )
#     @scores = codon_usage_p_values( $cnts,        \@freq_sets, $max_len )
#     @scores = codon_usage_p_values( $labled_cnts, \@freq_sets )
#     @scores = codon_usage_p_values( $labled_cnts, \@freq_sets, $max_len )
#
#-----------------------------------------------------------------------------

sub codon_usage_p_values
{
    my ( $cnts, $freq_sets, $max_len ) = @_;
    $cnts      && ref( $cnts )      eq 'ARRAY' or return ();
    $freq_sets && ref( $freq_sets ) eq 'ARRAY' or return ();
    $freq_sets = [ $freq_sets ] if ! ref $freq_sets->[0]->[0];  #  Allow one set of frequencies

    map { count_vs_freq_p_value( $cnts, $_, $max_len ) } @$freq_sets;
}


#-----------------------------------------------------------------------------
#  Score one frequency against a set of counts.
#  A score based on the sum of the p-values (or log likelihoods) for all gene
#  counts compared of a set of relative codon usage frequencies:
#
#     $score = codon_freq_score( $freq, \@count_sets, \%options )
#
#  Options:
#
#     expon      => exponent  #  Return sum of P**exponent
#     exponent   => exponent  #  Same as expon
#     likelihood => boolean   #  Score by log likelihood
#     max_len    => max_len   #  Max codons in calculating P-values (D = unlim)
#     max_length => max_len   #  Same as max_len
#     p_val      => P-value   #  Return the count of genes with P >= P-value
#     p_value    => P-value   #  Same as p_val
#-----------------------------------------------------------------------------
sub codon_freq_score
{
    my ( $freq, $cnts, $opts ) = @_;
    $freq && ref( $freq ) eq 'ARRAY' or return -1;
    $cnts && ref( $cnts ) eq 'ARRAY' or return -1;

    $opts ||= {};
    my $expon = option_by_regexp( $opts, qr/^expon/i, undef );
    my $like  = option_by_regexp( $opts, qr/like/i,   undef );
    my $max_l = option_by_regexp( $opts, qr/len/i,    undef );
    my $p_val = option_by_regexp( $opts, qr/^p_val/i, undef );

    $like ? codon_freq_score_lnL( $freq, $cnts, $max_l )
          : codon_freq_score_0( $freq, $cnts, $p_val, $expon, $max_l );
}


#-----------------------------------------------------------------------------
#  Score one frequency against a set of counts.
#  A score based on the sum of p-value**0.3 for all gene counts compared
#  of a set of relative codon usage frequencies:
#
#     $score = codon_freq_score_0( $freq, \@count_sets, $p_val, $expon, $max_l )
#
#  Params:
#
#     $p_val    #  Return the count of genes with P >= P-value (D = p-value sum)
#     $max_len  #  Max codons in calculating P-values (D = unlim)
#     $expon    #  Return sum of P**exponent (D = 0.3)
#-----------------------------------------------------------------------------
sub codon_freq_score_0
{
    my ( $freq, $cntsets, $p_val, $expon, $max_l ) = @_;
    $freq    && ref( $freq )    eq 'ARRAY' && @$freq >= 18 or croak;
    $cntsets && ref( $cntsets ) eq 'ARRAY' or croak;

    $expon ||= 0.3;   # Default power of the P-value

    my $score = 0;
    foreach ( @$cntsets )
    {
        my ( $chisqr, $df, $n ) = count_vs_freq_chi_sqr( $_, $freq );
        if ( $n && ( $df > 0 ) )
        {
            $chisqr *= $max_l / $n if ( $max_l && ( $n > $max_l ) );
            my $p = gjostat::chisqr_prob( $chisqr, $df );
            $score += $p_val ? ( $p >= $p_val ? 1 : 0 )  # P >= p_value
                             : $p**$expon;               # sum( P ** exponent )
        }
    }

    $score;
}


#===============================================================================
#  Score frequencies relative to a set of gene counts:
#  (This is the original version that runs one analysis pipe.)
#
#    @scored_freqs = score_codon_frequencies_0( \@freqs, \@counts, \%options )
#   \@scored_freqs = score_codon_frequencies_0( \@freqs, \@counts, \%options )
#    @scored_freqs = score_codon_frequencies_0( \@freqs,           \%options )
#   \@scored_freqs = score_codon_frequencies_0( \@freqs,           \%options )
#
#  Output is [ score, freqs ] pairs.
#
#  Codon counts for scoring can be supplied in the command, or can be supplied
#  by a file named in the options.  If both counts and a name are supplied,
#  this is used as the temporary file name.
#
#  Options:
#
#      count_file => file      #  name for the codon counts file
#      exponent   => expon     #  P-value exponent for scoring total P-value**expon (D = 0.3)
#      max_length => max_len   #  max gene codons in calculating P-values (D = unlim)
#      p_value    => p-value   #  cutoff for counting hits (D = 0.1)
#      verbose    => interval  #  reporting interval for count of genes scored (D = never)
#
#  By default, the score is the sum of exponentiated P-values
#===============================================================================
sub score_codon_frequencies_0
{
    my $freqs = shift;
    $freqs && ref( $freqs ) eq 'ARRAY'
        or croak "score_codon_frequencies_0() called with invalid freqs\n";

    my $counts = ( ref($_[0]) eq 'ARRAY' ) ? shift : [];

    my $options = ( ref($_[0]) eq 'HASH' ) ? shift : {};

    my $cntfile = option_by_regexp( $options, qr/(count)|(file)/i, '' );
    my $expon   = option_by_regexp( $options, qr/exp/i,   0.3 );
    my $max_l   = option_by_regexp( $options, qr/len/i,   undef );
    my $p_val   = option_by_regexp( $options, qr/p_val/i, undef );
    my $verbose = option_by_regexp( $options, qr/^verb/i, undef );

    my $save_cnt = -f $cntfile;
    if ( @$counts )
    {
        my $cntFH;
        if ( length $cntfile )
        {
            open( $cntFH, '>', $cntfile )
                or print STDERR "score_codon_frequencies_0() could not open '$cntfile' for writing.\n"
                    and exit;
        }
        else
        {
            ( $cntFH, $cntfile ) = SeedAware::open_tmp_file( 'score_codon_frequencies_tmp', 'counts' );
            $cntFH
                or print STDERR "score_codon_frequencies_0() could not open a temp file for writing.\n"
                    and exit;
        }
        foreach ( @$counts ) { report_counts( $cntFH, $_ ) }
        close $cntFH;
    }
    elsif ( ! -s $cntfile )
    {
        print STDERR "score_codon_frequencies_0() called with neither count data or a count file.\n";
        exit;
    }

    #  Open the evaluation pipe:

    my @eval_cmd = ( 'codon_freq_eval_2',
                     ( $max_l ? ( '-l', sprintf( '%d', $max_l ) ) : () ),
                     ( $p_val ? ( '-p', sprintf( '%.3e', $p_val ) ) : ( '-e', sprintf( '%.3e', $expon ) ) ),
                     $cntfile
                   );

    my( $pid, $rd, $wr );
    $pid = open2( $rd, $wr, @eval_cmd )
        or print STDERR "score_codon_frequencies_0() could not open evaluation pipe to:\n",
                        "    '", join( ' ', @eval_cmd ), "'\n"
           and exit;
    { my $old = select $wr; $| = 1; select $old; }  #  Autoflush the write pipe

    my $ndone = 0;
    my @scored;
    foreach my $freq ( @$freqs )
    {
        #  If called with scored frequencies ( [$score, $freq] ), fix them.
        $freq = $freq->[1] if ( @$freq == 2 );
        request_freq_score( $wr, $freq );
        push @scored, [ read_freq_score( $rd ), $freq ];
        print STDERR "score_codon_frequencies_0: $ndone done.\n" if $verbose && ( (++$ndone % $verbose) == 0 );
    }

    close( $wr );
    close( $rd );
    waitpid $pid, 0;

    unlink $cntfile if ! $save_cnt;
    wantarray() ? @scored : \@scored
}


#===============================================================================
#  Score requencies relative to a set of gene counts:
#
#    @scored_freqs = score_codon_frequencies( \@freqs, \@counts, \%options )
#   \@scored_freqs = score_codon_frequencies( \@freqs, \@counts, \%options )
#    @scored_freqs = score_codon_frequencies( \@freqs,           \%options )
#   \@scored_freqs = score_codon_frequencies( \@freqs,           \%options )
#
#  Output is [ score, freqs ] pairs.
#
#  Codon counts for scoring can be supplied in the command, or can be supplied
#  by a file named in the options.  If both counts and a name are supplied,
#  this is used as the temporary file name.
#
#  Options:
#
#      count_file => file      #  name for the codon counts file
#      exponent   => expon     #  P-value exponent for scoring total P-value**expon (D = 0.3)
#      max_length => max_len   #  max gene codons in calculating P-values (D = unlim)
#      p_value    => p-value   #  cutoff for counting hits (D = 0.1)
#      pipes      => n_pipes   #  number of evaluation pipes to run (D = 1)
#      verbose    => interval  #  reporting interval for count of genes scored (D = never)
#
#  By default, the score is the sum of exponentiated P-values
#===============================================================================
sub score_codon_frequencies
{
    my $freqs = shift;
    ref( $freqs ) eq 'ARRAY'
        or croak "score_codon_frequencies() called with invalid freqs\n";

    #  If called with scored frequencies ( [$score, $freq] ), fix them.
    my @freqs = map { ( @$_ == 2 ) ? $_->[1] : $_ } @$freqs;
    
    my $counts = ( ref($_[0]) eq 'ARRAY' ) ? shift : [];

    my $options = ( ref($_[0]) eq 'HASH' ) ? shift : {};

    my $cnt_file = option_by_regexp( $options, qr/(count)|(file)/i, '' );
    my $expon    = option_by_regexp( $options, qr/exp/i,       0.3 );
    my $max_l    = option_by_regexp( $options, qr/len/i,   undef );
    my $p_val    = option_by_regexp( $options, qr/p_val/i, undef );
    my $pipes    = option_by_regexp( $options, qr/pipe/i,      1 );
    my $verbose  = option_by_regexp( $options, qr/^verb/i, undef );

    #  This is a very bad overloading of the parameter
    if ( $cnt_file && ref( $cnt_file ) eq 'ARRAY' && ! $counts )
    {
        $counts = $cnt_file;
        $cnt_file = '';
    }

    my %clean_opts = ( cnt_file => $cnt_file,
                       counts   => $counts,
                       expon    => $expon,
                       max_len  => $max_l,
                       p_value  => $p_val,
                       pipes    => $pipes
                     );

    my $analysis_pipe = open_codon_freq_eval( \%clean_opts );

    my @scored = score_codon_freq_sets( $analysis_pipe, \@freqs );

    close_codon_freq_eval( $analysis_pipe );

    wantarray() ? @scored : \@scored
}


#-------------------------------------------------------------------------------
#  The idea is to open one or more pipelines for evaluating codon usage
#  frequencies against a set of codon usages. This will allow a general
#  interface for using C or perl external programs, or (the ultimage fall
#  back) a perl subroutine. Frequencies are then evaluated by calling an
#  evaluation routine with the descriptor and the frequencies. This hides
#  the actual mechanism being used.
#
#  \%descriptor = open_codon_freq_eval( \%options )
#   $n_pipes    = n_codon_freq_eval_pipes( \%descriptor )
#   @scr_freq   = score_codon_freq_sets( \%descriptor, \@freq_sets )
#  \@scr_freq   = score_codon_freq_sets( \%descriptor, \@freq_sets )
#                 close_codon_freq_eval( \%descriptor )
#
#  Options (no flexibility in the keys used here):
#
#      cnt_file =>  $cnt_file  #  file with codon counts
#      counts   => \@counts    #      or codon counts
#      expon    =>  $expon     #  use p-value**expon as score
#      max_len  =>  $max_l     #  max_length used in chi square
#      p_value  =>  $p_val     #  P-value threshold for scoring
#      pipes    =>  $pipes     #  requested number of pipes
#
#  If both cnt_file and counts are supplied, any contents of cnt_file are
#  overwritten.
#
#  Descriptor components:
#
#      cnt_file =>  $cnt_file  #  file with codon counts, only if to be unlinked
#      pid      => \@pid       #  PID of each child process
#      rd       => \@rd        #  file handle for reading scores
#      wr       => \@wr        #  file handle for writing freqs to evaluate
#
#-------------------------------------------------------------------------------
#  \%descriptor = open_codon_freq_eval( \%options )
#-------------------------------------------------------------------------------
sub open_codon_freq_eval
{
    my ( $opts ) = @_;
    return undef if ! ( $opts && ref( $opts ) eq 'HASH' );

    my $cnt_file = $opts->{ cnt_file } || '';
    my $counts   = $opts->{ counts }   || [];
    my $expon    = $opts->{ expon }    || 0.3;
    my $max_l    = $opts->{ max_len };
    my $p_val    = $opts->{ p_value };
    my $pipes    = min( $opts->{ pipes } || 1, &n_cpu() );

    #  Locate the counts data:

    my $save_cnt = -f $cnt_file;
    ( @$counts || -s $cnt_file )
        or croak "gjocodonlib::open_codon_freq_eval() called with neither count data or a count file.\n";

    #  Open the evaluation pipe(s):

    my( $prog, @pid, @rd, @wr );
    my $npipe = 0;

    if ( &version( 'codon_freq_eval_2'  ) )
    {
        $prog = 'codon_freq_eval_2';
    }
    elsif ( ( $pipes > 1 ) && &version( 'codon_freq_eval_pl' ) )
    {
        $prog = 'codon_freq_eval_pl';
    }

    if ( $prog )
    {
        my $save_cnt = -f $cnt_file;
        if ( @$counts )
        {
            my $cntFH;
            if ( length $cnt_file )
            {
                open( $cntFH, '>', $cnt_file )
                    or print STDERR "open_codon_freq_eval() could not open '$cnt_file' for writing.\n"
                        and exit;
            }
            else
            {
                ( $cntFH, $cnt_file ) = SeedAware::open_tmp_file( 'open_codon_freq_eval_tmp', 'counts' );
                $cntFH
                    or print STDERR "open_codon_freq_eval() could not open a temp file for writing.\n"
                        and exit;
                $opts->{ cnt_file } = $cnt_file;
            }
            foreach ( @$counts ) { report_counts( $cntFH, $_ ) }
            close $cntFH;
        }

        my @eval_cmd = ( $prog,
                         ( $max_l ? ( '-l', sprintf( '%d',   $max_l ) ) : ()  ),
                         ( $p_val ? ( '-p', sprintf( '%.3e', $p_val ) ) : ( '-e', sprintf( '%.3f', $expon ) ) ),
                         $cnt_file
                       );

        #  Try to establish one or more evaluation pipes to scoring program:

        my $okay = 1;
        for ( $npipe = 0; $npipe < $pipes; $npipe++ )
        {
            $pid[ $npipe ] = open2( $rd[ $npipe ], $wr[ $npipe ], @eval_cmd );
            #  open2() never returns false, so we need a different test:
            if ( ! $pid[ $npipe ] ) { $okay = 0; last; }
 
            my $old = select $wr[ $npipe ];  #  Select write pipe
            $| = 1;                          #  Autoflush the stream
            select $old;                     #  Restore previous stream
        }
    }

    if ( ! $npipe )
    {
        #  If running without pipes, we need the counts in memory:
        if ( ! @$counts )
        {
            open( CNTS, "<$cnt_file" )
                or die "Could not find or open codon counts file '$cnt_file'\n";
            @$counts = map { chomp; scalar split_counts( $_ ) } <CNTS>;
            close CNTS;

            @$counts or die "No codon counts found in '$cnt_file'\n";
        }

        # request_freq_score() and read_freq_score() use these values

        $rd[0] = $wr[0] = [ $counts, $p_val, $expon, $max_l ];
        $pid[0] = 0;   # indicates that it is not external process
        $npipe  = 1;
    }

    my %desc = ( pid => \@pid,  # PID of each child process
                 rd  => \@rd,   # file handle for reading scores
                 wr  => \@wr,   # file handle for writing freqs to evaluate
               );

    #  Include the counts file, if it is to be removed when done:
    $desc{ cnt_file } = $cnt_file if $cnt_file && ! $save_cnt;

    return \%desc;
}


#-------------------------------------------------------------------------------
#   $n_pipes = n_codon_freq_eval_pipes( \%descriptor )
#-------------------------------------------------------------------------------
sub n_codon_freq_eval_pipes
{
    my ( $opts ) = @_;
    $opts && ( ref( $opts ) eq 'HASH' ) ? scalar @{ $opts->{pid} } : 1;
}


#-------------------------------------------------------------------------------
#   @scr_freq = score_codon_freq_sets( \%descriptor, \@freq_sets )
#  \@scr_freq = score_codon_freq_sets( \%descriptor, \@freq_sets )
#-------------------------------------------------------------------------------
sub score_codon_freq_sets
{
    my ( $opts, $freq_sets ) = @_;
    return () if ! (  $opts      && ( ref( $opts )      eq 'HASH' )
                  &&  $freq_sets && ( ref( $freq_sets ) eq 'ARRAY' )
                  && @$freq_sets
                   );

    my $npipe = @{ $opts->{ pid } };
    return () if ! $npipe;
    my @wr = @{ $opts->{ wr } };
    my @rd = @{ $opts->{ rd } };
    return () if ! ( @wr && @rd );

    my ( $imax, @scored );

    #  Distribute problems in batches of no more than 256 per pipe:

    for ( my $i0 = 0; $i0 < @$freq_sets; $i0 = $imax )
    {
        $imax = $i0 + 256 * $npipe;
        $imax = @$freq_sets if $imax > @$freq_sets;
        #  Distribute a batch:
        for ( my $i = $i0; $i < $imax; $i++ )
        {
            request_freq_score( $wr[$i % $npipe], $freq_sets->[$i] );
        }
        #  Gather answers:
        for ( my $i = $i0; $i < $imax; $i++ )
        {
            push @scored, [ read_freq_score( $rd[$i % $npipe] ), $freq_sets->[$i] ];
        }
    }

    return wantarray ? @scored : \@scored;
}


#-------------------------------------------------------------------------------
#   close_codon_freq_eval( \%descriptor )
#-------------------------------------------------------------------------------
sub close_codon_freq_eval
{
    my $opts = shift || {};

    my $pid = $opts->{ pid } || [];

    #  If one or more pipes were openned, then $pid[0] is positive

    if ( ref( $pid ) eq 'ARRAY' && @$pid && $pid->[0] )
    {
        my $wr = $opts->{ wr } || [];
        if ( ref( $wr ) eq 'ARRAY' ) { foreach ( @$wr ) { close( $_ ) } }

        my $rd = $opts->{ rd } || [];
        if ( ref( $rd ) eq 'ARRAY' ) { foreach ( @$rd ) { close( $_ ) } }

        foreach ( @$pid ) { waitpid $_, 0 }
    }

    my $cnt_file = $opts->{ cnt_file } || '';
    unlink $cnt_file if $cnt_file && -f $cnt_file;

    return;
}


#-------------------------------------------------------------------------------
#  $version = version( $program_name )
#-------------------------------------------------------------------------------
sub version
{
    local $_ = shift;
    $_ or return undef;

    my $bin = SeedAware::executable_for( $_ )
        or return undef;
    my ( $version ) = SeedAware::run_gathering_output( $bin, '-v' );
    chomp $version if $version;
    return $version;
}


#-------------------------------------------------------------------------------
#  $ncpu = n_cpu()
#
#  Based upon tim_yates's answer to
#
#     http://stackoverflow.com/questions/19619582/get-the-number-of-processors-cores-in-bash
#
#  and Sambatyon's answer to
#
#     http://superuser.com/questions/226552/how-to-tell-how-many-cpus-cores-you-have-on-windows-7
#
#-------------------------------------------------------------------------------
sub n_cpu
{
    my $os = $^O;
    my @cmd = $os =~ /linux/  ? qw(grep -c ^processor /proc/cpuinfo)
            : $os =~ /darwin/ ? qw(sysctl -n hw.ncpu)
            : $os =~ /win32/  ? qw(echo %NUMBER_OF_PROCESSORS%)
            :                   ();
    my ( $ncpu ) = @cmd ? SeedAware::run_gathering_output( @cmd ) : qw( 1 );

    $ncpu && ($ncpu =~ /(\d+)/) ? $1 : 1;
}


#-------------------------------------------------------------------------------
#  \%sysctl = sysctl()
#-------------------------------------------------------------------------------
sub sysctl
{
    my $bin = SeedAware::executable_for( 'sysctl' )
        or return {};

    my %data = map { chomp; /^(\S+):\s(.*)$/ ? ( $1, $2 ) : () }
               SeedAware::run_gathering_output( qw( sysctl -a ) );

    \%data;
}


#===============================================================================
#  Likelihood-based scores
#===============================================================================
#  Compare codon counts to expected frequencies by log-likelihood.
#
#     $lnL = count_vs_freq_lnL( \@cnt, \@freq )
#     $lnL = count_vs_freq_lnL( \@cnt, \@freq, $max_len )
#
#-------------------------------------------------------------------------------
sub count_vs_freq_lnL
{
    my ( $cnt, $freq, $max_len ) = @_;

    my $min_fr = 1e-6;
    my $n_cdn  = 0;
    my $lnL    = 0;
    for ( my $aa = 0; $aa < 18; $aa++ )
    {
        my $cdn_fr  = $freq->[ $aa ];
        my $cdn_cnt = $cnt->[ $aa ];
        for ( my $j = 0; $j < @$cdn_fr; $j++ )
        {
            my $nj  = $cdn_cnt->[ $j ] or next;
            my $fr  = $cdn_fr->[ $nj ];
            $fr     = $min_fr if $fr < $min_fr;
            $lnL   += $nj * log( $fr );
            $n_cdn += $nj;
        }
    }

    $lnL *= ( $max_len / $n_cdn ) if $max_len && ( $n_cdn > $max_len );

    $lnL;
}


#-----------------------------------------------------------------------------
#  Compare codon counts to log expected frequencies by log-likelihood.
#
#     $lnL = count_vs_ln_freq_lnL( \@cnt, \@freq )
#     $lnL = count_vs_ln_freq_lnL( \@cnt, \@freq, $max_len )
#
#-------------------------------------------------------------------------------
sub count_vs_ln_freq_lnL
{
    my ( $cnt, $ln_freq, $max_len ) = @_;

    my $n_cdn = 0;
    my $lnL   = 0;
    for ( my $aa = 0; $aa < 18; $aa++ )
    {
        my $cdn_fr  = $ln_freq->[ $aa ];
        my $cdn_cnt = $cnt->[ $aa ];
        for ( my $j = 0; $j < @$cdn_fr; $j++ )
        {
            my $nj  = $cdn_cnt->[ $j ] or next;
            $lnL   += $nj * $cdn_fr->[ $nj ];
            $n_cdn += $nj;
        }
    }

    $lnL *= ( $max_len / $n_cdn ) if $max_len && ( $n_cdn > $max_len );

    $lnL;
}


#-----------------------------------------------------------------------------
#  Score a gene's codon usage against one or more sets of frequencies:
#
#     @lnL = codon_usage_lnL( \@codon_counts, \@freq_sets )
#     @lnL = codon_usage_lnL( \@codon_counts, \@freq_sets, $max_len )
#
#-----------------------------------------------------------------------------
sub codon_usage_lnL
{
    my ( $cnts, $freq_sets, $max_len ) = @_;
    $freq_sets = [ $freq_sets ] if ! ref $freq_sets->[0]->[0];  #  Allow one set of frequencies

    map { count_vs_freq_lnL( $cnts, $_, $max_len ) } @$freq_sets;
}


#-----------------------------------------------------------------------------
#  Score one frequency against a set of counts.
#  A score based on the sum of log likelihoods for all gene counts compared
#  of a set of relative codon usage frequencies:
#
#     $score = codon_freq_score_lnL( \@freq, \@per_gene_counts, $max_l )
#
#  Params:
#
#     $max_len  #  Max codons in calculating P-values (D = unlim)
#-----------------------------------------------------------------------------
sub codon_freq_score_lnL
{
    my ( $freq, $cnts, $max_l ) = @_;
    croak if ! $freq;

    my $min_fr = 1e-6;
    my $ln_freq = [ map { [ map { my $ln_fr = $_ >= $min_fr ? log( $_ ) : log( $min_fr ) } @$_ ] } @$freq ];

    my $lnL = 0;
    foreach ( @$cnts )
    {
        $lnL += count_vs_ln_freq_lnL( $_, $freq, $max_l );
    }

    $lnL;
}


#===============================================================================
#  Convert packaged codon counts into an array of amino acid counts, for one
#  or more genes:
#
#      @per_gene_aa_cnts = codon_counts_2_aa_counts( @per_gene_codon_cnts )
#
#===============================================================================
sub codon_counts_2_aa_counts
{
    map { [ map { my $ttl = 0; foreach ( @$_ ) { $ttl += $_ } $ttl } @$_ ] } @_
}


#===============================================================================
#  Produce a simulated set of codon counts matched to the length and amino
#  acid composition of the genes:
#
#    @per_gene_codon_cnt = simulate_genome( \@packaged_freqs, @per_gene_aa_cnt )
#
#===============================================================================

sub simulate_genome
{
    my $have_seglib;
    eval { require 'gjosegmentlib'; $have_seglib = 1; };
    return () if ! $have_seglib;

    my $freqs = shift;
    ref $freqs eq 'ARRAY'
        and ref $freqs->[0] eq 'ARRAY'
        or return undef;

    #  Encapsulate the codon frequencies at covering segments on the
    #  interval between 0 and 1.  This will allow efficient access to
    #  codons with the desired frequencies.

    my @aa_info;
    my @extra = ( [1] ) x ( 20 - @$freqs );
    foreach my $aa_freq ( @$freqs, @extra )
    {
        #  Ensure that the frequencies are normalized:

        my $ttl = 0;
        foreach ( @$aa_freq ) { $ttl += $_ }
        my @aa_freq = $ttl ? map { $_ / $ttl      } @$aa_freq
                           : map { 1  / @$aa_freq } @$aa_freq;

        #  Create a tree of the intervals:

        my $i = 0;
        my @pairs = map { [ $i++, $_ ] } @aa_freq;

        push @aa_info, [ gjosegmentlib::segment_new_tree( @pairs ), scalar @aa_freq ];
    }

    #  Process each gene:

    map { my $gene = $_;
          my @gene_data;
          my $aa_num = 0;
          foreach my $aa_cnt ( @$gene )
          {
              #  Initialize the codon counts so that we alwoys get a list
              #  of the correctl length:

              my ( $tree, $n_codon ) = @{ $aa_info[ $aa_num++ ] };
              my @aa_data = ( 0 ) x $n_codon;
              for ( my $i = 0; $i < $aa_cnt; $i++ )
              {
                  $aa_data[ gjosegmentlib::segment_by_coord( rand(), $tree ) ]++;
              }

              push @gene_data, \@aa_data;
          }
          \@gene_data
        } @_
}


#===============================================================================
#  Modal codon usage of a set of genes.  If fewer than 6 sets of counts are
#  supplied, the average codon usage is returned.
#
#            \@modal_freqs   = modal_codon_usage( \@gene_cnt_pkgs, \%options )
#  ( $score, \@modal_freqs ) = modal_codon_usage( \@gene_cnt_pkgs, \%options )
#
#  Options:
#
#      average    => boolean   #  include average as seed vertex
#      count_file => cnt_file  #  file with (or for) codon counts
#      exponent   => float     #  P-value exponent in optimization (D = 0.3)
#      max_steps  => max_step  #  max simplex steps in optimization (D = 1e6)
#      n_top      => n         #  maximum vertices in simplex optimization (D = 75)
#      pipes      => n_pipe    #  number of processes to use in evaluation (D = 4)
#      pseudo     => float     #  per aa pseudo count in codon frequencies (D = 1)
#      root       => temp_file #  root name for count_file
#      trust_cnt  => boolean   #  trust the counts file (don't clobber it)
#      verbose    => int       #  reporting interval for opt steps (D = never)
#      vertices   => int       #  minimum vertices in simplex optimization (D = 50)
#
#  If both count_file and gene_cnt_pkgs are supplied, any data in count_file
#  are overwritten.
#===============================================================================
sub modal_codon_usage
{
    my ( $counts, $options ) = @_;
    $options ||= {};
    my $quiet = $options->{ quiet };

    if ( ! ( $counts && ref( $counts ) eq 'ARRAY' && @$counts ) )
    {
        return () if $quiet;
        croak "gjocodonlib::modal_codon_usage() called with bad counts.\n";
    }

    my $dfl_pipe = @$counts > 192 ? 4
                 : @$counts > 128 ? 3
                 : @$counts >  64 ? 2
                 :                  1;
    my $average   = option_by_regexp( $options, qr/^av/i,          0 );
    my $cnt_file  = option_by_regexp( $options, qr/file/i,        '' );
    my $expon     = option_by_regexp( $options, qr/exp/i,          0.3 );
    my $extra     = option_by_regexp( $options, qr/extra/i,        0 );
    my $maxstep   = option_by_regexp( $options, qr/step/i,   1000000 );
    my $n_top     = option_by_regexp( $options, qr/top/i,         75 );
    my $pipes     = option_by_regexp( $options, qr/pipe/i, $dfl_pipe );
    my $pseudo    = option_by_regexp( $options, qr/^pseudo/i,      1 );
    my $root_name = option_by_regexp( $options, qr/root/i,     undef );
    my $trust_cnt = option_by_regexp( $options, qr/^trust/i,       0 );
    my $verbose   = option_by_regexp( $options, qr/^verb/i,    undef );
    my $vertices  = option_by_regexp( $options, qr/vert/i,        50 );
    $n_top = $vertices if $n_top < $vertices;

    if ( ! defined( $cnt_file ) && $root_name )
    {
        $cnt_file = "$root_name.counts";
    }
    my $save_cnt_file = -f $cnt_file;

    #  The mode optimization needs a counts file.  This is configured to not
    #  clobber an existing file of nonzero size.  Other subroutines in this
    #  module will overwrite it with the data supplied. 

    if ( ( ( @$counts >= 6 ) || $save_cnt_file )
      && ( ( ! -s $cnt_file ) || ! $trust_cnt )
       )
    {
        my $cntFH;
        if ( length $cnt_file )
        {
            open( $cntFH, '>', $cnt_file )
                or print STDERR "modal_codon_usage() could not open '$cnt_file' for writing.\n"
                    and exit;
        }
        else
        {
            ( $cntFH, $cnt_file ) = SeedAware::open_tmp_file( 'open_codon_freq_eval_tmp', 'counts' );
            $cntFH
                or print STDERR "modal_codon_usage() could not open a temp file for writing.\n"
                    and exit;
            $options->{ cnt_file } = $cnt_file;
        }
        foreach ( @$counts ) { report_counts( $cntFH, $_ ) }
        close $cntFH;
    }

    $average = 1 if ( @$counts < 6 );

    my @freqs;
    push @freqs, count_to_freq( sum_counts( $counts ), $pseudo ) if $average;

    if ( @$counts < 6 )
    {
        print STDERR "gjocodonlib::modal_codon_usage() called with less than 6 sets of counts.\n",
                     "   Returning average codon usage.\n"
                     if ! $quiet;
        return wantarray() ? ( 0, $freqs[0] ) : $freqs[0];
    }

    push @freqs, map { count_to_freq( $_, $pseudo ) } @$counts;

    my $scr_opts = { count_file => $cnt_file,
                     exponent   => $expon,
                     pipes      => $pipes
                   };

    @freqs = sort { $b->[0] <=> $a->[0] }
             score_codon_frequencies( \@freqs, $scr_opts );

    splice @freqs, $n_top if @freqs > $n_top;

    #  n_top is number of actual to keep
    #  extra is number above min_vertices to explore

    my $opt_opts = { count_file => $cnt_file,
                     exponent   => $expon,
                     extra      => $extra,
                     pipes      => $pipes,
                     verbose    => $verbose,
                     vertices   => $vertices
                   };

    my ( $score, $modal_freqs ) = optimize_frequencies( \@freqs, $opt_opts );

    unlink $cnt_file if ! $save_cnt_file;

    wantarray() ? ( $score, $modal_freqs ) : $modal_freqs
}


#-------------------------------------------------------------------------------
#  $min = min( $n1, $n2 )
#-------------------------------------------------------------------------------
sub min { $_[0] <= $_[1] ? $_[0] : $_[1] }


#-------------------------------------------------------------------------------
#  $max = max( $n1, $n2 )
#-------------------------------------------------------------------------------
sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }


#===============================================================================
#  Optimize codon frequencies:
#
#              $freqs   = optimize_frequencies_0( \@freqs, \@counts, \%options )
#              $freqs   = optimize_frequencies_0( \@freqs,           \%options )
#    ( $score, $freqs ) = optimize_frequencies_0( \@freqs,           \%options )
#    ( $score, $freqs ) = optimize_frequencies_0( \@freqs, \@counts, \%options )
#
#  Options:
#
#      count_file   => file      #  name for the codon counts file
#      exponent     => expon     #  P-value exponent for scoring total
#                                #     P-value**expon (D = 0.3)
#      extra_vertices => extra   #  number of extra starting points to evaluate
#                                #     saving on the best
#      max_length   => max_len   #  max gene codons in calculating P-values
#                                #     (D = unlimited, changes not recommended)
#      max_steps    => max_step  #  max simplex steps in optimization (D = 1e6)
#      min_vertices => vertices  #  minimum number of vertices (D = 42)
#      p_value      => p-value   #  report number with p >= p-value for score
#      verbose      => interval  #  reporting interval for opt steps (D = never)
#
#===============================================================================
sub optimize_frequencies_0
{
    my $freqs = shift;
    ref( $freqs ) eq 'ARRAY'
        or croak "optimize_frequencies_0() called with invalid freqs\n";

    my $counts = ( ref($_[0]) eq 'ARRAY' ) ? shift : [];

    my $options = ( ref($_[0]) eq 'HASH' ) ? shift : {};

    my $cnt_file = option_by_regexp( $options, qr/(count)|(file)/i, '' );
    my $expon    = option_by_regexp( $options, qr/exp/i,        0.3 );
    my $extra    = option_by_regexp( $options, qr/extra/i,      0 );
    my $max_l    = option_by_regexp( $options, qr/len/i,    undef );
    my $maxstep  = option_by_regexp( $options, qr/step/i, 1000000 );
    my $verbose  = option_by_regexp( $options, qr/^verb/i,  undef );
    my $vertices = option_by_regexp( $options, qr/vert/i,      42 );

    my $save_cnt = -f $cnt_file;
    if ( @$counts )
    {
        my $cntFH;
        if ( length $cnt_file )
        {
            open( $cntFH, '>', $cnt_file )
                or print STDERR "optimize_frequencies_0() could not open '$cnt_file' for writing.\n"
                    and exit;
        }
        else
        {
            ( $cntFH, $cnt_file ) = SeedAware::open_tmp_file( 'optimize_frequencies', 'counts' );
            $cntFH
                or print STDERR "optimize_frequencies_0() could not open a temp file for writing.\n"
                    and exit;
        }
        foreach ( @$counts ) { report_counts( $cntFH, $_ ) }
        close $cntFH;
    }
    elsif ( ! -s $cnt_file )
    {
        print STDERR "optimize_frequencies_0() called with neither count data or a count file.\n";
        exit;
    }

    #  Do we have >= 6 points?

    my @freqs = @$freqs;
    if ( @freqs < 6 )
    {
        print STDERR <<"End_of_Few_Points";

Cannot optimize codon usage frequencies with only @{[scalar @freqs]} points.
Consider using average codon usage.

End_of_Few_Points

        exit 1;
    }

    #  Open the evaluation pipe:

    my @eval_cmd = ( 'codon_freq_eval_2',
                     ( $max_l ? ( '-l', sprintf( '%d', $max_l ) ) : () ),
                     '-e', sprintf( '%.3e', $expon ),
                     $cnt_file
                   );

    my( $pid, $rd, $wr );
    $pid = open2( $rd, $wr, @eval_cmd )
        or print STDERR "optimize_frequencies_0() could not open evaluation pipe:\n",
                        "    '", join( ' ', @eval_cmd ), "'\n"
           and exit;
    { my $old = select $wr; $| = 1; select $old; }  #  Autoflush the write pipe

    #  Score frequencies, if they are not already score-frequency pairs:

    if ( @{ $freqs[0] } != 2 )
    {
        @freqs = map { [ calc_freq_score( $wr, $rd, $_ ), $_ ] } @freqs;
    }

    my $nstep = 0;
    my @attempts;
    if ( $verbose )
    {
        foreach ( @freqs )
        {
            report_attempts( $nstep, $_->[0] ) if ++$nstep % $verbose == 0;
        }
    }

    #  Order them best to worst:

    @freqs = sort { $b->[0] <=> $a->[0] } @freqs;

    #  Do we need more vertices?  Make combinations of amino acid-specific
    #  compositions, drawn randomly from among the available points.  (This
    #  is way too easy.)

    my $np  = @freqs;               # number of preexisting points
    my $naa = @{ $freqs[0]->[1] };  # number of amino acids
    $vertices = @freqs if $vertices < @freqs;
    while ( @freqs < $vertices + $extra )
    {
        my $freq = random_freq_3( \@freqs, $naa );
        my $scr = calc_freq_score( $wr, $rd, $freq );
        report_attempts( $nstep, $scr ) if $verbose && ++$nstep % $verbose == 0;
        @freqs = sort { $b->[0] <=> $a->[0] } @freqs, [ $scr, $freq ];
    }

    splice @freqs, $vertices;

    # return $freqs[0]->[1];     #############################################

    #  Do a simplex optimization of the score by moving the orginal points
    #
    #  Try up to 4 options for test point.  Nothing is done to maintain
    #  the normalization of the frequencies, but round off error in the
    #  point movements is so small that this does not see to accumulate
    #  significantly.  The chi-square itself enforces normalization of the
    #  frequencies, so that cannot introduce systematic error.
    #
    #  Locations of points tested:
    #
    #     p0     p1    mean     p2      p3      p4
    #     0.0    0.5    1.0     1.5     2.0     2.4
    #           shrink         move    move    move
    #                           and             and
    #                          shrink          grow

    # my @step = ( 0.0, 0.4, 1.6, 2.0, 2.4 );
    my @step = ( 0.8, 0.5, 1.5, 2.0, 2.5 );

    my $done = 0;
    while ( ! $done )
    {
        #  Order points from worst to best:

        @freqs = sort { $a->[0] <=> $b->[0] } @freqs;
        my ( $wrst_scr, $wrst_pnt ) = @{ $freqs[  0 ] };  # Worst
        my ( $best_scr, $best_pnt ) = @{ $freqs[ -1 ] };  # Best

        #  Stop if there is no significant spread of scores;

        if ( ( $best_scr - $wrst_scr ) < 1e-6 * $best_scr ) { $done = 1; next }
        @attempts = ( ++$nstep );

        #  Try to improve one vertex, from worst to best:

        my $imprv_pnt = undef;
        while ( ( ! $imprv_pnt ) && ( ! $done ) )
        {
            my ( $scr, $p0 ) = @{ shift @freqs };
            push @attempts, $scr;
            my $mean_pnt = mean_point( map { $_->[1] } @freqs ); # p0 not in @freqs
            my $dir = subtract_points( $mean_pnt, $p0 );

            my $p1 = move_point( $p0, $dir, $step[1] );
            if ( $p1 )
            {
                my $s1 = calc_freq_score( $wr, $rd, $p1 );
                if ( $s1 > $scr ) { $scr = $s1; $imprv_pnt = $p1 }
                push @attempts, $s1;
            }

            my $p2 = move_point( $p0, $dir, $step[2] );
            if ( $p2 )
            {
                my $s2 = calc_freq_score( $wr, $rd, $p2 );
                push @attempts, $s2;
                if ( $s2 > $scr )
                {
                    $scr = $s2;
                    $imprv_pnt = $p2;

                    #  Only consider p3 if p2 is current best

                    my $p3 = move_point( $p0, $dir, $step[3] );
                    if ( $p3 )
                    {
                        my $s3 = calc_freq_score( $wr, $rd, $p3 );
                        push @attempts, $s3;
                        if ( $s3 > $scr )
                        {
                            $scr = $s3;
                            $imprv_pnt = $p3;

                            #  Only consider p4 if p3 is current best

                            my $p4 = move_point( $p0, $dir, $step[4] );
                            if ( $p4 )
                            {
                                my $s4 = calc_freq_score( $wr, $rd, $p4 );
                                push @attempts, $s4;
                                if ( $s4 > $scr ) { $scr = $s4; $imprv_pnt = $p4 }
                            }
                        }
                    }
                }
            }
            push @freqs, [ $scr, $imprv_pnt || $p0 ];    #  Final point
            report_attempts( @attempts ) if $verbose && $nstep % $verbose == 0;

            if  ( ! $imprv_pnt && $p0 eq $best_pnt )     #  Tried all points
            {
                #  Last ditch effort to recover the optimizaton.
                #  Take step most of the way to the average.

                $p0 = undef;
                while ( ! $imprv_pnt && ( $p0 ne $best_pnt ) )
                {
                    ( $scr, $p0 ) = @{ shift @freqs };
                    @attempts = ( '', $scr );
                    $mean_pnt = mean_point( map { $_->[1] } @freqs ); # p0 not in @freqs
                    $dir = subtract_points( $mean_pnt, $p0 );
                    $p1 = move_point( $p0, $dir, $step[0] );
                    if ( $p1 )
                    {
                        my $s1 = calc_freq_score( $wr, $rd, $p1 );
                        if ( $s1 > $scr ) { $scr = $s1; $imprv_pnt = $p1 }
                        push @attempts, $s1;
                    }
                    push @freqs, [ $scr, $imprv_pnt || $p0 ];
                    report_attempts( @attempts ) if $verbose && $nstep % $verbose == 0;
                }
                $done = 1 if ! $imprv_pnt;
            }

            if ( ! $imprv_pnt ) { @attempts = ( '' ) }  # Not a new step
        }

        $done = 1 if ( $nstep >= $maxstep );
    }

    close( $wr );
    close( $rd );
    waitpid $pid, 0;

    unlink $cnt_file if ! $save_cnt;

    my ( $best ) = sort { $b->[0] <=> $a->[0] } @freqs;

    wantarray() ? @$best : $best->[1]
}


#===============================================================================
#  Optimize codon frequencies:
#
#              $freqs   = optimize_frequencies( \@freqs, \@counts, \%options )
#              $freqs   = optimize_frequencies( \@freqs,           \%options )
#    ( $score, $freqs ) = optimize_frequencies( \@freqs,           \%options )
#    ( $score, $freqs ) = optimize_frequencies( \@freqs, \@counts, \%options )
#
#  Options:
#
#      count_file   => file      #  name for the codon counts file
#      exponent     => expon     #  P-value exponent for scoring total
#                                #     P-value**expon (D = 0.3)
#      extra_vertices => extra   #  number of extra starting points to evaluate
#                                #     saving on the best
#      max_length   => max_len   #  max gene codons in calculating P-values
#                                #     (D = unlimited, changes not recommended)
#      max_steps    => max_step  #  max simplex steps in optimization (D = 1e6)
#      min_vertices => vertices  #  minimum number of vertices (D = 42)
#      p_value      => p-value   #  report number with p >= p-value for score
#      pipes        => n_pipe    #  number of evaluation processes to use (D = 4)
#      verbose      => interval  #  reporting interval for opt steps (D = never)
#
#===============================================================================
sub optimize_frequencies
{
    my $freqs = shift;
    ref( $freqs ) eq 'ARRAY'
        or croak "optimize_frequencies() called with invalid freqs\n";

    my $counts = ( ref($_[0]) eq 'ARRAY' ) ? shift : [];

    my $options = ( ref($_[0]) eq 'HASH' ) ? shift : {};

    my $cnt_file = option_by_regexp( $options, qr/(count)|(file)/i, '' );
    my $expon    = option_by_regexp( $options, qr/exp/i,        0.3 );
    my $extra    = option_by_regexp( $options, qr/extra/i,      0 );
    my $max_l    = option_by_regexp( $options, qr/len/i,    undef );
    my $maxstep  = option_by_regexp( $options, qr/step/i, 1000000 );
    my $pipes    = option_by_regexp( $options, qr/pipe/i,       4 );
    my $verbose  = option_by_regexp( $options, qr/^verb/i,  undef );
    my $vertices = option_by_regexp( $options, qr/vert/i,      42 );

    #  This is a very bad overloading of the parameter
    if ( $cnt_file && ref( $cnt_file ) eq 'ARRAY' && ! $counts )
    {
        $counts   = $cnt_file;
        $cnt_file = '';
    }

    my $save_cnt = -f $cnt_file;
    ( @$counts || -s $cnt_file )
        or croak "optimize_frequencies() called with neither count data or a count file.\n";

    #  Do we have >= 6 points?

    my @freqs = @$freqs;
    if ( @freqs < 6 )
    {
        print STDERR <<"End_of_Few_Points";

Cannot optimize codon usage frequencies with only @{[scalar @freqs]} points.
Consider using average codon usage.

End_of_Few_Points

        croak;
    }

    #  Open the evaluation pipe:

    my %eval_opts = ( cnt_file => $cnt_file,
                      counts   => $counts,
                      expon    => $expon,
                      max_len  => $max_l,
                      pipes    => $pipes
                    );
    my $analysis_pipe = open_codon_freq_eval( \%eval_opts );
    my $n_pipes = n_codon_freq_eval_pipes( $analysis_pipe );

    #  Score frequencies, if they are not already score-frequency pairs:
    if ( @{ $freqs[0] } != 2 )
    {
        @freqs = score_codon_freq_sets( $analysis_pipe, \@freqs );
    }

    my $nstep = 0;

    #  Order them best to worst:

    @freqs = sort { $b->[0] <=> $a->[0] } @freqs;

    #  Do we need more vertices?  Make combinations of amino acid-specific
    #  compositions, drawn randomly from among the available points.  (This
    #  is way too easy.)

    my $np = @freqs;               # number of preexisting points
    $vertices = $np if $vertices < $np;

    my $naa = @{ $freqs[0]->[1] };  # number of amino acids
    while ( @freqs < $vertices + $extra )
    {
        my $freq = random_freq_3( \@freqs, $naa );
        my ( $scr_freq ) = score_codon_freq_sets( $analysis_pipe, [$freq] );
        @freqs = sort { $b->[0] <=> $a->[0] } @freqs, $scr_freq;
    }

    splice @freqs, $vertices;

    #  Do a simplex optimization of the score by moving the orginal points
    #
    #  Try up to 4 options for test point.  Nothing is done to maintain
    #  the normalization of the frequencies, but round off error in the
    #  point movements is so small that this does not see to accumulate
    #  significantly.  The chi-square itself enforces normalization of the
    #  frequencies, so that cannot introduce systematic error.
    #
    #  Locations of points tested:
    #
    #     p0     p1    mean     p2      p3      p4
    #     0.0    0.5    1.0     1.5     2.0     2.4
    #           shrink         move    move    move
    #                           and             and
    #                          shrink          grow

    #             0    1    2    3    4
    my @step = ( 0.8, 0.5, 1.5, 2.0, 2.5 );
    #  @step = ( 0.0, 0.4, 1.6, 2.0, 2.4 );

    my $done = 0;
    while ( ! $done )
    {
        #  Order points from worst to best:

        @freqs = sort { $a->[0] <=> $b->[0] } @freqs;
        my ( $wrst_scr, $wrst_pnt ) = @{ $freqs[  0 ] };  # Worst
        my ( $best_scr, $best_pnt ) = @{ $freqs[ -1 ] };  # Best

        #  Stop if there is no significant spread of scores;

        if ( ( $best_scr - $wrst_scr ) < 1e-6 * $best_scr ) { $done = 1; last }

        #  Try to improve one vertex, from worst to best:

        my ( $sf0, $scr, $p0, $mean, $dir, $p, $s, $sf, @pts );

        my $better  = undef;
        my $n_tried = 0;
        while ( ( ! $better ) && ( ! $done ) && ( $n_tried < $vertices ) )
        {
            $sf0 = shift @freqs;   #  These are scored frequencies
            ( $scr, $p0 ) = @$sf0;
            $mean = mean_point( map { $_->[1] } @freqs ); # p0 not in @freqs
            $dir = subtract_points( $mean, $p0 );

            if ( $n_pipes < 2 )
            {
                #  1 evaluation pipe
                $p = move_point( $p0, $dir, $step[1] );
                if ( $p )
                {
                    ( $sf ) = score_codon_freq_sets( $analysis_pipe, [ $p ] );
                    $s = $sf->[0];
                    if ( $s > $scr ) { $scr = $s; $better = $sf }
                }

                $p = move_point( $p0, $dir, $step[2] );
                if ( $p )
                {
                    ( $sf ) = score_codon_freq_sets( $analysis_pipe, [ $p ] );
                    $s = $sf->[0];
                    if ( $s > $scr )
                    {
                        $scr = $s;
                        $better = $sf;

                        $p = move_point( $p0, $dir, $step[3] );
                        if ( $p )
                        {
                            ( $sf ) = score_codon_freq_sets( $analysis_pipe, [ $p ] );
                            $s = $sf->[0];
                            if ( $s > $scr )
                            {
                                $scr = $s;
                                $better = $sf;

                                $p = move_point( $p0, $dir, $step[4] );
                                if ( $p )
                                {
                                    ( $sf ) = score_codon_freq_sets( $analysis_pipe, [ $p ] );
                                    $s = $sf->[0];
                                    if ( $s > $scr ) { $scr = $s; $better = $sf }
                                }
                            }
                        }
                    }
                }
            }
            elsif ( $n_pipes < 4 )
            {
                #  2 evaluation pipes
                @pts = map { move_point( $p0, $dir, $_ ) } @step[1..2];
                ( $sf ) = sort { $b->[0] <=> $a->[0] }
                          score_codon_freq_sets( $analysis_pipe, \@pts );
                $s = $sf->[0];
                if ( $s > $scr )
                {
                    $scr = $s;
                    $better = $sf;

                    if ( $pts[1] && ( $sf->[1] eq $pts[1] ) )
                    {
                        @pts = map { move_point( $p0, $dir, $_ ) } @step[3..4];
                        ( $sf ) = sort { $b->[0] <=> $a->[0] }
                                  score_codon_freq_sets( $analysis_pipe, \@pts );
                        $s = $sf->[0];
                        if ( $s > $scr ) { $scr = $s; $better = $sf }
                    }
                }
            }
            else
            {
                #  4 evaluation pipes
                @pts = map { move_point( $p0, $dir, $_ ) } @step[1..4];
                ( $sf ) = sort { $b->[0] <=> $a->[0] }
                          score_codon_freq_sets( $analysis_pipe, \@pts );
                $s = $sf->[0];
                if ( $s > $scr ) { $scr = $s; $better = $sf }
            }

            push @freqs, ( $better || $sf0 );           #  Final point
            $n_tried++;
        }

        #  If previous failed, try moving closer to mean point:

        $n_tried = 0;
        while ( ( ! $better ) && ( ! $done ) && ( $n_tried < $vertices ) )
        {
            @pts = ();
            while ( ( @pts < $n_pipes ) && ( $n_tried < $vertices ) )
            {
                my $f = shift @freqs;
                ( $scr, $p0 ) = @$f;
                $mean = mean_point( map { $_->[1] } @freqs ); # p0 not in @freqs
                $dir = subtract_points( $mean, $p0 );
                $p  = move_point( $p0, $dir, $step[0] );
                push @pts, $p if $p;
                push @freqs, $f;
                $n_tried++;
            }

            if ( @pts )
            {
                ( $sf ) = sort { $b->[0] <=> $a->[0] }
                          score_codon_freq_sets( $analysis_pipe, \@pts );
                $s = $sf->[0];
                if ( $s > $scr )
                {
                    $scr = $s;
                    $better = $sf;
                    $p = $sf->[1];
                    @freqs = grep { $_->[1] ne $p } @freqs;
                    push @freqs, $sf;
                }
            }
        }

        $done = 1 if ( ( ! $better ) || ( ++$nstep >= $maxstep ) );
    }

    close_codon_freq_eval( $analysis_pipe );

    my ( $best ) = sort { $b->[0] <=> $a->[0] } @freqs;

    wantarray() ? @$best : $best->[1]
}


sub merge_new_freq
{
    my ( $freqs, $new ) = @_;
    my ( $i, $j ) = ( 0, @$freqs );
    my $k;
    while ( $i != $j )
    {
        my $k = int( ( $i+$j ) / 2 );
        if ( $new->[0] >= $freqs->[$k]->[0] ) { $j = $k } else { $i = $k-1 }
    }
    splice @$freqs, $i, 0, $new;
    $freqs
}


#-------------------------------------------------------------------------------
#  Four ways to generate a new set of frequencies based on the current ones:
#
#      $newfreq = random_freq_1( \@scr_freqs, $n_aa )
#      $newfreq = random_freq_2( \@scr_freqs, $n_aa )
#      $newfreq = random_freq_3( \@scr_freqs, $n_aa )
#      $newfreq = random_freq_4( \@scr_freqs, $n_aa )
#
#-------------------------------------------------------------------------------
#  Each amino acid drawn from one member
#-------------------------------------------------------------------------------
sub random_freq_1
{
    my ( $scr_freqs, $naa ) = @_;
    my $nf = @$scr_freqs;
    [ map { [ @{ $scr_freqs->[int($nf*rand())]->[1]->[$_] } ] } ( 0 .. $naa-1 ) ]
}

#-------------------------------------------------------------------------------
#  Each amino acid drawn from one member, biased toward low numbers
#-------------------------------------------------------------------------------
sub random_freq_2
{
    my ( $scr_freqs, $naa ) = @_;
    my $nf = @$scr_freqs;
    [ map { [ @{ $scr_freqs->[int($nf*rand()**2)]->[1]->[$_] } ] } ( 0 .. $naa-1 ) ]
}

#-------------------------------------------------------------------------------
#  Each amino acid as average of 2 others
#-------------------------------------------------------------------------------
sub random_freq_3
{
    mean_2_points( random_freq_1( @_ ), random_freq_1( @_ ) );
}

#-------------------------------------------------------------------------------
#  Each amino acid as average of 2 others, biased toward low numbers
#-------------------------------------------------------------------------------
sub random_freq_4
{
    mean_2_points( random_freq_2( @_ ), random_freq_2( @_ ) );
}


#-------------------------------------------------------------------------------
#  Local calculation of a frequence score using an open bidirectional pipe:
#
#      $score = calc_freq_score( $wr, $rd, $freq )
#
#-------------------------------------------------------------------------------
sub calc_freq_score
{
    my ( $wr, $rd, $freq ) = @_;
    ( ref $freq eq 'ARRAY' and ref $freq->[0] eq 'ARRAY' )
        or croak;
    print $wr join( " ", map { @$_ } @$freq ), "\n";
    <$rd> + 0
}


#-------------------------------------------------------------------------------
#  Local calculation of a frequence score using an open bidirectional pipe:
#
#      $okay = request_freq_score( $wr, $freq )
#
#-------------------------------------------------------------------------------
my %freq_score_cache;
sub request_freq_score
{
    my ( $wr, $freq ) = @_;

    $freq = [] if ( ! $freq || ref( $freq ) ne 'ARRAY' || ref( $freq->[0] ) ne 'ARRAY' );
    if ( ref( $wr ) eq 'GLOB' )
    {
        print $wr join( ' ', map { @$_ } @$freq ), "\n";
    }
    elsif ( ( ref( $wr ) eq 'ARRAY' ) && ( @$wr == 4 ) )
    {
        push @{ $freq_score_cache{ $wr } }, codon_freq_score_0( $freq, @$wr );
    }
    else
    {
        croak "request_freq_score() called with bad args.\n";
    }
}


#-------------------------------------------------------------------------------
#  Local calculation of a frequence score using an open bidirectional pipe:
#
#      $score = read_freq_score( $rd )
#
#-------------------------------------------------------------------------------
sub read_freq_score
{
    my ( $rd ) = @_;
    if    ( ref $rd eq 'GLOB' )               { return <$rd> + 0; }
    elsif ( exists $freq_score_cache{ $rd } ) { return shift @{ $freq_score_cache{ $rd } } }
    else
    {
        croak "read_freq_score() called with bad value\n";
    }
}


#-------------------------------------------------------------------------------
#  Output a set of frequencies in a reasonably human friendly form:
#-------------------------------------------------------------------------------
sub debug_freq
{
    my ( $freq, $lbl ) = @_;
    if ( $lbl ) { print STDERR "$lbl\n" }
    print STDERR join( "\n", map { join( ", ", map { sprintf "%7.4f", $_ } @$_ ) } @$freq ), "\n\n";
}


#-------------------------------------------------------------------------------
#  Report a log of simplex point evaluation scores:
#
#    report_attempts( $step, @scores )
#
#-------------------------------------------------------------------------------
sub report_attempts
{
    my $step = shift;
    print STDERR join( ' ', sprintf( '%6s', $step ), map { sprintf( '%11.6f', $_ ) } @_ ), "\n";
}


#-------------------------------------------------------------------------------
#  Find the mean of a list of points:
#
#    \@point = mean_point( \@point1, \@point2, ... )
#
#-------------------------------------------------------------------------------
sub mean_point
{
    my $p = copy_point( shift );
    my $n = 1;
    foreach ( @_ ) { $p = add_to_point( $p, $_ ); $n++ }
    scale_point( $p, 1/$n );
}


#-------------------------------------------------------------------------------
#  Make a copy of a point:
#-------------------------------------------------------------------------------
sub copy_point { [ map { [ @$_ ] } @{$_[0]} ] }


#-------------------------------------------------------------------------------
#  Scale a copy of a point:
#
#      \@point2 = scaled_point( \@point, $factor )
#
#-------------------------------------------------------------------------------
sub scaled_point
{
    my ( $point, $factor ) = @_;
    [ map { [ map { $factor * $_ } @$_ ] } @$point ]
}


#-------------------------------------------------------------------------------
#  Rescale a point in place:
#
#      \@point = scale_point( \@point, $factor )
#
#-------------------------------------------------------------------------------
sub scale_point
{
    my ( $point, $factor ) = @_;
    foreach ( @$point ) { foreach ( @$_ ) { $_ *= $factor } }
    $point
}


#-------------------------------------------------------------------------------
#  Add to a point in place:
#
#      \@point = add_to_point( \@point, \@delta )
#
#-------------------------------------------------------------------------------
sub add_to_point
{
    my ( $point, $delta ) = @_;
    my $d = copy_point( $delta );    # So that we do not destroy the original
    my $dp;
    foreach ( @$point ) { $dp = shift @$d; foreach ( @$_ ) { $_ += shift @$dp } }
    $point
}


#-------------------------------------------------------------------------------
#  Add two points:
#
#      \@point = add_points( \@point1, \@point2 )
#
#-------------------------------------------------------------------------------
sub add_points
{
    my ( $point1, $point2 ) = @_;
    my $p2 = copy_point( $point2 );    # So that we do not destroy the original
    my $p2p;
    [ map { $p2p = shift @$p2; [ map { $_ + (shift @$p2p) } @$_ ] } @$point1 ]
}


#-------------------------------------------------------------------------------
#  Mean of two points:
#
#      \@point = mean_2_points( \@point1, \@point2 )
#
#-------------------------------------------------------------------------------
sub mean_2_points
{
    my ( $point1, $point2 ) = @_;
    my $p2 = copy_point( $point2 );    # So that we do not destroy the original
    my $p2p;
    [ map { $p2p = shift @$p2; [ map { 0.5 * ( $_ + (shift @$p2p) ) } @$_ ] } @$point1 ]
}


#-------------------------------------------------------------------------------
#  Subtract two points:
#
#      \@point = subtract_points( \@point1, \@point2 )
#
#-------------------------------------------------------------------------------
sub subtract_points
{
    my ( $point1, $point2 ) = @_;
    my $p2 = copy_point( $point2 );    # So that we do not destroy the original
    my $p2p;
    [ map { $p2p = shift @$p2; [ map { $_ - (shift @$p2p) } @$_ ] } @$point1 ]
}


#-------------------------------------------------------------------------------
#  Move a point by a scaled direction vector
#
#    $point = move_point( $point0, $direction_vector, $distance )
#
#-------------------------------------------------------------------------------
sub move_point
{
    my ( $p0, $dir, $dist ) = @_;
    legal_point( add_points( $p0, scaled_point( $dir, $dist ) ) );
}


#-------------------------------------------------------------------------------
#  Check legality of composition of a point in codon frequency space:
#
#     $point = legal_point( \@point )
#
#-------------------------------------------------------------------------------
sub legal_point
{
    foreach ( @{ $_[0] } )
    {
        foreach ( @$_ ) { $_ >= 0 && $_ <= 1 || return undef }
    }
    $_[0]
}


#===============================================================================
#  Subroutines for codon frequency distances:
#
#    $distance = codon_freq_distance( \@freq1, \@freq2, $type )  # D = type 2
#    $distance = codon_freq_distance_1( \@freq1, \@freq2 )
#    $distance = codon_freq_distance_2( \@freq1, \@freq2 )
#    $distance = codon_freq_distance_3( \@freq1, \@freq2 )
#
#  The type 1 distance calculation treats each codon equally.  The difference in
#  relative codon usage for each codon is squared, and then summed over codons.
#                 ____
#                 \
#  distance1**2 =  |   ( f1(c) - f2(c) )**2
#                 /___
#               c = codons
#
#  where fn(c) is the frequency of codon c in frequency set n.
#
#  The type 2 distance calculation proceeds by amino acid.  For a given amino
#  acid, the sum of absolute differenes of codon frequencies is squared, and the
#  results are summed over amino acids.
#                     ____             ____
#                 1   \                \
#  distance2**2 = - *  |            (   |    abs( f1(c) - f2(c) ) )**2
#                 4   /___             /___
#                   a = amino acids  c = codons for amino acid a
#
#  The type 3 distance calculation treats each codon equally.  The distance
#  is the absolute difference in frequencies, summed over codons.  That is,
#  it is a Manhattan metric.
#              ____
#              \
#  distance3 =  |   abs( f1(c) - f2(c) )
#              /___
#            c = codons
#
#
#  Type 2 distances provide more equal treatment of amino acids with
#  different uses of codons.  N.b.,
#  ----------------------------------------------------------------
#           Codon usage for leucine         Distance**2 for leucine
#         ----------------------------      -----------------------
#         TTA  TTG  TCT  TCC  TCA  TCG        Type 1      Type 2
#  ----------------------------------------------------------------
#  set1    1    0    0    0    0    0            2          1
#  set2    0    1    0    0    0    0
#
#  set1    1    0    0    0    0    0           6/5         1
#  set2    0   1/5  1/5  1/5  1/5  1/5
#
#  set1   1/2  1/2   0    0    0    0           3/4         1
#  set2    0    0   1/4  1/4  1/4  1/4
#
#  set1   1/3  1/3  1/3   0    0    0           2/3         1
#  set2    0    0    0   1/3  1/3  1/3
#  ----------------------------------------------------------------
#
#  Since all of these scenarios have completely disjoint codon usages
#  between the two sets of frequencies, it makes sense that they have the
#  same score.
#
#===============================================================================

#  Allow method as 3rd arg:

sub codon_freq_distance
{
    my $type = $_[2] || 2;

    return  $type == 2 ? codon_freq_distance_2( @_[0,1] )
          : $type == 1 ? codon_freq_distance_1( @_[0,1] )
          : $type == 3 ? codon_freq_distance_3( @_[0,1] )
          : undef
}


sub codon_freq_distance_1
{
    my ( $f1, $f2 ) = @_;
    $f1 && ref( $f1 ) eq 'ARRAY' && $f2 && ref( $f2 ) eq 'ARRAY'
        or croak( "codon_freq_distance_1 called with inappropriate args.\n" );

    my $dist_sq = 0;
    for ( my $aa = 0; $aa < @$f1; $aa++ )
    {
        $dist_sq += aa_freq_dist_sq_1( $f1->[$aa], $f2->[$aa] );
    }

    sqrt( $dist_sq )
}


sub aa_freq_dist_sq_1
{
    my ( $f1, $f2 ) = @_;
    $f1 && ref( $f1 ) eq 'ARRAY' && $f2 && ref( $f2 ) eq 'ARRAY'
        or croak( "aa_freq_dist_sq_1 called with inappropriate args.\n" );

    my $ttl = 0;
    for ( my $codon = 0; $codon < @$f1; $codon++ )
    {
        $ttl += ( $f1->[$codon] - $f2->[$codon] ) ** 2;
    }

    $ttl
}


sub codon_freq_distance_2
{
    my ( $f1, $f2 ) = @_;
    $f1 && ref( $f1 ) eq 'ARRAY' && $f2 && ref( $f2 ) eq 'ARRAY'
        or croak( "codon_freq_distance_2 called with inappropriate args.\n" );

    my $dist_sq = 0;
    for ( my $aa = 0; $aa < @$f1; $aa++ )
    {
        $dist_sq += aa_freq_dist_sq_2( $f1->[$aa], $f2->[$aa] );
    }

    sqrt( $dist_sq )
}


sub aa_freq_dist_sq_2
{
    my ( $f1, $f2 ) = @_;
    $f1 && ref( $f1 ) eq 'ARRAY' && $f2 && ref( $f2 ) eq 'ARRAY'
        or croak( "aa_freq_dist_sq_2 called with inappropriate args.\n" );

    my $ttl = 0;
    for ( my $codon = 0; $codon < @$f1; $codon++ )
    {
        $ttl += abs( $f1->[$codon] - $f2->[$codon] );
    }

    0.25 * $ttl ** 2
}

sub codon_freq_distance_3
{
    my ( $f1, $f2 ) = @_;
    $f1 && ref( $f1 ) eq 'ARRAY' && $f2 && ref( $f2 ) eq 'ARRAY'
        or croak( "codon_freq_distance_3 called with inappropriate args.\n" );

    my $dist_sq = 0;
    for ( my $aa = 0; $aa < @$f1; $aa++ )
    {
        $dist_sq += aa_freq_dist_3( $f1->[$aa], $f2->[$aa] );
    }

    $dist_sq
}

sub aa_freq_dist_3
{
    my ( $f1, $f2 ) = @_;
    $f1 && ref( $f1 ) eq 'ARRAY' && $f2 && ref( $f2 ) eq 'ARRAY'
        or croak( "aa_freq_dist_3 called with inappropriate args.\n" );

    my $ttl = 0;
    for ( my $codon = 0; $codon < @$f1; $codon++ )
    {
        $ttl += abs( $f1->[$codon] - $f2->[$codon] );
    }
}


#===============================================================================
#  For each frequency in the arguements, find the position along the
#  $freq0 to $freq1 vector that is closest to the frequencies point.
#  Coordinates along vector are measured with $freq0 being 0, and $freq1
#  being 1.
#
#     @projections = project_on_freq_vector_by_dist( \@freq_0, \@freq_1,   \@freq1, \@freq2, ...   )
#     @projections = project_on_freq_vector_by_dist( \@freq_0, \@freq_1, [ \@freq1, \@freq2, ... ] )
#
#  The returned projections are pairs composed of the position on the axis and
#  distance from the axis to the gene frequency.
#===============================================================================

sub project_on_freq_vector_by_dist
{
    my $freq_0 = shift;  #  Frequencies at point 0
    my $freq_1 = shift;  #  Frequencies at point 1
    return () if ! @_;
    my $d_freq_d_x = subtract_points( $freq_1, $freq_0 );
    return undef if is_zero_vector( $d_freq_d_x );

    #  Find the lower and upper bounds of x for each frequency:

    my @d_freq_d_x  = map { @$_ } @$d_freq_d_x;

    my @min_and_max = map { min_and_max_x( $_, ( shift @d_freq_d_x ) ) }
                      map { @$_ }
                      @$freq_0[ 0 .. 17 ];

    #  Find the maximum of the lower bounds, and minimum of the upper bounds:

    my ( $min_x, $max_x ) = ( -1e9, +1e9 );
    foreach ( @min_and_max )
    {
        $min_x = $_->[0] if $_->[0] > $min_x;
        $max_x = $_->[1] if $_->[1] < $max_x;
    }

    #  For each frequency in the arguements, find the position along the
    #  $freq0 to $freq1 vector that is closest to the point:

    my @projections = map { project_by_min_distance( $freq_0, $d_freq_d_x, $_, $min_x, $max_x ) }
                      ( ref $_[0]->[0]->[0] ? @{$_[0]} : @_ );

    wantarray ? @projections : \@projections
}


sub project_by_min_distance
{
    my ( $freq_0, $d_freq_d_x, $freq, $min_x, $max_x ) = @_;
    my $n_step = 16;
    my $inc = ( $max_x - $min_x ) / $n_step;
    my ( $x, $f );
    my @dists = map { $x = $inc * $_ + $min_x;
                      $f = move_point( $freq_0, $d_freq_d_x, $x );
                      [ $x, codon_freq_distance_2( $freq, $f ) ]
                    }
                ( 1 .. ($n_step-1) );  #  Leave empty space at ends

    my $x_and_dist = ( sort { $a->[1] <=> $b->[1] } @dists )[0];

    #  Divide and conquer search centered on current best point

    while ( $inc > 0.001 )
    {
        $inc *= 0.5;
        @dists = ( $x_and_dist,
                   map { $f = move_point( $freq_0, $d_freq_d_x, $_ );
                         [ $_, codon_freq_distance_2( $freq, $f ) ]
                       }
                   ( $x_and_dist->[0] - $inc, $x_and_dist->[0] + $inc )
                 );
        $x_and_dist = ( sort { $a->[1] <=> $b->[1] } @dists )[0];
    }

    $x_and_dist
}


#===============================================================================
#  For each frequency in the arguements, find the position along the
#  $freq0 to $freq1 vector that gives the smallest chi square value.
#  Coordinates along vector are measured with $freq0 being 0, and $freq1
#  being 1.
#
#     @projections = project_on_freq_vector_by_chi_sqr( \@freq_0, \@freq_1,   \@cnts1, \@cnts2, ...   )
#     @projections = project_on_freq_vector_by_chi_sqr( \@freq_0, \@freq_1, [ \@cnts1, \@cnts2, ... ] )
#
#  The returned projections are quartets composed of the position on the axis
#  the chi square value, the degrees of freedom and the number of different
#  amino acids.
#===============================================================================
sub project_on_freq_vector_by_chi_sqr
{
    my $freq_0 = shift;  #  Frequencies at point 0
    my $freq_1 = shift;  #  Frequencies at point 1
    return () if ! @_;
    my $d_freq_d_x = subtract_points( $freq_1, $freq_0 );
    return undef if is_zero_vector( $d_freq_d_x );

    #  Find the lower and upper bounds of x for each frequency:

    my @d_freq_d_x  = map { @$_ } @$d_freq_d_x;

    my @min_and_max = map { min_and_max_x( $_, ( shift @d_freq_d_x ) ) }
                      map { @$_ }
                      @$freq_0[ 0 .. 17 ];

    #  Find the maximum of the lower bounds, and minimum of the upper bounds:

    my ( $min_x, $max_x ) = ( -1e9, +1e9 );
    foreach ( @min_and_max )
    {
        $min_x = $_->[0] if $_->[0] > $min_x;
        $max_x = $_->[1] if $_->[1] < $max_x;
    }

    #  For each set of counts in the arguements, find the position along the
    #  $freq0 to $freq1 vector that has smallest chi square:

    my @projections = map { project_by_min_chi_sqr( $freq_0, $d_freq_d_x, $_, $min_x, $max_x ) }
                      ( ref $_[0]->[0]->[0] ? @{$_[0]} : @_ );

    wantarray ? @projections : \@projections
}


#-------------------------------------------------------------------------------
#  Find the point on an axis defined by $f0 & $k for which the chi square is
#  minimized:
#
#    ( $x, $chi_sqr, $df, $ncdn ) = project_by_min_chi_sqr( $freq_0, $d_freq_d_x, $counts, $min_x, $max_x )
#    [ $x, $chi_sqr, $df, $ncdn ] = project_by_min_chi_sqr( $freq_0, $d_freq_d_x, $counts, $min_x, $max_x )
#
#-------------------------------------------------------------------------------
sub project_by_min_chi_sqr
{
    my ( $freq_0, $d_freq_d_x, $counts, $min_x, $max_x ) = @_;
    my $n_step = 16;
    my $inc = ( $max_x - $min_x ) / $n_step;
    my ( $x, $f );
    my @chi_sqrs = map { $x = $inc * $_ + $min_x;
                         $f = move_point( $freq_0, $d_freq_d_x, $x );
                         [ $x, count_vs_freq_chi_sqr( $counts, $f ) ]
                       }
                   ( 1 .. ($n_step-1) );  #  Leave empty space at ends

    my $x_and_chi_sqr = ( sort { $a->[1] <=> $b->[1] } @chi_sqrs )[0];

    #  Divide and conquer search centered on current best point

    while ( $inc > 0.001 )
    {
        $inc *= 0.5;
        @chi_sqrs = ( $x_and_chi_sqr,
                      map { $f = move_point( $freq_0, $d_freq_d_x, $_ );
                            [ $_, count_vs_freq_chi_sqr( $counts, $f ) ]
                          }
                      ( $x_and_chi_sqr->[0] - $inc, $x_and_chi_sqr->[0] + $inc )
                    );
        $x_and_chi_sqr = ( sort { $a->[1] <=> $b->[1] } @chi_sqrs )[0];
    }

    wantarray ? @$x_and_chi_sqr : $x_and_chi_sqr;
}


sub projection_confidence_interval
{
    my ( $freq_0, $d_freq_d_x, $cnts, $x_opt, $min_x, $max_x, $options ) = @_;

    $options ||= {};
    my $max_len = $options->{ max_len } || $options->{ max_length } || 1e99;

    my $p_opt = count_vs_freq_p_value( $cnts, move_point( $freq_0, $d_freq_d_x, $x_opt ), $max_len );

    return ( $min_x, $max_x, $p_opt ) if $p_opt < 1e-10;
    my $p_target = 0.05 * $p_opt;

    #  Divide and conquer search for points with desired p-value

    my $inc = 0.5 * ( $max_x - $x_opt );
    my $x_max = $x_opt + $inc;
    while ( $inc > 0.001 )
    {
        $inc *= 0.5;
        my $p = count_vs_freq_p_value( $cnts, move_point( $freq_0, $d_freq_d_x, $x_max ), $max_len );
        $x_max += ( $p_target <=> $p ) * $inc;
    }

    $inc = 0.5 * ( $x_opt - $min_x );
    my $x_min = $x_opt - $inc;
    while ( $inc > 0.001 )
    {
        $inc *= 0.5;
        my $p = count_vs_freq_p_value( $cnts, move_point( $freq_0, $d_freq_d_x, $x_min ), $max_len );
        $x_min -= ( $p_target <=> $p ) * $inc;
    }

    ( $x_min, $x_max, $p_opt )
}


sub is_zero_vector
{
    foreach ( @{ shift @_ }[ 0 .. 17 ] ) { foreach ( @$_ ) { return 0 if $_ } }
    return 1;
}


#  Find the minimum and maximum x coordinates at which a frequency is in
#  the range $limit <= $freq <= ( 1 - $limit ), where $f_0 is the frequency
#  at x = 0 and $df_dx is the change in frequency per unit x.

sub min_and_max_x
{
    my ( $f_0, $df_dx, $limit ) = @_;
    return () if ! $df_dx;
    $limit ||= 1e-3;
    my $x_0 = (      $limit - $f_0 ) / $df_dx;
    my $x_1 = (  1 - $limit - $f_0 ) / $df_dx;

    ( $df_dx > 0 ) ? [ $x_0, $x_1 ] : [ $x_1, $x_0 ]
}


#===============================================================================
#  Functions that deal with codon usage axes (as in Kloster and Tang 2008,
#  and Davis and Olsen 2010).
#===============================================================================
#  For a given amino acid, the relative frequency of codon i at point x is
#  f(i,x).
#
#  Define frequencies f0(i) and f1(i) that we want to match at x = 0 and 1.
#  Typically these will be the modal and high expression usage frequencies.
#  Define the relative weight of codon i at point x as:
#
#     w(i,x) = f0(i) * exp( k(i) * x )
#
#  where f0(i) is the frequency of codon i at x = 0.  To get the frequency
#  of codon i at point x we normalize by the sum of the weights at x:
#
#     f(i,x) = w(i,x) / sum_over_j( w(j,x) )
#
#  At x = 0,
#
#     f(i,0) = w(i,0) / sum_over_i( w(i,0) )
#            = f0(i) * exp( k(i) * 0 ) / sum_over_j( f0(j) * exp( k(j) * 0 ) )
#            = f0(i) * exp( 0 ) / sum_over_j( f0(j) * exp( 0 ) )
#            = f0(i) * 1 / sum_over_j( f0(j) * 1 )
#            = f0(i) / sum_over_j( f0(j) )
#            = f0(i) / 1
#            = f0(i)
#
#  as it should.  Note that k(i) does not enter.  At x = 1,
#
#     f(i,1)   f0(i) * exp( k(i) )
#     ------ = -------------------
#     f(j,1)   f0(j) * exp( k(j) )
#
#  or
#
#     exp( k(i) )   f(i,1) / f0(i)   f1(i) / f0(i)
#     ----------- = -------------- = -------------
#     exp( k(j) )   f(j,1) / f0(j)   f1(j) / f0(j)
#
#  where f1(i) = f(i,1).
#
#  The values of k are underdetermined within a constant multiplier, but this
#  form suggests that it is natural to define:
#
#     exp( k(i) ) = f1(i) / f0(i)
#
#  or
#
#     k(i) = ln( f1(i) / f0(i) )
#
#===============================================================================
#  Project frequencies on an axis passing through freq_0 and freq_1.  The
#  projection is to the point on the line that minimizes the resulting
#  distance. The line is not straight; as the projection coordinate goes
#  to minus or plus infinity, frequencies remain between 0 and 1.
#
#     @projections = project_freq_on_axis_by_dist( \@freq_0, \@freq_1,   \@freq1, \@freq2, ...   )
#     @projections = project_freq_on_axis_by_dist( \@freq_0, \@freq_1, [ \@freq1, \@freq2, ... ] )
#
#  Each projection is:
#
#     [ $pos_along_axis, $dist_from_axis, $freq_at_pos ]
#
#-------------------------------------------------------------------------------
sub project_freq_on_axis_by_dist
{
    my $f0 = shift;                               #  Frequencies at x = 0
    my $f1 = shift;                               #  Frequencies at x = 1
    return( undef ) if is_zero_vector( subtract_points( $f1, $f0 ) );

    #  No options are currently supported, but distance measure is an obvious
    #  choice.

    my $opts = ( $_[0] && ( ref( $_[0] ) eq 'HASH' ) ) ? shift : {};

    return () unless @_ && defined $_[0]      && ref $_[0]      eq 'ARRAY'
                        && defined $_[0]->[0] && ref $_[0]->[0] eq 'ARRAY'
                        && defined $_[0]->[0]->[0];

    #  Figuring out the nature of the input list is a bit convoluted.
    #
    #  ! ref $_[0]->[0]->[0]              -->  $_[0] is   $freqs
    #  @{$_[0]} == 3 && ! ref $_[0]->[2]  -->  $_[0] is [ $freqs, $scr, $id ]

    my @freqs = map { @$_ == 3 && ! ref $_->[2] ? $_->[0] : $_ }
                ( ! ref $_[0]->[0]->[0] || ( @{$_[0]} == 3 && ! ref $_[0]->[2] ) ? @_ : @{$_[0]} );

    #  Compute exponential coeficient k for each codon for each amino acid:

    my $k = k_from_f0_and_f1( $f0, $f1 );

    #  For each set of frequencies in the arguements, find the position along
    #  the $freq0 to $freq1 axis that has the smallest distance.

    my @projections = map { project_freq_by_min_distance( $f0, $k, $_ ) } @freqs;

    wantarray ? @projections : \@projections
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#    $projection = project_freq_by_min_distance( $freq_0, $d_freq_d_x, $freq )
#    $projection = project_freq_by_min_distance( $freq_0, $d_freq_d_x, $freq, $min_x, $max_x )
#
#    $projection = [ $x, $dist_from_axis, $freq_on_axis ]
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub project_freq_by_min_distance
{
    my ( $freq_0, $d_freq_d_x, $freq, $min_x, $max_x ) = @_;
    $min_x = -8 if ! defined( $min_x );
    $max_x =  8 if ! defined( $max_x );

    my $n_step = 64;
    my $inc = ( $max_x - $min_x ) / $n_step;

    my @dists = map { my $x = $inc * $_ + $min_x;
                      my $f = freqs_at_x( $freq_0, $d_freq_d_x, $x );
                      [ $x, codon_freq_distance_2( $freq, $f ), $f ]
                    }
                ( 1 .. ($n_step-1) );

    my $x_dist_f = ( sort { $a->[1] <=> $b->[1] } @dists )[0];

    #  Divide and conquer search centered on current best point

    while ( $inc > 0.0001 )
    {
        $inc *= 0.5;
        @dists = ( $x_dist_f,
                   map { my $f = freqs_at_x( $freq_0, $d_freq_d_x, $_ );
                         [ $_, codon_freq_distance_2( $freq, $f ), $f ]
                       }
                   ( $x_dist_f->[0] - $inc, $x_dist_f->[0] + $inc )
                 );
        $x_dist_f = ( sort { $a->[1] <=> $b->[1] } @dists )[0];
    }

    $x_dist_f
}


#-------------------------------------------------------------------------------
#  Project codon counts onto a frequencies axis.
#
#  For each frequency in the arguements, find the position along the
#  $freq0 to $freq1 vector that gives the smallest chi square value.
#  Coordinates along vector are measured with $freq0 being 0, and $freq1
#  being 1.
#
#   @projections = project_on_axis_by_chi_sqr( \@freq_0, \@freq_1,   \@cnts1, \@cnts2, ...   )
#   @projections = project_on_axis_by_chi_sqr( \@freq_0, \@freq_1, [ \@cnts1, \@cnts2, ... ] )
#
# Old name:
#
#   @projections = project_on_freq_vector_by_chi_sqr_2( \@freq_0, \@freq_1,   \@cnts1, \@cnts2, ...   )
#   @projections = project_on_freq_vector_by_chi_sqr_2( \@freq_0, \@freq_1, [ \@cnts1, \@cnts2, ... ] )
#
#  The returned projections are quadruples or pentuples:
#
#     [ $projection_on_f0_f1_axis, $chi_square, $deg_of_freedom, $n_codon ]
#     [ $projection_on_f0_f1_axis, $chi_square, $deg_of_freedom, $n_codon, $id ]
#
#-------------------------------------------------------------------------------
sub project_on_freq_vector_by_chi_sqr_2 { project_on_axis_by_chi_sqr( @_ ) }


sub project_on_axis_by_chi_sqr
{
    my $f0 = shift;                               #  Frequencies at x = 0
    my $f1 = shift;                               #  Frequencies at x = 1
    my $opts = ref $_[0] eq 'HASH' ? shift : {};  #  Options
    return () if ! @_;

    return undef if is_zero_vector( subtract_points( $f1, $f0 ) );

    #  Compute exponential coeficient k for each codon for each amino acid:

    my $k = k_from_f0_and_f1( $f0, $f1 );

    #  For each set of counts in the arguements, find the position along the
    #  $freq0 to $freq1 vector that has smallest chi square.  Figuring out
    #  the nature of the input list is a bit convoluted.
    #
    #  ! ref $_[0]->[0]->[0]              -->  $_[0] is   $counts
    #  @{$_[0]} == 2 && ! ref $_[0]->[1]  -->  $_[0] is [ $counts, $id ]
    #
    my @counts = ( ! ref $_[0]->[0]->[0]              ? @_
                 :  @{$_[0]} == 2 && ! ref $_[0]->[1] ? @_
                 :                                      @{$_[0]}
                 );

    my @projections = map { scalar project_by_min_chi_sqr_2( $f0, $k, $_ ) }
                      @counts;

    wantarray ? @projections : \@projections
}


#-------------------------------------------------------------------------------
#  If $counts includes an id, i.e., $counts = [ [ [ ... ], ... ], $id ]:
#
#      ( $x, $chisqr, $df, $ncodon, $id ) = project_by_min_chi_sqr_2( $f0, $k, $counts )
#      [ $x, $chisqr, $df, $ncodon, $id ] = project_by_min_chi_sqr_2( $f0, $k, $counts )
#
#  If $counts does not include an id, i.e., $counts = [ [ ... ], ... ]:
#
#      ( $x, $chisqr, $df, $ncodon )      = project_by_min_chi_sqr_2( $f0, $k, $counts )
#      [ $x, $chisqr, $df, $ncodon ]      = project_by_min_chi_sqr_2( $f0, $k, $counts )
#-------------------------------------------------------------------------------
sub project_by_min_chi_sqr_2
{
    my ( $f0, $k, $counts ) = @_;

    #  Allow $counts = [ [ ... ], ... ] or [ [ [ ... ], ... ], $id ]

    my $id;
    ( $counts, $id ) = @$counts if ( ! ref $counts->[1] );
    my ( $min_x, $max_x ) = ( -5, 5 );
    my $n_step = 20;
    my $inc = ( $max_x - $min_x ) / $n_step;

    my @chi_sqrs = map { [ $_, chi_sqr_at_x( $counts, $f0, $k, $_ ) ] }
                   map { $inc * $_ + $min_x }    # Convert counter value to x
                   ( 1 .. ($n_step-1) );         # Leave empty space at ends

    my ( $x_and_chi_sqr ) = sort { $a->[1] <=> $b->[1] } @chi_sqrs;

    #  Divide and conquer search centered on current best point

    while ( $inc > 0.0005 )
    {
        $inc *= 0.5;
        my $x0 = $x_and_chi_sqr->[0];
        @chi_sqrs = ( $x_and_chi_sqr,
                      map { [ $_, chi_sqr_at_x( $counts, $f0, $k, $_ ) ] } ( $x0-$inc, $x0+$inc )
                    );
        ( $x_and_chi_sqr ) = sort { $a->[1] <=> $b->[1] } @chi_sqrs;
    }

    push @$x_and_chi_sqr, $id if defined $id;

    wantarray ? @$x_and_chi_sqr : $x_and_chi_sqr;
}


#-------------------------------------------------------------------------------
#  Compute the exponential coeficient k for each codon for each amino acid:
#  (does not check than frequencies are greater than 0)
#-------------------------------------------------------------------------------
sub k_from_f0_and_f1
{
    my ( $f0, $f1 ) = @_;
    my @k = ();
    for ( my $aa = 0; $aa <= 17; $aa++ )
    {
        my $f0aa = $f0->[$aa];
        my $f1aa = $f1->[$aa];
        my @kaa = ();
        for ( my $i = 0; $i < @$f0aa; $i++ )
        {
            push @kaa, log( ( $f1aa->[$i] || 0.000001 ) / ( $f0aa->[$i] || 0.000001 ) );
        }
        push @k, \@kaa;
    }

    \@k;
}


#-------------------------------------------------------------------------------
#  For a given point $x along the (extrapolated) line from $f0 to $f1, find
#  the codon frequencies.  The exponential coeficients $k can be computed
#  from $f0 and $f1 with k_from_f0_and_f1( $f0, $f1 ).
#
#     $freq = freqs_at_x( $f0, $k, $x )
#
#-------------------------------------------------------------------------------
sub freqs_at_x
{
    my ( $f0, $k, $x ) = @_;
    my $min_f = 0.0001;       # No frequencies less than $min_f

    #  Compute freqs for each amino acid and codon:

    my @f = ();
    for ( my $aa = 0; $aa <= 17; $aa++ )
    {
        my $f0aa = $f0->[$aa];
        my $kaa  = $k->[$aa];
        my $sum_wi = 0;
        my @w = ();
        foreach ( my $i = 0; $i < @$f0aa; $i++ )
        {
            my $wi = $f0aa->[$i] * exp( $kaa->[$i] * $x );
            $sum_wi += $wi;
            push @w, $wi;
        }

        #  Normalize frequencies, recording minimum found

        my $min = 1;
        foreach ( @w ) { $_ /= $sum_wi; $min = $_ if $_ < $min }

        #  If any frequencies are below $min_f, fix them:

        if ( $min < $min_f )
        {
            $sum_wi = 0;
            foreach ( @w ) { $_ = $min_f if $_ < $min_f; $sum_wi += $_ }
            foreach ( @w ) { $_ /= $sum_wi }    #  Renormalize
        }
        push @f, \@w;
    }

    \@f;
}


#-------------------------------------------------------------------------------
#  For a given point x along the (extrapolated) line from f0 to f1, find
#  the codon frequencies.  ( When used multiple times for the same $f0 and
#  $f1, it is more efficient to save the exponentical coeficients $k.)
#
#     $freq = freqs_at_x_given_f0_and_f1( $f0, $f1, $x )
#
#-------------------------------------------------------------------------------
sub freqs_at_x_given_f0_and_f1
{
    my ( $f0, $f1, $x ) = @_;
    freqs_at_x( $f0, scalar k_from_f0_and_f1( $f0, $f1 ), $x );
}


#-------------------------------------------------------------------------------
#  This is used in the search for the value of x that will optimize the
#  chi square p value, since the lowest chi square maximizes the P-value
#
#     $freq = freqs_at_x_given_f0_and_f1( $f0, $f1, $x )
#
#-------------------------------------------------------------------------------
sub chi_sqr_at_x
{
    my ( $counts, $f0, $k, $x ) = @_;
    count_vs_freq_chi_sqr( $counts, scalar freqs_at_x( $f0, $k, $x ) )
}


#===============================================================================
#  Evaluate a batch of codon usages for match on an axis defined by $f0 and $f1.
#-------------------------------------------------------------------------------
#   @x_p = codon_counts_x_and_p( $f0, $f1, \%opts,   $cnt, $cnt, ... );
#  \@x_p = codon_counts_x_and_p( $f0, $f1, \%opts,   $cnt, $cnt, ... );
#   @x_p = codon_counts_x_and_p( $f0, $f1, \%opts, \@$cnts );
#  \@x_p = codon_counts_x_and_p( $f0, $f1, \%opts, \@$cnts );
#
#  Options:
#
#      genome  => $bool         #  if true, x values less than 0 are not allowed
#      max_len => $max_length   #  maximum sequence length used in p value
#      xmax    => $xmax         #  largest permissible value of x (D = 20)
#      xmin    => $xmin         #  smallest permissible value of x (D = -20)
#
#-------------------------------------------------------------------------------
sub codon_counts_x_and_p
{
    my ( $f0, $f1, $opts ) = splice @_, 0, 3;

    $f0   && ref( $f0 )   eq 'ARRAY' && @$f0 or return ();
    $f1   && ref( $f1 )   eq 'ARRAY' && @$f0 or return ();

    $opts && ref( $opts ) eq 'HASH' or $opts = {};

    my $genome  = $opts->{ genome }  || 0;
    my $max_len = $opts->{ max_len } || $opts->{ maxlen } || 0;

    my $xmin = defined( $opts->{ xmin  } ) ? $opts->{ xmin }
             : defined( $opts->{ x_min } ) ? $opts->{ x_min }
             : $genome                     ? 0 : -20;

    my $xmax = defined( $opts->{ xmax  } ) ? $opts->{ xmax }
             : defined( $opts->{ x_max } ) ? $opts->{ x_max }
             :                               20;

    my @cnts = is_array_of_cnts_or_freqs( $_[0] ) ? @{$_[0]} : @_;

    my $k = k_from_f0_and_f1( $f0, $f1 );
    my $fmin = freqs_at_x( $f0, $k, $xmin );
    my $fmax = freqs_at_x( $f0, $k, $xmax );

    my @x_p;

    #  If there are more than 100 counts to evaluate, try a pipe:

    if ( @cnts > 100 && &version( 'codon_counts_x_and_p' ) )
    {
        my @eval_cmd = ( 'codon_counts_x_and_p',
                         ( $max_len ? ( -l => $max_len ) : () )
                       );
        my ( $rd, $wr );
        my $pid = open2( $rd, $wr, @eval_cmd );
        { my $old = select $wr; $| = 1; select $old; }  #  Autoflush the write pipe
        &report_frequencies( $wr, $f0 );
        &report_frequencies( $wr, $f1 );

        foreach my $cnt ( @cnts )
        {
            report_counts( $wr, $cnt );
            my ( $x, $p ) = map { chomp; split /\t/ } scalar <$rd>;
            if ( $x < $xmin )
            {
                $x = $xmin;
                $p = count_vs_freq_p_value( $cnt, $fmin, $max_len )

            }
            elsif ( $x > $xmax )
            {
                $x = $xmax;
                $p = count_vs_freq_p_value( $cnt, $fmax, $max_len )

            }
            push @x_p, [ $x, $p ];
        }

        close $wr if $wr;
        close $rd if $rd;
        waitpid( $pid, 0 ) if $pid;
    }

    #  Otherwise, do it in perl

    else
    {
        my $k = &k_from_f0_and_f1( $f0, $f1 );

        foreach my $cnt ( @cnts )
        {
            my ( $x, $chisqr, $df, $n ) = project_by_min_chi_sqr_2( $f0, $k, $cnt );
            my $p;
            if ( $x < $xmin )
            {
                $x = $xmin;
                $p = count_vs_freq_p_value( $cnt, $fmin, $max_len )

            }
            elsif ( $x > $xmax )
            {
                $x = $xmax;
                $p = count_vs_freq_p_value( $cnt, $fmax, $max_len )

            }
            else
            {
                $chisqr *= ( $max_len / $n ) if ( $max_len && $n > $max_len );
                $p = ( $df > 1 ) ? gjostat::chisqr_prob( $chisqr, $df ) : 1;
            }
            push @x_p, [ $x, $p ];
        }
    }

    wantarray ? @x_p : \@x_p;
}


#===============================================================================
#  Evaluate a batch of codon usages for match on an axis defined by $f0 and $f1.
#-------------------------------------------------------------------------------
#   @x_lnL = codon_counts_x_and_lnL( $f0, $f1, \%opts,   $cnt, $cnt, ... );
#  \@x_lnL = codon_counts_x_and_lnL( $f0, $f1, \%opts,   $cnt, $cnt, ... );
#   @x_lnL = codon_counts_x_and_lnL( $f0, $f1, \%opts, \@$cnts );
#  \@x_lnL = codon_counts_x_and_lnL( $f0, $f1, \%opts, \@$cnts );
#-------------------------------------------------------------------------------
sub codon_counts_x_and_lnL
{
    my ( $f0, $f1, $opts ) = splice @_, 0, 3;

    $f0   && ref( $f0 )   eq 'ARRAY' && @$f0 or return ();
    $f1   && ref( $f1 )   eq 'ARRAY' && @$f0 or return ();
    $opts && ref( $opts ) eq 'HASH' or $opts = {};

    my $max_len = $opts->{ max_len };
    my $genome  = $opts->{ genome  } || 0;

    my @cnts = is_array_of_cnts_or_freqs( $_[0] ) ? @{$_[0]} : @_;

    my @x_lnL;

    #  If there are more than 100 counts to evaluate, try a pipe.
    #  This is not yet converted from p value to lnL

    if ( 0 && @cnts > 100 && &version( 'codon_counts_x_and_p' ) )
    {
        my @eval_cmd = ( 'codon_counts_x_and_p',
                         ( $max_len ? ( '-l', $max_len ) : () )
                       );
        my ( $rd, $wr );
        my $pid = open2( $rd, $wr, @eval_cmd );
        { my $old = select $wr; $| = 1; select $old; }  #  Autoflush the write pipe
        &report_frequencies( $wr, $f0 );
        &report_frequencies( $wr, $f1 );

        foreach my $cnt ( @cnts )
        {
            report_counts( $wr, $cnt );
            my ( $x, $lnL ) = map { chomp; split /\t/ } scalar <$rd>;
            if ( $genome && $x < 0 )
            {
                $x   = 0;
                $lnL = count_vs_freq_lnL( $cnt, $f0, $max_len )

            }
            push @x_lnL, [ $x, $lnL ];
        }

        close $wr if $wr;
        close $rd if $rd;
        waitpid( $pid, 0 ) if $pid;
    }

    #  Otherwise, do it in perl

    else
    {
        my $k = &k_from_f0_and_f1( $f0, $f1 );

        foreach my $cnt ( @cnts )
        {
            my ( $x, $lnL ) = project_by_max_lnL( $f0, $k, $cnt );
            if ( $genome && $x < 0 )
            {
                $x   = 0;
                $lnL = count_vs_freq_lnL( $cnt, $f0, $max_len )

            }
            elsif ( $max_len )
            {
                my $n = n_codon( $cnt );
                $lnL *= ( $max_len / $n ) if ( $n > $max_len );
            }
            push @x_lnL, [ $x, $lnL ];
        }
    }

    wantarray ? @x_lnL : \@x_lnL;
}


#-------------------------------------------------------------------------------
#  Divide and conquer search for x value with maximum log( likelihood ).
#
#  If $counts includes an id, i.e., $counts = [ [ [ ... ], ... ], $id ]:
#
#      ( $x, $lnL, $id ) = project_by_max_lnL( $f0, $k, $counts )
#      [ $x, $lnL, $id ] = project_by_max_lnL( $f0, $k, $counts )
#
#  If $counts does not include an id, i.e., $counts = [ [ ... ], ... ]:
#
#      ( $x, $lnL )      = project_by_max_lnL( $f0, $k, $counts )
#      [ $x, $lnL ]      = project_by_max_lnL( $f0, $k, $counts )
#-------------------------------------------------------------------------------
sub project_by_max_lnL
{
    my ( $f0, $k, $counts ) = @_;

    #  Allow $counts = [ [ ... ], ... ] or [ [ [ ... ], ... ], $id ]

    my $id;
    ( $counts, $id ) = @$counts if ( ! ref $counts->[1] );
    my ( $min_x, $max_x ) = ( -5, 5 );
    my $n_step = 20;
    my $inc = ( $max_x - $min_x ) / $n_step;

    my @x_and_lnL = map { [ $_, lnL_at_x( $counts, $f0, $k, $_ ) ] }
                    map { $inc * $_ + $min_x }    # Convert counter value to x
                    ( 1 .. ($n_step-1) );         # Leave empty space at ends

    my ( $x_and_lnL ) = sort { $b->[1] <=> $a->[1] } @x_and_lnL;

    #  Divide and conquer search centered on current best point

    while ( $inc > 0.0005 )
    {
        $inc *= 0.5;
        my $x0 = $x_and_lnL->[0];
        @x_and_lnL = ( $x_and_lnL,
                       map { [ $_, lnL_at_x( $counts, $f0, $k, $_ ) ] } ( $x0-$inc, $x0+$inc )
                     );
        ( $x_and_lnL ) = sort { $b->[1] <=> $a->[1] } @x_and_lnL;
    }

    push @$x_and_lnL, $id if defined $id;

    wantarray ? @$x_and_lnL : $x_and_lnL;
}


#------------------------------------------------------------------------------
#  Given counts, $f0, $k and $x, what is the log( likelihood )?
#
#     $lnL = lnL_at_x( $counts, $f0, $k, $x )
#------------------------------------------------------------------------------
sub lnL_at_x
{
    my ( $counts, $f0, $k, $x ) = @_;
    count_vs_freq_lnL( $counts, scalar freqs_at_x( $f0, $k, $x ) )
}


#==============================================================================
#  If two sets of frequencies were drawn from the same distribution, what would
#  be the expected distance between them?  Found by analysis of random suffles
#  of the members between the two input sets.
#
#      $distance            = null_distance( \@cnt1, \@cnt2, \%options )
#    ( $distance, $stddev ) = null_distance( \@cnt1, \@cnt2, \%options )
#
#  Options:
#
#      method   => 'average' | 'mode'  #  Evaluation method: average or mode (D)
#      mode_opt => \%options           #  modal_codon_usage() options (D = {})
#      n_null   => $reps               #  Number of shuffles (D = 10)
#      n_rep    => $reps               #  Number of shuffles (D = 10)
#
#  Note: if both n_null and n_rep are supplied, the value of n_null is used.
#------------------------------------------------------------------------------
sub null_distance
{
    my ( $cnt1, $cnt2, $opt ) = @_;
    $opt ||= {};

    my $method   = $opt->{ method };
    my $mode_opt = $opt->{ mode_opt } || {}  if $method =~ /^m/i;
    my $n_rep    = $opt->{ n_null }   || $opt->{ n_rep } || 10;

    my @null_dists = map { null_distance_1( $cnt1, $cnt2, $method, $mode_opt ) }
                     ( 1 .. $n_rep );
    my ( $null_mean, $null_stddev ) = gjostat::mean_stddev( @null_dists );
    $null_stddev ||= 0;
    # foreach ( sort { $a<=>$b} @null_dists ) { printf "%.4f\n", $_ }
    wantarray ? ( $null_mean, $null_stddev ) : $null_mean;
}


sub null_distance_1
{
    my ( $cnt1, $cnt2, $method, $mode_opt ) = @_;

    my @mix1 = sort { rand() <=> 0.5 } ( @$cnt1, @$cnt2 );
    my @mix2 = splice @mix1, @$cnt1;

    my ( $freq1, $freq2 );
    if ( $method =~ m/^av/i )
    {
        $freq1 = average_freq( \@mix1 );
        $freq2 = average_freq( \@mix2 );
    }
    else
    {
        $freq1 = modal_codon_usage( \@mix1, $mode_opt );
        $freq2 = modal_codon_usage( \@mix2, $mode_opt );
    }

    codon_freq_distance( $freq1, $freq2 );
}

#==============================================================================
#  A bunch of more or less useful functions
#==============================================================================
#   $value = is_cnts_or_freqs( $ref )
#
#      0 => not a valid reference to counts or frequencies
#      1 => unlabeled counts or frequencies
#      2 => labeled counts or frequencies
#------------------------------------------------------------------------------
sub is_cnts_or_freqs
{
    local $_ = shift;
    ( $_ && ( ref($_) eq 'ARRAY' ) && @$_ ) ? ( unlabeled_c_or_f( $_ ) ? 1 :
                                                labeled_c_or_f( $_ )   ? 2 :
                                                                         0
                                              )
                                            : 0;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   $bool = unlabeled_c_or_f( $ref )
#
#   [ [ gcu, gcc, gca, gcg ], [ ugu, ugc ], ... ]
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub unlabeled_c_or_f
{
    local $_ = shift;
    return ( $_->[0] && ( ref $_->[0] eq 'ARRAY' ) && ( @{ $_->[0] } == 4 )
          && defined $_->[0]->[0] && ! ref $_->[0]->[0] );
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#   $bool = labeled_c_or_f( $ref )
#
#   [ [ [ gcu, gcc, gca, gcg ], [ ugu, ugc ], ... ], label ]
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub labeled_c_or_f
{
    local $_ = shift;
    return ( @$_ >= 2 && defined $_->[1] && ! ref $_->[1]
          && $_->[0]      && ref $_->[0]      eq 'ARRAY' && @{ $_->[0] }
          && $_->[0]->[0] && ref $_->[0]->[0] eq 'ARRAY' && @{ $_->[0]->[0] } == 4
          && defined $_->[0]->[0]->[0] && ! ref $_->[0]->[0]->[0] );
}

#------------------------------------------------------------------------------
#   $value = is_array_of_cnts_or_freqs( $ref )
#
#      0 => not a valid array of counts or frequencies
#      1 => array of unlabeled counts or frequencies
#      2 => array of labeled counts or frequencies
#------------------------------------------------------------------------------
sub is_array_of_cnts_or_freqs
{
    local $_ = shift;
    ( $_ && ref $_ eq 'ARRAY' && @$_ ) ? is_cnts_or_freqs( $_->[0] ) : 0;
}


#------------------------------------------------------------------------------
#   $value = option_by_regexp( $opts, $regexp, $default )
#------------------------------------------------------------------------------
sub option_by_regexp
{
    my ( $opts, $regexp, $default ) = @_;
    return $default if ! $opts || ref $opts ne 'HASH' || ! $regexp;
    my ( $key ) = grep { $_ =~ $regexp } keys %$opts;
    $key && defined( $opts->{ $key } ) ? $opts->{ $key } : $default
}


#------------------------------------------------------------------------------
#   $value = option_value( $opts, $regexp, $default )
#------------------------------------------------------------------------------
sub option_value
{
    my ( $opts, $key, $default ) = @_;
    $opts && ref( $opts ) eq 'HASH'
          && $key && defined( $opts->{ $key } ) ? $opts->{ $key } : $default
}


#------------------------------------------------------------------------------
#  Provide an open input file handle from undef (STDIN), empty string (STDIN),
#  glob reference, string reference or file name:
#
#   ( $fh, $close ) = input_handle( )        # STDIN
#   ( $fh, $close ) = input_handle(  '' )    # STDIN
#   ( $fh, $close ) = input_handle( \*FH )
#   ( $fh, $close ) = input_handle( \$string )
#   ( $fh, $close ) = input_handle(  $filename )
#
#  $close is true if the input parameter is a file name or scalar reference,
#  indicating that the handle should be closed upon completion of the read.
#------------------------------------------------------------------------------
sub input_handle
{
    my ( $in ) = @_;
    return ( \*STDIN, 0 ) if ( ! defined $in ) || ( $in eq '' );
    return (  $in,    0 ) if ( ref $in eq 'GLOB' );
    my $fh;
    return (  $fh,    1 ) if ( ref $in eq 'SCALAR' || -f $in ) && open( $fh, "<", $in );
    return (  undef,  0 );
}


#------------------------------------------------------------------------------
#  Provide an open output file handle from undef (STDIN), empty string (STDIN),
#  glob reference, string reference or file name:
#
#   ( $fh, $close ) = output_handle( )        # STDIN
#   ( $fh, $close ) = output_handle(  '' )    # STDIN
#   ( $fh, $close ) = output_handle( \*FH )
#   ( $fh, $close ) = output_handle( \$string )
#   ( $fh, $close ) = output_handle(  $filename )
#
#  $close is true if the output parameter is a file name or scalar reference,
#  indicating that the handle should be closed upon completion of the write.
#------------------------------------------------------------------------------
sub output_handle
{
    my $out = shift;
    return ( \*STDOUT, 0 ) if ( ! defined $out ) || ( $out eq '' );
    return (  $out,    0 ) if ( ref $out eq 'GLOB' );
    my $fh;
    return (  $fh,    1 ) if ( ref $out eq 'SCALAR' || $out ) && open( $fh, ">", $out );
    return (  undef,  0 );
}


1;
