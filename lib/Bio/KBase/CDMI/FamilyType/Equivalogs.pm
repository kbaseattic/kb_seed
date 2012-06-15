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
    my ($filter, $parms, $type) = ('AssertsFunctionFor(external-id) = ?', 
            [$memberID], "Raw");
    if ($memberID =~ /^GP\|([^|]+)\|([^\/]+)/) {
        # This is a special ID format where the real ID follows an ID of
        # a type we don't understand.
        $parms = [$2];
        $type = 'GP';
    } elsif ($memberID =~ /^(\w+)\|([^\/|]+)/) {
        # This is the standard ID format. We have a prefixed identifier
        # terminated by a slash or vertical bar. The prefix may need to
        # be changed.
        my ($prefix, $suffix) = ($1, $2);
        if ($prefix eq 'OMNI') {
            $filter .= ' AND AssertsFunctionFor(from-link) = ?';
            $parms = [$2, 'CMR'];
            $type = 'OMNI';
        } elsif ($prefix eq 'GB') {
            $parms = ["gb|$2"];
            $type = 'GB';
        } elsif ($prefix eq 'PIR') {
            $parms = ["pir||$2"];
            $type = 'PIR';
        } elsif ($prefix eq 'RF') {
            $parms = ["ref|$2"];
            $type = 'RF';
        } elsif ($prefix eq 'SP') {
            $filter = 'AssertsFunctionFor(external-id) LIKE ?';
            $parms = ['sp|$2|%'];
            $type = 'SP';
        } elsif ($prefix eq 'gi') {
            $filter = 'AssertsFunctionFor(gi-number) = ?';
            $parms = [$2];
            $type = 'GI';
        } else {
            $parms = [(lc $1) . "|$2"];
            $type = 'Unknown';
        }
    } elsif ($memberID =~ /^([^|\/]+)/) {
        # Here we have an unprefixed identifier, which is handled unmodified.
        $parms = [$1];
        $type = 'Unprefixed';
    }
    # Look for the protein in the database.
    my ($retVal) = $cdmi->GetFlat('AssertsFunctionFor', $filter, $parms,
            'to-link');
    # Track whether or not we found it.
    if ($retVal) {
        $stats->Add("proteinFound$type" => 1);
        $stats->Add(proteinFound => 1);
    } else {
        print STDERR "$memberID not found.\n";
        $stats->Add("proteinNotFound$type" => 1);
        $stats->Add(proteinNotFound => 1);
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
