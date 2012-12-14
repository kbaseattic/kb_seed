#!/usr/bin/perl -w

#
# This is a SAS component.
#

package ServerThing;
    use Data::Dumper;
    use strict;
    use Tracer;
    use YAML;
    use YAML::XS;
    use JSON::Any;
    use ERDB;
    use TestUtils;
    use Time::HiRes 'gettimeofday';
    use File::Temp;
    use ErrorMessage;
    use CGI;

#    use bytes;

    no warnings qw(once);

    # Maximum number of requests to run per invocation.
    use constant MAX_REQUESTS => 50;

#
# Carefully import Log4perl.
#
BEGIN {
    eval {
	require Log::Log4perl;
	Log::Log4perl->import('get_logger');
	require Try::Tiny;
	Try::Tiny->import;
    };
};

=head1 General Server Helper

This package provides a method-- I<RunServer>-- that can be called from a CGI
script to perform the duties of a FIG server. RunServer is called with two
parameters: the name of the server package (e.g. C<SAP> for B<SAP.pm>) and
the first command-line parameter. The command-line parameter (if defined) will
be used as the tracing key, and also indicates that the script is being invoked
from the command line rather than over the web.

=cut

sub RunServer {
    # Get the parameters.
    my ($serverName, $key) = @_;
    # Set up tracing. We never do CGI tracing here; the only question is whether
    # or not the caller passed in a tracing key. If he didn't, we use the server
    # name.
    ETracing($key || $serverName, destType => 'APPEND', level => '0 ServerThing');
    # Turn off YAML compression, which causes problems with some of our hash keys.
    $YAML::CompressSeries = 0;
    # Create the server object.
    Trace("Requiring $serverName for task $$.") if T(3);
    eval {
        my $output = $serverName;
        $output =~ s/::/\//g;
        require "$output.pm";
    };
    # If we have an error, create an error document.
    if ($@) {
        SendError($@, "Could not load server module.");
    } else {
        # Having successfully loaded the server code, we create the object.
        my $serverThing = eval("$serverName" . '->new()');
        Trace("$serverName object created for task $$.") if T(2);
        # If we have an error, create an error document.
        if ($@) {
            SendError($@, "Could not start server.");
        } else {
            # No error, so now we can process the request. First, get the method list.
            my $methods = $serverThing->methods();

	    my $raw_methods = [];
	    if ($serverThing->can("raw_methods"))
	    {
		$raw_methods = $serverThing->raw_methods();
	    }
            # Store it in the object so we can use it to validate methods.
            my %methodHash = map { $_ => 1 } @$methods;
            $serverThing->{methods} = \%methodHash;
	    $serverThing->{raw_methods} = { map { $_ => 1 } @$raw_methods };
            my $cgi;
            if (! defined $key) {
                # No tracing key, so presume we're a web service. Check for Fast CGI.
                if ($ENV{REQUEST_METHOD} eq '') {
                    # Count the number of requests.
                    my $requests = 0;
                    # warn "Starting fast CGI loop.\n"; ##HACK Trace("Starting Fast CGI loop.") if T(3);
                    # Loop through the fast CGI requests. If we have request throttling,
                    # we exit after a maximum number of requests has been exceeded.
                    require CGI::Fast;
		    open(SERVER_STDERR, ">&", *STDERR);
                    while ((MAX_REQUESTS == 0 || ++$requests < MAX_REQUESTS) &&
                           ($cgi = new CGI::Fast())) {
			#
			# Remap STDERR. Inside here, our STDERR is a tie to a FCGI::Stream
			# so we need to save it to keep FCGI happy.
			#
			*SAVED_STDERR = *STDERR;
                        *STDERR = *SERVER_STDERR;
                        my $function = $cgi->param('function') || "<non-functional>"; # (useful if we do tracing in here)
                        # warn "Function request is $function in task $$.\n"; ##HACK
                        RunRequest($cgi, $serverThing);
                        # warn "$requests requests complete in fast CGI task $$.\n"; ##HACK Trace("Request $requests complete in task $$.") if T(3);
			*STDERR = *SAVED_STDERR;
                    }
                    # warn "Terminating FastCGI task $$ after $requests requests.\n"; ##HACK Trace("Terminating FastCGI task $$ after $requests requests.") if T(2);
		    close(SERVER_STDERR);
                } else {
                    # Here we have a normal web service (non-Fast).
                    my $cgi = CGI->new();
                    # Check for a source parameter. This gets used as the tracing key.
                    $key = $cgi->param('source');
                    # Run this request.
                    RunRequest($cgi, $serverThing);
                }
            } else {
                # We're being invoked from the command line. Use the tracing
                # key to find the parm file and create the CGI object from that.
                my $ih = Open(undef, "<$FIG_Config::temp/$key.parms");
                $cgi = CGI->new($ih);
                # Run this request.
                RunRequest($cgi, $serverThing);
            }
        }
    }
}

=head2 RunRabbitMQClient

This routine sets itself up as a FCGI listener for incoming FCGI requests (like
RunServer), but instead of processing the requests forwards them to the
RabbitMQ message broker. For each request, we set up an ephemeral response
queue for handling the response to the message.

Note that we don't touch the message bodies; they are only decoded on the
actual messaging processing node.


=cut

sub RunRabbitMQClient {
    # Get the parameters.
    my ($serverName, $conf) = @_;

    require Net::RabbitMQ;
    require UUID;
    require CGI::Fast;

    my $conn = Net::RabbitMQ->new();

    $conn->connect($conf->{rabbitmq_host},
	       {
		   user => $conf->{rabbitmq_user},
		   password => $conf->{rabbitmq_password},
		   (defined($conf->{rabbitmq_vhost}) ? (vhost => $conf->{rabbitmq_vhost}) : ()),
	       });

    my $channel = 1;
    $conn->channel_open($channel);

    my $exchange_name = "svr.$serverName";

    my $queue_name = $conn->queue_declare($channel,'', { durable => 0, exclusive => 1, auto_delete => 1 });
    print "Created $queue_name\n";

    my $requests = 0;
    open(SERVER_STDERR, ">&", *STDERR);
    while ((MAX_REQUESTS == 0 || ++$requests < MAX_REQUESTS) &&
	   (my $cgi = new CGI::Fast())) {
	#
	# Remap STDERR. Inside here, our STDERR is a tie to a FCGI::Stream
	# so we need to save it to keep FCGI happy.
	#
	*SAVED_STDERR = *STDERR;
	*STDERR = *SERVER_STDERR;

	print STDERR "Working...\n";

	my $function = $cgi->param('function');

	my($uuid, $uuid_str);

	UUID::generate($uuid);
	UUID::unparse($uuid, $uuid_str);

	my $encoding = $cgi->param('encoding') || 'yaml';

	my $type;
	if ($encoding eq 'yaml')
	{
	    $type = 'application/yaml';
	}
	elsif ($encoding eq 'yaml2')
	{
	    $type = 'application/yaml2';
	}
	else
	{
	    $type = 'application/json';
	}

	print STDERR "publish request to $exchange_name rpc.$function\n";
	$conn->publish($channel, "rpc.$function", $cgi->param('args'),
		   { exchange => $exchange_name },
		   {
		       content_type => $type,
		       correlation_id => $uuid_str,
		       reply_to => $queue_name,
		   });

	print STDERR "await resp\n";
	$conn->consume($channel, $queue_name, { no_ack => 1 });

	my $msg = $conn->recv();
	print STDERR Dumper($msg);
	print "OK\n";

	*STDERR = *SAVED_STDERR;
    }
    # warn "Terminating FastCGI task $$ after $requests requests.\n"; ##HACK Trace("Terminating FastCGI task $$ after $requests requests.") if T(2);
    close(SERVER_STDERR);

}

=head3 RunRabbitMQClientAsync($server_name, $config)

Run the asynchronous FCGI gateway server.

=cut

sub RunRabbitMQClientAsync {
    # Get the parameters.
    my ($serverName, $conf) = @_;

    require Net::Async::FastCGI;
    require IO::Handle;
    require IO::Async::Loop;
    require IO::Async::Handle;
    require IO::Async::Timer::Periodic;
    require IO::Async::Signal;
    require Net::RabbitMQ;
    require UUID;
    require CGI::Fast;

    my $logger = get_logger("FCGI::RunRabbitMQClientAsync");

    my $loop = IO::Async::Loop->new();

    my $conn = Net::RabbitMQ->new();

    my $rabbit_fd = $conn->connect($conf->{rabbitmq_host},
			       {
				   user => $conf->{rabbitmq_user},
				   password => $conf->{rabbitmq_password},
				   (defined($conf->{rabbitmq_vhost}) ? (vhost => $conf->{rabbitmq_vhost}) : ()),
			       });

    my $channel = 1;
    $conn->channel_open($channel);

    my $exchange_name = "svr.$serverName";

    my $queue_name = $conn->queue_declare($channel,'', { durable => 0, exclusive => 1, auto_delete => 1 });
    $logger->info("Created $queue_name fcgi_port=$conf->{fcgi_port}");

    $conn->consume($channel, $queue_name, { no_ack => 1 });

    my $waiting = {};
    my $global = { messages => 0,
		   queue_size => 0,
		   };
    my $rabbit_fh = IO::Handle->new();
    $rabbit_fh->fdopen($rabbit_fd, "r");

    my $timer = IO::Async::Timer::Periodic->new(interval => 60,
						on_tick => sub {
						    my $last = $global->{last_time};
						    my $now = gettimeofday;
						    if (defined($last))
						    {
							my $int = $now - $last;
							my $rate = $global->{messages} / $int;
							$logger->debug("$rate $global->{queue_size}");
							for my $ent (values %$waiting)
							{
							    my $dur = $now - $ent->{start_time};
							    my $ip = $ent->{request}->param("REMOTE_ADDR");
							    $logger->debug(join("\t", '', $dur, $ip, $ent->{function}));
							}
						    }
						    $global->{last_time} = $now;
						    $global->{messages} = 0;
						});

    $timer->start();
    $loop->add($timer);
    my $rabbit_listener = IO::Async::Handle->new(read_handle => $rabbit_fh,
						 on_read_ready => sub {
						     AsyncRabbitCheck($loop, $channel, $conn, $waiting, $global);
						 });
    $loop->add($rabbit_listener);

    my $fcgi = Net::Async::FastCGI->new(on_request => sub {
					    my($fcgi, $req) = @_;
					    $global->{messages}++;

					    AsyncFcgiReq($loop, $fcgi, $req, $channel, $conn, $queue_name,
							 $exchange_name, $waiting, $global);

					    if (defined($conf->{max_messages}) && $global->{messages} > $conf->{max_messages})
					    {
						$global->{request_exit} = 1;
					    }
					});
    #
    # This is critical, otherwise we get our bytes munged.
    #
    $fcgi->configure(default_encoding => undef);

    for my $signal (qw(HUP INT TERM))
    {
	my $sighandler = IO::Async::Signal->new(name => $signal,
						on_receipt => sub { AsyncSignalHandler($global, $logger, $loop, $fcgi); });
	$loop->add($sighandler);
    }

    $loop->add( $fcgi );

    $fcgi->listen(service  => $conf->{fcgi_port},
		  socktype => 'stream',
		  host => '0.0.0.0',
		   on_resolve_error => sub { $logger->error("Cannot resolve - $_[0]"); },
		   on_listen_error  => sub { $logger->error("Cannot listen"); },
		  );

    $global->{idle_notifier_count} = scalar grep { $_->isa("IO::Async::Handle") } $loop->notifiers();

    while (1)
    {
	$loop->loop_once();

	if ($global->{request_exit} && $global->{queue_size} == 0)
	{
	    my $n = scalar grep { $_->isa("IO::Async::Handle") } $loop->notifiers();
	    if ($n <= $global->{idle_notifier_count})
	    {
		$logger->info("Final requests have completed, exiting program.");
		return;
	    }
	}
    }
}

sub AsyncSignalHandler
{
    my($global, $logger, $loop, $fcgi) = @_;

    if ($global->{signal_seen})
    {
	$logger->info("AsyncSignalHandler already saw a signal, terminating now");
	exit;
    }
    $logger->info("AsyncSignalHandler handling first signal");

    #
    # Mark for a graceful exit.
    #

    $logger->info("Requesting graceful exit");

    $global->{signal_seen} = 1;
    $global->{request_exit} = 1;
#    $fcgi->close_read();
}

sub AsyncRabbitCheck
{
    my($loop, $channel, $conn, $waiting, $global) = @_;

    my $msg = $conn->recv();

    my $logger = get_logger("FCGI::QueueRead");
    $logger->debug("AsyncRabbitCheck start");

    my $corr= $msg->{props}->{correlation_id};

    my $slot = delete $waiting->{$corr};
    if ($slot)
    {
	my $req = $slot->{request};
	my $start = $slot->{start_time};

	#
	# Unpack body.
	#
	my($code, $msg, $body) = unpack("nN/aN/a", $msg->{body});

	my $now = gettimeofday;
	my $elap = $now - $start;
	$logger->info(sprintf("Evaluation of method $slot->{function} complete code=$code time=%.6f ip=%s corr=$corr",
			      $elap, $req->{params}->{REMOTE_ADDR}));

	try {
	    $req->print_stdout("Status: $code $msg\r\n" .
			       "Content-type: application/octet-stream\r\n" .
			       "\r\n");
	    $req->print_stdout($body);
	}
	catch {
	    $logger->error("Error caught while returning response: $_");
	};
	$req->finish();
	$global->{queue_size}--;
    }
    else
    {
	$logger->error("No matching request found for correlation_id=$corr");
    }
}

sub AsyncFcgiReq
{
    my($loop, $fcgi, $req, $channel, $conn, $queue_name, $exchange_name, $waiting, $global) = @_;

    my $logger = get_logger("FCGI::Handler");

    my $params = $req->params;
    my $cgi = CGI->new();
    my $in = $req->read_stdin;
    $cgi->parse_params($in);

    my $function = $cgi->param('function');
    my $publish_queue = "rpc.$function";

#    print STDERR Dumper($cgi, $req);
    #
    # Inspect the incoming request to see if we have one of the "slow queue"
    # requests. Currently these are only the blast-based assignment
    # calls using assign_function_to_prot.
    #
    if (($function eq 'assign_function_to_prot' && $cgi->param('-assignToAll')) ||
	($function eq 'metabolic_reconstruction'))
    {
	$publish_queue = "rpc_slow.$function";
    }

    my($uuid, $uuid_str);

    UUID::generate($uuid);
    UUID::unparse($uuid, $uuid_str);

    $logger->debug("Request received for $function correlation_id=$uuid_str");

    my $encoding = $cgi->param('encoding') || 'yaml';
    my $type;
    if ($encoding eq 'yaml')
    {
	$type = 'application/yaml';
    }
    elsif ($encoding eq 'yaml2')
    {
	$type = 'application/yaml2';
    }
    else
    {
	$type = 'application/json';
    }

    my $now = gettimeofday;

    my $s = YAML::Dump($params);
#    if ($s =~ /CONTENT/ )
#    {
#	$s = $s . ('-'  x (944 - length($s)));
#    }
    my $packed_data = pack("N/aN/a", $s, $in);
#    print "utf s=" . (Encode::is_utf8($s) ? 'YES' : 'NO') . "\n";
#    print "utf in=" . (Encode::is_utf8($in) ? 'YES' : 'NO') . "\n";

#    print "pack length " . length($s) . " is_utf=" . (Encode::is_utf8($packed_data) ? 'YES' : 'NO') . "\n";
#    utf8::downgrade($packed_data);
#    use Devel::Peek;

#    print Dump($packed_data);
    $conn->publish($channel, $publish_queue,
		   $packed_data,
	       { exchange => $exchange_name },
		   {
		       content_type => $type,
		       correlation_id => $uuid_str,
		       reply_to => $queue_name,
		   });

    $global->{queue_size}++;

    $waiting->{$uuid_str} = { request => $req,
			      start_time => $now,
			      function => $function,
			      };
}

=head2 RunRabbitMQServer

This is the agent code that listens on a queue for incoming requests to
process data. We run one of these processes for every core we want to
do active processing.

=cut

sub RunRabbitMQServer {
    # Get the parameters.
    my ($serverName, $conf) = @_;

    my $logger = get_logger("Server");
    $logger->info("RunRabbitMQServer startup");

    eval {
        my $output = $serverName;
        $output =~ s/::/\//;
        require "$output.pm";
    };

    if ($@) {
        $logger->logdie("Could not load server module $serverName");
    }
    # Having successfully loaded the server code, we create the object.
    my $serverThing = $serverName->new();

    #
    # If we are running with memcache, configure the server for it.
    #
    if ($conf->{memcache_namespace} && ref($conf->{memcache_servers}) eq 'ARRAY' && @{$conf->{memcache_servers}})
    {
	if (!$serverThing->can('_set_memcache'))
	{
	    warn "Server $serverName does not have a _set_memcache method";
	}
	else
	{
	    my $mcc = {
		servers => $conf->{memcache_servers},
		namespace => $conf->{memcache_namespace},
	    };
	    print STDERR "Create memcache with config " . Dumper($mcc);
	    require Cache::Memcached::Fast;
	    my $mc = Cache::Memcached::Fast->new($mcc);
	    $serverThing->_set_memcache($mc);

	}
    }

    my $methodsL = $serverThing->methods;
    my $raw_methodsL = $serverThing->can("raw_methods") ? $serverThing->raw_methods : [];
    my %methods = (methods => 1 );
    my %raw_methods;
    $methods{$_} = 1 for @$methodsL;
    $raw_methods{$_} = 1 for @$raw_methodsL;

    require Net::RabbitMQ;
    require UUID;
    require CGI::Fast;

    my $conn = Net::RabbitMQ->new();

    $conn->connect($conf->{rabbitmq_host},
	       {
		   user => $conf->{rabbitmq_user},
		   password => $conf->{rabbitmq_password},
		   (defined($conf->{rabbitmq_vhost}) ? (vhost => $conf->{rabbitmq_vhost}) : ()),
	       });

    my $channel = 1;
    $conn->channel_open($channel);

    $conn->basic_qos($channel, { prefetch_count => 1 });

    my $exchange_name = "svr.$serverName";

    my $queue_name = "q.$exchange_name";
    my $base = "rpc";
    if ($conf->{slow_queue_listener})
    {
	$base = "rpc_slow";
	$queue_name = "qslow.$exchange_name";
    }

    $conn->exchange_declare($channel, $exchange_name, { exchange_type => "topic", durable => 1,
							    auto_delete => 0 });

    $conn->queue_declare($channel, $queue_name, { durable => 1, exclusive => 0, auto_delete => 0 });

    $conn->queue_bind($channel, $queue_name, $exchange_name, "$base.*");

    $logger->debug("Listening: queue=$queue_name base=$base");

    $conn->consume($channel, $queue_name, { no_ack => 0 } );
    my $messages_processed = 0;
    while (!defined($conf->{max_messages}) ||
	   $messages_processed < $conf->{max_messages})
    {
	$logger->debug("Await message");

	my $msg = $conn->recv();
	$conn->ack($channel, $msg->{delivery_tag});

	my $key = $msg->{routing_key};

	my $args = [];

	if ($key !~ /^$base\.(.*)/)
	{
	    $logger->error("invalid message key '$key'");
#	    $conn->ack($channel, $msg->{delivery_tag});
	    next;
	}
	my $method = $1;

	my $props = $msg->{props};
	my $encoding = $props->{content_type};
	my $corr = $props->{correlation_id};
	my $reply_to = $props->{reply_to};

	my $raw_body = $msg->{body};

	my($param_json, $body);
	my $param;

	try {
	    ($param_json, $body) = unpack("N/aN/a", $raw_body);
	} catch {
	    $logger->error("Error unpacking body: $!");
	    next;
	};

	try {
	    $param = YAML::Load($param_json);
	} catch {

	    $logger->error("Error parsing JSON for method $method: $_");
	    $param = {};
	};

	my $cgi = CGI->new();
	$cgi->parse_params($body);

	my @res = ();
	my $err;
	my $enc_res = '';
	my $start = gettimeofday;

	try {
	    if ($raw_methods{$method})
	    {
		$logger->debug("Raw evaluation of method $method");
		@res = $serverThing->$method($cgi);
	    }
	    elsif ($methods{$method})
	    {
		$logger->debug("Normal evaluation of method $method");
		my $arg_raw = $cgi->param('args');

		if ($encoding eq 'application/json')
		{
		    $args = JSON::Any->jsonToObj($arg_raw);
		}
		elsif ($encoding eq 'application/yaml')
		{
		    $args = YAML::Load($arg_raw);
		}
		elsif ($encoding eq 'application/yaml2')
		{
		    $args = YAML::XS::Load($arg_raw);
		}
		else
		{
		    $logger->logwarn("Invalid encoding $encoding");
		    $args = [];
		}
		@res = eval { $serverThing->$method($args) };
	    }
	    else
	    {
		$logger->error("No method defined for $method");
		die new ServerReturn(500, "Undefined method", "No method defined for $method");
	    }
	    my $end = gettimeofday;
	    my $elap = $end - $start;
	    $logger->info(sprintf("Evaluation of method $method complete time=%.6f corr=$corr", $elap));


	    if ($encoding eq 'application/json')
	    {
		$enc_res = JSON::Any->objToJson(@res);
	    }
	    elsif ($encoding eq 'application/yaml')
	    {
		$enc_res = YAML::Dump(@res);
	    }
	    elsif ($encoding eq 'application/yaml2')
	    {
		$enc_res = YAML::XS::Dump(@res);
	    }
	}
	catch
	{
	    $logger->error("Error encountered in method evaluation: $_");
	    if (ref($_))
	    {
		$err = $_;
	    }
	    else
	    {
		$err = new ServerReturn(500, "Evaluation error", $_);
	    }
	};
	# print Dumper($encoding, $enc_res);

	#
	# The returned message consists of a response code, response message,
	# and the body of the response. These map currently to the HTTP return code,
	# the short message, and the body of the reply. The FCGI management code that
	# receives these responses does not touch the data in the body.
	#

	my $ret;

	if ($err)
	{
	    $ret = $err;
	}
	else
	{
	    $ret = ServerReturn->new(200, "OK", $enc_res);
	}

	$conn->publish($channel, $reply_to, $ret->package_response(), { exchange => '' }, { correlation_id => $corr });
	$messages_processed++;
    }
}


=head2 Server Utility Methods

The methods in this section are utilities of general use to the various
server modules.

=head3 AddSubsystemFilter

    ServerThing::AddSubsystemFilter(\$filter, $args, $roles);

Add subsystem filtering information to the specified query filter clause
based on data in the argument hash. The argument hash will be checked for
the C<-usable> parameter, which includes or excludes unusuable subsystems,
the C<-exclude> parameter, which lists types of subsystems that should be
excluded, and the C<-aux> parameter, which filters on auxiliary roles.

=over 4

=item filter

Reference to the current filter string. If additional filtering is required,
this string will be updated.

=item args

Reference to the parameter hash for the current server call. This hash will
be examined for the C<-usable> and C<-exclude> parameters.

=item roles

If TRUE, role filtering will be applied. In this case, the default action
is to exclude auxiliary roles unless C<-aux> is TRUE.

=back

=cut

use constant SS_TYPE_EXCLUDE_ITEMS => { 'cluster-based' => 1,
                                         experimental   => 1,
                                         private        => 1 };

sub AddSubsystemFilter {
    # Get the parameters.
    my ($filter, $args, $roles) = @_;
    # We'll put the new filter stuff in here.
    my @newFilters;
    # Unless unusable subsystems are desired, we must add a clause to the filter.
    # The default is that only usable subsystems are included.
    my $usable = 1;
    # This default can be overridden by the "-usable" parameter.
    if (exists $args->{-usable}) {
        $usable = $args->{-usable};
    }
    # If we're restricting to usable subsystems, add a filter to that effect.
    if ($usable) {
        push @newFilters, "Subsystem(usable) = 1";
    }
    # Check for exclusion filters.
    my $exclusions = ServerThing::GetIdList(-exclude => $args, 1);
    for my $exclusion (@$exclusions) {
        if (! SS_TYPE_EXCLUDE_ITEMS->{$exclusion}) {
            Confess("Invalid exclusion type \"$exclusion\".");
        } else {
            # Here we have to exclude subsystems of the specified type.
            push @newFilters, "Subsystem($exclusion) = 0";
        }
    }
    # Check for role filtering.
    if ($roles) {
        # Here, we filter out auxiliary roles unless the user requests
        # them.
        if (! $args->{-aux}) {
            push @newFilters, "Includes(auxiliary) = 0"
        }
    }
    # Do we need to update the incoming filter?
    if (@newFilters) {
        # Yes. If the incoming filter is nonempty, push it onto the list
        # so it gets included in the result.
        if ($$filter) {
            push @newFilters, $$filter;
        }
        # Put all the filters together to form the new filter.
        $$filter = join(" AND ", @newFilters);
        Trace("Subsystem filter is $$filter.") if T(ServerUtilities => 3);
    }
}



=head3 GetIdList

    my $ids = ServerThing::GetIdList($name => $args, $optional);

Get a named list of IDs from an argument structure. If the IDs are
missing, or are not a list, an error will occur.

=over 4

=item name

Name of the argument structure member that should contain the ID list.

=item args

Argument structure from which the ID list is to be extracted.

=item optional (optional)

If TRUE, then a missing value will not generate an error. Instead, an empty list
will be returned. The default is FALSE.

=item RETURN

Returns a reference to a list of IDs taken from the argument structure.

=back

=cut

sub GetIdList {
    # Get the parameters.
    my ($name, $args, $optional) = @_;
    # Declare the return variable.
    my $retVal;
    # Check the argument format.
    if (! defined $args && $optional) {
        # Here there are no parameters, but the arguments are optional so it's
        # okay.
        $retVal = [];
    } elsif (ref $args ne 'HASH') {
        # Here we have an invalid parameter structure.
        Confess("No '$name' parameter present.");
    } else {
        # Here we have a hash with potential parameters in it. Try to get the
        # IDs from the argument structure.
        $retVal = $args->{$name};
        # Was a member found?
        if (! defined $retVal) {
            # No. If we're optional, return an empty list; otherwise throw an error.
            if ($optional) {
                $retVal = [];
            } else {
                Confess("No '$name' parameter found.");
            }
        } else {
            # Here we found something. Get the parameter type. We want a list reference.
            # If it's a scalar, we'll convert it to a singleton list. If it's anything
            # else, it's an error.
            my $type = ref $retVal;
            if (! $type) {
                $retVal = [$retVal];
            } elsif ($type ne 'ARRAY') {
                Confess("The '$name' parameter must be a list.");
            }
        }
    }
    # Return the result.
    return $retVal;
}


=head3 RunTool

    ServerThing::RunTool($name => $cmd);

Run a command-line tool. A non-zero return value from the tool will cause
a fatal error, and the tool's error log will be traced.

=over 4

=item name

Name to give to the tool in the error output.

=item cmd

Command to use for running the tool. This should be the complete command line.
The command should not contain any fancy piping, though it may redirect the
standard input and output. The command will be modified by this method to
redirect the error output to a temporary file.

=back

=cut

sub RunTool {
    # Get the parameters.
    my ($name, $cmd) = @_;
    # Compute the log file name.
    my $errorLog = "$FIG_Config::temp/errors$$.log";
    # Execute the command.
    Trace("Executing command: $cmd") if T(ServerUtilities => 3);
    my $res = system("$cmd 2> $errorLog");
    Trace("Return from $name tool is $res.") if T(ServerUtilities => 3);
    # Check the result code.
    if ($res != 0) {
        # We have an error. If tracing is on, trace it.
        if (T(ServerUtilities => 1)) {
            TraceErrorLog($name, $errorLog);
        }
        # Delete the error log.
        unlink $errorLog;
        # Confess the error.
        Confess("$name command failed with error code $res.");
    } else {
        # Everything worked. Trace the error log if necessary.
        if (T(ServerUtilities => 3) && -s $errorLog) {
            TraceErrorLog($name, $errorLog);
        }
        # Delete the error log if there is one.
        unlink $errorLog;
    }
}

=head3 ReadCountVector

    my $vector = ServerThing::ReadCountVector($qh, $field, $rawFlag);

Extract a count vector from a query. The query can contain zero or more results,
and the vectors in the specified result field of the query must be concatenated
together in order. This method is optimized for the case (expected to be most
common) where there is only one result.

=over 4

=item qh

Handle for the query from which results are to be extracted.

=item field

Name of the field containing the count vectors.

=item rawFlag

TRUE if the vector is to be returned as a raw string, FALSE if it is to be returned
as reference to a list of numbers.

=item RETURN

Returns the desired vector, either encoded as a string or as a reference to a list
of numbers.

=back

=cut

sub ReadCountVector {
    # Get the parameters.
    my ($qh, $field, $rawFlag) = @_;
    # Declare the return variable.
    my $retVal;
    # Loop through the query results.
    while (my $resultRow = $qh->Fetch()) {
        # Get this vector.
        my ($levelVector) = $resultRow->Value($field, $rawFlag);
        # Is this the first result?
        if (! defined $retVal) {
            # Yes. Assign the result directly.
            $retVal = $levelVector;
        } elsif ($rawFlag) {
            # This is a second result and the vectors are coded as strings.
            $retVal .= $levelVector;
        } else {
            # This is a second result and the vectors are coded as array references.
            push @$retVal, @$levelVector;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 ChangeDB

    ServerThing::ChangeDB($thing, $newDbName);

Change the sapling database used by this server. The old database will be closed and a
new one attached.

=over 4

=item newDbName

Name of the new Sapling database on which this server should operate. If omitted, the
default database will be used.

=back

=cut

sub ChangeDB {
    # Get the parameters.
    my ($thing, $newDbName) = @_;
    # Default the db-name if it's not specified.
    if (! defined $newDbName) {
        $newDbName = $FIG_Config::saplingDB;
    }
    # Check to see if we really need to change.
    my $oldDB = $thing->{db};
    if (! defined $oldDB || $oldDB->dbName() ne $newDbName) {
        # We need a new sapling.
        require Sapling;
        my $newDB = Sapling->new(dbName => $newDbName);
        $thing->{db} = $newDB;
    }
}


=head2 Gene Correspondence File Methods

These methods relate to gene correspondence files, which are generated by the
L<svr_corresponding_genes.pl> script. Correspondence files are cached in the
organism cache (I<$FIG_Config::orgCache>) directory. Eventually they will be
copied into the organism directories themselves. At that point, the code below
will be modified to check the organism directories first and use the cache
directory if no file is found there.

A gene correspondence file contains correspondences from a source genome to a
target genome. Most such correspondences are bidirectional best hits. A unidirectional
best hit may exist from the source genome to the target genome or in the reverse
direction from the targtet genome to the source genome. The cache directory itself
is divided into subdirectories by organism. The subdirectory has the source genome
name and the files themselves are named by the target genome.

Some of the files are invalid and will be erased when they are found. A file is
considered invalid if it has a non-numeric value in a numeric column or if it
does not have any unidirectional hits from the target genome to the source
genome.

The process of managing the correspondence files is tricky and dangerous because
of the possibility of race conditions. It can take several minutes to generate a
file, and if two processes try to generate the same file at the same time we need
to make sure they don't step on each other.

In stored files, the source genome ID is always lexically lower than the target
genome ID. If a correspondence in the reverse direction is desired, the converse
file is found and the contents flipped automatically as they are read. So, the
correspondence from B<360108.3> to B<100226.1> would be found in a file with the
name B<360108.3> in the directory for B<100226.1>. Since this file actually has
B<100226.1> as the source and B<360108.3> as the target, the columns are
re-ordered and the arrows reversed before the file contents are passed to the
caller.

=head4 Gene Correspondence List

A gene correspondence file contains 18 columns. These are usually packaged as
a reference to list of lists. Each sub-list has the following format.

=over 4

=item 0

The ID of a PEG in genome 1.

=item 1

The ID of a PEG in genome 2 that is our best estimate of a "corresponding gene".

=item 2

Count of the number of pairs of matching genes were found in the context.

=item 3

Pairs of corresponding genes from the contexts.

=item 4

The function of the gene in genome 1.

=item 5

The function of the gene in genome 2.

=item 6

Comma-separated list of aliases for the gene in genome 1 (any protein with an
identical sequence is considered an alias, whether or not it is actually the
name of the same gene in the same genome).

=item 7

Comma-separated list of aliases for the gene in genome 2 (any protein with an
identical sequence is considered an alias, whether or not it is actually the
name of the same gene in the same genome).

=item 8

Bi-directional best hits will contain "<=>" in this column; otherwise, "->" will appear.

=item 9

Percent identity over the region of the detected match.

=item 10

The P-score for the detected match.

=item 11

Beginning match coordinate in the protein encoded by the gene in genome 1.

=item 12

Ending match coordinate in the protein encoded by the gene in genome 1.

=item 13

Length of the protein encoded by the gene in genome 1.

=item 14

Beginning match coordinate in the protein encoded by the gene in genome 2.

=item 15

Ending match coordinate in the protein encoded by the gene in genome 2.

=item 16

Length of the protein encoded by the gene in genome 2.

=item 17

Bit score for the match. Divide by the length of the longer PEG to get
what we often refer to as a "normalized bit score".

=item 18 (optional)

Clear-correspondence indicator. If present, will be C<1> if the correspondence is a
clear bidirectional best hit (no similar candidates) and C<0> otherwise.

=back

In the actual files, there will also be reverse correspondences indicated by a
back-arrow ("<-") in item (8). The output returned by the servers, however,
is filtered so that only forward correspondences occur. If a converse file
is used, the columns are re-ordered and the arrows reversed so that it looks
correct.

=cut

# hash for reversing the arrows
use constant ARROW_FLIP => { '->' => '<-', '<=>' => '<=>', '<-' => '->' };
# list of columns that contain numeric values that need to be validated
use constant NUM_COLS => [2,9,10,11,12,13,14,15,16,17];

=head3 CheckForGeneCorrespondenceFile

    my ($fileName, $converse) = ServerThing::CheckForGeneCorrespondenceFile($genome1, $genome2);

Try to find a gene correspondence file for the specified genome pairing. If the
file exists, its name and an indication of whether or not it is in the correct
direction will be returned.

=over 4

=item genome1

Source genome for the desired correspondence.

=item genome2

Target genome for the desired correspondence.

=item RETURN

Returns a two-element list. The first element is the name of the file containing the
correspondence, or C<undef> if the file does not exist. The second element is TRUE
if the correspondence would be forward or FALSE if the file needs to be flipped.

=back

=cut

sub CheckForGeneCorrespondenceFile {
    # Get the parameters.
    my ($genome1, $genome2) = @_;
    # Declare the return variables.
    my ($fileName, $converse);
    # Determine the ordering of the genome IDs.
    my ($corrFileName, $genomeA, $genomeB) = ComputeCorrespondenceFileName($genome1, $genome2);
    $converse = ($genomeA ne $genome1);
    # Look for a file containing the desired correspondence. (The code to check for a
    # pre-computed file in the organism directories is currently turned off, because
    # these files are all currently invalid.)
    my $testFileName = "$FIG_Config::organisms/$genomeA/CorrToReferenceGenomes/$genomeB";
    if (0 && -f $testFileName) {
        # Use the pre-computed file.
        Trace("Using pre-computed file $fileName for genome correspondence.") if T(Corr => 3);
        $fileName = $testFileName;
    } elsif (-f $corrFileName) {
        $fileName = $corrFileName;
        Trace("Using cached file $fileName for genome correspondence.") if T(Corr => 3);
    }
    # Return the result.
    return ($fileName, $converse);
}


=head3 ComputeCorrespondenceFileName

    my ($fileName, $genomeA, $genomeB) = ServerThing::ComputeCorrespondenceFileName($genome1, $genome2);

Compute the name to be given to a genome correspondence file in the organism cache
and return the source and target genomes that would be in it.

=over 4

=item genome1

Source genome for the desired correspondence.

=item genome2

Target genome for the desired correspondence.

=item RETURN

Returns a three-element list. The first element is the name of the file to contain the
correspondence, the second element is the name of the genome that would act as the
source genome in the file, and the third element is the name of the genome that would
act as the target genome in the file.

=back

=cut

sub ComputeCorrespondenceFileName {
    # Get the parameters.
    my ($genome1, $genome2) = @_;
    # Declare the return variables.
    my ($fileName, $genomeA, $genomeB);
    # Determine the ordering of the genome IDs.
    if (MustFlipGenomeIDs($genome1, $genome2)) {
        ($genomeA, $genomeB) = ($genome2, $genome1);
    } else {
        ($genomeA, $genomeB) = ($genome1, $genome2);
    }
    # Insure the source organism has a subdirectory in the organism cache.
    my $orgDir = ComputeCorrespondenceDirectory($genomeA);
    # Compute the name of the correspondence file for the appropriate target genome.
    $fileName = "$orgDir/$genomeB";
    # Return the results.
    return ($fileName, $genomeA, $genomeB);
}


=head3 ComputeCorresopndenceDirectory

    my $dirName = ServerThing::ComputeCorrespondenceDirectory($genome);

Return the name of the directory that would contain the correspondence files
for the specified genome.

=over 4

=item genome

ID of the genome whose correspondence file directory is desired.

=item RETURN

Returns the name of the directory of interest.

=back

=cut

sub ComputeCorrespondenceDirectory {
    # Get the parameters.
    my ($genome) = @_;
    # Insure the source organism has a subdirectory in the organism cache.
    my $retVal = "$FIG_Config::orgCache/$genome";
    Tracer::Insure($retVal, 0777);
    # Return it.
    return $retVal;
}


=head3 CreateGeneCorrespondenceFile

    my ($fileName, $converse) = ServerThing::CheckForGeneCorrespondenceFile($genome1, $genome2);

Create a new gene correspondence file in the organism cache for the specified
genome correspondence. The name of the new file will be returned along with
an indicator of whether or not it is in the correct direction.

=over 4

=item genome1

Source genome for the desired correspondence.

=item genome2

Target genome for the desired correspondence.

=item RETURN

Returns a two-element list. The first element is the name of the file containing the
correspondence, or C<undef> if an error occurred. The second element is TRUE
if the correspondence would be forward or FALSE if the file needs to be flipped.

=back

=cut

sub CreateGeneCorrespondenceFile {
    # Get the parameters.
    my ($genome1, $genome2) = @_;
    # Declare the return variables.
    my ($fileName, $converse);
    # Compute the ultimate name for the correspondence file.
    my ($corrFileName, $genomeA, $genomeB) = ComputeCorrespondenceFileName($genome1, $genome2);
    $converse = ($genome1 ne $genomeA);
    # Generate a temporary file name in the same directory. We'll build the temporary
    # file and then rename it when we're done.
    my $tempFileName = "$corrFileName.$$.tmp";
    # This will be set to FALSE if we detect an error.
    my $fileOK = 1;
    # The file handles will be put in here.
    my ($ih, $oh);
    # Protect from errors.
    eval {
        # Open the temporary file for output.
        $oh = Open(undef, ">$tempFileName");
        # Open a pipe to get the correspondence data.
        $ih = Open(undef, "$FIG_Config::bin/svr_corresponding_genes -u localhost $genomeA $genomeB |");
        Trace("Creating correspondence file for $genomeA to $genomeB in temporary file $tempFileName.") if T(3);
        # Copy the pipe date into the temporary file.
        while (! eof $ih) {
            my $line = <$ih>;
            print $oh $line;
        }
        # Close both files. If the close fails we need to know: it means there was a pipe
        # error.
        $fileOK &&= close $ih;
        $fileOK &&= close $oh;
    };
    if ($@) {
        # Here a fatal error of some sort occurred. We need to force the files closed.
        close $ih if $ih;
        close $oh if $oh;
    } elsif ($fileOK) {
        # Here everything worked. Try to rename the temporary file to the real
        # file name.
        if (rename $tempFileName, $corrFileName) {
            # Everything is ok, fix the permissions and return the file name.
            chmod 0664, $corrFileName;
            $fileName = $corrFileName;
            Trace("Created correspondence file $fileName.") if T(Corr => 3);
        }
    }
    # If the temporary file exists, delete it.
    if (-f $tempFileName) {
        unlink $tempFileName;
    }
    # Return the results.
    return ($fileName, $converse);
}


=head3 MustFlipGenomeIDs

    my $converse = ServerThing::MustFlipGenomeIDs($genome1, $genome2);

Return TRUE if the specified genome IDs are out of order. When genome IDs are out of
order, they are stored in the converse order in correspondence files on the server.
This is a simple method that allows the caller to check for the need to flip.

=over 4

=item genome1

ID of the proposed source genome.

=item genome2

ID of the proposed target genome.

=item RETURN

Returns TRUE if the first genome would be stored on the server as a target, FALSE if
it would be stored as a source.

=back

=cut

sub MustFlipGenomeIDs {
    # Get the parameters.
    my ($genome1, $genome2) = @_;
    # Return an indication.
    return ($genome1 gt $genome2);
}


=head3 ReadGeneCorrespondenceFile

    my $list = ServerThing::ReadGeneCorrespondenceFile($fileName, $converse, $all);

Return the contents of the specified gene correspondence file in the form of
a list of lists, with backward correspondences filtered out. If the file is
for the converse of the desired correspondence, the columns will be reordered
automatically so that it looks as if the file were designed for the proper
direction.

=over 4

=item fileName

The name of the gene correspondence file to read.

=item converse (optional)

TRUE if the file is for the converse of the desired correspondence, else FALSE.
If TRUE, the file columns will be reorderd automatically. The default is FALSE,
meaning we want to use the file as it appears on disk.

=item all (optional)

TRUE if backward unidirectional correspondences should be included in the output.
The default is FALSE, in which case only forward and bidirectional correspondences
are included.

=item RETURN

Returns a L</Gene Correspondence List> in the form of a reference to a list of lists.
If the file's contents are invalid or an error occurs, an undefined value will be
returned.

=back

=cut

sub ReadGeneCorrespondenceFile {
    # Get the parameters.
    my ($fileName, $converse, $all) = @_;
    # Declare the return variable. We will only put something in here if we are
    # completely successful.
    my $retVal;
    # This value will be set to 1 if an error is detected.
    my $error = 0;
    # Try to open the file.
    my $ih;
    Trace("Reading correspondence file $fileName.") if T(3);
    if (! open $ih, "<$fileName") {
        # Here the open failed, so we have an error.
        Trace("Failed to open gene correspondence file $fileName: $!") if T(Corr => 1);
        $error = 1;
    }
    # The gene correspondence list will be built in here.
    my @corrList;
    # This variable will be set to TRUE if we find a reverse correspondence somewhere
    # in the file. Not finding one is an error.
    my $reverseFound = 0;
    # Loop until we hit the end of the file or an error occurs. We must check the error
    # first in case the file handle failed to open.
    while (! $error && ! eof $ih) {
        # Get the current line.
        my @row = Tracer::GetLine($ih);
        # Get the correspondence direction and check for a reverse arrow.
        $reverseFound = 1 if ($row[8] eq '<-');
        # If we're in converse mode, reformat the line.
        if ($converse) {
            ReverseGeneCorrespondenceRow(\@row);
        }
        # Validate the row.
        if (ValidateGeneCorrespondenceRow(\@row)) {
            Trace("Invalid row $. found in correspondence file $fileName.") if T(Corr => 1);
            $error = 1;
        }
        # If this row is in the correct direction, keep it.
        if ($all || $row[8] ne '<-') {
            push @corrList, \@row;
        }
    }
    # Close the input file.
    close $ih;
    # If we have no errors, keep the result.
    if (! $error) {
        $retVal = \@corrList;
    }
    # Return the result (if any).
    return $retVal;
}

=head3 ReverseGeneCorrespondenceRow

    ServerThing::ReverseGeneCorrespondenceRow($row)

Convert a gene correspondence row to represent the converse correspondence. The
elements in the row will be reordered to represent a correspondence from the
target genome to the source genome.

=over 4

=item row

Reference to a list containing a single row from a L</Gene Correspondence List>.

=back

=cut

sub ReverseGeneCorrespondenceRow {
    # Get the parameters.
    my ($row) = @_;
    # Flip the row in place.
    ($row->[1], $row->[0], $row->[2], $row->[3], $row->[5], $row->[4], $row->[7],
     $row->[6], $row->[8], $row->[9], $row->[10], $row->[14],
     $row->[15], $row->[16], $row->[11], $row->[12], $row->[13], $row->[17]) = @$row;
    # Flip the arrow.
    $row->[8] = ARROW_FLIP->{$row->[8]};
    # Flip the pairs.
    my @elements = split /,/, $row->[3];
    $row->[3] = join(",", map { join(":", reverse split /:/, $_) } @elements);
}

=head3 ValidateGeneCorrespondenceRow

    my $errorCount = ServerThing::ValidateGeneCorrespondenceRow($row);

Validate a gene correspondence row. The numeric fields are checked to insure they
are numeric and the source and target gene IDs are validated. The return value will
indicate the number of errors found.

=over 4

=item row

Reference to a list containing a single row from a L</Gene Correspondence List>.

=item RETURN

Returns the number of errors found in the row. A return of C<0> indicates the row
is valid.

=back

=cut

sub ValidateGeneCorrespondenceRow {
    # Get the parameters.
    my ($row, $genome1, $genome2) = @_;
    # Denote no errors have been found so far.
    my $retVal = 0;
    # Check for non-numeric values in the number columns.
    for my $col (@{NUM_COLS()}) {
        unless ($row->[$col] =~ /^-?\d+\.?\d*(?:e[+-]?\d+)?$/) {
            Trace("Gene correspondence error. \"$row->[$col]\" not numeric.") if T(Corr => 2);
            $retVal++;
        }
    }
    # Check the gene IDs.
    for my $col (0, 1) {
        unless ($row->[$col] =~ /^fig\|\d+\.\d+\.\w+\.\d+$/) {
            Trace("Gene correspondence error. \"$row->[$col]\" not a gene ID.") if T(Corr => 2);
            $retVal++;
        }
    }
    # Verify the arrow.
    unless (exists ARROW_FLIP->{$row->[8]}) {
        Trace("Gene correspondence error. \"$row->[8]\" not an arrow.") if T(Corr => 2);
        $retVal++;
    }
    # Return the error count.
    return $retVal;
}

=head3 GetCorrespondenceData

    my $corrList = ServerThing::GetCorrespondenceData($genome1, $genome2, $passive, $full);

Return the L</Gene Correspondence List> for the specified source and target genomes. If the
list is in a file, it will be read. If the file does not exist, it may be created.

=over 4

=item genome1

ID of the source genome.

=item genome2

ID of the target genome.

=item passive

If TRUE, then the correspondence file will not be created if it does not exist.

=item full

If TRUE, then both directions of the correspondence will be represented; otherwise, only
correspondences from the source to the target (including bidirectional corresopndences)
will be included.

=item RETURN

Returns a L</Gene Correspondence List> in the form of a reference to a list of lists, or an
undefined value if an error occurs or no file exists and passive mode was specified.

=back

=cut

sub GetCorrespondenceData {
    # Get the parameters.
    my ($genome1, $genome2, $passive, $full) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a gene correspondence file.
    my ($fileName, $converse) = ServerThing::CheckForGeneCorrespondenceFile($genome1, $genome2);
    if ($fileName) {
        # Here we found one, so read it in.
        $retVal = ServerThing::ReadGeneCorrespondenceFile($fileName, $converse, $full);
    }
    # Were we successful?
    if (! defined $retVal) {
        # Here we either don't have a correspondence file, or the one that's there is
        # invalid. If we are NOT in passive mode, then this means we need to create
        # the file.
        if (! $passive) {
            ($fileName, $converse) = ServerThing::CreateGeneCorrespondenceFile($genome1, $genome2);
            # Now try reading the new file.
            if (defined $fileName) {
                $retVal = ServerThing::ReadGeneCorrespondenceFile($fileName, $converse);
            }
        }
    }
    # Return the result.
    return $retVal;

}


=head2 Internal Utility Methods

The methods in this section are used internally by this package.

=head3 RunRequest

    ServerThing::RunRequest($cgi, $serverThing, $docURL);

Run a request from the specified server using the incoming CGI parameter
object for the parameters.

=over 4

=item cgi

CGI query object containing the parameters from the web service request. The
significant parameters are as follows.

=over 8

=item function

Name of the function to run.

=item args

Parameters for the function.

=item encoding

Encoding scheme for the function parameters, either C<yaml> (the default) or C<json> (used
by the Java interface).

=back

Certain unusual requests can come in outside of the standard function interface.
These are indicated by special parameters that override all the others.

=over 8

=item pod

Display a POD documentation module.

=item code

Display an example code file.

=item file

Transfer a file (not implemented).

=back

=item serverThing

Server object against which to run the request.

=item docURL

URL to use for POD documentation requests.

=back

=cut

sub RunRequest {
    # Get the parameters.
    my ($cgi, $serverThing, $docURL) = @_;
    # Make the CGI object available to the server.
    $serverThing->{cgi} = $cgi;
    # Determine the request type.
    my $module = $cgi->param('pod');
    if ($module) {
        # Here we have a documentation request.
        if ($module eq 'ServerScripts') {
            # Here we list the server scripts.
            require ListServerScripts;
            ListServerScripts::main();
        } else {
            # In this case, we produce POD HTML.
            ProducePod($cgi->param('pod'));
        }
    } elsif ($cgi->param('code')) {
        # Here the user wants to see the code for one of our scripts.
        LineNumberize($cgi->param('code'));
    } elsif ($cgi->param('file')) {
        # Here we have a file request. Process according to the type.
        my $type = $cgi->param('file');
        if ($type eq 'open') {
            OpenFile($cgi->param('name'));
        } elsif ($type eq 'create') {
            CreateFile();
        } elsif ($type eq 'read') {
            ReadChunk($cgi->param('name'), $cgi->param('location'), $cgi->param('size'));
        } elsif ($type eq 'write') {
            WriteChunk($cgi->param('name'), $cgi->param('data'));
        } else {
            Die("Invalid file function \"$type\".");
        }
    } else {
        # The default is a function request. Get the function name.
        my $function = $cgi->param('function') || "";
        Trace("Server function for task $$ is $function.") if T(3);
        # Insure the function name is valid.
        if ($function ne "methods" && exists $serverThing->{methods} && ! $serverThing->{methods}{$function}) {
            SendError("Invalid function name.", "$function not found.")
        } else {
            # Determing the encoding scheme. The default is YAML.
            my $encoding = $cgi->param('encoding') || 'yaml';
            # Optional callback for json encoded documents
            my $callback = $cgi->param('callback');
            # The parameter structure will go in here.
            my $args = {};
            # Start the timer.
            my $start = time();
            # The output document goes in here.
            my $document;
            # Protect from errors.
            eval {
                # Here we parse the arguments. This is affected by the encoding parameter.
                # Get the argument string.
                my $argString = $cgi->param('args');
                # Only proceed if we found one.
                if ($argString) {
                    if ($encoding eq 'yaml') {
                        # Parse the arguments using YAML.
                        $args = YAML::Load($argString);
                    } elsif ($encoding eq 'yaml2') {
                        # Parse the arguments using C-based YAML.
                        $args = YAML::XS::Load($argString);
                    } elsif ($encoding eq 'json') {
                        # Parse the arguments using JSON.
                        Trace("Incoming string is:\n$argString") if T(3);
                        $args = JSON::Any->jsonToObj($argString);
                    } else {
                        Die("Invalid encoding type $encoding.");
                    }
                }
            };
            # Check to make sure we got everything.
            if ($@) {
                SendError($@, "Error formatting parameters.");
            } elsif (! $function) {
                SendError("No function specified.", "No function specified.");
            } else {
                # Insure we're connected to the correct database.
                my $dbName = $cgi->param('dbName');
                if ($dbName && exists $serverThing->{db}) {
                    ChangeDB($serverThing, $dbName);
                }
                # Run the request.
		if ($serverThing->{raw_methods}->{$function})
		{
		    $document = eval { $serverThing->$function($cgi) };
		}
		else
		{
		    $document = eval { $serverThing->$function($args) };
		}
                # If we have an error, create an error document.
                if ($@) {
                    SendError($@, "Error detected by service.");
                    Trace("Error encountered by service: $@") if T(0);
                } else {
                    # No error, so we output the result. Start with an HTML header.
                    if ($encoding eq 'yaml') {
                        print $cgi->header(-type => 'text/plain');
                    } else {
                        print $cgi->header(-type => 'text/javascript');
                    }
                    # The nature of the output depends on the encoding type.
                    eval {
                        my $string;
                        if ($encoding eq 'yaml') {
                            $string = YAML::Dump($document);
                        } elsif ($encoding eq 'yaml2') {
                            $string = YAML::XS::Dump($document);
                        } elsif (defined($callback)) {
                            $string = $callback . "(".JSON::Any->objToJson($document).")";
                        } else {
                            $string = JSON::Any->objToJson($document);
                        }
                        print $string;
                        MemTrace(length($string) . " bytes returned from $function by task $$.") if T(Memory => 3);
                    };
                    if ($@) {
                        SendError($@, "Error encoding result.");
                        Trace("Error encoding result: $@") if T(0);
                    }
                }
            }
            # Stop the timer.
            my $duration = int(time() - $start + 0.5);
            Trace("Function $function executed in $duration seconds by task $$.") if T(2);
        }
    }
}

=head3 CreateFile

    ServerThing::CreateFile();

Create a new, empty temporary file and send its name back to the client.

=cut

sub CreateFile {
    ##TODO: Code
}

=head3 OpenFile

    ServerThing::OpenFile($name);

Send the length of the named file back to the client.

=over 4

=item name

##TODO: name description

=back

=cut

sub OpenFile {
    # Get the parameters.
    my ($name) = @_;
    ##TODO: Code
}

=head3 ReadChunk

    ServerThing::ReadChunk($name, $location, $size);

Read the indicated number of bytes from the specified location of the
named file and send them back to the client.

=over 4

=item name

##TODO: name description

=item location

##TODO: location description

=item size

##TODO: size description

=back

=cut

sub ReadChunk {
    # Get the parameters.
    my ($name, $location, $size) = @_;
    ##TODO: Code
}

=head3 WriteChunk

    ServerThing::WriteChunk($name, $data);

Write the specified data to the named file.

=over 4

=item name

##TODO: name description

=item data

##TODO: data description

=back

=cut

sub WriteChunk {
    # Get the parameters.
    my ($name, $data) = @_;
    ##TODO: Code
}


=head3 LineNumberize

    ServerThing::LineNumberize($module);

Output the module line by line with line numbers

=over 4

=item module

Name of the module to line numberized

=back

=cut

sub LineNumberize {
    # Get the parameters.
    my ($module) = @_;
    my $fks_path = "$FIG_Config::fig_disk/dist/releases/current/FigKernelScripts/$module";
    # Start the output page.
    print CGI::header();
    print CGI::start_html(-title => 'Documentation Page',
                          -style => { src => "http://servers.nmpdr.org/sapling/Html/css/ERDB.css" });
    # Protect from errors.
    eval {
        if (-e $fks_path) {
            print "<pre>\n";
            my $i = 1;
            foreach my $line (`cat $fks_path`) {
                print "$i.\t$line";
                $i++;
            }
            print "</pre>\n";
        } else {
            print "File $fks_path not found";
        }
    };
    # Process any error.
    if ($@) {
        print CGI::blockquote({ class => 'error' }, $@);
    }
    # Close off the page.
    print CGI::end_html();

}

=head3 ProducePod

    ServerThing::ProducePod($module);

Output the POD documentation for the specified module.

=over 4

=item module

Name of the module whose POD document is to be displayed.

=back

=cut

sub ProducePod {
    # Get the parameters.
    my ($module) = @_;
    # Start the output page.
    print CGI::header();
    print CGI::start_html(-title => "$module Documentation Page",
                          -style => { src => "http://servers.nmpdr.org/sapling/Html/css/ERDB.css" });
    # Protect from errors.
    eval {
        # We'll format the HTML text in here.
        require DocUtils;
        my $html = DocUtils::ShowPod($module, "http://pubseed.theseed.org/sapling/server.cgi?pod=");
        # Output the POD HTML.
        print $html;
    };
    # Process any error.
    if ($@) {
        print CGI::blockquote({ class => 'error' }, $@);
    }
    # Close off the page.
    print CGI::end_html();

}

=head3 TraceErrorLog

    ServerThing::TraceErrorLog($name, $errorLog);

Trace the specified error log file. This is a very dinky routine that
performs a task required by L</RunTool> in multiple places.

=over 4

=item name

Name of the tool relevant to the log file.

=item errorLog

Name of the log file.

=back

=cut

sub TraceErrorLog {
    my ($name, $errorLog) = @_;
    my $errorData = Tracer::GetFile($errorLog);
    Trace("$name error log:\n$errorData");
}

=head3 SendError

    ServerThing::SendError($message, $status);

Fail an HTTP request with the specified error message and the specified
status message.

=over 4

=item message

Detailed error message. This is sent as the page content.

=item status

Status message. This is sent as part of the status code.

=back

=cut

sub SendError {
    # Get the parameters.
    my ($message, $status) = @_;
    warn ("SAS Error \"$status\" $message\n");
    # Check for a DBserver error. These can be retried and get a special status
    # code.
    my $realStatus;
    if ($message =~ /DBServer Error:\s+/) {
        $realStatus = "503 $status";
    } else {
        $realStatus = "500 $status";
    }
    # Print the header and the status message.
    print CGI::header(-type => 'text/plain',
                      -status => $realStatus);
    # Print the detailed message.
    print $message;
}


=head3 Log

    Log($msg);

Write a message to the log. This is a temporary hack until we can figure out how to get
normal tracing and error logging working.

=over 4

=item msg

Message to write. It will be appended to the C<servers.log> file in the FIG temporary directory.

=back

=cut

sub Log {
    # Get the parameters.
    my ($msg) = @_;
    # Open the log file for appending.
    open(my $oh, ">>$FIG_Config::temp/servers.log") || Confess("Log error: $!");
    print $oh "$msg\n";
    close $oh;
}

package ServerReturn;

=head1 ServerReturn

ServerReturn is a little class used to encapsulate  responses to be
sent back toclients. It holds an code code (to be pushed into
a HTTP response response), a short message, and long details.

=cut

use strict;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(code msg body));

sub new
{
    my($class, $code, $msg, $body) = @_;
    my $self = {
	code => $code,
	msg => $msg,
	body => $body,
    };
    return bless $self, $class;
}

sub package_response
{
    my($self) = @_;
    return pack("nN/aN/a", @{$self}{qw(code msg body)});
}

1;
