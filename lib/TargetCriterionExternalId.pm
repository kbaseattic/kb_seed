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

package TargetCriterionExternalId;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionQuery);

=head1 External Database Gene ID Target Search Criterion Object

=head2 Introduction

This is a search criterion object for search criteria involving one of the
curated external IDs. Each criterion object is for a single ID type.

=head3 new

    my $tc = TargetCriterionExternalId->new($rhelp, $name, $label, $hint, $databaseID);

Construct a new TargetCriterionExternalId object. The following parameters are
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

=item databaseID

The ID of the relevant external database.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint, $databaseID) = @_;
    # Construct the underlying object.
    my $retVal = TargetCriterionQuery::new($class, $rhelp, { label => $label,
                                                            hint => $hint,
                                                            text => 1,
                                                            name => $name },
                                           alias => qw(Feature IsAlsoFoundIn));
    # Save the database ID.
    $retVal->{externalDatabase} = $databaseID;
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
    # Get the name of the relevant field with the appropriate suffix.
    my $fieldName = $self->RelevantField($criterion->{idx});
    # Compute the join list.
    my $joins = $self->JoinList();
    # Compute the filter string.
    my $filterString = "$fieldName = ? AND IsAlsoFoundIn(to-link) = ?";
    # Get the parameter value.
    my $parm = $criterion->{stringValue};
    # Return the results.
    return ($joins, $filterString, [$parm, $self->{externalDatabase}]);
}

=head3 Sane

    my $flag = $tc->Sane($parms);

Return TRUE if this is a sane criterion, else FALSE. Every search must have at least one
sane criterion in order to be valid.

=over 4

=item parms (optional)

A Criterion Parameter Object for the current query.

=item RETURN

Returns TRUE if this query returns a relatively limited result set and uses SQL,
else FALSE. If you do not override this method, it returns FALSE.

=back

=cut

sub Sane {
    return 1;
}

=head3 ReadDatabaseValues

    my @values = $tc->ReadDatabaseValues($fid);

Read this field's values from the database. This method is called when we
need a field at search time and it's not a basic field (that is, it isn't
in the Feature or Genome tables) or when we need a field at runtime.

=over 4

=item fid

ID of the current feature.

=item RETURN

Returns a list of the values for the given field.

=back

=cut

sub ReadDatabaseValues {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Get the Sprout database.
    my $sprout = $self->DB();
    # Get the key table name.
    my $keyTable = $self->{keyTable};
    # Get the field name.
    my $field = $self->RelevantField();
    # Get the value list from the database.
    my @retVal = $sprout->GetFlat("IsAlsoFoundIn",
                                  "IsAlsoFoundIn(from-link) = ? AND IsAlsoFoundIn(to-link) = ?",
                                  [$fid, $self->{externalDatabase}], "alias");
    # Return the value list.
    return @retVal;
}


1;
