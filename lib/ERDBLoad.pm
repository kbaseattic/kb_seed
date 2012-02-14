#!/usr/bin/perl -w

package ERDBLoad;

    use strict;
    use Tracer;
    use PageBuilder;
    use ERDB;
    use Stats;

=head1 ERDB Table Load Utility Object

=head2 Introduction

This object is designed to assist with creating the load file for an ERDB
data relation. The user constructs the object by specifying an ERDB object
and a relation name. This create the load file for the relevant relation. The client
then passes in data lines which are written to a file, and calls
L</Finish> to close the file and get the statistics.

This module makes use of the internal ERDB method C<_IsPrimary>.

=cut

#

=head2 Public Methods

=head3 new

    my $erload = ERDBLoad->new($erdb, $relationName, $directory, $loadOnly, $ignore);

Begin loading an ERDB relation.

=over 4

=item erdb

ERDB object representing the target database.

=item relationName

Name of the relation being loaded.

=item directory

Name of the directory to use for the load files, WITHOUT a trailing slash.

=item loadOnly

TRUE if the data is to be loaded from an existing file, FALSE if a file is
to be created.

=item ignore

TRUE if the data is to be discarded. This is used to save time when only
a subset of the tables need to be loaded: the data for the ignored tables
is simply discarded.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $relationName, $directory, $loadOnly, $ignore) = @_;
    # Validate the directory name.
    if (! -d $directory) {
        Confess("Load directory \"$directory\" not found.");
    }
    # Determine the name for this relation's load file.
    my $fileName = "$directory/$relationName.dtx";
    # Declare the file handle variable.
    my $fileHandle;
    # Determine whether or not this is a simply keyed relation. For a simply keyed
    # relation, we can determine at run time if it is pre-sorted, and if so, skip
    # the sort step.
    my $sortString = $erdb->SortNeeded($relationName);
    # Get all of the key specifiers in the sort string.
    my @specs = grep { $_ =~ /-k\S+/ } split /\s+/, $sortString;
    # We are pre-sortable if the key is a single, non-numeric field at the beginning. If
    # we are pre-sortable, we'll check each incoming key and skip the sort step if the
    # keys are already in the correct order.
    my $preSortable = (scalar(@specs) == 1 && $specs[0] eq "-k1,1");
    # Check to see if this is a load-only, ignore, or a generate-and-load.
    if ($ignore) {
        Trace("Relation $relationName will be ignored.") if T(2);
        $fileHandle = "";
    } elsif ($loadOnly) {
        Trace("Relation $relationName will be loaded from $fileName.") if T(2);
        $fileHandle = "";
    } else {
        # Compute the file namefor this relation. We will build a file on
        # disk and then sort it into the real file when we're done.
        my $fileString = ">$fileName.tmp";
        # Open the output file and remember its handle.
        $fileHandle = Open(undef, $fileString);
        Trace("Relation $relationName load file created.") if T(2);
    }
    # Create the $erload object.
    my $retVal = {
                  dbh => $erdb,
                  fh => $fileHandle,
                  fileName => $fileName,
                  relName => $relationName,
                  fileSize => 0,
                  lineCount => 0,
                  stats => Stats->new(),
                  presorted => $preSortable,
                  ignore => ($ignore ? 1 : 0),
                  sortString => $sortString,
                  presorted => $preSortable,
                  lastKey => ""
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 Ignore

    my $flag = $erload->Ignore;

Return TRUE if we are ignoring this table, else FALSE.

=cut
#: Return Type $;
sub Ignore {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{ignore};
}

=head3 Put

    my  = $erload->Put($field1, $field2, ..., $fieldN);

Write a line of data to the load file. This may also cause the load file to be closed
and data read into the table.

=over 4

=item field1, field2, ..., fieldN

List of field values to be put into the data line. The field values must be in the
order determined shown in the documentation for the table. Internal tabs and
new-lines will automatically be escaped before the data line is formatted.

=back

=cut
#: Return Type ;
sub Put {
    # Get the ERDBLoad instance and the field list.
    my ($self, @rawFields) = @_;
    # Only proceed if we're not ignoring.
    if (! $self->{ignore}) {
        # Convert the hash-string fields to their digested value.
        $self->{dbh}->DigestFields($self->{relName}, \@rawFields);
        # Insure the field values are okay.
        my $truncates = $self->{dbh}->VerifyFields($self->{relName}, \@rawFields);
        # Run through the list of field values, escaping them.
        my @fields = map { Tracer::Escape($_) } @rawFields;
        # Form a data line from the fields.
        my $line = join("\t", @fields) . "\n";
        # Write the new record to the load file.
        my $fh = $self->{fh};
        print $fh $line;
        # Determine how long this will make the load file.
        my $lineLength = length $line;
        # Check to see if we're still pre-sorted.
        if ($self->{presorted}) {
            if ($fields[0] lt $self->{lastKey}) {
                # This key is out of order, so we're not pre-sorded any more.
                $self->{presorted} = 0;
            } else {
                # We're still pre-sorted, so save this key.
                $self->{lastKey} = $fields[0];
            }
        }
        # Update the statistics.
        $self->{fileSize} += $lineLength;
        $self->{lineCount} ++;
        $self->Add("lineOut");
        if ($truncates > 0) {
            $self->Add("truncated", $truncates);
        }
    }
}

=head3 Add

    my  = $stats->Add($statName, $value);

Increment the specified statistic.

=over 4

=item statName

Name of the statistic to increment.

=item value (optional)

Value by which to increment it. If omitted, C<1> is assumed.

=back

=cut
#: Return Type ;
sub Add {
    # Get the parameters.
    my ($self, $statName, $value) = @_;
    # Fix the value.
    if (! defined $value) {
        $value = 1;
    }
    # Increment the statistic.
    $self->{stats}->Add($statName, $value);
}

=head3 Finish

    my $stats = $erload->Finish();

Finish loading the table. This closes and sorts the load file.

=over 4

=item RETURN

Returns a statistics object describing what happened during the load and containing any
error messages.

=back

=cut

sub Finish {
    # Get this object instance.
    my ($self) = @_;
    if ($self->{fh}) {
        # Close the load file.
        close $self->{fh};
        # Get the ERDB object.
        my $erdb = $self->{dbh};
        # Get the output file name.
        my $fileName = $self->{fileName};
        # Do we need a sort?
        if ($self->{presorted}) {
            # No, so just rename the file.
            Trace("$fileName is pre-sorted.") if T(3);
            unlink $fileName;
            rename "$fileName.tmp", $fileName;
        } else {
            # Get the sort command for this relation.
            my $sortCommand = $erdb->SortNeeded($self->{relName});
            Trace("Sorting into $fileName with command: $sortCommand") if T(3);
            # Set up a timer.
            my $start = time();
            # Execute the sort command and save the error output.
            my @messages = `$sortCommand 2>&1 1>$fileName <$fileName.tmp`;
            # Record the time spent
            $self->{stats}->Add(sortTime => (time() - $start));
            # If there was no error, delete the temp file.
            if (! scalar(@messages)) {
                unlink "$fileName.tmp";
            } else {
                # Here there was an error.
                Confess("Error messages from $sortCommand:\n" . join("\n", @messages));
            }
        }
        # Tell the user we're done.
        Trace("Load file $fileName created.") if T(3);
    }
    # Return the statistics object.
    return $self->{stats};
}

=head3 FinishAndLoad

    my $stats = $erload->FinishAndLoad();

Finish the load and load the table, returning the statistics.

=cut

sub FinishAndLoad {
    # Get the parameters.
    my ($self) = @_;
    # Finish the load file.
    my $retVal = $self->Finish();
    # Load the table.
    my $newStats = $self->LoadTable();
    # Accumulate the stats.
    $retVal->Accumulate($newStats);
    # Return the result.
    return $retVal;
}

=head3 RelName

    my $name = $erload->RelName;

Name of the relation being loaded by this object.

=cut

sub RelName {
    # Get the object instance.
    my ($self) = @_;
    # Return the relation name.
    return $self->{relName};
}

=head3 LoadTable

    my $stats = $erload->LoadTable();

Load the database table from the load file and return a statistics object.

=cut

sub LoadTable {
    # Get the parameters.
    my ($self) = @_;
    # Get the database object, the file name, and the relation name.
    my $erdb = $self->{dbh};
    my $fileName = $self->{fileName};
    my $relName = $self->{relName};
    # Load the table. The third parameter indicates this is a drop and reload.
    my $retVal = $erdb->LoadTable($fileName, $relName, truncate => 1);
    # Return the result.
    return $retVal;
}

1;

