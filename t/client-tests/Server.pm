# Helper packages Server. I just put this package in the actual
# perl test code, but of course having it be a separate perl
# module could be considered better design practice. Whatever
# you decide.
#
# Note current implemetation assumes the test gets run from the
# top level directory within the module. This manifests
# in the hardcoded path to lib where the psgi file is deployed.
package Server;
use Plack::Runner;
use IO::Socket::INET;

sub start {
  my $service = shift;

  # Find an unused port.
  my $port;
  {
     my $sock = IO::Socket::INET->new('LocalPort' => 0);
     $sock->listen;
     $port = $sock->sockport;
     $sock->close();
  }

  # Fork and create service.
  my $child_pid = fork;
  if ($child_pid == 0)
  {
     die "could not find ./lib/$service.psgi" unless -e "lib/$service.psgi";
     open STDOUT, "/dev/null";
     open STDERR, "/dev/null";
     my $runner = Plack::Runner->new();
     $runner->parse_options("--listen", "0:$port");
     $runner->run("lib/$service.psgi");
     exit;
  }

  # Wait for server to start.
  sleep 15;
  return ($child_pid, "http://localhost:$port");
}

sub stop {
  my($child_pid, $url) = shift;
  kill 1, $child_pid;
}

1;
