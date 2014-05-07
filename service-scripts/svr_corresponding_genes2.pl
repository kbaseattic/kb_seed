#########################################################################
use SeedEnv;
use gjoseqlib;

use strict;
use JSON::XS;
use Data::Dumper;
use Carp;
use CorrTableEntry;

=head1 svr_corresponding_genes2

Attempt to Tabulate Corresponding Genes from Two Complete Genomes

------
Example: svr_corresponding_genes2 107806.1 198804.1

would produce a 20-column table that is an attempt to present the
correspondence between the genes in two genomes (in this case
107806.1 and 198804.1, which are two Buchnera genomes).
------

There is no input other than the command-line arguments.  The two genomes
must be specified, and there are two optional arguments that relate to determining
how to determine the "context" of genes.

One important aspect of the tool is that it tries to establish the correspondence,
and then for a corresponding pair of genes Ga and Gb, it attemptes to determine
how many genes in the "context" of Ga map to genes in the "context" of Gb.  This is 
important, since preservation of context increases the confidence of the mapping
between Ga and Gb considerably.  The optional parameters effect the determination
of the genes in the "context".  Using

    -n 5

would indicate that the context of G should include 5 distinct genes 
to the left of G and 5 distinct genes to the right of G.  This notion of distinct
was added due to the existence of numerous splice variants in some eukaryotic
genomes.  Genes are considered to be distinct if the size of the overlap
between the genes is less than a threshhold.  The threshhold can be set using
the -o parameter.  Thus, use of 

    -o 1000

would indicate that two genes are distinct iff the boundaries of the two genes 
overlap by less than 1000 bp.  The default is a very high value, so if you specify
nothing (which is appropriate for prokaryotic genomes), any two genes will be 
considered distinct.

=head2 Command-Line Options

The program is invoked using

    svr_corresponding_genes [-u ServerUrl] [-n HalfSzOfContext] [-o MaxOverlap] GenomeSpec1 GenomeSpec2

=over 4

=item -n HalfSizeOfRegion

This is used to specify how many genes to the left and right you want to
be considered in the context.  The default is 10.

=item -o MaxOverlap

This allows the user the specify a maximum overlap that would result in two genes
being considered "distinct" in the computation of genes to be added to the context.
It defaults to a very large value.

=item -u ServerUrl

This allows the user to specify the URL for the Sapling server. If it is
"localhost", then the Sapling method will be run on the local SEED.

=item GenomeSpec1

=item GenomeSpec2

Specify a source of genome data. Either a genome ID (that is available in the SEED servers),
a SEED genome directory, or a comma-separated triple (protein fasta file, tbl file, function-assignment file).
    
=head2 Output Format

The standard output is a 18-column tab-delimited file:

=item Column-1
The ID of a PEG in Genome1.

=item Column-2

The ID of a PEG in Genome2 that is our best estimate of a "corresponding gene".

=item Column-3
Count of the number of pairs of matching genes were found in the context

=item Column-4

Pairs of corresponding genes from the contexts

=item Column-5

The function of the gene in Genome1

=item Column-6

The function of the gene in Genome2

=item Column-7

Aliases of the gene in Genome1 (any protein with an identical sequence
is considered an alias, whether or not it is actually the name of the
same gene in the same genome)

=item Column-8

Aliases of the gene in Genome2 (any protein with an identical sequence
is considered an alias, whether or not it is actually the name of the
same gene in the same genome)

=item Column-9

Bi-directional best hits will contain "<=>" in this column.
Otherwise, an "->" or an "<-" will appear.    

=item Column-10

Percent identity over the region of the detected match

=item Column-11

The P-sc for the detected match

=item Column-12

Beginning match coordinate in the protein encoded by the gene in Genome1.

=item Column-13

Ending  match coordinate in the protein encoded by the gene in Genome1.

=item Column-14

Length of the protein encoded by the gene in Genome1.

=item Column-15

Beginning match coordinate in the protein encoded by the gene in Genome2.

=item Column-16

Ending  match coordinate in the protein encoded by the gene in Genome2

=item Column-17

Length of the protein encoded by the gene in Genome2.

=item Column-18

Bit score for the match.  Divide by the length of the longer PEG to get
what we often refer to as a "normalized bit score".

=item Column-19

Number of pegs in the context that have matching functions.

=item Column-20

1 -> it is a clear BBH (similarity is over 80% of each peg, pegs are BBHs, there is no other
     similarity with a per cent identity within 5)
0 -> it is not a clear BBH

=back

=cut

use SeedEnv;
use SeedUtils;
use SAPserver;
use ProtSims;
use SeedAware;
use Getopt::Long;

my $usage = "usage: svr_corresponding_genes [-u SERVERURL] [-o N1] [-n N2] [-d RASTdirectory] Genome1 Genome2";

my $ignore_ov   = 1000000;
my $sz_context  = 4;
my $url;

my $rc    = GetOptions("o"              => \$ignore_ov,
                       "n=i"            => \$sz_context,
                       "u=s"            => \$url
                      );
if (! $rc) { print STDERR "$usage\n"; exit }

my $sapObject = SAPserver->new(url => $url);

my($genome1_name, $genome2_name);
(
 ($genome1_name = shift @ARGV) &&
 ($genome2_name = shift @ARGV) 
)
    || die $usage;


my $genome1 = make_genome_source($genome1_name, $sapObject);
$genome1 or die "Cannot load genome data from $genome1_name\n";

my $genome2 = make_genome_source($genome2_name, $sapObject);
$genome2 or die "Cannot load genome data from $genome2_name\n";

$genome1->init_data();
$genome2->init_data();
my $functions = {};
$genome1->get_functions($functions);
$genome2->get_functions($functions);

# print STDERR "GOT Functions\n";

my $aliases = {};
$genome1->get_aliases($aliases);
$genome2->get_aliases($aliases);

#
# If both arguments are genome ids, see if the SAP server
# has already computed this correspondence.
# 
if ((ref($genome1) eq 'SapGenomeSource') && (ref($genome2) eq 'SapGenomeSource'))
{
    my $corr = $sapObject->gene_correspondence_map(-genome1 => $genome1_name,
						   -genome2 => $genome2_name,
						   -fullOutput => 1,
						   -passive => 1);
    my $fns;
    my $out_of_date = 0;
    if (defined($corr))
    {
	foreach my $ent (@$corr)
	{
	    my $corr = bless $ent, 'CorrTableEntry';;
	    if (!defined($corr->num_matching_functions))
	    {
		my $count = 0;

		if (!defined($fns))
		{
		    #
		    # Pull all the functions for the given genomes.
		    #
		    my $fidHash  = $sapObject->all_features(-ids => [$genome1_name, $genome2_name], -type => 'peg');
		    $fns = $sapObject->ids_to_functions(-ids => [map { @$_ } values %$fidHash]);
		}

		for my $pair ($corr->pairs)
		{
		    my($p1, $p2) = @$pair;
		    my $f1 = $fns->{$p1};
		    my $f2 = $fns->{$p2};
		    $count++ if $f1 eq $f2;
		}
		$ent->[18] = $count;
	    }
	    if ((@$ent < 20) && (! $out_of_date)) { $out_of_date = 1 }
	}

	if ($out_of_date)
	{
	    $corr = &update_correspondence($corr,$genome1,$genome2,$functions,$aliases,$sz_context,$ignore_ov);
	}
	&print_corr($corr);
	exit 0;
    }
}

my $tmp_dir = SeedAware::location_of_tmp();
my $formatdb = SeedAware::executable_for("formatdb");

my $tmp1 = "$tmp_dir/tmp1_$$.fasta";
my $tmp2 = "$tmp_dir/tmp2_$$.fasta";

my $lens1 =  $genome1->get_fasta($tmp1);
my $lens2 =  $genome2->get_fasta($tmp2);
# print STDERR "GOT SIMS\n";
system($formatdb, '-i', $tmp2, '-p', 'T');

my($sims1,$sims2,$not_clear) = &get_sims($tmp1,$tmp2,$lens1,$lens2);
unlink($tmp1,$tmp2,"$tmp2.psq","$tmp2.pin","$tmp2.phr");

my $corr = &build_corr($genome1,$sims1,$genome2,$sims2,$functions,$aliases,$sz_context,$ignore_ov,$not_clear);
&print_corr($corr);

sub print_corr {
    my($corr) = @_;

    foreach my $tuple (sort { &SeedUtils::by_fig_id($a->[0],$b->[0]) } @$corr)
    {
	print join("\t",@$tuple),"\n";
    }
}

sub build_corr {
    my($genome1,$sims1,$genome2,$sims2,$functions,$aliases,$sz_context,$ignore_ov,$not_clear) = @_;

    my $corr = [];

    my($matching_context, $matching_count) = 
	&matching_neighbors($genome1,$sims1,$genome2,$sims2,$functions,$sz_context,$ignore_ov);

    foreach my $peg1 (keys(%$sims1))
    {
	my $peg2 = $sims1->{$peg1}->[0];
	if ($peg2)
	{
	    my $context = "";
	    my $context_count = 0;
	    my $function2 = "";
	    my $aliases2 = "";

	    my $function1 = $functions->{$peg1} ? $functions->{$peg1} : "";
	    my $aliases1  = $aliases->{$peg1}   ? $aliases->{$peg1} : "";
	    my $peg3 = $sims2->{$peg2}->[0]; 
	    my $bbh  =  ($peg3  && ($peg3 eq $peg1)) ? "<=>" : "->";

	    if ($_ = $matching_context->{"$peg1,$peg2"})  
	    { 
		$context = $_;
		$context_count = ($context =~ tr/,//) + 1;
	    }

	    my($iden,$psc,$b1,$e1,$b2,$e2,$ln1,$ln2,$bitsc);
	    (undef,$iden,$psc,$bitsc,$b1,$e1,$b2,$e2,$ln1,$ln2) = @{$sims1->{$peg1}};
	    if ($functions->{$peg2})  { $function2 = $functions->{$peg2} }
	    if ($aliases->{$peg2})    { $aliases2  = $aliases->{$peg2} }
	    my $mcount = $matching_count->{"$peg1,$peg2"};
	    $mcount = 0 unless defined($mcount);
	    push(@$corr,[$peg1,$peg2,$context_count,$context,$function1,$function2,
			 $aliases1,$aliases2,$bbh,$iden,$psc,
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

	    my $function2 = $functions->{$peg2} ? $functions->{$peg2} : "";
	    my $aliases2  = $aliases->{$peg2}   ? $aliases->{$peg2} : "";
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
		if ($functions->{$peg1})  { $function1 = $functions->{$peg1} }
		if ($aliases->{$peg1})    { $aliases1  = $aliases->{$peg1} }

		push(@$corr,[$peg1,$peg2,$context_count,$context,$function1,$function2,
			     $aliases1,$aliases2,"<-",$iden,$psc,
			     $b1,$e1,$ln1,$b2,$e2,$ln2,$bitsc,$mcount,0]);
	    }
	}	
    }
    return $corr;
}

sub update_correspondence {
    my($corr,$genome1,$genome2,$functions,$aliases,$sz_context,$ignore_ov) = @_;

    my $sims1 = {};
    my $sims2 = {};
    my $not_clear = {};
    foreach $_ (@$corr)
    {
	my($id1,$id2,$context_count,$context,$function1,$function2,$aliases1,$aliases2,$bbh,$iden,$psc,
	   $b1,$e1,$ln1,$b2,$e2,$ln2,$bit_sc,$mcount) = @$_;
	&update_best($sims1,$id1,$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$ln1,$ln2);
	&update_best($sims2,$id2,$id1,$iden,$psc,$bit_sc,$b2,$e2,$b1,$e1,$ln2,$ln1);
    }
    &set_best_and_not_clear($sims1,$not_clear);
    &set_best_and_not_clear($sims2,$not_clear);
    $corr =  &build_corr($genome1,$sims1,$genome2,$sims2,$functions,$aliases,$sz_context,$ignore_ov,$not_clear);
    return $corr;
}

sub get_sims {
    my($tmp1,$tmp2) = @_;

    my @sims = &ProtSims::blastP($tmp1,$tmp2,1,1);  # this last argument forces the use of blast, bypassing blat
    my $sims1 = {};
    my $sims2 = {};
    my $not_clear = {};
    
    my $last = shift @sims;
    while ($last)
    {
	my $peg1 = $last->id1;
	my @sims_for_peg = ();
	while ($last && ($last->id1 eq $peg1))
	{
	    push(@sims_for_peg,$last);
	    $last = shift @sims;
	}
	@sims_for_peg = sort { ($a->id2 cmp $b->id2) or ($b->iden <=> $a->iden) } @sims_for_peg;
	foreach $_ (@sims_for_peg)
	{
	    my($id1,$id2,$iden,undef,undef,undef,$b1,$e1,$b2,$e2,$psc,$bit_sc,$ln1,$ln2) = @$_;
	    &update_best($sims1,$id1,$id2,$iden,$psc,$bit_sc,$b1,$e1,$b2,$e2,$ln1,$ln2);
	    &update_best($sims2,$id2,$id1,$iden,$psc,$bit_sc,$b2,$e2,$b1,$e1,$ln2,$ln1);
	}
    }
    &set_best_and_not_clear($sims1,$not_clear);
    &set_best_and_not_clear($sims2,$not_clear);
	
    return ($sims1,$sims2,$not_clear);
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
    my($genome1,$sims1,$genome2,$sims2,$functions,$sz_context,$ignore_ov) = @_;

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

		if ($functions->{$n1} eq $functions->{$maps_to})
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
#	if ($id eq "fig|224325.1.peg.418") { print STDERR &Dumper($id,$bestL) }
	my $best = $bestL->[0];
	if ($best->[2] > 1.0e-20) 
	{ 
#	    if ($id eq "fig|224325.1.peg.418") { print STDERR &Dumper($best); die "aborted" }
	    $not_clear->{$id} = 1 ;
	}

	if     (! &ok_len($best)) 
	{ 
	    $not_clear->{$id} = 1; # poor coverage -> not-clear
#	    if ($id eq "fig|224325.1.peg.418") { print STDERR &Dumper($best); die "aborted" }
	} 

	if (@$bestL > 1)
	{
	    if  (&ok_len($bestL->[1]) && 
		 (abs($best->[1] - $bestL->[1]->[1]) < 5))   # diff in identity is < 5 -> not-clear
	    {
#		if ($id eq "fig|224325.1.peg.418") { print STDERR &Dumper($bestL); die "aborted"; }
		$not_clear->{$id} = 1;
	    }
	}
#	if ($id eq "fig|224325.1.peg.418") { print STDERR &Dumper($id,$best,$not_clear->{$id}) }
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


sub get_aliases {
    my($sapObject,$pegs) = @_;
    
    my $aliases = {};
    my $aliasHash = $sapObject->fids_to_ids(-ids => $pegs);

    foreach my $peg (@$pegs)
    {
	my $typeH = $aliasHash->{$peg} ? $aliasHash->{$peg} : {};
	my @all_aliases = map { @{$typeH->{$_}} } keys(%$typeH);
	my $aliasStr = (@all_aliases > 0) ? join(",",@all_aliases) : "";
	$aliases->{$peg} = $aliasStr;
    }
    return $aliases;
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
	my @base_files;
	if (-f "$name/RAST")
	{
	    @base_files = qw(assigned_functions);
	}
	else
	{
	    @base_files = qw(assigned_functions proposed_non_ff_functions proposed_functions proposed_user_functions);
	}
	foreach my $file (@base_files)
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
    elsif (my @x = ($name =~ /^([^,]+),([^,]+),([^,]+)$/))
    {
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
    elsif (-f $name)
    {
	#
	# Try to parse JSON; is it a genome object?
	#
	open(F, "<", $name) or die "Cannot open $name: $!";
	my $obj;
	eval {
	    local $/;
	    undef $/;
	    my $txt = <F>;
	    $obj = decode_json($txt);
	};
	if ($@)
	{
	    die "Cannot process $name: $@\n";
	}
	return GenomeObjectSource->new($obj);
    }
}

package GenomeObjectSource;
use strict;
use gjoseqlib;
use BasicLocation;
use Data::Dumper;
use GenomeTypeObject;

sub new
{
    my($class, $obj) = @_;
    $obj = GenomeTypeObject->initialize($obj);
    my $self = {
	obj => $obj,
    };
    bless $self, $class;
    return $self;
}

sub init_data
{
}

sub get_functions
{
    my($self, $functions) = @_;

    for my $feature ($self->{obj}->features())
    {
	next unless $feature->{type} eq 'peg' || $feature->{type} eq 'CDS';
	$functions->{$feature->{id}} = $feature->{function};
    }
}

sub get_aliases
{
    my($self, $aliases) = @_;

    for my $feature ($self->{obj}->features())
    {
	next unless $feature->{type} eq 'peg' || $feature->{type} eq 'CDS';
	$aliases->{$feature->{id}} = join(",", @{$feature->{aliases}}) if ref($feature->{aliases});
    }
}

sub get_fasta
{
    my($self, $file) = @_;
    my $lengths = {};

    open(F, ">", $file) or die "cannot write $file: $!";
    for my $feature ($self->{obj}->features())
    {
	next unless $feature->{type} eq 'peg' || $feature->{type} eq 'CDS';
	print_alignment_as_fasta(\*F, [$feature->{id}, undef, $feature->{protein_translation}]);
	$lengths->{$feature->{id}} = length($feature->{protein_translation});
    }
    return $lengths;
}

sub get_peg_loc_tuples
{
    my($self) = @_;

    my @locs;
    for my $feature ($self->{obj}->features())
    {
	next unless $feature->{type} eq 'peg' || $feature->{type} eq 'CDS';
	my $loc = [map { BasicLocation->new(@$_)->String() } @{$feature->{location}}];
	push(@locs, [$feature->{id}, $loc]);
    }
    my @tuples = sort { &main::compare_locs($a->[1], $b->[1]) } @locs;
    return @tuples;
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
	    my $g = &SeedUtils::genome_of($id);
	    if ($loc =~ /^(\S+)_(\d+)_(\d+)$/)
	    {
		my($contig,$b,$e) = ($1,$2,$3);
		my $strand = ($b < $e) ? '+' : '-';
		my $ln = abs($e - $b) + 1;
		$self->{loc}->{$id} = "$contig\_$b$strand$ln";
	    }
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
	
