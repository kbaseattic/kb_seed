use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Biomass

=head1 SYNOPSIS

all_entities_Biomass [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Biomass entity.

A biomass is a collection of compounds in a specific
ratio and in specific compartments that are necessary for a
cell to function properly. The prediction of biomasses is key
to the functioning of the model. Each biomass belongs to
a specific model.

Example:

    all_entities_Biomass -a 

would retrieve all entities of type Biomass and include all fields
in the entities in the output.

=head2 Related entities

The Biomass entity has the following relationship links:

=over 4
    
=item IsComprisedOf CompoundInstance

=item IsManagedBy Model


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Biomass [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item mod_date

last modification date of the biomass data

=item name

descriptive name for this biomass

=item dna

portion of a gram of this biomass (expressed as a fraction of 1.0) that is DNA

=item protein

portion of a gram of this biomass (expressed as a fraction of 1.0) that is protein

=item cell_wall

portion of a gram of this biomass (expressed as a fraction of 1.0) that is cell wall

=item lipid

portion of a gram of this biomass (expressed as a fraction of 1.0) that is lipid but is not part of the cell wall

=item cofactor

portion of a gram of this biomass (expressed as a fraction of 1.0) that function as cofactors

=item energy

number of ATP molecules hydrolized per gram of this biomass


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'mod_date', 'name', 'dna', 'protein', 'cell_wall', 'lipid', 'cofactor', 'energy' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Biomass [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    mod_date
        last modification date of the biomass data
    name
        descriptive name for this biomass
    dna
        portion of a gram of this biomass (expressed as a fraction of 1.0) that is DNA
    protein
        portion of a gram of this biomass (expressed as a fraction of 1.0) that is protein
    cell_wall
        portion of a gram of this biomass (expressed as a fraction of 1.0) that is cell wall
    lipid
        portion of a gram of this biomass (expressed as a fraction of 1.0) that is lipid but is not part of the cell wall
    cofactor
        portion of a gram of this biomass (expressed as a fraction of 1.0) that function as cofactors
    energy
        number of ATP molecules hydrolized per gram of this biomass
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
	print STDERR "all_entities_Biomass: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Biomass($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Biomass($start, $count, \@fields);
}
