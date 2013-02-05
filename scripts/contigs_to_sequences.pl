use strict;
use Data::Dumper;
use Carp;
use gjoseqlib;

#
# This is a SAS Component
#

=head1 NAME

contigs_to_sequences

=head1 SYNOPSIS

contigs_to_sequences [arguments] < input > output

=head1 DESCRIPTION


contigs_to_sequences is used to access the DNA sequence associated with each of a set
of input contigs.  It takes as input a set of contig IDs (from which the genome can be determined) and
produces a mapping from the input IDs to the returned DNA sequence in each case.

Normally, people want to get back a fasta file, so that is the default (the input table
is essentially discarded, keeping only the fasta file).  The alternative to to add a column
to the table (containing the contig sequence).  The "-fasta=0" argument should be used, if you
do not want fasta output. 

Example:

    contigs_to_sequences [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: contigs_to_sequences [arguments] < input > output


    -c num        Select the identifier from column num
    --fasta integer
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: contigs_to_sequences [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $fasta = 1;
my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
				     'fasta=i' => \$fasta,
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

my %fasta_written;   # to remove any possible duplicates
while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $kbO->contigs_to_sequences(\@h);

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
		if ($fasta)
		{
		    if (! $fasta_written{$id})
		    {
			$fasta_written{$id} = 1;
			#print ">$id\n$_\n";
			write_fasta([$id, undef, $_]);
		    }
		}
		else
		{
		    print "$line\t$_\n";
		}
            }
        }
        else
        {
	    if ($fasta)
	    {
		if (! $fasta_written{$id})
		{
		    $fasta_written{$id} = 1;
		    write_fasta([$id, undef, $v]);
		    #print ">$id\n$v\n";
		}
	    }
	    else
	    {
		print "$line\t$v\n";
	    }
        }
    }
}

__DATA__
