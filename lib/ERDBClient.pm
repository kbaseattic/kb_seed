package ERDBClient;

use strict;
use FreezeThaw qw(thaw);
use LWP::UserAgent;
use LWP::Protocol;
use HTTP::Request::Common;
use base 'Class::Accessor';
use Data::Dumper;

require LWP::Protocol::http10;
LWP::Protocol::implementor('http', 'LWP::Protocol::http10');

my $CRLF         = "\015\012";     # how lines should be terminated;
				   # "\r\n" is not correct on all systems, for
				   # instance MacPerl defines it to "\012\015"

__PACKAGE__->mk_accessors(qw(ua server_url database));

sub new
{
    my($class, $server_url, $database) = @_;

    if ($server_url !~ /cgi$/)
    {
	$server_url .= "/ERDBServer.cgi";
    }
    my $ua = LWP::UserAgent->new();

    my $self = {
	server_url => $server_url,
	database => $database,
	ua => $ua,
    };

    return bless $self, $class;
}

#
# We assemble  the request manually using the methods that LWP::UserAgent does
# because we want to incrementally pull the response from the socket.
#

sub Get
{
    my($self, $objectNames, $filterClause, $params, $fields, $count) = @_;

    my @params = (db => $self->database,
		  op => 'Get',
		  path => $objectNames,
		  filter => $filterClause,
		  @$params ? map { (params => $_) } @$params : (),
		  @$fields ? map { (fields => $_) }  @$fields : (),
		  count => $count,
		  );
    # print Dumper(\@params);

    my $req = POST $self->server_url, \@params;

    my $method = $req->method;
    my $url = $req->url;
    my $host = $url->host;
    my $port = $url->port;
    my $fullpath = $url->path_query;
    $fullpath = "/$fullpath" unless $fullpath =~ m,^/,;
    my $timeout = 180;

    my $proto = LWP::Protocol::create('http', $self);
    my $socket = $proto->_new_socket($host, $port, $timeout);
    $socket->blocking(1);
    my $request_headers = $req->headers->clone;
    $proto->_fixup_header($request_headers, $url, undef);
    my @h;
    $request_headers->scan(sub {
			       my($k, $v) = @_;
			       $k =~ s/^://;
			       $v =~ s/\n/ /g;
			       push(@h, $k, $v);
			   });
    push(@h, TE => '');

    print Dumper(\@h);
    my $req_buf = "$method $fullpath HTTP/1.0$CRLF";
    $req_buf .= $request_headers->as_string($CRLF) . $CRLF;
    
    my $tmp = $req_buf;
    $tmp =~ s/\r/\\r/g;
    print "req: $tmp\n";

    my $n = $socket->syswrite($req_buf, length($req_buf));
    print "Wrote $n\n";
    die $! unless defined($n);
    die "short write" unless $n == length($req_buf);

    $req_buf = $req->content;
    print $req_buf;
    $n = $socket->syswrite($req_buf, length($req_buf));
    print "Wrote $n\n";
    die $! unless defined($n);
    die "short write" unless $n == length($req_buf);

    while (<$socket>)
    {
	last if /^\s*$/;
	s/\r/\\r/g;
	print "Hdr: $_";
    }

    print "Hdrs done\n";

    while (!$socket->eof())
    {
	my $len = <$socket>;
	if ($len =~ /(\d+)/)
	{
	    my $buf;
	    my $n = $socket->read($buf, $len);
	    print "Read $n: '$buf'\n";
	    my @dat = thaw($buf);
	    print Dumper(\@dat);
	}

    }
}


1;
