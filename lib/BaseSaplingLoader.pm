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

package BaseSaplingLoader;

    use strict;
    use Tracer;
    use ERDB;
    use FIG;
    use Time::HiRes;
    use base 'ERDBLoadGroup';
    
    # Name of the global section
    use constant GLOBAL => 'Globals';

=head1 Sapling Load Group Base Class

=head2 Introduction

This is the base class for all the Sapling loaders. It performs common tasks
required by multiple load groups.

=head3 new

    my $sl = BaseSaplingLoader->new($erdb, $options, @tables);

Construct a new BaseSaplingLoader object.

=over 4

=item erdb

L<Sapling> object for the database being loaded.

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

=head3 global

    my $flag = $sl->global();

Return TRUE if the current section is the global section.

=cut

sub global {
    my ($self) = @_;
    # Get the database.
    my $sapling = $self->db();
    # Get the section ID.
    my $section = $self->section();
    # Ask the DB object if this is the global section.
    return $sapling->GlobalSection($section);
}

=head3 Starless

    my $adjusted = BaseSaplingLoader::Starless($codeString);

Remove any spaces and leading or trailing asterisks from the incoming string and
return the result.

=over 4

=item codeString

Input string that needs to have the asterisks trimmed.

=item RETURN

Returns the incoming string with spaces and leading and trailing asterisks
removed.

=back

=cut

sub Starless {
    # Get the parameters.
    my ($codeString) = @_;
    # Declare the return variable.
    my $retVal = $codeString;
    # Remove the spaces.
    $retVal =~ s/\s+//g;
    # Trim the asterisks.
    $retVal =~ s/^\*+//;
    $retVal =~ s/\*+$//;
    # Return the result.
    return $retVal;
}

=head3 LoadFromFile

    $sl->LoadFromFile($tableName => $fileName, @fieldNames);

This method loads the specified table from the specified tab-delimited
file. The list of field names indicates the order in which the fields are
present in the input file.

=over 4

=item tableName

Name of the table to load.

=item fileName

Name of the file containing the data for the table.

=item fieldNames

List of the names of the fields found in the file, in the order they are
found in the load file.

=back

=cut

sub LoadFromFile {
    # Get the parameters.
    my ($self, $tableName, $fileName, @fieldNames) = @_;
    # Open the input file.
    my $ih = Open(undef, "<$fileName");
    # We'll use this to count the number of records read.
    my $count = 0;
    # Loop through the file.
    while (! eof $ih) {
        # Get the next input record.
        my @inFields = Tracer::GetLine($ih);
        $self->Track(FileRecords => $fileName . " line " . ++$count, 1000);
        # Insure we have any blank fields truncated from the end.
        while (scalar(@inFields) <= $#fieldNames) {
            push @inFields, "";
        }
        # Create a map from field names to values.
        my %map = map { $fieldNames[$_] => $inFields[$_] } 0 .. $#fieldNames;
        # Insert it into the table.
        $self->Put($tableName, %map);
    }
}


1;
