package bidir_best_hits;

# This is a SAS component.

#
#  Find bidirectional best hit pairs between two sequences sets
#  (not tested for DNA yet).
#
#  ( \@bbh, \@log1, \@log2 ) = bbh( \@seq1, \@seq2, \%options );
#  ( \@bbh, \@log1, \@log2 ) = bbh( \@seq1, $file2, \%options );
#  ( \@bbh, \@log1, \@log2 ) = bbh( $file1, \@seq2, \%options );
#  ( \@bbh, \@log1, \@log2 ) = bbh( $file1, $file2, \%options );
#
#  Options:
#
#    blast_opts    => string     # Blast options
#    max_e_value   => float      # D = 1e-5;
#    min_coverage  => frac_cover # D = 0.30;
#    min_identity  => frac_id    # D = 0.10;
#    min_positives => frac_pos   # D = 0.20;
#    program       => program    # D = blastp
#    subset        => \@ids      # restrict to a subset of the @seq1 sequences
#    subset1       => \@ids      # restrict to a subset of the @seq1 sequences
#    verbose       => bool       # Display more messages
#
#  Each gene set can be supplied as either a file name, or a reference to an
#  array of sequences.
#
#  Bidirectional best hits:
#
#     [ qid, sid, qlen, slen, score, id_frac, pos_frac, q_cover, s_cover ]
#
#  The logs provide an accounting of the best hit for each gene in the
#  respective sequence set. If there is no hit, then the first form is
#  returned. If there is a hit, then the second form is returned.
#
#     [ qid, qlen, type ]
#     [ qid, qlen, type, sid, slen, fract_id, fract_pos, q_cover, s_cover ]
#
#  type is '<->' for bbh, ' ->' for a oneway best hit, and ' - ' for no hit.
#
#  Beware: when used with 'subset', the log outputs will not include all
#  sequences.
#

use strict;
use gjoseqlib;
use gjoparseblast;
use SeedAware;
eval { require Data::Dumper };

sub bbh
{
    my ( $seq1, $seq2, $options ) = @_;
    $seq1 && $seq2 or return ();
    $options ||= {};

    my $min_cover     = $options->{ min_cover }    || $options->{ min_coverage }  || 0.30;
    my $min_positives = $options->{ min_positive } || $options->{ min_positives } || 0.20;
    my $min_ident     = $options->{ min_ident }    || $options->{ min_identity }  || 0.10;
    my $max_e_val     = $options->{ max_e_val }    || $options->{ max_e_value }   || 1e-5;
    my $program       = $options->{ program }      || 'blastp';
    my $blast_opts    = $options->{ blast_opt }    || $options->{ blast_opts }    || '';
    my $verbose       = $options->{ verbose }      || '';
    my $subset1       = $options->{ subset1 }      || $options->{ subset } || undef;

    my $analysis_options = { e_value => $max_e_val,
                             program => $program,
                             options => $blast_opts
                           };

    $subset1 = undef if !$subset1 || ref( $subset1 ) ne 'ARRAY' || ! @$subset1;

    my $file1 = $seq1;
    my $save1 = 1;
    my $tmp   = SeedAware::location_of_tmp( $options );
    if ( ref( $seq1 ) eq 'ARRAY' )
    {
        @$seq1 or return ([], [], []);
        my $fh1;
        ( $fh1, $file1 ) = SeedAware::open_tmp_file( 'bbh_tmp1', 'faa', $tmp );
        gjoseqlib::write_fasta( $fh1, $seq1 );
        close( $fh1 );
        $save1 = 0;
    }
    elsif ( ! -f $file1 )
    {
        print STDERR "bbh() cannot locate sequence file '$file1'.\n";
        return ([], [], []);
    }
    elsif ( $subset1 )
    {
        $seq1 = gjoseqlib::read_fasta( $file1 );
        @$seq1 or return ([], [], []);
    }

    my $file2 = $seq2;
    my $save2 = 1;
    if ( ref( $seq2 ) eq 'ARRAY' )
    {
        @$seq2 or return ([], [], []);
        my $fh2;
        ( $fh2, $file2 ) = SeedAware::open_tmp_file( 'bbh_tmp2', 'faa', $tmp );
        gjoseqlib::write_fasta( $fh2, $seq2 );
        close( $fh2 );
        $save2 = 0;
    }
    elsif ( ! -f $file2 )
    {
        print STDERR "bbh() cannot locate sequence file '$file2'.\n";
        unlink $file1 if $file1 && ! $save1;
        return ([], [], []);
    }
    elsif ( $subset1 )
    {
        $seq2 = gjoseqlib::read_fasta( $file2 );
        @$seq2 or return ([], [], []);
    }

    # Blast 1 against 2:

    my $file1s;
    if ( $subset1 )
    {
        my %seq1  = map { $_->[0] => $_ } @$seq1;
        my $n_seq1 = @$seq1;
        foreach ( grep { ! $seq1{ $_ } } @$subset1 )
        {
            print STDERR "Warning: bbh subset id '$_' not found.\n";
        }
        my @seq1s = map { $seq1{ $_ } ? $seq1{ $_ } : () } @$subset1;
        @seq1s or die "Requested subset has no valid sequences.\n";
        my $n_seq1s = @seq1s;
        print STDERR "Using $n_seq1s of $n_seq1 sequences in $file1.\n" if $verbose;

        my $fh1s;
        ( $fh1s, $file1s ) = SeedAware::open_tmp_file( 'bbh_tmp1s', 'faa', $tmp );
        gjoseqlib::write_fasta( $fh1s, \@seq1s );
        close( $fh1s );
    }

    print STDERR "Blasting $file1 against $file2 ...\n" if $verbose;
    my $file1_use = $subset1 ? $file1s : $file1;
    my @f1_data = best_merged_blast_hit( $file1_use, $file2, $analysis_options );
    unlink( $file1s ) if $subset1;

    my %f1_data = map { $_->[0] => $_ } @f1_data;  # Results indexed by id

    # Blast 2 against 1:

    my ( @f2_data, %f2_data );
    if ( @f1_data )
    {
        my $file2s;
        if ( $subset1 )
        {
            my %seq2id = map { $_->[3] => 1 } grep { $_->[3] } @f1_data;  # ids to keep
            my @seq2s  = map { $seq2id{ $_->[0] } ? $_ : () } @$seq2;
            my $n_seq2  = @$seq2;
            my $n_seq2s = @seq2s;
            print STDERR "Using $n_seq2s of $n_seq2 sequences in $file2.\n" if $verbose;

            my $fh2s;
            ( $fh2s, $file2s ) = SeedAware::open_tmp_file( 'bbh_tmp2s', 'faa', $tmp );
            gjoseqlib::write_fasta( $fh2s, \@seq2s );
            close( $fh2s );
        }

        print STDERR "Blasting $file2 against $file1 ...\n" if $verbose;
        my $file2_use = $subset1 ? $file2s : $file2;
        @f2_data = best_merged_blast_hit( $file2_use, $file1, $analysis_options );
        unlink( $file2s ) if $subset1;
 
        %f2_data = map { $_->[0] => $_ } @f2_data;  # Results indexed by id

        print STDERR "Done blasting\n" if $verbose;
    }

    my @suf = ( '', qw( .nin .nhr .nsq .pin .phr .psq ) );
    unlink( grep { -f $_ } map { $file1 . $_ } @suf ) if ! $save1;
    unlink( grep { -f $_ } map { $file2 . $_ } @suf ) if ! $save2;

    @f2_data or return ([], [], []);

    #
    # Bidirectional best hits:
    #
    #  [ qid, sid, qlen, slen, score, id_frac, pos_frac, q_cover, s_cover ]
    #
    my ( $qid, $sid );
    my ( $f1_vs_f2, $f2_vs_f1 );
    my ( $fract_id, $fract_pos );
    my ( $q_coverage, $s_coverage );
    my %log;
    my @bbh;

    foreach $qid ( sort keys %f1_data )
    {
        $f1_vs_f2 = $f1_data{$qid};
        $sid = $f1_vs_f2->[3];

        if ( $sid && $f2_data{$sid} && $f2_data{$sid}->[3] && $f2_data{$sid}->[3] eq $qid )
        {
            $f2_vs_f1 = $f2_data{$sid};
            $log{ $qid } = [ $f1_vs_f2, '<->' ];
            $log{ $sid } = [ $f2_vs_f1, '<->' ];

            #  Found BBH, does it pass other tests?

            ( $fract_id, $fract_pos ) = fract_id_and_pos( $f1_vs_f2 );
            next if ( $fract_id < $min_ident ) || ( $fract_pos < $min_positives );
            ( $q_coverage, $s_coverage ) = coverage( $f1_vs_f2 );
            next if ( $q_coverage < $min_cover ) || ( $s_coverage < $min_cover );

            #  Passed.  Record it.

            push @bbh, [ @$f1_vs_f2[ 0, 3, 2, 5, 6 ], $fract_id, $fract_pos, $q_coverage, $s_coverage ];
        }
        else
        {
            $log{ $qid } = [ $f1_vs_f2, ( $sid ? ' ->' : ' - ' ) ];
        }
    }

    foreach $sid ( grep { ! $log{ $_ } } keys %f2_data )
    {
        $f2_vs_f1 = $f2_data{$sid};
        $log{ $sid } = [ $f2_vs_f1, ( ( $f2_vs_f1->[3] ) ? ' ->' : ' - ' ) ];
    }

    my $genome1 = $file1;
    $genome1 =~ s|.*/||;
    my $genome2 = $file2;
    $genome2 =~ s|.*/||;

    my @log1;
    foreach ( map { $_->[0] } @f1_data )
    {
        my ( $data, $type ) = @{$log{$_}};
        my @datum = ( @$data[ 0, 2 ], $type );
        push @datum, ( @$data[ 3, 5 ], fract_id_and_pos( $data ), coverage( $data ) ) if $type =~ /->/;
        push @log1, \@datum;
    }

    my @log2;
    foreach ( map { $_->[0] } @f2_data )
    {
        my ( $data, $type ) = @{$log{$_}};
        my @datum = ( @$data[ 0, 2 ], $type );
        push @datum, ( @$data[ 3, 5 ], fract_id_and_pos( $data ), coverage( $data ) ) if $type =~ /->/;
        push @log2, \@datum;
    }

    return \@bbh, \@log1, \@log2;
}


#-------------------------------------------------------------------------------
#  Calculage the fraction of aligned positions that are identical or similar
#-------------------------------------------------------------------------------
sub fract_id_and_pos
{
    my ( $mat_len, $n_ident, $n_pos ) = @{$_[0]}[ 10, 11, 12 ];
    $mat_len ? ( sprintf( "%.3f", $n_ident/$mat_len ),
                 sprintf( "%.3f", $n_pos/$mat_len   ) )
             : ( '0.000', '0.000' )
}


#-------------------------------------------------------------------------------
#  Calculage the fraction of the query and subject lengths covered by match
#-------------------------------------------------------------------------------
sub coverage
{
    my ( $qlen, $slen, $q1, $q2, $s1, $s2 ) = @{$_[0]}[ 2, 5, 15, 16, 18, 19 ];
    $qlen && $slen ? ( sprintf( "%.3f", abs($q2-$q1)/$qlen ),
                       sprintf( "%.3f", abs($s2-$s1)/$slen ) )
                   : ( '0.000', '0.000' )
}



#-------------------------------------------------------------------------------
#  Find the single best blast match for each query sequence, possibly merging
#  consistent hsps.
#
#   @matches = best_merged_blast_hit( $query_file, $subject_file, \%options )
#   @matches = best_merged_blast_hit( $query_file, $subject_file,  %options )
#  \@matches = best_merged_blast_hit( $query_file, $subject_file, \%options )
#  \@matches = best_merged_blast_hit( $query_file, $subject_file,  %options )
#
#      options:
#      -------------------------------------------
#      e_value => max_e_value         # D = 10e-5
#      program => blast_program       # D = blastp
#      options => blast_command_opts  # D = ''
#      -------------------------------------------
#
#
#  Matches are:
#
#    [ qid, qdef, qlen, sid, sdef, slen,
#      score, e_val, n_seq, p_n,
#      aln_len, aln_id, aln_pos, aln_gap, aln_dir
#      q_start, q_end, q_aln, s_start, s_end, s_aln,
#      [ @hsps ]
#    ]
#-------------------------------------------------------------------------------

sub best_merged_blast_hit
{
    my $file1 = shift;  # queries
    my $file2 = shift;  # database

    my %opts  = $_[0] && ref( $_[0] ) eq 'HASH' ? %{ $_[0] } : @_;
    foreach ( keys %opts )
    {
        $opts{ canonical_key( $_ ) } = $opts{ $_ }
    }

    my $max_e_val     = $opts{ evalue }   || $opts{ maxevalue } || 1e-5;
    my $program       = $opts{ program }  || 'blastp';
    my $blast_options = $opts{ options }  || '';
    my $n_thread      = $opts{ n_thread } || 4;

    if ( $blast_options )
    {
        $blast_options = ' ' . $blast_options;
        $blast_options =~ s/ +-a *(\d+)// and $n_thread = $1;
        $blast_options =~ s/ +-b *[^ ]+//g;     # No changing result count
        $blast_options =~ s/ +-d *[^ ]+//g;     # No changing the database
        $blast_options =~ s/ +-e *[^ ]+//g;     # No separate e-value
        $blast_options =~ s/ +-F *[^ ]*//g;     # No filtering
        $blast_options =~ s/ +-i *[^ ]+//g;     # No changing the input
        $blast_options =~ s/ +-m *[^ ]+//g;     # No reformatting output
        $blast_options =~ s/ +-L *[^ ]+//g;     # No location
        $blast_options =~ s/ +-o *[^ ]+//g;     # No redirecting output
        $blast_options =~ s/ +-O *[^ ]+//g;     # No redirecting output
        $blast_options =~ s/ +-p *[^ ]+//g;     # No changing the program
        $blast_options =~ s/ +-R *[^ ]+//g;     # No PSI blast
        $blast_options =~ s/ +-T *[^ ]+//g;     # No reformatting output
        $blast_options =~ s/ +-v *[^ ]+//g;     # No changing result count
        $blast_options =~ s/^ +//;
    }

    # Check for query sequence file:

    my $blastdb = $ENV{BLASTDB};
    $blastdb = undef if $blastdb && ! -d $blastdb;

    my $file1p;
    if ( -f $file1 )
    {
        $file1p = $file1;
    }
    elsif ( $blastdb && -f "$blastdb/$file1" )
    {
        $file1p = "$blastdb/$file1";
    }
    else
    {
        print STDERR "Unable to find sequence file '$file1'\n";
        return ();
    }

    # Check for blast database:

    my $prot_db = ( $program =~ m/^blast[px]$/i ) ? 'T' : 'F';

    my $suffix = $prot_db eq 'T' ? 'psq' : 'nsq';

    my $formatdb = SeedAware::executable_for( 'formatdb' );
    my $file2p;
    if ( -f "$file2.$suffix" )
    {
        $file2p = $file2;
    }
    elsif ( $blastdb && -f "$blastdb/$file2.$suffix" )
    {
        $file2p = $file2;
    }
    elsif ( -f $file2 )
    {
        $file2p = $file2;
        $formatdb
            or print STDERR "Could not find executable for 'formatdb'.\n"
                and return ();
        system( $formatdb, '-p', $prot_db, '-i', $file2p );
    }
    elsif ( $blastdb && -f "$blastdb/$file2" )
    {
        $file2p = "$blastdb/$file2";
        $formatdb
            or print STDERR "Could not find executable for 'formatdb'.\n"
                and return ();
        system( $formatdb, '-p', $prot_db, '-i', $file2p );
    }
    else
    {
        print STDERR "Unable to find blast database or sequence file '$file2'\n";
        return ();
    }

    my $blastall = SeedAware::executable_for( 'blastall' )
        or print STDERR "Could not find executable for 'blastall'.\n"
            and return ();

    my @blast_opts = $blast_options? split /\s+/, $blast_options : ();
    my @blast_command = ( $blastall,
                          '-p' => $program,
                          '-i' => $file1p,
                          '-d' => $file2,
                          '-e' => $max_e_val,
                          '-b' => 5,
                          '-v' => 5,
                          '-F' => 'f',
                          '-a' => $n_thread,
                          @blast_opts
                        );

    my $redirect = { stderr => '/dev/null' };
    my $blast = SeedAware::read_from_pipe_with_redirect( @blast_command, $redirect );
    if ( ! $blast )
    {
        my $blast_command = join( ' ', @blast_command );
        print STDERR "Could not open blast command:\n$blast_command\n";
        return ();
    }

    #  Blast output one query at a time:
    #
    #     $query_results = next_blast_query( $input, $self )
    #
    #     Output is clustered heirarchically by query, by subject and by hsp.  The
    #     highest level is query records:
    #
    #     [ qid, qdef, qlen, [ [ sid, sdef, slen, [ hsp_data, hsp_data, ... ] ],
    #                          [ sid, sdef, slen, [ hsp_data, hsp_data, ... ] ],
    #                          ...
    #                        ]
    #     ]
    #
    #     hsp_data:
    #
    #     [ scr, exp, p_n, pval, nmat, nid, nsim, ngap, dir, q1, q2, qseq, s1, s2, sseq ]
    #        0    1    2    3     4     5    6     7     8   9   10   11   12  13   14
    #

    # Some variables:

    my ( $qid, $qdef, $qlen, $sid, $sdef, $slen );
    my ( @results, $qdata, $qdatum, $sdata, $sdatum, $hsps, $composite_hsp );

    my @best_matches;
    while( $qdata = next_blast_query( $blast, 1 ) )  # The 1 allows self matches
    {
        ( $qid, $qdef, $qlen, $sdata ) = @$qdata;
        @results = ();
        foreach $sdatum ( @$sdata )
        {
            ( $sid, $sdef, $slen, $hsps ) = @$sdatum;
            push @results, [ $sid, $sdef, $slen, merge_hsps( $hsps, $qlen, $slen ) ];
        }

        ( $composite_hsp ) = sort { $b->[3] <=> $a->[3] } @results;

        push @best_matches, [ $qid, $qdef, $qlen,
                              ( $composite_hsp ? @$composite_hsp : () )
                            ];
    }

    close $blast;

    wantarray ? @best_matches : \@best_matches;
}


#-------------------------------------------------------------------------------
#  Canonical form of key is lower case, with no '_' or terminal 's':
#
#    $key = canonical_key( $key )
#-------------------------------------------------------------------------------

sub canonical_key
{
    my $key = lc shift;
    $key =~ s/_//g;
    $key =~ s/s$//;
    $key
}


#-------------------------------------------------------------------------------
#  Stub function for later merging of hsps.  This just returns the first.
#
#    $hsp = merge_hsps( $hsps, $qlen, $slen )
#    @hsp = merge_hsps( $hsps, $qlen, $slen )
#-------------------------------------------------------------------------------

sub merge_hsps
{
    my ( $hsps, $qlen, $slen ) = @_;

    ( ref( $hsps ) eq 'ARRAY' && ref( $hsps->[0] ) eq 'ARRAY' ) or return ();

    wantarray ? @{ $hsps->[0] } : $hsps->[0];
}


1;
