#!/usr/bin/perl -w 

use strict;
use SAPserver;
use Getopt::Long;
use ScriptThing;

# This is a SAS Component

=head1 svr_pegs_in_subsystems

    svr_pegs_in_subsystems genome_ids.tbl <subsystem_ids.tbl >peg_role_data.tbl

Return all genes in one or more subsystems found in one or more genomes.

This script takes a list of genomes and a list of subsystems and returns a list
of the genes represented in each genome/subsystem pair. It takes one positional
parameter-- the name of the file containing the genome IDs, and reads the list
of subsystem IDs from the standard input.

The standard output will be a tab-delimited file, each record containing a
subsystem ID, a functional role in that subsystem, and the ID of a gene with
that role from one of the supplied genomes.

This is a pipe command. The input is from the standard input and the output is
to the standard output.

The following command-line options are supported.

=over 4

=item group

If specified, then each output line will be for a single role, and the gene IDs will
be listed as a single comma-delimited string.

=item noroles

If specified, then the second column in each output line (functional role) will be
omitted from the output.

=item url

The URL for the Sapling server, if it is to be different from the default.

=item c

Number (1-based) of the column in the input file containing the subsystem name. If omitted,
the last column is used.

=back

=cut

my $noroles = 0;
my $group = 0;
my $show_owner = 0;
my $column;
my $oldid = "";
my $url = "";
my $inputFile = "-";

$0 =~ m/([^\/]+)$/;
my $self = $1;
my $usage = "$self [--noroles --group --url=http://...] GenomeF < SubsystemIDs";

my $rc = GetOptions("noroles" => \$noroles, "group" => \$group, "url=s" => \$url, "i=s" => \$inputFile, "c=i" => \$column);

if (!$rc) {
    die "\n   usage: $usage\n\n";
}

my $roles = $noroles ? 0 : 1;
my $ss = SAPserver->new(url => $url);

open my $gh, "<" . $ARGV[$#ARGV] || die "Genome file error: $!";

my @genomes = ScriptThing::GetList($gh);
close $gh;
open(my $ih, "<$inputFile") || die "Error opening input: $!";
while (my @tuples = ScriptThing::GetBatch($ih, 10, $column)) {
    my @subs = map { $_->[0] } @tuples;
    my $pegs_inss = $ss->pegs_in_subsystems(-genomes => \@genomes,
                                            -subsystems => \@subs);
    # Loop through the incoming lines, and pair the results with the inputs.
    for my $tuple (@tuples) {
        # Get the current line and its subsystem ID.
        my ($sub, $line) = @$tuple;
        # Get the role hash for this subsystem.
        my $roleHash = $pegs_inss->{$sub};
        # Only proceed if we found something.
        if ($roleHash) {
            # Are we including roles in the output?
            if ($roles) {
                # Yes. Loop through the roles.
                for my $role (sort keys %$roleHash) {
                    # Get the features for this role.
                    my $fids = $roleHash->{$role};
                    # Are we in group mode?
                    if ($group) {
                        # Yes. Put all the pegs on a single line.
                        print "$line\t$role\t" . join(", ", @$fids) . "\n";
                    } else {
                        # No. Put each peg on a line by itself.
                        for my $fid (@$fids) {
                            print "$line\t$role\t$fid\n";
                        }
                    }
                }
            } else {
                # Roles are not included in the output. We need to create
                # a list of the features for all the roles.
                my %fids;
                for my $role (keys %$roleHash) {
                    my $fidList = $roleHash->{$role};
                    for my $fid (@$fidList) {
                        $fids{$fid} = 1;
                    }
                }
                my @fids = sort keys %fids;
                # Are we grouping the features?
                if ($group) {
                    # Yes. Put all the pegs on one line.
                    print "$line\t" . join(", ", @fids) . "\n";
                } else {
                    # No. Put each peg on its own line.
                    for my $fid (@fids) {
                        print "$line\t$fid\n";
                    }
                }
            }
        }
    }
}

