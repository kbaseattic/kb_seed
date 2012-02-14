
package SapFeature;

#
# Wrap a feature and provide easy common calls.
#

use Moose;
use strict;
use SeedUtils;
use Data::Dumper;
use SapGenome;
use SapGenomeFactory;
use List::Util 'reduce';
use SapContig;
use SapContigFactory;

has 'sap' => (isa => 'SAP', is => 'ro', required => 1);
has 'fid' => (isa => 'Str', is => 'ro', required => 1);

has 'function' => (isa => 'Str', is => 'rw',
		   builder => '_build_function',
		   clearer => 'clear_function',
		   lazy => 1);
has 'location' => (isa => 'Maybe[ArrayRef[Str]]', is => 'rw',
		   builder => '_build_location',
		   lazy => 1);
has 'contig' => (isa => 'Maybe[SapContig]', is => 'ro',
		 builder => '_build_contig',
		 lazy => 1);
has 'boundaries' => (isa => 'ArrayRef', is => 'ro', builder => '_build_boundaries', lazy => 1);

has 'genome' => (isa => 'SapGenome', is => 'ro', builder => '_build_genome', lazy => 1);

has 'translation' => (isa => 'Str', is => 'ro', builder => '_build_translation', lazy => 1);

has 'dna' => (isa => 'Str', is => 'ro', builder => '_build_dna', lazy => 1);


sub _build_genome
{
    my($self) = @_;
    return SapGenomeFactory->instance->get_genome(SeedUtils::genome_of($self->fid));
}

sub _build_function
{
    my($self) = @_;

    my $res = $self->sap->ids_to_functions({ -ids => $self->fid });
    return $res->{$self->fid} // "";
}

sub _build_location
{
    my($self) = @_;

    my $res = $self->sap->fid_locations({ -ids => $self->fid });

    return $res->{$self->fid};
}

sub _build_boundaries
{
    my($self) = @_;
    return [SeedUtils::boundaries_of($self->location)];
}

sub _build_contig
{
    my($self) = @_;
    return SapContigFactory->instance->get_contig($self->genome, $self->boundaries->[0]);
}

sub _build_translation
{
    my($self) = @_;
    my $res = $self->sap->ids_to_sequences({ -ids => [$self->fid],
					     -protein => 1});
    return $res->{$self->fid};
}

sub _build_dna
{
    my($self) = @_;
    my $res = $self->sap->ids_to_sequences({ -ids => [$self->fid],
					     -protein => 0});
    return $res->{$self->fid};
}

sub id
{
    my($self) = @_;

    #
    # alias this since I keep doing it wrong.
    #
    return $self->fid;
}

sub exists
{
    my($self) = @_;

    my $res = $self->sap->exists({ -type => 'Feature', -ids => [$self->fid] });
    return $res->{$self->fid};
}

sub center
{
    my($self) = @_;
    my ($contig, $min, $max, $dir) = @{$self->boundaries};
    return int(($min + $max) / 2);
}

sub loc_min
{
    my($self) = @_;
    my ($contig, $min, $max, $dir) = @{$self->boundaries};
    return $min;
}

sub loc_max
{
    my($self) = @_;
    my ($contig, $min, $max, $dir) = @{$self->boundaries};
    return $max
}

sub dir
{
    my($self) = @_;
    my ($contig, $min, $max, $dir) = @{$self->boundaries};
    return $dir
}

=head3 genes_around

Returns the set of genes around this gene.

Returns a list of tuples [ peg_id, contig_id, min, max, direction ]
    
=cut

sub genes_around
{
    my($self, $width) = @_;

    return ([], undef, undef) unless $self->exists();

    my ($contig, $min, $max, $dir) = SeedUtils::boundaries_of($self->location);

    if (!defined($min))
    {
	warn "No min for " . $self->fid . " " . $self->location . "\n";
    }

    my $center = int(($min + $max) / 2);
    my $left = $center - $width;
    $left = 0 if $left < 0;
    my $right = $center + $width;

    my $rloc = SeedUtils::location_string($contig, $left, $right);
    my $res = $self->sap->genes_in_region({ -locations => $rloc,
					    -includeLocation => 1});

    my $h = $res->{$rloc};
    my $glist = [sort { $a->[2] <=> $b->[2] } map { [ $_, SeedUtils::boundaries_of($h->{$_}) ] } keys %$h];

    my($rmin, $rmax);
    if (@$glist)
    {
	$rmin = $glist->[0]->[2];
	$rmax = (reduce { $a->[3] > $b->[3] ? $a : $b } @$glist)->[3];
    }

    return ($glist, $rmin, $max);
    
}

sub add_annotation
{
    my($self, $anno_txt) = @_;
}

sub assign_function
{
    my($self, $new, $user) = @_;
    print "Setting fn to $new\n";
    myRAST->instance->sapling_function_loader->UpdateFeature($self->fid, $new, $user);
    $self->clear_function();
}

sub delete
{
    my($self) = @_;
    #
    # What to do with my deleted self here... at least wipe from cache
    #
    SapFeatureFactory->instance->uncache($self->fid);
    $self->contig->clear_peg_cache();

    myRAST->instance->sapling_function_loader->DeleteFeature($self->fid);
}

1;
