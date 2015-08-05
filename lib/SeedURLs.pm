package SeedURLs;

#
# Copyright (c) 2003-2015 University of Chicago and Fellowship
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

# This is a SAS component.

#===============================================================================
#  This is a central place to keep a list of active SEED instances.
#  The SEEDs come in two varieties: public and private. The intent is
#  that public SEEDs will be advertised, private ones will not be.
#  There is no implication of access control.
#
#     %SeedURLs::public    #  Mapping of "public" SEED names to URLs
#     @SeedURLs::names     #  List of "public" SEED names
#     $SeedURLs::names     #  Text list of "public" SEED names (comma separated)
#
#     %SeedURLs::all       #  Mapping of all SEED names to URLs
#     @SeedURLs::all_names #  List of all SEED names
#     $SeedURLs::all_names #  Text list of all SEED names (comma separated)
#
#  Names of the known SEEDs:
#
#     @names = SeedURLs::names( $all_flag );  # list
#     $names = SeedURLs::names( $all_flag );  # text string, comma separated
#
#  URLs of the known SEEDs:
#
#     @urls = SeedURLs::urls( $all_flag );    # list
#    \@urls = SeedURLs::urls( $all_flag );    # reference to a list
#
#     @name_and_url = SeedURLs::names_and_urls( $all_flag );  # list
#    \@name_and_url = SeedURLs::names_and_urls( $all_flag );  # reference to a list
#
#     where:  $name_and_url = [ $name, $url ]
#
#  URL of a known SEED referenced by name, or any SEED referenced by URL:
#
#     $url = SeedURLs::url( $name_or_url );
#
#===============================================================================

use strict;
use warnings;

#  Map of SEEDs to base URLs, and lists of the names:

our %public = ( core      => "http://core.theseed.org/FIG",
                open      => "http://open.theseed.org/FIG",
                pseed     => "http://pseed.theseed.org",
                pubseed   => "http://pubseed.theseed.org",
                uchicago  => "http://theseed.uchicago.edu/FIG"
              );

our @names  = sort { lc $a cmp lc $b } keys %public;
our $names  = join( ', ', @names );

#  SEEDs that will be recognized, but not advertised:

my %private = ( alien     => "http://alien.life.uiuc.edu/FIG",
                annotator => "http://anno-3.nmpdr.org/anno/FIG",
                golsen    => "http://bioseed.mcs.anl.gov/~golsen/FIG",
                mirror    => "http://seed-viewer.theseed.org"
              );

#  Mappings and names of complete list:

our %all       = ( %public, %private );
our @all_names = sort { lc $a cmp lc $b } keys %all;
our $all_names = join( ', ', @all_names );


#-------------------------------------------------------------------------------
#  Get a list of names of known SEEDs:
#
#   @names = SeedURLs::names( $all_flag );  # list
#   $names = SeedURLs::names( $all_flag );  # text string, comma separated
#
#
#  Get URLs of known SEEDs:
#
#   @urls  = SeedURLs::urls( $all_flag );   # list
#  \@urls  = SeedURLs::urls( $all_flag );   # reference to list
#
#   @name_and_url = SeedURLs::names_and_urls( $all_flag );  # list
#  \@name_and_url = SeedURLs::names_and_urls( $all_flag );  # reference to a list
#
#     where:  $name_and_url = [ $name, $url ]
#
#  If $all_flag is true, provide all names (public and private), otherwise
#  just provide the "public" values.
#-------------------------------------------------------------------------------

sub names
{
    wantarray ? $_[0] ? @all_names : $all_names
              : $_[0] ? @names     : $names;
}


sub urls
{
    my @urls = map { $all{ $_ } } ( $_[0] ? @all_names : @names );
    wantarray ? @urls : \@urls;
}


sub names_and_urls
{
    my @pairs = map { [ $_, $all{ $_ } ] } ( $_[0] ? @all_names : @names );
    wantarray ? @pairs : \@pairs;
}


#-------------------------------------------------------------------------------
#  Return a URL for a supplied name or URL. In case of a URL, no checking
#  is performed as this is intended to supply access to SEEDs that are not
#  included in this module.
#
#   $url = SeedURLs::url( $name_or_url )
#
#-------------------------------------------------------------------------------

sub url
{
    my ( $name ) = @_;
    $name ||= '';        # Avoid undefined valies

    ( $name =~ m/^http/i ) ? $name : $all{ $name };
}


1;
