package Bio::KBase::KmerEval::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

our %have_impl;
eval {
    require Bio::KBase::KmerEval::KmerEvalImpl;
    $have_impl{'KmerEval'} = 1;
};
if ($@)
{
    warn "Error loading impl: $@\n";
}


# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::KBase::KmerEval::Client

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;

    my $local_impl = {};
    if ($url eq 'local' || $ENV{KB_CLIENT_LOCAL} || $ENV{'KB_CLIENT_LOCAL_KmerEval'})
    {
	$have_impl{'KmerEval'} or die "Error: Local implementation requested for service, but the implementation module did not load properly\n";
	my $impl = Bio::KBase::KmerEval::KmerEvalImpl->new();
	$local_impl->{'KmerEval'} = $impl;
    }
    if (!defined($url))
    {
	$url = 'http://ash.mcs.anl.gov:5060/services/kmer_eval';
    }

    my $self = {
	client => Bio::KBase::KmerEval::Client::RpcClient->new,
	url => $url,
	local_impl => $local_impl,
    };


    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 call_dna_with_kmers

  $return = $obj->call_dna_with_kmers($seq_set)

=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$return is a reference to a hash where the key is a contig and the value is a contig_data
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
contig is a string
contig_data is a reference to a list containing 3 items:
	0: a length
	1: a frames
	2: an otu_data
length is an int
frames is a reference to a list where each element is a frame
frame is a reference to a list containing 3 items:
	0: a strand
	1: (offset_of_frame) an int
	2: a calls
strand is an int
calls is a reference to a list where each element is a call
call is a reference to a list containing 4 items:
	0: (start_of_first_hit) an int
	1: (end_of_last_hit) an int
	2: (number_hits) an int
	3: a function
function is a string
otu_data is a reference to a list where each element is an otu_set_counts
otu_set_counts is a reference to a list containing 2 items:
	0: (count) an int
	1: an otu_set
otu_set is a reference to a list where each element is a genus_species
genus_species is a reference to a list containing 2 items:
	0: (genus) a string
	1: (species) a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$return is a reference to a hash where the key is a contig and the value is a contig_data
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
contig is a string
contig_data is a reference to a list containing 3 items:
	0: a length
	1: a frames
	2: an otu_data
length is an int
frames is a reference to a list where each element is a frame
frame is a reference to a list containing 3 items:
	0: a strand
	1: (offset_of_frame) an int
	2: a calls
strand is an int
calls is a reference to a list where each element is a call
call is a reference to a list containing 4 items:
	0: (start_of_first_hit) an int
	1: (end_of_last_hit) an int
	2: (number_hits) an int
	3: a function
function is a string
otu_data is a reference to a list where each element is an otu_set_counts
otu_set_counts is a reference to a list containing 2 items:
	0: (count) an int
	1: an otu_set
otu_set is a reference to a list where each element is a genus_species
genus_species is a reference to a list containing 2 items:
	0: (genus) a string
	1: (species) a string


=end text

=item Description



=back

=cut

sub call_dna_with_kmers
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function call_dna_with_kmers (received $n, expecting 1)");
    }
    {
	my($seq_set) = @args;

	my @_bad_arguments;
        (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"seq_set\" (value was \"$seq_set\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to call_dna_with_kmers:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'call_dna_with_kmers');
	}
    }

    #
    # See if we have a local implementation objct for this call.
    #
    if (ref(my $impl = $self->{local_impl}->{'KmerEval'}))
    {
	my @result = $impl->call_dna_with_kmers(@args);
	
	return wantarray ? @result : $result[0];
    }
    else
    {
	my $result = $self->{client}->call($self->{url}, {
	    method => "KmerEval.call_dna_with_kmers",
	    params => \@args,
	});

	if ($result) {
	    if ($result->is_error) {
		Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
						       code => $result->content->{code},
						       method_name => 'call_dna_with_kmers',
						      );
	    } else {
    		return wantarray ? @{$result->result} : $result->result->[0];
	   }
	} else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method call_dna_with_kmers",
					    status_line => $self->{client}->status_line,
					    method_name => 'call_dna_with_kmers',
				       );
        }
    }
}



=head2 call_prot_with_kmers

  $return = $obj->call_prot_with_kmers($seq_set)

=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$return is a reference to a hash where the key is an id and the value is a reference to a list containing 2 items:
	0: a calls
	1: an otu_data
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
calls is a reference to a list where each element is a call
call is a reference to a list containing 4 items:
	0: (start_of_first_hit) an int
	1: (end_of_last_hit) an int
	2: (number_hits) an int
	3: a function
function is a string
otu_data is a reference to a list where each element is an otu_set_counts
otu_set_counts is a reference to a list containing 2 items:
	0: (count) an int
	1: an otu_set
otu_set is a reference to a list where each element is a genus_species
genus_species is a reference to a list containing 2 items:
	0: (genus) a string
	1: (species) a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$return is a reference to a hash where the key is an id and the value is a reference to a list containing 2 items:
	0: a calls
	1: an otu_data
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
calls is a reference to a list where each element is a call
call is a reference to a list containing 4 items:
	0: (start_of_first_hit) an int
	1: (end_of_last_hit) an int
	2: (number_hits) an int
	3: a function
function is a string
otu_data is a reference to a list where each element is an otu_set_counts
otu_set_counts is a reference to a list containing 2 items:
	0: (count) an int
	1: an otu_set
otu_set is a reference to a list where each element is a genus_species
genus_species is a reference to a list containing 2 items:
	0: (genus) a string
	1: (species) a string


=end text

=item Description



=back

=cut

sub call_prot_with_kmers
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function call_prot_with_kmers (received $n, expecting 1)");
    }
    {
	my($seq_set) = @args;

	my @_bad_arguments;
        (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"seq_set\" (value was \"$seq_set\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to call_prot_with_kmers:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'call_prot_with_kmers');
	}
    }

    #
    # See if we have a local implementation objct for this call.
    #
    if (ref(my $impl = $self->{local_impl}->{'KmerEval'}))
    {
	my @result = $impl->call_prot_with_kmers(@args);
	
	return wantarray ? @result : $result[0];
    }
    else
    {
	my $result = $self->{client}->call($self->{url}, {
	    method => "KmerEval.call_prot_with_kmers",
	    params => \@args,
	});

	if ($result) {
	    if ($result->is_error) {
		Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
						       code => $result->content->{code},
						       method_name => 'call_prot_with_kmers',
						      );
	    } else {
    		return wantarray ? @{$result->result} : $result->result->[0];
	   }
	} else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method call_prot_with_kmers",
					    status_line => $self->{client}->status_line,
					    method_name => 'call_prot_with_kmers',
				       );
        }
    }
}



=head2 check_contig_set

  $return = $obj->check_contig_set($seq_set)

=over 4

=item Parameter and return types

=begin html

<pre>
$seq_set is a seq_set
$return is a reference to a list containing 4 items:
	0: (estimate) an int
	1: a comment
	2: (placed) a genome_tuples
	3: (unplaced) a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
genome_tuples is a reference to a list where each element is a genome_tuple
genome_tuple is a reference to a list containing 4 items:
	0: a genus_species
	1: (genetic_code) an int
	2: (estimated_taxonomy) a string
	3: a seq_set
genus_species is a reference to a list containing 2 items:
	0: (genus) a string
	1: (species) a string

</pre>

=end html

=begin text

$seq_set is a seq_set
$return is a reference to a list containing 4 items:
	0: (estimate) an int
	1: a comment
	2: (placed) a genome_tuples
	3: (unplaced) a seq_set
seq_set is a reference to a list where each element is a seq_triple
seq_triple is a reference to a list containing 3 items:
	0: an id
	1: a comment
	2: a sequence
id is a string
comment is a string
sequence is a string
genome_tuples is a reference to a list where each element is a genome_tuple
genome_tuple is a reference to a list containing 4 items:
	0: a genus_species
	1: (genetic_code) an int
	2: (estimated_taxonomy) a string
	3: a seq_set
genus_species is a reference to a list containing 2 items:
	0: (genus) a string
	1: (species) a string


=end text

=item Description



=back

=cut

sub check_contig_set
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function check_contig_set (received $n, expecting 1)");
    }
    {
	my($seq_set) = @args;

	my @_bad_arguments;
        (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"seq_set\" (value was \"$seq_set\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to check_contig_set:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'check_contig_set');
	}
    }

    #
    # See if we have a local implementation objct for this call.
    #
    if (ref(my $impl = $self->{local_impl}->{'KmerEval'}))
    {
	my @result = $impl->check_contig_set(@args);
	
	return wantarray ? @result : $result[0];
    }
    else
    {
	my $result = $self->{client}->call($self->{url}, {
	    method => "KmerEval.check_contig_set",
	    params => \@args,
	});

	if ($result) {
	    if ($result->is_error) {
		Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
						       code => $result->content->{code},
						       method_name => 'check_contig_set',
						      );
	    } else {
    		return wantarray ? @{$result->result} : $result->result->[0];
	   }
	} else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method check_contig_set",
					    status_line => $self->{client}->status_line,
					    method_name => 'check_contig_set',
				       );
        }
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "KmerEval.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'check_contig_set',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method check_contig_set",
            status_line => $self->{client}->status_line,
            method_name => 'check_contig_set',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::KBase::KmerEval::Client\n";
    }
    if ($sMajor == 0) {
        warn "Bio::KBase::KmerEval::Client version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 comment

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



=head2 sequence

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



=head2 id

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



=head2 function

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



=head2 strand

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



=head2 contig

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



=head2 strand

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 length

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 seq_triple

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: an id
1: a comment
2: a sequence

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: an id
1: a comment
2: a sequence


=end text

=back



=head2 seq_set

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a seq_triple
</pre>

=end html

=begin text

a reference to a list where each element is a seq_triple

=end text

=back



=head2 genus_species

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: (genus) a string
1: (species) a string

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: (genus) a string
1: (species) a string


=end text

=back



=head2 genome_tuple

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: a genus_species
1: (genetic_code) an int
2: (estimated_taxonomy) a string
3: a seq_set

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: a genus_species
1: (genetic_code) an int
2: (estimated_taxonomy) a string
3: a seq_set


=end text

=back



=head2 genome_tuples

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a genome_tuple
</pre>

=end html

=begin text

a reference to a list where each element is a genome_tuple

=end text

=back



=head2 otu_set

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a genus_species
</pre>

=end html

=begin text

a reference to a list where each element is a genus_species

=end text

=back



=head2 otu_set_counts

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: (count) an int
1: an otu_set

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: (count) an int
1: an otu_set


=end text

=back



=head2 otu_data

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an otu_set_counts
</pre>

=end html

=begin text

a reference to a list where each element is an otu_set_counts

=end text

=back



=head2 call

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: (start_of_first_hit) an int
1: (end_of_last_hit) an int
2: (number_hits) an int
3: a function

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: (start_of_first_hit) an int
1: (end_of_last_hit) an int
2: (number_hits) an int
3: a function


=end text

=back



=head2 calls

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a call
</pre>

=end html

=begin text

a reference to a list where each element is a call

=end text

=back



=head2 frame

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a strand
1: (offset_of_frame) an int
2: a calls

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a strand
1: (offset_of_frame) an int
2: a calls


=end text

=back



=head2 frames

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a frame
</pre>

=end html

=begin text

a reference to a list where each element is a frame

=end text

=back



=head2 contig_data

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a length
1: a frames
2: an otu_data

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a length
1: a frames
2: an otu_data


=end text

=back



=cut

package Bio::KBase::KmerEval::Client::RpcClient;
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


sub _post {
    my ($self, $uri, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        $obj->{id} = $self->id if (defined $self->id);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
