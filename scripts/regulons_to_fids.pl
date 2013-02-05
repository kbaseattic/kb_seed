use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

regulons_to_fids

=head1 SYNOPSIS

regulons_to_fids [arguments] < input > output

=head1 DESCRIPTION

The CS contains two similar notions:

    1. atomic regulons, which are sets of fids thought to have exactly the
       same expression profiles (derived from operons, subsystems, and expression data)

    2. regulons which are thought of as a set of genes impacted by a transcription factor.
       This second notion is built up looking for binding-site/transcription-factor pairs 
       and reconciling the insights with operons and subsystems.

Clearly the two notions are closely related.  

This command takes as input a table in which one column is composed of regulon ids,
and it adds a column corresponding to the fids that make up the regulon.

Example:

    regulons_to_fids [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the regulon identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the regulon ID.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: regulons_to_fids [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: regulons_to_fids [-c column] < input > output";

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
    my $h = $kbO->regulons_to_fids(\@h);
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
