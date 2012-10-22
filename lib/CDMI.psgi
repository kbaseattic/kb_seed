use Bio::KBase::CDMI::CDMI_APIImpl;
use Bio::KBase::CDMI::CDMI_EntityAPIImpl;

use Bio::KBase::CDMI::Service;



my @dispatch;

{
    my $obj = Bio::KBase::CDMI::CDMI_APIImpl->new;
    push(@dispatch, 'CDMI_API' => $obj);
}
{
    my $obj = Bio::KBase::CDMI::CDMI_EntityAPIImpl->new;
    push(@dispatch, 'CDMI_EntityAPI' => $obj);
}


my $server = Bio::KBase::CDMI::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub {
    my($env) = @_;
    
    my $resp = $server->handle_input($env);

    if ($env->{HTTP_ORIGIN})
    {
	my($code, $hdrs, $body) = @$resp;
	push(@$hdrs, 'Access-Control-Allow-Origin', $env->{HTTP_ORIGIN});
    }
    return $resp;
};

$handler;
