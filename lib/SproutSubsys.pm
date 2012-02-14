#!/usr/bin/perl -w

package SproutSubsys;

    use strict;
    use Tracer;
    use PageBuilder;
    use FIG;
    use Sprout;

=head1 Sprout Subsystem Object

=head2 Introduction

This object emulates the capabilities of the FIG-style C<Subsystem> object, but
uses Sprout methods to retrieve the data. This object can be dropped in place of
the UnvSubsys object to create subsystem displays for the Sprout rather than the
SEED.

The structure created by the constructor contains the following data members.

=over 4

=item name

Name of the subsystem. This is needed for any further database accesses required.

=item curator

Name of the subsystem's official curator.

=item notes

General notes about the subsystem.

=item sprout

Sprout object for accessing the database. This is a genuine Sprout object, not
an SFXlate object.

=item genomeHash

Map of genome IDs to row indices.

=item genomes

List of [genomeID, variantCode] tuples in row order.

=item roleHash

Map of role IDs and abbreviations to column indices. In other words, plugging
either a full-blown role ID or its abbreviation into this hash will return
the role's column index.

=item roles

List of [roleID, abbreviation] tuples in column order.

=item dir

Directory root for the diagram and image files.

=item reactionHash

Map of role IDs to a list of the reactions catalyzed by the role.

=item colorHash

Map of PEG IDs to cluster numbers. This is used to create color maps for
display of a subsystem's PEGs.

=item hopeReactions

Map of roles to EC numbers for the Hope reactions. This object is not loaded
until it is needed.

=item rows

Map of spreadsheet rows, keyed by genome ID. Each row is a list of cells. Each
cell is a list of feature ID.

=item featureData

Hash mapping feature IDs to assigned functions.

=back

=cut

#: Constructor SproutSubsys->new();

=head2 Public Methods

=head3 new

    my $sub = SproutSubsys->new($subName, $sprout);

Load the subsystem.

=over 4

=item subName

Name of the desired subsystem.

=item sprout

Sprout or SFXlate object for accessing the Sprout data store.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $subName, $sprout) = @_;
    # Insure we have a Sprout object.
    if (ref $sprout eq 'SFXlate') {
        $sprout = $sprout->{sprout};
    }
    # Declare the return value.
    my $retVal;
    # Get the subsystem's object.
    my $subsystemObject = $sprout->GetEntity('Subsystem', $subName);
    if (! defined $subsystemObject) {
        # Here we're stuck.
        Confess("Subsystem \"$subName\" not found in database.");
    } else {
        # We've found it, so get the major data.
        my ($curator, $notes, $description, $version) = $subsystemObject->Values(['Subsystem(curator)', 'Subsystem(notes)',
                                                            'Subsystem(description)', 'Subsystem(version)']);
        # Get the genome IDs and variant codes for the rows. The list returned
        # by GetAll will be a list of 2-tuples, each consisting of a genome ID
        # and a subsystem variant code.
        my @genomes = $sprout->GetAll(['ParticipatesIn'],
                                      'ParticipatesIn(to-link) = ? ORDER BY ParticipatesIn(variant-code), ParticipatesIn(from-link)',
                                      [$subName], ['ParticipatesIn(from-link)',
                                                   'ParticipatesIn(variant-code)']);
        # Create the genome ID directory. This is a hash that maps a genome ID to its
        # row index.
        my $idx = 0;
        my %genomeHash = map { $_->[0] => $idx++ } @genomes;
        # Get the role IDs and abbreviations. The list returned by GetAll will be
        # a list of 2-tuples, each consisting of a role ID and abbreviation. The
        # 2-tuples will be ordered by the spreadsheet column number.
        my @roles = $sprout->GetAll(['OccursInSubsystem'],
                                    'OccursInSubsystem(to-link) = ? ORDER BY OccursInSubsystem(column-number)',
                                    [$subName], ['OccursInSubsystem(from-link)', 'OccursInSubsystem(abbr)',
                                                 'OccursInSubsystem(auxiliary)']);
        # Now we need to create the role ID directory, which maps role IDs and their
        # abbreviations to column numbers.
        my %roleHash = ();
        my %abbrHash = ();
        my %auxHash = ();
        for ($idx = 0; $idx <= $#roles; $idx++) {
            # Get the role ID, aux flag, and abbreviation for this column's role.
            my ($roleID, $abbr, $aux) = @{$roles[$idx]};
            # Put the ID and abbreviation in the role directory.
            $roleHash{$roleID} = $idx;
            $roleHash{$abbr} = $idx;
            # Put the aux flag in the aux hash.
            $auxHash{$roleID} = $aux;
            # Put the full name in the abbreviation directory.
            $abbrHash{$abbr} = $roleID;
        }
        # Find the subsystem directory.
        my $subDir = Subsystem::get_dir_from_name($subName);
        Trace("Subsystem directory is $subDir.") if T(3);
        # Create the subsystem object.
        $retVal = {
                    # Name of the subsystem. This is needed for any further database
                    # accesses required.
                    name => $subName,
                    # Directory root for diagram and image files.
                    dir => $subDir,
                    # Name of the subsystem's official curator.
                    curator => $curator,
                    # General notes about the subsystem.
                    notes => $notes,
                    # Sprout object for accessing the database.
                    sprout => $sprout,
                    # Map of genome IDs to row indices.
                    genomeHash => \%genomeHash,
                    # List of [genomeID, variantCode] tuples in row order.
                    genomes => \@genomes,
                    # Map of role IDs and abbreviations to column indices.
                    roleHash => \%roleHash,
                    # List of [roleID, abbreviation] tuples in column order.
                    roles => \@roles,
                    # Map of PEG IDs to cluster numbers.
                    colorHash => {},
                    # Map of abbreviations to role names.
                    abbrHash => \%abbrHash,
                    # Map of auxiliary rols.
                    auxHash => \%auxHash,
                    # Map of role IDs to reactions.
                    reactionHash => undef,
                    # Version number.
                    version => $version,
                    # Row hash, initially undefined.
                    rows => undef,
                    # Map of feature IDs to functional assignments
                    featureData => {},
                };
        # Bless and return it.
        bless $retVal, $class;
    }
    return $retVal;
}

=head3 is_aux_role

    my $flag = $sub->is_aux_role($roleID);

Return TRUE if the specified role is auxiliary to this subsystem, FALSE
if it is essential to it.

=over 4

=item roleID

ID of the relevant role.

=item RETURN

Returns TRUE if the specified role is auxiliary, else FALSE.

=back

=cut

sub is_aux_role {
    # Get the parameters.
    my ($self, $roleID) = @_;
    # Declare the return variable.
    my $retVal = $self->{auxHash}->{$roleID};
    # Return the result.
    return $retVal;
}


=head3 get_row

    my $rowData = $sub->get_row($rowIndex);

Return the specified row in the subsystem spreadsheet. The row consists
of a list of lists. Each position in the major list represents the role
for that position, and contains a list of the IDs for the features that
perform the role.

=over 4

=item rowIndex

Index of the row to return. A row contains data for a single genome.

=item RETURN

Returns a reference to a list of lists. Each element in the list represents
a spreadsheet column (role) and contains a list of features that perform the
role.

=back

=cut

sub get_row {
    # Get the parameters.
    my ($self, $rowIndex) = @_;
    # Get the genome ID for the specified row's genome.
    my $genomeID = $self->{genomes}->[$rowIndex]->[0];
    # Get the row hash.
    my $rowHash = $self->_get_spreadsheet();
    # Declare the return variable.
    my @retVal;
    # If this genome does not exist for the subsystem, all the cells are empty.
    if (! exists $rowHash->{$genomeID}) {
        @retVal = map { [] } @{$self->{roles}};
    } else {
        # Here we just return the row.
        push @retVal, @{$rowHash->{$genomeID}};
    }
    # Return the result.
    return \@retVal;
}

=head3 get_roles_for_genome

    my @roles = $sub->get_roles_for_genome($genome_id);

Return a list of the roles in this subsystem that have nonempty
spreadsheet cells for the given genome.

=over 4

=item genome_id

ID of the relevant genome.

=item RETURN

Returns a list of role IDs.

=back

=cut

sub get_roles_for_genome {
    # Get the parameters.
    my ($self, $genome_id) = @_;
    # Get the subsystem's spreadsheet.
    my $rowHash = $self->_get_spreadsheet();
    # Declare the return variable.
    my @retVal;
    # Only proceed if this genome exists for this subsyste,
    if (exists $rowHash->{$genome_id}) {
        # Get the role list.
        my $roles = $self->{roles};
        # Get the row's cell list.
        my $row = $rowHash->{$genome_id};
        # Loop through the cells. We'll save the role name for each
        # nonempty cell.
        my $cols = scalar @$roles;
        for (my $i = 0; $i < $cols; $i++) {
            my $cell = $row->[$i];
            if (scalar @$cell) {
                push @retVal, $roles->[$i][0];
            }
        }
    }
    # Return the result.
    return @retVal;
}

=head3 get_abbr_for_role

    my $abbr = $sub->get_abbr_for_role($name);

Get this subsystem's abbreviation for the specified role.

=over 4

=item name

Name of the relevant role.

=item RETURN

Returns the abbreviation for the role. Each subsystem has its own abbreviation
system; the abbreviations make it easier to display the subsystem spreadsheet.

=back

=cut

sub get_abbr_for_role {
    # Get the parameters.
    my ($self, $name) = @_;
    # Get the index for this role.
    my $idx = $self->get_role_index($name);
    # Return the abbreviation.
    return $self->get_role_abbr($idx);
}

=head3 get_subsetC

    my @columns = $sub->get_subsetC($subsetName);

Return a list of the column numbers for the columns in the named role
subset.

=over 4

=item subsetName

Name of the subset whose columns are desired.

=item RETURN

Returns a list of the indices for the columns in the named subset.

=back

=cut

sub get_subsetC {
    # Get the parameters.
    my ($self, $subsetName) = @_;
    # Get the roles in the subset.
    my @roles = $self->get_subsetC_roles($subsetName);
    # Convert them to indices.
    my $roleHash = $self->{roleHash};
    my @retVal = map { $roleHash->{$_} } @roles;
    # Return the result.
    return @retVal;
}

=head3 get_genomes

    my @genomeList = $sub->get_genomes();

Return a list of the genome IDs for this subsystem. Each genome corresponds to a row
in the subsystem spreadsheet. Indexing into this list returns the ID of the genome
in the specified row.

=cut

sub get_genomes {
    # Get the parameters.
    my ($self) = @_;
    # Return a list of the genome IDs. The "genomes" member contains a 2-tuple
    # with the genome ID followed by the variant code. We only return the
    # genome IDs.
    my @retVal = map { $_->[0] } @{$self->{genomes}};
    return @retVal;
}

=head3 get_variant_code

    my $code = $sub->get_variant_code($gidx);

Return the variant code for the specified genome. Each subsystem has multiple
variants which involve slightly different chemical reactions, and each variant
has an associated variant code. When a genome is connected to the spreadsheet,
the subsystem variant used by the genome must be specified.

=over 4

=item gidx

Row index for the genome whose variant code is desired.

=item RETURN

Returns the variant code for the specified genome.

=back

=cut

sub get_variant_code {
    # Get the parameters.
    my ($self, $gidx) = @_;
    # Extract the variant code for the specified row index. It is the second
    # element of the tuple from the "genomes" member.
    my $retVal = $self->{genomes}->[$gidx]->[1];
    return $retVal;
}

=head3 get_curator

    my $userName = $sub->get_curator();

Return the name of this subsystem's official curator.

=cut

sub get_curator {
    # Get the parameters.
    my ($self) = @_;
    # Return the curator member.
    return $self->{curator};
}

=head3 get_notes

    my $text = $sub->get_notes();

Return the descriptive notes for this subsystem.

=cut

sub get_notes {
    # Get the parameters.
    my ($self) = @_;
    # Return the notes member.
    return $self->{notes};
}

=head3 get_description

    my $text = $sub->get_description();

Return the description for this subsystem.

=cut

sub get_description
{
    my($self) = @_;
    return $self->{description};
}

=head3 get_roles

    my @roles = $sub->get_roles();

Return a list of the subsystem's roles. Each role corresponds to a column
in the subsystem spreadsheet. The list entry at a specified position in
the list will contain the ID of that column's role.

=cut

sub get_roles {
    # Get the parameters.
    my ($self) = @_;
    # Return the list of role IDs. The role IDs are stored as the first
    # element of each 2-tuple in the "roles" member.
    my @retVal = map { $_->[0] } @{$self->{roles}};
    return @retVal;
}

=head3 get_reactions

    my $reactHash = $sub->get_reactions();

Return a reference to a hash that maps each role ID to a list of the reactions
catalyzed by the role.

=cut

sub get_reactions {
    # Get the parameters.
    my ($self) = @_;
    # Do we already have a reaction hash?
    my $retVal = $self->{reactionHash};
    if (! $retVal) {
        # No, so we'll build it.
        $retVal = {};
        my $sprout = $self->{sprout};
        for my $roleID ($self->get_roles()) {
            # Get this role's reactions.
            my @reactions = $sprout->GetFlat(['Catalyzes'], 'Catalyzes(from-link) = ?',
                                             [$roleID], 'Catalyzes(to-link)');
            # Put them in the reaction hash.
            if (@reactions > 0) {
                $retVal->{$roleID} = \@reactions;
            }
        }
        # Save it for future use.
        $self->{reactionHash} = $retVal;
    }
    # Return the reaction hash.
    return $retVal;
}

=head3 get_subset_namesC

    my @subsetNames = $sub->get_subset_namesC();

Return a list of the names for all the column (role) subsets. Given a subset
name, you can use the L</get_subsetC_roles> method to get the roles in the
subset.

=cut

sub get_subset_namesC {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object and use it to retrieve the subset names.
    my $sprout = $self->{sprout};
    my @subsets = $sprout->GetFlat(['HasRoleSubset'], 'HasRoleSubset(from-link) = ?',
                                   [$self->{name}], 'HasRoleSubset(to-link)');
    # The sprout subset names are prefixed by the subsystem name. We need to pull the
    # prefix off before we return the results. The prefixing character is a colon (:),
    # so we search for the last colon to get ourselves the true subset name.
    my @retVal = map { $_ =~ /:([^:]+)$/; $1 } @subsets;
    return @retVal;
}

=head3 get_subset_names

    my @subsetNames = $sub->get_subset_names();

Return the names of the column subsets.

=cut

sub get_subset_names{
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->get_subset_namesC();
}

=head3 get_role_abbr

    my $abbr = $sub->get_role_abbr($ridx);

Return the abbreviation for the role in the specified column. The abbreviation
is a shortened identifier that is not necessarily unique, but is more likely to
fit in a column heading.

=over 4

=item ridx

Column index for the role whose abbreviation is desired.

=item RETURN

Returns an abbreviated name for the role corresponding to the indexed column.

=back

=cut

sub get_role_abbr {
    # Get the parameters.
    my ($self, $ridx) = @_;
    # Return the role abbreviation. The abbreviation is the second element
    # in the 2-tuple for the specified column in the "roles" member.
    my $retVal = $self->{roles}->[$ridx]->[1];
    return $retVal;
}


=head3 get_hope_reactions_for_genome

    my %ss_reactions = $subsys->get_hope_reactions_for_genome($genome);

This method returns a hash that maps reactions to the pegs that catalyze
them for the specified genome. For each role in the subsystem, the pegs
are computed, and these are attached to the reactions for the role.

=over 4

=item genome

ID of the genome whose reactions are to be put into the hash.

=item RETURN

Returns a hash mapping reactions in the subsystem to pegs in the
specified genome, or an empty hash if the genome is not found in the
subsystem.

=back

=cut

sub get_hope_reactions_for_genome {
    # Get the parameters.
    my($self, $genome) = @_;
    # Declare the return variable.
    my %retVal;
    # Look for the genome in our spreadsheet.
    my $index = $self->get_genome_index($genome);
    # Only proceed if we found it.
    if (defined $index) {
        # Extract the roles.
        my @roles = $self->get_roles;
        # Get the hope reaction hash. For each role, this gives us a list
        # of reactions.
        my %hope_reactions = $self->get_hope_reactions();
        # Loop through the cells in this genome's role.
        for my $role (@roles) {
            # Get the features in this role's cell.
            my @peg_list = $self->get_pegs_from_cell($genome,$role);
            # Only proceed if we have hope reactions AND pegs for this role.
            if (defined $hope_reactions{$role} && scalar @peg_list > 0) {
                # Loop through the reactions, pushing the pegs in this cell onto
                # the reaction's peg list.
                for my $reaction (@{$hope_reactions{$role}}) {
                    push @{$retVal{$reaction}}, @peg_list;
                }
            }
        }
    }
    # Return the result.
    return %retVal;
}


=head3 get_hope_additional_reactions

    my %ss_reactions = $subsys->get_hope_additional_reactions($scenario_name);

Return a list of the additional reactions for the specified scenario.

=over 4

=item scenario_name

Name of the scenario whose additional reactions are desired.

=item RETURN

Returns a list of the additional reactions attached to the named scenario.

=back

=cut

sub get_hope_additional_reactions {
    # Get the parameters.
    my($self, $scenario_name) = @_;
    # Ask the database for this scenario's additional reactions.
    my @retVal = $self->{sprout}->GetFlat(['IncludesReaction'], "IncludesReaction(from-link) = ?",
                                          [$scenario_name], 'IncludesReaction(to-link)');
    return @retVal;
}


=head3 get_hope_reactions

    my %reactionHash = $subsys->get_hope_reactions();

Return a hash mapping the roles of this subsystem to the EC numbers for
the reactions used in scenarios (if any). It may return an empty hash
if the Hope reactions are not yet known.

=cut

sub get_hope_reactions {
    # Get the parameters.
    my ($self) = @_;
    # Try to get the hope reactions from the object.
    my $retVal = $self->{hopeReactions};
    if (! defined($retVal)) {
        # They do not exist, so we must create them. Make a copy of the role-to-reaction
        # hash.
        my %hopeHash = %{$self->get_reactions()};
        # Insure we have it if we need it again.
        $retVal = \%hopeHash;
        $self->{hopeReactions} = $retVal;
    }
    # Return the result.
    return %{$retVal};
}

=head3 get_hope_reaction_notes

    my %roleHash = $sub->get_hope_reaction_notes();

Return a hash mapping the roles of the subsystem to any existing notes
about the relevant reactions.

=cut

sub get_hope_reaction_notes {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my %retVal;
    # Get the database object.
    my $sprout = $self->{sprout};
    # Get our name.
    my $ssName = $self->{name};
    # Loop through the roles, getting each role's hope notes.
    for my $role ($self->get_roles()) {
        my ($note) = $self->get_hope_reaction_note($role);
        # If this role had a nonempty note, stuff it in the hash.
        if ($note) {
            $retVal{$role} = $note;
        }
    }
    # Return the result.
    return %retVal;
}

=head3 get_hope_reaction_note

    my $note = $sub->get_hope_reaction_note($role);

Return the text note about the curation of the scenario reactions
relating to this role.

=over 4

=item role

ID of the role whose note is desired.

=item RETURN

Returns the relevant role's note for this subsystem's hope reactions, or FALSE (empty string
or undefined) if no such note was found.

=back

=cut

sub get_hope_reaction_note {
    # Get the parameters.
    my ($self, $role) = @_;
    # Ask the database for the note.
    my ($retVal) = $self->{sprout}->GetFlat(['OccursInSubsystem'],
                                            "OccursInSubsystem(from-link) = ? AND OccursInSubsystem(to-link) = ?",
                                            [$role, $self->{name}], 'OccursInSubsystem(hope-reaction-note)');
    # Return the result.
    return $retVal;
}

=head3 get_role_index

    my $idx = $sub->get_role_index($role);

Return the column index for the role with the specified ID.

=over 4

=item role

ID (full name) or abbreviation of the role whose column index is desired.

=item RETURN

Returns the column index for the role with the specified name or abbreviation.

=back

=cut

sub get_role_index {
    # Get the parameters.
    my ($self, $role) = @_;
    # The role index is directly available from the "roleHash" member.
    my $retVal = $self->{roleHash}->{$role};
    return $retVal;
}

=head3 get_subsetC_roles

    my @roles = $sub->get_subsetC_roles($subname);

Return the names of the roles contained in the specified role (column) subset.

=over 4

=item subname

Name of the role subset whose roles are desired.

=item RETURN

Returns a list of the role names for the columns in the named subset.

=back

=cut

sub get_subsetC_roles {
    # Get the parameters.
    my ($self, $subname) = @_;
    # Get the sprout object. We need it to be able to get the subset data.
    my $sprout = $self->{sprout};
    # Convert the subset name to Sprout format. In Sprout, the subset name is
    # prefixed by the subsystem name in order to get a unique subset ID.
    my $subsetID = $self->{name} . ":$subname";
    # Get a list of the role names for this subset.
    my @roleNames = $sprout->GetFlat(['ConsistsOfRoles'], 'ConsistsOfRoles(from-link) = ?',
                                  [$subsetID], 'ConsistsOfRoles(to-link)');
    # Sort them by column number. We get the column number from the role hash.
    my $roleHash = $self->{roleHash};
    my @retVal = sort { $roleHash->{$a} <=> $roleHash->{$b} } @roleNames;
    # Return the sorted list.
    return @retVal;
}

=head3 get_genome_index

    my $idx = $sub->get_genome_index($genome);

Return the row index for the genome with the specified ID.

=over 4

=item genome

ID of the genome whose row index is desired.

=item RETURN

Returns the row index for the genome with the specified ID, or an undefined
value if the genome does not participate in the subsystem.

=back

=cut

sub get_genome_index {
    # Get the parameters.
    my ($self, $genome) = @_;
    # Get the genome row index from the "genomeHash" member.
    my $retVal = $self->{genomeHash}->{$genome};
    return $retVal;
}

=head3 get_cluster_number

    my $number = $sub->get_cluster_number($pegID);

Return the cluster number for the specified PEG, or C<-1> if the
cluster number for the PEG is unknown or it is not clustered.

=over 4

=item pegID

ID of the PEG whose cluster number is desired.

=item RETURN

Returns the appropriate cluster number.

=back

=cut
#: Return Type $;
sub get_cluster_number {
    # Get the parameters.
    my ($self, $pegID) = @_;
    # Declare the return variable.
    my $retVal = -1;
    # Insure we have a color hash.
    $self->_get_spreadsheet();
    # Check for a cluster number in the color hash.
    if (exists $self->{colorHash}->{$pegID}) {
        $retVal = $self->{colorHash}->{$pegID};
    }
    # Return the result.
    return $retVal;
}


=head3 get_pegs_from_cell

    my @pegs = $sub->get_pegs_from_cell($rowstr, $colstr);

Return a list of the peg IDs for the features in the specified spreadsheet cell.

=over 4

=item rowstr

Genome row, specified either as a row index or a genome ID.

=item colstr

Role column, specified either as a column index, a role name, or a role
abbreviation.

=item RETURN

Returns a list of PEG IDs. The PEGs in the list belong to the genome in the
specified row and perform the role in the specified column. If the indicated
row and column does not exist, returns an empty list.

=back

=cut

sub get_pegs_from_cell {
    # Get the parameters.
    my ($self, $rowstr, $colstr) = @_;
    # Get the sprout object for accessing the database.
    my $sprout = $self->{sprout};
    # We need to convert the incoming row and column identifiers. We need a
    # numeric column index and a character genome ID to create the ID for the
    # subsystem spreadsheet cell. First, the column index: note that our version
    # of "get_role_index" conveniently works for both abbreviations and full role IDs.
    my $colIdx = ($colstr =~ /^(\d+)$/ ? $colstr : $self->get_role_index($colstr));
    # Next the genome ID. In this case, we convert any number we find to a string.
    # This requires a little care to avoid a run-time error if the row number is
    # out of range.
    my $genomeID = $rowstr;
    if ($rowstr =~ /^(\d+)$/) {
        # Here we need to convert the row number to an ID. Insure the number is in
        # range. Note that if we do have a row number out of range, the genome ID
        # will be invalid, and our attempt to read from the database will return an
        # empty list.
        my $genomeList = $self->{genomes};
        if ($rowstr >= 0 && $rowstr < @{$genomeList}) {
            $genomeID = $genomeList->[$rowstr]->[0];
        }
    }
    # Get the spreadsheet.
    my $rowHash = $self->_get_spreadsheet();
    # Delcare the return variable.
    my @retVal;
    # Only proceed if this genome is in this subsystem.
    if (exists $rowHash->{$genomeID}) {
        # Push the cell's contents into the return list.
        push @retVal, @{$rowHash->{$genomeID}->[$colIdx]};
    }
    # Return the list. If the spreadsheet cell was empty or non-existent, we'll end
    # up returning an empty list.
    return @retVal;
}

=head3 get_subsetR

    my @genomes = $sub->get_subsetR($subName);

Return the genomes in the row subset indicated by the specified subset name.

=over 4

=item subName

Name of the desired row subset, or C<All> to get all of the rows.

=item RETURN

Returns a list of genome IDs corresponding to the named subset.

=back

=cut

sub get_subsetR {
    # Get the parameters.
    my ($self, $subName) = @_;
    # Look for the specified row subset in the database. A row subset is identified using
    # the subsystem name and the subset name. The special subset "All" is actually
    # represented in the database, so we don't need to check for it.
    my @rows = $self->{sprout}->GetFlat(['ConsistsOfGenomes'], "ConsistsOfGenomes(from-link) = ?",
                                        ["$self->{name}:$subName"], 'ConsistsOfGenomes(to-link)');
    return @rows;
}

=head3 get_diagrams

    my @list = $sub->get_diagrams();

Return a list of the diagrams associated with this subsystem. Each diagram
is represented in the return list as a 4-tuple C<[diagram_id, diagram_name,
page_link, img_link]> where

=over 4

=item diagram_id

ID code for this diagram.

=item diagram_name

Displayable name of the diagram.

=item page_link

URL of an HTML page containing information about the diagram.

=item img_link

URL of an HTML page containing an image for the diagram.

=back

Note that the URLs are in fact for CGI scripts with parameters that point them
to the correct place. Though Sprout has diagram information in it, it has
no relationship to the diagrams displayed in SEED, so the work is done entirely
on the SEED side.

=cut

sub get_diagrams {
    # Get the parameters.
    my ($self) = @_;
    # Get the diagram IDs.
    my @diagramIDs = Subsystem::GetDiagramIDs($self->{dir});
    Trace("Diagram IDs are " . join(", ", @diagramIDs)) if T(3);
    # Create the return variable.
    my @retVal = ();
    # Loop through the diagram IDs.
    for my $diagramID (@diagramIDs) {
        Trace("Processing diagram $diagramID.") if T(3);
        my ($name, $link, $imgLink) = $self->get_diagram($diagramID);
        Trace("Diagram $name URLs are \"$link\" and \"$imgLink\".") if T(3);
        push @retVal, [$diagramID, $name, $link, $imgLink];
    }
    # Return the result.
    return @retVal;
}

=head3 get_diagram

    my ($name, $pageURL, $imgURL) = $sub->get_diagram($id);

Get the information (if any) for the specified diagram. The diagram corresponds
to a subdirectory of the subsystem's C<diagrams> directory. For example, if the
diagram ID is C<d03>, the diagram's subdirectory would be C<$dir/diagrams/d03>,
where I<$dir> is the subsystem directory. The diagram's name is extracted from
a tiny file containing the name, and then the links are computed using the
subsystem name and the diagram ID. The parameters are as follows.

=over 4

=item id

ID code for the desired diagram.

=item RETURN

Returns a three-element list. The first element is the diagram name, the second
a URL for displaying information about the diagram, and the third a URL for
displaying the diagram image.

=back

=cut

sub get_diagram {
    my($self, $id) = @_;
    my $name = Subsystem::GetDiagramName($self->{dir}, $id);
    my ($link, $img_link) = Subsystem::ComputeDiagramURLs($self, $self->{name}, $id, 1);
    return($name, $link, $img_link);
}


=head3 get_diagram_html_file

    my $fileName = $sub->get_diagram_html_file($id);

Get the HTML file (if any) for the specified diagram. The diagram corresponds
to a subdirectory of the subsystem's C<diagrams> directory. For example, if the
diagram ID is C<d03>, the diagram's subdirectory would be C<$dir/diagrams/d03>,
where I<$dir> is the subsystem directory. If an HTML file exists, it will be
named C<diagram.html> in the diagram directory.  The parameters are as follows.

=over 4

=item id

ID code for the desired diagram.

=item RETURN

Returns the name of an HTML diagram file, or C<undef> if no such file exists.

=back

=cut

sub get_diagram_html_file {
    my ($self, $id) = @_;
    my $retVal;
    my $ddir = "$self->{dir}/diagrams/$id";
    Trace("Looking for diagram file at $ddir.") if T(3);
    if (-d $ddir) {
        my $html = "$ddir/diagram.html";
        if (-f $html) {
            $retVal = $html;
        }
    }
    return $retVal;
}

=head3 is_new_diagram

    my $flag = $sub->is_new_diagram($id);

Return TRUE if the specified diagram is in the new format, else FALSE.

=over 4

=item id

ID code (e.g. C<d03>) of the relevant diagram.

=item RETURN

Returns TRUE if the diagram is in the new format, else FALSE.

=back

=cut

sub is_new_diagram {
  my ($self, $id) = @_;

  my $image_map = $self->get_diagram_html_file($id);
  if ($image_map) {
    Trace("Image map found for diagram $id at $image_map.") if T(3);
    Open(\*IN, "<$image_map");
    my $header = <IN>;
    close(IN);

    if ($header =~ /\<map name=\"GraffleExport\"\>/) {
      return 1;
    }
  }

  return undef;
}

=head3 get_role_from_abbr

    my $roleName = $sub->get_role_from_abbr($abbr);

Return the role name corresponding to an abbreviation.

=over 4

=item abbr

Abbreviation name of the relevant role.

=item RETURN

Returns the full name of the specified role.

=back

=cut

sub get_role_from_abbr {
    # Get the parameters.
    my($self, $abbr) = @_;
    # Get the role name from the abbreviation hash.
    my $retVal = $self->{abbrHash}->{$abbr};
    # Check for a case incompatability.
    if (! defined $retVal) {
        $retVal = $self->{abbrHash}->{lcfirst $abbr};
    }
    # Return the result.
    return $retVal;
}


=head3 get_name

    my $name = $sub->get_name();

Return the name of this subsystem.

=cut

sub get_name {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{name};
}

=head3 open_diagram_image

    my ($type, $fh) = $sub->open_diagram_image($id);

Open a diagram's image file and return the type and file handle.

=over 4

=item id

ID of the desired diagram

=item RETURN

Returns a 2-tuple containing the diagram's MIME type and an open filehandle
for the diagram's data. If the diagram does not exist, the type will be
returned as <undef>.

=back

=cut

sub open_diagram_image {
    # Get the parameters.
    my ($self, $id) = @_;
    # Declare the return variables.
    my ($type, $fh);
    # Get the diagram directory.
    my $img_base = "$self->{dir}/diagrams/$id/diagram";
    # Get a list of file extensions and types.
    my %types = (png => "image/png",
                 gif => "image/gif",
                 jpg => "image/jpeg");
    # This is my new syntax for the for-each-while loop.
    # We loop until we run out of keys or come up with a type value.
    for my $ext (keys %types) { last if (defined $type);
        my $myType = $types{$ext};
        # Compute a file name for this diagram.
        my $file = "$img_base.$ext";
        # If it exists, try to open it.
        if (-f $file) {
            $fh = Open(undef, "<$file");
            $type = $myType;
        }
    }
    # Return the result.
    return ($type, $fh);
}

=head3 get_hope_scenario_names

    my @names = $sub->get_hope_scenario_names();

Return a list of the names for the scenarios associated with this
subsystem.

=cut

sub get_hope_scenario_names {
    # Get the parameters.
    my ($self) = @_;
    # Get the names from the database.
    my $sprout = $self->{sprout};
    my @retVal = $sprout->GetFlat("HasScenario",
                                  "HasScenario(from-link) = ? ORDER BY HasScenario(to-link)",
                                  [$self->{name}], 'to-link');
    # Return the result.
    return @retVal;
}

=head3 get_hope_input_compounds

    my @compounds = $sub->get_hope_input_compounds($name);

Return a list of the input compounds for the named hope scenario.

=over 4

=item name

Name of a Hope scenario attached to this subsystem.

=item RETURN

Returns a list of compound IDs.

=back

=cut

sub get_hope_input_compounds {
    # Get the parameters.
    my ($self, $name) = @_;
    # Ask for the compounds.
    my @retVal = $self->{sprout}->GetFlat("IsInputFor", "IsInputFor(to-link) = ?",
                                          [$name], "IsInputFor(from-link)");
    # Return the result.
    return @retVal;
}

=head3 get_hope_output_compounds

    my ($main, $aux) = $sub->get_hope_output_compounds($name);

Return a list of the output compounds for the named hope scenario.

=over 4

=item name

Name of the relevant scenario.

=item RETURN

Returns two lists of compound IDs: one for the main outputs and one for the
auxiliary outputs.

=back

=cut

sub get_hope_output_compounds {
    # Get the parameters.
    my ($self, $name) = @_;
    # Ask for the compounds.
    my $sprout = $self->{sprout};
    my @pairs = $sprout->GetAll("IsOutputOf", "IsOutputOf(to-link) = ?",
                                [$name], "from-link auxiliary");
    # We now have a list of pairs in the form [name, aux-flag]. We put each
    # name in the list indicated by its aux-flag.
    my @retVal = ([], []);
    for my $pair (@pairs) {
        push @{$retVal[$pair->[1]]}, $pair->[0];
    }
    # Return the result.
    return @retVal;
}

=head3 get_hope_map_ids

    my @mapIDs = $sub->get_hope_map_ids($name);

Return a list of the ID numbers for the diagrams associated with the named
scenario.

=over 4

=item name

Name of the relevant scenario.

=item RETURN

Returns a list of the ID numbers for the KEGG diagrams associated with this
scenario. These are different from the diagram IDs, all of which begin with
the string "map". This recognizes a design incompatability between SEED and
Sprout.

=back

=cut

sub get_hope_map_ids {
    # Get the parameters.
    my ($self, $name) = @_;
    # Get the map IDs.
    my @diagrams = $self->{sprout}->GetFlat('IsOnDiagram', "IsOnDiagram(from-link) = ?",
                                            [$name], 'to-link');
    # Modify and return the result.
    my @retVal = map { /(\d+)/ } @diagrams;
    return @retVal;
}

=head3 all_functions

    my $pegRoles = $sub->all_functions();

Return a hash of all the features in the subsystem. The hash maps each
feature ID to its functional assignment.

=cut

sub all_functions {
    # Get the parameters.
    my ($self) = @_;
    # Insure we have a spreadsheet.
    $self->_get_spreadsheet();
    # Return the feature hash.
    return $self->{featureData};
}

=head2 Internal Utility Methods

=head3 _get_spreadsheet

    my $hash = $sub->_get_spreadsheet();

Return a reference to a hash mapping each of the subsystem's genomes to
their spreadsheet rows. Each row is a list of cells, and each cell is a
list of feature IDs. This method also creates the color hash that maps PEGs
to cluster numbers.

=cut

sub _get_spreadsheet {
    # Get the parameters.
    my ($self) = @_;
    # Do we already have a spreadsheet?
    my $retVal = $self->{rows};
    if (! defined $retVal) {
        # We don't, so we have to create one. Start with an empty hash.
        $retVal = {};
        # Ask for all the subsystem's cells and their features.
        my $query = $self->{sprout}->Get("HasSSCell SSCell ContainsFeature Feature",
                                         "HasSSCell(from-link) = ?",
                                         [$self->{name}]);
        # Loop through the features.
        while (my $feature = $query->Fetch()) {
            # Get the column number, the feature ID, and the cluster number.
            my $featureID = $feature->PrimaryValue('ContainsFeature(to-link)');
            my $cluster = $feature->PrimaryValue('ContainsFeature(cluster-number)');
            my $column = $feature->PrimaryValue('SSCell(column-number)');
            my $role = $feature->PrimaryValue('Feature(assignment)');
            # Compute the genome.
            my $genomeID = FIG::genome_of($featureID);
            # If we don't have this genome in the hash, create it.
            if (! exists $retVal->{$genomeID}) {
                # The initial value is a list of empty lists. Features
                # are then pushed into each individual list.
                my @row = map { [] } @{$self->{roles}};
                # Put this list of null lists in the hash.
                $retVal->{$genomeID} = \@row;
            }
            # Get this row. We know now that it exists.
            my $row = $retVal->{$genomeID};
            # Add this feature to the appropriate cell in the row.
            push @{$row->[$column]}, $featureID;
            # Put it in the color hash and the feature data hash.
            $self->{colorHash}->{$featureID} = $cluster;
            $self->{featureData}->{$featureID} = $role;
        }
        # Save the row hash.
        $self->{rows} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 get_col

    my $cellArray = $sub->get_col($idx);

Return an array of the cells in the specified column of the subsystem
spreadsheet. Each cell is a reference to a list of the features for the
corresponding row in the specified column.

=over 4

=item idx

Index of the desired column.

=item RETURN

Returns a reference to a list containing the spreadsheet column's cells, in
row order.

=back

=cut

sub get_col {
    # Get the parameters.
    my ($self, $idx) = @_;
    # Declare the return variable.
    my @retVal;
    # Get the subsystem spreadsheet.
    my $sheet = $self->_get_spreadsheet();
    # Loop through the row list.
    for my $rowPair (@{$self->{genomes}}) {
        # Get the genome for this row. Each row pair is [genomeID, variantCode].
        my ($genomeID) = @$rowPair;
        # Get the genome's row in the spreadsheet.
        my $rowList = $sheet->{$genomeID};
        # Push this column's cell into the output list.
        push @retVal, $rowList->[$idx];
    }
    # Return the result.
    return \@retVal;
}

1;
