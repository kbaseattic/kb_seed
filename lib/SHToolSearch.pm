#!/usr/bin/perl -w

package SHToolSearch;

    use strict;
    use Tracer;
    use CGI qw(-nosticky);
    use HTML;
    use Sprout;
    use Sim;
    use RHLocations;
    use ERDBObject;
    use XML::Simple;
    use Data::Dumper;
    use base 'SearchHelper';

=head1 Tool Search Feature Search Helper

=head2 Introduction

This object conducts searches using command-line tools that compare a DNA or Protein
pattern against a text database of genetic information.

The tools are invoked by a method called L</ExecScan>. This processes the input,
invokes the tool, and returns a list of hash references. The hash references contain
whatever fields are required in the search output. Two fields are required: C<hitLoc>,
which specifies the location of the matching data, and C<sortKey>, which is used
to sort it.

=over 4

=item sequence

DNA or protein sequence. This can be a feature ID, pattern, or a FASTA string. A feature ID
is automatically converted to a FASTA string. If a pattern is specified, it is passed
directly to the pattern match tool.

=item tool

Tool to use: currently C<blastp>, C<blastn>, C<blastx>, C<dnaScan>, or C<protScan>.

=item options

BLAST options, encoded as a string

=item genome[]

IDs of the genomes to be included in the search.

=back

=cut

=head2 Data Structures

=head3 ToolTable

This search is a fairly complicated thing that is basically used to search for
sequence data in one or more genomes using command-line tools. The idea is that
any command-line tool can be put in here and made available for use by the
search system. From a coding point of view, it would make sense to have a
separate search helper for each tool, but combining them in this way has
a psychological benefit for the user. The one requirement across all the tools
is that the input is a DNA or protein sequence of some sort. For the BLAST
tools, the sequence is a standard FASTA thing. For the scan-for-matches
tools, the sequence is a search pattern.

The tool table is a hash that performs the services normally expected of
subclasses. The hash maps each tool name to a hash reference. The various
fields in the hash references are as follows.

=over 4

=item db_type

Type of database against which the tool runs: C<prot> for a protein database and
C<dna> for a DNA database. This tells us which files to pass into the tool as
the search database.

=item exec

Execution string for the tool. The variable C<$seqFile> is presumed to be the location
of the input sequence, C<$db> is the directory, and C<$options> are the user-specified options.

=item output

The method for converting the output from the tool (presented as a set of lines of text) to
the output format expected by the BLAST search tool (a list of hash references).

=item inputType

The type of input expected. This is either a FASTA for protein or DNA (C<prot> or C<dna>),
or a scan pattern for protein or DNA (C<protPattern> or C<dnaPattern>). If additional
formats are needed, they must be programmed into the B<ComputeFASTA> method of C<SearchHelper>.

=item extras

A list of lists describing the extra columns desired in the output. The extra column names
must exist as keys in the hashes produced by the output method. In addition to the fields named
in this list, the output hashes must contain a field named C<sortKey> that can be used to sort
the results. The lists correspond exactly to the parameter list for the B<AddExtraColumn>
method of the B<ResultHelper> class.

=item buttonName

The name to display on the search button if this tool is selected.

=item targetRelationship

The name of the relationship from the genome to the entity whose IDs will appear in the output regions. This is C<HasContig> for
a DNA search and C<HasFeature> for a feature search.

=item title

Title to be used for the search results pages.

=back

=cut

my %ToolTable = (   blastp => {     db_type => 'prot',
                                    exec => 'blastall -i $seqFile -d $db -m 7 -FF -p blastp $options',
                                    output => \&blastXML,
                                    inputType => 'prot',
                                    extras => [[hitLoc => 0, title => "Hit Location", style => "leftAlign", download => 'text'],
                                               [evalue => undef, title => "eValue", style => "leftAlign", download => 'num'],
                                               [queryLoc => undef, title => "Query Location", style => "leftAlign", download => 'text'],
                                               [alignment => undef, title => "Alignment", style => "code", download => 'align']],
                                    buttonName => 'BLAST',
                                    targetRelationship => 'HasFeature',
                                    title => 'Blastp Search',
                              },
                    blastx => {     db_type => 'prot',
                                    exec => 'blastall -i $seqFile -d $db -m 7 -FF -p blastx $options',
                                    output => \&blastXML,
                                    inputType => 'prot',
                                    extras => [[hitLoc => 0, title => "Hit Location", style => "leftAlign", download => 'text'],
                                               [evalue => undef, title => "eValue", style => "leftAlign", download => 'num'],
                                               [queryLoc => undef, title => "Query Location", style => "leftAlign", download => 'text'],
                                               [alignment => undef, title => "Alignment", style => "code", download => 'align']],
                                    buttonName => 'BLAST',
                                    targetRelationship => 'HasFeature',
                                    title => 'Blastx Search',
                              },
                    blastn => {     db_type => 'dna',
                                    exec => 'blastall -i $seqFile -d $db -m 7 -FF -p blastn $options',
                                    output => \&blastXML,
                                    inputType => 'dna',
                                    extras => [[hitLoc => 0, title => "Hit Location", style => "leftAlign", download => 'text'],
                                               [evalue => undef, title => "eValue", style => "leftAlign", download => 'num'],
                                               [queryLoc => undef, title => "Query Location", style => "leftAlign", download => 'text'],
                                               [alignment => undef, title => "Alignment", style => "code", download => 'align']],
                                    buttonName => 'BLAST',
                                    targetRelationship => 'HasContig',
                                    title => 'Blastn Search',
                              },
                    dnaScan => {    db_type => 'dna',
                                    exec => 'scan_for_matches -c $seqFile $options <$db',
                                    output => \&scanLines,
                                    inputType => 'dnaPattern',
                                    extras => [[hitLoc => 0, title => "Hit Location", style => "leftAlign", download => 'text'],
                                               [alignment => undef, title => "Matching Sequence", style => "code", download => 'align']],
                                    buttonName => 'SCAN',
                                    targetRelationship => 'HasContig',
                                    title => 'DNA Scan for Matches',
                               },
                    protScan => {   db_type => 'prot',
                                    exec => 'scan_for_matches -p $seqFile $options <$db',
                                    output => \&scanLines,
                                    inputType => 'protPattern',
                                    extras => [[hitLoc => 0, title => "Hit Location", style => "leftAlign", download => 'text'],
                                               [alignment => undef, title => "Matching Sequence", style => "code", download => 'align']],
                                    buttonName => 'SCAN',
                                    targetRelationship => 'HasFeature',
                                    title => 'Protein Scan for Matches',
                                }
                );

=head2 Public Methods

=head3 ExecTool

    my @sims = $shelp->ExecTool($seqFile, \@genomes, $tool, $options);

Call a tool to search for DNA sequences or features.

=over 4

=item seqFile

Name of a file containing the input sequence. This will either be a FASTA or a scan pattern.

=item genomes

A list of the IDs for the target genomes of the search.

=item tool

Name of the tool to use.

=item options

Options to pass to the tool, formatted for the command line.

=item RETURN

Returns a list of hashes, each representing a single match point.

=back

=cut

sub ExecTool {
    # Get the parameters.
    my ($self, $seqFile, $genomes, $tool, $options) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Get a Sprout database object.
    my $sprout = $self->DB();
    # Insure the blast tools can find the blast matrix directory.
    if (! $ENV{"BLASTMAT"}) { $ENV{"BLASTMAT"} = $FIG_Config::blastmat; }
    # Get the location of the tools.
    my $toolDir = "$FIG_Config::ext_bin";
    Trace("ExecTool for file $seqFile, tool => $tool, options => $options.") if T(2);
    # Get this tool's parameters.
    my $toolData = $ToolTable{$tool};
    # Determine whether or not this is a multi-genome call.
    my $genomeCount = scalar(@$genomes);
    Trace("$genomeCount genomes in list.") if T(2);
    my $multiGenome = ($genomeCount > 1 ? 1 : 0);
    # Loop through the genome list.
    for my $genome (@$genomes) {
        $self->PrintLine("Performing $tool for $genome.<br />");
        Trace("Matching against $genome.") if T(3);
        # Get the target database location for this genome.
        my $db = ($toolData->{db_type} eq 'prot' ?
                  "$FIG_Config::organisms/$genome/Features/peg/fasta" :
                  "$FIG_Config::organisms/$genome/contigs");
        # Only proceed if the database has data in it.
        if (-s $db) {
            # Verify the database.
            VerifyDB($db, $toolData->{db_type});
            # Get the command.
            my $string = $toolData->{exec};
            # Make the substitutions.
            my %subs = (db => $db, options => ($options || ''), seqFile => $seqFile);
            for my $key (keys %subs) {
                $string =~ s/\$$key/$subs{$key}/g;
            }
            my $command = "$toolDir/$string";
            # Call the command.
            Trace("Executing: $command") if T(3);
            my @data = TICK($command);
            my $dataLineCount = scalar(@data);
            Trace("$dataLineCount lines returned from $tool.") if T(3);
            $self->PrintLine("$dataLineCount data lines returned from $tool.<br />");
            # Compute the maximum number of hits we want back from this genome. Note
            # that scalar(@data) will always be at lest the total number of hits
            # returned.
            my $maxHits = ($multiGenome ? $FIG_Config::blast_limit : scalar(@data));
            # Process the lines. Note that we pass ourselves as the first parameter,
            # mimicking what would happen if the output routine were called as an
            # instance method.
            my @results = &{$toolData->{output}}($self, \@data, $maxHits, $genome);
            # Get a hash of valid targets.
            my $targetRel = $toolData->{targetRelationship};
            my %targetHash = map { $_ => 1 } $sprout->GetFlat([$targetRel], "$targetRel(from-link) = ?",
                                                              [$genome], "$targetRel(to-link)");
            # Insure the results all have valid targets.
            my $keepCount = 0;
            for my $result (@results) {
                # Get the hit location and convert it to a location object.
                my $targetLoc = BasicLocation->new($result->{hitLoc});
                # Test the contig to see if it's a valid target. It's valid if
                # we found it when we did the query above. Invalid targets come
                # from things added to SEED after the Sprout was built.
                if ($targetHash{$targetLoc->Contig}) {
                    push @retVal, $result;
                    $keepCount++;
                }
            }
            my $message = scalar(@results) . " hits found. $keepCount kept.";
            Trace($message) if T(3);
            $self->PrintLine("$message<br />");
        } else {
            Confess("Blast data not found at $db.");
        }
    }
    # Return the resulting list.
    return @retVal;
}

=head2 Output Processing Methods

=head3 blastXML

    my @dataRows = $shelp->blastXML(\@data, $maxHits, $genome);

Process XML output from Blast.

The BLAST output is presented as a list of text lines, each of which contains a line-end
character. We combine all these lines into a single string and read it in using an XML parser.
The parsed result contains the interesting data 3 levels deep as C<iteration hits>. Each hit
corresponds to a single target object-- either a feature or a contig-- identified as the C<Hit_def>.
Inside each hit is a list of C<Hit_hsps>. These are single-level hashes that represent a point of contact
between the query sequence and the target. The from- and to-locations for the query sequence
are stored as C<Hsp_query-from> and C<Hsp_query-to>, and for the target object they are
C<Hsp_hit-from> and C<Hsp_hit-to>. The alignment is stored in C<Hsp_hseq>, C<Hsp_qseq>, and
C<Hsp_midline>. The bit score is in C<Hsp_bit-score> and the e-value is in C<Hsp_evalue>.

=over 4

=item data

Reference to a list of XML output lines from BLAST.

=item maxHits

Maximum number of hits to return. This is used to control the output size in multi-genome
searches.

=item genome

ID of the target genome.

=item RETURN

Returns a list of hash references. In each hash, C<hitLoc> indicates the hit location, C<queryLoc>
indicates the query location, C<alignment> the three-line alignment between the
query and hit locations, C<sortKey> a sort key based on the bit score, and C<bsc> the bit
score itself.

=back

=cut

sub blastXML {
    # Get the parameters.
    my ($self, $data, $maxHits, $genome) = @_;
    # Declare the return variable.
    my @retVal;
    Trace("Processing blastXML output for $genome. Max Hits = $maxHits.") if T(2);
    # Set up a counter so that we stop after the appropriate
    # number of hits.
    my $outputHits = 0;
    # Create the xml string from the data.
    my $xmlString = join("", @{$data});
    # Only proceed if we got something back.
    # Parse the XML. The various options help to keep the result more compact and predictable.
    # Note we do some major error-checking here, because XMLin is very delicate.
    my $xmlThing;
    eval {
        if ($xmlString) {
            $xmlThing = XMLin($xmlString, GroupTags =>  { Iteration_hits => 'Hit', Hit_hsps => 'Hsp' },
                                          ForceArray => ['Hit', 'Hsp']);
        }
    };
    if ($@) {
        Confess("XML parsing error for $genome: $@");
    } elsif (! defined($xmlThing)) {
        Trace("No result from XML parse for $genome.") if T(3);
    } else {
        Trace("XML thing for $genome = \n" . Dumper($xmlThing)) if T(blastXML => 3);
        # Get the name of the query object.
        my $queryName = $xmlThing->{'BlastOutput_query-def'};
        # Strip out the comments (if any).
        if ($queryName =~ /^(\S+)\s+/) {
            $queryName = $1;
        }
        my $iterationData = $xmlThing->{BlastOutput_iterations}->{Iteration}->{Iteration_hits};
        Trace("Iteration data contains " . scalar(@{$iterationData}) . " hits.") if T(3);
        # "$iterationData" is now a list of hits. We process these one at a time in the
        # following loop.
        for my $hit (@{$iterationData}) { last if ($outputHits >= $maxHits);
            # Get the hit target. This is the contig or feature containing the hit locations.
            # We canonicalize it so that it has the genome name somewhere in it.
            my $hitArea = Canonize($hit->{Hit_def}, $genome);
            Trace("Hit on $hitArea. Point count = " . scalar(@{$hit->{Hit_hsps}}) . ".") if T(3);
            # Now we loop through the hit points for this hit.
            for my $point (@{$hit->{Hit_hsps}}) { last if ($outputHits >= $maxHits);
                # We need to create an output tuple for this hit. First, we
                # create the alignment string.
                my $alignment = join("<br/>", $point->{Hsp_qseq}, $point->{Hsp_midline}, $point->{Hsp_hseq});
                # Convert the spaces to non-breaking so that they aren't mucked up by HTML formatting.
                $alignment =~ s/ /&nbsp;/g;
                # Next, we need to create the locations. The fields Hsp_query-frame and Hsp_hit-frame indicate
                # whether the location is on the plus or minus strand.
                my $hitLoc = BasicLocation->new($hitArea, $point->{'Hsp_hit-from'}, "_", $point->{'Hsp_hit-to'});
                $hitLoc->Reverse if $point->{'Hsp_hit-frame'} < 0;
                my $queryLoc = BasicLocation->new($queryName, $point->{'Hsp_query-from'}, "_", $point->{'Hsp_query-to'});
                $queryLoc->Reverse if $point->{'Hsp_query-frame'} < 0;
                # We also need the e-value.
                my $eValue = $point->{'Hsp_evalue'};
                # Finally, we get the bit score, formatted nicely for the sorting.
                my $bsc = sprintf("%0.3f", $point->{'Hsp_bit-score'});
                # Now we can build our output tuple.
                push @retVal, { queryLoc  => $queryLoc->SeedString,
                                hitLoc    => $hitLoc->SeedString,
                                evalue    => $eValue,
                                alignment => $alignment,
                                sortKey   => $self->ToolSortKey($genome, $bsc, $hitLoc),
                              };
                # Update our result counter. Both loops will exit when this equals the maximum.
                $outputHits++;
            }
        }
    }
    # Return the results.
    return @retVal;
}


=head3 scanLines

    my @dataRows = $shelp->scanLines(\@data, $maxHits, $genome);

Process output from the scan-for-matches tool. Each match consists of two
output lines. The first contains the hit source (feature or contig), the
begin point, and the end point. The second contains the sequence matched.
Unlike a BLAST search, there is no concept of a query location: the entire
query matches.

=over 4

=item data

Reference to a list of the output lines from the scan.

=item maxHits

The maximum number of matches to return. This value is used to control
the output size in multi-genome searches.

=item genome

The ID of the genome containing the hits.

=item RETURN

Returns a list of hash references. In each hash, C<hitLoc> indicates the hit location, C<sortKey> a
sort key, and C<alignment> the matching sequence.

=back

=cut

sub scanLines {
    # Get the parameters.
    my ($self, $data, $maxHits, $genome) = @_;
    Trace("Processing scanLines output for $genome.") if T(2);
    # Declare the return variable.
    my @retVal;
    # Insure we don't try to return more than the maximum number
    # of hits. Each hit is two lines, so this involves multiplying
    # by two.
    my $maxLines = $maxHits * 2;
    if ($maxLines > scalar(@{$data})) {
        $maxLines = scalar(@{$data});
    }
    # Loop through the lines containing the hits we want.
    for (my $i = 0; $i < $maxLines; $i += 2) {
        # Parse the first line, containing the hit location.
        $data->[$i] =~ /^>([^:]+):\[(\d+),(\d+)\]/;
        # Convert the result to a location.
        my ($hitObject, $beg, $end) = ($1, $2, $3);
        $hitObject = Canonize($hitObject, $genome);
        my $hitLoc = BasicLocation->new($hitObject, $beg, "_", $end);
        # Get the match string.
        my $matchString = $data->[$i+1];
        chomp $matchString;
        # Output the result.
        push @retVal, { hitLoc => $hitLoc->SeedString,
                        alignment => $matchString,
                        sortKey => $self->ToolSortKey($genome, 0, $hitLoc),
                      };
    }
    # Return the result.
    return @retVal;
}

=head2 Utility Methods

=head3 Canonize

    my $newName = CallScanner::Canonize($name, $genomeID);

If the specified name is a contig ID, insure it has a genome ID in front of it.

=over 4

=item name

Name to fix up.

=item genomeID

ID of the genome to be added to the contig ID, if necessary.

=item RETURN

Returns a fixed-up name.

=back

=cut

sub Canonize {
    # Get the parameters.
    my ($name, $genomeID) = @_;
    # Declare the return variable.
    my $retVal = $name;
    # Check for a genome ID already in place or a feature ID.
    if ($retVal !~ /:/ && $retVal !~ /^fig/) {
        $retVal = "$genomeID:$name";
    }
    # Return the result.
    return $retVal;
}

=head3 VerifyDB

    CallScanner::VerifyDB($db, $type);

Verify that the specified FASTA file has BLAST databases. If the databases
do not exist, they will be created. If they are older than the FASTA file,
they will be regenerated.

=over 4

=item db

Name of the FASTA file.

=item type

Type of database desired: C<prot> for protein and C<dna> for DNA.

=back

=cut

sub VerifyDB {
    # Get the parameters.
    my ($db, $type) = @_;
    # Process according to the data type.
    if ($type eq 'prot') {
        if ((! -s "$db.psq") || (-M "$db.psq" > -M $db)) {
            Trace("Building protein FASTA database for $db.") if T(3);
            system "$FIG_Config::ext_bin/formatdb -p T -i $db";
        }
    } else {
        if ((! -s "$db.nsq") || (-M "$db.nsq" > -M $db)) {
            Trace("Building DNA FASTA database for $db.") if T(3);
            system "$FIG_Config::ext_bin/formatdb -p F -i $db";
        }
    }
}

=head3 ToolSortKey

    my $key = $shelp->ToolSortKey($genome, $bsc, $hitLoc);

Return the sort key for a match result against the specified
genome with the specified bit-score. The results are
to be sorted by bit-score, with the highest score at the top
and preferential treatment given to NMPDR core genomes.
The tie-breaker for entries with the same score is the
organism name followed by the hit location.

=over 4

=item genome

ID of the genome containing the target area.

=item bsc

Bit-score for the match.

=item hitLoc

The hit location, encoded as a location object.

=item RETURN

Returns a key field that can be used to sort the match in among the
results in the desired fashion.

=back

=cut

sub ToolSortKey {
    # Get the parameters.
    my ($self, $genome, $bsc, $hitLoc) = @_;
    # Get the group from the genome ID.
    my ($orgName, $group) = $self->OrganismData($genome);
    # Declare the return value. It begins with an "A" if this is an NMPDR
    # feature and a "Z" otherwise.
    my $retVal = ($group ? "A" : "Z");
    # Convert the bit score to an integer.
    my $bitScore = int(10 * $bsc);
    # We want to sort by descending bit score, so subtract the result from a big
    # number.
    my $bitThing = 10000000000 - $bitScore;
    if ($bitThing < 0) {
        $bitThing = 0;
    }
    # Pad it to 10 characters.
    $bitThing = "0$bitThing" while (length $bitThing < 10);
    # Tack it onto the group character.
    $retVal .= $bitThing;
    # Finish up with the organism name and the hit location.
    $retVal .= "$orgName:::" . $hitLoc->SeedString;
    Trace("Blast sort key is $retVal, based on group \"$group\".") if T(4);
    # Return the result.
    return $retVal;
}

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
    my $retVal = $self->FormStart("Sequence Search");
    # Get the list of selected genomes.
    my @selected = $cgi->param('genome');
    # Get the incoming genome sequence and the options. These are the incoming scalar
    # values; the others apply to menus.
    my $sequence = $cgi->param('sequence') || "";
    my $options = $cgi->param('options') || "";
    my $neighborhood = $cgi->param('neighborhood') || RHLocations::NEIGHBORHOOD;
    # Get the selected tool and compute the corresponding button caption.
    my $toolChosen = $cgi->param('tool') || "";
    my $caption = ($toolChosen ? $ToolTable{$toolChosen}->{buttonName} : "");
    # Create the menus. First is the tool menu.
    my @valueList = ("", sort keys %ToolTable);
    my $toolMenu = CGI::popup_menu(-name => "tool", -values => \@valueList,
                                    -onChange => 'setSubmit(this.value)',
                                    -default => $toolChosen);
    # Create the genome selection menu.
    my $menu = $self->NmpdrGenomeMenu("genome", 'multiple', \@selected);
    # The general structure here will be to have the DNA/protein sequence on the top,
    # then genome selector and finally the small controls.
    my @rows = ();
    push @rows, CGI::Tr(CGI::td("Tool"), CGI::td($toolMenu));
    push @rows, CGI::Tr(CGI::td("Sequence in Raw or FASTA Format"),
                         CGI::td({colspan => 2}, CGI::textarea(-name => "sequence", -rows => 5,
                                                               -value => $sequence, -cols => 62,
                                                               -style => 'font-family: monospace')));
    push @rows, CGI::Tr(CGI::td("Select one or more genomes"),
                         CGI::td({colspan => 2}, $menu));
    push @rows, CGI::Tr(CGI::td("Blast Options"),
                         CGI::td({colspan => 2}, CGI::textfield(-name => 'options', size => 45,
                                                                 -value => $options)));
    push @rows, CGI::Tr(CGI::td("Neighborhood Width"),
                         CGI::td(CGI::textfield(-name => 'neighborhood', -size => 5,
                                                -value => $neighborhood)));
    push @rows, $self->SubmitRow($caption);
    # Create the table.
    $retVal .= $self->MakeTable(\@rows);
    # Close the form.
    $retVal .= $self->FormEnd();
    # Get the form name. We'll need it for the upcoming javascript.
    my $formName = $self->FormName();
    # Add the javaScript to update the button.
    $retVal .= "<script type=\"text/javascript\">\n" .
               "  function setSubmit(tool) {\n" .
               "    switch (tool) {\n";
    for my $tool (sort keys %ToolTable) {
        $retVal .= "    case '$tool' : document.$formName.Search.value = '$ToolTable{$tool}->{buttonName}'; break;\n";
    }
    $retVal .= "    }\n" .
               "  }\n" .
               "</script>\n";
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
    # Declare the return variable. If it remains undefined, the caller will
    # know there's been an error.
    my $retVal;
    # Get the sprout and CGI query objects.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Get the genome IDs.
    my @genomes = $self->GetGenomes('genome');
    if (! @genomes) {
        $self->SetMessage("No genomes specified.");
    } else {
        # Get the sequence in its raw form.
        my $sequence = $cgi->param('sequence');
        if (! $sequence) {
            $self->SetMessage("No sequence specified.");
        } else {
            # Get the blast options and the tool type.
            my $toolType = $cgi->param('tool') || "";
            my $options = $cgi->param('options') || "";
            # Insure the tool type is valid.
            if (! $toolType) {
                $self->SetMessage("No tool specified.");
            } else {
                # Create the result helper.
                my $rhelp = RHLocations->new($self);
                # Compute the columns. The default columns are determined mostly by the result type.
                $self->DefaultColumns($rhelp);
                #
                # (NOTE: Optional columns should be added here so they go before the alignment column.)
                #
                # Define the extra columns for this tool.
                for my $extraCol (@{$ToolTable{$toolType}->{extras}}) {
                    $rhelp->AddExtraColumn(@{$extraCol});
                }
                # Now, the sequence. We use a utility to convert it to a uniform
                # FASTA format of the correct type. Note that for patterns there
                # will not be a header line.
                my $sequenceThing = $self->ComputeFASTA($ToolTable{$toolType}->{inputType}, $cgi->param('sequence'));
                Trace("Fasta sequence has length " . length($sequenceThing) . ".") if T(3);
                # Only proceed if the FASTA sequence was converted successfully.
                if ($sequenceThing) {
                    # Write the FASTA to a temporary file. We use the session name with a suffix of
                    # "fasta" for the file name.
                    my $tmpFile = $self->GetTempFileName('fasta');
                    Tracer::PutFile($tmpFile, $sequenceThing);
                    # Call the tool.
                    my @results = $self->ExecTool($tmpFile, \@genomes, $toolType, $options);
                    # Start the output session.
                    $self->OpenSession($rhelp);
                    # Compute the number of results.
                    $retVal = scalar(@results);
                    $self->PrintLine("$retVal hit locations found.<br />");
                    # Loop through the results.
                    my $resultCounter = 0;
                    for my $result (@results) {
                        # Store the result fields as extra columns. Only the result fields
                        # defined as extra columns in the tool table will be kept by the
                        # result helper.
                        $rhelp->PutExtraColumns(%{$result});
                        # Create an ERDB object for the hit location. We use BasicLocation to
                        # parse it into its components.
                        my $data = $rhelp->BuildLocationRecord($result->{hitLoc});
                        # Now put the location data and its sort key into the output stream.
                        $rhelp->PutData($result->{sortKey}, $result->{hitLoc}, $data);
                        # Tell the user every so often what kind of progress we're making.
                        $resultCounter++;
                        if ($resultCounter % 100 == 0) {
                            $self->PrintLine("$resultCounter of $retVal hit locations processed.<br />");
                        }
                    }
                    # Close the output session.
                    $self->CloseSession();
                }
            }
        }
    }
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
    return "Search for matching DNA or protein regions.";
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
    # Compute the title. We extract the tool ID from the query parameters.
    my $cgi = $self->Q();
    my $tool = $cgi->param('tool');
    my $retVal = $ToolTable{$tool}->{title};
    # Return it.
    return $retVal;
}


1;
