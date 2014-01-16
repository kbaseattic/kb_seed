use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_ProteinSequence

=head1 SYNOPSIS

all_entities_ProteinSequence [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the ProteinSequence entity.

We use the concept of ProteinSequence as an amino acid
string with an associated MD5 value.  It is easy to access the
set of Features that relate to a ProteinSequence.  While function
is still associated with Features (and may be for some time),
publications are associated with ProteinSequences (and the inferred
impact on Features is through the relationship connecting
ProteinSequences to Features).

Example:

    all_entities_ProteinSequence -a 

would retrieve all entities of type ProteinSequence and include all fields
in the entities in the output.

=head2 Related entities

The ProteinSequence entity has the following relationship links:

=over 4
    
=item HasAssertedFunctionFrom Source

=item HasConservedDomainModel ConservedDomainModel

=item IsATopicOf Publication

=item IsAlignedProteinComponentOf AlignmentRow

=item IsProteinFor Feature

=item IsProteinMemberOf Family


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_ProteinSequence [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item sequence

The sequence contains the letters corresponding to the protein's amino acids.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'sequence' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_ProteinSequence [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    sequence
        The sequence contains the letters corresponding to the protein's amino acids.
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
	print STDERR "all_entities_ProteinSequence: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_ProteinSequence($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_ProteinSequence($start, $count, \@fields);
}
