use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Subsystem

=head1 SYNOPSIS

all_entities_Subsystem [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Subsystem entity.

A subsystem is a set of functional roles that have been annotated simultaneously (e.g.,
the roles present in a specific pathway), with an associated subsystem spreadsheet
which encodes the fids in each genome that implement the functional roles in the
subsystem.

Example:

    all_entities_Subsystem -a 

would retrieve all entities of type Subsystem and include all fields
in the entities in the output.

=head2 Related entities

The Subsystem entity has the following relationship links:

=over 4
    
=item Describes Variant

=item Includes Role

=item IsInClass SubsystemClass

=item IsRelevantTo Diagram

=item IsSubInstanceOf Scenario

=item WasProvidedBy Source


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Subsystem [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item version

version number for the subsystem. This value is incremented each time the subsystem is backed up.

=item curator

name of the person currently in charge of the subsystem

=item notes

descriptive notes about the subsystem

=item description

description of the subsystem's function in the cell

=item usable

TRUE if this is a usable subsystem, else FALSE. An unusable subsystem is one that is experimental or is of such low quality that it can negatively affect analysis.

=item private

TRUE if this is a private subsystem, else FALSE. A private subsystem has valid data, but is not considered ready for general distribution.

=item cluster_based

TRUE if this is a clustering-based subsystem, else FALSE. A clustering-based subsystem is one in which there is functional-coupling evidence that genes belong together, but we do not yet know what they do.

=item experimental

TRUE if this is an experimental subsystem, else FALSE. An experimental subsystem is designed for investigation and is not yet ready to be used in comparative analysis and annotation.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'version', 'curator', 'notes', 'description', 'usable', 'private', 'cluster_based', 'experimental' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Subsystem [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    version
        version number for the subsystem. This value is incremented each time the subsystem is backed up.
    curator
        name of the person currently in charge of the subsystem
    notes
        descriptive notes about the subsystem
    description
        description of the subsystem's function in the cell
    usable
        TRUE if this is a usable subsystem, else FALSE. An unusable subsystem is one that is experimental or is of such low quality that it can negatively affect analysis.
    private
        TRUE if this is a private subsystem, else FALSE. A private subsystem has valid data, but is not considered ready for general distribution.
    cluster_based
        TRUE if this is a clustering-based subsystem, else FALSE. A clustering-based subsystem is one in which there is functional-coupling evidence that genes belong together, but we do not yet know what they do.
    experimental
        TRUE if this is an experimental subsystem, else FALSE. An experimental subsystem is designed for investigation and is not yet ready to be used in comparative analysis and annotation.
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
	print STDERR "all_entities_Subsystem: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Subsystem($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Subsystem($start, $count, \@fields);
}
