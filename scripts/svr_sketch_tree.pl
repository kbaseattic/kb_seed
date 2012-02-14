#
# This is a SAS Component
#

use strict; 

=head1 svr_sketch_tree

=head2 Introduction

    svr_sketch_tree [options]   < tree.nwk > tree.suitable.for.looking.at

This little utility invokes a tree "printing" utility Gary Olsen wrote.
It has a rich set of options.  We suggest a default usage of -m and -a.
Thus,
       svr_sketch_tree -a -m < some_tree.nwk

is a reasonable thing to do.

=head2 Command-Line Options

=over 4

=item -a

Specifies that you wish an aesthetic reordering of subtrees at each point.

=item -c

Asks that zero length branches be collapsed to multifurcating nodes.

=item -f=fasta.file

Read the fasta file to get comments associated with the tip IDs

=item -h

Specifies that the output should be written as HTML.

=item -i

This should only be used with a -f, and it means "print just the description,
not the id followed by the description.

=item -l=file

The specified file should be a two-column, tab-separated table in which the first
column is the sequence ID and the second the value you wish it to be relabeled to.

=item -m

The tree should be rerooted at a midpoint (take the longest distance between
tips and reroot to the midpoint of that path)

=item -s

Do not include a scale bar in the diagram (but -S takes precedence)

=item -S bar_units

Include a scale bar with a units label in the diagram

=item -u

Make the output in UniCode line-drawing character set

=item -w=N

Allows you to specify the width you wish for the sketched tree

=item -x=N

Specifies the minimum length of a distance between two nodes

=item -y=N

Specifies vertical separation of consecutive tips

=back

=cut

#!/usr/bin/env perl -w
#
#  Make a printer plot of a newick tree file.
#

use strict;
use gjonewicklib;
use Data::Dumper;

my $usage = <<"End_of_Usage";
svr_sketch_tree -

A program to make a printer plot of a Newick tree.

Usage:  sketch_tree  [options]  < tree  > ascii_sketch

    options:
        -a         Reorder taxa in aesthetic tree order
        -c         Collapse zero-length branches
        -f fasta   Relabel tips from descriptions in fasta sequence file
        -h         Use HTML encoded line drawing set
        -i         Omit identifiers (first word) when relabeling tips
        -k keep    Keep only the taxa listed (one per line) in the file keep
        -l table   Relabel tips from tab delimited from -> to table
        -m         Use midpoint rooting
        -o omit    Delete the taxa listed (one per line) in the file omit
        -s         Do not include scale bar (but -S takes precedence)
        -S label   Include scale bar with units label
        -t         Print tree comment as title
        -u         Use UTF8 encoded line drawing set
        -w width   Width of tree (without labels) (D=64)
        -x min_dx  Minimum horizontal space between consecutive nodes (D=2)
        -y dy      Vertical separation of consecutive tips (D=2)

End_of_Usage

my ( $width, $min_dx, $dy );

my $TREE;
my $aesthetic;
my $collapse;
my $midpoint;
my $relabel;
my $scale_bar = 1;
my $scale_lbl;
my $skip_id;
my $title;
my $utf8;
my $html;

my $fastafile = '';
my $tablefile = '';
my $treefile  = '';
my $keepfile  = '';
my $omitfile  = '';

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    local $_ = shift @ARGV;
    if ( s/^f *=? *// )
    {
        $fastafile = /./ ? $_ : shift @ARGV or die "Missing value for -f\n$usage\n";
        $relabel = 1;
        next;
    }
    if ( s/^k *=? *// )
    {
        $keepfile = /./ ? $_ : shift @ARGV or die "Missing value for -k\n$usage\n";
        next;
    }
    if ( s/^l *=? *// )
    {
        $tablefile = /./ ? $_ : shift @ARGV or die "Missing value for -l\n$usage\n";
        $relabel = 1;
        next;
    }
    if ( s/^o *=? *// )
    {
        $omitfile = /./ ? $_ : shift @ARGV or die "Missing value for -o\n$usage\n";
        next;
    }
    if ( s/^S *=? *// )
    {
        $scale_lbl = /./ ? $_ : shift @ARGV or die "Missing value for -S\n$usage\n";
        next;
    }
    if ( s/^w *=? *// )
    {
        $width     = /./ ? $_ : shift @ARGV or die "Missing value for -w\n$usage\n";
        next;
    }
    if ( s/^x *=? *// )
    {
        $min_dx    = /./ ? $_ : shift @ARGV or die "Missing value for -x\n$usage\n";
        next;
    }
    if ( s/^y *=? *// )
    {
        $dy        = /./ ? $_ : shift @ARGV or die "Missing value for -y\n$usage\n";
        next;
    }

    if ( s/a//g ) { $aesthetic = 1 }
    if ( s/c//g ) { $collapse  = 1 }
    if ( s/h//g ) { $html      = 1 }
    if ( s/i//g ) { $skip_id   = 1 }
    if ( s/m//g ) { $midpoint  = 1 }
    if ( s/s//g ) { $scale_bar = 0 }
    if ( s/t//g ) { $title     = 1 }
    if ( s/u//g ) { $utf8      = 1 }
    if (  /./ )   { die "Bad flag: $_\n$usage\n" }
}

$min_dx = ( $html || $utf8 ) ? 1 : 2 if ! defined( $min_dx );
$dy     = ( $html || $utf8 ) ? 1 : 2 if ! defined( $dy );
$width  = 64                         if ! $width;


my %label = ();
if ( $fastafile )
{
    -f $fastafile or die "Relabeling fasta file ($fastafile) not found\n";
    open( FASTA, "<$fastafile" ) || die "Could not open fasta relabeling file\n";
    while ( defined( $_ = <FASTA> ) )
    {
        s/^>\s*// or next;
        chomp;
        my ( $id, $def ) = m/^(\S+)\s+(\S.*)$/;
        if ( $id && $def )
        {
            ( my $id2 = $id ) =~ s/_/ /g;
            $label{ $id2 } = $skip_id ? $def : "$id $def";
        }
    }
    close( FASTA );
}

my @keep;
if ( $keepfile )
{
    -f $keepfile or die "Keep id file ($keepfile) not found\n";
    open KEEP, "<$keepfile" or print STDERR "Could not open file '$keepfile'\n" and exit;
    @keep = map { ( m/(\S+)/ ) } <KEEP>;
    close KEEP;
    @keep or print STDERR "No ids found in keep id file '$keepfile'." and exit;
}

my @omit;
if ( $omitfile )
{
    -f $omitfile or die "Omit id file ($omitfile) not found\n";
    open OMIT, "<$omitfile" or print STDERR "Could not open file '$omitfile'\n" and exit;
    @omit = map { ( m/(\S+)/ ) } <OMIT>;
    close OMIT;
}

if ( $tablefile )
{
    -f $tablefile or die "Relabeling table file ($tablefile) not found\n";
    open( TABLE, "<$tablefile" ) || die "Could not open relabeling table file\n";
    while ( defined( $_ = <TABLE> ) )
    {
        chomp;
        my ( $old, $new ) = split /\t/;
        if ( $old && $new )
        {
            $label{ $old } = $new;
            if ( $old =~ s/_/ /g ) { $label{ $old } = $new }
        }
    }
    close( TABLE );
}

foreach my $tree0 ( gjonewicklib::read_newick_trees( $ARGV[0] ) )
{
    $tree0 or die "Could not parse tree.\n\n$usage\n";

    $title = gjonewicklib::newick_c1( $tree0 ) if $title;
    $title = $title->[0] if defined $title && ref $title eq 'ARRAY';

    if ( @omit )
    {
        my %omit = map { $_ => 1 } @omit;
        @keep = grep { ! $omit{ $_ } } newick_tip_list( $tree0 );
    }

    my $tree1 = $midpoint  ? gjonewicklib::reroot_newick_to_midpoint_w( $tree0 )   : $tree0;
    my $tree2 = @keep      ? gjonewicklib::rooted_newick_subtree( $tree1, \@keep ) : $tree1;
    my $tree3 = $aesthetic ? gjonewicklib::aesthetic_newick_tree( $tree2 )         : $tree2;
    my $tree4 = $relabel   ? gjonewicklib::newick_relabel_tips( $tree3, \%label )  : $tree3;
    gjonewicklib::collapse_zero_length_branches( $tree4 ) if $collapse;

    my $opts = { dy     => $dy,
                 min_dx => $min_dx,
                 width  => $width,
               };
    $opts->{ chars } = 'html' if $html;
    $opts->{ chars } = 'utf8' if $utf8;

    $opts->{ scale_bar } = 1          if $scale_bar;
    $opts->{ scale_lbl } = $scale_lbl if defined $scale_lbl;

    print "\n";
    print $title, "\n" if defined $title;
    $title = $title->[0] if $title && ref $title eq 'ARRAY';
    gjonewicklib::printer_plot_newick( $tree4, \*STDOUT, $opts );
    print "\n";
}

exit;
