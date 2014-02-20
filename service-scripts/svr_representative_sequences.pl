#! /usr/bin/perl

#
# This is a SAS Component
#

=head1 svr_representative_sequences [ opts ] [ rep_seqs_0 ] < new_seqs > rep_seqs

usage: representative_sequences [ opts ] [ rep_seqs_0 ] < new_seqs > rep_seqs

       -a                - number of threads used by blastall (D=2)
       -b                - order input sequences by size (long to short)
       -c cluster_type   - behavior of clustering algorithm (0 or 1, D=1)
       -d seq_clust_dir  - directory for files of clustered sequencees
       -f id_clust_file  - file with one line per cluster, listing its ids 
       -g keep_gid_list  - list of genome IDs to keep
       -i keep_id_list   - list of sequence IDs to keep
       -l log_file       - real-time record of clustering, one line per seq
       -m measure_of_sim - measure of similarity to use:
                               identity_fraction  (default),
                               positive_fraction  (proteins only), or
                               score_per_position (0-2 bits)
       -s similarity     - similarity required to be clustered (D = 0.8)

    Sequences are clustered, with one representative sequence reported for
    each cluster.  rep_seqs_0 is an optional file of sequences to be assigned
    to unique clusters, regardless of their similarities.  Each new sequence
    is added to the cluster with the most similar representative sequence, or,
    if its similarity to any existing representative is less than 'similarity',
    it becomes the representative of a new cluster.  With the -d option,
    each cluster of sequences is written to a distinct file in the specified
    directory.  With the -f option, for each cluster, a tab-separated list
    of ids is written to the specified file.  With the -l option, the id of
    each sequence analyzed is written to the log file, followed by the id of
    the sequence that represents it (when appropriate).

    cluster_type 0 is the original method, which has only the representative
    for each group in the blast database.  This can randomly segregate
    distant members of groups, regardless of the placement of other very
    similar sequences.
    
    cluster_type 1 adds more diverse representatives of a group in the blast
    database.  This is slightly more expensive, but is much less likely to
    split close relatives into different groups.

=head2 Command-Line options

=over 4

=item -a

Number of threads used by blastall (D=2)

=item -b

order input sequences by size (long to short)

=item -c cluster_type

behavior of clustering algorithm (0 or 1, D=1)

cluster_type 0 is the original method, which has only the representative
for each group in the blast database.  This can randomly segregate
distant members of groups, regardless of the placement of other very
similar sequences.
    
cluster_type 1 adds more diverse representatives of a group in the blast
database.  This is slightly more expensive, but is much less likely to
split close relatives into different groups.

=item -d  seq_clust_dir  - directory for files of clustered sequencees

With the -d option, each cluster of sequences is written to a 
distinct file in the specified directory.

=item -f id_clust_file  - file with one line per cluster, listing its ids 

With the -f option, for each cluster, a tab-separated list
of ids is written to the specified file.  

=item -g keep_gid_list  - list of genome IDs to keep (i.e., keep all ids from these genomes)

The file specified contains lines beginning with a genome ID.  Any IDs for these genomes are
always kept.

=item -i keep_id_list   - list of sequence IDs to keep

The specified file contains lines, each of which is a list of comma-separated FIG IDs.
Sequences with these IDs are always kept.

=item -l log_file       - real-time record of clustering, one line per seq

This is used to see the details of the clustering process.  We doubt that most users
should find it necessary.

=item -m measure_of_sim - measure of similarity to use:

Sequences are removed if there similarity to a "kept" sequence exceeds a specified 
threshold (see -similarity below)

The possible measures of similarity that you can specify are as follows:
      
identity_fraction  (default),
positive_fraction  (proteins only), or
score_per_position (0-2 bits)

=item -s similarity     - similarity required to be clustered (D = 0.8)

The similarity threshhold used to determine when sequences are deleted (but
represented by a kept sequence).

=back

=head2 Command-Line Arguments

You have the option of reading all of the sequences from STDIN, but you can also
specify a set of files as arguments on the command line.  All of these files (plus
STDIN) are sources for the input sequences.

=head2 Output

The set of retained sequences is written to STDOUT.  Which sequences are represented
by each retained sequence can be determined by the output indicated in -f (a file
of grouped sequences, one group per line) or in -d (a directory in which each file
represents a single group).

=cut


use gjoseqlib;
use representative_sequences;
use strict;

my $usage = <<"End_of_Usage";

usage: svr_representative_sequences [ opts ] [ rep_seqs_0 ] < new_seqs > rep_seqs

       -a                - number of threads used by blastall (D=2)
       -b                - order input sequences by size (long to short)
       -c cluster_type   - behavior of clustering algorithm (0 or 1, D=1)
       -d seq_clust_dir  - directory for files of clustered sequencees
       -f id_clust_file  - file with one line per cluster, listing its ids 
       -g keep_gid_list  - list of genome IDs to keep
       -i keep_id_list   - list of sequence IDs to keep
       -l log_file       - real-time record of clustering, one line per seq
       -m measure_of_sim - measure of similarity to use:
                               identity_fraction  (default),
                               positive_fraction  (proteins only), or
                               score_per_position (0-2 bits)
       -s similarity     - similarity required to be clustered (D = 0.8)

    Sequences are clustered, with one representative sequence reported for
    each cluster.  rep_seqs_0 is an optional file of sequences to be assigned
    to unique clusters, regardless of their similarities.  Each new sequence
    is added to the cluster with the most similar representative sequence, or,
    if its similarity to any existing representative is less than 'similarity',
    it becomes the representative of a new cluster.  With the -d option,
    each cluster of sequences is written to a distinct file in the specified
    directory.  With the -f option, for each cluster, a tab-separated list
    of ids is written to the specified file.  With the -l option, the id of
    each sequence analyzed is written to the log file, followed by the id of
    the sequence that represents it (when appropriate).

    cluster_type 0 is the original method, which has only the representative
    for each group in the blast database.  This can randomly segregate
    distant members of groups, regardless of the placement of other very
    similar sequences.
    
    cluster_type 1 adds more diverse representatives of a group in the blast
    database.  This is slightly more expensive, but is much less likely to
    split close relatives into different groups.

End_of_Usage

my $n_thread      = 2;
my $by_size       = undef;
my $cluster_type  = 1;
my $seq_clust_dir = undef;
my $id_clust_file = undef;
my $log           = undef;
my $threshold     = 0.80;
my $measure       = 'identity_fraction';
my $keep_id_file  = undef;
my $keep_gid_file = undef;

while ( $ARGV[0] =~ /^-/ )
{
    $_ = shift @ARGV;
    if    ($_ =~ s/^-a//) { $n_thread      = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-b//) { $by_size       = 1 }
    elsif ($_ =~ s/^-c//) { $cluster_type  = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-d//) { $seq_clust_dir = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-f//) { $id_clust_file = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-g//) { $keep_gid_file = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-i//) { $keep_id_file  = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-l//) { $log           = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-m//) { $measure       = ($_ || shift @ARGV) }
    elsif ($_ =~ s/^-s//) { $threshold     = ($_ || shift @ARGV) }
    else                  { print STDERR  "Bad flag: '$_'\n$usage"; exit 1 }
}

# Is there a starting set of representative sequences?

my $repF = undef;
my @reps = ();

if ( @ARGV )
{
    ( $repF = shift @ARGV )
        && ( -f $repF )
        && ( @reps = &gjoseqlib::read_fasta( $repF ) )
        && ( @reps )
            or print STDERR "Bad representative sequences starting file: $repF\n"
            and print STDERR $usage
            and exit 1;
}

if ( $log )
{
    open LOG, ">$log"
        or print STDERR "Unable to open log file '$log'\n$usage"
        and exit 1;
}

my @seqs = &gjoseqlib::read_fasta( \*STDIN );
@seqs or print STDERR "Failed to read sequences from stdin\n$usage"
      and exit 1;

my %options = ( max_sim  => $threshold,
                n_thread => $n_thread,
                sim_meas => $measure
              );

$options{ by_size } = 1     if $by_size;
$options{ logfile } = \*LOG if $log;


my @keep_ids;
my @keep_gids;

if (defined $keep_gid_file)
{
    open F, "<$keep_gid_file"
        or die "Unable to open $keep_gid_file";
    while (<F>) {
        chomp;
        push @keep_gids, map { /(\d+\.\d+)/ ? "fig\|$1" : () } split /[\s,]+/, $_;
    }
    close F;
}

if (defined $keep_id_file)
{
    open F, "<$keep_id_file"
        or die "Unable to open $keep_id_file";
    while (<F>) {
        chomp;
        push @keep_ids, split /[\s,]+/, $_; 
    }    
    close F;
}

$options{ keep_gid }  = \@keep_gids if @keep_gids;
$options{ keep_id }   = \@keep_ids  if @keep_ids;

my ( $rep, $reping );

if ( $cluster_type == 1 )
{
    ( $rep, $reping ) = &representative_sequences::rep_seq( ( @reps ? \@reps : () ),
                                                             \@seqs,
                                                             \%options
                                                          );
}
else
{
    ( $rep, $reping ) = &representative_sequences::rep_seq_2( ( @reps ? \@reps : () ),
                                                               \@seqs,
                                                               \%options
                                                            );
}

close( LOG ) if $log;

&gjoseqlib::print_alignment_as_fasta( $rep );

if ( $id_clust_file )
{
    open FILE, ">$id_clust_file"
        or print STDERR "Could not open id_clust_file '$id_clust_file'\n$usage"
        and exit 1;
    foreach ( map { $_->[0] } @$rep )
    {
        print FILE join( "\t", $_, @{ $reping->{$_} } ), "\n";
    }
    close FILE;
}

if ( $seq_clust_dir )
{
    mkdir $seq_clust_dir if ! -d $seq_clust_dir;
    -d $seq_clust_dir
        or print STDERR "Could not make seq_clust_dir '$seq_clust_dir'\n$usage"
        and exit 1;
    chdir $seq_clust_dir;

    my %index = map { $_->[0] => $_ } @reps, @seqs;

    my $file = 'group00000';
    foreach ( map { $_->[0] } @$rep )
    {
        my $cluster = [ map { $index{$_} } $_, @{ $reping->{$_} } ];
        &gjoseqlib::print_alignment_as_fasta( ++$file, $cluster );
    }
}

