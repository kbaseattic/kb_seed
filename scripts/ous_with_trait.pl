use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

ous_with_trait

=head1 SYNOPSIS

ous_with_trait -g Genome -mtype MeasurementType -min MinVal -max MaxVal < traits_input > output_with_ous

=head1 DESCRIPTION

Fetches "Observational Units" having a specified trait.
An "Observational Unit" is an individual plant that
1) is part of an experiment or study,
2) has measured traits, and
3) is assayed for the purpose of determining alleles. 
 
Example:

    ous_with_trait -g Genome -mtype MeasurementType -min MinVal -max MaxVal < traits_input > output_with_ous

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the identifier.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.


=head1 COMMAND-LINE OPTIONS

Usage: ous_with_trait -g Genome -mtype MeasurementType -min MinVal -max MaxVal < traits_input > output_with_ous

    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input
    -g genome     We are extracting ous for which this is the reference genome
    -mtype Type   Measurement Type
    -min MinVal   Minimum value of measurement
    -max MaxVal   Maximum value of measurement

=head1 OUTPUT FORMAT

The standard output is a tab-delimited file. It consists of the input
file with extra columns added (the measurement vlue and an ou with that value).

Input lines that cannot be extended are written to stderr.

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use SeedUtils;

our $usage = "usage: ous_with_trait [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $genome;
my $meas_type;
my $min = 0.0;
my $max = 100000000.0;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
						       'g=s' => \$genome,
						       'mtype=s' => \$meas_type,
						       'min=f' => \$min,
						       'max=f' => \$max,
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
        my ($trait, $line) = @$tuple;
	$genome || die "you need to specify a genome";
	$meas_type  || die "you need to specify a measurement type";
	my $ous_and_measurements = $kbO->ous_with_trait($genome,$trait,$meas_type,$min,$max);
	foreach my $_ (@$ous_and_measurements)
	{
	    my($ou,$mval) = @$_;
	    print join("\t",($line,$mval,$ou)),"\n";
	}
    }
}

__DATA__
