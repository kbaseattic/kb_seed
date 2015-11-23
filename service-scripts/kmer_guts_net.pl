#
# This is a SAS component.
#

use Data::Dumper;
use File::Copy;
use URI;
use strict;
use Getopt::Long::Descriptive;
use File::Temp;
use IO::Socket;
use HTTP::Response;

#
# kmer_guts script that is invoked with the same params as
# kmer_guts but hits the server version instead.
#

my($opt, $usage) = describe_options("%c %o",
				    ["url|u=s" => "server URL (required)"],
				    ["min-hits|m=i" => "minimum hits required for a match"],
				    ["max-gap|g=i" => "maximum gap allowed for a match"],
				    ["a" => "query sequence is protein not DNA"],
				    ["debug|d=i" => "debug level. debug=1 shows individual hits"],
				    ["min-weighted-hits|M=i" => "minimum weighted hits required for a match"],
				    ["order-constraint|O" => "apply order constraint"],
				    ["help|h" => "show this help message"]);

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if @ARGV != 0;
if (!$opt->url)
{
    die "URL is requred\n" . $usage->text;
}

my $url = $opt->url;

my @opts;

my @url_options = qw(min_hits max_gap min_weighted_hits order_constraint);

push(@opts, "-m", $opt->min_hits) if $opt->min_hits;
push(@opts, "-g", $opt->max_gap) if $opt->max_gap;
push(@opts, "-a") if $opt->a;
push(@opts, "-d", $opt->debug) if $opt->debug;
push(@opts, "-M", $opt->min_weighted_hits) if $opt->min_weighted_hits;
push(@opts, "-O") if $opt->order_constraint;

my %qp;
for my $uopt (@url_options)
{
    if (defined(my $v = $opt->$uopt))
    {
	$qp{$uopt} = $v;
    }
}
my $qp;
if (%qp)
{
    $qp = '?' . join("&", map { "$_=$qp{$_}" } keys %qp);
}
    
my @params;
push(@params, "-s");
push(@params, "-H", "Kmer-Options: " . join(" ", @opts)) if @opts;
push(@params, "--data-binary", '@-');

my @cmd = ("curl", @params, $url . $qp);
#print @cmd;

my $rc = system(@cmd);

if ($rc != 0)
{
    die "cmd failed with rc=$rc: @cmd\n";
}
