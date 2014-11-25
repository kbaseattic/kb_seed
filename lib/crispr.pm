package crispr;

# This is a SAS component.

use strict;
use gjoseqlib;
use gjostat;
use Data::Dumper;
# use Time::HiRes qw(time);

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( find_crisprs );

#===============================================================================
#  Find CRISPR repeat regions in DNA sequences:
#
#     @crisprs = find_crisprs( \@seq_entries, \%opts )
#     @crisprs = find_crisprs(  $seq_entry,   \%opts )
#    \@crisprs = find_crisprs( \@seq_entries, \%opts )
#    \@crisprs = find_crisprs(  $seq_entry,   \%opts )
#
#  Options:
#
#    maxperiod   => int       #  Maximum repeat period
#    maxreplen   => int       #  Maximum length of repeat (D = 40)
#    maxsplen    => int       #  Maximum distance between repeats (D = 50)
#    minperiod   => int       #  Minimum repeat period
#    minreplen   => int       #  Minimum length of repeat (D = 24)
#    minsplen    => int       #  Minimum distance getween repeats (D = 30)
#    mintimes    => int       #  Minimum nuber of repeats in an array (D = 4)
#    minconsenid => fraction  #  Minimum conservation to add to repeat (D = 0.80)
#    minmatchid  => fraction  #  Minimum conservation to match repeat; default
#                             #     is defined by pmatch
#    pmatch      => fraction  #  P-value threshold for adding another repeat
#                             #     (D = 0.001); this value alters minmatchid
#
#  Output:
#
#  @crisprs = ( [ $loc, $consensus, \@repeats, \@spacers ], ...)
#  @repeats = ( [ $loc, $repseq ], ... )
#  @spacers = ( [ $loc, $spcseq ], ... )
#  $loc     = [ [ $contig, $beg, $dir, $len ], ... ]
#
#===============================================================================
sub find_crisprs
{
    my ( $seqs, $opts ) = @_;
    $opts ||= {};

    my $minrep      = $opts->{ mintimes    } ||  3;      #  Min number of repeats

    my $maxperiod   = $opts->{ maxperiod   } ||  0;      #  Max period (maxreplen + maxsplen)

    my $minreplen   = $opts->{ minreplen   }
                   || $opts->{ repeatlen   } || 24;      #  Min length of repeat unit
    my $maxreplen   = $opts->{ maxreplen   } || 40;      #  Max length of repeat unit

    my $minsp       = $opts->{ minsplen    } || 30;      #  Min distance between repeats
    my $maxsp       = $opts->{ maxsplen    } || 54;      #  Max spacer length

    my $min_mat_id  = $opts->{ minmatchid  } ||  0;      #  Minimum match identity (D = P-val based)
    my $p_match     = $opts->{ pmatch      } ||  0.0001; #  Maximum match P-value

    my $debug       = defined $opts->{ debug } ? $opts->{ debug } : 0; 

    my $min_nid = $min_mat_id ? int( $min_mat_id * $minreplen )
                              : gjostat::binomial_critical_value_m_ge( $minreplen, 0.3, $p_match );

    $minrep--;                    #  The first occurrance is not counted

    my @crisprs;
    foreach my $entry ( ref $seqs->[0] eq 'ARRAY' ? @$seqs : ( $seqs ) )
    {
        my $id  =    $entry->[0];
        my $seq = lc $entry->[2];

        #  Find each repeat array:

        my $pos0 = 0;
        my @parts;
        my $maxgap = $maxsp + ( $maxreplen - $minreplen );
        while ( $seq =~ m/([acgt]{$minreplen})((?:[acgt]{$minsp,$maxgap}\1){2,})/g )
        {
            my $n1      = $-[0];
            my $n2      = $+[0];
            my $rept    = $1;
            my $rest    = $2;
            my @parts   = $rest =~ m/([acgt]{$minsp,$maxgap}$rept)/g;
            my @hits    = $rest =~ m/$rept/g;
            print STDERR "  *** low complexity repeat skipped\n\n" if $debug && ( @hits > @parts );
            next if ( @hits > @parts );              # Poor man's test for simple repeat

            my $len     = length( $rest );
            my $period  = int( $len / @parts + 0.5 );

            #  @locs are offsets to starts of repeats in the sequence string

            my $n       = $n1;
            my @locs    = map { $n += length($_) } ( '', @parts );

            print STDERR "  $rept:\n",
                         ( map { sprintf "%12d\n", $_ } @locs ),
                         "\n" if $debug;

            #  Find framing of repeat sequence that maximizes the number of
            #  repeats.

            my $best_locs = [];
            my $max_shift = $maxreplen - $minreplen + 4;
            for ( my $delta = -$max_shift; $delta <= $max_shift; $delta++ )
            {
                # Working from the second repeat helps if first repeat is truncated

                my $p = $locs[1] + $delta;
                my $r = substr( $seq, $p, $minreplen );

                #  Work backward and forward, looking for matches:

                my @l = ( extend_array_backward( \$seq, $r, $p - $period, $period, $min_nid ),
                          $p,
                          extend_array_forward(  \$seq, $r, $p + $period, $period, $min_nid )
                        );

                $best_locs = \@l if ( @l > @$best_locs );
            }

            @locs = @$best_locs;
            next if ( @locs < $minrep );

            print STDERR "  $rept (requires $min_nid / $minreplen):\n",
                         ( map { sprintf "%12d  %s\n", $_, substr( $seq, $_, $minreplen ) } @locs ),
                         "\n" if $debug;

            #  Find the repeat profile:

            my @data;
            for ( my $i = -$max_shift; $i <= $maxreplen+4; $i++ )
            {
                # ( $nt, $n_change, $ttl ) = consensus_at_offset( \$seq, \@locs, $i )

                push @data, [ $i, consensus_at_offset( \$seq, \@locs, $i ) ];
            }

            my $max_chg = int( 0.25 * @locs + 0.5 );
            my @runs;
            my $run = [];
            foreach ( @data )
            {
                #  Too much variation? This cannot be in the consensus.
                if    ( $_->[2] <= $max_chg ) { push @$run, $_ }
                elsif ( @$run )               { push @runs, $run; $run = [] }
                next;
            }
            push @runs, $run if @$run;

            @runs or next;   #  This would be very bad

            ( $run ) = sort { @$b <=> @$a } @runs;
            my $replen = @$run;
            my $repseq = join( '', map { $_->[1] } @$run );
            if ( $replen < $minreplen )
            {
                print STDERR "Consensus length ($replen) is less than $minreplen.\n" if $debug;
                next;
            }
            if ( $replen > $maxreplen )
            {
                print STDERR "Consensus length ($replen) is greater than $maxreplen.\n" if $debug;
                next;
            }

            my $badsp = 0;
            for ( my $i = 1; $i < @locs; $i++ )
            {
                my $sp = $locs[$i] - $locs[$i-1] - $replen;
                $badsp++ if ($sp < $minsp) || ($sp > $maxsp);
            }
            if ( $badsp > 0.5 * ( @locs - 2 ) )
            {
                print STDERR "Too many bad spacer lengths.\n" if $debug;
                next;
            }

            my $offset = $run->[0]->[0];
            foreach ( @locs ) { $_ += $offset }

            #  Describe the array:

            my $beg = $locs[ 0];
            my $end = $locs[-1] + $replen - 1;
            $beg = 0 if $beg < 0;
            $end = length($seq) - 1 if $end >= length($seq);
            my $len = $end - $beg + 1;
            my $loc = [ [ $id, $beg+1, '+', $len ] ];

            #  Split into repeats and spacers:

            my @reps;
            my @spcs;
            for ( my $i = 0; $i < @locs; $i++ )
            {
                # Repeat element:

                my $rbeg = $locs[$i];
                my $rend = $rbeg + $replen - 1;
                $rbeg = 0 if $rbeg < 0;
                $rend = length($seq) - 1 if $rend >= length($seq);
                my $rlen = $rend - $rbeg + 1;
                my $rloc = [ [ $id, $rbeg+1, '+', $rlen ] ];
                my $rseq = substr( $seq, $rbeg, $rlen );
                push @reps, [ $rloc, $rseq ];

                # Spacer element:

                if ( $locs[$i+1] )
                {
                    my $sbeg = $rend + 1;
                    my $slen = $locs[$i+1] - $sbeg;
                    my $sloc = [ [ $id, $sbeg+1, '+', $slen ] ];
                    push @spcs, [ $sloc, substr( $seq, $sbeg, $slen ) ];
                }
            }

            #  The spacers are still coming through with repeated sequences.
            #  For the time being, let's do a clean up based on kmer counts.

            my %kmers;
            my $klen = 6;
            my $nmax = 0.7 * @spcs;
            foreach my $sp ( map { $_->[1] } @spcs )
            {
                my %k = map { $_ => 1 }                              # hash
                        map { m/(.{$klen})/g }                       # kmers
                        map { substr( $sp, $_ ) } ( 0 .. $klen-1 );  # frames
                foreach ( keys %k ) { $kmers{$_}++ }
            }
            my ( $maxcnt ) = sort { $b <=> $a } values %kmers;

            if ( $maxcnt <= $nmax )
            {
                #  Save location, repeat consensus, repeats and spacers:
                #  $crispr = [ $loc, $repseq, \@repeats, \@spacers ];
                push @crisprs, [ $loc, $repseq, \@reps, \@spcs ];
            }
            elsif ( $debug )
            {
                print STDERR "=========================================================\n";
                print STDERR "Repeats in the spacers:\n";
                print STDERR map { "    $_->[1]\n" } @spcs;
                print STDERR "=========================================================\n\n";
            }

            #  Move past this repeat array:

            pos( $seq ) = $pos0 = $end + 1;

        }
    }

    wantarray ? @crisprs : \@crisprs;
}


#-------------------------------------------------------------------------------
#  Find locations that match a repeat consensus starting near a position.
#  This version updates the repeat with each new match, allowing sequence
#  creep.
#
#     @locs = extend_array_backward( \$seq, $rep, $pos, period, $min_nid )
#     @locs = extend_array_forward(  \$seq, $rep, $pos, period, $min_nid )
#
#-------------------------------------------------------------------------------
sub extend_array_backward
{
    my ( $seqR, $rept, $pos0, $period, $min_nid ) = @_;

    my $replen   = length( $rept );
    my $vicinity = 15;

    my @locs   = ();
    while ( $pos0 + $vicinity >= 0 )
    {
        #  Search vicinity outward from pos0:

        my $hit_pos = search_vicinity( $seqR, $rept, $pos0, $min_nid, 2 * $vicinity );
        if ( $hit_pos >= 0 )
        {
            unshift @locs, $hit_pos;
            $rept = substr( $$seqR, $hit_pos, $replen );
            $pos0 = $hit_pos - $period;
            next;
        }

        #  Search progressively to left for one more period:

        $pos0 -= $vicinity;
        my $pmin = $pos0 - $period;
        $pmin = 0 if $pmin < 0;
        for ( ; $pos0 >= $pmin; $pos0-- )
        {
            my $nid = identical_nt( $rept, substr( $$seqR, $pos0, $replen ) );
            if ( $nid >= $min_nid )
            {
                unshift @locs, $pos0;
                $rept = substr( $$seqR, $pos0, $replen );
                $pos0 -= $period;
                next;
            }
        }

        #  Search fell through; end of array:

        last;
    }

    @locs;
}


sub extend_array_forward
{
    my ( $seqR, $rept, $pos0, $period, $min_nid ) = @_;

    my $replen   = length( $rept );
    my $seqlen   = length( $$seqR );
    my $pmax     = $seqlen - $replen;
    my $vicinity = 20;

    my @locs   = ();
    while ( $pos0 - $vicinity <= $pmax )
    {
        #  Search vicinity outward from pos0:

        my $hit_pos = search_vicinity( $seqR, $rept, $pos0, $min_nid, 2 * $vicinity );
        if ( $hit_pos >= 0 )
        {
            push @locs, $hit_pos;
            $rept = substr( $$seqR, $hit_pos, $replen );
            $pos0 = $hit_pos + $period;
            next;
        }

        #  Search progressively to left for one more period:

        $pos0 += $vicinity;
        my $pmax2 = $pos0 + $period;
        $pmax2 = $pmax if $pmax2 > $pmax;
        for ( ; $pos0 <= $pmax2; $pos0++ )
        {
            my $nid = identical_nt( $rept, substr( $$seqR, $pos0, $replen ) );
            if ( $nid >= $min_nid )
            {
                push @locs, $pos0;
                $rept = substr( $$seqR, $pos0, $replen );
                $pos0 += $period;
                next;
            }
        }

        #  Search fell through; end of array:

        last;
    }

    @locs;
}


#-------------------------------------------------------------------------------
#  Find the consensus residue at an offset for a series of positions.
#  Evaluate the number of state changes of the residue.
#
#  ( $residue, $n_change, $ttl ) = consensus_at_offset( \$seq, \@locs, $offset )
#
#-------------------------------------------------------------------------------
sub consensus_at_offset
{
    my ( $seqR, $locL, $offset ) = @_;

    my $len  = length( $$seqR );
    my $prev = '';
    my $nchg = 0;
    my $ttl  = 0;
    my %cnt;
    foreach ( @$locL )
    {
        my $loc = $_ + $offset;
        next if ( $loc < 0 ) || ( $loc >= $len );
        my $nt = substr( $$seqR, $loc, 1 );
        next if $nt !~ /[acgt]/;
        $cnt{ $nt }++;
        $ttl++;
        $nchg++ if $prev && $prev ne $nt;
        $prev = $nt;
    }

    my ( $nt ) = sort { $cnt{$b} <=> $cnt{$a} } keys %cnt;

    ( $nt, $nchg, $ttl );
}


#===============================================================================
#  Find CRISPR repeat regions in DNA sequences:
#
#     @crisprs = find_crisprs2( \@seq_entries, \%opts )
#     @crisprs = find_crisprs2(  $seq_entry,   \%opts )
#    \@crisprs = find_crisprs2( \@seq_entries, \%opts )
#    \@crisprs = find_crisprs2(  $seq_entry,   \%opts )
#
#  Options:
#
#    maxperiod   => int       #  Maximum repeat period
#    maxreplen   => int       #  Maximum length of repeat (D = 40)
#    maxsplen    => int       #  Maximum distance between repeats (D = 50)
#    minperiod   => int       #  Minimum repeat period
#    minreplen   => int       #  Minimum length of repeat (D = 24)
#    minsplen    => int       #  Minimum distance getween repeats (D = 30)
#    mintimes    => int       #  Minimum nuber of repeats in an array (D = 4)
#    minconsenid => fraction  #  Minimum conservation to add to repeat (D = 0.80)
#    minmatchid  => fraction  #  Minimum conservation to match repeat; default
#                             #     is defined by pmatch
#    pmatch      => fraction  #  P-value threshold for adding another repeat
#                             #     (D = 0.001); this value alters minmatchid
#
#  Output:
#
#  @crisprs = ( [ $loc, $consensus, \@repeats, \@spacers ], ...)
#  @repeats = ( [ $loc, $repseq ], ... )
#  @spacers = ( [ $loc, $spcseq ], ... )
#  $loc     = [ $contig, $beg, $dir, $len ]
#
#===============================================================================
sub find_crisprs2
{
    my ( $seqs, $opts ) = @_;
    $opts ||= {};

    my $minrep      = $opts->{ mintimes    } ||  3;     #  Min number of repeats

    my $maxperiod   = $opts->{ maxperiod   } ||  0;     #  Max period (maxreplen + maxsplen)

    my $minreplen   = $opts->{ minreplen   }
                   || $opts->{ repeatlen   } || 24;     #  Min length of repeat unit
    my $maxreplen   = $opts->{ maxreplen   }            #  Max length of repeat unit
                   || $minreplen + 16;                  #     (D = minreplen + 16)

    my $minsp       = $opts->{ minsplen    } || 30;     #  Min distance between repeats
    my $maxsp       = $opts->{ maxsplen    }            #  Max spacer length
                   || $minsp + 24;                      #      (D = minspacer + 24)

    my $min_cons_id = $opts->{ minconserve } ||  0.80;  #  Conservation in repeat consensus
    my $min_mat_id  = $opts->{ minmatchid  } ||  0;     #  Minimum match identity (D = P-val based)
    my $p_match     = $opts->{ pmatch      } ||  0.001; #  Maximum match P-value

    my $debug       = defined $opts->{ debug } ? $opts->{ debug } : 0; 

    my $replen  = $minreplen;
    my $min_nid = $min_mat_id ? int( $min_mat_id * $replen )
                              : gjostat::binomial_critical_value_m_ge( $minreplen, 0.3, $p_match );

    $minrep--;                    #  The first occurrance is not counted

    my @crisprs;
    foreach my $entry ( ref $seqs->[0] eq 'ARRAY' ? @$seqs : ( $seqs ) )
    {
        my $id  =    $entry->[0];
        my $seq = lc $entry->[2];

        #  Find each repeat array:

        my $pos0 = 0;
        my @parts;
        my $maxgap = $maxsp + ( $maxreplen - $replen );
        while ( $seq =~ m/([acgt]{$replen})((?:[acgt]{$minsp,$maxgap}\1){$minrep,})/g )
        {
            my $n1      = $-[0];
            my $n2      = $+[0];
            my $rept    = $1;
            my $rest    = $2;
            my @parts   = $rest =~ m/([acgt]{$minsp,$maxgap}$rept)/g;
            my @hits    = $rest =~ m/$rept/g;
            print STDERR "  *** low complexity repeat skipped\n\n" if $debug && ( @hits > @parts );
            next if ( @hits > @parts );              # Poor man's test for simple repeat

            my $len     = length( $rest );
            my $period  = int( $len / @parts + 0.5 );
            my $n       = $n1;
            my @locs    = map { $n += length($_) } ( '', @parts );

            print STDERR "  $rept:\n",
                         ( map { sprintf "%12d\n", $_ } @locs ),
                         "\n" if $debug;

            #  Work backward, looking for more matches:

            unshift @locs, extend_array_backward_2( \$seq, $rept, $n1 - $period, $period, $min_nid );

            #  Work forwards, looking for more matches:

            push @locs, extend_array_forward_2( \$seq, $rept, $locs[-1] + $period, $period, $min_nid );

            print STDERR "  $rept (requires $min_nid / $replen):\n",
                         ( map { sprintf "%12d  %s\n", $_, substr( $seq, $_, $replen ) } @locs ),
                         "\n" if $debug;

            #  Refine repeat profile:

            my $min_i   = -( $maxreplen - $replen + 4 );
            my $max_i   =    $maxreplen           + 4;
            my $current = { seq => [], good => 0 };
            my $consen  = $current;
            my @miss    = ();
            for ( my $i = $min_i; $i < $max_i; $i++ )
            {
                my ( $nt, $frac ) = consensus_at_offset_2( \$seq, \@locs, $i );

                #  If this is a good position, extend the current string
                if ( $frac >= $min_cons_id )
                {
                    push @{ $current->{ seq } }, @miss, $nt;
                    $current->{ good }++;
                    $current->{ i1 } = $i if ! defined( $current->{ i1 } );

                    #  If this is better than the best consensus, make this the best
                    if ( $current ne $consen && $current->{good} > $consen->{good} )
                    {
                        $consen = $current;
                    }
                    @miss = ();
                }

                #  If this exceeds the limit on consecutive bad positions, start over
                elsif ( @miss > 0 )
                {
                    if ( $current->{ good } && $current eq $consen )
                    {
                        $current = { seq => [], good => 0 };
                    }
                    else
                    {
                        @{ $current->{ seq } } = ();
                        $current->{ good } = 0;
                    }
                    @miss = ();
                }

                else
                {
                    push @miss, $nt;
                }
            }

            my $rept2;
            my $replen2;
            if ( $consen->{ good } >= $replen )
            {
                $rept2   = join( '', @{ $consen->{ seq } } );
                $replen2 = length( $rept2 );
            }

            if ( $rept2 && $rept2 ne $rept )
            {
                if ( $replen2 > $maxreplen )
                {
                    print STDERR "  *** repeat exceeds maximum length ($replen2 vs. $maxreplen).\n\n" if $debug;
                    next;
                }

                $n1 += $consen->{ i1 };
                my $min_nid2 = $min_mat_id ? int( $min_mat_id * $replen2 )
                                           : gjostat::binomial_critical_value_m_ge( $replen2, 0.3, $p_match );

                #  Work backward and forward, looking for matches:

                @locs = ( extend_array_backward_2( \$seq, $rept2, $n1,           $period, $min_nid2 ),
                          extend_array_forward_2(  \$seq, $rept2, $n1 + $period, $period, $min_nid2 )
                        );

                print STDERR "  $rept2 (requires $min_nid2 / $replen2):\n",
                             ( map { sprintf "%12d  %s\n", $_, substr( $seq, $_, $replen2 ) } @locs ),
                             "\n\n" if $debug;
            }
            else
            {
                $rept2   = $rept;
                $replen2 = $replen;
            }

            #  Describe the array:

            my $beg = $locs[ 0];
            my $end = $locs[-1] + $replen2 - 1;
            my $len = $end - $beg + 1;
            my $loc = [ $id, $beg, '+', $len ];

            #  Split into repeats and spacers:

            my @reps;
            my @spcs;
            for ( my $i = 0; $i < @locs; $i++ )
            {
                # Repeat element:

                my $rbeg = $locs[$i];
                my $rloc = [ $id, $rbeg, '+', $replen2 ];
                my $rseq = substr( $seq, $rbeg, $replen2 );
                push @reps, [ $rloc, $rseq ];

                # Spacer element:

                if ( $locs[$i+1] )
                {
                    my $sbeg = $rbeg + $replen2;
                    my $slen = $locs[$i+1] - $sbeg;
                    my $sloc = [ $id, $sbeg, '+', $slen ];
                    push @spcs, [ $sloc, substr( $seq, $sbeg, $slen ) ];
                }
            }

            #  Save location, repeat consensus, repeats and spacers:
            #  $crispr = [ $loc, $repseq, \@repeats, \@spacers ];

            push @crisprs, [ $loc, $rept2, \@reps, \@spcs ];

            #  Move past this repeat array:

            pos( $seq ) = $pos0 = $end + 1;
        }
    }

    wantarray ? @crisprs : \@crisprs;
}


#-------------------------------------------------------------------------------
#  Find locations that match a repeat consensus starting near a position.
#
#     @locs = extend_array_backward_2( \$seq, $rep, $pos, period, $min_nid )
#     @locs = extend_array_forward_2(  \$seq, $rep, $pos, period, $min_nid )
#
#-------------------------------------------------------------------------------
sub extend_array_backward_2
{
    my ( $seqR, $rept, $pos0, $period, $min_nid ) = @_;

    my $replen   = length( $rept );
    my $vicinity = 15;

    my @locs   = ();
    while ( $pos0 + $vicinity >= 0 )
    {
        #  Search vicinity outward from pos0:

        my $hit_pos = search_vicinity( $seqR, $rept, $pos0, $min_nid, 2 * $vicinity );
        if ( $hit_pos >= 0 )
        {
            unshift @locs, $hit_pos;
            $pos0 = $hit_pos - $period;
            next;
        }

        #  Search progressively to left for one more period:

        $pos0 -= $vicinity;
        my $pmin = $pos0 - $period;
        $pmin = 0 if $pmin < 0;
        for ( ; $pos0 >= $pmin; $pos0-- )
        {
            my $nid = identical_nt( $rept, substr( $$seqR, $pos0, $replen ) );
            if ( $nid >= $min_nid )
            {
                unshift @locs, $pos0;
                $pos0 -= $period;
                next;
            }
        }

        #  Search fell through; end of array:

        last;
    }

    @locs;
}


sub extend_array_forward_2
{
    my ( $seqR, $rept, $pos0, $period, $min_nid ) = @_;

    my $replen   = length( $rept );
    my $seqlen   = length( $$seqR );
    my $pmax     = $seqlen - $replen;
    my $vicinity = 20;

    my @locs   = ();
    while ( $pos0 - $vicinity <= $pmax )
    {
        #  Search vicinity outward from pos0:

        my $hit_pos = search_vicinity( $seqR, $rept, $pos0, $min_nid, 2 * $vicinity );
        if ( $hit_pos >= 0 )
        {
            push @locs, $hit_pos;
            $pos0 = $hit_pos + $period;
            next;
        }

        #  Search progressively to left for one more period:

        $pos0 += $vicinity;
        my $pmax2 = $pos0 + $period;
        $pmax2 = $pmax if $pmax2 > $pmax;
        for ( ; $pos0 <= $pmax2; $pos0++ )
        {
            my $nid = identical_nt( $rept, substr( $$seqR, $pos0, $replen ) );
            if ( $nid >= $min_nid )
            {
                push @locs, $pos0;
                $pos0 += $period;
                next;
            }
        }

        #  Search fell through; end of array:

        last;
    }

    @locs;
}


sub search_vicinity
{
    my ( $seqR, $rept, $pos, $min_nid, $window ) = @_;
    $window ||= 30;
    my $replen = length( $rept );
    my $pmax   = length( $$seqR ) - length( $rept );
    for ( my $i = 0; $i <= $window; $i++ )
    {
        $pos += ($i & 1) ? $i : -$i;  # Forward on odd, backward on even
        next if ( $pos < 0 ) || ( $pos > $pmax );
        my $nid = identical_nt( $rept, substr( $$seqR, $pos, $replen ) );
        # print STDERR "        $pos  $nid / $min_nid\n";
        return $pos if ( $nid >= $min_nid );
    }

    -1;
}


#-------------------------------------------------------------------------------
#  Find the consensus residue at an offset from a series of positions.
#  Omit the first and last repeats.
#
#  ( $residue, $frac ) = consensus_at_offset_2( \$seq, \@locs, $offset )
#
#-------------------------------------------------------------------------------
sub consensus_at_offset_2
{
    my ( $seqR, $locL, $offset ) = @_;

    my $len = length( $$seqR );
    my %cnt;
    my @locs = @$locL;
    shift @locs;
    pop   @locs;
    foreach ( @locs )
    {
        my $loc = $_ + $offset;
        next if $loc < 0 || $loc >= $len;
        my $nt = substr( $$seqR, $loc, 1 );
        $cnt{ $nt }++ if $nt =~ /[acgt]/;
    }

    my $c;
    my $cmax = 0;
    my $ttl  = 0;
    my $nt   = '';
    foreach ( keys %cnt )
    {
        $ttl += $c = $cnt{$_};
        if ( $c > $cmax ) { $cmax = $c; $nt = $_ }
    }

    ( $nt, $ttl ? $cmax / $ttl : 0 );
}


#-------------------------------------------------------------------------------
#  Number of identical nontrivial nucleotides in align.
#
#     $nid = identical_nt( $seq1, $seq2 )
#
#-------------------------------------------------------------------------------
sub identical_nt
{
    my ( $s1, $s2 ) = @_;
    $s1 =~ tr/acgt/\377/c;                # Disallowed symbols to x'FF' byte
    $s2 =~ tr/acgt/\376/c;                # Disallowed symbols to x'FE' byte
    scalar ( ( $s1^$s2 ) =~ tr/\000// );  # Count the nulls (identical residues)
}


sub sum { my $ttl = 0; foreach ( @_ ) { $ttl += $_ if defined $_ }; $ttl }


1;
