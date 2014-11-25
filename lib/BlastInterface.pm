#
# Copyright (c) 2003-2014 University of Chicago and Fellowship
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

package BlastInterface;

# This is a SAS component.

use Carp;
use Data::Dumper;

use strict;
use SeedAware;
use gjoalignment;
use gjoseqlib;
use gjoparseblast;

#-------------------------------------------------------------------------------
#  This is a general interface to NCBI blastall.  It supports blastp,
#  blastn, blastx, and tblastn. The psiblast and rpsblast programs
#  from the blast+ package are also supported. 
#
#      @matches = blast( $query, $db, $blast_prog, \%options )
#     \@matches = blast( $query, $db, $blast_prog, \%options )
#
#  The first two arguments supply the query and db data.  These can be supplied
#  in any of several forms:
#
#      filename
#      existing blast database name (for db only)
#      open filehandle
#      sequence triple (i.e., [id, def, seq])
#      list of sequence triples
#      undef or '' -> read from STDIN
#
#  The third argument is the blast tool (blastp, blastn, blastx, tblastn, psiblast or rpsblast)
#
#  The fourth argument is an options hash. The available options have been
#  expanded to better match those of the new blast+ set of programs.
#
#     For binary flag values: F = no = 0; and T = yes = 1.
#     For query strand values: 1 = plus, 2 = minus and 3 = both.
#
#      asciiPSSM          => name of output file to store the ASCII version of PSSM
#      blastall           => attempt to use blastall program
#      blastplus          => attempt to use blast+ series of programs
#      caseFilter         => ignore lowercase query residues in scoring (T/F) [D = F]
#      db_gen_code        => genetic code for DB sequences [D = 1]
#      dbCode             => genetic code for DB sequences [D = 1]
#      dbGenCode          => genetic code for DB sequences [D = 1]
#      dbLen              => effective length of DB for computing E-values
#      dbsize             => effective length of DB for computing E-values
#      dbSize             => effective length of DB for computing E-values
#      dust               => define blastn filtering (yes, no or filter parameters)
#      evalue             => maximum E-value [D = 0.01]
#      excludeSelf        => suppress reporting matches of ID to itself (D = 0)
#      filtering_db       => database of sequences to filter from query (blastn)
#      filteringDB        => database of sequences to filter from query (blastn)
#      gapextend          => cost (>0) for extending a gap
#      gapExtend          => cost (>0) for extending a gap
#      gapopen            => cost (>0) for opening a gap
#      gapOpen            => cost (>0) for opening a gap
#      ignore_msa_master  => ignore the master sequence when psiblast creates PSSM (D = 0)
#      ignoreMaster       => ignore the master sequence when psiblast creates PSSM (D = 0)
#      in_msa             => multiple sequence alignment to be start psiblast; can be filename or list of sequence triples
#      in_pssm            => input checkpoint file for psiblast
#      includeSelf        => force reporting of matches of ID to itself (D = 1)
#      inclusion_ethresh  => e-value inclusion threshold for pairwise alignments in psiblast (D = 0.002)
#      inclusionEvalue    => e-value inclusion threshold for pairwise alignments in psiblast (D = 0.002)
#      inMSA              => multiple sequence alignment to be start psiblast; can be filename or list of sequence triples
#      inPHI              => filename containing pattern to search in psiblast
#      inPSSM             => input checkpoint file for psiblast
#      iterations         => number of psiblast iterations
#      lcase_masking      => ignore lowercase query residues in scoring (T/F) [D = F]
#      lcaseMasking       => ignore lowercase query residues in scoring (T/F) [D = F]
#      lcFilter           => low complexity query sequence filter setting (T/F) [D = T]
#      matrix             => amino acid comparison matrix [D = BLOSUM62]
#      max_intron_length  => maximum intron length in joining translated alignments
#      maxE               => maximum E-value [D = 0.01]
#      maxHSP             => maximum number of returned HSPs (before filtering)
#      maxIntronLength    => maximum intron length in joining translated alignments
#      minCovQ            => minimum fraction of query covered by match
#      minCovS            => minimum fraction of the DB sequence covered by the match
#      minIden            => fraction (0 to 1) that is a minimum required identity
#      minNBScr           => minimum normalized bit-score (bit-score per alignment position)
#      minPos             => fraction of aligned residues with positive score
#      minScr             => minimum required bit-score
#      msa_master_id      => ID of the sequence in in MSA for psiblast to use as a master
#      msa_master_idx     => 1-based index of the sequence in MSA for psiblast to use as a master
#      nucIdenScr         => score (>0) for identical nucleotides [D = 1]
#      nucMisScr          => score (<0) for non-identical nucleotides [D = -1]
#      num_alignments     => maximum number of returned HSPs (before filtering)
#      num_iterations     => number of psiblast iterations
#      num_threads        => number of threads that can be run in parallel
#      numAlignments      => maximum number of returned HSPs (before filtering)
#      numThreads         => number of threads that can be run in parallel
#      out_ascii_pssm     => name of output file to store the ASCII version of PSSM
#      out_pssm           => name of output file to store PSSM
#      outForm            => 'sim' => return Sim objects [D]; 'hsp' => return HSPs (as defined in gjoparseblast.pm)
#      outPSSM            => name of output file to store PSSM
#      penalty            => score (<0) for non-identical nucleotides [D = -1]
#      perc_identity      => minimum percent identity for blastn
#      percIdentity       => minimum percent identity for blastn
#      phi_pattern        => filename containing pattern to search in psiblast
#      pseudocount        => pseudo-count value used when constructing PSSM in psiblast
#      pseudoCount        => pseudo-count value used when constructing PSSM in psiblast
#      query_genetic_code => genetic code for query sequence [D = 1]
#      query_loc          => range of residues in the query to search (begin-end)
#      queryCode          => genetic code for query sequence [D = 1]
#      queryGeneticCode   => genetic code for query sequence [D = 1]
#      queryID            => ID of the sequence in in MSA for psiblast to use as a master
#      queryIndex         => 1-based index of the sequence in MSA for psiblast to use as a master
#      queryLoc           => range of residues in the query to search (begin-end)
#      reward             => score (>0) for identical nucleotides [D = 1]
#      save_dir           => Boolean that causes the scratch directory to be retained (good for debugging)
#      searchsp           => product of effective query and DB lengths for computing E-values
#      searchSp           => product of effective query and DB lengths for computing E-values
#      seg                => define protein sequence filtering (yes, no or filter parameters)
#      soft_masking       => only use masking to filter initial hits, not final matches
#      softMasking        => only use masking to filter initial hits, not final matches
#      strand             => query strand(s) to search: 1 (or plus), 2 (or minus), 3 (or both) [D = both]
#      threads            => number of threads that can be run in parallel
#      threshold          => minimum score included in word lookup table
#      tmp_dir            => $tmpD   # use $tmpD as the scratch directory
#      ungapped           => do not produce gapped blastn alignments
#      use_sw_tback       => do final blastp alignment with Smith-Waterman algorithm
#      warnings           => do not suppress warnings in stderr
#      word_size          => word size used for initiating matches
#      wordSize           => word size used for initiating matches
#      wordSz             => word size used for initiating matches
#      xdrop_final        => score drop permitted in final gapped alignment
#      xdrop_gap          => score drop permitted in initial gapped alignment
#      xdrop_ungap        => score drop permitted in initial ungapped alignment
#      xDropFinal         => score drop permitted in final gapped alignment
#      xDropGap           => score drop permitted in initial gapped alignment
#      xDropUngap         => score drop permitted in initial ungapped alignment
#
#  The following program-specific interfaces are also provided:
#
#      @matches =   blastn( $query, $db, \%options )
#     \@matches =   blastn( $query, $db, \%options )
#      @matches =   blastp( $query, $db, \%options )
#     \@matches =   blastp( $query, $db, \%options )
#      @matches =   blastx( $query, $db, \%options )
#     \@matches =   blastx( $query, $db, \%options )
#      @matches =  tblastn( $query, $db, \%options )
#     \@matches =  tblastn( $query, $db, \%options )
#      @matches = psiblast( $query, $db, \%options )
#     \@matches = psiblast( $query, $db, \%options )
#      @matches = rpsblast( $query, $db, \%options )
#     \@matches = rpsblast( $query, $db, \%options )
#
#-------------------------------------------------------------------------------
sub blast
{
    my( $query, $db, $blast_prog, $parms ) = @_;
 
    #  Life is easier without tests against undef

    $query      = ''      if ! defined $query;
    $db         = ''      if ! defined $db;
    $blast_prog = 'undef' if ! defined $blast_prog;
    $parms      = {}      if ! defined $parms || ref( $parms ) ne 'HASH';

    #  Have temporary directory ready in case we need it

    my( $tempD, $save_temp ) = &SeedAware::temporary_directory($parms);
    $parms->{tmp_dir}        = $tempD;

    #  These are the file names that will be handed to blastall

    my ( $queryF, $dbF );
    my $user_output = [];

    #  If both query and db are STDIN, we must unify them

    my $dbR = ( is_stdin( $query ) && is_stdin( $db ) ) ? \$queryF : \$db;

    #  Okay, let's work through the user-supplied data

    my %valid_tool = map { $_ => 1 } qw( blastn blastp blastx tblastn psiblast rpsblast );
    if ( ! $valid_tool{ lc $blast_prog } )
    {
        warn "BlastInterface::blast: invalid blast program '$blast_prog'.\n";
    }
    elsif ( $blast_prog ne 'psiblast'
         && ! ( $queryF = &get_query( $query, $tempD, $parms ) )
       # && ! ( print STDERR Dumper($queryF = &get_query( $query, $tempD, $parms )) )
          ) 
    {
        warn "BlastInterface::get_query: failed to get query sequence data.\n";
    }
    elsif ( $blast_prog eq 'psiblast'
         && $query
         && ! ( ( $queryF, $parms ) = &psiblast_in_msa( $query, $parms ) )[0]
       # && ! ( print STDERR Dumper(( $queryF, $parms ) = &psiblast_in_msa( $query, $parms )) )[0]
          )
    {
        warn "BlastInterface::psiblast_in_msa: failed to get query msa data.\n";
    }
    elsif (
            ! ( $dbF = &get_db( $$dbR, $blast_prog, $tempD, $parms ) )
       #    ! ( print STDERR Dumper($dbF = &get_db( $$dbR, $blast_prog, $tempD, $parms )) )
          )
    {
        warn "BlastInterface::get_db: failed to get database sequence data.\n";
    }
    elsif ( ! ( $user_output = &run_blast( $queryF, $dbF, $blast_prog, $parms ) ) )
    {
        warn "BlastInterface::blast: failed to run blastall.\n";
        $user_output = [];
    }

    if (! $save_temp)
    {
        delete $parms->{tmp_dir};
        system( "rm", "-fr", $tempD );
    }

    return wantarray ? @$user_output : $user_output;
}


sub    blastn { &blast( $_[0], $_[1],    'blastn', $_[2] ) }
sub    blastp { &blast( $_[0], $_[1],    'blastp', $_[2] ) }
sub    blastx { &blast( $_[0], $_[1],    'blastx', $_[2] ) }
sub   tblastn { &blast( $_[0], $_[1],   'tblastn', $_[2] ) }
sub psiblast  { &blast( $_[0], $_[1],  'psiblast', $_[2] ) }
sub rpsblast  { &blast( $_[0], $_[1],  'rpsblast', $_[2] ) }


#-------------------------------------------------------------------------------
#  Convert a multiple sequence alignment into a PSSM file suitable for the
#  -in_pssm parameter of psiblast, or the input file list of build_rps_db.
#  (Note: the psiblast -in_msa option takes the name of a fasta alignment
#  file, not a pssm file.)
#
#      $db_name = alignment_to_pssm(  $align_file, \%options )
#      $db_name = alignment_to_pssm( \@alignment,  \%options )
#      $db_name = alignment_to_pssm( \*ALIGN_FH,   \%options )
#
#  The first argument supplies the MSA to be converted. It can be a list of
#  sequence triple, a file name, or an open file handle.
#
#  General options:
#
#    out_pssm =>  $file   #  output PSSM filename or handle (D = STDOUT)
#    outPSSM  =>  $file   #  output PSSM filename or handle (D = STDOUT)
#    title    =>  $title  #  title of the PSSM (D = "untitled_$i")
#
#  In addition, alignment_to_pssm takes all of the options of psiblast_in_msa
#  (see below)
#
#-------------------------------------------------------------------------------

#  Keep a counter for untitled PSSMs, so that they get unique names.

my $n_pssm = 0;

sub alignment_to_pssm
{
    my ( $align, $opts ) = @_;
    $opts = {}  unless $opts && ( ref( $opts ) eq 'HASH' );

    my ( $alignF, $opts2, $rm_alignF ) = psiblast_in_msa( $align, $opts );

    my $subject = [ 'subject', '', 'MKLYNLKDHNEQVSFAQAVTQGLGKNQGLFFPHDLPEFSLTEIDEMLKLDFVTRSAKILS' ]; 

    my ( $fh, $subjectF ) = SeedAware::open_tmp_file( 'alignment_to_pssm_subject', 'fasta' );
    gjoseqlib::write_fasta( $fh, $subject );
    close( $fh );

    my $pssm0F;
    ( $fh, $pssm0F ) = SeedAware::open_tmp_file( 'alignment_to_pssm', 'pssm0' );
    close( $fh );
    
    my $prog = SeedAware::executable_for( 'psiblast' )
        or warn "BlastInterface::alignment_to_pssm: psiblast program not found.\n"
            and return undef;

    my @args = ( -in_msa   => $alignF,
                 -subject  => $subjectF,
                 -out_pssm => $pssm0F
               );

    my $msa_master_idx = $opts2->{ msa_master_idx };
    push @args, -msa_master_idx    => $msa_master_idx  if $msa_master_idx > 1;
    push @args, -ignore_msa_master => ()               if $opts2->{ ignore_master };

    my $rc = SeedAware::system_with_redirect( $prog, @args, { stdout => '/dev/null', stderr => '/dev/null' } );
    if ( $rc != 0 )
    {
        my $cmd = join( ' ', $prog, @args );
        warn "BlastInterface::alignment_to_pssm: psiblast failed with rc = $rc: $cmd\n";
        return undef;
    }

    unlink $alignF if $rm_alignF;
    unlink $subjectF;

    #  Edit the raw PSSM file:

    my $title = $opts->{ title } || ( 'untitled_' . ++$n_pssm );

    my $close;
    my $pssmF = $opts->{ outPSSM } || $opts->{ out_pssm };

    ( $fh, $close ) = output_file_handle( $pssmF );
    
    my $skip;
    open( PSSM0, "<", $pssm0F ) or die "Could not open $pssm0F";
    while ( <PSSM0> )
    {
        if ( /inst \{/ ) {
            print $fh "      descr {\n";
            print $fh "        title \"$title\"\n";
            print $fh "      },\n";
        }            
        $skip = 1 if /intermediateData \{/;
        $skip = 0 if /finalData \{/;
        print $fh $_ unless $skip;
    }
    close( PSSM0 );
    close $fh if $close;

    unlink $pssm0F;

    $close ? $pssmF : 1;
}


#-------------------------------------------------------------------------------
#  Fix a multiple sequence alignment to be appropriate for a psiblast
#  -in_msa file.
#
#      ( $msa_name, \%opts, $rm_msa ) = psiblast_in_msa(  $align_file, \%opts )
#      ( $msa_name, \%opts, $rm_msa ) = psiblast_in_msa( \@alignment,  \%opts )
#      ( $msa_name, \%opts, $rm_msa ) = psiblast_in_msa( \*ALIGN_FH,   \%opts )
#
#  The scalar context form below should generally not be used because the output
#  options hash supplied in list context many include important modifications
#  to those supplied by the user.
#
#        $msa_name                    = psiblast_in_msa(  $align_file, \%opts )
#        $msa_name                    = psiblast_in_msa( \@alignment,  \%opts )
#        $msa_name                    = psiblast_in_msa( \*ALIGN_FH,   \%opts )
#
#  The first argument supplies the MSA to be fixed. It can be a list of
#  sequence triples, a file name, or an open file handle. Note that the
#  output options might be modified relative to that input (it is a copy;
#  the user-supplied options hash will not be modified). The value of
#  $rm_msa will be 1 if the msa is written to a new (temporary) file.
#
#  General options:
#
#    tmp_dir => $dir            #  directory for output file
#
#  Sequence filtering options:
#
#    keep    => \@ids           #  ids of sequences to keep in the MSA, regardless
#                               #      of similarity filtering.
#    max_sim =>  $fract         #  maximum identity of sequences in profile; i.e., build
#                               #      the PSSM from a representative set (D = no_limit).
#                               #      This can take a significant amount of time.
#    min_sim =>  $min_sim_spec  #  exclude sequences with less than the specified identity 
#                               #      to all specified sequences (D = no_limit).
#
#  The minimum similarity specification is one of:
#
#    $min_sim_spec = [ $min_ident,  @ref_ids ]
#    $min_sim_spec = [ $min_ident, \@ref_ids ]
#
#
#  Master sequence options:
#
#    ignore_msa_master => $bool   #  do not include the master sequence in the PSSM (D = 0)
#    ignoreMaster      => $bool   #  do not include the master sequence in the PSSM (D = 0)
#    msa_master_id     => $id     #  ID of the sequence to use as a master (D is first in align)
#    msa_master_idx    => $int    #  1-based index of the sequence to use as a master (D = 1)
#    pseudo_master     => $bool   #  add a master sequence covering all columns in the MSA (D = 0)
#    pseudoMaster      => $bool   #  add a master sequence covering all columns in the MSA (D = 0)
#
#  Master sequence notes:
#
#    A psiblast PSSM is a query for a database search. The search output
#    alignments are shown against the "msa_master" sequence, which defaults
#    to the first sequence in the alignment supplied. The PSSM only includes
#    alignment columns that are in the master sequence, so the reported
#    match statistics (E-value, identity, positives, and gaps) and the
#    alignment are all evaluated relative to the master sequence. For this
#    reason, we provide a 'pseudo_master' option that adds a master sequence
#    that is the plurality residue type in every column of the alignment.
#    Thus, PSSM and the output alignments will reflect all columns in the
#    original alignment, but the query sequence shown is unlikely to
#    correspond to any of the input sequences. If this option is chosen,
#    ignore_msa_master is set to true, so that the consensus is not included
#    in the calculation of the PSSM. Any msa_master_id or msa_master_idx option
#    value will be ignored.
#
#-------------------------------------------------------------------------------
sub psiblast_in_msa
{
    my ( $align, $opts ) = @_;
    $opts = {}  unless $opts && ( ref( $opts ) eq 'HASH' );

    my $ignore_master  = $opts->{ ignore_msa_master } || $opts->{ ignoreMaster };
    my $pseudo_master  = $opts->{ pseudo_master }     || $opts->{ pseudoMaster };
    my $msa_master_id  = $opts->{ msa_master_id };
    my $msa_master_idx = $opts->{ msa_master_idx }    || 0;
    my $max_sim        = $opts->{ max_sim };
    my $min_opt        = $opts->{ min_sim };

    my %strip = map { $_ => 1 } qw( ignore_msa_master ignoreMaster
                                    pseudo_master pseudoMaster
                                    msa_master_id msa_master_idx
                                    max_sim
                                    min_sim
                                  );

    my $opts2 = { map { ! $strip{$_} ? ( $_ => $opts->{$_} ) : () } keys %$opts };

    my ( $min_sim, @ref_ids );
    if ( $min_opt && ( ref($min_opt) eq 'ARRAY' ) && @$min_opt > 1 )
    {
        ( $min_sim, @ref_ids ) = @$min_opt;
        @ref_ids = @{$ref_ids[0]} if ( ( @ref_ids == 1 ) && ( ref( $ref_ids[0] ) eq 'ARRAY' ) )
    }

    my $alignF;
    my $write_file;

    my $is_array = gjoseqlib::is_array_of_sequence_triples( $align );
    my $is_glob  = $align && ref( $align ) eq 'GLOB';

    if ( $is_array || $is_glob
                   || $msa_master_id
                   || $max_sim
                   || $min_sim
                   || $pseudo_master
                   || ( $msa_master_idx > 1 && $ignore_master )
       )
    {
        my @align;

        if ( $is_array )
        {
            @align = @$align;
            $write_file = 1;
        }
        elsif ( $is_glob )
        {
            @align = gjoseqlib::read_fasta( $align );
            $write_file = 1;
        }
        elsif ( $align && ! ref( $align ) && -s $align )
        {
            @align  = gjoseqlib::read_fasta( $align );
            $alignF = $align;
        }

        @align
            or warn "BlastInterface::psiblast_in_msa: No alignment supplied."
                and return undef;

        $msa_master_id ||= $align[ $msa_master_idx - 1 ]->[0] if $msa_master_idx;

        my @keep = ();
        push @keep, $msa_master_id if $msa_master_id;

        my $keep = $opts->{ keep };
        if ( $keep )
        {
            push @keep, ( ref( $keep ) eq 'ARRAY' ? @$keep : $keep );
        }

        my $n_seq = @align;
        if ( $max_sim )
        {
            my %rep_opts = ( max_sim => $max_sim );

            $rep_opts{ keep }    = \@keep    if @keep;
            $rep_opts{ min_sim } =  $min_sim if $min_sim;

            @align = gjoalignment::representative_alignment( \@align, \%rep_opts );
        }
        elsif ( $min_sim )
        {
            my %keep = map { $_ => 1 } @keep;
            foreach ( gjoalignment::filter_by_similarity( \@align, $min_sim, @ref_ids ) )
            {
                $keep{ $_->[0] } = 1;
            }
            @align = grep { $keep{ $_->[0] } } @align;
            @align = gjoseqlib::pack_alignment( \@align ) if @align < $n_seq;
        }

        $write_file ||= ( @align < $n_seq );

        if ( $pseudo_master )
        {
            my $master = gjoalignment::consensus_sequence( \@align );
            unshift @align, [ 'consensus', '', $master ];
            $write_file     = 1;
            $msa_master_id  = 'consensus';
            $msa_master_idx = 1;
            $ignore_master  = 1;
        }

        if ( $msa_master_id && ! $msa_master_idx )
        {
            for ( my $i = 0; $i < @align; $i++ )
            {
                next unless $msa_master_id eq $align[$i]->[0];
                $msa_master_idx = $i + 1;
                last;
            }
            $msa_master_idx
                or warn "BlastInterface::psiblast_in_msa: msa_master_id '$msa_master_id' not found in alignment.";
        }

        #  In psiblast 2.2.29+ command flags -ignore_master and
        #  -msa_master_idx are imcompatible, so we move the master
        #  sequence to be sequence 1 (the default master sequence).

        if ( $ignore_master && $msa_master_idx > 1 )
        {
            my $master = splice( @align, $msa_master_idx-1, 1 );
            unshift @align, $master;
            $msa_master_idx = 1; 
            $write_file     = 1;
        }

        if ( $write_file )
        {
            my $fh;
            my @dir = $opts->{ tmp_dir } ? ( $opts->{ tmp_dir } ) : ();
            ( $fh, $alignF ) = SeedAware::open_tmp_file( 'psiblast_in_msa', 'fasta', @dir );
            gjoseqlib::write_fasta( $fh, \@align );
            close( $fh );
        } 

        $opts2->{ in_msa }            = $alignF          if $alignF;
        $opts2->{ ignore_msa_master } = 1                if $ignore_master;
        $opts2->{ msa_master_idx }    = $msa_master_idx  if $msa_master_idx > 1;
    }

    wantarray ? ( $alignF, $opts2, $write_file ) : $alignF;
}


#-------------------------------------------------------------------------------
#  Build an RPS database from a list of alignments and/or alignment files
#
#      $db_file = build_rps_db( \@aligns, \%options )
#
#  The first argument supplies the list of alignments and/or alignment files. 
#
#  Three forms of alignments are supported:
#
#       [ [ 'alignment-id', 'optional title', [ @seqs1 ] ], ... ]
#       [ [ 'alignment-id', 'optional title', 'align1.fa' ], ... ];
#       [ 'align1.pssm', ... ];
#
# 
#  Options:
# 
#      title => DB title
#
#-------------------------------------------------------------------------------

sub build_rps_db
{
    my ( $aligns, $db, $opts ) = @_;
    
    return '' unless $aligns && ref( $aligns ) eq 'ARRAY' && @$aligns;
    return '' unless defined( $db ) && ! ref( $db ) && $db ne '';
    $opts = {} unless $opts && ref( $opts ) eq 'HASH';

    my @pssms;
    my %title_to_pssm;
    foreach ( @$aligns )
    {
        my $pssm = verify_pssm( $_ , \%title_to_pssm, $opts )
            or next;
        
        push @pssms, $pssm;
    }
    @pssms
        or warn "BlastInterface::build_rps_db: no valid pssm found.\n"
            and return '';

    open( DB, ">", $db ) or die "Could not open '$db'.\n";
    print DB map { $_ . "\n" } @pssms;
    close( DB );

    #  makeprofiledb (v2.2.29+) works, but only supports numerical subject IDs
    #  (v2.2.27+ does not work). The subject IDs need to be provided in the id
    #  field.
    #
    # my $prog_name = 'makeprofiledb';
    # my @args = ( -in => $db );
    #
    #  formatrpsdb (v2.2.26) supports text subject IDs given in the title
    #  "subject_id" field.

    my $prog_name = 'formatrpsdb';
    my $title = $opts->{ title } || 'Untitled RPS DB';
    my @args = ( -i => $db, -t => $title );

    my $prog = SeedAware::executable_for( $prog_name );

    if ( ! $prog )
    {
        warn "BlastInterface::build_rps_db: $prog_name program not found.\n";
        return '';
    }
    
    my $rc = SeedAware::system_with_redirect( $prog, @args );
    if ( $rc != 0 )
    {
        my $cmd = join( ' ', $prog, @args );
        warn "BlastInterface::build_rps_db: $prog_name failed with rc = $rc: $cmd\n";
        return '';
    }
    
    return $db;
}


sub verify_pssm
{
    my ( $align, $title_to_pssm, $opts ) = @_;

    $align
        or warn "BlastInterface::verify_pssm: invalid alignment"
            and return undef;

    $title_to_pssm && ref($title_to_pssm) eq 'HASH'
        or warn "BlastInterface::verify_pssm: invalid title hash"
            and return undef;

    $opts = {} unless $opts && ref($opts) eq 'HASH';

    my $title;
    my $pssm;

    if ( ! ref( $align ) )
    {
        $title = pssm_title( $align );
        
        if ( ! ( defined $title && length( $title ) ) )
        {
            $align ||= 'undefined';
            warn "BlastInterface::verify_pssm: failed for alignment '$align'."
                and return undef;
        }

        $pssm = $align;
    }
    elsif ( ref( $align ) eq 'ARRAY' && @$align == 3 )
    {
        my ( $id, $desc, $data ) = @$align;
        defined( $id ) && length( $id ) && $data
            or warn "BlastInterface::verify_pssm: invalid alignment definition"
                and return undef;

        $title = $id;
        $title .= " $desc" if $desc;
        $title =~ s/\s+/_/g;    # rpsblast+ only returns the first word in outfmt 6

        if ( gjoseqlib::is_array_of_sequence_triples( $data )
             || ( ! ref( $data ) && -s $data )
           )
        {
            my ( $fh, $path_name ) = SeedAware::open_tmp_file( "verify_pssm", "pssm" );
            
            my %parms = %$opts;
            $parms{ title } = $title;
            $parms{ out_pssm } = $fh;

            alignment_to_pssm( $data, \%parms );

            $pssm = $path_name;
        }
        else 
        {
            warn "BlastInterface::verify_pssm: invalid alignment definition data"
                and return undef;
        }
    
    }
    else
    {    
        warn "BlastInterface::verify_pssm: invalid alignment structure"
            and return undef;
    }

    # check if title is seen before
    if ( $title_to_pssm->{ $title } )
    {
        warn "BlastInterface::verify_pssm: duplicated title '$title' in '$pssm'"
            and return undef;
    }

    $title_to_pssm->{ $title } = $pssm;

    return $pssm;
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  Read the title from a PSSM file.
#
#    $title = pssm_title( $pssm_file, \%opts )
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub pssm_title
{
    my ( $pssm, $opts ) = @_;
    my $title;

    if ( $pssm && -s $pssm && open( PSSM, '<', $pssm ) )
    {
        while ( <PSSM> )
        {
            if (/\btitle\s+"(.*)"/)
            {
                $title = $1;
                last;
            }
        }
        close( PSSM );
    }

    return $title;
}


#-------------------------------------------------------------------------------
#  Do psiblast against tranlated genomic DNA. Most of this can be done by
#  psiblast( $profile, $db, \%options ).
#
#   $records = psi_tblastn(  $prof_file,  $nt_file, \%options )
#   $records = psi_tblastn(  $prof_file, \@nt_seq,  \%options )
#   $records = psi_tblastn( \@prof_seq,   $nt_file, \%options )
#   $records = psi_tblastn( \@prof_seq,  \@nt_seq,  \%options )
#
#  Required:
#
#     $prof_file or \@prof_seq
#     $nt_file   or \@nt_seq
#
#  Options unique to psi_tblastn:
#
#     aa_db  =>  $trans_file    # put translated db here
#
#-------------------------------------------------------------------------------

sub psi_tblastn
{
    my ( $profile, $nt_db, $opts ) = @_;
    $opts ||= {};

    my $aa_db = $opts->{ aa_db };
    my $rm_db  = ! ( $aa_db && -f $aa_db );
    if ( defined $aa_db && -f $aa_db && -s $aa_db )
    {
        #  The translated sequence database exists
    }
    elsif ( defined $nt_db )
    {
        if ( ref $nt_db eq 'ARRAY' && @$nt_db )
        {
            ref $nt_db eq 'ARRAY' && @$nt_db
                or print STDERR "Bad nucleotide sequence reference passed to psi_tblastn.\n"
                    and return undef;
            my $dbfh;
            if ( $aa_db )
            {
                open( $dbfh, '>', $aa_db );
            }
            else
            {
                ( $dbfh, $aa_db ) = SeedAware::open_tmp_file( "psi_tblastn_db", '' );
                $opts->{ aa_db }  = $aa_db;
            }
            $dbfh or print STDERR 'Could not open $dbfile.'
                and return undef;
            foreach ( @$nt_db )
            {
                gjoseqlib::write_fasta( $dbfh, six_translations( $_ ) );
            }
            close( $dbfh );
        }
        elsif ( -f $nt_db && -s $nt_db )
        {
            my $dbfh;
            ( $dbfh, $aa_db ) = SeedAware::open_tmp_file( "psi_tblastn_db", '' );
            close( $dbfh );   # Tacky, but it avoids the warning

            my $redir = { 'stdin'  => $nt_db,
                          'stdout' => $aa_db
                        };
            my $gencode = $opts->{ dbCode }
                       || $opts->{ dbGenCode }
                       || $opts->{ db_gen_code };
            SeedAware::system_with_redirect( 'translate_fasta_6',
                                             $gencode ? ( -g => $gencode ) : (),
                                             $redir
                                           );
        }
        else
        {
            print STDERR "psi_tblastn requires a sequence database."
                and return undef;
        }
    }
    else
    {
        die "psi_tblastn requires a sequence database.";
    }

    my $blast_opts = { %$opts, outForm => 'hsp' };
    my @hsps = blast( $profile, $nt_db, $blast_opts );

    if ( $rm_db )
    {
        my @files = grep { -f $_ } map { ( $_, "$_.psq", "$_.pin", "$_.phr" ) } $aa_db;
        unlink @files if @files;
    }

    #  Fix the data "in place"

    foreach ( @hsps )
    {
        my ( $sid, $sdef ) = @$_[3,4];
        my $fr;
        ( $sid, $fr ) = $sid =~ m/^(.*)\.([-+]\d)$/;
        my ( $beg, $end, $slen ) = $sdef =~ m/(\d+)-(\d+)\/(\d+)$/;
        $sdef =~ s/ ?\S+$//;
        @$_[3,4,5] = ( $sid, $sdef, $slen );
        adjust_hsp( $_, $fr, $beg );
    }

    @hsps = sort { $a->[3] cmp $b->[3] || $b->[6] <=> $a->[6] } @hsps;

    if ( $opts->{ outForm } ne 'hsp' )
    {
        @hsps = map { format_hsp( $_, 'psi_tblastn', $opts ) } @hsps;
    }

    wantarray ? @hsps : \@hsps;
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  When search is versus six frame translation, there is a need to adjust
#  the frame and location information in the hsp back to the DNA coordinates.
#
#     adjust_hsp( $hsp, $frame, $begin )
#
#   6   7    8    9    10  11   12   13  14 15 16  17  18 19  20
#  scr Eval nseg Eval naln nid npos ngap fr q1 q2 qseq s1 s2 sseq
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub adjust_hsp
{
    my ( $hsp, $fr, $b ) = @_;
    $hsp->[14] = $fr;
    if ( $fr > 0 )
    {
        $hsp->[18] = $b + 3 * ( $hsp->[18] - 1 );
        $hsp->[19] = $b + 3 * ( $hsp->[19] - 1 ) + 2;
    }
    else
    {
        $hsp->[18] = $b - 3 * ( $hsp->[18] - 1 );
        $hsp->[19] = $b - 3 * ( $hsp->[19] - 1 ) - 2;
    }
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  Do a six frame translation for use by psi_tblastn.  These modifications of
#  the identifiers and definitions are essential to the interpretation of
#  the blast results.  The program 'translate_fasta_6' produces the same
#  output format, and is much faster.
#
#   @translations = six_translations( $nucleotide_entry )
#
#  The ids are modified by adding ".frame" (+1, +2, +3, -1, -2, -3).
#  The definition is modified by adding " begin-end/of_length".
#  NCBI reverse strand translation frames count from the end of the
#  sequence (i.e., the beginning of the complement of the strand).
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub six_translations
{
    my ( $id, $def, $seq ) = map { defined($_) ? $_ : '' } @{ $_[0] };
    my $l = length( $seq );

    return () if $l < 15;

    #                    fr   beg    end
    my @intervals = ( [ '+1',  1,   $l - (  $l    % 3 ) ],
                      [ '+2',  2,   $l - ( ($l-1) % 3 ) ],
                      [ '+3',  3,   $l - ( ($l-2) % 3 ) ],
                      [ '-1', $l,    1 + (  $l    % 3 ) ],
                      [ '-2', $l-1,  1 + ( ($l-1) % 3 ) ],
                      [ '-3', $l-2,  1 + ( ($l-2) % 3 ) ]
                    );
    my ( $fr, $b, $e );

    map { ( $fr, $b, $e ) = @$_;
          [ "$id.$fr",
            "$def $b-$e/$l",
            gjoseqlib::translate_seq( gjoseqlib::DNA_subseq( \$seq, $b, $e ) )
          ]
        } @intervals;
}


#-------------------------------------------------------------------------------
#  Determine whether a user-supplied parameter will result in reading from STDIN
#
#      $bool = is_stdin( $source )
#
#  For our purposes, undef, '', *STDIN and \*STDIN are all STDIN.
#  There might be more.
#-------------------------------------------------------------------------------
sub is_stdin
{ 
    return ( ! defined $_[0] )
        || ( $_[0] eq '' )
        || ( $_[0] eq \*STDIN )   # Stringifies to GLOB(0x....)
        || ( $_[0] eq  *STDIN )   # Stringifies to *main::STDIN
}


#-------------------------------------------------------------------------------
#  Process the query source request, returning the name of a fasta file
#  with the data.
#
#      $filename = get_query( $query_request, $tempD, \%options )
#
#  Options: none are currently used
#
#  If the data are already in a file, that file name is returned. Otherwise
#  the data are read into a file in the directory $tempD.
#-------------------------------------------------------------------------------
sub get_query
{
    my( $query, $tempD, $parms ) = @_;
#   returns query-file

    &valid_fasta( $query, "$tempD/query" );
}


#-------------------------------------------------------------------------------
#  Process the database source request, returning the name of a formatted
#  blast database with the data.
#
#      $dbname = get_db( $db_request, $blast_prog, $tempD )
#
#  Options: none are currently used
#
#  If the data are already in a database, that name is returned. If the
#  data are in a file that is in writable directory, the database is built
#  there and the name is returned. Otherwise the data are read into a file
#  in the directory $tempD and the database is built there.
#-------------------------------------------------------------------------------
sub get_db
{
    my( $db, $blast_prog, $tempD, $parms ) = @_;
#   returns db-file

    #  It should be possible to pass in a database without a fasta file,
    #  a case that valid_fasta() cannot handle.

    my $seq_type = ( ($blast_prog eq 'blastp')
                  || ($blast_prog eq 'blastx')
                  || ($blast_prog eq 'psiblast')
                   ) ? 'P' : 'N' ;
    return $db if check_db( $db, $seq_type );

    #  This is not an existing database, figure out what we have been handed ...

    my $dbF = &valid_fasta( $db, "$tempD/db" );

    #  ... and build a blast database for it.

    return &verify_db( $dbF, $seq_type, $tempD );
}


#-------------------------------------------------------------------------------
#  Return a fasta file name for data supplied in any of the supported formats.
#
#      $file_name = valid_fasta( $seq_source, $temp_file )
#
#  If supplied with a filename, return that. Otherwise determine the nature of
#  the data, write it to $tmp_file, and return that name.
#
#  In psiblast, query might be a pssm file, an alignment file, or an alignment.
#-------------------------------------------------------------------------------
sub valid_fasta
{
    my( $seq_src, $tmp_file ) = @_;
    my $out_file;

    #  If we have a filename, leave the data where they are

    if ( defined($seq_src) && (! ref($seq_src)) && ($seq_src ne '') )
    {
        if (-s $seq_src)
        {
            $out_file = $seq_src;
        }
    }

    #  Other sources need to be written to the file name supplied

    else
    {
        my $data;

        # Literal sequence data?

        if ( $seq_src && ( ref($seq_src) eq 'ARRAY' ) )
        {
            #  An array of sequences?
            if ( @$seq_src
               && $seq_src->[0]
               && (ref($seq_src->[0]) eq 'ARRAY')
               )
            {
                $data = $seq_src;
            }

            #  A single sequence triple?
            elsif ( @$seq_src == 3          # three elements
                  && $seq_src->[0]          # first element defined
                  && ! ref($seq_src->[0])   # first element not a reference
                  && $seq_src->[2]          # third element defined
                  )
            {
                $data = [$seq_src];  # Nesting is unnecessary, but is consistent
            }
        }

        #  read_fasta will read from STDIN, a filehandle, or a reference to a string

        elsif ((! $seq_src) || (ref($seq_src) eq 'GLOB') || (ref($seq_src) eq 'SCALAR'))
        {
            $data = &gjoseqlib::read_fasta($seq_src);
        }

        #  If we got data, write it to the file

        if ($data && (@$data > 0))
        {
            $out_file = $tmp_file;
            &gjoseqlib::write_fasta( $out_file, $data );
        }
    }

    $out_file;
}


#-------------------------------------------------------------------------------
#  Determine whether a formatted blast database exists, and (when the source
#  sequence file exists) that the database is up-to-date. This function is
#  broken out of verify_db to support checking for databases without a
#  sequence file.
#
#      $okay = check_db( $db, $seq_type )
#      $okay = check_db( $db )                 # assumes seq_type is protein
#
#  Parameters:
#
#      $db       - file path to the data, or root name for an existing database
#      $seq_type - begins with 'P' for protein data [D], or 'N' for nucleotide
#
#-------------------------------------------------------------------------------
sub check_db
{
    my ( $db, $seq_type ) = @_;

    #  Need a valid name

    return '' unless ( defined( $db ) && ! ref( $db ) && $db ne '' );

    my $suf = ( ! $seq_type || ( $seq_type =~ m/^p/i ) ) ? 'psq' : 'nsq';

    #         db exists        and, no source data or db is up-to-date
    return ( (-s "$db.$suf")    && ( (! -f $db) || (-M "$db.$suf"    <= -M $db) ) )
        || ( (-s "$db.00.$suf") && ( (! -f $db) || (-M "$db.00.$suf" <= -M $db) ) );
}


#-------------------------------------------------------------------------------
#  Verify that a formatted blast database exists and is up-to-date, otherwise
#  create it. Return the db name, or empty string upon failure.
#
#      $db = verify_db( $db                               )  # Protein assumed
#      $db = verify_db( $db,                    \%options )  # Protein assumed
#      $db = verify_db( $db, $seq_type                    )  # Use specified type
#      $db = verify_db( $db, $seq_type,         \%options )  # Use specified type
#      $db = verify_db( $db, $seq_type, $tempD            )  # Move to tempD, if necessary
#      $db = verify_db( $db, $seq_type, $tempD, \%options )  # Move to tempD, if necessary
#
#  Parameters:
#
#      $db       - file path to the data, or root name for an existing database
#      $seq_type - begins with 'P' or 'p' for protein data, or with 'N' or 'n'
#                  for nucleotide [Default = P]
#      $tempD    - if the db directory is unwritable, build the database here
#
#  Options:
#
#      tmp_dir => $tempD   # the temporary directory of the database
#
#  If the datafile is readable, but is in a directory that is not writable, we
#  copy it to $tempD or $options->{tmp_dir} and try to build the blast database
#  there. If these are not available, it is built in SeedAware::
#-------------------------------------------------------------------------------
sub verify_db
{
    #  Allow a hash at the end of the parameters

    my $opts = ( $_[-1] && ( ref( $_[-1] ) eq 'HASH') ) ? pop @_ : {};

    #  Get the rest of the parameters

    my ( $db, $seq_type, $tempD ) = @_;

    #  Need a valid name

    return '' unless defined( $db ) && ! ref( $db ) && $db ne '';

    #  If the database is already okay, we are done

    $seq_type ||= 'P';  #  Default to protein sequence

    return $db if &check_db( $db, $seq_type );

    #  To build the database we need data

    return '' unless -s $db;

    #  We need to format the database. Figure out if the db directory is
    #  writable, otherwise make a copy in a temporary location:

    my $dir = eval { require File::Basename; } ? File::Basename::dirname( $db )
            : ( $db =~ m#^(.*[/\\])[^/\\]+$# ) ? $1 : '.';
    if ( ! -w $dir )
    {
        $tempD ||= $opts->{ tmp_dir } || SeedAware::tmp_file_name( 'tmp_blast_db' );

        mkdir $tempD if $tempD && ! -d $tempD && ! -e $tempD;
        if ( ! $tempD || ! -d $tempD || ! -w $tempD )
        {
            warn "BlastInterface::verify_db: failed to locate or make a writeable directory for blast database.\n";
            return '';
        }

        my $newdb = "$tempD/db";
        if ( system( 'cp', $db, $newdb ) )  # I would prefer /bin/cp, but ...
        {
            warn "BlastInterface::verify_db: failed to copy database file to a new location.\n";
            return '';
        }

        #  This is just an informative message. If permissions are set correctly, it
        #  should never occur, but ....
        print STDERR "BlastInterface::verify_db: Database '$db' copied to '$newdb'.\n";

        $db = $newdb;
    }

    #  Assemble the necessary data for format db

    my $is_prot = ( $seq_type =~ m/^p/i ) ? 'T' : 'F';
    my @args = ( -p => $is_prot,
                 -i => $db
               );

    #  Find formatdb appropriate for the excecution environemnt.

    my $prog = SeedAware::executable_for( 'formatdb' );
    if ( ! $prog )
    {
        warn "BlastInterface::verify_db: formatdb program not found.\n";
        return '';
    }

    #  Run formatdb, redirecting the annoying messages about unusual residues.

    my $rc = SeedAware::system_with_redirect( $prog, @args, { stderr => '/dev/null' } );
    if ( $rc != 0 )
    {
        my $cmd = join( ' ', $prog, @args );
        warn "BlastInterface::verify_db: formatdb failed with rc = $rc: $cmd\n";
        return '';
    }

    return $db;
}


#-------------------------------------------------------------------------------
#  Given that we can end up with a temporary blast database, provide a method
#  to remove it.
#
#      remove_blast_db_dir( $db )
#
#  Typical usage would be:
#
#      my @out;
#      my $db = BlastInterface::verify_db( $file, ... );
#      if ( $db )
#      {
#          @out = BlastInterface::blast( $query, $db, 'blastp', ... );
#          BlastInterface::remove_blast_db_dir( $db ) if $db ne $file;
#      }
#
#  We need to be stringent. The database must be named db, in a directory
#  tmp_blast_db_..., and which contains only files db and db\..+ . 
#-------------------------------------------------------------------------------
sub remove_blast_db_dir
{
    my ( $db ) = @_;
    return unless $db && -f $db && $db =~ m#^((.*[/\\])tmp_blast_db_[^/\\]+)[/\\]db$#;
    my $tempD = $1;
    return if ! -d $tempD;
    opendir( DIR, $tempD );
    my @bad = grep { ! ( /^db$/ || /^db\../ || /^\.\.?$/ ) } readdir( DIR );
    close DIR;
    return if @bad;

    ! system( 'rm', '-r', $tempD );
}


#-------------------------------------------------------------------------------
#  Run blastall, and deal with the results.
#
#      $bool = run_blast( $queryF, $dbF, $blast_prog, \%options )
#
#-------------------------------------------------------------------------------
sub run_blast
{
    my( $queryF, $dbF, $blast_prog, $parms ) = @_;

    if ( lc ( $parms->{outForm} || '' ) ne 'hsp' )
    {
        eval { require Sim; }
            or print STDERR "Failed in require Sim. Consider using outForm => 'hsp'.\n"
                and return wantarray ? () : [];
    }

    my $cmd   = &form_blast_command( $queryF, $dbF, $blast_prog, $parms )
        or warn "BlastInterface::run_blast: Failed to create a blast command."
            and return wantarray ? () : [];
    my $redir = { $parms->{ warnings } ? () : ( stderr => "/dev/null" ) };
    my $fh    = &SeedAware::read_from_pipe_with_redirect( $cmd, $redir )
        or return wantarray ? () : [];

    my $includeSelf = defined( $parms->{ includeSelf } ) ?   $parms->{ includeSelf }
                    : defined( $parms->{ excludeSelf } ) ? ! $parms->{ excludeSelf }
                    :                                        $queryF ne $dbF;

    #  With blastall, we must parse the output; with the new blast programs
    #  we can get the desired tabular output directly, so, hm, no alignments.
    #
    # my $blastall = $cmd->[0] =~ /blastall$/;

    my @output;
    while ( my $hsp = &gjoparseblast::next_blast_hsp( $fh, $includeSelf ) )
    {
        if ( &keep_hsp( $hsp, $parms ) )
        {
            push( @output, &format_hsp( $hsp, $blast_prog, $parms ) );
        }
    }

    wantarray ? @output : \@output;
}


#-------------------------------------------------------------------------------
#  Determine which blast hsp records pass the user-supplied, and default
#  criteria.
#
#      $bool = keep_hsp( \@hsp, \%options )
#
#
#  Data records from next_blast_hsp() are of the form:
#
#     [ qid qdef qlen sid sdef slen scr e_val p_n p_val n_mat n_id n_pos n_gap dir q1 q2 qseq s1 s2 sseq ]
#        0   1    2    3   4    5    6    7    8    9    10    11   12    13   14  15 16  17  18 19  20
#
#-------------------------------------------------------------------------------
sub keep_hsp
{
    my( $hsp, $parms ) = @_;

    local $_;
    return 0 if (($_ = $parms->{minIden})  && ($_ > ($hsp->[11]/$hsp->[10])));
    return 0 if (($_ = $parms->{minPos})   && ($_ > ($hsp->[12]/$hsp->[10])));
    return 0 if (($_ = $parms->{minScr})   && ($_ >  $hsp->[6]));
    #  This could be defined with the min aligned length, not the alignment length
    return 0 if (($_ = $parms->{minNBScr}) && ($_ >  $hsp->[6]/$hsp->[10]));
    return 0 if (($_ = $parms->{minCovQ})  && ($_ > ((abs($hsp->[16]-$hsp->[15])+1)/$hsp->[2])));
    return 0 if (($_ = $parms->{minCovS})  && ($_ > ((abs($hsp->[19]-$hsp->[18])+1)/$hsp->[5])));
    return 1;
}


#-------------------------------------------------------------------------------
#  We currently can return a blast hsp, as defined above, or a Sim object
#
#      $hsp_or_sim = format_hsp( \@hsp, $blast_prog, \%options )
#
#-------------------------------------------------------------------------------
sub format_hsp
{
    my( $hsp, $blast_prog, $parms ) = @_;

    my $out_form = lc ( $parms->{outForm} || 'sim' );
    $hsp->[7] =~ s/^e-/1.0e-/  if $hsp->[7];
    $hsp->[9] =~ s/^e-/1.0e-/  if $hsp->[9];
    return ($out_form eq 'hsp') ? $hsp
                                : Sim->new_from_hsp( $hsp, $blast_prog );
}


#-------------------------------------------------------------------------------
#  Build the appropriate blastall command for a system or pipe invocation
#
#      @cmd_and_args = form_blast_command( $queryF, $dbF, $blast_prog, \%options )
#     \@cmd_and_args = form_blast_command( $queryF, $dbF, $blast_prog, \%options )
#
#-------------------------------------------------------------------------------
sub form_blast_command
{
    my( $queryF, $dbF, $blast_prog, $parms ) = @_;
    $parms ||= {};

    my %prog_ok = map { $_ => 1 } qw( blastn blastp blastx tblastn tblastx psiblast rpsblast);
    $queryF && $dbF && $blast_prog && $prog_ok{ $blast_prog }
        or return wantarray ? () : [];

    my $try_plus = $parms->{ blastplus }
                || $blast_prog eq 'psiblast'
                || $blast_prog eq 'rpsblast';

    my $blastplus = ! $try_plus ? ''
                  : $blast_prog eq 'rpsblast' ? SeedAware::executable_for( 'rpsblast+' ) 
                                              : SeedAware::executable_for( $blast_prog );

    $blastplus ||= '/home/fangfang/programs/ncbi-blast-2.2.27+/bin/rpsblast+' if $blast_prog eq 'rpsblast';
    $blastplus ||= '/home/fangfang/programs/ncbi-blast-2.2.27+/bin/psiblast'  if $blast_prog eq 'psiblast';

    my $try_all = ! $blastplus
               && $blast_prog ne 'psiblast'
               && $blast_prog ne 'rpsblast';
    my $blastall = $try_all ? SeedAware::executable_for( 'blastall' ) : '';

    $blastplus || $blastall
        or return wantarray ? () : [];

    my $threads          = $parms->{ threads }          || $parms->{ numThreads }       || $parms->{ num_threads };

    my $dbCode           = $parms->{ dbCode }           || $parms->{ dbGenCode }        || $parms->{ db_gen_code };
    my $giList           = $parms->{ giList }           || $parms->{ gilist };

    my $queryCode        = $parms->{ queryCode }        || $parms->{ queryGeneticCode } || $parms->{ query_genetic_code };
    my $queryLoc         = $parms->{ queryLoc }         || $parms->{ query_loc };
    my $strand           = $parms->{ strand };
    my $lcFilter         = flag_value( $parms, qw( lcFilter seg dust ) );
    my $dust             = $parms->{ dust };
    my $seg              = $parms->{ seg };
    my $caseFilter       = flag_value( $parms, qw( caseFilter lcaseMasking lcase_masking ) );
    my $softMasking      = flag_value( $parms, qw( softMasking soft_masking ) );
    my $filteringDB      = $parms->{ filteringDB }      || $parms->{ filtering_db };

    my $maxE             = $parms->{ maxE }             || $parms->{ evalue }           || 0.01;
    my $percentIdentity  = $parms->{ percIdentity }     || $parms->{ perc_identity }    || 0;
    my $maxHSP           = $parms->{ maxHSP }           || $parms->{ numAlignments }    || $parms->{ num_alignments };
    my $dbLen            = $parms->{ dbLen }            || $parms->{ dbSize }           || $parms->{ dbsize };
    my $searchSp         = $parms->{ searchSp }         || $parms->{ searchsp };
    my $bestHitOverhang  = $parms->{ bestHitOverhang }  || $parms->{ best_hit_overhang };
    my $bestHitScoreEdge = $parms->{ bestHitScoreEdge } || $parms->{ best_hit_score_edge };

    my $wordSz           = $parms->{ wordSz }           || $parms->{ wordSize }         || $parms->{ word_size };
    my $matrix           = $parms->{ matrix };
    my $nucIdenScr       = $parms->{ nucIdenScr }       || $parms->{ reward };
    my $nucMisScr        = $parms->{ nucMisScr }        || $parms->{ penalty };
    my $gapOpen          = $parms->{ gapOpen }          || $parms->{ gapopen };
    my $gapExtend        = $parms->{ gapExtend }        || $parms->{ gapextend };
    my $threshold        = $parms->{ threshold };
    my $xDropFinal       = $parms->{ xDropFinal }       || $parms->{ xdrop_final };
    my $xDropGap         = $parms->{ xDropGap }         || $parms->{ xdrop_gap };
    my $xDropUngap       = $parms->{ xDropUngap }       || $parms->{ xdrop_ungap };

    my $useSwTback       = flag_value( $parms, qw( useSwTback use_sw_tback ) );
    my $ungapped         = flag_value( $parms, qw( ungapped ) );
    my $maxIntronLength  = $parms->{ maxIntronLength }  || $parms->{ max_intron_length };

    my $showGIs          = flag_value( $parms, qw( showGIs show_gis ) );

    # PSI-BLAST and PSSM engine options in blast+/psiblast

    my $iterations       = $parms->{ iterations }       || $parms->{ num_iterations };
    my $outPSSM          = $parms->{ outPSSM }          || $parms->{ out_pssm };
    my $asciiPSSM        = $parms->{ asciiPSSM }        || $parms->{ out_ascii_pssm };
    my $inMSA            = $parms->{ inMSA }            || $parms->{ in_msa };
    my $queryIndex       = $parms->{ queryIndex }       || $parms->{ msa_master_idx };
    my $queryID          = $parms->{ queryID }          || $parms->{ msa_master_id };
    my $ignoreMaster     = flag_value( $parms, qw( ignoreMaster ignore_msa_master ) );
    my $inPSSM           = $parms->{ inPSSM }           || $parms->{ in_pssm };
    my $pseudoCount      = $parms->{ pseudoCount }      || $parms->{ pseudocount };
    my $inclusionEvalue  = $parms->{ inclusionEvalue }  || $parms->{ inclusion_ethresh };
    my $inPHI            = $parms->{ inPHI }            || $parms->{ phi_pattern };

    my @cmd;
    if ( $blastall )
    {
        push @cmd, $blastall;
        push @cmd, -p => $blast_prog;
        push @cmd, -a => $threads                 if $threads;

        push @cmd, -d => $dbF;
        push @cmd, -D => $dbCode                  if $dbCode;
        push @cmd, -l => $giList                  if $giList;

        push @cmd, -i => $queryF;
        push @cmd, -Q => $queryCode               if $queryCode;
        push @cmd, -L => $queryLoc                if $queryLoc;
        push @cmd, -S => strand2($strand)         if $strand;
        push @cmd, -F => $lcFilter   ? 'T' : 'F'  if defined $lcFilter;
        push @cmd, -U => $caseFilter ? 'T' : 'F'  if defined $caseFilter;

        push @cmd, -e => $maxE                    if $maxE;
        push @cmd, -b => $maxHSP                  if $maxHSP;
        push @cmd, -z => $dbLen                   if $dbLen;
        push @cmd, -Y => $searchSp                if $searchSp;

        push @cmd, -W => $wordSz                  if $wordSz;
        push @cmd, -M => $matrix                  if $matrix;
        push @cmd, -r => $nucIdenScr ||  1        if $blast_prog eq 'blastn';
        push @cmd, -q => $nucMisScr  || -1        if $blast_prog eq 'blastn';
        push @cmd, -G => $gapOpen                 if $gapOpen;
        push @cmd, -E => $gapExtend               if $gapExtend;
        push @cmd, -f => $threshold               if $threshold;
        push @cmd, -X => $xDropGap                if $xDropGap;
        push @cmd, -y => $xDropUngap              if $xDropUngap;
        push @cmd, -Z => $xDropFinal              if $xDropFinal;
        push @cmd, -s => $useSwTback ? 'T' : 'F'  if defined $useSwTback;
        push @cmd, -g => $ungapped   ? 'T' : 'F'  if defined $ungapped;
        push @cmd, -t => $maxIntronLength         if $maxIntronLength;

        push @cmd, -I => $showGIs    ? 'T' : 'F'  if defined $showGIs;

        #  blastall does not have a percent identity option, so we must set the
        #  filter.

        $parms->{minIden} ||= 0.01 * $percentIdentity if $blast_prog eq 'blastn';
    }
    else
    {
        if ( defined $lcFilter )
        {
            my %seg_prog = map { $_ => 1 } qw( blastp blastx tblastn );
            $seg  = $lcFilter ? 'yes' : 'no' if ! defined $seg  && $seg_prog{ $blast_prog };
            $dust = $lcFilter ? 'yes' : 'no' if ! defined $dust && $blast_prog eq 'blastn';
        }

        my $alignF;
        if ( $blast_prog eq 'psiblast' )
        {
            $alignF   = valid_fasta( $inMSA, $parms->{ tmp_dir }.'/inMSA' ) if defined $inMSA;
            $alignF ||= $queryF if ! defined $inPSSM ;

            # queryIndex is 1-based 
            if ( ! $queryIndex && ! defined $inPSSM )
            {
                my @align = gjoseqlib::read_fasta( $alignF );
                my @query = gjoseqlib::read_fasta( $queryF ) if -s $queryF;

                my $masterID = $queryID;
                $masterID  ||= $query[0]->[0] if @query && @query == 1;
                $masterID  ||= representative_for_profile( \@align )->[0];

                for ( $queryIndex = 0; $queryIndex < @align; $queryIndex++ )
                {
                    last if $align[$queryIndex]->[0] eq $masterID;
                }

                $queryIndex = 1 if $queryIndex >= @align;
            }
        }

        push @cmd, $blastplus;
        push @cmd, -num_threads         => $threads           if $threads;

        push @cmd, -db                  => $dbF;
        push @cmd, -db_gen_code         => $dbCode            if $dbCode;
        push @cmd, -gilist              => $giList            if $giList;

        push @cmd, -query               => $queryF            if $blast_prog ne 'psiblast';
        push @cmd, -query_genetic_code  => $queryCode         if $queryCode;
        push @cmd, -query_loc           => $queryLoc          if $queryLoc;
        push @cmd, -strand              => strand3($strand)   if $strand;
        push @cmd, -seg                 => $seg               if $seg;
        push @cmd, -dust                => $dust              if $dust;
        push @cmd, -lcase_masking       => ()                 if $caseFilter;
        push @cmd, -soft_masking        => 'true'             if $softMasking;
        push @cmd, -filtering_db        => $filteringDB       if $filteringDB;

        push @cmd, -evalue              => $maxE              if $maxE;
        push @cmd, -perc_identity       => $percentIdentity   if $percentIdentity;
        push @cmd, -num_alignments      => $maxHSP            if $maxHSP;
        push @cmd, -dbsize              => $dbLen             if $dbLen;
        push @cmd, -searchsp            => $searchSp          if $searchSp;
        push @cmd, -best_hit_overhang   => $bestHitOverhang   if $bestHitOverhang;
        push @cmd, -best_hit_score_edge => $bestHitScoreEdge  if $bestHitScoreEdge;

        push @cmd, -word_size           => $wordSz            if $wordSz;
        push @cmd, -matrix              => $matrix            if $matrix;
        push @cmd, -reward              => $nucIdenScr ||  1  if $blast_prog eq 'blastn';
        push @cmd, -penalty             => $nucMisScr  || -1  if $blast_prog eq 'blastn';
        push @cmd, -gapopen             => $gapOpen           if $gapOpen;
        push @cmd, -gapextend           => $gapExtend         if $gapExtend;
        push @cmd, -threshold           => $threshold         if $threshold;
        push @cmd, -xdrop_gap           => $xDropGap          if $xDropGap;
        push @cmd, -xdrop_ungap         => $xDropUngap        if $xDropUngap;
        push @cmd, -xdrop_final         => $xDropFinal        if $xDropFinal;
        push @cmd, -use_sw_tback        => ()                 if $useSwTback;
        push @cmd, -ungapped            => ()                 if $ungapped;
        push @cmd, -max_intron_length   => $maxIntronLength   if $maxIntronLength;

        push @cmd, -show_gis            => ()                 if $showGIs;

        # PSI-BLAST and PSSM engine options in blast+/psiblast

        push @cmd, -num_iterations      => $iterations        if $iterations;
        push @cmd, -msa_master_idx      => $queryIndex        if $queryIndex;
        push @cmd, -pseudocount         => $pseudoCount       if $pseudoCount;
        push @cmd, -inclusion_ethresh   => $inclusionEvalue   if $inclusionEvalue;
        push @cmd, -ignore_msa_master   => ()                 if $ignoreMaster;

        push @cmd, -in_msa              => $alignF            if $alignF;
        push @cmd, -in_pssm             => $inPSSM            if $inPSSM && ! $alignF;
        push @cmd, -phi_pattern         => $inPHI             if $inPHI;

        push @cmd, -out_pssm            => $outPSSM           if $outPSSM;
        push @cmd, -out_ascii_pssm      => $outPSSM           if $asciiPSSM;
    }

    wantarray ? @cmd : \@cmd;
}


sub flag_value
{
    my $parms = shift;
    return undef unless $parms && ref($parms) eq 'HASH';

    my ( $val ) = map { $_ && defined( $parms->{$_} ) ? $parms->{$_} : () } @_;
    return undef if ! defined $val;

    ( ! $val || ( $val eq '0' ) || ( $val =~ /^f/i ) || ( $val =~ /^n/i ) ) ? 0 : 1;
}


sub strand2
{
    my $strand = shift || '';

    return ( ( $strand == 1 ) || ( $strand =~ /^p/i ) ) ? 1
         : ( ( $strand == 2 ) || ( $strand =~ /^m/i ) ) ? 2
         :                                                3;
}


sub strand3
{
    my $strand = shift || '';

    return ( ( $strand == 1 ) || ( $strand =~ /^p/i ) ) ? 'plus'
         : ( ( $strand == 2 ) || ( $strand =~ /^m/i ) ) ? 'minus'
         :                                                'both';
}


#-------------------------------------------------------------------------------
#
#   write_pseudoclustal( $align, \%opts )
#
#   Options:
#
#        file  =>  $filename  #  supply a file name to open and write
#        file  => \*FH        #  supply an open file handle (D = STDOUT)
#        line  =>  $linelen   #  residues per line (D = 60)
#        lower =>  $bool      #  all lower case sequence
#        upper =>  $bool      #  all upper case sequence
#
#-------------------------------------------------------------------------------

sub write_pseudoclustal
{
    my ( $align, $opts ) = @_;
    $align && ref $align eq 'ARRAY' && @$align
        or print STDERR "write_pseudoclustal called with invalid sequence list.\n"
           and return wantarray ? () : [];

    $opts = {} if ! ( $opts && ref $opts eq 'HASH' );
    my $line_len = $opts->{ line } || 60;
    my $case = $opts->{ upper } ?  1 : $opts->{ lower } ? -1 : 0;

    my ( $fh, $close ) = output_file_handle( $opts->{ file } );

    my $namelen = 0;
    foreach ( @$align ) { $namelen = length $_->[0] if $namelen < length $_->[0] }
    my $fmt = "%-${namelen}s  %s\n";

    my $id;
    my @lines = map { $id = $_->[0]; [ map { sprintf $fmt, $id, $_ }
                                       map { $case < 0 ? lc $_ : $case > 0 ? uc $_ : $_ }  # map sequence only
                                       $_->[2] =~ m/.{1,$line_len}/g
                                     ] }
                @$align;

    my $ngroup = @{ $lines[0] };
    for ( my $i = 0; $i < $ngroup; $i++ )
    {
        foreach ( @lines ) { print $fh $_->[$i] if $_->[$i] }
        print $fh "\n";
    }

    close $fh if $close;
}


#-------------------------------------------------------------------------------
#
#    @seqs = read_pseudoclustal( )              #  D = STDIN
#   \@seqs = read_pseudoclustal( )              #  D = STDIN
#    @seqs = read_pseudoclustal(  $file_name )
#   \@seqs = read_pseudoclustal(  $file_name )
#    @seqs = read_pseudoclustal( \*FH )
#   \@seqs = read_pseudoclustal( \*FH )
#
#-------------------------------------------------------------------------------

sub read_pseudoclustal
{
    my ( $file ) = @_;
    my ( $fh, $close ) = input_file_handle( $file );
    my %seq;
    my @ids;
    while ( <$fh> )
    {
        chomp;
        my ( $id, $data ) = /^(\S+)\s+(\S.*)$/;
        if ( defined $id && defined $data )
        {
            push @ids, $id if ! $seq{ $id };
            $data =~ s/\s+//g;
            push @{ $seq{ $id } }, $data;
        }
    }
    close $fh if $close;

    my @seq = map { [ $_, '', join( '', @{ $seq{ $_ } } ) ] } @ids;
    wantarray ? @seq : \@seq;
}


#-------------------------------------------------------------------------------
#  The profile 'query' sequence:
#
#     1. Minimum terminal gaps
#     2. Longest sequence passing above
#
#    $prof_rep = representative_for_profile( $align )
#-------------------------------------------------------------------------------
sub representative_for_profile
{
    my ( $align ) = @_;
    $align && ref $align eq 'ARRAY' && @$align
        or die "representative_for_profile called with invalid sequence list.\n";

    my ( $r0 ) = map  { $_->[0] }                                      # sequence entry
                 sort { $a->[1] <=> $b->[1] || $b->[2] <=> $a->[2] }   # min terminal gaps, max aas
                 map  { my $tgap = ( $_->[2] =~ /^(-+)/ ? length( $1 ) : 0 )
                                 + ( $_->[2] =~ /(-+)$/ ? length( $1 ) : 0 );
                        my $naa = $_->[2] =~ tr/ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy//;
                        [ $_, $tgap, $naa ]
                      }
                 @$align;

    my $rep = [ @$r0 ];             # Make a copy
    $rep->[2] =~ s/[^A-Za-z]+//g;   # Compress to letters

    $rep;
}


#-------------------------------------------------------------------------------
#  Support for rewriting blast output as text
#-------------------------------------------------------------------------------

my %aa_num = ( R  =>  1,
               K  =>  2,
               Q  =>  3,
               E  =>  4,
               N  =>  5,
               D  =>  6,
               H  =>  7,
               G  =>  8,
               S  =>  9,
               T  => 10,
               A  => 11,
               C  => 12,
               V  => 13,
               I  => 14,
               L  => 15,
               M  => 16,
               F  => 17,
               Y  => 18,
               W  => 19,
               P  => 20,
               X  => 21,
              '*' => 22 );

my @aa_num = ( (0) x 256 );
foreach ( keys %aa_num )
{
   $aa_num[ord(lc $_)] = $aa_num[ord($_)] = $aa_num{$_};
}

sub aa_num { $aa_num[ord($_[0]||' ')] }

my @b62mat =                         # . R K Q E N D H G S T A C V I L M F Y W P X *
    ( [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . . . . . . . . . . . ) ],  # .
      [ map {$_ eq '.' ? ' ' : $_} qw( . R + + . . . . . . . . . . . . . . . . . . . ) ],  # R
      [ map {$_ eq '.' ? ' ' : $_} qw( . + K + + . . . . . . . . . . . . . . . . . . ) ],  # K
      [ map {$_ eq '.' ? ' ' : $_} qw( . + + Q + . . . . . . . . . . . . . . . . . . ) ],  # Q
      [ map {$_ eq '.' ? ' ' : $_} qw( . . + + E . + . . . . . . . . . . . . . . . . ) ],  # E
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . N + + . + . . . . . . . . . . . . . ) ],  # N
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . + + D . . . . . . . . . . . . . . . . ) ],  # D
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . + . H . . . . . . . . . . + . . . . ) ],  # H
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . G . . . . . . . . . . . . . . ) ],  # G
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . + . . . S + + . . . . . . . . . . . ) ],  # S
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . + T . . . . . . . . . . . . ) ],  # T
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . + . A . . . . . . . . . . . ) ],  # A
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . C . . . . . . . . . . ) ],  # C
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . V + + + . . . . . . ) ],  # V
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . + I + + . . . . . . ) ],  # I
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . + + L + . . . . . . ) ],  # L
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . + + + M . . . . . . ) ],  # M
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . . . . . F + + . . . ) ],  # F
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . + . . . . . . . . . + Y + . . . ) ],  # Y
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . . . . . + + W . . . ) ],  # W
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . . . . . . . . P . . ) ],  # P
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . . . . . . . . . X . ) ],  # X
      [ map {$_ eq '.' ? ' ' : $_} qw( . . . . . . . . . . . . . . . . . . . . . . * ) ]   # *
    );


sub b62_match_chr
{
    defined $_[0] && length($_[0]) && defined $_[1] && length($_[1])
        or return undef;
    lc $_[0] eq lc $_[1] ? $_[0]
                         : $b62mat[$aa_num[ord($_[0])]]->[$aa_num[ord($_[1])]];
}

#
#  If characters are known to be defined:
#
sub b62_match_chr_0
{
    lc $_[0] eq lc $_[1] ? $_[0]
                         : $b62mat[$aa_num[ord($_[0])]]->[$aa_num[ord($_[1])]];
}

sub b62_match_seq
{
    my ( $s1, $s2 ) = @_;
    $s1 && $s2 && length($s1) == length($s2)
        or return '';

    join( '', map { b62_match_chr_0( substr($s1,$_,1), substr($s2,$_,1) ) }
              ( 0 .. length($s1)-1 )
        );
}


sub nt_match_chr { $_[0] && $_[1] && lc $_[0] eq lc $_[1] ? '|' : ' ' }

#
#  If characters are known to be defined:
#
sub nt_match_chr_0 { lc $_[0] eq lc $_[1] ? '|' : ' ' }

sub nt_match_seq
{
    my ( $s1, $s2 ) = @_;
    $s1 && $s2 && length($s1) == length($s2)
        or return '';

    join( '', map { nt_match_chr_0( substr($s1,$_,1), substr($s2,$_,1) ) } (0..length($s1)-1) );
}


#
#  [ qid qdef qlen sid sdef slen scr e_val p_n p_val n_mat n_id n_pos n_gap dir q1 q2 qseq s1 s2 sseq ]
#     0   1    2    3   4    5    6    7    8    9    10    11   12    13   14  15 16  17  18 19  20
#
sub hsps_to_text
{
    my ( $hsps, $tool, $parm ) = @_;
    return wantarray ? () : [] unless $hsps && @$hsps;

    $tool ||= 'blastp';
    $parm ||= {};
    my $perline = $parm->{ perLine } || $parm->{ perline } || 60;

    my %summary;
    my %seen;
    if ( ! $parm->{nosummary} )
    {
        foreach my $hsp ( @$hsps )
        {
            my ( $qid, $sid, $sdef, $scr, $e_val ) = @$hsp[0,3,4,6,7];
            next if $seen{"$qid-$sid"}++;

            $sdef =~ s/\001/; /g;
            $sdef = html_esc( $sdef );
            my $e_str = $e_val >= 0.1 ? sprintf( "%.1f", $e_val )
                      : $e_val >    0 ? sprintf( "%.1e", $e_val )
                      :                 "0.0";
            $e_str =~ s/\.0e/e/;
            my $row = join( "", "  <TR>\n",
                                "    <TD NoWrap>$sid</TD>\n",
                                "    <TD>$sdef</TD>\n",
                                "    <TD Align=right NoWrap>$scr</TD>\n",
                                "    <TD Align=right NoWrap>$e_val</TD>\n",
                                "  </TR>\n"
                          );
            push @{$summary{$qid}}, $row;
        }

        foreach my $qid ( keys %summary )
        {
            my $table = join( "", "</PRE>High-scoring matches:<BR />",
                                  "<TABLE>\n",
                                  "<TABLE>\n",
                                  "<TABLEBODY>\n",
                                  "<TR>\n",
                                  "    <TD NoWrap><BR />Subject ID</TD>\n",
                                  "    <TD><BR />Description</TD>\n",
                                  "    <TD Align=center NoWrap>Bit<BR />score</TD>\n",
                                  "    <TD Align=right NoWrap><BR />E-value</TD>\n",
                                  "  </TR>\n",
                                  @{$summary{$qid}},
                                  "</TABLEBODY>\n",
                                  "</TABLE><PRE>\n"
                              );
            $summary{$qid} = $table;
        }
    }

    my @out;
    my $qid = '';
    my $sid = '';
    my ( $qdef, $qlen, $sdef, $slen );

    foreach my $hsp ( @$hsps )
    {
        if ( $hsp->[0] ne $qid )
        {
            ( $qid, $qdef, $qlen ) = @$hsp[0,1,2];
            push @out, join( '', "Query= $qid",
                                 (defined $qdef && length $qdef) ? " $qdef" : (),
                                 "\n"
                           );
            push @out, "         ($qlen letters)\n\n";

            push @out, $summary{$qid} if  $summary{$qid};

            $sid = '';
        }

        if ( $hsp->[3] ne $sid )
        {
            ( $sid, $sdef, $slen ) = @$hsp[3,4,5];
            my $desc = $sid;
            $desc .= " " . join( "\n ", split /\001/, $sdef ) if length( $sdef || '' );
            push @out, ">$desc\n",
                       "         Length = $slen\n\n";
        }

        my ( $scr, $e_val, $n_mat, $n_id, $n_pos, $n_gap, $dir ) = @$hsp[6,7,10..14];
        my ( $q1, $q2, $qseq, $s1, $s2, $sseq ) = @$hsp[15..20];

        my $e_str = $e_val >= 0.1 ? sprintf( "%.1f", $e_val )
                  : $e_val >    0 ? sprintf( "%.1e", $e_val )
                  :                 "0.0";
        $e_str =~ s/\.0e/e/;
        push @out, sprintf( " Score = %.1f bits (%d), Expect = %s\n", $scr, 2*$scr, $e_str );
        push @out, join( '', sprintf( " Identities = %d/%d (%d%%)", $n_id, $n_mat, 100*$n_id/$n_mat ),
                             $n_pos ? sprintf( ", Positives = %d/%d (%d%%)", $n_pos, $n_mat, 100*$n_pos/$n_mat ) : (),
                             sprintf( ", Gaps = %d/%d (%d%%)", $n_gap, $n_mat, 100*$n_gap/$n_mat ),
                             "\n"
                       );
        push @out, $tool eq 'blastn'  ? " Strand = @{[$q2>$q1?'Plus':'Minus']} / @{[$s2>$s1?'Plus':'Minus']}\n\n"
                 : $tool eq 'blastx'  ? " Frame = $dir\n\n"
                 : $tool eq 'tblastn' ? " Frame = $dir\n\n"
                 :                      "\n";

        my $match = $tool eq 'blastn' ? nt_match_seq(  $qseq, $sseq )
                                      : b62_match_seq( $qseq, $sseq );

        my @qseq  = $qseq  =~ /(.{1,$perline})/g;
        my @sseq  = $sseq  =~ /(.{1,$perline})/g;
        my @match = $match =~ /(.{1,$perline})/g;

        my $ndig = int( log(max_n($q1,$q2,$s1,$s2)+0.5) / log(10) ) + 1;

        my $q_step = $tool =~ /^blast[np]$/i || lc $tool eq 'tblastn' ? 1 : 3;
        my $q_dir  = $q2 > $q1 ? 1 : -1;
        my $s_step = $tool =~ /^blast[np]$/i || lc $tool eq 'blastx'  ? 1 : 3;
        my $s_dir  = $s2 > $s1 ? 1 : -1;

        my $sp = ' ' x $ndig;
        my $qfmt = "Query: \%${ndig}d %s \%${ndig}d\n";
        my $mfmt = "       $sp %s\n";
        my $sfmt = "Subjt: \%${ndig}d %s \%${ndig}d\n\n";

        while ( @qseq )
        {
            my $qs      = shift @qseq;
            my $q_used  = $qs =~ tr/-//c;
            my $q1_next = $q1 + $q_used * $q_step * $q_dir;

            my $ms = shift @match;

            my $ss      = shift @sseq;
            my $s_used  = $ss =~ tr/-//c;
            my $s1_next = $s1 + $s_used * $s_step * $s_dir;

            push @out, sprintf( $qfmt, $q1, $qs,  $q1_next-$q_dir );
            push @out, sprintf( $mfmt,      $ms );
            push @out, sprintf( $sfmt, $s1, $ss,  $s1_next-$s_dir );

            $q1 = $q1_next;
            $s1 = $s1_next;
        }

        push @out, "\n";
    }

    wantarray ? @out : join( '', @out );
}


#-------------------------------------------------------------------------------
#  Get an input file handle, and boolean on whether to close or not:
#
#  ( \*FH, $close ) = input_file_handle(  $filename );
#  ( \*FH, $close ) = input_file_handle( \*FH );
#  ( \*FH, $close ) = input_file_handle( );                   # D = STDIN
#
#-------------------------------------------------------------------------------

sub input_file_handle
{
    my ( $file ) = @_;

    my ( $fh, $close );
    if ( defined $file )
    {
        if ( ref $file eq 'GLOB' )
        {
            $fh = $file;
            $close = 0;
        }
        elsif ( -f $file )
        {
            open( $fh, "<", $file) || die "input_file_handle could not open '$file'.\n";
            $close = 1;
        }
        else
        {
            die "input_file_handle could not find file '$file'.\n";
        }
    }
    else
    {
        $fh = \*STDIN;
        $close = 0;
    }

    return ( $fh, $close );
}


#-------------------------------------------------------------------------------
#  Get an output file handle, and boolean on whether to close or not:
#
#  ( \*FH, $close ) = output_file_handle(  $filename );
#  ( \*FH, $close ) = output_file_handle( \*FH );
#  ( \*FH, $close ) = output_file_handle( );                   # D = STDOUT
#
#-------------------------------------------------------------------------------

sub output_file_handle
{
    my ( $file, $umask ) = @_;

    my ( $fh, $close );
    if ( defined $file )
    {
        if ( ref $file eq 'GLOB' )
        {
            $fh = $file;
            $close = 0;
        }
        else
        {
            open( $fh, ">", $file) || die "output_file_handle could not open '$file'.\n";
            $umask ||= 0664;
            chmod $umask, $file;  #  Seems to work on open file!
            $close = 1;
        }
    }
    else
    {
        $fh = \*STDOUT;
        $close = 0;
    }

    return ( $fh, $close );
}


sub html_esc { local $_ = shift || ''; s/\&/&amp;/g; s/>/&gt;/g; s/</&lt;/g; $_ }

sub max   { $_[0] >= $_[1] ? $_[0] : $_[1] }

sub max_n { my $max = shift; foreach ( @_ ) { $max = $_ if $_ > $max }; $max } 

1;
