use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

protein_families_to_co_occurring_families

=head1 SYNOPSIS

protein_families_to_co_occurring_families [arguments] < input > output

=head1 DESCRIPTION


Since we accumulate data relating to the co-occurrence (i.e., chromosomal
clustering) of genes in prokaryotic genomes,  we can note which pairs of genes tend to co-occur.
From this data, one can compute the protein families that tend to co-occur (i.e., tend to
cluster on the chromosome).  This allows one to formulate conjectures for unclustered pairs, based
on clustered pairs from the same protein_families.


Example:

    protein_families_to_co_occurring_families [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: protein_families_to_co_occurring_families [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: protein_families_to_co_occurring_families [-c column] < input > output";

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
    my $h = $kbO->protein_families_to_co_occurring_families(\@h);
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
		my $a = join("\t", @$_);
                print "$line\t$a\n";
            }
        }
        else
        {
            print "$line\t$v\n";
        }
    }
}

__DATA__
