package SapGenomeFactory;

use MooseX::Singleton;

use strict;

use SapGenome;
use myRAST;

has 'genome_cache' => (isa => 'HashRef[SapGenome]', is => 'ro',
		       default => sub { {} });

has 'sap' => (isa => 'SAP', is => 'ro', lazy => 1, builder => '_build_sap');

sub _build_sap
{
    my($self);
    return myRAST->instance->sap;
}

sub get_genome
{
    my($self, $id) = @_;
    my $obj = $self->genome_cache->{$id};
    if (!$obj)
    {
#	print "Creating new genome obj for $id\n";
	$obj = SapGenome->new(sap => $self->sap, id => $id);
	$self->genome_cache->{$id} = $obj;
    }
    else
    {
#	print "Returning cached genome obj for $id\n";
    }
    return $obj;
}

1;
