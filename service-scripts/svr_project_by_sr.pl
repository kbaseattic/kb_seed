use strict;
use Data::Dumper;
use Carp;
use SeedEnv;


#
# This is a SAS Component
#


=head1 svr_project_by_sr

Get corresponding genes.

------

Example:

    svr_all_features 3702.1 peg | svr_project_by_sr

would produce a 2-column table.  The first column would contain
PEG IDs for genes occurring in genome 3702.1, and the second
would contain a peg believed to correspond in a second genome

The svr_corresponding_genes command can be used to map from one known genome 
to another.  However, this command is the start of a tool for mapping
specific genes to sets of corresponding genes (envision using FIGfams,
subsystems, or whatever).  For now we use just the technology of Solid Rectangles.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG for which functions are being requested.
If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (a peg that is putatively an isofunctional
homolog).

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svr_projet [-c column]";

my $column;
my $i = "-";
my $rc  = GetOptions('c=i' => \$column, 
		     'i=s' => \$i);
if (! $rc) { print STDERR $usage; exit }
open my $ih, "<$i";
while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @ids = map { $_->[0] } @tuples;
    my $same = &project(\@ids);
    for my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        my $pegs = $same->{$id};
        if (defined $pegs) {
	    foreach my $peg (@$pegs)
	    {
		print "$line\t$peg\n";
	    }
        }
    }
}

sub project {
    my($pegs) = @_;

    my $same = {};

    my %need;
    my $pegH        = $sapObject->fids_to_proteins(-ids => $pegs);
    my %md5s_needed = map { ($pegH->{$_} => 1) } keys(%$pegH);
    my %md5_to_set;
    my %set_to_pegs;

    if (open(SR,"<$FIG_Config::global/SolidRectangles.sets"))
    {
	my $line = <SR>;
	while ($line && ($line =~ /^(\d+)/))
	{
	    my $set = $1;
	    my @md5s;
	    while ($line && ($line =~ /^(\d+)\t(\S+)/) && ($1 == $set))
	    {
		push(@md5s,$2);
		$line = <SR>;
	    }
	    my @tmp = grep { $md5s_needed{$_} } @md5s;
	    if (@tmp > 0)
	    {
		my $md5H = $sapObject->proteins_to_fids(-prots => \@md5s);
		my %all_pegs;
		foreach my $md5 (keys(%$md5H))
		{
		    my $pegs_for_md5 = $md5H->{$md5};
		    foreach $_ (@$pegs_for_md5) { $all_pegs{$_} = 1 }
		}
		my @pegs_in_fam = grep { $pegH->{$_} } keys(%all_pegs);
		foreach my $peg (@pegs_in_fam)
		{
		    my @all_but = grep { $_ ne $peg } keys(%all_pegs);;
		    if (@all_but > 0)
		    {
			$same->{$peg} = \@all_but;
		    }
		    else
		    {
			$same->{$peg} = [];
		    }
		}
	    }
	}
	close(SR);
    }
    else
    {
	print STDERR "Could not find the solid rectangles\n";
    }
    return $same;
}
