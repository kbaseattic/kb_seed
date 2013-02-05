use strict;
use Data::Dumper;
use Bio::KBase::Utilities::ScriptThing;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

get_entity_Subsystem

=head1 SYNOPSIS

get_entity_Subsystem [-c N] [-a] [--fields field-list] < ids > table.with.fields.added

=head1 DESCRIPTION

A subsystem is a set of functional roles that have been annotated simultaneously (e.g.,
the roles present in a specific pathway), with an associated subsystem spreadsheet
which encodes the fids in each genome that implement the functional roles in the
subsystem.

Example:

    get_entity_Subsystem -a < ids > table.with.fields.added

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

Usage: get_entity_Subsystem [arguments] < ids > table.with.fields.added

    -a		    Return all available fields.
    -c num          Select the identifier from column num.
    -i filename     Use filename rather than stdin for input.
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


our $usage = <<'END';
Usage: get_entity_Subsystem [arguments] < ids > table.with.fields.added

    -c num          Select the identifier from column num
    -i filename     Use filename rather than stdin for input
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



use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'version', 'curator', 'notes', 'description', 'usable', 'private', 'cluster_based', 'experimental' );
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
	print STDERR "get_entity_Subsystem: unknown fields @err. Valid fields are: @all_fields\n";
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
    my $h = $geO->get_entity_Subsystem(\@h, \@fields);
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
