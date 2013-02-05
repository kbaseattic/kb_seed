use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Biomass

=head1 SYNOPSIS

get_entity_Biomass [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

A biomass is a collection of compounds in a specific
ratio and in specific compartments that are necessary for a
cell to function properly. The prediction of biomasses is key
to the functioning of the model. Each biomass belongs to
a specific model.

Example:

    get_entity_Biomass -a < ids > table.with.fields.added

would read in a file of ids and add a column for each field in the entity.

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the id. If some other column contains the id,
use

    -c N

where N is the column (from 1) that contains the id.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Related entities

The Biomass entity has the following relationship links:

=over 4
    
=item IsComprisedOf CompoundInstance

=item IsManagedBy Model


=back

=head1 COMMAND-LINE OPTIONS

Usage: get_entity_Biomass [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
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


our $usage = <<'END';
Usage: get_entity_Biomass [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
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



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'mod_date', 'name', 'dna', 'protein', 'cell_wall', 'lipid', 'cofactor', 'energy' );
my %all_fields = map { $_ => 1 } @all_fields;

my $column;
my $a;
my $f;
my $i = "-";
my @fields;
my $help;
my $show_fields;
my $geO = Bio::KBase::CDMI::CDMIClient->new_get_entity_for_script('c=i'		 => \$column,
								  "all-fields|a" => \$a,
								  "help|h"	 => \$help,
								  "show-fields"	 => \$show_fields,
								  "fields=s"	 => \$f,
								  'i=s'		 => \$i);
if ($help)
{
    print $usage;
    exit 0;
}

if ($show_fields)
{
    print STDERR "Available fields:\n";
    print STDERR "\t$_\n" foreach @all_fields;
    exit 0;
}

if ($a && $f) 
{
    print STDERR "Only one of the -a and --fields options may be specified\n";
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
	print STDERR "get_entity_Biomass: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
} else {
    print STDERR $usage;
    exit 1;
}

my $ih;
if ($i eq '-')
{
    $ih = \*STDIN;
}
else
{
    open($ih, "<", $i) or die "Cannot open input file $i: $!\n";
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;
    my $h = $geO->get_entity_Biomass(\@h, \@fields);
    for my $tuple (@tuples) {
        my @values;
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};
	if (! defined($v))
	{
	    #nothing found for this id
	    print STDERR $line,"\n";
     	} else {
	    foreach $_ (@fields) {
		my $val = $v->{$_};
		push (@values, ref($val) eq 'ARRAY' ? join(",", @$val) : $val);
	    }
	    my $tail = join("\t", @values);
	    print "$line\t$tail\n";
        }
    }
}
__DATA__
