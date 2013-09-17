
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

use strict;
use Data::Dumper;
use Carp;
use Getopt::Long;

=head1 svr_taxonomically_related_genomes

    svr_taxonomically_related_genomes [-c] [-d depth] < genome_ids > expanded_genome_ids

Get a list of genomes that are taxonomically related to the input genomes.

=head1 Introduction

Usage: svr_taxonomically_related_genomes [-c] [-d depth] < genome_ids > expanded_genome_ids

       -c  turn on caching; fetch taxonomy data over sapling only once
       -d  taxonomy level  (D = 7, species)
       -t  show taxonomy hierarchy of the input genomes

       If genome IDs are found in the command line, STDIN is not read.

       Examples: 

       1. Get all Bacillus genomes

          svr_taxonomically_related_genomes -d 6 224308.1 

       2. Get all Escherichia coli genomes using cached taxonomy info

          svr_taxonomically_related_genomes -d -1 -c -t 83333.1


=head2 Command-Line options

=over 4

=item -c 

Turn on caching; fetch taxonomy data over sapling only once.

=item -d depth (D = 7)

Taxonomy level. (1: Kindom, 2: Phylum, 3: Class, 4: Order, 5: Family,
6: Genus, 7: Species, 8: Strain)

Use negative numbers to go up from the highest taxonomy level.

=item -t 

Show taxonomy hierarchy of the query genomes.

=back

=head2 Input

The input is a list of genome IDs supplied in the command line or read from STDIN.

=head2 Output

The output is a list of related genome IDs written to STDOUT.

=cut

use SeedAware;
use SeedUtils;
use SAPserver;
use Storable;

my $usage = <<"End_of_Usage";

Usage: svr_taxonomically_related_genomes [-c] [-d depth] < genome_ids > expanded_genome_ids

       -c  turn on caching; fetch taxonomy data over sapling only once
       -d  depth of taxonomy subtree  (D = 7, species)
       -t  show taxonomy hierarchy of the input genomes

       If genome IDs are found in the command line, STDIN is not read.

       Examples: 

       1. Get all Bacillus genomes

          svr_taxonomically_related_genomes -d 6 224308.1 

       2. Get all Escherichia coli genomes using cached taxonomy info

          svr_taxonomically_related_genomes -d -1 -c -t 83333.1

End_of_Usage

my $help;
my $cache;
my $depth   = 7;
my $showtax = 0;

GetOptions("h|help"    => \$help,
           "c|cache"   => \$cache,
           "d|depth=i" => \$depth,
           "t|showtax" => \$showtax);

$help and die $usage;

my @gids = map { /(\d+\.\d+)/ ? $1 : () } @ARGV;
@gids > 0 or @gids = ( join(" ", <STDIN>) =~ m/(\d+\.\d+)/g );

die $usage unless @gids > 0;


my $pseed = 1;
my $envParm = $ENV{SAS_SERVER};

$ENV{SAS_SERVER} = 'PSEED' if $pseed;

my $sap  = SAPserver->new();

my ($gnmH, $taxH);

retrieve_if_exists('gnmH', '$sap->all_genomes()', { cache => $cache});
retrieve_if_exists('taxH', '$sap->taxonomy_of(-ids => [ keys %$gnmH ])', { cache => $cache});

my @orgs = keys %$gnmH;

my $chosen;

foreach my $gid (@gids) {

    if (!$taxH->{$gid}) {
        print STDERR "Taxnomy info not found for genome ID: $gid\n";
        next;
    } 

    my @levels = @{$taxH->{$gid}};

    my $l = ($depth > 0) ? ($depth - 1) : ($#levels + $depth);
       $l = 0 if $l < 0;

    if ($showtax) {
        print STDERR $gid . "\n";
        for my $i (0 .. $#levels) {
            my $padding = ($i == $l) ? "    => " : "       ";
            print STDERR $padding . $levels[$i]. "\n";
        }
        print STDERR  "\n";
    }

    my $t1 = $taxH->{$gid}->[$l];
    next unless $t1;

    for my $org (@orgs) {
        # $chosen->{$_} = 1 if $taxH->{$_} && $t1 eq $taxH->{$_}->[-$depth-1]; # only match the corresponding taxonomy level
        if ($taxH->{$org}) {
            for my $t2 (@{$taxH->{$org}}) {
                if ($t1 eq $t2) {
                    $chosen->{$org} = 1;
                    last;
                }
            }
        }
    }
}

for (keys %$chosen) {
    print join("\t", $_, $gnmH->{$_}) . "\n";
}

$ENV{SAS_SERVER} = $envParm if $pseed;

sub retrieve_if_exists {
    my ($var, $func, $opts) = @_;
    my $tmpdir = SeedAware::location_of_tmp($opts);
    my $store = "$tmpdir/$var.store";
    unlink $store if -e $store && !$opts->{cache};
    my $str = '
        if (-s $store) {
            $'.$var.' = retrieve($store);
        } else {
            $'.$var.' = '.$func.';
            store($'.$var.', $store);
        }';
    eval $str;
}
