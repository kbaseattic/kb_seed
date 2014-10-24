#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
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
#

=head1 Function Update Utility

    CDMIFixFunctions [options] inFile

=head2 Introduction

This script reads a file of functional assignments and updates the CDMI with them.
The functional assignment is updated in place and the role connections redone
accordingly.

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

There is one positional parameter-- the name of the input file.

=cut

    use strict;
    use Bio::KBase::CDMI::CDMI;
    use Bio::KBase::CDMI::CDMILoader;
    use Stats;
    use SeedUtils;

    $| = 1; # Prevent buffering on STDOUT.
    # Connect to the target database.
    print "Connecting to database.\n";
    my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
    if (! $cdmi) {
        print "usage: CDMIFixFunctions [options] infile\n";
    } else {
        # Create the loader object.
        my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
        # Get the statistics object.
        my $stats = $loader->stats;
        # Loop through the input file.
        my $inFile = $ARGV[0] || '-';
        open(my $ih, "<$inFile") || die "Could not open $inFile: $!";
        while (! eof $ih) {
        	my ($fid, $function) = $loader->GetLine($ih);
		    # Only proceed if the feature exists.
		    if (! $cdmi->Exists(Feature => $fid)) {
		    	$stats->Add(featureNotFound => 1);
		    } else {
		    	$loader->UpdateFunction($fid, $function);
		    }
        }
        print "All done:\n" . $stats->Show();
    }
    
