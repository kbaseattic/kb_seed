
use strict;
use myRAST;

use SaplingGenomeLoader;

use Getopt::Long;

my $sapling = myRAST->instance->sapling;
$sapling->CreateTables();
