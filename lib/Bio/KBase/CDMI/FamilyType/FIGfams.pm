package Bio::KBase::CDMI::FamilyType::FIGfams;

    use strict;
    use base qw(Bio::KBase::CDMI::FamilyType);

=head1 FIGfam Family Type Subclass

This subclass is used to load FIGfams from L<CDMILoadFamilies.pl>.
FIGfams are feature-based, and the additional data is in the form
of coupling relationships between the families.

=head2 Special Methods

    my $ffType = Bio::KBase::CDMI::FamilyType::FIGfams->new($release);

Create a new FIGfam family-type object.

=over 4

=item release

Release code for the FIGfams being loaded.

=cut

sub new {
    # Get the parameters.
    my ($class, $release) = @_;
    # Construct the object from the base class.
    my $retVal = Bio::KBase::CDMI::FamilyType::new($class, 'FIGfam',
            $release, 1);
    # Return the result.
    return $retVal;
}

=head2 Virtual Override Methods

=head3 Init

    $familyType->Init($loader, $directory);

Perform special initialization. This method is called after the basic
data structures are created but before any data is processed from the
input directory.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for the current load.

=item directory

Name of the directory containing the load files.

=back

=cut

sub Init {
    # Get the parameters.
    my ($self, $loader, $directory) = @_;
    # Denote that the feature IDs are all SEED IDs.
    $loader->SetSource('SEED');
}

=head3 ProcessAdditionalFiles

    $familyType->ProcessAdditionalFiles($loader, $directory);

Process additional files in the specified directory. This method
handles files aside from the two standard files used to load
families. For FIGfams, there is one such file, the C<coupling.values>
file, that describes couplings between the families.

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
    # Now we process the coupling values.
    print "Processing coupling values.\n";
    # Compute the file name.
    my $couplingFile = "$directory/coupling.values";
    # Insure it exists.
    if (! -f $couplingFile) {
        print "Coupling file $couplingFile not found: skipping.\n";
    }
    # This will be used to track the number of lines so we can show
    # progress.
    my $count = 0;
    # Open the file and loop through it.
    open(my $ih, "<$couplingFile") || die "Could not open coupling values file: $1\n";
    while (! eof $ih) {
        # Get this coupling record.
        my ($from, $to, $expScore, $fcScore) = $loader->GetLine($ih);
        $stats->Add(couplingValuesProcessed => 1);
        # Connect the FIGfams.
        $loader->InsertObject('IsCoupledTo', from_link => $from,
                to_link => $to, co_expression_evidence => $expScore,
                co_occurrence_evidence => $fcScore);
        # Keep the user informed of our progress.
        $count++;
        if ($count % 10000 == 0) {
            print "$count couplings processed.\n";
        }
    }
    # Close the coupling file.
    close $ih;
}

1;


