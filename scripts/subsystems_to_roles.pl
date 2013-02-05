use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

subsystems_to_roles

=head1 SYNOPSIS

subsystems_to_roles [arguments] < input > output

=head1 DESCRIPTION

The command subsystem_to_roles takes as input a table with a column containing subsystem IDs.  The table is
extended with an extra column set to roles that make up the subsystems.  For each
input line (designating a subsystem), a line will be added to the output for each
role that occurs in the subsystem.

You can ask for auxiliary roles, but the default is to leave them out.  If you want
them, use "-aux=1".
Example:

    subsystems_to_roles [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the subsystem name. If another column contains the subsystem,
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: subsystems_to_roles [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: subsystems_to_roles [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;
my $aux;
my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
				       'aux' => \$aux,
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
    my $h = $kbO->subsystems_to_roles(\@h, $aux);
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
