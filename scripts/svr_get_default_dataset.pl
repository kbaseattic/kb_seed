#!/usr/bin/perl -w

#
# This is a SAS Component
#

########################################################################
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
########################################################################

use strict;
use Data::Dumper;
use ANNOserver;
use Getopt::Long;
#use Pod::Usage;

=head1 svr_get_default_dataset

=head2 Introduction

    svr_get_default_dataset [options] 

Return the name of the default dataset currently installed in the figfams annotation server.

=head2 Command-Line Options

=over 4

=item help

Display this command's parameters and options.

=item url

The URL for the FIGfam server, if it is to be different from the default.

=back

=cut

# Get the command-line options and parameters.
my $show_all;
my $help;
my $man;
my $url = "";
my $rc = GetOptions("help" => \$help,
		    "all" => \$show_all,
		    "url=s" => \$url);


if ($help)
{
    #pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});  
    my $usage = [ "$0 [options]",
		  "\tOPTIONAL",
		  "\t-all\tShow all datasets",
		  "\t-url\tANNO server URL",
		  "\t-help\tdisplay command-line options", ""];
    
    print join "\n", @$usage;
    exit;
}

# Create a FIGfam server object.
my $ffServer = ANNOserver->new(url => $url);

my $res = $ffServer->get_active_datasets();
my($default, $all_sets) = @$res;

print "$default\n";
if ($show_all)
{
    for my $s (sort { $a cmp $b } keys %$all_sets)
    {
	my @k = sort { $a <=> $b } @{$all_sets->{$s}};
	print join("\t", $s, @k), "\n";
    }
}
