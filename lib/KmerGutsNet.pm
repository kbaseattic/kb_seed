package KmerGutsNet;

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

sub new
{
    my($class, $url) = @_;

    my $self = {
	url => $url,
    };
    return bless $self, $class;
}

sub request
{
    my($self, $seq, %opts) = @_;

    my $uri = URI->new($self->{url});
    my $host = $uri->host;
    my $port = $uri->port;
    my $path = $uri->path;
    
    my $sock = IO::Socket::INET->new(PeerAddr => $host,
				     PeerPort => $port,
				     Proto => 'tcp');
    $sock or die "cannot connect to $uri: $!";

    my @opts;

    push(@opts, "-m", $opts{min_hits}) if $opts{min_hits};
    push(@opts, "-g", $opts{max_gap}) if $opts{max_gap};
    push(@opts, "-a") if $opts{a};
    push(@opts, "-d", $opts{debug}) if $opts{debug};
    push(@opts, "-M", $opts{min_weighted_hits}) if $opts{min_weighted_hits};
    push(@opts, "-O") if $opts{o};
    
    my $sz = length($seq);

    $sock->print("POST $path HTTP/1.1\r\n");
    $sock->print("Host: $host:$port\r\n");
    $sock->print("Content-type: application/octet-stream\r\n");

    $sock->print("Content-length: $sz\r\n");
    $sock->print("Kmer-Options: " . join(" ", @opts) . "\r\n") if @opts;
    $sock->print("\r\n");
    
    $sock->print($seq);

    my $resp = $sock->getline();
    chomp $resp;
    #print "resp=$resp\n";
    my($what, $code, $str) = split(/\s+/, $resp, 3);
    if ($code != 200)
    {
	die "Failed: $code $str\n";
    }
    
    while (my $l = $sock->getline())
    {
	chomp $l;
	# don't care about headers for now.
	last if $l eq '';
    }

    my $res;
    my $buf;
    while ($sock->read($buf, 4096))
    {
	$res .= $buf;
    }
    return $res;
}
    
1;
