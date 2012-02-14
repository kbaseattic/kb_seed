# -*- perl -*-
# This is a SAS Component
#########################################################################
# Copyright (c) 2011 University of Chicago and Fellowship
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
#########################################################################

use strict;
use warnings;

use SeedUtils;
use gjoseqlib;

use URI::Escape;
# use Carp qw(cluck);
use Data::Dumper;


=head1 svr_inherit_annotations

Cause a new genome to inherit annotations from an existing
genome for protein-encoding genes that are unique within each
genome and that have identical translations.

------

Example:

    svr_inherit_annotations OldSEEDdir NewSEEDdir User

would alter the contents of the NewSEEDdir.  Each directory may
contain a file called "rewrite.functions".  These are 2-column
tables [function,normalized.function].  We will speak of
"corresponding genes".  These are genes that can unambiguously be
identified in each genome, and they have identical translations.


    1. The assigned functions will be calculated as follows:

       Let Gn be a gene in the new genome.  The rewrite.functions in the
       new directory will be a superset of the rewrite.functions in the old directory.

       Let Fn be the initial function of Gn (the value in the
       assigned_functions file).  If the rewrite.functions specifies a
       rewrite to Fn' for Fn, then Fn' is the value placed into the
       assigned_functions file (and an annotation indicating the change
       is recorded).  If there is no rewrite rule in the old
       rewrite.functions, and there is a corresponding gene in the old
       directory with function Fo and Fo is not Fn, then Fo is the
       value placed in the new assigned_functions, and

           a. Fn -> Fo becomes a rewrite in the new rewrite.functions,

           b. an annotation is added designating the change (at the current time).

       Otherwise, Fn is retained.

    2. The annotations in the new directory become a merge of the annotations
       in the old and new directories.

------

=head2 Command-Line Options

=over 4

=item oldSEEDdir

This is a path to the old SEED directory from which assignments and annotations
are inherited

=item newSEEDdir

This is a path to the new SEED directory which inherits assignments and annotations.

-item User

This is the user credited with making the changes to the functions 

=back

=cut


my $usage  = "usage: svr_inherit_annotations oldSEEDdir newSEEDdir User";

my($oldD,$newD,$user);

(($oldD = shift @ARGV) && (-d $oldD)) || die "$usage";
(($newD = shift @ARGV) && (-d $newD)) || die "$usage";
($user  = shift @ARGV) || die "you need to give a User: $usage";

my ($oldOrgID) = ($oldD =~ m/(\d+\.\d+)$/);
my ($newOrgID) = ($newD =~ m/(\d+\.\d+)$/);

if (-s "$newD/rewrite.functions") {
    die "$newD/rewrite.functions already exists; delete it and rerun, if it is ok to do so";
}

if (-s "$oldD/rewrite.functions") {
    &run("cp $oldD/rewrite.functions $newD/rewrite.functions");
}

my $rewriteH = &load_rewrite("$newD/rewrite.rules");

&verify_exists("$oldD/Features/peg/fasta");
&verify_exists("$newD/Features/peg/fasta");

my ($mapL, $uniqueH) = &get_correspondence("$oldD/Features/peg/fasta",
					   "$newD/Features/peg/fasta");
open( MAP, ">>$newD/inheritance.id_map") || die "Could not write-open \'$newD/inheritance.id_map\'";
print MAP map { (join(q(,), @ { $_->[0] }), qq(\t),
		 join(q(,), @ { $_->[1] }), qq(\n) 
		 )
		} (sort { &SeedUtils::by_fig_id($a->[0]->[0], $b->[0]->[0]) } @$mapL);
close(MAP);

&update_functions($oldD, $newD, $uniqueH, $rewriteH, $user);
&update_annotations($oldOrgID, $newOrgID, $oldD, $newD, $uniqueH);
&update_rewrite($rewriteH, "$newD/rewrite.rules");

print STDERR qq(Successful completion of \`svr_inherit_annotations\`\n) if $ENV{VERBOSE};
exit(0);


sub update_functions {
    my ($oldD, $newD, $uniqueH, $rewriteH, $user) = @_;
    
    my $funcsN = &load_funcs("$newD/assigned_functions");
    my $funcsO = &load_funcs("$oldD/assigned_functions");
    
    my $func_fh;
    open($func_fh, ">>$newD/assigned_functions")
	|| die "Could not append-open file \'$newD/assigned_functions\'";
    
    my $anno_fh;
    open($anno_fh, ">>$newD/annotations")
	|| warn "Could not append-open file \'$newD/annotations\'";
    print STDERR "Append-opened $newD/annotations in update_functions" if $ENV{VERBOSE};
    
    foreach my $pegN (keys(%$funcsN))
    {
	my($pegO,$fO,$fn,$fn1);
	$fn = $funcsN->{$pegN};
	if ($fn1 = $rewriteH->{$fn})
	{
	    $funcsN->{$pegN} = $fn1;
	    &assign_function($pegN, $fn1, $user,
			     qq(Based on rewrite rule for function \'$fn\'),
			     $func_fh, $anno_fh);
	}
	elsif (defined($pegO = $uniqueH->{$pegN}) && $pegO && ($fO = $funcsO->{$pegO}) && ($fO ne $fn))
	{
	    $rewriteH->{$fn} = $fO;
	    &assign_function($pegN, $fO, $user,
			     qq(Based on inheritance from PEG $pegO),
			     $func_fh, $anno_fh);
	}
    }
    close($anno_fh);
    close($func_fh);
    
    return;
}

sub assign_function {
    my ($new_peg, $func, $user, $reason, $func_fh, $anno_fh) = @_;
    
    warn ("bad call to assign_function:\n",
	  join("\n", ($new_peg,$func,$user)),
	  "\n")
	unless ($new_peg && $func && $user);
    
    unless (print $func_fh ($new_peg, "\t", $func, "\n")) {
	die qq(Could not update function for user=$user, peg=$new_peg, func=$func);
    }
    
    my $time = time;
    if ($new_peg && $user && $func && $time) {
	unless (print $anno_fh (join("\n", ($new_peg, $time, $user,
					    "Set master function to", $func,
					    $reason
					    )
				     ),
				"\n//\n")
		) {
	    die qq(Could not update annotation for user=$user, peg=$new_peg, func=$func);
	}
    }
    else {
	die qq(Malformed update annotation with user=$user, peg=$new_peg, func=$func);
    }
    
    return;
}

sub load_funcs {
    my($assignF) = @_;
    
    my $assignments = {};
    
    if (open(ASSF,"<$assignF")) {
	while (defined($_ = <ASSF>)) {
	    if ($_ =~ /^(\S+)\t(\S[^\t]+\S)/) {
		$assignments->{$1} = $2;
	    }
	}
	close(ASSF);
    }
    else {
	print STDERR "No existing assigned_functions in $assignF\n";
    }
    return $assignments;
}

sub update_annotations {
    my ($oldOrgID, $newOrgID, $oldD, $newD, $uniqueH) = @_;
    
    my $annoL = [];
    &load_annotations($oldD, $annoL);
    &load_annotations($newD, $annoL);
    
    if (-s "$newD/annotations") {
	rename("$newD/annotations","$newD/annotations~");
	system('cp', "$newD/annotations~", "$newD/annotations")
	    && die "Could not recopy \'$newD/annotations~\' to  \'$newD/annotations\'";
	warn "File \'$newD/annotations\' renamed and copied" if $ENV{VERRBOSE};
    }
    open(ANNO,">$newD/annotations") || die "could not open $newD/annotations";
    warn "Write-opened \'$newD/annotations\' in update_annotations" if $ENV{VERRBOSE};
    
    foreach my $tuple (sort {  ($a->[0] <=> $b->[0])
			    || &SeedUtils::by_fig_id($a->[1], $b->[1])
			    || ($a->[2] cmp $b->[2])
			    || ($a->[3] cmp $b->[3])
			} @$annoL)
    {
	my ($ts,$peg,$user,$anno) = @$tuple;
	
	if ($ts && $peg && $user && $anno) {
	    next if ((&SeedUtils::genome_of($peg) eq $oldOrgID) && ($oldOrgID ne $newOrgID));
	    unless (print ANNO (join("\n",($peg,$ts,$user,$anno)), "\n//\n")) {
		die qq(Could not update annotation for user=$user, peg=$peg, time=$ts, anno=$anno);
	    }
	}
	else {
	    warn "Malformed annotation: user=$user, peg=$peg, anno=$anno";
	}
    }
    close(ANNO);
}

sub load_annotations {
    my ($dir, $annoL) = @_;
    
    if ($ENV{VERBOSE}) {
	print STDERR "Read-opening $dir/annotations in load_annotations\n";
    }
    
    if (open(ANNO,"<$dir/annotations"))
    {
	$/ = "\n//\n";
	while (defined(my $_ = <ANNO>))
	{
	    chomp;
	    my @lines = split(/\n|\r/,$_);
	    my ($peg, $ts, $user, @rest) = @lines;
	    
	    if ($peg && $ts && $user) {
		push @$annoL, [$ts, $peg, $user, join("\n",@rest)];
	    }
	    else {
		warn ("Read malformed annotation at record=$.:\n$_", "==>\n", join("\n", @lines));
	    }
	}
	close(ANNO);
    }
}

sub load_rewrite {
    my($file) = @_;

    my $rewriteH = {};
    if (open(REWRITES,"<$file")) {
	while (defined($_ = <REWRITES>)) {
	    if ($_ =~ /^(\S[^\t]+\S)\t(\S[^\t+]\S)$/) {
		$rewriteH->{$1} = $2;
	    }
	}
	close(REWRITES);
    }
    return $rewriteH;
}

sub update_rewrite {
    my($rewriteH, $file) = @_;

    if (open(REWRITES,">$file")) {
	foreach my $rule (sort keys %$rewriteH) {
	    print REWRITES ($rule, "\t", $rewriteH->{$rule}, "\n");
	}
	close(REWRITES);
    }
}

sub get_correspondence {
    my($oldF,$newF) = @_;
    
    my %old;
    my @old = &gjoseqlib::read_fasta($oldF);
    foreach $_ (@old) {
	push @ { $old{$_->[2]} }, $_->[0];
    }
    
    my %new;
    my @new = &gjoseqlib::read_fasta($newF);
    foreach $_ (@new) {
	push @ { $new{$_->[2]} }, $_->[0];
    }
    
    my $mapL    = [];
    my $uniqueH = {};
    foreach my $seqN (keys(%new)) {
	if (defined($old{$seqN}) && defined($new{$seqN})) {
	    my @old_IDs = sort { &SeedUtils::by_fig_id($a,$b) }  (@ { $old{$seqN} });
	    my @new_IDs = sort { &SeedUtils::by_fig_id($a,$b) }  (@ { $new{$seqN} });
	    
	    push @$mapL, [ [@new_IDs], [@old_IDs] ];
	    
	    if ((@old_IDs == 1) && (@new_IDs == 1)) {
		$uniqueH->{$new_IDs[0]} = $old_IDs[0];
	    }
	}
    }
    return ($mapL, $uniqueH);
}

sub verify_exists {
    my($file) = @_;

    if (! -s $file)
    {
	die "$file either does not exist or is empty";
    }
}

sub run {
    my($cmd) = @_;

    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
