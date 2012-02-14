use CDMI_EntityAPIImpl;

use CDMI_EntityAPIServer;



my @dispatch;

{
    my $obj = CDMI_EntityAPIImpl->new;
    push(@dispatch, 'CDMI_EntityAPI' => $obj);
}


my $server = CDMI_EntityAPIServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler;
