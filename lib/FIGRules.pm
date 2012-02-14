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

package FIGRules;

use strict;
use BasicLocation;
use LWP::UserAgent;
use Sim;
use Tracer;
use Time::HiRes 'gettimeofday';
use POSIX;
use Digest::MD5;
use CGI;

=head1 FIG Rules Module

=head2 Introduction

This module contains methods that are shared by both B<FIG.pm> and B<Sprout.pm>.

=cut

#

=head2 Public Methods

=head3 NormalizeAlias

    my ($newAlias, $flag) = FIGRules::NormalizeAlias($alias);

Convert a feature alias to a normalized form. The incoming alias is examined to determine
whether it is a FIG feature name, a UNIPROT feature name, or a GenBank feature name. A
prefix is then applied to convert the alias to the form in which it occurs in the Sprout
database. The supported feature name styles are as follows.

C<fig|>I<dd..d>C<.>I<dd..d>C<.peg.>I<dd..d> where "I<dd..d>" is a sequence of one or more
digits, is a FIG feature name.

I<dd..dd> where "I<dd..d>" is a sequence of one or more digits, is a GenBank feature name.

I<XXXXXX> where "I<XXXXXX>" is a sequence of exactly 6 letters and/or digits, is a UNIPROT
feature name.

=over 4

=item alias

Alias to be converted to its normal form.

=item RETURN

Returns a two-element list. The first element (newAlias) is the normalized alias; the second
(flag) is 1 if the alias is a FIG feature name, 0 if it is not. Thus, if the flag value is
1, the alias will be expected in the B<Feature(id)> field of the Sprout data, and if it is
0, the alias will be expected in the B<Feature(alias)> field.

=back

=cut

sub NormalizeAlias {
    # Get the parameters.
    my ($alias) = @_;
    # Declare the return variables.
    my ($retVal,$flag);
    # Determine the type of alias.
    if ($alias =~ /^fig\|\d+\.\d+\.\w+\.\d+$/) {
        # Here we have a FIG feature ID.
        $retVal = $alias;
        $flag = 1;
    } elsif ($alias =~ /^\d+$/) {
        # Here we have a GenBank alias.
        $retVal = "gi|" . $alias;
        $flag = 0;
    } elsif ($alias =~ /^[A-Z0-9]{6}$/) {
        # Here we have a UNIPROT alias.
        $retVal = "uni|" . $alias;
        $flag = 0;
    } else {
        # Here we have an unknown alias type. We assumed that it does not require
        # normalization. (If it does, then additional ELSIF-cases need to be added
        # above.)
        $retVal = $alias;
        $flag = 0;
    }
    # Return the normalized alias and the flag.
    return ($retVal, $flag);
}

=head3 Upstream

    my $dna = FIGRules::Upstream($fig, $genome, $location, $upstream, $coding);

Return the DNA immediately upstream of a location. This method contains code lifted from
the C<upstream.pl> script.

=over 4

=item fig

FIG-like object that can be used to access DNA and feature data. For example, an
C<SFXlate> object or a true C<FIG> object.

=item genome

ID of the genome containing the location's contig.

=item location

Location string describing the location whose upstream data is desired, in the standard
form I<contig>C<_>I<beg>I<dir>I<end> used throughout FIG and Sprout.

=item upstream

Number of base pairs considered upstream.

=item coding

Number of base pairs inside the feature to be included in the upstream region.

=item RETURN

Returns the DNA sequence upstream of the location's begin point and extending into the coding
region. Letters inside a feature are in upper case and inter-genic letters are in lower case.
A hyphen separates the true upstream letters from the coding region.

=back

=cut
#: Return Type $;
sub Upstream {
    # Get the parameters.
    my ($fig, $genome, $location, $upstream, $coding) = @_;
    # Create a location object from the incoming location.
    my $locObject = BasicLocation->new($location);
    # Get the contig length.
    my $contig = $locObject->Contig;
    my $contig_ln = $fig->contig_ln($genome,$contig);
    # Get the endpoint of the coding region (if any).
    my $insideEnd = $locObject->Begin;
    if ($coding) {
        if ($coding < $locObject->Length) {
            $insideEnd += $coding;
        } else {
            $insideEnd = $locObject->EndPoint;
        }
    }
    # Save the begin point of the location.
    my $begin = $locObject->Begin;
    # Now get the upstream region.
    my $uLoc = $locObject->Upstream($upstream);
    # Pull its DNA. Note we take a precaution in case the upstream region is zero length.
    my $u_seq = ($uLoc->Length > 0 ? lc $fig->dna_seq($genome, $uLoc->SeedString) : "");
    # Get the coding region.
    my $c_seq = "";
    if ($coding) {
        $locObject->Truncate($coding);
        $c_seq = uc $fig->dna_seq($genome, $locObject->SeedString);
    }
    # Now we look for overlap in the upstream region. As a safety precaution, we only
    # do this if the upstream region has a nonzero length.
    if ($uLoc->Length > 0) {
        my (undef, $b_ov, $e_ov) = $fig->genes_in_region($genome,
                                                         $uLoc->Contig, $uLoc->Left, $uLoc->Right);
        # Now $b_ov through $e_ov is inside a gene. We want to uppercase this portion of the
        # upstream region. We only proceed if we found something.
        if ($b_ov && $e_ov) {
            # Compute the length of the overlap.
            my $overlap = $uLoc->Overlap($b_ov, $e_ov);
            # Only proceed if it's nonzero.
            if ($overlap > 0) {
                # Uppercase the overlapping part.
                my $u_over = uc substr($u_seq, 0, $overlap);
                $u_seq = $u_over . substr($u_seq, $overlap);
            }
        }
    }
    # Return the result.
    my $retVal = $u_seq . "-" . $c_seq;
    return $retVal;
}

=head3 FIGCompare

    my $cmp = FIGCompare($aPeg, $bPeg);

Compare two FIG IDs. This method is designed for use in sorting a list of FIG-style
feature IDs. For example, to sort the list C<@pegs>, you would use.

    my @sortedPegs = sort { &FIGCompare($a,$b) } @pegs;

=over 4

=item aPeg

First feature ID to compare.

=item bPeg

Second feature ID to compare.

=item RETURN

Returns a negative number if C<aPeg> should sort before C<bPeg>, a positive number if C<aPeg>
should sort after C<bPeg>, and zero if both should sort to the same place.

=back

=cut

sub FIGCompare {
    # Get the parameters.
    my($aPeg, $bPeg) = @_;
    # Declare the work variables.
    my($g1,$g2,$t1,$t2,$n1,$n2);
    # Declare the return variable.
    my $retVal;
    # The IF-condition parses out the pieces of the IDs. If both IDs are FIG IDs, then
    # the condition will match and we'll do a comparison of the pieces. If either one is
    # not a FIG ID, we'll do a strict string comparison. The FIG ID pieces are,
    # respectively, the Genome ID, the feature type, and the feature index number. These
    # are all dot-delimited, except that the genome ID already has a dot in it.
    if (($aPeg =~ /^fig\|(\d+\.\d+).([^\.]+)\.(\d+)$/) && (($g1,$t1,$n1) = ($1,$2,$3)) &&
    ($bPeg =~ /^fig\|(\d+\.\d+).([^\.]+)\.(\d+)$/) && (($g2,$t2,$n2) = ($1,$2,$3))) {
        $retVal = (($g1 <=> $g2) or ($t1 cmp $t2) or ($n1 <=> $n2));
    } else {
        $retVal = ($aPeg cmp $bPeg);
    }
    # Return the comparison indicator.
    return $retVal;
}

=head3 NetCouplingData

    my @data = FIGRules::NetCouplingData($function, %parms);

Request data from the PCH server. The PCH server takes as input a function and a
set of parameters, and returns one or more lines of tab-separated n-tuples. The
n-tuples are then parsed out and returned by this method in the form of a list.

=over 4

=item function

Name of the coupling function to invoke. These are C<coupled_to> to get a
list of coupled PEGs for a given PEG, C<coupling_evidence> for a list
of physically close homologs for a given pair of coupled PEGs, and
C<coupling_and_evidence> for a list of coupled PEGs, each with a
list of evidence.

=item parms

Hash of the parameters to pass, keyed by parameter name.

=item RETURN

Returns a list of n-tuples transmitted by the server.

=back

=cut

sub NetCouplingData {
    # Get the parameters.
    my($function, %parms) = @_;
    # Declare the return list.
    my @retVal = ();
    # Get the PCH server URL. This is normally in FIG_Config, but if not, we have
    # a default to fall back on.
    my $url = $FIG_Config::pch_server_url || "http://bioseed.mcs.anl.gov/simserver/perl/pchs.pl";
    # Send the request.
    my $ua = LWP::UserAgent->new();
    my $resp = $ua->post($url, { function => $function, %parms });
    # Check for a result.
    if ($resp->is_success) {
        # Here we got couplings, so we unspool them into the return list.
        my $dat = $resp->content;
        Trace(length($dat) . " bytes returned from coupling server.") if T(coupling => 3);
        # Loop through each line of text in the response.
        while ($dat =~ /([^\n]+)\n/g) {
            # Split this line into a coupled peg and a score.
            my @l = split(/\t/, $1);
            # Push it into the output list.
           push @retVal, \@l;
        }
    } else {
        # Here we failed to get a good response from the coupling server.
        warn "Failure response during network coupling function $function: " . $resp->content . "\n";
    }
    # Return the result.
    return @retVal;
}

=head3 ParseFeatureID

    my ($genomeID,$type,$pegNum) = FIGRules::ParseFeatureID($fid);

Parse out the components of a FIG feature ID.

=over 4

=item fid

FIG ID of a feature.

=item RETURN

Returns a three-element list consisting of the feature's parent genome ID, its
type, and its ID number.

=back

=cut

sub ParseFeatureID {
    # Get the parameters.
    my ($fid) = @_;
    # Declare the return variables.
    my ($genomeID, $type, $pegNum);
    # Attempt the parse.
    if ($fid =~ /^fig\|(\d+\.\d+).([^\.]+)\.(\d+)$/) {
        ($genomeID, $type, $pegNum) = ($1, $2, $3);
    }
    # Return the result.
    return ($genomeID, $type, $pegNum);

}

=head3 BBHData

    my $bbhList = FIGRules::BBHData($peg, $cutoff);

Return a list of the bi-directional best hits relevant to the specified PEG.

=over 4

=item peg

ID of the feature whose bidirectional best hits are desired.

=item cutoff

Similarity cutoff. If omitted, 1e-10 is used.

=item RETURN

Returns a reference to a list of 3-tuples. The first element of the list is the best-hit
PEG; the second element is the score. A lower score indicates a better match. The third
element is the normalized bit score for the pair, and is normalized to the length
of the protein.

=back

=cut
#: Return Type @@;
sub BBHData {
    my ($peg, $cutoff) = @_;
    my @retVal = ();
    my $ua = LWP::UserAgent->new();
    my $url = GetBBHServerURL();
    my $retries = 5;
    my $done = 0;
    my $resp;
    while ($retries > 0 && ! $done) {
        Trace("Requesting BBH data for $peg.") if T(nbbh => 3);
        $resp = $ua->post($url, { id => $peg, cutoff => $cutoff });
        if ($resp->is_success) {
            Trace("Successful response received from BBH request for $peg.") if T(nbbh => 3);
            my $dat = $resp->content;
            Trace("Processing " . length($dat) . " bytes of response data") if T(nbbh => 3);
            while ($dat =~ /([^\n]+)\n/g) {
                my @l = split(/\t/, $1);
                push @retVal, \@l;
            }
            $done = 1;
        } else {
            Trace("Retrying BBH request for $peg.") if T(nbbh => 3);
            $retries--;
        }
    }
    if (! $done) {
        Confess("Failure retrieving network coupling for $peg: " . $resp->status_line);
    }
    return \@retVal;
}

=head3 BatchBBHs

    my @bbhList = FIGRules::BatchBBHs($pattern, $cutoff, @targets);

Return a list of bidirectional best hits. The BBHs will be for features whose ID
matches the specified SQL pattern, are below a specified cutoff score, and
are in at least one of the specified target genomes. If no target genomes
are specified, all BBHs for matching features will be returned.

=over 4

=item pattern

SQL pattern to match against feature IDs. Generally, this will be either a real
feature ID or somthing like C<fig|100226.1.%> to get all features for a specified
genome.

=item cutoff

Maximum permissible score for a BBH to be returned.

=item targets

A list of zero or more genome IDs. Only BBHs that land in the target genomes will be
returned.

=item RETURN

Returns a list of 4-tuples. Each tuple will contain an originating feature ID,
a target feature ID, a P-score, and an N-score.

=back

=cut

sub BatchBBHs {
    # Get the parameters.
    my ($pattern, $cutoff, @targets) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Get the BBH server data.
    my $ua = LWP::UserAgent->new();
    my $url = GetBBHServerURL();
    my $retries = 5;
    my $done = 0;
    my $resp;
    # Find out if we're doing one feature or a bunch.
    my $is_pattern = ($pattern =~ /%/);
    # Format the target list.
    my $targets = join(",", @targets);
    # Loop until we get results.
    while ($retries > 0 && ! $done) {
        Trace("Requesting BBH data for $pattern.") if T(nbbh => 3);
        $resp = $ua->post($url, { id => $pattern, cutoff => $cutoff, targets => $targets });
        if ($resp->is_success) {
            Trace("Successful response received from BBH request for $pattern.") if T(nbbh => 3);
            my $dat = $resp->content;
            while ($dat =~ /([^\n]+)\n/g) {
                # A little goofiness is required in case we're getting 3-tuples.
                my @l = ();
                if (! $is_pattern) {
                    push @l, $pattern;
                }
                push @l, split(/\t/, $1);
                push @retVal, \@l;
            }
            $done = 1;
        } else {
            Trace("Retrying BBH request for $pattern.") if T(nbbh => 3);
            $retries--;
        }
    }
    if (! $done) {
        Confess("Failure retrieving network BBHs for $pattern: " . $resp->status_line);
    }
    return @retVal;
}

=head3 GetBBHServerURL

    my $url = FIGRules::GetBBHServerURL();

Return the URL of the BBH server.

=cut

sub GetBBHServerURL {
    # Find the server.
    my $retVal = $FIG_Config::bbh_server_url || "http://bioseed.mcs.anl.gov/simserver/perl/bbhs.pl";
    # Return the result.
    return $retVal;
}

=head3 GetNetworkSims

    my $sims = FIGRules::GetNetworkSims($fig, $id, \%seen, $maxN, $maxP, $select, $max_expand, $filters);

Retrieve similarities from the network similarity server. The similarity retrieval
is performed using an HTTP user agent that returns similarity data in multiple
chunks. An anonymous subroutine is passed to the user agent that parses and
reformats the chunks as they come in. The similarites themselves are returned
as B<Sim> objects. Sim objects are actually list references with 15 elements.
The Sim object methods allow access to the elements by name.

Similarities can be either raw or expanded. The raw similarities are basic
hits between features with similar DNA. Expanding a raw similarity drags in any
features considered substantially identical. So, for example, if features B<A1>,
B<A2>, and B<A3> are all substatially identical to B<A>, then a raw similarity
B<[C,A]> would be expanded to B<[C,A] [C,A1] [C,A2] [C,A3]>.

Specify the trace type C<nsims> to trace this method.

=over 4

=item fig

An object that supports the C<is_deleted_fid> method to determine whether or not
a feature exists in the data store, or a raw Sprout object.

=item id

ID of the feature whose similarities are desired, or reference to a list
of the IDs of the features whose similarities are desired.

=item seen

Reference to a hash keyed by feature ID that returns a value of C<1> for features
to be discarded when constructing the return list. This parameter is provided so
that the caller can avoid doing any hard work on similarities that are already
known.

=item maxN

Maximum number of similarities to return.

=item maxP

The maximum allowable similarity score.

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

sub GetNetworkSims {
    # Get the parameters.
    my($fig, $id, $seen, $maxN, $maxP, $select, $max_expand, $filters) = @_;
    # Get the URL for submitting to the sims server.
    #my $url = "http://bio-ppc-head-2/~olson/FIG/perl/sims.cgi"; #TODO: put in FIG_Config
    my $url = "http://bioseed.mcs.anl.gov/simserver/perl/sims.pl"; #TODO: put in FIG_Config
    #my $url = "http://xenophilus.nmpdr.org/ss/sims.pl"; #TODO: put in FIG_Config

    if ($FIG_Config::sim_server_url ne '')
    {
	$url = $FIG_Config::sim_server_url;
	# warn "Using $url\n";
    }

    # Get a list of the IDs to process.
    my @ids;
    if (ref($id) eq "ARRAY") {
        @ids = @$id;
    } else {
        @ids = ($id);
    }
    # Form a list of the parameters to pass to the server.
    my %args = ();
    $args{id} = \@ids;
    $args{maxN} = $maxN if defined($maxN);
    $args{maxP} = $maxP if defined($maxP);
    $args{select} = $select if defined($select);
    $args{max_expand} = $max_expand if defined($max_expand);
    # If the filter is a hash, put the filters in the argument list.
    if (ref($filters) eq 'HASH') {
        for my $k (keys(%$filters))
        {
            $args{"filter_$k"}= $filters->{$k};
        }
    }
    # Dump the request data.
    if (T(nsims => 3)) {
        for my $arg (keys %args) {
            if (ref $args{$arg} eq 'ARRAY') {
                Trace("Request argument $arg has " . scalar(@{$args{$arg}}) . " values.");
            } else {
                Trace("Request argument $arg = $args{$arg}");
            }
        }
    }
    # Get the user agent.
    my $ua = LWP::UserAgent->new();
    #
    # Our next task is to create the anonymous subroutine that will process the
    # chunks that come back from the server. We require three global variables:
    # @sims to hold the similarities found, $tail to remember the unprocessed
    # data from the previous chunk, and $chunks to count the chunks.
    #
    my @sims;
    my $tail;
    my $chunks = 0;
    #
    # ANONYMOUS SUBROUTINE
    #
    my $isSprout = ref($fig) eq 'Sprout';
    my $cb = sub {
        eval {
            # Get the parameters.
            my ($data, $command) = @_;
            # Determine the type of the fig object.
            # Check for a reset command. If we get one, we discard any data
            # in progress.
            if ($command && $command eq 'reset') {
#                Trace("Reset command received by nsims CB method.") if T(nsims => 4);
                $tail = '';
            } else {
                $chunks++;
#               Trace("Data chunk $chunks received.") if T(nsims => 3);
#		Trace("chunk data: $data") if T(nsims => 4);
                # Get the data to process. Note we concatenate it to the incoming
                # tail from last time.
                my $c = $tail . $data;
                # Make sure the caller hasn't messed up the new-line character.
                # FASTA readers in particular are notorious for doing things
                # like that.
                local $/ = "\n";
                # Split the input into lines.
                my @lines = split(/\n/, $c);
                # If the input does not end with a new-line, we have a partial
                # chunk and need to put it in the tail for next time. If not,
                # there is no tail for next time.
                if (substr($c, -1, 1) ne "\n") {
                    $tail = pop @lines;
#                    Trace("Tail for next iteration is: $tail") if T(nsims => 4);
                } else {
                    $tail = '';
                }
                # Loop through the lines. Note there's no need to chomp because
                # the SPLIT took out the new-line characters.
                for my $l (@lines) {
                    # Split the line into fields.
                    my @s = split(/\t/, $l);
                    # Insure we have all the fields we need.
                    if (@s < 9) {
#                        Trace("Insufficient fields in line $l.") if T(nsims => 1);
                    } else {
                        # Check to see if we've seen this SIM before.
                        my $id1 = $s[0];
                        my $id2 = $s[1];
#                        my $deleted = ($isSprout ? ! $fig->Exists(Feature => $id2) : $fig->is_deleted_fid($id2));
#                        if ($deleted) {
#                            Trace("Deleted feature $id2 ignored in sim list for $id1.") if T(nsims => 4);
#                            $deleted_fids++;
#                       } elsif ($seen->{$id1,$id2}) {
#                        if ($seen->{$id1,$id2}) {
#                            Trace("Similarity ($id1,$id2) ignored: redundant.") if T(nsims => 4);
#                        } else {
                            # Insure we don't use this similarity again.
#                            $seen->{$id1,$id2} = 1;
                            # Add it to the result list.
                            push(@sims, bless \@s, 'Sim');
#                        }
                    }
                }
            }
        };
        if ($@) {
            Trace("Network sims request failed with error: $@") if T(nsims => 0);
        }
    };
    #
    #   END OF ANONYMOUS SUBROUTINE
    #
    # Now we're ready to start. Because networking is an iffy thing, we set up
    # to try our request multiple times.
    my $n_retries = 10;     # TODO: put in FIG_Config
    my $attempts = 0;
    # Set the timeout value, in seconds.
    $ua->timeout(180);      # TODO: put in FIG_Config
    # Loop until we succeed or run out of retries.
    my $done = 0;
    while (! $done && $attempts++ < $n_retries) {
        # Reset the content processor. This clears the tail.
        &$cb(undef, 'reset');
        Trace("Sending request to $url.") if T(nsims => 3);
        my $resp = $ua->post($url, \%args, ':content_cb' => $cb);
        if ($resp->is_success) {
            # If the response was successful, get the content. This triggers
            # the anonymous subroutine.
            Trace("Processing similarity results.") if T(nsims => 3);
            my $x = $resp->content;
            Trace("Response content is:\n$x") if T(nsims => 4);
            # Denote we've been successful.
            $done = 1;
        } else {
            Trace("Error getting sims (attempt $attempts of $n_retries): " . $resp->status_line) if T(nsims => 1);
        }
    }
    # Declare the return variable.
    my $retVal;
    if (! $done) {
        # Here we failed.
        Trace("Could not get network sims after $attempts retries; request url is $url.") if T(nsims => 0);
        # Denote we got no results.
        $retVal = undef;
    } else {
        # Here everything worked, but note we may not have received any sims! If that's the case,
        # the return value will be a reference to an empty list as opposed to C<undef>.
        Trace(scalar(@sims) . " sims and $chunks chunks received from network.") if T(nsims => 3);
        $retVal = \@sims;
    }
    return $retVal;
}

=head3 wikipedia_link

    my $url = FIGRules::wikipedia_link($organism_name);

Return the URL of a Wikipedia page for the specified organism,
or C<undef> if no Wikipedia page exists.

=over 4

=item organism_name

Word or phrase to look for in Wikipedia.

=item RETURN

Returns the Wikipedia URL for the specified organism, or C<undef> if no Wikipedia
page for the organism exists.

=back

=cut

sub wikipedia_link {
  my ($organism_name) = @_;

  my $link = undef;
  my @organism_tokens = split(/\s/, $organism_name);
  my $wikipedia_url = "http://en.wikipedia.org/wiki/";
  my $curr_link = $wikipedia_url . $organism_tokens[0];
  if (scalar(@organism_tokens) > 1) {
    $curr_link .= "_" . $organism_tokens[1];
  }

  my $ua = new LWP::UserAgent;

  my $res = $ua->get($curr_link);
  if (not $res->is_success) {
#    print STDERR "Could not access Wikipedia\n";
    return undef;
  }
  my $page = $res->content;

  if ($page =~ /Wikipedia does not have an article with this exact name/) {
    $curr_link = $wikipedia_url . $organism_tokens[0];
    $res = $ua->get($curr_link);
    $page = $res->content;
    if ($page =~ /Wikipedia does not have an article with this exact name/) {
      $link = undef;
    } else {
      $link = $curr_link;
    }
  } else {
    $link = $curr_link;
  }

  return $link;
}

=head3 ParseFasta

    my ($title, $sequence) = FIGRules::ParseFasta($string);

Convert the specified FASTA-like string into a sequence and a title. Spaces and
newlines will have been deleted from the string, and if no title is present one
will be created automatically. In addition, any digits will have been removed,
which allows people to paste sequences in directly from the NCBI.

=over 4

=item string

Incoming string. This may be a string of letters with scattered white space,
or it may be a real FASTA string.

=item RETURN

Returns a list containing a title (with the little ">") and a string of
letters.

=back

=cut

sub ParseFasta {
    # Get the parameters.
    my ($string) = @_;
    # Declare the return variables.
    my ($title, $sequence);
    # Check for a title.
    if ($string =~ /^>(.+?)[\r\n]+(.+)/s) {
        # Yes, we have the title.
        ($title, $sequence) = ($1, $2);
    } else {
        # No title, so make one up.
        $title = ">UnlabeledSequence";
        $sequence = $string;
    }
    # Clean up the sequence.
    $sequence =~ s/\s+|\d+//g;
    # Return the results.
    return ($title, $sequence);
}




=head3 SortedFids

    my @fids = FIGRules::SortedFids(@fidList);

Convert a list of feature IDs to a sorted list with duplicates removed.

=over 4

=item fidList

A list of feature IDs.

=item RETURN

Returns the original list, sorted in feature order with no duplicates.

=back

=cut

sub SortedFids {
    # Get the features.
    my %fids = map { $_ => 1 } @_;
    # Return them in sorted order.
    return sort { &FIGCompare($a, $b) } keys %fids;
}

=head3 EncodeScore

    my $scoreString = FIGRules::EncodeScore($score);

Convert a BLAST score to a sortable string. The sortable string will float lower
scores to the beginning, and is a fixed-length string so that there are no
comparison anomalies.

=over 4

=item score

Floating-point score to convert to a string. It must be a value greater than or equal
to zero and less than 1.

=item RETURN

Sortable string created from the incoming score.

=back

=cut

sub EncodeScore {
    # Get the parameters.
    my ($score) = @_;
    # Declare the return value.
    my $retVal;
    # Validate the value.
    if ($score < 0 || $score >= 1) {
        Confess("Invalid score $score. Scores must be in the range [0,1).");
    } elsif ($score == 0) {
        # The arithmetic used to convert the score doesn't work for 0, so we
        # have to do it by hand.
        $retVal = "000.000";
    } else {
        # Compute the exponent.
        my $expo = POSIX::floor(log($score)/log(10));
        # Add it to 1000 so that it sorts correctly. (Note that we are guaranteed its negative
        # by the input restriction.
        my $normalizedExpo = 1000 + $expo;
        # Compute the three-digit mantissa. We divide the score by 10 to the power of expo.
        my $mant = $score / "1e$expo";
        # We have successfully normalized the exponent out of the mantissa. Now multiply
        # by 100 and truncate to get a 3-digit value.
        $mant = int($mant * 100);
        # Compute the return string.
        $retVal = "$normalizedExpo.$mant";
    }
    # Return the result to the caller.
    return $retVal;
}

=head3 DecodeScore

    my $score = FIGRules::DecodeScore($scoreString);

Convert a sortable score string to a real score. The sortable score string
is of the form I<XXX>C<.>I<YYY> where I<XXX> is the exponent subtracted from
1000 and I<YYY> is the mantissa multiplied by 100. So, for example, an
incoming value of 987.810 turns out to be 8.1e-13.

=over 4

=item scoreString

Sortable string encoding a BLAST score.

=item RETURN

The BLAST score corresponding to the sortable string, or C<undef> if the string is invalid.

=back

=cut

sub DecodeScore {
    # Get the parameters.
    my ($scoreString) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Parse the string.
    if ($scoreString =~ /^0+\.0+$/) {
        # This is the special value for 0.
        $retVal = 0;
    } elsif ($scoreString =~ /(\d+)\.(\d+)/) {
        # Here we have an ordinary score. Compute the
        # exponent from the first part.
        my $expo = $1 - 1000;
        # Compute the mantisa from the second part. We need to boost it to three digits.
        my $mantDigits = $2;
        $mantDigits .= '0' while length($mantDigits) < 3;
        my $mant = $mantDigits/100;
        # Convert it to a number.
        $retVal = 0.0 + "${mant}e$expo";
    }
    # Return the result.
    return $retVal;
}

=head3 NewSessionID

    my $id = FIGRules::NewSessionID();

Generate a new session ID for the current user.

=cut

sub NewSessionID {
    # Declare the return variable.
    my $retVal;
    # Get a digest encoder.
    Trace("Retrieving digest encoder.") if T(3);
    my $md5 = Digest::MD5->new();
    # Add the PID, the IP, and the time stamp. Note that the time stamp is
    # actually two numbers, and we get them both because we're in list
    # context.
    Trace("Assembling pieces.") if T(3);
    $md5->add($$, $ENV{REMOTE_ADDR}, $ENV{REMOTE_PORT}, gettimeofday());
    # Hash up all this identifying data.
    Trace("Producing result.") if T(3);
    $retVal = $md5->hexdigest();
    # Return the result.
    return $retVal;
}

=head3 GetTempFileName

    my $fileName = FIGRules::GetTempFileName(%options);

Return a temporary file name. The file name will consist of a long, hashed-up hex
string followed by a file name extension, and it will be in the FIG temporary
directory. This method accepts a single hash as a parameter, with the following
possible options.

=over 4

=item sessionID

A string that may be used to generate a unique file name. If none is specified,
a string will be generated using the </NewSessionID> method.

=item extension

The name to be used for the file extension. If none is specified, the extension
will be C<tmp>.

=back

=cut

sub GetTempFileName {
    # Get the parameters.
    my (%options) = @_;
    # Declare the return variable.
    my $retVal;
    # Insure we have a session ID.
    my $sessionID;
    if (exists $options{sessionID}) {
        $sessionID = $options{sessionID};
    } else {
        $sessionID = NewSessionID();
    }
    # Insure we have an extension.
    my $extension;
    if (exists $options{extension}) {
        $extension = $options{extension};
    } else {
        $extension = 'tmp';
    }
    # Return the file name.
    return "$FIG_Config::temp/tmp_$sessionID.$extension";
}

=head3 ComputeEol

    my $eol = FIGRules::ComputeEol($osType);

Compute the correct end-of-line character for the specified operating system.

=over 4

=item osType

Operating system type, currently either C<MacIntosh>, C<Windows>, or C<Unix>.

=item RETURN

Returns the end-of-line character string for the specified operating system. If the operating
system name is not recognized, C<\n> will be assumed.

=back

=cut

sub ComputeEol {
    # Get the parameters.
    my ($osType) = @_;
    # Declare the return variable.
    my $retVal;
    # Compute the EOL string.
    if ($osType eq 'Windows') {
        $retVal = "\r\n";
    } elsif ($osType eq 'MacIntosh') {
        $retVal = "\r";
    } else {
        $retVal = "\n";
    }
    # Return it.
    return $retVal;
}

=head3 nmpdr_mode

    my $flag = FIGRules::nmpdr_mode($cgi);

Return TRUE if this is the NMPDR environment and FALSE otherwise. An
NMPDR environment is possible only if the NMPDR variables exist in
FIG_Config. Otherwise, if a CGI object is specified or there is an
HTTP_HOST provided in the environment variables, we look for a cookie
named C<SPROUT> and check its value. If there is no CGI object
or no HTTP_HOST provided in the environment variables, we look for a
value for the C<SPROUT> environment variable and return that. If none of
these methods work, we return the value of the C<FIG_Config::nmpdr_mode>
variable.

What this means is that each FIG installation has a default mode-- NMPDR
or SEED-- based on its FIG_Config. For a command-line script, this mode
can be overridden by an environment variable. For a CGI script, this mode
can be overridden by a cookie.

Note that currently NMPDR mode determines our style of display and whether
or not the data is coming from Sprout. This may not always be the case,
in which case we'll have some serious updating to do.

=over 4

=item cgi (optional)

CGI object used to access query parameters. If no object is specified and
we are running or emulating a web script, one will be created and
interrogated. Otherwise, it will be assumed we are running a command-line
script and the CGI object will not be used.

=item RETURN

Returns TRUE if this is Sprout/NMPDR, else FALSE.

=back

=cut

sub nmpdr_mode {
    # Get the parameters.
    my ($cgi) = @_;
    # Declare the return variable.
    my $retVal;
    # Determine the mode: command-line or CGI.
    if (defined($cgi) || exists $ENV{HTTP_HOST}) {
        # Here we're in CGI mode. Insure we have a CGI object.
        if (! defined($cgi)) { $cgi = CGI->new(); }
        # Check for the SPROUT cookie.
        my $sprout = $cgi->cookie('SPROUT');
        if (defined $sprout) {
            # If it's found, we check its value. A value of "Sprout" means
            # sprout mode. Anything else is SEED mode.
            $retVal = ($sprout =~ /sprout/i);
            Trace("SPROUT cookie value $sprout used: returning $retVal.") if T(4);
        }
    } else {
        # Here we're in command-line mode. Check for an environment
        # variable.
        if (exists $ENV{SPROUT}) {
            # We found one, so we use its value.
            $retVal = $ENV{SPROUT};
            Trace("SPROUT environment variable value $retVal used.") if T(4);
        }
    }
    # If we do not yey have a return value, we use the value from FIG_Config.
    if (! defined $retVal) {
        $retVal = ($FIG_Config::nmpdr_mode ? 1 : 0);
        Trace("FIG_Config mode value $retVal used.") if T(4);
    }
    # Return the result.
    return $retVal;
}

=head3 GetHopeReactions

    my $reactionHash = FIGRules::GetHopeReactions($subsysObject, $directory);

This method returns a reference to a hash that maps each subsystem role
to a list of EC numbers representing Hope reactions. These reactions are
useful in analyzing scenarios.

=over 4

=item subsysObject

B<Subsystem> or B<SproutSubsys> object for the subsystem in question.

=item directory

Directory for the subsystem in the FIG disk cluster.

=item RETURN

Returns a reference to a hash that maps role names to lists. The list for
each role name contains the EC numbers for that role's Hope reactions.

=back

=cut

sub GetHopeReactions {
    # Get the parameters.
    my ($subsysObject, $directory) = @_;
    # Declare the return variable.
    my $retVal = {};
    # Only proceed if a hope reactions file exists.
    my $hopeFileName = "$directory/hope_reactions";
    if (-f $hopeFileName) {
        # Open the hope reaction file.
        my $hope_fh = Open(undef, "<$hopeFileName");
        # Loop through the hope reaction file.
        while (defined($_ = <$hope_fh>)) {
            # Parse out the role and the reaction list.
            if ($_ =~ /^(\S.*\S)\t(\S+)/) {
                my ($role, $reactions) = ($1, $2);
                # Insure the role is in this subsystem.
                my $ridx = $subsysObject->get_role_index($role);
                if (defined $ridx && $ridx >= 0) {
                    # Yes, put the reactions in the list for the role.
                    push(@{$retVal->{$role}},split(/,\s*/,$reactions));
                } else {
                    Trace("Ignoring obsolete role '$role' for " . $subsysObject->get_name .
                    "ridx = " . Tracer::Quoted($ridx) . ".") if T(1);
                }
            }
        }
        close($hope_fh);
    }
    # Return the result.
    return $retVal;
}

=head3 robot_mode

    my $flag = FIGRules::robot_mode($cgi);

Return TRUE if the current user is a recognized robot, else FALSE. Note
that if the C<Robot> cookie is present and has a TRUE value, this method
will also return TRUE.

Use of the site by search engine robots is important in order to bring
in traffic; however, they can also put a strain on the server. CGI scripts
can use this method to determine if the current user agent is a search
engine robot and, if so, produce a lightweight version of the page that
has fewer fancy charts and graphs. This provides the search engines with
the information needed to index the page without putting a strain on the
server.

If the user agent is not one of the preferred search engine robots,
then a C<noindex, nofollow> tag is put in the header. This will have
no effect on human users, but robots will read the header and stop
trying to index the site.

=over 4

=item cgi

CGI query object for the current session.

=item RETURN

Returns TRUE if the user agent in the CGI object is a search engine robot
that deserves special treatment, else FALSE.

=back

=cut

sub robot_mode {
    # Get the parameters.
    my ($cgi) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a robot cookie.
    if ($cgi->cookie('Robot')) {
        $retVal = 1;
        Trace("Robot mode selected via cookie.") if T(CGI => 3);
    } else {
        my $agt = lc($ENV{"HTTP_USER_AGENT"});
        if (($agt =~ /googlebot/) ||
            ($agt =~ /yahoo/) ||
            ($agt =~ /spiderman/) ||
            ($agt =~ /msnbot/) ||
            ($agt =~ /crawler/) ||
            ($agt =~ /altavista/) ||
            ($agt =~ /ask jeeves/) ||
            ($agt =~ /lycos/) ||
            ($agt =~ /accoona/) ) {
          $retVal = 1;
          Trace("Robot mode selected for $agt.") if T(CGI => 3);
        } else {
          $retVal = 0;
          Trace("Human mode selected for $agt.") if T(CGI => 4);
        }
    }
    # Return the result.
    return $retVal;
}

=head3 LogRobot

    FIGRules::LogRobot($cgi);

Create a feed event for the current web page if this user is a robot.

=over 4

=item cgi

CGI object describing the current web request.

=back

=cut

sub LogRobot {
    # Get the parameters.
    my ($cgi) = @_;
    # Is this a robot and are we tracking them?
    if (robot_mode($cgi) && $FIG_Config::robot_feed) {
        # Yes.
        my $event = "Robot detected.";
        # Check the system load.
        if ($FIG_Config::load_feed) {
            my ($loadString) = `$FIG_Config::load_feed`;
            if ($loadString) {
                $event .= " $loadString";
            }
        }
        Warn($event, qw(noStack)) if T(Robot => 0);
    }
}



=head3 to_structured_english

    my ($ev_code_list, $subsys_list, $english_string) = FIGRules::to_structured_english($fig, $peg, $escape_flag);

Create a structured English description of the evidence codes for a PEG,
in either HTML or text format. In addition to the structured text, we
also return the subsystems and evidence codes for the PEG in list form.

=over 4

=item fig

A FIG-like object for accessing the data store.

=item peg

ID of the protein or feature whose evidence is desired.

=item escape_flag

TRUE if the output text should be HTML, else FALSE

=item RETURN

Returns a three-element list. The first element is a reference to a list of evidence codes,
the second is a list of the subsystem containing the peg, and the third is the readable
text description of the evidence.

=back

=cut

sub to_structured_english {
    my($self,$peg, $escaped, %options ) = @_;
    my $fig = $self;

#1) With dlits:    "The characterization of essentially identical proteins has been discussed in 
#pubmed1 [, pubmed2,... and pubmedn]"  Where the pubmed IDs are links

#2) With ilits:     "The characterization of proteins implementing this function was done in 
#GenusSpecies1 [, GenusSpecies2, ... and GenusSpecies3].  We believe that this protein is an 
#isofunctional homolog of these characterized proteins."

# GenusSpeciesn should not be the whole string returned by $fig->genus_species($genome) -- use only the first two words.

    my @ev_codes = &evidence_codes($fig,$peg);
    if (!@ev_codes) {return ("", "", "");}
    my $by_sub = {};
    my $ilit = {};
    my $dlit = {};
    
    # for testing
    #push (@ev_codes, "dlit(8332479);gj");
    #push (@ev_codes, "dlit(1646786);gj");
    #push (@ev_codes, "ilit(1646786);fig|351605.3.peg.2740");
    #push (@ev_codes, "ilit(8332479);fig|351605.3.peg.2740");
    #push (@ev_codes, "ilit(1646787);fig|224308.1.peg.2273");
    #push (@ev_codes, "ilit(1646787);fig|192222.1.peg.543");

    foreach my $code (@ev_codes)
    {
	if ($code =~ /^isu;(\S.*\S)/)                { $by_sub->{$1}->{'isu'} = 1  }
	if ($code =~ /^icw\((\d+)\);(\S.*\S)/)       { $by_sub->{$2}->{'icw'} = $1 }
	if ($code =~ /^ilit\((\d+)\);(\S.*\S)/)       {
		my $gs = &get_gs($fig, $2);
#		print STDERR "GS = $gs\n";
		unless (exists $ilit->{$gs}) { $ilit->{$gs} = [];}
		push(@{$ilit->{$gs}}, $1);
	} 
	if ($code =~ /^dlit\((\d+)\);(\S.*\S)/)        { $dlit->{$1} = 1 }
    }

     $peg =~ /^fig\|(\d+\.\d+)\.peg\.\d+$/;
     my $genome = $1;


    my @newsubs = grep { $fig->usable_subsystem($_,1) } $fig->peg_to_subsystems($peg,1,1);

    # The need for the following block of code is removed by the new active-only flag
    # passed to peg_to_subsystems.

#     my @insubs = ();
#     foreach my $sub (@newsubs) {
#             my $ss = $fig->get_subsystem($sub);
# 	    my $idx = $ss->get_genome_index($genome);
# 	    my $vc = $ss->get_variant_code($idx);
# 	    if ($vc ne "-1" && $vc ne "0") {
# 	    #if ($vc > 0) {
# 	    	push (@insubs, $sub);
# 	    }	
#     }
    my @insubs = @newsubs;

    #my @insubs = grep { $fig->usable_subsystem($_,1) } $fig->peg_to_subsystems($peg,1);
    my %subs = map { $_ => 1 } @insubs;
    my $funcSeed = $fig->function_of($peg,undef,1);
#    if (@insubs < 1) { return ("", "", "") }

    my $pieces = [];
    &add_func_assertion($pieces,$funcSeed);
    &add_in_subs($pieces,\@insubs);
    my @sub_numbers;

    foreach my $sub (@insubs)
    {
    #print STDERR "Sub = $sub\n";
	&add_clustering_and_dup($pieces,$by_sub->{$sub},$sub);
	if (!$options{-skip_registered_ids})
	{
	    push(@sub_numbers, "SS:".$fig->clearinghouse_register_subsystem_id($sub));
	}
    }

     my @keys =  keys(%$dlit);
     if (@keys) {
    	make_dlit_text($pieces, @keys);
    }
    if (keys(%$ilit)) {
	    make_ilit_text($pieces, $ilit); 
    }

    return join(",", @ev_codes), join(",", @sub_numbers), &render($pieces, $escaped);
}

sub get_gs {
	my ($fig, $peg) = @_;

	$peg =~ /^fig\|(\d+\.\d+)\.peg\.\d+$/;
	my $gs = $fig->genus_species($1);
	my @words = split /\s+/, $gs;
	if (@words)  {
		$gs = $words[0];
		if (@words > 1)  {
			$gs .= " $words[1]";
		}
	}
	return($gs);
}

sub render {
    my $cgi = new CGI;
    my($pieces, $escaped) = @_;

    my @lines = ();
    my $curr  = "";
    foreach my $piece (@$pieces)
    {
	$piece = "$piece  ";
	$curr = $curr . $piece;

	while (length($curr) > 100)
	{
	    my($p1,$p2) = &split_piece($curr,100);
	    $p1 =~ s/^\s+//;
	    push(@lines, $p1);
	    $curr = $p2;
	}
    }
    if ($curr) 
    { 
	$curr =~ s/^\s+//; 
	push(@lines,$curr) ;
    }

    if ($escaped) {
    	return  $cgi->escape(join("\n",@lines) . "\n");
    } else {
    	return (join("\n",@lines) . "\n");

    }
}

sub split_piece {
    my($piece,$n) = @_;

    my $i;
    for ($i = $n; ($i > 0) && (substr($piece,$i,1) ne " "); $i--) {}
    if ($i)
    {
	return (substr($piece,0,$i+1),substr($piece,$i+1));
    }
    else
    {
	return ($piece,"");
    }
}

sub make_dlit_text {
	my ($pieces, @dlit) = @_;

	#my $text = "The characterization of essentially identical proteins has been discussed in ".&make_pubmed_link($dlit[0]);
	my $text = "The function of this gene is asserted in ".&make_pubmed_link($dlit[0]);
	shift(@dlit);
	if (@dlit) {
		my $size = @dlit;
		
		while (--$size) {
			my $p = shift(@dlit);
			$text = $text.", ".&make_pubmed_link($p);
		}
		if (@dlit) {
			$text = $text." and ".&make_pubmed_link($dlit[0]);
		}
	}	
	$text .= ".";
	push (@$pieces, $text);
}


sub make_ilit_text {
	my ($pieces, $ilit) = @_;

       my  @keys =  keys(%$ilit);
	my $filler = "";
	#my $text = "The characterization of proteins implementing this function was done in ";
	#my $text = "The function of genes we believe play the same functional roles have been described in ";
	my $text = "The function of genes having the same functional roles have been described in ";
	my $key = shift(@keys);
	$text .= $key.&make_pubmed_list($ilit->{$key});

	if (@keys) {
		$filler.="These are homologous proteins which implement"; 
		my $size =  @keys;
		while(--$size) {
			$key = shift(@keys);
			$text .= ", ".$key.&make_pubmed_list($ilit->{$key});
		}
		if (@keys) {
			$key = shift(@keys);
			$text = $text." and ".$key.&make_pubmed_list($ilit->{$key});
		}	
	} else {	
		$filler.="This is a homologous protein which implements"; 
	}


	#$text = $text.".  We believe that $filler the same function.";
	$text = $text.".  $filler the same function.";
	push (@$pieces, $text);

}

sub make_pubmed_list {

	my ($plst) = @_;

	my $text = " (";
	foreach my $pub (@$plst) {
#		print STDERR $pub, "\n";
		$text .= make_pubmed_link($pub).", ";
	}
	$text =~s/, $/)/;
	return($text);
}


sub make_pubmed_link {
	my ($pubmed) = @_;
	return "<a href='http://www.ncbi.nlm.nih.gov/sites/entrez?cmd=Retrieve&db=PubMed&list_uids=$pubmed&dopt=AbstractPlus' target='_blank'>$pubmed</a>";
}

sub add_clustering_and_dup {
    my($pieces,$by_sub_entry,$sub) = @_;

    if ($by_sub_entry)
    {
	if ($by_sub_entry->{isu} || $by_sub_entry->{icw})
	{
	    my $fixed_sub = &fix_sub_name($sub);
	    push(@$pieces,"In $fixed_sub, " . &isu_and_icw($by_sub_entry->{isu},$by_sub_entry->{icw}));
	}
    }
}

sub isu_and_icw {
    my($isu,$icw) = @_;

    if ($isu && $icw) { return "it appears to play a functional role that we have not associated with any other gene, and it occurs in close proximity on the chromosome with " . (($icw == 1) ? "another gene from the same subsystem." : "$icw other genes from the same subsystem.") }
    if ($isu)         { return "it appears to play a functional role that we have not associated with any other gene." }
    if ($icw)         { "it occurs in close proximity on the chromosome with " . (($icw == 1) ? "another gene from the same subsystem." : "$icw other genes from the same subsystem.") }
}

sub add_func_assertion {
    my($pieces,$funcSeed) = @_;

    my $func_text = &encoded_annotation_to_natural_english($funcSeed);
    push(@$pieces,$func_text);

    return;
}

# this function parses the encoded annotation into a natural english version
sub encoded_annotation_to_natural_english {
  my ($annotation, $return_table_version) = @_;

  # check if we have an annotation to parse
  unless (defined($annotation)) {
    return "";
  }

  my $natural_english = "";
  my $table_version = "";

  my @funcs = ();
  my $introduction = "";
  if ($annotation =~ /(.+?) \/ (.+)/) {
    $introduction = "This feature plays multiple roles which are implemented by distinct domains within the feature. The roles are:";
    $natural_english = "The encoded protein plays multiple roles which are implemented by distinct domains within the feature. The roles are ";
    push(@funcs, $1);
    my $shortened_list = $2;
    while ($shortened_list =~ /(.+?) \/ (.+)/) {
      push(@funcs, $1);
      $shortened_list = $2;
    }
    push(@funcs, $shortened_list);
    for (my $i=0; $i<scalar(@funcs); $i++) {
      if ($i == scalar(@funcs)-1) {
	$natural_english .= " and \"" . $funcs[$i] . "\".";
      } elsif ($i == 0) {
	$natural_english .= "\"" . $funcs[$i] . "\"";
      } else {
	$natural_english .= ", \"" . $funcs[$i] . "\"";
      }
    }
    
  } elsif ($annotation =~ /(.+?) \@ (.+)/) {
    $introduction = "This feature plays multiple roles which are implemented by the same domain with a broad specificity. The roles are:";
    $natural_english = "The encoded protein plays multiple roles which are implemented by the same domain with a broad specificity. The roles are ";
    push(@funcs, $1);
    my $shortened_list = $2;
    while ($shortened_list =~ /(.+?) \@ (.+)/) {
      push(@funcs, $1);
      $shortened_list = $2;
    }
    push(@funcs, $shortened_list);
    for (my $i=0; $i<scalar(@funcs); $i++) {
      if ($i == scalar(@funcs)-1) {
	$natural_english .= " and \"" . $funcs[$i] . "\".";
      } elsif ($i == 0) {
	$natural_english .= "\"" . $funcs[$i] . "\"";
      } else {
	$natural_english .= ", \"" . $funcs[$i] . "\"";
      }
    }
    
  } elsif ($annotation =~ /(.+?); (.+)/) {
    $introduction = "We are uncertain of the precise function of this feature. It is probably one of the following:";
    $natural_english = "We are uncertain of the precise function of the encoded protein. It is probably ";
    push(@funcs, $1);
    my $shortened_list = $2;
    while ($shortened_list =~ /(.+?); (.+)/) {
      push(@funcs, $1);
      $shortened_list = $2;
    }
    push(@funcs, $shortened_list);
    for (my $i=0; $i<scalar(@funcs); $i++) {
      if ($i == scalar(@funcs)-1) {
	$natural_english .= " or \"" . $funcs[$i] . "\".";
      } elsif ($i == 0) {
	$natural_english .= "\"" . $funcs[$i] . "\"";
      } else {
	$natural_english .= ", \"" . $funcs[$i] . "\"";
      }
    }
    
  } else {
    push(@funcs, $annotation);
  }
  
  if (scalar(@funcs)>1) {
    $table_version .= "<td colspan=3><span id='func_english'><table><tr><td>" . $introduction . "</td></tr>";
    
    foreach my $func (@funcs) {
      my $ec_cell = "";
      $table_version .= '<tr>';
      $table_version .= "<td width=400>" . $func . "</td>";
      while ($func =~ /[\[\(]{1}EC (\d+\.\d+\.[\d\-]+\.[\d\-]+)[\)\]]{1}/gi) {
	$ec_cell .= " <a href='http://www.genome.jp/dbget-bin/www_bget?ec:$1' target=outbound>$1</a>,";
      }
      if ($ec_cell) {
	chop $ec_cell;
	$table_version .= "<th>EC Number</th><td>$ec_cell</td>";
      }
      $table_version .= "</tr>";      
    }

    $table_version .= "</table></span><span id='func_code' style='display: none'>$annotation<br><br></span><input type='button' value='show encoded function' onclick=\"if(document.getElementById('func_english').style.display=='none') { document.getElementById('func_english').style.display='inline'; document.getElementById('func_code').style.display='none'; this.value='show encoded function'; } else { document.getElementById('func_english').style.display='none'; document.getElementById('func_code').style.display='inline'; this.value='show natural english'; }\"></td></tr>";

  } else {
    $table_version .= "<td width=400>" . $annotation . "</td>";
    my $ec_cell = "";
    while ($annotation =~ /[\[\(]{1}EC (\d+\.\d+\.[\d\-]+\.[\d\-]+)[\)\]]{1}/gi) {
      $ec_cell .= " <a href='http://www.genome.jp/dbget-bin/www_bget?ec:$1' target=outbound>$1</a>,";
    }
    if ($ec_cell) {
      chop $ec_cell;
      $table_version .= "<th>EC Number</th><td>$ec_cell</td>";
    }
    $table_version .= "</tr>";
    $natural_english .= "We have assigned the function \"$annotation\" to the encoded protein."
  }

  if ($return_table_version) {
    return $table_version;
  }

  return $natural_english;
}

sub add_in_subs {
    my($pieces,$insubs) = @_;

    if (@$insubs > 0)
    {
	my $n = @$insubs;
	#print STDERR "n = $n, insubs = $insubs\n";
	if ($n > 0)
	{
	    my $in_sub_state = "The protein occurs in " .
		               (($n == 1) ? "1 subsystem" : "$n subsystems") . ': ' . &subs($insubs) . ".";
	    push(@$pieces,$in_sub_state);
	}
    }
}

sub subs {
    my($subs) = @_;

    if (@$subs == 1) { return &fix_sub_name($subs->[0]) }
    my @subL = map { &fix_sub_name($_) } @$subs;
    $subL[$#subL] = "and $subL[$#subL]";
    return join(", ",@subL);
}

sub fix_sub_name {
    my($x) = @_;

    $x =~ s/_/ /g;
    return "\"$x\"";
}

sub evidence_codes {
    my($fig,$peg) = @_;

    if ($peg !~ /^fig\|\d+\.\d+\.peg\.\d+$/) { return "" }

    my @codes = $fig->get_attributes($peg, "evidence_code");
    return map { $_->[2] } @codes;
}

=head3 clearinghouse_register_subsystem_id

    my $tax = FIGRules::clearinghouse_register_subsystem_id($ss_name);

Return a subsystem's short ID. Short IDs are maintained at a special
clearinghouse web site. If the subsystem does not yet have a short ID, a
new one will be assigned by the clearinghouse and returned.

=over 4

=item ss_name

Full name of the relevant subsystem.

=item RETURN

Short ID of the subsystem.

=back

=cut

sub clearinghouse_register_subsystem_id {
    my($ss_name) = @_;

    my $ch_url = "http://clearinghouse.theseed.org/Clearinghouse/clearinghouse_services.cgi";
    my $proxy = SOAP::Lite->uri("http://www.soaplite.com/Scripts")->proxy($ch_url);

    my ($resp, $retVal);
    eval {
        $resp = $proxy->register_subsystem_id($ss_name);
    };
    if ($@) {
        Trace("Error on proxy call: $@") if T(0);
        $retVal = undef;
    } elsif ($resp->fault) {
        Trace("Failure on register_subsystem_id($ss_name): " .$resp->faultcode . ": " . $resp->faultstring) if T(0);
        $retVal = undef;
    } else {
        $retVal = $resp->result;
    }
    return $retVal;
}

=head3 FindNamedThing

    my ($type, $id) = FIGRules::FindNamedThing($fig, $name);

Return the type and ID of a named thing. The thing can be a feature,
subsystem, or organism. If nothing is found with the given name, an
undefined value will be returned for the type and the entire name will be
returned as an ID. Acceptable names include FIG feature IDs,
corresponding feature IDs, NMPDR feature IDs, gene IDs, organism IDs,
organism names, EC numbers, and external contig IDs. In the case of an organism
name, an exact match including the strain is required in SEED. In the
NMPDR, you only need to specify enough of the name to guarantee uniqueness.

=over 4

=item fig

A FIG-like object for accessing the data store.

=item name

An ID or name representing a thing whose page is desired.

=item RETURN

Returns a two-element list. If the named thing was found, the list will contain the
thing's type (Genome, Feature, Contig, EC) and its ID. If the named thing was not found,
the list will contain an undefined value for the type and the input string for the ID.

=back

=cut

sub FindNamedThing {
    # Get the parameters.
    my ($fig, $name) = @_;
    # Declare the return variables.
    my ($type, $id) = (undef, $name);
    # Look for the thing. We can do a bit of parsing to figure out the type.
    if (lc($name) =~ /^(fig|nmpdr)\|(\d+\.\d+)\.([a-z]+)\.(\d+)$/) {
        # Here we have a sort-of feature ID. We need to change "gene" to "peg"
        # and force the prefix to "fig".
        my ($org, $kind, $seq) = ($2, $3, $4);
        Trace("Sort-of feature ID found: $org, $kind, $seq") if T(3);
        $kind = 'peg' if ($kind eq 'gene');
        $id = "fig|$org.$kind.$seq";
        $type = "Feature";
    } elsif (lc($name) =~ /^\d+\.\d+$/) {
        # Here we have an organism ID.
        $id = $name;
        $type = "Genome";
    } elsif ($name =~ /^nmpdr\|(\d+\.\d+)\.contig\.(.+)$/ ||
             $name =~ /^(\d+\.\d+):(.+)$/) {
        # Here we have a contig ID. The colon form ID is the one we use.
        $id = "$1:$2";
        $type = "Contig";
    } elsif (my @list = grep { $_ =~ /^fig/ } $fig->get_corresponding_ids($name)) {
        # Here we have a feature alias.
        ($id) = @list;
        $type = "Feature";
    } else {
        # Here we have a possible organism name.
        my $genome = $fig->orgid_of_orgname($name);
        if ($genome) {
            # We found it!
            $id = $genome;
            $type = "Genome";
        }
    }
    # Return the results.
    return ($type, $id);
}

=head3 CrudeDistanceFormula

    my $distance = FIGRules::CrudeDistanceFormula(\@tax1, \@tax2);

Compute the taxonomic distance from two taxonomy lists. The crude
distance is 1 for organisms in different domains, 1/2 for organisms that
are in the same domain but different subdomains, and so forth.

=over 4

=item tax1

Reference to a list containing the taxonomy of the first organism.

=item tax2

Reference to a list containing the taxonomy of the second organism.

=item RETURN

Returns a number between 0 and 1 that is higher the further away the
organisms are from each other.

=back

=cut

sub CrudeDistanceFormula {
    # Get the parameters.
    my ($tax1, $tax2) = @_;
    # Declare the return variable.
    my $retVal = 1.0;
    # Compute the taxonomy lengths.
    my $n1 = scalar(@$tax1);
    my $n2 = scalar(@$tax2);
    # Loop through the lists.
    for (my $i = 0; $i < $n1 && $i < $n2 && $tax1->[$i] eq $tax2->[$i]; $i++) {
        # We're the same at this level, so cut the return value in half.
        $retVal /= 2.0;
    }
    # Return the result.
    return $retVal;
}

=head3 NmpdrErrorPage

    my $html = FIGRules::NmpdrErrorPage($module => $message);

Display an NMPDR error page for the given module with the given message.
If tracing is turned on, the error will be displayed and traced;
otherwise, it will be logged as a warning and sent to the RSS error feed
(if any).

=over 4

=item module

Name of the relevant module. The module name appears in the warning log,
and is used to interrogate the trace level.

=item message

Error message to use.

=item options

Hash of options. Currently none are defined.

=item RETURN

Returns the HTML for the error display.

=back

=cut

sub NmpdrErrorPage {
    # Get the parameters.
    my ($module, $message, %options) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Start with a heading.
    $retVal .= CGI::h3("NMPDR Error Encountered");
    # We format our friendly text in here.
    my @lines;
    push @lines, "We are sorry, but NMPDR encountered an error while",
                 "formatting this web page. This could be a temporary",
                 "server problem or a genuine bug.";
    # If we output the error message, it will go here.
    my $messageSection = "";
    # Are we tracing?
    if (T($module => 3)) {
        # Yes. Trace the error message.
        Trace("Error in $module: $@");
        push @lines, "The PERL error message follows below:";
        $messageSection = CGI::pre($@);
    } else {
        # No. Send it to the RSS error feed.
        Warn("Error in $module: $@");
        push @lines, "A message has been sent to our programming staff about this incident.";
        $messageSection = CGI::p("Use your browser's BACK button and try again, or ",
                                 CGI::a({ href => "$FIG_Config::nmpdr_site_url" },
                                        "return to the NMPDR home page."));
    }
    # Format the nice text.
    $retVal .= CGI::p(join(" ", @lines));
    # Add the message section.
    $retVal .= $messageSection;
    # Return the result.
    return $retVal;
}


1;
