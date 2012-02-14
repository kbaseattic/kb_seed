package SapFeatureFactory;

use MooseX::Singleton;
use MooseX::Method::Signatures;
use Data::Dumper;
use myRAST;
use Carp;

use strict;

use SapFeature;

has 'feature_cache' => (isa => 'HashRef[SapFeature]', is => 'ro',
		       default => sub { {} });

has 'sap' => (isa => 'SAP', is => 'ro', lazy => 1, builder => '_build_sap');

sub _build_sap
{
    my($self);
    return myRAST->instance->sap;
}
sub get_feature
{
    my($self, $id) = @_;
    my $obj = $self->feature_cache->{$id};
    if (!$obj)
    {
#	print "Creating new feature obj for $id\n";
	$obj = SapFeature->new(sap => $self->sap, fid => $id);
	$self->feature_cache->{$id} = $obj;
    }
#     else
#     {
# #	print "Returning cached feature obj for $id\n";
#     }
    return $obj;
}

method get_features (ArrayRef :$fids, Bool :$inflate) {

    if ($inflate)
    {
	my @new = grep { !exists($self->feature_cache->{$_}) } @$fids;

	my $fns = $self->sap->ids_to_functions({ -ids => \@new });
	my $locs = $self->sap->fid_locations({ -ids => \@new });

	my @out;
	for my $fid (@$fids)
	{
	    if (exists($self->feature_cache->{$fid}))
	    {
		push(@out, $self->get_feature($fid));
	    }
	    else
	    {
		my $loc = $locs->{$fid};
		my $fn = $fns->{$fid};
		next unless $fn && $loc;
		my $fobj = SapFeature->new(sap => $self->sap,
					   fid => $fid,
					   function => $fn,
					   location => $loc);
		$self->feature_cache->{$fid} = $fobj;
		push(@out, $fobj);
	    }
	}
	return @out;
    }

    return map { $self->get_feature($_) } @$fids;

}

method uncache (Str $fid) {
    delete $self->feature_cache->{$fid};
}

1;
