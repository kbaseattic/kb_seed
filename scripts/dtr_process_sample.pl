
#
# myRAST pipeline processing script.
#
# dtr_process_sample notify-port notify-handle sample-dir args
#

#
# This is a SAS Component
#

use strict;
use ANNOserver;
use NotifyClient;
use Data::Dumper;
use SampleDir;

@ARGV >= 4 or die "Usage: $0 notify-port notify-handle sample-dir [args]\n";

my $nport = shift;
my $nhandle = shift;
my $sample_dir = shift;
my %args = @ARGV;

my @uarg = ();
if (defined(my $url = delete $args{-url}))
{
    @uarg = (-url => $url);
}

my $nc = NotifyClient->new(port => $nport, handle => $nhandle);

-d $sample_dir or die "Sample directory $sample_dir does not exist\n";

my $sample = SampleDir->new($sample_dir, @uarg);
$sample or die "Could not create SampleDir from $sample_dir\n";

my($ds, $num) = $sample->perform_basic_analysis(%args);

print "dataset\t$ds\t$num\n";

