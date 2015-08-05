#
# This is a SAS Component
#
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

=head1 Convert Tabbed Representation of Sets to Numbered Relational Representation

This script takes as input a tab-delimited file of sets, with each set being one
record in the file. It outputs a two-column tab-delimited file where the first
column is the set number and the second column is a set member. Thus, if the
input file is

    a       b       c
    d       e
    f
    g       h

The output would be

    1       a
    1       b
    1       c
    2       d
    2       e
    3       f
    4       g
    4       h

The optional positional parameter is the number to give to the first set. The default
is C<1>.

=cut

my $usage = "usage: tabs2rel [InitialN] < tab-sep-sets > relation";

my $n = (@ARGV > 0) ? $ARGV[0] : 1;

while (defined($_ = <STDIN>))
{
    chop;
    foreach $x (split(/\t/,$_))
    {
        print "$n\t$x\n";
    }
    $n++;
}

