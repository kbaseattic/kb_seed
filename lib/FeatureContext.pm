
package FeatureContext;

use Moose;
use MooseX::Method::Signatures;

use strict;

use SapFeature;
use SapFeatureFactory;
use LocalCorrespondences;
use GenomeSet;

=head1 FeatureContext

A feature context object contains all the information needed to render
(and otherwise peruse) the locale around a given feature.

=cut

has 'focus' => (isa => 'SapFeature', is => 'rw');
has 'genome_count' => (isa => 'Int', is => 'rw', default => 10);
has 'width' => (isa => 'Int', is => 'rw', default => 5000);
has 'cutoff' => (isa => 'Num', is => 'rw', default => 1e-5);

has 'local_correspondences' => (isa => 'LocalCorrespondences', is => 'ro', required => 1);

has 'genome_set' => (isa => 'Maybe[GenomeSet]', is => 'rw');

has 'genome_list' => (isa => 'ArrayRef[SapGenome]', is => 'ro',
		      default => sub { [] },
		      traits => ['Array'],
		      handles => {
			  genomes => 'elements',
			  num_genomes => 'count',
			  clear_genomes => 'clear',
			  push_genome => 'push',
	       });

has 'pin' => (isa => 'ArrayRef[SapFeature]', is => 'rw');

has 'genome_data' => (isa => 'HashRef[ArrayRef[SapFeature]]',
		      is => 'ro',
		      traits => ['Hash'],
		      handles => {
			  set_genome_context => 'set',
			  get_genome_context => 'get',
			  clear_genome_contexts => 'clear',
		      },
		      default => sub { {} });

has 'genome_focus_data' => (isa => 'HashRef[SapFeature]',
		      is => 'ro',
		      traits => ['Hash'],
		      handles => {
			  set_genome_focus => 'set',
			  get_genome_focus => 'get',
			  clear_genome_focus => 'clear',
		      },
		      default => sub { {} });

method recompute() {

    my $pin = $self->get_pin(feature => $self->focus, size => $self->genome_count, cutoff => $self->cutoff);

    my @pinobjs = map { SapFeatureFactory->instance->get_feature($_) } @$pin;

    # print "Pin: \n";
    # print join("\t", '', $_->fid, $_->function), "\n" foreach @pinobjs;

    $self->clear_genomes();
    $self->clear_genome_contexts();
    $self->clear_genome_focus();
    $self->pin(\@pinobjs);

    for my $feature ($self->focus, @pinobjs)
    {
	my $genome = $feature->genome;
	my $gobjs = $self->compute_genome_context($feature, $self->width);
#	print "context for " . $feature->fid . ": \n";
#	print join("\t", '', $_->fid, $_->function), "\n" foreach @$gobjs;

	$self->push_genome($genome);
	$self->set_genome_context($genome => $gobjs);
	$self->set_genome_focus($genome => $feature);
    }
}

method compute_coloring_by_function() {

    #
    # Sort by distance in the display from the center.
    #

    my(%fid_dist, %fid_row);

    my @genomes = $self->genomes;
    my $pin = $self->pin;
    my @all;
    for my $row (0..$#genomes)
    {
	my $genome = $genomes[$row];
	my $ctr = $self->get_genome_focus($genome)->loc_min;
	for my $f (@{$self->get_genome_context($genome)})
	{
	    $fid_dist{$f->fid} = abs($f->loc_min - $ctr);
	    $fid_row{$f->fid} = $row;
	    push(@all, $f);
	}
	
    }
    my @sorted = sort { $fid_dist{$a->fid} <=> $fid_dist{$b->fid} or
			    $fid_row{$a->fid} <=> $fid_row{$b->fid} } @all;
#    print "Sorted: \n";
#    print join("\t", $_->fid, $_->loc_min, $fid_row{$_->fid}), "\n" foreach @sorted;

    my $colormap = {};
    my %group;
    my %group_count;
    my $next_group = 1;
    for my $fobj (@sorted)
    {
	my $func= $fobj->function;
	next if $func eq '';
	$func = SeedUtils::strip_func_comment($func);
	my $group = $group{$func};
	if (!defined($group))
	{
	    $group{$func} = $group = $next_group++;
	}
	$colormap->{$fobj->fid} = $group;
	$group_count{$group}++;
    }
    return $colormap, \%group, \%group_count;
}

method compute_genome_context(SapFeature $feature, Int $width) {

    my ($genes, $min, $max) = $feature->genes_around($width);
    # print "genes around " . $feature->fid . ": " . join(" ", map { $_->[0] } @$genes) . "\n";

    my @gobjs = SapFeatureFactory->instance->get_features(fids => [map { $_->[0] } @$genes],
							  inflate => 1);
#    print "Inflated to " . join(" ", map { $_->fid } @gobjs) . "\n";
    return \@gobjs;
}

method get_pin (SapFeature :$feature, Int :$size, Num :$cutoff) {

    if ($self->genome_set)
    {
#	print "Getting pin for $feature using genome set\n";
	my $hits= $self->genome_set->corresponding_features($feature->fid, $self->local_correspondences);
	return $hits;
    }
    else
    {
	my $hits = $self->local_correspondences->corresponding_pegs(id => $feature->fid,
								    psc => $cutoff,
								    as_corr_entry => 1,
								    in_set => $self->genome_set);
	
	my @pegs = map { $_->id2 }
	sort { $b->bsc <=> $a->bsc or
		   abs($a->len1 - $a->len2) <=> abs($b->len1 - $b->len2) }
	@$hits;
	$#pegs = ($size - 1) if @pegs > $size;
	return \@pegs;
    }
}


1;
