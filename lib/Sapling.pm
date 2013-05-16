#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

#
# This is a SAS component.
#

package Sapling;

    use strict;
    use Tracer;
    use base qw(ERDB);
    use Stats;
    use DBKernel;
    use SeedUtils;
    use BasicLocation;
    use ERDBGenerate;
    use XML::Simple;
    use Digest::MD5;

=head1 Sapling Package

Sapling Database Access Methods

=head2 Introduction

The Sapling database is a new Entity-Relationship Database that attempts to
encapsulate our data in a portable form for distribution. It is loaded directly
from the genomes and subsystems of the SEED. This object has minimal
capabilities: most of its power comes the L<ERDB> base class.

The fields in this object are as follows.

=over 4

=item loadDirectory

Name of the directory containing the files used by the loaders.

=item loaderSource

Source object for the loaders (a L<FIG> in our case).

=item genomeHash

Reference to a hash of the genomes to include when loading.

=item subHash

Reference to a hash of the subsystems to include when loading.

=item tuning

Reference to a hash of tuning parameters.

=item otuHash

Reference to a hash that maps genome IDs to genome set names.

=back

=head2 Configuration and Construction

The default loading profile for the Sapling database is to include all complete
genomes and all usable subsystems. This can be overridden by specifying a list of
genomes and subsystems in an XML configuration file. The file name should be
C<SaplingConfig.xml> in the specified data directory. The document element should
be C<Sapling>, and it has two sub-elements. The C<Genomes> element should contain as
its text a space-delimited list of genome IDs. The <Subsystems> element should contain
a list of subsystem names, one per line. If a particular section is missing, the
default list will be used.

=head3 Example

The following configuration file specifies 10 genomes and 6 subsystems.

    <Sapling>
      <Genomes>
        100226.1 31033.3 31964.1 36873.1 126740.4
        155864.1 349307.7 350058.5 351348.5 412694.5
      </Genomes>
      <Subsystems>
        Sugar_utilization_in_Thermotogales
        Coenzyme_F420_hydrogenase
        Ribosome_activity_modulation
        prophage_tails
        CBSS-393130.3.peg.794
        Apigenin_derivatives
      </Subsystems>
    </Sapling>

The XML file also contains tuning parameters that affect the way the data
is loaded. These are specified as attributes in the TuningParameters element,
as follows.

=over 4

=item maxLocationLength

The maximum number of base pairs allowed in a single location. B<IsLocatedIn>
records are split into sections based on this length, so when you are looking
for all the features in a particular neighborhood, you can look for locations
within the maximum location distance from the neighborhood, and even if you have
a huge operon that contains tens of thousands of base pairs, you'll still be
able to find it.

=item maxSequenceLength

The maximum number of base pairs allowed in a single DNA sequence. DNA sequences
are broken into segments to prevent excessively large genomes from clogging
memory during sequence resolution.

=back

=head3 Global Section Constant

Each section of the database used by the loader corresponds to a single genome.
The global section is loaded after all the others, and is concerned with data
not related to a particular genome.

=cut

    # Name of the global section
    use constant GLOBAL => 'Globals';

=head3 Tuning Parameter Defaults

Each tuning parameter must have a default value, in case it is not present in
the XML configuration file. The defaults are specified in a constant hash
reference called C<TUNING_DEFAULTS>.

=cut

    use constant TUNING_DEFAULTS => {
        maxLocationLength => 4000,
        maxSequenceLength => 10000,
    };

=head3 new

    my $sap = Sapling->new(%options);

Construct a new Sapling object. The following options are supported.

=over 4

=item loadDirectory

Data directory to be used by the loaders.

=item DBD

XML database definition file.

=item dbName

Name of the database to use.

=item sock

Socket for accessing the database.

=item userData

Name and password used to log on to the database, separated by a slash.

=item dbhost

Database host name.

=item port

MYSQL port number to use (MySQL only).

=item dbms

Database management system to use (e.g. C<SQLite> or C<postgres>, default C<mysql>).

=back

=cut

sub new {
    # Get the parameters.
    my ($class, %options) = @_;
    # Get the options.
    if (! $options{loadDirectory}) {
        $options{loadDirectory} = $FIG_Config::saplingData ||
            "$FIG_Config::fig/SaplingData";
    }
    my $dbd = $options{DBD} || "$options{loadDirectory}/SaplingDBD.xml";
    my $dbName = $options{dbName} || $FIG_Config::saplingDB || "nmpdr_sapling";
    my $userData = $options{userData} || "seed/";
    my $dbhost = $options{dbhost} || $FIG_Config::saplingHost || "localhost";
    my $port = $options{port} || 3306;
    my $dbms = $options{dbms} || 'mysql';
    # Insure that if the user specified a DBD, it overrides the internal one.
    if ($options{DBD} && ! defined $options{externalDBD}) {
    	$options{externalDBD} = 1;
    }
    # Compute the socket. An empty string is a valid override here.
    my $sock = $options{sock};
    if (! defined $sock) {
        $sock = $FIG_Config::sproutSock || "";
    }
    # Compute the user name and password.
    my ($user, $pass) = split '/', $userData, 2;
    $pass = "" if ! defined $pass;
    Trace("Connecting to sapling database.") if T(2);
    # Connect to the database.
    my $dbh = DBKernel->new($dbms, $dbName, $user, $pass, $port, $dbhost, $sock);
    # Create the ERDB object.
    my $retVal = ERDB::new($class, $dbh, $dbd, %options);
    # Set up the spaces for the loader source object, the subsystem hash, the
    # genome hash, and the tuning parameters.
    $retVal->{source} = undef;
    $retVal->{genomeHash} = undef;
    $retVal->{subHash} = undef;
    $retVal->{tuning} = undef;
    # Set up the hash of genome IDs to OTUs.
    $retVal->{otuHash} = {};
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 OTU

    my $otu = $sap->OTU($genomeID);

Return the name of the Organism Taxonomic Unit (GenomeSet) for the
specified genome ID. OTU information is cached in memory, so that once it
is known, it does not need to be re-fetched from the database.

=over 4

=item genomeID

ID of a genome or feature. If a feature ID is specified, the genome ID will be
extracted from it.

=item RETURN

Returns the name of the genome set for the specified genome, or C<undef> if the
genome is not in the 

=back

=cut

sub OTU {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Get the OTU hash.
    my $otuHash = $self->{otuHash};
    # Compute the real genome ID.
    my $realGenomeID = ($genomeID =~ /^fig\|(\d+\.\d+)/ ? $1 : $genomeID);
    # Look it up in the hash.
    my $retVal = $otuHash->{$realGenomeID};
    # Was it found?
    if (! defined $retVal) {
        # No, get the OTU from the database.
        ($retVal) = $self->GetFlat("IsCollectedInto", "IsCollectedInto(from-link) = ?",
                                   [$realGenomeID], "to-link");
        # Save it in the hash for future use.
        $otuHash->{$realGenomeID} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 ProteinID

    my $key = $sap->ProteinID($sequence);

Return the protein sequence ID that would be associated with a specific
protein sequence.

=over 4

=item sequence

String containing the protein sequence in question.

=item RETURN

Returns the ID value for the specified protein sequence. If the sequence exists
in the database, it will have this ID in the B<ProteinSequence> table.

=back

=cut

sub ProteinID {
    # Get the parameters.
    my ($self, $sequence) = @_;
    # Compute the MD5 hash.
    my $retVal = Digest::MD5::md5_hex($sequence);
    # Return the result.
    return $retVal;
}


=head3 IsProteinID

    my $md5 = $sap->IsProteinID($identifier);

Check for a protein identifier. If a protein identifier is found, the
corresponding protein sequence ID will be returned; otherwise, an
undefined value will be returned. A protein identifier is either a
raw protein sequence ID, an ID preceded by C<md5|>, or an ID preceded by
C<gnl|md5|>

=over 4

=item identifier

Identifier to test.

=item RETURN

Returns the MD5 code from the protein identifier, or C<undef> if the incoming
string is not a protein identifier.

=back

=cut

sub IsProteinID {
    # Get the parameters.
    my ($self, $identifier) = @_;
    # Declare the return variable.
    my $retVal;
    # Check the input.
    if ($identifier =~ /^(?:gnl\|)?(?:md5\|)?([0-9a-f]{32})$/) {
        $retVal = $1;
    }
    # Return the result.
    return $retVal;
}


=head3 Assignment

    my $assignment = $sapling->Assignment($fid);

Return the functional assignment for the specified feature.

=over 4

=item fid

FIG ID of the desired feature.

=item RETURN

Returns the functional assignment of the specified feature, or C<undef>
if the feature does not exist.

=back

=cut

sub Assignment {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Get the functional assignment.
    my ($retVal) = $self->GetFlat("Feature", "Feature(id) = ?", [$fid], 'function');
    # Return the result.
    return $retVal;
}

=head3 IdsForProtein

    my @ids = $sap->IdsForProtein($protID);

Return a list of all the identifiers associated with the specified
protein.

=over 4

=item protID

ID of the protein of interest.

=item RETURN

Returns a list of the Identifiers for the specific protein or for genes that
produce the specific protein.

=back

=cut

sub IdsForProtein {
    # Get the parameters.
    my ($self, $protID) = @_;
    # We'll put the identifiers found in here.
    my %retVal;
    # Ask for identifiers that directly name the protein.
    for my $id ($self->GetFlat("ProteinSequence IsNamedBy Identifier",
                               "ProteinSequence(id) = ?", [$protID],
                               'Identifier(id)')) {
        $retVal{$id} = 1;
    }
    # Add identifiers that name genes producing the protein.
    for my $id ($self->GetFlat("ProteinSequence IsProteinFor Feature IsIdentifiedBy Identifier",
                               "ProteinSequence(id) = ?", [$protID],
                               'Identifier(id)')) {
        $retVal{$id} = 1;
    }
    # Return the results found.
    return sort keys %retVal;
}


=head3 ComputeDNA

    my $dna = $sap->ComputeDNA($location);

Return the DNA sequence for the specified location.

=over 4

=item location

A L<BasicLocation> object indicating the contig, start location, direction, and
length of the desired DNA segment.

=item RETURN

Returns a string containing the desired DNA. The DNA comes back in pure lower-case.

=back

=cut

sub ComputeDNA {
    # Get the parameters.
    my ($self, $location) = @_;
    # Get the contig, left end, and right end of the location. Note we subtract
    # 1 to convert contig positions to string offsets.
    my $contig = $location->Contig;
    my $left = $location->Left - 1;
    my $right = $location->Right - 1;
    # Insure the left location is valid.
    if ($left < 0) {
        $left = 0;
    }
    # Get the DNA segment length.
    my $maxSequenceLength = $self->TuningParameter("maxSequenceLength");
    # Compute the key of the first segment of our DNA and the starting
    # point in that segment.
    my $leftOffset = $left % $maxSequenceLength;
    my $leftKey = "$contig:" . Tracer::Pad(($left - $leftOffset)/$maxSequenceLength,
                                        7, 1, '0');
    # Compute the key of the last segment containing our DNA.
    my $rightKey = "$contig:" . Tracer::Pad(int($right/$maxSequenceLength), 7, 1, '0');
    my @results = $self->GetFlat("DNASequence", 
                                 'DNASequence(id) >= ? AND DNASequence(id) <= ?', 
                                 [$leftKey, $rightKey], 'sequence');
    # Form all the DNA into a string and extract our piece.
    my $retVal = substr(join("", @results), $leftOffset, $location->Length);
    # If this is a backwards string, we need the reverse complement.
    rev_comp(\$retVal) if $location->Dir eq '-';
    # Return the result.
    return $retVal;
}

=head3 FilterByGenome

    my @filteredFids = $sapling->FilterByGenome(\@fids, $genomeFilter);

Filter the features using the specified genome-based criterion. The
criterion can be either a comma-separated list of genome IDs, or a
partial organism name.

=over 4

=item fids

Reference to a list of feature IDs.

=item genomeFilter

A string specifying the filtering criterion. If undefined or blank, then
no filter is applied. If a name, then only features from genomes with a
matching name will be returned. A name is a match if the filter is an
exact match for some prefix of the organism name. Thus, C<Listeria> would
get all Listerias, while C<Listeria monocytogenes EGD-e> would match only
the specific EGD-e strain. For a more precise match, you can specify
instead a comma-delimited list of genome IDs. In this latter case, only
features for the listed genomes will be included in the results.

=item RETURN

Returns the features from the incoming list that match the filter condition.

=back

=cut

sub FilterByGenome {
    # Get the parameters.
    my ($self, $fids, $genomeFilter) = @_;
    # Declare the return variable.
    my @retVal;
    # Check the type of filter.
    if (! $genomeFilter) {
        # No filter, so copy the input directly to the result.
        @retVal = @$fids;
    } else {
        # Trim edge spaces from the filter.
        $genomeFilter = Tracer::Trim($genomeFilter);
        # This hash will contain the permissible genome IDs.
        my %genomeIDs;
        # Check for a name. We assume we have a name if there's an
        # alphabetic letter anywhere in the filter string.
        if ($genomeFilter =~ /[a-zA-Z]/) {
            # The filter contains something that does not look like a genome
            # ID, so it is treated as a genome name. We get the IDs of the
            # genomes with that name and put them in the hash.
            %genomeIDs = map { $_ => 1 } $self->GetFlat("Genome",
                                                        'Genome(scientific-name) LIKE ?', 
                                                        ["$genomeFilter%"], 'id');
        } else {
            # We are expecting a comma-delimited list of genome IDs, so we
            # put these in our hash.
            %genomeIDs = map { $_ => 1 } split(/\s*,\s*/, $genomeFilter);
        }
        # Now we loop through the features, keeping the ones whose genome ID
        # matches something in the hash.
        @retVal = grep { $genomeIDs{genome_of($_)} } @$fids;
    }
    # Return the result.
    return @retVal;
}


=head3 GetLocations

    my @locs = $sapling->GetLocations($fid);

Return the locations of the DNA for the specified feature.

=over 4

=item fid

ID of the feature whose location is desired.

=item RETURN

Returns a list of L<BasicLocation> objects for the locations containing the
feature's DNA.

=back

=cut

sub GetLocations {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Declare the return variable.
    my @retVal;
    # This will contain the last location found.
    my $lastLoc;
    # Get this feature's locations.
    my $qh = $self->Get("IsLocatedIn", 
                       'IsLocatedIn(from-link) = ? ORDER BY IsLocatedIn(ordinal)', 
                       [$fid]);
    while (my $resultRow = $qh->Fetch()) {
        # Compute the contig ID and other information.
        my $contig = $resultRow->PrimaryValue('to-link');
        my $begin = $resultRow->PrimaryValue('begin');
        my $dir = $resultRow->PrimaryValue('dir');
        my $len = $resultRow->PrimaryValue('len');
        # Create a location from the location information.
        my $start = ($dir eq '+' ? $begin : $begin + $len - 1);
        my $loc = BasicLocation->new($contig, $start, $dir, $len);
        # Check to see if this location is adjacent to the previous one.
        if ($lastLoc && $lastLoc->Adjacent($loc)) {
            # It is, so merge it in.
            $lastLoc->Merge($loc);
        } else {
            # It isn't, so push the new one on the list.
            $lastLoc = $loc;
            push @retVal, $loc;
        }
    }
    # Return the result.
    return @retVal;
}


=head3 IdentifiedProtein

    my $proteinID = $sap->IdentifiedProtein($id);

Compute the protein for a specified identifier. If the identifier does
not exist or does not identify a protein, this method will return
C<undef>.

=over 4

=item id

Identifier whose protein is desired.

=item RETURN

Returns the protein ID corresponding to the incoming identifier,
or C<undef> if the identifier does not exist or is not for a protein.

=back

=cut

sub IdentifiedProtein {
    # Get the parameters.
    my ($self, $id) = @_;
    # Declare the return variable.
    my $retVal;
    # Try to find a protein for this ID.
    my ($proteinID) = $self->GetFlat("Identifier Names ProteinSequence",
                                     "Identifier(id) = ?", [$id],
                                     'ProteinSequence(id)');
    if (defined $proteinID) {
        # We found one, so we're done.
        $retVal = $proteinID;
    } else {
        # Not a protein ID. See if it's the ID of a feature that has a
        # protein connected. Note that it's possible to find more than one,
        # but we're going to punt and pick the first.
        ($proteinID) = $self->GetFlat("Identifier Identifies Feature Produces ProteinSequence",
                                      "Identifier(id) = ? LIMIT 1", [$id],
                                      'ProteinSequence(id)');
        if (defined $proteinID) {
            # We found a protein ID, so return it.
            $retVal = $proteinID;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 FeaturesByID

    my @fids = $sapling->FeaturesByID($id);

Return all the features corresponding to the specified identifier. Only features
that represent the same locus will be returned.

=over 4

=item id

Identifier of interest.

=item RETURN

Returns a list of all the features in the database that match the given
identifier.

=back

=cut

sub FeaturesByID {
    # Get the parameters.
    my ($self, $id) = @_;
    # Ask for features from the database.
    my @retVal = $self->GetFlat("Identifies", "Identifies(from-link) = ?", [$id],
                                'to-link');
    # Return the result.
    return @retVal;
}

=head3 ProteinsByID

    my @fids = $sapling->ProteinsByID($id);

Return all the features that have the same protein sequence as the
identified feature. The returned features mar or may not have the same locus. If
the identifier is not for a protein encoding gene, no result will be returned.

=over 4

=item id

Identifier of interest. This can be any alias identifier from the B<Identifier>
table (which includes the FIG ID).

=item RETURN

Returns a list of FIG IDs for features having the same protein sequence. If the
identifier does not specify a protein-encoding gene, the list will be empty.

=back

=cut

sub ProteinsByID {
    # Get the parameters.
    my ($self, $id) = @_;
    # Declare the return variable.
    my @retVal;
    # Compute the protein for this identifier.
    my $protID = $self->IdentifiedProtein($id);
    # Only proceed if a protein was found. If no protein was found, we're
    # already set up to return an empty list.
    if (defined $protID) {
        # Get all the features connected to the identified protein.
        @retVal = $self->GetFlat("IsProteinFor", "IsProteinFor(from-link) = ?",
                                 [$protID], "IsProteinFor(to-link)");
    }
    # Return the result.
    return @retVal;
}

=head3 GetSubsystem

    my $ssData = $sapling->GetSubsystem($ssName);

Return a L<SaplingSubsys> object for the named subsystem.

=over 4

=item ssName

Name of the desired subsystem.

=item RETURN

Returns an object that defines multiple useful methods for manipulating the
named subsystem.

=back

=cut

sub GetSubsystem {
    # Get the parameters.
    my ($self, $ssName) = @_;
    # Declare the return variable.
    require SaplingSubsys;
    my $retVal = SaplingSubsys->new($ssName, $self);
    # Return the result.
    return $retVal;
}


=head3 GenesInRegion

    my @pegs = $sap->GenesInRegion($location);

Return a list of the IDs for the features that overlap the specified
region on a contig.

=over 4

=item location

Location of interest, either in the form of a location string (e.g.
C<360108.3:NZ_AANK01000002_264528_264007>)  or a L<BasicLocation>
object.

=item RETURN

Returns a list of feature IDs. The features in the list will be all
those that overlap or occur inside the location of interest.

=back

=cut

sub GenesInRegion {
    # Get the parameters.
    my ($self, $location) = @_;
    # Insure we have a location object.
    my $locObject = (ref $location ? $location : BasicLocation->new($location));
    # Get the beginning and the end of the location of interest.
    my $begin = $locObject->Left();
    my $end = $locObject->Right();
    # For performance reasons, we limit the possible starting location, using the
    # tuning parameter for maximum location length.
    my $limit = $begin - $self->TuningParameter('maxLocationLength');
    # Perform the query. Note we use a hash to eliminate duplicates.
    my %retVal = map { $_ => 1 } $self->GetFlat('Contig IsLocusFor Feature',
                                "Contig(id) = ? AND IsLocusFor(begin) <= ? AND " .
                                "IsLocusFor(begin) > ? AND " .
                                "IsLocusFor(begin) + IsLocusFor(len) >= ?",
                                [$locObject->Contig(), $end, $limit, $begin],
                                'Feature(id)');
    # Return the result.
    return sort keys %retVal;
}

=head3 GetFasta

    my $fasta = $sapling->GetFasta($proteinID, $id, $comment);

Return a FASTA sequence for the specified protein. An optional identifier
can be provided to be used as the identification string.

=over 4

=item proteinID

Protein sequence identifier.

=item id (optional)

The identifier to be used in the FASTA output. If omitted, the protein ID
is used.

=item comment (optional)

The comment string to be used in the identification line of the FASTA output.
If omitted, no comment will be present.

=item RETURN

Returns a FASTA string for the protein. This includes the identification
line and the protein letters themselves.

=back

=cut

sub GetFasta {
    # Get the parameters.
    my ($self, $proteinID, $id, $comment) = @_;
    # Compute the identifier.
    my $realID = $id || "md5|$proteinID";
    # Declare the return variable.
    my $retVal;
    # Get the protein sequence.
    my ($sequence) = $self->GetFlat("ProteinSequence", "ProteinSequence(id) = ?",
                                    [$proteinID], "sequence");
    # It's an error if the sequence was not found.
    if (! defined $sequence) {
        Confess("No protein found with the sequence identifier $proteinID.");
    } else {
        # Create a FASTA string for the protein.
        $retVal = SeedUtils::create_fasta_record($realID, $comment, $sequence);
    }
    # Return the result.
    return $retVal;
}


=head3 Taxonomy

    my @taxonomy = $sap->Taxonomy($genomeID, $format);

Return the full taxonomy of the specified genome, starting from the
domain downward.

=over 4

=item genomeID

ID of the genome whose taxonomy is desired. The genome does not need to exist
in the database: the version number will be lopped off and the result used as
an entry point into the taxonomy tree.

=item format (optional)

Format of the taxonomy. C<names> will return primary names, C<numbers> will
return taxonomy numbers, and C<both> will return taxonomy number followed by
primary name. The default is C<names>.

=item RETURN

Returns a list of taxonomy names, starting from the domain and moving
down to the node where the genome is attached.

=back

=cut

sub Taxonomy {
    # Get the parameters.
    my ($self, $genomeID, $format) = @_;
    # Get the genome's taxonomic group.
    my ($taxon) = split m/\./, $genomeID, 2;
    # We'll put the return data in here.
    my @retVal;
    # Loop until we hit a domain.
    my $domainFlag;
    while (! $domainFlag) {
        # Get the data we need for this taxonomic group.
        my ($taxonData) = $self->GetAll('TaxonomicGrouping IsInGroup',
                                        'TaxonomicGrouping(id) = ?', [$taxon],
                                        'domain scientific-name IsInGroup(to-link)');
        # If we didn't find what we're looking for, then we have a problem. This
        # would indicate a node below the domain level that doesn't have a parent
        # or (more likely) an invalid input string.
        if (! $taxonData) {
            # Terminate the loop and trace a warning.
            $domainFlag = 1;
            Trace("Could not find node or parent for \"$taxon\".") if T(1);
        } else {
            # Extract the data for the current group. Note we overwrite our
            # taxonomy ID with the ID of our parent, priming the next iteration
            # of the loop.
            my $name;
            my $oldTaxon = $taxon;
            ($domainFlag, $name, $taxon) = @$taxonData;
            # Compute the value we want to put in the output list.
            my $value;
            if ($format eq 'numbers') {
                $value = $oldTaxon;
            } elsif ($format eq 'both') {
                $value = "$oldTaxon $name";
            } else {
                $value = $name;
            }
            # Put the current group's data in the return list.
            unshift @retVal, $value;
        }
    }
    # Return the result.
    return @retVal;
}

=head3 IsDeletedFid

    my $flag = $sapling->IsDeletedFid($fid);

Return TRUE if the specified feature is B<not> in the database, else
FALSE.

=over 4

=item fid

FIG ID of the relevant feature.

=item RETURN

Returns TRUE if the specified feature is in the database, else FALSE.

=back

=cut

sub IsDeletedFid {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Check for the feature. If the feature does not exist, we'll get an
    # undefined value (FALSE). If it does, we'll get the feature ID itself
    # (TRUE).
    my ($retVal) = $self->GetFlat("Feature", "Feature(id) = ?", [$fid], 'id');
    # Return FALSE if the feature was found, TRUE if it was not found.
    return ($retVal ? 0 : 1);
}


=head3 GenomeHash

    my $genomeHash = $sap->GenomeHash();

Return a hash of the genomes configured to be in this database. The list
is either taken from the active SEED database or from a configuration
file in the data directory. The hash maps genome IDs to TRUE.

=cut

sub GenomeHash {
    # Get the parameters.
    my ($self) = @_;
    # We'll build the hash in here.
    my %genomeHash;
    # Do we already have a list?
    if (! defined $self->{genomeHash}) {
        # No, check for a configuration file.
        my $xml = $self->ReadConfigFile();
        if (defined $xml && $xml->{Genomes}) {
            # We found one and it has a genome list, so extract the genomes.
            %genomeHash = map { $_ => 1 } grep { $_ =~ /\S/ } split /\s+/, $xml->{Genomes};
        } else {
            # No, so get the genome list.
            my $fig = $self->GetSourceObject();
            my @genomes = $fig->genomes();
            # Verify the genome list to insure every genome has an organism
            # directory.
            for my $genome (@genomes) {
                if (-d "$FIG_Config::organisms/$genome") {
                    $genomeHash{$genome} = 1;
                }
            }
        }
        # Store the genomes in this object.
        $self->{genomeHash} = \%genomeHash;
    }
    # Return the result.
    return $self->{genomeHash};
}

=head3 SubsystemID

    my $subID = $sap->SubsystemID($subName);

Return the ID of the subsystem with the specified name.

=over 4

=item subName

Name of the relevant subsystem. A subsystem name with underscores for spaces
will return the same ID as a subsystem name with the spaces still in it.

=item RETURN

Returns a normalized subsystem name.

=back

=cut

sub SubsystemID {
    # Get the parameters.
    my ($self, $subName) = @_;
    # Normalize the subsystem name by converting underscores to spaces.
    # Underscores at the beginning and end are not converted.
    my $retVal = $subName;
    my $trailer = chop $retVal;
    my $prefix = substr($retVal,0,1);
    $retVal = substr($retVal, 1);
    $retVal =~ tr/_/ /;
    $retVal = $prefix . $retVal . $trailer;
    # Return the result.
    return $retVal;
}

=head3 Alias

    my $translatedID = $sap->Alias($fid, $source);

Return an alternate ID of the specified type for the specified feature.
If no alternate ID of that type exists, the incoming value will be
returned unchanged.

=over 4

=item fid

FIG ID of the feature whose alias identifier is desired.

=item source

Database type for the alternate ID (e.g. C<LocusTag>, C<NCBI>, C<RefSeq>). If
C<SEED> is specified, the ID will be returned unchanged and no database lookup
will occur.

=item RETURN

Returns an equivalent ID for the specified feature that belongs to the specified
database (that is, has the specified source). If no such ID exists, returns the
incoming ID.

=back

=cut

sub Alias {
    # Get the parameters.
    my ($self, $fid, $source) = @_;
    # Default to the incoming value.
    my $retVal = $fid;
    # We only have work to do if the database type isn't "SEED".
    if ($source ne 'SEED') {
        # Look for an alias.
        my ($alias) = $self->GetFlat("IsIdentifiedBy Identifier",
                                     'IsIdentifiedBy(from-link) = ? AND Identifier(source) = ?',
                                     [$fid, $source], 'Identifier(natural-form)');
        # If we found one, return it.
        if (defined $alias) {
            $retVal = $alias;
        }
    }
    # Return the result.
    return $retVal;
}


=head3 ContigLength

    my $contigLen = $sap->ContigLength($contigID);

Return the number of base pairs in the specified contig.

=over 4

=item contigID

ID of the contig of interest.

=item RETURN

Returns the number of base pairs in the specified contig, or 0 if the contig
does not exist.

=back

=cut

sub ContigLength {
    # Get the parameters.
    my ($self, $contigID) = @_;
    # Try to find the length.
    my ($retVal) = $self->GetEntityValues(Contig => $contigID, 'length');
    # Convert not-found to 0.
    $retVal = 0 if ! defined $retVal;
    # Return the result.
    return $retVal;
}

=head3 ReactionRoles

    my @roles = $sap->ReactionRoles($rxnID);

Return a list of all the roles for a single reaction. The reactions are connected
to roles through the complexes, so an extra step is required to sort out
duplicates from the results.

=over 4

=item rxnID

ID of the reaction whose roles are desired.

=item RETURN

Returns a list of the roles associated with the reaction.

=back

=cut

sub ReactionRoles {
    # Get the parameters.
    my ($self, $rxnID) = @_;
    # Get the roles for this reaction, using a hash to filter out the
    # duplicates.
    my %retVal = map { $_ => 1 } $self->GetFlat("IsElementOf IsTriggeredBy",
        "IsElementOf(from-link) = ?", [$rxnID], "IsTriggeredBy(to-link)");
    # Sort and return the results.
    return sort keys %retVal;
}

=head3 RoleReactions

    my @rxns = $sap->RoleReactions($roleID);

Return a list of all the reactions for a single role. The reactions are connected
to roles through the complexes, so an extra step is required to sort out
duplicates from the results.

=over 4

=item roleID

ID of the role whose reactions are desired.

=item RETURN

Returns a list of the IDs for the reactions associated with the role.

=back

=cut

sub RoleReactions {
    # Get the parameters.
    my ($self, $roleID) = @_;
    # Get the roles for this reaction, using a hash to filter out the
    # duplicates.
    my %retVal = map { $_ => 1 } $self->GetFlat("Triggers IsSetOf",
        "Triggers(from-link) = ?", [$roleID], "IsSetOf(to-link)");
    # Sort and return the results.
    return sort keys %retVal;
}


=head2 Configuration-Related Methods

=head3 SubsystemHash

    my $subHash = $sap->SubsystemHash();

Return a hash of the subsystems configured to be in this database. The
list is either taken from the active SEED database or from a
configuration file in the data directory. The hash maps subsystem names
to TRUE.

=cut

sub SubsystemHash {
    # Get the parameters.
    my ($self) = @_;
    # We'll build the hash in here.
    my %subHash;
    # Do we already have a list?
    if (! defined $self->{subHash}) {
        # No, check for a configuration file.
        my $xml = $self->ReadConfigFile();
        if (defined $xml && $xml->{Subsystems}) {
            # We found one, and it has subsystems, so we extract them.
            # A little dancing is necessary to trim spaces.
            my @subs = map { $_ =~ /\s*(\S.+\S)/; $1 } split /\n/, $xml->{Subsystems};
            # Here we need to clear out any null subsystem names resulting from
            # blank lines in the file.
            %subHash = map { $_ => 1 } grep { $_ } @subs;
        } else {
            # No config file, so we ask the FIG object.
            my $fig = $self->GetSourceObject();
            for my $subsystem ($fig->all_subsystems()) {
                my $subsysID = $self->SubsystemID($subsystem);
                $subHash{$subsysID} = 1;
            }
        }
        # Store the subsystems in this object.
        $self->{subHash} = \%subHash;
    }
    # Return the result.
    return $self->{subHash};
}

=head3 TuningParameter

    my $parm = $erdb->TuningParameter($parmName);

Return the value of the specified tuning parameter. Tuning parameters are
read from the XML configuration file.

=over 4

=item parmName

Name of the parameter whose value is desired.

=item RETURN

Returns the paramter value.

=back

=cut

sub TuningParameter {
    # Get the parameters.
    my ($self, $parmName) = @_;
    # Insure we have the parameters in memory.
    if (! defined $self->{tuning}) {
        # Read the configuration file.
        my $configFile = $self->ReadConfigFile();
        # Get the tuning parameters (if any).
        my $tuning;
        if (! defined $configFile || ! exists $configFile->{TuningParameters}) {
            $tuning = {};
        } else {
            $tuning = $configFile->{TuningParameters};
        }
        # Merge in the default option values.
        Tracer::MergeOptions($tuning, TUNING_DEFAULTS);
        # Save the result in our object.
        $self->{tuning} = $tuning;
    }
    # Extract the tuning paramter.
    my $retVal = $self->{tuning}{$parmName};
    # Throw an error if it does not exist.
    Confess("Invalid tuning parameter \"$parmName\".") if ! defined $retVal;
    # Return the result.
    return $retVal;
}


=head3 ReadConfigFile

    my $xmlObject = $sap->ReadConfigFile();

Return the hash structure created from reading the configuration file, or
an undefined value if the file is not found.

=cut

sub ReadConfigFile {
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    # Compute the configuration file name.
    my $fileName = "$self->{loadDirectory}/SaplingConfig.xml";
    # Did we find it?
    if (-f $fileName) {
        # Yes, read it in.
        $retVal = XMLin($fileName);
    }
    # Return the result.
    return $retVal;
}

=head3 GlobalSection

    my $flag = $sap->GlobalSection($name);

Return TRUE if the specified section name is the global section, FALSE
otherwise.

=over 4

=item name

Section name to test.

=item RETURN

Returns TRUE if the parameter matches the GLOBAL constant, else FALSE.

=back

=cut

sub GlobalSection {
    # Get the parameters.
    my ($self, $name) = @_;
    # Return the result.
    return ($name eq GLOBAL);
}

=head3 LoadGenome

    my $stats = $sap->LoadGenome($genome, $directory);

Load the specified genome directory into the database. The genome's DNA, features,
protein sequences, and other supporting information will be inserted. If the
genome already exists, numerous errors will occur; therefore, it is recommended
that the genome be deleted first using the L<ERDB/Delete> method.

=over 4

=item genom

The ID of the genome being loaded.

=item directory

Name of the genome directory.

=item RETURN

Returns a statistics object describing the load activity.

=back

=cut

sub LoadGenome {
    # Get the parameters.
    my ($self, $genome, $directory) = @_;
    # Verify that the directory exists.
    Confess ("Genome directory $directory not found.") if ! -d $directory;
    # Verify that the ID is valid.
    Confess("Invalid genome ID $genome.") if $genome !~ /^\d+\.\d+$/;
    # Import the loader and call it.
    require SaplingGenomeLoader;
    my $retVal = SaplingGenomeLoader::Load($self, $genome, $directory);
    # Return the statistics object.
    return $retVal;
}

=head2 Special-Purpose Methods

=head3 ComputeFeatureFilter

    my ($objects, $filter, @parms) = $sap->ComputeFeatureFilter($source, $genome);

Compute the initial object name list, filter string, and parameter list
for a query by feature ID. The object name list will always end with the
B<Feature> entity, and the combination of the filter string and parameter
list will translate the incoming ID from the specified format to a real
FIG feature ID. If the specified format B<is> FIG feature IDs, then the
query will start on the B<Feature> entity; otherwise, it will start with
the B<Identifier> entity. This is a special-purpose method that performs
the task of intelligently modifying queries to allow for external ID
types.

=over 4

=item source (optional)

Database source of the IDs specified-- C<SEED> for FIG IDs, C<GENE> for standard
gene identifiers, or C<LocusTag> for locus tags. In addition, you may specify
C<RefSeq>, C<CMR>, C<NCBI>, C<Trembl>, or C<UniProt> for IDs from those databases.
Use C<mixed> to allow mixed ID types (though this may cause problems when the same
ID has different meanings in different databases). Use C<prefixed> to allow IDs with
prefixing indicating the ID type (e.g. C<uni|P00934> for a UniProt ID, C<gi|135813> for
an NCBI identifier, and so forth). The default is C<SEED>.

=item genome (optional)

ID of a genome. If specified, only features from the specified genome will be
accepted by the filter. This is important for IDs that are ambiguous between
genomes (like Locus Tags). If omitted, no genome filtering will take place.

=item RETURN

Returns a list containing parameters to the desired query call. The first element
is the prefix for the object name list, the second is the prefix for the filter
string, and the subsequent elements form the prefix for the parameter value list.

=back

=cut

sub ComputeFeatureFilter {
    # Get the parameters.
    my ($self, $source, $genome) = @_;
    # Declare the return variables.
    my ($objects, $filter, @parms);
    # This will be set to TRUE if we are directly processing FIG IDs.
    my $figOnly = 0;
    # Determine the source type.
    if (! defined $source || $source eq 'SEED') {
        # Here we're directly processing FIG IDs.
        $objects = 'Feature';
        $filter = 'Feature(id) = ?';
        $figOnly = 1;
    } elsif ($source eq 'mixed') {
        # Here we're processing mixed IDs of unknown type.
        $objects = 'Identifier Identifies Feature';
        $filter = 'Identifier(natural-form) = ?';
    } elsif ($source eq 'prefixed') {
        # Here we're processing mixed IDs with prefixes. This is the internal form
        # of the ID.
        $objects = 'Identifier Identifies Feature';
        $filter = 'Identifier(id) = ?';
    } else {
        # Here we're processing a fixed ID type from an external database.
        # This is the case that requires an additional parameter. Note that
        # we insist that the additional parameter matches the first parameter
        # mark.
        $objects = 'Identifier Identifies Feature';
        $filter = 'Identifier(source) = ? AND Identifier(natural-form) = ?';
        push @parms, $source;
    }
    # Was a genome ID specified?
    if ($genome) {
        # Yes. Add genome filtering.
        if ($figOnly) {
            # In a FIG ID situation, we can simply add the genome filtering to the front
            # of the object list.
            $objects = "Genome IsOwnerOf $objects";
        } else {
            # Otherwise, we need to do an AND thing.
            $objects = "Genome IsOwnerOf Feature AND $objects";
        }
        # Add the genome ID to the filter clause.
        $filter = "Genome(id) = ? AND $filter";
        # Add it to the parameter list.
        unshift @parms, $genome;
    }
    # Return the results.
    return ($objects, $filter, @parms);
}


=head3 FindGapLeft

    my @operonData = $sap->FindGapLeft($loc, $maxGap, $interval, \%redundancyHash, \$redundancyFlag);

This method performs a rather arcane task: searching for a gap to the
left of a location in the contig. The search will proceed from the
starting point to the left, and will stop when a gap between occupied
locations is found that is larger than the specified maximum. The caller
has the option of specifying a hash of feature IDs that are redundant. If
any feature in the hash is found, the search will stop early and the
provided redundancy flag will be set. In addition, an interval size can
be specified to tune the process of retrieving data from the database.

=over 4

=item loc

L<BasicLocation> object for the location from which the search is to start.
This gives us the contig ID, the strand of interest (forward or backward),
and the starting point of the search.

=item maxGap

The maximum allowable gap. The search will stop at the left end of the contig
or the first gap larger than this amount.

=item interval (optional)

Interval to use for retrieving data from the database. This is the size of
the contig segments being retrieved. The default is C<10000>

=item redundancyHash (optional)

A hash of feature IDs. If any feature present in this hash is found during
the search, the search will stop and no data will be returned. The default
is an empty hash (no check).

=item redundancyFlag (optional)

A reference to a scalar flag. If present, the entire method will be bypassed
if the flag is TRUE. If a redundancy hash is specified and a redundant feature
is found, this flag will be set to TRUE by the method.

=item RETURN

Returns a list of 4-tuples. Each tuple will contain a feature ID, a begin
offset, a direction (C<+> or C<->), and a length, representing an occupied
location on the contig and the feature to which it belongs. The complete
list of locations will be to the left of the starting location and relatively
close together, with no gap larger than the caller-specified maximum.

=back

=cut

sub FindGapLeft {
    # Get the parameters.
    my ($self, $loc, $maxGap, $interval, $redundancyHash, $redundancyFlag) = @_;
    # Declare the return variable.
    my @retVal;
    # Fix up defaults for the missing parameters.
    $interval ||= 10000;
    if (! defined $redundancyHash) {
        $redundancyHash = {};
    }
    my $fakeFlag = 0;
    if (! defined $redundancyFlag) {
        $redundancyFlag = \$fakeFlag;
    }
    # This flag will be set to TRUE if we run out of locations or find a gap.
    my $gapFound = 0;
    # This will be used to store tuples found. If we are successful, it will
    # be copied to the return list.
    my @operonData;
    # Now we need to set up some data for the loop. In particular, the contig
    # ID, the strand (direction), and the starting point. We add one to the
    # starting current position to insure that the starting point is included
    # in the first search.
    my $currentPosition = $loc->Left + 1;
    my $contigID = $loc->Contig;
    my $strand = $loc->Dir;
    # This variable keeps the leftmost begin location found.
    my $begin = $loc->Left;
    # Loop until we find a redundancy or a gap.
    while (! $$redundancyFlag && ! $gapFound && $currentPosition >= 0) {
        # Compute the limits of the search interval for this iteration.
        my $nextPosition = $currentPosition - $interval;
        # Get all the locations in the interval.
        my @rows = $self->GetAll("IsLocatedIn",
                                 'IsLocatedIn(to-link) = ? AND IsLocatedIn(dir) = ? AND IsLocatedIn(begin) >= ? AND IsLocatedIn(begin) < ?',
                                [$contigID, $strand, $nextPosition, $currentPosition],
                                [qw(from-link begin dir len)]);
        # If nothing was found, it's a gap.
        if (! @rows) {
            $gapFound = 1;
        } else {
            # We got something, so we can loop through looking for gaps. The search
            # requires we sort by right point.
            my @sortableTuples;
            for my $tuple (@rows) {
                my ($fid, $left, $dir, $len) = @$tuple;
                push @sortableTuples, [$left + $len, $tuple];
            }
            my @sortedTuples = map { $_->[1] } sort { -($a->[0] <=> $b->[0]) } @sortableTuples;
            # Loop through the tuples, stopping at the first redundancy or gap.
            for my $tuple (@sortedTuples) { last if $gapFound || $$redundancyFlag;
                # Get this tuple's data.
                my ($fid, $left, $dir, $len) = @$tuple;
                # Is it close enough to be counted?
                if ($begin - ($left + $len) <= $maxGap) {
                    # Yes. We can include this tuple.
                    push @operonData, $tuple;
                    # Update the begin point.
                    $begin = $left;
                    # Is it redundant? It's only reasonable to ask this if it's
                    # an included feature.
                    if ($redundancyHash->{$fid}) {
                        $$redundancyFlag = 1;
                    }
                } else {
                    # No, it's not close enough. We've found a gap.
                    $gapFound = 1;
                }
            }
        }
        # Set up for the next interval.
        $currentPosition = $nextPosition;
    }
    # If we're nonredundant, save our results.
    if (! $$redundancyFlag) {
        @retVal = @operonData;
    }
    # Return the result.
    return @retVal;
}

=head3 FindGapRight

    my @operonData = $sap->FindGapRight($loc, $maxGap, $interval, \%redundancyHash, \$redundancyFlag);

This method is the dual of L</FindGapLeft>: it searches for a gap to the
right of a location in the contig. The search will proceed from the
starting point to the right, and will stop when a gap between occupied
locations is found that is larger than the specified maximum. The caller
has the option of specifying a hash of feature IDs that are redundant. If
any feature in the hash is found, the search will stop early and the
provided redundancy flag will be set. In addition, an interval size can
be specified to tune the process of retrieving data from the database.

=over 4

=item loc

L<BasicLocation> object for the location from which the search is to start.
This gives us the contig ID, the strand of interest (forward or backward),
and the starting point of the search.

=item maxGap

The maximum allowable gap. The search will stop at the right end of the contig
or the first gap larger than this amount.

=item interval (optional)

Interval to use for retrieving data from the database. This is the size of
the contig segments being retrieved. The default is C<10000>

=item redundancyHash (optional)

A hash of feature IDs. If any feature present in this hash is found during
the search, the search will stop and no data will be returned. The default
is an empty hash (no check).

=item redundancyFlag (optional)

A reference to a scalar flag. If present, the entire method will be bypassed
if the flag is TRUE. If a redundancy hash is specified and a redundant feature
is found, this flag will be set to TRUE by the method.

=item RETURN

Returns a list of 4-tuples. Each tuple will contain a feature ID, a begin
offset, a direction (C<+> or C<->), and a length, representing an occupied
location on the contig and the feature to which it belongs. The complete
list of locations will be to the right of the starting location and relatively
close together, with no gap larger than the caller-specified maximum.

=back

=cut

sub FindGapRight {
    # Get the parameters.
    my ($self, $loc, $maxGap, $interval, $redundancyHash, $redundancyFlag) = @_;
    # Declare the return variable.
    my @retVal;
    # Fix up defaults for the missing parameters.
    $interval ||= 10000;
    if (! defined $redundancyHash) {
        $redundancyHash = {};
    }
    my $fakeFlag = 0;
    if (! defined $redundancyFlag) {
        $redundancyFlag = \$fakeFlag;
    }
    # This flag will be set to TRUE if we run out of locations or find a gap.
    my $gapFound = 0;
    # This will be used to store tuples found. If we are successful, it will
    # be copied to the return list.
    my @operonData;
    # Now we need to set up some data for the loop. In particular, the contig
    # ID, the strand (direction), and the starting point. We subtract one from the
    # starting current position to insure that the starting point is included
    # in the first search.
    my $currentPosition = $loc->Left - 1;
    my $contigID = $loc->Contig;
    my $strand = $loc->Dir;
    # Get the length of the contig.
    my $contigLen = $self->ContigLength($contigID);
    Trace("Contig length is $contigLen. Starting at $currentPosition.") if T(3);
    # This variable keeps the rightmost end location found.
    my $endPoint = $loc->Left;
    # Loop until we find a redundancy or a gap.
    while (! $$redundancyFlag && ! $gapFound && $currentPosition <= $contigLen) {
        Trace("Checking at $currentPosition.") if T(3);
        # Compute the limits of the search interval for this iteration.
        my $nextPosition = $currentPosition + $interval;
        # Get all the locations in the interval.
        my @rows = $self->GetAll("IsLocatedIn",
                                 'IsLocatedIn(to-link) = ? AND IsLocatedIn(dir) = ? AND IsLocatedIn(begin) >= ? AND IsLocatedIn(begin) < ?',
                                [$contigID, $strand, $currentPosition, $nextPosition],
                                [qw(from-link begin dir len)]);
        # If nothing was found, it's a gap.
        if (! @rows) {
            $gapFound = 1;
            Trace("No result. Gap found.") if T(3);
        } else {
            # We got something, so we can loop through looking for gaps. The search
            # requires we sort by left point.
            my @sortedTuples = sort { $a->[1] <=> $b->[1] } @rows;
            # Loop through the tuples, stopping at the first redundancy or gap.
            for my $tuple (@sortedTuples) { last if $gapFound || $$redundancyFlag;
                # Get this tuple's data.
                my ($fid, $left, $dir, $len) = @$tuple;
                # Is it close enough to be counted?
                if ($left - $endPoint <= $maxGap) {
                    # Yes. We can include this tuple.
                    push @operonData, $tuple;
                    # Update the end point.
                    $endPoint = $left + $len;
                    # Is it redundant? It's only reasonable to ask this if it's
                    # an included feature.
                    if ($redundancyHash->{$fid}) {
                        $$redundancyFlag = 1;
                    }
                } else {
                    # No, it's not close enough. We've found a gap.
                    $gapFound = 1;
                    Trace("Long distance. Gap found.") if T(3);
                }
            }
        }
        # Set up for the next interval.
        $currentPosition = $nextPosition;
    }
    # If we're nonredundant, save our results.
    if (! $$redundancyFlag) {
        @retVal = @operonData;
    }
    # Return the result.
    return @retVal;
}

=head3 GenomesInPairSet

    my @genomes = $sap->GenomesInPairSet($pairSetID);

Return a list of the IDs for all of the genomes represented in the
specified pair set. This is useful when analyzing what data is missing
from the coupling tables.

=over 4

=item pairSetID

ID of the pair set to examine.

=item RETURN

Returns a list of the IDs for the genomes represented in the specified pair set.

=back

=cut

sub GenomesInPairSet {
    # Get the parameters.
    my ($self, $pairSetID) = @_;
    # We'll use this hash to isolate the genome IDs.
    my %retVal;
    # Get all the pairs in this set.
    my $query = $self->Get("IsDeterminedBy", "IsDeterminedBy(from-link) = ?",
                           [$pairSetID]);
    while (my $pairData = $query->Fetch()) {
        # Record the genomes for the pegs in the pair. The pegs can be found
        # separated by a colon in the pairing ID.
        for my $peg (split m/:/, $pairData->PrimaryValue('to-link')) {
            $retVal{genome_of($peg)} = 1;
        }
    }
    # Return the genome IDs.
    return keys %retVal;
}


=head2 Virtual Methods

=head3 PreferredName

    my $name = $erdb->PreferredName();

Return the variable name to use for this database when generating code.

=cut

sub PreferredName {
    return 'sap';
}

=head3 GetSourceObject

    my $source = $erdb->GetSourceObject();

Return the object to be used in creating load files for this database. This is
only the default source object. Loaders have the option of overriding the chosen
source object when constructing the L<ERDBLoadGroup> objects.

=cut

sub GetSourceObject {
    my ($self) = @_;
    # Insure the source object exists in our internal cache.
    if (! defined $self->{source}) {
        # We require the FIG object. If the user has no intention of
        # doing a load, this method won't be used, so he won't need to
        # have the FIG object on his system.
        require FIG;
        $self->{source} = FIG->new();
    }
    # Return it to the caller.
    return $self->{source};
}

=head3 SectionList

    my @sections = $erdb->SectionList();

Return a list of the names for the different data sections used when loading this database.
The default is a single string, in which case there is only one section representing the
entire database.

=cut

sub SectionList {
    # Get the parameters.
    my ($self) = @_;
    # The section names will be put in here.
    my @retVal;
    # Get the name of the section control file.
    my $controlFileName = ERDBGenerate::CreateFileName("SectionList", undef, 'control', $self->LoadDirectory());
    # Check to see if it exists.
    if (-f $controlFileName) {
        # Yes. Pull out the sections from it.
        Trace("Reading section list from $controlFileName.") if T(ERDBGenerate => 2);
        @retVal = Tracer::GetFile($controlFileName);
    } else {
        # No, so we have to create it. Get the genome hash.
        my $genomes = $self->GenomeHash();
        @retVal = sort keys %$genomes;
        # Append the global section.
        push @retVal, GLOBAL;
        # Write out the control file with the new sections.
        Trace("Writing section list to $controlFileName.") if T(ERDBGenerate => 2);
        Tracer::PutFile($controlFileName, \@retVal);
    }
    # Return the section list.
    return @retVal;
}

=head3 Loader

    my $groupLoader = $erdb->Loader($groupName, $source, $options);

Return an L<ERDBLoadGroup> object for the specified load group. This method is used
by L<ERDBGenerator.pl> to create the load group objects. If you are not using
L<ERDBGenerator.pl>, you don't need to override this method.

=over 4

=item groupName

Name of the load group whose object is to be returned. The group name is
guaranteed to be a single word with only the first letter capitalized.

=item source

The source object used to access the data from which the load file is derived. This 
is the same object returned by L</GetSourceObject>; however, we allow the caller to pass
it in as a parameter so that we don't end up creating multiple copies of a potentially
expensive data structure. It is permissible for this value to be undefined, in which
case the source will be retrieved the first time the client asks for it.

=item options

Reference to a hash of command-line options.

=item RETURN

Returns an L<ERDBLoadGroup> object that can be used to process the specified load group
for this database.

=back

=cut

sub Loader {
    # Get the parameters.
    my ($self, $groupName, $options) = @_;
    # Compute the loader name.
    my $loaderClass = "${groupName}SaplingLoader";
    # Pull in its definition.
    require "$loaderClass.pm";
    # Create an object for it.
    my $retVal = eval("$loaderClass->new(\$self, \$options)");
    # Insure it worked.
    Confess("Could not create $loaderClass object: $@") if $@;
    # Return it to the caller.
    return $retVal;
}

=head3 LoadGroupList

    my @groups = $erdb->LoadGroupList();

Returns a list of the names for this database's load groups. This method is used
by L<ERDBGenerator.pl> when the user wishes to load all table groups. The default
is a single group called 'All' that loads everything.

=cut

sub LoadGroupList {
    # Return the list.
    return qw(Model Alignment Expression Subsystem Family Feature Protein Genome Scenario);
}

=head3 LoadDirectory

    my $dirName = $erdb->LoadDirectory();

Return the name of the directory in which load files are kept. The default is
the FIG temporary directory, which is a really bad choice, but it's always there.

=cut

sub LoadDirectory {
    # Get the parameters.
    my ($self) = @_;
    # Return the directory name.
    return $self->{loadDirectory};
}

=head3 UseInternalDBD

    my $flag = $erdb->UseInternalDBD();

Return TRUE if this database should be allowed to use an internal DBD.
The internal DBD is stored in the C<_metadata> table, which is created
when the database is loaded. The Sapling uses an internal DBD.

=cut

sub UseInternalDBD {
    return 1;
}

1;
