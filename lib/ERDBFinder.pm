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

package ERDBFinder;

    use strict;
    use Tracer;
    use ERDB;
    use Data::Dumper;


=head1 ERDBFinder Package

=head2 Introduction

This object is used to convert a list of criteria to a list of database objects.
The objects returned will all be of the same type, and it must be an entity type.

The criteria are coded as n-tuples. Each n-tuple consists of a logical
operator (C<AND> or C<NOT>), a criterion name, and zero or more parameter
values.

The criterion names are interpreted by a hash that is passed in to the object
constructor. For each criterion name, the hash specifies an I<object name string>
and a I<filter string>. The type of the desired entity objects is put in front of the
object name string, and the object name string, filter string, and criteria parameters
are all passed into the L<ERDB/Get> function to return the desired objects. For
example, consider a search for C<Feature> objects, and we want to be able to search
on EC number. The criterion definition for C<EC number> would be something like this:

  'EC number' => { objects => 'IsRoleOf HasRoleEC',
                   filter  => 'HasRoleEC(to-link) = ?' }

If the incoming criteria tuple is

    ['EC number', '2.7.6.3']

then the ultimate C<Get> call is

    $erdb->Get('Feature IsRoleOf HasRoleEC', 'HasRoleEC(to-link) = ?', ['2.7.6.3']);

Since we are looking for features, C<Feature> is automatically put at the beginning of
the object name list.

=head2 Object Definition

The fields in this object are as follows.

=over 4

=item entityType

The type of entity being sought by this finder object (e.g. C<Feature>, C<Subsystem>).

=item erdb

L<ERDB> database object to be used to get the data.

=item fieldHash

Reference to a hash keyed on incoming field name. For each field, the value is a
sub-hash with two string fields: C<objects> contains the object name string and
C<filter> contains the filter clause string. The object name string and the
filter clause string are combined with incoming parameters to create an
L<ERDB/Get> query that returns the desired objects.

=back

=cut

=head3 new

    my $ff = ERDBFinder->new($erdb, $entityType, \%fieldHash);

Construct a new ERDBFinder object for the specified database.

=over 4

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $entityType, $fieldHash) = @_;
    # Create the ERDBFinder object.
    my $retVal = {
                    entityType => $entityType,
                    erdb => $erdb,
                    fieldHash => $fieldHash,
                 };
    Trace("Criterion hash:\n" . Data::Dumper::Dumper($fieldHash)) if T(4);
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 Find

    my %results = $ff->Find($criteria);

Use the incoming criteria to return a hash of L<ERDBObject> objects
for the desired data.

=over 4

=item criteria

A reference to a list of search criteria. Each element in the list is an n-tuple
consisting of a logical operator (C<AND> or C<NOT>), a criterion name that
matches one of the keys of the field hash passed to the constructor, and zero
or more parameter values. Criteria used to form the result set are removed from
the list, so when the method returns, any unrecognized criteria will still be
present, and can be processed separately.

=item RETURN

Returns a hash of L<ERDBObject> objects for this finder's entity type, keyed
on the entity ID. All of the objects must satisfy the incoming criteria.

=back

=cut

sub Find {
    # Get the parameters.
    my ($self, $criteria) = @_;
    # Create the return hash.
    my %retVal = ();
    Trace("ERDBFinder now finding.") if T(3);
    # Form a query out of as many criteria as we can.
    my $found = $self->PeelQuery($criteria, \%retVal);
    # Keep performing queries until we run out of criteria or we get an empty set.
    while ($found && scalar(keys %retVal)) {
        # Create a buffer for the results of the next query.
        my %buffer;
        # Perform the query.
        $found = $self->PeelQuery($criteria, \%buffer);
        # If we found criteria we could use, merge in the new values found.
        if ($found) {
            # This is an AND merge. We get all the keys in the current hash
            # and delete any that are NOT found in the buffer hash.
            my @old = keys %retVal;
            for my $oldKey (@old) {
                if (! exists $buffer{$oldKey}) {
                    delete $retVal{$oldKey};
                }
            }
        }
    }
    # Return the found objects.
    return %retVal;
}

=head3 PeelQuery

    my $found = $ff->PeelQuery($criteria, \%buffer);

Use as many criteria as possible to create a query and store the results
in the specified buffer. This method returns TRUE if a query was executed
and FALSE otherwise. It can therefore be called repeatedly until it
returns FALSE and the results merged by the calling process.

=over 4

=item criteria

A reference to a list of search criteria. Each element in the list is an n-tuple
consisting of a logical operator (C<AND> or C<NOT>), a criterion name that
matches one of the keys of the field hash passed to the constructor, and zero
or more parameter values. Criteria used to form the result set are removed from
the list, so when the method returns, any unrecognized criteria will still be
present, and can be processed separately.

=item buffer

A hash into which the results of the query will be stored. The hash will be keyed
on object ID and the value will be an L<ERDBObject> object for the entity of this
finder's target type with the specified ID.

=item RETURN

Returns TRUE if at least one criterion was used to make a query, else FALSE.

=back

=cut

sub PeelQuery {
    # Get the parameters.
    my ($self, $criteria, $buffer) = @_;
    Trace("Incoming criteria are\n" . Data::Dumper::Dumper($criteria)) if T(4);
    # Declare the return variable. We'll set it to TRUE if we find a criterion.
    my $retVal = 0;
    # We need to accumulate a filter clause list and a parameter list for
    # the eventual query.
    my @filters;
    my @parms;
    # We also need an object name string. This begins with the target entity type name.
    my $objectNames = $self->{entityType};
    # Now we loop through the criterion list. We'll save the criteria we don't use in
    # this list.
    my @saved;
    # it, or skip it.
    my $entry;
    while (defined($entry = pop @$criteria)) {
        # Grab the criterion data.
        my ($operator, $fieldName, @newParms) = @$entry;
        Trace("Processing \"$fieldName\" for $operator.") if T(3);
        # Skip operators we don't understand.
        if ($operator ne 'AND' && $operator ne 'NOT') {
            push @saved, $entry;
        } else {
            # Look for this field name in the field hash.
            my $fieldDescriptor = $self->{fieldHash}->{$fieldName};
            # Skip this criterion if we didn't find it.
            if (! $fieldDescriptor) {
                push @saved, $entry;
            } else {
                # We found it. Check to see if the object name list is compatible. This
                # can happen in three ways: (1) the list of names is already present, (2) the
                # list of names is empty, OR the last name in the list is a relationship
                # with the target entity type as a FROM or a TO. First, we need to get
                # the data from the descriptor.
                my $newObjectNames = $fieldDescriptor->{objects} || "";
                my $newFilterClause = $fieldDescriptor->{filter};
                Trace("New object name string is \"$newObjectNames\".") if T(4);
                # Before we go too far, we need to do an error check. Does the number of
                # parameter marks match the number of parameters?
                my $markCount = grep { $_ eq '?' } split /(\?)/, $newFilterClause;
                Confess("Invalid parameter specification for $fieldName.")
                    if ($markCount ne scalar(@newParms));
                # Now we check for our three possibilities. We'll set this flag to TRUE
                # if we want to use this criterion.
                my $okToUse = 0;
                if (! $newObjectNames || index($objectNames, $newObjectNames) >= 0) {
                    # Here we have an easy case. We can use the criterion without modifying
                    # the object name string.
                    $okToUse = 1;
                } else {
                    # Here we have a more complicated case. We need to know if we can add the object name list
                    # to the current list. Get the name of the last object in the list. There must always
                    # be at least one, because we prime it with the target type.
                    $objectNames =~ /(\S+)$/;
                    my $lastGuy = $1;
                    if ($lastGuy eq $self->{entityType}) {
                        # Here we're okay, because the last thing in the list is our target.
                        $okToUse = 1;
                    } elsif (grep { $_ eq $self->{entityType} } $self->{erdb}->GetRelationshipEntities($lastGuy)) {
                        # Here we're okay as well.
                        $okToUse = 1;
                    }
                    # Are we going to be able to use this criterion?
                    if ($okToUse) {
                        # Yes. Add our new object names to the object name string.
                        $objectNames .= " $newObjectNames";
                        Trace("Updated object name string is \"$objectNames\".") if T(4);
                    }
                }
                # Now we know whether or not we can use this criterion.
                if (! $okToUse) {
                    # We can't, so skip it.
                    push @saved, $entry;
                } else {
                    # Now we must add the filter clause for this criterion.
                    if ($operator eq 'NOT') {
                        $newFilterClause = "NOT ($newFilterClause)";
                    }
                    push @filters, "($newFilterClause)";
                    push @parms, @newParms;
                    # Denote we've found at least one criterion.
                    $retVal = 1;
                }
            }
        }
    }
    # Can we make a query?
    if ($retVal) {
        # Yes. Organize the filter strings.
        my $filter = join(" AND ", @filters);
        Trace("Filter = \"$filter\" with " . scalar(@parms) . " parameters.") if T(3);
        my $query = $self->{erdb}->Get($objectNames, join(" AND ", @filters), \@parms);
        # Loop through the results, storing them in the return hash by ID.
        while (my $object = $query->Fetch()) {
            my $id = $object->PrimaryValue("$self->{entityType}(id)");
            $buffer->{$id} = $object;
        }
    }
    # Return the result.
    return $retVal;
}


1;
