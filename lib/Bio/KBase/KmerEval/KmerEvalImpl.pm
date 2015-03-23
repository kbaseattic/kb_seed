package Bio::KBase::KmerEval::KmerEvalImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

KmerEval

=head1 DESCRIPTION



=cut

#BEGIN_HEADER
use Kmers2013;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



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
    my $self = shift;
    my($seq_set) = @_;

    my @_bad_arguments;
    (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"seq_set\" (value was \"$seq_set\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_dna_with_kmers:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_dna_with_kmers');
    }

    my $ctx = $Bio::KBase::KmerEval::Service::CallContext;
    my($return);
    #BEGIN call_dna_with_kmers


    $return = Kmers2013::call_dna_with_kmers($seq_set);

    #END call_dna_with_kmers
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_dna_with_kmers:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_dna_with_kmers');
    }
    return($return);
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
    my $self = shift;
    my($seq_set) = @_;

    my @_bad_arguments;
    (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"seq_set\" (value was \"$seq_set\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to call_prot_with_kmers:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_prot_with_kmers');
    }

    my $ctx = $Bio::KBase::KmerEval::Service::CallContext;
    my($return);
    #BEGIN call_prot_with_kmers
    $return = Kmers2013::call_aa_with_kmers($seq_set);
    #END call_prot_with_kmers
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to call_prot_with_kmers:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'call_prot_with_kmers');
    }
    return($return);
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
    my $self = shift;
    my($seq_set) = @_;

    my @_bad_arguments;
    (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"seq_set\" (value was \"$seq_set\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to check_contig_set:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'check_contig_set');
    }

    my $ctx = $Bio::KBase::KmerEval::Service::CallContext;
    my($return);
    #BEGIN check_contig_set

    $return = Kmers2013::check_contig_set($seq_set);
        


    #END check_contig_set
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to check_contig_set:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'check_contig_set');
    }
    return($return);
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

1;
