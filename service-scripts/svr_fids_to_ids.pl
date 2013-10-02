# -*- perl -*-
# This is a SAS Component
########################################################################
# Copyright (c) 2003-2008 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
# 
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License. 
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
########################################################################

use strict;
use SeedEnv;

=head1 NAME

svr_fids_to_ids

=head1 SYNOPSIS

svr_fids_to_ids < table.with.FID.as.last.column > extended.table

=head1 DESCRIPTION

Extend a table containing a column of FIG-IDs (FIDs) by appending
a column containing a comma-separated list of other known identifiers.

Example:

    svr_fids_to_ids < table.with.FID.in.last.column > extended.table

=head1 COMMAND-LINE OPTIONS

Usage: svr_subsystem_classification [-url=URL] [-c=num] [-protein] [-natural] < table.with.FID.in.some.column > extended.table

    --help     --- Displays this document

    --url      --- Optional URL for alternate SAPLING server (D: http://pubseed.theseed.org/sapling/server.cgi)

    --c        --- Column number, if the FID is not in the last column

    --protein  --- Also return alternate IDs for every FID having the same protein sequence as this FID (D: FALSE)

    --natural  --- Return IDs in "natural" form rather than SEED type-prefixed form (D: FALSE)

=head1 Output

A table with one added columnn containing a comma-separated list of other known identifiers.

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

my $usage = "svr_fids_to_ids [-c=num] < table.with.fid.as.last.column > extended.table";

use Getopt::Long;
my $help;
my $url     = '';
my $column  = undef;
my $types   = '';
my $protein = 0;
my $natural = 0;
my $rc = GetOptions( "help"    => \$help,
		     "c=i"     => \$column,
                     "url=s"   => \$url,
		     "types=s" => \$types,
		     "protein" => \$protein,
		     "natural" => \$natural,
                   );

if (!$rc || $help) {
    seek(DATA, 0, 0);
    while (<DATA>) {
	last if /^=head1 COMMAND-LINE /;
    }
    while (<DATA>) {
	last if (/^=/);
	print $_;
    }
    exit($help ? 0 : 1);
}


# Get the server object.
my $sapServer = SAPserver->new(url => $url);

# The main loop processes chunks of input, 1000 lines at a time.
while (my @tuples = ScriptThing::GetBatch(\*STDIN, undef, $column)) {
    # Build argument hashP
    my $argH     = { -ids => [ map { $_->[0] } @tuples] };
    if ($types)    { $argH->{-types} = [ split(/,/, $types) ]; }
    if ($protein)  { $argH->{-protein} = 1; }
    if ($natural)  { $argH->{-natural} = 1; }
    
    # Ask the server for the list of alias IDs
    my $idHash = $sapServer->fids_to_ids($argH);
    
    # Output the results for these FIDs.
    for my $tuple (@tuples) {
        # Get this FID and the line
        my ($fid, $line) = @$tuple;
	
	my @ids = ();
	foreach my $idType (sort keys %{ $idHash->{$fid} }) {
	    push @ids, @{ $idHash->{$fid}->{$idType} };
	}
	
	# Output the line with the alt-IDs appended.
	print STDOUT (join("\t", ($line, join(",", @ids))), "\n");
    }
}
exit(0);

__DATA__
