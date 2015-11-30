# This is a SAS Component

use strict;
use Data::Dumper;
use Getopt::Long::Descriptive;
use gjoseqlib;
use GenomeTypeObject;
use Time::HiRes 'gettimeofday';
use KmerGutsNet;
use IPC::Run qw(start run finish);
use LWP::UserAgent;

#
# Use a kser server loaded with the local family reps, issue queries
# using KmerGutsNet to find the reps that match.
#

my($opt, $usage) = describe_options("%c %o kmer-dir url input-file",
				    ["output|o=s", "Write output to this file"],
				    ["genus=s", "Use this genus to assign a local family"],
				    ["required-common-kmers|r=i" => "Minimium kmers in common required for a family to have a vote", { default => 3 }],
				    ["help|h" => "Show this help message."]);

print($usage->text), exit if $opt->help;
@ARGV == 3 or die $usage->text;

my $kmer_dir = shift;
my $url = shift;
my $in_file = shift;

my $ua = LWP::UserAgent->new();

my $genus_name = $opt->genus;
my $genus;

my $kg_query = KmerGutsNet->new("$url/query");
my $kg_lookup = KmerGutsNet->new("$url/lookup");

#
# Determine input file type. Read the first line; if starts with "<" it's a fasta,
# otherwise treat as genome object.
#

my $file_type;
open(IF, "<", $in_file);
my $l = <IF>;
close(IF);
my $fasta_data;
my $gto;
my %vers;
if ($l =~ /^>/)
{
    $file_type = 'fasta';
    $fasta_data= $in_file;
}
else
{
    $file_type = 'gto';
    $gto = GenomeTypeObject->create_from_file($in_file);
    $fasta_data = $gto->extract_protein_sequences_to_temp_file();

    ($genus_name) = $gto->{scientific_name} =~ /^(\S+)/;

    #
    # Look up version data.
    #
    my $res = $ua->get("$url/version");
    if ($res->is_success)
    {
	my $txt = $res->content;
	while ($txt =~ /^(.*)\t(.*)$/mg)
	{
	    $vers{$1} = $2;
	}
    }

    my $hostname = `hostname`;
    chomp $hostname;
    my $event = {
	tool_name => $0,
	execute_time => scalar gettimeofday,
	parameters => ["required-common-kmers", $opt->required_common_kmers,
		       kmer_dir => $kmer_dir,
		       url => $url,
		       in_file => $in_file,
		       %vers
		       ],
	hostname => $hostname,
    };
    my $event_id = $gto->add_analysis_event($event);
    
}

#
# Look up tax id of genus.
#

{
    my $res = $ua->get("$url/genus_lookup/$genus_name");
    if ($res->is_success)
    {
	my $txt = $res->content;
	($genus) = $txt =~ /(\d+)/;
    }
    else
    {
	print STDERR "Failure looking up genus $genus_name:" . $res->status_line . " " . $res->content;
    }
}

#
# We need to begin by calling the functions.
#

my $min_score = 5;

my $h = start(["kmer_search", "--url", $kg_query->{url}, "-d", $kmer_dir, "-a", "-m", $min_score],
	     '<', $fasta_data,
	      '>pipe', \*CALLS);

my %calls;
while (<CALLS>)
{
    chomp;
    my($fid, $fn, $score, $wt) = split(/\t/);
    $calls{$fid} = $fn;
}
close(CALLS);
$h->finish;


open(P, "-|", "curl", "--data-binary", "\@$fasta_data", "$url/lookup")
   or die "Cannot curl $url/lookup: $!";

my $genus_re = genus_re($genus) if $genus;
# print Dumper($genus, $genus_re);

my $out_fh;
if ($opt->output)
{
    open($out_fh, ">", $opt->output) or die "Cannot write " . $opt->output . ": $!\n";
}
else
{
    $out_fh = \*STDOUT;
}

while (<P>)
{
    chomp;
    my $fid = $_;

    my $this_call = $calls{$fid} // "hypothetical protein";
    
    my(%gcount, %gscore, %lcount, %lscore);
    my(%lcount, %lscore);
    while (<P>)
    {
	# print STDERR;
	last if /^\/\//;
	chomp;
	my($mfid, $score, $pgf, $plf, $func) = split(/\t/);
	next if $func ne $this_call;
	next if $score < $opt->required_common_kmers;

	$gcount{$pgf}++;
	$gscore{$pgf} += $score;

	if ($genus_re && ($plf =~ $genus_re))
        {
	    $lcount{$plf}++;
	    $lscore{$plf} += $score;
	}
    }

    my @bycount = sort { $gcount{$b} <=> $gcount{$a} } keys %gcount;
    my @byscore = sort { $gscore{$b} <=> $gscore{$a} } keys %gscore;

    my @lbycount = sort { $lcount{$b} <=> $lcount{$a} } keys %lcount;
    my @lbyscore = sort { $lscore{$b} <=> $lscore{$a} } keys %lscore;

    my $lbsscore = $lscore{$lbyscore[0]} - $lscore{$lbyscore[1]};
    my $bcscore = $gcount{$bycount[0]} - $gcount{$bycount[1]};
    my $bsscore = $gscore{$byscore[0]} - $gscore{$byscore[1]};

    # print STDERR Dumper(\%gcount, \%gscore, \@bycount, \@byscore);
    # print STDERR Dumper(\%lcount, \%lscore, \@lbycount, \@lbyscore);

    if ($file_type eq 'fasta')
    {
	print $out_fh join("\t", $fid, $byscore[0], $bsscore, $this_call), "\n" if $byscore[0];
#	print $out_fh join("\t", $fid, $bycount[0], $byscore[0], $bcscore, $bsscore, $calls{$fid}), "\n";
	print $out_fh join("\t", $fid, $lbyscore[0], $lbsscore, $this_call), "\n" if $lbyscore[0];
    }
    else
    {
	# for a gto, we choose the best by score and add the assignment to the feature.
	my $feat = $gto->find_feature($fid);
	if ($byscore[0])
	{
	    my $assign = ["PGFAM", $byscore[0], $this_call, $vers{families}];
	    push(@{$feat->{family_assignments}}, $assign);
	}
	if ($lbyscore[0])
	{
	    my $lassign = ["PLFAM", $lbyscore[0], $this_call, $vers{families}];
	    push(@{$feat->{family_assignments}}, $lassign);
	}
    }
}

if ($file_type eq 'gto')
{
    $gto->destroy_to_file($out_fh);
}

close($out_fh) if $opt->output;

sub genus_re
{
    my($genus) = @_;
    return qr/^PLF_${genus}_/;
}
