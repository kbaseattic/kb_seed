use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

fids_to_coexpressed_fids

=head1 SYNOPSIS

fids_to_coexpressed_fids [arguments] < input > output

=head1 DESCRIPTION


The routine fids_to_coexpressed_fids returns (for each input fid) a
list of features that appear to be coexpressed.  That is,
for an input fid, we determine the set of fids from the same genome that
have Pearson Correlation Coefficients (based on normalized expression data)
greater than 0.5 or less than -0.5.


Example:

    fids_to_coexpressed_fids [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: fids_to_coexpressed_fids [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: fids_to_coexpressed_fids [-c column] < input > output";

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
    my $h = $kbO->fids_to_coexpressed_fids(\@h);
    for my $tuple (@tuples) {
        #
        # Process output here and print.
        #
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};

        if (! defined($v))
        {
            print STDERR $line,"\n";
        }
        elsif (ref($v) eq 'ARRAY')
        {
            foreach $_ (@$v)
            {
		my($fid,$pcc) = @$_;
                print "$line\t$pcc\t$fid\n";
            }
        }
    }
}

__DATA__
