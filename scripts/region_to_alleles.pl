use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

region_to_alleles

=head1 SYNOPSIS

region_to_alleles [-c Column] [-d regionSize] < input > output
region_to_alleles [-c Column] [-d regionSize] -i input > output

=head1 DESCRIPTION

Example:

    region_to_alleles [-d 10000] < input > output

Here the region will be 20kb centered on the input positions.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: region_to_alleles [-c Column] [-d regionSize] < input > output
Usage: region_to_alleles [-c Column] [-d regionSize] -i input > output

    -d Distance   Width of region in base-pairs on either side of feature (Default=5000)
    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 OUTPUT FORMAT

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.

Input lines that cannot be extended are written to stderr.

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use SeedUtils;

our $usage = "usage: region_to_alleles [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $d = 5000;
my $column;

my $input_file;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
						       'd=i' => \$d,
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
    foreach my $tuple (@tuples)
    {
	print STDERR &Dumper($tuple);
	my($position,$line) = @$tuple;
	my($contig,$pos,$strand,$len);

	if ($position =~ /^(\S+)\_(\d+)$/)
	{
	    ($contig,$pos,$strand,$len) = ($1,$2,'+',1);
	}
	elsif ($position =~ /^(\S+)\_(\d+)\+1$/)
	{
	    ($contig,$pos,$strand,$len) = ($1,$2,'+',1);
	}
	my $beg = $pos - $d;
	if ($beg < 1) { $beg = 1 }
	my $ln = 2 * $d;
	my $tuples = $kbO->region_to_alleles([$contig,$beg,$strand,$ln]);
	foreach my $tuple (@$tuples)
	{
	    print join("\t",($line,$tuple->[0])),"\n";
	}
    }
}

__DATA__
