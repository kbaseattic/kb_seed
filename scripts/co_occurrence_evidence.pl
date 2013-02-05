use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

co_occurrence_evidence

=head1 SYNOPSIS

co_occurrence_evidence [-c column] < input > output

=head1 DESCRIPTION

co-occurence_evidence is used to retrieve the detailed pairs of genes that go into the
computation of co-occurence scores.  The scores reflect an estimate of the number of distinct OTUs that
contain an instance of a co-occuring pair.  This routine returns as evidence a list of all the pairs that
went into the computation.

The input to the computation is table in which one of the columns contains 
co-occurring pairs.  For example,

     echo 'kb|g.0.peg.101:kb|g.0.peg.263' | co_occurrence_evidence 

takes in a table with 1 column and one row.  The input row is a single pair
of related fids joined using a ':'.

The output is a table with an added (usually huge) column containing the evidence that
the pair of fids are,in fact, related.  The evidence is a comma-separated list of pairs
(each pair being two fids joined with ':').  Thus the command above produces

           kb|g.0.peg.101:kb|g.0.peg.263	kb|g.0.peg.101:kb|g.0.peg.263,kb|g.10.peg.3334:kb|g.10.peg.3978,...

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: co_occurrence_evidence [-c column] < input > output

    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head OUTPUT FORMAT

The standard output is a tab-delimited file. It consists of the input
file with an extra column (containing large evidence strings)  added.

Input lines that cannot be extended are written to stderr.

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: co_occurrence_evidence [-c column] < input > output";

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
    my @h;
    my %lines;
    foreach my $tuple (@tuples) {
	my ($id, $line) = @$tuple;
        my ($a, $b) =  split(":", $id);
	push (@h, [$a, $b]);
	#make a hash so I can look up the line;
	$lines{$id} = $line;
    }
    my $h = $kbO->co_occurrence_evidence(\@h);

    foreach my $p (@$h) {
	my $a = join(":", @{$p->[0]});
        my @b;
	foreach my $pair (@{$p->[1]}) {
		push (@b, join(":", @$pair));
	}

	print $lines{$a}, "\t";;
	print join(",",@b), "\n";
    }
}

__DATA__
