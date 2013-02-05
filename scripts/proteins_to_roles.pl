use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

proteins_to_roles

=head1 SYNOPSIS

proteins_to_roles [arguments] < input > output

=head1 DESCRIPTION


The routine proteins_to_roles allows a user to gather the set of functional
roles that are associated with specifc protein sequences.  A single protein
sequence (designated by an MD5 value) may have numerous associated functions,
since functions are treated as an attribute of the feature, and multiple
features may have precisely the same translation.  In our experience,
it is not uncommon, even for the best annotation teams, to assign
distinct functions (and, hence, functional roles) to identical
protein sequences.

For each input MD5 value, this routine gathers the set of features (fids)
that share the same sequence, collects the associated functions, expands
these into functional roles (for multi-functional proteins), and returns
the set of roles that results.

Note that, if the user wishes to see the specific features that have the
assigned functional roles, they should use proteins_to_functions instead (it
returns the fids associated with each assigned function).


Example:

    proteins_to_roles [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output. For each input line, there can be multiple output lines, one for each role the protein can map to. The role is added to the end of each line.

=head1 COMMAND-LINE OPTIONS

Usage: proteins_to_roles [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: proteins_to_roles [-c column] < input > output";

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
    my $h = $kbO->proteins_to_roles(\@h);
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
