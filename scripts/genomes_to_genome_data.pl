use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

genomes_to_genome_data

=head1 SYNOPSIS

genomes_to_genome_data [arguments] < input > output

=head1 DESCRIPTION





Example:

    genomes_to_genome_data [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: genomes_to_genome_data [arguments] < input > output


    -c num        Select the identifier from column num
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: genomes_to_genome_data [-c column] < input > output";

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
    my $h = $kbO->genomes_to_genome_data(\@h);
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
	    my $rna = $v->{rnas};
	    my $gc = $v->{gc_content};
	    my $dna_size = $v->{dna_size};
	    my $tax = $v->{taxonomy};
	    my $name = $v->{scientific_name};
	    my $contigs = $v->{contigs};
	    my $md5 = $v->{genome_md5};
	    my $pegs = $v->{pegs};
	    my $gcode = $v->{genetic_code};
	    my $complete = $v->{complete};


            print "$line\t$rna\t$gc\t$dna_size\t$tax\t$name\t$contigs\t$md5\t$pegs\t$gcode\t$complete\n";
        }
    }
}

__DATA__
