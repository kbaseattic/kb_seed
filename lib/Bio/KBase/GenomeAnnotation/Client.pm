package Bio::KBase::GenomeAnnotation::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

=head1 NAME

Bio::KBase::GenomeAnnotation::Client

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => Bio::KBase::GenomeAnnotation::Client::RpcClient->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);

    return bless $self, $class;
}




=head2 $result = genomeTO_to_reconstructionTO(genomeTO)



=cut

sub genomeTO_to_reconstructionTO
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomeTO_to_reconstructionTO (received $n, expecting 1)");
    }
    {
	my($genomeTO) = @args;

	my @_bad_arguments;
        (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"genomeTO\" (value was \"$genomeTO\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomeTO_to_reconstructionTO:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomeTO_to_reconstructionTO');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GenomeAnnotation.genomeTO_to_reconstructionTO",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomeTO_to_reconstructionTO',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomeTO_to_reconstructionTO",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomeTO_to_reconstructionTO',
				       );
    }
}



=head2 $result = genomeTO_to_feature_data(genomeTO)



=cut

sub genomeTO_to_feature_data
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomeTO_to_feature_data (received $n, expecting 1)");
    }
    {
	my($genomeTO) = @args;

	my @_bad_arguments;
        (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"genomeTO\" (value was \"$genomeTO\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomeTO_to_feature_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomeTO_to_feature_data');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GenomeAnnotation.genomeTO_to_feature_data",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomeTO_to_feature_data',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomeTO_to_feature_data",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomeTO_to_feature_data',
				       );
    }
}



=head2 $result = reconstructionTO_to_roles(reconstructionTO)



=cut

sub reconstructionTO_to_roles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function reconstructionTO_to_roles (received $n, expecting 1)");
    }
    {
	my($reconstructionTO) = @args;

	my @_bad_arguments;
        (ref($reconstructionTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"reconstructionTO\" (value was \"$reconstructionTO\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to reconstructionTO_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'reconstructionTO_to_roles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GenomeAnnotation.reconstructionTO_to_roles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'reconstructionTO_to_roles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method reconstructionTO_to_roles",
					    status_line => $self->{client}->status_line,
					    method_name => 'reconstructionTO_to_roles',
				       );
    }
}



=head2 $result = reconstructionTO_to_subsystems(reconstructionTO)



=cut

sub reconstructionTO_to_subsystems
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function reconstructionTO_to_subsystems (received $n, expecting 1)");
    }
    {
	my($reconstructionTO) = @args;

	my @_bad_arguments;
        (ref($reconstructionTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"reconstructionTO\" (value was \"$reconstructionTO\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to reconstructionTO_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'reconstructionTO_to_subsystems');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GenomeAnnotation.reconstructionTO_to_subsystems",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'reconstructionTO_to_subsystems',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method reconstructionTO_to_subsystems",
					    status_line => $self->{client}->status_line,
					    method_name => 'reconstructionTO_to_subsystems',
				       );
    }
}



=head2 $result = annotate_genome(genomeTO)

Given a genome object populated with contig data, perform gene calling
and functional annotation and return the annotated genome.

=cut

sub annotate_genome
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function annotate_genome (received $n, expecting 1)");
    }
    {
	my($genomeTO) = @args;

	my @_bad_arguments;
        (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"genomeTO\" (value was \"$genomeTO\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to annotate_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'annotate_genome');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GenomeAnnotation.annotate_genome",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'annotate_genome',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method annotate_genome",
					    status_line => $self->{client}->status_line,
					    method_name => 'annotate_genome',
				       );
    }
}



=head2 $result = annotate_proteins(genomeTO)

Given a genome object populated with feature data, reannotate
the features that have protein translations. Return the updated
genome object.

=cut

sub annotate_proteins
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function annotate_proteins (received $n, expecting 1)");
    }
    {
	my($genomeTO) = @args;

	my @_bad_arguments;
        (ref($genomeTO) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"genomeTO\" (value was \"$genomeTO\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to annotate_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'annotate_proteins');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GenomeAnnotation.annotate_proteins",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'annotate_proteins',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method annotate_proteins",
					    status_line => $self->{client}->status_line,
					    method_name => 'annotate_proteins',
				       );
    }
}




package Bio::KBase::GenomeAnnotation::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


1;
