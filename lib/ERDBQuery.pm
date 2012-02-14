package ERDBQuery;

    use strict;
    use DBKernel;
    use ERDBObject;
    use DBI;
    use Tracer;

=head1 Entity-Relationship Database Package Query Iterator

=head2 Introduction

This package defines the Iteration object for an Entity-Relationship Database. The iteration object
represents a filtered SELECT statement against an Entity-Relationship Database, and provides
methods for getting the appropriate records.

There are two common ways an iteration object can be created. An I<entity iterator> is created when the
client asks for objects of a given entity type. A I<relationship iterator> is created when the
client asks for objects across a relationship starting from a specific entity instance. The
entity iterator returns a single object at each position; the relationship iterator returns two
objects at each position-- one for the target entity, and one for the relationship instance
that connects it to the source entity.

For example, a client could ask for all B<Feature> instances that are marked active. This would
return an entity iterator. Each position in the iteration would consist of a single
B<Feature> instance. From a specific B<Feature> instance, the client could decide to cross the
B<IsLocatedIn> relationship to get all the B<Contig> instances which contain residues that
participate in the feature. This would return a relationship iterator. Each position in the
iterator would contain a single B<IsLocatedIn> instance and a single B<Contig> instance.

At each point in the result set, the iterator returns a B<ERDBObject>. The ERDBObject allows the
client to access the fields of the current entity or relationship instance.

It is also possible to ask for many different objects in a single iterator by chaining long
sequences of entities together by relationships. This is discussed in the documentation for the
B<ERDB> object's C<Get> method.

Finally, objects of this type should never by created directly. Instead, they are created
by the aforementioned C<Get> method and the B<ERDBObject>'s C<Cross> method.

=head2 Public Methods

=head3 Fetch

    my $dbObject = $dbQuery->Fetch();

Retrieve a record from this query. The record returned will be a B<ERDBObject>, which
may represent a single entity instance or a list of entity instances joined by relationships.
The first time this method is called it will return the first result from query. After that it
will continue sequentially. It will return an undefined value if we've reached the end of the
result set.

=cut

use constant FROMTO => { 'from-link' => 'to-link', 'to-link' => 'from-link' };

sub Fetch {
    # Get the parameters;
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    # Do we have a statement handle?
    my $sth = $self->{_sth};
    if (! defined $sth) {
        # No, so we have a prepared statement. Start the query.
        $sth = $self->_Run();
    }
    # Do we have the field information?
    if (! defined $self->{_fieldInfo}) {
        # No. We put together the field information array to help us process
        # the results. Pull out the ERDB object and the relationship map.
        my $erdb = $self->{_db};
        my $relationMap = $self->{_objectNames};
        # Get the metadata.
        my $metadata = $erdb->{_metaData};
        # We put the target object name in here. It's the alias name (position 0)
        # for the first object in the map (also position 0).
        $self->{_targetObject} = $relationMap->[0][0];
        # Loop through the object names, extracting each object's fields. We will
        # strip each field from the value array and add it to the hash table using
        # the field's standard-format name.
        my @field_info;
        for my $mappingTuple (@{$relationMap}) {
            # Get the real object name for this mapped name.
            my ($alias, $objectName, $converseFlag) = @{$mappingTuple};
            # Get the relation descriptor for this object.
            my $relationData = $erdb->FindRelation($objectName);
            # Loop through the field list.
            for my $field (@{$relationData->{Fields}}) {
                # Get the current field's name.
                my $fieldName = $field->{name};
                # If we're converse, swap FROM and TO.
                if ($converseFlag && exists FROMTO->{$fieldName}) {
                    $fieldName = FROMTO->{$fieldName};
                }
                # Add the field's data to the field info list.
                my $fieldKey = "$alias($fieldName)";
                push(@field_info, [$fieldName, "$objectName($fieldName)", $fieldKey]);
            }
        }
        # Save the field information array.
        $self->{_fieldInfo} = \@field_info;
    }
    # Fetch the next row in the query result set.
    my @row = $sth->fetchrow;
    # Check to see if we got any results.
    if (@row == 0) {
        # Here we have no result. If we're at the end of the result set, this is
        # okay, because we'll be returning an undefined value in $retVal. If an
        # error occurred, we need to abort.
        if ($sth->err) {
            # Get the error message from the DBKernel object.
            my $dbh = $self->{_database}->{_dbh};
            my $msg = $dbh->ErrorMessage($sth);
            # Throw an error with it.
            Confess($msg);
        } else {
            # Trace the number of results returned.
            Trace("$self->{_results} rows processed by query.") if T(SQL => 4);
        }
    } else {
        # Here we have a result, so we need to turn it into an instance object.
        $retVal = ERDBObject->_new($self, @row);
        # Count this result.
        $self->{_results}++;
    }
    # Return the result.
    return $retVal;
}

=head3 DefaultObjectName

    my $objectName = $query->DefaultObjectName();

Return the name of this query's default entity or relationship.

=cut

sub DefaultObjectName {
    # Get the parameters.
    my ($self) = @_;
    # Get the relation map.
    my $map = $self->{_objectNames};
    # Get the default object alias. This is always the first alias in the
    # relation map.
    my $retVal = $map->[0][0];
    # Return the result.
    return $retVal;
}


=head3 AnalyzeFieldName

    my ($objectName, $fieldName, $type) = $query->AnalyzeFieldName($name);

Analyze a field name (such as might be found in a L<ERDB/GetAll>
parameter list) and return the real name of the relevant entity or
relationship, the field name itself, and the associated type object
(which will be a subclass of L<ERDBType>).

=over 4

=item name

Field name to examine, in the standard field name format used by L<ERDB>.

=item RETURN

Returns a 3-tuple containing the name of the object containing the field, the
base field name, and a type object describing the field's type.

=back

=cut

sub AnalyzeFieldName {
    # Get the parameters.
    my ($self, $name) = @_;
    # Attempt to find the field's data.
    my ($objectName, $fieldName, $type) = $self->CheckFieldName($name);
    # Process errors.
    if (! defined $objectName) {
        Confess("Field identifier \"$name\" has an invalid format.");
    } elsif (! defined $fieldName) {
        Confess("Object name \"$objectName\" not found in query.");
    } elsif (! defined $type) {
        Confess("Field name \"$fieldName\" not found in \"$objectName\".");
    }
    # Return the results.
    return ($objectName, $fieldName, $type);
}


=head3 CheckFieldName

    my ($objectName, $fieldName, $type) = $query->CheckFieldName($name);

Analyze a field name (such as might be found in a L<ERDB/GetAll>.
parameter list) and return the real name of the relevant entity or
relationship, the field name itself, and the associated type object
(which will be a subclass of L<ERDBType>. Unlike L</AnalyzeFieldName>,
this method always returns results. If the field name is invalid, one
or more of the three results will be undefined.

=over 4

=item name

Field name to examine, in the standard field name format used by L<ERDB>.

=item RETURN

Returns a 3-tuple containing the name of the object containing the field, the
base field name, and a type object describing the field's type. If the field
descriptor is invalid, the returned object name will be undefined. If the object
name is invalid, the returned field name will be undefined, and if the field
name is invalid, the returned type will be undefined.

=back

=cut

sub CheckFieldName {
    # Get the parameters.
    my ($self, $name) = @_;
    # Declare the return variables.
    my ($objectName, $fieldName, $type);
    # Get the relation map.
    my $map = $self->{_objectNames};
    # Get the default object alias. This is always the first alias in the
    # relation map.
    my $defaultName = $map->[0][0];
    # Parse the field name.
    my ($alias, $fieldThing) = ERDB::ParseFieldName($name, $defaultName);
    # Only proceed if we could successfully parse the field. If we couldn't,
    # everything will be going back undefined.
    if (defined $alias) {
        # Find the alias in the relation map.
        my ($aliasTuple) = grep { $_->[0] eq $alias } @$map;
        if (! defined $aliasTuple) {
            # We have a bad object name, so the object name is all
            # we return.
            $objectName = $alias;
        } else {
            # Get the real object name.
            $objectName = $aliasTuple->[1];
            # Now it's safe to return the field name.
            $fieldName = $fieldThing;
            # Ask the database for the field descriptor. If the field name is
            # invalid, this will throw an error.
            my $fieldData = $self->{_db}->_CheckField($objectName, $fieldName);
            # Only proceed if the field exists.
            if (defined $fieldData) {
                # Extract the field type.
                my $typeName = $fieldData->{type};
                # Get the corresponding type object.
                $type = ERDB::GetDataTypes()->{$typeName};
            }
        }
    }
    # Return the results.
    return ($objectName, $fieldName, $type);
}

=head3 GetObjectNames

    my $nameHash = $query->GetObjectNames();

Return a hash that maps the name of each object in this query to its
actual name in the database.

=cut

sub GetObjectNames {
    # Get the parameters.
    my ($self) = @_;
    # Extract the relation map.
    my $relationMap = $self->{_objectNames};
    # Convert it to a hash.
    my %retVal;
    for my $tuple (@$relationMap) {
        my ($label, $object) = @$tuple;
        $retVal{$label} = $object;
    }
    # Return the result.
    return \%retVal;
}

=head2 Internal Methods

=head3 _new

    my $query = ERDBQuery->new($database, $sth, $relationMap, $searchObject);

Create a new query object.

=over 4

=item database

ERDB object for the relevant database.

=item sth

Statement handle for the SELECT clause generated by the query.

=item relationMap

Reference to a list of 2-tuples. Each tuple consists of an object name as used
in the query followed by the actual name of that object. This enables the
B<ERDBObject> to determine the order of the tables in the query and which object
name belongs to each mapped object name. Most of the time these two values are
the same; however, if a relation occurs twice in the query, the relation name in
the field list and WHERE clause will use a mapped name (generally the actual
relation name with a numeric suffix) that does not match the actual relation
name.

=item searchObject (optional)

If specified, then the query is a full-text search, and the first field will be a
relevance indicator for the named table.

=back

=cut

sub _new {
    # Get the parameters.
    my ($database, $sth, $relationMap, $searchObject) = @_;
    # Create this object.
    my $self = { _db => $database, _sth => $sth, _objectNames => $relationMap,
                 _fullText => $searchObject, _results => 0, _parsed => {} };
    # Bless and return it.
    bless $self;
    return $self;
}

=head3 _Prepare

    $query->_Prepare($command, $parms);

Cache the SQL command and parameter list for this query. The information
can be used to run the query at a future point.

=over 4

=item command

SQL command to execute for this query.

=item parms

Parameters to feed to the query.

=back

=cut

sub _Prepare {
    # Get the parameters.
    my ($self, $command, $parms) = @_;
    # Stash the SQL command and the parameters.
    $self->{_sql} = $command;
    $self->{_parms} = $parms;
}

=head3 _Run

    $query->_Run();

Run this query. This method is used the first time Fetch is called
on a prepared query.

=cut

sub _Run {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the database object and the SQL command.
    my $erdb = $self->{_db};
    my $command = $self->{_sql};
    # Insure both are valid.
    if (! defined $erdb) {
        Confess("No database available to run this query.");
    } elsif (! defined $command) {
        Confess("Attempt to get results from an unprepared query.");
    } else {
        # Get the parameters. If there are no parameters, we use an empty list.
        my $parms = $self->{_parms} || [];
        # Create the statement handle and run the query.
        $retVal = $erdb->_GetStatementHandle($command, $parms);
        # Save the statement handle for Fetch to use.
        $self->{_sth} = $retVal;
    }
    # Return it.
    return $retVal;
}


1;
