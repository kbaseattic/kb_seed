package DeferredExecutor;
use Moose;

=head1 DeferredExecutor

Class that will execute a shell command in the background and then
invoke the given piece of code with the output of the command.

=cut
