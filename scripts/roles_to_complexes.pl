use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

roles_to_complexes

=head1 SYNOPSIS

roles_to_complexes [arguments] < input > output

=head1 DESCRIPTION


roles_to_complexes allows a user to connect Roles to Complexes,
from there, the connection exists to Reactions (although in the
actual ER-model model, the connection from Complex to Reaction goes through
ReactionComplex).  Since Roles also connect to fids, the connection between
fids and Reactions is induced.

Example:

    roles_to_complexes [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output. For each line of input there may be multiple lines of output, one per complex associated with the role. Two columns are appended to the input line, the optional flag, and the complex id.

=head1 COMMAND-LINE OPTIONS

Usage: roles_to_complexes [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: roles_to_complexes [-c column] < input > output";

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
    my $h = $kbO->roles_to_complexes(\@h);
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
        else
        {
            foreach $_ (@$v)
            {
		my($complex,$optional) = @$_;
                print "$line\t$optional\t$complex\n";
            }
        }
    }
}

__DATA__
