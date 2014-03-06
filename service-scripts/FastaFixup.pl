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

=head1 Fasta File Fixup

    FastaFixup fileName1 fileName2

This script fixes a common problem with FASTA protein files provided for plants:
the feature ID is suffixed with a vertical bar and an additional ID. The file will
be rewritten with the suffix removed.

Files are essentially modified in place, so this is a very destructive command.
The original file is renamed, then written back to its original location with the
fix in place, and the renamed file is deleted.

The positional parameters are the names of the files to process.

