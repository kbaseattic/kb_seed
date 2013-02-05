use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

proteins_to_functions

=head1 SYNOPSIS

proteins_to_functions [arguments] < input > output

=head1 DESCRIPTION


The routine proteins_to_functions allows users to access functions associated with
specific protein sequences.  The input proteins are given as a list of MD5 values
(these MD5 values each correspond to a specific protein sequence).  For each input
MD5 value, a list of [feature-id,function] pairs is constructed and returned.
Note that there are many cases in which a single protein sequence corresponds
to the translation associated with multiple protein-encoding genes, and each may
have distinct functions (an undesirable situation, we grant).

This function allows you to access all of the functions assigned (by all annotation
groups represented in Kbase) to each of a set of sequences.


Example:

    proteins_to_functions [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output. For each input line there are multiple output lines, one for each fid the protein maps to. Two columns are added to each output line, a fid and a function.

=head1 COMMAND-LINE OPTIONS

Usage: proteins_to_functions [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: proteins_to_functions [-c column] < input > output";

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
    my $h = $kbO->proteins_to_functions(\@h);
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
