package Sprout;

    use Data::Dumper;
    use strict;
    use DBKernel;
    use XML::Simple;
    use ERDBQuery;
    use ERDBObject;
    use Tracer;
    use FIGRules;
    use FidCheck;
    use Stats;
    use POSIX qw(strftime);
    use BasicLocation;
    use CustomAttributes;
    use RemoteCustomAttributes;
    use CGI qw(-nosticky);
    use WikiTools;
    use BioWords;
    use base qw(ERDB);

=head1 Sprout Database Manipulation Object

=head2 Introduction

This object enables the user to load and query the Sprout genome database using a few simple methods.
To construct the object, specify the name of the database. By default, the database is assumed to be a
MySQL database accessed via the user ID I<root> with no password and the database definition will
be in a file called F<SproutDBD.xml>. All of these defaults can be overridden
on the constructor. For example, the following invocation specifies a PostgreSQL database named I<GenDB>
whose definition and data files are in a co-directory named F<Data>.

    my $sprout = Sprout->new('GenDB', { dbType => 'pg', dataDir => '../Data', xmlFileName => '../Data/SproutDBD.xml' });

Once you have a sprout object, you may use it to re-create the database, load the tables from
tab-delimited flat files and perform queries. Several special methods are provided for common
query tasks. For example, L</Genomes> lists the IDs of all the genomes in the database and
L</DNASeq> returns the DNA sequence for a specified genome location.

The Sprout object is a subclass of the ERDB object and inherits all its properties and methods.

=cut

=head2 Public Methods

=head3 new

    my $sprout = Sprout->new(%parms)

This is the constructor for a sprout object. It connects to the database and loads the
database definition into memory. The incoming parameter hash has the following permissible
members (others will be ignored without error.

=over 4

=item DBD

Name of the XML file containing the database definition (default C<SproutDBD.xml> in
the DBD directory).

=item dbName

Name of the database. If omitted, the default Sprout database name is used.

=item options

Sub-hash of special options.

* B<dbType> type of database (currently C<mysql> for MySQL and C<pg> for PostgreSQL) (default C<mysql>)

* B<dataDir> directory containing the database definition file and the flat files used to load the data (default C<Data>)

* B<userData> user name and password, delimited by a slash (default same as SEED)

* B<port> connection port (default C<0>)

* B<sock> connection socket (default same as SEED)

* B<maxSegmentLength> maximum number of residues per feature segment, (default C<4500>)

* B<maxSequenceLength> maximum number of residues per sequence, (default C<8000>)

* B<noDBOpen> suppresses the connection to the database if TRUE, else FALSE

* B<host> name of the database host

=back

For example, the following constructor call specifies a database named I<Sprout> and a user name of
I<fig> with a password of I<admin>. The database load files are in the directory
F</usr/fig/SproutData>.

    my $sprout = Sprout->new(dbName => 'Sprout', options => { userData => 'fig/admin', dataDir => '/usr/fig/SproutData' });

The odd constructor signature is a result of Sprout's status as the first ERDB database,
and the need to make it compatible with the needs of its younger siblings.

=cut

sub new {
    # Get the parameters.
    my ($class, %parms) = @_;
    # Look for an options hash.
    my $options = $parms{options} || {};
    # Plug in the DBD and name parameters.
    if ($parms{DBD}) {
        $options->{xmlFileName} = $parms{DBD};
    }
    my $dbName = $parms{dbName} || $FIG_Config::sproutDB;
    # Compute the DBD directory.
    my $dbd_dir = (defined($FIG_Config::dbd_dir) ? $FIG_Config::dbd_dir :
                                                  $FIG_Config::fig );
    # Compute the options. We do this by starting with a table of defaults and overwriting with
    # the incoming data.
    my $optionTable = Tracer::GetOptions({
                       dbType       => $FIG_Config::dbms,
                                                        # database type
                       dataDir      => $FIG_Config::sproutData,
                                                        # data file directory
                       xmlFileName  => "$dbd_dir/SproutDBD.xml",
                                                        # database definition file name
                       userData     => "$FIG_Config::sproutUser/$FIG_Config::sproutPass",
                                                        # user name and password
                       port         => $FIG_Config::sproutPort,
                                                        # database connection port
                       sock         => $FIG_Config::sproutSock,
                       host         => $FIG_Config::sprout_host,
                       maxSegmentLength => 4500,        # maximum feature segment length
                       maxSequenceLength => 8000,       # maximum contig sequence length
                       noDBOpen     => 0,               # 1 to suppress the database open
                       demandDriven => 0,               # 1 for forward-only queries
                      }, $options);
    # Get the data directory.
    my $dataDir = $optionTable->{dataDir};
    # Extract the user ID and password.
    $optionTable->{userData} =~ m!([^/]*)/(.*)$!;
    my ($userName, $password) = ($1, $2);
    # Connect to the database.
    my $dbh;
    if (! $optionTable->{noDBOpen}) {
        Trace("Connect data: host = $optionTable->{host}, port = $optionTable->{port}.") if T(3);
        $dbh = DBKernel->new($optionTable->{dbType}, $dbName, $userName,
                                $password, $optionTable->{port}, $optionTable->{host}, $optionTable->{sock});
    }
    # Create the ERDB object.
    my $xmlFileName = "$optionTable->{xmlFileName}";
    my $retVal = ERDB::new($class, $dbh, $xmlFileName, %$optionTable);
    # Add the option table and XML file name.
    $retVal->{_options} = $optionTable;
    $retVal->{_xmlName} = $xmlFileName;
    # Set up space for the group file data.
    $retVal->{groupHash} = undef;
    # Set up space for the genome hash. We use this to identify NMPDR genomes
    # and remember genome data.
    $retVal->{genomeHash} = {};
    $retVal->{genomeHashFilled} = 0;
    # Remember the data directory name.
    $retVal->{dataDir} = $dataDir;
    # Return it.
    return $retVal;
}

=head3 ca

    my $ca = $sprout->ca():;

Return the [[CustomAttributesPm]] object for retrieving object
properties.

=cut

sub ca {
    # Get the parameters.
    my ($self) = @_;
    # Do we already have an attribute object?
    my $retVal = $self->{_ca};
    if (! defined $retVal) {
        # No, create one. How we do it depends on the configuration.
        if ($FIG_Config::attrURL) {
            Trace("Remote attribute server $FIG_Config::attrURL chosen.") if T(3);
            $retVal = RemoteCustomAttributes->new($FIG_Config::attrURL);
        } elsif ($FIG_Config::attrDbName) {
            Trace("Local attribute database $FIG_Config::attrDbName chosen.") if T(3);
            my $user = ($FIG_Config::arch eq 'win' ? 'self' : scalar(getpwent()));
            $retVal = CustomAttributes->new(user => $user);
        }
        # Save it for next time.
        $self->{_ca} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 CoreGenomes

    my @genomes = $sprout->CoreGenomes($scope);

Return the IDs of NMPDR genomes in the specified scope.

=over 4

=item scope

Scope of the desired genomes. C<core> covers the original core genomes,
C<nmpdr> covers all genomes in NMPDR groups, and C<all> covers all
genomes in the system.

=item RETURN

Returns a list of the IDs for the genomes in the specified scope.

=back

=cut

sub CoreGenomes {
    # Get the parameters.
    my ($self, $scope) = @_;
    # Declare the return variable.
    my @retVal = ();
    # If we want all genomes, then this is easy.
    if ($scope eq 'all') {
        @retVal = $self->Genomes();
    } else {
        # Here we're dealing with groups. Get the hash of all the
        # genome groups.
        my %groups = $self->GetGroups();
        # Loop through the groups, keeping the ones that we want.
        for my $group (keys %groups) {
            # Decide if we want to keep this group.
            my $keepGroup = 0;
            if ($scope eq 'nmpdr') {
                # NMPDR mode: keep all groups.
                $keepGroup = 1;
            } elsif ($scope eq 'core') {
                # CORE mode. Only keep real core groups.
                if (grep { $group =~ /$_/ } @{$FIG_Config::realCoreGroups}) {
                    $keepGroup = 1;
                }
            }
            # Add this group if we're keeping it.
            if ($keepGroup) {
                push @retVal, @{$groups{$group}};
            }
        }
    }
    # Return the result.
    return @retVal;
}

=head3 SuperGroup

    my $superGroup = $sprout->SuperGroup($groupName);

Return the name of the super-group containing the specified NMPDR genome
group. If no appropriate super-group can be found, an error will be
thrown.

=over 4

=item groupName

Name of the group whose super-group is desired.

=item RETURN

Returns the name of the super-group containing the incoming group.

=back

=cut

sub SuperGroup {
    # Get the parameters.
    my ($self, $groupName) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the group hash.
    my %groupHash = $self->CheckGroupFile();
    # Find the super-group genus.
    $groupName =~ /([A-Z]\w+)/;
    my $nameThing = $1;
    # See if it's directly in the group hash.
    if (exists $groupHash{$nameThing}) {
        # Yes, then it's our result.
        $retVal = $nameThing;
    } else {
        # No, so we have to search.
        for my $superGroup (keys %groupHash) {
            # Get this super-group's item list.
            my $list = $groupHash{$superGroup}->{contents};
            # Search it.
            if (grep { $_->[0] eq $nameThing } @{$list}) {
                $retVal = $superGroup;
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 MaxSegment

    my $length = $sprout->MaxSegment();

This method returns the maximum permissible length of a feature segment. The length is important
because it enables us to make reasonable guesses at how to find features inside a particular
contig region. For example, if the maximum length is 4000 and we're looking for a feature that
overlaps the region from 6000 to 7000 we know that the starting position must be between 2001
and 10999.

=cut
#: Return Type $;
sub MaxSegment {
    my ($self) = @_;
    return $self->{_options}->{maxSegmentLength};
}

=head3 MaxSequence

    my $length = $sprout->MaxSequence();

This method returns the maximum permissible length of a contig sequence. A contig is broken
into sequences in order to save memory resources. In particular, when manipulating features,
we generally only need a few sequences in memory rather than the entire contig.

=cut
#: Return Type $;
sub MaxSequence {
    my ($self) = @_;
    return $self->{_options}->{maxSequenceLength};
}

=head3 Load

    $sprout->Load($rebuild);;

Load the database from files in the data directory, optionally re-creating the tables.

This method always deletes the data from the database before loading, even if the tables are not
re-created. The data is loaded into the relations from files in the data directory either having the
same name as the target relation with no extension or with an extension of C<.dtx>. Files without an
extension are used in preference to the files with an extension.

The files are loaded based on the presumption that each line of the file is a record in the
relation, and the individual fields are delimited by tabs. Tab and new-line characters inside
fields must be represented by the escape sequences C<\t> and C<\n>, respectively. The fields must
be presented in the order given in the relation tables produced by the database documentation.

=over 4

=item rebuild

TRUE if the data tables need to be created or re-created, else FALSE

=item RETURN

Returns a statistical object containing the number of records read, the number of duplicates found,
the number of errors, and a list of the error messages.

=back

=cut
#: Return Type %;
sub Load {
    # Get the parameters.
    my ($self, $rebuild) = @_;
    # Load the tables from the data directory.
    my $retVal = $self->LoadTables($self->{_options}->{dataDir}, $rebuild);
    # Return the statistics.
    return $retVal;
}

=head3 LoadUpdate

    my $stats = $sprout->LoadUpdate($truncateFlag, \@tableList);

Load updates to one or more database tables. This method enables the client to make changes to one
or two tables without reloading the whole database. For each table, there must be a corresponding
file in the data directory, either with the same name as the table, or with a C<.dtx> suffix. So,
for example, to make updates to the B<FeatureTranslation> relation, there must be a
C<FeatureTranslation.dtx> file in the data directory. Unlike a full load, files without an extension
are not examined. This allows update files to co-exist with files from an original load.

=over 4

=item truncateFlag

TRUE if the tables should be rebuilt before loading, else FALSE. A value of TRUE therefore causes
current data and schema of the tables to be replaced, while a value of FALSE means the new data
is added to the existing data in the various relations.

=item tableList

List of the tables to be updated.

=item RETURN

Returns a statistical object containing the number of records read, the number of duplicates found,
the number of errors encountered, and a list of error messages.

=back

=cut
#: Return Type $%;
sub LoadUpdate {
    # Get the parameters.
    my ($self, $truncateFlag, $tableList) = @_;
    # Declare the return value.
    my $retVal = Stats->new();
    # Get the data directory.
    my $optionTable = $self->{_options};
    my $dataDir = $optionTable->{dataDir};
    # Loop through the incoming table names.
    for my $tableName (@{$tableList}) {
        # Find the table's file.
        my $fileName = LoadFileName($dataDir, $tableName);
        if (! $fileName) {
            Trace("No load file found for $tableName in $dataDir.") if T(0);
        } else {
            # Attempt to load this table.
            my $result = $self->LoadTable($fileName, $tableName, truncate => $truncateFlag);
            # Accumulate the resulting statistics.
            $retVal->Accumulate($result);
        }
    }
    # Return the statistics.
    return $retVal;
}

=head3 GenomeCounts

    my ($arch, $bact, $euk, $vir, $env, $unk) = $sprout->GenomeCounts($complete);

Count the number of genomes in each domain. If I<$complete> is TRUE, only complete
genomes will be included in the counts.

=over 4

=item complete

TRUE if only complete genomes are to be counted, FALSE if all genomes are to be
counted

=item RETURN

A six-element list containing the number of genomes in each of six categories--
Archaea, Bacteria, Eukaryota, Viral, Environmental, and Unknown, respectively.

=back

=cut

sub GenomeCounts {
    # Get the parameters.
    my ($self, $complete) = @_;
    # Set the filter based on the completeness flag.
    my $filter = ($complete ? "Genome(complete) = 1" : "");
    # Get all the genomes and the related taxonomy information.
    my @genomes = $self->GetAll(['Genome'], $filter, [], ['Genome(id)', 'Genome(taxonomy)']);
    # Clear the counters.
    my ($arch, $bact, $euk, $vir, $env, $unk) = (0, 0, 0, 0, 0, 0);
    # Loop through, counting the domains.
    for my $genome (@genomes) {
        if    ($genome->[1] =~ /^archaea/i)  { ++$arch }
        elsif ($genome->[1] =~ /^bacter/i)   { ++$bact }
        elsif ($genome->[1] =~ /^eukar/i)    { ++$euk }
        elsif ($genome->[1] =~ /^vir/i)      { ++$vir }
        elsif ($genome->[1] =~ /^env/i)      { ++$env }
        else  { ++$unk }
    }
    # Return the counts.
    return ($arch, $bact, $euk, $vir, $env, $unk);
}

=head3 ContigCount

    my $count = $sprout->ContigCount($genomeID);

Return the number of contigs for the specified genome ID.

=over 4

=item genomeID

ID of the genome whose contig count is desired.

=item RETURN

Returns the number of contigs for the specified genome.

=back

=cut

sub ContigCount {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Get the contig count.
    my $retVal = $self->GetCount(['Contig', 'HasContig'], "HasContig(from-link) = ?", [$genomeID]);
    # Return the result.
    return $retVal;
}

=head3 GenomeMenu

    my $html = $sprout->GenomeMenu(%options);

Generate a genome selection control with the specified name and options.
This control is almost but not quite the same as the genome control in the
B<SearchHelper> class. Eventually, the two will be combined.

=over 4

=item options

Optional parameters for the control (see below).

=item RETURN

Returns the HTML for a genome selection control on a form (sometimes called a popup menu).

=back

The valid options are as follows.

=over 4

=item name

Name to give this control for use in passing it to the form. The default is C<myGenomeControl>.
Terrible things will happen if you have two controls with the same name on the same page.

=item filter

If specified, a filter for the list of genomes to display. The filter should be in the form of a
list reference, a string, or a hash reference. If it is a list reference, the first element
of the list should be the filter string, and the remaining elements the filter parameters. If it is a
string, it will be split into a list at each included tab. If it is a hash reference, it should be
a hash that maps genomes which should be included to a TRUE value.

=item multiSelect

If TRUE, then the user can select multiple genomes. If FALSE, the user can only select one genome.

=item size

Number of rows to display in the control. The default is C<10>

=item id

ID to give this control. The default is the value of the C<name> option. Nothing will work correctly
unless this ID is unique.

=item selected

A comma-delimited list of selected genomes, or a reference to a list of selected genomes. The
default is none.

=item class

If specified, a style class to assign to the genome control.

=back

=cut

sub GenomeMenu {
    # Get the parameters.
    my ($self, %options) = @_;
    # Get the control's name and ID.
    my $menuName = $options{name} || $options{id} || 'myGenomeControl';
    my $menuID = $options{id} || $menuName;
    Trace("Genome menu name = $menuName with ID $menuID.") if T(3);
    # Compute the IDs for the status display.
    my $divID = "${menuID}_status";
    my $urlID = "${menuID}_url";
    # Compute the code to show selected genomes in the status area.
    my $showSelect = "showSelected('$menuID', '$divID', '$urlID', $FIG_Config::genome_control_cap)";
    # Check for single-select or multi-select.
    my $multiSelect = $options{multiSelect} || 0;
    # Get the style data.
    my $class = $options{class} || '';
    # Get the list of pre-selected items.
    my $selections = $options{selected} || [];
    if (ref $selections ne 'ARRAY') {
        $selections = [ split /\s*,\s*/, $selections ];
    }
    my %selected = map { $_ => 1 } @{$selections};
    # Extract the filter information. The default is no filtering. It can be passed as a tab-delimited
    # string, a hash reference, or a list reference.
    my ($filterHash, $filterString);
    my $filterParms = $options{filter} || "";
    if (ref $filterParms eq 'HASH') {
        $filterHash = $filterParms;
        $filterParms = [];
        $filterString = "";
    } else {
        if (! ref $filterParms) {
            $filterParms = [split /\t|\\t/, $filterParms];
        }
        $filterString = shift @{$filterParms};
    }
    # Check for possible subsystem filtering. If there is one, we will tack the
    # relationship onto the object name list.
    my @objectNames = qw(Genome);
    if ($filterString =~ /ParticipatesIn\(/) {
        push @objectNames, 'ParticipatesIn';
    }
    # Get a list of all the genomes in group order. In fact, we only need them ordered
    # by name (genus,species,strain), but putting primary-group in front enables us to
    # take advantage of an existing index.
    my @genomeList = $self->GetAll(\@objectNames, "$filterString ORDER BY Genome(primary-group), Genome(genus), Genome(species), Genome(unique-characterization)",
                                   $filterParms,
                                   [qw(Genome(primary-group) Genome(id) Genome(genus) Genome(species) Genome(unique-characterization) Genome(taxonomy) Genome(contigs))]);
    # Apply the hash filter (if any).
    if (defined $filterHash) {
        @genomeList = grep { $filterHash->{$_->[1]} } @genomeList;
    }
    # Create a hash to organize the genomes by group. Each group will contain a list of
    # 2-tuples, the first element being the genome ID and the second being the genome
    # name.
    my %gHash = ();
    for my $genome (@genomeList) {
        # Get the genome data.
        my ($group, $genomeID, $genus, $species, $strain, $taxonomy, $contigs) = @{$genome};
        # Compute its name. This is the genus, species, strain (if any), and the contig count.
        my $name = "$genus $species ";
        $name .= "$strain " if $strain;
        my $contigCount = ($contigs == 1 ? "" : ", $contigs contigs");
        # Now we get the domain. The domain tells us the display style of the organism.
        my ($domain) = split /\s*;\s*/, $taxonomy, 2;
        # Now compute the display group. This is normally the primary group, but if the
        # organism is supporting, we blank it out.
        my $displayGroup = ($group eq $FIG_Config::otherGroup ? "" : $group);
        # Push the genome into the group's list. Note that we use the real group
        # name for the hash key here, not the display group name.
        push @{$gHash{$group}}, [$genomeID, $name, $contigCount, $domain];
    }
    # We are almost ready to unroll the menu out of the group hash. The final step is to separate
    # the supporting genomes by domain. First, we extract the NMPDR groups and sort them. They
    # are sorted by the first capitalized word. Groups with "other" are sorted after groups
    # that aren't "other". At some point, we will want to make this less complicated.
    my %sortGroups = map { $_ =~ /(other)?(.*)([A-Z].+)/; "$3$1$2" => $_ }
                         grep { $_ ne $FIG_Config::otherGroup } keys %gHash;
    my @groups = map { $sortGroups{$_} } sort keys %sortGroups;
    # Remember the number of NMPDR groups.
    my $nmpdrGroupCount = scalar @groups;
    # Are there any supporting genomes?
    if (exists $gHash{$FIG_Config::otherGroup}) {
        # Loop through the supporting genomes, classifying them by domain. We'll also keep a list
        # of the domains found.
        my @otherGenomes = @{$gHash{$FIG_Config::otherGroup}};
        my @domains = ();
        for my $genomeData (@otherGenomes) {
            my ($genomeID, $name, $contigCount, $domain) = @{$genomeData};
            if (exists $gHash{$domain}) {
                push @{$gHash{$domain}}, $genomeData;
            } else {
                $gHash{$domain} = [$genomeData];
                push @domains, $domain;
            }
        }
        # Add the domain groups at the end of the main group list. The main group list will now
        # contain all the categories we need to display the genomes.
        push @groups, sort @domains;
        # Delete the supporting group.
        delete $gHash{$FIG_Config::otherGroup};
    }
    # Now it gets complicated. We need a way to mark all the NMPDR genomes. We take advantage
    # of the fact they come first in the list. We'll accumulate a count of the NMPDR genomes
    # and use that to make the selections.
    my $nmpdrCount = 0;
    # Create the type counters.
    my $groupCount = 1;
    # Get the number of rows to display.
    my $rows = $options{size} || 10;
    # If we're multi-row, create an onChange event.
    my $onChangeTag = ( $rows > 1 ? " onChange=\"$showSelect;\" onFocus=\"$showSelect;\"" : "" );
    # Set up the multiple-select flag.
    my $multipleTag = ($multiSelect ? " multiple" : "" );
    # Set up the style class.
    my $classTag = ($class ? " $class" : "" );
    # Create the SELECT tag and stuff it into the output array.
    my @lines = qq(<SELECT name="$menuName" id="$menuID" class="genomeSelect $class" $onChangeTag$multipleTag$classTag size="$rows">);
    # Loop through the groups.
    for my $group (@groups) {
        # Get the genomes in the group.
        for my $genome (@{$gHash{$group}}) {
            # If this is an NMPDR organism, we add an extra style and count it.
            my $nmpdrStyle = "";
            if ($nmpdrGroupCount > 0) {
                $nmpdrCount++;
                $nmpdrStyle = " Core";
            }
            # Get the organism ID, name, contig count, and domain.
            my ($genomeID, $name, $contigCount, $domain) = @{$genome};
            # See if we're pre-selected.
            my $selectTag = ($selected{$genomeID} ? " SELECTED" : "");
            # Compute the display name.
            my $nameString = "$name ($genomeID$contigCount)";
            # Generate the option tag.
            my $optionTag = "<OPTION class=\"$domain$nmpdrStyle\" title=\"$group\" value=\"$genomeID\"$selectTag>$nameString</OPTION>";
            push @lines, "    $optionTag";
        }
        # Record this group in the nmpdrGroup count. When that gets to 0, we've finished the NMPDR
        # groups.
        $nmpdrGroupCount--;
    }
    # Close the SELECT tag.
    push @lines, "</SELECT>";
    if ($rows > 1) {
        # We're in a non-compact mode, so we need to add some selection helpers. First is
        # the search box. This allows the user to type text and change which genomes are
        # displayed. For multiple-select mode, we include a button that selects the displayed
        # genes. For single-select mode, we use a plain label instead.
        my $searchThingName = "${menuID}_SearchThing";
        my $searchThingLabel = "Type to narrow selection";
        my $searchThingButton = "";
        if ($multiSelect) {
            $searchThingButton = qq(<INPUT type="button" name="MacroSearch" class="button" value="Go" onClick="selectShowing('$menuID', '$searchThingName'); $showSelect;" />);
        }
        push @lines, "<br />$searchThingLabel&nbsp;" .
                     qq(<INPUT type="text" id="$searchThingName" name="$searchThingName" class="genomeSearchThing" onKeyup="showTyped('$menuID', '$searchThingName');" />) .
                     $searchThingButton .
                     Hint("GenomeControl", 28) . "<br />";
        # For multi-select mode, we also have buttons to set and clear selections.
        if ($multiSelect) {
            push @lines, qq(<INPUT type="button" name="ClearAll" class="bigButton genomeButton" value="Clear All" onClick="clearAll(getElementById('$menuID')); $showSelect" />);
            push @lines, qq(<INPUT type="button" name="SelectAll" class="bigButton genomeButton" value="Select All" onClick="selectAll(getElementById('$menuID')); $showSelect" />);
            push @lines, qq(<INPUT type="button" name="NMPDROnly" class="bigButton genomeButton" value="Select NMPDR" onClick="selectSome(getElementById('$menuID'), $nmpdrCount, true); $showSelect;" />);
        }
        # Add a hidden field we can use to generate organism page hyperlinks.
        push @lines, qq(<INPUT type="hidden" id="$urlID" value="$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/SeedViewer?page=Organism;organism=" />);
        # Add the status display. This tells the user what's selected no matter where the list is scrolled.
        push @lines, qq(<DIV id="$divID" class="Panel"></DIV>);
    }
    # Assemble all the lines into a string.
    my $retVal = join("\n", @lines, "");
    # Return the result.
    return $retVal;
}

=head3 Cleanup

    $sprout->Cleanup();

Release the internal cache structures to free up memory.

=cut

sub Cleanup {
    # Get the parameters.
    my ($self) = @_;
    # Delete the stemmer.
    delete $self->{stemmer};
    # Delete the attribute database.
    delete $self->{_ca};
    # Delete the group hash.
    delete $self->{groupHash};
    # Is there a FIG object?
    if (defined $self->{fig}) {
        # Yes, clear its subsystem cache.
        $self->{fig}->clear_subsystem_cache();
    }
}


=head3 Stem

    my $stem = $sprout->Stem($word);

Return the stem of the specified word, or C<undef> if the word is not
stemmable. Note that even if the word is stemmable, the stem may be
the same as the original word.

=over 4

=item word

Word to convert into a stem.

=item RETURN

Returns a stem of the word (which may be the word itself), or C<undef> if
the word is not stemmable.

=back

=cut

sub Stem {
    # Get the parameters.
    my ($self, $word) = @_;
    # Get the stemmer object.
    my $stemmer = $self->{stemmer};
    if (! defined $stemmer) {
        # We don't have one pre-built, so we build and save it now.
        $stemmer = BioWords->new(exceptions => "$FIG_Config::sproutData/Exceptions.txt",
                                 stops => "$FIG_Config::sproutData/StopWords.txt",
                                 cache => 0);
        $self->{stemmer} = $stemmer;
    }
    # Try to stem the word.
    my $retVal = $stemmer->Process($word);
    # Return the result.
    return $retVal;
}


=head3 Build

    $sprout->Build();

Build the database. The database will be cleared and the tables re-created from the metadata.
This method is useful when a database is brand new or when the database definition has
changed.

=cut
#: Return Type ;
sub Build {
    # Get the parameters.
    my ($self) = @_;
    # Create the tables.
    $self->CreateTables();
}

=head3 Genomes

    my @genomes = $sprout->Genomes();

Return a list of all the genome IDs.

=cut
#: Return Type @;
sub Genomes {
    # Get the parameters.
    my ($self) = @_;
    # Get all the genomes.
    my @retVal = $self->GetFlat(['Genome'], "", [], 'Genome(id)');
    # Return the list of IDs.
    return @retVal;
}

=head3 GenusSpecies

    my $infoString = $sprout->GenusSpecies($genomeID);

Return the genus, species, and unique characterization for a genome.

=over 4

=item genomeID

ID of the genome whose genus and species is desired

=item RETURN

Returns the genus and species of the genome, with the unique characterization (if any). If the genome
does not exist, returns an undefined value.

=back

=cut
#: Return Type $;
sub GenusSpecies {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return value.
    my $retVal;
    # Get the genome data.
    my $genomeData = $self->_GenomeData($genomeID);
    # Only proceed if we found the genome.
    if (defined $genomeData) {
        $retVal = $genomeData->PrimaryValue('Genome(scientific-name)');
    }
    # Return it.
    return $retVal;
}

=head3 FeaturesOf

    my @features = $sprout->FeaturesOf($genomeID, $ftype);

Return a list of the features relevant to a specified genome.

=over 4

=item genomeID

Genome whose features are desired.

=item ftype

Type of feature desired. If omitted, all features will be returned.

=item RETURN

Returns a list of the feature IDs for features relevant to the genome. If the genome does not exist,
will return an empty list.

=back

=cut
#: Return Type @;
sub FeaturesOf {
    # Get the parameters.
    my ($self, $genomeID,$ftype) = @_;
    # Get the features we want.
    my @features;
    if (!$ftype) {
        @features = $self->GetFlat(['HasContig', 'IsLocatedIn'], "HasContig(from-link) = ?",
                                   [$genomeID], 'IsLocatedIn(from-link)');
    } else {
        @features = $self->GetFlat(['HasContig', 'IsLocatedIn', 'Feature'],
                            "HasContig(from-link) = ? AND Feature(feature-type) = ?",
                            [$genomeID, $ftype], 'IsLocatedIn(from-link)');
    }
    # Return the list with duplicates merged out. We need to merge out duplicates because
    # a feature will appear twice if it spans more than one contig.
    my @retVal = Tracer::Merge(@features);
    # Return the list of feature IDs.
    return @retVal;
}

=head3 FeatureLocation

    my @locations = $sprout->FeatureLocation($featureID);

Return the location of a feature in its genome's contig segments. In a list context, this method
will return a list of the locations. In a scalar context, it will return the locations as a space-
delimited string. Each location will be of the form I<contigID>C<_>I<begin>I<dir>I<len> where
I<begin> is the starting position, I<dir> is C<+> for a forward transcription or C<-> for a backward
transcription, and I<len> is the length. So, for example, C<1999.1_NC123_4000+200> describes a location
beginning at position 4000 of contig C<1999.1_NC123> and ending at position 4199. Similarly,
C<1999.1_NC123_2000-400> describes a location in the same contig starting at position 2000 and ending
at position 1601.

This process is complicated by the fact that we automatically split up feature segments longer than
the maximum segment length. When we find two segments that are adjacent to each other, we must
put them back together.

=over 4

=item featureID

FIG ID of the desired feature

=item RETURN

Returns a list of the feature's contig segments. The locations are returned as a list in a list
context and as a comma-delimited string in a scalar context. An empty list means the feature
wasn't found.

=back

=cut

sub FeatureLocation {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Get the feature record.
    my $object = $self->GetEntity('Feature', $featureID);
    # Only proceed if we found it.
    if (defined $object) {
        # Get the location string.
        my $locString = $object->PrimaryValue('Feature(location-string)');
        # Create the return list.
        @retVal = split /\s*,\s*/, $locString;
    }
    # Return the list in the format indicated by the context.
    return (wantarray ? @retVal : join(',', @retVal));
}

=head3 ParseLocation

    my ($contigID, $start, $dir, $len) = Sprout::ParseLocation($location);

Split a location specifier into the contig ID, the starting point, the direction, and the
length.

=over 4

=item location

A location specifier (see L</FeatureLocation> for a description).

=item RETURN

Returns a list containing the contig ID, the start position, the direction (C<+> or C<->),
and the length indicated by the incoming location specifier.

=back

=cut

sub ParseLocation {
    # Get the parameter. Note that if we're called as an instance method, we ignore
    # the first parameter.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($location) = @_;
    # Parse it into segments.
    $location =~ /^(.+)_(\d+)([+\-_])(\d+)$/;
    my ($contigID, $start, $dir, $len) = ($1, $2, $3, $4);
    # If the direction is an underscore, convert it to a + or -.
    if ($dir eq "_") {
        if ($start < $len) {
            $dir = "+";
            $len = $len - $start + 1;
        } else {
            $dir = "-";
            $len = $start - $len + 1;
        }
    }
    # Return the result.
    return ($contigID, $start, $dir, $len);
}


=head3 PointLocation

    my $found = Sprout::PointLocation($location, $point);

Return the offset into the specified location of the specified point on the contig. If
the specified point is before the location, a negative value will be returned. If it is
beyond the location, an undefined value will be returned. It is assumed that the offset
is for the location's contig. The location can either be new-style (using a C<+> or C<->
and a length) or old-style (using C<_> and start and end positions.

=over 4

=item location

A location specifier (see L</FeatureLocation> for a description).

=item point

The offset into the contig of the point in which we're interested.

=item RETURN

Returns the offset inside the specified location of the specified point, a negative
number if the point is before the location, or an undefined value if the point is past
the location. If the length of the location is 0, this method will B<always> denote
that it is outside the location. The offset will always be relative to the left-most
position in the location.

=back

=cut

sub PointLocation {
    # Get the parameter. Note that if we're called as an instance method, we ignore
    # the first parameter.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($location, $point) = @_;
    # Parse out the location elements. Note that this works on both old-style and new-style
    # locations.
    my ($contigID, $start, $dir, $len) = ParseLocation($location);
    # Declare the return variable.
    my $retVal;
    # Compute the offset. The computation is dependent on the direction of the location.
    my $offset = (($dir == '+') ? $point - $start : $point - ($start - $len + 1));
    # Return the offset if it's valid.
    if ($offset < $len) {
        $retVal = $offset;
    }
    # Return the offset found.
    return $retVal;
}

=head3 DNASeq

    my $sequence = $sprout->DNASeq(\@locationList);

This method returns the DNA sequence represented by a list of locations. The list of locations
should be of the form returned by L</featureLocation> when in a list context. In other words,
each location is of the form I<contigID>C<_>I<begin>I<dir>I<end>.

For example, the following would return the DNA sequence for contig C<83333.1:NC_000913>
between positions 1401 and 1532, inclusive.

    my $sequence = $sprout->DNASeq('83333.1:NC_000913_1401_1532');

=over 4

=item locationList

List of location specifiers, each in the form I<contigID>C<_>I<begin>I<dir>I<len> or
I<contigID>C<_>I<begin>C<_>I<end> (see L</FeatureLocation> for more about this format).

=item RETURN

Returns a string of nucleotides corresponding to the DNA segments in the location list.

=back

=cut
#: Return Type $;
sub DNASeq {
    # Get the parameters.
    my ($self, $locationList) = @_;
    # Create the return string.
    my $retVal = "";
    # Loop through the locations.
    for my $location (@{$locationList}) {
        # Set up a variable to contain the DNA at this location.
        my $locationDNA = "";
        # Parse out the contig ID, the beginning point, the direction, and the end point.
        my ($contigID, $beg, $dir, $len) = ParseLocation($location);
        # Now we must create a query to return all the sequences in the contig relevant to the region
        # specified. First, we compute the start and stop points when reading through the sequences.
        # For a forward transcription, the start point is the beginning; for a backward transcription,
        # the start point is the ending. Note that in the latter case we must reverse the DNA string
        # before putting it in the return value.
        my ($start, $stop);
        Trace("Parse of \"$location\" is $beg$dir$len.") if T(SDNA => 4);
        if ($dir eq "+") {
            $start = $beg;
            $stop = $beg + $len - 1;
        } else {
            $start = $beg - $len + 1;
            $stop = $beg;
        }
        Trace("Looking for sequences containing $start through $stop.") if T(SDNA => 4);
        my $query = $self->Get(['IsMadeUpOf','Sequence'],
            "IsMadeUpOf(from-link) = ? AND IsMadeUpOf(start-position) + IsMadeUpOf(len) > ? AND " .
            " IsMadeUpOf(start-position) <= ? ORDER BY IsMadeUpOf(start-position)",
            [$contigID, $start, $stop]);
        # Loop through the sequences.
        while (my $sequence = $query->Fetch()) {
            # Determine whether the location starts, stops, or continues through this sequence.
            my ($startPosition, $sequenceData, $sequenceLength) =
                $sequence->Values(['IsMadeUpOf(start-position)', 'Sequence(sequence)',
                                   'IsMadeUpOf(len)']);
            my $stopPosition = $startPosition + $sequenceLength;
            Trace("Sequence is from $startPosition to $stopPosition.") if T(SDNA => 4);
            # Figure out the start point and length of the relevant section.
            my $pos1 = ($start < $startPosition ? 0 : $start - $startPosition);
            my $len1 = ($stopPosition < $stop ? $stopPosition : $stop) + 1 - $startPosition - $pos1;
            Trace("Position is $pos1 for length $len1.") if T(SDNA => 4);
            # Add the relevant data to the location data.
            $locationDNA .= substr($sequenceData, $pos1, $len1);
        }
        # Add this location's data to the return string. Note that we may need to reverse it.
        if ($dir eq '+') {
            $retVal .= $locationDNA;
        } else {
            $retVal .= FIG::reverse_comp($locationDNA);
        }
    }
    # Return the result.
    return $retVal;
}

=head3 AllContigs

    my @idList = $sprout->AllContigs($genomeID);

Return a list of all the contigs for a genome.

=over 4

=item genomeID

Genome whose contigs are desired.

=item RETURN

Returns a list of the IDs for the genome's contigs.

=back

=cut
#: Return Type @;
sub AllContigs {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Ask for the genome's Contigs.
    my @retVal = $self->GetFlat(['HasContig'], "HasContig(from-link) = ?", [$genomeID],
                                'HasContig(to-link)');
    # Return the list of Contigs.
    return @retVal;
}

=head3 GenomeLength

    my $length = $sprout->GenomeLength($genomeID);

Return the length of the specified genome in base pairs.

=over 4

=item genomeID

ID of the genome whose base pair count is desired.

=item RETURN

Returns the number of base pairs in all the contigs of the specified
genome.

=back

=cut

sub GenomeLength {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Get the genome data.
    my $genomeData = $self->_GenomeData($genomeID);
    # Only proceed if it exists.
    if (defined $genomeData) {
        $retVal = $genomeData->PrimaryValue('Genome(dna-size)');
    }
    # Return the result.
    return $retVal;
}

=head3 FeatureCount

    my $count = $sprout->FeatureCount($genomeID, $type);

Return the number of features of the specified type in the specified genome.

=over 4

=item genomeID

ID of the genome whose feature count is desired.

=item type

Type of feature to count (eg. C<peg>, C<rna>, etc.).

=item RETURN

Returns the number of features of the specified type for the specified genome.

=back

=cut

sub FeatureCount {
    # Get the parameters.
    my ($self, $genomeID, $type) = @_;
    # Compute the count.
    my $retVal = $self->GetCount(['HasFeature', 'Feature'],
                                "HasFeature(from-link) = ? AND Feature(feature-type) = ?",
                                [$genomeID, $type]);
    # Return the result.
    return $retVal;
}

=head3 GenomeAssignments

    my $fidHash = $sprout->GenomeAssignments($genomeID);

Return a list of a genome's assigned features. The return hash will contain each
assigned feature of the genome mapped to the text of its most recent functional
assignment.

=over 4

=item genomeID

ID of the genome whose functional assignments are desired.

=item RETURN

Returns a reference to a hash which maps each feature to its most recent
functional assignment.

=back

=cut

sub GenomeAssignments {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return variable.
    my $retVal = {};
    # Query the genome's features.
    my $query = $self->Get(['HasFeature', 'Feature'], "HasFeature(from-link) = ?",
                           [$genomeID]);
    # Loop through the features.
    while (my $data = $query->Fetch) {
        # Get the feature ID and assignment.
        my ($fid, $assignment) = $data->Values(['Feature(id)', 'Feature(assignment)']);
        if ($assignment) {
            $retVal->{$fid} = $assignment;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 ContigLength

    my $length = $sprout->ContigLength($contigID);

Compute the length of a contig.

=over 4

=item contigID

ID of the contig whose length is desired.

=item RETURN

Returns the number of positions in the contig.

=back

=cut
#: Return Type $;
sub ContigLength {
    # Get the parameters.
    my ($self, $contigID) = @_;
    # Get the contig's last sequence.
    my $query = $self->Get(['IsMadeUpOf'],
        "IsMadeUpOf(from-link) = ? ORDER BY IsMadeUpOf(start-position) DESC",
        [$contigID]);
    my $sequence = $query->Fetch();
    # Declare the return value.
    my $retVal = 0;
    # Set it from the sequence data, if any.
    if ($sequence) {
        my ($start, $len) = $sequence->Values(['IsMadeUpOf(start-position)', 'IsMadeUpOf(len)']);
        $retVal = $start + $len - 1;
    }
    # Return the result.
    return $retVal;
}

=head3 ClusterPEGs

    my $clusteredList = $sprout->ClusterPEGs($sub, \@pegs);

Cluster the PEGs in a list according to the cluster coding scheme of the specified
subsystem. In order for this to work properly, the subsystem object must have
been used recently to retrieve the PEGs using the B<get_pegs_from_cell> or
B<get_row> methods. This causes the cluster numbers to be pulled into the
subsystem's color hash. If a PEG is not found in the color hash, it will not
appear in the output sequence.

=over 4

=item sub

Sprout subsystem object for the relevant subsystem, from the L</get_subsystem>
method.

=item pegs

Reference to the list of PEGs to be clustered.

=item RETURN

Returns a list of the PEGs, grouped into smaller lists by cluster number.

=back

=cut
#: Return Type $@@;
sub ClusterPEGs {
    # Get the parameters.
    my ($self, $sub, $pegs) = @_;
    # Declare the return variable.
    my $retVal = [];
    # Loop through the PEGs, creating arrays for each cluster.
    for my $pegID (@{$pegs}) {
        my $clusterNumber = $sub->get_cluster_number($pegID);
        # Only proceed if the PEG is in a cluster.
        if ($clusterNumber >= 0) {
            # Push this PEG onto the sub-list for the specified cluster number.
            push @{$retVal->[$clusterNumber]}, $pegID;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 GenesInRegion

    my (\@featureIDList, $beg, $end) = $sprout->GenesInRegion($contigID, $start, $stop);

List the features which overlap a specified region in a contig.

=over 4

=item contigID

ID of the contig containing the region of interest.

=item start

Offset of the first residue in the region of interest.

=item stop

Offset of the last residue in the region of interest.

=item RETURN

Returns a three-element list. The first element is a list of feature IDs for the features that
overlap the region of interest. The second and third elements are the minimum and maximum
locations of the features provided on the specified contig. These may extend outside
the start and stop values. The first element (that is, the list of features) is sorted
roughly by location.

=back

=cut

sub GenesInRegion {
    # Get the parameters.
    my ($self, $contigID, $start, $stop) = @_;
    # Get the maximum segment length.
    my $maximumSegmentLength = $self->MaxSegment;
    # Prime the values we'll use for the returned beginning and end.
    my @initialMinMax = ($self->ContigLength($contigID), 0);
    my ($min, $max) = @initialMinMax;
    # Get the overlapping features.
    my @featureObjects = $self->GeneDataInRegion($contigID, $start, $stop);
    # We'l use this hash to help us track the feature IDs and sort them. The key is the
    # feature ID and the value is a [$left,$right] pair indicating the maximum extent
    # of the feature's locations.
    my %featureMap = ();
    # Loop through them to do the begin/end analysis.
    for my $featureObject (@featureObjects) {
        # Get the feature's location string. This may contain multiple actual locations.
        my ($locations, $fid) = $featureObject->Values([qw(Feature(location-string) Feature(id))]);
        my @locationSegments = split /\s*,\s*/, $locations;
        # Loop through the locations.
        for my $locationSegment (@locationSegments) {
            # Construct an object for the location.
            my $locationObject = BasicLocation->new($locationSegment);
            # Merge the current segment's begin and end into the min and max.
            my ($left, $right) = ($locationObject->Left, $locationObject->Right);
            my ($beg, $end);
            if (exists $featureMap{$fid}) {
                ($beg, $end) = @{$featureMap{$fid}};
                $beg = $left if $left < $beg;
                $end = $right if $right > $end;
            } else {
                ($beg, $end) = ($left, $right);
            }
            $min = $beg if $beg < $min;
            $max = $end if $end > $max;
            # Store the feature's new extent back into the hash table.
            $featureMap{$fid} = [$beg, $end];
        }
    }
    # Now we must compute the list of the IDs for the features found. We start with a list
    # of midpoints / feature ID pairs. (It's not really a midpoint, it's twice the midpoint,
    # but the result of the sort will be the same.)
    my @list = map { [$featureMap{$_}->[0] + $featureMap{$_}->[1], $_] } keys %featureMap;
    # Now we sort by midpoint and yank out the feature IDs.
    my @retVal = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @list;
    # Return it along with the min and max.
    return (\@retVal, $min, $max);
}

=head3 GeneDataInRegion

    my @featureList = $sprout->GenesInRegion($contigID, $start, $stop);

List the features which overlap a specified region in a contig.

=over 4

=item contigID

ID of the contig containing the region of interest.

=item start

Offset of the first residue in the region of interest.

=item stop

Offset of the last residue in the region of interest.

=item RETURN

Returns a list of B<ERDBObjects> for the desired features. Each object will
contain a B<Feature> record.

=back

=cut

sub GeneDataInRegion {
    # Get the parameters.
    my ($self, $contigID, $start, $stop) = @_;
    # Get the maximum segment length.
    my $maximumSegmentLength = $self->MaxSegment;
    # Create a hash to receive the feature list. We use a hash so that we can eliminate
    # duplicates easily. The hash key will be the feature ID. The value will be the feature's
    # ERDBObject from the query.
    my %featuresFound = ();
    # Create a table of parameters for the queries. Each query looks for features travelling in
    # a particular direction. The query parameters include the contig ID, the feature direction,
    # the lowest possible start position, and the highest possible start position. This works
    # because each feature segment length must be no greater than the maximum segment length.
    my %queryParms = (forward => [$contigID, '+', $start - $maximumSegmentLength + 1, $stop],
                      reverse => [$contigID, '-', $start, $stop + $maximumSegmentLength - 1]);
    # Loop through the query parameters.
    for my $parms (values %queryParms) {
        # Create the query.
        my $query = $self->Get([qw(Feature IsLocatedIn)],
            "IsLocatedIn(to-link)= ? AND IsLocatedIn(dir) = ? AND IsLocatedIn(beg) >= ? AND IsLocatedIn(beg) <= ?",
            $parms);
        # Loop through the feature segments found.
        while (my $segment = $query->Fetch) {
            # Get the data about this segment.
            my ($featureID, $contig, $dir, $beg, $len) = $segment->Values([qw(IsLocatedIn(from-link)
                IsLocatedIn(to-link) IsLocatedIn(dir) IsLocatedIn(beg) IsLocatedIn(len))]);
            # Determine if this feature segment actually overlaps the region. The query insures that
            # this will be the case if the segment is the maximum length, so to fine-tune
            # the results we insure that the inequality from the query holds using the actual
            # length.
            my $loc = BasicLocation->new($contig, $beg, $dir, $len);
            my $found = $loc->Overlap($start, $stop);
            if ($found) {
                # Save this feature in the result list.
                $featuresFound{$featureID} = $segment;
            }
        }
    }
    # Return the ERDB objects for the features found.
    return values %featuresFound;
}

=head3 FType

    my $ftype = $sprout->FType($featureID);

Return the type of a feature.

=over 4

=item featureID

ID of the feature whose type is desired.

=item RETURN

A string indicating the type of feature (e.g. peg, rna). If the feature does not exist, returns an
undefined value.

=back

=cut
#: Return Type $;
sub FType {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the specified feature's type.
    my ($retVal) = $self->GetEntityValues('Feature', $featureID, ['Feature(feature-type)']);
    # Return the result.
    return $retVal;
}

=head3 FeatureAnnotations

    my @descriptors = $sprout->FeatureAnnotations($featureID, $rawFlag);

Return the annotations of a feature.

=over 4

=item featureID

ID of the feature whose annotations are desired.

=item rawFlag

If TRUE, the annotation timestamps will be returned in raw form; otherwise, they
will be returned in human-readable form.

=item RETURN

Returns a list of annotation descriptors. Each descriptor is a hash with the following fields.

* B<featureID> ID of the relevant feature.

* B<timeStamp> time the annotation was made.

* B<user> ID of the user who made the annotation

* B<text> text of the annotation.

=back

=cut
#: Return Type @%;
sub FeatureAnnotations {
    # Get the parameters.
    my ($self, $featureID, $rawFlag) = @_;
    # Create a query to get the feature's annotations and the associated users.
    my $query = $self->Get(['IsTargetOfAnnotation', 'Annotation', 'MadeAnnotation'],
                           "IsTargetOfAnnotation(from-link) = ?", [$featureID]);
    # Create the return list.
    my @retVal = ();
    # Loop through the annotations.
    while (my $annotation = $query->Fetch) {
        # Get the fields to return.
        my ($featureID, $timeStamp, $user, $text) =
            $annotation->Values(['IsTargetOfAnnotation(from-link)',
                                 'Annotation(time)', 'MadeAnnotation(from-link)',
                                 'Annotation(annotation)']);
        # Convert the time, if necessary.
        if (! $rawFlag) {
            $timeStamp = FriendlyTimestamp($timeStamp);
        }
        # Assemble them into a hash.
        my $annotationHash = { featureID => $featureID,
                               timeStamp => $timeStamp,
                               user => $user, text => $text };
        # Add it to the return list.
        push @retVal, $annotationHash;
    }
    # Return the result list.
    return @retVal;
}

=head3 AllFunctionsOf

    my %functions = $sprout->AllFunctionsOf($featureID);

Return all of the functional assignments for a particular feature. The data is returned as a
hash of functional assignments to user IDs. A functional assignment is a type of annotation,
Functional assignments are described in the L</ParseAssignment> function. Its worth noting that
we cannot filter on the content of the annotation itself because it's a text field; however,
this is not a big problem because most features only have a small number of annotations.
Finally, if a single user has multiple functional assignments, we will only keep the most
recent one.

=over 4

=item featureID

ID of the feature whose functional assignments are desired.

=item RETURN

Returns a hash mapping the user IDs to functional assignment IDs.

=back

=cut
#: Return Type %;
sub AllFunctionsOf {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get all of the feature's annotations.
    my @query = $self->GetAll(['IsTargetOfAnnotation', 'Annotation', 'MadeAnnotation'],
                            "IsTargetOfAnnotation(from-link) = ?",
                            [$featureID], ['Annotation(time)', 'Annotation(annotation)',
                                           'MadeAnnotation(from-link)']);
    # Declare the return hash.
    my %retVal;
    # Now we sort the assignments by timestamp in reverse.
    my @sortedQuery = sort { -($a->[0] <=> $b->[0]) } @query;
    # Loop until we run out of annotations.
    for my $annotation (@sortedQuery) {
        # Get the annotation fields.
        my ($timeStamp, $text, $user) = @{$annotation};
        # Check to see if this is a functional assignment.
        my ($actualUser, $function) = _ParseAssignment($user, $text);
        if ($actualUser && ! exists $retVal{$actualUser}) {
            # Here it is a functional assignment and there has been no
            # previous assignment for this user, so we stuff it in the
            # return hash.
            $retVal{$actualUser} = $function;
        }
    }
    # Return the hash of assignments found.
    return %retVal;
}

=head3 FunctionOf

    my $functionText = $sprout->FunctionOf($featureID, $userID);

Return the most recently-determined functional assignment of a particular feature.

The functional assignment is handled differently depending on the type of feature. If
the feature is identified by a FIG ID (begins with the string C<fig|>), then the functional
assignment is taken from the B<Feature> or C<Annotation> table, depending.

Each user has an associated list of trusted users. The assignment returned will be the most
recent one by at least one of the trusted users. If no trusted user list is available, then
the specified user and FIG are considered trusted. If the user ID is omitted, only FIG
is trusted.

If the feature is B<not> identified by a FIG ID, then we search the aliases for it.
If no matching alias is found, we return an undefined value.

=over 4

=item featureID

ID of the feature whose functional assignment is desired.

=item userID (optional)

ID of the user whose function determination is desired. If omitted, the primary
functional assignment in the B<Feature> table will be returned.

=item RETURN

Returns the text of the assigned function.

=back

=cut
#: Return Type $;
sub FunctionOf {
    # Get the parameters.
    my ($self, $featureID, $userID) = @_;
    # Declare the return value.
    my $retVal;
    # Find a FIG ID for this feature.
    my ($fid) = $self->FeaturesByAlias($featureID);
    # Only proceed if we have an ID.
    if ($fid) {
        # Here we have a FIG feature ID.
        if (!$userID) {
            # Use the primary assignment.
            ($retVal) = $self->GetEntityValues('Feature', $fid, ['Feature(assignment)']);
        } else {
            # We must build the list of trusted users.
            my %trusteeTable = ();
            # Check the user ID.
            if (!$userID) {
                # No user ID, so only FIG is trusted.
                $trusteeTable{FIG} = 1;
            } else {
                # Add this user's ID.
                $trusteeTable{$userID} = 1;
                # Look for the trusted users in the database.
                my @trustees = $self->GetFlat(['IsTrustedBy'], 'IsTrustedBy(from-link) = ?', [$userID], 'IsTrustedBy(to-link)');
                if (! @trustees) {
                    # None were found, so build a default list.
                    $trusteeTable{FIG} = 1;
                } else {
                    # Otherwise, put all the trustees in.
                    for my $trustee (@trustees) {
                        $trusteeTable{$trustee} = 1;
                    }
                }
            }
            # Build a query for all of the feature's annotations, sorted by date.
            my $query = $self->Get(['IsTargetOfAnnotation', 'Annotation', 'MadeAnnotation'],
                                   "IsTargetOfAnnotation(from-link) = ? ORDER BY Annotation(time) DESC",
                                   [$fid]);
            my $timeSelected = 0;
            # Loop until we run out of annotations.
            while (my $annotation = $query->Fetch()) {
                # Get the annotation text.
                my ($text, $time, $user) = $annotation->Values(['Annotation(annotation)',
                                                         'Annotation(time)', 'MadeAnnotation(from-link)']);
                # Check to see if this is a functional assignment for a trusted user.
                my ($actualUser, $function) = _ParseAssignment($user, $text);
                Trace("Assignment user is $actualUser, text is $function.") if T(4);
                if ($actualUser) {
                    # Here it is a functional assignment. Check the time and the user
                    # name. The time must be recent and the user must be trusted.
                    if ((exists $trusteeTable{$actualUser}) && ($time > $timeSelected)) {
                        $retVal = $function;
                        $timeSelected = $time;
                    }
                }
            }
        }
    }
    # Return the assignment found.
    return $retVal;
}

=head3 FunctionsOf

    my @functionList = $sprout->FunctionOf($featureID, $userID);

Return the functional assignments of a particular feature.

The functional assignment is handled differently depending on the type of feature. If
the feature is identified by a FIG ID (begins with the string C<fig|>), then a functional
assignment is a type of annotation. The format of an assignment is described in
L</ParseAssignment>. Its worth noting that we cannot filter on the content of the
annotation itself because it's a text field; however, this is not a big problem because
most features only have a small number of annotations.

=over 4

=item featureID

ID of the feature whose functional assignments are desired.

=item RETURN

Returns a list of 2-tuples, each consisting of a user ID and the text of an assignment by
that user.

=back

=cut
#: Return Type @@;
sub FunctionsOf {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Declare the return value.
    my @retVal = ();
    # Convert to a FIG ID.
    my ($fid) = $self->FeaturesByAlias($featureID);
    # Only proceed if we found one.
    if ($fid) {
        # Here we have a FIG feature ID. We must build the list of trusted
        # users.
        my %trusteeTable = ();
        # Build a query for all of the feature's annotations, sorted by date.
        my $query = $self->Get(['IsTargetOfAnnotation', 'Annotation', 'MadeAnnotation'],
                               "IsTargetOfAnnotation(from-link) = ? ORDER BY Annotation(time) DESC",
                               [$fid]);
        my $timeSelected = 0;
        # Loop until we run out of annotations.
        while (my $annotation = $query->Fetch()) {
            # Get the annotation text.
            my ($text, $time, $user) = $annotation->Values(['Annotation(annotation)',
                                                            'Annotation(time)',
                                                            'MadeAnnotation(user)']);
            # Check to see if this is a functional assignment for a trusted user.
            my ($actualUser, $function) = _ParseAssignment($user, $text);
            if ($actualUser) {
                # Here it is a functional assignment.
                push @retVal, [$actualUser, $function];
            }
        }
    }
    # Return the assignments found.
    return @retVal;
}

=head3 BBHList

    my $bbhHash = $sprout->BBHList($genomeID, \@featureList);

Return a hash mapping the features in a specified list to their bidirectional best hits
on a specified target genome.

=over 4

=item genomeID

ID of the genome from which the best hits should be taken.

=item featureList

List of the features whose best hits are desired.

=item RETURN

Returns a reference to a hash that maps the IDs of the incoming features to the best hits
on the target genome.

=back

=cut
#: Return Type %;
sub BBHList {
    # Get the parameters.
    my ($self, $genomeID, $featureList) = @_;
    # Create the return structure.
    my %retVal = ();
    # Loop through the incoming features.
    for my $featureID (@{$featureList}) {
        # Ask the server for the feature's best hit.
        my $bbhData = FIGRules::BBHData($featureID);
        # Peel off the BBHs found.
        my @found = ();
        for my $bbh (@$bbhData) {
            my $fid = $bbh->[0];
            my $bbGenome = $self->GenomeOf($fid);
            if ($bbGenome eq $genomeID) {
                push @found, $fid;
            }
        }
        $retVal{$featureID} = \@found;
    }
    # Return the mapping.
    return \%retVal;
}

=head3 SimList

    my %similarities = $sprout->SimList($featureID, $count);

Return a list of the similarities to the specified feature.

This method just returns the bidirectional best hits for performance reasons.

=over 4

=item featureID

ID of the feature whose similarities are desired.

=item count

Maximum number of similar features to be returned, or C<0> to return them all.

=back

=cut
#: Return Type %;
sub SimList {
    # Get the parameters.
    my ($self, $featureID, $count) = @_;
    # Ask for the best hits.
    my $lists = FIGRules::BBHData($featureID);
    # Create the return value.
    my %retVal = ();
    for my $tuple (@$lists) {
        $retVal{$tuple->[0]} = $tuple->[1];
    }
    # Return the result.
    return %retVal;
}

=head3 IsComplete

    my $flag = $sprout->IsComplete($genomeID);

Return TRUE if the specified genome is complete, else FALSE.

=over 4

=item genomeID

ID of the genome whose completeness status is desired.

=item RETURN

Returns TRUE if the genome is complete, FALSE if it is incomplete, and C<undef> if it is
not found.

=back

=cut
#: Return Type $;
sub IsComplete {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the genome's data.
    my $genomeData = $self->_GenomeData($genomeID);
    # Only proceed if it exists.
    if (defined $genomeData) {
        # The genome exists, so get the completeness flag.
        $retVal = $genomeData->PrimaryValue('Genome(complete)');
    }
    # Return the result.
    return $retVal;
}

=head3 FeatureAliases

    my @aliasList = $sprout->FeatureAliases($featureID);

Return a list of the aliases for a specified feature.

=over 4

=item featureID

ID of the feature whose aliases are desired.

=item RETURN

Returns a list of the feature's aliases. If the feature is not found or has no aliases, it will
return an empty list.

=back

=cut
#: Return Type @;
sub FeatureAliases {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the desired feature's aliases
    my @retVal = $self->GetFlat(['IsAliasOf'], "IsAliasOf(to-link) = ?", [$featureID], 'IsAliasOf(from-link)');
    # Return the result.
    return @retVal;
}

=head3 GenomeOf

    my $genomeID = $sprout->GenomeOf($featureID);

Return the genome that contains a specified feature or contig.

=over 4

=item featureID

ID of the feature or contig whose genome is desired.

=item RETURN

Returns the ID of the genome for the specified feature or contig. If the feature or contig is not
found, returns an undefined value.

=back

=cut
#: Return Type $;
sub GenomeOf {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Declare the return value.
    my $retVal;
    # Parse the genome ID from the feature ID.
    if ($featureID =~ /^fig\|(\d+\.\d+)/) {
        $retVal = $1;
    } else {
        # Find the feature by alias.
        my ($realFeatureID) = $self->FeaturesByAlias($featureID);
        if ($realFeatureID && $realFeatureID =~ /^fig\|(\d+\.\d+)/) {
            $retVal = $1;
        }
    }
    # Return the value found.
    return $retVal;
}

=head3 CoupledFeatures

    my %coupleHash = $sprout->CoupledFeatures($featureID);

Return the features functionally coupled with a specified feature. Features are considered
functionally coupled if they tend to be clustered on the same chromosome.

=over 4

=item featureID

ID of the feature whose functionally-coupled brethren are desired.

=item RETURN

A hash mapping the functionally-coupled feature IDs to the coupling score.

=back

=cut
#: Return Type %;
sub CoupledFeatures {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Ask the coupling server for the data.
    Trace("Looking for features coupled to $featureID.") if T(coupling => 3);
    my @rawPairs = FIGRules::NetCouplingData('coupled_to', id1 => $featureID);
    Trace(scalar(@rawPairs) . " couplings returned.") if T(coupling => 3);
    # Form them into a hash.
    my %retVal = ();
    for my $pair (@rawPairs) {
        # Get the feature ID and score.
        my ($featureID2, $score) = @{$pair};
        # Only proceed if the feature is in NMPDR.
        if ($self->_CheckFeature($featureID2)) {
            $retVal{$featureID2} = $score;
        }
    }
    # Return the hash.
    return %retVal;
}

=head3 CouplingEvidence

    my @evidence = $sprout->CouplingEvidence($peg1, $peg2);

Return the evidence for a functional coupling.

A pair of features is considered evidence of a coupling between two other
features if they occur close together on a contig and both are similar to
the coupled features. So, if B<A1> and B<A2> are close together on a contig,
B<B1> and B<B2> are considered evidence for the coupling if (1) B<B1> and
B<B2> are close together, (2) B<B1> is similar to B<A1>, and (3) B<B2> is
similar to B<A2>.

The score of a coupling is determined by the number of pieces of evidence
that are considered I<representative>. If several evidence items belong to
a group of genomes that are close to each other, only one of those items
is considered representative. The other evidence items are presumed to be
there because of the relationship between the genomes rather than because
the two proteins generated by the features have a related functionality.

Each evidence item is returned as a three-tuple in the form C<[>I<$peg1a>C<,>
I<$peg2a>C<,> I<$rep>C<]>, where I<$peg1a> is similar to I<$peg1>, I<$peg2a>
is similar to I<$peg2>, and I<$rep> is TRUE if the evidence is representative
and FALSE otherwise.

=over 4

=item peg1

ID of the feature of interest.

=item peg2

ID of a feature functionally coupled to the feature of interest.

=item RETURN

Returns a list of 3-tuples. Each tuple consists of a feature similar to the feature
of interest, a feature similar to the functionally coupled feature, and a flag
that is TRUE for a representative piece of evidence and FALSE otherwise.

=back

=cut
#: Return Type @@;
sub CouplingEvidence {
    # Get the parameters.
    my ($self, $peg1, $peg2) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Get the coupling and evidence data.
    my @rawData = FIGRules::NetCouplingData('coupling_evidence', id1 => $peg1, id2 => $peg2);
    # Loop through the raw data, saving the ones that are in NMPDR genomes.
    for my $rawTuple (@rawData) {
        if ($self->_CheckFeature($rawTuple->[0]) && $self->_CheckFeature($rawTuple->[1])) {
            push @retVal, $rawTuple;
        }
    }
    # Return the result.
    return @retVal;
}

=head3 GetSynonymGroup

    my $id = $sprout->GetSynonymGroup($fid);

Return the synonym group name for the specified feature.

=over 4

=item fid

ID of the feature whose synonym group is desired.

=item RETURN

The name of the synonym group to which the feature belongs. If the feature does
not belong to a synonym group, the feature ID itself is returned.

=back

=cut

sub GetSynonymGroup {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Declare the return variable.
    my $retVal;
    # Find the synonym group.
    my @groups = $self->GetFlat(['IsSynonymGroupFor'], "IsSynonymGroupFor(to-link) = ?",
                                   [$fid], 'IsSynonymGroupFor(from-link)');
    # Check to see if we found anything.
    if (@groups) {
        $retVal = $groups[0];
    } else {
        $retVal = $fid;
    }
    # Return the result.
    return $retVal;
}

=head3 GetBoundaries

    my ($contig, $beg, $end) = $sprout->GetBoundaries(@locList);

Determine the begin and end boundaries for the locations in a list. All of the
locations must belong to the same contig and have mostly the same direction in
order for this method to produce a meaningful result. The resulting
begin/end pair will contain all of the bases in any of the locations.

=over 4

=item locList

List of locations to process.

=item RETURN

Returns a 3-tuple consisting of the contig ID, the beginning boundary,
and the ending boundary. The beginning boundary will be left of the
end for mostly-forward locations and right of the end for mostly-backward
locations.

=back

=cut

sub GetBoundaries {
    # Get the parameters.
    my ($self, @locList) = @_;
    # Set up the counters used to determine the most popular direction.
    my %counts = ( '+' => 0, '-' => 0 );
    # Get the last location and parse it.
    my $locObject = BasicLocation->new(pop @locList);
    # Prime the loop with its data.
    my ($contig, $beg, $end) = ($locObject->Contig, $locObject->Left, $locObject->Right);
    # Count its direction.
    $counts{$locObject->Dir}++;
    # Loop through the remaining locations. Note that in most situations, this loop
    # will not iterate at all, because most of the time we will be dealing with a
    # singleton list.
    for my $loc (@locList) {
        # Create a location object.
        my $locObject = BasicLocation->new($loc);
        # Count the direction.
        $counts{$locObject->Dir}++;
        # Get the left end and the right end.
        my $left = $locObject->Left;
        my $right = $locObject->Right;
        # Merge them into the return variables.
        if ($left < $beg) {
            $beg = $left;
        }
        if ($right > $end) {
            $end = $right;
        }
    }
    # If the most common direction is reverse, flip the begin and end markers.
    if ($counts{'-'} > $counts{'+'}) {
        ($beg, $end) = ($end, $beg);
    }
    # Return the result.
    return ($contig, $beg, $end);
}

=head3 ReadFasta

    my %sequenceData = Sprout::ReadFasta($fileName, $prefix);

Read sequence data from a FASTA-format file. Each sequence in a FASTA file is represented by
one or more lines of data. The first line begins with a > character and contains an ID.
The remaining lines contain the sequence data in order.

=over 4

=item fileName

Name of the FASTA file.

=item prefix (optional)

Prefix to be put in front of each ID found.

=item RETURN

Returns a hash that maps each ID to its sequence.

=back

=cut
#: Return Type %;
sub ReadFasta {
    # Get the parameters.
    my ($fileName, $prefix) = @_;
    # Create the return hash.
    my %retVal = ();
    # Open the file for input.
    open FASTAFILE, '<', $fileName;
    # Declare the ID variable and clear the sequence accumulator.
    my $sequence = "";
    my $id = "";
    # Loop through the file.
    while (<FASTAFILE>) {
        # Get the current line.
        my $line = $_;
        # Check for a header line.
        if ($line =~ m/^>\s*(.+?)(\s|\n)/) {
            # Here we have a new header. Store the current sequence if we have one.
            if ($id) {
                $retVal{$id} = lc $sequence;
            }
            # Clear the sequence accumulator and save the new ID.
            ($id, $sequence) = ("$prefix$1", "");
        } else {
            # Here we have a data line, so we add it to the sequence accumulator.
            # First, we get the actual data out. Note that we normalize to lower
            # case.
            $line =~ /^\s*(.*?)(\s|\n)/;
            $sequence .= $1;
        }
    }
    # Flush out the last sequence (if any).
    if ($sequence) {
        $retVal{$id} = lc $sequence;
    }
    # Close the file.
    close FASTAFILE;
    # Return the hash constructed from the file.
    return %retVal;
}

=head3 FormatLocations

    my @locations = $sprout->FormatLocations($prefix, \@locations, $oldFormat);

Insure that a list of feature locations is in the Sprout format. The Sprout feature location
format is I<contig>_I<beg*len> where I<*> is C<+> for a forward gene and C<-> for a backward
gene. The old format is I<contig>_I<beg>_I<end>. If a feature is in the new format already,
it will not be changed; otherwise, it will be converted. This method can also be used to
perform the reverse task-- insuring that all the locations are in the old format.

=over 4

=item prefix

Prefix to be put in front of each contig ID (or an empty string if the contig ID should not
be changed.

=item locations

List of locations to be normalized.

=item oldFormat

TRUE to convert the locations to the old format, else FALSE

=item RETURN

Returns a list of updated location descriptors.

=back

=cut
#: Return Type @;
sub FormatLocations {
    # Get the parameters.
    my ($self, $prefix, $locations, $oldFormat) = @_;
    # Create the return list.
    my @retVal = ();
    # Check to see if any locations were passed in.
    if ($locations eq '') {
        Confess("No locations specified.");
    } else {
        # Loop through the locations, converting them to the new format.
        for my $location (@{$locations}) {
            # Parse the location elements.
            my ($contig, $beg, $dir, $len) = ParseLocation($location);
            # Process according to the desired output format.
            if (!$oldFormat) {
                # Here we're producing the new format. Add the location to the return list.
                push @retVal, "$prefix${contig}_$beg$dir$len";
            } elsif ($dir eq '+') {
                # Here we're producing the old format and it's a forward gene.
                my $end = $beg + $len - 1;
                push @retVal, "$prefix${contig}_${beg}_$end";
            } else {
                # Here we're producting the old format and it's a backward gene.
                my $end = $beg - $len + 1;
                push @retVal, "$prefix${contig}_${beg}_$end";
            }
        }
    }
    # Return the normalized list.
    return @retVal;
}

=head3 DumpData

    $sprout->DumpData();

Dump all the tables to tab-delimited DTX files. The files will be stored in the data directory.

=cut

sub DumpData {
    # Get the parameters.
    my ($self) = @_;
    # Get the data directory name.
    my $outputDirectory = $self->{_options}->{dataDir};
    # Dump the relations.
    $self->DumpRelations($outputDirectory);
}

=head3 XMLFileName

    my $fileName = $sprout->XMLFileName();

Return the name of this database's XML definition file.

=cut
#: Return Type $;
sub XMLFileName {
    my ($self) = @_;
    return $self->{_xmlName};
}

=head3 GetGenomeNameData

    my ($genus, $species, $strain) = $sprout->GenomeNameData($genomeID);

Return the genus, species, and unique characterization for a genome. This
is similar to L</GenusSpecies>, with the exception that it returns the
values in three seperate fields.

=over 4

=item genomeID

ID of the genome whose name data is desired.

=item RETURN

Returns a three-element list, consisting of the genus, species, and strain
of the specified genome. If the genome is not found, an error occurs.

=back

=cut

sub GetGenomeNameData {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return variables.
    my ($genus, $species, $strain);
    # Get the genome's data.
    my $genomeData = $self->_GenomeData($genomeID);
    # Only proceed if the genome exists.
    if (defined $genomeData) {
        # Get the desired values.
        ($genus, $species, $strain) = $genomeData->Values(['Genome(genus)',
                                                           'Genome(species)',
                                                           'Genome(unique-characterization)']);
    } else {
        # Throw an error because they were not found.
        Confess("Genome $genomeID not found in database.");
    }
    # Return the results.
    return ($genus, $species, $strain);
}

=head3 GetGenomeByNameData

    my @genomes = $sprout->GetGenomeByNameData($genus, $species, $strain);

Return a list of the IDs of the genomes with the specified genus,
species, and strain. In almost every case, there will be either zero or
one IDs returned; however, two or more IDs could be returned if there are
multiple versions of the genome in the database.

=over 4

=item genus

Genus of the desired genome.

=item species

Species of the desired genome.

=item strain

Strain (unique characterization) of the desired genome. This may be an empty
string, in which case it is presumed that the desired genome has no strain
specified.

=item RETURN

Returns a list of the IDs of the genomes having the specified genus, species, and
strain.

=back

=cut

sub GetGenomeByNameData {
    # Get the parameters.
    my ($self, $genus, $species, $strain) = @_;
    # Try to find the genomes.
    my @retVal = $self->GetFlat(['Genome'], "Genome(genus) = ? AND Genome(species) = ? AND Genome(unique-characterization) = ?",
                                [$genus, $species, $strain], 'Genome(id)');
    # Return the result.
    return @retVal;
}

=head3 Insert

    $sprout->Insert($objectType, \%fieldHash);

Insert an entity or relationship instance into the database. The entity or relationship of interest
is defined by a type name and then a hash of field names to values. Field values in the primary
relation are represented by scalars. (Note that for relationships, the primary relation is
the B<only> relation.) Field values for the other relations comprising the entity are always
list references. For example, the following line inserts an inactive PEG feature named
C<fig|188.1.peg.1> with aliases C<ZP_00210270.1> and C<gi|46206278>.

    $sprout->Insert('Feature', { id => 'fig|188.1.peg.1', active => 0, feature-type => 'peg', alias => ['ZP_00210270.1', 'gi|46206278']});

The next statement inserts a C<HasProperty> relationship between feature C<fig|158879.1.peg.1> and
property C<4> with an evidence URL of C<http://seedu.uchicago.edu/query.cgi?article_id=142>.

    $sprout->InsertObject('HasProperty', { 'from-link' => 'fig|158879.1.peg.1', 'to-link' => 4, evidence => 'http://seedu.uchicago.edu/query.cgi?article_id=142'});

=over 4

=item newObjectType

Type name of the entity or relationship to insert.

=item fieldHash

Hash of field names to values.

=back

=cut
#: Return Type ;
sub Insert {
    # Get the parameters.
    my ($self, $objectType, $fieldHash) = @_;
    # Call the underlying method.
    $self->InsertObject($objectType, $fieldHash);
}

=head3 Annotate

    my $ok = $sprout->Annotate($fid, $timestamp, $user, $text);

Annotate a feature. This inserts an Annotation record into the database and links it to the
specified feature and user.

=over 4

=item fid

ID of the feature to be annotated.

=item timestamp

Numeric timestamp to apply to the annotation. This is concatenated to the feature ID to create the
key.

=item user

ID of the user who is making the annotation.

=item text

Text of the annotation.

=item RETURN

Returns 1 if successful, 2 if an error occurred.

=back

=cut
#: Return Type $;
sub Annotate {
    # Get the parameters.
    my ($self, $fid, $timestamp, $user, $text) = @_;
    # Create the annotation ID.
    my $aid = "$fid:$timestamp";
    # Insert the Annotation object.
    my $retVal = $self->Insert('Annotation', { id => $aid, time => $timestamp, annotation => $text });
    if ($retVal) {
        # Connect it to the user.
        $retVal = $self->Insert('MadeAnnotation', { 'from-link' => $user, 'to-link' => $aid });
        if ($retVal) {
            # Connect it to the feature.
            $retVal = $self->Insert('IsTargetOfAnnotation', { 'from-link' => $fid,
                                                             'to-link' => $aid });
        }
    }
    # Return the success indicator.
    return $retVal;
}

=head3 AssignFunction

    my $ok = $sprout->AssignFunction($featureID, $user, $function, $assigningUser);

This method assigns a function to a feature. Functions are a special type of annotation. The general
format is described in L</ParseAssignment>.

=over 4

=item featureID

ID of the feature to which the assignment is being made.

=item user

Name of the user group making the assignment, such as C<kegg> or C<fig>.

=item function

Text of the function being assigned.

=item assigningUser (optional)

Name of the individual user making the assignment. If omitted, defaults to the user group.

=item RETURN

Returns 1 if successful, 0 if an error occurred.

=back

=cut
#: Return Type $;
sub AssignFunction {
    # Get the parameters.
    my ($self, $featureID, $user, $function, $assigningUser) = @_;
    # Default the assigning user.
    if (! $assigningUser) {
        $assigningUser = $user;
    }
    # Create an annotation string from the parameters.
    my $annotationText = "$assigningUser\nset $user function to\n$function";
    # Get the current time.
    my $now = time;
    # Declare the return variable.
    my $retVal = 1;
    # Locate the genome containing the feature.
    my $genome = $self->GenomeOf($featureID);
    if (!$genome) {
        # Here the genome was not found. This probably means the feature ID is invalid.
        Trace("No genome found for feature $featureID.") if T(0);
        $retVal = 0;
    } else {
        # Here we know we have a feature with a genome. Store the annotation.
        $retVal = $self->Annotate($featureID, $now, $user, $annotationText);
    }
    # Return the success indicator.
    return $retVal;
}

=head3 FeaturesByAlias

    my @features = $sprout->FeaturesByAlias($alias);

Returns a list of features with the specified alias. The alias is parsed to determine
the type of the alias. A string of digits is a GenBack ID and a string of exactly 6
alphanumerics is a UniProt ID. A built-in FIG.pm method is used to analyze the alias
string and attach the necessary prefix. If the result is a FIG ID then it is returned
unmodified; otherwise, we look for an alias.

=over 4

=item alias

Alias whose features are desired.

=item RETURN

Returns a list of the features with the given alias.

=back

=cut
#: Return Type @;
sub FeaturesByAlias {
    # Get the parameters.
    my ($self, $alias) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Parse the alias.
    my ($mappedAlias, $flag) = FIGRules::NormalizeAlias($alias);
    # If it's a FIG alias, we're done.
    if ($flag) {
        push @retVal, $mappedAlias;
    } else {
        # Here we have a non-FIG alias. Get the features with the normalized alias.
        @retVal = $self->GetFlat(['IsAliasOf'], 'IsAliasOf(from-link) = ?', [$mappedAlias], 'IsAliasOf(to-link)');
    }
    # Return the result.
    return @retVal;
}

=head3 FeatureTranslation

    my $translation = $sprout->FeatureTranslation($featureID);

Return the translation of a feature.

=over 4

=item featureID

ID of the feature whose translation is desired

=item RETURN

Returns the translation of the specified feature.

=back

=cut
#: Return Type $;
sub FeatureTranslation {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the specified feature's translation.
    my ($retVal) = $self->GetEntityValues("Feature", $featureID, ['Feature(translation)']);
    return $retVal;
}

=head3 Taxonomy

    my @taxonomyList = $sprout->Taxonomy($genome);

Return the taxonomy of the specified genome. This will be in the form of a list
containing the various classifications in order from domain (eg. C<Bacteria>, C<Archaea>,
or C<Eukaryote>) to sub-species. For example,

    (Bacteria, Proteobacteria, Gammaproteobacteria, Enterobacteriales, Enterobacteriaceae, Escherichia, Escherichia coli, Escherichia coli K12)

=over 4

=item genome

ID of the genome whose taxonomy is desired.

=item RETURN

Returns a list containing all the taxonomy classifications for the specified genome's organism.

=back

=cut
#: Return Type @;
sub Taxonomy {
    # Get the parameters.
    my ($self, $genome) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Get the genome data.
    my $genomeData = $self->_GenomeData($genome);
    # Only proceed if it exists.
    if (defined $genomeData) {
        # Create the taxonomy from the taxonomy string.
        @retVal = split /\s*;\s*/, $genomeData->PrimaryValue('Genome(taxonomy)');
    } else {
        # Genome doesn't exist, so emit a warning.
        Trace("Genome \"$genome\" does not have a taxonomy in the database.\n") if T(0);
    }
    # Return the value found.
    return @retVal;
}

=head3 CrudeDistance

    my $distance = $sprout->CrudeDistance($genome1, $genome2);

Returns a crude estimate of the distance between two genomes. The distance is construed so
that it will be 0 for genomes with identical taxonomies and 1 for genomes from different domains.

=over 4

=item genome1

ID of the first genome to compare.

=item genome2

ID of the second genome to compare.

=item RETURN

Returns a value from 0 to 1, with 0 meaning identical organisms, and 1 meaning organisms from
different domains.

=back

=cut
#: Return Type $;
sub CrudeDistance {
    # Get the parameters.
    my ($self, $genome1, $genome2) = @_;
    # Insure that the distance is commutative by sorting the genome IDs.
    my ($genomeA, $genomeB);
    if ($genome2 < $genome2) {
        ($genomeA, $genomeB) = ($genome1, $genome2);
    } else {
        ($genomeA, $genomeB) = ($genome2, $genome1);
    }
    my @taxA = $self->Taxonomy($genomeA);
    my @taxB = $self->Taxonomy($genomeB);
    # Compute the distance.
    my $retVal = FIGRules::CrudeDistanceFormula(\@taxA, \@taxB);
    return $retVal;
}

=head3 RoleName

    my $roleName = $sprout->RoleName($roleID);

Return the descriptive name of the role with the specified ID. In general, a role
will only have a descriptive name if it is coded as an EC number.

=over 4

=item roleID

ID of the role whose description is desired.

=item RETURN

Returns the descriptive name of the desired role.

=back

=cut
#: Return Type $;
sub RoleName {
    # Get the parameters.
    my ($self, $roleID) = @_;
    # Get the specified role's name.
    my ($retVal) = $self->GetEntityValues('Role', $roleID, ['Role(name)']);
    # Use the ID if the role has no name.
    if (!$retVal) {
        $retVal = $roleID;
    }
    # Return the name.
    return $retVal;
}

=head3 RoleDiagrams

    my @diagrams = $sprout->RoleDiagrams($roleID);

Return a list of the diagrams containing a specified functional role.

=over 4

=item roleID

ID of the role whose diagrams are desired.

=item RETURN

Returns a list of the IDs for the diagrams that contain the specified functional role.

=back

=cut
#: Return Type @;
sub RoleDiagrams {
    # Get the parameters.
    my ($self, $roleID) = @_;
    # Query for the diagrams.
    my @retVal = $self->GetFlat(['RoleOccursIn'], "RoleOccursIn(from-link) = ?", [$roleID],
                                'RoleOccursIn(to-link)');
    # Return the result.
    return @retVal;
}

=head3 FeatureProperties

    my @properties = $sprout->FeatureProperties($featureID);

Return a list of the properties for the specified feature. Properties are key-value pairs
that specify special characteristics of the feature. For example, a property could indicate
that a feature is essential to the survival of the organism or that it has benign influence
on the activities of a pathogen. Each property is returned as a triple of the form
C<($key,@values)>, where C<$key> is the property name and  C<@values> are its values.

=over 4

=item featureID

ID of the feature whose properties are desired.

=item RETURN

Returns a list of tuples, each tuple containing the property name and its values.

=back

=cut
#: Return Type @@;
sub FeatureProperties {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the properties.
    my @attributes = $self->ca->GetAttributes($featureID);
    # Strip the feature ID off each tuple.
    my @retVal = ();
    for my $attributeRow (@attributes) {
        shift @{$attributeRow};
        push @retVal, $attributeRow;
    }
    # Return the resulting list.
    return @retVal;
}

=head3 DiagramName

    my $diagramName = $sprout->DiagramName($diagramID);

Return the descriptive name of a diagram.

=over 4

=item diagramID

ID of the diagram whose description is desired.

=item RETURN

Returns the descripive name of the specified diagram.

=back

=cut
#: Return Type $;
sub DiagramName {
    # Get the parameters.
    my ($self, $diagramID) = @_;
    # Get the specified diagram's name and return it.
    my ($retVal) = $self->GetEntityValues('Diagram', $diagramID, ['Diagram(name)']);
    return $retVal;
}

=head3 PropertyID

    my $id = $sprout->PropertyID($propName, $propValue);

Return the ID of the specified property name and value pair, if the
pair exists. Only a small subset of the FIG attributes are stored as
Sprout properties, mostly for use in search optimization.

=over 4

=item propName

Name of the desired property.

=item propValue

Value expected for the desired property.

=item RETURN

Returns the ID of the name/value pair, or C<undef> if the pair does not exist.

=back

=cut

sub PropertyID {
    # Get the parameters.
    my ($self, $propName, $propValue) = @_;
    # Try to find the ID.
    my ($retVal) = $self->GetFlat(['Property'],
                                  "Property(property-name) = ? AND Property(property-value) = ?",
                                  [$propName, $propValue], 'Property(id)');
    # Return the result.
    return $retVal;
}

=head3 MergedAnnotations

    my @annotationList = $sprout->MergedAnnotations(\@list);

Returns a merged list of the annotations for the features in a list. Each annotation is
represented by a 4-tuple of the form C<($fid, $timestamp, $userID, $annotation)>, where
C<$fid> is the ID of a feature, C<$timestamp> is the time at which the annotation was made,
C<$userID> is the ID of the user who made the annotation, and C<$annotation> is the annotation
text. The list is sorted by timestamp.

=over 4

=item list

List of the IDs for the features whose annotations are desired.

=item RETURN

Returns a list of annotation descriptions sorted by the annotation time.

=back

=cut
#: Return Type @;
sub MergedAnnotations {
    # Get the parameters.
    my ($self, $list) = @_;
    # Create a list to hold the annotation tuples found.
    my @tuples = ();
    # Loop through the features in the input list.
    for my $fid (@{$list}) {
        # Create a list of this feature's annotation tuples.
        my @newTuples = $self->GetAll(['IsTargetOfAnnotation', 'Annotation', 'MadeAnnotation'],
                               "IsTargetOfAnnotation(from-link) = ?", [$fid],
                               ['IsTargetOfAnnotation(from-link)', 'Annotation(time)',
                                'MadeAnnotation(from-link)', 'Annotation(annotation)']);
        # Put it in the result list.
        push @tuples, @newTuples;
    }
    # Sort the result list by timestamp.
    my @retVal = sort { $a->[1] <=> $b->[1] } @tuples;
    # Loop through and make the time stamps friendly.
    for my $tuple (@retVal) {
        $tuple->[1] = FriendlyTimestamp($tuple->[1]);
    }
    # Return the sorted list.
    return @retVal;
}

=head3 RoleNeighbors

    my @roleList = $sprout->RoleNeighbors($roleID);

Returns a list of the roles that occur in the same diagram as the specified role. Because
diagrams and roles are in a many-to-many relationship with each other, the list is
essentially the set of roles from all of the maps that contain the incoming role. Such
roles are considered neighbors because they are used together in cellular subsystems.

=over 4

=item roleID

ID of the role whose neighbors are desired.

=item RETURN

Returns a list containing the IDs of the roles that are related to the incoming role.

=back

=cut
#: Return Type @;
sub RoleNeighbors {
    # Get the parameters.
    my ($self, $roleID) = @_;
    # Get all the diagrams containing this role.
    my @diagrams = $self->GetFlat(['RoleOccursIn'], "RoleOccursIn(from-link) = ?", [$roleID],
                                  'RoleOccursIn(to-link)');
    # Create the return list.
    my @retVal = ();
    # Loop through the diagrams.
    for my $diagramID (@diagrams) {
        # Get all the roles in this diagram.
        my @roles = $self->GetFlat(['RoleOccursIn'], "RoleOccursIn(to-link) = ?", [$diagramID],
                                   'RoleOccursIn(from-link)');
        # Add them to the return list.
        push @retVal, @roles;
    }
    # Merge the duplicates from the list.
    return Tracer::Merge(@retVal);
}

=head3 FeatureLinks

    my @links = $sprout->FeatureLinks($featureID);

Return a list of the web hyperlinks associated with a feature. The web hyperlinks are
to external websites describing either the feature itself or the organism containing it
and are represented in raw HTML.

=over 4

=item featureID

ID of the feature whose links are desired.

=item RETURN

Returns a list of the web links for this feature.

=back

=cut
#: Return Type @;
sub FeatureLinks {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the feature's links.
    my @retVal = $self->GetEntityValues('Feature', $featureID, ['Feature(link)']);
    # Return the feature's links.
    return @retVal;
}

=head3 SubsystemsOf

    my %subsystems = $sprout->SubsystemsOf($featureID);

Return a hash describing all the subsystems in which a feature participates. Each subsystem is mapped
to the roles the feature performs.

=over 4

=item featureID

ID of the feature whose subsystems are desired.

=item RETURN

Returns a hash mapping all the feature's subsystems to a list of the feature's roles.

=back

=cut
#: Return Type %@;
sub SubsystemsOf {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the subsystem list.
    my @subsystems = $self->GetAll(['ContainsFeature', 'HasSSCell', 'IsRoleOf'],
                                    "ContainsFeature(to-link) = ?", [$featureID],
                                    ['HasSSCell(from-link)', 'IsRoleOf(from-link)']);
    # Create the return value.
    my %retVal = ();
    # Build a hash to weed out duplicates. Sometimes the same PEG and role appears
    # in two spreadsheet cells.
    my %dupHash = ();
    # Loop through the results, adding them to the hash.
    for my $record (@subsystems) {
        # Get this subsystem and role.
        my ($subsys, $role) = @{$record};
        # Insure it's the first time for both.
        my $dupKey = "$subsys\n$role";
        if (! exists $dupHash{"$subsys\n$role"}) {
            $dupHash{$dupKey} = 1;
            push @{$retVal{$subsys}}, $role;
        }
    }
    # Return the hash.
    return %retVal;
}

=head3 SubsystemList

    my @subsystems = $sprout->SubsystemList($featureID);

Return a list containing the names of the subsystems in which the specified
feature participates. Unlike L</SubsystemsOf>, this method only returns the
subsystem names, not the roles.

=over 4

=item featureID

ID of the feature whose subsystem names are desired.

=item RETURN

Returns a list of the names of the subsystems in which the feature participates.

=back

=cut
#: Return Type @;
sub SubsystemList {
    # Get the parameters.
    my ($self, $featureID) = @_;
    # Get the list of names. We do a join to the Subsystem table because we have missing subsystems in
    # the Sprout database!
    my @retVal = $self->GetFlat(['HasRoleInSubsystem', 'Subsystem'], "HasRoleInSubsystem(from-link) = ?",
                                [$featureID], 'HasRoleInSubsystem(to-link)');
    # Return the result, sorted.
    return sort @retVal;
}

=head3 GenomeSubsystemData

    my %featureData = $sprout->GenomeSubsystemData($genomeID);

Return a hash mapping genome features to their subsystem roles.

=over 4

=item genomeID

ID of the genome whose subsystem feature map is desired.

=item RETURN

Returns a hash mapping each feature of the genome to a list of 2-tuples. Eacb
2-tuple contains a subsystem name followed by a role ID.

=back

=cut

sub GenomeSubsystemData {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return variable.
    my %retVal = ();
    # Get a list of the genome features that participate in subsystems. For each
    # feature we get its subsystem ID and the corresponding roles.
    my @roleData = $self->GetAll(['HasFeature', 'ContainsFeature', 'IsRoleOf', 'HasSSCell'],
                                 "HasFeature(from-link) = ?", [$genomeID],
                                 ['HasFeature(to-link)', 'IsRoleOf(from-link)',  'HasSSCell(from-link)']);
    # Now we get a list of valid subsystems. These are the subsystems connected to the genome with
    # a non-negative variant code.
    my %subs = map { $_ => 1 } $self->GetFlat(['ParticipatesIn'],
                                                "ParticipatesIn(from-link) = ? AND ParticipatesIn(variant-code) >= 0",
                                                [$genomeID], 'ParticipatesIn(to-link)');
    # We loop through @roleData to build the hash.
    for my $roleEntry (@roleData) {
        # Get the data for this feature and cell.
        my ($fid, $role, $subsys) = @{$roleEntry};
        Trace("Subsystem for $fid is $subsys.") if T(4);
        # Check the subsystem;
        if ($subs{$subsys}) {
            Trace("Subsystem found.") if T(4);
            # Insure this feature has an entry in the return hash.
            if (! exists $retVal{$fid}) { $retVal{$fid} = []; }
            # Merge in this new data.
            push @{$retVal{$fid}}, [$subsys, $role];
        }
    }
    # Return the result.
    return %retVal;
}

=head3 RelatedFeatures

    my @relatedList = $sprout->RelatedFeatures($featureID, $function, $userID);

Return a list of the features which are bi-directional best hits of the specified feature and
have been assigned the specified function by the specified user. If no such features exists,
an empty list will be returned.

=over 4

=item featureID

ID of the feature to whom the desired features are related.

=item function

Functional assignment (as returned by C</FunctionOf>) that is used to determine which related
features should be selected.

=item userID

ID of the user whose functional assignments are to be used. If omitted, C<FIG> is assumed.

=item RETURN

Returns a list of the related features with the specified function.

=back

=cut
#: Return Type @;
sub RelatedFeatures {
    # Get the parameters.
    my ($self, $featureID, $function, $userID) = @_;
    # Get a list of the features that are BBHs of the incoming feature.
    my $bbhData = FIGRules::BBHData($featureID);
    my @bbhFeatures = map { $_->[0] } @$bbhData;
    # Now we loop through the features, pulling out the ones that have the correct
    # functional assignment.
    my @retVal = ();
    for my $bbhFeature (@bbhFeatures) {
        # Get this feature's functional assignment.
        my $newFunction = $self->FunctionOf($bbhFeature, $userID);
        # If it matches, add it to the result list.
        if ($newFunction eq $function) {
            push @retVal, $bbhFeature;
        }
    }
    # Return the result list.
    return @retVal;
}

=head3 TaxonomySort

    my @sortedFeatureIDs = $sprout->TaxonomySort(\@featureIDs);

Return a list formed by sorting the specified features by the taxonomy of the containing
genome. This will cause genomes from similar organisms to float close to each other.

This task could almost be handled by the database; however, the taxonomy string in the
database is a text field and can't be indexed. Instead, we create a hash table that maps
taxonomy strings to lists of features. We then process the hash table using a key sort
and merge the feature lists together to create the output.

=over 4

=item $featureIDs

List of features to be taxonomically sorted.

=item RETURN

Returns the list of features sorted by the taxonomies of the containing genomes.

=back

=cut
#: Return Type @;
sub TaxonomySort {
    # Get the parameters.
    my ($self, $featureIDs) = @_;
    # Create the working hash table.
    my %hashBuffer = ();
    # Loop through the features.
    for my $fid (@{$featureIDs}) {
        # Get the taxonomy of the feature's genome.
        my ($taxonomy) = $self->GetFlat(['IsLocatedIn', 'HasContig', 'Genome'], "IsLocatedIn(from-link) = ?",
                                        [$fid], 'Genome(taxonomy)');
        # Add this feature to the hash buffer.
        push @{$hashBuffer{$taxonomy}}, $fid;
    }
    # Sort the keys and get the elements.
    my @retVal = ();
    for my $taxon (sort keys %hashBuffer) {
        push @retVal, @{$hashBuffer{$taxon}};
    }
    # Return the result.
    return @retVal;
}

=head3 Protein

    my $protein = Sprout::Protein($sequence, $table);

Translate a DNA sequence into a protein sequence.

=over 4

=item sequence

DNA sequence to translate.

=item table (optional)

Reference to a Hash that translates DNA triples to proteins. A triple that does not
appear in the hash will be translated automatically to C<X>.

=item RETURN

Returns the protein sequence that would be created by the DNA sequence.

=back

=cut

# This is the translation table for protein synthesis.
my $ProteinTable = { AAA => 'K', AAG => 'K', AAT => 'N', AAC => 'N',
                     AGA => 'R', AGG => 'R', AGT => 'S', AGC => 'S',
                     ATA => 'I', ATG => 'M', ATT => 'I', ATC => 'I',
                     ACA => 'T', ACG => 'T', ACT => 'T', ACC => 'T',
                     GAA => 'E', GAG => 'E', GAT => 'D', GAC => 'D',
                     GTA => 'V', GTG => 'V', GTT => 'V', GTC => 'V',
                     GGA => 'G', GGG => 'G', GGT => 'G', GGC => 'G',
                     GCA => 'A', GCG => 'A', GCT => 'A', GCC => 'A',
                     CAA => 'Q', CAG => 'Q', CAT => 'H', CAC => 'H',
                     CTA => 'L', CTG => 'L', CTT => 'L', CTC => 'L',
                     CGA => 'R', CGG => 'R', CGT => 'R', CGC => 'R',
                     CCA => 'P', CCG => 'P', CCT => 'P', CCC => 'P',
                     TAA => '*', TAG => '*', TAT => 'Y', TAC => 'Y',
                     TGA => '*', TGG => 'W', TGT => 'C', TGC => 'C',
                     TTA => 'L', TTG => 'L', TTT => 'F', TTC => 'F',
                     TCA => 'S', TCG => 'S', TCT => 'S', TCC => 'S',
                     AAR => 'K', AAY => 'N',
                     AGR => 'R', AGY => 'S',
                     ATY => 'I',
                     ACR => 'T', ACY => 'T', 'ACX' => 'T',
                     GAR => 'E', GAY => 'D',
                     GTR => 'V', GTY => 'V', GTX => 'V',
                     GGR => 'G', GGY => 'G', GGX => 'G',
                     GCR => 'A', GCY => 'A', GCX => 'A',
                     CAR => 'Q', CAY => 'H',
                     CTR => 'L', CTY => 'L', CTX => 'L',
                     CGR => 'R', CGY => 'R', CGX => 'R',
                     CCR => 'P', CCY => 'P', CCX => 'P',
                     TAR => '*', TAY => 'Y',
                     TGY => 'C',
                     TTR => 'L', TTY => 'F',
                     TCR => 'S', TCY => 'S', TCX => 'S'
                   };

sub Protein {
    # Get the paraeters.
    my ($sequence, $table) = @_;
    # If no table was specified, use the default.
    if (!$table) {
        $table = $ProteinTable;
    }
    # Create the return value.
    my $retVal = "";
    # Loop through the input triples.
    my $n = length $sequence;
    for (my $i = 0; $i < $n; $i += 3) {
        # Get the current triple from the sequence. Note we convert to
        # upper case to insure a match.
        my $triple = uc substr($sequence, $i, 3);
        # Translate it using the table.
        my $protein = "X";
        if (exists $table->{$triple}) { $protein = $table->{$triple}; }
        $retVal .= $protein;
    }
    # Remove the stop codon (if any).
    $retVal =~ s/\*$//;
    # Return the result.
    return $retVal;
}

=head3 LoadInfo

    my ($dirName, @relNames) = $sprout->LoadInfo();

Return the name of the directory from which data is to be loaded and a list of the relation
names. This information is useful when trying to analyze what needs to be put where in order
to load the entire database.

=cut
#: Return Type @;
sub LoadInfo {
    # Get the parameters.
    my ($self) = @_;
    # Create the return list, priming it with the name of the data directory.
    my @retVal = ($self->{_options}->{dataDir});
    # Concatenate the table names.
    push @retVal, $self->GetTableNames();
    # Return the result.
    return @retVal;
}

=head3 BBHMatrix

    my $bbhMap = $sprout->BBHMatrix($genomeID, $cutoff, @targets);

Find all the bidirectional best hits for the features of a genome in a
specified list of target genomes. The return value will be a hash mapping
features in the original genome to their bidirectional best hits in the
target genomes.

=over 4

=item genomeID

ID of the genome whose features are to be examined for bidirectional best hits.

=item cutoff

A cutoff value. Only hits with a score lower than the cutoff will be returned.

=item targets

List of target genomes. Only pairs originating in the original
genome and landing in one of the target genomes will be returned.

=item RETURN

Returns a reference to a hash mapping each feature in the original genome
to a sub-hash mapping its BBH pegs in the target genomes to their scores.

=back

=cut

sub BBHMatrix {
    # Get the parameters.
    my ($self, $genomeID, $cutoff, @targets) = @_;
    # Declare the return variable.
    my %retVal = ();
    # Ask for the BBHs.
    my @bbhList = FIGRules::BatchBBHs("fig|$genomeID.%", $cutoff, @targets);
    Trace("Retrieved " . scalar(@bbhList) . " BBH results.") if T(3);
    # We now have a set of 4-tuples that we need to convert into a hash of hashes.
    for my $bbhData (@bbhList) {
        my ($peg1, $peg2, $score) = @{$bbhData};
        if (! exists $retVal{$peg1}) {
            $retVal{$peg1} = { $peg2 => $score };
        } else {
            $retVal{$peg1}->{$peg2} = $score;
        }
    }
    # Return the result.
    return \%retVal;
}


=head3 SimMatrix

    my %simMap = $sprout->SimMatrix($genomeID, $cutoff, @targets);

Find all the similarities for the features of a genome in a
specified list of target genomes. The return value will be a hash mapping
features in the original genome to their similarites in the
target genomes.

=over 4

=item genomeID

ID of the genome whose features are to be examined for similarities.

=item cutoff

A cutoff value. Only hits with a score lower than the cutoff will be returned.

=item targets

List of target genomes. Only pairs originating in the original
genome and landing in one of the target genomes will be returned.

=item RETURN

Returns a hash mapping each feature in the original genome to a hash mapping its
similar pegs in the target genomes to their scores.

=back

=cut

sub SimMatrix {
    # Get the parameters.
    my ($self, $genomeID, $cutoff, @targets) = @_;
    # Declare the return variable.
    my %retVal = ();
    # Get the list of features in the source organism.
    my @fids = $self->FeaturesOf($genomeID);
    # Ask for the sims. We only want similarities to fig features.
    my $simList = FIGRules::GetNetworkSims($self, \@fids, {}, 1000, $cutoff, "fig");
    if (! defined $simList) {
        Confess("Unable to retrieve similarities from server.");
    } else {
        Trace("Processing sims.") if T(3);
        # We now have a set of sims that we need to convert into a hash of hashes. First, we
        # Create a hash for the target genomes.
        my %targetHash = map { $_ => 1 } @targets;
        for my $simData (@{$simList}) {
            # Get the PEGs and the score.
            my ($peg1, $peg2, $score) = ($simData->id1, $simData->id2, $simData->psc);
            # Insure the second ID is in the target list.
            my ($genome2) = FIGRules::ParseFeatureID($peg2);
            if (exists $targetHash{$genome2}) {
                # Here it is. Now we need to add it to the return hash. How we do that depends
                # on whether or not $peg1 is new to us.
                if (! exists $retVal{$peg1}) {
                    $retVal{$peg1} = { $peg2 => $score };
                } else {
                    $retVal{$peg1}->{$peg2} = $score;
                }
            }
        }
    }
    # Return the result.
    return %retVal;
}


=head3 LowBBHs

    my %bbhMap = $sprout->LowBBHs($featureID, $cutoff);

Return the bidirectional best hits of a feature whose score is no greater than a
specified cutoff value. A higher cutoff value will allow inclusion of hits with
a greater score. The value returned is a map of feature IDs to scores.

=over 4

=item featureID

ID of the feature whose best hits are desired.

=item cutoff

Maximum permissible score for inclusion in the results.

=item RETURN

Returns a hash mapping feature IDs to scores.

=back

=cut
#: Return Type %;
sub LowBBHs {
    # Get the parsameters.
    my ($self, $featureID, $cutoff) = @_;
    # Create the return hash.
    my %retVal = ();
    # Query for the desired BBHs.
    my $bbhList = FIGRules::BBHData($featureID, $cutoff);
    # Form the results into the return hash.
    for my $pair (@$bbhList) {
        my $fid = $pair->[0];
        if ($self->Exists('Feature', $fid)) {
            $retVal{$fid} = $pair->[1];
        }
    }
    # Return the result.
    return %retVal;
}

=head3 Sims

    my $simList = $sprout->Sims($fid, $maxN, $maxP, $select, $max_expand, $filters);

Get a list of similarities for a specified feature. Similarity information is not kept in the
Sprout database; rather, they are retrieved from a network server. The similarities are
returned as B<Sim> objects. A Sim object is actually a list reference that has been blessed
so that its elements can be accessed by name.

Similarities can be either raw or expanded. The raw similarities are basic
hits between features with similar DNA. Expanding a raw similarity drags in any
features considered substantially identical. So, for example, if features B<A1>,
B<A2>, and B<A3> are all substantially identical to B<A>, then a raw similarity
B<[C,A]> would be expanded to B<[C,A] [C,A1] [C,A2] [C,A3]>.

=over 4

=item fid

ID of the feature whose similarities are desired, or reference to a list of IDs
of features whose similarities are desired.

=item maxN

Maximum number of similarities to return.

=item maxP

Minumum allowable similarity score.

=item select

Selection criterion: C<raw> means only raw similarities are returned; C<fig>
means only similarities to FIG features are returned; C<all> means all expanded
similarities are returned; and C<figx> means similarities are expanded until the
number of FIG features equals the maximum.

=item max_expand

The maximum number of features to expand.

=item filters

Reference to a hash containing filter information, or a subroutine that can be
used to filter the sims.

=item RETURN

Returns a reference to a list of similarity objects, or C<undef> if an error
occurred.

=back

=cut

sub Sims {
    # Get the parameters.
    my ($self, $fid, $maxN, $maxP, $select, $max_expand, $filters) = @_;
    # Create the shim object to test for deleted FIDs.
    my $shim = FidCheck->new($self);
    # Ask the network for sims.
    my $retVal = FIGRules::GetNetworkSims($shim, $fid, {}, $maxN, $maxP, $select, $max_expand, $filters);
    # Return the result.
    return $retVal;
}

=head3 IsAllGenomes

    my $flag = $sprout->IsAllGenomes(\@list, \@checkList);

Return TRUE if all genomes in the second list are represented in the first list at
least one. Otherwise, return FALSE. If the second list is omitted, the first list is
compared to a list of all the genomes.

=over 4

=item list

Reference to the list to be compared to the second list.

=item checkList (optional)

Reference to the comparison target list. Every genome ID in this list must occur at
least once in the first list. If this parameter is omitted, a list of all the genomes
is used.

=item RETURN

Returns TRUE if every item in the second list appears at least once in the
first list, else FALSE.

=back

=cut

sub IsAllGenomes {
    # Get the parameters.
    my ($self, $list, $checkList) = @_;
    # Supply the checklist if it was omitted.
    $checkList = [$self->Genomes()] if ! defined($checkList);
    # Create a hash of the original list.
    my %testList = map { $_ => 1 } @{$list};
    # Declare the return variable. We assume that the representation
    # is complete and stop at the first failure.
    my $retVal = 1;
    my $n = scalar @{$checkList};
    for (my $i = 0; $retVal && $i < $n; $i++) {
        if (! $testList{$checkList->[$i]}) {
            $retVal = 0;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 GetGroups

    my %groups = $sprout->GetGroups(\@groupList);

Return a hash mapping each group to the IDs of the genomes in the group.
A list of groups may be specified, in which case only those groups will be
shown. Alternatively, if no parameter is supplied, all groups will be
included. Genomes that are not in any group are omitted.

=cut
#: Return Type %@;
sub GetGroups {
    # Get the parameters.
    my ($self, $groupList) = @_;
    # Declare the return value.
    my %retVal = ();
    # Determine whether we are getting all the groups or just some.
    if (defined $groupList) {
        # Here we have a group list. Loop through them individually,
        # getting a list of the relevant genomes.
        for my $group (@{$groupList}) {
            my @genomeIDs = $self->GetFlat(['Genome'], "Genome(primary-group) = ?",
                [$group], "Genome(id)");
            $retVal{$group} = \@genomeIDs;
        }
    } else {
        # Here we need all of the groups. In this case, we run through all
        # of the genome records, putting each one found into the appropriate
        # group. Note that we use a filter clause to insure that only genomes
        # in real NMPDR groups are included in the return set.
        my @genomes = $self->GetAll(['Genome'], "Genome(primary-group) <> ?",
                                    [$FIG_Config::otherGroup], ['Genome(id)', 'Genome(primary-group)']);
        # Loop through the genomes found.
        for my $genome (@genomes) {
            # Get the genome ID and group, and add this genome to the group's list.
            my ($genomeID, $group) = @{$genome};
            push @{$retVal{$group}}, $genomeID;
        }
    }
    # Return the hash we just built.
    return %retVal;
}

=head3 MyGenomes

    my @genomes = Sprout::MyGenomes($dataDir);

Return a list of the genomes to be included in the Sprout.

This method is provided for use during the Sprout load. It presumes the Genome load file has
already been created. (It will be in the Sprout data directory and called either C<Genome>
or C<Genome.dtx>.) Essentially, it reads in the Genome load file and strips out the genome
IDs.

=over 4

=item dataDir

Directory containing the Sprout load files.

=back

=cut
#: Return Type @;
sub MyGenomes {
    # Get the parameters.
    my ($dataDir) = @_;
    # Compute the genome file name.
    my $genomeFileName = LoadFileName($dataDir, "Genome");
    # Extract the genome IDs from the files.
    my @retVal = map { $_ =~ /^(\S+)/; $1 } Tracer::GetFile($genomeFileName);
    # Return the result.
    return @retVal;
}

=head3 LoadFileName

    my $fileName = Sprout::LoadFileName($dataDir, $tableName);

Return the name of the load file for the specified table in the specified data
directory.

=over 4

=item dataDir

Directory containing the Sprout load files.

=item tableName

Name of the table whose load file is desired.

=item RETURN

Returns the name of the file containing the load data for the specified table, or
C<undef> if no load file is present.

=back

=cut
#: Return Type $;
sub LoadFileName {
    # Get the parameters.
    my ($dataDir, $tableName) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for the various file names.
    if (-e "$dataDir/$tableName") {
        $retVal = "$dataDir/$tableName";
    } elsif (-e "$dataDir/$tableName.dtx") {
        $retVal = "$dataDir/$tableName.dtx";
    }
    # Return the result.
    return $retVal;
}

=head3 DeleteGenome

    my $stats = $sprout->DeleteGenome($genomeID, $testFlag);

Delete a genome from the database.

=over 4

=item genomeID

ID of the genome to delete

=item testFlag

If TRUE, then the DELETE statements will be traced, but no deletions will occur.

=item RETURN

Returns a statistics object describing the rows deleted.

=back

=cut
#: Return Type $%;
sub DeleteGenome {
    # Get the parameters.
    my ($self, $genomeID, $testFlag) = @_;
    # Perform the delete for the genome's features.
    my $retVal = $self->Delete('Feature', "fig|$genomeID.%", testMode => $testFlag);
    # Perform the delete for the primary genome data.
    my $stats = $self->Delete('Genome', $genomeID, testMode => $testFlag);
    $retVal->Accumulate($stats);
    # Return the result.
    return $retVal;
}

=head3 Fix

    my %fixedHash = $sprout->Fix(%groupHash);

Prepare a genome group hash (like that returned by L</GetGroups>) for processing.
The groups will be combined into the appropriate super-groups.

=over 4

=item groupHash

Hash to be fixed up.

=item RETURN

Returns a fixed-up version of the hash.

=back

=cut

sub Fix {
    # Get the parameters.
    my ($self, %groupHash) = @_;
    # Create the result hash.
    my %retVal = ();
    # Copy over the genomes.
    for my $groupID (keys %groupHash) {
        # Get the super-group name.
        my $realGroupID = $self->SuperGroup($groupID);
        # Append this group's genomes into the result hash
        # using the super-group name.
        push @{$retVal{$realGroupID}}, @{$groupHash{$groupID}};
    }
    # Return the result hash.
    return %retVal;
}

=head3 GroupPageName

    my $name = $sprout->GroupPageName($group);

Return the name of the page for the specified NMPDR group.

=over 4

=item group

Name of the relevant group.

=item RETURN

Returns the relative page name (e.g. C<../content/campy.php>). If the group file is not in
memory it will be read in.

=back

=cut

sub GroupPageName {
    # Get the parameters.
    my ($self, $group) = @_;
    # Check for the group file data.
    my %superTable = $self->CheckGroupFile();
    # Compute the real group name.
    my $realGroup = $self->SuperGroup($group);
    # Get the associated page name.
    my $retVal = "../content/$superTable{$realGroup}->{page}";
    # Return the result.
    return $retVal;
}


=head3 AddProperty

    $sprout->AddProperty($featureID, $key, @values);

Add a new attribute value (Property) to a feature.

=over 4

=item peg

ID of the feature to which the attribute is to be added.

=item key

Name of the attribute (key).

=item values

Values of the attribute.

=back

=cut
#: Return Type ;
sub AddProperty {
    # Get the parameters.
    my ($self, $featureID, $key, @values) = @_;
    # Add the property using the attached attributes object.
    $self->ca->AddAttribute($featureID, $key, @values);
}

=head3 CheckGroupFile

    my %groupData = $sprout->CheckGroupFile();

Get the group file hash. The group file hash describes the relationship
between a group and the super-group to which it belongs for purposes of
display. The super-group name is computed from the first capitalized word
in the actual group name. For each super-group, the group file contains
the page name and a list of the species expected to be in the group.
Each species is specified by a genus and a species name. A species name
of C<0> implies an entire genus.

This method returns a hash from super-group names to a hash reference. Each
resulting hash reference contains the following fields.

=over 4

=item specials

Reference to a hash whose keys are the names of special species.

=item contents

A list of 2-tuples, each containing a genus name followed by a species name
(or 0, indicating all species). This list indicates which organisms belong
in the super-group.

=back

=cut

sub CheckGroupFile {
    # Get the parameters.
    my ($self) = @_;
    # Check to see if we already have this hash.
    if (! defined $self->{groupHash}) {
        # We don't, so we need to read it in.
        my %groupHash;
        # Read the group file.
        my @groupLines = Tracer::GetFile("$FIG_Config::sproutData/groups.tbl");
        # Loop through the list of sort-of groups.
        for my $groupLine (@groupLines) {
            my ($name, $specials, @contents) = split /\t/, $groupLine;
            $groupHash{$name} = { specials => { map { $_ => 1 } split /\s*,\s*/, $specials },
                                  contents => [ map { [ split /\s*,\s*/, $_ ] } @contents ]
                                };
        }
        # Save the hash.
        $self->{groupHash} = \%groupHash;
    }
    # Return the result.
    return %{$self->{groupHash}};
}

=head2 Virtual Methods

=head3 CleanKeywords

    my $cleanedString = $sprout->CleanKeywords($searchExpression);

Clean up a search expression or keyword list. This involves converting the periods
in EC numbers to underscores, converting non-leading minus signs to underscores,
a vertical bar or colon to an apostrophe, and forcing lower case for all alphabetic
characters. In addition, any extra spaces are removed.

=over 4

=item searchExpression

Search expression or keyword list to clean. Note that a search expression may
contain boolean operators which need to be preserved. This includes leading
minus signs.

=item RETURN

Cleaned expression or keyword list.

=back

=cut

sub CleanKeywords {
    # Get the parameters.
    my ($self, $searchExpression) = @_;
    # Get the stemmer.
    my $stemmer = $self->GetStemmer();
    # Convert the search expression using the stemmer.
    my $retVal = $stemmer->PrepareSearchExpression($searchExpression);
    Trace("Cleaned keyword list for \"$searchExpression\" is \"$retVal\".") if T(3);
    # Return the result.
    return $retVal;
}

=head3 GetSourceObject

    my $source = $erdb->GetSourceObject();

Return the object to be used in creating load files for this database.

=cut

sub GetSourceObject {
    # Get the parameters.
    my ($self) = @_;
    # Do we already have one?
    my $retVal = $self->{fig};
    if (! defined $retVal) {
        # Create the object.
        require FIG;
        $retVal = FIG->new();
        Trace("FIG source object created for process $$.") if T(ERDBLoadGroup => 3);
        # Set up retries to prevent the lost-connection error when harvesting
        # the feature data.
        my $dbh = $retVal->db_handle();
        $dbh->set_retries(5);
        # Save it for other times.
        $self->{fig} = $retVal;
    }
    # Return the object.
    return $retVal;
}

=head3 SectionList

    my @sections = $erdb->SectionList($fig);

Return a list of the names for the different data sections used when loading this database.
The default is a single string, in which case there is only one section representing the
entire database.

=cut

sub SectionList {
    # Get the parameters.
    my ($self, $source) = @_;
    # Ask the BaseSproutLoader for a section list.
    require BaseSproutLoader;
    my @retVal = BaseSproutLoader::GetSectionList($self, $source);
    # Return the list.
    return @retVal;
}

=head3 Loader

    my $groupLoader = $erdb->Loader($groupName, $options);

Return an [[ERDBLoadGroupPm]] object for the specified load group. This method is used
by L<ERDBGenerator.pl> to create the load group objects. If you are not using
L<ERDBGenerator.pl>, you don't need to override this method.

=over 4

=item groupName

Name of the load group whose object is to be returned. The group name is
guaranteed to be a single word with only the first letter capitalized.

=item options

Reference to a hash of command-line options.

=item RETURN

Returns an [[ERDBLoadGroupPm]] object that can be used to process the specified load group
for this database.

=back

=cut

sub Loader {
    # Get the parameters.
    my ($self, $groupName, $options) = @_;
    # Compute the loader name.
    my $loaderClass = "${groupName}SproutLoader";
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
    return qw(Feature Subsystem Genome Annotation Property Source Reaction Synonym Drug);
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
    return $self->{dataDir};
}

=head2 Internal Utility Methods

=head3 GetStemmer

    my $stermmer = $sprout->GetStemmer();

Return the stemmer object for this database.

=cut

sub GetStemmer {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal = $self->{stemmer};
    if (! defined $retVal) {
        # We don't have one pre-built, so we build and save it now.
        $retVal = BioWords->new(exceptions => "$FIG_Config::sproutData/Exceptions.txt",
                                 stops => "$FIG_Config::sproutData/StopWords.txt",
                                 cache => 0);
        $self->{stemmer} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 ParseAssignment

Parse annotation text to determine whether or not it is a functional assignment. If it is,
the user, function text, and assigning user will be returned as a 3-element list. If it
isn't, an empty list will be returned.

A functional assignment is always of the form

    set YYYY function to
    ZZZZ

where I<YYYY> is the B<user>, and I<ZZZZ> is the actual functional role. In most cases,
the user and the assigning user (from MadeAnnotation) will be the same, but that is
not always the case.

In addition, the functional role may contain extra data that is stripped, such as
terminating spaces or a comment separated from the rest of the text by a tab.

This is a static method.

=over 4

=item user

Name of the assigning user.

=item text

Text of the annotation.

=item RETURN

Returns an empty list if the annotation is not a functional assignment; otherwise, returns
a two-element list containing the user name and the function text.

=back

=cut

sub _ParseAssignment {
    # Get the parameters.
    my ($user, $text) = @_;
    # Declare the return value.
    my @retVal = ();
    # Check to see if this is a functional assignment.
    my ($type, $function) = split(/\n/, $text);
    if ($type =~ m/^set function to$/i) {
        # Here we have an assignment without a user, so we use the incoming user ID.
        @retVal = ($user, $function);
    } elsif ($type =~ m/^set (\S+) function to$/i) {
        # Here we have an assignment with a user that is passed back to the caller.
        @retVal = ($1, $function);
    }
    # If we have an assignment, we need to clean the function text. There may be
    # extra junk at the end added as a note from the user.
    if (defined( $retVal[1] )) {
        $retVal[1] =~ s/(\t\S)?\s*$//;
    }
    # Return the result list.
    return @retVal;
}

=head3 _CheckFeature

    my $flag = $sprout->_CheckFeature($fid);

Return TRUE if the specified FID is probably an NMPDR feature ID, else FALSE.

=over 4

=item fid

Feature ID to check.

=item RETURN

Returns TRUE if the FID is for one of the NMPDR genomes, else FALSE.

=back

=cut

sub _CheckFeature {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Insure we have a genome hash.
    my $genomes = $self->_GenomeHash();
    # Get the feature's genome ID.
    my ($genomeID) = FIGRules::ParseFeatureID($fid);
    # Return an indicator of whether or not the genome ID is in the hash.
    return ($self->{genomeHash}->{$genomeID} ? 1 : 0);
}

=head3 FriendlyTimestamp

Convert a time number to a user-friendly time stamp for display.

This is a static method.

=over 4

=item timeValue

Numeric time value.

=item RETURN

Returns a string containing the same time in user-readable format.

=back

=cut

sub FriendlyTimestamp {
    my ($timeValue) = @_;
    my $retVal = localtime($timeValue);
    return $retVal;
}


=head3 Hint

    my $htmlText = Sprout::Hint($wikiPage, $hintID);

Return the HTML for a help link that displays the specified hint text when it is clicked.
This HTML can be put in forms to provide a useful hinting mechanism.

=over 4

=item wikiPage

Name of the wiki page to be popped up when the hint mark is clicked.

=item hintID

ID of the text to display for the hint. This should correspond to a tip number
in the Wiki.

=item RETURN

Returns the html for the hint facility. The resulting html shows the word "help" and 
uses the standard FIG popup technology.

=back

=cut

sub Hint {
    # Get the parameters.
    my ($wikiPage, $hintID) = @_;
    # Declare the return variable.
    my $retVal;
    # Convert the wiki page name to a URL.
    my $wikiURL;
    if ($wikiPage =~ m#/#) {
        # Here it's a URL of some sort.
        $wikiURL = $wikiPage;
    } else {
        # Here it's a wiki page.
        my $page = join("", map { ucfirst $_ } split /\s+/, $wikiPage);
        if ($page =~ /^(.+?)\.(.+)$/) {
            $page = "$1/$2";
        } else {
            $page = "FIG/$page";
        }
        $wikiURL = "$FIG_Config::cgi_url/wiki/view.cgi/$page";
    }
    # Is there hint text?
    if (! $hintID) {
        # No. Create a new-page hint.
        $retVal = qq(&nbsp;<a class="hint" onclick="doPagePopup(this, '$wikiURL')">(help)</a>);
    } else {
        # With hint text, we create a popup window hint. We need to compute the hint URL.
        my $tipURL = "$FIG_Config::cgi_url/wiki/view.cgi/FIG/TWikiCustomTip" .
            Tracer::Pad($hintID, 3, 1, "0");
        # Create a hint pop-up link.
        $retVal = qq(&nbsp;<a class="hint" onclick="doHintPopup(this, '$wikiURL', '$tipURL')">(help)</a>);
    }
    # Return the HTML.
    return $retVal;
}

=head3 _GenomeHash

    my $gHash = $sprout->_GenomeHash();

Return a hash mapping all NMPDR genome IDs to [[ERDBObjectPm]] genome objects.

=cut

sub _GenomeHash {
    # Get the parameters.
    my ($self) = @_;
    # Do we already have a filled hash?
    if (! $self->{genomeHashFilled}) {
        # No, create it.
        my %gHash = map { $_->PrimaryValue('id') => $_ } $self->GetList("Genome", "", []);
        $self->{genomeHash} = \%gHash;
        # Denote we have it.
        $self->{genomeHashFilled} = 1;
    }
    # Return the hash.
    return $self->{genomeHash};
}

=head3 _GenomeData

    my $genomeData = $sprout->_GenomeData($genomeID);

Return an [[ERDBObjectPm]] object for the specified genome, or an undefined
value if the genome does not exist.

=over 4

=item genomeID

ID of the desired genome.

=item RETURN

Returns either an [[ERDBObjectPm]] containing the genome, or an undefined value.
If the genome exists, it will have been read into the genome cache.

=back

=cut

sub _GenomeData {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Are we in the genome hash?
    if (! exists $self->{genomeHash}->{$genomeID} && ! $self->{genomeHashFilled}) {
        # The genome isn't in the hash, and the hash is not complete, so we try to
        # read it.
        $self->{genomeHash}->{$genomeID} = $self->GetEntity(Genome => $genomeID);
    }
    # Return the result.
    return $self->{genomeHash}->{$genomeID};
}

=head3 _CacheGenome

    $sprout->_CacheGenome($genomeID, $genomeData);

Store the specified genome object in the genome cache if it is already there.

=over 4

=item genomeID

ID of the genome to store in the cache.

=item genomeData

An [[ERDBObjectPm]] containing at least the data for the specified genome.
Note that the Genome may not be the primary object in it, so a fully-qualified
field name has to be used to retrieve data from it.

=back

=cut

sub _CacheGenome {
    # Get the parameters.
    my ($self, $genomeID, $genomeData) = @_;
    # Only proceed if we don't already have the genome.
    if (! exists $self->{genomeHash}->{$genomeID}) {
        $self->{genomeHash}->{$genomeID} = $genomeData;
    }
}

1;