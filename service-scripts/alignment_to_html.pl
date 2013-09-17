#! /usr/bin/perl -w
#
# This is a SAS Component
#
#
#  alignment_to_html -- convert a fasta alignment to html
#

use strict;

eval { use Data::Dumper };
use gjoalign2html;
use gjoseqlib;

my $usage = <<"End_of_Usage";

usage:  alignment_to_html [options] < fasta_alignment > alignment_html

   options:
      -c          #  Do not color the alignment (same as -R none)
      -d          #  Omit pop-up sequence definitions
      -j          #  Omit JavaScript (only valid with -t)
      -l          #  Omit legend
      -n          #  Treat residues as nucleotides (D = guess)
      -p          #  Treat residues as amino acids (D = guess)
      -r          #  Color by residue type (same as -R default)
      -R pallet   #  Color by residue type (pallet = ale | gde | none | default )
      -s seqfile  #  Add unaligned residues to the ends of the alignment
      -t          #  Write html table (D = write a self-contained page)

End_of_Usage

my $as_table    = 0;
my $by_residue  = '';
my $colored     = 1;
my $is_protein  = undef;
my $javascript  = 1;
my $popup       = 1;
my $seqF        = undef;
my $show_legend = 1;

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    foreach ( shift )
    {
        if ( s/^R//  ) { $by_residue = /./ ? $_ : shift; next }
        if ( s/^s//  ) { $seqF       = /./ ? $_ : shift; next }

        if ( s/c//g ) { $colored     = 0 }
        if ( s/d//g ) { $popup       = 0 }
        if ( s/j//g ) { $javascript  = 0 }
        if ( s/l//g ) { $show_legend = 0 }
        if ( s/n//g ) { $is_protein  = 0 }
        if ( s/p//g ) { $is_protein  = 1 }
        if ( s/r//g ) { $by_residue  = 'default' }
        if ( s/t//g ) { $as_table    = 1 }
        if ( /./ )
        {
            print STDERR "Bad flag: '$_'\n$usage";
            exit;
        }
    }
}

if ( $by_residue )
{
    local $_ = $by_residue;
    $by_residue = /^a/i ? 'ale'
                : /^d/i ? 'default'
                : /^g/i ? 'gde'
                : /^n/i ? 'none'
                :         'default';
    $colored = $by_residue eq 'none' ? 0 : 1;
}

my @ali = read_fasta();
@ali or print STDERR "Failed to read alignment\n$usage"
     and exit;

my $ali2;
if ( $seqF )
{
    my @seq = read_fasta( $seqF );
    @seq or print STDERR "Failed to read sequence file '$seqF'\n$usage"
         and exit;
    $ali2 = gjoalign2html::add_alignment_context( \@ali, \@seq );
}
else
{
    $ali2 = \@ali;
}

my ( $ali3, $legend );
if ( ! $colored )
{
    $ali3   = gjoalign2html::repad_alignment( $ali2 );
    $legend = '';
}
elsif ( $by_residue )
{
    ( $ali3, $legend ) = gjoalign2html::color_alignment_by_residue( 
                           { align  => $ali2,
                             ( defined( $is_protein ) ? ( protein => $is_protein ) : () ),
                             pallet => $by_residue
                           } );
}
else
{
    ( $ali3, $legend ) = gjoalign2html::color_alignment_by_consensus( { align => $ali2 } );
}

my @legend_opt = ( $show_legend && $legend ) ? ( legend => $legend ) : ();

if ( $as_table )
{
    my @javascript_opt = $javascript ? () : ( nojavascript => 1 );

    print scalar gjoalign2html::alignment_2_html_table( { align   => $ali3,
                                                          @javascript_opt,
                                                          @legend_opt,
                                                          tooltip => $popup
                                                        } );
}
else
{
    my $title = $by_residue ? 'Alignment colored by residue'
                            : 'Alignment colored by consensus';

    print gjoalign2html::alignment_2_html_page( { align   => $ali3, 
                                                  @legend_opt,
                                                  title   => $title,
                                                  tooltip => $popup
                                                } );
}

