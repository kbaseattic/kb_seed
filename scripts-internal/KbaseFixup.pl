### Test program for Ross's project.

    use strict;
    use Stats;
    use SeedUtils;
    use CustomAttributes;
    use Sapling;
    use Getopt::Long;

# Turn off buffering on STDOUT: it's our progress log.
$| = 1;
# Connect to the database using the command-line options.
my $dbHost = $FIG_Config::attrHost;
my $dbPort = 3306;
my $attrDBD = $FIG_Config::attrDBD;
my $rc = GetOptions("dbport=s" => \$dbPort, "dbhost=s" => \$dbHost,
        "attrDBD=s" => \$attrDBD);
if (! $rc) {
    print "usage: KbaseFixup [options]\n";
} else {
    # Create the statistics object.
    my $stats = Stats->new();
    # Get the attribute database.
    print "Connecting to attribute database.\n";
    my $ca = CustomAttributes->new(dbport => $dbPort, dbhost => $dbHost,
            DBD => $attrDBD, dbuser => 'seed');
    # Get the Sapling.
    my $sap = Sapling->new(port => $dbPort, dbhost => $dbHost);
    # Count the number of dlits processed. We'll write a message after
    # each 1000.
    my $count = 0;
    print "Looking for evidence.\n";
    # Loop through the dlit evidence codes.
    my $query = $ca->Get('IsEvidencedBy', "IsEvidencedBy(to_link) LIKE ? AND IsEvidencedBy(value) LIKE ?",
            ['fig|%', 'dlit%']);
    while (my $evidence = $query->Fetch()) {
        $stats->Add(evidenceFound => 1);
        # Get the feature ID and the pubmed ID.
        my $key = $evidence->PrimaryValue('to-link');
        my $value = $evidence->PrimaryValue('value');
        unless ($value =~ /dlit\((\d+)/) {
            # Here we have one of the badly-formatted attributes.
            $stats->Add(invalidEvidence => 1);
        } else {
            my $pubmed = $1;
            # Now we have a valid publication ID and feature.
            $stats->Add(dlits => 1);
            # Look for the feature in the CDMI and get its protein sequence.
            my ($prot) = $sap->GetFlat('Produces', 'Produces(from-link) = ?',
                    [$key], 'Produces(to-link)');
            if (! defined $prot) {
                $stats->Add(protNotFound => 1);
            } else {
                # The protein is in the Sapling. See if it is already connected.
                my ($evcode) = $ca->GetFlat('IsEvidencedBy',
                        "IsEvidencedBy(to-link) = ? AND IsEvidencedBy(value) LIKE ?",
                        ["Protein:$prot", "dlit($pubmed)%"], 'from-link');
                if ($evcode) {
                    $stats->Add(alreadyConnected => 1);
                } else {
                    # It's not, so add it.
                    $ca->InsertObject('IsEvidencedBy', from_link => 'evidence_code',
                            to_link => "Protein:$prot", value => $value);
                    $stats->Add(proteinConnected => 1);
                }
                # Delete the feature connection.
                $ca->DeleteRow('IsEvidencedBy', "evidence_code", $key, { value => $value });
                $stats->Add(rowDeleted => 1);
            }
            $count++;
            if ($count % 1000 == 0) {
                print "$count dlits processed.\n";
            }
        }
    }
    print "All done:\n" . $stats->Show();
}
