#!/Users/olson/wx/bin/perl


=head1 NAME

dtr_helper_cddsearch - run CDD lookup in background for Desktop RAST

=head1 SYNOPSIS

  dtr_helper_cddsearch < sequence > ids

=head1 DESCRIPTION

This is a simpler version of the old one with no progress stuff. With the new CDD search interface
it doesn't appear to be necessary.

=cut

use strict;

use LWP::UserAgent;
use Time::HiRes 'gettimeofday';
use YAML::Any;

my $input_file;

@ARGV == 0 or die "Usage: $0  < inp > out\n";

my $ua = LWP::UserAgent->new();
my $url = "http://www.ncbi.nlm.nih.gov/Structure/cdd/wrpsb.cgi";

my $seq;
{
    undef $/;
    $seq = <STDIN>;
}

$seq =~ s/\n/%0A/g;
$seq =~ s/>/%3E/g;
$seq =~ s/\|/%7C/g;

my $q = "$url?seqinput=$seq&db=cdd";
#print "$q\n";
my $res = $ua->get($q);
my $rid;
if ($res->is_success)
{
    my $dat = $res->content;

    if ($dat =~ /Live blast search.*RID.*>(\w+)/)
    {
	$rid = $1;
    }
}

print "$rid\n";
