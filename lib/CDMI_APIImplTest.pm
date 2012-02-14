package CDMI_APIImpl;

=head1 NAME

CDMI_APIImpl

=head1 DESCRIPTION

The CDMI_API defines the component of the Kbase API that supports interaction with
instances of the CDM (Central Data Model).  A basic familiarity with these routines
will allow the user to extract data from the CS (Central Store).  We anticipate
supporting numerous sparse CDMIs in the PS (Persistent Store).

Basic Themes:

There are several broad categories of routines supported in the CDMI-API.

The simplest is set of "get entity" routines -- each returning data
extracted from instances of a single entity type.  These routines all take
as input a list of ids referencing instances of a single type of entity.
They construct as output a mapping which takes as input an id and
associates as output a set of fields from that instance of the entity.  Each
routine allows the user to specify which fields are desired.

        NEEDS EXAMPLE

To use these routines effectively, a user will need to gradually
become familiar with the entities supported in the CDM.  We suggest
perusing the entity-relationship model that underlies the CDM to
get a good introduction.

The next simplest set of routines provide the "get relationship" routines.  These
take as input a list of ids for a specific entity type, and the give access
to the relationship nodes associated with each entity.  Thus,

        NEEDS EXAMPLE

Of the remaining CDMI-API routines, most are used to extract data by
"crossing one or more relationships".  Thus,

        my $references = $kbO->fids_to_literature($fids)

takes as input a list of feature ids referenced by the variable $fids.  It
creates a hash ($references) which maps each input key to a list of literature
references.  The construction of the literature references for a given ID involves
crossing relationships from the entity 'Feature' to 'ProteinSequence' to 'Publication'.
We have attempted to package this specific search in a convenient form.  We anticipate
that the number of queries of this last class will grow (especially as new entities are
added to the model).

Batching queries:

A majority of the CS-API routines take a list of ids as input.  Each id may be thought
of as input to a query that produces an output result.  We support processing an input list,
since the performance (which is usually governed by network interactions) is much better
if you process a batch of items, rather than invoking the API repeatedly for each of the
ids.  Normally, the output would be a mapping (a hash for Perl versions) from the
input ids to the output results.  Thus, a routine like 'fids_to_literature'
 will take a list of feature ids as input.  The returned value will be a mapping from
 feature ids (fids) to publication references.
 It is a little inconvenient to batch your requests by supplying a list of fids,
 but the performance will be much better in most cases.  Please note that you are
 controlling the granularity of each request, and in most cases the size of the input
 list is not critical.  However, you should note that while batching up hundreds or thousands
 of input ids at a time should work just fine, millions may well cause things to break (e.g.,
 you may exhaust local memory in your machine as the output results are returned).  As
 machines get larger, the appropriate size of the input lists may become largely irrelevant.
 For now, we recommend that you experiment a bit and use common sense.

=cut

sub new
{
    my($class) = @_;
    my $self = {
    };
    return bless $self, $class;
}

=head1 METHODS

=head2 contigs_to_lengths

    $return = $obj->contigs_to_lengths($contigs)

=over 4

=item Parameter and return types

=begin html

<pre>
$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a length
contigs is a reference to a list where each element is a contig
contig is a string
length is an int
</pre>

=end html

=begin text

$contigs is a contigs
$return is a reference to a hash where the key is a contig and the value is a length
contigs is a reference to a list where each element is a contig
contig is a string
length is an int

=end text

=item Description

In some cases, one wishes to know just the lengths of the contigs, rather than their
actual DNA sequence (e.g., suppose that you wished to know if a gene boundary occured within
100 bp of the end of the contig).  To avoid requiring a user to access the entire DNA sequence,
we offer the ability to retrieve just the contig lengths.  Input to the routine is a list of contig IDs.
The routine returns a mapping from contig IDs to lengths

=back

=cut

sub contigs_to_lengths
{
    my($self, $ctx, $contigs) = @_;
    my($return);
    #BEGIN contigs_to_lengths
        #END contigs_to_lengths
    return($return);
}


=head2 annotation

=over 4

=item DESCRIPTION

The Kbase stores annotations relating to features.  Each annotation
is a 3-tuple:

     the text of the annotation (often a record of assertion of function)

     the annotator attaching the annotation to the feature

     the time (in seconds from the epoch) at which the annotation was attached


=item DEFINITION

=begin html

<pre>
a reference to a list containing 3 items:
0: a comment
1: an annotator
2: an annotation_time

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a comment
1: an annotator
2: an annotation_time


=end text

=back

=cut

1;
