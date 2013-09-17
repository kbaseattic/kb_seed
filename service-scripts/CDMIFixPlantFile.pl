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
use SeedUtils;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use BasicLocation;

=head1 CDMI Plant File Repair Utility

    CDMIFixPlantFile [options] source genomeName controlFile inDirectory outDirectory

Fix up the exchange files in a directory. This script fixes two common
problems in exchange files for plant data.

=over 4

=item 1

Sometimes the contig IDs are missing the prefix C<Chr>.

=item 2

The text C<NULL> is used for a null value instead of a period (C<.>).

=back

All files are assumed to be tab-delimited. The column containing contig IDs
is listed in the command-line parameters.

=head2 Command-Line Options and Parameters

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>.

There are five positional parameters.

=over 4

=item 1

The source database name (e.g. C<SEED>, C<MOL>, ...)

=item 2

The KBase ID of the genome in question

=item 3

The full name of a control file containing a list of the input file names.
Each file name should be a base name with optional wildcards. The control
file is tab-delimited and contains an input file name pattern in the
first column, the (1-based) number of the column in that file containing contig 
IDs in the second column, and the comment character in the third column. If 
no input file column contains contig IDs, the second column should be empty.
If the input file does not have comment lines, the third column should be
empty.

=item 4

The name of the input file directory.

=item 5

The name of the output directory.

=back

The output files will be put in the output directory with the same base name
as the input files.

=cut

# Turn off buffering for progress messages.
$| = 1;

# Connect to the database.
my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
if (! $cdmi) {
    print "usage: CDMIFixPlantFile [options] source genomeName controlFile inDirectory outDirectory\n";
    exit;
}
print "Connected to CDMI.\n";
# Get the source and genome directory.
my ($source, $genomeName, $controlFile, $inDirectory, $outDirectory) = @ARGV;
if (! $source) {
    die "No source database specified.\n";
} elsif (! $genomeName) {
    die "No genome name specified.\n";
} elsif (! $controlFile) {
    die "No control file specified.\n";
} elsif (! -f $controlFile) {
    die "Control file $controlFile not found.\n";
} elsif (! $inDirectory) {
    die "No input directory specified.\n";
} elsif (! -d $inDirectory) {
    die "Input directory $inDirectory not found.\n";
} elsif (! $outDirectory) {
    die "No output directory specified.\n";
} elsif (! -d $outDirectory) {
    die "Output directory $outDirectory not found.\n";
} else {
    # Initialize the load helper.
    my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);
    $loader->SetSource($source);
    # Get the statistics.
    my $stats = $loader->stats();
    # Find the genome and get its contig list.
    my %contigMap = map { $_ => 1 } $cdmi->GetFlat("Submitted Genome IsComposedOf Contig",
            "Submitted(from-link) = ? AND Genome(source-id) = ?", [$source, $genomeName],
            'Contig(source-id)');
    my $contigCount = scalar keys %contigMap;
    # Only proceed if we found it.
    if (! $contigCount) {
        die "Genome $genomeName for $source is missing or has no contigs.\n";
    } else {
        print "$contigCount contigs found in $genomeName.\n";
        # Change to the input directory.
        chdir $inDirectory;
        # Open the control file.
        open(my $cih, "<$controlFile") || die "Could not open control file: $!\n";
        # Loop through it.
        while (! eof $cih) {
            my ($pattern, $contigCol, $commentChar) = $loader->GetLine($cih);
            $stats->Add(controlLineIn => 1);
            my @inFiles = glob $pattern;
            print "Processing $pattern: " . scalar(@inFiles) . " files found.\n";
            # Compute the real contig column. We convert from 1-based to 0-based
            # and use -1 if there is no contig column.
            if (! $contigCol) {
                $contigCol = -1;
            } else {
                $contigCol--;
            }
            # Loop through the files found.
            for my $inFile (@inFiles) {
                # Open the input and output files.
                open(my $ih, "<$inDirectory/$inFile") || die "Could not open input file $inFile: $!\n";
                open(my $oh, ">$outDirectory/$inFile") || die "Could not open output file $inFile: $!\n";
                # Loop through the input file.
                while (! eof $ih) {
                    my $line =<$ih>;
                    $stats->Add(inputLineIn => 1);
                    # Check to see if this is a comment.
                    if (defined $commentChar && substr($line, 0, 1) eq $commentChar) {
                        # It is. Write it unmodified.
                        print $oh $line;
                        $stats->Add(commentLineOut => 1);
                    } else {
                        # Split the line into columns.
                        chomp $line;
                        my @cols = split /\t/, $line;
                        # Convert the columns.
                        for (my $i = 0; $i < @cols; $i++) {
                            # Check for NULL.
                            if ($cols[$i] =~ /^\s*NULL\s*$/) {
                                $cols[$i] = '.';
                                $stats->Add(nullFixed => 1);
                            }
                            # Check for a need to trim.
                            if ($cols[$i] =~ /(.*?)\s+$/) {
                                $cols[$i] = $1;
                                $stats->Add(colTrimmed => 1);
                            }
                            # Check for a contig ID.
                            if ($i == $contigCol) {
                                # Find out if we need to use the contig ID's alternate form.
                                my $altForm;
                                my $origForm = $cols[$i];
                                if ($origForm =~ /^chr(.+)/) {
                                    $altForm = $1;
                                } else {
                                    $altForm = "chr$origForm";
                                }
                                if (! $contigMap{$origForm} && $contigMap{$altForm}) {
                                    $cols[$i] = $altForm;
                                    $stats->Add(contigIdFixed => 1);
                                }
                            }
                            $stats->Add(columnProcessed => 1);
                        }
                        # Output the line.
                        print $oh join("\t", @cols) . "\n";
                        $stats->Add(dataLineOut => 1);
                    }
                }
            }
        }
    }
    # Display the statistics.
    print "All done.\n" . $stats->Show();
}


=head2 Subroutines

