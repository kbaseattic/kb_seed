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

package SynonymSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSproutLoader';

=head1 Sprout Synonym Load Group Class

=head2 Introduction

The Synonym Load Group includes all of the major non-redundancy tables.

=head3 new

    my $sl = SynonymSproutLoader->new($erdb, $options, @tables);

Construct a new SynonymSproutLoader object.

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
    my @tables = sort qw(SynonymGroup IsSynonymGroupFor);
    # Create the BaseSproutLoader object.
    my $retVal = BaseSproutLoader::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the non-redundancy files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG object.
    my $fig = $self->source();
    # Is this the global section?
    if (! $self->global()) {
        # No, then get the section ID.
        my $genomeID = $self->section();
        # Get the database handle.
        my $dbh = $fig->db_handle();
        # Ask for the synonyms. Note that "maps_to" is a group name, and "syn_id" is a PEG ID or alias.
        my $sth = $dbh->prepare_command("SELECT maps_to, syn_id FROM peg_synonyms WHERE syn_id LIKE ?");
        my $result = $sth->execute("fig|$genomeID%");
        if (! defined($result)) {
            Confess("Database error in Synonym load: " . $sth->errstr());
        } else {
            Trace("Processing synonym results for $genomeID.") if T(2);
            # Loop through the synonym/peg pairs.
            while (my @row = $sth->fetchrow()) {
                # Get the synonym group ID and feature ID.
                my ($syn_id, $peg) = @row;
                # Count this row.
                $self->Add('synonyms-read' => 1);
                # Insure it's not deleted.
                if ($fig->is_deleted_fid($peg)) {
                    $self->Add('synonyms-skipped' => 1);
                } else {
                    # Create the group record.
                    $self->PutE(SynonymGroup => $syn_id);
                    # Connect the synonym to the peg.
                    $self->PutR(IsSynonymGroupFor => $syn_id, $peg);
                }
            }
        }
    }
}


1;
