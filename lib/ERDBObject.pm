package ERDBObject;

    use strict;
    use DBKernel;
    use Tracer;

=head1 Entity-Relationship Database Package Instance Object

=head2 Introduction

This package defines the instance object for the Entity-Relationship Database
Package (L<ERDB>. This object can be created directly, returned by the
C<Fetch> method of the B<ERDBQuery> object, or returned by the C<Cross> method
of this object. An object created directly is considered I<transient>. An object
created by one of the database methods is considered I<persistent>.

An instance object allows the user to access the fields in the current instance.
The instance consists of zero or more entity and/or relationship objects and a
map of field names to locations. Some entity fields require additional queries
to the database. If the entity object is present, the additional queries are
executed automatically. Otherwise, the value is treated as missing.

Each L<ERDBObject> has at least one object called the I<target object>. This
can be specified directly in the constructor or it can be computed implicity
from the query that created the object. This object name is used as the
default when parsing field names.

=head2 Public Methods

=head3 new

    my $dbObject = ERDBObject->new($erdb, $objectName, \%fields);

Create a new transient object. A transient object maps fields to values, but is
not read from  a database. The parameter list should be an entity name
followed by a set of key-value pairs. Each key should be in the
L<ERDB/Standard Field Name Format>.

=over 4

=item erdb

L<ERDB> object for accessing the database. If undefined, the object will
be considered transient.

=item objectName

Default object name that should be used when resolving field name specifiers.
If undefined, no object will be considered the default.

=item fields

Reference to a hash mapping field names to field values. For a multi-valued
field, the value should be a list reference.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $objectName, $fields) = @_;
    # Create the value hash.
    my %values;
    # Loop through the fields.
    for my $fieldName (keys %$fields) {
        # Normalize the field name.
        my $normalizedName = ERDB::ParseFieldName($fieldName, $objectName);
        # Get the field value.
        my $list = $fields->{$fieldName};
        # Convert it to a list. A single-valued field is stored as a singleton
        # list.
        if (ref $list ne 'ARRAY') {
            $list = [$list];
        }
        # Store the field.
        $values{$normalizedName} = $list;
    }
    # Create this object.
    my $retVal = {
                  _db => $erdb,
                  _targetObject => $objectName,
                  _values => \%values,
                  _parsed => {}
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 Attributes

    my @attrNames = $dbObject->Attributes();

This method will return a sorted list of the attributes present in this object.
The list can be used in the L</Values> method to get all the values stored.

If the ERDBObject was created by a database query, the attributes returned will
only be those which occur on the primary relation. Additional fields may get
loaded into the object if the client has asked for them in a L</Value> or
L</Values> command. Initially, however, only the primary fields-- each of which
has one and only one value-- will be found in the attribute list.

=cut
#: Return Type @;
sub Attributes {
    # Get the parameters.
    my ($self) = @_;
    # Get the keys of the value hash.
    my @retVal = sort keys %{$self->{_values}};
    # Return the result.
    return @retVal;
}

=head3 HasField

    my $flag = $dbObject->HasField($fieldSpec);

Return TRUE if this object has the specified field available, else FALSE.
This method can be used to determine if a value is available without
requiring an additional database query.

=over 4

=item fieldSpec

A standard field specifier. See L<ERDB/Standard Field Name Format>. The
default table name is the object's target entity.

=item RETURN

Returns TRUE if there's a value for the field in this object, else FALSE.

=back

=cut

sub HasField {
    # Get the parameters.
    my ($self, $fieldName) = @_;
    # Parse the field name.
    my $normalizedName = ERDB::ParseFieldName($fieldName, $self->{_targetObject});
    # Get the field hash.
    my $fields = $self->{_values};
    # Return the result.
    return exists $fields->{$normalizedName};
}

=head3 AddValues

    $dbObject->AddValues($name, @values);

Add one or more values to a specified field.

=over 4

=item name

Name of the field to receive the new values, in the L<ERDB/Standard Field Name Format>.
If the field does not exist, it will be created.

=item values

List of values to put in the field.

=back

=cut

sub AddValues {
    # Get the parameters.
    my ($self, $name, @values) = @_;
    # Parse the value name.
    my $normalizedName = ERDB::ParseFieldName($name, $self->{_targetObject});
    # Get the field hash.
    my $fields = $self->{_values};
    # Add the new values.
    push @{$fields->{$name}}, @values;
}

=head3 PrimaryValue

    my $value = $dbObject->PrimaryValue($name);

Return the primary value of a field. This will be its first value in a standard
value list.

This method is a more convenient version of L</Value>. Basically, the call

    my ($value) = $dbObject->Value($name);

is equivalent to

    my $value = $dbObject->PrimaryValue($name);

but the latter is syntactically more convenient.

=over 4

=item name

Name of the field whose value is desired, in the L<ERDB/Standard Field Name Format>.

=item RETURN

Returns the value of the specified field, or C<undef> if the field has no value.

=back

=cut

sub PrimaryValue {
    # Get the parameters.
    my ($self, $name) = @_;
    # Get the value.
    my ($retVal) = $self->Value($name);
    # Return it.
    return $retVal;
}

=head3 Value

    my @values = $dbObject->Value($attributeName, $rawFlag);

Return a list of the values for the specified attribute.

=over 4

=item attributeName

Name of the desired attribute, in the L<ERDB/Standard Field Name Format>.

=item rawFlag (optional)

If TRUE, then the data will be returned in raw form, without decoding from the
database format.

=item RETURN

Returns a list of the values for the specified attribute.

=back

=cut

sub Value {
    # Get the parameters.
    my ($self, $attributeName, $rawFlag) = @_;
    # Get the database.
    my $erdb = $self->{_db};
    # Declare the return variable.
    my @retVal = ();
    # Normalize the field name. We keep the normalized name data in a hash so we only
    # need to compute it once per field name.
    my $parsed = $self->{_parsed}->{$attributeName};
    if (!defined($parsed)) {
        $parsed = [ ERDB::ParseFieldName($attributeName, $self->{_targetObject}) ];
        $self->{_parsed}->{$attributeName} = $parsed;
    }
    my($alias, $fieldName) = @$parsed;
    my $normalizedName = "$alias($fieldName)";
    # Insure the field name is valid.
    if (! defined $fieldName) {
        Confess("Invalid field name \"$fieldName\".");
    } else {
        # Look for the field in the values hash.
        my $fieldHash = $self->{_values};
        my $retValRef = $fieldHash->{$normalizedName};
        if (defined $retValRef) {
            # Here we have the field already. Split out the real field name and the value.
            my ($fieldName, $fieldValue) = @$retValRef;
            # Find out if we need to convert.
            if (defined $erdb && ! $rawFlag) {
                # Yes. Map the values to decoded fields.
                @retVal = $erdb->DecodeField($fieldName, $fieldValue);
            } else {
                # No. Copy the value to the output.
                @retVal = $fieldValue;
            }
        } else {
            # Here the field is not in the hash. If we don't have a database, we are
            # done. The user will automatically get an empty list handed back to him.
            if (defined $erdb) {
                # We must first find the field's data structure.
                # If the field name is invalid, this will throw an error.
                my $fieldData = $erdb->_FindField($attributeName, $alias);
                # Insure we have an ID for this entity.
                my $idName = "$alias(id)";
                if (! exists $fieldHash->{$idName}) {
                    Confess("Cannot retrieve a field from \"$alias\": it is not part of this query.");
                } else {
                    # Get the ID value. The field hash points to a list of IDs, but of
                    # course, there is only one, so we just take the first.
                    my $idValue = $fieldHash->{$idName}[1];
                    # We need to encode the ID because we're using it as a query parameter.
                    my $id = $erdb->EncodeField("$alias(id)", $idValue);
                    # Determine the name of the relation that contains this field.
                    my $relationName = $fieldData->{relation};
                    # Compute the actual name of the field in the database.
                    my $fixedFieldName = ERDB::_FixName($fieldName);
                    # Create the SELECT statement for the desired relation and execute it.
                    my $command = "SELECT $fixedFieldName FROM $relationName WHERE id = ?";
                    my $sth = $erdb->_GetStatementHandle($command, [$id]);
                    # Loop through the query results creating a list of the values found.
                    my $rows = $sth->fetchall_arrayref;
                    for my $row (@{$rows}) {
                        # Are we decoding?
                        if ($rawFlag) {
                            # No, stuff the value in the result list unmodified.
                            push @retVal, $row->[0];
                        } else {
                            # Yes, decode it before stuffing.
                            push @retVal, $erdb->DecodeField($normalizedName, $row->[0])
                        }
                    }
                }
            }
        }
    }
    # Return the field values found.
    return @retVal;
}

=head3 Values

    my @values = $dbObject->Values(\@attributeNames);

This method returns a list of all the values for a list of field specifiers.
Essentially, it calls the L</Value> method for each element in the parameter
list and returns a flattened list of all the results.

For example, let us say that C<$feature> contains a feature with two links and a
translation. The following call will put the feature links in C<$link1> and
C<$link2> and the translation in C<$translation>.

    my ($link1, $link2, $translation) = $feature->Values(['Feature(link)', 'Feature(translation)']);

=over 4

=item attributeNames

Reference to a list of attribute names, or a space-delimited string of attribute names.

=item RETURN

Returns a flattened list of all the results found for each specified field.

=back

=cut

sub Values {
    # Get the parameters.
    my ($self, $attributeNames) = @_;
    # Create the return list.
    my @retVal = ();
    # Create the attribute name list.
    my @attributes;
    if (ref $attributeNames eq 'ARRAY') {
        @attributes = @$attributeNames;
    } else {
        @attributes = split /\s+/, $attributeNames;
    }
    # Loop through the specifiers, pushing their values into the return list.
    for my $specifier (@attributes) {
        push @retVal, $self->Value($specifier);
    }
    # Return the resulting list.
    return @retVal;
}

=head2 Internal Methods

=head3 _new

    my $erdbObject = ERDBObject->_new($dbquery, @values);

Create an B<ERDBObject> for the current database row.

=over 4

=item dbquery

L<ERDBQuery> object for the relevant query.

=item RETURN

Returns an B<ERDBObject> that can be used to access fields from this row of data.

=back

=cut

sub _new {
    # Get the parameters.
    my ($class, $dbquery, @values) = @_;
    # Create the field hash.
    my %fh;
    # Get the database.
    my $erdb = $dbquery->{_db};
    # Check for a search relevance field in the results.
    if ($dbquery->{_fullText}) {
        # Create the special search relevance field from the first element of
        # the row values. Note that the object name for this field is the
        # stored in the query object's _fullText property.
        my $relevanceName = "$dbquery->{_fullText}(search-relevance)";
        $fh{$relevanceName} = [shift @values];
    }
    # Loop through the field information array, copying in the field values.
    for my $finfo (@{$dbquery->{_fieldInfo}}) {
        my($fieldName, $extFieldName, $fieldKey) = @$finfo;
        $fh{$fieldKey} = [$extFieldName, shift @values];
    }
    # Create this object.
    my $self = {
        _db => $erdb,
        _targetObject => $dbquery->{_targetObject},
        _values => \%fh,
        _parsed => $dbquery->{_parsed}
    };
    # Bless and return it.
    bless $self, $class;
    return $self;
}

=head3 DB

    my $erdb = $dbObject->DB();

Return the database for this result object.

=cut

sub DB {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{_db};
}

1;
