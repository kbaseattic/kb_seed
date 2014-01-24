########################################################################
use strict;
use Data::Dumper;
use Getopt::Long;
use SeedUtils;

my $usage = "usage: km_build_kmers_part2 -d DataDir\n";
my $dataD;
my $k;
my $rc  = GetOptions('d=s' => \$dataD);

if ((! $rc) || (! -d $dataD))
{ 
    print STDERR $usage; exit ;
}

&extend_otu_index($dataD);
&update_kmers_with_extended_OTUs($dataD);
sub extend_otu_index {
    my($DataD) = @_;

    my %occ;
    foreach $_ (`cat $dataD/otu.occurrences`)
    {
	if ($_ =~ /^(\d+)\t(\d+)/) { $occ{$1} = $2; }
    }
				     
    my @otus = map { chop; [split(/\t/,$_)] } `cat $dataD/otu.occurrences`;
    my $nxt = $otus[-1]->[0] + 1;
    open(EXT,">>$DataD/otu.occurrences") || die "could not extend otu.occurrences";
    my %composite;
    foreach $_ (`cut -f6 $DataD/reduced.kmers | grep ',' `)
    {
	chop;
	$composite{$_} = 1;
    }
    foreach my $composite_key (keys(%composite))
    {
	my @basic = split(/,/,$composite_key);
	my $tot_occ = 0;
	foreach $_ (@basic) { $tot_occ += $occ{$_} }
	print EXT join("\t",($nxt++,$tot_occ,$composite_key)),"\n";
    }
    close(EXT);
    &SeedUtils::run("cut -f1,3 $dataD/otu.occurrences > $dataD/otu.index");
}

sub update_kmers_with_extended_OTUs {
    my($dataD) = @_;

    my %to_oI;
    foreach $_ (`cat $dataD/otu.occurrences`)
    {
	if ($_ =~ /^(\d+)\t\d+\t(\S+)/)
	{
	    $to_oI{$2} = $1;
	}
    }
    open(IN,"<$dataD/reduced.kmers") || die "bad";
    open(OUT,">$dataD/final.kmers") || die "could not open final.kmers";
    while (defined($_ = <IN>))
    {
	if ($_ !~ /,/) { print OUT $_ }
	else
	{
	    chop;
	    my($kmer,$off,$fI,$fI_wt,$otu_wt,$otus) = split(/\t/,$_);
	    my $otu = $to_oI{$otus};
	    print OUT join("\t",($kmer,$off,$fI,$fI_wt,$otu_wt,$otu)),"\n";
	}
    }
    close(IN);
    close(OUT);
}
