use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

complexes_to_complex_data

=head1 SYNOPSIS

complexes_to_complex_data [arguments] < input > output

=head1 DESCRIPTION





Example:

    complexes_to_complex_data [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: complexes_to_complex_data [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: complexes_to_complex_data [-c column] < input > output";

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
    my $h = $kbO->complexes_to_complex_data(\@h);
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
	    my $roles = $v->{complex_roles};
            my @role_strings = map {join("", $_->[1], "\t", $_->[0])} @$roles;
	    my $rol = join(",", @role_strings);
	    my $name = $v->{complex_name};
	    my $reactions = $v->{complex_reactions};
    	    my $reaction_strings = join("\t", @$reactions);
            print "$line\t$name\t$reaction_strings\t$rol\n";
        }
    }
}

__DATA__
