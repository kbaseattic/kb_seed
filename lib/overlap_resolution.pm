package overlap_resolution;

# This is a SAS component.

#
#  Functions to aid in the resolution of overlapping features
#
#  Feature data:
#
#     ftr_type
#     priority
#     max_overlap
#
#  Rule types:
#
#     remove duplicates - same type and location
#     ignore overlap
#     early first
#     tool-supplied priority or tool-based priority
#     annotation-based score
#     spacing-based score (CDS)
#
#  
#
#   typedef structure {
#       bool truncated_begin;
#       bool truncated_end;
#       /* Is this a real feature? */
#       float existence_confidence;
#
#       bool frameshifted;
#       bool selenoprotein;
#       bool pyrrolysylprotein;
#
#       list<string> overlap_rules;
#       float priority;
#
#       float hit_count;
#       float weighted_hit_count;
#   } feature_quality_measure;
#
#   typedef structure {
#       feature_id id;
#       location location;
#       feature_type type;
#       string function;
#       string protein_translation;
#       list<string> aliases;
#       list<annotation> annotations;
#       feature_quality_measure quality;
#       analysis_event_id feature_creation_event;
#   } feature;
#

use strict;
use Data::Dumper;

#
# Overlap scoring rules:
#
# Rule directions are same, conv and div.
# Rule values are [ $max_over, $over_scr, $opt_scr, $opt_dist, $decay ]
# The structure of scoring is:
#
#   overlap greater than $max_over is forbidden
#   spacing between $max_over and $opt_dist is linear interpolation from $over_scr to $opt_scr
#   spacing greater than $opt_dist decays from $opt_scr to zero with rate $decay.
#
# Score is defined by right-most end in the path, except that violating any max_over limit is enforced
#

my $tRNA_rules = { tRNA => { same => [  0, -1.0, 1.0, 20, 50 ], conv => [  0, -1.0, 1.0, 100, 100 ], div => [  0, -1.0, 1.0, 100, 100 ] },
                   rRNA => { same => [  0, -1.0, 1.0, 20, 50 ], conv => [  0, -1.0, 1.0, 100, 100 ], div => [  0, -1.0, 1.0, 100, 100 ] },
                   rna  => { same => [  0, -1.0, 1.0, 20, 50 ], conv => [  0, -1.0, 1.0, 100, 100 ], div => [  0, -1.0, 1.0, 100, 100 ] },
                   CDS  => { same => [ 10, -1.0, 1.0, 20, 50 ], conv => [ 10, -1.0, 1.0, 100, 100 ], div => [ 10, -1.0, 1.0, 100, 100 ] },
                   default => { allow => 1 }
                 };

my $rRNA_rules = $tRNA_rules;

my $CDS_rules  = { tRNA => { same => [ 10, -1.0, 1.0, 20, 100 ], conv => [ 10, -1.0, 1.0, 100, 100 ], div => [ 10, -1.0, 1.0, 100, 100 ] },
                   rRNA => { same => [ 10, -1.0, 1.0, 20, 100 ], conv => [ 10, -1.0, 1.0, 100, 100 ], div => [ 10, -1.0, 1.0, 100, 100 ] },
                   rna  => { same => [ 10, -1.0, 1.0, 20, 100 ], conv => [ 10, -1.0, 1.0, 100, 100 ], div => [ 10, -1.0, 1.0, 100, 100 ] },
                   CDS  => { same => [ 30, -1.0, 1.0, 10,  50 ], conv => [ 30, -1.0, 1.0, 100, 100 ], div => [ 30, -1.0, 1.0, 100, 100 ] },
                   default => { allow => 1 }
                 };

#
#  [ $type, $exempt, $score, $rules, \@bound ] = overlap_rules( $ftr, $opts );
#  ( $type, $exempt, $score, $rules, \@bound ) = overlap_rules( $ftr, $opts );
#  ( $contig, $left, $right, $dir, $size ) = @bound;
#  $left and $right are the min and max coordinates on the contig.
#

sub overlap_rules
{
    my ( $ftr, $opts ) = @_;
    $opts ||= {};

    my $type   = $ftr->{type}     || 'CDS';
    my $loc    = $ftr->{location} || [];
    my $func   = $ftr->{function} || '';
    my $events = $opts->{events}  || {};
    my $event  = $events->{ $ftr->{feature_creation_event} || "" } || {};
    my $qual   = $ftr->{quality}  ||= {};
    my @bound  = bounds( $ftr );         # ( $contig, $left, $right, $dir, $size )
    my $size   = $bound[4];              # feature size in nt

    $type = 'CDS' if $type eq 'peg';
    if ( lc $type eq 'rna' )
    {
        $type = ( $func =~ /^tRNA/i ) ? 'tRNA'
              : ( $func =~ /^rRNA/i ) ? 'rRNA'
              :                         $type;
    }

    my $conf   = $qual->{existence_confidence} || 0.5;
    my $rules0 = $qual->{overlap_rules}        || [];   # not yet implemented
    my $hits   = $qual->{hit_count}            ||  0;

    my $exempt = 0;
    my $score  = 1.0;

    my $tool = $event->{tool_name} || '';
    $score  += 1.0  if $tool eq 'prodigal';

    #  Interpret rules supplied with the feature:

    my $rules  = {};
    foreach ( @$rules0 )
    {
        if    ( s/^+// ) { $rules->{ $_ }->{ default => { allow => 1 } } }
        elsif ( s/^-// ) { $rules->{ $_ }->{ default => { same => [ 0, 0.0, 0.0, 0, 0 ],
                                                          conv => [ 0, 0.0, 0.0, 0, 0 ],
                                                          div  => [ 0, 0.0, 0.0, 0, 0 ]
                                                        }
                                           };
                         }
    }

    #
    #  If we got rules, we just need to do a little interpretation,
    #  otherwise we need to supply some default rules that are reasonable
    #  for the feature type.
    #

    if ( %$rules )
    {
        $exempt = 1 if ( keys %$rules == 1 && $rules->{all} && $rules->{all}->{default}->{allow} );
    }
    elsif ( $type eq 'tRNA' )
    {
        $rules = $tRNA_rules;
        $score += 10;
    }
    elsif ( $type eq 'rRNA' )
    {
        $rules = $rRNA_rules;
        $score += 10;
    }
    elsif ( $type eq 'CDS' )
    {
        $rules = $CDS_rules;

        # $conf   = 0.99 if $conf > 0.99;
        # $score += log(1-$conf) / log(0.5);  # This may be redundant with $hits
        $score += 10 if $tool =~ /selenocys/i;
        $score += 10 if $tool =~ /pyrrolys/i;
        $score +=  0.1 * $hits / ($size/1000)**0.25 if $hits;
    }
    else
    {
        $exempt = 1;
    }

    #  This is adding data to the feature itself:
    $qual->{priority} = $score if ! defined( $qual->{priority} );

    my @rules = ( $type, $exempt, $score, $rules, \@bound );

    wantarray ? @rules : \@rules;
}


#
#  ( $contig, $left, $right, $dir, $size ) = bounds( $ftr );
#
sub bounds
{
    ( $_[0] && ( ref $_[0] eq 'HASH' ) ) or return ();

    my $loc = $_[0]->{ location };
    $loc && ref( $loc ) eq 'ARRAY' && @$loc && $loc->[0] && ref( $loc->[0] ) eq 'ARRAY'
        or return undef;
    my $size = 0;
    my $contig = $loc->[0]->[0] || '';
    my @parts  = @$loc;
    my ( $c0, $b, $d, $len ) = @{ shift @parts };
    my $size += $len;
    my $e = $b + ( $d eq '+' ? $len-1 : -($len-1) );
    my ( $left, $right ) = $d eq '+' ? ( $b, $b+$len-1 ) : ( $b-$len, $b );
    foreach ( @parts )
    {
        my ( $c, $b, $d, $len ) = @$_;
        my $size += $len;
        $c eq $c0 or next;
        my $e = $b + ( $d eq '+' ? $len-1 : -($len-1) );
        my ( $l, $r ) = $d eq '+' ? ( $b, $b+$len-1 ) : ( $b-$len+1, $b );
        $left  = $l if $l < $left;
        $right = $r if $r > $right;
    }

    ( $c0, $left, $right, $d, $size );
}

sub resolve_overlapping_features
{
    my($genomeTO, $opts) = @_;
    my $new_features = pick_features($genomeTO, $opts);
    $genomeTO->{features} = $new_features;
    return $genomeTO;
}   

sub pick_features
{
    my ( $genomeTO, $opts ) = @_;
    $genomeTO or return;
    $opts ||= {};

    my $ftrTO  = $genomeTO->{ features } || [];
    my $events = $genomeTO->{ analysis_events } || [];
    $opts->{ events } = { map { $_->{id} => $_ } @$events };

    #
    #  Add rule data to features and sort them:
    #
    #  [ $ftrTO, $type, $exempt, $score, $rules, [ $contig, $left, $right, $dir, $size ] ]
    #

    my @ftrs = sort { $a->[5]->[0] cmp $b->[5]->[0]    # contig
                   || $a->[5]->[1] <=> $b->[5]->[1]    # left end of feature
                   || $b->[5]->[2] <=> $a->[5]->[2]    # right end of feature
                   || $a->[5]->[3] cmp $b->[5]->[3]    # dir
                   || $a->[1]      cmp $b->[1]         # type
                   || $b->[3]      <=> $a->[3]         # score
                    }
               map  { [ $_, overlap_rules( $_, $opts ) ] }
               @$ftrTO;

    #
    #  Remove duplicates lower-scoring (later) duplicates:
    #

    {
        # my $m1 = @ftrs;
        my %seen;
        @ftrs = grep { ! $seen{ "$_->[1].$_->[5]->[0].$_->[5]->[1].$_->[5]->[2].$_->[5]->[3]" }++ } @ftrs;
        # my $m2 = @ftrs;
        # print STDERR "$m1 features -> $m2 features\n";
    }

    #
    #  A path is an endpoint in a linked list of consistent features.
    #
    #  $path = [ $ftr,         # last added feature
    #            $scr,         # total score for path
    #            $end,         # rightmost end of all features in path
    #            $path0        # path to which this feature was added
    #          ]
    #
    #  We start with one path with no prefix
    #
    my $path0   = [ undef, 0.0, -10000, [] ];
    my @current = ( $path0 );
    my @exempt  = ();        # Features that are exempt from overlap constraints
    my $contig  = "";        # Current contig
    my @kept    = ();

    #  Work through the features, adding to existing prefixes:

    foreach my $ftr2 ( @ftrs )
    {
        my ( $ftrTO2, $type2, $exempt2, $score2, $rules2, $bounds2 ) = @$ftr2;
        my ( $con2, $beg2, $end2, $dir2, $size2 ) = @$bounds2;

        if ( $contig && ( $con2 ne $contig ) ) # end of contig; report best path
        {
            # print STDERR "Reporting contig '$contig'.\n";
            push @kept, report( \@current, \@exempt );
            @current = ( $path0 );
            @exempt  = ();
        }

        $contig = $con2;

        if ( $exempt2 )
        {
            push @exempt, $ftr2;
            next;
        }

        #
        #  Reduce @current if we can. Keep only the best score of the
        #  current paths that end more than 1000 nt before the left end
        #  of the new feature.
        #

        my $gap       =  1000;  # Okay, I will parameterize this spacing
        my $best_path = undef;
        my $best_scr  =    -1;
        foreach ( @current )
        {
            next if ( $beg2 - $_->[2] <= $gap );
            ( $best_path, $best_scr ) = ( $_, $_->[1] ) if $_->[1] > $best_scr;
        }

        @current = grep { $beg2 - $_->[2] <= $gap } @current;
        push @current, $best_path if $best_path;

        #  Okay, let's try adding the new feature to each of the current
        #  candidate prefixes:

        my @added  = ();

        #  Search active paths for best prefix for new ftr:

        foreach my $pre1 ( @current )
        {
            my ( $ftr1, $scr1, $end0, $pre0 ) = @$pre1;
            my ( $sp_scr, $end ) = path_join_scr( $pre1, $ftr2 );
            if ( $score2 + $sp_scr >= 0 )
            {
                my $score = $scr1 + $score2 + $sp_scr;
                push @added, [ $ftr2, $score, $end, $pre1 ];
            }
        }

        push @current, @added;
    }

    #  Done; report the features on the contig

    # print STDERR "Reporting contig '$contig'.\n";
    push @kept, report( \@current, \@exempt ) if $contig;

    print STDERR scalar @kept, " features kept.\n";

    wantarray ? @kept : \@kept;
}


#
#  ( $sp_scr, $end )
#
sub path_join_scr
{
    my ( $path, $ftr2 ) = @_;

    my ( $ftr1, $scr1, $end0, $path0 ) = @$path;
    my ( $ftrTO2, $type2, $exempt2, $score2, $rules2, $bounds2 ) = @$ftr2;

    #  We can always add if there is no path

    return ( 0, -1000 )  if ! $ftr1;

    #  In the following, $beg and $end are really min and max coordinates:

    my ( $ftrTO1, $type1, $exempt1, $score1, $rules1, $bounds1 ) = @$ftr1;
    my ( $con1, $beg1, $end1, $dir1, $size1 ) = @$bounds1;
    my ( $con2, $beg2, $end2, $dir2, $size2 ) = @$bounds2;

    #  We prohibit adding two CDS features with same stop points. To override
    #  this, the shorter one(s) should be made exempt from overlap testing.

    if ( ( $type1 eq 'CDS' ) && ( $type2 eq 'CDS' ) && ( $dir1 eq $dir2 ) )
    {
        if ( $dir1 eq '+' ? $end1 == $end2 : $beg1 == $beg2 )
        {
            return ( -1000, 0 );
        }
    }

    my $space = $beg2 - $end1 - 1;
    my $rules = $rules2->{ $type1 }
             || $rules2->{ default }
             || { allow => 1 };

    my $sp_scr = 0;
    if ( ! $rules->{ allow } )
    {
        $sp_scr = spacing_scr( $end1, $beg2, scr_param( $rules, $dir1, $dir2 ) );
    }

    #
    #  Because different feature types can have different overlap rules,
    #  and because a shorter feature can be added later, the most recently
    #  pushed feature on a path might not be the most limiting.
    #
    my $end = $end1;
    if ( $sp_scr > -900 && $path0 && @$path0 && $path0->[2] >= $end1 )
    {
        my ( $s, $e ) = path_join_scr( $path0->[3], $ftr2 );

        #
        #  A negative score overrides any larger score.
        #
        if ( ( $s < 0 ) && ( $s < $sp_scr ) )
        {
            $sp_scr = $s;
            $end    = $e  if ( $e > $end );
        }

        #
        #  If score is not negative, we adjust it to the overlap with the end
        #  of the right-most feature.
        #
        elsif ( $e > $end )
        {
            $sp_scr = $s if $sp_scr >= 0;
            $end    = $e;
        }
    }

    ( $sp_scr, $end );
}


sub scr_param
{
    my ( $rules, $dir1, $dir2 ) = @_;
    $rules && $dir1 && $dir2 or return undef;

    return ( $dir1 eq $dir2 )               ? $rules->{ same }
         : ( $dir1 eq '+' && $dir2 eq '-' ) ? $rules->{ conv }
         : ( $dir1 eq '-' && $dir2 eq '+' ) ? $rules->{ div }
         :                                    undef;
}


#
#  Score for the length of space (or overlap) between prev stop and new start
#  "Ideal" intervals give max score
#
sub spacing_scr
{
    my ( $end1, $beg2, $scr_param ) = @_;
    return 0 unless $scr_param && ref( $scr_param ) eq 'ARRAY' && @$scr_param >= 5;

    my ( $max_over, $over_scr, $opt_scr, $opt_space, $decay ) = @$scr_param;
    my $min_space = -$max_over;
    my $space = $beg2 - $end1 - 1;

    return ( $space < $min_space ) ? -1000
         : ( $space < $opt_space ) ? ( $opt_scr - $over_scr ) * ( $space - $min_space ) / ( $opt_space - $min_space ) + $over_scr
         :                           $opt_scr * exp( -( $space - $opt_space ) / $decay );
}

#
#  @ftrTO = report( \@current, \@exempt );
#
sub report
{
    my ( $paths, $exempt ) = @_;

    my ( $path ) = sort { $b->[1] <=> $a->[1] } @{ $paths || [] };

    my @ftrTO = map { $_->[0] } @{ $exempt || [] };

    report1( $path, \@ftrTO )  if $path;

    wantarray ? @ftrTO : \@ftrTO;
}


sub report1
{
    my ( $path, $ftrTO ) = @_;
    ($path && $path->[0] && $path->[0]->[0]) or return;

    push @$ftrTO, $path->[0]->[0];
    report1( $path->[3], $ftrTO ) if $path->[3];
}


1;
