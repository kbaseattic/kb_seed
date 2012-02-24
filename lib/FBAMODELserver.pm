#
# This is a SAS Component
#

package FBAMODELserver;

use strict;
use base qw(ClientThing);

sub new {
    my($class, @options) = @_;
    my %options = ClientThing::FixOptions(@options);
	if (!defined($options{url})) {
		#Currently, the model server is found in only one location
		$options{url} = "http://pubseed.theseed.org/model-prod/FBAMODEL_server.cgi";
		#$options{url} = ClientThing::ComputeURL($options{url}, 'FBAMODEL_server.cgi', 'model-prod');
	}
    #$options{url} =~ s/\/server\.cgi$/\/FBAMODEL_server.cgi/; # switch /server.cgi to /FBAMODEL_server.cgi
    return $class->SUPER::new("ModelSEED::FBAMODEL" => %options);
}

1;
