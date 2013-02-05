use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_CoregulatedSet

=head1 SYNOPSIS

all_entities_CoregulatedSet [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the CoregulatedSet entity.

We need to represent sets of genes that are coregulated via
some regulatory mechanism.  In particular, we wish to represent
genes that are coregulated using transcription binding sites and
corresponding transcription regulatory proteins. We represent a
coregulated set (which may, or may not, be considered a regulon)
using CoregulatedSet.

Example:

    all_entities_CoregulatedSet -a 

would retrieve all entities of type CoregulatedSet and include all fields
in the entities in the output.

=head2 Related entities

The CoregulatedSet entity has the following relationship links:

=over 4
    
=item IsControlledUsing Feature

=item IsRegulatedSetOf Feature

=item WasFormulatedBy Source


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_CoregulatedSet [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item source_id

original ID of this coregulated set in the source (core) database

=item binding_location

binding location for this set's transcription factor; there may be none of these or there may be more than one


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'source_id', 'binding_location' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_CoregulatedSet [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    source_id
        original ID of this coregulated set in the source (core) database
    binding_location
        binding location for this set's transcription factor; there may be none of these or there may be more than one
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
	print STDERR "all_entities_CoregulatedSet: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_CoregulatedSet($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_CoregulatedSet($start, $count, \@fields);
}
