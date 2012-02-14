#########################################################################
use SeedEnv;
use gjoseqlib;

use strict;
use Data::Dumper;
use Carp;
use CorrTableEntry;

=head1 svr_update_corr_maps

Update correspondence maps after PEG insertions/deletions/function-changes

Note only updates to the given genome are reflected in the updates.

------
Example: svr_update_corr_maps -g GenomeDir

would update the 20-column correspondence tables kept in Dir/CorrToReferenceGenomes/*

------

=head2 Command-Line Options

The program is invoked using

    svr_update_corr_maps -g GenomeDir

=over 4

=item -g GenomeDir

This is used to specify a SEED genome directory.  If there is a subdirectory
CorrToReferenceGenomes containing 20-column maps to a set of reference genomes,
and if PEG insertions or deletions have occurred, this program will update
the maps (overwriting the proevious set of maps in CorrToReferenceGenomes.

=head2 Output Format

The files in CorrToReferenceGenomes (each containing a map) are updated.
Otherwise, no changes are made.

=back

=cut

use SeedEnv;
use SeedUtils;
use SAPserver;
use SeedAware;
use Getopt::Long;
use ProtSims;

my $usage = "usage: svr_update_corr_maps -g SEEDdirectory\n";

my $genome_dir;

my $rc    = GetOptions("g=s" => \$genome_dir );
if ((! $rc) || 
    (! $genome_dir) || (! -s "$genome_dir/Features/peg/tbl")
    )
{ 
    print STDERR "$usage\n"; exit 
}
my ($genome1_id) = ($genome_dir =~ /(\d+\.\d+)$/);

if (! opendir(CORR,"$genome_dir/CorrToReferenceGenomes"))
{
    print STDERR "There is no $genome_dir/CorrToReferenceGenomes directory to update\n";
    exit;
}

my @genome2s = grep { $_ =~ /^(\d+\.\d+)$/ } readdir(CORR);
closedir(CORR);
if (@genome2s == 0)
{
    print STDERR "There are no $genome_dir/CorrToReferenceGenomes/* to update\n";
    exit;
}

my $sapObject = SAPserver->new;

my $genome1 = make_genome_source($genome_dir, $sapObject);
$genome1 or die "Cannot load genome data from $genome1\n";

$genome1->init_data();
my $functions1 = {};
$genome1->get_functions($functions1);
my $aliases1 = {};
$genome1->get_aliases($aliases1);

foreach my $genome2_name (@genome2s)
{
    print STDERR "processing $genome2_name\n";

    my $genome2 = make_genome_source($genome2_name, $sapObject);
    $genome2 or die "Cannot load genome data from $genome2_name\n";

    $genome2->init_data();
    my $functions2 = {};
    $genome2->get_functions($functions2);
    my $aliases2 = {};
    $genome2->get_aliases($aliases2);

    my @old_corr = map { chop; [split(/\t/,$_)] } `cat $genome_dir/CorrToReferenceGenomes/$genome2_name`;
    my $corr = &update_correspondence(\@old_corr,$genome1,$functions1,$aliases1,$genome2,$functions2,$aliases2);
    &print_corr($corr,$genome2_name,$genome_dir);
}

sub update_correspondence {
    my($corr,$genome1,$functions1,$aliases1,$genome2,$functions2,$aliases2) = @_;

    my $deleted1 = $genome1->{deleted} ? $genome1->{deleted} : {};
    my $deleted2 = $genome2->{deleted} ? $genome2->{deleted} : {};
    my $sims1 = {};
    my $sims2 = {};
    my $not_clear = {};
    my $in_corr1 = {};
    foreach $_ (@$corr)
    {
	my($id1,$id2,$context_count,$context,$function1,$function2,$aliases1,$aliases2,$bbh,$iden,$psc,
	   $b1,$e1,$ln1,$b2,$e2,$ln2,$bit_sc,$mcount) = @$_;
	if ((! $deleted1->{$id1}) && (! $deleted2->{$id2}))
	{
	    $in_corr1->{$id1} = 1;
	    &update_best($sims1,$id1,$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$ln1,$ln2);
	    &update_best($sims2,$id2,$id1,$iden,$psc,$bit_sc,$b2,$e2,$b1,$e1,$ln2,$ln1);
	}
    }
    my @possibly_inserted_pegs = grep { ! $in_corr1->{$_} } keys(%$aliases1);
    if (@possibly_inserted_pegs > 0)
    {
	my @sims_new = &get_new_sims($genome1,$genome2,\@possibly_inserted_pegs);
	foreach my $sim (@sims_new)
	{
	    &update_best($sims1,$sim->id1,$sim->id2,$sim->iden,$sim->psc,$sim->bitsc,$sim->b1,$sim->e1,$sim->b2,$sim->e2,$sim->ln1,$sim->ln2);
	    &update_best($sims2,$sim->id2,$sim->id1,$sim->iden,$sim->psc,$sim->bitsc,$sim->b2,$sim->e2,$sim->b1,$sim->e1,$sim->ln2,$sim->ln1);
	}
    }
	
    &set_best_and_not_clear($sims1,$not_clear);
    &set_best_and_not_clear($sims2,$not_clear);
    $corr =  &build_corr($genome1,$sims1,$functions1,$aliases1,$genome2,$sims2,$functions2,$aliases2,5,1000000,$not_clear);
    return $corr;
}

sub get_new_sims {
    my($genome1,$genome2,$inserted_pegs) = @_;

    my %ins_pegs = map { $_ => 1 } @$inserted_pegs;
    my $tmp_dir = SeedAware::location_of_tmp();
    my $tmp1 = "$tmp_dir/tmp1_$$.fasta";
    my $tmp2 = "$tmp_dir/tmp2_$$.fasta";
    my $lens1 =  $genome1->get_fasta($tmp1);
    my $lens2 =  $genome2->get_fasta($tmp2);
    my @seqs1 = grep { $ins_pegs{$_->[0]} } &gjoseqlib::read_fasta($tmp1);
    my @sims = &ProtSims::blastP(\@seqs1,$tmp2,1,1);  # this last argument forces the use of blast, bypassing blat
    return @sims;
}

sub print_corr {
    my($corr,$genome2_name,$genome_dir) = @_;

    my $file = "$genome_dir/CorrToReferenceGenomes/$genome2_name";
    rename($file,$file . "~") || die "could not rename $file";
    open(CORR,">$file") || die "could not open $file";
    foreach $_ (sort { &SeedUtils::by_fig_id($a->[0],$b->[0]) } @$corr)
    {
	print CORR join("\t",@$_),"\n";
    }
    close(CORR);
}

sub build_corr {
    my($genome1,$sims1,$functions1,$aliases1,$genome2,$sims2,$functions2,$aliases2,$sz_context,$ignore_ov,$not_clear) = @_;

    my $corr = [];

    my($matching_context, $matching_count) = 
	&matching_neighbors($genome1,$sims1,$functions1,$genome2,$sims2,$functions2,$sz_context,$ignore_ov);

    foreach my $peg1 (keys(%$sims1))
    {
	my $peg2 = $sims1->{$peg1}->[0];
	if ($peg2)
	{
	    my $context = "";
	    my $context_count = 0;
	    my $function2 = "";
	    my $aliases_peg2 = "";

	    my $function1 = $functions1->{$peg1} ? $functions1->{$peg1} : "";
	    my $aliases1  = $aliases1->{$peg1}   ? $aliases1->{$peg1} : "";
	    my $peg3 = $sims2->{$peg2}->[0]; 
	    my $bbh  =  ($peg3  && ($peg3 eq $peg1)) ? "<=>" : "->";

	    if ($_ = $matching_context->{"$peg1,$peg2"})  
	    { 
		$context = $_;
		$context_count = ($context =~ tr/,//) + 1;
	    }

	    my($iden,$psc,$b1,$e1,$b2,$e2,$ln1,$ln2,$bitsc);
	    (undef,$iden,$psc,$bitsc,$b1,$e1,$b2,$e2,$ln1,$ln2) = @{$sims1->{$peg1}};
	    if ($functions2->{$peg2})  { $function2 = $functions2->{$peg2} }
	    if ($aliases2->{$peg2})    { $aliases_peg2  = $aliases2->{$peg2} }
	    my $mcount = $matching_count->{"$peg1,$peg2"};
	    $mcount = 0 unless defined($mcount);
	    push(@$corr,[$peg1,$peg2,$context_count,$context,$function1,$function2,
			 $aliases1,$aliases_peg2,$bbh,$iden,$psc,
			 $b1,$e1,$ln1,$b2,$e2,$ln2,$bitsc,$mcount,
			 (($bbh ne "<=>") || $not_clear->{$peg1}) ? 0 : 1]);
	}
    }

    foreach my $peg2 (keys(%$sims2))
    {
	my $peg1 = $sims2->{$peg2}->[0];
	if ($peg1)
	{
	    my $context = "";
	    my $context_count = 0;
	    my $function1 = "";
	    my $aliases1 = "";

	    my $function2 = $functions2->{$peg2} ? $functions2->{$peg2} : "";
	    my $aliases_peg2  = $aliases2->{$peg2}   ? $aliases2->{$peg2} : "";
	    my $peg3 = $sims1->{$peg1}->[0]; 
	    if ($peg3 ne $peg2)
	    {
		if ($_ = $matching_context->{"$peg1,$peg2"})  
		{ 
		    $context = $_;
		    $context_count = ($context =~ tr/,//) + 1;
		}
		my $mcount = $matching_count->{"$peg1,$peg2"};
		$mcount = 0 unless defined($mcount);
		my($iden,$psc,$b1,$e1,$b2,$e2,$ln1,$ln2,$bitsc);
		(undef,$iden,$psc,$bitsc,$b2,$e2,$b1,$e1,$ln2,$ln1) = @{$sims2->{$peg2}};
		if ($functions1->{$peg1})  { $function1 = $functions1->{$peg1} }
		if ($aliases1->{$peg1})    { $aliases1  = $aliases1->{$peg1} }

		push(@$corr,[$peg1,$peg2,$context_count,$context,$function1,$function2,
			     $aliases1,$aliases_peg2,"<-",$iden,$psc,
			     $b1,$e1,$ln1,$b2,$e2,$ln2,$bitsc,$mcount,0]);
	    }
	}	
    }
    return $corr;
}

sub merge {
    my($b1a,$e1a,$b2a,$e2a,$b1b,$e1b,$b2b,$e2b,$bsc1,$bsc2) = @_;

    if (($b1a < $b1b) && (abs($b1b - $e1a) < 10) &&
	($b2a < $b2b) && (abs($b2b - $e2a) < 10))
    {
	return ($b1a,$e1b,$b2a,$e2b);
    }
    elsif (($b1b < $b1a) && (abs($b1a - $e1b) < 10) &&
	   ($b2b < $b2a) && (abs($b2a - $e2b) < 10))
    {
	return ($b1b,$e1a,$b2b,$e2a);
    }
    elsif ($bsc1 >= $bsc2)
    {
	return ($b1a,$e1a,$b2a,$e2a);
    }
    else
    {
	return ($b1b,$e1b,$b2b,$e2b);
    }
}

sub matching_neighbors {
    my($genome1,$sims1,$functions1,$genome2,$sims2,$functions2,$sz_context,$ignore_ov) = @_;

    my %by_genome;
    my @peg_loc_tuples_in_genome;

    @peg_loc_tuples_in_genome = $genome1->get_peg_loc_tuples();
    $by_genome{$genome1} = &set_neighbors(\@peg_loc_tuples_in_genome, $sz_context, $ignore_ov);

    @peg_loc_tuples_in_genome = $genome2->get_peg_loc_tuples();
    $by_genome{$genome2} = &set_neighbors(\@peg_loc_tuples_in_genome, $sz_context, $ignore_ov);
    
    my %matched_pairs;
    my %matching_count;
    foreach my $peg1 (keys(%$sims1))
    {
	my $peg2   = $sims1->{$peg1}->[0];
	my $neigh1 = $by_genome{$genome1}->{$peg1};
	my $neigh2 = $by_genome{$genome2}->{$peg2};
	my %neigh2H = map { $_ => 1 } @$neigh2;
	my @pairs = ();
	my $matching_count = 0;
	foreach my $n1 (@$neigh1)
	{
	    my $maps_to = $sims1->{$n1}->[0];
	    if ($maps_to && $neigh2H{$maps_to})
	    {
		push(@pairs,"$n1:$maps_to");

		if ($functions1->{$n1} eq $functions2->{$maps_to})
		{
		    $matching_count++;
		}
	    }
	}
	$matched_pairs{"$peg1,$peg2"} = join(",",@pairs);
	$matching_count{"$peg1,$peg2"} = $matching_count;
    }
    return \%matched_pairs, \%matching_count;
}

sub set_best_and_not_clear {
    my($sims,$not_clear) = @_;

    foreach my $id (keys(%$sims))
    {
	my $bestL = $sims->{$id};
	my $best = $bestL->[0];
	if ($best->[2] > 1.0e-20) 
	{ 
	    $not_clear->{$id} = 1 ;
	}

	if     (! &ok_len($best)) 
	{ 
	    $not_clear->{$id} = 1; # poor coverage -> not-clear
	} 

	if (@$bestL > 1)
	{
	    if  (&ok_len($bestL->[1]) && 
		 (abs($best->[1] - $bestL->[1]->[1]) < 5))   # diff in identity is < 5 -> not-clear
	    {
		$not_clear->{$id} = 1;
	    }
	}
	$sims->{$id} = $best;
    }
}

sub ok_len {
    my($sim) = @_;

    my($b1,$e1,$b2,$e2,$ln1,$ln2) = @{$sim}[4..9];
    return ((($e1-$b1) >= (0.8 * $ln1)) && (($e2-$b2) >= (0.8 * $ln2)));
}

sub better {
    my($psc1,$psc2,$bsc1,$bsc2) = @_;

    return (($psc1 < $psc2) || (($psc1 == $psc2) && ($bsc1 > $bsc2)));
}

sub update_best {
    my($sims1,$id1,$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2) = @_;

    my $x = $sims1->{$id1};
    if (! $x)
    {
	$sims1->{$id1} = [[$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2]];
    }
    elsif ($x && (($x->[0]->[0] ne $id2) && &better($psc,$x->[0]->[2],$bit_sc,$x->[0]->[3])))
    {
	splice(@$x,0,0,[$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2]);
	$#{$x} = 1;
    }
    elsif ($x && ($x->[0]->[0] eq $id2))
    {
	($b1,$e1,$b2,$e2) = &merge($b1,$e1,$b2,$e2,$x->[0]->[4],$x->[0]->[5],$x->[0]->[6],$x->[0]->[7],$bit_sc,$x->[0]->[3]);
	$x->[0]->[4] = $b1;
	$x->[0]->[5] = $e1;
	$x->[0]->[6] = $b2;
	$x->[0]->[7] = $e2;
    }
    elsif ((@$x == 1) && (($x->[0]->[0] ne $id2) &&  (! &better($psc,$x->[0]->[2],$bit_sc,$x->[0]->[3]))))
    {
	$x->[1] = [$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2];
    }
    elsif ((@$x == 2) && (($x->[1]->[0] ne $id2) && ($psc < $x->[1]->[2])))
    {
	$x->[1] = [$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$len1,$len2];
    }
}

sub compare_locs {
    my($loc1,$loc2) = @_;

    my($contig1,$min1,$max1) = &SeedUtils::boundaries_of($loc1);
    my($contig2,$min2,$max2) = &SeedUtils::boundaries_of($loc2);
    return (($contig1 cmp $contig2) or (($min1+$max1) <=> ($min2+$max2)));
}

sub set_neighbors {
    my($peg_loc_tuples,$N,$ignore_ov) = @_;

    my $peg_to_neighbors = {};
    my $i;

    for ($i=0; ($i < @$peg_loc_tuples); $i++)
    {
	my($contigI,$minI,$maxI) = &SeedUtils::boundaries_of($peg_loc_tuples->[$i]->[1]);
	$contigI || confess "BAD";
	my $neighbors = [];
	my $j = $i-1;
	my $to_add = $N;
	while (($j >= 0) && ($to_add > 0) && 
	       &same_contig($peg_loc_tuples->[$j]->[1],$contigI))
	{
	    $j--;
	    if (&distinct($peg_loc_tuples->[$j]->[1],$peg_loc_tuples->[$j+1]->[1],$ignore_ov))
	    {
		$to_add--;
	    }
	}
	$j++;
	while ($j < $i) { push(@$neighbors,$peg_loc_tuples->[$j]->[0]); $j++ }

	$j = $i+1;
	$to_add = $N;
	while (($j < @$peg_loc_tuples) && ($to_add > 0) &&
	       &same_contig($peg_loc_tuples->[$j]->[1],$contigI))
	{
	    push(@$neighbors,$peg_loc_tuples->[$j]->[0]);
	    if (&distinct($peg_loc_tuples->[$j]->[1],$peg_loc_tuples->[$j-1]->[1],$ignore_ov))
	    {
		$to_add--;
	    }
	    $j++;
	}
	$peg_to_neighbors->{$peg_loc_tuples->[$i]->[0]} = $neighbors;
    }
    return $peg_to_neighbors;
}

sub distinct {
    my($x,$y,$ignore_ov) = @_;

    return ($ignore_ov > &overlap($x,$y));
}

sub overlap {
    my($x,$y) = @_;

    my($contig1,$min1,$max1) = &SeedUtils::boundaries_of($x);
    my($contig2,$min2,$max2) = &SeedUtils::boundaries_of($y);
    if ($contig1 ne $contig2) { return 0 }
    if (&SeedUtils::between($min1,$min2,$max1)) { return ($max1 - $min2)+1 }
    if (&SeedUtils::between($min2,$min1,$max2)) { return ($max2 - $min1)+1 }
    return 0;
}

sub same_contig {
    my($entry,$contig) = @_;

    $contig || confess "BAD";
    my($contig1,$minI,$maxI) = &SeedUtils::boundaries_of($entry);
    return ($contig eq $contig1);
}

sub make_genome_source
{
    my($name, $sap) = @_;

    if ($name =~ /^\d+\.\d+$/)
    {
	return SapGenomeSource->new($name, $sap);
    }
    elsif (-d $name)
    {
	my %deleted;
	if (-s "$name/Features/peg.deleted.features")
	{
	   %deleted  = map { $_ =~ /^(\S+)/; ($1 => 1) } `cut -f1 $name/Features/peg/deleted.features`;
       }

	my $fasta = "$name/Features/peg/fasta";
	
	my $tbl = "$name/Features/peg/tbl";

	if (! -f $fasta)
	{
	    die "No fasta found in $fasta\n";
	}
	if (! -f $tbl)
	{
	    die "No tbl file found in $tbl\n";
	}

	#
	# We might have multiple functions files. If there are,
	# collapse into one based on the usual RAST
	# rules (old assigned funcs overwritten by
	# auto-assign funcs overwritten by FIGfams funcs).
	#

	my @files;
	foreach my $file (qw(assigned_functions proposed_non_ff_functions proposed_functions))
	{
	    if (-f "$name/$file")
	    {
		push(@files, "$name/$file")
	    }
	}
	if (@files == 0)
	{
	    die "No functions file found for $name\n";
	}
	return SapFileSource->new($fasta, $tbl, \@files, \%deleted);
    }
    else
    {
	#
	# Must be a comma-sep triple
	#
	my @x = split(/,/, $name);
	if (@x != 3)
	{
	    die "Invalid genome specifier: $name\n";
	}
	my($fasta, $tbl, $func) = @x;
	if (! -f $fasta)
	{
	    die "No fasta found in $fasta\n";
	}
	if (! -f $tbl)
	{
	    die "No tbl file found in $tbl\n";
	}
	if (! -f $func)
	{
	    die "No function file found in $func\n";
	}

	return SapFileSource->new($fasta, $tbl, [$func], {});
    }
}

package SapFileSource;
use strict;

sub new
{
    my($class, $fasta, $tbl, $func_files,$deleted) = @_;
    my $self = {
	fasta => $fasta,
	tbl => $tbl,
	deleted => $deleted,
	func_files => $func_files,
    };
    bless $self, $class;
    return $self;
}

sub init_data
{
    my($self) = @_;

    my $deleted = $self->{deleted} ? $self->{deleted} : {};
    open(TBL, "<", $self->{tbl}) or die "Cannot read $self->{tbl}: $!";
    
    while (<TBL>)
    {
        chomp;
	my($id, $loc, @aliases) = split(/\t/);
	if (! $deleted->{$id})
	{
	    $self->{aliases}->{$id} = [@aliases];
	}
    }
    close(TBL);
}

sub get_fasta
{
    my($self, $file) = @_;
    
    my $deleted = $self->{deleted} ? $self->{deleted} : {};
    my @seqs = grep { ! $deleted->{&SeedUtils::genome_of($_->[0])} }  &gjoseqlib::read_fasta($self->{fasta});
    &gjoseqlib::print_alignment_as_fasta($file,\@seqs);
    my $lens = {};
    foreach $_ (@seqs)  { $lens->{$_->[0]} = length($_->[2]) }
    return $lens;
}

sub get_functions
{
    my($self, $hash) = @_;
    my $deleted = $self->{deleted} ? $self->{deleted} : {};

    for my $file (@{$self->{func_files}})
    {
	open(FFILE, "<", $file) or die "Cannot read $file: $!";
	while (<FFILE>)
	{
	    chomp;
	    my($id, $fn) = split(/\t/);
	    if (! $deleted->{$id})
	    {
		$hash->{$id} = $fn;
	    }
	}
	close(FFILE);
    }
}

sub get_aliases
{
    my($self, $hash) = @_;
    my $deleted = $self->{deleted} ? $self->{deleted} : {};
    for my $key (keys % {$self->{aliases}})
    {
	if (! $deleted->{$key})
	{
	    $hash->{$key} = join(",", @{$self->{aliases}->{$key}});
	}
    }
}

sub get_peg_loc_tuples
{
    my($self) = @_;
    my $deleted = $self->{deleted} ? $self->{deleted} : {};
    my @all_fids = grep { ! $deleted->{$_} } keys(%{$self->{loc}});;

    my @peg_loc_tuples_in_genome =
	sort { &main::compare_locs($a->[1],$b->[1]) }
 	    map { [$_, [split(/,/,$self->{loc}->{$_})]] }
	    @all_fids;
    return @peg_loc_tuples_in_genome;
}

package SapGenomeSource;

sub new
{
    my($class, $genome, $sap) = @_;
    my $self = {
	genome => $genome,
	sap => $sap,
    };

    return bless $self, $class;
}

sub init_data
{
    my($self) = @_;
    my $genome = $self->{genome};
    my $sap = $self->{sap};
    
    my $fidHash  = $sap->all_features(-ids => $genome, -type => 'peg');
    $self->{all_fids} = $fidHash->{$genome};

    if (@{$self->{all_fids}} == 0)
    {
	die "Could not load pegs for $genome\n";
    }
    
    my $locHash  = $sap->fid_locations(-ids => $self->{all_fids});
}

sub get_functions
{
    my($self, $hash) = @_;

    my $fns = $self->{sap}->ids_to_functions(-ids => $self->{all_fids});
    $hash->{$_} = $fns->{$_} for keys %$fns;
}

sub get_aliases {
    my($self, $aliases) = @_;
    
    my $aliasHash = $sapObject->fids_to_ids(-ids => $self->{all_fids});

    foreach my $peg (keys %$aliasHash)
    {
	my $typeH = $aliasHash->{$peg} ? $aliasHash->{$peg} : {};
	my @all_aliases = map { @{$typeH->{$_}} } keys(%$typeH);
	my $aliasStr = (@all_aliases > 0) ? join(",",@all_aliases) : "";
	$aliases->{$peg} = $aliasStr;
    }
    return $aliases;
}

sub get_peg_loc_tuples
{
    my($self) = @_;

    my $locHash  = $sapObject->fid_locations(-ids => $self->{all_fids});
    my @peg_loc_tuples_in_genome =
	sort { &main::compare_locs($a->[1],$b->[1]) }
 	    map { [$_,$locHash->{$_}] }
 	    keys(%$locHash);
    return @peg_loc_tuples_in_genome;
}

sub get_fasta {
    my($self, $file) = @_;

    my $lens = {};
    my $fastaHash = $sapObject->ids_to_sequences(-ids => $self->{all_fids},
						 -protein => 1);

    open(FASTA,">$file") || die "could not open $file";
    foreach my $peg (keys(%$fastaHash))
    {
	my $seq = $fastaHash->{$peg};
	if ($seq)
	{
	    print FASTA ">$peg\n$seq\n";
	    $lens->{$peg} = length($seq);
	}
    }
    close(FASTA);
    return $lens;
}
	
