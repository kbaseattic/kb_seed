package Browser;

#
# primary controlling logic for the browser.
#

use Moose;

use File::HomeDir;
use List::Util qw(sum reduce );
use List::MoreUtils qw(first_value last_value first_index);
use Data::Dumper;
use SapFeature;
use SapContig;
use LocalCorrespondences;
use FeatureContext;
use GenomeSet;

has 'sap' => (isa => 'SAP', is => 'ro');
has 'context' => (isa => 'FeatureContext', is => 'ro',
		  lazy => 1, builder => '_build_context');
has 'genome_set' => (isa => 'Maybe[GenomeSet]', is => 'rw');
		  
has 'local_correspondences' => (isa => 'LocalCorrespondences', is => 'ro', required => 1);

has 'current_feature' => (isa => 'SapFeature',
			  is => 'rw');

has 'region_default_width' => (isa => 'Num',
			       is => 'rw',
			       default => 5000);

has 'region_width' => (isa => 'Num',
		       is => 'rw',
		       default => 5000);

has 'region_count' => (isa => 'Num',
		       is => 'rw',
		       default => 10000);

has 'region_cutoff' => (isa => 'Num',
			is => 'rw',
			default => 1e-20);

has 'region' => (isa => 'ArrayRef',
		 is => 'rw');

has 'observer_list' => (is => 'rw',
			isa => 'ArrayRef[CodeRef]',
			traits => ['Array'],
			handles => {
			    add_observer => 'push',
			    observers => 'elements',
			},
			lazy => 1,
			default => sub { [] } ,
		       );
has 'next_peg' => (is => 'rw', isa => 'Str');
has 'prev_peg' => (is => 'rw', isa => 'Str');
has 'next_halfpage' => (is => 'rw', isa => 'Str');
has 'prev_halfpage' => (is => 'rw', isa => 'Str');
has 'next_page' => (is => 'rw', isa => 'Str');
has 'prev_page' => (is => 'rw', isa => 'Str');
has 'next_contig' => (is => 'rw', isa => 'Str');
has 'prev_contig' => (is => 'rw', isa => 'Str');

has 'history_list' => (is => 'ro',
		       isa => 'ArrayRef[SapFeature]',
		       traits => ['Array'],
		       handles => {
			   push_history => 'push',
			   splice_history => 'splice',
			   history => 'elements',
			   history_count => 'count',
		       },
		       lazy => 1,
		       default => sub { [] } ,
		      );
has 'history_index' => (is => 'rw', isa => 'Int',
			traits => ['Counter'],
			handles => {
			    inc_history_index => 'inc',
			    dec_history_index => 'dec',
			},
			default => -1,
		       );

sub current_peg
{
    my($self) = @_;
    return $self->current_feature->fid;
}

sub _build_context
{
    my($self) = @_;
    return FeatureContext->new(local_correspondences => $self->local_correspondences,
			       genome_set => $self->genome_set,
			       genome_count => $self->region_count,
			       width => $self->region_width,
			       cutoff => $self->region_cutoff);
}

sub get_motion_actions
{
    my($self) = @_;
    return [
	{ button => '<Contig<', action => sub { $self->set_peg($self->prev_contig()) } },
	{ button => '<<<', action => sub { $self->set_peg($self->prev_page()) } },
	{ button => '<<', action => sub { $self->set_peg($self->prev_halfpage()) } },
	{ button => '<', action => sub { $self->set_peg($self->prev_peg()) } },
	{ button => '>', action => sub { $self->set_peg($self->next_peg()) } },
	{ button => '>>', action => sub { $self->set_peg($self->next_halfpage()) } },
	{ button => '>>>', action => sub { $self->set_peg($self->next_page()) } },
	{ button => '>Contig>', action => sub { $self->set_peg($self->next_contig()) } },
	];
}

sub zoom_in
{
    my($self) = @_;
    my $nw = int($self->region_width / 2);
    if ($nw > 10)
    {
	$self->region_width($nw);
    }
}

sub zoom_out
{
    my($self) = @_;
    my $nw = int($self->region_width * 2);
    $self->region_width($nw);
}

sub zoom_original
{
    my($self) = @_;
    $self->region_width($self->region_default_width);
}

sub current_genome
{
    my($self) = @_;
    return $self->current_feature->genome->id;
}

sub current_function
{
    my($self) = @_;
    return $self->current_feature->function;
}

=head3 set_peg($peg)

set_peg is the external interface for moving to a new peg.

=cut

sub set_peg
{
    my($self, $peg) = @_;

    if (!defined($peg))
    {
	warn "set_peg called without valid peg";
    }

    my $fobj = SapFeatureFactory->instance->get_feature($peg);
    if (!$fobj->exists)
    {
	warn "$peg not found\n";
	return;
    }

    #
    # Update history.
    #
    if ($self->history_index < $self->history_count - 1)
    {
	$self->splice_history($self->history_index + 1);
    }
    $self->push_history($fobj);
    $self->inc_history_index();

    $self->_set_peg($fobj);
}

=head3 _set_peg($peg)

_set_peg is the one that does the work, but does not alter history.

=cut

sub _set_peg
{
    my($self, $fobj) = @_;

    $self->current_feature($fobj);

    $self->reload();
}

=head3 history_forward()

Move forward in peg history.

=cut

sub history_forward
{
    my($self) = @_;
    return if ($self->history_index == $self->history_count - 1);
    $self->inc_history_index();
    $self->_set_peg($self->history_list->[$self->history_index]);
}

sub history_back
{
    my($self) = @_;
    return if ($self->history_index == 0);
    $self->dec_history_index();
    $self->_set_peg($self->history_list->[$self->history_index]);
}

=head3 find_location($str)

Try to map the given location string to a feature id.

=cut

sub find_location
{
    my($self, $peg) = @_;

    $peg =~ s/^\s*//;
    $peg =~ s/\s*$//;

    my $genome = $self->current_genome();

    my $dest;
    
    if ($peg =~ /^\d+$/)
    {
	$dest = "fig|$genome.peg.$peg";
    }
    elsif ($peg =~ /^\w+\.\d+$/)
    {
	$dest = "fig|$genome.$peg";
    }
    elsif ($peg =~ /fig\|(\d+\.\d+).*/)
    {
	$dest = $peg;
    }
#     elsif ($peg =~ /^(\S+):(\d+)$/)
#     {
# 	#
# 	# Find by contig location
# 	#

# 	my $contig = $1;
# 	my $loc = $2;
# 	my ($ids, $l1, $l2) = $self->browser->seedv->genes_in_region($contig, $loc - 100, $loc + 100);
# 	print Dumper($ids);
# 	my $best = min { $_->[5] },
# 		map { my($c, $start, $stop, $dir) = SeedUtils::parse_location($self->browser->seedv->feature_location($_));
# 		      my $x = [$_, $c, $start, $stop, $dir, abs($stop - $loc)];
# 		      print Dumper($x);
# 		      $x;
# 		  } @$ids;
# 	if (defined($best))
# 	{
# 	    $dest = $best->[0];
# 	}
#     }
    
    my $fobj;
    if (defined($dest))
    {
	my $xfobj = SapFeatureFactory->get_feature($dest);
	if ($xfobj->exists())
	{
	    $fobj = $xfobj;
	}
    }

    if ($fobj)
    {
	$self->set_peg($dest);
	return 1;
    }
    else
    {
	return undef;
    }
	
}

sub reload
{
    my($self) = @_;

    my $fobj = $self->current_feature;

    $self->compute_motion_targets($fobj);
    $self->update_context();

    my $have_back = $self->history_index > 0;
    my $have_fwd = $self->history_index < $self->history_count - 1;
#    print "History is fwd=$have_fwd back=$have_back " . join(" ", $self->history) . "\n";

    &$_($self, $fobj->fid, $have_back, $have_fwd) for $self->observers();
}

sub update_context
{
    my($self) = @_;
    my $fc = $self->context;
    $fc->genome_count($self->region_count);
    $fc->width($self->region_width);
    $fc->cutoff($self->region_cutoff);
    $fc->focus($self->current_feature);
    $fc->recompute();
}

sub compute_motion_targets
{
    my($self, $fobj) = @_;

    my $peg = $fobj->fid;

    #
    # Determine targets for motion in the chromosome.
    #

    my $center = $fobj->center;
    my ($my_genes, $minV, $maxV) = $fobj->genes_around($self->region_width);
    
    my @contigs = sort { SeedUtils::by_fig_id($a->first_peg, $b->first_peg) } @{$fobj->genome->contigs};
    my $contig = $fobj->contig;

    my $ctg_index = first_index { $_->id eq $contig->id } @contigs;

 #   print Dumper(\@sorted, \@contigs, $ctg_index);


    #
    # If we are at one end of the contig or the other, the "next X"
    # in that direction is the start / end of the next / previous contig.
    #

    my $peg_idx = first_index { $_->[0] eq $peg } @$my_genes;

    my($prev_contig, $prev_contig_peg, $next_contig, $next_contig_peg);
    
    if (@contigs > 0)
    {

	$prev_contig = $contigs[($ctg_index - 1 + @contigs) % @contigs];
	$prev_contig_peg = $prev_contig->last_peg();
	
	$next_contig = $contigs[($ctg_index + 1) % @contigs];
	$next_contig_peg = $next_contig->first_peg();
	
	$self->prev_contig($prev_contig_peg);
	$self->next_contig($next_contig_peg);
	#print "me: $contig $peg\n";
	#print "nxt: $next_contig $next_contig_peg\n";
	#print "prv: $prev_contig $prev_contig_peg\n";
    }
	
    my @left = @$my_genes[0..$peg_idx - 1];
    my @right = @$my_genes[$peg_idx + 1 .. $#$my_genes];
    # print "left=" . join(" ", map { $_->[0] } @left) . "\n";
    # print "right=" . join(" ", map { $_->[0] } @right) . "\n";
    # print Dumper(\@left, \@right);

    #
    # Compute prev-peg addresses.
    #
    if ($peg_idx == 0)
    {
	$self->prev_peg($prev_contig_peg);
	$self->prev_halfpage($prev_contig_peg);
	$self->prev_page($prev_contig_peg);
    }
    else
    {
	$self->prev_peg($left[$#left]->[0]);
	$self->prev_page($left[0]->[0]);
	#
	# half-page is first peg width/2 from the center
	#
	my $offset = $center - $self->region_width / 2;
	my $ent = first_value { $_->[2] > $offset } @left;
	
	$self->prev_halfpage(defined($ent) ? $ent->[0] : $self->prev_page);
    }

    #
    # Compute next-peg addresses
    if ($peg_idx == $#$my_genes)
    {
	$self->next_peg($next_contig_peg);
	$self->next_halfpage($next_contig_peg);
	$self->next_page($next_contig_peg);
    }
    else
    {
	$self->next_peg($right[0]->[0]);
	$self->next_page($right[$#right]->[0]);
	#
	# half-page is first peg width/2 from the center
	#
	my $offset = $center + $self->region_width / 2;
	my $ent = last_value { $_->[2] < $offset } @right;
	# print Dumper($center, $offset, $ent);
	$self->next_halfpage(defined($ent) ? $ent->[0] : $self->next_page);
    }
	    
#     print "$peg :\n";
#     for my $x (qw(prev_page prev_halfpage prev_peg next_peg next_halfpage next_page))
#     {
# 	print "  $x $self->{$x}\n";
#     }
}

sub remove_observer
{
    my($self, $obs) = @_;
    $self->observer_list([ grep { $_ ne $obs } $self->observers]);
}

1;
