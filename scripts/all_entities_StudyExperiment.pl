use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 NAME

all_entities_StudyExperiment

=head1 SYNOPSIS

all_entities_StudyExperiment [-a] [--fields fieldlist] > entity-data

=head1 DESCRIPTION

Return all instances of the StudyExperiment entity.

An Experiment is a collection of observational units with one originator that are part of a specific study.  An experiment may be conducted at more than one location and in more than one season or year.

Example:

    all_entities_StudyExperiment -a 

would retrieve all entities of type StudyExperiment and include all fields
in the entities in the output.

=head2 Related entities

The StudyExperiment entity has the following relationship links:

=over 4
    
=item IncludesPart ObservationalUnit

=item IsAssayedBy Assay


=back

=head1 COMMAND-LINE OPTIONS

Usage: all_entities_StudyExperiment [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

=over 4    

=item source_name

Name/ID by which the experiment is known at the source.  

=item design

Design of the experiment including the numbers and types of observational units, traits, replicates, sampling plan, and analysis that are planned.

=item originator

Name of the individual or program that are the originators of the experiment.


=back

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use Bio::KBase::CDMI::CDMIClient;
use Getopt::Long;

#Default fields

my @all_fields = ( 'source_name', 'design', 'originator' );
my %all_fields = map { $_ => 1 } @all_fields;

our $usage = <<'END';
Usage: all_entities_StudyExperiment [arguments] > entity.data

    --fields list   Choose a set of fields to return. List is a comma-separated list of strings.
    -a		    Return all available fields.
    --show-fields   List the available fields.

The following fields are available:

    source_name
        Name/ID by which the experiment is known at the source.  
    design
        Design of the experiment including the numbers and types of observational units, traits, replicates, sampling plan, and analysis that are planned.
    originator
        Name of the individual or program that are the originators of the experiment.
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
	print STDERR "all_entities_StudyExperiment: unknown fields @err. Valid fields are: @all_fields\n";
	exit 1;
    }
}

my $start = 0;
my $count = 1_000_000;

my $h = $geO->all_entities_StudyExperiment($start, $count, \@fields );

while (%$h)
{
    while (my($k, $v) = each %$h)
    {
	print join("\t", $k, map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$v{@fields}), "\n";
    }
    $start += $count;
    $h = $geO->all_entities_StudyExperiment($start, $count, \@fields);
}
