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

package TargetCriterionGeneId;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionQuery);

=head1 GeneId Match Target Search Criterion Object

=head2 Introduction

This is a search criterion object for search criteria involving a search by feature ID.
This is a little different from a normal query-based search because the ID could be a
FIG ID-- which would be in the Feature table-- or an Alias, which would be in the
IsAliasOf table.

=head3 new

    my $tc = TargetCriterionGeneId->new($rhelp);

Construct a new TargetCriterionGeneId object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion.

=item label

Label to display for this criterion in the type dropdown.

=item hint

The hint tooltip to be displayed for this criterion.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint) = @_;
    # Construct the underlying object.
    my $retVal = TargetCriterionQuery::new($class, $rhelp,
                                           { label => $label, hint => $hint, text => 1,
                                             name => $name },
                                           'from-link' => qw(Feature IsAliasOf));
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
    # Get the string value.
    my $value = $parms->{stringValue};
    # It's only invalid if it's blank.
    if (! defined $value || $value eq '' || $value =~ /^\s+$/) {
        $retVal = 0;
        $self->SetMessage("No value specified for $self->{label}.");
    }
    # Return the validation code.
    return $retVal;
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

Returns a scalar containing the value used to determine whether or not the specified
feature will match a criterion of this type. The object can be a list reference, a hash
reference, or a blessed object, so long as the virtual L</PutExtraColumns> and
L</CheckValue> methods understand it.

=back

=cut

sub GetValueData {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Get the feature ID.
    my $fid = $feature->PrimaryValue("Feature(id)");
    # Get the aliases from the database.
    my $sprout = $self->DB();
    my @aliases = $sprout->FeatureAliases($fid);
    # Put them together.
    my $retVal = [ $fid, @aliases ];
    # Return the result.
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
    # Get the parameter value.
    my $parm = $criterion->{stringValue};
    # Declare the join and filter variables.
    my ($joins, $filterString);
    # Is this a FIG ID?
    if ($parm =~ /^fig/) {
        # Yes, so use the feature ID.
        $joins = [];
        $filterString = "Feature(id) = ?";
    } else {
        # No, so use the alias join.
        $joins = [qw(Feature IsAliasOf)];
        $filterString = 'IsAliasOf(from-link) = ?';
    }
    # Return the results.
    return ($joins, $filterString, [$parm]);
}

=head3 AddExtraColumns

    my $flag = $tc->AddExtraColumns($rhelp);

Add any extra columns relevant to this criterion to the result helper.
If the data used to evaluate this criterion is not shown in the
default feature columns, then this method will call the B<AddExtraColumn>
method of the caller-specified [[ResultHelperPm]] object to reserve space
for the data in the result file. The default is to not add any extra columns.

=over 4

=item rhelp

Result helper to which the columns should be added.

=item RETURN

Returns TRUE if this criterion requires extra columns in the output, else FALSE.

=back

=cut

sub AddExtraColumns {
    # Get the parameters.
    my ($self, $rhelp) = @_;
    # We don't need extra columns for this. Instead, we add the optional
    # alias column at the end.
    $rhelp->AddOptionalColumn('alias');
    # Denote there are no extra columns.
    return 0;
}

=head3 CheckValue

    my $match = $tc->CheckValue($criterion, $valueData);

Return TRUE if the current feature matches this criterion, else FALSE.

=over 4

=item criterion

Criterion Parameter object describing this criterion's parameters.

=item valueData

Value computed for the current feature by the L</GetValueData> method.

=item RETURN

Returns TRUE if the current feature matches the criterion, else FALSE.

=back

=cut

sub CheckValue {
    # Get the parameters.
    my ($self, $criterion, $valueData) = @_;
    # Get the desired gene ID.
    my $geneID = $criterion->{stringValue};
    # Declare the return variable.
    my $retVal;
    # If it's a FIG ID, we only need to check the first thing in the list.
    if ($geneID =~ /^fig/) {
        $retVal = ($geneID eq $valueData->[0]);
    } else {
        # It's an alias, so check the whole list for a match.
        $retVal = grep { $_ eq $geneID } @$valueData;
    }
    # Return the result.
    return $retVal;
}

1;
