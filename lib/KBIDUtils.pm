package KBIDUtils;

    use strict;

=head1 KBase ID Server Utilities

This module defines an object that can be used to request and check
IDs from the KBase ID server.

The object has the following fields.

=over 4

=item server

Handle to the KBase ID server.

=back

=head2 SPECIAL NOTE

The Kbase ID server is not yet operational, so this method generates
temporary IDs.

=head2 Special Methods

=head3 new

    my $kbidObject = KBIDUtiles->new();

Create a new KBase ID server utility object.

=cut

sub new {
    # Get the class name.
    my ($class) = @_;
    # Create the object.
    my $retVal = {
    };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 get_kbase_id

    my $newID = $kbidObject->get_kbase_id($source, $id);

Return the KBase ID for a single foreign identifier from the
specified source database. If the ID does not exist, it will
be created.

=over 4

=item source

Source (core) database from which the identifier is coming.

=item id

Foreign identifier whose KBase ID is desired.

=item RETURN

Returns the KBase identifier for the specified object.

=back

=cut

sub get_kbase_id {
    # Get the parameters.
    my ($self, $source, $id) = @_;
    # Get the KBase ID for the incoming foreign identifier.
    my $idHash = $self->get_kbase_ids($source, [$id]);
    # Return the result.
    return $idHash->{$id};
}

=head3 get_kbase_ids

    my $idHash = $kbidObject->get_kbase_ids($source, \@ids, $noCreate);

Return the KBase ID for one or more foreign identifiers from the
specified source database. Normally, if the IDs do not exist, they
will be created. This behavior can be suppressed, however, by
specifying the optional B<noCreate> parameter.

=over 4

=item source

Source (core) database from which the identifiers are coming.

=item ids

Reference to a list of foreign identifiers whose KBase IDs are needed.

=item noCreate (optional)

If TRUE, then no new IDs will be created. The default is FALSE.

=item RETURN

Returns a reference to a hash mapping each incoming foreign identifier
to its KBase equivalent.

=back

=cut

sub get_kbase_ids {
    # Get the parameters.
    my ($self, $source, $ids, $noCreate) = @_;
    # We make two passes through the data. One asks for IDs already
    # registered, and the last registers new IDs. The results of each
    # pass are put in here.
    my %retVal;
    # Insure the incoming ID is a list.
    if (ref $ids ne 'ARRAY') {
        $ids = [$ids];
    }
    # Ask for the IDs already registered.
    my $oldHash = $self->_get_kb_identifiers($source, $ids);
    # We'll put the IDs we still need to find in here.
    my @needed;
    # Loop through the ID list.
    for my $id (@$ids) {
        # Did we find a registered ID for this one?
        my $oldId = $oldHash->{$id};
        if (defined $oldId) {
            # Yes. Save it.
            $retVal{$id} = $oldId;
        } else {
            # No. We must register this ID.
            push @needed, $id;
        }
    }
    # Is there anything left to find?
    if (@needed && ! $noCreate) {
        # Yes, register the remaining IDs.
        my $newHash = $self->create_kbase_ids($source, \@needed);
        # Add them to the output hash.
        for my $id (keys %$newHash) {
            $retVal{$id} = $newHash->{$id};
        }
    }
    # Return the ID mapping.
    return \%retVal;
}

=head3 create_kbase_ids

    my $idHash = $kbidObject->get_kbase_ids($source, \@ids);

Return the KBase ID for one or more foreign identifiers from the
specified source database. The IDs must not previously exist.

=over 4

=item source

Source (core) database from which the identifiers are coming.

=item ids

Reference to a list of foreign identifiers whose KBase IDs are needed.

=item RETURN

Returns a reference to a hash mapping each incoming foreign identifier
to its new KBase equivalent.

=back

=cut

sub create_kbase_ids {
    # Get the parameters.
    my ($self, $source, $ids) = @_;
    # Ask the ID server for new IDs.
    my $retVal = $self->_register_kb_identifiers($source, $ids);
    # Return the result.
    return $retVal;
}

=head2 Internal Methods

=head3 _get_kb_identifiers

    my $idHash = $kbidObject->_get_kb_identifiers($source, \@ids);

Ask the KBase ID server to return the identifiers already registered
for the specified foreign identifiers from the specified database
source.

=over 4

=item source

Source (core) database from which the identifiers are coming.

=item ids

Reference to a list of foreign identifiers whose KBase IDs are needed.

=item RETURN

Returns a reference to a hash mapping each incoming foreign identifier
to its KBase equivalent. If no KBase equivalent exists, the identifier
will not be present in the return hash.

=back

=cut

sub _get_kb_identifiers {
    # Get the parameters.
    my ($self, $source, $ids) = @_;
    # The stubbed version always returns an empty hash.
    return {};
}

=head3 _register_kb_identifiers

    my $idHash = $kbidObject->_register_kb_identifiers($source, \@ids);

Ask the KBase ID server to create new KBase identifiers for the
specified foreign identifiers from the specified database
source.

=over 4

=item source

Source (core) database from which the identifiers are coming.

=item ids

Reference to a list of foreign identifiers whose KBase IDs are needed.

=item RETURN

Returns a reference to a hash mapping each incoming foreign identifier
to its new KBase equivalent.

=back

=cut

sub _register_kb_identifiers {
    # Get the parameters.
    my ($self, $source, $ids) = @_;
    # The stubbed version simply prefixes "kb|" and the source name to the
    # incoming ID.
    my %retVal = map { $_ => "kb|$source|$_" } @$ids;
    return \%retVal;
}

1;