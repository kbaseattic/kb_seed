#!/usr/bin/perl -w

package ResultHelper;

    use strict;
    use Tracer;
    use FIG;
    use URI::Escape;

=head1 Search Result Display Helper

=head2 Introduction

This is the base class for search output. It provides common methods for formatting the
output and providing options to the caller. This class is never used by itself.
Instead, a subclass (whose name begins with C<RH> is constructed.

The following fields are maintained by this object.

=over 4

=item parent

The parent search helper.

=item record

An B<ERDBObject> representing the current data.

=item columns

Reference to a hash specifying the different possible columns that can be
included in the result.

=back

Additional fields may be appended by the subclasses.

=head2 Column Processing

The subclass will generally have multiple column names defined. For each column,
several bits of information are needed-- how to format the column, how to compute
the column value at search time, how to compute it at run time (which is optional),
the column title to be used, and whether or not the column should be included in
a download. The orthodox object-oriented method for doing this would be to define
a B<Column> class and define each possible column using a subclass. To make things
a little less cumbersome, we instead define each column using a static method in
the subclass. The method gets as its parameters the result helper object and
the type of information required. For example, the following call would ask for
the title of a column called C<orgName>.

    my $title = RHFeatures::orgName(title => $rhelp);

The B<orgName> method itself would look like this.

    sub orgName {
        # Get the parameters.
        my ($type, $rhelp, $key) = @_;
        # Declare the return variable.
        my $retVal;
        # Process according to the information requested.
        if ($type eq 'title' {
            # Return the title for this column.
            $retVal = 'Organism and Gene ID';
        } elsif ($type eq 'download') {
            # This field should be included in a download.
            $retVal = 'text'; # or 'num', or 'list', or ''
        } elsif ($type eq 'style') {
            # This is a text field, so it's left-aligned.
            $retVal = "leftAlign";
        } elsif ($type eq 'value') {
            # Get the organism and feature name.
            $rhelp->FeatureName();
        } elsif ($type eq 'runTimeValue') {
            # This field does not require a runtime value.
        } elsif ($type eq 'valueFromKey') {
            # Get the feature name from the feature ID.
            $rhelp->FeatureNameFromID($key);
        };
        return $retVal;
    }

The method is essentially a giant case statement based on the type of data desired. The
types are

=over 4

=item title

Return the title of the column to be used when it is displayed.

=item download

Identifies how the column should be downloaded. An empty string means it should not
be downloaded at all. The other values are C<num>, indicating that the column contains
numeric data, C<text>, indicating that the column contains an html-escaped string,
C<link>, indicating that the column contains a L</Formlet> or L</FakeButton>,
C<list>, indicating that the column contains a comma-separated list with optional
hyperlinks, or C<align>,indicating that the column contains multi-line
aligned text with individual lines separated by a C<br> tag.

=item style

Return the style to be used to display each table cell in the column. The return
value is a valid C<TD> class name from the style sheet. The style sheet should
contain styles for C<leftAlign>, C<rightAlign>, and C<center> to accomodate the
most common requirements.

=item value

Return the value to be stored in the result cache. In most cases, this should be an
html string. If the value is to be computed when the data is displayed (which is
sometimes necessary for performance reasons), then the return value should be of
the form C<%%>I<colName>C<=>I<key>, where I<colName> is the column name and
I<key> is a value used to compute the result at display time. The key value will
be passed as a third parameter to the column method.

=item runTimeValue

Return the value to be displayed. This method is only used when the information
is not easily available at the time the result cache is built.

=item valueFromKey

Compute the value from a row ID. This method is used when the results are being
loaded asynchronously into a WebApplication table.

=back

The idea behind this somewhat cumbersome design is that new columns can be added
very easily by simply adding a new method to the result helper.

Note that a column name must be a valid PERL method name! This means no spaces
or other fancy stuff.

Run-time values are a bit tricky, and require some explanation. The normal procedure
during a search is to compute the values to be displayed as soon as an item is found
and store them directly in the result cache. Run-time values are those that are too
expensive to compute during the search, so they are not computed until the result
cache is displayed. Because a search can return thousands of results, but only 50 or
so are displayed at a time, this makes a big difference.

=head3 Extra Columns

It is necessary for individual searches to be able to create output columns specific
to the type of search. These are called extra columns.

To create extra columns, you use the L</AddExtraColumn> method. This method
specifies the location of an extra column in the column list, its name, and its format.

The extra columns are put in whatever positions the user specifies, although if
you try to put two columns in the same place or add a column before another added
column, this could cause the position to shift.

Unlike regular columns, there is no need to compute a value or run-time value. The
other column properties (title, style, etc.) are stored in the extra column's
definition in this object. When the column headers are written, the header for an
extra column is in the form C<X=>I<something>. The I<something> is a frozen copy
of the extra column's hash. When the headers are read back in, the extra column data
is thawed into the hash so that the various options are identical to what they were
when the result cache was created.

=head3 Object-Based Columns

Some result helpers need to be much more fluid with column definitions than is possible
with the standard column-processing model. These helpers should override the L</VirtualCompute>
method. The L</Compute> method calls L</VirtualCompute> to give the subclass an opportunity
to process the column computation request before it tries working with a built-in column.
It is expected that eventually all columns will be converted to this object-based
approach, but there is no hurry.

=cut

# This value is used to do a single indent level in the XML output.
use constant XML_INDENT => "  ";

=head2 Public Methods

=head3 new

    my $rhelp = ResultHelper->new($shelp);

Construct a new ResultHelper object to serve the specified search helper.

=over 4

=item shelp

Parent search helper that is generating the output.

=item type

Classname used to format requests for columns.

=item extras

Reference to a hash of extra column data keyed on extra column name. For each extra column,
it contains the column's current value.

=item cache

A hash for use by the run-time value methods, to save time when multiple run-time values
use the same base object.

=item columns

The list of the columns to displayed in the search results. Normal columns are stored as
strings. Extra columns are stored as hash references.

=item record

Data record for the current output row.

=item id

ID for the current output row.

=item RETURN

Returns a newly-constructed result helper.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $shelp) = @_;
    # Save the result type in the CGI parms.
    my $cgi = $shelp->Q();
    $cgi->param(-name => 'ResultType', -value => substr($class, 2));
    Trace("Result helper created of type $class.") if T(3);
    # Create the $rhelp object.
    my $retVal = {
                  parent => $shelp,
                  record => undef,
                  id => undef,
                  type => $class,
                  extras => {},
                  cache => {},
                  columns => [],
                 };
    # Return it.
    return $retVal;
}

=head3 DB

    my $sprout = $rhelp->DB();

Return the Sprout object for accessing the database.

=cut

sub DB {
    # Get the parameters.
    my ($self) = @_;
    # Return the parent helper's database object.
    return $self->Parent()->DB();
}

=head3 PutData

    $rhelp->PutData($sortKey, $id, $record);

Store a line of data in the result file.

=over 4

=item sortKey

String to be used for sorting this line of data among the others.

=item id

ID string for the result line. This is not shown in the results, but
is used by some of the download methods.

=item record

An B<ERDBObject> containing data to be used by the column methods.

=back

=cut

sub PutData {
    # Get the parameters.
    my ($self, $sortKey, $id, $record) = @_;
    # Save the data record and ID so the column methods can get to it.
    $self->{record} = $record;
    $self->{id} = $id;
    # Loop through the columns, producing output data.
    my @outputCols = ();
    for my $column (@{$self->{columns}}) {
        push @outputCols, $self->ColumnValue($column);
    }
    # Get the parent search helper.
    my $shelp = $self->{parent};
    # Write the column data.
    $shelp->WriteColumnData($sortKey, $id, @outputCols);
}

=head3 GetColumnHeaders

    my $colHdrs = $rhelp->GetColumnHeaders();

Return the list of column headers for this session. The return value is a
reference to the live column header list.

=cut

sub GetColumnHeaders {
    # Get the parameters.
    my ($self) = @_;
    # Return the column headers.
    return $self->{columns};
}

=head3 DownloadFormatsAvailable

    my %dlTypes = $rhelp->DownloadFormatsAvailable();

Return a hash mapping each download type to a download description. The default is
the C<tbl> format, which is a tab-delimited download, and the C<xml> format,
which is XML. If you want additional formats, override L</MoreDownloadFormats>.

=cut

sub DownloadFormatsAvailable {
    # Get the parameters.
    my ($self) = @_;
    Trace("Creating download type hash.") if T(3);
    # Declare the return variable.
    my %retVal = ( tbl => 'Results table as a tab-delimited file',
                   xml => 'Results table in XML format');
    Trace("Asking for download formats from the helper.") if T(3);
    # Ask for more formats.
    $self->MoreDownloadFormats(\%retVal);
    # Return the resulting hash.
    return %retVal;
}

=head3 DownloadDataLine

    $rhelp->DownloadDataLine($objectID, $dlType, \@cols, \@colHdrs);

Return one or more lines of download data. The exact data returned depends on the
download type.

=over 4

=item objectID

ID of the object whose data is in this line of results.

=item dlType

The type of download (e.g. C<tbl>, C<fasta>).

=item eol

The end-of-line character to use.

=item cols

A reference to a list of the data columns, or a string containing
C<header> or C<footer>. The strings will cause the header lines
or footer lines to be output rather than a data line.

=item colHdrs

A reference to a list of the column headers. Each header describes the data found
in the corresponding column of the I<cols> list.

=item RETURN

Returns a list of strings that can be written to the download output.

=back

=cut

sub DownloadDataLine {
    # Get the parameters.
    my ($self, $objectID, $dlType, $cols, $colHdrs) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Check the download type.
    if ($dlType eq 'tbl' || $dlType eq 'xml') {
        # Check for headers or footers.
        if ($cols eq 'header') {
            # Here we want headers. Only the XML type has them.
            if ($dlType eq 'xml') {
                @retVal = ('<?xml version="1.0" encoding="utf-8" ?>',
                           '<Results>');
            }
        } elsif ($cols eq 'footer') {
            # Here we want footers. Again, only the XML type requires them.
            if ($dlType eq 'xml') {
                @retVal = ('</Results>');
            }
        } else {
            # Here we are downloading the displayed columns as a tab-delimited file or
            # as XML and we are tasked with producing the output lines for the current
            # row of data. The first thing is to get the download format information
            # about the columns.
            my @keepCols = map { $self->ColumnDownload($_) } @{$colHdrs};
            # Remove the columns that are not being kept. The list we create here
            # will contain the name of each column, its value, and its download format.
            my @actualCols = ();
            for (my $i = 0; $i <= $#keepCols; $i++) {
                Trace("Keep flag for $i is $keepCols[$i].") if T(4);
                if ($keepCols[$i]) {
                    push @actualCols, [$colHdrs->[$i], $self->GetRunTimeValues($cols->[$i]), $keepCols[$i]];
                }
            }
            Trace(scalar(@actualCols) . " columns kept.") if T(4);
            # Now it's time to do the actual writing, so we need to know if this
            # is XML or tab-delimited.
            if ($dlType eq 'tbl') {
                # Clean up the HTML.
                my @actual = map { HtmlCleanup($_->[1], $_->[2]) } @actualCols;
                # Return the line of data.
                push @retVal, join("\t", @actual);
                Trace("Output line is\n" . join("\n", @actual)) if T(4);
            } elsif ($dlType eq 'xml') {
                # Convert to XML.
                my @actual = ();
                for my $actualCol (@actualCols) {
                    # First we need the column name. This is the column header for an ordinary column,
                    # and the title for an extra column.
                    my $colName;
                    if (ref $actualCol->[0]) {
                        # Here we have an extra column.
                        $colName = $actualCol->[0]->{title};
                        # Remove internal spaces to make it name-like.
                        $colName =~ s/\s+//g;
                    } else {
                        # For a normal column, the value is the name.
                        $colName = $actualCol->[0];
                    }
                    # Create the tag for this column.  Since a single XML tag can contain multiple
                    # lines, we re-split them. This is important, because when the lines are output
                    # we need to insure the correct EOL character is used.
                    push @actual, split /\n/, "<$colName>" . XmlCleanup($actualCol->[1], $actualCol->[2]) . "</$colName>";
                }
                # Return the XML object.
                push @retVal, XML_INDENT x 1 . "<Item id=\"$objectID\">";
                push @retVal, map { XML_INDENT x 2 . $_ } @actual;
                push @retVal, XML_INDENT x 1 . "</Item>";
            }
        }
    } else {
        # Now we have a special-purpose download format, so we let the subclass deal
        # with it.
        @retVal = $self->MoreDownloadDataMethods($objectID, $dlType, $cols, $colHdrs);
    }
    # Return the result.
    return @retVal;
}

=head3 Formlet

    my $html = $rhelp->Formlet($caption, $url, $target, %parms);

Create a mini-form that posts to the specified URL with the specified parameters. The
parameters will be stored in hidden fields, and the form's only visible control will
be a submit button with the specified caption.

Note that we don't use B<CGI.pm> services here because they generate forms with extra characters
and tags that we don't want to deal with.

This method is tightly bound to L</FormletToLink>, which converts a formlet to a URL. A
change here will require a change to the other method.

=over 4

=item caption

Caption to be put on the form button.

=item url

URL to be put in the form's action parameter.

=item target

Frame or target in which the form results should appear. If C<undef> is specified,
the default target will be used.

=item parms

Hash containing the parameter names as keys and the parameter values as values.

=back

=cut

sub Formlet {
    # Get the parameters.
    my ($self, $caption, $url, $target, %parms) = @_;
    # Compute the target HTML.
    my $targetHtml = ($target ? " target=\"$target\"" : "");
    # Start the form.
    my $retVal = "<form method=\"POST\" action=\"$FIG_Config::cgi_url/$url\"$target>";
    # Add the parameters.
    for my $parm (keys %parms) {
        $retVal .= "<input type=\"hidden\" name=\"$parm\" value=\"$parms{$parm}\" />";
    }
    # Put in the button.
    $retVal .= "<input type=\"submit\" name=\"submit\" value=\"$caption\" class=\"button\" />";
    # Close the form.
    $retVal .= "</form>";
    # Return the result.
    return $retVal;
}

=head3 HtmlCleanup

    my $text = ResultHelper::HtmlCleanup($htmlText, $type);

Take a string of Html text and clean it up so it appears as real text.
Note that this method is not yet sophisticated enough to detect right-angle brackets
inside tag parameters, nor can it handle style or script tags. Its only sophistication
is that it knows how to convert formlets or fake buttons URLs. Otherwise, it is a dirt simple
method that suffices for search result processing.

=over 4

=item htmlText

Html text to clean up.

=item type

Type of column: C<num> for a number, C<text> for a string, C<list> for a
comma-separated list, and C<link> for a formlet link.

=item RETURN

Returns the downloadable form of the Html string.

=back

=cut

sub HtmlCleanup {
    # Get the parameters.
    my ($htmlText, $type) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a formlet.
    if ($type eq 'link') {
        # Here we have a formlet or fake button and we want to convert it to a URL.
        $retVal = ButtonToLink($htmlText);
    } elsif ($type eq 'align') {
        # Here we have multiple lines. Convert the new-lines to serial commas.
        $retVal = $htmlText;
        $retVal =~ s/<br\s*\/?>/, /g;
        # Convert &nbsp; marks to real spaces.
        $retVal =~ s/&nbsp;/ /g;
    } else {
        # Here we have normal HTML. Start by taking the raw text.
        $retVal = $htmlText;
        # Delete any tags. This is a very simplistic algorithm that will fail if there
        # is a right angle bracket inside a parameter string.
        $retVal =~ s/<[^>]+>//g;
        # Convert &nbsp; marks to real spaces.
        $retVal =~ s/&nbsp;/ /g;
        # Unescape the & tags.
        $retVal = CGI::unescapeHTML($retVal);
    }
    # Return the result.
    return $retVal;
}

=head3 XmlCleanup

    my $text = ResultHelper::XmlCleanup($htmlText, $type);

Take a string of Html text and clean it up so it appears as html.

=over 4

=item htmlText

Html text to clean up.

=item type

Type of column: C<num> for a number, C<text> for a string, C<list> for a
comma-separated list, and C<link> for a formlet or fake button.

=item RETURN

Returns the column data in XML format.

=back

=cut

sub XmlCleanup {
    # Get the parameters.
    my ($htmlText, $type) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a formlet.
    if ($type eq 'link') {
        # Here we have a formlet or fake button and we want to convert it to a URL.
        $retVal = ButtonToLink($htmlText);
    } elsif ($type eq 'num' || $type eq 'text') {
        # Here we have a number or text. Return the raw value.
        $retVal = $htmlText;
    } elsif ($type eq 'align') {
        # Here we have aligned text. This is converted into an XML array of lines.
        # First, we find the break tags.
        Trace("Alignment cleanup of: $htmlText") if T(4);
        my @lines = split /<br[^>]+>/, $htmlText;
        Trace(scalar(@lines) . " lines found.") if T(4);
        # Format the lines as an XML array. The extra new-line causes the first array
        # element to be on a separate line from the first item tag.
        $retVal = "\n" . join("", map { XML_INDENT . "<line>$_</line>\n" } @lines);
    } elsif ($type eq 'list') {
        # Here we have a comma-delimited list of possibly-linked strings. We will convert it to
        # an XML array. First, we get the pieces.
        my @entries = split /\s*,\s*/, $htmlText;
        # Each piece is processed individually, so we can check for hyperlinks.
        # The return value starts with a new-line, so that the first list element
        # is not on the same line as the open tag.
        $retVal = "\n";
        for my $entry (@entries) {
            # Check for a hyperlink.
            if ($entry =~ /<a[^>]+(href="[^"]+")[^>]*>(.+)<\/a>/) {
                # Put the URL in the tag.
                $retVal .= XML_INDENT . "<value $1>$2</value>\n";
            } else {
                # No URL, so the tag is unadorned.
                $retVal .= XML_INDENT . "<value>$entry</value>\n";
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 ButtonToLink

    my $url = ResultHelper::ButtonToLink($htmlText);

Convert a formlet or fake button to a link. This process is bound very tightly with
the way L</Formlet> and L</FakeButton> generate Html. A change there requires a
change here.

=over 4

=item htmlText

HTML text for the formlet.

=item RETURN

Returns a URL that will produce the same result as clicking the formlet button.

=back

=cut

sub ButtonToLink {
    # Get the parameters.
    my ($htmlText) = @_;
    # Declare the return variable.
    my $retVal;
    # We begin with the action.
    if ($htmlText =~ /action="([^"]+)"/i) {
        # Action found, so this is a formlet. The action is the base of the URL.
        $retVal = $1;
        # Now, parse out the parameters, all of which are stored in the formlet as hidden
        # input fields. This is the point where we assume that the formlet generates things
        # in a well-defined format.
        my @parms = ();
        while ($htmlText =~ /<input\s+type="hidden"\s+name="([^"]+)"\s+value="([^"]+)"/ig) {
            push @parms, "$1=" . uri_escape($2);
        }
        # If there were any parameters, assemble them into the URL.
        if (scalar(@parms)) {
            $retVal .= "?" . join(";", @parms);
        }
    } elsif ($htmlText =~ /<a\s+href="([^"]+)"/) {
        # Here we have a fake button. The URL is the HREF.
        $retVal = $1;
    } else {
        # Here the column is empty. We output an empty string.
        $retVal = '';
    }
    # Now a final cleanup. If we have a URL and it's relative, we need to add our path to it.
    if ($retVal && $retVal !~ m#http://#) {
        # The link doesn't begin with http, so we must fix it.
        $retVal = "$FIG_Config::cgi_url/$retVal";
    }
    # Return the result.
    return $retVal;
}

=head3 FakeButton

    my $html = $rhelp->FakeButton($caption, $url, $target, %parms);

Create a fake button that hyperlinks to the specified URL with the specified parameters.
Unlike a real button, this one won't visibly click, but it will take the user to the
correct place.

The parameters of this method are deliberately identical to L</Formlet> so that we
can switch easily from real buttons to fake ones in the code.

=over 4

=item caption

Caption to be put on the button.

=item url

URL for the target page or script.

=item target

Frame or target in which the new page should appear. If C<undef> is specified,
the default target will be used.

=item parms

Hash containing the parameter names as keys and the parameter values as values.
These will be appended to the URL.

=back

=cut

sub FakeButton {
    # Get the parameters.
    my ($self, $caption, $url, $target, %parms) = @_;
    # Declare the return variable.
    my $retVal;
    # Compute the target URL.
    my $targetUrl = "$FIG_Config::cgi_url/$url?" . join(";", map { "$_=" . uri_escape($parms{$_}) } keys %parms);
    # Compute the target-frame HTML.
    my $targetHtml = ($target ? " target=\"$target\"" : "");
    # Assemble the result.
    return "<a href=\"$targetUrl\" $targetHtml><div class=\"button2 button\">$caption</div></a>";
}

=head3 Parent

    my $shelp = $rhelp->Parent();

Return this helper's parent search helper.

=cut

sub Parent {
    # Get the parameters.
    my ($self) = @_;
    # Return the parent.
    return $self->{parent};
}

=head3 Record

    my $erdbObject = $rhelp->Record();

Return the record currently stored in this object. The record contains the data for
the result output line being built, and is in the form of a B<ERDBObject>.

=cut

sub Record {
    # Get the parameters.
    my ($self) = @_;
    # Get the record.
    my $retVal = $self->{record};
    # If it does not exist, trace a message.
    Trace("No record found in result helper.") if T(3) && ! defined($retVal);
    # Return the record.
    return $retVal;
}

=head3 ID

    my $id = $rhelp->ID();

Return the ID for the record currently stored in this object (if any).


=cut

sub ID {
    # Get the parameters.
    my ($self) = @_;
    # Get the record.
    my $retVal = $self->{id};
    # If it does not exist, trace a message. We say "no record found" because a
    # missing ID implies a missing record.
    Trace("No record found in result helper.") if T(3) && ! defined($retVal);
    # Return the ID.
    return $retVal;
}



=head3 Cache

    my $cacheHash = $rhelp->Cache();

Return a reference to the internal cache. The internal cache is used by the
run-time value methods to keep stuff in memory between calls for the same
output line.

=cut

sub Cache {
    # Get the parameters.
    my ($self) = @_;
    # Return the cache.
    return $self->{cache};
}

=head3 PreferredID

    my $featureID = $rhelp->PreferredID($featureObject);

Return the preferred ID for the specified feature. The feature passed in must be in the
form of an ERDB feature object. The preferred alias type will be determined using the
CGI C<AliasType> parameter, and then cached in the feature object using the name
C<Feature(alias)> so this method can find it easily if it is needed again.

=over 4

=item featureObject

An B<ERDBObject> for the relevant feature.

=item RETURN

The preferred ID for the feature (Locus Tag, Uniprot ID, etc.) if one exists, otherwise
the FIG ID.

=back

=cut

sub PreferredID {
    # Get the parameters.
    my ($self, $featureObject) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for a cached value.
    if ($featureObject->HasField('Feature(alias)')) {
        $retVal = $featureObject->PrimaryValue('Feature(alias)');
    } else {
        # Here we need to compute the alias. First, get the preferred type.
        my $aliasType = $self->Parent()->GetPreferredAliasType();
        # The fallback is to use the FIG ID.
        my $fid = $featureObject->PrimaryValue('Feature(id)');
        $retVal = $fid;
        # We only need to proceed if the preferred type is NOT FIG.
        if ($aliasType ne 'FIG') {
            # Here we need to find a real alias of the specified type. To start,
            # we need a Sprout object.
            my $sprout = $self->DB();
            # Ask for all the aliases connected to this feature ID.
            my @aliases = $sprout->GetFlat(['IsAliasOf'], 'IsAliasOf(to-link) = ?',
                                           [$fid], 'IsAliasOf(from-link)');
            # Extract an alias of the preferred type.
            my $foundAlias = AliasAnalysis::Find($aliasType, \@aliases);
            # If an alias was found, use it. Otherwise, the FIG ID will stay in place.
            if (defined($foundAlias)) {
                $retVal = $foundAlias;
            }
        }
        # Save the alias type for future calls.
        $featureObject->AddValues('Feature(alias)', $retVal);
    }
    # Return the ID computed.
    return $retVal;
}


=head2 Column-Related Methods

=head3 Compute

    my $retVal = $rhelp->Compute($type, $colName, $runTimeKey);

Call a column method to return a result. This involves some fancy C<eval> stuff.
The column method is called as a static method of the relevant subclass.

=over 4

=item type

The type of column data requested: C<title> for the column title, C<style> for the
column's display style, C<value> for the value to be put in the result cache,
C<download> for the indicator of how the column should be included in
downloads, C<runTimeValue> for the value to be used when the result is
displayed, and C<valueFromKey> for the value when all we have is the object ID. Note
that if a run-time value is required, then the normal value must be formatted in
a special way (see L<Column Processing>).

A little fancy dancing is required for extra columns. For extra columns, only
the title, style, and download status are ever requested.

=item colName

Name of the column of interest. The name may contain a colon, in which case
the column name is the part before the colon and the value after it is
passed to the column method as the run-time key. For an extra column, this is
the extra-column hash.

=item runTimeKey (optional)

If a run-time value is desired, this should be the key taken from the value stored
in the result cache.

=item RETURN

Returns the desired result for the specified column.

=back

=cut

sub Compute {
    # Get the parameters.
    my ($self, $type, $colName, $runTimeKey) = @_;
    # Declare the return variable.
    my $retVal;
    # Check for an extra column.
    if (ref $colName eq 'HASH') {
        # Look for the appropriate data from the hash.
        if ($type eq 'value') {
            # The caller wants the column value, which is stored in the "extras"
            # member keyed by column name.
            my $realName = $colName->{name};
            $retVal = $self->{extras}->{$realName};
            Trace("Extra column $realName retrieved value is $retVal.") if T(ResultCache => 3);
        } else {
            # The other data items are stored in the column name itself.
            $retVal = $colName->{$type};
        }
    } else {
        # Here we have a built-in column or an object-based column. The search
        # helper chooses which of these to use (usually by adding to a default
        # list), and we use static methods in our subclass to process them. An
        # eval call is used to accomplish the result. First, we do some
        # goofiness so we can deal with the possible absence of a run-time key.
        my $realRunTimeKey = (defined $runTimeKey ? $runTimeKey : undef);
        # Check for a complex column name. The column name fragment is made
        # part of the run-time key.
        if ($colName =~ /(\S+):(.+)/) {
            $colName = $1;
            $realRunTimeKey = $2;
            if (defined $runTimeKey) {
                $realRunTimeKey .= "/$runTimeKey";
            }
        }
        # Check to see if this is an object-based column.
        $retVal = $self->VirtualCompute($colName, $type, $realRunTimeKey);
        # If we didn't get a result, then the column is truly built-in.
        if (defined $retVal) {
            Trace("Virtual compute for \"colName\" type $type is \"$retVal\".") if T(ResultCache => 3);
        } else {
            # Format a parameter list containing a self reference and optionally
            # the run-time key.
            my @parms = '$self';
            push @parms, "'$realRunTimeKey'" if defined $realRunTimeKey;
            my $parms = join(", ", @parms);
            # Get the result helper type.
            my $rhType = $self->{type};
            # Create the string for returning the desired results.
            my $expression = "${rhType}::$colName($type => $parms)";
            Trace("Evaluating: $expression") if T(ResultCache => 3);
            # Evaluate to get the result. Note we automatically translate
            # undefined results to an empty string.
            $retVal = eval($expression) || "";
            # Check for an error.
            if ($@) {
                Trace("Evaluation failed in Compute of $expression") if T(1);
                Confess("$self->{type} column request failed: $@");
            }
            Trace("Found \"$retVal\" for $colName type $type.") if T(ResultCache => 3);
        }
    }
    # Return the computed result.
    return $retVal;
}

=head3 ColumnMetaData

    my $metadata = $rhelp->ColumnMetaData($colHdr, $idx, $visible);

Compute the [[ColumnDisplayList]] metadata for a column. The column is
identified either by its name or by the hash reference that specifies the
characteristics of an extra column.

=over 4

=item colHdr

Name of the column in question, or the extra column hash for an extra column.

=item idx

Index position at which the column is to be displayed.

=item visible

If TRUE, the column will be marked visible; otherwise, it will initially be hidden.

=item RETURN

Returns a metadata structure suitable for use by the [[DisplayListSelectPm]]
component in manipulating this column.

=back

=cut

sub ColumnMetaData {
    # Get the parameters.
    my ($self, $colHdr, $idx, $visible) = @_;
    # Declare the return variable.
    my $retVal = {};
    # Get the column label.
    my $label = $self->Compute(title => $colHdr);
    # Create the table column object.
    my $columnThing = { name => $label };
    # Get our download type.
    my $dlType = $self->Compute(download => $colHdr);
    # We use the download type to decide how fancy the column should be. For a
    # list-type column we want no fanciness. For numbers we allow inequalities,
    # for strings we allow LIKE stuff.
    if ($dlType eq 'num') {
        $columnThing->{filter} = 1;
        $columnThing->{operator} = "equal";
        $columnThing->{operators} = [qw(equal unequal less more)];
        $columnThing->{sortable} = 1;
    } elsif ($dlType eq 'text') {
        $columnThing->{filter} = 1;
        $columnThing->{operator} = "equal";
        $columnThing->{operators} = [qw(equal unequal like unlike)];
        $columnThing->{sortable} = 1;
    }
    # Store the table column object in the metadata we're returning.
    $retVal->{header} = $columnThing;
    # Now we set the visibility, permanence, and order.
    $retVal->{visible} = ($visible ? 1 : 0);
    $retVal->{order} = $idx;
    $retVal->{permanent} = $self->Permanent($colHdr);
    # Return the result.
    return $retVal;
}

=head3 ColumnName

    my $name = $rhelp->ColumnName($colName);

Return the name of a column. Normally, this involves just returning the
parameter unmodified. If it's an extra column, however, the input is a
hash reference and we have to pull out the name.

=over 4

=item colName

Column name, or the extra column hash.

=item RETURN

Returns a string that may be used as a column identifier.

=back

=cut

sub ColumnName {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Declare the return variable.
    my $retVal;
    # Check the column type.
    if (ref $colName eq 'HASH') {
        $retVal = $colName->{name};
    } else {
        $retVal = $colName;
    }
    # Return the result.
    return $retVal;
}


=head3 ColumnDownload

    my $flag = $rhelp->ColumnDownload($colName);

Return the type of data in the column, or an empty string if it should
not be downloaded. In general, all columns are downloaded except those
that are graphic representations of something.

=over 4

=item colName

Name of the column in question.

=item RETURN

Returns one of the download data types discussed in L</Column Processing>.

=back

=cut

sub ColumnDownload {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Compute the result.
    my $retVal = $self->Compute(download => $colName);
    # Return it.
    return $retVal;
}

=head3 ColumnTitle

    my $titleHtml = $rhelp->ColumnTitle($colName);

Return the title to be used in the result table for the specified column.

=over 4

=item colName

Name of the relevant column.

=item RETURN

Returns the html to be used for the column title.

=back

=cut

sub ColumnTitle {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Compute the result.
    my $retVal = $self->Compute(title => $colName);
    # Return it.
    return $retVal;
}

=head3 ColumnValue

    my $htmlValue = $rhelp->ColumnValue($colName);

Return the display value for a column. This could be HTML text or it
could be a run-time value specification. The column value is computed
using the data record currently stored in the result helper.

=over 4

=item colName

Name of the column whose value is desired.

=item RETURN

Returns the value to be stored in the result cache.

=back

=cut

sub ColumnValue {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Compute the return value.
    my $retVal = $self->Compute(value => $colName);
    # Return it.
    return $retVal;
}

=head3 ColumnStyle

    my $className = $rhelp->ColumnStyle($colName);

Return the display style for the specified column. This must be a classname
defined for C<TD> tags in the active style sheet.

=over 4

=item colName

Name of the relevant column.

=item RETURN

Returns the name of the style class to be used for this column's cells.

=back

=cut

sub ColumnStyle {
    # Get the parameters.
    my ($self, $colName) = @_;
    # Compute the return value.
    my $retVal = $self->Compute(style => $colName);
    # Return it.
    return $retVal;
}

=head3 GetRunTimeValues

    my @valueHtml = $rhelp->GetRunTimeValues(@cols);

Return the run-time values of a row of columns. The incoming values contain
the actual column contents. Run-time columns will be identified by the
leading C<%%> marker. The run-time columns are converted in sequence
using methods in the base class.

=over 4

=item cols

A list of columns. Runtime columns will be of the format C<%%>I<colName>C<=>I<key>,
where I<colName> is the actual column name and I<key> is the key to be passed to
the evaluator. Columns that do not have this format are unchanged.

=item RETURN

Returns a list of the final values for all the run-time columns.

=back

=cut

sub GetRunTimeValues {
    # Get the parameters.
    my ($self, @cols) = @_;
    # Declare the return value.
    my @retVal = ();
    # Clear the cache. The run-time value methods can store stuff
    # in here to save computation time.
    $self->{cache} = {};
    # Loop through the columns.
    for my $col (@cols) {
        # Declare a holding variable.
        my $retVal;
        Trace("Value \"$retVal\" found in column.") if T(ResultCache => 3);
        # Parse the column data.
        if ($col =~ /^%%(\w+)=(.+)/) {
            # It parsed as a run-time value, so call the Compute method.
            $retVal = $self->Compute(runTimeValue => $1, $2);
        } else {
            # Here it's a search-time value, so we leave it unchanged.
            $retVal = $col;
        }
        # Add this column to the result list.
        push @retVal, $retVal;
    }
    # Return the result.
    return @retVal;
}

=head3 SetColumns

    $rhelp->SetColumns(@cols);

Store the specified object columns. These are the columns computed by the search
framework, and should generally be specified first. If the search itself is
going to generate additional data, the columns for displaying this additional
data should be specified by a subsequent call to L</AddExtraColumn>.

=over 4

=item cols

A list of column names. These must correspond to names defined in the result
helper subclass (see L</Column Processing>).

=back

=cut

sub SetColumns {
    # Get the parameters.
    my ($self, @cols) = @_;
    # Store the columns in the column list. Note that this erases any
    # previous column information.
    $self->{columns} = \@cols;
}

=head3 AddExtraColumn

    $rhelp->AddExtraColumn($name => $loc, %data);

Add an extra column to the column list at a specified location.

=over 4

=item name

The name of the column to add.

=item loc

The location at which the column should be displayed. The column is added
at the specified column location in the column list. It may be moved,
however, if subsequent column additions are placed at or before its
specified location. To put a column at the beginning, specify C<0>;
to put it at the end specify C<undef>.

=item data

A hash specifying the title, style, and download flag for the extra
column. The download flag (key C<download>) should specify the type
of data in the column. The title (key C<title>) should be the name
displayed for the column in the result display table. The style
(key C<style>) should be the style class used for displaying the cells
in the column.

=back

=cut

sub AddExtraColumn {
    # Get the parameters.
    my ($self, $name, $loc, %data) = @_;
    # Add the name to the column hash.
    $data{name} = $name;
    # Store the result in the column list.
    $self->_StoreColumnSpec(\%data, $loc);
}

=head3 AddOptionalColumn

    $rhelp->AddOptionalColumn($name => $loc);

Store the specified column name in the column list at the
specified location. The column name must be one that
is known to the result helper subclass. This method
allows ordinary columns (as opposed to extra columns)
to be added after the initial L</SetColumns> call.

=over 4

=item name

Name of the desired column.

=item location

Location at which the desired column should be stored.

=back

=cut

sub AddOptionalColumn {
    # Get the parameters.
    my ($self, $name => $loc) = @_;
    # Currently, there is no extra work required here, but that
    # may change.
    $self->_StoreColumnSpec($name, $loc);
}

=head3 PutExtraColumns

    $rhelp->PutExtraColumns(name1 => value1, name2 => value2, ...);

Store the values of one or more extra columns. If a search produces extra columns (that is,
columns whose data is determined by the search instead of queries against the database), then
for each row of output, the search must call this method to specify the values of the various
extra columns. Multiple calls to this method are allowed, in which case each call either
overrides or adds to the values specified by the prior call.

=over 4

=item extraColumnMap

A hash keyed on extra column name that maps the column names to the column's values for the current
row of table data.

=back

=cut

sub PutExtraColumns {
    # Get the parameters.
    my ($self, %extraColumnMap) = @_;
    # Copy the hash values into the extra column hash.
    my $counter = 0;
    for my $name (keys %extraColumnMap) {
        $self->{extras}->{$name} = $extraColumnMap{$name};
        Trace("Extra column $name has value $extraColumnMap{$name}.") if T(4);
    }
}

=head2 Internal Utilities

=head3 StoreColumnSpec

    $rhelp->_StoreColumnSpec($column, $location);

Store the specified column information at the specified location in the column name list.
The information is a string for an ordinary column and a hash for an extra column. The
actual location at which the column is stored will be adjusted so that there are no
gaps in the list. If the location is undefined, it defaults to the end. Thus, C<0>
will always store at the beginning and C<undef> will always store at the end. If the
column is already in the list this method will have no effect.

=over 4

=item column

A column name or extra-column hash to be stored in the column list.

=item location

The index at which the column name should be stored, or C<undef> to store it
at the end.

=back

=cut

sub _StoreColumnSpec {
    # Get the parameters.
    my ($self, $column, $location) = @_;
    # Get the current column list.
    my $columnList = $self->{columns};
    # Compute the current column count.
    my $columnCount = scalar @$columnList;
    # See if the column is already present.
    my $alreadyPresent;
    if (ref $column eq 'HASH') {
        Trace("Checking extra column $column->{name}.") if T(3);
        my @extras = grep { ref $_ eq 'HASH' } @$columnList;
        $alreadyPresent = grep { $_->{name} eq $column->{name} } @extras;
    } else {
        Trace("Checking optional column $column.") if T(3);
        $alreadyPresent = grep { $_ eq $column } @$columnList;
    }
    # Only proceed if the column is NOT already present.
    if ($alreadyPresent) {
        Trace("Column is already present.") if T(3);
    } else {
        # Adjust the location.
        if (! defined($location) || $location > $columnCount) {
            $location = $columnCount;
        }
        # Insert the column into the list.
        splice @{$self->{columns}}, $location, 0, $column;
        Trace("Column inserted at position $location.") if T(3);
    }
}


=head2 Virtual Methods

The following methods can be overridden by the subclass. In some cases, they
must be overridden.

=head3 VirtualCompute

    my $dataValue = $rhelp->VirtualCompute($colName, $type, $runTimeKey);

Retrieve the column data of the specified type for the specified column
using the optional run-time key.

This method is called after extra columns have been handled but before
built-in columns are processed. The subclass can use this method to
handle columns that are object-based or otherwise too complex or varied
for the standard built-in column protocol. If the column name isn't
recognized, this method should return an undefined value. This will
happen automatically if the base class method is not overridden.

=over 4

=item colName

Name of the relevant column.

=item type

The type of column data requested: C<title> for the column title, C<style> for the
column's display style, C<value> for the value to be put in the result cache,
C<download> for the indicator of how the column should be included in
downloads, and C<runTimeValue> for the value to be used when the result is
displayed. Note that if a run-time value is required, then the normal value
must be formatted in a special way (see L<Column Processing>).

=item runTimeKey (optional)

If a run-time value is desired, this should be the key taken from the value stored
in the result cache.

=item RETURN

Returns the requested value for the named column, or C<undef> if the column
is built in to the subclass using the old protocol.

=back

=cut

sub VirtualCompute {
    # Get the parameters.
    my ($self, $colName, $type, $runTimeKey) = @_;
    # Declare the return variable.
    my $retVal;
    # Return the result.
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
    # This method must be overridden.
    Confess("Pure virtual call to DefaultResultColumns.");
}

=head3 MoreDownloadFormats

    $rhelp->MoreDownloadFormats(\%dlTypes);

Add additional supported download formats to the type table. The table is a
hash keyed on the download type code for which the values are the download
descriptions. There is a special syntax that allows the placement of text
fields inside the description. Use square brackets containing the name
for the text field. The field will come in to the download request as
a GET-type field.

=over 4

=item dlTypes

Reference to a download-type hash. The purpose of this method is to add more
download types relevant to the particular result type. Each type is described
by a key (the download type itself) and a description. The description can
contain a single text field that may be used to pass a parameter to the
download. The text field is of the format C<[>I<fieldName>C<]>,
where I<fieldName> is the name to give the text field's parameter in the
generated download URL.

=back

=cut

sub MoreDownloadFormats {
    Trace("Pure virtual call to MoreDownloadFormats.") if T(3);
    # Take no action.
}

=head3 MoreDownloadDataMethods

    my @lines = $rhelp->MoreDownloadDataMethods($objectID, $dlType, \@cols, \@colHdrs);

Create one or more lines of download data for a download of the specified type. Override
this method if you need to process more download types than the default C<tbl> method.

=over 4

=item objectID

ID of the object for this data row.

=item dlType

Download type (e.g. C<fasta>, etc.)

=item cols

Reference to a list of the data columns from the result cache, or alternatively
the string C<header> (indicating that header lines are desired) or C<footer>
(indicating that footer lines are desired).

=item colHdrs

The list of column headers from the result cache.

=item RETURN

Returns an array of data lines to output to the download file.

=back

=cut

sub MoreDownloadDataMethods {
    # Get the parameters.
    my ($self, $objectID, $dlType, $cols, $colHdrs) = @_;
    # If we need to call this method, then the subclass should have overridden it.
    Confess("Invalid download type \"$dlType\" specified for result class $self->{type}.");
}

=head3 GetColumnNameList

    my @names = $rhelp->GetColumnNameList();

Return a complete list of the names of columns available for this result
helper. The base class method simply regurgitates the default columns.

=cut

sub GetColumnNameList {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->DefaultResultColumns();
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
    my $retVal;
    Confess("Pure virtual method Permanent called.");
    # Return the result.
    return $retVal;
}

=head3 Initialize

    $rhelp->Initialize();

Perform any initialization required after construction of the helper.

=cut

sub Initialize {
    # The default is to do nothing.
}




1;
