use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Variant

=head1 SYNOPSIS

all_entities_Variant [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Variant entity.

Each subsystem may include the designation of distinct
variants.  Thus, there may be three closely-related, but
distinguishable forms of histidine degradation.  Each form
would be called a "variant", with an associated code, and all
genomes implementing a specific variant can easily be accessed. The ID
is an MD5 of the subsystem name followed by the variant code.

Example:

    all_entities_Variant -a 

would retrieve all entities of type Variant and include all fields
in the entities in the output.

=head2 Related entities

The Variant entity has the following relationship links:

=over 4
    
=item IsDescribedBy Subsystem

=item IsImplementedBy SSRow


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Variant [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item role_rule

a space-delimited list of role IDs, in alphabetical order, that represents a possible list of non-auxiliary roles applicable to this variant. The roles are identified by their abbreviations. A variant may have multiple role rules.

=item code

the variant code all by itself

=item type

variant type indicating the quality of the subsystem support. A type of "vacant" means that the subsystem does not appear to be implemented by the variant. A type of "incomplete" means that the subsystem appears to be missing many reactions. In all other cases, the type is "normal".

=item comment

commentary text about the variant


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'role_rule', 'code', 'type', 'comment' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Variant [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    role_rule
        a space-delimited list of role IDs, in alphabetical order, that represents a possible list of non-auxiliary roles applicable to this variant. The roles are identified by their abbreviations. A variant may have multiple role rules.
    code
        the variant code all by itself
    type
        variant type indicating the quality of the subsystem support. A type of "vacant" means that the subsystem does not appear to be implemented by the variant. A type of "incomplete" means that the subsystem appears to be missing many reactions. In all other cases, the type is "normal".
    comment
        commentary text about the variant
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
	print STDERR "all_entities_Variant: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Variant($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Variant($start, $count, \@fields);
}
