use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Interaction

=head1 SYNOPSIS

all_entities_Interaction [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Interaction entity.

An Interaction represents a protein complex or a pairwise
(binary) physical interaction between proteins.


Example:

    all_entities_Interaction -a 

would retrieve all entities of type Interaction and include all fields
in the entities in the output.

=head2 Related entities

The Interaction entity has the following relationship links:

=over 4
    
=item DetectedBy InteractionDetectionType

=item InInteractionDataset InteractionDataset

=item InteractionFeature Feature

=item InteractionProtein ProteinSequence

=item InteractionPublishedIn Publication


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Interaction [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item description

This is a description of this interaction.  If the protein complex has a name, this should be it. 

=item directional

True for directional binary interactions (e.g., those detected by a pulldown experiment), false for non-directional binary interactions and complexes. Bidirectional interactions (e.g., interactions detected by reciprocal pulldown experiments) should be encoded as 2 separate binary interactions. 

=item confidence

Optional numeric estimate of confidence in the interaction. Recommended to use a 0-100 scale. 

=item url

Optional URL for more info about this complex.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'description', 'directional', 'confidence', 'url' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Interaction [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    description
        This is a description of this interaction.  If the protein complex has a name, this should be it. 
    directional
        True for directional binary interactions (e.g., those detected by a pulldown experiment), false for non-directional binary interactions and complexes. Bidirectional interactions (e.g., interactions detected by reciprocal pulldown experiments) should be encoded as 2 separate binary interactions. 
    confidence
        Optional numeric estimate of confidence in the interaction. Recommended to use a 0-100 scale. 
    url
        Optional URL for more info about this complex.
END


my $a;
my $f;
my @fields;
my $show_fields;
my $help;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script("a" 		=> \$a,
								  "show-fields" => \$show_fields,
								  "h" 		=> \$help,
								  "fields=s"    => \$f);

if ($help)
{
    print $usage;
    exit 0;
}

if ($show_fields)
{
    print "Available fields:\n";
    print "\t$_\n" foreach @all_fields;
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
	print STDERR "all_entities_Interaction: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Interaction($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Interaction($start, $count, \@fields);
}
