use strict;
#
# This is a SAS Component
#
use SeedEnv;
use Data::Dumper;
use Carp;
use gjoseqlib;

my $usage = "usage: CSA_gather_mapped_objects Dir ";
my $dir;
(
 ($dir = shift @ARGV) && (-s "$dir/layout.after.second.pass")
)
    || die $usage;

open(SPLIT,">$dir/split.over.multiple.contigs") 
    || die "could not open split.over.multiple.contigs";

open(MAPPED,">$dir/mapped.features") || die "could not open $dir/mapped.features";
open(TMP,">tmp.$$.not_mapped") || die "could not open tmp.$$.not_mapped";

my %contigs1 = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$dir/contigs1");
my %contigs2 = map { $_->[0] => $_->[2] } &gjoseqlib::read_fasta("$dir/contigs2");

my %mapped = map { ($_ =~ /^(\S+)\s+(\d+)\s+(\S+)\s+(fig\|\d+\.\d+\.\S+)\s+(.*)$/) ?
		       ("$4:$3" => [$1,$2,$5]) : () } `grep fig $dir/layout.after.second.pass`;
my @hits   = sort keys(%mapped);

my %to_abbrev = map { $_ =~ /^(\S+)\t(\S+)/; ($2 => $1) } `cat $dir/index1`;
my %loc;
foreach $_ (`cat $dir/peg.tbl1`,`cat $dir/rna.tbl1`)
{
    if ($_ =~ /^(fig\|\S+)\t(\S+)/)
    {
	my $peg = $1;
	my($contig,$left,$right,$strand) = &SeedUtils::boundaries_of($2);
	my($beg,$end) = ($strand eq "+") ? ($left,$right) : ($right,$left);
	$loc{$peg} = [$to_abbrev{$contig},$beg,$end];
    }
}

my @got;
my @not_got;
my $i = 0;
my %not_mapped;
my %disrupted;

while ($i < @hits)
{
    my $id;
    if (($i < (@hits-1)) && 
	($hits[$i] =~ /^([^:]+)/) && ($id = $1) && 
	($hits[$i+1] =~ /^([^:]+)/) && ($1 eq $id))
    {
	my $start = $mapped{"$id:start"};
	my $end   = $mapped{"$id:end"};
	my($contig1,$pt1,$func1) = @$start;
	my($contig2,$pt2,$func2) = @$end;
	if (($contig1 eq $contig2) && (abs($pt1 - $pt2) < 6000))
	{
	    my $seq = &dna_seq($contig1,$pt1,$pt2,\%contigs2);
	    print MAPPED join("\t",($contig1,$pt1,$pt2,$id,$func1,$seq)),"\n";
	}
	else
	{
	    print SPLIT join("\t",($id,$contig1,$pt1,$contig2,$pt2,$func1)),"\n";
	}
	$i += 2;
    }
    elsif ($hits[$i] =~ /^([^:]+)/)
    {
	$id = $1;
	if ((! $loc{$id}) || (! defined($loc{$id}->[0])))
	{
	    print STDERR &Dumper($id,$loc{$id});
	    die "aborted";
	}
	my($c1,$b1,$e1) = @{$loc{$id}};
	my(undef,undef,$func) = @{$mapped{$hits[$i]}};
	my $seq = &dna_seq($c1,$b1,$e1,\%contigs1);
	$not_mapped{$id} = [$id,$c1,$b1,$e1,$func,$seq];
	print TMP ">$id\n$seq\n";
	$i++;
    }
}
close(MAPPED);
close(TMP);

foreach my $sim (`blastall -p blastn -FF -m8 -i tmp.$$.not_mapped -d $dir/contigs2`)
{
    chop $sim;
    my($id,undef,$iden,undef,undef,undef,$b1,$e1,undef,undef,undef,undef) = split(/\s+/,$sim);
    if ($iden > 50)
    {
	my $ln = abs($e1-$b1)+1;
	$_ = $not_mapped{$id};
	if ($_)
	{
	    my $full_ln = length($_->[5]);
	    my $cov = sprintf("%0.3f",$ln/$full_ln);
#	    print STDERR "$sim $ln $full_ln $cov\n";
	    if ($ln  >  (0.85 * $full_ln))
	    {
		delete $not_mapped{$id};
	    }
	    elsif ($ln  >  (0.15 * $full_ln))
	    {
		$disrupted{$id} = 1;
	    }
	}
    }
}
unlink("tmp.$$.not_mapped");

open(DISRUPTED,">$dir/disrupted.features") || die "could not open $dir/disrupted.features";
open(LOST,">$dir/lost.features") || die "could not open $dir/lost.features";
foreach my $id (sort keys(%not_mapped))
{
    $_ = $not_mapped{$id};
    if ($_ && $disrupted{$id})
    {
	print DISRUPTED ">$id $_->[4]d\n$_->[5]\n";
#	print DISRUPTED join("\t",@$_),"\n";
    }
    elsif ($_)
    {
	print LOST ">$id $_->[4]d\n$_->[5]\n";
#	print LOST join("\t",@$_),"\n";
    }
}
close(DISRUPTED);
close(LOST);

sub dna_seq {
    my($contig,$beg,$end,$contigs) = @_;
    if ($beg < $end)
    {
	return substr($contigs->{$contig},$beg-1,$end-($beg-1));
    }
    else
    {
	return &SeedUtils::rev_comp(substr($contigs->{$contig},$end-1,$beg-($end-1)));
    }
}
