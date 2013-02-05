use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_ContigSequence

=head1 SYNOPSIS

all_entities_ContigSequence [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the ContigSequence entity.

ContigSequences are strings of DNA.  Contigs have an
associated genome, but ContigSequences do not.  We can think
of random samples of DNA as a set of ContigSequences. There
are no length constraints imposed on ContigSequences -- they
can be either very short or very long.  The basic unit of data
that is moved to/from the database is the ContigChunk, from
which ContigSequences are formed. The key of a ContigSequence
is the sequence's MD5 identifier.

Example:

    all_entities_ContigSequence -a 

would retrieve all entities of type ContigSequence and include all fields
in the entities in the output.

=head2 Related entities

The ContigSequence entity has the following relationship links:

=over 4
    
=item HasSection ContigChunk

=item IsAlignedDNAComponentOf AlignmentRow

=item IsSequenceOf Contig


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_ContigSequence [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item length

number of base pairs in the contig


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'length' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_ContigSequence [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    length
        number of base pairs in the contig
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
	print STDERR "all_entities_ContigSequence: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_ContigSequence($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_ContigSequence($start, $count, \@fields);
}
