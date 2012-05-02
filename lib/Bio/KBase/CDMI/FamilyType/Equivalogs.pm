package Bio::KBase::CDMI::FamilyType::Equivalogs;

    use strict;
    use base qw(Bio::KBase::CDMI::FamilyType);

=head1 Equivalog Family Type Subclass

This subclass is used to load FIGfams from L<CDMILoadFamilies.pl>.
Equivalogs are protein-based, and the additional data is in the form
of alignments stored in subdirectories.

=head2 Special Methods

    my $ffType = Bio::KBase::CDMI::FamilyType::Equivalogs->new($release);

Create a new Equivalogs family-type object.

=over 4

=item release

Release code for the Equivalogs being loaded.

=cut

sub new {
    # Get the parameters.
    my ($class, $release) = @_;
    # Construct the object from the base class.
    my $retVal = Bio::KBase::CDMI::FamilyType::new($class, 'equivalog',
            $release);
    # Return the result.
    return $retVal;
}

=head2 Virtual Override Methods

=head3 ResolveProteinMember

    my $idHash = $familyType->ResolveProteinMember($loader, $memberID);

Compute the KBase ID for the specified protein member ID. The member IDs
for equivalogs are complex and most require conversion. To translate the
IDs to KBase protein IDs, we use the B<AssertsFunctionFor> relationship.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for this load.

=item memberID

Family member ID to translate.

=item RETURN

Returns the KBase protein ID for the member, or C<undef> if the protein
is not in the database.

=back

=cut

sub ResolveProteinMember {
    # Get the parameters.
    my ($self, $loader, $memberID) = @_;
    # Get the CDMI database and the statistics object.
    my $cdmi = $loader->cdmi;
    my $stats = $loader->stats;
    # Parse the ID to determine how to convert it to a form we would find
    # in the database. If we don't parse it successfully, we will try it
    # unmodified.
    my $realID = $memberID;
    if ($memberID =~ /^(\w+)\|([^\/|]+)/) {
        # This is the standard ID format. We have a prefixed identifier
        # terminated by a slash or vertical bar. The prefix may need to
        # be changed.
        my ($prefix, $suffix) = ($1, $2);
        if ($prefix eq 'OMNI') {
            $realID = "cmr|$2";
            $stats->Add(proteinCMR => 1);
        } elsif ($prefix eq 'GB') {
            $realID = "gb|$2";
            $stats->Add(proteinGB => 1);
        } elsif ($prefix eq 'PIR') {
            $realID = "pir||$2";
            $stats->Add(proteinPIR => 1);
        } elsif ($prefix eq 'RF') {
            $realID = $2;
            $stats->Add(proteinRF => 1);
        } else {
            $realID = (lc $1) . "|$2";
            $stats->Add(proteinPrefixUnknown => 1);
        }
    } elsif ($memberID =~ /^([^|\/]+)/) {
        # Here we have an unprefixed identifier, which is handled unmodified.
        $realID = $1;
        $stats->Add(proteinUnprefixed => 1);
    }
    # Look for the protein in the database.
    my ($retVal) = $cdmi->GetFlat('AssertsFunctionFor',
            'AssertsFunctionFor(external-id) = ?', [$realID],
            'to-link');
    # Track whether or not we found it.
    if ($retVal) {
        $stats->Add(proteinMemberFound => 1);
    } else {
        $stats->Add(proteinMemberNotFound => 1);
    }
    # Return the result.
    return $retVal;
}


=head3 ProcessAdditionalFiles

    $familyType->ProcessAdditionalFiles($loader, $directory);

Process additional files in the specified directory. This method
handles files aside from the two standard files used to load
families. For Equivalogs, these are the alignment files. The
alignment files are stored in a directory called C<Alignments>
under the release directory. For each family, there is a file
whose name is the same as the family name with the extension C<.fasta>.
The text of the file is stored as the alignment text.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for the current load.

=item directory

Name of the directory containing the load files.

=back

=cut

sub ProcessAdditionalFiles {
    # Get the parameters.
    my ($self, $loader, $directory) = @_;
    # Get the statistics object.
    my $stats = $loader->stats;
    print "Processing alignments for $directory.\n";
    # Get a list of the alignment files.
    opendir(TMP, "$directory/Alignments") || die "Could not open alignments directory.\n";
    my @files = sort grep { $_ =~ /^TIGR\d+\.fasta$/ } readdir(TMP);
    print scalar(@files) . " entries found in alignments directory.\n";
    # Loop through them, creating the alignment records.
    for my $file (@files) {
        # Extract the family ID.
        my ($family) = split /\./, $file;
        # Read in the alignment text.
        open(my $ih, "<$directory/Alignments/$file") || die "Could not open alignment file $file: $!\n";
        $stats->Add(alignmentFileIn => 1);
        my @lines;
        push @lines, <$ih>;
        $stats->Add(alignmentLineIn => scalar(@lines));
        # Add it to the family.
        $loader->InsertObject('FamilyAlignment', id => $family,
                alignment => join("", @lines));
        $stats->Add(familyAlignmentAdded => 1);
    }
}

1;
