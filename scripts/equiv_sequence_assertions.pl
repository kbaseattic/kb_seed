use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

equiv_sequence_assertions

=head1 SYNOPSIS

equiv_sequence_assertions [arguments] < input > output

=head1 DESCRIPTION


Different groups have made assertions of function for numerous protein sequences.
The equiv_sequence_assertions allows the user to gather function assertions from
all of the sources.  Each assertion includes a field indicating whether the person making
the assertion viewed themself as an "expert".  The routine gathers assertions for all
proteins having identical protein sequence.


Example:

    equiv_sequence_assertions [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain a protein identifier (i.e., an md5 value). 
If another column contains the md5s
use

    -c N

where N is the column (from 1) that contains the protein identifiers.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: equiv_sequence_assertions [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: equiv_sequence_assertions [-c column] < input > output";

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
    my $h = $kbO->equiv_sequence_assertions(\@h);
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
		print join("\t",($line,@$_)),"\n";
            }
        }
        else
        {
            print "$line\t$v\n";
        }
    }
}

__DATA__
