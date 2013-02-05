use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

fids_to_protein_sequences

=head1 SYNOPSIS

fids_to_protein_sequences [arguments] < input > output

=head1 DESCRIPTION


fids_to_protein_sequences allows the user to look up the amino acid sequences
corresponding to each of a set of fids.  You can also get the sequence from proteins (i.e., md5 values).
This routine saves you having to look up the md5 sequence and then accessing
the protein string in a separate call.


Example:

    fids_to_protein_sequences [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: fids_to_protein_sequences [arguments] < input > output


    -c num        Select the identifier from column num
    --fasta integer
    --fc string
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: fids_to_protein_sequences [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $fasta = 1;
my $fasta_comment;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
				     'fasta=i' => \$fasta,
				     'fc=s'    => \$fasta_comment,
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
    my $h = $kbO->fids_to_protein_sequences(\@h);
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
            foreach my $seq (@$v)
            {
		if ($fasta)
		{
		    if (! $fasta_written{$id})
		    {
			$fasta_written{$id} = 1;
			my $hdr = "";
			if ($fasta_comment)
			{
			    my @fields = split(/\t/,$line);
			    $hdr = join("; ",map { $fields[$_-1] } split(/,/,$fasta_comment));
			}
			print ">$id $hdr\n$_\n";
		    }
		}
		else
		{
		    print "$line\t$seq\n";
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
		    my $hdr = "";
		    if ($fasta_comment)
		    {
			my @fields = split(/\t/,$line);
			$hdr = join("; ",map { $fields[$_-1] } split(/,/,$fasta_comment));
		    }
		    print ">$id $hdr\n$v\n";
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
