### Untar plant files.

use strict;

$| = 1; # Prevent buffering on STDOUT.
my ($inDir, $outDir) = @ARGV;
opendir(my $ih, $inDir) || die "Cannot open $inDir.";
my @files = grep { /.+\.tar\.gz/ } readdir($ih);
closedir $ih;
chdir $outDir;
for my $file (@files) {
	if ($file =~ /(.+)\.tar.gz/) {
		my $name = $1;
		mkdir "$outDir/$name";
		print "Processing $name from $file.\n";
		open(my $oh, "tar xzvf $inDir/$file |") || die "Tar failed on $file: $!";
		while (! eof $oh) {
			print "   " . <$oh>;
		}
		close $oh;
	}
}
