########################################################################

# This is a SAS Component

use strict;
use warnings;

use SeedEnv;
use ProtSims;
use gjoseqlib;
use Data::Dumper;

my $usage = "usage: find_approx_neigh  GenomeDir [MaxNum]";
my $gdir;

$| = 1;

my $sapO = SAPserver->new;

#...Process @ARGV...
my $trouble = 0;
while (@ARGV && ($ARGV[0] =~ m/^-/o)) {
    if    ($ARGV[0] =~ m/^-{1,2}help/o) {
	print STDERR (qq(\n  ), $usage, qq(\n));
	exit(0);
    }
    else {
	$trouble = 1;
	warn qq(Unrecognized switch \'$ARGV[0]\'\n);
	$trouble = 1;
    }
    
    shift @ARGV;
}
die "\n   $usage\n\n" if $trouble;

($gdir =  shift @ARGV)   || die $usage;
$gdir  =~ s/\/$//o;
($gdir =~ /(\d+\.\d+)$/) || die "Invalid Genome Directory: $gdir";
my $gdir_id = $1;

my $max_num = (@ARGV > 0) ? $ARGV[0] : 30;


my @fasta = ();
if (-d "$gdir/Features/peg")  {
    push @fasta, &gjoseqlib::read_fasta("$gdir/Features/peg/fasta");
}
elsif ((@fasta < 500) && (-d "$gdir/Features/orf")) {
    push @fasta, &gjoseqlib::read_fasta("$gdir/Features/orf/fasta");
}
else {
    die "No translatable features found in OrgDir=$gdir";
}

my %id2seqH = map { ($_->[2] && (length($_->[2]) > 30)) ? ($_->[0] => $_->[2]) : () } @fasta;

my @poss_pegs = &prioritize_pegs_used_to_find_neighbors($gdir);
my %counts;
my $best  = 0;
my $tuple;
while (($best < 500) && ($tuple = shift @poss_pegs)) {
    my($role,$peg) = @$tuple;
    if ($id2seqH{$peg} && (length($id2seqH{$peg}) > 30)) {
	&compute_hits_and_set_best($tuple, \%id2seqH, \%counts, \$best);
    }
}

if ($best == 0) {
    print STDERR "WARNING: $gdir describes a genome without enough RAST-called genes to identify neighbors\n";
    exit(0);
}

my @reference = sort { $counts{$b} <=> $counts{$a} } keys(%counts);
if (@reference > $max_num) { $#reference = $max_num-1 }

my $genomesH  = $sapO->all_genomes(-complete => 1);
foreach my $g2 (@reference) {
    if (($g2 ne $gdir_id) && defined($genomesH->{$g2})) {
	print STDOUT (join("\t",($g2, $counts{$g2}, $genomesH->{$g2})), "\n");
    }
}

sub prioritize_pegs_used_to_find_neighbors {
    my($gdir) = @_;
    
    my %func_of;
    my $functions_file;
    if    (-s ($functions_file = "$gdir/proposed_functions")) {
	foreach my $line (&SeedUtils::file_read($functions_file)) {
	    if ($line =~ /^(fig\|\d+\.\d+\.(peg|orf)\.\d+)\t(\S[^\#]+\S)/) {
		$func_of{$1} = $3;
	    }
	}
    }
    
    if ((scalar keys %func_of) < 200) {
	if (-s ($functions_file = "$gdir/proposed_non_ff_functions")) {
	    foreach my $line (&SeedUtils::file_read($functions_file)) {
		if ($line =~ /^(fig\|\d+\.\d+\.(peg|orf)\.\d+)\t(\S[^\#]+\S)/) {
		    if (not defined($func_of{$1})) { $func_of{$1} = $3; }
		}
	    }
	}
    }
    
    if ((scalar keys %func_of) < 200) {
	if (-s ($functions_file = "$gdir/assigned_functions")) {
	    foreach my $line (&SeedUtils::file_read($functions_file)) {
		if ($line =~ /^(fig\|\d+\.\d+\.(peg|orf)\.\d+)\t(\S[^\#]+\S)/) {
		    if (not defined($func_of{$1})) { $func_of{$1} = $3; }
		}
	    }
	}
    }
    
    if ((scalar keys %func_of) == 0) {
	print STDERR "WARNING: $gdir contains no assigned functions\n";
	exit(0);
    }
    
    
    my %by_func;
    foreach my $peg (keys(%func_of)) {
	my $func = $func_of{$peg};
	$func =~ s/\s*\#.*$//;
	push @ { $by_func{$func} }, $peg;
    }
    
    my @synthetases        = map {[$_,$by_func{$_}->[0]] } grep { @{$by_func{$_}} == 1 } grep { $_ =~ /tRNA synthetase/o   } keys(%by_func);
    my @ribosomal_proteins = map {[$_,$by_func{$_}->[0]] } grep { @{$by_func{$_}} == 1 } grep { $_ =~ /ribosomal protein/o } keys(%by_func);
    my @ok_pegs            = map {[$_,$by_func{$_}->[0]] } grep { @{$by_func{$_}} == 1 }                                     keys(%by_func);

    if ($ENV{VERBOSE} || $ENV{DEBUG}) {
	print STDERR (q(Found ),
		      (scalar @synthetases), q( unique synthetases, ),
		      (scalar @ribosomal_proteins), q( unique ribosomal proteins, ),
		      (scalar @ok_pegs), q( PEGs with unique function),
		      qq(\n)
		      );
    }
    
    my @prioritized = ();
    my %seen;
    foreach my $tuple (@synthetases,@ribosomal_proteins,@ok_pegs) {
	if (! $seen{$tuple->[0]}) {
	    $seen{$tuple->[0]} = 1;
	    push(@prioritized,$tuple);
	}
    }
    return @prioritized;
}

sub compute_hits_and_set_best {
    my ($tuple, $id2seqH, $counts, $bestP) = @_;

    my ($role, $peg) = @$tuple;
    my $figfam_pegs  = &figfam_pegs_for_role($role);
    my @sims         = &ProtSims::blastP([[$peg, '', $id2seqH->{$peg}]], $figfam_pegs, 10);
    
    for (my $i=0; (($i < @sims) && ($i < 50)); ++$i) {
	my $g2 = &SeedUtils::genome_of($sims[$i]->id2);
	$counts->{$g2} += 50 - $i;
	if ($counts->{$g2} > $$bestP) { $$bestP = $counts->{$g2} }
    }
}

sub figfam_pegs_for_role {
    my ($role) = @_;
    
    my %figfams;
    
    my $res = $sapO->all_figfams(-roles => $role);
    my @pegs;
    for my $ff (keys %$res) {
	my $fids = $sapO->figfam_fids(-id => $ff);
	push(@pegs, @$fids);
    }

    my $idsH = $sapO->ids_to_sequences(-ids => \@pegs, -protein => 1);

    return [map { my $seq = $idsH->{$_}; $seq ? [$_,'',$seq] : () } keys(%$idsH)];
}
