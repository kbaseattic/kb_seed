#!/usr/bin/perl -w

package SearchHelper;

    use strict;
    use Tracer;
    use PageBuilder;
    use Digest::MD5;
    use File::Basename;
    use File::Path;
    use File::stat;
    use LWP::UserAgent;
    use FIGRules;
    use Sprout;
    use SFXlate;
    use FIGRules;
    use HTML;
    use BasicLocation;
    use URI::Escape;
    use PageBuilder;
    use AliasAnalysis;
    use CGI::Cookie;
    use FreezeThaw qw(freeze thaw);

=head1 Search Helper Base Class

=head2 Introduction

The search helper is a base class for all search objects. It has methods for performing
all the common tasks required to build and manage a search cache. The subclass must
provide methods for generating and processing search forms. The base class has the
following object fields.

=over 4

=item cols

Reference to a list of column header descriptions. If undefined, then the session cache
file has been opened but nothing has been written to it.

=item fileHandle

File handle for the session cache file.

=item query

CGI query object, which includes the search parameters and the various
session status variables kept between requests from the user.

=item type

Session type: C<old> if there is an existing cache file from which we are
displaying search results, or C<new> if the cache file needs to be built.

=item class

Name of the search helper class as it would appear in the CGI query object
(i.e. without the C<SH> prefix.

=item sprout

Sprout object for accessing the database.

=item message

Message to display if an error has been detected.

=item orgs

Reference to a hash mapping genome IDs to organism data. (Used to
improve performance.)

=item name

Name to use for this object's form.

=item scriptQueue

List of JavaScript statements to be executed after the form is closed.

=item genomeHash

Cache of the genome group hash used to build genome selection controls.

=item genomeParms

List of the parameters that are used to select multiple genomes.

=item notices

A list of messages to be put in the notice file.

=back

=head2 Adding a new Search Tool

To add a new search tool to the system, you must

=over 4

=item 1

Choose a class name for your search tool.

=item 2

Create a new subclass of this object and implement each of the virtual methods. The
name of the subclass must be C<SH>I<className>, where I<className> is the
type of search.

=item 3

Create an include file among the web server pages that describes how to use
the search tool. The include file must be in the B<includes> directory, and
its name must be C<SearchHelp_>I<className>C<.inc>.

=item 4

If your search produces a result for which a helper does not exist, you
must create a new subclass of B<ResultHelper>. Its name must be
C<RH>I<className>, where I<className> is the type of result.

=back

=head3 Building a Search Form

All search forms are three-column tables. In general, you want one form
variable per table row. The first column should contain the label and
the second should contain the form control for specifying the variable
value. If the control is wide, you should use C<colspan="2"> to give it
extra room. B<Do not> specify a width in any of your table cells, as
width management is handled by this class.

The general code for creating the form should be

    sub Form {
        my ($self) = @_;
        # Get the CGI object.
        my $cgi = @self->Q();
        # Start the form.
        my $retVal = $self->FormStart("form title");
        # Assemble the table rows.
        my @rows = ();
        ... push table row Html into @rows ...
        push @rows, $self->SubmitRow();
        ... push more Html into @rows ...
        # Build the table from the rows.
        $retVal .= $self->MakeTable(\@rows);
        # Close the form.
        $retVal .= $self->FormEnd();
        # Return the form Html.
        return $retVal;
    }

Several helper methods are provided for particular purposes.

L</NmpdrGenomeMenu> generates a control for selecting one or more genomes. Use
L</GetGenomes> to retrieve all the genomes passed in for a specified parameter
name. Note that as an assist to people working with GET-style links, if no
genomes are specified and the incoming request style is GET, all genomes will
be returned.

L</QueueFormScript> allows you to queue JavaScript statements for execution
after the form is fully generated. If you are using very complicated
form controls, the L</QueueFormScript> method allows you to perform
JavaScript initialization. The L</NmpdrGenomeMenu> control uses this
facility to display a list of the pre-selected genomes.

Finally, when generating the code for your controls, be sure to use any incoming
query parameters as default values so that the search request is persistent.

=head3 Finding Search Results

The L</Find> method is used to create the search results. The basic code
structure would work as follows.

    sub Find {
        my ($self) = @_;
        # Get the CGI and Sprout objects.
        my $cgi = $self->Q();
        my $sprout = $self->DB();
        # Declare the return variable. If it remains undefined, the caller will
        # know that an error occurred.
        my $retVal;
        ... validate the parameters ...
        if (... invalid parameters...) {
            $self->SetMessage(...appropriate message...);
        } else {
            # Determine the result type.
            my $rhelp = SearchHelper::GetHelper($self, RH => $resultType);
            # Specify the columns.
            $self->DefaultColumns($rhelp);
            # You may want to add extra columns. $name is the column name and
            # $loc is its location. The other parameters take their names from the
            # corresponding column methods.
            $rhelp->AddExtraColumn($name => $loc, style => $style, download => $flag,
                title => $title);
            # Some searches require optional columns that are configured by the
            # user or by the search query itself. There are some special methods
            # for this in the result helpers, but there's also the direct approach
            # shown below.
            $rhelp->AddOptionalColumn($name => $loc);
            # Initialize the session file.
            $self->OpenSession($rhelp);
            # Initialize the result counter.
            $retVal = 0;
            ... set up to loop through the results ...
            while (...more results...) {
                ...compute extra columns and call PutExtraColumns...
                $rhelp->PutData($sortKey, $objectID, $record);
                $retVal++;
            }
            # Close the session file.
            $self->CloseSession();
        }
        # Return the result count.
        return $retVal;
    }

A Find method is of course much more complicated than generating a form, and there
are variations on the above theme.

In addition to the finding and filtering, it is necessary to send status messages
to the output so that the user does not get bored waiting for results. The L</PrintLine>
method performs this function. The single parameter should be text to be
output to the browser. In general, you'll invoke it as follows.

    $self->PrintLine("...my message text...<br />");

The break tag is optional. When the Find method gets control, a paragraph will
have been started so that everything is XHTML-compliant.

The L</Find> method must return C<undef> if the search parameters are invalid. If this
is the case, then a message describing the problem should be passed to the framework
by calling L</SetMessage>. If the parameters are valid, then the method must return
the number of items found.

=cut

# This counter is used to insure every form on the page has a unique name.
my $formCount = 0;
# This counter is used to generate unique DIV IDs.
my $divCount = 0;

=head2 Public Methods

=head3 new

    my $shelp = SearchHelper->new($cgi);

Construct a new SearchHelper object.

=over 4

=item cgi

The CGI query object for the current script.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $cgi) = @_;
    # Check for a session ID. First we look in the CGI parameters.
    my $session_id = $cgi->param("SessionID");
    my $type = "old";
    if (! $session_id) {
        # We need a session ID. Try to get it from the cookies.
        my %cookies = fetch CGI::Cookie;
        my $session_cookie = $cookies{$class};
        if (! $session_cookie) {
            Trace("No session ID found.") if T(3);
            # Here we're starting a new session. We create the session ID and
            # store it in a cookie.
            $session_id = FIGRules::NewSessionID();
            Trace("New session ID is $session_id.") if T(3);
            $session_cookie = new CGI::Cookie(-name => $class,
                                              -value => $session_id);
            $session_cookie->bake();
        } else {
            # Here we're recovering an old session. The session ID is
            # used to find any old search options lying around, but we're
            # still considered a new session.
            $session_id = $session_cookie->value();
            Trace("Session $session_id recovered from cookie.") if T(3);
        }
        # Denote this is a new session.
        $type = "new";
        # Put the session ID in the parameters.
        $cgi->param(-name => 'SessionID', -value => $session_id);
    } else {
        Trace("Session ID is $session_id.") if T(3);
    }
    Trace("Computing subclass.") if T(3);
    # Compute the subclass name.
    my $subClass;
    if ($class =~ /SH(.+)$/) {
        # Here we have a real search class.
        $subClass = $1;
    } else {
        # Here we have a bare class. The bare class cannot search, but it can
        # process search results.
        $subClass = 'SearchHelper';
    }
    Trace("Subclass name is $subClass.") if T(3);
    # Insure everybody knows we're in Sprout mode.
    $cgi->param(-name => 'SPROUT', -value => 1);
    # Generate the form name.
    my $formName = "$class$formCount";
    $formCount++;
    Trace("Creating helper.") if T(3);
    # Create the shelp object. It contains the query object (with the session ID)
    # as well as an indicator as to whether or not the session is new, plus the
    # class name and a placeholder for the Sprout object.
    my $retVal = {
                  query => $cgi,
                  type => $type,
                  class => $subClass,
                  sprout => undef,
                  orgs => {},
                  name => $formName,
                  scriptQueue => [],
                  genomeList => undef,
                  genomeParms => [],
                  notices => [],
                 };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 Q

    my $query = $shelp->Q();

Return the CGI query object.

=cut

sub Q {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{query};
}


=head3 DB

    my $sprout = $shelp->DB();

Return the Sprout database object.

=cut

sub DB {
    # Get the parameters.
    my ($self) = @_;
    # Insure we have a database.
    my $retVal = $self->{sprout};
    if (! defined $retVal) {
        $retVal = SFXlate->new_sprout_only();
        $self->{sprout} = $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 IsNew

    my $flag = $shelp->IsNew();

Return TRUE if this is a new session, FALSE if this is an old session. An old
session already has search results ready to process.

=cut

sub IsNew {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return ($self->{type} eq 'new');
}

=head3 ID

    my $sessionID = $shelp->ID();

Return the current session ID.

=cut

sub ID {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->Q()->param("SessionID");
}

=head3 FormName

    my $name = $shelp->FormName();

Return the name of the form this helper object will generate.

=cut

sub FormName {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{name};
}

=head3 QueueFormScript

    $shelp->QueueFormScript($statement);

Add the specified statement to the queue of JavaScript statements that are to be
executed when the form has been fully defined. This is necessary because until
the closing </FORM> tag is emitted, the form elements cannot be referenced by
name. When generating the statement, you can refer to the variable C<thisForm>
in order to reference the form in progress. Thus,

    thisForm.simLimit.value = 1e-10;

would set the value of the form element C<simLimit> in the current form to
C<1e-10>.

=over 4

=item statement

JavaScript statement to be queued for execution after the form is built.
The trailing semi-colon is required. Theoretically, you could include
multiple statements separated by semi-colons, but one at a time works
just as well.

=back

=cut

sub QueueFormScript {
    # Get the parameters.
    my ($self, $statement) = @_;
    # Push the statement onto the script queue.
    push @{$self->{scriptQueue}}, $statement;
}

=head3 FormStart

    my $html = $shelp->FormStart($title);

Return the initial section of a form designed to perform another search of the
same type. The form header is included along with hidden fields to persist the
tracing, sprout status, and search class.

A call to L</FormEnd> is required to close the form.

=over 4

=item title

Title to be used for the form.

=item RETURN

Returns the initial HTML for the search form.

=back

=cut

sub FormStart {
    # Get the parameters.
    my ($self, $title) = @_;
    # Get the CGI object.
    my $cgi = $self->Q();
    # Start the form. Note we use the override option on the Class value, in
    # case the Advanced button was used.
    my $retVal = "<div class=\"search\">\n" .
                 CGI::start_form(-method => 'POST',
                                  -action => "$FIG_Config::cgi_url/wiki/rest.cgi/NmpdrPlugin/search",
                                  -name => $self->FormName(),
                                  -id => $self->FormName()) .
                 CGI::hidden(-name => 'Class',
                              -value => $self->{class}) .
                 CGI::hidden(-name => 'SPROUT',
                              -value => 1) .
                 CGI::h3("$title" . Hint($self->{class}));
    # Put in an anchor tag in case there's a table of contents.
    my $anchorName = $self->FormName();
    $retVal .= "<a name=\"$anchorName\"></a>\n";
    # Return the result.
    return $retVal;
}

=head3 FormEnd

    my $htmlText = $shelp->FormEnd();

Return the HTML text for closing a search form. This closes both the C<form> and
C<div> tags.

=cut

sub FormEnd {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable, closing the form and the DIV block.
    my $retVal = "</form></div>\n";
    # Now we flush out the statement queue.
    my @statements = @{$self->{scriptQueue}};
    if (@statements > 0) {
        # Switch to JavaScript and set the "thisForm" variable.
        $retVal .= "<SCRIPT language=\"JavaScript\">\n" .
                   "  thisForm = document.$self->{name};\n";
        # Unroll the statements.
        while (@statements > 0) {
            my $statement = shift @statements;
            $retVal .= "  $statement\n";
        }
        # Close the JavaScript.
        $retVal .= "</SCRIPT>\n";
    }
    # Return the result.
    return $retVal;
}

=head3 SetMessage

    $shelp->SetMessage($msg);

Store the specified text as the result message. The result message is displayed
if an invalid parameter value is specified.

=over 4

=item msg

Text of the result message to be displayed.

=back

=cut

sub SetMessage {
    # Get the parameters.
    my ($self, $msg) = @_;
    # Store the message.
    $self->{message} = $msg;
}

=head3 Message

    my $text = $shelp->Message();

Return the result message. The result message is displayed if an invalid parameter
value is specified.

=cut

sub Message {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{message};
}

=head3 OpenSession

    $shelp->OpenSession($rhelp);

Set up the session cache file and write out the column headers.
This method should not be called until all the columns have
been configured, including the extra columns.

=over 4

=item rhelp

Result helper for formatting the output. This has the column
headers stored in it.

=back

=cut

sub OpenSession {
    # Get the parameters.
    my ($self, $rhelp) = @_;
    # Insure the result helper is valid.
    if (! defined($rhelp)) {
        Confess("No result type specified for $self->{class}.");
    } elsif(! $rhelp->isa('ResultHelper')) {
        Confess("Invalid result type specified for $self->{class}.");
    } else {
        # Get the column headers and write them out.
        my $colHdrs = $rhelp->GetColumnHeaders();
        Trace(scalar(@{$colHdrs}) . " column headers written to output.") if T(3);
        $self->WriteColumnHeaders(@{$colHdrs});
    }
}

=head3 GetCacheFileName

    my $fileName = $shelp->GetCacheFileName();

Return the name to be used for this session's cache file.

=cut

sub GetCacheFileName {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->GetTempFileName('cache');
}

=head3 GetTempFileName

    my $fileName = $shelp->GetTempFileName($type);

Return the name to be used for a temporary file of the specified type. The
name is computed from the session name with the type as a suffix.

=over 4

=item type

Type of temporary file to be generated.

=item RETURN

Returns a file name generated from the session name and the specified type.

=back

=cut

sub GetTempFileName {
    # Get the parameters.
    my ($self, $type) = @_;
    # Compute the file name. Note it gets stuffed in the FIG temporary
    # directory.
    my $retVal = FIGRules::GetTempFileName(sessionID => $self->ID(), extension => $type);
    # Return the result.
    return $retVal;
}

=head3 WriteColumnHeaders

    $shelp->WriteColumnHeaders(@colNames);

Write out the column headers for the current search session. The column headers
are sent to the cache file, and then the cache is re-opened as a sort pipe and
the handle saved.

=over 4

=item colNames

A list of column names in the desired presentation order. For extra columns,
the column name is the hash supplied as the column definition.

=back

=cut

sub WriteColumnHeaders {
    # Get the parameters.
    my ($self, @colNames) = @_;
    # Get the cache file name and open it for output.
    my $fileName = $self->GetCacheFileName();
    my $handle1 = Open(undef, ">$fileName");
    # Freeze the column headers.
    my @colHdrs = map { freeze($_) } @colNames;
    # Write the column headers and close the file.
    Tracer::PutLine($handle1, \@colHdrs);
    close $handle1;
    # Now open the sort pipe and save the file handle. Note how we append the
    # sorted data to the column header row already in place. The output will
    # contain a sort key followed by the real columns. The sort key is
    # hacked off before going to the output file.
    $self->{fileHandle} = Open(undef, "| sort | cut --fields=2- >>$fileName");
}

=head3 SetNotice

    $shelp->SetNotice($message);

This method creates a notice that will be displayed on the search results
page. After the search is complete, notices are placed in a small temporary
file that is checked by the results display engine.

=over 4

=item message

Message to write to the notice file.

=back

=cut

sub SetNotice {
    # Get the parameters.
    my ($self, $message) = @_;
    # Save the message.
    push @{$self->{notices}}, $message;
}


=head3 ReadColumnHeaders

    my @colHdrs = $shelp->ReadColumnHeaders($fh);

Read the column headers from the specified file handle. The column headers are
frozen strings intermixed with frozen hash references. The strings represent
column names defined in the result helper. The hash references represent the
definitions of the extra columns.

=over 4

=item fh

File handle from which the column headers are to be read.

=item RETURN

Returns a list of the column headers pulled from the specified file's first line.

=back

=cut

sub ReadColumnHeaders {
    # Get the parameters.
    my ($self, $fh) = @_;
    # Read and thaw the columns.
    my @retVal = map { thaw($_) } Tracer::GetLine($fh);
    # Return them to the caller.
    return @retVal;
}

=head3 WriteColumnData

    $shelp->WriteColumnData($key, @colValues);

Write a row of column values to the current search session. It is assumed that
the session file is already open for output.

=over 4

=item key

Sort key.

=item colValues

List of column values to write to the search result cache file for this session.

=back

=cut

sub WriteColumnData {
    # Get the parameters.
    my ($self, $key, @colValues) = @_;
    # Write them to the cache file.
    Tracer::PutLine($self->{fileHandle}, [$key, @colValues]);
    Trace("Column data is " . join("; ", $key, @colValues) . ".") if T(4);
}

=head3 CloseSession

    $shelp->CloseSession();

Close the session file.

=cut

sub CloseSession {
    # Get the parameters.
    my ($self) = @_;
    # Check for an open session file.
    if (defined $self->{fileHandle}) {
        # We found one, so close it.
        Trace("Closing session file.") if T(2);
        close $self->{fileHandle};
        # Tell the user.
        my $cgi = $self->Q();
        $self->PrintLine("Output formatting complete.<br />");
    }
    # Check for notices.
    my @notices = @{$self->{notices}};
    if (scalar @notices) {
        # We have some, so put then in a notice file.
        my $noticeFile = $self->GetTempFileName('notices');
        my $nh = Open(undef, ">$noticeFile");
        print $nh join("\n", @notices, "");
        close $nh;
        $self->PrintLine(scalar(@notices) . " notices saved.<br />");
    }
}

=head3 OrganismData

    my ($orgName, $group) = $shelp->Organism($genomeID);

Return the name and status of the organism corresponding to the specified genome ID.
For performance reasons, this information is cached in a special hash table, so we
only compute it once per run.

=over 4

=item genomeID

ID of the genome whose name is desired.

=item RETURN

Returns a list of three items. The first item in the list is the organism name,
and the second is the name of the NMPDR group, or an empty string if the
organism is not in an NMPDR group. The third item is the organism's domain.

=back

=cut

sub OrganismData {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Declare the return variables.
    my ($orgName, $group, $domain);
    # Check the cache.
    my $cache = $self->{orgs};
    if (exists $cache->{$genomeID}) {
        ($orgName, $group, $domain) = @{$cache->{$genomeID}};
        Trace("Cached organism $genomeID has group \"$group\".") if T(4);
    } else {
        # Here we have to use the database.
        my $sprout = $self->DB();
        my ($genus, $species, $strain, $newGroup, $taxonomy) = $sprout->GetEntityValues('Genome', $genomeID,
                                                                ['Genome(genus)', 'Genome(species)',
                                                                 'Genome(unique-characterization)',
                                                                 'Genome(primary-group)',
                                                                 'Genome(taxonomy)']);
        # Format and cache the name and display group.
        Trace("Caching organism $genomeID with group \"$newGroup\".") if T(4);
        ($orgName, $group, $domain) = $self->SaveOrganismData($newGroup, $genomeID, $genus, $species,
                                                              $strain, $taxonomy);
        Trace("Returning group $group.") if T(4);
    }
    # Return the result.
    return ($orgName, $group, $domain);
}

=head3 Organism

    my $orgName = $shelp->Organism($genomeID);

Return the name of the relevant organism. The name is computed from the genus,
species, and unique characterization. A cache is used to improve performance.

=over 4

=item genomeID

ID of the genome whose name is desired.

=item RETURN

Returns the display name of the specified organism.

=back

=cut

sub Organism {
    # Get the parameters.
    my ($self, $genomeID) = @_;
    # Get the organism data.
    my ($retVal) = $self->OrganismData($genomeID);
    # Return the result.
    return $retVal;
}

=head3 ComputeFASTA

    my $fasta = $shelp->ComputeFASTA($desiredType, $sequence, $flankingWidth, $comments);

Parse a sequence input and convert it into a FASTA string of the desired type with
the desired flanking width.

=over 4

=item desiredType

C<dna> to return a DNA sequence, C<prot> to return a protein sequence, C<dnaPattern>
to return a DNA search pattern, C<protPattern> to return a protein search pattern.

=item sequence

Sequence to return. It may be a DNA or protein sequence in FASTA form or a feature ID.
If a feature ID is specified, the feature's DNA or translation will be returned. The
feature ID is recognized by the presence of a vertical bar in the input. Otherwise,
if the input does not begin with a greater-than sign (FASTA label line), a default label
line will be provided.

=item flankingWidth

If the DNA FASTA of a feature is desired, the number of base pairs to either side of the
feature that should be included. Currently we can't do this for Proteins because the
protein translation of a feature doesn't always match the DNA and is taken directly
from the database.

=item comments

Comment string to be added to the FASTA header.

=item RETURN

Returns a string in FASTA format representing the content of the desired sequence with
an appropriate label. If the input is invalid, a message will be stored and we will
return C<undef>. Note that the output will include a trailing new-line.

=back

=cut

sub ComputeFASTA {
    # Get the parameters.
    my ($self, $desiredType, $sequence, $flankingWidth, $comment) = @_;
    # Declare the return variable. If an error occurs, it will remain undefined.
    my $retVal;
    # This variable will be cleared if an error is detected.
    my $okFlag = 1;
    # Create variables to hold the FASTA label and data.
    my ($fastaLabel, $fastaData);
    Trace("FASTA desired type is $desiredType.") if T(4);
    # Check for a feature specification. The smoking gun for that is a vertical bar.
    if ($sequence =~ /^\s*(\w+\|\S+)\s*$/) {
        # Here we have a feature ID in $1. We'll need a Sprout object to process it.
        my $fid = $1;
        Trace("Feature ID for fasta is $fid.") if T(3);
        my $sprout = $self->DB();
        # Get the FIG ID. Note that we only use the first feature found. We are not
        # supposed to have redundant aliases, though we may have an ID that doesn't
        # exist.
        my ($figID) = $sprout->FeaturesByAlias($fid);
        if (! $figID) {
            $self->SetMessage("No gene found with the ID \"$fid\".");
            $okFlag = 0;
        } else {
            # Set the FASTA label. The ID is the first favored alias.
            my $favored = $self->Q()->param('FavoredAlias') || 'fig';
            my $favorLen = length $favored;
            ($fastaLabel) = grep { substr($_, 0, $favorLen) eq $favored } $sprout->FeatureAliases($fid);
            if (! $fastaLabel) {
                # In an emergency, fall back to the original ID.
                $fastaLabel = $fid;
            }
            # Add any specified comments.
            if ($comment) {
                $fastaLabel .= " $comment";
            }
            # Now proceed according to the sequence type.
            if ($desiredType =~ /prot/) {
                # We want protein, so get the translation.
                $fastaData = $sprout->FeatureTranslation($figID);
                Trace(length $fastaData . " characters returned for translation of $fastaLabel.") if T(3);
            } elsif ($desiredType =~ /dna/) {
                # We want DNA, so get the DNA sequence. This is a two-step process. First, we get the
                # locations.
                my @locList = $sprout->FeatureLocation($figID);
                if ($flankingWidth > 0) {
                    # Here we need to add flanking data. Convert the locations to a list
                    # of location objects.
                    my @locObjects = map { BasicLocation->new($_) } @locList;
                    # Initialize the return variable. We will put the DNA in here segment by segment.
                    $fastaData = "";
                    # Now we widen each location by the flanking width and stash the results. This
                    # requires getting the contig length for each contig so we don't fall off the end.
                    for my $locObject (@locObjects) {
                        Trace("Current location is " . $locObject->String . ".") if T(4);
                        # Remember the current start and length.
                        my ($start, $len) = ($locObject->Left, $locObject->Length);
                        # Get the contig length.
                        my $contigLen = $sprout->ContigLength($locObject->Contig);
                        # Widen the location and get its DNA.
                        $locObject->Widen($flankingWidth, $contigLen);
                        my $fastaSegment = $sprout->DNASeq([$locObject->String()]);
                        # Now we need to do some case changing. The main DNA is upper case and
                        # the flanking DNA is lower case.
                        my $leftFlank = $start - $locObject->Left;
                        my $rightFlank = $leftFlank + $len;
                        Trace("Wide location is " . $locObject->String . ". Flanks are $leftFlank and $rightFlank. Contig len is $contigLen.") if T(4);
                        my $fancyFastaSegment = lc(substr($fastaSegment, 0, $leftFlank)) .
                                                uc(substr($fastaSegment, $leftFlank, $rightFlank - $leftFlank)) .
                                                lc(substr($fastaSegment, $rightFlank));
                        $fastaData .= $fancyFastaSegment;
                    }
                } else {
                    # Here we have just the raw sequence.
                    $fastaData = $sprout->DNASeq(\@locList);
                }
                Trace((length $fastaData) . " characters returned for DNA of $fastaLabel.") if T(3);
            }
        }
    } else {
        Trace("Analyzing FASTA sequence.") if T(4);
        # Here we are expecting a FASTA. We need to see if there's a label.
        if ($sequence =~ /^>[\n\s]*(\S[^\n]*)\n(.+)$/s) {
            Trace("Label \"$1\" found in match to sequence:\n$sequence") if T(4);
            # Here we have a label, so we split it from the data.
            $fastaLabel = $1;
            $fastaData = $2;
        } else {
            Trace("No label found in match to sequence:\n$sequence") if T(4);
            # Here we have no label, so we create one and use the entire sequence
            # as data.
            $fastaLabel = "$desiredType sequence specified by user";
            $fastaData = $sequence;
        }
        # If we are not doing a pattern search, we need to clean the junk out of the sequence.
        if ($desiredType !~ /pattern/i) {
            $fastaData =~ s/\n//g;
            $fastaData =~ s/\s+//g;
            $fastaData =~ s/\d+//g;
        }
        # Finally, verify that it's DNA if we're doing DNA stuff.
        if ($desiredType eq 'dna' && $fastaData =~ /[^agctxn-]/i) {
            $self->SetMessage("Invalid characters detected. Is the input really a DNA sequence?");
            $okFlag = 0;
        }
    }
    Trace("FASTA data sequence: $fastaData") if T(4);
    # Only proceed if no error was detected.
    if ($okFlag) {
        if ($desiredType =~ /pattern/i) {
            # For a scan, there is no label and no breakup.
            $retVal = $fastaData;
        } else {
            # We need to format the sequence into 60-byte chunks. We use the infamous
            # grep-split trick. The split, because of the presence of the parentheses,
            # includes the matched delimiters in the output list. The grep strips out
            # the empty list items that appear between the so-called delimiters, since
            # the delimiters are what we want.
            my @chunks = grep { $_ } split /(.{1,60})/, $fastaData;
            $retVal = join("\n", ">$fastaLabel", @chunks, "");
        }
    }
    # Return the result.
    return $retVal;
}

=head3 SubsystemTree

    my $tree = SearchHelper::SubsystemTree($sprout, %options);

This method creates a subsystem selection tree suitable for passing to
L</SelectionTree>. Each leaf node in the tree will have a link to the
subsystem display page. In addition, each node can have a radio button. The
radio button alue is either C<classification=>I<string>, where I<string> is
a classification string, or C<id=>I<string>, where I<string> is a subsystem ID.
Thus, it can either be used to filter by a group of related subsystems or a
single subsystem.

=over 4

=item sprout

Sprout database object used to get the list of subsystems.

=item options

Hash containing options for building the tree.

=item RETURN

Returns a reference to a tree list suitable for passing to L</SelectionTree>.

=back

The supported options are as follows.

=over 4

=item radio

TRUE if the tree should be configured for radio buttons. The default is FALSE.

=item links

TRUE if the tree should be configured for links. The default is TRUE.

=back

=cut

sub SubsystemTree {
    # Get the parameters.
    my ($sprout, %options) = @_;
    # Process the options.
    my $optionThing = Tracer::GetOptions({ radio => 0, links => 1 }, \%options);
    # Read in the subsystems.
    my @subs = $sprout->GetAll(['Subsystem'], "ORDER BY Subsystem(classification), Subsystem(id)", [],
                               ['Subsystem(classification)', 'Subsystem(id)']);
    # Put any unclassified subsystems at the end. They will always be at the beginning, so if one
    # is at the end, ALL subsystems are unclassified and we don't bother.
    if ($#subs >= 0 && $subs[$#subs]->[0] ne '') {
        while ($subs[0]->[0] eq '') {
            my $classLess = shift @subs;
            push @subs, $classLess;
        }
    }
    # Get the seedviewer URL.
    my $svURL = $FIG_Config::linkinSV || "$FIG_Config::cgi_url/seedviewer.cgi";
    Trace("Seed Viewer URL is $svURL.") if T(3);
    # Declare the return variable.
    my @retVal = ();
    # Each element in @subs represents a leaf node, so as we loop through it we will be
    # producing one leaf node at a time. The leaf node is represented as a 2-tuple. The
    # first element is a semi-colon-delimited list of the classifications for the
    # subsystem. There will be a stack of currently-active classifications, which we will
    # compare to the incoming classifications from the end backward. A new classification
    # requires starting a new branch. A different classification requires closing an old
    # branch and starting a new one. Each classification in the stack will also contain
    # that classification's current branch. We'll add a fake classification at the
    # beginning that we can use to represent the tree as a whole.
    my $rootName = '<root>';
    # Create the classification stack. Note the stack is a pair of parallel lists,
    # one containing names and the other containing content.
    my @stackNames = ($rootName);
    my @stackContents = (\@retVal);
    # Add a null entry at the end of the subsystem list to force an unrolling.
    push @subs, ['', undef];
    # Loop through the subsystems.
    for my $sub (@subs) {
        # Pull out the classification list and the subsystem ID.
        my ($classString, $id) = @{$sub};
        Trace("Processing class \"$classString\" and subsystem $id.") if T(4);
        # Convert the classification string to a list with the root classification in
        # the front.
        my @classList = ($rootName, split($FIG_Config::splitter, $classString));
        # Find the leftmost point at which the class list differs from the stack.
        my $matchPoint = 0;
        while ($matchPoint <= $#stackNames && $matchPoint <= $#classList &&
               $stackNames[$matchPoint] eq $classList[$matchPoint]) {
            $matchPoint++;
        }
        Trace("Match point is $matchPoint. Stack length is " . scalar(@stackNames) .
              ". Class List length is " . scalar(@classList) . ".") if T(4);
        # Unroll the stack to the matchpoint.
        while ($#stackNames >= $matchPoint) {
            my $popped = pop @stackNames;
            pop @stackContents;
            Trace("\"$popped\" popped from stack.") if T(4);
        }
        # Start branches for any new classifications.
        while ($#stackNames < $#classList) {
            # The branch for a new classification contains its radio button
            # data and then a list of children. So, at this point, if radio buttons
            # are desired, we put them into the content.
            my $newLevel = scalar(@stackNames);
            my @newClassContent = ();
            if ($optionThing->{radio}) {
                my $newClassString = join($FIG_Config::splitter, @classList[1..$newLevel]);
                push @newClassContent, { value => "classification=$newClassString%" };
            }
            # The new classification node is appended to its parent's content
            # and then pushed onto the stack. First, we need the node name.
            my $nodeName = $classList[$newLevel];
            # Add the classification to its parent. This makes it part of the
            # tree we'll be returning to the user.
            push @{$stackContents[$#stackNames]}, $nodeName, \@newClassContent;
            # Push the classification onto the stack.
            push @stackContents, \@newClassContent;
            push @stackNames, $nodeName;
            Trace("\"$nodeName\" pushed onto stack.") if T(4);
        }
        # Now the stack contains all our parent branches. We add the subsystem to
        # the branch at the top of the stack, but only if it's NOT the dummy node.
        if (defined $id) {
            # Compute the node name from the ID.
            my $nodeName = $id;
            $nodeName =~ s/_/ /g;
            # Create the node's leaf hash. This depends on the value of the radio
            # and link options.
            my $nodeContent = {};
            if ($optionThing->{links}) {
                # Compute the link value.
                my $linkable = uri_escape($id);
                $nodeContent->{link} = "$svURL?page=Subsystems;subsystem=$linkable";
            }
            if ($optionThing->{radio}) {
                # Compute the radio value.
                $nodeContent->{value} = "id=$id";
            }
            # Push the node into its parent branch.
            Trace("\"$nodeName\" added to node list.") if T(4);
            push @{$stackContents[$#stackNames]}, $nodeName, $nodeContent;
        }
    }
    # Return the result.
    return \@retVal;
}


=head3 NmpdrGenomeMenu

    my $htmlText = $shelp->NmpdrGenomeMenu($menuName, $multiple, \@selected, $rows);

This method creates a hierarchical HTML menu for NMPDR genomes organized by category. The
category indicates the low-level NMPDR group. Organizing the genomes in this way makes it
easier to select all genomes from a particular category.

=over 4

=item menuName

Name to give to the menu.

=item multiple

TRUE if the user is allowed to select multiple genomes, else FALSE.

=item selected

Reference to a list containing the IDs of the genomes to be pre-selected. If the menu
is not intended to allow multiple selections, the list should be a singleton. If the
list is empty, nothing will be pre-selected.

=item rows (optional)

Number of rows to display. If omitted, the default is 1 for a single-select list
and 10 for a multi-select list.

=item crossMenu (optional)

This is currently not supported.

=item RETURN

Returns the HTML text to generate a C<SELECT> menu inside a form.

=back

=cut

sub NmpdrGenomeMenu {
    # Get the parameters.
    my ($self, $menuName, $multiple, $selected, $rows, $cross) = @_;
    # Get the Sprout and CGI objects.
    my $sprout = $self->DB();
    my $cgi = $self->Q();
    # Compute the row count.
    if (! defined $rows) {
        $rows = ($multiple ? 10 : 1);
    }
    # Get a comma-delimited list of the preselected genomes.
    my $preselected = "";
    if ($selected) {
        $preselected = join(", ", @$selected);
    }
    # Ask Sprout for a genome menu.
    my $retVal = $sprout->GenomeMenu(name => $menuName,
                                     multiSelect => $multiple,
                                     selected => $preselected,
                                     size => $rows);
    # Return the result.
    return $retVal;
}

=head3 MakeTable

    my $htmlText = $shelp->MakeTable(\@rows);

Create a table from a group of table rows. The table rows must be fully pre-formatted: in
other words, each must have the TR and TD tags included.

The purpose of this method is to provide a uniform look for search form tables. It is
almost impossible to control a table using styles, so rather than have a table style,
we create the TABLE tag in this method. Note also that the first TD or TH in each row will
be updated with an explicit width so the forms look pretty when they are all on one
page.

=over 4

=item rows

Reference to a list of table rows. Each table row must be in HTML form with all
the TR and TD tags set up. The first TD or TH tag in the first non-colspanned row
will be modified to set the width. Everything else will be left as is.

=item RETURN

Returns the full HTML for a table in the approved NMPDR Search Form style.

=back

=cut

sub MakeTable {
    # Get the parameters.
    my ($self, $rows) = @_;
    # Get the CGI object.
    my $cgi = $self->Q();
    # The first column of the first row must have its width fixed.
    # This flag will be set to FALSE when that happens.
    my $needWidth = 1;
    # modifier becase we only want to change the first tag. Also, if a width
    # is already specified on the first column bad things will happen.
    for my $row (@{$rows}) {
        # See if this row needs a width.
        if ($needWidth && $row =~ /<(td|th) ([^>]+)>/i) {
            # Here we have a first cell and its tag parameters are in $2.
            my $elements = $2;
            if ($elements !~ /colspan/i) {
                Trace("No colspan tag found in element \'$elements\'.") if T(3);
                # Here there's no colspan, so we plug in the width. We
                # eschew the "g" modifier on the substitution because we
                # only want to update the first cell.
                $row =~ s/(<(td|th))/$1 width="150"/i;
                # Denote we don't need this any more.
                $needWidth = 0;
            }
        }
    }
    # Create the table.
    my $retVal = CGI::table({border => 2, cellspacing => 2,
                              width => 700, class => 'search'},
                             @{$rows});
    # Return the result.
    return $retVal;
}

=head3 SubmitRow

    my $htmlText = $shelp->SubmitRow($caption);

Returns the HTML text for the row containing the page size control
and the submit button. All searches should have this row somewhere
near the top of the form.

=over 4

=item caption (optional)

Caption to be put on the search button. The default is C<Go>.

=item RETURN

Returns a table row containing the controls for submitting the search
and tuning the results.

=back

=cut

sub SubmitRow {
    # Get the parameters.
    my ($self, $caption) = @_;
    my $cgi = $self->Q();
    # Compute the button caption.
    my $realCaption = (defined $caption ? $caption : 'Go');
    # Get the current page size.
    my $pageSize = $cgi->param('PageSize');
    # Get the form name.
    my $formName = $self->FormName();
    # Get the current feature ID type.
    my $aliasType = $self->GetPreferredAliasType();
    # Create the rows.
    my $retVal = CGI::Tr(CGI::td("Identifier Type "),
                          CGI::td({ colspan => 2 },
                                   CGI::popup_menu(-name => 'AliasType',
                                                    -values => ['FIG', AliasAnalysis::AliasTypes() ],
                                                    -default => $aliasType) .
                                   Hint("Identifier Type", 27))) .
                 "\n" .
                 CGI::Tr(CGI::td("Results/Page"),
                          CGI::td(CGI::popup_menu(-name => 'PageSize',
                                                  -values => [50, 10, 25, 100, 1000],
                                                  -default => $pageSize)),
                          CGI::td(CGI::submit(-class => 'goButton',
                                                -name => 'Search',
                                                -value => $realCaption)));
    # Return the result.
    return $retVal;
}

=head3 GetGenomes

    my @genomeList = $shelp->GetGenomes($parmName);

Return the list of genomes specified by the specified CGI query parameter.
If the request method is POST, then the list of genome IDs is returned
without preamble. If the request method is GET and the parameter is not
specified, then it is treated as a request for all genomes. This makes it
easier for web pages to link to a search that wants to specify all genomes.

=over 4

=item parmName

Name of the parameter containing the list of genomes. This will be the
first parameter passed to the L</NmpdrGenomeMenu> call that created the
genome selection control on the form.

=item RETURN

Returns a list of the genomes to process.

=back

=cut

sub GetGenomes {
    # Get the parameters.
    my ($self, $parmName) = @_;
    # Get the CGI query object.
    my $cgi = $self->Q();
    # Get the list of genome IDs in the request header.
    my @retVal = $cgi->param($parmName);
    Trace("Genome list for $parmName is (" . join(", ", @retVal) . ") with method " . $cgi->request_method() . ".") if T(3);
    # Check for the special GET case.
    if ($cgi->request_method() eq "GET" && ! @retVal) {
        # Here the caller wants all the genomes.
        my $sprout = $self->DB();
        @retVal = $sprout->Genomes();
    }
    # Return the result.
    return @retVal;
}

=head3 ComputeSearchURL

    my $url = $shelp->ComputeSearchURL(%overrides);

Compute the GET-style URL for the current search. In order for this to work, there
must be a copy of the search form on the current page. This will always be the
case if the search is coming from C<SearchSkeleton.cgi>.

A little expense is involved in order to make the URL as smart as possible. The
main complication is that if the user specified all genomes, we'll want to
remove the parameter entirely from a get-style URL.

=over 4

=item overrides

Hash containing override values for the parameters, where the parameter name is
the key and the parameter value is the override value. If the override value is
C<undef>, the parameter will be deleted from the result.

=item RETURN

Returns a GET-style URL for invoking the search with the specified overrides.

=back

=cut

sub ComputeSearchURL {
    # Get the parameters.
    my ($self, %overrides) = @_;
    # Get the database and CGI query object.
    my $cgi = $self->Q();
    my $sprout = $self->DB();
    # Start with the full URL.
    my $retVal = "$FIG_Config::cgi_url/SearchSkeleton.cgi";
    # Get all the query parameters in a hash.
    my %parms = $cgi->Vars();
    # Now we need to do some fixing. Each multi-valued parameter is encoded as a string with null
    # characters separating the individual values. We have to convert those to lists. In addition,
    # the multiple-selection genome parameters and the feature type parameter must be checked to
    # determine whether or not they can be removed from the URL. First, we get a list of the
    # genome parameters and a list of all genomes. Note that we only need the list if a
    # multiple-selection genome parameter has been found on the form.
    my %genomeParms = map { $_ => 1 } @{$self->{genomeParms}};
    my @genomeList;
    if (keys %genomeParms) {
        @genomeList = $sprout->Genomes();
    }
    # Create a list to hold the URL parameters we find.
    my @urlList = ();
    # Now loop through the parameters in the hash, putting them into the output URL.
    for my $parmKey (keys %parms) {
        # Get a list of the parameter values. If there's only one, we'll end up with
        # a singleton list, but that's okay.
        my @values = split (/\0/, $parms{$parmKey});
        # Check for special cases.
        if (grep { $_ eq $parmKey } qw(SessionID ResultCount Page PageSize Trace TF)) {
            # These are bookkeeping parameters we don't need to start a search.
            @values = ();
        } elsif ($parmKey =~ /_SearchThing$/) {
            # Here the value coming in is from a genome control's search thing. It does
            # not affect the results of the search, so we clear it.
            @values = ();
        } elsif ($genomeParms{$parmKey}) {
            # Here we need to see if the user wants all the genomes. If he does,
            # we erase all the values just like with features.
            my $allFlag = $sprout->IsAllGenomes(\@values, \@genomeList);
            if ($allFlag) {
                @values = ();
            }
        } elsif (exists $overrides{$parmKey}) {
            # Here the value is being overridden, so we skip it for now.
            @values = ();
        }
        # If we still have values, create the URL parameters.
        if (@values) {
            push @urlList, map { "$parmKey=" . uri_escape($_) } @values;
        }
    }
    # Now do the overrides.
    for my $overKey (keys %overrides) {
        # Only use this override if it's not a delete marker.
        if (defined $overrides{$overKey}) {
            push @urlList, "$overKey=" . uri_escape($overrides{$overKey});
        }
    }
    # Add the parameters to the URL.
    $retVal .= "?" . join(";", @urlList);
    # Return the result.
    return $retVal;
}

=head3 AdvancedClassList

    my @classes = SearchHelper::AdvancedClassList();

Return a list of advanced class names. This list is used to generate the directory
of available searches on the search page.

We do a file search to accomplish this, but to pull it off we need to look at %INC.

=cut

sub AdvancedClassList {
    # Determine the search helper module directory.
    my $libDirectory = $INC{'SearchHelper.pm'};
    $libDirectory =~ s/SearchHelper\.pm//;
    # Read it, keeping only the helper modules.
    my @modules = grep { /^SH\w+\.pm/ } Tracer::OpenDir($libDirectory, 0);
    # Convert the file names to search types.
    my @retVal = map { $_ =~ /^SH(\w+)\.pm/; $1 } @modules;
    # Return the result in alphabetical order.
    return sort @retVal;
}

=head3 SelectionTree

    my $htmlText = SearchHelper::SelectionTree($cgi, \%tree, %options);

Display a selection tree.

This method creates the HTML for a tree selection control. The tree is implemented as a set of
nested HTML unordered lists. Each selectable element of the tree will contain a radio button. In
addition, some of the tree nodes can contain hyperlinks.

The tree itself is passed in as a multi-level list containing node names followed by
contents. Each content element is a reference to a similar list. The first element of
each list may be a hash reference. If so, it should contain one or both of the following
keys.

=over 4

=item link

The navigation URL to be popped up if the user clicks on the node name.

=item value

The form value to be returned if the user selects the tree node.

=back

The presence of a C<link> key indicates the node name will be hyperlinked. The presence of
a C<value> key indicates the node name will have a radio button. If a node has no children,
you may pass it a hash reference instead of a list reference.

The following example shows the hash for a three-level tree with links on the second level and
radio buttons on the third.

    [   Objects => [
            Entities => [
                {link => "../docs/WhatIsAnEntity.html"},
                Genome => {value => 'GenomeData'},
                Feature => {value => 'FeatureData'},
                Contig => {value => 'ContigData'},
            ],
            Relationships => [
                {link => "../docs/WhatIsARelationShip.html"},
                HasFeature => {value => 'GenomeToFeature'},
                IsOnContig => {value => 'FeatureToContig'},
            ]
        ]
    ]

Note how each leaf of the tree has a hash reference for its value, while the branch nodes
all have list references.

This next example shows how to set up a taxonomy selection field. The value returned
by the tree control will be the taxonomy string for the selected node ready for use
in a LIKE-style SQL filter. Only the single branch ending in campylobacter is shown for
reasons of space.

    [   All => [
            {value => "%"},
            Bacteria => [
                {value => "Bacteria%"},
                Proteobacteria => [
                    {value => "Bacteria; Proteobacteria%"},
                    Epsilonproteobacteria => [
                        {value => "Bacteria; Proteobacteria;Epsilonproteobacteria%"},
                        Campylobacterales => [
                            {value => "Bacteria; Proteobacteria; Epsilonproteobacteria; Campylobacterales%"},
                            Campylobacteraceae =>
                                {value => "Bacteria; Proteobacteria; Epsilonproteobacteria; Campylobacterales; Campylobacteraceae%"},
                            ...
                        ]
                        ...
                    ]
                    ...
                ]
                ...
            ]
            ...
        ]
    ]


This method of tree storage allows the caller to control the order in which the tree nodes
are displayed and to completely control value selection and use of hyperlinks. It is, however
a bit complicated. Eventually, tree-building classes will be provided to simplify things.

The parameters to this method are as follows.

=over 4

=item cgi

CGI object used to generate the HTML.

=item tree

Reference to a hash describing a tree. See the description above.

=item options

Hash containing options for the tree display.

=back

The allowable options are as follows

=over 4

=item nodeImageClosed

URL of the image to display next to the tree nodes when they are collapsed. Clicking
on the image will expand a section of the tree. The default is C<plus.gif>.

=item nodeImageOpen

URL of the image to display next to the tree nodes when they are expanded. Clicking
on the image will collapse a section of the tree. The default is C<minus.gif>.

=item style

Style to use for the tree. The default is C<tree>. Because the tree style is implemented
as nested lists, the key components of this style are the definitions for the C<ul> and
C<li> tags. The default style file contains the following definitions.

    .tree ul {
       margin-left: 0; padding-left: 22px
    }
    .tree li {
        list-style-type: none;
    }

The default image is 22 pixels wide, so in the above scheme each tree level is indented from its
parent by the width of the node image. This use of styles limits the things we can do in formatting
the tree, but it has the advantage of vastly simplifying the tree creation.

=item name

Field name to give to the radio buttons in the tree. The default is C<selection>.

=item target

Frame target for links. The default is C<_self>.

=item selected

If specified, the value of the radio button to be pre-selected.

=back

=cut

sub SelectionTree {
    # Get the parameters.
    my ($cgi, $tree, %options) = @_;
    # Get the options.
    my $optionThing = Tracer::GetOptions({ name => 'selection',
                                           nodeImageClosed => "$FIG_Config::cgi_url/Html/plus.gif",
                                           nodeImageOpen => "$FIG_Config::cgi_url/Html/minus.gif",
                                           style => 'tree',
                                           target => '_self',
                                           selected => undef},
                                         \%options);
    # Declare the return variable. We'll do the standard thing with creating a list
    # of HTML lines and rolling them together at the end.
    my @retVal = ();
    # Only proceed if the tree is present.
    if (defined($tree)) {
        # Validate the tree.
        if (ref $tree ne 'ARRAY') {
            Confess("Selection tree is not a list reference.");
        } elsif (scalar @{$tree} == 0) {
            # The tree is empty, so we do nothing.
        } elsif ($tree->[0] eq 'HASH') {
            Confess("Hash reference found at start of selection tree. The tree as a whole cannot have attributes, only tree nodes.");
        } else {
            # Here we have a real tree. Apply the tree style.
            push @retVal, CGI::start_div({ class => $optionThing->{style} });
            # Give us a DIV ID.
            my $divID = GetDivID($optionThing->{name});
            # Show the tree.
            push @retVal, ShowBranch($cgi, "(root)", $divID, $tree, $optionThing, 'block');
            # Close the DIV block.
            push @retVal, CGI::end_div();
        }
    }
    # Return the result.
    return join("\n", @retVal, "");
}

=head3 ShowBranch

    my @htmlLines = SearchHelper::ShowBranch($cgi, $label, $id, $branch, $options, $displayType);

This is a recursive method that displays a branch of the tree.

=over 4

=item cgi

CGI object used to format HTML.

=item label

Label of this tree branch. It is only used in error messages.

=item id

ID to be given to this tree branch. The ID is used in the code that expands and collapses
tree nodes.

=item branch

Reference to a list containing the content of the tree branch. The list contains an optional
hash reference that is ignored and the list of children, each child represented by a name
and then its contents. The contents could by a hash reference (indicating the attributes
of a leaf node), or another tree branch.

=item options

Options from the original call to L</SelectionTree>.

=item displayType

C<block> if the contents of this list are to be displayed, C<none> if they are to be
hidden.

=item RETURN

Returns one or more HTML lines that can be used to display the tree branch.

=back

=cut

sub ShowBranch {
    # Get the parameters.
    my ($cgi, $label, $id, $branch, $options, $displayType) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Start the branch.
    push @retVal, CGI::start_ul({ id => $id, style => "display:$displayType" });
    # Check for the hash and choose the start location accordingly.
    my $i0 = (ref $branch->[0] eq 'HASH' ? 1 : 0);
    # Get the list length.
    my $i1 = scalar(@{$branch});
    # Verify we have an even number of elements.
    if (($i1 - $i0) % 2 != 0) {
        Trace("Branch elements are from $i0 to $i1.") if T(3);
        Confess("Odd number of elements in tree branch $label.");
    } else {
        # Loop through the elements.
        for (my $i = $i0; $i < $i1; $i += 2) {
            # Get this node's label and contents.
            my ($myLabel, $myContent) = ($branch->[$i], $branch->[$i+1]);
            # Get an ID for this node's children (if any).
            my $myID = GetDivID($options->{name});
            # Now we need to find the list of children and the options hash.
            # This is a bit ugly because we allow the shortcut of a hash without an
            # enclosing list. First, we need some variables.
            my $attrHash = {};
            my @childHtml = ();
            my $hasChildren = 0;
            if (! ref $myContent) {
                Confess("Invalid tree definition. Scalar found as content of node \"$myLabel\".");
            } elsif (ref $myContent eq 'HASH') {
                # Here the node is a leaf and its content contains the link/value hash.
                $attrHash = $myContent;
            } elsif (ref $myContent eq 'ARRAY') {
                # Here the node may be a branch. Its content is a list.
                my $len = scalar @{$myContent};
                if ($len >= 1) {
                    # Here the first element of the list could by the link/value hash.
                    if (ref $myContent->[0] eq 'HASH') {
                        $attrHash = $myContent->[0];
                        # If there's data in the list besides the hash, it's our child list.
                        # We can pass the entire thing as the child list, because the hash
                        # is ignored.
                        if ($len > 1) {
                            $hasChildren = 1;
                        }
                    } else {
                        $hasChildren = 1;
                    }
                    # If we have children, create the child list with a recursive call.
                    if ($hasChildren) {
                        Trace("Processing children of $myLabel.") if T(4);
                        push @childHtml, ShowBranch($cgi, $myLabel, $myID, $myContent, $options, 'block');
                        Trace("Children of $myLabel finished.") if T(4);
                    }
                }
            }
            # Okay, it's time to pause and take stock. We have the label of the current node
            # in $myLabel, its attributes in $attrHash, and if it is NOT a leaf node, we
            # have a child list in @childHtml. If it IS a leaf node, $hasChildren is 0.
            # Compute the image HTML. It's tricky, because we have to deal with the open and
            # closed images.
            my @images = ($options->{nodeImageOpen}, $options->{nodeImageClosed});
            my $image = $images[$hasChildren];
            my $prefixHtml = CGI::img({src => $image, id => "${myID}img"});
            if ($hasChildren) {
                # If there are children, we wrap the image in a toggle hyperlink.
                $prefixHtml = CGI::a({ onClick => "javascript:treeToggle('$myID','$images[0]', '$images[1]')" },
                                      $prefixHtml);
            }
            # Now the radio button, if any. Note we use "defined" in case the user wants the
            # value to be 0.
            if (defined $attrHash->{value}) {
                # Due to a glitchiness in the CGI stuff, we have to build the attribute
                # hash for the "input" method. If the item is pre-selected, we add
                # "checked => undef" to the hash. Otherwise, we can't have "checked"
                # at all.
                my $radioParms = { type => 'radio',
                                   name => $options->{name},
                                   value => $attrHash->{value},
                                 };
                if (defined $options->{selected} && $options->{selected} eq $attrHash->{value}) {
                    $radioParms->{checked} = undef;
                }
                $prefixHtml .= CGI::input($radioParms);
            }
            # Next, we format the label.
            my $labelHtml = $myLabel;
            Trace("Formatting tree node for \"$myLabel\".") if T(4);
            # Apply a hyperlink if necessary.
            if (defined $attrHash->{link}) {
                $labelHtml = CGI::a({ href => $attrHash->{link}, target => $options->{target} },
                                     $labelHtml);
            }
            # Finally, roll up the child HTML. If there are no children, we'll get a null string
            # here.
            my $childHtml = join("\n", @childHtml);
            # Now we have all the pieces, so we can put them together.
            push @retVal, CGI::li("$prefixHtml$labelHtml$childHtml");
        }
    }
    # Close the tree branch.
    push @retVal, CGI::end_ul();
    # Return the result.
    return @retVal;
}

=head3 GetDivID

    my $idString = SearchHelper::GetDivID($name);

Return a new HTML ID string.

=over 4

=item name

Name to be prefixed to the ID string.

=item RETURN

Returns a hopefully-unique ID string.

=back

=cut

sub GetDivID {
    # Get the parameters.
    my ($name) = @_;
    # Compute the ID.
    my $retVal = "elt_$name$divCount";
    # Increment the counter to make sure this ID is not re-used.
    $divCount++;
    # Return the result.
    return $retVal;
}

=head3 PrintLine

    $shelp->PrintLine($message);

Print a line of CGI output. This is used during the operation of the B<Find> method while
searching, so the user sees progress in real-time.

=over 4

=item message

HTML text to display.

=back

=cut

sub PrintLine {
    # Get the parameters.
    my ($self, $message) = @_;
    # Send the message to the output.
    print "$message\n";
}

=head3 GetHelper

    my $shelp = SearchHelper::GetHelper($parm, $type => $className);

Return a helper object with the given class name. If no such class exists, an
error will be thrown.

=over 4

=item parm

Parameter to pass to the constructor. This is a CGI object for a search helper
and a search helper object for the result helper.

=item type

Type of helper: C<RH> for a result helper and C<SH> for a search helper.

=item className

Class name for the helper object, without the preceding C<SH> or C<RH>. This is
identical to what the script expects for the C<Class> or C<ResultType> parameter.

=item RETURN

Returns a helper object for the specified class.

=back

=cut

sub GetHelper {
    # Get the parameters.
    my ($parm, $type, $className) = @_;
    # Declare the return variable.
    my $retVal;
    # Try to create the helper.
    eval {
        # Load it into memory. If it's already there nothing will happen here.
        my $realName = "$type$className";
        Trace("Requiring helper $realName.") if T(3);
        require "$realName.pm";
        Trace("Constructing helper object.") if T(3);
        # Construct the object.
        $retVal = eval("$realName->new(\$parm)");
        # Commit suicide if it didn't work.
        if (! defined $retVal) {
            die "Could not find a $type handler of type $className.";
        } else {
            # Perform any necessary subclass initialization.
            $retVal->Initialize();
        }
    };
    # Check for errors.
    if ($@) {
        Confess("Error retrieving $type$className: $@");
    }
    # Return the result.
    return $retVal;
}

=head3 SaveOrganismData

    my ($name, $displayGroup, $domain) = $shelp->SaveOrganismData($group, $genomeID, $genus, $species, $strain, $taxonomy);

Format the name of an organism and the display version of its group name. The incoming
data should be the relevant fields from the B<Genome> record in the database. The
data will also be stored in the genome cache for later use in posting search results.

=over 4

=item group

Name of the genome's group as it appears in the database.

=item genomeID

ID of the relevant genome.

=item genus

Genus of the genome's organism. If undefined or null, it will be assumed the genome is not
in the database. In this case, the organism name is derived from the genomeID and the group
is automatically the supporting-genomes group.

=item species

Species of the genome's organism.

=item strain

Strain of the species represented by the genome.

=item taxonomy

Taxonomy of the species represented by the genome.

=item RETURN

Returns a three-element list. The first element is the formatted genome name. The second
element is the display name of the genome's group. The third is the genome's domain.

=back

=cut

sub SaveOrganismData {
    # Get the parameters.
    my ($self, $group, $genomeID, $genus, $species, $strain, $taxonomy) = @_;
    # Declare the return values.
    my ($name, $displayGroup);
    # If the organism does not exist, format an unknown name and a blank group.
    if (! defined($genus)) {
        $name = "Unknown Genome $genomeID";
        $displayGroup = "";
    } else {
        # It does exist, so format the organism name.
        $name = "$genus $species";
        if ($strain) {
            $name .= " $strain";
        }
        # Compute the display group. This is currently the same as the incoming group
        # name unless it's the supporting group, which is nulled out.
        $displayGroup = ($group eq $FIG_Config::otherGroup ? "" : $group);
        Trace("Group = $displayGroup, translated from \"$group\".") if T(4);
    }
    # Compute the domain from the taxonomy.
    my ($domain) = split /\s*;\s*/, $taxonomy, 2;
    # Cache the group and organism data.
    my $cache = $self->{orgs};
    $cache->{$genomeID} = [$name, $displayGroup, $domain];
    # Return the result.
    return ($name, $displayGroup, $domain);
}

=head3 ValidateKeywords

    my $okFlag = $shelp->ValidateKeywords($keywordString, $required);

Insure that a keyword string is reasonably valid. If it is invalid, a message will be
set.

=over 4

=item keywordString

Keyword string specified as a parameter to the current search.

=item required

TRUE if there must be at least one keyword specified, else FALSE.

=item RETURN

Returns TRUE if the keyword string is valid, else FALSE. Note that a null keyword string
is acceptable if the I<$required> parameter is not specified.

=back

=cut

sub ValidateKeywords {
    # Get the parameters.
    my ($self, $keywordString, $required) = @_;
    # Declare the return variable.
    my $retVal = 0;
    my @wordList = split /\s+/, $keywordString;
    # Right now our only real worry is a list of all minus words. The problem with it is that
    # it will return an incorrect result.
    my @plusWords = grep { $_ =~ /^[^\-]/ } @wordList;
    if (! @wordList) {
        if ($required) {
            $self->SetMessage("No search words specified.");
        } else {
            $retVal = 1;
        }
    } elsif (! @plusWords) {
        $self->SetMessage("At least one keyword must be positive. All the keywords entered are preceded by minus signs.");
    } else {
        $retVal = 1;
    }
    # Return the result.
    return $retVal;
}

=head3 TuningParameters

    my $options = $shelp->TuningParameters(%parmHash);

Retrieve tuning parameters from the CGI query object. The parameter is a hash that maps parameter names
to their default values. The parameters and their values will be returned as a hash reference.

=over 4

=item parmHash

Hash mapping parameter names to their default values.

=item RETURN

Returns a reference to a hash containing the parameter names mapped to their actual values.

=back

=cut

sub TuningParameters {
    # Get the parameters.
    my ($self, %parmHash) = @_;
    # Declare the return variable.
    my $retVal = {};
    # Get the CGI Query Object.
    my $cgi = $self->Q();
    # Loop through the parameter names.
    for my $parm (keys %parmHash) {
        # Get the incoming value for this parameter.
        my $value = $cgi->param($parm);
        # Zero might be a valid value, so we do an is-defined check rather than an OR.
        if (defined($value)) {
            $retVal->{$parm} = $value;
        } else {
            $retVal->{$parm} = $parmHash{$parm};
        }
    }
    # Return the result.
    return $retVal;
}

=head3 ParseIDList

    my @idList = $sh->ParseIDList($string);

Compute the list of IDs found in the specified string. In the string, any
comma, quote, or white space character is considered a delimiter.
Everything else is considered an ID.

=over 4

=item string

Input string containing the IDs.

=item RETURN

Returns a list of the IDs found.

=back

=cut

sub ParseIDList {
    # Get the parameters.
    my ($self, $string) = @_;
    # Declare the return variable.
    my $retVal;
    # Get a safety copy of the string.
    my $line = $string;
    # Convert all delimiter sequences to spaces.
    $line =~ s/[\s"',]+/ /gs;
    # Split the result and remove empty entries.
    my @retVal = grep { $_ } split / /, $line;
    # Return the result.
    return @retVal;
}




=head3 GetPreferredAliasType

    my $type = $shelp->GetPreferredAliasType();

Return the preferred alias type for the current session. This information is stored
in the C<AliasType> parameter of the CGI query object, and the default is C<FIG>
(which indicates the FIG ID).

=cut

sub GetPreferredAliasType {
    # Get the parameters.
    my ($self) = @_;
    # Determine the preferred type.
    my $cgi = $self->Q();
    my $retVal = $cgi->param('AliasType') || 'FIG';
    # Return it.
    return $retVal;
}

=head3 Hint

    my $htmlText = SearchHelper::Hint($wikiPage, $hintID);

Return the HTML for a small question mark that displays the specified hint text when it is clicked.
This HTML can be put in forms to provide a useful hinting mechanism.

=over 4

=item wikiPage

Name of the wiki page to be popped up when the hint mark is clicked.

=item hintID

ID of the text to display for the hint. This is the ID number for a tip-of-the-day.

=item RETURN

Returns the html for the hint facility. The resulting html shows a small button-like thing that
uses the standard FIG popup technology.

=back

=cut

sub Hint {
    # Get the parameters.
    my ($wikiPage, $hintID) = @_;
    # Ask Sprout to draw the hint button for us.
    return Sprout::Hint($wikiPage, $hintID);
}



=head2 Virtual Methods

=head3 HeaderHtml

    my $html = $shelp->HeaderHtml();

Generate HTML for the HTML header. If extra styles or javascript are required,
they should go in here.

=cut

sub HeaderHtml {
    return "";
}

=head3 Form

    my $html = $shelp->Form($mode);

Generate the HTML for a form to request a new search. If the subclass does not
override this method, then the search is formless, and must be started from an
external page.

=cut

sub Form {
    # Get the parameters.
    my ($self) = @_;
    return "";
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
    $self->Message("Call to pure virtual Find method in helper of type " . ref($self) . ".");
    return undef;
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
    $self->Message("Call to pure virtual Description method in helper of type " . ref($self) . ".");
    return "Unknown search type";
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
    # Declare the return variable.
    my $retVal = "";
    # Return it.
    return $retVal;
}

=head3 DefaultColumns

    $shelp->DefaultColumns($rhelp);

Store the default columns in the result helper. The default action is just to ask
the result helper for its default columns, but this may be changed by overriding
this method.

=over 4

=item rhelp

Result helper object in which the column list should be stored.

=back

=cut

sub DefaultColumns {
    # Get the parameters.
    my ($self, $rhelp) = @_;
    # Get the default columns from the result helper.
    my @cols = $rhelp->DefaultResultColumns();
    # Store them back.
    $rhelp->SetColumns(@cols);
}


=head3 Initialize

    $shelp->Initialize();

Perform any initialization required after construction of the helper.

=cut

sub Initialize {
    # The default is to do nothing.
}

=head3 GetResultHelper

    my $rhelp = $shelp->GetResultHelper($className);

Return a result helper for this search helper. The default action is to create
a result helper from scratch; however, if the subclass has an internal result
helper it can override this method to return it without having to create a new
one.

=over 4

=item className

Result helper class name.

=item RETURN

Returns a result helper of the specified class connected to this search helper.

=back

=cut

sub GetResultHelper {
    # Get the parameters.
    my ($self, $className) = @_;
    # Create the helper.
    my $retVal = GetHelper($self, RH => $className);
    # return it.
    return $retVal;
}

1;
