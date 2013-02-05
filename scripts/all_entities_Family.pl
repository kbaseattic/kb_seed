use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_Family

=head1 SYNOPSIS

all_entities_Family [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the Family entity.

The Kbase will support the maintenance of protein families
(as sets of Features with associated translations).  We are
initially only supporting the notion of a family as composed of
a set of isofunctional homologs.  That is, the families we
initially support should be thought of as containing
protein-encoding genes whose associated sequences all implement
the same function (we do understand that the notion of "function"
is somewhat ambiguous, so let us sweep this under the rug by
calling a functional role a "primitive concept").
We currently support families in which the members are
protein sequences as well. Identical protein sequences
as products of translating distinct genes may or may not
have identical functions.  This may be justified, since
in a very, very, very few cases identical proteins do, in
fact, have distinct functions.

Example:

    all_entities_Family -a 

would retrieve all entities of type Family and include all fields
in the entities in the output.

=head2 Related entities

The Family entity has the following relationship links:

=over 4
    
=item HasMember Feature

=item HasProteinMember ProteinSequence

=item IsCoupledTo Family

=item IsCoupledWith Family

=item IsFamilyFor Role

=item IsRepresentedIn Genome


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_Family [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item type

type of protein family (e.g. FIGfam, equivalog)

=item release

release number / subtype of protein family

=item family_function

optional free-form description of the family. For function-based families, this would be the functional role for the family members.

=item alignment

FASTA-formatted alignment of the family's protein sequences


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'type', 'release', 'family_function', 'alignment' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_Family [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    type
        type of protein family (e.g. FIGfam, equivalog)
    release
        release number / subtype of protein family
    family_function
        optional free-form description of the family. For function-based families, this would be the functional role for the family members.
    alignment
        FASTA-formatted alignment of the family's protein sequences
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
	print STDERR "all_entities_Family: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_Family($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_Family($start, $count, \@fields);
}
