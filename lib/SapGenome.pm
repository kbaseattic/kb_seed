
package SapGenome;

#
# Wrap a genome and provide easy common calls.
#

use Moose;
use strict;
use SeedUtils;
use Data::Dumper;
use List::Util 'reduce';
use SapContig;

has 'sap' => (isa => 'SAP', is => 'ro', required => 1);
has 'id' => (isa => 'Str', is => 'ro', required => 1);

has 'name' => (isa => 'Str', is => 'ro', builder => '_build_name', lazy => 1);
has 'name_text' => (isa => 'Str', is => 'ro', builder => '_build_name_text', lazy => 1);
has 'contigs' => (isa => 'ArrayRef[SapContig]', is => 'ro', builder => '_build_contigs', lazy => 1);

sub _build_name
{
    my($self) = @_;
    return $self->sap->genome_names({ -ids => $self->id })->{$self->id} || "";
}

sub _build_name_text
{
    my($self) = @_;
    my $n = $self->name;
    if ($n)
    {
	return "$n (" . $self->id . ")";
    }
    else
    {
	return $self->id;
    }
}

sub _build_contigs
{
    my($self) = @_;
    my $contigs = $self->sap->genome_contigs({ -ids => $self->id })->{$self->id};
    my $lens = $self->sap->contig_lengths({ -ids => $contigs });
    
    return [map { SapContigFactory->instance->get_contig($self, $_, $lens->{$_}) }
	    @$contigs];
}

sub exists
{
    my($self) = @_;

    my $res = $self->sap->exists({ -type => 'Genome', -ids => [$self->id] });
    return $res->{$self->id};
}


1;
