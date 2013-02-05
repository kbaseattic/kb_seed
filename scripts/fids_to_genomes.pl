use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

fids_to_genomes

=head1 SYNOPSIS

fids_to_genomes [arguments] < input > output

=head1 DESCRIPTION





Example:

    fids_to_genomes [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: fids_to_genomes [arguments] < input > output



=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: fids_to_genomes [-c column] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;
my $input_file;

my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script('c=i' => \$column,
                                      'i=s' => \$input_file);

if (! $geO) { print STDERR $usage; exit }

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}

my @from_fields;
my @rel_fields;
my @to_fields = ("id");

my %lines;
while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        $lines{$id} = $line;
    }

    my @h = map { $_->[0] } @tuples;
    my $h = $geO->get_relationship_IsOwnedBy(\@h, \@from_fields, \@rel_fields, \@to_fields);
    for my $result (@$h) {
        my @from;
        my @rel;
        my @to;
        my $from_id;
        my $res = $result->[0];
        for my $key (@from_fields) {
                push (@from,$res->{$key});
        }
        my $res = $result->[1];
        $from_id = $res->{'from_link'};
        for my $key (@rel_fields) {
                push (@rel,$res->{$key});
        }
        my $res = $result->[2];
        for my $key (@to_fields) {
                push (@to,$res->{$key});
        }
        if ($from_id) {
                print join("\t", $lines{$from_id}, @from, @rel, @to), "\n";
        }
    }
}

__DATA__
