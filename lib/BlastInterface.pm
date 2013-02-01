#
# Copyright (c) 2003-2012 University of Chicago and Fellowship
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
use gjoseqlib;
use gjoparseblast;
use Sim;

#-------------------------------------------------------------------------------
#  This is a general interface to NCBI blastall.  It supports blastp, blastn,
#  blastx, and tblastn.
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
#  The third argument is the blast tool (blastp, blastn, blastx or tblastn)
#
#  The fourth argument is an options hash.  The available options are:
#
#      caseFilter  => ignore lowercase query residues in scoring (T/F) [D = F]
#      dbCode      => genetic code for DB sequences [D = 1]
#      dbLen       => effective length of DB for computing E-values
#      excludeSelf => suppress reporting matches of ID to itself (D = 0)
#      gapExtend   => cost (>0) for extending a gap
#      gapOpen     => cost (>0) for opening a gap
#      includeSelf => force reporting of matches of ID to itself (D = 1)
#      lcFilter    => low complexity query sequence filter setting (T/F) [D = T]
#      matrix      => amino acid comparison matrix [D = BLOSUM62]
#      maxE        => maximum E-value [D = 0.01]
#      maxHSP      => maximum number of returned HSPs (before filtering)
#      minCovQ     => minimum fraction of query covered by match
#      minCovS     => minimum fraction of the DB sequence covered by the match
#      minIden     => fraction (0 to 1) that is a minimum required identity
#      minPos      => fraction of aligned residues with positive score
#      minScr      => minimum required bit-score
#      nucIdenScr  => score (>0) for identical nucleotides [D = 1]
#      nucMisScr   => score (<0) for non-identical nucleotides [D = -1]
#      outForm     => 'sim' => return Sim objects [D];
#                     'hsp' => return HSPs (as defined in gjoparseblast.pm)
#      queryCode   => genetic code for query sequence [D = 1]
#      save_dir    => Boolean that causes the scratch directory to be retained
#                         (good for debugging)
#      threads     => number of threads that can be run in parallel
#      tmp_dir     => $tmpD   # use $tmpD as the scratch directory
#      wordSz      => word size used for initiating matches
#
#  The following program-specific interfaces are also provided:
#
#      @matches =  blastn( $query, $db, \%options )
#     \@matches =  blastn( $query, $db, \%options )
#      @matches =  blastp( $query, $db, \%options )
#     \@matches =  blastp( $query, $db, \%options )
#      @matches =  blastx( $query, $db, \%options )
#     \@matches =  blastx( $query, $db, \%options )
#      @matches = tblastn( $query, $db, \%options )
#     \@matches = tblastn( $query, $db, \%options )
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

    my %valid_tool = map { $_ => 1 } qw( blastn blastp blastx tblastn );
    if ( ! $valid_tool{ lc $blast_prog } )
    {
        warn "BlastInterface::blast: invalid blast program '$blast_prog'.\n";
    }
    elsif ( ! ( $queryF = &get_query( $query, $tempD, $parms ) ) ) 
    {
        warn "BlastInterface::get_query: failed to get query sequence data.\n";
    }
    elsif ( ! ( $dbF = &get_db( $$dbR, $blast_prog, $tempD, $parms ) ) )
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
        system( "rm", "-r", $tempD );
    }

    return wantarray ? @$user_output : $user_output;
}


sub  blastn { &blast( $_[0], $_[1],  'blastn', $_[2] ) }
sub  blastp { &blast( $_[0], $_[1],  'blastp', $_[2] ) }
sub  blastx { &blast( $_[0], $_[1],  'blastx', $_[2] ) }
sub tblastn { &blast( $_[0], $_[1], 'tblastn', $_[2] ) }


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

    return &valid_fasta( $query, "$tempD/query" );
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

    my $seq_type = (($blast_prog eq 'blastp') || ($blast_prog eq 'blastx')) ? 'P' : 'N' ;
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
            if ( @$seq_src && $seq_src->[0] && (ref($seq_src->[0]) eq 'ARRAY') )
            {
                $data = $seq_src;
            }
            #  A single sequence triple?
            elsif (@$seq_src == 3)
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

    return $out_file;
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

    my $cmd = &form_blast_command( $queryF, $dbF, $blast_prog, $parms );
    my $fh  = &SeedAware::read_from_pipe_with_redirect( $cmd, { stderr => "/dev/null" } )
        or return undef;

    my $includeSelf = defined( $parms->{ includeSelf } ) ?   $parms->{ includeSelf }
                    : defined( $parms->{ excludeSelf } ) ? ! $parms->{ excludeSelf }
                    :                                        $queryF ne $dbF;

    my @output;
    while (my $hsp = &gjoparseblast::next_blast_hsp( $fh, $includeSelf ) )
    {
        if ( &keep_hsp( $hsp, $parms ) )
        {
            push( @output, &format_hsp( $hsp, $blast_prog, $parms ) );
        }
    }

    return wantarray ? @output : \@output;
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

    return 0 if ($parms->{minIden} && ($parms->{minIden} > ($hsp->[11]/$hsp->[10])));
    return 0 if ($parms->{minPos}  && ($parms->{minPos}  > ($hsp->[12]/$hsp->[10])));
    return 0 if ($parms->{minScr}  && ($parms->{minScr}  >  $hsp->[6]));
    return 0 if ($parms->{minCovQ} && ($parms->{minCovQ} > ((abs($hsp->[16]-$hsp->[15])+1)/$hsp->[2])));
    return 0 if ($parms->{minCovS} && ($parms->{minCovS} > ((abs($hsp->[19]-$hsp->[18])+1)/$hsp->[5])));
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

    # my $is_protQ = (($blast_prog eq 'blastp') || ($blast_prog eq 'tblastn'));
    # my $is_protD = (($blast_prog eq 'blastp') || ($blast_prog eq 'blastx'));

    my @cmd = ( SeedAware::executable_for( 'blastall' ), 
                -p => $blast_prog,
                -i => $queryF,
                -d => $dbF,
                -e => $parms->{maxE} || 0.01
              );

    #  These two parameters do the opposite of what might be expected for
    #  numeric values, so we fix them:

    my $lcFilter = defined $parms->{lcFilter} ? $parms->{lcFilter} : '';
    if    ( $lcFilter eq '0' ) { $lcFilter = 'F' }
    elsif ( $lcFilter eq '1' ) { $lcFilter = 'T' }

    my $caseFilter = defined $parms->{caseFilter} ? $parms->{caseFilter} : '';
    if    ( $caseFilter eq '0' ) { $caseFilter = 'F' }
    elsif ( $caseFilter eq '1' ) { $caseFilter = 'T' }

    push(@cmd, -a => $parms->{threads})          if $parms->{threads};
    push(@cmd, -b => $parms->{maxHSP})           if $parms->{maxHSP};
    push(@cmd, -D => $parms->{dbCode})           if $parms->{dbCode};
    push(@cmd, -E => $parms->{gapExtend})        if $parms->{gapExtend};
    push(@cmd, -F => $lcFilter)                  if $lcFilter;
    push(@cmd, -G => $parms->{gapOpen})          if $parms->{gapOpen};
    push(@cmd, -M => $parms->{matrix})           if $parms->{matrix};
    push(@cmd, -q => $parms->{nucMisScr}  || -1) if $blast_prog eq 'blastn';
    push(@cmd, -Q => $parms->{queryCode})        if $parms->{queryCode};
    push(@cmd, -r => $parms->{nucIdenScr} ||  1) if $blast_prog eq 'blastn';
    push(@cmd, -U => $caseFilter)                if $caseFilter;
    push(@cmd, -W => $parms->{wordSz})           if $parms->{wordSz};
    push(@cmd, -z => $parms->{dbLen})            if $parms->{dbLen};

    return wantarray ? @cmd : \@cmd;
}


1;

