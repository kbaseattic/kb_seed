use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

fids_to_locations

=head1 SYNOPSIS

fids_to_locations [arguments] < input > output

=head1 DESCRIPTION


A "location" is a sequence of "regions".  A region is a contiguous set of bases
in a contig.  We work with locations in both the string form and as structures.
fids_to_locations takes as input a list of fids.  For each fid, a structured location
is returned.  The location is a list of regions; a region is given as a pointer to
a list containing

             the contig,
             the beginning base in the contig (from 1).
             the strand (+ or -), and
             the length

Note that specifying a region using these 4 values allows you to represent a single
base-pair region on either strand unambiguously (which giving begin/end pairs does
not achieve).


Example:

    fids_to_locations [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: fids_to_locations [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: fids_to_locations [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
				      'i=s' => \$input_file);
if (! $kbO) { print STDERR $usage; exit }

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $result = $kbO->fids_to_locations(\@h);

#print Dumper $result;
	for my $tuple (@tuples) {
		my ($fid, $line) = @$tuple;
                my $locs = $result->{$fid};
                my @locStrings = map { join("", $_->[0], "_", $_->[1], $_->[2], $_->[3]) } @$locs;
                print "$line\t" . join(",", @locStrings) . "\n";
    }
}

__DATA__
