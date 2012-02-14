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

#
# This is a SAS component.
#

package KBASE;

    use strict;
    use ERDB;
    use Tracer;
    use SeedUtils;
    use ServerThing;
    use CDMI;

=head1 KBase Server Function Object

This file contains the functions and utilities used by the KBase Server
(B<kbase_server.cgi>). The various methods listed in the sections below
represent function calls direct to the server. These all have a signature
similar to the following.

    my $results = $kbObject->function_name($args);

where C<$kbObject> is an object created by this module,
C<$args> is a parameter structure, and C<function_name> is the KBase
Server function name. The output $results is a scalar, generally a hash
reference, but sometimes a string or a list reference.

=head2 Constructor

Use

    my $kbObject = KBASEserver->new();

to create a new KBase server function object. The server function object
is used to invoke the L</Primary Methods> listed below. See
L<KBASEserver> for more information on how to create this object and the
options available.

=cut

#
# Actually, if you are using KBASE.pm, you should do KBASE->new(), not
# KBASEserver->new(). That comment above is for the benefit of the pod
# doc stuff on how to use KBASEserver that is generated from this file.
#

sub new {
    my ($class, $cdmi) = @_;
    # Create the CMDI database object.
    if (! defined $cdmi) {
        $cdmi = CDMI->new();
    }
    # Create the server object.
    my $retVal = { db => $cdmi };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head1 Primary Methods

=head2 Server Utility Methods

These are general-purpose methods that are used for framework purposes
(L</methods>) or for non-specialized database access.

=head3 methods

    my $methodList =        $sapObject->methods();

Return a reference to a list of the methods allowed on this object.

=cut

use constant METHODS => [qw(
                            select
                            get_entity
                            get_relationship
                            get_path
                        )];

sub methods {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return METHODS;
}

=head3 get_entity

    my $idHash = $kbObject->get_entity(-name => $entityName,
                                       -ids => [$id1, $id2, ...]);

Return one or more entity instances. All fields in the each instance will
be returned in the form of a hash.

=over 4

=item parameter

The parameter should be a reference to a hash with the following keys.

=over 8

=item -name

Name of the entity whose instances are desired.

=item -ids (optional)

Reference to a list of the IDs for the desired entities. If this parameter
is omitted, then all instances of the desired entity will be returned.
(This should be avoided in cases where the number of instances is large.)

=back

=item RETURN

Returns a reference to a hash that maps each entity ID to a sub-hash
that maps field names to field values.  Note that if a field is
multi-valued, its value will be represented as a list reference.

    $idHash = { $id1 => { $field1a => $value1a, $field1b => $value1b, ... },
                $id2 => { $field2a => $value2a, $field2b => $value2b, ... },
                ... };

=back

=cut

sub get_entity {
    # Get the parameters.
    my ($self, $args) = @_;
    # Get the entity name.
    my $name = $args->{-name};
    Confess("No entity name specified for get_entity.") if ! defined $name;
    # Now we need to get the list of entity IDs and use them to create a
    # query filter. If none are specified, we will be doing an unfiltered
    # query. The filter clause and parameters are put in these variables.
    my ($filter, $parms);
    # Get the ID parameter.
    my $ids = $args->{-ids};
    if (! defined $ids) {
        # Here we have an unfiltered query.
        $filter = "";
        $parms = [];
    } elsif (ref $ids eq 'ARRAY') {
        # Here we are asking for multiple entity instances with specific IDs.
        $filter = "$name(id) IN (" . join(", ", map { '?' } @$ids) . ")";
        $parms = $ids;
    } else {
        # Here we have a query for a single instance.
        $filter = "$name(id) = ?";
        $parms = [$ids];
    }
    # Get the data from the database.
    my $hashList = $self->get_path({ -path => $name, -filter => $filter,
            -parms => $parms, -primary => $name });
    # Convert the result to a hash based on the entity ID.
    my %retVal;
    for my $hash (@$hashList) {
        $retVal{$hash->{id}} = $hash;
    }
    # Return the hash.
    return \%retVal;
}

=head3 get_path

    my $hashList = $kbObject->get_path(-path => $objectNames,
                                       -filter => $filter,
                                       -parms => \@parameters,
                                       -idField => $fieldName,
                                       -primary => $objectName);

This is a service method that executes a query and returns the
results in the form of a list of hashes. It is unlikely to be
of any general use; however, it is used to implement several
other methods that are of general use.

=over 4

=item parameter

The parameter should be a reference to a hash with the following keys.

=over 8

=item -path

The object name string listing all the entities and relationships in the
query. See L<ERDB/Object Name List> for more details.

=item -filter (optional)

An L<ERDB> filter string. The default is an unfiltered query.

=item -parms (optional)

Reference to a list of values for the bound parameters in the filter
string. The default is an empty list.

=item -primary (optional)

The name of the primary object. Normally, in the sub-hashes of the
returned result, each field will be represented using the name of the
object that contained the field followed by the field name in
parentheses (e.g. C<Genome(dna-size)>). Fields of the object named
in this parameter will be unqualified, consisting of the field name
by itself (e.g. C<dna-size>).

=back

=item RETURN

Returns a reference to a hash of hashes, keyed by the value of the
ID field. Each subhash maps field names to field values. The field
names for the primary object will be unqualified. All other field
names will be qualified by the object name.

    $hashList = [{ $field1a => $value1a, $field1b => $value1b, ... },
                 { $field2a => $value2a, $field2b => $value2b, ... },
                 ... ];

=back

=cut

sub get_path {
    # Get the parameters.
    my ($self, $args) = @_;
    # Get the KBASE Central Database.
    my $cdmi = $self->{db};
    # Get the main arguments.
    my $path = $args->{-path};
    Confess("No path specified for get_path.") if ! $path;
    my $filter = $args->{-filter} || "";
    my $parms = $args->{-parms} || [];
    Confess("Invalid parameter list specified for get_path.")
        if ref $parms ne 'ARRAY';
    my $primary = $args->{-primary} || "";
    # Declare the return list.
    my @retVal;
    # Execute the query.
    my $query = $cdmi->Get($path, $filter, $parms);
    # Get the query's object map.
    my $objectMap = $query->GetObjectNames();
    # Loop through the entity instances.
    while (my $instance = $query->Fetch()) {
        # This hash will be used to save the field values for this entity
        # instance.
        my %values;
        # Loop through the objects.
        for my $name (keys %$objectMap) {
            # Get this object's real name and its field table.
            my $object = $objectMap->{$name};
            my $fieldH = $cdmi->GetFieldTable($object);
            # Determine whether or not this is the primary object.
            my $primaryFlag = ($object eq $primary);
            # Loop through the fields.
            for my $field (keys %$fieldH) {
                # Compute the full field name and the output key name.
                my $fieldName = "$name($field)";
                my $keyName = ($primaryFlag ? $field : $fieldName);
                # Determine how we will process this field.
                if ($cdmi->IsSecondary($field, $object)) {
                    # This is a secondary field. Store it as a list reference.
                    $values{$keyName} = [ $instance->Value($fieldName) ];
                } else {
                    # This is a primary field. Store it as a scalar.
                    $values{$keyName} = $instance->PrimaryValue($fieldName);
                }
            }
        }
        # Store the hash of field values in the output.
        push @retVal, \%values;
    }
    # Return the list of instances found.
    return \@retVal;
}

=head3 get_relationship

    my $idHash =            $kbObject->get_relationship({
                                -rel => $relationshipName,
                                -ids => [$id1, $id2, ...]
                            });

Return the entity instances on the other side of a relationship.
Use this method to find, for example, all features for a genome,
or all experiments in a probe set.

=over 4

=item parameter

The parameter should be a reference to a hash with the following keys.

=over 8

=item -rel

Name of the relationship to cross. The results will cross the relationship
starting with the from-link and ending on the to-link. To cross the
relationship in the backward direction, use the relationship's converse
name. (For example, use C<Concerns> to start with a publication and
find all of the protein sequences it describes. Use C<IsATopicOf> to
start with a protein sequence and find all the publications about it.)

=item -ids

Reference to a list of IDs for the starting entity instances. For each,
a hash of the related entities will be returned.

=back

=item RETURN

Returns a reference to a hash of lists. Each list contains a hash
that maps field names to field values. The field names for the target
entity will be unqualified. The field names for the relationship will
be qualified by the relationship name.

    $idHash = { $id1 => [{ $field1ax => $value1ax, $field1ay => $value1ay, ... },
                         { $field1bx => $value1bx, $field1by => $value1by, ... },
                         ...],
                $id2 => [{ $field2ax => $value2ax, $field2ay => $value2ay, ... },
                         { $field2bx => $value2bx, $field2by => $value2by, ... },
                         ...],
                ... };

=back

=cut

sub get_relationship {
    # Get the parameters.
    my ($self, $args) = @_;
    # Get the CDMI database.
    my $cdmi = $self->{db};
    # Declare the return hash.
    my %retVal;
    # Get the relationship name.
    my $rel = $args->{-rel};
    Confess("No relationship specified on get_relationship.") if ! $rel;
    # Get the incoming IDs.
    my $ids = ServerThing::GetIdList(-ids => $args);
    # Compute the target entity.
    my $entity = $cdmi->ComputeTargetEntity($rel);
    # Loop through the IDs.
    for my $id (@$ids) {
        # Get the target instances for this source instance.
        my $hashList = $self->get_path({ -path => "$rel $entity",
            -filter => "$rel(from-link) = ?", -parms => [$id],
            -primary => $entity });
        # Store them in the return hash.
        $retVal{$id} = $hashList;
    }
    # Return the result.
    return \%retVal;
}

=head3 select

    my $listList =          $kbObject->select({
                                -path => $objectNameString,
                                -filter => { $field1 => $list1, $field2 => $list2, ... },
                                -fields => [$fieldA, $fieldB, ... ],
                                -limit => $maxRows,
                                -multiples => 'list'
                            });

Query the KBase database. This method allows you to navigate a path
through the database using simplified criteria. The return is a list of
lists, and the criteria are always in the form of lists of possible
values.

=over 4

=item parameter

The parameter should be a reference to a hash with the following keys.

=over 8

=item -path

The object name string listing all the entities and relationships in the
query. See L<ERDB/Object Name List> for more details.

=item -filter (optional)

Reference to a hash that maps field identifiers in
L<ERDB/Standard Field Name Format> to lists of permissible values. A
record matches the filter if the field value matches at least one
element of the list.

=item -fields

Reference to a list of field names in L<ERDB/Standard Field Name Format>.

=item -limit (optional)

Maximum number of rows to return for this query. The default is no limit.

=item -multiples (optional)

Rule for handling field values in the result hashes. The default option
is C<smart>, which maps single-valued fields to scalars and multi-valued
fields to list references. If C<primary> is specified, then all fields
are mapped to scalars-- only the first value of a multi-valued field is
retained. If C<list> is specified, then all fields are mapped to lists.

=back

=item RETURN

Returns a reference to a list of lists. Each sub-list represents a single
record in the result set, and contains the field values in the order the
fields were lists in the C<-fields> parameter. Note that if a field is
multi-valued, it will be represented as a list reference.

    $listList = [[$row1value1, $row1value2, ... ], [$row2value1, $row2value2, ...], ... ];

=back

=cut

sub select {
    # Get the parameters.
    my ($self, $args) = @_;
    # Get the CDMI database.
    my $cdmi = $self->{db};
    # Get the filter hash, the flags, and the limit. All of these
    # are optional.
    my $filter = $args->{-filter} || {};
    my $limit = $args->{-limit} || 0;
    my $multiples = $args->{-multiples} || 'smart';
    # Initialize the return variable.
    my $retVal = [];
    # Get the object name string and the result field list.
    my $objects = $args->{-path};
    my $fields = ServerThing::GetIdList(-fields => $args);
    # Insure the object name list is present.
    if (! $objects) {
        Confess("Object name string not specified.");
    } else {
        # Get the default object name from the object name list.
        my ($defaultObject) = split /\s+/, $objects, 2;
        # We'll build the filter elements and the parameter list in
        # these lists. The filter string will be formed by ANDing
        # together the filter elements.
        my (@filters, @parms);
        # Loop through the filter hash.
        for my $filterField (keys %$filter) {
            # Compute the field type.
            my $fieldType = $cdmi->FieldType($filterField);
            # Get this field's criterion.
            my $criterion = $filter->{$filterField};
            # Insure the criterion exists.
            if (! defined $criterion) {
                Confess("Invalid (missing) criterion for field \"$filterField\".");
            } elsif (ref $criterion ne 'ARRAY') {
                # Here we have a scalar criterion. It is encoded as
                # an equality clause.
                push @parms, $fieldType->encode($criterion);
                push @filters, "$filterField = ?";
            } else {
                # Here we have to deal with multiple field values. We'll
                # stash one question mark per value in this list.
                my @marks;
                # Process the criterion elements.
                for (my $i = 1; $i < scalar @$criterion; $i++) {
                    push @marks, "?";
                    push @parms, $fieldType->encode($criterion->[$i]);
                }
                # Form the filter element from the collected marks.
                push @filters, "$filterField IN (" . join(", ", @marks) . ")";
            }
        }
        # Create the filter string.
        my $filterString = join(" AND ", @filters);
        # Add the limit clause.
        if ($limit > 0) {
            $filterString .= " LIMIT $limit";
        }
        # Run the query.
        my $query = $cdmi->Get($objects, $filterString, \@parms);
        # Loop through the results.
        while (my $record = $query->Fetch()) {
            # Create the result list for this record.
            my @results;
            # Loop through the fields.
            for my $outputField (@$fields) {
                # Get the value.
                my @values = $record->Value($outputField);
                # Process according to the output type.
                if ($multiples eq 'list') {
                    push @results, \@values;
                } elsif ($multiples eq 'primary' || scalar(@values) == 1) {
                    push @results, $values[0];
                } else {
                    push @results, \@values;
                }
            }
            # Add the result list to the output. In first-only mode,
            # we store it; otherwise, we push it in.
            push @$retVal, \@results;
        }
    }
    # Return the result.
    return $retVal;
}


1;
