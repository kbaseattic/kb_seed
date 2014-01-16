use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Association

=head1 SYNOPSIS

all_entities_Association [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Association entity.

An Association represents a protein complex or a pairwise
(binary) physical association between proteins.


Example:

    all_entities_Association -a 

would retrieve all entities of type Association and include all fields
in the entities in the output.

=head2 Related entities

The Association entity has the following relationship links:

=over 4
    
=item AssociationFeature Feature

=item AssociationPublishedIn Publication

=item DetectedBy AssociationDetectionType

=item InAssociationDataset AssociationDataset


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Association [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item name

This is the name of the association. 

=item description

This is a description of this association.  If the protein complex has a name, this should be it. 

=item directional

True for directional binary associations (e.g., those detected by a pulldown experiment), false for non-directional binary associations and complexes. Bidirectional associations (e.g., associations detected by reciprocal pulldown experiments) should be encoded as 2 separate binary associations. 

=item confidence

Optional numeric estimate of confidence in the association. Recommended to use a 0-100 scale. 

=item url

Optional URL for more info about this complex.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'name', 'description', 'directional', 'confidence', 'url' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Association [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    name
        This is the name of the association. 
    description
        This is a description of this association.  If the protein complex has a name, this should be it. 
    directional
        True for directional binary associations (e.g., those detected by a pulldown experiment), false for non-directional binary associations and complexes. Bidirectional associations (e.g., associations detected by reciprocal pulldown experiments) should be encoded as 2 separate binary associations. 
    confidence
        Optional numeric estimate of confidence in the association. Recommended to use a 0-100 scale. 
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
	print STDERR "all_entities_Association: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Association($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Association($start, $count, \@fields);
}
