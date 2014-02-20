# This is a SAS component.

use strict;
use bidir_best_hits qw( bbh );
# use Data::Dumper;

my $usage = <<"End_of_Usage";

Usage:

   find_bidir_best_hits [options] file1 file2 [blast_options] > BDBHs

Options:

    -c min_cover      #  minimum coverage of query and subject (D = 0.30)
    -e max_eval       #  maximum E-value (D = 1e-5)
    -f                #  append function from file1
    -F                #  append function from file2
    -i min_ident      #  minimum fraction identity (D = 0.1)
    -l                #  write log file of matches for each genome as query
    -p min_positives  #  minimum fraction positive-scoring positions (D = 0.2)

   log file ouput for each genome:

      qid \\t qlen \\t type [ \\t sid \\t slen \\t fract_id \\t fract_pos \\t q_cover \\t s_cover

Output:
   
      id1 \\t id2 \\t len1 \\t len2 \\t score \\t fract_id \\t fract_pos \\t q_cover \\t s_cover \\n

End_of_Usage

my $func1         = 0;
my $func2         = 0;
my $log_file      = 0;
my $max_e_val     = 1e-5;
my $min_cover     = 0.30;
my $min_ident     = 0.10;
my $min_positives = 0.20;

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    $_ = shift @ARGV;
    if ( s/^c// ) { $min_cover     = /./ ? $_ : shift @ARGV; next }
    if ( s/^e// ) { $max_e_val     = /./ ? $_ : shift @ARGV; next }
    if ( s/^i// ) { $min_ident     = /./ ? $_ : shift @ARGV; next }
    if ( s/^p// ) { $min_positives = /./ ? $_ : shift @ARGV; next }

    if ( s/f//g ) { $func1    = 1 }
    if ( s/F//g ) { $func2    = 1 }
    if ( s/l//g ) { $log_file = 1 }

    if ( /./ ) { print STDERR "Bad flag '$_'\n$usage"; exit }
}

my $file1 = shift @ARGV;
my $file2 = shift @ARGV;
$file1 && -f $file1 or print STDERR "Missing file1.\n$usage" and exit;
$file2 && -f $file2 or print STDERR "Missing file2.\n$usage" and exit;

my $options = { min_cover     => $min_cover,
                min_positives => $min_positives,
                min_ident     => $min_ident,
                max_e_val     => $max_e_val,
                program       => 'blastp',
                blast_opts    => join( ' ', @ARGV ),
                verbose       => 1
              };

my ( $bbh, $log1, $log2 ) = bidir_best_hits::bbh( $file1, $file2, $options );

if ( $func1 && open( FASTA, "<$file1" ) )
{
    my %def = map { chomp; /^>\s*(\S+)\s+(.*\S)/ ? ( $1 => $2 ) : () } <FASTA>;
    close( FASTA );

    my $def;
    foreach ( @$bbh ) { push @$_, defined( $def = $def{ $_->[0] } ) ? $def : '' }
}

if ( $func2 && open( FASTA, "<$file2" ) )
{
    my %def = map { chomp; /^>\s*(\S+)\s+(.*\S)/ ? ( $1 => $2 ) : () } <FASTA>;
    close( FASTA );

    my $def;
    foreach ( @$bbh ) { push @$_, defined( $def = $def{ $_->[1] } ) ? $def : '' }
}

foreach ( @$bbh ) { print join( "\t", @$_ ), "\n" }

if ( $log_file )
{
    my $genome1 = $file1;
    $genome1 =~ s|.*/||;
    my $genome2 = $file2;
    $genome2 =~ s|.*/||;

    my $log = "${genome1}_vs_$genome2.log";
    open LOG, ">$log" or print STDERR "Could not open log $log\n"
                           and exit;
    foreach ( @$log1 ) { print LOG join( "\t", @$_ ), "\n" }
    close LOG;

    $log = "${genome2}_vs_$genome1.log";
    open LOG, ">$log" or print STDERR "Could not open log $log\n"
                           and exit;
    foreach ( @$log2 ) { print LOG join( "\t", @$_ ), "\n" }
    close LOG;
}

exit;
