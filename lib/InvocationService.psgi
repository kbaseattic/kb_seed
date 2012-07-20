use strict;
use Bio::KBase::InvocationService::InvocationServiceImpl;

use Bio::KBase::InvocationService::Service;

use Data::Dumper;
use Plack::Request;
use URI::Dispatch;

my @dispatch;

my $storage_dir = "/tmp/storage";

my $kb_storage_dir = "/xfs/kb_inst/iris_storage";

if (-d $kb_storage_dir && -w $kb_storage_dir)
{
    $storage_dir = $kb_storage_dir;
}

my $obj = Bio::KBase::InvocationService::InvocationServiceImpl->new($storage_dir);
push(@dispatch, 'InvocationService' => $obj);

my $server = Bio::KBase::InvocationService::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $dispatch = URI::Dispatch->new();
$dispatch->add('/', 'handle_service');
$dispatch->add('/invoke', 'handle_invoke');
$dispatch->add('/upload', 'handle_upload');
$dispatch->add('/download/#*', 'handle_download');

{
    package handle_download;
    use strict;
    use Data::Dumper;

    sub get
    {
	my($req, $args) = @_;
	my $session = $req->param("session_id");

	if (!$obj->_validate_session($session))
	{
	    return [500, [], ["Invalid session id\n"]];
	}

	my $dir = $obj->_session_dir($session);

	#
	# Validate path given.
	#
	my $file = $args->[0];
	my @comps = split(/\//, $file);
	if (grep { $_ eq '..' } @comps)
	{
	    return [404, [], ["File not found\n"]];
	}
	
	my $path = "$dir/$file";
	my $fh;
	if (!open($fh, "<", $path))
	{
	    return [404, [], ["File not found\n"]];
	}

	return [200, [], $fh];
    }
}

{
    package handle_upload;
    use strict;
    use Data::Dumper;

    sub post
    {
	my($req, $args) = @_;

	my @origin_hdr = ('Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN});

	my $session = $req->param("session_id");

	if (!$obj->_validate_session($session))
	{
	    return [500, \@origin_hdr, ["Invalid session id\n"]];
	}

	my $dir = $obj->_session_dir($session);

	#
	# Validate path given.
	#
	my $file = $req->param('qqfile');
	my @comps = split(/\//, $file);
	if (grep { $_ eq '..' } @comps)
	{
	    return [404, \@origin_hdr, ["File not found\n"]];
	}
	
	my $path = "$dir/$file";
	my $fh;
	if (!open($fh, ">", $path))
	{
	    return [404, \@origin_hdr, ["File not found\n"]];
	}

	my $buf;
	while ($req->input->read($buf, 4096))
	{
	    print $fh $buf;
	}
	close($fh);

	return [200, [], ['{ "success": true}']];
    }
    sub options
    {
	my($req, $args) = @_;

	my @origin_hdr = ('Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN},
			  'Access-Control-Allow-Methods', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_METHOD},
			  'Access-Control-Allow-Headers', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS},
			  'Access-Control-Expose-Headers', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS},
			  'Access-Control-Allow-Credentials', 'true');

	return [200, \@origin_hdr, []];
    }

}

{
    package handle_invoke;

    use strict;
    use Data::Dumper;

    sub post
    {
	my($req) = @_;
	#
	# The invoke REST interface expects to get a 3-line header:
	#
	#   session-id
	#   pipeline   
	#   cwd
	#
	# followed by the pipeline input. It emits lines of output
	# which may have stdout and stderr interleaved; the lines are
	# prefixed by the characters 'O' for stdout and 'E' for stderr.
	# 
    }
}

{
    package handle_service;
    use strict;
    use Data::Dumper;

    sub post
    {
	my($req) = @_;
	my $resp = $server->handle_input($req->env);
	my($code, $hdrs, $body) = @$resp;
#	if ($code =~ /^5/)
	{
	    if ($req->env->{HTTP_ORIGIN})
	    {
		push(@$hdrs, 'Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN});
	    }
	}
			print Dumper($resp);
	return $resp;
    }
}

my $handler = sub {
    my($env) = @_;
    print Dumper($env);
    my $req = Plack::Request->new($env);
    my $ret = $dispatch->dispatch($req);
    return $ret;
};

$handler;
