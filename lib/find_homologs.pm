package find_homologs;

# This is a SAS component.
#
#  Find homologs to a set of nucleotide sequences
#
use strict;
use gjoseqlib;
use gjoparseblast;
use SeedAware;
use Data::Dumper;

my $debug = 0;

require Exporter;

our @ISA    = qw( Exporter );
our @EXPORT = qw( find_nucleotide_homologs );


#===============================================================================
#
#  \@instances = find_nucleotide_homologs( \@contigs,     \%options )
#  \@instances = find_nucleotide_homologs(  $contig_file, \%options )
#
#  An instance is:
#
#      { location   => $loc,       #  SEED or Sapling location string
#        definition => $def,
#        sequence   => $seq,
#        uncover5   => $uncov5,    #  Uncovered ref seq 5' end
#        uncover3   => $uncov3,
#        from_end5  => $fromend5,  #  Distance to contig end
#        from_end3  => $fromend3
#      }
#
#  Options:
#
#      blastall    =>  $blastall_path        # Use specified blastall program
#      blastall    =>  $bool                 # Use default blastall program
#      blastn      =>  $blastm_path          # Use specified blastn program
#      blastn      =>  $bool                 # Use default blastn program (D)
#      coverage    =>  $min_coverage         # D = 0.70
#      descript    =>  $description          # D = ''
#      description =>  $description          # D = ''
#      expect      =>  $max_expect           # D = 1e-2
#      extrapol    =>  $max_extrapolate      # D = 0
#      extrapolate =>  $max_extrapolate      # D = 0
#      formatdb    =>  $formatdb_path
#      identity    =>  $min_identity         # D = 0.60
#      loc_format  =>  $format               # SEED, Sapling, CBDL [contig,beg,dir,len]
#      maxgap      =>  $max_gap              # D = 5000 nt
#      maxsplit    =>  $max_split            # Modify description to reflect truncated
#                                            #    ref sequence match (<= max split from
#                                            #    end of contig) or fragment (> max
#                                            #    split from end of contig)
#      mingain     =>  $min_gain             # D =   10 nt query coverage for merge
#      prefix      =>  $contig_id_prefix     # D = ''
#      reffile     =>  $filename
#      refseq      => \@seqs
#      seedexp     =>  $max_seed_expect      # D = 1e-20
#      tmp         =>  $location_for_tmpdir
#      tmpdir      =>  $location_of_tmpdir
#      verbose     =>  boolean               # D = 0
#
#===============================================================================

sub find_nucleotide_homologs
{
    my ( $contigs, $options ) = @_;
    -f $contigs && -s $contigs
       or ref $contigs eq 'ARRAY' && ref $contigs->[0] eq 'ARRAY'
       or print STDERR "find_nucleotide_homologs called with bad \\\@contigs\n"
          and return [];
    ref $options eq 'HASH'
       or print STDERR "find_nucleotide_homologs called with bad \\%options\n"
          and return [];

    my $blastall  = $options->{ blastall };
    my $blastn    = $options->{ blastn };
    my $min_cover = $options->{ coverage }   ||=    0.70;  # Minimum fraction of reference covered
       $debug     = $options->{ debug } if exists $options->{ debug };
    my $max_exp   = $options->{ expect }     ||=    0.01;  # Maximum e-value for blast
    my $extrapol  = $options->{ extrapol }   ||= $options->{ extrapolate } || 0;  # Max to extrapolate ends of subj seq
    my $formatdb  = $options->{ formatdb }   ||= SeedAware::executable_for( 'formatdb' );
    my $ftr_type  = $options->{ ftrtype } if exists $options->{ ftrtype };
    my $descr     = $options->{ descript }   ||= $options->{ description } || "";
    my $loc_form  = $options->{ loc_format } ||= 'seed';
    my $min_ident = $options->{ identity }   ||=    0.60;  # Minimum fraction sequence identity
    my $max_split = $options->{ maxsplit }   ||=    0;
    my $max_gap   = $options->{ maxgap }     ||= 5000;     # Maximum gap in genome match
    my $prefix    = $options->{ prefix }     ||=   "";
    my $ref_file  = $options->{ reffile };
    my $ref_seq   = $options->{ refseq };
    my $seed_exp  = $options->{ seedexp }    ||=    1e-20; # Maximum e-value to nucleate match
    my $verbose   = $options->{ verbose }    ||=    0;

    my ( $tmp_dir, $save_tmp ) = SeedAware::temporary_directory( $options );

    #  Find the blast program. Note the blastn is now the default given observations
    #  that blastall seems to return corrupt output for some large query files,
    #  which puts the reading of output out of sync with the contigs.

    if ( $blastn || ( ! $blastall ) )
    {
        $blastn = SeedAware::executable_for( 'blastn' ) unless -x $blastn;
    }
    if ( ! ( -x $blastn ) )
    {
        $blastall = SeedAware::executable_for( 'blastall' ) unless -x $blastall;
        if ( ! ( -x $blastall ) )
        {
            print STDERR "find_nucleotide_homologs() failed to find a blast program.\n";
            return wantarray ? () : [];
        }
    }

    #  Build the blast database of reference sequences:
    #
    #  Four cases:
    #     "$ref_file.nsq" exists
    #         use it
    #     "$ref_file.nsq" and $ref_seq do not exist, but "$ref_file" exists
    #         run formatdb -i $ref_file -n "$tmp_dir/$tmp_name"
    #     "$ref_file.nsq" does not exist, but $ref_seq exists
    #         write a temp file in $tmp_dir and run formatdb -i "$tmp_dir/$tmp_name"
    #     nothing exists
    #         bail

    my $db;
    if ( $ref_file && -f "$ref_file.nsq" )
    {
        $db = $ref_file;
    }
    elsif ( ref $ref_seq eq 'ARRAY' && ref $ref_seq->[0] eq 'ARRAY' )
    {
        $db = "$tmp_dir/ref_seqs";
        print_alignment_as_fasta( $db, $ref_seq );
        my @cmd = ( $formatdb, -p => 'f', -i => $db );
        system( @cmd ) and die join( ' ', 'Failed', @cmd );
    }
    elsif ( -f $ref_file && -s $ref_file )
    {
        my $name = $ref_file;
        $name =~ s/^.*\///;    # Remove leading path
        $db = "$tmp_dir/$name";
        my @cmd = ( $formatdb, -p => 'f', -i => $ref_file, -n => $db );
        system( @cmd ) and die join( ' ', 'Failed', @cmd );
    }
    else
    {
        print STDERR "find_nucleotide_homologs cannot locate reference sequence data\n";
        return [];
    }

    $options->{ db } = $db;

    #  There are two ways to go for the contigs:
    #
    #     $contigs is a file of contigs
    #         use it
    #     $contigs is a reference to an array of sequences
    #         write them to a file

    my $qfile;
    if ( ref $contigs eq 'ARRAY' )
    {
        return [] if ! @$contigs;
        return [] if ! ref $contigs->[0] eq 'ARRAY';   #  Could do better diagnosis
        $qfile   = "$tmp_dir/query";
        print_alignment_as_fasta( $qfile, $contigs );  #  Write them all
    }
    else
    {
        -f $contigs
            or print STDERR "Bad contigs file '$contigs'\n"
            and return [];
        $qfile = $contigs;
    }

    my @cmd = $blastn ? ( $blastn,
                          -db               => $db,
                          -query            => $qfile,
                          -reward           =>  1,
                          -penalty          => -1,
                          -gapopen          =>  2,   # These are required
                          -gapextend        =>  1,   # These are required
                          -dust             => 'no',
                          -evalue           => $max_exp,
                          -num_descriptions =>  5,
                          -num_alignments   =>  5,
                          -num_threads      =>  2
                        )
                      : ( $blastall,
                          -p => 'blastn',
                          -d => $db,
                          -i => $qfile,
                          -r =>  1,
                          -q => -1,
                          -F => 'f',
                          -e => $max_exp,
                          -v =>  5,
                          -b =>  5,
                          -a =>  2
                        );

    my $redirect = { stderr => '/dev/null' };
    my $blastFH = SeedAware::read_from_pipe_with_redirect( @cmd, $redirect )
        or die join( ' ', 'Failed:', @cmd );

    #  Process contig blast results one contig at a time

    my @out;
    my $contig;  #  Contig sequence data
    my $n = 0;

    while ( $contig = next_contig( $contigs, $n++ ) )
    {
        my $query_results = next_blast_query( $blastFH );
        # if ( $contig->[0] eq 'AACY01526565' or $contig->[0] eq 'AACY01526566' )
        # {
        #     print STDERR Dumper( $contig, $query_results )
        # }
        $query_results or next;

        my ( $qid, $qdef, $qlen, $q_matches ) = @$query_results;

        #  Check the framing between contigs and blast queries:

        if ( $qid ne $contig->[0] )
        {
            die "Contig data ($contig->[0]) and blastn output ($qid) are out of phase.\n";
        }

        #  A given query (contig) may hit zero or more reference sequences

        my @matches = ();
        foreach my $subject_results ( @$q_matches )
        {
            my ( $sid, $sdef, $slen, $s_matches ) = @$subject_results;
            push @matches, merge_hsps( $qlen, $slen, $s_matches, $options );
        }

        #  Okay, now we need to remove duplicates:

        my @merged = merge_contig_matches( \@matches );

        #  Report matched sequences, or just locations:

        $qid      =  $contig->[0];
        my $qseqR = \$contig->[2];
        foreach ( sort { $a->[3] <=> $b->[3] } @merged )
        {
            # [ $l, $r, $d, $m, $uc5, $uc3 ]
            my ( $l, $r, $dir ) = @$_[0,1,2];
            my ( $beg, $end ) = ( $dir > 0 ) ? ( $l, $r ) : ( $r, $l );
            my $loc = format_match_location( $qid, $beg, $end, $dir, $r-$l+1, $loc_form );
            my ( $l_dist, $r_dist ) = ( $l - 1, length( $$qseqR ) - $r );
            my ( $from_end5, $from_end3 ) = ( $dir > 0 ) ? ( $l_dist, $r_dist ) : ( $r_dist, $l_dist );
            my $seq = DNA_subseq( $qseqR, $beg, $end );
            push @out, { location   => $loc,
                         definition => ( $max_split ? munge_assignment( $descr, $max_split, $_->[4], $from_end5, $_->[5], $from_end3 )
                                                    : $descr
                                       ),
                         sequence   => $seq,
                         uncover5   => $_->[4],
                         uncover3   => $_->[5],
                         from_end5  => $from_end5,
                         from_end3  => $from_end3,
                         ( $ftr_type ? ( type => $ftr_type ) : () )      
                       };
        }
    }

    close( $blastFH );
    system( '/bin/rm', '-r', $tmp_dir ) if ! $save_tmp;

    wantarray ? @out : \@out;
}


sub munge_assignment
{
    my ( $assign,
         $max_split,
         $unmatched_5_ref,
         $unmatched_5_contig,
         $unmatched_3_ref,
         $unmatched_3_contig )  = @_;

    my $extra = "";
    if ( $unmatched_5_ref > 0 ) { $extra .= ( $unmatched_5_contig <= $max_split ) ? " - 5 prime truncation" : " - 5 prime missing fragment" }
    if ( $unmatched_3_ref > 0 ) { $extra .= ( $unmatched_3_contig <= $max_split ) ? " - 3 prime truncation" : " - 3 prime missing fragment" }
    if ( $extra )
    {
        $assign .= ( $assign =~ / \#\#? / ) ? $extra : " #$extra";
        $assign =~ s/ \#\# / \# /;
        $assign =~ s/\# - /\# /;
    }

    $assign;
}


sub format_match_location
{
    my ( $contig, $beg, $end, $dir, $len, $format ) = @_;

    $format ||= 'seed';
    $dir = $dir =~ /^-/ ? '-' : '+';
    return ( $format =~ m/sap/i )  ? "${contig}_$beg$dir$len"          :
           ( $format =~ m/cbdl/i ) ? [ [ $contig, $beg, $dir, $len ] ] :
                                     "${contig}_${beg}_$end" 
}


#  Produce the next fasta sequence from an array or a file:

sub next_contig
{
    my ( $contigs, $n ) = @_;
    return $contigs->[ $n || 0 ] if ref $contigs eq 'ARRAY';
    gjoseqlib::read_next_fasta_seq( $contigs );
}


#===============================================================================
#  Merge the hsps for a single reference sequence.  The goal is to cover as
#  much of the reference as possible.
#
#     \@match_regions = merge_hsps( $qlen, $slen, $s_matches, $options )
#
#  Match regions are in contig orientation, not query orientation:
#
#     $match_region = [ $q1, $q2, $dir, $mid, $uncov5, $uncov3 ]
#
#  Hsps are:
#
#                 0    1    2    3     4     5    6     7     8   9   10   11   12  13   14
#  $hsp_data = [ scr, exp, p_n, pval, nmat, nid, nsim, ngap, dir, q1, q2, qseq, s1, s2, sseq ]
#
#  2013-09-23 -- future work
#
#  Merging should also have a test on reuse of previously used parts of the
#  reference sequence. Otherwise tandem duplications can be joined. -- GJO
#===============================================================================
sub merge_hsps
{
    my ( $qlen, $slen, $s_matches, $options ) = @_;
    my $min_cover = $options->{ coverage };  # Minimum fraction of reference covered
    my $min_gain  = $options->{ mingain } || 10; # Minimum added ref coverage for merge
    my $max_exp   = $options->{ expect };    # Maximum e-value for blast
    my $extrapol  = $options->{ extrapol };  # Amount to extrapolate ends of subject seq
    my $min_ident = $options->{ identity };  # Minimum fraction sequence identity
    my $max_gap   = $options->{ maxgap };    # Maximum gap in genome match
    my $seed_exp  = $options->{ seedexp };   # Maximum e-value to nucleate match
    my $verbose   = $options->{ verbose };

    my $max_dissim  = 1 - $min_ident;
    my $max_uncover = $min_cover ? $slen * ( 1 - $min_cover ) : $slen;


    my @by_score = sort { $b->[0] <=> $a->[0] }
                   grep { $_->[1] <=  $max_exp
                       && gjoseqlib::fraction_nt_diff( @$_[11,14] ) <= $max_dissim
                        }
                   @$s_matches;
    foreach ( @by_score )
    {
        push @$_, $_->[ 9]  +  $_->[10];  # $_->[15] = 2 * query midpoint
        $_->[8] = $_->[13] <=> $_->[12];  # direction
    }

    my @by_pos = sort { $a->[15] <=> $b->[15] } @by_score;
    my $i = 0;
    my %pos_dex = map { $_ => $i++ } @by_pos;

    my @found;  #  [ $q1, $q2, $s1, $s2, $dir, \@hsps ]
    my %done;
    foreach my $hsp ( @by_score )
    {
        next if $done{ $hsp } || ( $hsp->[1] > $seed_exp );
        $done{ $hsp } = 1;
        my @hsps = ( $hsp );
        my ( $dir, $q1, $q2, $s1, $s2 )= @$hsp[ 8, 9, 10, 12, 13 ];
        my $dex = $pos_dex{ $hsp };

        # extend left on query (maybe):

        my $min_dex = $dex;   #  Smallest index used
        my $skip_scr = 0;     #  Biggest score skipped
        my $d = $dex;         #  Current try
        while ( $d > 0 )
        {
            last if $dir > 0 ? $s1 <= $min_gain       #  Not enough unused ref
                             : $s1 + $min_gain > $slen;
            my $try = $by_pos[ $d - 1 ];
            last if $done{ $try };                    #  Used
            last if ( $q1 - $try->[10] > $max_gap );  #  Too far
            $d--;                                     #  Move current try
            #  Can extend if moves to left in both subject and query
            if ( $try->[8] == $dir                     # Same strand
              && $try->[9] <= $q1                      # Move to left in query
              && ( $dir > 0 ? $try->[12] <= $s1 - $min_gain
                            : $try->[12] >= $s1 + $min_gain
                 )                                     # Move far enough to left in ref
               )
            {
                #  But do not do it if score added is less than score "skipped"
                if ( $try->[0] >= $skip_scr )
                {
                    print STDERR Dumper( 'Extending to left', $hsp, $try ) if $debug;
                    $q1 = $try->[ 9];
                    # $q2 = $try->[10] if $try->[10] > $q2;
                    $s1 = $try->[12];
                    # $s2 = $try->[13] if ( $s1 <=> $s2 ) == ( $s2 <=> $try->[13] );
                    push @hsps, $try;
                    while ( $min_dex > $d ) { $done{ $by_pos[ --$min_dex ] } = 1 }
                    $skip_scr = 0;
                }
            }
            else
            {
                $skip_scr = $try->[0] if $try->[0] > $skip_scr;
            }
        }

        # extend right on query (maybe):

        my $max_dex = $dex;   #  Largest index used
        $skip_scr = 0;        #  Biggest score skipped
        $d = $dex;            #  Current try
        while ( $d < @by_pos - 1 )
        {
            last if $dir < 0 ? $s2 <= $min_gain       #  Not enough unused ref
                             : $s2 + $min_gain > $slen;
            my $try = $by_pos[ $d + 1 ];
            last if $done{ $try };                    #  Used
            last if ( $try->[9] - $q2 > $max_gap );   #  Too far
            $d++;                                     #  Move current try
            #  Can extend if moves to right in both subject and query
            if ( $try->[ 8] == $dir                   #  Same strand
              && $try->[10] >  $q2                    #  Move to right in query
              && ( $dir > 0 ? $try->[13] >= $s2 + $min_gain
                            : $try->[13] <= $s2 - $min_gain
                 )                                     # Move far enough to right in ref
               )
            {
                #  But do not do it if score added is less than score "skipped"
                if ( $try->[0] >= $skip_scr )
                {
                    print STDERR Dumper( 'Extending to right', $hsp, $try ) if $debug;
                    # $q1 = $try->[ 9] if $try->[9] < $q1;
                    $q2 = $try->[10];
                   #  $s1 = $try->[12] if ( $s1 <=> $s2 ) == ( $try->[12] <=> $s1 );
                    $s2 = $try->[13];
                    push @hsps, $try;
                    while ( $max_dex < $d ) { $done{ $by_pos[ ++$max_dex ] } = 1 }
                    $skip_scr = 0;
                }
            }
            else
            {
                $skip_scr = $try->[0] if $try->[0] > $skip_scr;
            }
        }

        #  Amount of uncovered reference sequence:

        my $d_s5 = ( ( $dir > 0 ) ? $s1 : $s2 ) - 1;
        my $d_s3 = $slen - ( ( $dir > 0 ) ? $s2 : $s1 );

        #  Extrapolate ends in query to ends of reference?

        if ( $extrapol )
        {
            #  Map desired adjust to proper ends of query sequence:

            my ( $d_q1, $d_q2 ) = ( $dir > 0 ) ? ( $d_s5, $d_s3 ) : ( $d_s3, $d_s5 );

            #  Limit by ends of query sequence and adjust if small enough:

            $d_q1 = $q1 - 1 if $q1 - $d_q1 < 1;
            if ( $d_q1 <= $extrapol )
            {
                $q1 -= $d_q1;
                if ( $dir > 0 ) { $d_s5 -= $d_q1 } else { $d_s3 -= $d_q1 }
            }

            $d_q2 = $qlen - $q2 if $q2 + $d_q2 > $qlen;
            if ( $d_q2 <= $extrapol )
            {
                $q2 += $d_q2;
                if ( $dir > 0 ) { $d_s3 -= $d_q2 } else { $d_s5 -= $d_q2 }
            }
        }

        #  Impose the reference coverage test:

        next if ( $d_s5 + $d_s3 ) > $max_uncover;

        push @found, [ $q1, $q2, $dir, $q1+$q2, $d_s5, $d_s3 ];
    }

    @found;
}


#===============================================================================
#  Combine regions identified by different reference sequences:
#
#     @merged_matches = merge_contig_matches( \@match_regions )
#
#     $match_region = [ $l, $r, $dir, $mid, $uncov5, $uncov3 ]
#===============================================================================
sub merge_contig_matches
{
    ref $_[0] eq 'ARRAY' and @{$_[0]} or return ();

    my @regions = sort { $a->[2] <=> $b->[2] || $a->[3] <=> $b->[3] } @{$_[0]};
    my @keep  = ();
    
    #   left, right, dir, mid, uncov5, uncov3
    my ( $l1, $r1, $d1, $m1, $ub1, $ue1 ) = @{ shift @regions };
    foreach my $match ( @regions )
    {
        my ( $l2, $r2, $d2, $m2, $ub2, $ue2 ) = @$match;
        my $overlap = min( $r1, $r2 ) - max( $l1, $l2 ) + 1;
        my $length  = min( $r1 - $l1 + 1, $r2 - $l2 + 1 );
        if ( ( $d2 == $d1 )  && ( $overlap >= 0.5 * $length ) )
        {
            if ( $l2 < $l1 )  # Leftmost match
            {
                $l1 = $l2;
                if ( $d1 > 0 ) { $ub1 = $ub2 } else { $ue1 = $ue2 }
            }
            if ( $r2 > $r1 )  # Rightmost match
            {
                $r1 = $r2;
                if ( $d1 > 0 ) { $ue1 = $ue2 } else { $ub1 = $ub2 }
            }
            $m1 = $l1 + $r1;
        }
        else
        {
            push @keep, [ $l1, $r1, $d1, $m1, $ub1, $ue1 ];
            ( $l1, $r1, $d1, $m1, $ub1, $ue1 ) = @$match;
        }
    }
    push @keep, [ $l1, $r1, $d1, $m1, $ub1, $ue1 ];

    # This is where we could check things (like coverage):

    @keep
}


sub min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max { $_[0] > $_[1] ? $_[0] : $_[1] }


#-------------------------------------------------------------------------------
#  Utility functions:
#-------------------------------------------------------------------------------
#  Allow variations of option keys including uppercase, underscores and
#  terminal 's':
#
#      $key = canonical_key( $key );
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub canonical_key
{
    my $key = lc shift;
    $key =~ s/_//g;
    $key =~ s/s$//;  #  This is dangerous if an s is part of a word!
    return $key;
}


1;
