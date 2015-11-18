package Bio::KBase::Exceptions;

use Exception::Class
    (
     Bio::KBase::Exceptions::KBaseException => {
	 description => 'KBase exception',
	 fields => ['method_name'],
     },

     Bio::KBase::Exceptions::JSONRPC => {
	 description => 'JSONRPC error',
	 fields => ['code', 'data'],
	 isa => 'Bio::KBase::Exceptions::KBaseException',
     },

     Bio::KBase::Exceptions::HTTP => {
	 description => 'HTTP error',
	 fields => ['status_line'],
	 isa => 'Bio::KBase::Exceptions::KBaseException',
     },

     Bio::KBase::Exceptions::ArgumentValidationError => {
	 description => 'argument validation error',
	 fields => ['method_name'],
	 isa => 'Bio::KBase::Exceptions::KBaseException',
     },

     Bio::KBase::Exceptions::ClientServerIncompatible => {
     description => "Client and Server libraries are incompatible with eachother",
     fields => ['server_version', 'client_version'],
	 isa => 'Bio::KBase::Exceptions::KBaseException',
     }

    );

Bio::KBase::Exceptions::KBaseException->Trace(1);

package Bio::KBase::Exceptions::HTTP;
use strict;

sub full_message
{
    my($self) = @_;
    return $self->message . "\nHTTP status: " . $self->status_line . "\nFunction invoked: " . $self->method_name;
}

package Bio::KBase::Exceptions::ClientServerIncompatible;
use strict;

sub full_message
{
    my ($self) = @_;
    return $self->message . "\nClient version: " . $self->client_version . "\nServer version: " . $self->server_version;
}
1;
