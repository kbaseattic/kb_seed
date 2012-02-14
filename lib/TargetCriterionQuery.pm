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

package TargetCriterionQuery;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterion);

=head1 Code Match Target Search Criterion Object

=head2 Introduction

This is a query-based search criterion object. It serves as the base class for most
search criterion that revolve around the use of a single database field. The constructor
specifies a field name followed by a list of table names. The table name list must
always begin with either C<Feature> or C<Genome>. The subclasses will need to override
most methods, but this object comes with some built-in utilities for manipulating the
path and field name that the various subclasses will find essential.

This object has the following fields in addition to the ones in the base class.

=over 4

=item path

Reference to a list of the objects in the join path required for this query.

=item field

Name of the field containing the data relevant to the query.

=item keyTable

Name of the object containing the relevant field.

=item basic

TRUE if the field is in the B<Genome> or B<Feature> tables, else FALSE.

=item erdbType

[[ERDBTypePm]] object describing the data type of the field.

=item sanity

TRUE if the field is feature-based, else FALSE.

=back

=head3 new

    my $tc = TargetCriterionQuery->new($rhelp, $options, $field => @path);

Construct a new TargetCriterionQuery object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item options

Reference to a hash of constructor options. These match the options on the constructor
for the base class.

=item field

Name of the relevant database field.

=item path

List of entities and relationships forming a path from the C<Genome> or C<Feature> table
to the table containing the database field.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $options, $field, @path) = @_;
    # Construct the underlying object.
    my $retVal = TargetCriterion::new($class, $rhelp, %$options);
    # Compute the keytable. It's the last table in the path.
    my $keyTable = $path[$#path];
    # Compute the path. It is either an empty list or the incoming path.
    my @realPath = ();
    if (scalar(@path) > 1) {
        push @realPath, @path;
    }
    # Save the custom fields.
    $retVal->{path} = \@realPath;
    $retVal->{field} = $field;
    $retVal->{keyTable} = $keyTable;
    $retVal->{basic} = scalar(grep { $_ eq $keyTable } qw(Genome Feature));
    $retVal->{sanity} = ($path[0] eq 'Feature');
    # Compute the ERDB type of the field.
    my $sprout = $rhelp->DB();
    $retVal->{erdbType} = $sprout->FieldType($field, $keyTable);
    # Return the object.
    return $retVal;
}

=head3 Utility Methods

=head3 RelevantField

    my $fieldSpec = $tc->RelevantField();

Return the name, in ERDB format, of the field relevant to this query.

=over 4

=item RETURN

Returns a formatted ERDB-style name for the target field.

=back

=cut

sub RelevantField {
    # Get the parameters.
    my ($self) = @_;
    # Get the key table name.
    my $name = $self->{keyTable};
    # Form the field name.
    my $retVal = "$name($self->{field})";
    # Return the result.
    return $retVal;
}

=head3 JoinList

    my $joins = $tc->JoinList();

Return the join list for this criterion. The join list will be a
reference to an empty list (indicating the field is in the B<Genome> or
B<Feature> table) or a reference to a list that specifies the join path
to get the to table containing the relevant field.

=cut

sub JoinList {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{path};
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
    # Declare the return variable.
    my @retVal;
    # Get the Sprout database.
    my $sprout = $self->DB();
    # Get the key table name.
    my $keyTable = $self->{keyTable};
    # Get the field name.
    my $field = $self->RelevantField();
    # Check to see if this is a basic field.
    if ($self->{basic}) {
        # Yes. Determine the appropriate ID (either Genome or Feature).
        my $thingID = ($keyTable eq 'Genome' ? FIGRules::ParseFeatureID($fid) : $fid);
        # Do the GetFlat.
        @retVal = $sprout->GetFlat($keyTable, "$keyTable(id) = ?", [$thingID], $field);
    } else {
        # Here the field is in a table at the end of a path. Get the path and yank off
        # the starting table.
        my ($startTable, @path) = @{$self->JoinList()};
        # If the start table is Genome, we simply use the HasFeature table to get us to
        # the genome from the feature.
        if ($startTable eq 'Genome') {
            @retVal = $sprout->GetFlat(['HasFeature', @path], "HasFeature(to-link) = ?",
                                       [$fid], $field);
        } else {
            # Here we're starting from the feature table. Determine which field in the
            # starting relationship is the feature field.
            my ($from, $to) = $sprout->GetRelationshipEntities($path[0]);
            my $linkName = ($from eq 'Feature' ? 'from-link' : 'to-link');
            # Build the query.
            @retVal = $sprout->GetFlat(\@path, "$path[0]($linkName) = ?", [$fid],
                                       $field);
        }
    }
    # Return the value list.
    return @retVal;
}

=head3 FormatValueList

    my $html = $self->FormatValueList(\@values);

Format a list of values for the current field. The values are converted
to HTML using the method appropriate to the field type and then joined
together with commas. If the value is a singleton no commas will appear.

=over 4

=item values

Reference to a list of values to format.

=item RETURN

Returns an HTML string with the best possible representation for the field values.

=back

=cut

sub FormatValueList {
    # Get the parameters.
    my ($self, $values) = @_;
    # Get the ERDB type object for this field.
    my $typeData = $self->{erdbType};
    # Use it to convert the values to HTML.
    my @elements = map { $typeData->html($_) } @$values;
    # String them together.
    my $retVal = join(", ", @elements);
    # Return the result.
    return $retVal;
}

=head2 Virtual Methods

=head3 GetValueData

    my $value = $tc->GetValueData($feature);

Return the value data from the specified feature that is relevant to this
criterion. This method is called when the object cache is empty and the
value is needed in order to call L</CheckValue>.

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
    # Declare the return variable.
    my $retVal;
    # Get the field name.
    my $field = $self->RelevantField();
    # Is this a basic field?
    if ($self->{basic}) {
        # Yes. Pull it out of the feature object.
        $retVal = [ $feature->Value($field) ];
    } else {
        # Here we have to read the value from a table at the end of a path. We
        # begin by getting the current feature ID.
        my $fid = $feature->PrimaryValue('Feature(id)');
        # Ask for the field's values.
        $retVal = [ $self->ReadDatabaseValues($fid) ];
    }
    # Return the result.
    return $retVal;
}

=head3 Sane

    my $flag = $tc->Sane($parms);

Return TRUE if this is a sane criterion, else FALSE. Every search must have at least one
sane criterion in order to be valid.

=over 4

=item parms (optional)

The Criterion Parameter Object for the current query.

=item RETURN

Returns TRUE if this query returns a relatively limited result set and uses SQL,
else FALSE. If you do not override this method, it returns TRUE for feature-based
criteria and FALSE for genome-based criteria.

=back

=cut

sub Sane {
    my ($self, $parms) = @_;
    return $self->{sanity};
}

=head3 colName

    my $name = $tc->colName();

Return the column name for this criterion. Normally, the column name is
the same as the label. In some cases, however, we have criterion types
that involve built-in columns. For these, this method should be
overridden so that it returns the built-in column's name.

=cut

sub colName {
    # Get the parameters.
    my ($self) = @_;
    # Get our field's name.
    my $field = $self->RelevantField();
    # Ask the result helper if we're built-in. If we aren't, we return our own name.
    my $retVal = RHFeatures::FieldMap($field) || $self->name();
    # Return the result.
    return $retVal;
}


=head3 DownloadType

    my $dlType = $tc->DownloadType();

Return the download type of this criterion's data column. This will
usually be C<list>, C<num>, or C<text>.

=cut

sub DownloadType {
    # Get the parameters.
    my ($self) = @_;
    # Get the database.
    my $sprout = $self->DB();
    # Get our field's name.
    my $field = $self->RelevantField();
    # If we are keying off a secondary field, or a non-basic field, it's
    # automatically a list. Otherwise, it's numeric or a string.
    my $retVal;
    if (! $self->{basic} || $sprout->IsSecondary($field)) {
        $retVal = 'list';
    } else {
        # Get the field type.
        my $erdbTypeObject = $self->{erdbType};
        if ($erdbTypeObject->numeric()) {
            $retVal = 'num';
        } else {
            $retVal = 'text';
        }
    }
    # Return the result.
    return $retVal;
}

=head3 CacheValue

    my $value = $tc->CacheValue($feature);

Return the value to cache for this criterion with respect to the specified
feature. Normally, this will be an HTML displayable version of the
appropriate value. If the value is immediate;y available, it is
returned; however, if the value is not available at the current time, a
runtime-value request is returned in its place.

=over 4

=item feature

[[ERDBObjectPm]] object containing the data for the current feature.

=item RETURN

Returns the value that should be put in the search result cache file for
this column.

=back

=cut

sub CacheValue {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Declare the return variable.
    my $retVal;
    # We need to determine if we already have the value or not. First, we check
    # the cache.
    if (defined $self->{cache}) {
        # Yes. Format it as HTML.
        $retVal = $self->FormatValueList($self->{cache});
    } else {
        # It's not in the cache, but if it's already in the feature record, we can
        # get it cheaply.
        my $field = $self->RelevantField();
        if ($feature->HasField($field)) {
            $retVal = $self->FormatValueList([ $feature->Value($field) ]);
        } else {
            # Here we have to put it off until runtime.
            my $name = $self->name();
            my $fid = $feature->PrimaryValue('Feature(id)');
            $retVal = "%%$name=$fid";
        }
    } 
    # Return the result.
    return $retVal;
}


=head3 RunTimeValue

    my $runTimeValue = $tc->RunTimeValue($runTimeKey);

Return the run-time value for this column using the specified key. The key
in this case will be the feature ID. The feature ID continas the genome ID
embedded within it.

The way we compute the run-time value depends on where the value can be found.
If it's in the Feature or Genome objects, we simply read it using B<GetFlat>.
Otherwise, we 

=over 4

=item runTimeKey

Key value placed in the search result cache when the need for the desired
value was determined during search processing. This will be the feature
ID.

=item RETURN

Returns the actual value to be used for the specified column.

=back

=cut

sub RunTimeValue {
    # Get the parameters.
    my ($self, $runTimeKey) = @_;
    # Read the values from the database. Note that the run-time key in this case
    # is a feature ID.
    my @values = $self->ReadDatabaseValues($runTimeKey);
    # Format the values for HTML display.
    my $retVal = $self->FormatValueList(\@values);
    # Return the result.
    return $retVal;
}



1;
