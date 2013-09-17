use strict;

use Getopt::Long;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_get_all

Process a general query against the Sapling database.

This command performs a generalized query against the Sapling database using
a path through the entities and relationships and a parameterized constraint.
A list of output fields is used to produce a tab-delimited output file.
The content of this file is completely variable, dependent entirely on the
fields chosen.

For a description of how to create queries using this command, refer to
L<ERDB/Queries> and L<ERDB/GetAll> to understand how queries work, and
to the Sapling database documentation for a description of the entities,
relationships, and fields in the database.

=head2 Examples

    svr_get_all -p 'Feature Produces ProteinSequence' -c 'Feature(id) = ?' -v 'fig|1247729.4.peg.1025' -f 'Feature(function),ProteinSequence(sequence)'

would produce a 2-column file with a single row.  The first column would contain 
the functional assignment of the identified feature (C<fig|1247729.4.peg.1025>) and
the second its protein sequence.

    svr_get_all -p 'Genome IsOwnerOf Feature' -c 'Genome(scientific-name) LIKE ? AND Feature(feature-type) = ?' -v 'Campylobacter %,rna' -f 'Feature(id)'

would produce a 1-column file with multiple rows. The file would contain the IDs
of all the RNA features in Campylobacter genomes.

    svr_get_all -p 'Genome' -c 'Genome(complete) = 1 ORDER BY Genome(scientific-name)' -f 'scientific-name,id'

would produce a 2-column file containing the name and ID of each complete genome,
ordered by genome name. (Note that this is the same as the output from the command 
L<svr_all_genomes.pl> with the C<-complete> option).

=head2 Command-Line Options

=over 4

=item url

The URL for the Sapling server, if it is to be different from the default.

=item p

The path through the Sapling database (see L<ERDB/Object Name List>) for the query to follow.

=item c

The constraint (see L<ERDB/Filter Clause>) for the query, expressed in a syntax similar to an SQL
WHERE clause. Note that the C<LIMIT> option is prohibited. Use the C<-n> parameter
of this command instead.

=item v

A comma-delimited list of the parameter values to be substituted into the constraint.
There must be one parameter in this list for each question mark in the constraint.

=item f

A comma-delimited list of the names for the fields to return.

=item n

The maximum number of results to return. If omitted, all qualifying results will
be returned.

=back

=head2 Output Format

The standard output is a file where each line contains a genome name and a genome ID.

=cut

my $usage    = "usage: svr_get_all [--url=http://...] -p path [-c filter] [-v parameters] -f fields [-n count] >output\n";
my $url = '';
my $path = '';
my $filter = '';
my $parameters = '';
my $fields = '';
my $count = 'none';
my $opted    = GetOptions('p=s' => \$path,
                          'c=s' => \$filter,
                          'v=s' => \$parameters,
                          'f=s' => \$fields,
                          'n=i' => \$count,
                          'url=s', \$url);

if (! $opted || ! $path || ! $fields) {
    print STDERR $usage;
} else {
    # Connect to the sapling server.
    my $sapObject  = SAPserver->new(url => $url);
    # Parse the parameters.
    my $parmList = [];
    if ($parameters) {
        $parmList = [ split m/,/, $parameters ];
    }
    # Parse the fields. Note that we allow comma-separated or space-separated.
    my $fieldList;
    if ($fields =~ /,/) {
        $fieldList = [ split m/\s*,\s*/, $fields ];
    } else {
        $fieldList = [ split m/\s+/, $fields ];
    }
    # Execute the query.
    my $rows = $sapObject->query({ -objects => $path, -filterString => $filter,
            -limit => $count, -parameters => $parmList, -fields => $fieldList });
    if (! defined $rows) {
        # Note we have an error.
        print STDERR "Error executing query.\n";
    } else {
        # Output the rows.
        for my $row (@$rows) {
	    my @disp = map { ref($_) eq 'ARRAY' ? join(",", @$_) : $_ } @$row;
            print join("\t", @disp) . "\n";
        }
    }
}
