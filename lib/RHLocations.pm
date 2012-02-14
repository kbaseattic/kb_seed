#!/usr/bin/perl -w

package RHLocations;

    use strict;
    use Tracer;
    use BasicLocation;
    use ERDBObject;
    use POSIX;
    use base 'ResultHelper';

=head1 Location Result Helper

=head2 Introduction

The location result helper is used to display the results of a search that returns
DNA or protein locations. A DNA location is specified as a location inside a contig.
A protein location is specified as a location inside a feature.

=cut

=head2 Data Structures

=head3 NEIGHBORHOOD

Maximum distance in nucleotides for two locations to be considered in the same neighborhood.

=cut

    use constant { NEIGHBORHOOD => 4000 };

=head2 Public Methods

=head3 new

    my $rhelp = RHLocations->new($shelp);

Construct a new RHLocations object.

=over 4

=item shelp

Parent search helper object for this result helper.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $shelp) = @_;
    # Create the helper object.
    my $retVal = ResultHelper::new($class, $shelp);
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 BuildLocationRecord

    my $erdbObject = $rhelp->BuildLocationRecord($hitLocString);

Build an B<ERDBObject> containing data about a specified location. Unlike most
result objects, a location does not exist in the Sprout database. This method
is used to parse the location string into fields and package them as an
object for use by the column methods.

This method is provided as a static function so that the other methods of
this object have the privilege of knowing what data is in the B<ERDBObject>
generated. This is less important for the other result helpers because they
deal in database objects whose fields can be deduced from the database design.

=over 4

=item hitLocString

A string representation of a hit location, in a standard form that can
be parsed using the B<BasicLocation> constructor (e.g. C<fig|100226.1.peg.3361_140_10>
or C<100226.1:NC_003888_3766170+612>).

=item RETURN

Returns an B<ERDBObject> containing all the values parsed out of the hit location.

=back

=cut

sub BuildLocationRecord {
    # Get the parameters.
    my ($self, $hitLocString) = @_;
    # Parse the location string into a location object.
    my $hitLocObject = BasicLocation->new($hitLocString);
    # Compute the genome ID from the Contig. Note that if this is a protein
    # location, the Contig is actually a feature ID. In both cases, however,
    # the genome ID is encoded as part of the ID in clear text.
    my $contig = $hitLocObject->Contig;
    $contig =~ /(\d+\.\d+)/;
    my $genome = $1;
    # Convert the components into data fields in an ERDBObject.
    my $retVal = ERDBObject->new($self->DB(), 'Location', {
                                 container => $contig,
                                 genome    => $genome,
                                 begin     => $hitLocObject->Begin,
                                 dir       => $hitLocObject->Dir,
                                 length    => $hitLocObject->Length,
                                 string    => $hitLocObject->String
                                 });
    # Return the result.
    return $retVal;
}

=head3 HitLocation

    my $locString = $rhelp->HitLocation();

Return the hit location string for the current output line.

=cut

sub HitLocation {
    # Get the parameters.
    my ($self) = @_;
    # Get the record.
    my $record = $self->Record;
    # Pull out the location string.
    return $record->PrimaryValue('Location(string)');
}

=head3 FindNearbyFeature

    my $featureObject = $rhelp->FindNearbyFeature($hitLoc);

Find a nearby feature for this hit location. If the hit location is a protein
location (i.e. inside a known feature), then the feature is returned without
preamble. If the hit location is on a contig, the feature chosen will be the
one whose midpoint is closest to the location's midpoint.

This method is used by the run-time-value methods, so there will not be
a copy of the current record available.

=over 4

=item hitLoc

String describing the relevant hit location.

=item RETURN

Returns a record for the nearest feature.

=back

=cut

sub FindNearbyFeature {
    # Get the parameters.
    my ($self, $hitLoc) = @_;
    # Declare the return variable.
    my $retVal;
    # Get a sprout object.
    my $shelp = $self->Parent();
    my $sprout = $shelp->DB();
    # Compute the hit location object and the target object name.
    my $hitLocObj = BasicLocation->new($hitLoc);
    # Get the location's target object.
    my $targetObjectName = $hitLocObj->Contig;
    # Check its type.
    if ($targetObjectName =~ /^fig\|/) {
        # Here the target object is a feature, so we return the feature itself.
        $retVal = $sprout->GetEntity(Feature => $targetObjectName);
        Trace("Feature $targetObjectName chosen as nearby to $hitLoc.") if T(4);
        Trace("Feature object not found.") if T(4) && ! defined $retVal;
    } else {
        # Here it's a contig, so we have to search the hard way. First, we need the
        # neighborhood size.
        my $tuningParms = $shelp->TuningParameters(neighborhood => NEIGHBORHOOD);
        my $neighborhood = $tuningParms->{neighborhood};
        Trace("Neighborhood is $neighborhood.") if T(4);
        # Widen the location by the neighborhood distance on both sides. This requires knowing
        # the contig length.
        my $contigLength = $sprout->ContigLength($targetObjectName);
        my $wideLocObj = BasicLocation->new($hitLocObj);
        $wideLocObj->Widen($neighborhood, $contigLength);
        Trace("Search neighborhood is " . $hitLocObj->String . ".") if T(4);
        # Look for features in the computed region.
        my @features = $sprout->GeneDataInRegion($targetObjectName, $wideLocObj->Left, $wideLocObj->Right);
        # Get the midpoint of the hit location.
        my $hitMidpoint = ($hitLocObj->Begin + $hitLocObj->EndPoint) / 2;
        # Search for the best choice. This will be a feature whose midpoint is closest to our
        # mid point.
        my $bestFeature;
        my $bestDistance = INT_MAX;
        for my $feature (@features) {
            # Get this feature's last location.
            my @locList = split /\s*,\s*/, $feature->PrimaryValue('Feature(location-string)');
            for my $featureLoc (@locList) {
                my $currentLoc = BasicLocation->new($featureLoc);
                my $midPoint = ($currentLoc->Begin + $currentLoc->EndPoint) / 2;
                my $newDistance = abs($midPoint - $hitMidpoint);
                Trace("Distance is $newDistance. Best is $bestDistance.") if T(4);
                # Now we determine whether or not this feature is better than the best one so far.
                my $better = 0;
                if ($newDistance < $bestDistance) {
                    # Here it's closer, so it is automatically better.
                    $better = 1;
                } elsif ($newDistance == $bestDistance && $currentLoc->Dir eq $hitLocObj->Dir) {
                    # If the distances are the same, we break ties in favor of the location on the same strand.
                    $better = 1;
                }
                if ($better) {
                    $bestFeature = $feature;
                    $bestDistance = $newDistance;
                }
            }
        }
        # Return the feature with the best distance.
        $retVal = $bestFeature;
    }
    # Return the result.
    return $retVal;
}

=head3 NearbyFeature

    my $featureRecord = $rhelp->NearbyFeature($hitLoc);

Return the nearby feature. If it has already been found, we return it from the
cache. Otherwise we find it and then cache it on our way out.

=over 4

=item hitLoc

Location string for the current hit.

=item RETURN

Returns an C<ERDBObject> for the desired feature, or C<undef> if no such
feature exists.

=back

=cut

sub NearbyFeature {
    # Get the parameters.
    my ($self, $hitLoc) = @_;
    # Declare the return variable.
    my $retVal;
    # Check the cache.
    my $cache = $self->Cache;
    if (exists $cache->{nearby}) {
        # Here we've already cached the value.
        $retVal = $cache->{nearby};
    } else {
        # Here we need to find it the hard way.
        $retVal = $self->FindNearbyFeature($hitLoc);
        # Save it for next time.
        $cache->{nearby} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head2 Virtual Overrides

=head3 DefaultResultColumns

    my @colNames = $rhelp->DefaultResultColumns();

Return a list of the default columns to be used by searches with this
type of result. Note that the actual default columns are computed by
the search helper. This method is only needed if the search helper doesn't
care.

The columns returned should be in the form of column names, all of which
must be defined by the result helper class.

=cut

sub DefaultResultColumns {
    return qw(nextFeature orgName nextFeatureFunction compareLink);
}

=head3 GetColumnNameList

    my @names = $rhelp->GetColumnNameList();

Return a complete list of the names of columns available for this result
helper. This is considerably smaller than the complete list, because not all
of the columns are available when we're in the Seed Viewer.

=cut

sub GetColumnNameList {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return qw(orgName nextFeature);
}

=head3 Permanent

    my $flag = $rhelp->Permanent($colName);

Return TRUE if the specified column should be permanent when used in a
Seed Viewer table, else FALSE.

=over 4

=item colName

Name of the column to check.

=item RETURN

Returns TRUE if the column should be permanent, else FALSE.

=back

=cut

sub Permanent {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Declare the return variable.
    my $retVal = ($colName eq 'orgName' || $colName eq 'nextFeature');
    # Return the result.
    return $retVal;
}

=head2 Column Methods

=head3 compareLink

    my $colDatum = RHLocations::compareLink($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the compareLink column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the compareLink column.

=back

=cut

sub compareLink {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column. Button columns
        # generally don't have titles.
        $retVal = '';
    } elsif ($type eq 'download') {
        # This field should not be included in a download. It relies on the
        # existence of files that may expire soon.
        $retVal = '';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # This is a run-time value that depends on the hit location.
        my $newKey = $rhelp->HitLocation;
        $retVal = "%%compareLink=$newKey";
    } elsif ($type eq 'runTimeValue') {
        my $feature = $rhelp->NearbyFeature($key);
        if (! defined($feature)) {
            # No nearby feature, so we don't return anything.
            $retVal = "";
        } else {
            # Here we want to create a formlet. We need the session ID
            # and the feature id.
            my $shelp = $rhelp->Parent;
            my $session = $shelp->ID();
            my $fid = $feature->PrimaryValue('Feature(id)');
            $retVal = $rhelp->FakeButton('Context', "wiki/rest.cgi/NmpdrPlugin/PatScanResult",
                                         undef, page => 'genome_regions', peg => $fid,
                                         file => "tmp_$session.cache",
                                         SPROUT => 1);
        }
    }
    return $retVal;
}

=head3 nextFeature

    my $colDatum = RHLocations::nextFeature($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the nextFeature column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the nextFeature column.

=back

=cut

sub nextFeature {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Nearest Feature';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # This is a run-time value that depends on the hit location.
        my $newKey = $rhelp->HitLocation;
        $retVal = "%%nextFeature=$newKey";
    } elsif ($type eq 'runTimeValue' || $type eq 'valueFromKey') {
        my $feature = $rhelp->NearbyFeature($key);
        if (! defined($feature)) {
            # No nearby feature, so we don't return anything.
            $retVal = "";
        } else {
            # Get the feature's preferred ID.
            $retVal = $rhelp->PreferredID($feature);
            # Get its real ID.
            my $fid = $feature->PrimaryValue('id');
            # If we're a run-time value. Link it to the seed viewer page.
            if ($type eq 'runTimeValue') {
                $retVal = CGI::a({ href => "$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/SeedViewer?page=Annotation;feature=$fid" },
                         $retVal);
            }
        }
    }
    return $retVal;
}

=head3 nextFeatureFunction

    my $colDatum = RHLocations::nextFeatureFunction($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the nextFeatureFunction column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the nextFeatureFunction column.

=back

=cut

sub nextFeatureFunction {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Assignment';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # This is a run-time value that depends on the hit location.
        my $newKey = $rhelp->HitLocation;
        $retVal = "%%nextFeatureFunction=$newKey";
    } elsif ($type eq 'runTimeValue') {
        my $feature = $rhelp->NearbyFeature($key);
        if (! defined($feature)) {
            # No nearby feature, so we don't return anything.
            $retVal = "";
        } else {
            # Get the feature's assignment.
            $retVal = $feature->PrimaryValue('Feature(assignment)');
        }
    }
    return $retVal;
}

=head3 nextFeatureLink

    my $colDatum = RHLocations::nextFeatureLink($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the nextFeatureLink column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the nextFeatureLink column.

=back

=cut

sub nextFeatureLink {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Links don't need a column title.
        $retVal = '';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'link';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # This is a run-time value that depends on the hit location.
        my $newKey = $rhelp->HitLocation;
        $retVal = "%%nextFeatureLink=$newKey";
    } elsif ($type eq 'runTimeValue') {
        my $feature = $rhelp->NearbyFeature($key);
        if (! defined($feature)) {
            # No nearby feature, so we don't return anything.
            $retVal = "";
        } else {
            # Create a formlet for the feature's page.
            my $fid = $feature->PrimaryValue('Feature(id)');
            $retVal = $rhelp->FakeButton('Viewer', "wiki/rest.cgi/NmpdrPlugin/SeedViewer",
                                         undef, page => 'Annotation', feature => $fid);
        }
    }
    return $retVal;
}

=head3 orgName

    my $colDatum = RHLocations::orgName($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the orgName column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag, and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the orgName column.

=back

=cut

sub orgName {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'Organism Name';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # Get the data record and the parent search helper.
        my $record = $rhelp->Record;
        my $shelp = $rhelp->Parent;
        # Extract the genome ID.
        my $genomeID = $record->PrimaryValue('Location(genome)');
        # Ask the parent for the organism name. This will usually be in a cache.
        $retVal = $shelp->Organism($genomeID);
        # Convert it to a hyperlink.
        $retVal = CGI::a({ href => "$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/SeedViewer?page=Organism;organism=$genomeID" },
                         $retVal);
    } elsif ($type eq 'runTimeValue') {
        # Run-time support is not needed for this column.
    } elsif ($type eq 'valueFromKey') {
        # The key is the hit location string. It starts with the genome ID.
        my $shelp = $rhelp->Parent;
        my ($genomeID) = split /:/, $key, 2;
        $retVal = $shelp->Organism($genomeID);
    }
    return $retVal;
}


1;
