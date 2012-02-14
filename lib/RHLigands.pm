#!/usr/bin/perl -w

package RHLigands;

    use strict;
    use Tracer;
    use ERDBObject;
    use POSIX;
    use base 'ResultHelper';

=head1 Ligand Result Helper

=head2 Introduction

This result helper allows a search to display data about ligands. Currently,
there is very little data about a ligand in the database. The only
column we support is the ligand ID formatted with the name as a tooltip.


=head2 Public Methods

=head3 new

    my $rhelp = RHLigands->new($shelp);

Construct a new RHLigands object.

=over 4

=item shelp

Parent search helper object for this result helper.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $shelp) = @_;
    # Create and bless the helper object.
    my $retVal = ResultHelper::new($class, $shelp);
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

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
    return qw(zincId);
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
    my $retVal = ($colName eq 'zincId');
    # Return the result.
    return $retVal;
}

=head2 Column Methods

=head3 zincId

    my $colDatum = RHLigands::zincId($type => $rhelp, $key);

This method computes the various things we need to know into order to process
the zincId column.

=over 4

=item type

Type of data about the column that is required: C<title> for the column title,
C<download> for the download flag (TRUE if the field should be included in
a standard tab-delimited download file and FALSE otherwise), and so forth.

=item rhelp

Result helper being used to format the search output.

=item key (optional)

The key to be used to compute a run-time value.

=item RETURN

Returns the desired information about the zincId column.

=back

=cut

sub zincId {
    # Get the parameters.
    my ($type, $rhelp, $key) = @_;
    # Declare the return variable.
    my $retVal;
    # Process according to the information requested.
    if ($type eq 'title') {
        # Return the title for this column.
        $retVal = 'ZINC ID';
    } elsif ($type eq 'download') {
        # This field should be included in a download.
        $retVal = 'text';
    } elsif ($type eq 'style') {
        # Here the caller wants the style class used to format this column.
        $retVal = 'leftAlign';
    } elsif ($type eq 'value') {
        # Get the ligand record.
        my $record = $rhelp->Record();
        # Extract the ID and name.
        my ($id, $name) = $record->Values(['Ligand(id)', 'Ligand(name)']);
        # Create a tooltip for the ligand name.
        $retVal = CGI::a({ href => "http://blaster.docking.org/zinc/srchdbk.pl?zinc=$id;go=Query",
                            title => $name }, $id);
    } elsif ($type eq 'runTimeValue') {
        # Runtime support is not needed for this column.
    } elsif ($type eq 'valueFromKey') {
        # We can't do a tooltip on this one, it would be too expensive.
        $retVal = CGI::a({ href => "http://blaster.docking.org/zinc/srchdbk.pl?zinc=$key;go=Query" },
                         $key);
    }
    return $retVal;
}

1;
