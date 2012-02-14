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

package TargetCriterion;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use Sprout;


=head1 Target Search Criterion Object

=head2 Introduction

This object is the base class for all a target search criteria. For a specific
type of criterion, it provides methods that tell [[SHTargetSearchPm]] how to
configure the form, how to generate a query filter, how to check a returned
object to see if it qualifies, and which extra fields should be displayed in the
results. It is also used by [[RHFeaturePm]] to provide additional column support.

It's important to realize that an instance of this object represents a desire to
make a criterion available, not a specific crterion that can be applied to
determine the results of a search. The criterion objects are generated in the
constructor for the target search; the actual cirteria are specified in the form
fields filled out be the user. Thus, there would be a criterion object for
specifying the GC content range, but the criterion object won't know the minimum
and maximum values for the range, just how to deal with those values when the
user enters them.

A criterion in the target search form is implemented as a table row. The first
column of the table contains buttons for adding and deleting rows. The second
column contains the type dropdown. Selecting an entry in the type dropdown tells
the target search which criterion object applies to it. The last column contains
configurable form fields, including a selection control, an min/max control, a
text input control, and a hint control.

This object contains a cache that tracks the value of the current feature as
it relates to the criterion. The user may specify the same criterion more than
once with different filter values, but both will involve the same data about a
feature. For example, a query could ask for features that occur in both the
cytoplasm and the cell wall. This will generate two filter elements
(CellLocation = Cytoplasm AND CellLocation = CellWall) but both will use the
same criterion object. When the first filter element is checked, all of the
cell locations will be read into the cell-location criterion object's cache,
and the cached value is reused when the second filter element is checked.

The fields in this object are as follows.

=over 4

=item rhelp

[[SHTargetSearchPm]] object for the current search

=item hint

Tooltip string for the hint control when the user selects this criterion in the
type dropdown.

=item selectionData

Reference to a hash mapping selection values to labels. The hash is used to
generate the javascript for configuring the selection control. To indicate
a pre-selected value, prefix it with an asterisk. If this field is undefined,
then the selection control is hidden.

=item minMax

TRUE if the min/max control is to be displayed, else FALSE

=item text

TRUE if the text control is to be displayed, else FALSE

=item label

Label for this criterion type in the criterion type dropdown.

=item message

Error message from the most recent validation error.

=item cache

A cache containing the data value for the current feature relevant to this criterion.
This is frequently a list reference. The cache is automatically cleared each time
a new feature is processed by the search helper.

=item name

Name of this criterion.

=back

=cut

=head3 new

    my $tc = TargetCriterion->new($rhelp, %options);

Construct a new TargetCriterion object. The following parameters are expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item options

Hash of constructor options.

=back

The following options are supported.

=over 4

=item minMax

TRUE if the criterion uses the min/max control.

=item text

TRUE if the criterion uses the text control.

=item selectionData

Reference to the I<selectionData> hash, or undefined if the selection control is
not used

=item hint

Tooltip string for the hint control.

=item label

Label to give to this type in the criterion type dropdown.

=item name

Identifying name for this criterion.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, %options) = @_;
    # Get the options.
    my $minMax = $options{minMax} || 0;
    my $text = $options{text} || 0;
    my $selectionData = $options{selectionData};
    my $hint = $options{hint} || 'click for help';
    my $label = $options{label};
    my $name = $options{name};
    # Create the TargetCriterion object.
    my $retVal = {
                    rhelp => $rhelp,
                    hint => $hint,
                    selectionData => $selectionData,
                    minMax => $minMax,
                    text => $text,
                    label => $label,
                    message => '',
                    name => $name,
                    cache => undef,
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 message

    my $message = $tc->message();

Get the error message computed by this object's most recent L</Validate> call.

=cut

sub message {
    my ($self) = @_;
    return $self->{message};
}

=head3 name

    my $name = $tc->name();

Get the identifying name of this criterion.

=cut

sub name {
    my ($self) = @_;
    return $self->{name};
}

=head3 SetMessage

    $tc->SetMessage($newValue);

Store a new error message in this object.

=over 4

=item newValue

New error message to be stored in this object.

=back

=cut

sub SetMessage {
    my ($self, $newValue) = @_;
    $self->{message} = $newValue;
}

=head3 GetMinMax

    my ($min, $max) = $self->GetMinMax($criterion);

Return the minimum and maximum values for the specified criterion.

=over 4

=item criterion

A Criterion Parameter Object containing the minimum and maximum values as parameters.

=item RETURN

Returns a 2-tuple containing the minimum value followed by the maximum value. If
either value is non-numeric, it will be converted to C<undef>.

=back

=cut

sub GetMinMax {
    # Get the parameters.
    my ($self, $criterion) = @_;
    # Declare the return variables.
    my ($min, $max) = map { Tracer::Numeric($criterion->{$_}) } qw(minValue maxValue);
    # Return the results.
    return ($min, $max);
}

=head3 EqualCheck

    my $match = $tc->EqualCheck($feature, $value);

Return TRUE if the specified feature has the specified value for this
criterion's field, else FALSE.

=over 4

=item suffix

The ID number for the criterion.

=item feature

An [[ERDBObjectPm]] containing the relevant Feature record along with its parent
Genome.

=item RETURN

Returns TRUE if the relevant field value for the specified feature matches the
specified value, else FALSE. If there is more than one value for the field.

=back

=cut

sub EqualCheck {
    # Get the parameters.
    my ($self, $suffix, $feature, $value) = @_;
    # Get the relevant field values.
    my $values = $self->GetValue($feature);
    # Compute the number of matching values. If it's one or more, we have a match.
    my $retVal = scalar grep { $_ eq $value } @$values;
    # Return the result.
    return $retVal;
}

=head2 Internal Methods

=head3 Reset

    $tc->Reset();

Denote that a new feature is being processed. This clears the data cache.

=cut

sub Reset {
    # Get the parameters.
    my ($self) = @_;
    # Delete the cache.
    $self->{cache} = undef;
}

=head3 PutExtras

    $tc->PutExtras($rhelp, $feature);

Add any required extra columns for this criterion to the result helper. Note
that this method will only be called if the subclass has overridden
L</AddExtraColumns>.

=over 4

=item rhelp

Result helper to which the extra columns are to be added.

=item feature

[[ERDBObjectPm]] object for the current feature.

=back

=cut

sub PutExtras {
    # Get the parameters.
    my ($self, $rhelp, $feature) = @_;
    # Get the value data object from the cache.
    my $valueData = $self->GetValue($feature);
    # Ask the subclass to add the extra columns.
    $self->PutExtraColumns($rhelp, $valueData);
}

=head3 Check

    my $match = $tc->Check($criterion, $feature);

Return TRUE if the specified feature matches the specified criterion
parameters, else FALSE.

=over 4

=item criterion

A Criterion Parameter Object containing the specific parameter values to check.

=item feature

An [[ERDBObjectPm]] containing the relevant Feature record along with its parent
Genome.

=item RETURN

Returns TRUE if the specified criterion parameters match the specified feature with
respect to this criterion, else FALSE.

=back

=cut

sub Check {
    # Get the parameters.
    my ($self, $criterion, $feature) = @_;
    # Get the cache data for this criterion.
    my $valueData = $self->GetValue($feature);
    # Ask the subclass if we match.
    my $retVal = $self->CheckValue($criterion, $valueData);
    # Return the result.
    return $retVal;
}

=head3 GetValue

    my $value = $tc->GetValue($feature);

Return the value data from the specified feature that is relevant to this
criterion. This method is called when value is needed to call
L</PutExtraColumns> or L</CheckValue>. If the value is not in the cache,
it will call a virtual method to retrieve it from the subclass.

=over 4

=item feature

AN [[ERDBObject]] describing the current feature under consideration.

=item RETURN

A scalar value or reference describing the relevant data for the specified feature.

=back

=cut

sub GetValue {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Check the cache.
    my $retVal = $self->{cache};
    # If it wasn't found, ask for it.
    if (! defined $retVal) {
        $retVal = $self->GetValueData($feature);
        # Cache it for next time.
        $self->{cache} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 label

    my $label = $tc->label();

Return the label for this criterion, for use in the criterion type
dropdown.

=cut

sub label {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal = $self->{label};
    # Insure we have a label.
    if (! defined $retVal) {
        Confess("No label specified for search criterion.");
    }
    # Return the result.
    return $retVal;
}

=head3 hint

    my $hint = $tc->hint();

Return the tooltip hint for this criterion, for use in the hint control.

=cut

sub hint {
    # Get the parameters.
    my ($self) = @_;
    # Return the hint.
    return $self->{hint};
}

=head3 minMax

    my $flag = $tc->minMax();

Return C<true> if the min/max control should be shown for this criterion, else C<false>.
It is worth noting that we're returning the strings C<true> and C<false>, not a PERL
boolean. That is because this function is used in generating javascript.

=cut

sub minMax {
    # Get the parameters.
    my ($self) = @_;
    # Return the hint.
    return ($self->{minMax} ? 'true' : 'false');
}

=head3 text

    my $flag = $tc->text();

Return C<true> if the text control should be shown for this criterion, else C<false>.
It is worth noting that we're returning the strings C<true> and C<false>, not a PERL
boolean. That is because this function is used in generating javascript.

=cut

sub text {
    # Get the parameters.
    my ($self) = @_;
    # Return the hint.
    return ($self->{text} ? 'true' : 'false');
}

=head3 selectionData

    my $hash = $tc->selectionData();

Return the selection data hash for this criterion, or an undefined value if this
criterion doesn't use the selection control.

=cut

sub selectionData {
    # Get the parameters.
    my ($self) = @_;
    # Return the selection hash.
    return $self->{selectionData};
}


=head3 DB

    my $sprout = $tc->DB();

Return the ERDB database object for the relevant database.

=cut

sub DB {
    my ($self) = @_;
    return $self->{rhelp}->DB();
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
    Confess("Pure virtual Validate method called.");
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
    return 0;
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
    # Declare the return variables.
    my ($joins, $filterString, $parms);
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

Returns a scalar containing the value used to determine whether or not the specified
feature will match a criterion of this type. The object can be a list reference, a hash
reference, or a blessed object, so long as the virtual L</PutExtraColumns> and
L</CheckValue> methods understand it.

=back

=cut

sub GetValueData {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Throw an error.
    Confess("Pure virtual method GetValueData called.");
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
    # Declare the return variable.
    my $retVal;
    Confess("Pure virtual method CheckValue called.");
    # Return the result.
    return $retVal;
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
    # Return the result.
    return $self->label();
}

=head3 DownloadType

    my $dlType = $tc->DownloadType();

Return the download type of this criterion's data column. This will
usually be C<list>, C<num>, or C<text>.

=cut

sub DownloadType {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    Confess("Pure virtual DownloadType called.");
    # Return the result.
    return $retVal;
}

=head3 CacheValue

    my $value = $tc->CacheValue($feature);

Return the cache value for this criterion with respect to the specified
feature. Normally, this will be an HTML displayable version of the
appropriate value. If the value is immediately available, it should be
returned; however, if the value is not available at the current time, a
runtime-value request should be returned in its place.

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
    Confess("Pure virtual method CacheValue called.");
    # Return the result.
    return $retVal;
}

=head3 RunTimeValue

    my $runTimeValue = $tc->RunTimeValue($runTimeKey);

Return the run-time value for this column using the specified key.

=over 4

=item runTimeKey

Key value placed in the search result cache when the need for the desired
value was determined during search processing.

=item RETURN

Returns the actual value to be used for the specified column.

=back

=cut

sub RunTimeValue {
    # Get the parameters.
    my ($self, $runTimeKey) = @_;
    # Declare the return variable.
    my $retVal;
    Confess("Pure virtual method RunTimeValue called.");
    # Return the result.
    return $retVal;
}


1;
