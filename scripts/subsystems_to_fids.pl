use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

subsystems_to_fids

=head1 SYNOPSIS

subsystems_to_fids [arguments] < input > output

=head1 DESCRIPTION

This command gives to access to all of the rows in a subsystem.  It does not support
selecting just rows for specific genomes (although the underlying API routine
subsystems_to_fids does).  This command gives you all of the 

    [genome,variant-code,fids]

for an input subsystem.

Example:

    subsystems_to_fids [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain a subssytem name. If another column contains the subsystem
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: subsystems_to_fids [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: subsystems_to_fids [-c column] < input > output";

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
    my $h = $kbO->subsystems_to_fids(\@h, \@ARGV);
    for my $tuple (@tuples) {
        #
        # Process output here and print.
        #
        my ($id, $line) = @$tuple;
       my $genomeH = $h->{$id};
        if (! defined($genomeH))
        {
            print STDERR $line,"\n";
        }
        else
        {
            my @genomes = sort keys(%$genomeH);
            foreach my $g (@genomes)
            {
               my $rows = $genomeH->{$g};
               for my $row (@$rows) {
                    my($variant,$fids) = @$row;
                    foreach my $fid (@$fids)
                    {
                        print join("\t",($line,$g,$variant,$fid)),"\n";
                    }
               }
            }
        }
    }
}



__DATA__
