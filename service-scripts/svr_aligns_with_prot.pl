#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use AlignsAndTreesServer qw(data_on_aligns_with_prot);

#
#	This is a SAS Component.
#

=head1 svr_aligns_with_prot

    svr_aligns_with_prot         < fid-md5 > table-with-2-more-columns
    svr_aligns_with_prot --roles < fid-md5 > table-with-4-more-columns
    svr_aligns_with_prot --text  < fid-md5 > textual-descriptions

Get the list of alignments associated with each specified protein or fid.

This script takes as input a tab-delimited file with gene or protein IDs at 
the end of each line. For each ID, the associated alignment data are retrieved
and appended.

This is a pipe command: the input is taken from the standard input and the output
is to the standard output.

If a single ID is associated with multiple alignments, there will be one 
output line for each alignment.

Similarly, the --roles option adds one line per role found in the tree

=head2 Command-Line Options

=over 4

=item c

Column index. If specified, indicates that the input IDs should be taken from the
indicated column instead of the last column. The first column is column 1.

=item roles

Add two additional columns with roles and their counts in the alignment.
The number of roles is capped at 25 most commonly occurring.

=item text

Output data in a more human friendly manner. Implies -roles.

=item url

The URL for the Sapling server, if it is to be different from the default.

=back

=cut

my $usage = <<'End_of_Usage';

Usage:

    svr_aligns_with_prot         < fid-md5 > table-plus-coverage-alignID
    svr_aligns_with_prot --text  < fid-md5 > textual-descriptions

Get the list of alignments associated with each specified protein or fid.

This script takes as input a tab-delimited file with gene or protein IDs at 
the end of each line. For each ID, the protein sequence coverage and alignID
are added for each alignment containing the sequence.

This is a pipe command: the input is taken from the standard input and the
output is to the standard output.

If a single ID is associated with multiple alignments, there will be one 
output line for each alignment.

The --roles option adds two additional columns of data, count and role,
and generates one line per role found in each tree.

Command-Line Options:

   --c index # Column index. If specified, indicates that the input IDs should
             # be taken from the indicated column instead of the last column.
             # The first column is column 1.

   --roles   # Add number of occurrences and functional roles for each
             # alignment. The number of roles per alignment is capped at the
             # 25 most commonly occurring.

   --text    # The output data are displayed in a more human friendly manner.
             # Implies --roles.

   --url url # The URL for the Sapling server, if it is to be different from
             # the default.

End_of_Usage

# Parse the command-line options.

my $column   = '';
my $coverage =  0;
my $help     = '';
my $roles    = '';
my $text     = '';
my $url      = '';
GetOptions( 'c=i'        => \$column,
            'coverage=f' => \$coverage,
            'help'       => \$help,
            'roles'      => \$roles,
            'text'       => \$text,
            'url=s'      => \$url
          )
    or print STDERR $usage
        and exit;

print STDERR $usage and exit if $help;

$column ||= -1;
$column-- if $column > 0;

$roles  ||= $text;

# Get the server object.

my $sapServer     = SAPserver->new(url => $url);

my $opts = {};
$opts->{sap}      = $sapServer;
$opts->{roles}    = $roles ? 25 : 0;
$opts->{coverage} = $coverage if $coverage;

# The main loop processes lines of input:

my %cache;
my $line;
while ( defined( $line = <> ) )
{
    chomp $line;
    my ( $id ) = ( split /\t/, $line )[$column];
    $id or next;

    # Ask the server for results.

    my $aligns = $cache{$id} ||= AlignsAndTreesServer::data_on_aligns_with_prot( $id, $opts );

    print "\n$id\n\n" if $text;
    foreach ( @$aligns )
    {
        my ( $align_id, $cover, $role_data ) = @$_;
        my $cover_str = @{$cover||[]} ? $text ? " covers residues $cover->[0]-$cover->[1] of $cover->[2]"
                                              : "$cover->[0]-$cover->[1]/$cover->[2]"
                                      : "";

        if ( $text )
        {
            print "$align_id$cover_str\n";
            if ( $role_data )
            {
                foreach ( @$role_data ) { printf "%8d  %s\n", @$_[1,0] }
                print "\n";
            }
        }
        else
        {
            my $line2 = join( "\t", $line, $cover_str, $align_id );
            if ( $role_data )
            {
                foreach ( @$role_data )
                {
                    print join( "\t", $line2, @$_[1,0] ) . "\n";
                }
            }
            else
            {
                 print "$line2\n";
            }
        }
    }
}

