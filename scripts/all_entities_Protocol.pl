use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Protocol

=head1 SYNOPSIS

all_entities_Protocol [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Protocol entity.

A Protocol is a step by step set of instructions for
performing a part of an experiment.

Example:

    all_entities_Protocol -a 

would retrieve all entities of type Protocol and include all fields
in the entities in the output.

=head2 Related entities

The Protocol entity has the following relationship links:

=over 4
    
=item IsMeasurementMethodOf Measurement

=item ProtocolForSample Sample

=item ProtocolPublishedIn Publication


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Protocol [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item name

The name of the protocol.

=item description

The step by step instructions for performing the experiment, including measurement details, materials, and equipment. A researcher should be able to reproduce the experimental results with this information.

=item source_id

The ID of the protocol used by the data source.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'name', 'description', 'source_id' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Protocol [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    name
        The name of the protocol.
    description
        The step by step instructions for performing the experiment, including measurement details, materials, and equipment. A researcher should be able to reproduce the experimental results with this information.
    source_id
        The ID of the protocol used by the data source.
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
	print STDERR "all_entities_Protocol: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Protocol($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Protocol($start, $count, \@fields);
}
