use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

region_to_fids

=head1 SYNOPSIS

region_to_fids [arguments] <input > output

=head1 DESCRIPTION

This command is used to take positions in contigs and to find fids
that ocur within a specified distance of each position.  It differs
from locations_to_fids in which locations (list of regions) are
explicitly given. 

Example:

    region_to_fids -d 10000 < input > output [gets fids within 10kb of the positions]

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the position. If another column contains the positions
use

    -c N

where N is the column (from 1) that contains the identifier.

Positions are represented as Contig_Pos or Contig_Pos+1.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.


=head1 COMMAND-LINE OPTIONS

Usage: region_to_fids [arguments] <input > output

    -d Distance   All feature-IDs within this distance of a query will be reported (Default=5000)
    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use SeedUtils;

our $usage = "usage: region_to_fids [-c column] [-d distance] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $d = 5000;

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
	my $fids = $kbO->region_to_fids([$contig,$beg,$strand,$ln]);
	foreach my $fid (@$fids)
	{
	    print join("\t",($line,$fid)),"\n";
	}
    }
}

__DATA__
