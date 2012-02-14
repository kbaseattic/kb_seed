#!/usr/bin/perl -w

package FidCheck;

    require Exporter;
    @ISA = ('Exporter');
    @EXPORT = qw();
    @EXPORT_OK = qw();

    use strict;
    use Tracer;

=head1 Feature ID Checker

=head2 Introduction

This object supports the C<is_deleted_fid> method to determine whether or not
a feature exists in a Sprout or FIG data store. If a FIG data store is used, then
the the C<$fig> object is returned unmodified. In the Sprout case, it will check
to see if the incoming ID is for an existing feature or synonym group. In addition,
it will cache the identified IDs so they don't need to be checked against the
database if the method is called again.

=head2 Public Methods

=head3 new

    my $fidCheck = FidCheck->new($sprout_or_fig);

Construct a new FidCheck object from a specified Sprout, FIG, or SFXlate object.

=over 4

=item sprout_or_fig

A Sprout object that may be used to access the database, or a FIG object that
may be used to access the data store.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $sprout_or_fig) = @_;
    # Declare the return variable.
    my $retVal;
    # Check the object type.
    if (ref($sprout_or_fig) eq 'Sprout') {
        # Here we have a Sprout object.
        $retVal = { db => $sprout_or_fig,
                    cache => { } };
        bless $retVal, $class;
    } elsif (ref($sprout_or_fig) eq 'SFXlate') {
        # Here we have an SFXlate object. We need its internal Sprout object.
        $retVal = { db => $sprout_or_fig->{sprout},
                    cache => { } };
        bless $retVal, $class;
    } else {
        # Return the object unmodified. It already has the required method.
        $retVal = $sprout_or_fig;
    }
    # Return the new object.
    return $retVal;
}

=head3 is_deleted_fid

    my $flag = $fidCheck->is_deleted_fid($fid);

Return TRUE if the specified feature does not exist, else FALSE. A feature exists if it is
in the B<Feature> table or the B<SynonymGroup> table. The synonym groups are not real features,
but they do have similarities, so it's important to

=over 4

=item fid

ID of the feature whose existence is to be checked.

=item RETURN

Returns TRUE if the feature does NOT exist, else FALSE.

=back

=cut

sub is_deleted_fid {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Declare the return flag.
    my $flag;
    # Check the cache.
    my $cache = $self->{cache};
    if (exists $cache->{$fid}) {
        $flag = $cache->{$fid};
        Trace("$flag pulled from cache for $fid.") if T(4);
    } else {
        # Check the incoming ID type.
        if ($fid =~ /^fig\|/i) {
            # Here we have a feature ID. Test for existence of the feature.
            $flag = $self->{db}->Exists('Feature', $fid);
            Trace("$flag pulled from feature table for $fid.") if T(4);
        } else {
            # Here we have a synonym group ID. Test for its existence.
            $flag = $self->{db}->Exists('SynonymGroup', $fid);
            Trace("$flag pulled from synonym grup table for $fid.") if T(4);
        }
        # Cache the result.
        $cache->{$fid} = $flag;
    }
    # Return the result.
    return ! $flag;
}

1;

