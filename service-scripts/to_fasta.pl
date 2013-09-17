#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;

#
#	This is a SAS Component.
#

=head1 to_fasta

    to_fasta < tab.separated.table  > fasta.sequences

This script takes as input a tab-delimited file with one column of
DNA or sequence data.  The other columns are used to construct the ID
and comment fields, and a FASTA-formatted file is produced.  You need to
designate which column has the ID, and which columns go into building the COMMENT.

=head2 Command-Line Options

=over 4

=item -id Ni

Specifies the column containing the ID for the FASTA entries

=item -seq Ns

Specifies the column containing the sequence

=item -comment x,y,z

The comment will be formed as [contents-of-x] [contents-of-y]...

=back

=cut

# Parse the command-line options.
my $id;
my $seq;
my $comment = '';
my $opted =  GetOptions('id=i' => \$id, 
                        'seq=i' => \$seq, 
			'comment=s' => \$comment);
defined($id)   || die "You need to specify the column containing ids using '-id N'";
defined($seq)  || die "You need to specify the column containing sequence using '-seq N'";
my @comment;
if ($comment)
{
    @comment = grep { $_ =~ /^\d+$/ } split(/\s*,\s*/,$comment);
}
while (defined($_ = <STDIN>))
{
    chop;
    my @fields = split(/\t/,$_);
    my $id = $fields[$id-1];
    my $seq = $fields[$seq-1];
    my @tmp = map { "[" . $fields[$_-1] . "]" } @comment;
    my $c = join(' ',@tmp);
    print ">$id $c\n$seq\n";
}
