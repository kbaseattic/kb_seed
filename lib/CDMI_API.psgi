use CDMI_APIImpl;
use CDMI_APIServer;



my $impl_obj = CDMI_APIImpl->new;

my $server = CDMI_APIServer->new(instance_dispatch => { 'CDMI_API' => $impl_obj },

				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler;
