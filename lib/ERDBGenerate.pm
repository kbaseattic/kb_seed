#!/usr/bin/perl -w

package ERDBGenerate;

    use strict;
    use Tracer;
    use PageBuilder;
    use ERDB;
    use Stats;

=head1 ERDB Table Data Generation Helper Object

=head2 Introduction

This object is designed to assist with creating the load files for an ERDB
data relation (also known as a I<table>).

The generation process can be very long, so each table is loaded a section at a
time, with multiple sections running in parallel. After the load files for each
section are created, a separate process is used to collate the sections and load
them into the database tables.

When the output file is being written, its name is suffixed by a tilde (C<~>) to denote
it is currently being processed. When the L</Finish> method is called, the file is closed
and renamed. If the L</Finish> method is not called, it is presumed that the load has
failed. The tilde will remain in place so that the collater knows the file is invalid.

This object maintains the following data fields.

=over 4

=item directory

Directory into which load files should be placed.

=item erdb

L<ERDB> object used to create and access the database. This will usually
be a subclass of a pure ERDB object created to manage a particular database.

=item fh

Open handle of the current output file (if any).

=item fileName

Name of the current output file (if any).

=item relation

Reference to the descriptor for this table's relation in the ERDB database
object.

=item stats

Statistics object for recording events.

=item table

Name of the relation table being loaded.

=back

=cut

=head3 new

    my $erdbload = ERDBGenerate->new($erdb, $directory, $table, $stats);

Create an ERDB Table Load Utility object for a specified table. Note that
when generating a table, the section ID is required, but for collating
and loading it can be omitted.

=over 4

=item erdb

L<ERDB> object for the database being loaded.

=item directory

Name of the directory into which the load files are to be placed.

=item table

Name of the table being loaded.

=item stats

Statistics object for recording events.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $directory, $table, $stats) = @_;
    # Ask the database for the relation's descriptor.
    my $relation = $erdb->FindRelation($table);
    Confess("Invalid table name \"$table\".") if (! defined $relation);
    # Create the new object.
    my $retVal = {
        directory => $directory,
        erdb => $erdb,
        fh => undef,
        fileName => undef,
        relation => $relation,
        stats => $stats,
        table => $table,
    };
    # Bless and return the result.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 Start

    $erdbload->Start($section);

Initialize for loading the specified section into this loader's table.
This deletes any existing load file for the section and creates a
temporary file into which new data can be placed using L</Put> calls.

=over 4

=item section

ID of the section being loaded.

=back

=cut

sub Start {
    # Get the parameters.
    my ($self, $section) = @_;
    # Compute the output file name.
    my $fileName = CreateFileName($self->{table}, $section, 'data',
                                  $self->{directory});
    # Insure it doesn't already exist.
    unlink $fileName if -e $fileName;
    # Open a temporary file for it.
    my $oh = Open(undef, ">" . TempOf($fileName));
    # Save the name and handle.
    $self->{fh} = $oh;
    $self->{fileName} = $fileName;
    Trace("Starting output to $fileName for section $section and table $self->{table}.") if T(4);
}

=head3 Put

    my $length = $erdbload->Put(%putFields);

Output the specified fields to the currently-active load file. The fields
come in as a hash mapping field names to field values. Fields whose
values are not specified will be set to their default value.

=over 4

=item putFields

A hash mapping field names for this generator's target relation to
field values.

=item RETURN

Returns the number of characters output (excluding delimiters), or zero if
nothing is output (which usually indicates we're discarding a duplicate entity.)

=back

=cut

sub Put {
    # Get the parameters.
    my ($self, %putFields) = @_;
    # We return the number of characters output.
    my $retVal = 0;
    # Get the database object.
    my $erdb = $self->{erdb};
    # Get the descriptor for this relation.
    my $relationTable = $self->{relation};
    # Insure we have an output file to which we can write.
    my $oh = $self->{fh};
    Confess("Put before Start for $self->{table}.") if ! defined $oh;
    # We'll create an ordered list of field values in here.
    my @values;
    # Loop through the relation's fields.
    for my $field (@{$relationTable->{Fields}}) {
        # Get this field's value. We need to consider the possibility the
        # use used underscores instead of hyphens for convenience, so we
        # have to check twice.
        my $name = $field->{name};
        my $value = $putFields{$name};
        if (! defined $value) {
            my $altName = $name;
            $altName =~ tr/-/_/;
            $value = $putFields{$altName};
        }
        # Did we find a value?
        if (! defined $value) {
            # The field has no value, so check for a default.
            $value = $field->{default};
            # If there's no default, we have an error.
            Confess("Missing value for $field->{name} in Put for $self->{table}.")
                if ! defined $value;
        }
        # Push the value into the result list.
        push @values, $value;
        Trace("Field $name in $self->{table} has value \"$value\".") if T(4);
    }
    # Verify and fix the field values.
    $erdb->VerifyFields($self->{table}, \@values);
    $erdb->DigestFields($self->{table}, \@values);
    # Compute the total field length.
    for my $value (@values) {
        $retVal += length("$value");
    }
    # Write the record.
    Tracer::PutLine($oh, \@values);
    # Return the record length.
    return $retVal;
}

=head3 Finish

    $erdbload->Finish();

Finish the load for this table, closing the output file and renaming it
to mark it finished.

=cut

sub Finish {
    # Get the parameters.
    my ($self) = @_;
    # Do standard cleanup. This returns the file name.
    my $fileName = $self->_Cleanup();
    Confess("Finish called before Start for $self->{table}") if ! defined $fileName;
    # Rename the output file so the collator will find it.
    rename TempOf($fileName), $fileName;
}

=head3 Abort

    $erdbload->Abort();

Terminate the load for this table as having failed. The output file is
closed and deleted.

=cut

sub Abort {
    # Get the parameters.
    my ($self) = @_;
    # Do standard cleanup. This returns the file name.
    my $fileName = $self->_Cleanup();
    # Delete the temp file (if it exists).
    if (defined $fileName) {
        my $tempName = TempOf($fileName);
        unlink $tempName if -e $tempName;
    }
}


=head2 File Naming Methods

These methods are used to analyze and generate file names. There are many packages
involved in creating and managing load files. All the file names are generated by
methods in this group so that there is no breakdown of communication should the file
naming conventions change.

Currently, a file name consists of a content name, an optional section
name preceded by a hyphen, and an extension of C<dtx> or C<dty>. A C<dtx> file
contains table data, and its content name will be the same as the relevant table
name. A C<dty> file contains control data. Files with control data
are considered transient, so during post-processing no attempt is made to insure they
are all present or absent. If a control data file is not table-related, the content
name should be in all lower case with underscores, so that it is guaranteed not to
conflict with a table name.

=cut

# This constant maps file name extensions to content types.
use constant FILE_TYPES => { dtx => 'data', dty => 'control', 'dtz' => 'temp' };
# This constant maps content types to file name extensions.
use constant FILE_EXTS =>  { data => 'dtx', control => 'dty', temp => 'dtz' };

=head3 ParseFileName

    my ($content, $section, $type) = ERDBGenerate::ParseFileName($fileName);

Parse a base file name to extract the content name, the section name, and the
file type. If the file is for an entire table (not partial), the section name will
be undefined. If the file does not appear to be a load-related file, all return
values will be undefined. If the file belongs to a particular table, the content
name will be the table name; otherwise, the content name will not correspond to the
name of any table.

=over 4

=item fileName

File name to parse. This should be a base file name with no directory
information in it.

=item RETURN

Returns a three-element list. The first two elements are the content name (which
could be a table name) and the section name (which will be undefined if the
file does not belong to a specific section. The third element will be C<data>
if the file contains table data, C<control> if it contains control or status
data (such as, for example, a saved list of section names), or C<temp> if it is
a temporary file.

=back

=cut

sub ParseFileName {
    # Get the parameters.
    my ($fileName) = @_;
    # Declare the return variables.
    my ($content, $section, $type);
    # Try to parse the file name.
    if ($fileName =~ m#^(\w+)-(.+)\.(dtx|dty)#) {
        # We have a table and a section.
        ($content, $section, $type) = ($1, $2, FILE_TYPES->{$3});
    } elsif ($fileName =~ m#^(\w+)\.(dtx|dty)$#) {
        # Here it's just a table.
        ($content, $type) = ($1, FILE_TYPES->{$2});
    }
    # Return the results.
    return ($content, $section, $type);
}

=head3 CreateFileName

    my $fileName = ERDBGenerate::CreateFileName($content, $section, $type, $dir);

Return a file name for the specified type of operation on the specified
content and optionally the specified section.

=over 4

=item content

File content. This can be a table name or a lower-case phrase describing what's in
the file. In the latter case only letters, digits, and underscores are allowed.

=item section

The section of the data to which the file's content relates, or C<undef> if
the file is for all sections.

=item type

C<data> for a file containing table data, C<control> for a file containing
ancillary or control data, or C<temp> for a file containing temporary data.

=item dir (optional)

If specified, the name of a directory. The directory name will be prefixed to
the file name with an intervening slash.

=item RETURN

Returns a file name suitable for the specified purpose.

=back

=cut

sub CreateFileName {
    # Get the parameters.
    my ($content, $section, $type, $dir) = @_;
    # Format the section portion of the file name.
    my $sectionData = (defined $section && $section ne '' ? "-$section" : '');
    # Assemble it into the file name.
    my $retVal = "$content$sectionData." . FILE_EXTS->{$type};
    # Add the directory, if necessary.
    if (defined $dir) {
        $retVal = "$dir/$retVal";
    }
    # Return the result.
    return $retVal;
}

=head3 GetLoadFiles

    my @files = ERDBGenerate::GetLoadFiles($directory);

Get a list of the names of the load-related files in the specified
directory. Only the base file names are returned, without any path
information. The base names can later be fed to L</ParseFileName> to
determine what is in the file.

=over 4

=item directory

Load directory for the relevant database.

=item RETURN

Returns a list of base file names for load-related files in the specified
directory.

=back

=cut

sub GetLoadFiles {
    # Get the parameters.
    my ($directory) = @_;
    Trace("GetLoadFiles called for $directory.") if T(3);
    # Get matching file names from the specified directory.
    my @retVal = grep { $_ =~ /\.dt[xyz]$/ } Tracer::OpenDir($directory);
    # Return the result.
    return @retVal;
}

=head3 TempOf

    my $fileName = ERDBGenerate::TempOf($fileName);

Return the temporary file name associated with the specified data file
name. There is a one-to-one mapping between the name of a file containing
table data and the corresponding temporary file used during file creation.

=over 4

=item fileName

Name of the table data file to be converted File name to be converted

=item RETURN

Returns the corresponding temporary file name.

=back

=cut

sub TempOf {
    # Get the parameters.
    my ($fileName) = @_;
    # Copy the incoming file name.
    my $retVal = $fileName;
    # Change the last character to 'z'.
    substr($retVal, -1, 1, 'z');
    # Return the result.
    return $retVal;
}

=head2 Internal Utility Methods

=head3 _Cleanup

    my $fileName = $erdbload->_Cleanup();

Release resources held by this object and return the name of the current
output file. This method contains operations common to both L</Abort> and
L</Finish>. If no output file is present, it will return an undefined
value.

=cut

sub _Cleanup {
    # Get the parameters.
    my ($self) = @_;
    # Get the operating file name.
    my $retVal = $self->{fileName};
    # Close the file handle if it's open.
    my $oh = $self->{fh};
    close $oh if defined $oh;
    # Denote we're no longer inside a section.
    for my $field (qw(fh fileName)) {
        $self->{$field} = undef;
    }
    # Return the result.
    return $retVal;
}


1;