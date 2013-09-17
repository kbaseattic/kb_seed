#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use SAPserver;
use ScriptThing;

#
#	This is a SAS Component.
#

=head1 readable_fasta

    readable_fasta < fasta > fasta.with.60-char.lines

This script takes as input a FASTA file and writes it such that sequence
is broken into 60-character lines (rather than very long lines).

=cut

$/ = "\n>";
while (defined($_ = <STDIN>))
{
    chomp;
    if ($_ =~ /^\>?([^\n]*)\n(.*)/s)
    {
	my($hdr,$seq) = ($1,$2);
	print ">$hdr\n";
	$seq =~ s/\s//g;
	my $i = 0;
	while ($i < (length($seq) - 60))
	{
	    print substr($seq,$i,60),"\n";
	    $i += 60;
	}
	if ($i < length($seq)) { print substr($seq,$i),"\n" }
    }
}

