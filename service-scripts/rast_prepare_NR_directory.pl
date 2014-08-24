
#
# Process a directory of NR files as used for annotation.
#
# Create a btree genus_index.btree that points from lower-case genus name to file, and
# another function_index.btree that points from feature ID to function.
#

use DB_File;
use strict;

@ARGV == 1 or die "Usage: $0 nr-directory\n";

my $nr_dir = shift;

opendir(D, $nr_dir) or die "Cannot opendir $nr_dir: $!";

my %genus_index;

tie %genus_index, 'DB_File', "$nr_dir/genus_index.btree", O_RDWR | O_CREAT, 0644, $DB_BTREE or die "Cannot tie $nr_dir/genus_index.btree: $!";

while (my $p = readdir(D))
{
    if ($p =~ /^(.*)\.fasta.nr$/)
    {
	my $baseg = $1;
	print STDERR "$p\n";

	my %function_index;
	tie %function_index, 'DB_File', "$nr_dir/$p.btree", O_RDWR | O_CREAT, 0644, $DB_BTREE or die "Cannot tie $nr_dir/$p.btree: $!";

	if (open(P, "<", "$nr_dir/$p"))
	{
	    $genus_index{lc($baseg)} = $p;
	    while (<P>)
	    {
		chomp;
		if (/^>(\S+)\s+(.*)/)
		{
		    # print "$1 -> $2\n";
		    $function_index{$1} = $2;
		}
	    }
	    close(P);
	}
	else
	{
	    die "Cannot open $nr_dir/$p: $!";
	}
	untie %function_index;
    }
}
closedir(D);

   
