#!/usr/bin/perl -w

package CustomAttributes;

    use strict;
    use Tracer;
    use Stats;
    use Time::HiRes qw(time);
    use FIGRules;
    use base qw(ERDB);

=head1 Custom SEED Attribute Manager

=head2 Introduction

The Custom SEED Attributes Manager allows the user to upload and retrieve
custom data for SEED objects. It uses the B<ERDB> database system to
store the attributes.

Attributes are organized by I<attribute key>. Attribute values are
assigned to I<objects>. In the real world, objects have types and IDs;
however, to the attribute database only the ID matters. This will create
a problem if we have a single ID that applies to two objects of different
types, but it is more consistent with the original attribute implementation
in the SEED (which this implementation replaces).

The actual attribute values are stored as a relationship between the attribute
keys and the objects. There can be multiple values for a single key/object pair.

=head3 Object IDs

The object ID is normally represented as

    I<type>:I<id>

where I<type> is the object type (C<Role>, C<Coupling>, etc.) and I<id> is
the actual object ID. Note that the object type must consist of only upper- and
lower-case letters! Thus, C<GenomeGroup> is a valid object type, but
C<genome_group> is not. Given that restriction, the object ID

    Family:aclame|cluster10

would represent the FIG family C<aclame|cluster10>. For historical reasons,
there are three exceptions: subsystems, genomes, and features do not need
a type. So, for PEG 3361 of Streptomyces coelicolor A3(2), you simply code

    fig|100226.1.peg.3361

The methods L</ParseID> and L</FormID> can be used to make this all seem
more consistent. Given any object ID string, L</ParseID> will convert it to an
object type and ID, and given any object type and ID, L</FormID> will
convert it to an object ID string. The attribute database is pretty
freewheeling about what it will allow for an ID; however, for best
results, the type should match an entity type from a Sprout genetics
database. If this rule is followed, then the database object
corresponding to an ID in the attribute database could be retrieved using
L</GetTargetObject> method.

    my $object = CustomAttributes::GetTargetObject($sprout, $idValue);

=head3 Retrieval and Logging

The full suite of ERDB retrieval capabilities is provided. In addition,
custom methods are provided specific to this application. To get all
the values of the attribute C<essential> in a specified B<Feature>, you
would code

    my @values = $attrDB->GetAttributes($fid, 'essential');

where I<$fid> contains the ID of the desired feature.

Keys can be split into two pieces using the splitter value defined in the
constructor (the default is C<::>). The first piece of the key is called
the I<real key>. This portion of the key must be defined using the
web interface (C<Attributes.cgi>). The second portion of the key is called
the I<sub key>, and can take any value.

Major attribute activity is recorded in a log (C<attributes.log>) in the
C<$FIG_Config::var> directory. The log reports the user name, time, and
the details of the operation. The user name will almost always be unknown,
the exception being when it is specified in this object's constructor
(see L</new>).

=head2 FIG_Config Parameters

The following configuration parameters are used to manage custom attributes.
Most of these parameters have reasonable defaults. The exceptions is
C<attrHost>. The appropriate host is currently the annotator seed.

=over 4

=item attrDbms

Type of database manager used: C<mysql> for MySQL or C<pg> for PostGres.

=item attrDbName

Name of the attribute database.

=item attrHost

Name of the host server for the database. If omitted, the current host
is used.

=item attrUser

User name for logging in to the database.

=item attrPass

Password for logging in to the database.

=item attrPort

TCP/IP port for accessing the database.

=item attrSock

Socket name used to access the database. If omitted, the default socket
will be used.

=item attrDBD

Fully-qualified file name for the database definition XML file. This file
functions as data to the attribute management process, so if the data is
moved, this file must go with it.

=item attr_default_table

Name of the default relationship for attribute values. If not present,
C<HasValueFor> is used.

=back

=head2 Public Methods

=head3 new

    my $attrDB = CustomAttributes->new(%options);

Construct a new CustomAttributes object. The following options are
supported.

=over 4

=item splitter

Value to be used to split attribute values into sections in the
L</Fig Replacement Methods>. The default is a double colon C<::>,
and should only be overridden in extreme circumstances.

=item user

Name of the current user. This will appear in the attribute log.

=item DBD

Filename for the DBD. If unspecified, the default DBD is used.

=item dbName

SQL name of the database. If omitted, the value of
I<$FIG_Config::attrDBName> is used.

=item dbuser

User name for connecting to the database.

=item dbpass

Password for connecting to the database.

=item dbport

Port number for connecting to the database.

=item dbhost

Name of the database host.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, %options) = @_;
    # Compute the database name.
    my $dbName = $options{dbName} || $FIG_Config::attrDbName || 'fig_v6_attributes';
    my $dbms = $FIG_Config::attrDbms || 'mysql';
    my $user = $options{dbuser} || $FIG_Config::attrUser || 'attrib';
    my $pass = $options{dbpass} || $FIG_Config::attrPass || '';
    my $port = $options{dbport} || $FIG_Config::attrPort || $FIG_Config::dbport;
    my $host = $options{dbhost} || $FIG_Config::attrHost || 'localhost';
    my $sock = $FIG_Config::attrSock || $FIG_Config::dbsock;
    # Connect to the database.
    my $dbh = DBKernel->new($dbms, $dbName, $user, $pass, $port, $host, $sock);
    # Create the ERDB object.
    my $xmlFileName = $options{DBD} || $FIG_Config::attrDBD ||
                        "$FIG_Config::fig_disk/dist/releases/current/Sprout/AttributesDBD.xml";
    my $retVal = ERDB::new($class, $dbh, $xmlFileName, %options);
    # Store the splitter value.
    $retVal->{splitter} = $options{splitter} || '::';
    # Store the user name.
    $retVal->{user} = $options{user} || '<unknown>';
    Trace("User $retVal->{user} selected for attribute object.") if T(3);
    # Compute the default value table name. If it's not overridden, the
    # default is HasValueFor.
    $retVal->{defaultRel} = $FIG_Config::attr_default_table || 'HasValueFor';
    # Return the result.
    return $retVal;
}

=head3 StoreAttributeKey

    $attrDB->StoreAttributeKey($attributeName, $notes, \@groups, $table);

Create or update an attribute for the database.

=over 4

=item attributeName

Name of the attribute (the real key). If it does not exist already, it will be created.

=item notes

Descriptive notes about the attribute. It is presumed to be raw text, not HTML.

=item groups

Reference to a list of the groups to which the attribute should be associated.
This will replace any groups to which the attribute is currently attached.

=item table

The name of the relationship in which the attribute's values are to be stored.
If empty or undefined, the default relationship (usually C<HasValueFor>) will be
assumed.

=back

=cut

sub StoreAttributeKey {
    # Get the parameters.
    my ($self, $attributeName, $notes, $groups, $table) = @_;
    # Declare the return variable.
    my $retVal;
    # Default the table name.
    if (! $table) {
        $table = $self->{defaultRel};
    }
    # Validate the initial input values.
    if ($attributeName =~ /$self->{splitter}/) {
        Confess("Invalid attribute name \"$attributeName\" specified.");
    } elsif (! $notes) {
        Confess("Missing description for $attributeName.");
    } elsif (! grep { $_ eq $table } $self->GetConnectingRelationships('AttributeKey')) {
        Confess("Invalid relationship name \"$table\" specified as a custom attribute table.");
    } else {
        # Create a variable to hold the action to be displayed for the log (Add or Update).
        my $action;
        # Okay, we're ready to begin. See if this key exists.
        my $attribute = $self->GetEntity('AttributeKey', $attributeName);
        if (defined($attribute)) {
            # It does, so we do an update.
            $action = "Update Key";
            $self->UpdateEntity('AttributeKey', $attributeName,
                                { description => $notes,
                                  'relationship-name' => $table});
            # Detach the key from its current groups.
            $self->Disconnect('IsInGroup', 'AttributeKey', $attributeName);
        } else {
            # It doesn't, so we do an insert.
            $action = "Insert Key";
            $self->InsertObject('AttributeKey', { id => $attributeName,
                                description => $notes,
                                'relationship-name' => $table});
        }
        # Attach the key to the specified groups. (We presume the groups already
        # exist.)
        for my $group (@{$groups}) {
            $self->InsertObject('IsInGroup', { 'from-link' => $attributeName,
                                               'to-link'   => $group });
        }
        # Log the operation.
        $self->LogOperation($action, $attributeName, "Group list is " . join(" ", @{$groups}));
    }
}


=head3 DeleteAttributeKey

    my $stats = $attrDB->DeleteAttributeKey($attributeName);

Delete an attribute from the custom attributes database.

=over 4

=item attributeName

Name of the attribute to delete.

=item RETURN

Returns a statistics object describing the effects of the deletion.

=back

=cut

sub DeleteAttributeKey {
    # Get the parameters.
    my ($self, $attributeName) = @_;
    # Delete the attribute key.
    my $retVal = $self->Delete('AttributeKey', $attributeName);
    # Log this operation.
    $self->LogOperation("Delete Key", $attributeName, "Key will no longer be available for use by anyone.");
    # Return the result.
    return $retVal;

}

=head3 NewName

    my $text = CustomAttributes::NewName();

Return the string used to indicate the user wants to add a new attribute.

=cut

sub NewName {
    return "(new)";
}

=head3 LoadAttributesFrom

C<< my $stats = $attrDB->LoadAttributesFrom($fileName, %options); >>

Load attributes from the specified tab-delimited file. Each line of the file must
contain an object ID in the first column, an attribute key name in the second
column, and attribute values in the remaining columns. The attribute values must
be assembled into a single value using the splitter code. In addition, the key names may
contain a splitter. If this is the case, the portion of the key after the splitter is
treated as a subkey.

=over 4

=item fileName

Name of the file from which to load the attributes, or an open handle for the file.
(This last enables the method to be used in conjunction with the CGI form upload
control.)

=item options

Hash of options for modifying the load process.

=item RETURN

Returns a statistics object describing the load.

=back

Permissible option values are as follows.

=over 4

=item noAnalyze

Do not analyze the table after loading.

=item mode

Loading mode. Legal values are C<low_priority> (which reduces the task priority
of the load) and C<concurrent> (which reduces the locking cost of the load). The
default is a normal load.

=item append

If TRUE, then the attributes will be appended to existing data; otherwise, the
first time a key name is encountered, it will be erased.

=item archive

If specified, the name of a file into which the incoming data should be saved.
If I<resume> is also specified, only the lines actually loaded will be put
into this file.

=item objectType

If specified, the specified object type will be prefixed to each object ID.

=item resume

If specified, key-value pairs already in the database will not be reinserted.
Specify a number to start checking after the specified number of lines and
then admit everything after the first line not yet loaded. Specify C<careful>
to check every single line. Specify C<none> to ignore this option. The default
is C<none>. So, if you believe that a previous load failed somewhere after 50000
lines, a resume value of C<50000> would skip 50000 lines in the file, then
check each line after that until it finds one not already in the database. The
first such line found and all lines after that will be loaded. On the other
hand, if you have a file of 100000 records, and some have been loaded and some
not, you would use the word C<careful>, so that every line would be checked before
it is inserted. A resume of C<0> will start checking the first line of the
input file and then begin loading once it finds a line not in the database.

=item chunkSize

Number of lines to load in each burst. The default is 10,000.

=back

=cut

sub LoadAttributesFrom {
    # Get the parameters.
    my ($self, $fileName, %options) = @_;
    # Declare the return variable.
    my $retVal = Stats->new('keys', 'values', 'linesOut');
    # Initialize the timers.
    my ($eraseTime, $archiveTime, $checkTime) = (0, 0, 0);
    # Check for append mode.
    my $append = ($options{append} ? 1 : 0);
    # Check for resume mode.
    my $resume = (defined($options{resume}) ? $options{resume} : 'none');
    # Create a hash of key names found.
    my %keyHash = ();
    # Create a hash of table names to files. Most attributes go into the HasValueFor
    # table, but some are put into other tables. Each table name will be mapped
    # to a sub-hash with keys "fileName" (output file for the table) and "count"
    # (number of lines in the file).
    my %tableHash = ();
    # Compute the chunk size.
    my $chunkSize = ($options{chunkSize} ? $options{chunkSize} : 10000);
    # Open the file for input. Note we must anticipate the possibility of an
    # open filehandle being passed in. This occurs when the user is submitting
    # the load file over the web.
    my $fh;
    if (ref $fileName) {
        Trace("Using file opened by caller.") if T(3);
        $fh = $fileName;
    } else {
        Trace("Attributes will be loaded from $fileName.") if T(3);
        $fh = Open(undef, "<$fileName");
    }
    # Trace the mode.
    if (T(3)) {
        if ($options{mode}) {
            Trace("Mode is $options{mode}.")
        } else {
            Trace("No mode specified.")
        }
    }
    # Now check to see if we need to archive.
    my $ah;
    if (exists $options{archive}) {
        my $ah = Open(undef, ">$options{archive}");
        Trace("Load file will be archived to $options{archive}.") if T(3);
    }
    # Insure we recover from errors.
    eval {
        # If we have a resume number, process it here.
        if ($resume =~ /\d+/) {
            Trace("Skipping $resume lines.") if T(2);
            my $startTime = time();
            # Skip the specified number of lines.
            for (my $skipped = 0; ! eof($fh) && $skipped < $resume; $skipped++) {
                my $line = <$fh>;
                $retVal->Add(skipped => 1);
            }
            $checkTime += time() - $startTime;
        }
        # Loop through the file.
        Trace("Starting load.") if T(2);
        while (! eof $fh) {
            # Read the current line.
            my ($id, $key, @values) = Tracer::GetLine($fh);
            $retVal->Add(linesIn => 1);
            # Do some validation.
            if (! $id) {
                # We ignore blank lines.
                $retVal->Add(blankLines => 1);
            } elsif (substr($id, 0, 1) eq '#') {
                # A line beginning with a pound sign is a comment.
                $retVal->Add(comments => 1);
            } elsif (! defined($key)) {
                # An ID without a key is a serious error.
                my $lines = $retVal->Ask('linesIn');
                Confess("Line $lines in $fileName has no attribute key.");
            } elsif (! @values) {
                # A line with no values is not allowed.
                my $lines = $retVal->Ask('linesIn');
                Trace("Line $lines for key $key has no attribute values.") if T(1);
                $retVal->Add(skipped => 1);
            } else {
                # Check to see if we need to fix up the object ID.
                if ($options{objectType}) {
                    $id = "$options{objectType}:$id";
                }
                # The key contains a real part and an optional sub-part. We need the real part.
                my ($realKey, $subKey) = $self->SplitKey($key);
                # Now we need to check for a new key.
                if (! exists $keyHash{$realKey}) {
                    my $keyObject = $self->GetEntity(AttributeKey => $realKey);
                    if (! defined($keyObject)) {
                        # Here the specified key does not exist, which is an error.
                        my $line = $retVal->Ask('linesIn');
                        Confess("Attribute \"$realKey\" on line $line of $fileName not found in database.");
                    } else {
                        # Make sure we know this is no longer a new key. We do this by putting
                        # its table name in the key hash.
                        $keyHash{$realKey} = $keyObject->PrimaryValue('AttributeKey(relationship-name)');
                        $retVal->Add(keys => 1);
                        # If this is NOT append mode, erase the key. This does not delete the key
                        # itself; it just clears out all the values.
                        if (! $append) {
                            my $startTime = time();
                            $self->EraseAttribute($realKey);
                            $eraseTime += time() - $startTime;
                            Trace("Attribute $realKey erased.") if T(3);
                        }
                    }
                    Trace("Key $realKey found.") if T(3);
                }
                # If we're in resume mode, check to see if this insert is redundant.
                my $ok = 1;
                if ($resume ne 'none') {
                    my $startTime = time();
                    my $count = $self->GetAttributes($id, $key, @values);
                    if ($count) {
                        # Here the record is found, so we skip it.
                        $ok = 0;
                        $retVal->Add(skipped => 1);
                    } else {
                        # Here the record is not found. If we're in non-careful mode, we
                        # stop resume checking at this point.
                        if ($resume ne 'careful') {
                            $resume = 'none';
                        }
                    }
                    $checkTime += time() - $startTime;
                }
                if ($ok) {
                    # We're in business. First, archive this row.
                    if (defined $ah) {
                        my $startTime = time();
                        Tracer::PutLine($ah, [$id, $key, @values]);
                        $archiveTime += time() - $startTime;
                    }
                    # We need to format the attribute data so it will work
                    # as if it were a load file. This means we join the
                    # values.
                    my $valueString = join('::', @values);
                    # Now we need to get access to the key's load file. Check for it in the
                    # table hash.
                    my $keyTable = $keyHash{$realKey};
                    if (! exists $tableHash{$keyTable}) {
                        # This is a new table, so we need to set it up. First, we get
                        # a temporary file for it.
                        my $tempFileName = FIGRules::GetTempFileName(sessionID => $$ . $keyTable,
                                                                     extension => 'dtx');
                        my $oh = Open(undef, ">$tempFileName");
                        # Now we create its descriptor in the table hash.
                        $tableHash{$keyTable} = {fileName => $tempFileName, handle => $oh, count => 0};
                    }
                    # Everything is all set up, so we put the value in the temporary file and
                    # count it.
                    my $tableData = $tableHash{$keyTable};
                    my $startTime = time();
                    Tracer::PutLine($tableData->{handle}, [$realKey, $id, $subKey, $valueString]);
                    $archiveTime += time() - $startTime;
                    $retVal->Add(linesOut => 1);
                    $tableData->{count}++;
                    # See if it's time to load a chunk.
                    if ($tableData->{count} >= $chunkSize) {
                        # We've filled a chunk, so it's time.
                        close $tableData->{handle};
                        $self->_LoadAttributeTable($keyTable, $tableData->{fileName}, $retVal);
                        # Reset for the next chunk.
                        $tableData->{count} = 0;
                        $tableData->{handle} = Open(undef, ">$tableData->{fileName}");
                    }
                } else {
                    # Here we skipped because of resume mode.
                    $retVal->Add(resumeSkip => 1);
                }
                Trace($retVal->Ask('values') . " values processed.") if $retVal->Check(values => 1000) && T(3);
            }
        }
        # Now we close the archive file. Note we undefine the handle so the error methods know
        # not to worry.
        if (defined $ah) {
            close $ah;
            undef $ah;
        }
        # Now we load the residual from the temporary files (if any). This time we'll do an
        # analyze as well.
        for my $tableName (keys %tableHash) {
            # Get the data for this table.
            my $tableData = $tableHash{$tableName};
            # Close the handle. ERDB will re-open it for input later.
            close $tableData->{handle};
            # Check to see if there's anything left to load.
            if ($tableData->{count} > 0) {
                # Yes, load the data.
                $self->_LoadAttributeTable($tableName, $tableData->{fileName}, $retVal);
            }
            # Regardless of whether additional loading was required, we need to
            # analyze the table for performance.
            if (! $options{noAnalyze}) {
                my $startTime = time();
                $self->Analyze($tableName);
                $retVal->Add(analyzeTime => time() - $startTime);
            }
        }
        Trace("Attribute load successful.") if T(2);
    };
    # Check for an error.
    if ($@) {
        # Here we have an error. Display the error message.
        my $message = $@;
        Trace("Error during attribute load: $message") if T(0);
        $retVal->AddMessage($message);
        # Close the archive file if it's open. The archive file can sometimes provide
        # clues as to what happened.
        if (defined $ah) {
            close $ah;
        }
    }
    # Store the timers.
    $retVal->Add(eraseTime   => $eraseTime);
    $retVal->Add(archiveTime => $archiveTime);
    $retVal->Add(checkTime   => $checkTime);
    # Return the result.
    return $retVal;
}

=head3 BackupKeys

    my $stats = $attrDB->BackupKeys($fileName, %options);

Backup the attribute key information from the attribute database.

=over 4

=item fileName

Name of the output file.

=item options

Options for modifying the backup process.

=item RETURN

Returns a statistics object for the backup.

=back

Currently there are no options. The backup is straight to a text file in
tab-delimited format. Each key is backup up to two lines. The first line
is all of the data from the B<AttributeKey> table. The second is a
tab-delimited list of all the groups.

=cut

sub BackupKeys {
    # Get the parameters.
    my ($self, $fileName, %options) = @_;
    # Declare the return variable.
    my $retVal = Stats->new();
    # Open the output file.
    my $fh = Open(undef, ">$fileName");
    # Set up to read the keys.
    my $keyQuery = $self->Get(['AttributeKey'], "", []);
    # Loop through the keys.
    while (my $keyData = $keyQuery->Fetch()) {
        $retVal->Add(key => 1);
        # Get the fields.
        my ($id, $type, $tableName, $description) =
            $keyData->Values(['AttributeKey(id)', 'AttributeKey(relationship-name)',
                              'AttributeKey(description)']);
        # Escape any tabs or new-lines in the description.
        my $escapedDescription = Tracer::Escape($description);
        # Write the key data to the output.
        Tracer::PutLine($fh, [$id, $type, $tableName, $escapedDescription]);
        # Get the key's groups.
        my @groups = $self->GetFlat(['IsInGroup'], "IsInGroup(from-link) = ?", [$id],
                                    'IsInGroup(to-link)');
        $retVal->Add(memberships => scalar(@groups));
        # Write them to the output. Note we put a marker at the beginning to insure the line
        # is nonempty.
        Tracer::PutLine($fh, ['#GROUPS', @groups]);
    }
    # Log the operation.
    $self->LogOperation("Backup Keys", $fileName, $retVal->Display());
    # Return the result.
    return $retVal;
}

=head3 RestoreKeys

    my $stats = $attrDB->RestoreKeys($fileName, %options);

Restore the attribute keys and groups from a backup file.

=over 4

=item fileName

Name of the file containing the backed-up keys. Each key has a pair of lines,
one containing the key data and one listing its groups.

=back

=cut

sub RestoreKeys {
    # Get the parameters.
    my ($self, $fileName, %options) = @_;
    # Declare the return variable.
    my $retVal = Stats->new();
    # Set up a hash to hold the group IDs.
    my %groups = ();
    # Open the file.
    my $fh = Open(undef, "<$fileName");
    # Loop until we're done.
    while (! eof $fh) {
        # Get a key record.
        my ($id, $tableName, $description) = Tracer::GetLine($fh);
        if ($id eq '#GROUPS') {
            Confess("Group record found when key record expected.");
        } elsif (! defined($description)) {
            Confess("Invalid format found for key record.");
        } else {
            $retVal->Add("keyIn" => 1);
            # Add this key to the database.
            $self->InsertObject('AttributeKey', { id => $id,
                                                  description => Tracer::UnEscape($description),
                                                  'relationship-name' => $tableName});
            Trace("Attribute $id stored.") if T(3);
            # Get the group line.
            my ($marker, @groups) = Tracer::GetLine($fh);
            if (! defined($marker)) {
                Confess("End of file found where group record expected.");
            } elsif ($marker ne '#GROUPS') {
                Confess("Group record not found after key record.");
            } else {
                $retVal->Add(memberships => scalar(@groups));
                # Connect the groups.
                for my $group (@groups) {
                    # Find out if this is a new group.
                    if (! $groups{$group}) {
                        $retVal->Add(newGroup => 1);
                        # Add the group.
                        $self->InsertObject('AttributeGroup', { id => $group });
                        Trace("Group $group created.") if T(3);
                        # Make sure we know it's not new.
                        $groups{$group} = 1;
                    }
                    # Connect the group to our key.
                    $self->InsertObject('IsInGroup', { 'from-link' => $id, 'to-link' => $group });
                }
                Trace("$id added to " . scalar(@groups) . " groups.") if T(3);
            }
        }
    }
    # Log the operation.
    $self->LogOperation("Backup Keys", $fileName, $retVal->Display());
    # Return the result.
    return $retVal;
}

=head3 ArchiveFileName

    my $fileName = $ca->ArchiveFileName();

Compute a file name for archiving attribute input data. The file will be in the attribute log directory

=cut

sub ArchiveFileName {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    # We start by turning the timestamp into something usable as a file name.
    my $now = Tracer::Now();
    $now =~ tr/ :\//___/;
    # Next we get the directory name.
    my $dir = "$FIG_Config::var/attributes";
    if (! -e $dir) {
        Trace("Creating attribute file directory $dir.") if T(1);
        mkdir $dir;
    }
    # Put it together with the field name and the time stamp.
    $retVal = "$dir/upload.$now";
    # Modify the file name to insure it's unique.
    my $seq = 0;
    while (-e "$retVal.$seq.tbl") { $seq++ }
    # Use the computed sequence number to get the correct file name.
    $retVal .= ".$seq.tbl";
    # Return the result.
    return $retVal;
}

=head3 BackupAllAttributes

    my $stats = $attrDB->BackupAllAttributes($fileName, %options);

Backup all of the attributes to a file. The attributes will be stored in a
tab-delimited file suitable for reloading via L</LoadAttributesFrom>.

=over 4

=item fileName

Name of the file to which the attribute data should be backed up.

=item options

Hash of options for the backup.

=item RETURN

Returns a statistics object describing the backup.

=back

Currently there are no options defined.

=cut

sub BackupAllAttributes {
    # Get the parameters.
    my ($self, $fileName, %options) = @_;
    # Declare the return variable.
    my $retVal = Stats->new();
    # Get a list of the keys.
    my %keys = map { $_->[0] => $_->[1] } $self->GetAll(['AttributeKey'],
                                                        "", [], ['AttributeKey(id)',
                                                                  'AttributeKey(relationship-name)']);
    Trace(scalar(keys %keys) . " keys found during backup.") if T(2);
    # Open the file for output.
    my $fh = Open(undef, ">$fileName");
    # Loop through the keys.
    for my $key (sort keys %keys) {
        Trace("Backing up attribute $key.") if T(3);
        $retVal->Add(keys => 1);
        # Get the key's relevant relationship name.
        my $relName = $keys{$key};
        # Loop through this key's values.
        my $query = $self->Get([$relName], "$relName(from-link) = ?", [$key]);
        my $valuesFound = 0;
        while (my $line = $query->Fetch()) {
            $valuesFound++;
            # Get this row's data.
            my ($id, $key, $subKey, $value) = $line->Values(["$relName(to-link)",
                                                             "$relName(from-link)",
                                                             "$relName(subkey)",
                                                             "$relName(value)"]);
            # Check for a subkey.
            if ($subKey ne '') {
                $key = "$key$self->{splitter}$subKey";
            }
            # Write it to the file.
            Tracer::PutLine($fh, [$id, $key, Escape($value)]);
        }
        Trace("$valuesFound values backed up for key $key.") if T(3);
        $retVal->Add(values => $valuesFound);
    }
    # Log the operation.
    $self->LogOperation("Backup Data", $fileName, $retVal->Display());
    # Return the result.
    return $retVal;
}


=head3 GetGroups

    my @groups = $attrDB->GetGroups();

Return a list of the available groups.

=cut

sub GetGroups {
    # Get the parameters.
    my ($self) = @_;
    # Get the groups.
    my @retVal = $self->GetFlat(['AttributeGroup'], "", [], 'AttributeGroup(id)');
    # Return them.
    return @retVal;
}

=head3 GetAttributeData

    my %keys = $attrDB->GetAttributeData($type, @list);

Return attribute data for the selected attributes. The attribute
data is a hash mapping each attribute key name to a n-tuple containing the
data type, the description, the table name, and the groups.

=over 4

=item type

Type of attribute criterion: C<name> for attributes whose names begin with the
specified string, or C<group> for attributes in the specified group.

=item list

List containing the names of the groups or keys for the desired attributes.

=item RETURN

Returns a hash mapping each attribute key name to its description,
table name, and parent groups.

=back

=cut

sub GetAttributeData {
    # Get the parameters.
    my ($self, $type, @list) = @_;
    # Set up a hash to store the attribute data.
    my %retVal = ();
    # Loop through the list items.
    for my $item (@list) {
        # Set up a query for the desired attributes.
        my $query;
        if ($type eq 'name') {
            # Here we're doing a generic name search. We need to escape it and then tack
            # on a %.
            my $parm = $item;
            $parm =~ s/_/\\_/g;
            $parm =~ s/%/\\%/g;
            $parm .= "%";
            # Ask for matching attributes. (Note that if the user passed in a null string
            # he'll get everything.)
            $query = $self->Get(['AttributeKey'], "AttributeKey(id) LIKE ?", [$parm]);
        } elsif ($type eq 'group') {
            $query = $self->Get(['IsInGroup', 'AttributeKey'], "IsInGroup(to-link) = ?", [$item]);
        } else {
            Confess("Unknown attribute query type \"$type\".");
        }
        while (my $row = $query->Fetch()) {
            # Get this attribute's data.
            my ($key, $relName, $notes) = $row->Values(['AttributeKey(id)',
                                                     'AttributeKey(relationship-name)',
                                                     'AttributeKey(description)']);
            # If it's new, get its groups and add it to the return hash.
            if (! exists $retVal{$key}) {
                my @groups = $self->GetFlat(['IsInGroup'], "IsInGroup(from-link) = ?",
                                            [$key], 'IsInGroup(to-link)');
                $retVal{$key} = [$relName, $notes, @groups];
            }
        }
    }
    # Return the result.
    return %retVal;
}

=head3 LogOperation

    $ca->LogOperation($action, $target, $description);

Write an operation description to the attribute activity log (C<$FIG_Config::var/attributes.log>).

=over 4

=item action

Action being logged (e.g. C<Delete Group> or C<Load Key>).

=item target

ID of the key or group affected.

=item description

Short description of the action.

=back

=cut

sub LogOperation {
    # Get the parameters.
    my ($self, $action, $target, $description) = @_;
    # Get the user ID.
    my $user = $self->{user};
    # Get a timestamp.
    my $timeString = Tracer::Now();
    # Open the log file for appending.
    my $oh = Open(undef, ">>$FIG_Config::var/attributes.log");
    # Write the data to it.
    Tracer::PutLine($oh, [$timeString, $user, $action, $target, $description]);
    # Close the log file.
    close $oh;
}

=head2 FIG Method Replacements

The following methods are used by B<FIG.pm> to replace the previous attribute functionality.
Some of the old functionality is no longer present: controlled vocabulary is no longer
supported and there is no longer any searching by URL. Fortunately, neither of these
capabilities were used in the old system.

The methods here are the only ones supported by the B<RemoteCustomAttributes> object.
The idea is that these methods represent attribute manipulation allowed by all users, while
the others are only for privileged users with access to the attribute server.

In the previous implementation, an attribute had a value and a URL. In this implementation,
each attribute has only a value. These methods will treat the value as a list with the individual
elements separated by the value of the splitter parameter on the constructor (L</new>). The default
is double colons C<::>.

So, for example, an old-style keyword with a value of C<essential> and a URL of
C<http://www.sciencemag.org/cgi/content/abstract/293/5538/2266> using the default
splitter value would be stored as

    essential::http://www.sciencemag.org/cgi/content/abstract/293/5538/2266

The best performance is achieved by searching for a particular key for a specified
feature or genome.

=head3 GetAttributes

    my @attributeList = $attrDB->GetAttributes($objectID, $key, @values);

In the database, attribute values are sectioned into pieces using a splitter
value specified in the constructor (L</new>). This is not a requirement of
the attribute system as a whole, merely a convenience for the purpose of
these methods. If a value has multiple sections, each section
is matched against the corresponding criterion in the I<@valuePatterns> list.

This method returns a series of tuples that match the specified criteria. Each tuple
will contain an object ID, a key, and one or more values. The parameters to this
method therefore correspond structurally to the values expected in each tuple. In
addition, you can ask for a generic search by suffixing a percent sign (C<%>) to any
of the parameters. So, for example,

    my @attributeList = $attrDB->GetAttributes('fig|100226.1.peg.1004', 'structure%', 1, 2);

would return something like

    ['fig}100226.1.peg.1004', 'structure', 1, 2]
    ['fig}100226.1.peg.1004', 'structure1', 1, 2]
    ['fig}100226.1.peg.1004', 'structure2', 1, 2]
    ['fig}100226.1.peg.1004', 'structureA', 1, 2]

Use of C<undef> in any position acts as a wild card (all values). You can also specify
a list reference in the ID column. Thus,

    my @attributeList = $attrDB->GetAttributes(['100226.1', 'fig|100226.1.%'], 'PUBMED');

would get the PUBMED attribute data for Streptomyces coelicolor A3(2) and all its
features.

In addition to values in multiple sections, a single attribute key can have multiple
values, so even

    my @attributeList = $attrDB->GetAttributes($peg, 'virulent');

which has no wildcard in the key or the object ID, may return multiple tuples.

Value matching in this system works very poorly, because of the way multiple values are
stored. For the object ID, key name, and first value, we create queries that filter for the
desired results. On any filtering by value, we must do a comparison after the attributes are
retrieved from the database, since the database has no notion of the multiple values, which
are stored in a single string. As a result, queries in which filter only on value end up
reading a lot more than they need to.

=over 4

=item objectID

ID of object whose attributes are desired. If the attributes are desired for multiple
objects, this parameter can be specified as a list reference. If the attributes are
desired for all objects, specify C<undef> or an empty string. Finally, you can specify
attributes for a range of object IDs by putting a percent sign (C<%>) at the end.

=item key

Attribute key name. A value of C<undef> or an empty string will match all
attribute keys. If the values are desired for multiple keys, this parameter can be
specified as a list reference. Finally, you can specify attributes for a range of
keys by putting a percent sign (C<%>) at the end.

=item values

List of the desired attribute values, section by section. If C<undef>
or an empty string is specified, all values in that section will match. A
generic match can be requested by placing a percent sign (C<%>) at the end.
In that case, all values that match up to and not including the percent sign
will match. You may also specify a regular expression enclosed
in slashes. All values that match the regular expression will be returned. For
performance reasons, only values have this extra capability.

=item RETURN

Returns a list of tuples. The first element in the tuple is an object ID, the
second is an attribute key, and the remaining elements are the sections of
the attribute value. All of the tuples will match the criteria set forth in
the parameter list.

=back

=cut

sub GetAttributes {
    # Get the parameters.
    my ($self, $objectID, $key, @values) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Insure we have at least some sort of filtering going on.
    if (! grep { defined $_ } $objectID, $key, @values) {
        Confess("No filters specified in GetAttributes call.");
    } else {
        # This hash will map value-table fields to patterns. We use it to build the
        # SQL statement.
        my %data;
        # Add the object ID to the key information.
        $data{'to-link'} = $objectID;
        # The first value represents a problem, because we can search it using SQL, but not
        # in the normal way. If the user specifies a generic search or exact match for
        # every alternative value (remember, the values may be specified as a list),
        # then we can create SQL filtering for it. If any of the values are specified
        # as a regular expression, however, that's more complicated, because
        # we need to read every value to verify a match.
        if (@values > 0 && defined $values[0]) {
            # Get the first value and put its alternatives in an array.
            my $valueParm = $values[0];
            my @valueList;
            if (ref $valueParm eq 'ARRAY') {
                @valueList = @{$valueParm};
            } else {
                @valueList = ($valueParm);
            }
            # Okay, now we have all the possible criteria for the first value in the list
            # @valueList. We'll copy the values to a new array in which they have been
            # converted to generic requests. If we find a regular-expression match
            # anywhere in the list, we toss the whole thing.
            my @valuePatterns = ();
            my $okValues = 1;
            for my $valuePattern (@valueList) {
                # Check the pattern type.
                if (substr($valuePattern, 0, 1) eq '/') {
                    # Regular expressions invalidate the entire process.
                    $okValues = 0;
                } elsif (substr($valuePattern, -1, 1) eq '%') {
                    # A Generic pattern is passed in unmodified.
                    push @valuePatterns, $valuePattern;
                } else {
                    # An exact match is converted to generic.
                    push @valuePatterns, "$valuePattern%";
                }
            }
            # If everything works, add the value data to the filtering hash.
            if ($okValues) {
                $data{value} = \@valuePatterns;
            }
        }
        # Now comes the really tricky part, which is key handling. The key is
        # actually split in two parts: the real key and a sub-key. The real key
        # determines which value table contains the relevant values. The information
        # we need is kept in here.
        my %tables = map { $_ => [] } $self->_GetAllTables();
        # See if we have any key filtering to worry about.
        if ($key) {
            # Here we have either a single key or a list. We convert both cases to a list.
            my $keyList = (ref $key ne 'ARRAY' ? [$key] : $key);
            Trace("Reading key table.") if T(3);
            # Get easy access to the key/table hash.
            my $keyTableHash = $self->_KeyTable();
            # Loop through the keys, discovering tables.
            for my $keyChoice (@$keyList) {
                # Now we have to start thinking about the real key and the subkeys.
                my ($realKey, $subKey) = $self->_SplitKeyPattern($keyChoice);
                Trace("Checking $realKey against key table.") if T(3);
                # Find the matches for the real key in the key hash. For each of
                # these, we memorize the table name in the hash below.
                my %tableNames = ();
                for my $keyInTable (keys %$keyTableHash) {
                    if (_CheckSQLPattern($realKey, $keyInTable)) {
                        $tableNames{$keyTableHash->{$keyInTable}} = 1;
                        Trace("Table \"$keyTableHash->{$keyInTable}\" found for $keyInTable.") if T(3);
                    }
                }
                # If the key is generic, or didn't match anything, add
                # the default table to the mix.
                if (keys %tableNames == 0 || $keyChoice =~ /%/) {
                    $tableNames{$self->{defaultRel}} = 1;
                }
                # Now we add this key combination to the key list for each relevant table.
                for my $tableName (keys %tableNames) {
                    Trace("Adding query for $tableName.") if T(3);
                    push @{$tables{$tableName}}, [$realKey, $subKey];
                }
            }
        }
        # Now we loop through the tables of interest, performing queries.
        # Loop through the tables.
        for my $table (keys %tables) {
            # Get the key pairs for this table.
            my $pairs = $tables{$table};
            # Does this table have data? It does if there is no key specified or
            # it has at least one key pair.
            my $pairCount = scalar @{$pairs};
            Trace("Pair count for table $table is $pairCount.") if T(3);
            if ($pairCount || ! $key) {
                # Create some lists to contain the filter fragments and parameter values.
                my @filter = ();
                my @parms = ();
                # This next loop goes through the different fields that can be specified in the
                # parameter list and generates filters for each. The %data hash that we built above
                # contains most of the necessary information to do this. When we're done, we'll
                # paste on stuff for the key pairs.
                for my $field (keys %data) {
                    # Accumulate filter information for this field. We will OR together all the
                    # elements accumulated to create the final result.
                    my @fieldFilter = ();
                    # Get the specified filter for this field.
                    my $fieldPattern = $data{$field};
                    Trace("Processing $field in $table. Pattern is " . (defined $fieldPattern ? "\"$fieldPattern\"" : "undefined") . ".") if T(3);
                    # Only proceed if the pattern is one that won't match everything.
                    if (defined($fieldPattern) && $fieldPattern ne "" && $fieldPattern ne "%") {
                        Trace("Pattern for $field is specific.") if T(3);
                        # Convert the pattern to an array.
                        my @patterns = ();
                        if (ref $fieldPattern eq 'ARRAY') {
                            push @patterns, @{$fieldPattern};
                        } else {
                            push @patterns, $fieldPattern;
                        }
                        # Only proceed if the array is nonempty. The loop will work fine if the
                        # array is empty, but when we build the filter string at the end we'll
                        # get "()" in the filter list, which will result in an SQL syntax error.
                        if (@patterns) {
                            # Loop through the individual patterns.
                            for my $pattern (@patterns) {
                                my ($clause, $value) = _WherePart($table, $field, $pattern);
                                push @fieldFilter, $clause;
                                push @parms, $value;
                            }
                            # Form the filter for this field.
                            my $fieldFilterString = join(" OR ", @fieldFilter);
                            push @filter, "($fieldFilterString)";
                        }
                    }
                }
                # The final filter is for the key pairs. Only proceed if we have some.
                if ($pairCount) {
                    # We'll accumulate pair filter clauses in here.
                    my @pairFilters = ();
                    # Loop through the key pairs.
                    for my $pair (@$pairs) {
                        my ($realKey, $subKey) = @{$pair};
                        my ($realClause, $realValue) = _WherePart($table, 'from-link', $realKey);
                        if (! $subKey) {
                            # Here the subkey is wild, so only the real key matters.
                            push @pairFilters, $realClause;
                            push @parms, $realValue;
                        } else {
                            # Here we have to select on both keys.
                            my ($subClause, $subValue) = _WherePart($table, 'subkey', $subKey);
                            push @pairFilters, "($realClause AND $subClause)";
                            push @parms, $realValue, $subValue;
                        }
                    }
                    # Join the pair filters together to make a giant key filter.
                    my $pairFilter = "(" . join(" OR ", @pairFilters) . ")";
                    push @filter, $pairFilter;
                }
                # At this point, @filter contains one or more filter strings and @parms
                # contains the parameter values to bind to them.
                my $actualFilter = join(" AND ", @filter);
                # Now we're ready to make our query.
                my $query = $self->Get([$table], $actualFilter, \@parms);
                # Format the results.
                push @retVal, $self->_QueryResults($query, $table, @values);
            }
        }
    }
    # The above loop ran the query for each necessary value table and merged the
    # results into @retVal. Now we return the rows found.
    return @retVal;
}

=head3 AddAttribute

    $attrDB->AddAttribute($objectID, $key, @values);

Add an attribute key/value pair to an object. This method cannot add a new key, merely
add a value to an existing key. Use L</StoreAttributeKey> to create a new key.

=over 4

=item objectID

ID of the object to which the attribute is to be added.

=item key

Attribute key name.

=item values

One or more values to be associated with the key. The values are joined together with
the splitter value before being stored as field values. This enables L</GetAttributes>
to split them apart during retrieval. The splitter value defaults to double colons C<::>.

=back

=cut

sub AddAttribute {
    # Get the parameters.
    my ($self, $objectID, $key, @values) = @_;
    # Don't allow undefs.
    if (! defined($objectID)) {
        Confess("No object ID specified for AddAttribute call.");
    } elsif (! defined($key)) {
        Confess("No attribute key specified for AddAttribute call.");
    } elsif (! @values) {
        Confess("No values specified in AddAttribute call for key $key.");
    } else {
        # Okay, now we have some reason to believe we can do this. Form the values
        # into a scalar.
        my $valueString = join($self->{splitter}, @values);
        # Split up the key.
        my ($realKey, $subKey) = $self->SplitKey($key);
        # Find the table containing the key.
        my $table = $self->_KeyTable($realKey);
        # Connect the object to the key.
        $self->InsertObject($table, { 'from-link' => $realKey,
                                             'to-link'   => $objectID,
                                             'subkey'    => $subKey,
                                             'value'     => $valueString,
                                    });
    }
    # Return a one, indicating success. We do this for backward compatability.
    return 1;
}

=head3 DeleteAttribute

    $attrDB->DeleteAttribute($objectID, $key, @values);

Delete the specified attribute key/value combination from the database.

=over 4

=item objectID

ID of the object whose attribute is to be deleted.

=item key

Attribute key name.

=item values

One or more values associated with the key. If no values are specified, then all values
will be deleted. Otherwise, only a matching value will be deleted.

=back

=cut

sub DeleteAttribute {
    # Get the parameters.
    my ($self, $objectID, $key, @values) = @_;
    # Don't allow undefs.
    if (! defined($objectID)) {
        Confess("No object ID specified for DeleteAttribute call.");
    } elsif (! defined($key)) {
        Confess("No attribute key specified for DeleteAttribute call.");
    } else {
        # Split the key into the real key and the subkey.
        my ($realKey, $subKey) = $self->SplitKey($key);
        # Find the table containing the key's values.
        my $table = $self->_KeyTable($realKey);
        if ($subKey eq '' && scalar(@values) == 0) {
            # Here we erase the entire key for this object.
            $self->DeleteRow('HasValueFor', $key, $objectID);
        } else {
            # Here we erase the matching values.
            my $valueString = join($self->{splitter}, @values);
            $self->DeleteRow('HasValueFor', $realKey, $objectID,
                             { subkey => $subKey, value => $valueString });
        }
    }
    # Return a one. This is for backward compatability.
    return 1;
}

=head3 DeleteMatchingAttributes

    my @deleted = $attrDB->DeleteMatchingAttributes($objectID, $key, @values);

Delete all attributes that match the specified criteria. This is equivalent to
calling L</GetAttributes> and then invoking L</DeleteAttribute> for each
row found.

=over 4

=item objectID

ID of object whose attributes are to be deleted. If the attributes for multiple
objects are to be deleted, this parameter can be specified as a list reference. If
attributes are to be deleted for all objects, specify C<undef> or an empty string.
Finally, you can delete attributes for a range of object IDs by putting a percent
sign (C<%>) at the end.

=item key

Attribute key name. A value of C<undef> or an empty string will match all
attribute keys. If the values are to be deletedfor multiple keys, this parameter can be
specified as a list reference. Finally, you can delete attributes for a range of
keys by putting a percent sign (C<%>) at the end.

=item values

List of the desired attribute values, section by section. If C<undef>
or an empty string is specified, all values in that section will match. A
generic match can be requested by placing a percent sign (C<%>) at the end.
In that case, all values that match up to and not including the percent sign
will match. You may also specify a regular expression enclosed
in slashes. All values that match the regular expression will be deleted. For
performance reasons, only values have this extra capability.

=item RETURN

Returns a list of tuples for the attributes that were deleted, in the
same form as L</GetAttributes>.

=back

=cut

sub DeleteMatchingAttributes {
    # Get the parameters.
    my ($self, $objectID, $key, @values) = @_;
    # Get the matching attributes.
    my @retVal = $self->GetAttributes($objectID, $key, @values);
    # Loop through the attributes, deleting them.
    for my $tuple (@retVal) {
        $self->DeleteAttribute(@{$tuple});
    }
    # Log this operation.
    my $count = @retVal;
    $self->LogOperation("Mass Delete", $key, "$count matching attributes deleted.");
    # Return the deleted attributes.
    return @retVal;
}

=head3 ChangeAttribute

    $attrDB->ChangeAttribute($objectID, $key, \@oldValues, \@newValues);

Change the value of an attribute key/value pair for an object.

=over 4

=item objectID

ID of the genome or feature to which the attribute is to be changed. In general, an ID that
starts with C<fig|> is treated as a feature ID, and an ID that is all digits and periods
is treated as a genome ID. For IDs of other types, this parameter should be a reference
to a 2-tuple consisting of the entity type name followed by the object ID.

=item key

Attribute key name. This corresponds to the name of a field in the database.

=item oldValues

One or more values identifying the key/value pair to change.

=item newValues

One or more values to be put in place of the old values.

=back

=cut

sub ChangeAttribute {
    # Get the parameters.
    my ($self, $objectID, $key, $oldValues, $newValues) = @_;
    # Don't allow undefs.
    if (! defined($objectID)) {
        Confess("No object ID specified for ChangeAttribute call.");
    } elsif (! defined($key)) {
        Confess("No attribute key specified for ChangeAttribute call.");
    } elsif (! defined($oldValues) || ref $oldValues ne 'ARRAY') {
        Confess("No old values specified in ChangeAttribute call for key $key.");
    } elsif (! defined($newValues) || ref $newValues ne 'ARRAY') {
        Confess("No new values specified in ChangeAttribute call for key $key.");
    } else {
        # We do the change as a delete/add.
        $self->DeleteAttribute($objectID, $key, @{$oldValues});
        $self->AddAttribute($objectID, $key, @{$newValues});
    }
    # Return a one. We do this for backward compatability.
    return 1;
}

=head3 EraseAttribute

    $attrDB->EraseAttribute($key);

Erase all values for the specified attribute key. This does not remove the
key from the database; it merely removes all the values.

=over 4

=item key

Key to erase. This must be a real key; that is, it cannot have a subkey
component.

=back

=cut

sub EraseAttribute {
    # Get the parameters.
    my ($self, $key) = @_;
    # Find the table containing the key.
    my $table = $self->_KeyTable($key);
    # Is it the default table?
    if ($table eq $self->{defaultRel}) {
        # Yes, so the key is mixed in with other keys.
        # Delete everything connected to it.
        $self->Disconnect('HasValueFor', 'AttributeKey', $key);
    } else {
        # No. Drop and re-create the table.
        $self->TruncateTable($table);
    }
    # Log the operation.
    $self->LogOperation("Erase Data", $key);
    # Return a 1, for backward compatability.
    return 1;
}

=head3 GetAttributeKeys

    my @keyList = $attrDB->GetAttributeKeys($groupName);

Return a list of the attribute keys for a particular group.

=over 4

=item groupName

Name of the group whose keys are desired.

=item RETURN

Returns a list of the attribute keys for the specified group.

=back

=cut

sub GetAttributeKeys {
    # Get the parameters.
    my ($self, $groupName) = @_;
    # Get the attributes for the specified group.
    my @groups = $self->GetFlat(['IsInGroup'], "IsInGroup(to-link) = ?", [$groupName],
                                'IsInGroup(from-link)');
    # Return the keys.
    return sort @groups;
}

=head3 QueryAttributes

    my @attributeData = $ca->QueryAttributes($filter, $filterParms);

Return the attribute data based on an SQL filter clause. In the filter clause,
the name C<$object> should be used for the object ID, C<$key> should be used for
the key name, C<$subkey> for the subkey value, and C<$value> for the value field.

=over 4

=item filter

Filter clause in the standard ERDB format, except that the field names are C<$object> for
the object ID field, C<$key> for the key name field, C<$subkey> for the subkey field,
and C<$value> for the value field. This abstraction enables us to hide the details of
the database construction from the user.

=item filterParms

Parameters for the filter clause.

=item RETURN

Returns a list of tuples. Each tuple consists of an object ID, a key (with optional subkey), and
one or more attribute values.

=back

=cut

# This hash is used to drive the substitution process.
my %AttributeParms = (object => 'to-link',
                      key    => 'from-link',
                      subkey => 'subkey',
                      value  => 'value');

sub QueryAttributes {
    # Get the parameters.
    my ($self, $filter, $filterParms) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Make sue we have filter parameters.
    my $realParms = (defined($filterParms) ? $filterParms : []);
    # Loop through all the value tables.
    for my $table ($self->_GetAllTables()) {
        # Create the query for this table by converting the filter.
        my $realFilter = $filter;
        for my $name (keys %AttributeParms) {
            $realFilter =~ s/\$$name/$table($AttributeParms{$name})/g;
        }
        my $query = $self->Get([$table], $realFilter, $realParms);
        # Loop through the results, forming the output attribute tuples.
        while (my $result = $query->Fetch()) {
            # Get the four values from this query result row.
            my ($objectID, $key, $subkey, $value) = $result->Values(["$table($AttributeParms{object})",
                                                                    "$table($AttributeParms{key})",
                                                                    "$table($AttributeParms{subkey})",
                                                                    "$table($AttributeParms{value})"]);
            # Combine the key and the subkey.
            my $realKey = ($subkey ? $key . $self->{splitter} . $subkey : $key);
            # Split the value.
            my @values = split $self->{splitter}, $value;
            # Output the result.
            push @retVal, [$objectID, $realKey, @values];
        }
    }
    # Return the result.
    return @retVal;
}

=head2 Key and ID Manipulation Methods

=head3 ParseID

    my ($type, $id) = CustomAttributes::ParseID($idValue);

Determine the type and object ID corresponding to an ID value from the attribute database.
Most ID values consist of a type name and an ID, separated by a colon (e.g. C<Family:aclame|cluster10>);
however, Genomes, Features, and Subsystems are not stored with a type name, so we need to
deduce the type from the ID value structure.

The theory here is that you can plug the ID and type directly into a Sprout database method, as
follows

    my ($type, $id) = CustomAttributes::ParseID($attrList[$num]->[0]);
    my $target = $sprout->GetEntity($type, $id);

=over 4

=item idValue

ID value taken from the attribute database.

=item RETURN

Returns a two-element list. The first element is the type of object indicated by the ID value,
and the second element is the actual object ID.

=back

=cut

sub ParseID {
    # Get the parameters.
    my ($idValue) = @_;
    # Declare the return variables.
    my ($type, $id);
    # Parse the incoming ID. We first check for the presence of an entity name. Entity names
    # can only contain letters, which helps to insure typed object IDs don't collide with
    # subsystem names (which are untyped).
    if ($idValue =~ /^([A-Za-z]+):(.+)/) {
        # Here we have a typed ID.
        ($type, $id) = ($1, $2);
        # Fix the case sensitivity on PDB IDs.
        if ($type eq 'PDB') { $id = lc $id; }
    } elsif ($idValue =~ /fig\|/) {
        # Here we have a feature ID.
        ($type, $id) = (Feature => $idValue);
    } elsif ($idValue =~ /\d+\.\d+/) {
        # Here we have a genome ID.
        ($type, $id) = (Genome => $idValue);
    } else {
        # The default is a subsystem ID.
        ($type, $id) = (Subsystem => $idValue);
    }
    # Return the results.
    return ($type, $id);
}

=head3 FormID

    my $idValue = CustomAttributes::FormID($type, $id);

Convert an object type and ID pair into an object ID string for the attribute system. Subsystems,
genomes, and features are stored in the database without type information, but all other object IDs
must be prefixed with the object type.

=over 4

=item type

Relevant object type.

=item id

ID of the object in question.

=item RETURN

Returns a string that will be recognized as an object ID in the attribute database.

=back

=cut

sub FormID {
    # Get the parameters.
    my ($type, $id) = @_;
    # Declare the return variable.
    my $retVal;
    # Compute the ID string from the type.
    if (grep { $type eq $_ } qw(Feature Genome Subsystem)) {
        $retVal = $id;
    } else {
        $retVal = "$type:$id";
    }
    # Return the result.
    return $retVal;
}

=head3 GetTargetObject

    my $object = CustomAttributes::GetTargetObject($erdb, $idValue);

Return the database object corresponding to the specified attribute object ID. The
object type associated with the ID value must correspond to an entity name in the
specified database.

=over 4

=item erdb

B<ERDB> object for accessing the target database.

=item idValue

ID value retrieved from the attribute database.

=item RETURN

Returns a B<ERDBObject> for the attribute value's target object.

=back

=cut

sub GetTargetObject {
    # Get the parameters.
    my ($erdb, $idValue) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the type and ID for the target object.
    my ($type, $id) = ParseID($idValue);
    # Plug them into the GetEntity method.
    $retVal = $erdb->GetEntity($type, $id);
    # Return the resulting object.
    return $retVal;
}

=head3 SplitKey

    my ($realKey, $subKey) = $ca->SplitKey($key);

Split an external key (that is, one passed in by a caller) into the real key and the sub key.
The real and sub keys are separated by a splitter value (usually C<::>). If there is no splitter,
then the sub key is presumed to be an empty string.

=over 4

=item key

Incoming key to be split.

=item RETURN

Returns a two-element list, the first element of which is the real key and the second element of
which is the sub key.

=back

=cut

sub SplitKey {
    # Get the parameters.
    my ($self, $key) = @_;
    # Do the split.
    my ($realKey, $subKey) = split($self->{splitter}, $key, 2);
    # Insure the subkey has a value.
    if (! defined $subKey) {
        $subKey = '';
    }
    # Return the results.
    return ($realKey, $subKey);
}


=head3 JoinKey

    my $key = $ca->JoinKey($realKey, $subKey);

Join a real key and a subkey together to make an external key. The external key is the attribute key
used by the caller. The real key and the subkey are how the keys are represented in the database. The
real key is the key to the B<AttributeKey> entity. The subkey is an attribute of the B<HasValueFor>
relationship.

=over 4

=item realKey

The real attribute key.

=item subKey

The subordinate portion of the attribute key.

=item RETURN

Returns a single string representing both keys.

=back

=cut

sub JoinKey {
    # Get the parameters.
    my ($self, $realKey, $subKey) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a subkey.
    if ($subKey eq '') {
        # No subkey, so the real key is the key.
        $retVal = $realKey;
    } else {
        # Subkey found, so the two pieces must be joined by a splitter.
        $retVal = "$realKey$self->{splitter}$subKey";
    }
    # Return the result.
    return $retVal;
}


=head3 AttributeTable

    my $tableHtml = CustomAttributes::AttributeTable($cgi, @attrList);

Format the attribute data into an HTML table.

=over 4

=item cgi

CGI query object used to generate the HTML

=item attrList

List of attribute results, in the format returned by the L</GetAttributes> or
L</QueryAttributes> methods.

=item RETURN

Returns an HTML table displaying the attribute keys and values.

=back

=cut

sub AttributeTable {
    # Get the parameters.
    my ($cgi, @attrList) = @_;
    # Accumulate the table rows.
    my @html = ();
    for my $attrData (@attrList) {
        # Format the object ID and key.
        my @columns = map { CGI::escapeHTML($_) } @{$attrData}[0,1];
        # Now we format the values. These remain unchanged unless one of them is a URL.
        my $lastValue = scalar(@{$attrData}) - 1;
        push @columns, map { $_ =~ /^http:/ ? CGI::a({ href => $_ }, $_) : $_ } @{$attrData}[2 .. $lastValue];
        # Assemble the values into a table row.
        push @html, CGI::Tr(CGI::td(\@columns));
    }
    # Format the table in the return variable.
    my $retVal = CGI::table({ border => 2 }, CGI::Tr(CGI::th(['Object', 'Key', 'Values'])), @html);
    # Return it.
    return $retVal;
}


=head2 Internal Utility Methods

=head3 _KeyTable

    my $tableName = $ca->_KeyTable($keyName);

Return the name of the table that contains the attribute values for the
specified key.

Most attribute values are stored in the default table (usually C<HasValueFor>).
Some, however, are placed in private tables by themselves for performance reasons.

=over 4

=item keyName (optional)

Name of the attribute key whose table name is desired. If not specified, the
entire key/table hash is returned.

=item RETURN

Returns the name of the table containing the specified attribute key's values,
or a reference to a hash that maps key names to table names.

=back

=cut

sub _KeyTable {
    # Get the parameters.
    my ($self, $keyName) = @_;
    # Declare the return variable.
    my $retVal;
    # Insure the key table hash is present.
    if (! exists $self->{keyTables}) {
        Trace("Creating key table.") if T(3);
        my @pairs = $self->GetAll(['AttributeKey'],
                                  "AttributeKey(relationship-name) <> ?",
                                  [$self->{defaultRel}],
                                  ['AttributeKey(id)', 'AttributeKey(relationship-name)']);
        my %keyTables;
        for my $pair (@pairs) {
            my ($key, $table) = @$pair;
            Trace("Table for $key is \"$table\".") if T(3);
            $keyTables{$key} = $table;
        }
        $self->{keyTables} = \%keyTables;
    }
    # Get the key hash.
    my $keyHash = $self->{keyTables};
    # Does the user want a specific table or the whole thing?
    if ($keyName) {
        # Here we want a specific table. Is this key in the hash?
        if (exists $keyHash->{$keyName}) {
            # It's there, so return the specified table.
            $retVal = $keyHash->{$keyName};
            Trace("Returning \"$retVal\" from KeyTable.") if T(3);
        } else {
            # No, return the default table name.
            $retVal = $self->{defaultRel};
            Trace("Returning default table from KeyTable.") if T(3);
        }
    } else {
        # Here we want the whole hash.
        $retVal = $keyHash;
        Trace("Returning entire hash from KeyTable.") if T(3);
    }
    # Return the result.
    return $retVal;
}


=head3 _QueryResults

    my @attributeList = $attrDB->_QueryResults($query, $table, @values);

Match the results of a query against value criteria and return
the results. This is an internal method that splits the values coming back
and matches the sections against the specified section patterns. It serves
as the back end to L</GetAttributes> and L</FindAttributes>.

=over 4

=item query

A query object that will return the desired records.

=item table

Name of the value table for the query.

=item values

List of the desired attribute values, section by section. If C<undef>
or an empty string is specified, all values in that section will match. A
generic match can be requested by placing a percent sign (C<%>) at the end.
In that case, all values that match up to and not including the percent sign
will match. You may also specify a regular expression enclosed
in slashes. All values that match the regular expression will be returned. For
performance reasons, only values have this extra capability.

=item RETURN

Returns a list of tuples. The first element in the tuple is an object ID, the
second is an attribute key, and the remaining elements are the sections of
the attribute value. All of the tuples will match the criteria set forth in
the parameter list.

=back

=cut

sub _QueryResults {
    # Get the parameters.
    my ($self, $query, $table, @values) = @_;
    # Declare the return value.
    my @retVal = ();
    # We use this hash to check for duplicates.
    my %dupHash = ();
    # Get the number of value sections we have to match.
    my $sectionCount = scalar(@values);
    # Loop through the assignments found.
    while (my $row = $query->Fetch()) {
        # Get the current row's data.
        my ($id, $realKey, $subKey, $valueString) = $row->Values(["$table(to-link)",
                                                                  "$table(from-link)",
                                                                  "$table(subkey)",
                                                                  "$table(value)"
                                                                ]);
        # Form the key from the real key and the sub key.
        my $key = $self->JoinKey($realKey, $subKey);
        # Break the value into sections.
        my @sections = split($self->{splitter}, $valueString);
        # Match each section against the incoming values. We'll assume we're
        # okay unless we learn otherwise.
        my $matching = 1;
        for (my $i = 0; $i < $sectionCount && $matching; $i++) {
            # Get the pattern for this section.
            my $value = $values[$i];
            # Only check this value if it's defined. Undefined is a wild card.
            if (defined $value) {
                # The value pattern is a scalar or a reference to a list of possible
                # values. We convert it to a list and then record a match if any
                # list member matches.
                my $valueMatch = 0;
                my @valueList;
                if (ref $value eq 'ARRAY') {
                    @valueList = @$value;
                } else {
                    @valueList = ($value);
                }
                # Get this section of the value list.
                my $section = $sections[$i];
                # Loop through the pattern values WHILE ! $valueMatch.
                for my $thisValue (@valueList) { last unless ! $valueMatch;
                    Trace("Current value pattern is \"$value\".") if T(4);
                    if ($thisValue =~ m#^/(.+)/[a-z]*$#) {
                        Trace("Regular expression detected.") if T(4);
                        # Here we have a regular expression match.
                        $valueMatch = eval("\$section =~ $thisValue");
                    } else {
                        # Here we have a normal match.
                        Trace("SQL match used.") if T(4);
                        $valueMatch = _CheckSQLPattern($thisValue, $section);
                    }
                }
                # Record the match result.
                $matching = $valueMatch;
            }
        }
        # If we match, consider writing this row to the return list.
        if ($matching) {
            # Check for a duplicate.
            my $wholeThing = join($self->{splitter}, $id, $key, $valueString);
            if (! $dupHash{$wholeThing}) {
                # It's okay, we're not a duplicate. Insure we don't duplicate this result.
                $dupHash{$wholeThing} = 1;
                push @retVal, [$id, $key, @sections];
            }
        }
    }
    # Return the rows found.
    return @retVal;
}


=head3 _LoadAttributeTable

    $attr->_LoadAttributeTable($tableName, $fileName, $stats, $mode);

Load a file's data into an attribute table. This is an internal method
provided for the convenience of L</LoadAttributesFrom>. It loads the
specified file into the specified table and updates the statistics
object.

=over 4

=item tableName

Name of the table being loaded. This is usually C<HasValueFor>, but may
be a different table for some specific attribute keys.

=item fileName

Name of the file containing a chunk of attribute data to load.

=item stats

Statistics object into which counts and times should be placed.

=item mode

Load mode for the file, usually C<low_priority>, C<concurrent>, or
an empty string. The mode is used by some applications to control access
to the table while it's being loaded. The default (empty string) is to lock the
table until all the data's in place.

=back

=cut

sub _LoadAttributeTable {
    # Get the parameters.
    my ($self, $tableName, $fileName, $stats, $mode) = @_;
    # Load the table from the file. Note that we don't do an analyze.
    # The analyze is done only after everything is complete.
    my $startTime = time();
    Trace("Loading attributes from $fileName: " . (-s $fileName) .
          " characters.") if T(3);
    my $loadStats = $self->LoadTable($fileName, $tableName,
                                     mode => $mode, partial => 1);
    # Record the load time.
    $stats->Add(insertTime => time() - $startTime);
    # Roll up the other statistics.
    $stats->Accumulate($loadStats);
}


=head3 _GetAllTables

    my @tables = $ca->_GetAllTables();

Return a list of the names of all the tables used to store attribute
values.

=cut

sub _GetAllTables {
    # Get the parameters.
    my ($self) = @_;
    # Start with the default table.
    my @retVal = $self->{defaultRel};
    # Add the tables named in the key hash. These tables are automatically
    # NOT the default, and each can only occur once, because alternate tables
    # are allocated on a per-key basis.
    my $keyHash = $self->_KeyTable();
    push @retVal, values %$keyHash;
    # Return the result.
    return @retVal;
}


=head3 _SplitKeyPattern

    my ($realKey, $subKey) = $ca->_SplitKeyPattern($keyChoice);

Split a key pattern into the main part (the I<real key>) and a sub-part
(the I<sub key>). This method differs from L</SplitKey> in that it treats
the key as an SQL pattern instead of a raw string. Also, if there is no
incoming sub-part, the sub-key will be undefined instead of an empty
string.

=over 4

=item keyChoice

SQL key pattern to be examined. This can either be a literal, an SQL pattern,
a literal with an internal splitter code (usually C<::>) or an SQL pattern with
an internal splitter. Note that the only SQL pattern we support is a percent
sign (C<%>) at the end. This is the way we've declared things in the documentation,
so users who try anything else will have problems.

=item RETURN

Returns a two-element list. The first element is the SQL pattern for the
real key and the second is the SQL pattern for the sub-key. If the value
for either one does not matter (e.g., the user wants a real key value of
C<iedb> and doesn't care about the sub-key value), it will be undefined.

=back

=cut

sub _SplitKeyPattern {
    # Get the parameters.
    my ($self, $keyChoice) = @_;
    # Declare the return variables.
    my ($realKey, $subKey);
    # Look for a splitter in the input.
    if ($keyChoice =~ /^(.*?)$self->{splitter}(.*)/) {
        # We found one. This means we can treat both sides of the
        # splitter as known patterns.
        ($realKey, $subKey) = ($1, $2);
    } elsif ($keyChoice =~ /%$/) {
        # Here we have a generic pattern for the whole key. The pattern
        # is treated as the correct pattern for the real key, but the
        # sub-key is considered to be wild.
        $realKey = $keyChoice;
    } else {
        # Here we have a literal pattern for the whole key. The pattern
        # is treated as the correct pattern for the real key, and the
        # sub-key is required to be blank.
        $realKey = $keyChoice;
        $subKey = '';
    }
    # Return the results.
    return ($realKey, $subKey);
}


=head3 _WherePart

    my ($sqlClause, $escapedValue) = _WherePart($tableName, $fieldName, $sqlPattern);

Return the SQL clause and value for checking a field against the
specified SQL pattern value. If the pattern is generic (ends in a C<%>),
then a C<LIKE> expression is returned. Otherwise, an equality expression
is returned. We take in information describing the field being checked,
and the pattern we're checking against it. The output is a WHERE clause
fragment for the comparison and a value to be used as a bound parameter
value for the clause.

=over 4

=item tableName

Name of the table containing the field we want checked by the clause.

=item fieldName

Name of the field to check in that table.

=item sqlPattern

Pattern to be compared against the field. If the last character is a percent sign
(C<%>), it will be treated as a generic SQL pattern; otherwise, it will be treated
as a literal.

=item RETURN

Returns a two-element list. The first element will be an SQL comparison expression
and the second will be the value to be used as a bound parameter for the expression
in order to

=back

=cut

sub _WherePart {
    # Get the parameters.
    my ($tableName, $fieldName, $sqlPattern) = @_;
    # Declare the return variables.
    my ($sqlClause, $escapedValue);
    # Copy the pattern into the return area.
    $escapedValue = $sqlPattern;
    # Check the pattern. Is it generic or exact?
    if ($sqlPattern =~ /(.*)%$/) {
        # It's generic. We need a LIKE clause and we must escape the underscores
        # and percents in the pattern (except for the last one, of course).
        $escapedValue = $1;
        $escapedValue =~ s/(%|_)/\\$1/g;
        $escapedValue .= "%";
        $sqlClause = "$tableName($fieldName) LIKE ?";
    } else {
        # No, it isn't. We use an equality clause.
        $sqlClause = "$tableName($fieldName) = ?";
    }
    # Return the results.
    return ($sqlClause, $escapedValue);
}


=head3 _CheckSQLPattern

    my $flag = _CheckSQLPattern($pattern, $value);

Return TRUE if the specified SQL pattern matches the specified value,
else FALSE. The pattern is not a true full-blown SQL LIKE pattern: the
only wild-carding allowed is a percent sign (C<%>) at the end.

=over 4

=item pattern

SQL pattern to match against a value.

=item value

Value to match against an SQL pattern.

=item RETURN

Returns TRUE if the pattern matches the value, else FALSE.

=back

=cut

sub _CheckSQLPattern {
    # Get the parameters.
    my ($pattern, $value) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a generic pattern.
    if ($pattern =~ /(.*)%$/) {
        # Here we have one. Do a substring match.
        $retVal = (substr($value, 0, length $1) eq $1);
    } else {
        # Here it's an exact match.
        $retVal = ($pattern eq $value);
    }
    Trace("SQL pattern check: \"$value\" vs \"$pattern\" = $retVal.") if T(4);
    # Return the result.
    return $retVal;
}

1;
