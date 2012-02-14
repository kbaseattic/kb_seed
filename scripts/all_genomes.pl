use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 all_genomes

------

Example:

    fids_to_annotations < fids > table.with.annotations.added

would read in a file of fids and add an extra column
containing annotations.

------

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the fid. If some other column contains the fid,
use

    -c N

where N is the column (from 1) that contains the fid.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing fid is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the annotations).  Input lines that cannot
be extended are written to stderr.  If the input fid leads
to a list of annotations, then multiple lines will be written to the
output.

=cut
use ScriptThing;
use CDMIClient;
#use CDMI_EntityAPIImpl;
#use CDMI;

my @fields = ("source_id");
        
my $usage = "usage: all_genomes  > list of genome id's";

my $i = "-";
my $geO = CDMIClient->new_get_entity_for_script('i=s' => \$i);

if (! $geO) { print STDERR $usage; exit }


#do this 1000 at a time in a loop
my $start = 0;
my $count = 1000;
my $h = $geO->all_entities_Genome($start, $count, \@fields);
my @k = keys(%$h);

while (scalar @k > 0) {
    foreach my $g (@k) {
        print $g, "\n";
    }
    $start += $count;
    my $h = $geO->all_entities_Genome($start, $count, \@fields);
    @k = keys(%$h);
}
   
    

