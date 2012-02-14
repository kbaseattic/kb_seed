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

package TargetCriterionCellLocation;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionQuery);

=head1 Cell Location Target Search Criterion Object

=head2 Introduction

This is a search criterion object for filtering by cell location. A feature's
protein is considered a match for a particular cell location if there is an
C<IsPossiblePlaceFor> record connecting the feature and the location with a match
score of 2.5 or better.

=head3 new

    my $tc = TargetCriterionCellLocation->new($rhelp, $name, $label, $hint);

Construct a new TargetCriterionCellLocation object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion type.

=item label

Display label for this criterion type.

=item hint

Hint tooltip for this criterion type.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint) = @_;
    # Compute the possible cell locations.
    my $sprout = $rhelp->DB();
    my %selectionData;
    for my $cello ($sprout->GetFlat('CellLocation', "", [], 'id')) {
        # The cell location code is a wiki word. We convert it into a real
        # word by peeling capitalized sections off one by one.
        my @words;
        while ($cello =~ /([A-Z][a-z]+)/g) {
            push @words, $1;
        }
        $selectionData{$cello} = join(" ", @words);
    }
    # Package them with the label and hint.
    my %options = (
        name => $name,
        label => $label,
        hint => $hint,
        selectionData => \%selectionData,
    );
    # Construct the underlying object, specifying that the main field of interest
    # is the from-link of IsPossiblePlaceFor
    my $retVal = TargetCriterionQuery::new($class, $rhelp, \%options,
                                           'from-link', qw(Feature IsPossiblePlaceFor));
    # Denote this criterion is insane.
    $retVal->{sanity} = 0;
    # Return the object.
    return $retVal;
}

=head2 Virtual Methods

=head3 Validate

    my $okFlag = $tc->Validate($parms);

Return TRUE if the specified parameters are valid for a search criterion of this type
and FALSE otherwise. If an error is detected, the error message can be retrieved using
the L</message> method.

=over 4

=item parms

A Criterion Parameter Object whose fields are to be validated.

=item RETURN

Returns TRUE if the parameters are valid, else FALSE.

=back

=cut

sub Validate {
    # Get the parameters.
    my ($self, $parms) = @_;
    # Default to valid.
    my $retVal = 1;
    # Get the selection value.
    my $value = $parms->{selection};
    # Insure it matches one of the codes in the selection data.
    if (! exists $self->{selectionData}->{$value}) {
        # No, so we have an error.
        $self->SetMessage("Invalid selection \"$value\" for $self->{label}.");
        $retVal = 0;
    }
    # Return the validation code.
    return $retVal;
}

=head3 ComputeQuery

    my ($joins, $filterString, $parms) = $tc->ComputeQuery($criterion);

Compute the SQL filter, join list, and parameter list for this
criterion. If the criterion cannot be processed by SQL, then nothing is
returned, and the criterion must be handled during post-processing.

The join list and the parameter list should both be list references. The
filter string is a true string.

If the filter string only uses the B<Genome> and B<Feature> tables, then the
join list can be left empty. Otherwise, the join list should start with the
particular starting point (B<Genome> or B<Feature>) and list the path through
the other relevant entities and relationships. Each criterion will have its
own separate join path. 

=over 4

=item criterion

Reference to a Criterion Parameter Object.

=item RETURN

Returns a 3-tuple consisting of the join list, the relevant filter string,
and the matching parameters. If the criterion cannot be processed using
SQL, then the return list contains three undefined values. (This is what happens if
you don't override this method.)

=back

=cut

sub ComputeQuery {
    # Get the parameters.
    my ($self, $criterion) = @_;
    # Fetch the join list.
    my $joins = $self->JoinList();
    # Compute the filter string.
    my $filterString = "IsPossiblePlaceFor(from-link) = ? AND IsPossiblePlaceFor(confidence) >= 2.5";
    # Finally, we build the parameter list, which contains the selection value.
    my $parms = [ $criterion->{selection} ];
    # Return the results.
    return ($joins, $filterString, $parms);
}

=head3 GetValueData

    my $value = $tc->GetValueData($feature);

Return the value data from the specified feature that is relevant to this
criterion. This method is called when the object cache is empty and the
value is needed in order to call L</PutExtraColumns> or L</CheckValue>.

=over 4

=item feature

An [[ERDBObjectPm]] describing the current feature.

=item RETURN

Returns a reference to a possibly-empty hash that maps all of the feature's
possible cell locations to the corresponding confidence value.

=back

=cut

sub GetValueData {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Get the Sprout database.
    my $sprout = $feature->DB();
    # Get the feature ID.
    my $id = $feature->PrimaryValue('Feature(id)');
    # Get the possible places for this feature.
    my %retVal = map { $_->[0] => $_->[1] }
                    $sprout->GetAll('IsPossiblePlaceFor', 'IsPossiblePlaceFor(to-link) = ?', [$id],
                                    'IsPossiblePlaceFor(from-link) IsPossiblePlaceFor(confidence)');
    # Return them.
    return \%retVal;
}

=head3 CheckValue

    my $match = $tc->CheckValue($criterion, $valueData);

Return TRUE if the current feature matches this criterion, else FALSE.

=over 4

=item criterion

Criterion Parameter object describing this criterion's parameters.

=item valueData

Reference to a possibly-empty hash that maps all of the feature's
possible cell locations to the corresponding confidence value.

=item RETURN

Returns TRUE if the current feature matches the criterion, else FALSE.

=back

=cut

sub CheckValue {
    # Get the parameters.
    my ($self, $criterion, $valueData) = @_;
    # Extract the name for the location of interest.
    my $locName = $criterion->{selection};
    # We match if the confidence for the indicated location is 2,5 or better.
    my $confidence = $valueData->{$locName};
    my $retVal = (defined $confidence && $confidence >= 2.5);
    # Return the result.
    return $retVal;
}

1;