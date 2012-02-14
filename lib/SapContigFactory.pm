package SapContigFactory;

use MooseX::Singleton;

use strict;

use SapContig;
use myRAST;

has 'contig_cache' => (isa => 'HashRef[SapContig]', is => 'ro',
		       default => sub { {} });

has 'sap' => (isa => 'SAP', is => 'ro', lazy => 1, builder => '_build_sap');

sub _build_sap
{
    my($self);
    return myRAST->instance->sap;
}

sub get_contig
{
    my($self, $genome, $id, $length) = @_;
    my $obj = $self->contig_cache->{$genome->id, $id};
    if (!$obj)
    {
#	print "Creating new contig obj for $id\n";
	$obj = SapContig->new(sap => $self->sap, id => $id, genome => $genome,
			      (defined($length) ? (length => $length) : ()));
	$self->contig_cache->{$genome->id, $id} = $obj;
    }
#     else
#     {
# 	print "Returning cached contig obj for $id\n";
#     }
    return $obj;
}

1;
