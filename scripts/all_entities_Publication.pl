use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 all_entities_Publication

Return all instances of the Publication entity.

Experimenters attach publications to experiments and
protocols. Annotators attach publications to ProteinSequences.
The attached publications give an ID (usually a
DOI or Pubmed ID),  a URL to the paper (when we have it), and a title
(when we have it). Pubmed IDs are given unmodified. DOI IDs
are prefixed with [b]doi:[/b], e.g. [i]doi:1002385[/i].

Example:

    all_entities_Publication -a 

would retrieve all entities of type Publication and include all fields
in the entities in the output.

=head2 Related entities

The Publication entity has the following relationship links:

=over 4
    
=item Concerns ProteinSequence

=item PublishedExperiment PhenotypeExperiment

=item PublishedProtocol Protocol


=back


=head2 Command-Line Options

=over 4

=item -a

Return all fields.

=item -h

Display a list of the fields available for use.

=item -fields field-list

Choose a set of fields to return. Field-list is a comma-separated list of 
strings. The following fields are available:

=over 4

=item title

=item link

=item pubdate

=back    
   
=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added for each requested field.  Input lines that cannot
be extended are written to stderr.  

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'title', 'link', 'pubdate' );
my %all_fields = map { $_ => 1 } @all_fields;

my $usage = "usage: all_entities_Publication [-show-fields] [-a | -f field list] > entity.data";

my $a;
my $f;
my @fields;
my $show_fields;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script("a" 		=> \$a,
								  "show-fields" => \$show_fields,
								  "h" 		=> \$show_fields,
								  "fields=s"    => \$f);

if ($show_fields)
{
    print STDERR "Available fields: @all_fields\n";
    exit 0;
}

if (@ARGV != 0 || ($a && $f))
{
    print STDERR $usage, "\n";
    exit 1;
}

if ($a)
{
    @fields = @all_fields;
}
elsif ($f) {
    my @err;
    for my $field (split(",", $f))
    {
	if (!$all_fields{$field})
	{
	    push(@err, $field);
	}
	else
	{
	    push(@fields, $field);
	}
    }
    if (@err)
    {
	print STDERR "all_entities_Publication: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Publication($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Publication($start, $count, \@fields);
}
