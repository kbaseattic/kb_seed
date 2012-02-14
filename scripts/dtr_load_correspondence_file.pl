use strict;
use myRAST;

my @files = @ARGV;

my $lc = myRAST->instance->local_correspondences;

if (@files)
{
    for my $file (@files)
    {
	$lc->load_file(undef, undef, $file);
    }
}
else
{
    my $dir = myRAST->instance->data_dir;
    
    opendir(D, $dir) or die "Cannot open data dir $dir: $!";
    while (my $g = readdir(D))
    {
	next unless $g =~ /^\d+\.\d+$/;
	my $gdir = "$dir/$g/$g";
	my $refdir = "$gdir/CorrToReferenceGenomes";
	if (opendir(D2, $refdir))
	{
	    while (my $g2 = readdir(D2))
	    {
		next unless $g2 =~ /^\d+\.\d+$/;
		my $ref = "$refdir/$g2";
		#print "Load $g $ref\n";
		
		$lc->load_file($g, $g2, $ref);
		
	    }
	    
	}
    }
}
