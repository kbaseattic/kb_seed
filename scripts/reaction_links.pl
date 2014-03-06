use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

reaction_links

=head1 SYNOPSIS

reaction_links [arguments] < input > output

=head1 DESCRIPTION


Reaction_links are links to a web page in KBase with reaction details.


Example:

    reaction_links [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain a reaction ID. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: reaction_links [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: reaction_links [-c column] < input > output";

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
    for my $tuple (@tuples) {
        print $tuple->[1]."\t".'<a href="http://demo.kbase.us/functional-site/#/rxns/'.$tuple->[0].'">'.$tuple->[0]."</a>\n";
    }
}

__DATA__
