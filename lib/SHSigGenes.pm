#!/usr/bin/perl -w

package SHSigGenes;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use Time::HiRes;
    use FIGRules;
    use RHFeatures;
    use base 'SearchHelper';

=head1 Gene Discrimination Feature Search Helper

=head2 Introduction

This search performs a signature genes comparison. The user selects two genome sets,
and the search returns genes from a given genome which are common only in the first set
and not in the second. If the second set is empty, the search will return genes from
the given genome that are common in the first set.

Gene identity will be computed in this case using bidirectional best hits. If gene X
from the given genome has a BBH in a specified genome Y, then it is said to occur
in whatever set includes genome Y. A gene is considered I<common> if it occurs in a
certain percentage of the genomes of the set.

This search has the following extra parameters.

=over 4

=item given

The ID of the given genome.

=item target[]

The IDs of the genomes in the first (target) set. The given genome is
automatically considered a part of this set, so it can never be empty.

=item exclusion[]

The IDs of the genomes in the second (exclusion) set. If this set is empty, then
no genes will be considered common in set 2, causing all genes common in set 1
to be selected.

=item commonality

Minimum score for a gene to be considered common. The score is equal to the number
of genomes containing a bidirectional best hit of the gene divided by the total
number of genomes. The default is C<0.8>. A value of C<1> means a gene must have
BBHs in all of the genomes to be considered common; a value of C<0> is invalid.

=item cutoff

Maximum match difference for a BBH hit to be considered valid. The default is C<1e-10>.

=item showMatch

If TRUE, then all the genes in the target set that match the ones in the reference genome
will be shown in an extra column.

=back

=head2 Virtual Methods

=head3 Form

    my $html = $shelp->Form();

Generate the HTML for a form to request a new search.

=cut

sub Form {
    # Get the parameters.
    my ($self) = @_;
    # Get the CGI and sprout objects.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Start the form.
    my $retVal = $self->FormStart("Signature Genes");
    # The bulk of this form will be two genome selection menus, one for the first
    # (target) set and one for the second (exclusion) set. Above these two controls
    # there is the selector for the given genome, the commonality and cutoff values,
    # and the submit button. Our first task, then, is to get the genome selection
    # menus.
    my $givenMenu   = $self->NmpdrGenomeMenu('given', 0, [$cgi->param('given')]);
    my $targetMenu  = $self->NmpdrGenomeMenu('target', 'multiple', [$cgi->param('target')], 10, 'exclusion');
    my $excludeMenu = $self->NmpdrGenomeMenu('exclusion', 'multiple', [$cgi->param('exclusion')], 10, 'target');
    # Get the default values to use for the commonality and cutoff controls.
    my $commonality = $cgi->param('commonality') || "0.8";
    my $cutoff = $cgi->param('cutoff') || "1e-10";
    my $statistical = $cgi->param('statistical') || 1;
    my $showMatch = $cgi->param('showMatch') || 0;
    my $useSims = $cgi->param('useSims') || 0;
    my $pegsOnly = $cgi->param('pegsOnly') || 1;
    # Now we build the table rows.
    my @rows = ();
    # First we have the given genome.
    push @rows, CGI::Tr(CGI::td({valign => "top"}, "Reference Genome"),
                         CGI::td({colspan => 2}, $givenMenu));
    # Now show the target and exclusion menus.
    push @rows, CGI::Tr(CGI::td({valign => "top"}, "Inclusion Genomes (Set 1)"),
                         CGI::td({colspan => 2}, $targetMenu));
    push @rows, CGI::Tr(CGI::td({valign => "top"}, "Exclusion Genomes (Set 2)"),
                         CGI::td({colspan => 2}, $excludeMenu));
    # Next, the tuning parameters.
    push @rows, CGI::Tr(CGI::td("Commonality"),
                         CGI::td(CGI::textfield(-name => 'commonality',
                                                  -value => $commonality,
                                                  -size => 5))),
                CGI::Tr(CGI::td(), CGI::td(join(" ",
                                  CGI::checkbox(-name => 'statistical',
                                                 -checked => $statistical,
                                                 -value => 1,
                                                 -label => 'Use Statistical Algorithm') .
                                  SearchHelper::Hint("SigGenes", 24),
                                  CGI::checkbox(-name => 'useSims',
                                                 -checked => $useSims,
                                                 -value => 1,
                                                 -label => 'Use Similarities') .
                                  SearchHelper::Hint("SigGenes", 25)))),
                CGI::Tr(CGI::td(), CGI::td(join(" ",
                                  CGI::checkbox(-name => 'showMatch',
                                                 -checked => $showMatch,
                                                 -value => 1,
                                                 -label => 'Show Matching Genes') .
                                  SearchHelper::Hint("SigGenes", 26)))),
                CGI::Tr(CGI::td("Cutoff"),
                         CGI::td(CGI::textfield(-name => 'cutoff',
                                                  -value => $cutoff,
                                                  -size => 5)));
    # Next, the feature filter rows.
    push @rows, RHFeatures::WordSearchRow($self);
    push @rows, RHFeatures::FeatureFilterFormRows($self);
    # Finally, the submit button.
    push @rows, $self->SubmitRow();
    # Create the table.
    $retVal .= $self->MakeTable(\@rows);
    # Close the form.
    $retVal .= $self->FormEnd();
    # Return the result.
    return $retVal;
}

=head3 Find

    my $resultCount = $shelp->Find();

Conduct a search based on the current CGI query parameters. The search results will
be written to the session cache file and the number of results will be
returned. If the search parameters are invalid, a result count of C<undef> will be
returned and a result message will be stored in this object describing the problem.

=cut

sub Find {
    # Get the parameters.
    my ($self) = @_;
    # Get the sprout and CGI query objects.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Declare the return variable. If it remains undefined, the caller will
    # assume there was an error.
    my $retVal;
    # Create the timers.
    my ($saveTime, $loopCounter, $bbhTimer, $putTimer, $queryTimer) = (0, 0, 0, 0, 0);
    # Validate the numeric parameters.
    my $commonality = $cgi->param('commonality');
    my $cutoff = $cgi->param('cutoff');
    if ($commonality !~ /^\s*\d(\.\d+)?\s*$/) {
        $self->SetMessage("Commonality value appears invalid, too big, negative, or not a number.");
    } elsif ($commonality <= 0 || $commonality > 1) {
        $self->SetMessage("Commonality cannot be 0 and cannot be greater than 1.");
    } elsif ($cutoff !~ /^\s*\d(.\d+)?(e\-\d+)?\s*$/) {
        $self->SetMessage("Cutoff must be an exponential number (e.g. \"1e-20\" or \"2.5e-11\".");
    } elsif ($cutoff > 1) {
        $self->SetMessage("Cutoff cannot be greater than 1.");
    } else {
        # Get the result helper.
        my $rhelp = RHFeatures->new($self);
        # Set up the default columns.
        $self->DefaultColumns($rhelp);
        # Add the score at the end.
        $rhelp->AddExtraColumn(score => undef, title => 'Score', style => 'rightAlign', download => 'num');
        # Find out if we need to show matching genes.
        my $showMatch = $cgi->param('showMatch') || 0;
        # If we do, add a column for them at the front.
        if ($showMatch) {
            $rhelp->AddExtraColumn(matches => 0, title => 'Matches', style => 'leftAlign', download => 'list');
        }
        # Only proceed if the filtering parameters are valid.
        if ($rhelp->Valid()) {
            # Now we need to gather and validate the genome sets.
            $self->PrintLine("Gathering the target genomes.  ");
            my ($givenGenomeID) = $self->GetGenomes('given');
            Trace("Given genome is $givenGenomeID.") if T(3);
            my %targetGenomes = map { $_ => 1 } $self->GetGenomes('target');
            Trace("Target genomes are " . join(", ", sort keys %targetGenomes) . ".") if T(3);
            $self->PrintLine("Gathering the exclusion genomes.  ");
            my %exclusionGenomes = map { $_ => 1 } $self->GetGenomes('exclusion');
            Trace("Exclusion genomes are " . join(", ", sort keys %exclusionGenomes) . ".") if T(3);
            $self->PrintLine("Validating the genome sets.<br />");
            # Insure the given genome is not in the exclusion set.
            if ($exclusionGenomes{$givenGenomeID}) {
                $self->SetMessage("The given genome ($givenGenomeID) cannot be in the exclusion set.");
            } else {
                # Start the output session.
                $self->OpenSession($rhelp);
                # Insure the given genome is in the target set.
                $targetGenomes{$givenGenomeID} = 1;
                Trace("$givenGenomeID added to target set.") if T(3);
                # Find out if we want to use a statistical analysis.
                my $statistical = $cgi->param('statistical') || 1;
                # Denote we have not yet found any genomes.
                $retVal = 0;
                # Compute the list of genomes of interest.
                my @allGenomes = (keys %exclusionGenomes, keys %targetGenomes);
                # Get the peg matrix.
                Trace("Requesting matrix.") if T(3);
                $saveTime = time();
                my $bbhMatrix;
                if (! $cgi->param('useSims')) {
                    # Here we are using BBHs, which are fast enough to do in one gulp.
                    $self->PrintLine("Requesting bidirectional best hits.  ");
                    $bbhMatrix = $sprout->BBHMatrix($givenGenomeID, $cutoff, @allGenomes);
                } else {
                    # Here we are using similarities, which are much more complicated.
                    $self->PrintLine("Requesting similarities.<br />");
                    # Create a filtering matrix for the results. We only want to keep PEGs in the
                    # specified target and exclusion genomes.
                    my %keepGenomes = map { $_ => 1 } @allGenomes;
                    # Loop through the given genome's features.
                    my @features = $sprout->FeaturesOf($givenGenomeID);
                    for my $fid (@features) {
                        $self->PrintLine("Retrieving similarities for $fid.  ");
                        # Get this feature's similarities.
                        my $simList = $sprout->Sims($fid, 1000, $cutoff, 'fig');
                        my $simCount = scalar @{$simList};
                        $self->PrintLine("Raw similarity count: $simCount.  ");
                        # Create the matrix hash for this feature.
                        $bbhMatrix->{$fid} = {};
                        # Now we need to filter out the similarities that don't land on the target genome.
                        $simCount = 0;
                        for my $sim (@{$simList}) {
                            # Insure this similarity lands on a target genome.
                            my $genomeID2 = $sprout->GenomeOf($sim->id2);
                            if ($keepGenomes{$genomeID2}) {
                                # Here we're keeping the similarity, so we put it in this feature's hash.
                                $bbhMatrix->{$fid}->{$sim->id2} = $sim->psc;
                                $simCount++;
                            }
                        }
                        $self->PrintLine("Similarities retained: $simCount.<br />");
                    }
                }
                $bbhTimer += time() - $saveTime;
                $self->PrintLine("Time to build matrix: $bbhTimer seconds.<br />");
                Trace("Matrix built.") if T(3);
                # Create a feature query object to loop through the chosen features of the given
                # genome.
                Trace("Creating feature query.") if T(3);
                $saveTime = time();
                my $fquery = $rhelp->GetQuery($givenGenomeID);
                $queryTimer += time() - $saveTime;
                # Get the sizes of the two sets. This information is useful in computing commonality.
                my $targetSetSize = scalar keys %targetGenomes;
                my $exclusionSetSize = scalar keys %exclusionGenomes;
                # Loop through the features.
                my $done = 0;
                while (! $done) {
                    # Get the next feature.
                    $saveTime = time();
                    my $record = $rhelp->Fetch($fquery);
                    $queryTimer += time() - $saveTime;
                    if (! $record) {
                        $done = 1;
                    } else {
                        # Get the feature's ID.
                        my $fid = $record->PrimaryValue('Feature(id)');
                        Trace("Checking feature $fid.") if T(4);
                        $self->PrintLine("Checking feature $fid.<br />");
                        # Get its list of matching genes. The list is actually a hash mapping each matched gene to its
                        # score. All we care about, however, are the matches themselves.
                        my $bbhList = $bbhMatrix->{$fid};
                        # We next wish to loop through the BBH IDs, counting how many are in each of the
                        # sets. If a genome occurs twice, we only want to count the first occurrence, so
                        # we have a hash of genomes we've already seen. The hash will map each gene ID
                        # to 0, 1, or 2, depending on whether it was found in the reference genome,
                        # a target genome, or an exclusion genome.
                        my %alreadySeen = ();
                        # Save the matching genes in here.
                        my %genesMatching = ();
                        # Clear the exclusion count.
                        my $exclusionCount = 0;
                        # Denote that we're in our own genome.
                        $alreadySeen{$givenGenomeID} = 0;
                        my $targetCount = 1;
                        # Loop through the BBHs/Sims.
                        for my $bbhPeg (keys %{$bbhList}) {
                            # Get the genome ID. We want to find out if this genome is new.
                            my $genomeID = $sprout->GenomeOf($bbhPeg);
                            if (! exists $alreadySeen{$genomeID}) {
                                # It's new, so we check to see which set it's in.
                                if ($targetGenomes{$genomeID}) {
                                    # It's in the target set.
                                    $targetCount++;
                                    $alreadySeen{$genomeID} = 1;
                                } elsif ($exclusionGenomes{$genomeID}) {
                                    # It's in the exclusion set.
                                    $exclusionCount++;
                                    $alreadySeen{$genomeID} = 2;
                                }
                                # Note that $alreadySeen{$genomeID} exists in the hash by this
                                # point. If it's 1, we need to save the current PEG.
                                if ($alreadySeen{$genomeID} == 1) {
                                    $genesMatching{$bbhPeg} = 1;
                                }
                            }
                        }
                        # Create a variable to indicate whether or not we want to keep this feature and
                        # another for the score.
                        my ($okFlag, $score);
                        # We need to see if we're using statistics or not. This only matters
                        # for a two-set situation.
                        if ($statistical && $exclusionSetSize > 0) {
                            # This is the magic formula for choosing the differentiating genes. It looks like
                            # it has something to do with variance computations, but I'm not sure.
                            my $targetNotCount = $targetSetSize - $targetCount;
                            my $targetSquare = $targetCount * $targetCount + $targetNotCount * $targetNotCount;
                            my $exclusionNotCount = $exclusionSetSize - $exclusionCount;
                            my $exclusionSquare = $exclusionCount * $exclusionCount + $exclusionNotCount * $exclusionNotCount;
                            my $mixed = $targetCount * $exclusionCount + $targetNotCount * $exclusionNotCount;
                            my $inD = 1 - (($exclusionSetSize * $mixed) / ($targetSetSize * $exclusionSquare));
                            my $outD = 1 - (($targetSetSize * $mixed) / ($exclusionSetSize * $targetSquare));
                            # If the two differentials are greater than one, we keep this feature.
                            $score = $inD + $outD;
                            $okFlag = ($score > 1);
                            # Subtract 1 from the score so it looks like the commonality score.
                            $score -= 1.0;
                        } else {
                            # Check to see if we're common in set 1 and not in set 2.
                            my $score1 = IsCommon($targetCount, $targetSetSize, $commonality);
                            my $score2 = IsCommon($exclusionCount, $exclusionSetSize, $commonality);
                            if ($score1 && ! $score2) {
                                # We satisfy the criterion, so we put this feature to the output. The
                                # score is essentially $score1, since $score2 is zero.
                                $score = $score1;
                                $okFlag = 1;
                            }
                        }
                        if ($okFlag) {
                            # Put this feature to the output. We have one or two extra columns.
                            # First we store the score.
                            $rhelp->PutExtraColumns(score => sprintf("%0.3f",$score));
                            # Next we add the list of matching genes, but only if "showMatch" is specified.
                            if ($showMatch) {
                                # The matching genes are in the hash "genesMatching".
                                my @genes = sort { FIGRules::FIGCompare($a,$b) } keys %genesMatching;
                                # We need to linkify them.
                                my $genesHTML = join(", ", map { HTML::fid_link($cgi, $_) } @genes);
                                # Now add them as an extra column.
                                $rhelp->PutExtraColumns(matches => $genesHTML);
                            }
                            # Compute a sort key from the feature data and the score.
                            my $sort = $rhelp->SortKey($record, sprintf("%0.3f", 1 - $score));
                            # Output the feature.
                            $saveTime = time();
                            $rhelp->PutData($sort, $fid, $record);
                            $putTimer += time() - $saveTime;
                            # Increase the result count.
                            $retVal++;
                        }
                        # Check for a timer trace. We trace every 500 features.
                        $loopCounter++;
                        if (T(3) && $loopCounter % 500 == 0) {
                            Trace("Time spent for $loopCounter features: Put = $putTimer, Query = $queryTimer, BBH = $bbhTimer.");
                        }
                    }
                }
                # Close the session file.
                $saveTime = time();
                $self->CloseSession();
                $putTimer += time() - $saveTime;
            }
        }
    }
    # Trace the timers.
    Trace("Time spent: Put = $putTimer, Query = $queryTimer, BBH = $bbhTimer.") if T(3);
    # Return the result count.
    return $retVal;
}

=head3 Description

    my $htmlText = $shelp->Description();

Return a description of this search. The description is used for the table of contents
on the main search tools page. It may contain HTML, but it should be character-level,
not block-level, since the description is going to appear in a list.

=cut

sub Description {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return "Search for genes that are common to a group of organisms or that discriminate between two groups of organisms.";
}

=head3 SearchTitle

    my $titleHtml = $shelp->SearchTitle();

Return the display title for this search. The display title appears above the search results.
If no result is returned, no title will be displayed. The result should be an html string
that can be legally put inside a block tag such as C<h3> or C<p>.

=cut

sub SearchTitle {
    # Get the parameters.
    my ($self) = @_;
    # Compute the title. We extract the relevant clues from the query parameters.
    my $cgi = $self->Q();
    my $type = ($cgi->param('useSims') ? "Similarities" : "Bidirectional Best Hits");
    my $style = ($cgi->param('exclusion') ? "Discriminating" : "Common");
    my $retVal = "$style Genes using $type";
    # Return it.
    return $retVal;
}

=head2 Internal Utilities

=head3 IsCommon

    my $score = SHSigGenes::IsCommon($count, $size, $commonality);

Return the match score if a specified count indicates a gene is common in a specified set
and 0 otherwise. Commonality is computed by dividing the count by the size of the set and
comparing the result to the minimum commonality ratio. The one exception is
if the set size is 0. In that case, this method always returns 0.

=over 4

=item count

Number of elements of the set that have the relevant characteristic.

=item size

Total number of elements in the set.

=item commonality

Minimum count/size ratio for the characteristic to be considered common.

=item RETURN

Returns TRUE if the characteristic is common, else FALSE.

=back

=cut

sub IsCommon {
    # Get the parameters.
    my ($count, $size, $commonality) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Only procced if the size is positive.
    if ($size > 0) {
        # Compute the commonality.
        $retVal = $count/$size;
        # If it's too small, clear it.
        if ($retVal < $commonality) {
            $retVal = 0;
        }
    }
    # Return the result.
    return $retVal;
}

1;
