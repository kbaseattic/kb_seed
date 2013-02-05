use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

subsystems_to_spreadsheets

=head1 SYNOPSIS

subsystems_to_spreadsheets [arguments] < input > output

=head1 DESCRIPTION

The subsystem_to_spreadsheets command allows the user to output the entire spreadsheet for 
a set of input subsystems.  The input is a table with a column containing subsystem names.
The output is a table with 4 appended columns

     [Genome,variant-code,role,fid]

Example:

    subsystems_to_spreadsheets [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the subsystem name. If another column contains the subsystem
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: subsystems_to_spreadsheets [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: subsystems_to_spreadsheets [-c column] [g1 g2 g3 ...] < input > output";

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
    my $h = $kbO->subsystems_to_spreadsheets(\@h, \@ARGV);
    for my $tuple (@tuples) {
      my ($subsys, $line) = @$tuple;
        my $v = $h->{$subsys};
        if (! $v)
        {
            print STDERR $line,"\n";
        }
        else
        {
            foreach my $g (sort keys(%$v))
            {
                my $row = $v->{$g};
		my($variant,$roleH) = @$row;
		my @roles = keys(%$roleH);
		foreach my $role (sort @roles)
		{
		    my $fids = $roleH->{$role};
		    foreach my $fid (sort @$fids)
		    {
			print join("\t",($line,$g,$variant,$role,$fid)),"\n";
		    }
		}
            }
        }
        #
        # Process output here and print.
        #
    }
}

__DATA__
