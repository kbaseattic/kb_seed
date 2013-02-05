use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

proteins_to_protein_families

=head1 SYNOPSIS

proteins_to_protein_families [arguments] < input > output

=head1 DESCRIPTION


Protein families contain a set of isofunctional homologs.  proteins_to_protein_families
can be used to look up is used to get the set of protein_families containing a specified protein.
For performance reasons, you can submit a batch of proteins (i.e., a list of proteins),
and for each input protein, you get back a set (possibly empty) of protein_families.
Specific collections of families (e.g., FIGfams) usually require that a protein be in
at most one family.  However, we will be integrating protein families from a number of
sources, and so a protein can be in multiple families.


Example:

    proteins_to_protein_families [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the protein.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output. For each protein, the family it belongs to is added at the end of the input line.

=head1 COMMAND-LINE OPTIONS

Usage: proteins_to_protein_families [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: proteins_to_protein_families [-c column] < input > output";

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
    my $h = $kbO->proteins_to_protein_families(\@h);
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
                print "$line\t$_\n";
            }
        }
        else
        {
            print "$line\t$v\n";
        }
    }
}

__DATA__
