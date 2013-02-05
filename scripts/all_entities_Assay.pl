use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Assay

=head1 SYNOPSIS

all_entities_Assay [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Assay entity.

An assay is an experimental design for determining alleles at specific chromosome positions.

Example:

    all_entities_Assay -a 

would retrieve all entities of type Assay and include all fields
in the entities in the output.

=head2 Related entities

The Assay entity has the following relationship links:

=over 4
    
=item IsAssayOf StudyExperiment


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Assay [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item source_id

identifier for this assay in the original (source) database

=item assay_type

Text description of the type of assay (e.g., SNP, length, sequence, categorical, array, short read, SSR marker, AFLP marker)

=item assay_type_id

source ID associated with the assay type (informational)


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'source_id', 'assay_type', 'assay_type_id' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Assay [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    source_id
        identifier for this assay in the original (source) database
    assay_type
        Text description of the type of assay (e.g., SNP, length, sequence, categorical, array, short read, SSR marker, AFLP marker)
    assay_type_id
        source ID associated with the assay type (informational)
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
	print STDERR "all_entities_Assay: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Assay($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Assay($start, $count, \@fields);
}
