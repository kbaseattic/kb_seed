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

#
# This is a general blast interface.  It is supposed to support at least
# blastp, blastn, blastx, and tblastn.
#
# The first two arguments give the query and db sequences.  These both can
# be passed in several forms:
#
#        filename
#        open filehandle
#        single seq triple
#        a list of sequence triples
#        nothing -> read from STDIN 
#
###########
#
# The third argument is the "tool" (usually, 'blastp, blastn, or tblastn)
#
# The fourth argument is an options hash.  Here are the specs for those:
#
#    caseFilter => ignore lowercase query residues in scoring
#    dbCode => genetic code for DB sequences [D = 1]
#    dbLen => effective length of DB for computing E-values
#    excludeSelf => Boolean that suppresses matches between the same ID
#    gapExtend => cost for extending a gap
#    gapOpen => cost for opening a gap
#    matrix => amino acid comparison matrix [D = BLOSUM62]
#    maxE => maximum E-value [D = 0.01]
#    maxHSP => maximum number of returned HSPs (before filtering)
#    minCovQ => minimum fraction of query covered by match
#    minCovS => minimum fraction of the DB sequence covered by the match
#    minIden => fraction (0 to 1) that is a minimum required identity
#    minPos => fraction of aligned residues with positive score
#    minScr => minimum required bit-score
#    nucIdenScr => score for identical nucleotides
#    nucMisScr => score for non-identical nucleotides
#    outForm => 'sim' => Sim objects [D]; 'hsp' => return full HSPs (as defined in gjoparseblast.pm)
#    queryCode => genetic code for query sequence [D = 1]
#    save_dir => Boolean that causes the scratch directory to be retained (good for debugging)
#    threads => number of threads that can be run in parallel
#    tmp_dir => $tmpD   # use $tmpD as the scratch directory
#    wordSz => word size used for initiating matches
#
##########
sub blast {
    my($query,$db,$type,$parms) = @_;
 
    $parms ||= {};
    my($tempD,$save_temp) = &SeedAware::temporary_directory($parms);
    $parms->{tmp_dir}     = $tempD;
    my $user_output;
    if ((my $queryH       = &get_query($query,$tempD,$parms)) &&
	(my $dbH          = &get_db($db,$type,$tempD,$parms)))
    {
	$user_output   = &run_blast($queryH,$dbH,$type,$tempD,$parms);
    }
    else
    {
	$user_output      = wantarray ? [] : undef;
    }
    if (! $save_temp)
    {
 	delete $parms->{tmp_dir};
	system("rm","-r",$tempD);
    }
    return wantarray ? @$user_output : $user_output;
}

sub get_query {
    my($query,$tempD,$parms) = @_;
#   returns query-file

    return &valid_fasta($query,"$tempD/query");
}

sub valid_fasta {
    my($file,$tmp_file) = @_;

    my $out_file;
    if (defined($file) && (! ref($file)))
    {
	if (-s $file)
	{
	    $out_file = $file;
	}
    }
    else
    {
	my $data;
	if ($file && (ref($file) eq 'ARRAY'))
	{
	    if (@$file && $file->[0] && (ref($file->[0]) eq 'ARRAY'))
	    {
		$data = $file;
	    }
	    elsif (@$file == 3)
	    {
		$data = [$file];
	    }
	}
	elsif ((! $file) || (ref($file) eq 'GLOB'))
	{
	    $data = &gjoseqlib::read_fasta($file);
	}

	if ($data && (@$data > 0))
	{
	    $out_file = $tmp_file;
	    &gjoseqlib::write_fasta($out_file,$data);
	}
    }
    return $out_file;
}

sub get_db {
    my($db,$type,$tempD,$parms) = @_;
#   returns db-file

    my $dbF = &valid_fasta($db,"$tempD/db");
    my $type_file  = (($type eq 'blastp') || ($type eq 'blastx')) ? 'P' : 'N' ;
    if (! &verify_db($dbF,$type_file)) { $dbF = undef }
    return $dbF;
}

sub verify_db
{
    my ( $db, $type ) = @_;
    
    my @args;
    if ( $type =~ m/^p/i )
    {
        @args = ( "-p", "T", "-i", $db ) unless ((-s "$db.psq") && (-M "$db.psq" <= -M $db)) || ((-s "$db.00.psq") && (-M "$db.00.psq" <= -M $db));
    }
    else
    {
        @args = ( "-p", "F", "-i", $db ) unless ((-s "$db.nsq") && (-M "$db.nsq" <= -M $db)) || ((-s "$db.00.nsq") && (-M "$db.00.nsq" <= -M $db));
    }

    @args or return ( -s $db ? 1 : 0 );


    #
    #  Find formatdb appropriate for the excecution environemnt.
    #

    my $prog = SeedAware::executable_for( 'formatdb' );
    if ( ! $prog )
    {
        warn "BlastInterface::verify_db: formatdb program not found.\n";
        return 0;
    }

    my $rc = system( $prog, @args );

    if ( $rc != 0 )
    {
        my $cmd = join( ' ', $prog, @args );
        warn "BlastInterface::verify_db: formatdb failed with rc = $rc: $cmd\n";
        return 0;
    }

    return 1;
}

sub run_blast {
    my($queryH,$dbH,$type,$tempD,$parms) = @_;

    my $cmd = &form_blast_command($queryH,$dbH,$type,$tempD,$parms);
    my $fh  = &SeedAware::read_from_pipe_with_redirect($cmd,{ stderr => "/dev/null" });
    return undef if (! $fh);
    my @output;
    while (my $hsp = &gjoparseblast::next_blast_hsp($fh,$parms->{excludeSelf}))
    {
	if (&keep($hsp,$parms))
	{
	    push(@output,&format_hsp($hsp,$type,$parms));
	}
    }
    return \@output;
}

#     Output records are all of the form:
#
#     [ qid qdef qlen sid sdef slen scr e_val p_n p_val n_mat n_id n_pos n_gap dir q1 q2 qseq s1 s2 sseq ]
#        0   1    2    3   4    5    6    7    8    9    10    11   12    13   14  15 16  17  18 19  20
#

sub keep {
    my($hsp,$parms) = @_;

    return 0 if ($parms->{minIden} && ($parms->{minIden} > ($hsp->[11]/$hsp->[10])));
    return 0 if ($parms->{minPos}  && ($parms->{minPos}  > ($hsp->[12]/$hsp->[10])));
    return 0 if ($parms->{minScr}  && ($parms->{minScr}  > $hsp->[6]));
    return 0 if ($parms->{minCovQ} && ($parms->{minCovQ} > ((abs($hsp->[16]-$hsp->[15])+1)/$hsp->[2])));
    return 0 if ($parms->{minCovS} && ($parms->{minCovS} > ((abs($hsp->[19]-$hsp->[18])+1)/$hsp->[5])));
    return 1;
}

sub format_hsp {
    my($hsp,$type,$parms) = @_;

    my $out_form = $parms->{outForm} || 'sim';
    if ($out_form eq 'hsp')
    {
	return $hsp;
    }
    else 
    {
	return Sim->new_from_hsp($hsp,$type);
    }
}

sub form_blast_command {
    my($queryF,$dbF,$type,$tempD,$parms) = @_;

    my $is_protQ = (($type eq 'blastp') || ($type eq 'tblastn'));
    my $is_protD = (($type eq 'blastp') || ($type eq 'blastx'));

    my @cmd = (SeedAware::executable_for( 'blastall' ), 
	       -p => $type,
	       -i => $queryF,
	       -d => $dbF,
	       -e => $parms->{maxE} || 0.01);

    push(@cmd, -F => 'F')                      if ($parms->{lcFilter});
    push(@cmd, -b => $parms->{maxHSP})         if ($parms->{maxHSP});
    push(@cmd, -a => $parms->{threads})        if ($parms->{threads});
    push(@cmd, -M => $parms->{matrix})         if ($parms->{matrix});
    push(@cmd, -r => $parms->{nucIdenScr})     if ($parms->{nucIdenScr});
    push(@cmd, -q => $parms->{nucMisScr} || 1) if ($type eq 'blastn');
    push(@cmd, -G => $parms->{gapOpen})        if ($parms->{gapOpen});
    push(@cmd, -E => $parms->{gapExtend})      if ($parms->{gapExtend});
    push(@cmd, -Q => $parms->{queryCode})      if ($parms->{queryCode});
    push(@cmd, -D => $parms->{dbCode})         if ($parms->{dbCode});
    push(@cmd, -W => $parms->{wordSz})         if ($parms->{wordSz});
    push(@cmd, -z => $parms->{dbLen})          if ($parms->{dbLen});
    push(@cmd, -U => $parms->{caseFilter})     if ($parms->{caseFilter});

    return \@cmd;
}
	       
1

