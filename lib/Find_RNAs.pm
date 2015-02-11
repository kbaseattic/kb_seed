# -*- perl -*-

package Find_RNAs;

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
use IPC::Run;
use gjoseqlib;

sub find_rnas
{
    my ($params) = @_;
    my $rna_tool = 'search_for_rnas';
    
    my $orgID   = $params->{-orgID}   or die "missing -orgID parameter";
    my $genus   = $params->{-genus}   or die "missing -genus parameter";
    my $species = $params->{-species} or die "missing -species parameter"; 
    my $domain  = $params->{-domain}  or die "missing -domain parameter";
    my $contigs = $params->{-contigs} or die "missing -contigs parameter";
    
    #
    # Create temporary directory and FASTA for the contig data.
    #
#     my $tmp_dir = tempdir( DIR => (defined($params->{-tmpdir})
# 				   ? $params->{-tmpdir}
# 				   : q(/scratch/tmpdir_find_rnas_XXXXXXXX))
# 			   );

    my $tmp_dir = tempdir( q(tmpdir_search_for_rnas_XXXXXXXX),
			   (defined($params->{-tmpdir})
			    ? (DIR => $params->{-tmpdir})
			    : (TMPDIR => 1)));

    print STDERR "contig=$tmp_dir\n" if $ENV{DEBUG};
    
    #...Logfile will always be non-null, so no need to test it later...
    my $logfile = defined($params->{-log}) ? $params->{-log} : "$tmp_dir/find_rnas.log";
    
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
    

    
    my $tmp  = "$tmp_dir/tmp";
    my $tmp2 = "$tmp_dir/tmp";
    
    my $tbl  = "$tmp_dir/tbl";
    my $tbl2 = "$tmp_dir/tbl2";
    
    my $opt_rna_types = $params->{-rnas} ? "-rnas=$params->{-rnas}" : "";
    my @cmd = ($rna_tool, $opt_rna_types, "--contigs=$tmp_contigs_filename", "--orgid=1",
	       "--domain=$domain", "--genus=$genus", "--species=$species");
    warn "Run: @cmd\n" if $ENV{DEBUG}
;
    my $hostname = `hostname`;
    chomp $hostname;
    my $event = {
	tool_name => $rna_tool,
	execute_time => scalar gettimeofday,
	parameters => \@cmd,
	hostname => $hostname,
    };
    
    #
    # Need to clear the PERL5LIB from the environment since tool is configured to use its own.
    #
    my $ok = IPC::Run::run(\@cmd,
		  '>', $tbl,
		  '2>', $logfile,
		  init => sub {
		      chdir($tmp_dir);
		      delete $ENV{PERL5LIB};
		  });
    # my $res = system("cd $tmp_dir; env PERL5LIB= $cmd > $tbl 2> $logfile");
    if (!$ok)
    {
#	die "cmd failed with rc=$res: $cmd";
	die "cmd failed with rc=$?: @cmd\n";
    }
    
    my ($fh_tbl, $fh_tbl2);
    open($fh_tbl,  "<", $tbl)  or die "cannot read-open $tbl: $!";
    open($fh_tbl2, ">", $tbl2) or die "cannot write-open $tbl2: $!";
    
    my $ctr = 1;
    my $encoded_tbl = [];
    while (<$fh_tbl>) {
	chomp;
	my(@a)  = split(/\t/);
	
	my $new = sprintf("rna_%05d", $ctr++);
	
	print $fh_tbl2 (join("\t", $new, $a[1]), "\n");
	my ($contig, $beg, $end) = ($a[1] =~ /^(\S+)_(\d+)_(\d+)$/);
	push @$encoded_tbl, [$new, $contig, $beg, $end, $a[2]];
    }
    close($fh_tbl);
    close($fh_tbl2);
    
#...Cleanup...    
    #unlink($tmp);
    #unlink($tmp2);
    #unlink($tbl);
    #unlink($tbl2);

    rmtree($tmp_dir);
    
    return wantarray ? ($encoded_tbl, $event) : $encoded_tbl;
}

1;
