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

package TargetCriterionEC;

    use strict;
    use Tracer;
    use Sprout;
    use base qw(TargetCriterionQuery);

=head1 EC Number Match Target Search Criterion Object

=head2 Introduction

This is a search criterion object for search criteria involving an EC number.
For any given feature, we have not only its primary EC numbers, but also
any wild-card EC numbers that might subsume it. As a result, finding the
features for a particular EC number is very fast, but when we display the
EC numbers, we're going to be showing too much information. This object,
in addition to having a more sophisticated validation algorithm, also removes
redundant numbers from the display.

=head2 Special Methods

=head3 new

    my $tc = TargetCriterionEC->new($rhelp, $name, $label, $hint);

Construct a new TargetCriterionEC object. The following parameters are
expected.

=over 4

=item rhelp

[[ResultHelperPm]] object for the active search.

=item name

Identifying name of this criterion.

=item label

Label to display for this criterion in the type dropdown.

=item hint

The hint tooltip to be displayed for this criterion.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $rhelp, $name, $label, $hint) = @_;
    # Construct the underlying object.
    my $retVal = TargetCriterionQuery::new($class, $rhelp, { label => $label,
                                                            hint => $hint,
                                                            text => 1,
                                                            name => $name },
                                           ec => qw(Feature));
    # Return the object.
    return $retVal;
}

=head2 Virtual Methods

=head3 Validate

    my $okFlag = $tc->Validate($parms);

Return TRUE if the specified parameters are valid for a search criterion of this type
and FALSE otherwise. If an error is detected, the error message can be retrieved using
the L</message> method.

=over 4

=item parms

A Criterion Parameter Object whose fields are to be validated.

=item RETURN

Returns TRUE if the parameters are valid, else FALSE.

=back

=cut

sub Validate {
    # Get the parameters.
    my ($self, $parms) = @_;
    # Default to valid.
    my $retVal = 1;
    # Get the relevant value.
    my $value = $parms->{stringValue} || '';
    # Fail if it has the wrong format.
    if ($value eq '') {
        $retVal = 0;
        $self->SetMessage("No value specified for $self->{label}.");
    } else {
        my @pieces = split /\./, $value;
        if (@pieces != 4) {
            $retVal = 0;
            $self->SetMessage("Incorrect number of sections in $self->{label}.");
        } else {
            # Parse the individual pieces. Note that as soon as we find a minus,
            # we require all the following pieces to be minuses.
            while ($retVal && (my $piece = shift @pieces)) {
                if ($piece eq '-') {
                    my $count = scalar(grep { $_ ne '-' } @pieces);
                    if ($count > 0) {
                        $retVal = 0;
                        $self->SetMessage("Improper hyphen use in $self->{label}.");
                    }
                } elsif ($piece =~ /\D/) {
                    $retVal = 0;
                    $self->SetMessage("Invalid number in $self->{label}.");
                }
            }
        }
    }
    # Return the validation code.
    return $retVal;
}

=head3 Sane

    my $flag = $tc->Sane($parms);

Return TRUE if this is a sane criterion, else FALSE. Every search must have at least one
sane criterion in order to be valid.

=over 4

=item parms (optional)

The Criterion Parameter Object for the current query.

=item RETURN

Returns TRUE if this query returns a relatively limited result set and uses SQL,
else FALSE. We return TRUE if the EC number has no more than two hyphens.

=back

=cut

sub Sane {
    my ($self, $parms) = @_;
    # Declare the return value.
    my $retVal;
    # Check the parameters.
    if (! $parms) {
        # This is usually a sane criterion, so when we're called without a
        # parameter object, we return TRUE.
        $retVal = 1;
    } elsif ($parms->{stringValue} =~ /-.-.-/) {
        # Here there are too many hyphens (unless the thing is malformed in
        # some way, in which case sanity is not an issue).
        $retVal = 0;
    } else {
        # Here we're okay.
        $retVal = 1;
    }
    return $retVal;
}

=head3 CacheValue

    my $value = $tc->CacheValue($feature);

Return the value to cache for this criterion with respect to the specified
feature. Normally, this will be an HTML displayable version of the
appropriate value. If the value is immediately available, it is
returned; however, if the value is not available at the current time, a
runtime-value request is returned in its place.

=over 4

=item feature

[[ERDBObjectPm]] object containing the data for the current feature.

=item RETURN

Returns the value that should be put in the search result cache file for
this column.

=back

=cut

sub CacheValue {
    # Get the parameters.
    my ($self, $feature) = @_;
    # Declare the return variable.
    my $retVal;
    # We need to determine if we already have the value or not. First, we check
    # the cache.
    if (defined $self->{cache}) {
        # Yes. Format it as HTML.
        $retVal = $self->FormatECs($self->{cache});
    } else {
        # It's not in the cache, so we put it off until runtime.
        my $name = $self->name();
        my $fid = $feature->PrimaryValue('Feature(id)');
        $retVal = "%%$name=$fid";
    } 
    # Return the result.
    return $retVal;
}


=head3 RunTimeValue

    my $runTimeValue = $tc->RunTimeValue($runTimeKey);

Return the run-time value for this column using the specified key. The key
in this case will be the feature ID. The feature ID continas the genome ID
embedded within it.

The way we compute the run-time value depends on where the value can be found.
If it's in the Feature or Genome objects, we simply read it using B<GetFlat>.
Otherwise, we 

=over 4

=item runTimeKey

Key value placed in the search result cache when the need for the desired
value was determined during search processing. This will be the feature
ID.

=item RETURN

Returns the actual value to be used for the specified column.

=back

=cut

sub RunTimeValue {
    # Get the parameters.
    my ($self, $runTimeKey) = @_;
    # Read the values from the database. Note that the run-time key in this case
    # is a feature ID.
    my @values = $self->ReadDatabaseValues($runTimeKey);
    # Format the values for HTML display.
    my $retVal = $self->FormatECs(\@values);
    # Return the result.
    return $retVal;
}

=head3 FormatECs

    my $html = $tc->FormatECs(\@values);

Format a list of EC numbers for display. Redundant EC numbers will be
removed, and the others will be hyperlinked to searches.

=over 4

=item values

Reference to a list of well-formed EC number strings.

=item RETURN

Returns HTML listing the nonredundant EC numbers hyperlinked to the
appropriate searches.

=back

=cut

sub FormatECs {
    # Get the parameters.
    my ($self, $values) = @_;
    # Get a copy of the list sorted by the number of hyphens.
    my @sortedValues = sort { tr/-// <=> tr/-// } @$values;
    # We'll put the good values in here. Because the list
    # is sorted from fewest hyphens to most, we only need to
    # look at a kept number when deciding whether or not to
    # keep the current one. If there's a more specific version
    # of a number, we'll already have seen it thanks to the sort.
    my @keepers;
    # Loop through the list of values.
    for my $ec (@sortedValues) {
        # We'll set this to a nonzero value if there's a matching number.
        my $match = 0;
        # We only need to do fancy stuff if there's a hyphen.
        if ($ec =~ /(.+?)-/) {
            # Check for a match among the kept stuff.
            my $prefix = $1;
            my $len = length($1);
            $match = (grep { substr($_, 0, $len) eq $prefix } @keepers);
            # If there's no match, keep this number.
        }
        # If there's no match, this is a keeper.
        push @keepers, $ec;
    }
    # We need to convert each EC number to a search hyperlink. This
    # requires computing a URL with the following prefix.
    my $url = "$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/search?Class=WordSearch;keywords=";
    # Build the list of links.
    my @links = map { CGI::a({ href => "$url$_"}, $_) } @keepers;
    # Convert it to a comma-delimited list.
    my $retVal = join(", ", @links);
    # Return the result.
    return $retVal;
}

=head3 ComputeQuery

    my ($joins, $filterString, $parms) = $tc->ComputeQuery($criterion);

Compute the SQL filter, join list, and parameter list for this
criterion. If the criterion cannot be processed by SQL, then nothing is
returned, and the criterion must be handled during post-processing.

The join list and the parameter list should both be list references. The
filter string is a true string.

If the filter string only uses the B<Genome> and B<Feature> tables, then the
join list can be left empty. Otherwise, the join list should start with the
particular starting point (B<Genome> or B<Feature>) and list the path through
the other relevant entities and relationships. Each criterion will have its
own separate join path. 

=over 4

=item criterion

Reference to a Criterion Parameter Object.

=item RETURN

Returns a 3-tuple consisting of the join list, the relevant filter string,
and the matching parameters. If the criterion cannot be processed using
SQL, then the return list contains three undefined values. (This is what happens if
you don't override this method.)

=back

=cut

sub ComputeQuery {
    # Get the parameters.
    my ($self, $criterion) = @_;
    # Get the name of the relevant field with the appropriate suffix.
    my $fieldName = $self->RelevantField($criterion->{idx});
    # Compute the join list.
    my $joins = $self->JoinList();
    # Compute the filter string.
    my $filterString = "$fieldName = ?";
    # Get the parameter value.
    my $parm = $criterion->{stringValue};
    # Return the results.
    return ($joins, $filterString, [$parm]);
}

1;
