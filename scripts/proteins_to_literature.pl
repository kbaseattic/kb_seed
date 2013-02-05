use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

proteins_to_literature

=head1 SYNOPSIS

proteins_to_literature [arguments] < input > output

=head1 DESCRIPTION


The routine proteins_to_literature can be used to extract the list of papers
we have associated with specific protein sequences.  The user should note that
in many cases the association of a paper with a protein sequence is not precise.
That is, the paper may actually describe a closely-related protein (that may
not yet even be in a sequenced genome).  Annotators attempt to use best
judgement when associating literature and proteins.  Publication references
include [pubmed ID,URL for the paper, title of the paper].  In some cases,
the URL and title are omitted.  In theory, we can extract them from PubMed
and we will attempt to do so.


Example:

    proteins_to_literature [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: proteins_to_literature [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: proteins_to_literature [-c column] < input > output";

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
    my $h = $kbO->proteins_to_literature(\@h);
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
