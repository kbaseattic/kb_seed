# -*- perl -*-

#
# This is SAS component.
#

use strict;
use warnings;

$0 =~ m/([^\/]+)$/;
my $self  =  $1;
my $usage = "$self [-norm] [-null] [-nolabel] [-get_gc] [-get_dna] < fasta.file > fasta.cumul 2> summary";

if (defined($ARGV[0]) && ($ARGV[0] =~ m/-help/))
{
    print STDERR "\n\t$usage\n\n";
    exit(1);
}

my ($file, $fh);
my ($norm, $null, $nolabel, $quiet, $by_chars, $get_gc, $get_dna, $pct, $dumper);

while (@ARGV) {
    if    ($ARGV[0] =~ m/-norm/)       { $norm     = shift; }
    elsif ($ARGV[0] =~ m/-null/)       { $null     = shift; }
    elsif ($ARGV[0] =~ m/-nolabel/)    { $nolabel  = shift; }
    elsif ($ARGV[0] =~ m/-quiet/)      { $quiet    = shift; }
    elsif ($ARGV[0] =~ m/-by_chars/)   { $by_chars = shift; }
    elsif ($ARGV[0] =~ m/-get_gc/)     { $get_gc   = shift; }
    elsif ($ARGV[0] =~ m/-get_dna/)    { $get_dna  = shift; }
    elsif ($ARGV[0] =~ m/-pct/)        { $pct      = shift; }
    elsif ($ARGV[0] =~ m/-dumper/)     { $dumper   = shift; }
    elsif (-s $ARGV[0]) {
	$file = shift;
	open(FILE, "<$file") || die "could not read-open $file"; $fh = \*FILE;
    }
    else  {
	die "Invalid arg $ARGV[0] --- usage: $usage";
    }
}

my $num_chars = 0;
my $num_seqs  = 0;

my $num_a     = 0;
my $num_c     = 0;
my $num_g     = 0;
my $num_t     = 0;

my $num_gc    = 0;
my $num_at    = 0;

my ($head, $seqP, $id, $seq_len, %id_set, %histo);
while ( ($head, $seqP) = &get_a_fasta_record($fh) )
{
    if (defined($$seqP) && defined($seq_len = length($$seqP)))
    {
	++$num_seqs;
	$head =~ m/^(\S+)/;  $id = $1;
	
	unless (defined($histo{$seq_len})) 
	{ 
	    $histo{$seq_len} = [ 0, 0 ];
	    unless ($nolabel || $null)  { $id_set{$seq_len} = []; }
	}
	
	$num_chars  += $seq_len;
	$histo{$seq_len}->[0] += 1;
	unless ($nolabel || $null)  { my $x = $id_set{$seq_len};  push(@$x, $id); }
	
	if ($get_gc)
	{
	    $num_gc += ($$seqP =~ tr/gcGC//);
	    $num_at += ($$seqP =~ tr/atAT//);
	}
	
	if ($get_dna)
	{
	    $num_a += ($$seqP =~ tr/aA//);
	    $num_c += ($$seqP =~ tr/cC//);
	    $num_g += ($$seqP =~ tr/gG//);
	    $num_t += ($$seqP =~ tr/tuTU//);
	}
    }
}

my $cumul  = 0;
my $expect = 0;
my ($count, $plot, $min, $median, $max);
foreach $seq_len (sort { $a <=> $b } keys %histo)
{
    $count   = $histo{$seq_len}->[0];
    
    $expect += $count * $seq_len;
    $cumul  += $by_chars ? ($count * $seq_len) : $count;

    if ($norm)
    {
	$plot    = $num_chars > 0 ? ($by_chars ? $cumul/$num_chars : $cumul/$num_seqs) : 0;
    }
    else
    {
	$plot = $cumul;
    }
    
    $histo{$seq_len}->[1] = $cumul;
    unless ($null || $nolabel) {
	$histo{$seq_len}->[2] = $id_set{$seq_len};
    }
    
    if (! defined($min))     { $min = $seq_len; }
    
    if ((! defined($median)) && ($cumul > ($by_chars ? $num_chars : $num_seqs) / 2 ))  { 
	$median = $seq_len; 
    }
    
    unless ($null || $dumper)  {
	print "$seq_len\t$count\t$plot";
	print "\t", join(", ", @{$id_set{$seq_len}}) unless ($nolabel || $null);
	print "\n";
    }
    
    $max = $seq_len;
}

if ($dumper) { print Dumper(\%histo), qq(//\n); }

$expect     =  sprintf qq(%4.1f),  $cumul > 0 ?  ($expect / $cumul) : 0;

my $ambigs     =  $num_chars - ($num_a +$num_c + $num_g + $num_t);
my $gc_content =  100 * ($num_gc + 1) / ($num_gc + $num_at + 2);

if ($num_chars > 0)
{
    $num_a  = $pct ? (100.0 * $num_a / $num_chars)  : $num_a;
    $num_c  = $pct ? (100.0 * $num_c / $num_chars)  : $num_c;
    $num_g  = $pct ? (100.0 * $num_g / $num_chars)  : $num_g;
    $num_t  = $pct ? (100.0 * $num_t / $num_chars)  : $num_t;

    $ambigs = $pct ? (100.0 * $ambigs / $num_chars) : $ambigs;
}


print  STDERR "\nThere are $num_chars chars in $num_seqs seqs.";
printf STDERR " (G+C = %4.1f%%)", $gc_content if ($get_gc);
if ($get_dna) {
    if (not $pct) {
	printf STDERR " (A:%u, C:%u, G:%u, T:%u, Ambig:%u)"
	    ,  $num_a, $num_c, $num_g, $num_t, $ambigs;
    }
    else {
	printf STDERR " (A:%4.1f%%, C:%4.1f%%, G:%4.1f%%, T:%4.1f%%, Ambig:%4.1f%%)"
	    ,  $num_a, $num_c, $num_g, $num_t, $ambigs;
    }
}
print  STDERR "\nmin length = $min, median length = $median, mean length = $expect, max length = $max\n\n";


sub get_a_fasta_record
{
    my ($fh) = @_;
    my ($old_eol, $entry, @lines, $head, $seq, @result);
    
    if (not defined($fh))  { $fh = \*STDIN; }
    
    $old_eol = $/;
    $/ = "\n>";
 
    if (defined($entry = <$fh>))
    {
	chomp $entry;
	@lines  =  split( /\n/, $entry );
	$head   =  shift @lines;
	$head   =~ s/^>?//;
	$seq    =  join( "", @lines );
	
	@result =  ($head, \$seq);
    }
    else
    {
	@result = ();
    }
    
    $/ = $old_eol;
    return @result;
}
