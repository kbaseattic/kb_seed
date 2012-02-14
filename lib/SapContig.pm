
package SapContig;

#
# Wrap a contig and provide easy common calls.
#
# You get a contig by calling $genome->contigs or 
# $feature->contig.
#

use Moose;
use strict;
use SeedUtils;
use Data::Dumper;
use List::Util 'reduce';

has 'sap' => (isa => 'SAP', is => 'ro', required => 1);
has 'id' => (isa => 'Str', is => 'ro', required => 1);
has 'genome' => (isa => 'SapGenome', is => 'ro', required => 1);

has 'length' => (isa => 'Num', is => 'ro', lazy => 1, builder => '_build_length');
has 'last_peg' => (isa => 'Str', is => 'ro', lazy => 1, builder => '_build_last_peg', clearer => 'clear_last_peg');
has 'first_peg' => (isa => 'Str', is => 'ro', lazy => 1, builder => '_build_first_peg', clearer => 'clear_first_peg');

sub clear_peg_cache
{
    my($self) = @_;
    $self->clear_first_peg();
    $self->clear_last_peg();
}

sub _build_last_peg
{
    my($self) = @_;

    my $loc = SeedUtils::location_string($self->id, $self->length - 5000, $self->length);
    
    my $res = $self->sap->genes_in_region({ -locations => $loc, -includeLocation => 1 });

    my $h = $res->{$loc};
    my $ent = reduce { $a->[3] > $b->[3] ? $a : $b } map { [ $_, SeedUtils::boundaries_of($h->{$_}) ] } keys %$h;
    
    return defined($ent) ? $ent->[0] : undef;
}

sub _build_first_peg
{
    my($self) = @_;

    my $loc = SeedUtils::location_string($self->id, 0, 5000);
    my $res = $self->sap->genes_in_region({ -locations => $loc, -includeLocation => 1 });

    my $h = $res->{$loc};
    my $ent = reduce { $a->[2] < $b->[2] ? $a : $b } map { [ $_, SeedUtils::boundaries_of($h->{$_}) ] } keys %$h;
    
    return defined($ent) ? $ent->[0] : undef;

}

sub _build_length
{
    my($self) = @_;

    return $self->sap->contig_lengths({ -ids => $self->id })->{$self->id};
}

1;
