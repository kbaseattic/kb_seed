package Bio::KBase::AskKB::AskKBImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

AskKB

=head1 DESCRIPTION



=cut

#BEGIN_HEADER
use Bio::KBase::InvocationService::Client;
use YAML::XS qw(LoadFile DumpFile);
use Cmd2HTML;
use Data::Dumper;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

     my($ask_storage_dir) = @args;

     if (! -d $ask_storage_dir) {
         die "Storage directory $ask_storage_dir does not exist";
     }
     $self->{ask_storage_dir} = $ask_storage_dir;
     $self->{count} = 0;
    my $service_url = 'http://ash.mcs.anl.gov:5050';
    my $invoc = Bio::KBase::InvocationService::Client->new($service_url);
    if (! $invoc) { print STDERR Service fail; exit }
     $self->{invoc} = $invoc;

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 askKB

  $return_1, $return_2 = $obj->askKB($session_id, $cwd, $query, $guid)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a session_id
$cwd is a cwd
$query is a query
$guid is a string
$return_1 is a type
$return_2 is an answer
session_id is a string
cwd is a string
query is a string
type is a string
answer is a reference to a hash where the following keys are defined:
	header has a value which is a head
	data has a value which is a rows
	fasta has a value which is a string
	error has a value which is a string
head is a reference to a list where each element is a string
rows is a reference to a list where each element is a row
row is a reference to a list where each element is a string

</pre>

=end html

=begin text

$session_id is a session_id
$cwd is a cwd
$query is a query
$guid is a string
$return_1 is a type
$return_2 is an answer
session_id is a string
cwd is a string
query is a string
type is a string
answer is a reference to a hash where the following keys are defined:
	header has a value which is a head
	data has a value which is a rows
	fasta has a value which is a string
	error has a value which is a string
head is a reference to a list where each element is a string
rows is a reference to a list where each element is a row
row is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub askKB
{
    my $self = shift;
    my($session_id, $cwd, $query, $guid) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($query)) or push(@_bad_arguments, "Invalid type for argument \"query\" (value was \"$query\")");
    (!ref($guid)) or push(@_bad_arguments, "Invalid type for argument \"guid\" (value was \"$guid\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to askKB:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'askKB');
    }

    my $ctx = $Bio::KBase::AskKB::Service::CallContext;
    my($return_1, $return_2);
    #BEGIN askKB
    #$return_1 = "table";
    #$return_2->{header} = ["col1","col2"];
    #$return_2->{data} = [["val1","val2"],["val3","val4"]];
    #return($return_1, $return_2);
    my $ask_storage = $self->{ask_storage_dir};
    my $invoc = $self->{invoc};
    my $helpD = "$ask_storage/Help";
    my $userD = "$ask_storage/User/$session_id";
    my $prolog = "/home/overbeek/Ross/Prolog-KB/Grammar/kb_dcg"; 
    my $aliases;

    #if (! -d $userD) {
        #mkdir($userD);
        #$aliases = {};
    #} else {
        #$aliases = LoadFile("$userD/aliases");
#
    #}
    my $state = { invoc => $invoc, session => $session_id, cwd => $cwd,  helpD => $helpD, aliases => $aliases, userD => $userD, prolog => $prolog };


    my $ret = &Cmd2HTML::process_string($query, $state);
    #print STDERR "RET\n";
    #print STDERR Dumper $ret;
    $return_1 = $ret->[0];
    $return_2 = $ret->[1];
    #print STDERR " RETURN1$return_1\n";;
    #print STDERR Dumper $return_1;
    #print STDERR Dumper $return_2;

    
    DumpFile("$userD/last", $ret);
    DumpFile("$userD/$guid", $ret);
    #DumpFile("$userD/aliases", $aliases);
    #return $html;
    #END askKB
    my @_bad_returns;
    (!ref($return_1)) or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (ref($return_2) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return_2\" (value was \"$return_2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to askKB:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'askKB');
    }
    return($return_1, $return_2);
}




=head2 save

  $obj->save($session_id, $cwd, $filename, $guid)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a session_id
$cwd is a cwd
$filename is a string
$guid is a string
session_id is a string
cwd is a string

</pre>

=end html

=begin text

$session_id is a session_id
$cwd is a cwd
$filename is a string
$guid is a string
session_id is a string
cwd is a string


=end text



=item Description



=back

=cut

sub save
{
    my $self = shift;
    my($session_id, $cwd, $filename, $guid) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($guid)) or push(@_bad_arguments, "Invalid type for argument \"guid\" (value was \"$guid\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to save:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'save');
    }

    my $ctx = $Bio::KBase::AskKB::Service::CallContext;
    #BEGIN save
    my $ask_storage = $self->{ask_storage_dir};
    my $invoc = $self->{invoc};
    my $userD = "$ask_storage/User/$session_id";
    #print STDERR "SAVE!!! $ask_storage, $cwd, $filename, $guid, $userD\n";
    my $ret = LoadFile("$userD/$guid");
    #print STDERR "SAVE ", Dumper $ret;
    my $type = $ret->[0];
    my $retH = $ret->[1];
    my $file;
    if ($type eq 'table') {
            my $data = $retH->{data};
            foreach my $line (@$data) {
                    $file .= join("\t", @$line);
                    $file .= "\n";
            }
        print STDERR "PUT!!! $session_id, \n$file\n$filename, $cwd\n\n";
        $invoc->put_file($session_id, $filename, $file, $cwd);
    }
    if ($type eq 'Fasta File') {
            my $data = $retH->{data};
            $file = join("\n", $data);
            $invoc->put_file($session_id, $filename, $file, $cwd);
    }
    if ($type eq 'html') {
            my $data = $retH->{data};
            $invoc->put_file($session_id, $filename, $data, $cwd);
    }

            

    


    #END save
    return();
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 head

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 row

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 rows

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a row
</pre>

=end html

=begin text

a reference to a list where each element is a row

=end text

=back



=head2 answer

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
header has a value which is a head
data has a value which is a rows
fasta has a value which is a string
error has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
header has a value which is a head
data has a value which is a rows
fasta has a value which is a string
error has a value which is a string


=end text

=back



=head2 query

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 session_id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 cwd

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 type

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=cut

1;
