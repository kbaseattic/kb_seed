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

package BaseSproutLoader;

    use strict;
    use Tracer;
    use ERDB;
    use FIG;
    use Time::HiRes;
    use base 'ERDBLoadGroup';
    
    # Name of the global section
    use constant GLOBAL => 'Globals';

=head1 Sprout Load Group Base Class

=head2 Introduction

This is the base class for all the Sprout loaders. It performs common tasks
required by multiple load groups.

=head3 new

    my $sl = BaseSproutLoader->new($erdb, $options, @tables);

Construct a new BaseSproutLoader object.

=over 4

=item erdb

[[SproutPm]] object for the database being loaded.

=item source

L<FIG> object used to access the source data.

=item options

Reference to a hash of command-line options.

=item tables

List of tables in this load group.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options, @tables) = @_;
    # Create the base load group object.
    my $retVal = ERDBLoadGroup::new($class, $erdb, $options, @tables);
    # Return it.
    return $retVal;
}


=head2 Public Methods

=head3 GetGenomeAttributes

    my $aHashRef = $sl->GetGenomeAttributes($genomeID, \@fids);

Return a hash of attributes keyed on feature ID. This method gets all the NMPDR-related
attributes for all the features of a genome in a single call, then organizes them into
a hash.

=over 4

=item fig

FIG-like object for accessing attributes.

=item genomeID

ID of the genome whose attributes are desired.

=item fids (optional)

Reference to a list of feature IDs whose attributes are to be kept. If it is a list
of lists, the feature IDs will be taken from the first element in each sub-list.

=item RETURN

Returns a reference to a hash. The key of the hash is the feature ID. The value is the
reference to a list of the feature's attribute tuples. Each tuple contains the feature ID,
the attribute key, and one or more attribute values.

=back

=cut

sub GetGenomeAttributes {
    # Get the parameters.
    my ($self, $genomeID, $fids) = @_;
    # Get the source object.
    my $fig = $self->source();
    # Start a timer.
    my $start = time();
    # Initalize the FID list if we don't already have it.
    if (! defined $fids) {
        $fids = [ $fig->all_features($genomeID) ];
    }
    # Declare the return variable and initialize it with all the features.
    my %retVal = map { (ref $_ ? $_->[0] : $_) => [] } @$fids;
    # Get the attributes. If ev_code_cron is running, we may get a timeout error, so
    # an eval is used.
    my @aList = ();
    eval {
        @aList = $fig->get_attributes("fig|$genomeID%");
        Trace(scalar(@aList) . " attributes returned for genome $genomeID.") if T(ERDBLoadGroup => 3);
    };
    # Check for a problem.
    if ($@) {
        Trace("Retrying attributes for $genomeID due to error: $@") if T(ERDBLoadGroup => 1);
        # Our fallback plan is to process the attributes in blocks of 100. This is much slower,
        # but allows us to continue processing.
        my $nFids = scalar @$fids;
        for (my $i = 0; $i < $nFids; $i += 100) {
            # Determine the index of the last feature ID we'll be specifying on this pass.
            # Normally it's $i + 99, but if we're close to the end it may be less.
            my $end = ($i + 100 > $nFids ? $nFids - 1 : $i + 99);
            # Get a slice of the fid list.
            my @slice = @{$fids}[$i .. $end];
            # Get the relevant attributes.
            Trace("Retrieving attributes for fids $i to $end.") if T(ERDBLoadGroup => 3);
            my @aShort = $fig->get_attributes(\@slice);
            Trace(scalar(@aShort) . " attributes returned for fids $i to $end.") if T(ERDBLoadGroup => 3);
            push @aList, @aShort;
        }
    }
    # Now we should have all the interesting attributes in @aList. Populate the hash with
    # them.
    for my $aListEntry (@aList) {
        my $fid = $aListEntry->[0];
        if (exists $retVal{$fid}) {
            push @{$retVal{$fid}}, $aListEntry;
            $self->Add(attributes => 1);
        }
    }
    $self->Add('attribute-time' => time() - $start);
    # Return the result.
    return \%retVal;
}

=head3 GetSubsystems

    my $subsystems = $sl->GetSubsystems();

Get a hash of the subsystems for this incarnation of the Sprout database.
The hash maps each subsystem ID to 1. The first time this method is called,
it creates a file listing the subsystems found. Subsequent calls read the
list from the file so that the selection of subsystems remains consistent.

=cut

sub GetSubsystems {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout object.
    my $sprout = $self->db();
    # Get the FIG source object.
    my $fig = $self->source();
    # The names found will be put in here.
    my @retVal = ();
    # Check for the file.
    my $subFileName = $sprout->LoadDirectory() . "/SubsystemList.dty";
    if (-f $subFileName) {
        # It's there. Get the list from it.
        @retVal = Tracer::GetFile($subFileName);
    } else {
        # No, so compute the list and then create the file.
        my @subs = $fig->all_subsystems();
        for my $sub (@subs) {
            # Only keep NMPDR subsystems that exist on disk.
            if ($fig->nmpdr_subsystem($sub) && ! $fig->is_experimental_subsystem($sub)) {
                push @retVal, $sub;
            }
        }
        Tracer::PutFile($subFileName, \@retVal);
    }
    Trace(scalar(@retVal) . " subsystems in list.") if T(ERDBLoadGroup => 3);
    # Return the result.
    my %retVal = map { $_ => 1 } @retVal;
    return \%retVal;
}


=head3 GetSectionList

    my @sections = BaseSproutLoader::GetSectionList($sprout, fig, $directory);

Return a list of the sections for a Sprout load. The section list is
normally determined by retrieving a list of all the complete genomes and
adding an extra global section at the end; however, the first time the
sections are determined, they are stored in a master file so that the
same list is used regardless of what may have changed in the source data.
(A similar trick is used for subsystems).

=over 4

=item sprout

[[SproutPm]] object for the database being loaded.

=item fig

L<FIG> object from which the data is being retrieved.

=item directory (optional)

Directory from which the Sprout tables are being loaded.

=item RETURN

Returns a list of section names.

=back

=cut

sub GetSectionList {
    my ($sprout, $fig, $directory) = @_;
    # Declare the return variable.
    my @retVal;
    # Insure we have a data directory.
    $directory ||= $sprout->LoadDirectory();
    # Look for the section list in the data directory.
    my $sectionFileName = $directory . "/" .
        ERDBGenerate::CreateFileName('section_master', undef, 'control');
    if (-f $sectionFileName) {
        # It's there. Get the list from it.
        @retVal = Tracer::GetFile($sectionFileName);
    } else {
        # We need to create it. First, we get the list of all complete
        # genomes. As a safety feature, we only include genomes with
        # an organism directory.
        my @genomes = grep { -d "$FIG_Config::organisms/$_" } $fig->genomes(1);
        # Sort the results and add the GLOBAL tag.
        @retVal = sort { $a cmp $b } @genomes;
        push @retVal, GLOBAL;
        # Write the list to a file for future use. This insures that if the source
        # data changes, we have a consistent section list.
        Tracer::PutFile($sectionFileName, \@retVal);
    }
    # Return the list.
    return @retVal;
}

=head3 global

    my $flag = $sl->global();

TRUE if this is the global section, else FALSE.

=cut

sub global {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return ($self->{section} eq GLOBAL);
}

=head3 GetCommaList

    my $string = $sl->GetCommaList($value);

Create a comma-separated list of the values in a list reference. If the
list reference is a scalar, it will be returned unchanged. If it is
undefined, an empty string will be returned. The idea is that we may be
looking at a string, a list, or nothing, but whatever comes out will be a
string.

=over 4

=item value

Reference to a list of values to be assembled into the return string.

=item RETURN

Returns a scalar string containing the content of the input value.

=back

=cut

sub GetCommaList {
    # Get the parameters.
    my ($self, $value) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Only proceed if we have an input value.
    if (defined $value) {
        # Analyze the input value.
        if (ref $value eq 'ARRAY') {
            # Here it's a list reference.
            $retVal = join(", ", @$value);
        } else {
            # Here it's not. Flatten it to a scalar.
            $retVal = "$value";
        }
    }
    # Return the result.
    return $retVal;
}


1;
