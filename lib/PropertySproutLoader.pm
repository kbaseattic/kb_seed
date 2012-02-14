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

package PropertySproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Property Load Group Class

=head2 Introduction

The  Load Group includes all of the major searchable attribute tables.

=head3 new

    my $sl = SproutLoader->new($erdb, $source, $options, @tables);

Construct a new SproutLoader object.

=over 4

=item erdb

[[SproutPm]] object for the database being loaded.

=item options

Reference to a hash of command-line options.

=item tables

List of tables in this load group.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options) = @_;
    # Create the table list.
    my @tables = sort qw(Property HasProperty);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the searchable attribute files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # All of the property stuff is done globally.
    if ($self->global()) {
        # Get the list of attributes we need for these searches. Currently, it's 
        # essentials only.
        my @keys = $fig->get_group_keys('essential');
        # Get a hash of genome IDs.
        my %genomes = map { $_ => 1 } BaseSproutLoader::GetSectionList($sprout, $fig);
        # This will be where we compute the property IDs.
        my %propIDs = ();
        my $nextID = 1;
        # Loop through these keys, getting feature IDs.
        for my $key (@keys) {
            # Get all the attributes for this key.
            $self->Track(keys => $key, 10);
            my @attributes = $fig->get_attributes(undef, $key);
            MemTrace(scalar(@attributes) . " attribute values found for $key.") if T(ERDBLoadGroup => 3);
            $self->Add('attribute-keys' => 1);
            # Loop through them, extracting the ones for genomes in the genome hash.
            for my $attributeTuple (@attributes) {
                # Extract the pieces.
                my ($pegID, $key, $value, $url) = @{$attributeTuple};
                # Default the URL to an empty string.
                $url = "" if ! defined $url;
                # Only proceed if the peg ID is valid and for a known genome.
                if ($pegID =~ /^fig\|(\d+\.\d+)/ && $genomes{$1}) {
                    # It is. Compute the property ID.
                    my $propertyKeyValue = "$key::$value";
                    my $propID = $propIDs{$propertyKeyValue};
                    if (! defined $propID) {
                        # Here we have a new key/value pair, so it gets a new ID number.
                        $self->Add('attribute-pairs' => 1);
                        $propID = $nextID++;
                        $propIDs{$propertyKeyValue} = $propID;
                        # Add this ID to the property table.
                        $self->PutE(Property => $propID, 'property-name' => $key, 'property-value' => $value);
                    }
                    # Connect the feature to the property.
                    $self->PutR(HasProperty => $pegID, $propID, evidence => $url);
                    $self->Add('attributes-kept' => 1);
                } else {
                    # The object isn't a feature, or it isn't for an NMPDR genome, so we skip it.
                    $self->Add('attributes-skipped' => 1);
                }
            }
        }
    }
}


1;
