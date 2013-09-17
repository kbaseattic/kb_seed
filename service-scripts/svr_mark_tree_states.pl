#!/usr/bin/perl
#
#     svr_mark_tree_states  [opts] datafile            < tree > tree
#
#     svr_mark_tree_states  -x     datafile  reaction  < tree > tree
#
#  Options:
#
#     -c state rgb
#
#        rgb can be an html color, or 3 comma-separated components (if all
#             components are <= 1, the values are scaled up 255-fold).
#
#  Data are:
#
#     node  state
#
#  or with -x
#
#     node1 node2 reaction state1 state2 description
#
use strict;
use gjonewicklib;

my $usage = <<End_of_Usage;

Usage: svr_mark_tree_states  [opts]  data_file               < tree > tree

       svr_mark_tree_states  -x      data_file  reaction_id  < tree > tree

Options:

    -c state rgb   #  rgb color of a state; rgb can be an html color,
                   #      or 3 comma-separated components (if all components
                   #      are <= 1, the values are scaled up 255-fold).

Data are:

    node  state

  or with -x (raw mode)

    node1 node2 reaction state1 state2 description

Suggested rendering for default pallet and 2 or 3 reactions (black background,
white lines and text):

    modify_tree -a -l labels < marked.tree.nwk | gd_tree -bc 0,0,0 -tc 255,255,255 -lc 255,255,255 > marked.tree.png

End_of_Usage

my @pairs = ( [ 0 => 64 ], [ '0,1' => 127 ], [ 1 => 255 ] );

my %color = ( 0 => [96,96,255], '0,1' => [127,127,127], 1 => [255,48,48] );
foreach my $p1 ( @pairs )
{
    my ( $s1, $v1 ) = @$p1;
    foreach my $p2 ( @pairs )
    {
        my ( $s2, $v2 ) = @$p2;
        $color{ "$s1/$s2" } = [ $v1, 48, $v2 ];
        foreach my $p3 ( @pairs )
        {
            my ( $s3, $v3 ) = @$p3;
            $color{ "$s1/$s2/$s3" } = [ $v1, $v2, $v3 ];
        }
    }
}

$color{ '0/0' } = $color{ '0/0/0' } = [127,127,127];
$color{ '0/1' } = $color{ '0/0/1' } = [ 96, 96,255];

my $raw = 0;

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    local $_ = shift;
    if ( s/^c// )
    {
        my $s  = /./ ? $_ : shift;
        my $c0 = shift;
        my $c  = defined( $c0 ) ? $c0 : '';
        $c =~ s/^\s+//;
        $c =~ s/\s+$//;
        $c =~ s/^\[\s*(\S.*\S)\s*\]$/$1/ || $c =~ s/^\(\s*(\S.*\S)\s*\)$/$1/;

        my @rgb = $c =~ /^#?[0-9a-e]{6}$/i      ? gjocolorlib::html2rgb( $c ) :
                  $c =~ /^[a-z]{3,20}\d{0,3}$/i ? gjocolorlib::html2rgb( $c ) :
                  $c =~ /^(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)$/
                                                ? ( $1, $2, $3 )             
                                                : ();

        if ( defined( $s ) && length( $s ) && @rgb )
        {
            my $max = 0;
            foreach ( @rgb ) { $max = $_ if $_ > $max }
            @rgb = map { 255 * $_ } @rgb if $max <= 1;
            $color{ $s } = sprintf( '[%3d,%3d,%3d]', @rgb );
            next;
        }
        else
        {
            $s = '' if ! defined $s;
            print STDERR "Bad color specification: state = '$s', color = '$c0'.\n", $usage;
            exit;
        }
    }

    if ( s/^x$// ) { $raw = 1; next }

    if ( /./ )
    {
        print STDERR "Bad flag '$_'.\n", $usage;
        exit;
    }
}

my %rend = map { my $c = sprintf( "[%3d,%3d,%3d]", @{ $color{ $_ } } );
                 $_ => "&&treeLayout: line_color=>$c; text_color=>$c";
               }
           keys %color;

my ( $file, $rxn ) = @ARGV;
-f $file && ( ! $raw || $rxn ) && open( FH, '<', $file )
    or print STDERR $usage
        and exit;

my $tree = gjonewicklib::read_newick_tree()
    or print STDERR "Failed to read newick tree.\n", $usage
        and exit;

my %state;
if ( $raw )
{
    my @data = grep { $_->[2] eq $rxn }
               map  { chomp; [ split /\t/ ] }
               <FH>;

    %state = map { @$_[1,4] } @data;

    #  The root node is a special case

    my $root  = gjonewicklib::newick_lbl( $tree );
    if ( defined $root && length $root )
    {
        foreach ( @data ) { next unless $_->[0] eq $root; $state{ $root } = $_->[3]; last }
    }
}
else
{
    %state = map { chomp; ( split )[0,1] } <FH>;
}

close FH;

# foreach ( sort keys %state ) { print STDERR "node $_ changes state to $state{$_}.\n" }

%state
    or print STDERR "Failed to find data for reaction '$rxn'.\n", $usage
        and exit;

color_subtree( $tree, \%state, \%rend );

gjonewicklib::writeNewickTree( $tree );


sub color_subtree
{
    my ( $node, $state, $rend ) = @_;

    my ( $lbl, $st );
    if ( defined( $lbl = gjonewicklib::newick_lbl( $node ) )
      && exists(  $state->{ $lbl } )
      && defined( $st = $state->{ $lbl } )
       )
    {
        gjonewicklib::set_newick_c1( $node, [] ) if ! gjonewicklib::newick_c1( $node );
        push @{ gjonewicklib::newick_c1( $node ) }, $rend->{ $st } || $rend->{ 0 };
    }

    foreach ( gjonewicklib::newick_desc_list( $node ) ) { color_subtree( $_, $state, $rend ) }
}

