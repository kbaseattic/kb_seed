use Bio::KBase::CDMI::CDMI_APIImpl;
use Bio::KBase::CDMI::CDMI_EntityAPIImpl;

use Bio::KBase::CDMI::Service;
use Plack::Middleware::CrossOrigin;



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

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
