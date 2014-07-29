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

    use strict;
    use Stats;
    use SeedUtils;
    use Bio::KBase::CDMI::CDMI;

=head1 CDMI Relationship Cleaner

    CDMIDupFix [options] relName field1 field2 ...

This script analyzes a relationship in a CDMI and deletes duplicate rows.

The command-line options are as specified in L<Bio::KBase::CDMI::CDMI/new_for_script>. plus the following.

The positional parameters are the relationship name and the names of any additional
fields that should be used to determine whether or not a row is a duplicate.

=over 4

=item file

Name of a tab-delimited file containing a list of relationship names. Each row contains the relationship
name in the first column and the additional field names in the remaining columns. The utility will be
run on each relationship listed.

=back

=cut

# Prevent buffering on STDOUT.
$| = 1;
my $file;
# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script("file=s" => \$file);
if (! $cdmi) {
    print "usage: CDMIDupFix [options] relName field1 field2 ... \n";
} else {
    # We'll put the relationship name and the list of fields in @rows. Each individual
    # row will be parsed into $relName and @fields.
    my (@rows, $relName, @fields);
 	# Do we have a file?
    if ($file) {
    	# Yes. Read the instruction sets from the file.
    	open(my $ih, "<$file") || die "Could not open input file: $!";
    	while (! eof $ih) {
    		my $line = <$ih>;
    		chomp $line;
    		push @rows, [split /\t/, $line];
    	}	
    } else {
    	# No file. Use the parameters.
    	push @rows, [@ARGV];	
    }
    # Accumulate the stats in here.
    my $stats = Stats->new();
    for my $row (@rows) {
    	($relName, @fields) = @$row;
	    print "Processing $relName with " . scalar(@fields) . " extra fields.\n";
	    # Call the processing method.
	    my $subStats = $cdmi->CleanRelationship($relName, @fields);
	    # Fold in the statistics.
	    $stats->Accumulate($subStats);
    }
    # Denote we're done.
    print "All done.\n" . $stats->Show();
}