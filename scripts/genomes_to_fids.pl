use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

genomes_to_fids

=head1 SYNOPSIS

genomes_to_fids [options] [fid-type fid-type ...] < input > output

=head1 DESCRIPTION


genomes_to_fids is used to get the fids included in specific genomes.  It
is often the case that you want just one or two types of fids; in this case
you may enumerate the types that you wish to retrieve.

Example:

    genomes_to_fids peg CDS rna < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output. For each input line, ther can be many output lines, one per feature. The feature id is added to the end of the line.

=head1 COMMAND-LINE OPTIONS

Usage: genomes_to_fids [arguments] [fid-types] < input > output

    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input
    fid-type	  Optional type of fid to return (peg, CDS, rna, etc)
=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: genomes_to_fids [-c column] [fid-type, fid-type ...] < input > output";

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

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, 10, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $kbO->genomes_to_fids(\@h, \@ARGV);
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
