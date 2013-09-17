#!/usr/bin/perl
#
#     svr_reaction_gain_loss_table  datafile  reaction ... < tree > table
#
#  Data are:
#
#     node1 node2 reaction state1 state2 description
#
#  Output is:
#
#     node  state
#
use strict;
use gjonewicklib;

my $usage = <<End_of_Usage;

Usage: svr_reaction_gain_loss_table  datafile  reaction ... < tree > table

Data are:

    node1 node2 reaction state1 state2 description

Output is:

    node  state

End_of_Usage

my ( $file, @rxns ) = @ARGV;
-f $file && @rxns && open( FH, '<', $file )
    or print STDERR $usage
        and exit;

my %keeper = map { $_ => 1 } @rxns;

my $tree = gjonewicklib::read_newick_tree()
    or print STDERR "Failed to read newick tree.\n", $usage
        and exit;

my $root  = gjonewicklib::newick_lbl( $tree );

my @data = grep { $keeper{ $_->[2] } }
           map  { chomp; [ split /\t/ ] }
           <FH>;

close FH;

my %events;
my %seen_rxn;
foreach ( @data )
{
    my ( $n1, $n2, $rxn, $s1, $s2 ) = @$_;
    push @{ $events{ $n2 } },   [ $rxn, $s2 ];
    push @{ $events{ $root } }, [ $rxn, $s1 ] if ! $seen_rxn{ $rxn }++;
}

my %state = ();

map_state_changes( $tree, \%events, \%state );

exit;


sub map_state_changes
{
    my ( $node, $events, $state ) = @_;

    my ( $lbl, $ev );
    if ( defined( $lbl = gjonewicklib::newick_lbl( $node ) )
      && exists(  $events->{ $lbl } )
      && defined( $ev = $events->{ $lbl } )
       )
    {
        #  If we are going to modify the state, we need do it to a copy
        $state = { %$state };
        foreach ( @$ev )
        {
            $state->{ $_->[0] } = $_->[1];
        }

        #  Emit the new state description:
        printf "%s\t%s\n", $lbl, join( '/', map { defined() ? $_ : '' } map { $state->{ $_ } } @rxns );
    }

    foreach ( gjonewicklib::newick_desc_list( $node ) ) { map_state_changes( $_, $events, $state ) }
}




