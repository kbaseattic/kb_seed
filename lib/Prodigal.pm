# -*- perl -*-

package Prodigal;

#
# This is a SAS component.
#

########################################################################
# Copyright (c) 2003-2013 University of Chicago and Fellowship
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
########################################################################

use strict;
use warnings;

use Time::HiRes 'gettimeofday';
use Scalar::Util qw/ openhandle /;
use File::Temp qw/ tempfile tempdir /;
use File::Path qw(rmtree);
use Data::Dumper;
use Carp;

use gjoseqlib;

sub run_prodigal
{
    my ($params) = @_;
    my ($line, $contig_id);
    
    my $prodigal = 'prodigal';
    
    my $genetic_code = $params->{-genetic_code} or die "missing -genetic_code parameter";
    my $contigs      = $params->{-contigs}      or die "missing -contigs parameter";
    
    #
    # Create temporary directory and FASTA for the contig data.
    #
    my @tmpdir = defined($params->{-tmpdir}) ? (DIR => $params->{-tmpdir}) : (TMPDIR => 1);
    my $tmp_dir = tempdir('tmpdir_prodigal_XXXXXXXX', @tmpdir);

    print STDERR "contig=$tmp_dir\n" if $ENV{DEBUG};
    
    #...Logfile will always be non-null, so no need to test it later...
    my $logfile = defined($params->{-log}) ? $params->{-log} : "$tmp_dir/prodigal.log";
    
    my $tmp_contigs_filename = "$tmp_dir/contigs";
    print STDERR "tmp_contigs_filename=$tmp_contigs_filename\n" if $ENV{DEBUG};
    
    if (ref($contigs) eq "ARRAY") {
	print STDERR "Assuming -contigs is a GJO sequence object\n" if $ENV{DEBUG};
	&gjoseqlib::write_fasta( $tmp_contigs_filename, $contigs );
    }
    elsif (Scalar::Util::openhandle($contigs)) {
	print STDERR "Assuming -contigs is a read-opened filehandle\n" if $ENV{DEBUG};
	open( TMP, q(>), $tmp_contigs_filename)
	    or die qq(Could not write-open temporary contigs file \"$tmp_contigs_filename\");
	print TMP <$contigs>;
	close TMP;
    }
    elsif (-f $contigs) {
	print STDERR "Assuming -contigs is a FASTA file to be copied to tmp_dir/contigs" if $ENV{DEBUG};
	my $verbose = $ENV{DEBUG} ? q(-v) : q();
	system("cp $verbose $contigs $tmp_contigs_filename");
    }
    else {
	die ("-contigs parameter is not a recognized object --- dump follows:\n", Dumper($contigs));
    }
    
    my $trans_file = "$tmp_dir/translations";
    my $sco_file   = "$tmp_dir/calls.sco";
    
    my @cmd = ("$prodigal",
	       "-m",
	       "-a", $trans_file,
	       "-g", $genetic_code,
	       "-i", $tmp_contigs_filename,
	       "-f", "sco",
	       "-o", $sco_file,
	       );

    if ((-s $tmp_contigs_filename) < 25000) {
	print STDERR "Genome is smaller than 25000 bp -- using 'metagenome' mode\n" if $ENV{DEBUG};
	push @cmd, qw( -p meta );
    }
    
    my $cmd = join q( ), @cmd;
    
    my $hostname = `hostname`;
    chomp $hostname;
    my $event = {
	tool_name => "prodigal",
	execute_time => scalar gettimeofday,
	parameters => \@cmd,
	hostname => $hostname,
    };

    warn "Run: $cmd\n" if $ENV{DEBUG};
    my $res = system( @cmd );
    if ($res != 0) {
	die "cmd failed with rc=$res: $cmd";
    }
    
    
    #...Parse translations...
    my %transH;
    my ($fh_trans, $trans_id, $comment, $seq);
    open($fh_trans, q(<), $trans_file) or die qq(Could not read-open \"$trans_file\");
    while (($trans_id, $comment, $seq) = &gjoseqlib::read_next_fasta_seq($fh_trans)) {
	my ($contig_id) = ($trans_id =~ m/^(\S+)_\d+$/o);
	my ($left, $right, $strand, $left_trunc, $right_trunc) 
	    = ($comment =~ m/^\#\s+(\d+)\s+\#\s+(\d+)\s+\#\s+(-?1)\s+\#.*partial=([01])([01])/o);
	
	if ($contig_id && $left && $right && $strand && defined($left_trunc) && defined($right_trunc)) {
	    $seq =~ s/\*$//o;
	    $strand = ($strand == 1) ? q(+) : q(-);
	    $transH{"$contig_id\t$left\t$right\t$strand"} = [ $seq, $left_trunc, $right_trunc ];
	}
	else {
	    die ("Could not parse record:\n",
		 "trans_id=$trans_id\n",
		 "comment=$comment",
		 "left=$left\n",
		 "right=$right\n",
		 "strand=$strand\n",
		 "left_trunc=$left_trunc\n",
		 "right_trunc=$right_trunc\n",
		 );
	}
    }
    
    
    my $fh_sco;
    my $encoded_tbl = [];
    open($fh_sco, q(<), $sco_file) or die qq(Could not read-open sco_file=\"$sco_file\");
    while (defined($line = <$fh_sco>)) {
	chomp $line;
	if ($line =~ m/^\# Sequence Data:.*seqhdr=\"([^\"]+)\"/o) {
	    $contig_id = $1;
	    next;
	}
	
	if ($line =~ m/^\# Model Data/o) {
	    next;
	}
	
	if (my ($num, $left, $right, $strand) = ($line =~ m/^\>(\d+)_(\d+)_(\d+)_([+-])/o)) {
	    my ($beg, $end, $trunc_flag);
	    
	    if (my ($seq, $trunc_left, $trunc_right) = @ { $transH{"$contig_id\t$left\t$right\t$strand"} })
	    {
		my $len = 1 + $right - $left;
		
		if ($strand eq q(+)) {
		    ($beg, $end) = ($left, $right);
		    $trunc_flag = "$trunc_left,$trunc_right";
		}
		else {
		    ($beg, $end) = ($right, $left);
		    $trunc_flag = "$trunc_right,$trunc_left";
		}
		
		push @$encoded_tbl, [$contig_id, $beg, $end, $strand, $len, $seq, $trunc_flag];
	    }
	    else {
		warn "No translation found for \"$sco_file\" line: $line\n";
	    }
	}
	else {
	    warn "Could not parse calls for \"$sco_file\" line: $line\n";
	}
    }
    close($fh_sco);
#   die Dumper($encoded_tbl);
    
#...Cleanup...
    unless ($ENV{DEBUG}) {
	my $err;
	rmtree($tmp_dir, { error => \$err});
	if (ref($err) && @$err)
	{
	    warn "Error during rmtree $tmp_dir: " . Dumper($err);
	}
    }
    
    return wantarray ? ($encoded_tbl, $event) : $encoded_tbl;
}

1;
