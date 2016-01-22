# This is a SAS component
#
# Copyright (c) 2003-2015 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

package gjoalignment;

#===============================================================================
#  A package of functions for alignments (to be expanded)
#
#    @align = align_with_clustal(  @seqs )
#    @align = align_with_clustal( \@seqs )
#    @align = align_with_clustal( \@seqs, \%opts )
#   \@align = align_with_clustal(  @seqs )
#   \@align = align_with_clustal( \@seqs )
#   \@align = align_with_clustal( \@seqs, \%opts )
#
#    @align = clustal_profile_alignment( \@seqs,  $seq )
#   \@align = clustal_profile_alignment( \@seqs,  $seq )
#    @align = clustal_profile_alignment( \@seqs, \@seqs )
#   \@align = clustal_profile_alignment( \@seqs, \@seqs )
#
#   \@align                           = align_with_muscle( \@seqs )
#   \@align                           = align_with_muscle( \@seqs, \%opts )
#   \@align                           = align_with_muscle( \%opts )
# ( \@align, $newick-tree-as-string ) = align_with_muscle( \@seqs )
# ( \@align, $newick-tree-as-string ) = align_with_muscle( \@seqs, \%opts )
# ( \@align, $newick-tree-as-string ) = align_with_muscle( \%opts )
#
#   \@align                           = align_with_mafft( \@seqs )
#   \@align                           = align_with_mafft( \@seqs, \%opts )
#   \@align                           = align_with_mafft( \%opts )
# ( \@align, $newick-tree-as-string ) = align_with_mafft( \@seqs )
# ( \@align, $newick-tree-as-string ) = align_with_mafft( \@seqs, \%opts )
# ( \@align, $newick-tree-as-string ) = align_with_mafft( \%opts )
#
#    $tree      = tree_with_clustal( \@alignment );
#
#    @alignment = add_to_alignment(     $seqentry, \@alignment );
#    @alignment = add_to_alignment_v2(  $seqentry, \@alignment, \%options );
#    @alignment = add_to_alignment_v2a( $seqentry, \@alignment, \%options );
#
#  Compare two sequences for fraction identity.
#
#     $fract_id = fraction_identity( $seq1, $seq2, $type );
#     $fract_id = fraction_aa_identity( $seq1, $seq2 );
#     $fract_id = fraction_nt_identity( $seq1, $seq2 );
#
#     $type is 'p' or 'n' (D = p)
#
#  Find the consensus amino acid (or nucleotide) at specified alignment column.
#
#       $residue              = consensus_aa_in_column( \@align, $column )
#     ( $residue, $fraction ) = consensus_aa_in_column( \@align, $column )
#
#       $residue              = consensus_aa_in_column( \@seqR, $column )
#     ( $residue, $fraction ) = consensus_aa_in_column( \@seqR, $column )
#
#       $residue              = consensus_nt_in_column( \@align, $column )
#     ( $residue, $fraction ) = consensus_nt_in_column( \@align, $column )
#
#       $residue              = consensus_nt_in_column( \@seqR, $column )
#     ( $residue, $fraction ) = consensus_nt_in_column( \@seqR, $column )
#
#  The first form of each takes a reference to an array of sequence triples,
#  while the second form takes a reference to an array of references to
#  sequences. Column numbers are 1-based.
#
#  Extract a representative set from an alignment
#
#     @alignment = representative_alignment( \@alignment, \%options );
#    \@alignment = representative_alignment( \@alignment, \%options );
#
#  Remove divergent sequences from an alignment
#
#     @alignment = filter_by_similarity( \@align, $min_sim, @id_def_seq );
#    \@alignment = filter_by_similarity( \@align, $min_sim, @id_def_seq );
#
#     @alignment = filter_by_similarity( \@align, $min_sim, @ids );
#    \@alignment = filter_by_similarity( \@align, $min_sim, @ids );
#
#  Bootstrap sample an alignment:
#
#   \@alignment = bootstrap_sample( \@alignment );
#
#===============================================================================

use strict;
use gjoseqlib;
use SeedAware;
use Carp;                       # Used for diagnostics
eval { require Data::Dumper };  # Not present on all systems

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
        align_with_clustal
        clustal_profile_alignment
        align_with_muscle
        align_with_mafft
        add_to_alignment
        add_to_alignment_v2
        add_to_alignment_v2a
        bootstrap_sample
        );


#===============================================================================
#  Align sequences with muscle and return the alignment, or alignment and tree.
#
#     \@align                           = align_with_mafft( \@seqs )
#     \@align                           = align_with_mafft( \@seqs, \%opts )
#     \@align                           = align_with_mafft( \%opts )
#   ( \@align, $newick-tree-as-string ) = align_with_mafft( \@seqs )
#   ( \@align, $newick-tree-as-string ) = align_with_mafft( \@seqs, \%opts )
#   ( \@align, $newick-tree-as-string ) = align_with_mafft( \%opts )
#
#  If input sequences are not supplied, they must be included as an in or in1
#  option value.
#
#  Options:
#
#     add       =>  $seq      #  Add one sequence to \@ali1 alignment
#     algorithm =>  linsi, einsi, ginsi, nwnsi, nwns, fftnsi, fftns (d)
#                             #  Algorithms in descending order or accuracy
#     in        => \@seqs     #  Input sequences; same as in1, or \@seqs
#     in1       => \@ali1     #  Input sequences; same as in, or \@seqs
#     in2       => \@ali2     #  Align \@seqs with \@ali2; same as profile, or seed
#     profile   => \@ali2     #  Align \@seqs with \@ali2; same as in2, or seed
#     seed      => \@ali2     #  Align \@seqs with \@ali2; same as in2, or profile
#     version   =>  $bool     #  Return the program version number, or undef
#
#  Many of the program flags can be used as keys (without the leading --).
#===============================================================================
sub align_with_mafft
{
    my( $seqs, $opts );
    if ( $_[0] && ref( $_[0] ) eq 'HASH' ) { $opts = shift }
    else                                   { ( $seqs, $opts ) = @_ }

    $opts = {} if ! $opts || ( ref( $opts ) ne 'HASH' );

    my $add      = $opts->{ add }      || undef;
    my $profile  = $opts->{ profile }  || $opts->{ in2 } || $opts->{ seed } || undef;
       $seqs   ||= $opts->{ seqs }     || $opts->{ in }  || $opts->{ in1 };
    my $version  = $opts->{ version }  || 0;

    my $mafft = SeedAware::executable_for( $opts->{ mafft } || $opts->{ program } || 'mafft' )
        or print STDERR "Could not locate executable file for 'mafft'.\n"
            and return undef;

    if ( $version )
    {
        my $tmpdir = SeedAware::location_of_tmp( $opts );
        my $tmpF   = SeedAware::tmp_file_name( "version", '', $tmpdir );

        SeedAware::system_with_redirect( $mafft, "--help", { stderr => $tmpF } );
        open( MAFFT, $tmpF ) or die "Could not open $tmpF";
        my @info = <MAFFT>;
        close( MAFFT );
        unlink( $tmpF );

        $version = $info[2]; # second line of MAFFT usage info
        chomp( $version );
        return $version;
    }

    my %prog_val  = map { $_ => 1 }
                    qw( aamatrix
                        bl
                        ep
                        groupsize
                        jtt
                        lap
                        lep
                        lepx
                        LOP
                        LEXP
                        maxiterate
                        op
                        partsize
                        retree
                        tm
                        thread
                        weighti
                      );

    my %prog_flag = map { $_ => 1 }
                    qw( 6merpair
                        amino
                        anysymbol
                        auto
                        clustalout
                        dpparttree
                        fastapair
                        fastaparttree
                        fft
                        fmodel
                        genafpair
                        globalpair
                        inputorder
                        localpair
                        memsave
                        nofft
                        noscore
                        nuc
                        parttree
                        quiet
                        reorder
                        treeout
                      );

    my $degap = ! ( $add || $profile );
    my $tree  = ! ( $add || $profile );

    my $tmpdir = SeedAware::location_of_tmp( $opts );
    my $tmpin  = SeedAware::tmp_file_name( "seqs",  'fasta', $tmpdir );
    my $tmpin2 = SeedAware::tmp_file_name( "seqs2", 'fasta', $tmpdir );
    my $tmpout = SeedAware::tmp_file_name( "ali",   'fasta', $tmpdir );

    if ( ! ( $seqs && ref($seqs) eq 'ARRAY' && @$seqs && ref($seqs->[0]) eq 'ARRAY' ) )
    {
        print STDERR "gjoalignment::align_with_mafft() called without sequences\n";
        return undef;
    }

    my ( $id, $seq, %comment );
    my @clnseq = map { ( $id, $seq ) = @$_[0,2];
                       $comment{ $id } = $_->[1] || '';
                       $seq =~ tr/A-Za-z//cd if $degap;  # degap
                       [ $id, '', $seq ]
                     }
                 @$seqs;
    gjoseqlib::write_fasta( $tmpin, \@clnseq );

    #  Adding one sequence is a special case of profile alignment

    if ( $add ) { $profile = [ $add ]; $degap = 1 }

    if ( $profile )
    {
        if ( ! ( ref($profile) eq 'ARRAY' && @$profile && ref($profile->[0]) eq 'ARRAY' ) )
        {
            print STDERR "gjoalignment::align_with_mafft() requested to do profile alignment without sequences\n";
            return undef;
        }

        my @clnseq2 = map { ( $id, $seq ) = @$_[0,2];
                            $comment{ $id } = $_->[1] || '';
                            $seq =~ tr/A-Za-z//cd if $degap;  # degap
                            [ $id, '', $seq ]
                          }
                      @$profile;

        gjoseqlib::write_fasta( $tmpin2, \@clnseq );
    }

    my @params = $profile ? ( '--seed', $tmpin, '--seed', $tmpin2, '/dev/null')
               :            ( '--treeout',                         $tmpin,    );

    my $algorithm = lc( $opts->{ algorithm } || $opts->{ alg } );
    if ( $algorithm )
    {
        delete $opts->{ $_ } for qw( localpair genafpair globalpair nofft fft retree maxiterate );

        if    ( $algorithm eq 'linsi' || $algorithm eq 'l' ) { $opts->{ localpair }  = 1; $opts->{ maxiterate } = 1000 }
        elsif ( $algorithm eq 'einsi' || $algorithm eq 'e' ) { $opts->{ genafpair }  = 1; $opts->{ maxiterate } = 1000 }
        elsif ( $algorithm eq 'ginsi' || $algorithm eq 'g' ) { $opts->{ globalpair } = 1; $opts->{ maxiterate } = 1000 }
        elsif ( $algorithm eq 'nwnsi'  )                     { $opts->{ retree }     = 2; $opts->{ maxiterate } = 2;   $opts->{ nofft } = 1 }
        elsif ( $algorithm eq 'nwns'   )                     { $opts->{ retree }     = 2; $opts->{ maxiterate } = 0;   $opts->{ nofft } = 1 }
        elsif ( $algorithm eq 'fftnsi' )                     { $opts->{ retree }     = 2; $opts->{ maxiterate } = 2;   $opts->{ fft }   = 1 }
        elsif ( $algorithm eq 'fftns'  )                     { $opts->{ retree }     = 2; $opts->{ maxiterate } = 0;   $opts->{ fft }   = 1 }
    }

    foreach ( keys %$opts )
    {
        @params = ("--$_", @params)               if $prog_flag{ $_ };
        @params = ("--$_", $opts->{$_}, @params)  if $prog_val{ $_ };
    }

    my $redirects = { stdout => $tmpout, stderr => '/dev/null' };
    SeedAware::system_with_redirect( $mafft, @params, $redirects );
    
    my @ali = &gjoseqlib::read_fasta( $tmpout );
    foreach $_ ( @ali ) { $_->[1] = $comment{$_->[0]} }

    my $treestr;
    my $treeF  = "$tmpin.tree";
    if ( $tree && open( TREE, "<$treeF" ) ) { $treestr = join( "", <TREE> ); close( TREE ) }
    if ( $opts->{ treeout } ) { SeedAware::system_with_redirect( "cp", $treeF, $opts->{ treeout } ) }

    unlink( $tmpin, $tmpout,
            ( $profile ? $tmpin2 : () ),
            ( $tree    ? $treeF  : () )
          );

    return wantarray ? ( \@ali, $treestr ) : \@ali;
}

#===============================================================================
#  Align sequences with muscle and return the alignment, or alignment and tree.
#
#     \@align                           = align_with_muscle( \@seqs )
#     \@align                           = align_with_muscle( \@seqs, \%opts )
#     \@align                           = align_with_muscle( \%opts )
#   ( \@align, $newick-tree-as-string ) = align_with_muscle( \@seqs )
#   ( \@align, $newick-tree-as-string ) = align_with_muscle( \@seqs, \%opts )
#   ( \@align, $newick-tree-as-string ) = align_with_muscle( \%opts )
#
#  If input sequences are not supplied, they must be included as an in or in1
#  option value.
#
#  Options:
#
#     add      =>  $seq      #  Add one sequence to \@ali1 alignment
#     in       => \@seqs     #  Input sequences; same as in1, or \@seqs
#     in1      => \@ali1     #  Input sequences; same as in, or \@seqs
#     in2      => \@ali2     #  Align \@seqs with \@ali2; same as profile
#     profile  => \@ali2     #  Align \@seqs with \@ali2; same as in2
#     refine   =>  $bool     #  Do not start from scratch
#     version  =>  $bool     #  Return the program version number, or undef
#
#  Many of the program flags can be used as keys (without the leading -).
#===============================================================================
sub align_with_muscle
{
    my( $seqs, $opts );
    if ( $_[0] && ref( $_[0] ) eq 'HASH' ) { $opts = shift }
    else                                   { ( $seqs, $opts ) = @_ }

    $opts = {} if ! $opts || ( ref( $opts ) ne 'HASH' );

    my $add      = $opts->{ add }      || undef;
    my $profile  = $opts->{ profile }  || $opts->{ in2 } || undef;
    my $refine   = $opts->{ refine }   || 0;
       $seqs   ||= $opts->{ seqs }     || $opts->{ in } || $opts->{ in1 };
    my $version  = $opts->{ version }  || 0;

    my $muscle = SeedAware::executable_for( $opts->{ muscle } || $opts->{ program } || 'muscle' )
        or print STDERR "Could not locate executable file for 'muscle'.\n"
            and return undef;

    if ( $version )
    {
        $version = SeedAware::run_gathering_output($muscle, "-version");
        chomp $version;
        return $version;
    }

    my %prog_val  = map { $_ => 1 }
                    qw( anchorspacing
                        center
                        cluster1
                        cluster2
                        diagbreak
                        diaglength
                        diagmargin
                        distance1
                        distance2
                        gapopen
                        log
                        loga
                        matrix
                        maxhours
                        maxiters
                        maxmb
                        maxtrees
                        minbestcolscore
                        minsmoothscore
                        objscore
                        refinewindow
                        root1
                        root2
                        scorefile
                        seqtype
                        smoothscorecell
                        smoothwindow
                        spscore
                        SUEFF
                        usetree
                        weight1
                        weight2
                      );

    my %prog_flag = map { $_ => 1 }
                    qw( anchors
                        brenner
                        cluster
                        dimer
                        diags
                        diags1
                        diags2
                        le
                        noanchors
                        quiet
                        sp
                        spn
                        stable
                        sv
                        verbose
                      );

    my $degap = ! ( $add || $profile || $refine );
    my $tree  = ! ( $add || $profile || $refine );

    my $tmpdir = SeedAware::location_of_tmp( $opts );
    my $tmpin  = SeedAware::tmp_file_name( "seqs",  'fasta',  $tmpdir );
    my $tmpin2 = SeedAware::tmp_file_name( "seqs2", 'fasta',  $tmpdir );
    my $tmpout = SeedAware::tmp_file_name( "ali",   'fasta',  $tmpdir );
    my $treeF  = SeedAware::tmp_file_name( "ali",   'newick', $tmpdir );

    if ( ! ( $seqs && ref($seqs) eq 'ARRAY' && @$seqs && ref($seqs->[0]) eq 'ARRAY' ) )
    {
        print STDERR "gjoalignment::align_with_muscle() called without sequences\n";
        return undef;
    }

    my ( $id, $seq, %comment );
    my @clnseq = map { ( $id, $seq ) = @$_[0,2];
                       $comment{ $id } = $_->[1] || '';
                       $seq =~ tr/A-Za-z//cd if $degap;  # degap
                       [ $id, '', $seq ]
                     }
                 @$seqs;
    gjoseqlib::write_fasta( $tmpin, \@clnseq );

    #  Adding one sequence is a special case of profile alignment

    if ( $add ) { $profile = [ $add ]; $degap = 1 }

    if ( $profile )
    {
        if ( ! ( ref($profile) eq 'ARRAY' && @$profile && ref($profile->[0]) eq 'ARRAY' ) )
        {
            print STDERR "gjoalignment::align_with_muscle() requested to do profile alignment without sequences\n";
            return undef;
        }

        my @clnseq2 = map { ( $id, $seq ) = @$_[0,2];
                            $comment{ $id } = $_->[1] || '';
                            $seq =~ tr/A-Za-z//cd if $degap;  # degap
                            [ $id, '', $seq ]
                          }
                      @$profile;

        gjoseqlib::write_fasta( $tmpin2, \@clnseq );  # The zero is "do not compress"
    }

    my @params = $profile ? ( '-in1', $tmpin, '-in2', $tmpin2, '-out', $tmpout, '-profile' )
               : $refine  ? ( '-in1', $tmpin,                  '-out', $tmpout, '-refine' )
               :            ( '-in',  $tmpin,                  '-out', $tmpout, '-tree2', $treeF );

    foreach ( keys %$opts )
    {
        push @params, "-$_"               if $prog_flag{ $_ };
        push @params, "-$_", $opts->{$_}  if $prog_val{ $_ };
    }

    my $redirects = { stdout => '/dev/null', stderr => '/dev/null' };
    SeedAware::system_with_redirect( $muscle, @params, $redirects );

    my @ali = &gjoseqlib::read_fasta( $tmpout );
    foreach $_ ( @ali ) { $_->[1] = $comment{$_->[0]} }

    my $treestr;
    if ( $tree && open( TREE, "<$treeF" ) ) { $treestr = join( "", <TREE> ); close( TREE ) }

    unlink( $tmpin, $tmpout,
            ( $profile ? $tmpin2 : () ),
            ( $tree    ? $treeF  : () )
          );

    return wantarray ? ( \@ali, $treestr ) : \@ali;
}


#===============================================================================
#  Align sequence with clustalw and return the alignment
#
#    @align = align_with_clustal(  @sequences )
#    @align = align_with_clustal( \@sequences )
#    @align = align_with_clustal( \@sequences, \%opts )
#   \@align = align_with_clustal(  @sequences )
#   \@align = align_with_clustal( \@sequences )
#   \@align = align_with_clustal( \@sequences, \%opts )
#
#===============================================================================
sub align_with_clustal
{
    return wantarray ? [] : () if ! @_;        #  No input
    return wantarray ? [] : () if ref( $_[0] ) ne 'ARRAY';   #  Bad sequence entry

    my @seqs = ref( $_[0]->[0] ) eq 'ARRAY' ? @{ $_[0] } : @_;
    my $opts = ( $_[1] && ( ref( $_[1] eq 'HASH' ) ) ) ? $_[1] : {};

    return wantarray ? @seqs : \@seqs  if @seqs < 2;  # Just 1 sequence

    #  Remap the id to be clustal friendly, saving the originals in a hash:

    my ( $id, $def, $seq, $seq2, $id2, %desc, %seq, @seqs2 );

    #  CLUSTAL does not like long names, some characters in names, and
    #  odd symbols like * in sequences.

    $id2 = "seq000000";
    @seqs2 = map { $id  = $_->[0];
                   $def = ( ( @$_ == 3 ) && $_->[1] ) ? $_->[1] : '';
                   $desc{ ++$id2 } = [ $id, $def ];
                   $seq{ $id2 } = \$_->[-1];  #  Reference to original
                   $seq2 = $_->[-1];
                   $seq2 =~ s/\*/X/g;
                   $seq2 =~ tr/A-Za-z//cd;    #  Remove gaps
                   [ $id2, '', $seq2 ]        #  Sequences for clustal
                 } @seqs;

    #  Do the alignment:

    my $tmpdir  = SeedAware::location_of_tmp( $opts );
    my $seqfile = SeedAware::tmp_file_name( "align_fasta",  'fasta', $tmpdir );
    my $outfile = SeedAware::tmp_file_name( "align_fasta",  'aln',   $tmpdir );
    my $dndfile = SeedAware::tmp_file_name( "align_fasta",  'dnd',   $tmpdir );

    gjoseqlib::write_fasta( $seqfile, \@seqs2 );

    my $clustalw = SeedAware::executable_for( $opts->{ clustalw } || $opts->{ program } || 'clustalw' )
        or print STDERR "Could not locate executable file for 'clustalw'.\n"
            and return undef;

    my @params = ( "-infile=$seqfile",
                   "-outfile=$outfile",
                   "-newtree=$dndfile",
                   '-outorder=aligned',
                   '-maxdiv=0',
                   '-align'
                 );
    my $redirects = { stdout => '/dev/null' };
    SeedAware::system_with_redirect( $clustalw, @params, $redirects );

    my @aligned = gjoseqlib::read_clustal_file( $outfile );
    unlink( $seqfile, $outfile, $dndfile );

    #  Restore the id and definition, and restore original characters to sequence:

    my @aligned2 = map { $id2 = $_->[0];
                         [ @{ $desc{$id2} }, fix_sequence( ${$seq{$id2}}, $_->[2] ) ]
                       }
                   @aligned;

    wantarray ? @aligned2 : \@aligned2;
}


#  Expand seq1 to match seq2:

sub fix_sequence
{
    my ( $seq1, $seq2 ) = @_;
    return $seq2 if $seq1 eq $seq2;
    my $seq2a = $seq2;
    $seq2a =~ s/-+//g;
    return $seq2 if $seq1 eq $seq2a;  # Same but for gaps in $seq2;

    #  Build the string character by character

    my $i = 0;
    $seq1 =~ s/-+//g;   # The following requires $seq1 to be gapfree
    join '', map { $_ eq '-' ? '-' : substr( $seq1, $i++, 1 ) } split //, $seq2;
}

#===============================================================================
#  Insert a new sequence into an alignment without altering the relative
#  alignment of the existing sequences.  The alignment is based on a profile
#  of those sequences that are not significantly less similar than the most
#  similar sequence.
#===============================================================================

sub add_to_alignment
{
    my ( $seq, $ali, $trim, $silent ) = @_;

    my $std_dev = 1.5;  #  The definition of "not significantly less similar"

    #  Don't add a sequence with a duplicate id.  This used to be fatal.

    my $id = $seq->[0];
    foreach ( @$ali )
    {
        next if $_->[0] ne $id;
        if (! $silent)
        {
            print STDERR "Warning: add_to_alignment not adding sequence with duplicate id:\n$id\n";
        }
        return wantarray ? @$ali : $ali;
    }

    #  Put sequences in a clean canonical form:

    my $type = gjoseqlib::guess_seq_type( $seq->[2] );
    my $clnseq = [ "seq000000", '', clean_for_clustal( $seq->[2], $type ) ];
    $clnseq->[2] =~ s/[^A-Z]//g;   # remove gaps
    my @clnali = map { [ $_->[0], '', clean_for_clustal( $_->[2], $type ) ] } @$ali;

    my( $trimmed_start, $trimmed_len );
    if ( $trim )    #### if we are trimming sequences before inserting into the alignment
    {
        ( $clnseq, $trimmed_start, $trimmed_len ) = &trim_with_blastall( $clnseq, \@clnali );
        if (! defined( $clnseq ) )
        {
            print STDERR "Warning: attempting to add a sequence with no recognizable similarity: $id\n";
            return $ali;
        }
    }

    #  Tag alignment sequences with similarity to new sequence and sort:

    my @evaluated = sort { $b->[0] <=> $a->[0] }
                    map  { [ fract_identity( $_, $clnseq ), $_ ] }
                    @clnali;

    #  Compute identity threshold from the highest similarity:

    my $threshold = identity_threshold( $evaluated[0]->[0],
                                        length( $evaluated[0]->[1]->[2] ),
                                        $std_dev
                                      );
    my $top_hit = $evaluated[0]->[1]->[0];

    #  Filter sequences for those that pass similarity threshold.
    #  Give them clustal-friendly names.

    my $s;
    $id = "seq000001";
    my @relevant = map  { [ $id++, "", $_->[1]->[2] ] }
                   grep { ( $_->[0] >= $threshold ) }
                   @evaluated;

    #  Do the profile alignment:

    my $tmpdir  = SeedAware::location_of_tmp( );
    my $profile = SeedAware::tmp_file_name( "add_to_align_1", 'fasta', $tmpdir );
    my $seqfile = SeedAware::tmp_file_name( "add_to_align_2", 'fasta', $tmpdir );
    my $outfile = SeedAware::tmp_file_name( "add_to_align",   'aln',   $tmpdir );
    ( my $dndfile = $profile ) =~ s/fasta$/dnd/;  # The program ignores our name

    gjoseqlib::write_fasta( $profile, \@relevant );
    gjoseqlib::write_fasta( $seqfile, [ $clnseq ] );
    #
    #  I would have thought that the profile tree file should be -newtree1, but
    #  that fails.  -newtree works fine at putting the file where we want it.
    #  Perhaps it would have made more sense to do a cd to the desired directory
    #  first.
    #
    my $clustalw = SeedAware::executable_for( 'clustalw' )
        or print STDERR "Could not locate executable file for 'clustalw'.\n"
            and return undef;

    my @params = ( "-profile1=$profile",
                   "-profile2=$seqfile",
                   "-outfile=$outfile",
                   "-newtree=$dndfile",
                   '-outorder=input',
                   '-maxdiv=0',
                   '-profile'
                 );
    my $redirects = { stdout => '/dev/null' };
    SeedAware::system_with_redirect( $clustalw, @params, $redirects );

    my @relevant_aligned = map { $_->[2] } gjoseqlib::read_clustal_file( $outfile );

    unlink( $profile, $seqfile, $outfile, $dndfile );

    my $ali_seq = pop @relevant_aligned;

    #  Figure out where the gaps were added to the existing alignment:

    my ( $i, $j, $c );
    my $jmax = length( $relevant_aligned[0] ) - 1;
    my @rel_seqs = map { $_->[2] } @relevant; # Save a level of referencing;
    my @to_add = ();

    for ( $i = $j = 0; $j <= $jmax; $j++ ) {
        $c = same_col( \@rel_seqs, $i, \@relevant_aligned, $j ) ? "x" : "-";
        push @to_add, $c;
        if ( $c ne "-" ) { $i++ }
    }
    my $mask = join( '', @to_add );

    #  Time to expand the sequences; we will respect case and non-standard
    #  gap characters.  We will add new sequence immediately following the
    #  top_hit.

    my $def;
    my @new_align = ();

    foreach my $entry ( @$ali )
    {
        ( $id, $def, $s ) = @$entry;
        push @new_align, [ $id, $def, gjoseqlib::expand_sequence_by_mask( $s, $mask ) ];
        if ( $id eq $top_hit )
        {
            my( $new_id, $new_def, $new_s ) = @$seq;
            if ( $trim ) { $new_s = substr( $new_s, $trimmed_start, $trimmed_len ) }
            #  Add gap characters to new sequence:
            my $new_mask = gjoseqlib::alignment_gap_mask( $ali_seq );
            push @new_align, [ $new_id, $new_def, gjoseqlib::expand_sequence_by_mask( $new_s, $new_mask ) ];
        }
    }

    @new_align = &final_trim( $seq->[0], \@new_align ) if $trim;

    wantarray ? @new_align : \@new_align;
}


#===============================================================================
#  Insert a new sequence into an alignment without altering the relative
#  alignment of the existing sequences.  The alignment is based on a profile
#  of those sequences that are not significantly less similar than the most
#  similar sequence.  This differs from v2a in that it removes the shared gap
#  columns in the subset of sequences before doing the profile alignment.
#
#    \@align = add_to_alignment_v2( $seq, \@ali, \%options )
#
#  Options:
#
#     trim    => bool     # trim sequence start and end
#     silent  => bool     # no information messages
#     stddev  => float    # window of similarity to include in profile (D = 1.5)
#     verbose => bool     # add information messages
#
#===============================================================================

sub add_to_alignment_v2
{
    my ( $seq, $ali, $options ) = @_;

    $options = {} if ! $options || ( ref( $options ) ne 'HASH' );

    my $silent  = ! $options->{ verbose }
               && ( defined $options->{ silent } ? $options->{ silent } : 1 );
    my $std_dev = $options->{ stddev } || 1.5;  #  The definition of "not significantly less similar"
    my $trim    = $options->{ trim }   || 0;

    #  Don't add a sequence with a duplicate id.

    my $id = $seq->[0];
    foreach ( @$ali )
    {
        next if $_->[0] ne $id;
        print STDERR "Warning: add_to_alignment_v2 not adding sequence with duplicate id:\n$id\n" if ! $silent;
        return wantarray ? @$ali : $ali;
    }

    #  Put sequences in a clean canonical form and give them clustal-friendly
    #  names (first sequence through the map {} is the sequence to be added):

    my %id_map;
    $id = "seq000000";
    ( $seq ) = gjoseqlib::pack_sequences( $seq );
    my $type = gjoseqlib::guess_seq_type( $seq->[2] );
    my ( $clnseq, @clnali ) = map { $id_map{ $_->[0] } = $id;
                                    [ $id++, "", clean_for_clustal( $_->[2], $type ) ]
                                  }
                              ( $seq, @$ali );
    my %clnali = map { $_->[0] => $_ } @clnali;

    if ( $trim )    #### if we are trimming sequences before inserting into the alignment
    {
        my( $trimmed_start, $trimmed_len );
        ( $clnseq, $trimmed_start, $trimmed_len ) = trim_with_blastall( $clnseq, \@clnali, $type );
        if ( ! defined( $clnseq ) )
        {
            print STDERR "Warning: attempted to add a sequence with no recognizable similarity: $id\n";
            return $ali;
        }
        $seq->[2] = substr( $seq->[2], $trimmed_start, $trimmed_len );
    }

    my @relevant = @clnali;
    my @prof_ali;
    my $done  = 0;
    my $cycle = 0;
    my $m1;
    my $added;
    my $top_hit;

    print STDERR join( '', "Adding $seq->[0]", $seq->[1] ? " $seq->[1]\n" : "\n" ) if ! $silent;

    while ( ! $done )
    {
        #  Do profile alignment on the current set:

        my $n = @relevant;
        print STDERR "   Aligning on a profile of $n sequences.\n" if ! $silent;

        $m1 = gjoseqlib::alignment_gap_mask( \@relevant );
        my $ali_on = gjoseqlib::pack_alignment_by_mask( $m1, \@relevant );

        @prof_ali = clustal_profile_alignment_0( $ali_on, $clnseq );

        # gjoseqlib::write_fasta( "add_2_align_clean_$cycle.aln", $clnseq );
        # gjoseqlib::write_fasta( "add_2_align_prof_$cycle.aln",  $ali_on );
        # gjoseqlib::write_fasta( "add_2_align_raw_$cycle.aln", \@prof_ali ); ++$cycle;

        $added = pop @prof_ali;

        #  Tag alignment sequences with similarity to new sequence and sort:

        my @evaluated = sort { $b->[0] <=> $a->[0] }
                        map  { [ fraction_identity( $_->[2], $added->[2], $type ), $_ ] }
                        @prof_ali;

        #  Compute identity threshold from the highest similarity:

        my $threshold = identity_threshold( $evaluated[0]->[0],
                                            length( $evaluated[0]->[1]->[2] ),
                                            $std_dev
                                          );

        #  Filter sequences for those that pass similarity threshold.

        @relevant = map  { $clnali{ $_->[1]->[0] } }    #  Clean copies
                    grep { ( $_->[0] >= $threshold ) }  #  Pass threshold
                    @evaluated;

        #  $top_hit is used to position the new sequence in the output alignment:

        $top_hit = $evaluated[0]->[1]->[0];

        $done = 1 if @relevant == @evaluated;  #  No sequences were discarded
    }

    #  Figure out where the gaps were added to the subset alignment, and to
    #  the new sequence:

    my $m2 = gjoseqlib::alignment_gap_mask( \@prof_ali );
    my $m3 = gjoseqlib::alignment_gap_mask(  $added );

    my ( $m4, $m5 ) = merge_alignment_information( $m1, $m2, $m3 );
    if ( $options->{ debug } )
    {
        my $m41 = $m4;
        my $m51 = $m5;
        print STDERR join( ', ', length($m4), $m41 =~ tr/\377//, length( $ali->[0]->[2] )), "\n";
        print STDERR join( ', ', length($m5), $m51 =~ tr/\377//, length( $seq->[2] )), "\n";
    }

    #  Time to expand the sequences; we will respect case and non-standard
    #  gap characters.  We will add new sequence immediately following the
    #  top_hit.

    my @new_align = ();

    foreach my $entry ( @$ali )
    {
        my ( $id, $def, $s ) = @$entry;
        push @new_align, [ $id, $def, gjoseqlib::expand_sequence_by_mask( $s, $m4 ) ];
        if ( $id_map{ $id } eq $top_hit )
        {
            #  Add gap characters to new sequence:
            my( $new_id, $new_def, $new_s ) = @$seq;
            push @new_align, [ $new_id, $new_def, gjoseqlib::expand_sequence_by_mask( $new_s, $m5 ) ];
        }
    }

    @new_align = &final_trim( $seq->[0], \@new_align ) if $trim;

    wantarray ? @new_align : \@new_align;
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  Build the alignment merging information for coverting the original alignment
#  and the added sequence into the final alignment.
#
#  ( $m4, $m5 ) = merge_alignment_information( $m1, $m2, $m3 )
#
#  The inputs are:
#
#     $m1 = the gaps removed from the original alignment to make the
#               profile of "relevant" sequences,
#     $m2 = the gaps that clustal introduced into the profile, and
#     $m3 = the gaps that clustal introduced into the added sequence.
#
#  The outputs are:
#
#     $m4 = the locations to add new gaps to the original alignment, and
#     $m5 = the locations to add gaps to the new sequence.
#
#  ali  rel
#  pos  pos  seq  m1  m2  m3  m4  m5
#   1    1    1    1   1   1   1   1
#   2    2    2    1   1   1   1   1
#   3    3    3    1   1   1   1   1
#   4              0           1   0
#   5              0           1   0
#   6    4    4    1   1   1   1   1
#   7    5    5    1   1   1   1   1
#   8    6    6    1   1   1   1   1
#   9         7    0   0   1   1   1
#  10         8    0   0   1   1   1
#  11              0           1   0
#  12    7    9    1   1   1   1   1
#  13    8   10    1   1   1   1   1
#  14    9         1   1   0   1   0
#  15   10         1   1   0   1   0
#  16   11   11    1   1   1   1   1
#            12        0   1   0   1
#            13        0   1   0   1
#  17   12   14    1   1   1   1   1
#  18   13   15    1   1   1   1   1
#
#
#  -----------------------------------------
#      length              number of 1s
#  -----------------------------------------
#  m1  length of ali       length of profile
#  m2  length of prof ali  length of profile
#  m3  length of prof ali  lenght of seq
#  m4  length of merge     length of ali
#  m5  length of merge     length of seq
#  -----------------------------------------
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub merge_alignment_information
{
    my ( $m1, $m2, $m3 ) = @_;
    my $i1max = length $m1;
    my $i2max = length $m2;
    my $i1 = 0;
    my $c1 = substr( $m1, $i1, 1 );
    my $i2 = 0;
    my $c2 = substr( $m2, $i2, 1 );
    my @m4;                      #  Mask for expanding original alignment
    my @m5;                      #  Mask for expanding new sequence
    while ( $i1 < $i1max || $i2 < $i2max )
    {
        if ( $c1 eq "\000" )      # ali column not in profile
        {
            if ( $c2 eq "\000" )  # new sequence restores column
            {
                push @m4, "\377";
                push @m5, "\377";
                $c1 = ( ++$i1 < $i1max ) ? substr( $m1, $i1, 1 ) : "\377";
                $c2 = ( ++$i2 < $i2max ) ? substr( $m2, $i2, 1 ) : "\377";
            }
            else
            {
                push @m4, "\377";
                push @m5, "\000";
                $c1 = ( ++$i1 < $i1max ) ? substr( $m1, $i1, 1 ) : "\377";
            }
        }
        else   # $c1 eq "\377"
        {
            if ( $c2 eq "\000" )  # new sequence adds a column
            {
                push @m4, "\000";
                push @m5, "\377";
                $c2 = ( ++$i2 < $i2max ) ? substr( $m2, $i2, 1 ) : "\377";
            }
            else
            {
                push @m4, "\377";
                push @m5, substr( $m3, $i2, 1 );
                $c1 = ( ++$i1 < $i1max ) ? substr( $m1, $i1, 1 ) : "\377";
                $c2 = ( ++$i2 < $i2max ) ? substr( $m2, $i2, 1 ) : "\377";
            }
        }
    }

    return ( join( '', @m4 ), join( '', @m5 ) );
}


#===============================================================================
#  Insert a new sequence into an alignment without altering the relative
#  alignment of the existing sequences.  The alignment is based on a profile
#  of those sequences that are not significantly less similar than the most
#  similar sequence.
#
#    \@align = add_to_alignment_v2a( $seq, \@ali, \%options )
#
#  Options:
#
#     trim   => bool     # trim sequence start and end
#     silent => bool     # no information messages
#     stddev => float    # window of similarity to include in profile (D = 1.5)
#
#===============================================================================

sub add_to_alignment_v2a
{
    my ( $seq, $ali, $options ) = @_;

    $options = {} if ! $options || ( ref( $options ) ne 'HASH' );

    my $trim    = $options->{ trim }   || 0;
    my $silent  = $options->{ silent } || 0;
    my $std_dev = $options->{ stddev } || 1.5;  #  The definition of "not significantly less similar"

    #  Don't add a sequence with a duplicate id.

    my $id = $seq->[0];
    foreach ( @$ali )
    {
        next if $_->[0] ne $id;
        print STDERR "Warning: add_to_alignment_v2a not adding sequence with duplicate id:\n$id\n" if ! $silent;
        return wantarray ? @$ali : $ali;
    }

    #  Put sequences in a clean canonical form and give them clustal-friendly
    #  names (first sequence through the map {} is the sequence to be added):

    my %id_map;
    $id = "seq000000";
    ( $seq ) = gjoseqlib::pack_sequences( $seq );
    my $type = gjoseqlib::guess_seq_type( $seq->[2] );
    my ( $clnseq, @clnali ) = map { $id_map{ $_->[0] } = $id;
                                    [ $id++, "", clean_for_clustal( $_->[2], $type ) ]
                                  }
                              ( $seq, @$ali );
    my %clnali = map { $_->[0] => $_ } @clnali;

    if ( $trim )    #### if we are trimming sequences before inserting into the alignment
    {
        my( $trimmed_start, $trimmed_len );
        ( $clnseq, $trimmed_start, $trimmed_len ) = trim_with_blastall( $clnseq, \@clnali, $type );
        if ( ! defined( $clnseq ) )
        {
            print STDERR "Warning: attempted to add a sequence with no recognizable similarity: $id\n";
            return $ali;
        }
        $seq->[2] = substr( $seq->[2], $trimmed_start, $trimmed_len );
    }

    my ( @prof_ali, $added, @evaluated );
    my @relevant = @clnali;

    my $done = 0;
    my $cycle = 0;
    while ( ! $done )
    {
        #  Do profile alignment on the current set:

        my $n = @relevant;
        print STDERR "   Aligning on a profile of $n sequences.\n" if ! $silent;

        @prof_ali = clustal_profile_alignment_0( \@relevant, $clnseq );
        # gjoseqlib::write_fasta( "add_2_align_raw_$cycle.aln", \@prof_ali ); ++$cycle;

        $added = pop @prof_ali;

        #  Tag alignment sequences with similarity to new sequence and sort:

        @evaluated = sort { $b->[0] <=> $a->[0] }
                     map  { [ fraction_identity( $_->[2], $added->[2], $type ), $_ ] }
                     @prof_ali;

        #  Compute identity threshold from the highest similarity:

        my $threshold = identity_threshold( $evaluated[0]->[0],
                                            length( $evaluated[0]->[1]->[2] ),
                                            $std_dev
                                          );

        #  Filter sequences for those that pass similarity threshold.

        @relevant = map  { $clnali{ $_->[1]->[0] } }    #  Clean copies
                    grep { ( $_->[0] >= $threshold ) }  #  Pass threshold
                    @evaluated;

        $done = 1 if @relevant == @evaluated;  #  No sequences were discarded
    }

    #  $top_hit is used to position the new sequence in the output alignment:

    my $top_hit = $evaluated[0]->[1]->[0];

    #  Figure out where the gaps were added to the input alignment:

    my $mask = added_gap_columns( \@relevant, \@prof_ali );

    #  Time to expand the sequences; we will respect case and non-standard
    #  gap characters.  We will add new sequence immediately following the
    #  top_hit.

    my @new_align = ();

    foreach my $entry ( @$ali )
    {
        my ( $id, $def, $s ) = @$entry;
        push @new_align, [ $id, $def, gjoseqlib::expand_sequence_by_mask( $s, $mask ) ];
        if ( $id_map{ $id } eq $top_hit )
        {
            #  Add gap characters to new sequence:
            my( $new_id, $new_def, $new_s ) = @$seq;
            my $new_mask = gjoseqlib::alignment_gap_mask( $added );
            push @new_align, [ $new_id, $new_def, gjoseqlib::expand_sequence_by_mask( $new_s, $new_mask ) ];
        }
    }

    @new_align = &final_trim( $seq->[0], \@new_align ) if $trim;

    wantarray ? @new_align : \@new_align;
}


#-------------------------------------------------------------------------------
#  Compare two otherwise identical alignments, finding columns of all gaps
#  that have been added to the second that are not in the first.  Added
#  columns are "\000" in output string (like columns to pack).  Other columns
#  are "\377".
#
#      $added_gaps = added_gap_columns( \@alignment1, \@alignment2 )
#
#-------------------------------------------------------------------------------
sub added_gap_columns
{
    return undef if ! ( $_[0] && ref( $_[0] ) eq 'ARRAY'
                     && $_[1] && ref( $_[1] ) eq 'ARRAY' );
    my $ali1gap = gjoseqlib::alignment_gap_mask( $_[0] );
    my $ali2gap = gjoseqlib::alignment_gap_mask( $_[1] );

    my $i1 = 0;
    for ( my $i2 = 0; $i2 < length( $ali2gap ); $i2++ )
    {
        #  Not a gap in align 2?
        if    ( substr( $ali2gap, $i2, 1 ) ne "\000" ) { $i1++ }
        #  Is also a gap in align 1?
        elsif ( substr( $ali1gap, $i1, 1 ) eq "\000" ) { $i1++; substr( $ali2gap, $i2, 1 ) = "\377" }
    }

    $ali2gap;
}


#-------------------------------------------------------------------------------
#  Align a sequence or profile to an existing profile.
#
#     \@alignment = clustal_profile_alignment( \@seqs,  $seq )
#     \@alignment = clustal_profile_alignment( \@seqs, \@seqs )
#
#-------------------------------------------------------------------------------
sub clustal_profile_alignment
{
    my ( $seqs1, $seqs2 ) = @_;

    $seqs1 && ref $seqs1 eq 'ARRAY' && @$seqs1 && $seqs1->[0] && ref $seqs1 eq 'ARRAY'
        or return ();
    $seqs2 && ref $seqs2 eq 'ARRAY' && @$seqs2
        or return ();
    $seqs2 = [ $seqs2 ] if ! ( ref $seqs2->[0] );

    $seqs1 = gjoseqlib::pack_alignment( $seqs1 );
    $seqs2 = gjoseqlib::pack_alignment( $seqs2 );

    #  Put sequences in a clean canonical form and give them clustal-friendly
    #  names (first sequence through the map {} is the sequence to be added):

    my $id = "seq000001";
    my $type = gjoseqlib::guess_seq_type( $seqs1->[2] );

    my %id_map;
    my @cln1 = map { $id_map{ $id } = $_; [ $id++, "", clean_for_clustal( $_->[2], $type ) ] }
               @$seqs1;

    my @cln2 = map { $id_map{ $id } = $_; [ $id++, "", clean_for_clustal( $_->[2], $type ) ] }
               @$seqs2;

    my @aln1 = clustal_profile_alignment_0( \@cln1, \@cln2 );
    my @aln2 = splice @aln1, @$seqs1;

    my @align;

    my $gap1 = gjoseqlib::alignment_gap_mask( \@aln1 );
    push @align, map { my ( $ori_id, $ori_def, $ori_seq ) = @{ $id_map{ $_->[0] } };
                       [ $ori_id, $ori_def, gjoseqlib::expand_sequence_by_mask( $ori_seq, $gap1 ) ]
                     }
                 @aln1; 

    my $gap2 = gjoseqlib::alignment_gap_mask( \@aln2 );
    push @align, map { my ( $ori_id, $ori_def, $ori_seq ) = @{ $id_map{ $_->[0] } };
                       [ $ori_id, $ori_def, gjoseqlib::expand_sequence_by_mask( $ori_seq, $gap2 ) ]
                     }
                 @aln2; 

    wantarray ? @align : \@align;
}


#-------------------------------------------------------------------------------
#  Align a sequence or profile to an existing profile.
#
#     \@alignment = clustal_profile_alignment_0( \@seqs,  $seq )
#     \@alignment = clustal_profile_alignment_0( \@seqs, \@seqs )
#
#  Assumes that ids and sequences are clustal friendly, so this is not really
#  a function for the outside world; use clustal_profile_alignment() instead.
#-------------------------------------------------------------------------------
sub clustal_profile_alignment_0
{
    my ( $seqs1, $seqs2 ) = @_;

    my $tmpdir  = SeedAware::location_of_tmp( );
    my $profile = SeedAware::tmp_file_name( "add_to_align_1", 'fasta', $tmpdir );
    my $seqfile = SeedAware::tmp_file_name( "add_to_align_2", 'fasta', $tmpdir );
    my $outfile = SeedAware::tmp_file_name( "add_to_align",   'aln',   $tmpdir );
    ( my $dndfile = $profile ) =~ s/fasta$/dnd/;  # The program ignores our name

    $seqs2 = [ $seqs2 ] if ! ( ref $seqs2->[0] );
    gjoseqlib::write_fasta( $profile, $seqs1 );
    gjoseqlib::write_fasta( $seqfile, $seqs2 );

    my $clustalw = SeedAware::executable_for( 'clustalw' )
        or print STDERR "Could not locate executable file for 'clustalw'.\n"
            and return undef;

    my @params = ( "-profile1=$profile",
                   "-profile2=$seqfile",
                   "-outfile=$outfile",
                   "-newtree=$dndfile",
                   '-outorder=input',
                   '-maxdiv=0',
                   '-profile'
                 );
    my $redirects = { stdout => '/dev/null' };
    SeedAware::system_with_redirect( $clustalw, @params, $redirects );

    #  2010-09-08: clustalw profile align can columns of all gaps; so pack it

    my @aligned = gjoseqlib::pack_alignment( gjoseqlib::read_clustal_file( $outfile ) );

    unlink( $profile, $seqfile, $outfile, $dndfile );

    wantarray ? @aligned : \@aligned;
}


#-------------------------------------------------------------------------------
#
#  remove dangling ends from $id
#
#-------------------------------------------------------------------------------
sub final_trim
{
    my( $id, $ali ) = @_;

    my $mask = gjoseqlib::alignment_gap_mask( grep { $_->[0] ne $id } @$ali );
    if ( $mask =~ /^\000*(\377.*\377)\000*$/ )
    {
        my $off = $-[1] || 0;
        my $end = $+[1] || length( $mask );

        if ( $off > 0 || $end < length( $mask ) )
        {
            foreach my $seq ( @$ali ) { $seq->[2] = substr( $seq->[2], $off, $end-$off ) }
        }
    }
    return @$ali;
}


sub clean_for_clustal
{
    my $seq  = uc shift;
    my $type = shift || 'p';
    if ( $type =~ m/^p/i )
    {
        $seq =~ tr/UBJOZ*/CXXXXX/;             # Sec -> Cys, other to X
    }
    else
    {
        $seq =~ tr/UEFIJLOPQXZ/TNNNNNNNNNN/;   # U -> T, other to N
    }
    $seq =~ s/[^A-Z]/-/g;     # Nonstandard gaps

    $seq
}


sub fract_identity
{
    my ( $seq1, $seq2 ) = @_;
    my ( $s1, $s2, $i, $same );

    my $tmpdir  = SeedAware::location_of_tmp( );
    my $infile  = SeedAware::tmp_file_name( "fract_identity", 'fasta', $tmpdir );
    my $outfile = SeedAware::tmp_file_name( "fract_identity", 'aln',   $tmpdir );
    my $dndfile = SeedAware::tmp_file_name( "fract_identity", 'dnd',   $tmpdir );

    $s1 = $seq1->[2];
    $s1 =~ s/[^A-Za-z]+//g;
    $s2 = $seq2->[2];
    $s2 =~ s/[^A-Za-z]+//g;
    gjoseqlib::write_fasta( $infile, [ [ "s1", "", $s1 ], [ "s2", "", $s2 ] ] );

    my $clustalw = SeedAware::executable_for( 'clustalw' )
        or print STDERR "Could not locate executable file for 'clustalw'.\n"
            and return undef;

    my @params = ( "-infile=$infile",
                   "-outfile=$outfile",
                   "-newtree=$dndfile",
                   '-maxdiv=0',
                   '-align'
                 );
    my $redirects = { stdout => '/dev/null' };
    SeedAware::system_with_redirect( $clustalw, @params, $redirects );

    ( $s1, $s2 ) = map { $_->[2] } gjoseqlib::read_clustal_file( $outfile );  # just seqs

    unlink( $infile, $outfile, $dndfile );

    fraction_aa_identity( $s1, $s2 );
}


sub identity_threshold
{
    my ( $maxsim, $seqlen, $z ) = @_;
    $z = 1.5 if ! $z;
    my ( $p, $sigma, $step );

    $p = $maxsim / 2;
    $step = $p / 2;
    while ( $step > 0.0005 ) {
        $sigma = sqrt( $p * (1 - $p) / $seqlen );
        $p += ( $p + ( $z * $sigma ) < $maxsim ) ? $step : (- $step);
        $step /= 2;
    }
    return $p - $z * $sigma;
}

#
#  Relic: Use gjoseqlib::guess_seq_type() instead
#
sub guess_seq_type
{
    my $seq = shift;
    $seq =~ tr/A-Za-z//cd;
    my $nt_cnt = $seq =~ tr/ACGTUacgtu//;
    ( $nt_cnt > ( 0.5 * length( $seq ) ) ) ? 'n' : 'p';
}


#===============================================================================
#  Compare two sequences for fraction identity.
#
#     $fract_id = fraction_identity( $seq1, $seq2, $type );
#     $fract_id = fraction_aa_identity( $seq1, $seq2 );
#     $fract_id = fraction_nt_identity( $seq1, $seq2 );
#
#  $type is 'p' or 'n' (D = p)
#===============================================================================
sub fraction_identity
{
    my $prot = ( $_[2] && ( $_[2] =~ m/^n/i ) ) ? 0 : 1;
    my ( $npos, $nid ) = $prot ? gjoseqlib::interpret_aa_align( @_[0,1] )
                               : gjoseqlib::interpret_nt_align( @_[0,1] );
    ( $npos > 0 ) ? $nid / $npos : undef
}

sub fraction_aa_identity
{
    my ( $npos, $nid ) = gjoseqlib::interpret_aa_align( @_[0,1] );
    ( $npos > 0 ) ? $nid / $npos : undef
}

sub fraction_nt_identity
{
    my ( $npos, $nid ) = gjoseqlib::interpret_nt_align( @_[0,1] );
    ( $npos > 0 ) ? $nid / $npos : undef
}


#===============================================================================
#  The logic used here to optimize identification of "same" column depends
#  on the fact that only the second alignment ($y) has new columns, and they
#  are all gaps.  Therefore any non-gap character in alignment $y indicates
#  that it is not a column of added gaps (it must match).  After learning
#  that alignment $y has a gap, then we only need test $x for a gap.
#===============================================================================

sub same_col
{
    my ( $x, $colx, $y, $coly ) = @_;
    my ( $seq, $seqmax, $cy );

    $seqmax = @$x - 1;
    for ( $seq = 0; $seq <= $seqmax; $seq++ )
    {
        if ( substr($y->[$seq], $coly, 1) ne "-" ) { return 1 } # Non-gap in aligned
        if ( substr($x->[$seq], $colx, 1) ne "-" ) { return 0 } # Unmatched gap
    }
    return 1;
}


#===============================================================================
#  Trim sequences (needs to get updated to new tools and psiblast)
#===============================================================================
sub trim_with_blastall
{
    my( $clnseq, $clnali, $type ) = @_;

    my $tmpdir    = SeedAware::location_of_tmp( );
    my $blastfile = SeedAware::tmp_file_name( "trim_blastdb", $tmpdir );
    my $seqfile   = SeedAware::tmp_file_name( "trim_query",   $tmpdir );

    gjoseqlib::write_fasta( $blastfile, scalar gjoseqlib::pack_sequences( $clnali ) );
    gjoseqlib::write_fasta( $seqfile,   scalar gjoseqlib::pack_sequences( $clnseq ) );

    $type = gjoseqlib::guess_seq_type( $clnseq->[2] ) if ! $type;
    my ( $is_prot, $prog, @opt ) = ( $type =~ m/^n/i ) ? qw( f blastn -r 1 -q -1 )
                                                       : qw( t blastp );
    my $formatdb = SeedAware::executable_for( 'formatdb' )
        or print STDERR "Could not locate executable file for 'formatdb'.\n"
            and return undef;

    my $blastall = SeedAware::executable_for( 'blastall' )
        or print STDERR "Could not locate executable file for 'blastall'.\n"
            and return undef;

    my @fmt_params = ( '-i', $blastfile, '-p', $is_prot );
    my $fmt_redirects = { stderr => '/dev/null' };
    SeedAware::system_with_redirect( $formatdb, @fmt_params, $fmt_redirects );

    my @params = ( '-p', $prog,
                   '-d', $blastfile,
                   '-i', $seqfile,
                   '-e',  0.001,
                   '-b',  5,        # Top 5 matches
                   '-v',  5,
                   '-F', 'f',
                   '-m',  8,
                   @opt
                 );
    my $redirects = { stderr => '/dev/null' };
    my $BLASTOUT = SeedAware::read_from_pipe_with_redirect( $blastall, @params, $redirects )
        or die "could not handle the blast";
    my @out = map { chomp; [ ( split )[ 1, 6, 7, 8, 9 ] ] } <$BLASTOUT>;
    close( $BLASTOUT );

    my @dbfile = map { "$blastfile.$_" } $type =~ m/^n/i ? qw( nin nhr nsq ) : qw( pin phr psq );
    unlink( $seqfile, $blastfile, @dbfile );

    if (@out < 1) { return undef }

    my %lenH;
    foreach my $tuple (@$clnali)
    {
        $lenH{$tuple->[0]} = $tuple->[2] =~ tr/a-zA-Z//;
    }

    @out = sort { ($a->[1] <=> $b->[1]) or ($a->[3] <=> $b->[3]) } @out;
    my @to_removeS = sort { $a <=> $b } map { &remove($_->[1],$_->[3])} @out;

    my $lenQ = length($clnseq->[2]);
    my @ends = map { [$lenQ - $_->[2], $lenH{$_->[0]} - $_->[4]] } @out;
    my @to_removeE = sort { $a <=> $b } map { &remove($_->[0]+1,$_->[1]+1) } @ends;
    my $trimmed_start = $to_removeS[0];
    my $trimmed_len = $lenQ - ($to_removeS[0] + $to_removeE[0]);
    my $seqT = substr($clnseq->[2],$trimmed_start,$trimmed_len);

    return ([$clnseq->[0],$clnseq->[1],$seqT],$trimmed_start,$trimmed_len);
}


sub remove
{
    my( $b1, $b2 ) = @_;
    return ($b2 <= 5) ? &max( $b1 - $b2, 0 ) : $b1 - 1;
}


#===============================================================================
#  Extract a representative set from an alignment
#
#     @alignment = representative_alignment( \@alignment, \%options );
#    \@alignment = representative_alignment( \@alignment, \%options );
#
#  Options:
#
#     keep    =>   $id                    # keep this sequence unconditionally
#     keep    =>  \@ids                   # keep these sequences unconditionally
#     max_sim =>   $fract_ident           # maximum identity to retained sequences (D = 0.8)
#     min_sim => [ $fract_ident,  @ids ]  # remove sequences more diverged than
#     min_sim => [ $fract_ident, \@ids ]  # remove sequences more diverged than
#                                         #     this identity to these refs
#    nopack   =>   $bool                  # do not pack the resulting alignment
#
#  If the greatest identity is <= max_id, then it is a new similarity group.
#  If the greatest identity is <= ext_id, then it is an extra rep of an
#  existing group.
#
#                              new
#                             group
#   |        new group      |  rep  |  ignore  |
#   |-----------------------|-------|----------|->  identity
#   0                     max_id  ext_id       1
#
#===============================================================================

sub representative_alignment
{
    my ( $align, $opts ) = @_;

    return undef unless gjoseqlib::is_array_of_sequence_triples( $align );

    $opts = {} unless $opts && ref($opts) eq 'HASH';

    my $max_id = $opts->{ max_sim } || 0.8;
    my $ext_id = $max_id ** 0.8;

    my $keep = $opts->{ keep };
    my %keep;
    if ( $keep )
    {
        %keep = map { $_ => 1 }
                ( ref( $keep ) eq 'ARRAY' ) ? @$keep : $keep;
    }

    #  Remove sequences of low similarity to specified references

    my @align;
    my $min_opt = $opts->{ min_sim };
    if ( $min_opt && ( ref($min_opt) eq 'ARRAY' ) && @$min_opt > 1 )
    {
        my ( $min_sim, @ref_ids ) = @$min_opt;
        @ref_ids = @{ $ref_ids[0] } if @ref_ids == 1 && ref( $ref_ids[0] ) eq 'ARRAY';
        my %ref_id  = map  { defined($_) ? ( $_ => 1 ) : () } @ref_ids;
        my @ref_seq = grep { $ref_id{ $_->[0] } } @$align;
        if ( @ref_seq )
        {
            foreach my $aln_seq ( @$align )
            {
                if ( $keep && $keep{ $aln_seq->[0] } )
                {
                    push @align, $aln_seq;
                    next;
                }

                foreach ( @ref_seq )
                {
                    my $ident = fraction_aa_identity( $aln_seq->[2], $_->[2] );
                    if ( $ident && ( $ident >= $min_sim ) )
                    {
                        push @align, $aln_seq;
                        last;
                    }
                }
            }
        }
        else
        {
            #  No valid filter ids should have a warning;
            #  Of course we could just return an empty list.
            @align = @$align;
        }
    }
    else
    {
        @align = @$align;
    }

    #  Original order to restore on output

    my $n = 0;
    my %order = map { $_->[0] => ++$n } @align;

    #  Reorder the sequences for those with the most residues in columns
    #  that other sequences also use.

    @align = reorder_by_useful_residues( \@align );

    my %id_to_group;
    my @groups;
    my @reps;
    foreach my $try ( @align )
    {
        my $gr;
        my $status = 0;      #  Highest identity so far, or 2 for redundant
        foreach ( @reps )
        {
            #  ( $nid/$nmat ) = fraction_aa_identity( $seq1, $seq2 )
            my $ident = fraction_aa_identity( $try->[2], $_->[2] ) || 0;

            #  Too similar for extra rep of group; add to group of sim sequence
            if ( $ident > $ext_id )
            {
                $gr     = $id_to_group{ $_->[0] };
                $status = 2;
                last;
            }

            #  Too similar for new group, but possible extra rep of a group
            if ( ( $ident > $max_id ) && ( $ident > $status ) )
            {
                $gr     = $id_to_group{ $_->[0] };
                $status = $ident
            }
        }

        push @reps, $try  if ( $status <= 1 );  # add a new diverse rep

        my $id = $try->[0];
        if ( $status == 0 )     # start a new group
        {
            $id_to_group{ $id } = @groups;
            push @groups, [ $try ];
        }
        else                    # add to existing group
        {
            $id_to_group{ $id } = $gr;
            push @{ $groups[$gr] }, $try;
        }
    }

    #  Okay, we now need to pick one or more representatives from each
    #  similarity cluster.

    my %is_rep = ();
    foreach my $group ( @groups )
    {
        #  A keep option can give a group multiple reps.
        #  We might want to reconsider whether there are also conditions
        #  in which we also keep the nucleating member of the group.
        my @gr_rep;
        if ( $keep && ( @gr_rep = grep { $keep{ $_->[0] } } @$group ) )
        {
            foreach ( @gr_rep ) { $is_rep{ $_->[0] } = 1 }
        }

        #  If this did not get it, we just want the first member of the group,
        #  because the sequences were examined in a prioritized order.
        else
        {
            $is_rep{ $group->[0]->[0] } = 1;
        }
    }

    @reps = map  { $_->[0] }                     #  strip order info
            sort { $a->[1] <=> $b->[1] }         #  sort by input order
            map  { [ $_, $order{ $_->[0] } ] }   #  tag entry with order
            grep { $is_rep{ $_->[0] } } @align;  #  filter for reps

    @reps = gjoseqlib::pack_alignment( \@reps ) unless $opts->{ nopack };
    
    wantarray ? @reps : \@reps;
}


#===============================================================================
#  Remove divergent sequences from an alignment
#
#     @alignment = filter_by_similarity( \@align, $min_sim, @id_def_seq );
#    \@alignment = filter_by_similarity( \@align, $min_sim, @id_def_seq );
#
#     @alignment = filter_by_similarity( \@align, $min_sim, @ids );
#    \@alignment = filter_by_similarity( \@align, $min_sim, @ids );
#
#===============================================================================

sub filter_by_similarity
{
    my ( $align, $min_sim ) = splice @_, 0, 2;

    return undef unless gjoseqlib::is_array_of_sequence_triples( $align );
    return wantarray ? @_ : [ @_ ]  unless @_ && $_[0] && $min_sim && $min_sim > 0;

    my @ref_seq;
    if ( ref( $_[0] ) eq 'ARRAY' )
    {
        @ref_seq = @_;
    }
    else
    {
        my %ref_ids = map { $_->[0] => 1 } @_;
        @ref_seq = map { $ref_ids{ $_->[0] } ? $_ : () } @$align;
        return wantarray ? @_ : [ @_ ]  unless @ref_seq;
    }

    my @are_sim;
    foreach my $aln_seq ( @$align )
    {
        foreach ( @ref_seq )
        {
            my $ident = fraction_aa_identity( $aln_seq->[2], $_->[2] );
            if ( $ident && ( $ident >= $min_sim ) )
            {
                push @are_sim, $aln_seq;
                last;
            }
        }
    }

    wantarray ? @are_sim : \@are_sim;
}


#-------------------------------------------------------------------------------
#  Reorder sequences in an alignment, prioritized by the residues per column
#  of the columns in which the sequence has unambiguous residues.  That is,
#  each column is scored by the number of unambiguous residues that it
#  contains, and then for each sequence, these scores are summed for the
#  columns in which that sequence has residues.
#
#       @align = reorder_by_useful_residues( \@align, \%options )
#      \@align = reorder_by_useful_residues( \@align, \%options )
#
#  Options:
#
#    dna        => $bool   # Residues are nucleotides (D = guess)
#    nucleotide => $bool   # Residues are nucleotides (D = guess)
#    protein    => $bool   # Residues are amino acides (D = guess)
#    rna        => $bool   # Residues are nucleotides (D = guess)
#
#-------------------------------------------------------------------------------
sub reorder_by_useful_residues
{
    my ( $align, $opts ) = @_;
    return () unless $align && ( ref( $align ) eq 'ARRAY' ) && @$align && $align->[0];

    $opts = {} unless $opts && ref( $opts ) eq 'HASH';

    my $aa = $opts->{ protein };
    my $nt = $opts->{ rna } || $opts->{ RNA }
          || $opts->{ dna } || $opts->{ DNA }
          || $opts->{ nucleotide };

    if ( ! ( $aa || $nt ) )
    {
        my $type = gjoseqlib::guess_seq_type( $align->[0] );
        $nt = $type =~ /^.NA/i;
    }

    #  Get the per column residue counts as a string, where the ordinal
    #  values of the characters are the values.
    my $opt2 = { $nt ? ( dna => 1 ) : ( protein => 1 ) };
    my $cnts = residues_per_column( $align, $opt2 );

    my @wgt;
    foreach my $entry ( @$align )
    {
        local $_ = $entry->[2];

        #  Make a mask of the unambiguous characters in the sequence.
        if ( $nt )
        {
            tr/ACGTUacgtu/\0/c;
            tr/ACGTUacgtu/\x{FFFFFF}/;
        }
        else
        {
            tr/ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy/\0/c;
            tr/ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy/\x{FFFFFF}/;
        }

        #  Mask column counts by unambiguous residues in sequence, and compress
        $_ &= $cnts;
        tr/\0//d;

        #  Count the remaining column scores
        my $scr = 0;
        for ( my $i = 0; $i < length($_); $i++ )
        {
            $scr += ord( substr( $_, $i, 1 ) );
        }

        #  Tag the sequence entry for sorting
        push @wgt, [ $entry, $scr ];
    }

    my @align = map  { $_->[0] }
                sort { $b->[1] <=> $a->[1] }
                @wgt;

    wantarray ? @align : \@align;
}


#-------------------------------------------------------------------------------
#  Find the number of residues in each alignment column, with the idea of
#  using these as column weights.
#
#       @counts = residues_per_column( \@align, \%options )
#       @counts = residues_per_column( \@seq,   \%options )
#       @counts = residues_per_column( \@seqR,  \%options )
#
#       $counts = residues_per_column( \@align, \%options )
#       $counts = residues_per_column( \@seq,   \%options )
#       $counts = residues_per_column( \@seqR,  \%options )
#
#  Where:
#
#      @counts is a list of numbers; and
#      $counts is a string, in which the ordinal value of each character is
#          the count.
#
#  In each group:
#
#     The first form takes a reference to an array of sequence triples.
#     The second form takes a reference to an array of sequences.
#     The third form takes a reference to an array of sequence references.
#
#  Options:
#
#    dna        => $bool   # Residues are nucleotides (D = guess)
#    nucleotide => $bool   # Residues are nucleotides (D = guess)
#    protein    => $bool   # Residues are amino acides (D = guess)
#    rna        => $bool   # Residues are nucleotides (D = guess)
#
#-------------------------------------------------------------------------------
sub residues_per_column
{
    my ( $align, $opts ) = @_;
    return () unless $align && ( ref( $align ) eq 'ARRAY' ) && @$align && $align->[0];

    $opts = {} unless $opts && ref( $opts ) eq 'HASH';

    my $aa = $opts->{ protein };
    my $nt = $opts->{ rna } || $opts->{ RNA }
          || $opts->{ dna } || $opts->{ DNA }
          || $opts->{ nucleotide };

    if ( ! ( $aa || $nt ) )
    {
        my $type = gjoseqlib::guess_seq_type( $align->[0] );
        $nt = $type =~ /^.NA/i;
    }

    #  Normalize the alignment to be references to the sequences, comparing
    #  all lengths to that of first sequence.

    my $len;
    my @align;

    #  Array of id_def_seq triples:
    if ( gjoseqlib::is_array_of_sequence_triples( $align ) )
    {
        $len = length( $align->[0]->[2] );
        @align = map { length( $_->[2] ) == $len ? \$_->[2] : () } @$align;
    }

    #  Array of sequences:
    elsif ( ! ref( $align->[0] ) )
    {
        $len = length( $align->[0] );
        @align = map { $_ && ! ref( $_ ) && length( $_ ) == $len ? \$_ : () } @$align;
    }

    #  Array of sequence references:
    elsif ( ref( $align->[0] ) eq 'SCALAR' )
    {
        $len = length( ${$align->[0]} );
        @align = map { $_ && ref( $_ ) eq 'SCALAR' && length( $$_ ) == $len ? $_ : () } @$align;
    }
    return () unless @align == @$align;

    #  Set up the count array, and work through the sequences:

    my @cnt = map { 0 } ( 1 .. $len );
    foreach my $seqR ( @align )
    {
        local $_ = $$seqR;
        if ( $nt )
        {
            tr/ACGTUacgtu/\0/c;
            tr/ACGTUacgtu/\1/;
        }
        else
        {
            tr/ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy/\0/c;
            tr/ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy/\1/;
        }

        for ( my $i = 0; $i < $len; $i++ )
        {
            $cnt[$i] += ord( substr( $_, $i, 1 ) );
        }
    }

    wantarray ? @cnt : join( '', map { chr($_) } @cnt ); 
}


#-------------------------------------------------------------------------------
#  Find the consensus sequence for an alignment.
#
#       $sequence = consensus_sequence( \@align, \%options )
#       $sequence = consensus_sequence( \@seq,   \%options )
#       $sequence = consensus_sequence( \@seqR,  \%options )
#
#  The first form takes a reference to an array of sequence triples, while
#  the second form takes a reference to an array of sequences, and the
#  third form takes a reference to an array of sequence references.
#
#  Options:
#
#    dna      => $bool   # Find a DNA consensus (D = guess)
#    gap_ok   => $bool   # Allow gaps in the consensus (D = no gap residues)
#    min_freq => $fract  # Minimum occurrence frequency of residue (D = >0)
#    protein  => $bool   # Find a protein consensus (D = guess)
#    rna      => $bool   # Find an RNA consensus (D = guess)
#
#-------------------------------------------------------------------------------
sub consensus_sequence
{
    my ( $align, $opts ) = @_;
    return undef unless $align && ( ref( $align ) eq 'ARRAY' ) && @$align && $align->[0];

    $opts = {} unless $opts && ref( $opts ) eq 'HASH';

    my $aa = $opts->{ protein };
    my $nt = $opts->{ rna } || $opts->{ RNA }
          || $opts->{ dna } || $opts->{ DNA }
          || $opts->{ nucleotide };

    if ( ! ( $aa || $nt ) )
    {
        my $type = gjoseqlib::guess_seq_type( $align->[0] );
        $nt = $type =~ /^.NA/i;
        $opts->{ rna } = 1 if $type =~ /^RNA/i;
    }

    $nt ? consensus_sequence_nt( $align, $opts )
        : consensus_sequence_aa( $align, $opts );
}


#-------------------------------------------------------------------------------
#  Find the consensus sequence for an amino acid sequence alignment.
#
#       $sequence = consensus_sequence_aa( \@align, $options )
#       $sequence = consensus_sequence_aa( \@seq,   $options )
#       $sequence = consensus_sequence_aa( \@seqR,  $options )
#
#  The first form takes a reference to an array of sequence triples, while
#  the second form takes a reference to an array of sequences, and the
#  third form takes a reference to an array of sequence references.
#
#  Options:
#
#    gap_ok   => $bool   # Allow gaps in the consensus (D = no gap residues)
#    min_freq => $fract  # Minimum occurrence frequency of residue (D = >0)
#
#-------------------------------------------------------------------------------
sub consensus_sequence_aa
{
    my ( $align, $opts ) = @_;
    return undef unless $align && ( ref( $align ) eq 'ARRAY' ) && @$align && $align->[0];

    $opts = {} unless $opts && ref( $opts ) eq 'HASH';

    my $gap_ok = $opts->{ gap_ok }   || 0;
    my $min_fr = $opts->{ min_freq } || 1e-100;

    # Normalize the alignment to be references to the sequences.

    my $len;
    my @align;
    if ( gjoseqlib::is_array_of_sequence_triples( $align ) )
    {
        $len = length( $align->[0]->[2] );
        @align = map { length( $_->[2] ) == $len ? \$_->[2] : () } @$align;
    }
    elsif ( ! ref( $align->[0] ) )
    {
        $len = length( $align->[0] );
        @align = map { $_ && ! ref( $_ ) && length( $_ ) == $len ? \$_ : () } @$align;
    }
    elsif ( ref( $align->[0] ) eq 'SCALAR' )
    {
        $len = length( ${$align->[0]} );
        @align = map { $_ && ref( $_ ) eq 'SCALAR' && length( $$_ ) == $len ? $_ : () } @$align;
    }
    return undef unless @align == @$align;

    my @cnts = map { [ (0) x 22 ] } ( 1 .. $len );
    foreach my $seqR ( @align )
    {
        #  Copy the sequences so that we do not destroy the original.
        my $seq = $$seqR;
        #  Transliterate nonresidues to \000.
        $seq =~ tr/ACDEFGHIKLMNPQRSTVWYUacdefghiklmnpqrstvwyu-/\000/c;
        #  Transliterate residues to an index, with U going to the same index as C.
        $seq =~ tr/ACDEFGHIKLMNPQRSTVWYUacdefghiklmnpqrstvwyu-/\001-\024\002\001-\024\002\025/;
        #  Count the residues by column.
        for ( my $i = 0; $i < $len; $i++ ) { $cnts[$i]->[ord(substr($seq,$i,1))]++ }
    }

    my @consensus;
    foreach ( @cnts )
    {
        my $n;
        my $nmax = 0;
        my $imax = 0;
        my $ttl  = 0;
        for ( my $i = 1; $i <= 20; $i++ )
        {
            $n = $_->[$i];
            if ( $n > $nmax ) { $nmax = $n; $imax = $i }
            $ttl += $n;
        }

        my $res = 'X';
        #  Gaps allowed and more common than nongaps?
        if ( $gap_ok && ( $_->[21] > $ttl ) )
        {
            $res = '-';
        }
        #  Majority residue is sufficiently abundant?
        elsif ( $ttl && ( $nmax/$ttl >= $min_fr ) )
        {
            $res = qw( . A C D E F G H I K L M N P Q R S T V W Y )[$imax];
        }
        push @consensus, $res;
    }

    join( '', @consensus );
}


#-------------------------------------------------------------------------------
#  Find the consensus sequence for a nucleotide sequence alignment.
#
#       $sequence = consensus_sequence_nt( \@align, $options )
#       $sequence = consensus_sequence_nt( \@seq,   $options )
#       $sequence = consensus_sequence_nt( \@seqR,  $options )
#
#  The first form takes a reference to an array of sequence triples, while
#  the second form takes a reference to an array of sequences, and the
#  third form takes a reference to an array of sequence references.
#
#  Options:
#
#    gap_ok   => $bool   # Allow gaps in the consensus (D = no gap residues)
#    min_freq => $fract  #  Minimum occurrence frequency of residue (D = >0)
#    rna      => $bool   #  Output U instead of T.
#
#-------------------------------------------------------------------------------
sub consensus_sequence_nt
{
    my ( $align, $opts ) = @_;
    return undef unless $align && ( ref( $align ) eq 'ARRAY' ) && @$align &&  $align->[0];

    $opts = {} unless $opts && ref( $opts ) eq 'HASH';

    my $gap_ok = $opts->{ gap_ok }   || 0;
    my $min_fr = $opts->{ min_freq } || 1e-100;
    my $rna    = $opts->{ rna }      || 0;

    # Normalize the alignment to be references to the sequences.

    my $len;
    my @align;
    if ( gjoseqlib::is_array_of_sequence_triples( $align ) )
    {
        $len = length( $align->[0]->[2] );
        @align = map { length( $_->[2] ) == $len ? \$_->[2] : () } @$align;
    }
    elsif ( ! ref( $align->[0] ) )
    {
        $len = length( $align->[0] );
        @align = map { $_ && ! ref( $_ ) && length( $_ ) == $len ? \$_ : () } @$align;
    }
    elsif ( ref( $align->[0] ) eq 'SCALAR' )
    {
        $len = length( ${$align->[0]} );
        @align = map { $_ && ref( $_ ) eq 'SCALAR' && length( $$_ ) == $len ? $_ : () } @$align;
    }
    return undef unless @align == @$align;

    my @cnts = map { [ (0) x 6 ] } ( 1 .. $len );
    foreach my $seqR ( @align )
    {
        #  Copy the sequences so that we do not destroy the original.
        my $seq = $$seqR;
        #  Transliterate nonresidues to \000.
        $seq =~ tr/ACGTUacgtu-/\000/c;
        #  Transliterate residues to an index, with U going to the same index as T.
        $seq =~ tr/ACGTUacgtu-/\001-\004\004\001-\004\004\005/;
        #  Count the residues by column.
        for ( my $i = 0; $i < $len; $i++ ) { $cnts[$i]->[ord(substr($seq,$i,1))]++ }
    }

    my @consensus;
    foreach ( @cnts )
    {
        my $n;
        my $nmax = 0;
        my $imax = 0;
        my $ttl  = 0;
        for ( my $i = 1; $i <= 4; $i++ )
        {
            $n = $_->[$i];
            if ( $n > $nmax ) { $nmax = $n; $imax = $i }
            $ttl += $n;
        }

        my $res = 'N';
        #  Gaps allowed and more common than nongaps?
        if ( $gap_ok && ( $_->[5] > $ttl ) )
        {
            $res = '-';
        }
        #  Majority residue is sufficiently abundant?
        elsif ( $ttl && ( $nmax/$ttl >= $min_fr ) )
        {
            $res = $rna ? qw( . A C G U )[$imax]
                        : qw( . A C G T )[$imax];
        }
        push @consensus, $res;
    }

    join( '', @consensus );
}


#-------------------------------------------------------------------------------
#  Find the consensus amino acid residue at specified alignment column.
#  For evaluating a whole alignment, this routine is more than 5x slower
#  than consensus_sequence_aa().
#
#       $residue              = consensus_aa_in_column( \@align, $column, $gap_ok )
#     ( $residue, $fraction ) = consensus_aa_in_column( \@align, $column, $gap_ok )
#
#       $residue              = consensus_aa_in_column( \@seqR, $column, $gap_ok )
#     ( $residue, $fraction ) = consensus_aa_in_column( \@seqR, $column, $gap_ok )
#
#  The first form takes a reference to an array of sequence triples, while
#  the second form takes a reference to an array of references to sequences.
#  Column numbers are 1-based.
#  $gap_ok indicates whether the consensus can be a gap.
#-------------------------------------------------------------------------------
sub consensus_aa_in_column
{
    my ( $align, $column, $gap_ok ) = @_;

    my $are_seq_ref;
    my $len;
    if ( gjoseqlib::is_array_of_sequence_triples( $align ) )
    {
        $are_seq_ref = 0;
        $len = length( $align->[0]->[2] );
    }
    elsif ( $align      && ( ref( $align )      eq 'ARRAY' )
         && $align->[0] && ( ref( $align->[0] ) eq 'SCALAR' )
          )
    {
        $are_seq_ref = 1;
        $len = length( ${$align->[0]} );
    }
    else
    {
        return wantarray ? () : undef;
    }
    return wantarray ? () : undef unless $column && $column > 0 && $column <= $len;

    my $offset = $column - 1;
    my @cnt = ( (0) x 27 );
    my $ttl = 0;
    foreach ( @$align )
    {
        my $aa = uc( substr( $are_seq_ref ? $$_ : $_->[2], $offset, 1 ) || ' ');
        if ( $gap_ok && $aa eq '-' ) { $cnt[0]++; next }
        next if $aa !~ /^[ACDEFGHIKLMNPQRSTVWY]/;
        $cnt[ ord($aa) - 64 ]++;
        $ttl++;
    }

    return wantarray ? ( 'X', 0 ) : 'X' unless $ttl;

    my $n;
    my $nmax = 0;
    my $imax = 0;
    for ( my $i = 0; $i <= 26; $i++ )
    {
        if ( ( $n = $cnt[$i] ) > $nmax ) { $nmax = $n; $imax = $i }
    }

    my $aa = $imax ? chr( $imax + 64 ) : '-';
    wantarray ? ( $aa, $nmax/$ttl ) : $aa;
}


#-------------------------------------------------------------------------------
#  Find the consensus nucleotide residue at specified alignment column.
#  For evaluating a whole alignment, this routine is much slower than
#  consensus_sequence_nt().
#
#       $residue              = consensus_nt_in_column( \@align, $column )
#     ( $residue, $fraction ) = consensus_nt_in_column( \@align, $column )
#
#       $residue              = consensus_nt_in_column( \@seqR, $column )
#     ( $residue, $fraction ) = consensus_nt_in_column( \@seqR, $column )
#
#  The first form takes a reference to an array of sequence triples, while
#  the second form takes a reference to an array of references to sequences.
#  Column numbers are 1-based.
#
#-------------------------------------------------------------------------------
sub consensus_nt_in_column
{
    my ( $align, $column ) = @_;
    my $are_seq_ref;
    my $len;
    if ( gjoseqlib::is_array_of_sequence_triples( $align ) )
    {
        $are_seq_ref = 0;
        $len = length( $align->[0]->[2] );
    }
    elsif ( $align && $align->[0] && ref( $align->[0] ) eq 'SCALAR' )
    {
        $are_seq_ref = 1;
        $len = length( ${$align->[0]} );
    }
    else
    {
        return wantarray ? () : undef;
    }
    return wantarray ? () : undef unless $column && $column > 0 && $column <= $len;

    my $offset = $column - 1;
    my @cnt = ( ( 0 ) x 5 );
    my $ttl = 0;
    foreach ( @$align )
    {
        my $nt = substr( $are_seq_ref ? $$_ : $_->[2], $offset, 1 ) || ' ';
        next unless $nt =~ tr/ACGTUacgtu/\001\002\003\004\004\001\002\003\004\004/;
        $cnt[ ord($nt) ]++;
        $ttl++;
    }

    return wantarray ? ( 'N', 0 ) : 'N' unless $ttl;

    my $n;
    my $nmax = 0;
    my $imax = 0;
    for ( my $i = 1; $i <= 4; $i++ )
    {
        if ( ( $n = $cnt[$i] ) > $nmax ) { $nmax = $n; $imax = $i }
    }

    my $nt = qw( A C G T )[$imax-1];

    wantarray ? ( $nt, $nmax/$ttl ) : $nt;
}


#===============================================================================
#  Do a bootstrap sample of columns from an alignment:
#
#    \@alignment = bootstrap_sample( \@alignment );
#===============================================================================

sub bootstrap_sample
{
    my ( $align0, $seed ) = @_;
    return undef if ( ! $align0 ) || ( ref( $align0 ) ne 'ARRAY' ) || ( ! @$align0 );
    my $len = length( $align0->[0]->[2] );
    return $align0 if $len < 2;
    my @cols = map { int( $len * rand() ) } ( 1 .. $len );
    my @align1;
    foreach ( @$align0 )
    {
        my $seq1 = $_->[2];
        my $seq2 = $seq1;
        for ( my $i = 0; $i < $len; $i++ )
        {
            substr( $seq2, $i, 1 ) = substr( $seq1, $cols[$i], 1 );
        }
        push @align1, [ @$_[0,1], $seq2 ];
    }

    return wantarray ? @align1 : \@align1;
}


sub max { $_[0] > $_[1] ? $_[0] : $_[1] }


1;
