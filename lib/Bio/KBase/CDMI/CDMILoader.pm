package Bio::KBase::CDMI::CDMILoader;

    use strict;
    use Stats;
    use SeedUtils;
    use Digest::MD5;
    use DateTime;
    use Data::Dumper;
    use File::Spec;
    use File::Temp;
    use IDServerAPIClient;
    use Bio::KBase::CDMI::Sources;
    use ERDBTypeSemiBoolean;

=head1 CDMI Load Utility Object

This object contains methods useful for the programming of CDMI load
scripts. It has a built-in statistics object and KBase ID server.
In addition, it contains useful utility methods.

The object contains the following fields.

=over 4

=item stats

A L<Stats> object for tracking statistics about the load.

=item db

The L<Bio::KBase::CDMI::CDMI> object for the database being loaded.

=item idserver

An L<IDServerAPIClient> object for requesting KBase IDs.

=item protCache

Reference to a hash of proteins known to be in the database.

=item relations

Reference to a hash keyed by relation name. Each relation
maps to a list containing an open L<File::Temp> object followed by
a list of field names representing the relation's field names in
order. The L</InsertObject> method will output field data to the
open file handle, and when the L</LoadRelations> method is called,
all of the relations will be loaded from the files created.

=item relationList

List of relation names in the order they should be loaded
by L</LoadRelations>.

=item sourceData

L<Bio::KBase::CDMI::Sources> object describing the load characteristics
of the current data source.

=item genome

ID of the genome currently being loaded (if any)

=back

=head2 Static Methods

=head3 GetLine

    my @fields = Bio::KBase::CDMI::CDMILoader::GetLine($ih);

or

    my @fields = $loader->GetLine($ih);

Read a line from a tab-delimited file, returning the fields in the form
of a list.

=over 4

=item ih

Open input file handle.

=item RETURN

Returns a list of the fields in the next input line. Note that fields
containing a single period (C<.>) will be converted to null strings.

=back

=cut

sub GetLine {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($ih) = @_;
    # Read the line and chomp off the new-line character.
    my $line = <$ih>;
    chomp $line;
    # Return the individual fields.
    my @retVal = map { ($_ eq '.' ? '' : $_) } split /\t/, $line;
    return @retVal;
}

=head3 ReadFastaRecord

    my ($sequence, $nextID, $nextComment) = Bio::KBase::CDMI::CDMILoader::ReadFastaRecord($ih);

or

    my ($sequence, $nextID, $nextComment) = $loader->ReadFastaRecord($ih);

Read a sequence record from a FASTA file. The comment and identifier
for the next sequence record will be returned along with the sequence. If
end-of-file is reached, the returned comment and ID will be undefined.

=over 4

=item ih

Open file handle to the input file, which must be positioned after a
sequence header. At the end of the method call, the file will be
positioned after the next sequence header or at end-of-file.

=item RETURN

Returns a three-element list containing (0) the sequence read, (1) the
ID of the next sequence record in the file, and (2) the comment for
the next sequence record in the file.

=back

=cut

sub ReadFastaRecord {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($ih) = @_;
    # Declare the return variables for the ID and comment. When we read a
    # header record, we'll set the next-ID variable and that will stop the
    # read loop.
    my ($nextID, $nextComment);
    # This will hold the sequence fragments.
    my @lines;
    # Loop until we've read the whole sequence.
    while (! eof $ih && ! defined $nextID) {
        # Read the next line.
        my $line = <$ih>;
        chomp $line;
        # Check for a header.
        if (substr($line,0,1) eq '>') {
            # This is a header line. Save the ID and comment.
            ($nextID, $nextComment) = split m/\s+/, substr($line, 1), 2;
        } else {
            # This is a data line. Save the sequence.
            push @lines, $line;
        }
    }
    # Form the lines read into a sequence.
    my $sequence = join("", @lines);
    # Return everything read.
    return ($sequence, $nextID, $nextComment);
}

=head3 ParseMetadata

    my $metaHash = Bio::KBase::CDMI::CDMILoader::ParseMetadata($fileName);

or

    my $metaHash = $loader->ParseMetadata($fileName);

Parse a metadata file to extract the attributes and values. A
metadata file contains one or more multi-line records separated
by a record containing nothing but a double slash (C<//>). The
first line of the record is the attribute name. The remaining
lines form the attribute value.

=over 4

=item fileName

Name of the metadata file to parse.

=item RETURN

Returns a reference to a hash mapping attribute names to their
values. Multi-line values may contain embedded line-feeds.

=back

=cut

sub ParseMetadata {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fileName) = @_;
    # Declare the return hash.
    my %retVal;
    # Only proceed if the file exists.
    if (-f $fileName) {
        # Open the file.
        open(my $ih, "<$fileName") || die "Could not open $fileName: $!";
        # Denote we do not have an attribute or a value yet.
        my $key;
        my @value;
        # Loop through the file.
        while (! eof $ih) {
            # Get the current line.
            my $line = <$ih>;
            chomp $line;
            # Determine the type of line.
            if ($line eq '//') {
                # Here we have a delimiter. Store the accumulated value.
                $retVal{$key} = join("\n", @value);
                # Insure we know this key has been stored.
                undef $key;
            } elsif (! defined $key) {
                # Here we have an attribute name. Store it as the key and
                # clear the value.
                $key = $line;
                @value = ();
            } else {
                # Here we have part of the value.
                push @value, $line;
            }
        }
        # If there's a residual, put it in the hash.
        if (defined $key) {
            $retVal{$key} = join("\n", @value);
        }
    }
    # Return the hash of attributes.
    return \%retVal;
}

=head3 ReadAttribute

    my $value = Bio::KBase::CDMI::CDMILoader::ReadAttribute($fileName);

or

    my $value = $loader->ReadAttribute($fileName);

Read the record from a single-line file.

=over 4

=item fileName

Name of the file to read.

=item RETURN

Returns the record in the file read, or C<undef> if the file does
not exist.

=back

=cut

sub ReadAttribute {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fileName) = @_;
    # Declare the return variable.
    my $retVal;
    # Only proceed if the file exists.
    if (-f $fileName) {
        # Open the file and read its first line.
        open(my $ih, "<$fileName") || die "Could not open $fileName: $!";
        $retVal= <$ih>;
        chomp $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 ConvertTime

    my $timeValue = Bio::KBase::CDMI::CDMILoader::ConvertTime($modelTime);

Convert a time from ModelSEED format to an ERDB time value. The ModelSEED
format is

B<YYYY>C<->B<MM>C<->B<DD>C<T>B<HH>C<:>B<MM>C<:>B<SS>

The C<T> may sometimes be replaced by a space.

=over 4

=item modelTime

Date/time value in ModelSEED format.

=item RETURN

Returns the incoming time as a number of seconds since the epoch.

=back

=cut

sub ConvertTime {
    # Get the parameters.
    my ($modelTime) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Parse the components.
    if ($modelTime =~ /(\d+)[-\/](\d+)[-\/](\d+)[T ](\d+):(\d+):(\d+)/) {
        my $dt = DateTime->new(year => $1, month => $2, day => $3,
                               hour => $4, minute => $5, second => $6);
        $retVal = $dt->epoch();
    } elsif ($modelTime =~ /(\d+)[-\/](\d+)[-\/](\d+)/) {
        my $dt = DateTime->new(year => $1, month => $2, day => $3,
                               hour => 12, minute => 0, second => 0);
        $retVal = $dt->epoch();
    }
    # Return the result.
    return $retVal;
}

=head3 DoubleIdCheck

    my $actualKBID = Bio::KBase::CDMI::CDMILoader::DoubleIdCheck($stats, $sourceID, $kbID, \%idMap);

or

    my $actualKBID = $loader->DoubleIdCheck($stats, $sourceID, $kbID, \%idMap);

Select the KBase ID from a pair of link fields. In such cases, the first
field contains the source ID and the second contains a KBase ID. One or
the other of the IDs may be blank or missing, in which case the other one
is used. The KBase ID will be prefered if both IDs are present. If only
the source ID is present, the specified ID map will be used to translate
it.

=over 4

=item stats

A L<Stats> object that will be updated to indicate how the ID was computed.

=item sourceID (optional)

The source ID of the target object.

=item kbID (optional)

The KBase ID of the target object.

=item idMap

Reference to a hash mapping source IDs to KBase IDs.

=item RETURN

Returns the KBase ID of the target object.

=back

=cut

sub DoubleIdCheck {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($stats, $sourceID, $kbID, $idMap) = @_;
    # Declare the return variable.
    my $retVal;
    # Default to the incoming KBase ID.
    if ($kbID) {
        $stats->Add(kbLinkUsed => 1);
        $retVal = $kbID;
    } elsif ($sourceID) {
        $stats->Add(sourceLinkUsed => 1);
        $retVal = $idMap->{$sourceID};
    }
    # Return the result.
    return $retVal;
}


=head2 Special Methods

=head3 new

    my $loader = CDMILoader->new($cdmi, $idserver);

Create a new CDMI loader object for the specified CMDI database.

=over 4

=item cdmi

A L<Bio::KBase::CDMI::CDMI> object for the database being loaded.

=item idserver

KBase ID server object. If none is specified, a default one will be
created.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $cdmi, $idserver) = @_;
    # Create the statistics object.
    my $stats = Stats->new();
    # Create this object.
    my $retVal = {};
    bless $retVal, $class;
    # Store the statistics object and the database.
    $retVal->{stats} = $stats;
    $retVal->{cdmi} = $cdmi;
    # Insure we have a KBase ID server.
    if (! defined $idserver) {
        my $id_server_url = "http://bio-data-1.mcs.anl.gov:8080/services/idserver";
        $idserver = IDServerAPIClient->new($id_server_url);
    }
    # Attach the ID server.
    $retVal->{idserver} = $idserver;
    # Default to no genome and a source of KBase.
    $retVal->{sourceData} = Bio::KBase::CDMI::Sources->new("KBase");
    $retVal->{genome} = "";
    $retVal->{useSourceIDs} = 0;
    # Create the relation loader stuff.
    $retVal->{relations} = {};
    $retVal->{reltionList} = [];
    # Create the protein cache.
    $retVal->{protCache} = {};
    # Return the result.
    return $retVal;
}

=head2 Basic Access Methods

=head3 stats

    my $stats = $loader->stats;

Return the statistics object.

=cut

sub stats {
    return $_[0]->{stats};
}

=head3 cdmi

    my $cdmi = $loader->cdmi;

Return the database instance object.

=cut

sub cdmi {
    return $_[0]->{cdmi};
}

=head3 idserver

    my $idserver = $loader->idserver;

Return the ID server instance object.

=cut

sub idserver {
    return $_[0]->{idserver};
}

=head2 Relation Loader Services

The relation loader provides services for loading tables using the
B<LOAD DATA INFILE> facility, which is significantly faster. As
database records are computed, they are output to files using the
L</InsertObject> method. At the end of the load, the C<LoadRelations>
method is called to close the files and perform the B<LOAD DATA INFILE>
command. The C<SetRelations> method is called to initialize the
process.

B<There are limitations to this process>. It will only work if the
fields in question are untranslated scalars, such as numbers,
strings, or dates in internal format. For example, if the relation
in question contains DNA or images, it cannot be loaded in this
manner, since the fields need to be converted.

=head3 SetRelations

    $loader->SetRelations(@relationNames);

Initialize loaders for the specified relations.

=over 4

=item relationNames

List of the names for the relations to load.

=back

=cut

sub SetRelations {
    # Get the parameters.
    my ($self, @relationNames) = @_;
    # Get the attached database.
    my $cdmi = $self->cdmi;
    # Get the loader hash.
    my $relations = $self->{relations};
    # Save the relation name list.
    $self->{relationList} = \@relationNames;
    # Compute the temporary file directory.
    my $dirName = File::Spec->tmpdir();
    print "Temporary file directory is $dirName.\n";
    # Loop through the relation names, creating loaders.
    for my $relationName (@relationNames) {
        # Create the output file.
        my $fh = File::Temp->new(TEMPLATE => "loader_rel_$relationName.XXXXXXXX",
                SUFFIX => '.dtx', UNLINK => 0, DIR => $dirName);
        # Get the list of fields in the relation and remember which allow nulls.
        # Note we convert field name hyphens to underscores.
        my (@fields, @nulls);
        my $relData = $cdmi->FindRelation($relationName);
        for my $fieldDescriptor (@{$relData->{Fields}}) {
            my $name = $fieldDescriptor->{name};
            $name =~ tr/-/_/;
            push @fields, $name;
            push @nulls, ($fieldDescriptor->{null} ? 1 : 0);
        }
        # Create the relation loader.
        $relations->{$relationName} = [$fh, \@fields, \@nulls];
    }
}

=head3 InsertObject

    $loader->InsertObject($relationName, %fields);

Output a proposed database record to one of the relation loaders.

=over 4

=item relationName

Name of the relation being output.

=item fields

Hash mapping field names for the record to the field values.

=back

=cut

sub InsertObject {
    # Get the parameters.
    my ($self, $relationName, %fields) = @_;
    # Get the relation's loader.
    my $relData = $self->{relations}{$relationName};
    if (! defined $relData) {
        # No loader, so do a real insert.
        $self->cdmi->InsertObject($relationName, %fields);
    } else {
        my ($fh, $fieldNames, $nullFlags) = @$relData;
        # Loop through the field names, collecting the field values.
        my @values;
        for (my $i = 0; $i < @$fieldNames; $i++) {
            my $fieldName = $fieldNames->[$i];
            my $value = $fields{$fieldName};
            if (! defined $value) {
                # Check to see if we're using the hyphenated version of the
                # field name.
                my $altName = $fieldName;
                $altName =~ tr/_/-/;
                $value = $fields{$altName};
                # Check for a missing value.
                if (! defined $value) {
                    # Here the value is missing. If it's nullable, this is OK.
                    if ($nullFlags->[$i]) {
                        # Nulls are OK. Put in the MySQL load code for nulls.
                        $value = "\\N";
                    } else {
                        # The missing value is an error. Compute an ID for this record.
                        my $id = "<unknown>";
                        if (defined $fields{id}) {
                            $id = $fields{id};
                        } else {
                            my $from = $fields{from_link} || $fields{'from-link'};
                            my $to = $fields{to_link} || $fields{'to-link'};
                            if (defined $from && defined $to) {
                                $id = "$from -> $to";
                            }
                        }
                        die "Missing field $fieldName in $relationName InsertObject for record $id.\n";
                    }
                }
            }
            push @values, $value;
        }
        # Output the fields to the loader file.
        print $fh join("\t", @values) . "\n";
    }
}


=head3 LoadRelations

    $loader->LoadRelations($keep);

Unspool all the relation loaders into the database. Each load file will
be closed and then a B<LOAD DATA INFILE> command will be used to load it.
A statistical object (L<Stat>) will be returned.

=over 4

=item keep

If TRUE, the temporary files will not be deleted.

=back

=cut

sub LoadRelations {
    # Get the parameters.
    my ($self, $keep) = @_;
    # Get our statistics object.
    my $stats = $self->stats;
    # Get the database.
    my $cdmi = $self->cdmi;
    # Get the relation loaders.
    my $relations = $self->{relations};
    # Loop through the loaders in the user-specified order, processing
    # one relation at a time.
    for my $relationName (@{$self->{relationList}}) {
        print "Loading $relationName.\n";
        # Get the relation's file handle and file name.
        my $fh = $relations->{$relationName}[0];
        my $fileName = $fh->filename;
        # Close the handle and change the permissions to make the file available for reading.
        close $fh;
        chmod 0664, $fileName;
        # Load the file into the relation and roll up the statistics.
        my $stats2 = $cdmi->LoadTable($fileName, $relationName, partial => 1,
            );
        $stats->Accumulate($stats2);
        # Remove the loader.
        delete $relations->{$relationName};
        # Remove the temporary file if necessary.
        if (! $keep) {
        	unlink $fileName;
        }
    }
}


=head2 Loader Utility Methods

=head3 UpdateFunction

	$loader->UpdateFunction($fid, $function);

Update the functional assignment of a feature. The functional assignment is changed and the role links
are reconnected to reflect the new role.

=over 4

=item fid

ID of the feature whose functional assignment is to be updated.

=item function

new functional assignment to give to the feature

=back

=cut

sub UpdateFunction {
	# Get the parameters.
	my ($self, $fid, $function) = @_;
	# Get the support objects.
	my $cdmi = $self->cdmi;
	my $stats = $self->stats;
    # Compute the new roles.
	my ($roles, $errors) = SeedUtils::roles_for_loading($function);
    # Disconnect the feature from its current roles.
	$cdmi->Disconnect('IsFunctionalIn', Feature => $fid);
	if (! defined $roles) {
		# Here the function does not appear to be a role.
		$stats->Add(roleRejected => 1);
	} else {
		# Here the function contained one or more roles. We will also count
		# the number of roles that were rejected for being too
		# long.
		$stats->Add(rolesTooLong => $errors);
		# Loop through the roles found.
		for my $role (@$roles) {
		    # Insure this role is in the database.
		    my $roleID = $self->CheckRole($role);
		    # Connect it to the feature.
		    $cdmi->InsertObject('IsFunctionalIn', from_link => $roleID,
		        to_link => $fid);
		    $stats->Add(connectRole => 1);
		}
	}
	# Update the feature with the new function.
	$cdmi->UpdateEntity('Feature', $fid, function => $function);
}

=head3 genome_load_file_name

    my $fileName = $loader->genome_load_file_name($directory, $name);

Compute the fully-qualified name of a load file. The load file will be
located in the specified directory and will have either the name
given, or the name given with the current genome ID inserted before
the extension. So, for example, if the given name is C<contigs.fa>
and the genome ID is C<100226.1>, this method will look for
C<contigs.100226.1.fa> first, and if that is not found return
C<contigs.fa>.

=over 4

=item directory

Directory containing the load files.

=item name

Name of the particular load file.

=item RETURN

Returns a fully-qualified file name to use in the load.

=back

=cut

sub genome_load_file_name {
    # Get the parameters.
    my ($self, $directory, $name) = @_;
    # Start with the default file name.
    my $retVal = "$directory/$name";
    # Get the genome ID.
    my $genome = $self->{genome};
    # Only Check for a genome-altered file if we have a genome ID.
    if ($genome) {
        # Compute the genome-altered file name.
        my @parts = split  m/\./, $name;
        my $extension = pop @parts;
        my $altName = $directory . "/" . join(".", @parts, $genome, $extension);
        # Check to see if it exists.
        if (-f $altName) {
            # It does, so use it.
            $retVal = $altName;
        }
    }
    # Return the file name found.
    return $retVal;
}

=head3 CheckRole

    my $roleID = $loader->CheckRole($roleText);

Insure a record for the specified role exists in the database. If the
role is not found, it will be created.

=over 4

=item roleText

Text of the role.

=item RETURN

Returns the ID of the role in the database.

=back

=cut

sub CheckRole {
    # Get the parameters.
    my ($self, $roleText) = @_;
    # Get the database object.
    my $cdmi = $self->cdmi;
    # Get the statistics object.
    my $stats = $self->stats;
    # Compute the role ID from the role. They are currently the same.
    my $retVal = $roleText;
    # We have to add the role. Determine whether or not it is
    # hypothetical.
    my $hypo = (hypo($roleText) ? 1 : 0);
    $stats->Add(newRole => 1);
    # Create the role.
    $cdmi->InsertObject('Role', {id => $roleText, hypothetical => $hypo}, ignore => 1);
    # Return the role ID.
    return $retVal;
}

=head3 CheckProtein

    my $protID = $loader->CheckProtein($sequence);

Insure that a protein sequence is in the database. If it is not, a
record will be created for it.

=over 4

=item sequence

Protein amino acid sequence that needs to be in the database.

=item RETURN

Returns the MD5 identifier of the protein sequence.

=back

=cut

sub CheckProtein {
    # Get the parameters.
    my ($self, $sequence) = @_;
    # Get the statistics object.
    my $stats = $self->stats;
    # Get the database object;
    my $cdmi = $self->cdmi;
    # Compute the MD5 of the protein sequence.
    my $retVal = Digest::MD5::md5_hex($sequence);
    # Check to see if it's in the database.
    if ($self->{protCache}->{$retVal}) {
        # It's in the cache, so we're done.
        $stats->Add(proteinCached => 1);
    } else {
        # It isn't, so we must add it. We use "ignore" to suppress duplicate-key errors.
        $cdmi->InsertObject('ProteinSequence', {id => $retVal,
                sequence => $sequence}, ignore => 1);
        $stats->Add(proteinAdded => 1);
        # Put it in the cache so we can find it later.
        $self->{protCache}->{$retVal} = 1;
    }
    # Return the protein's MD5 identifier.
    return $retVal;
}

=head3 InsureEntity

    my $createdFlag = $loader->InsureEntity($entityType => $id, %fields);

Insure that the specified record exists in the database. If no record is
found of the specified type with the specified ID, one will be created
with the indicated fields.

=over 4

=item $entityType

Type of entity to check.

=item id

ID of the entity instance in question.

=item fields

Hash mapping field names to values for all the fields in the desired entity record except
for the ID.

=item RETURN

Returns TRUE always. We no longer know if a new object was created.

=back

=cut

sub InsureEntity {
    # Get the parameters.
    my ($self, $entityType, $id, %fields) = @_;
    # Get the database.
    my $cdmi = $self->cdmi;
    # Get the statistics object.
    my $stats = $self->stats;
    # Denote we haven't created a new record.
    my $retVal = 0;
    # Check the database. We use an insert-ignore to suppress duplicate-key errors.
    # If the object is already in the database, the insert will be ignored.
    $cdmi->InsertObject($entityType, {id => $id, %fields}, ignore => 1);
    $stats->Add(insertSupport => 1);
    $stats->Add("$entityType-added" => 1);
    # Return the insertion indicator.
    return $retVal;
}

=head3 DeleteRelatedRecords

    $loader->DeleteRelatedRecords($kbid, $relName, $entityName);

Delete all the records in the named entity and relationship relating to the
specified KBase ID and roll up the statistics.

=over 4

=item kbid

ID of the object whose related records are being deleted.

=item relName

Name of a relationship from the identified object's entity.

=item entityName

Name of the entity on the other side of the relationship.

=back

=cut

sub DeleteRelatedRecords {
    # Get the parameters.
    my ($self, $kbid, $relName, $entityName) = @_;
    # Get the database object.
    my $cdmi = $self->cdmi;
    # Get the statistics object.
    my $stats = $self->stats;
    # Get all the relationship records.
    my (@targets) = $cdmi->GetFlat($relName, "$relName(from_link) = ?", [$kbid],
                                  "to-link");
    print scalar(@targets) . " entries found for delete of $entityName via $relName.\n" if @targets;
    # Loop through the relationship records, deleting them and the target entity
    # records.
    for my $target (@targets) {
        # Delete the relationship instance.
        $cdmi->DeleteRow($relName, $kbid, $target);
        $stats->Add($relName => 1);
        # Delete the entity instance.
        my $subStats = $cdmi->Delete($entityName, $target);
        # Roll up the statistics.
        $stats->Accumulate($subStats);
    }
}

=head3 ConvertFileRecord

    $loader->ConvertFileRecord($objectName, \@fileRecord,
                               \%rules);

Convert a file record to a database record. The parameters specify
which input columns correspond to output fields and the rules for
converting them.

=over 4

=item objectName

Name of the output object (entity or relationship).

=item fileRecord

Reference to a list of the input fields.

=item rules

Reference to a hash, keyed by output field name. The value of each
field is a 3-tuple consisting of (0) the index of the input field,
(1) the name of the rule for translating the field, and (2) the
default value to use if the field is empty or missing. The acceptable
rules are as follows.

=over 8

=item copy

Copy without conversion.

=item timeStamp

Convert from a ModelSEED date/time value to an ERDB time stamp.

=item kbid

Convert from an ID to a KBase ID.

=item copy1

Copy the first half of the value.

=item copy2

Copy the second half of the value.

=item semi-boolean

Convert to a ERDB Semi-Boolean from a displayable string.

=back

As a shorthand, a single number is equivalent to the number, 'copy',
and an undefined value (no default).

=back

=cut

sub ConvertFileRecord {
    # Get the parameters.
    my ($self, $objectName, $fileRecord, $rules) = @_;
    # This will contain the field mapping for the InsertObject call.
    my %fields;
    # Get the CDMI database.
    my $cdmi = $self->cdmi;
    # Loop through the rules.
    for my $fieldName (keys %$rules) {
        my $ruleSpec = $rules->{$fieldName};
        my ($loc, $rule, $default);
        if (ref $ruleSpec eq 'ARRAY') {
            ($loc, $rule, $default) = @$ruleSpec;
        } else {
            ($loc, $rule) = ($ruleSpec, 'copy');
        }
        # The output value will be put in here.
        my $outputValue = $default;
        # We do extra checking for semi-boolean.
        if ($rule eq 'semi-boolean') {
            # The validator returns an empty string if the value is valid.
            my $badValue = ERDBTypeSemiBoolean->validate($outputValue);
            if ($badValue) {
                die "Illegal default value for semi-boolean: $outputValue";
            }
        }
        # Get the specified input field. If the input field spec is
        # missing, we'll always do the default.
        my $inputValue;
        if (defined $loc) {
            $inputValue = $fileRecord->[$loc];
        }
        # Only proceed if it has a value.
        if (defined $inputValue && $inputValue ne '') {
            # Process according to the format rule.
            if ($rule eq 'copy') {
                $outputValue = $inputValue;
            } elsif ($rule eq 'timeStamp') {
                $outputValue = ConvertTime($inputValue);
            } elsif ($rule eq 'kbid') {
                my $hash = $self->FindKBaseIDs('', [$inputValue]);
                $outputValue = $hash->{$inputValue};
            } elsif ($rule eq 'copy1') {
                $outputValue = substr($inputValue, 0, length($inputValue)/2);
            } elsif ($rule eq 'copy2') {
                $outputValue = substr($inputValue, length($inputValue)/2);
            } elsif ($rule eq 'semi-boolean') {
                $outputValue = ERDBTypeSemiBoolean::ComputeFromString($inputValue);
            } else {
                die "Invalid input rule $rule.\n";
            }
        }
        # Store the field specification in the field hash.
        $fields{$fieldName} = $outputValue;
    }
    # Insert the record.
    $self->InsertObject($objectName, %fields);
}

=head3 SimpleLoad

    $loader->SimpleLoad($inDirectory, $fileName, $tableName, $instructions, $header);

Load a table from a tab-delimited file according to a set of
instructions.

=over 4

=item inDirectory

Input directory containing the file.

=item fileName

Name of the file containing the data to load.

=item tableName

Name of the table being loaded.

=item instructions

Instructions for loading a record from the file, in the same format
as for L</ConvertFileRecord>.

=item header

If TRUE, the first input record is a header that will be skipped.

=item optional

If TRUE, the file is considered optional, and if it is not found, no error
will be generated.

=back

=cut

sub SimpleLoad {
    # Get the parameters.
    my ($self, $inDirectory, $fileName, $tableName, $instructions, $header, $optional) = @_;
    # Get the statistics object.
    my $stats = $self->stats;
    # Do we have an input file?
    my $fullFileName = "$inDirectory/$fileName";
    if (! -f $fullFileName) {
        # No. Is it optional?
        if ($optional) {
            # Yes. Write a message.
            print "File $fullFileName not found: skipped.\n";
            $stats->Add(fileNotFound => 1);
        } else {
            # No. We have an error.
            die "Required file $fullFileName not found.\n";
        }
    } else {
        # Open the input file.
        open(my $ih, "<$fullFileName") || die "Could not open $fileName: $!\n";
        print "Processing $fileName.\n";
        # Skip the header record, if necessary.
        if ($header) {
            $self->GetLine($ih);
        }
        # Loop through the data records.
        while (! eof $ih) {
            my @fields = $self->GetLine($ih);
            $stats->Add(($fileName . 'In') => 1);
            $self->ConvertFileRecord($tableName, \@fields, $instructions);
            $stats->Add(($tableName . "Out") => 1);
        }
        close $ih;
    }
}


=head2 KBase ID Services

=head3 SetSource

    $loader->SetSource($source);

Specify the current database source.

=over 4

=item source

Name of the database from which data is being loaded.

=back

=cut

sub SetSource {
    # Get the parameters.
    my ($self, $source) = @_;
    # Update the source data.
    $self->{sourceData} = Bio::KBase::CDMI::Sources->new($source);
}

=head3 UseSourceIDs

	$loader->UseSourceIDs($flag);

If the flag is TRUE, suppress calls to the ID server and return the source ID unchanged.
If the flag is FALSE, use the ID server.

=over 4

=item flag

TRUE to turn off the ID server, FALSE to turn it on (the normal condition).

=back

=cut

sub UseSourceIDs {
	my ($self, $flag) = @_;
	$self->{useSourceIDs} = $flag;
}

=head3 SetGenome

    $loader->SetGenome($genome);

Specify the ID of the genome being loaded. This helps the ID services
determine if the genome ID needs to be added to the object ID when
calling for the KBase ID.

=over 4

=item genome

Original (source) ID of the genome currently being loaded.

=back

=cut

sub SetGenome {
    # Get the parameters.
    my ($self, $genome) = @_;
    # Store the proposed genome ID.
    $self->{genome} = $genome;
}

=head3 LookupGenome

    my $genome = $loader->LookupGenome($genomeID);

Look up the KBase ID of a genome. If the genome is not in the database,
nothing will be returned.

=over 4

=back

=cut

sub LookupGenome {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Get the CDMI database.
    my $cdmi = $self->cdmi;
    # Look up the genome using the source ID.
    my ($retVal) = $cdmi->GetFlat("Submitted Genome",
            'Submitted(from_link) = ? AND Genome(source_id) = ?',
            [$self->source, $genomeID], 'Genome(id)');
    # Return the result (if any).
    return $retVal;
}

=head3 FindKBaseIDs

    my $idMapping = $loader->FindKBaseIDs($type, \@ids);

Find the KBase IDs for the specified identifiers from the given external
source database. No new IDs will be created or registered.

=over 4

=item type

Type of object to which the IDs apply.

=item ids

Reference to a list of foreign IDs to be converted to KBase IDs.

=item RETURN

Returns a reference to a hash that maps the foreign identifiers to their
KBase equivalents. If no KBase equivalent exists, the foreign identifier
will not appear in the hash.

=back

=cut

sub FindKBaseIDs {
    # Get the parameters.
    my ($self, $type, $ids) = @_;
    # Declare the return variable.
    my %retVal;
    # Are we in source ID mode?
    if ($self->{useSourceIDs}) {
    	# Yes. Return an identity mapping.
    	%retVal = map { $_ => $_ } @$ids;
    } else {
	    # No. Compute the real source and the real IDs.
	    my $realSource = $self->realSource($type);
	    my $idMap = $self->idMap($type, $ids);
	    # Call through to the ID server.
	    my $kbMap = $self->idserver->external_ids_to_kbase_ids($realSource,
	            [map { $idMap->{$_} } @$ids]);
	    # Convert the modified IDs to the original IDs.
	    %retVal = map { $_ => $kbMap->{$idMap->{$_}} } @$ids;
    }
    # Return the result.
    return \%retVal;
}

=head3 GetKBaseIDs

    my $idHash = $loader->GetKBaseIDs($prefix, $type, \@ids);

Compute KBase IDs for all the specified foreign IDs from the specified
source. The KBase IDs will all have the indicated prefix, which must
begin with the string C<kb|>.

=over 4

=item prefix

Prefix to be put on all the IDs created. Must be a string beginning with
C<kb|>.

=item type

Type of object to which the IDs apply.

=item ids

Reference to a list of foreign IDs whose KBase IDs are desired. If
no KBase ID exists for a foreign ID, one will be created.

=item RETURN

Returns a reference to a hash mapping the foreign IDs to KBase IDs.

=back

=cut

sub GetKBaseIDs {
    # Get the parameters.
    my ($self, $prefix, $type, $ids) = @_;
    # Insure the IDs are a list reference.
    if (ref $ids ne 'ARRAY') {
        $ids = [$ids];
    }
    # Declare the return variable.
    my %retVal;
    # Are we in source ID mode?
    if ($self->{useSourceIDs}) {
    	# Yes. Return an identity mapping.
    	%retVal = map { $_ => $_ } @$ids;
    } else {
	    # Compute the real source and the real IDs.
	    my $realSource = $self->realSource($type);
	    my $idMap = $self->idMap($type, $ids);
	    # Call through to the ID server.
	    my @mapped = map { $idMap->{$_} } @$ids;
	    my $kbMap;
	    my $counter = 0;
	    while (! defined $kbMap) {
		    eval {
			    $kbMap = $self->idserver->register_ids($prefix, $realSource,
			            \@mapped);
		    };
		    if ($@) {
		    	my $msg = $@;
		    	if ($counter < 10 && $msg =~ /500\s+Internal\s+Server\s+Error/i) {
		    		print "Retrying ID server call.\n";
		    		$self->{stats}->Add(idServerRetry => 1);
		    		$counter++;
		    		sleep 1;
		    	} else {
			    	print "ID server error ($counter retries): $msg\n";
			    	print "ID server call: $prefix, $realSource; " . join(", ", @mapped) . "\n";
		    		die "ID server failed.";
		    	}
		    }
	    }
	    # Convert the modified IDs to the original IDs.
	    %retVal = map { $_ => $kbMap->{$idMap->{$_}} } @$ids;
    }
    # Return the result.
    return \%retVal;
}


=head3 GetKBaseID

    my $kbID = $loader->GetKBaseID($prefix, $type, $id);

Return the KBase ID for the specified foreign ID from the specified
source. If no such ID exists, one will be created with the specified
prefix (which must begin with the string C<kb|>).

=over 4

=item prefix

Prefix to be put on the ID created. Must be a string beginning with
C<kb|>.

=item type

Type of object to which the ID applies

=item id

Foreign ID whose KBase ID is desired.

=item RETURN

Returns the KBase ID for the specified foreign ID. If one did not
exist, it will have been created.

=back

=cut

sub GetKBaseID {
    # Get the parameters.
    my ($self, $prefix, $type, $id) = @_;
    # Ask the ID server for the ID.
    my $idHash = $self->GetKBaseIDs($prefix, $type, [$id]);
    # Return the result.
    return $idHash->{$id};
}

=head3 source

    my $source = $loader->source;

Return the source name associated with this load.

=cut

sub source {
    # Get the parameters.
    my ($self) = @_;
    # Return the source name.
    return $self->{sourceData}->name;
}

=head3 realSource

    my $realSource = $loader->realSource($type);

Return the object source name to be used when requesting an ID for
objects of the specified type. This is either the unmodified source
name or (for typed IDs) the source name suffixed with the object
type.

=over 4

=item type

Type of object for which IDs are being generated or retrieved.

=item RETURN

Returns a string to be used for requesting ID services related to
objects of the specified type.

=back

=cut

use constant MAJOR => { Genome => 1, Contig => 1, Feature => 1 };

sub realSource {
    # Get the parameters.
    my ($self, $type) = @_;
    # Start with the source name.
    my $retVal = $self->{sourceData}->name;
    # If we're typed, add the type.
    my $typeLevel = $self->{sourceData}->typed;
    if ($typeLevel == 2 || $typeLevel == 1 && ! MAJOR->{$type}) {
        $retVal .= ":$type";
    }
    # Return the result.
    return $retVal;
}


=head3 idMap

    my $idMap = $loader->idMap($type, \@ids);

Return a hash mapping each incoming source ID to the ID that should be
passed to the ID server in order to find its KBase ID. This is either
the raw ID or (if the source has genome-based IDs) the ID prefixed by
the current genome ID.

=over 4

=item type

Type of object for the IDs.

=item ids

Reference to a list of source IDs.

=item RETURN

Returns a reference to a hash mapping each incoming source ID to the ID that
should be used when looking it up on the ID server.

=back

=cut

sub idMap {
    # Get the parameters.
    my ($self, $type, $ids) = @_;
    # Declare the return hash.
    my %retVal;
    # Determine whether or not we are genome-based. Note that we are
    # never genome-based when looking for genome IDs.
    if ($self->{sourceData}->genomeBased && $type ne 'Genome') {
        # We are, so prefix the current genome ID.
        %retVal = map { $_ => "$self->{genome}:$_" } @$ids;
    } else {
        # We aren't, so use the IDs in their raw form.
        %retVal = map { $_ => $_ } @$ids;
    }
    # Return the result.
    return \%retVal;
}


1;
