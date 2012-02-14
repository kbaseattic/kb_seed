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

package PageBuilder;

    use strict;
    use CGI;
    use LWP::UserAgent;
    use HTML::Template;

=head1 HTML Page Builder Methods

=head2 Introduction

This package contains methods for building HTML pages from skeletons. The skeleton itself consists
of a hash mapping section names to section text. The text itself is in raw HTML. All pages will
contain a fixed header that includes a style sheet link and a fixed footer. The body of the page
will contain segments of raw HTML pulled from a hash.

The templates are standard PERL HTML templates. In its simplest form, a template variable is
expressed as a C<TEMPL_VAR> HTML tag. For example, the tag

    <TEMP_VAR NAME="FROG">

would be replaced by the value of the hash entry I<frog>. Variable names are case-insensitive.

=cut

#

=head2 Public Methods

=head3 new

    my $builder = PageBuilder::new($fileName, \%variableHash, $relocator);

Start writing web content to the standard output. This method outputs the content-type
string and processes the header portion of the specified file name. It saves the
footer portion for use later. The text C<< <!--BREAK--> >> is used to separate the
header part of the template file from the footer part (note the lack of whitespace).

=over 4

=item fileName

Name of the file containing the template.

=item variableHash

Hash mapping variable names to raw HTML.

=item relocator (optional)

Address to which self-references should be relocated. This string will
replace the dot in any "./" sequence beginning a hyperlink or image
source reference. If the CGI script is running in a different directory
from the template, this parameter can be used to automatically fix
links.

=back

=cut

sub new {
    # Get the parameters.
    my ($fileName, $variableHash, $relocator) = @_;
    # Read the template file.
    my $template = Tracer::GetFile($fileName);
    # Create the return object. We default to a simple header and footer.
    my $self = { header => "<html><body>", footer => "</body></html>" };
    # Perform the necessary variable substitution. Note that we re-use the "template"
    # variable to save memory.
    $template = Build($template, $variableHash, $relocator);
    # Find the break marking.
    if ($template =~ m/(<!--\s*BREAK\s*-->)/ig) {
        # We found the break marking, so split the template into a header and a footer.
        # First, we need the break position. Note that the break string is in $1.
        my $end = pos $template;
        my $start = $end - length $1;
        # Now we can split the header and footer.
        $self->{header} = substr $template, 0, $start;
        $self->{footer} = substr $template, $end;
    } else {
        # Here no break was found. The entire thing is the header.
        $self->{header} = $template;
        $self->{footer} = "";
    }
    # Write the header.
    print $self->{header};
    # Bless and return this object.
    bless $self;
    return $self;
}

=head3 Build

    my $page = PageBuilder::Build($template, \%segmentHash, $relocator);

Build a page from a template and a hash. The template can be specified as a
string, a URL, or as a file name. If it is specified as a file name, the file name
must be preceded by the "<<" symbol. Thus,

    my $page = PageBuilder::Build("<<Protein_tmpl.htm", \%segmentHash, $relocator);

will use the contents of the file I<Protein_tmpl.htm> as the template.

=over 4

=item template

Template string from which the page will be built, the name of a
file containing the template, preceded by a "<<" symbol, or
the URL of a template on a web server.

=item segmentHash

Hash mapping variable names to raw HTML. If a variable maps to a list of strings,
the list is joined using new-lines. If it maps to a list of hash references,
then it is presumed to be a C<TMPL_LOOP> variable.

=item relocator

If specified, a string to be put in front of all relocatable image and hyperlink
references in the template string. The references must begin with a dot-slash
as in

    <a href="./Protein.html">Protein Page</a>

The relocator string will be substituted for the dot. This capability is provided
because most template files are designed in a different directory from the CGI
scripts that use them to generate web pages. The template can be designed in the
same directory as the images and style sheets it uses, and when it is invoked from
a CGI script, the link references will automatically be fixed to specify the
correct relative (or absolute) directory.

=item RETURN

 Returns a string containing the complete HTML text.

=back

=cut

sub Build {
    # Discard the first parameter if this is an object call.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    # Get the parameters.
    my ($template, $segmentHash, $relocator) = @_;
    # Check for a file name.
    if ($template =~ m/^<<(.*)$/) {
        # Here we have a file name, so we need to read the file.
        $template = Tracer::GetFile($1);
    } elsif ($template =~ m!^http://!) {
        # Here we have a URL, so we need to fetch a web page.
        Tracer::Trace("Reading template from URL $template.") if Tracer::T(3);
        $template = GetPage($template);
    }
    # Get a copy of the template value.
    my $html = $template;
    # If there is a relocator, apply it to the template links.
    if ($relocator) {
        # Find all the links we need to relocate.
        while ($html =~ m/(href|src)="\.\//gi) {
            # Here we've found a link to relocate and pos $retVal
            # points after the dot-slash. We replace the dot with the
            # relocator string.
            my $pos = (pos $html) - 2;
            substr $html, $pos, 1, $relocator;
        }
    }
    # Now we can process the template. First we create the template object.
    my $templateObject = HTML::Template->new(scalarref => \$html,
                                             die_on_bad_params => 0);
    # Next, we pass in the variable values.
    for my $varKey (keys %{$segmentHash}) {
        # Get the variable value.
        my $varValue = $segmentHash->{$varKey};
        # Check for an undefined value.
        if (! defined($varValue)) {
            # Treat it as a null string.
            $templateObject->param($varKey => "");
        } else {
            # Check for an array of scalars. We convert this into a string
            # for compatibility with earlier stuff. An array of hashes is
            # okay, because it's used for loops.
            if (ref $varValue eq 'ARRAY') {
                if (scalar @{$varValue} > 0 && ! ref $varValue->[0]) {
                    $varValue = join("\n", @{$varValue});
                }
            }
            # Record the parameter.
            Tracer::Trace("Variable $varKey has value \"$varValue\".") if Tracer::T(3);
            $templateObject->param($varKey => $varValue);
        }
    }
    # Finally, we produce the output.
    my $retVal = $templateObject->output();
    # Return the result.
    return $retVal;
}

=head3 GetPage

    my $pageContent = PageBuilder::GetPage($url);

Request the content of a page at a specified URL.

=over 4

=item url

URL of the desired page.

=item RETURN

Returns the content of the page as a string. If the URL indicates a script
file, the content returned will be the output of the script.

=back

=cut

sub GetPage {
    # Get the parameters.
    my ($url) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the web page.
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);
    # Check the result.
    if (! $response->is_success) {
        Tracer::Confess("Could not retrieve template source from $url.");
    } else {
        $retVal = $response->content;
        Tracer::Trace("Template read from URL $url.") if Tracer::T(3);
    }
    # Return the result.
    return $retVal;
}

=head3 Finish

    $builder->Finish();

Write the footer to the current page.

=cut

sub Finish {
    # Get the parameters.
    my ($self) = @_;
    # Write the footer.
    print $self->{footer};
    # Close the last line.
    print "\n";
}

=head3 StartTable

    $builder->StartTable(@columnNames);

Output the heading text for a standard table.

=over 4

=item columnNames

List of the names to use for each column. If the list is empty, no column headings will be
created. The names will automatically be escaped.

=back

=cut

sub StartTable {
    # Get the parameters.
    my ($self, @columnNames) = @_;
    # Print the table tag.
    print "<table border=\"2\" cellpadding=\"2\">\n";
    # If we have column names, generate the column headings.
    if (@columnNames > 0) {
        print "<tr>";
        for my $columnName (@columnNames) {
            print "<th>" . XText($columnName) . "</th>";
        }
        print "</tr>\n";
    }
}

=head3 TableRow

    $builder->TableRow(\@dataValues, \%options);

Output a table row.

=over 4

=item options

Options controlling the translation of text in the table elements to
HTML. These are identical to the options in the L</XText> method.

=item dataValues

List of data values to use for the columns of the table. The names will automatically be escaped.

=back

=cut

sub TableRow {
    # Get the parameters.
    my ($self, $dataValues, $options) = @_;
    # Generate the table row.
    print "<tr>";
    for my $dataValue (@{$dataValues}) {
        # Check to see if this cell is an array.
        if (ref $dataValue eq "ARRAY") {
            # Here we have an array, so we process it as a list.
            print "<td><ul>";
            for my $dataEntry (@{$dataValue}) {
                print "<li>" . XText($dataEntry, $options) . "</li>";
            }
        } else {
            # Not an array, so we just do the text.
            print "<td>" . XText($dataValue, $options) . "</td>";
        }
    }
    print "</tr>\n";
}

=head3 FinishTable

    $builder->FinishTable();

Output the trailing text for a standard table.

=cut

sub FinishTable {
    print "</table>\n";
}

=head3 TagItem

    $builder->TagItem($tag, $text, \%options);

Output a tag item. For example, the following call will output a list item.

    $builder->TagItem("li", "1234&abc");

The actual text output will be as follows.

    <li>1234&amp;abc</li>

=over 4

=item tag

Name of the tag.

=item options

Options controlling the translation of text in the table elements to
HTML. These are identical to the options in the L</XText> method.

=item text

Text of the item. The text will automatically be escaped.

=back

=cut

sub TagItem {
    # Get the parameters.
    my ($self, $tag, $text, $options) = @_;
    # Generate the tag item.
    print "<$tag>" . XText($text, $options) . "</$tag>\n";
}

=head3 XText

    my $html = PageBuilder::XText($text, $options);

Translate a text string into HTML. This generally involves escaping
special characters using the C<&;> notation, but may do more (or
less) work depending on the specified options.

=over 4

=item text

Text to translate.

=item options

Hash of translation options, as follows.

B<* raw> 1 if no translation is to be performed, default C<0>

B<* multiline> 1 if new-lines are to be translated to break
commands, default C<0>

=item RETURN

Returns the text translated into a form suitable for use in an HTML
document.

=back

=cut

sub XText {
    # Get the parameters.
    my ($text, $options) = @_;
    # Merge the options with the default values.
    my $actualOptions = Tracer::GetOptions({ raw => 0, multiline => 0},
                                            $options);
    # Declare the return variable.
    my $retVal = $text;
    # If we are not raw, escape the text.
    if (!$actualOptions->{raw}) {
        $retVal = CGI::escapeHTML($retVal);
    }
    # If we are multi-line, process the new-lines.
    if ($actualOptions->{multiline}) {
        $retVal =~ s!\n!<br />\n!g;
    }
    # Return the modified text.
    return $retVal;
}

=head3 MakeFancyTable

    my $htmlText = PageBuilder::MakeFancyTable($cgi, \@col_hdrs, \@rows);

Create a fancy odd/even table using the standard NMPDR styles. The table produced
is borderless with different coloring for the odd and even rows.

=over 4

=item cgi

The CGI query object being used to generate HTML.

=item col_hdrs

Reference to a list of the column headings.

=item rows

Reference to a list of the rows to put in the table. Each element of the list should
be a reference to a list of the HTML to be put in each column. So, this parameter is
effectively the table contents organized into a list of lists, row-first.

=item RETURN

Returns the HTML to display the specified table.

=back

=cut

sub MakeFancyTable {
    # Get the parameters.
    my ($cgi, $col_hdrs, $rows) = @_;
    # Create an array for the row styles.
    my @styles = ('even', 'odd');
    # Start the table.
    my @retVal = ($cgi->start_table({border => 0}));
    # Put in the column headers.
    push @retVal, $cgi->Tr({class => $styles[1]}, $cgi->th($col_hdrs));
    # Start the first data row with the even style.
    my $styleMode = 0;
    # Loop through the rows.
    for my $row (@{$rows}) {
        # Push this row into the result list.
        push @retVal, $cgi->Tr({class => $styles[$styleMode]}, $cgi->td($row));
        # Flip the style.
        $styleMode = 1 - $styleMode;
    }
    # Close the table.
    push @retVal, $cgi->end_table();
    # Return the result.
    return join("\n", "", @retVal, "");
}



1;
