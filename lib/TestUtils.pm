package TestUtils;

#
# This is a SAS component.
#

    use strict;
    use CGI;
    use Tracer;
    use Stats;

=head1 Testing Utilities

=head2 Introduction

This package contains some utilities used by the various testing scripts. It is not
expected they will have any general application.

The major method of this object is the static L</Display>. However, that method
requires a fancy data structure to manage a symbol map of things found. Therefore,
this package is also an object package for that data structure.

When displaying something in the normal way, we render arrays as numbered lists
and hashes as definition lists. A judicious use of styles is important to make the
result look good.

Two styles are mentioned by name:

=over 4

=item item

This is used for list items, and allows you to give the item text a different
format than the item number.

=item marker

This is used for special markers.

=back

For example, the styles

    ol {
       font-weight: bold;
    }
    .item {
       font-weight: normal;
    }

will cause the list numbers to appear in bold face while the items themselves are
normal.

The style

    .marker {
        font-style: italic;
        font-color: #CCCCCC;
    }

will cause special markers to appear as italicized and gray.

Finally, we make use of a javascript toggling method called C<TUToggle> that
is currently residing in [[ErdbJs]].

=cut

# These are special marks declared as constants. First, the suffix used to denote a
# broken string.
use constant BREAK_HTML => '&nbsp;<span class="marker">&gt;&gt;</span>';
# Now an actual arrow for dereferencing.
use constant ARROW_HTML => ' <span class="marker">=&gt;&gt;</span> ';
# This is for the infamous undefined value.
use constant UNDEF_HTML => '<span class="marker">undef</span>';
# Empty string.
use constant EMPTY_HTML => '<span class="marker">empty</span>';
# Single space.
use constant SPACE_HTML => '<span class="marker">space</span>';
# We also have codes for CRs TABs, and control characters in text mode.
use constant CR_HTML => '<span class="marker">R</span>';
use constant TAB_HTML => '<span class="marker">T</span>';
use constant ICKY_HTML => '<span class="marker">?</span>';
# This is what we do to end-of-line characters in text mode.
use constant EOL_HTML => '<span class="marker">&lt;&lt;</span><br />';

# You can't use constants in a s/// expression, so we put them in a hash.
my %Marks = (CR => CR_HTML, TAB => TAB_HTML, ICKY => ICKY_HTML, EOL => EOL_HTML);

=head2 Static Methods

=head3 Display

    my $html = TestUtils::Display($value, $format, $maxCols, $maxWidth);

Format a value for HTML display.

=over 4

=item value

Value to display. It can be an object or a reference.

=item format

Format for displaying the value. The formats are B<Normal>, B<Matrix>,
B<Table>, and B<Text>. See [[DebugConsoleOutput]] for a complete
description of each type.

=item maxCols (optional)

Maximum number of table columns allowed for the C<Table> format.

=item maxWidth (optional)

Maximum number of characters per line in a table cell.

=back

=cut

sub Display {
    # Get the parameters.
    my ($value, $format, $maxCols, $maxWidth) = @_;
    # Declare the return value.
    my $retVal;
    # Create a symbol map.
    my $map = TestUtils->new($maxCols, $maxWidth);
    # Display according to the format.
    if ($format eq 'Normal') {
        $retVal = $map->DisplayNormal($value);
    } elsif ($format eq 'Table') {
        $retVal = $map->DisplayTable($value);
    } elsif ($format eq 'Matrix') {
        $retVal = $map->DisplayMatrix($value);
    } elsif ($format eq 'Text') {
        $retVal = $map->DisplayText($value);
    } else {
        # Here we have an invalid format, which we display normally with
        # an error message thrown in.
        $retVal = $map->DisplayNormal($value);
        my $safeFormat = Tracer::Clean($format);
        $retVal = join("\n", CGI::blockquote("Invalid format type \"$safeFormat\"."),
                        $retVal);
    }
    # Return the html text built.
    return "$retVal\n";
}

=head3 IsComplex

    my $type = TestUtils::IsComplex($value);

Return the type of a value. If the value is an object, array, or hash reference,
the type will be C<ARRAY> or C<HASH>. Otherwise, the type will be undefined. This
method is used to determine how to treat a value when producing a table or matrix.

=over 4

=item value

Value to be tested.

=item RETURN

Returns C<ARRAY> if the value can be treated as an array reference, C<HASH>
if the value can be treated as a hash reference, and an undefined value otherwise.

=back

=cut

sub IsComplex {
    # Get the parameters.
    my ($value) = @_;
    # Check the possibilities. The default is failure.
    my $retVal;
    # Only proceed if the value is defined and not scalar.
    if (defined $value && ref $value) {
        # We have a reference. If it is hash-based, then the word
        # HASH will appear in its string expansion. If it is array-based,
        # then the word ARRAY will appear.
        if ("$value" =~ /(HASH|ARRAY)/) {
            $retVal = $1;
        }
    }
    # Return the result.
    return $retVal;
}


=head2 TestUtils Object Methods

=head3 new

    my $symbolMap = TestUtils->new($maxCols, $maxWidth);

Create a new, blank mapping of object reference strings to object names.

This object needs to perform two functions. First, it tracks objects already
found so we don't get into a recursion loop. Second, it uses a 
[[StatsPm]] object to track the number of objects of each type already found.
This is used to generate pretty names for each object.

The parameters are both optional.

=over 4

=item maxCols

Maximum number of columns allowed in C<Table> displays.

=item maxWidth

Maximum character width of a table cell.

=back

The fields in this object are as follows.

=over 4

=item nameHash

Hash of reference strings to object names.

=item objectStats

Statistics object containing the number of objects found of each type.

=item maxCols

Maximum number of table columns allowed for the C<Table> display format.

=item maxWidth

Maximum permissible width of a table cell in characters.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $maxCols, $maxWidth) = @_;
    # Set the defaults for the table limits.
    $maxCols = 100 if ! $maxCols;
    $maxWidth = 50 if ! $maxWidth;
    # Create and bless the object.
    my $retVal = { nameHash => {},
                   path => [],
                   objectStats => Stats->new(qw(ARRAY HASH SCALAR)),
                   maxCols => $maxCols,
                   maxWidth => $maxWidth};
    bless $retVal, $class;
    return $retVal;
}

=head3 DisplayText

    my $html = $symbolMap->DisplayText($value);

Display a multi-line string in a format that makes it easy to see how all
the pieces line up.

=over 4

=item value

Value to display.

=item RETURN

HTML string that displays the value preformatted with line-end markings.

=back

=cut

sub DisplayText {
    # Get the parameters.
    my ($self, $value) = @_;
    # Declare the return variable.
    my $retVal;
    # Insure this is really a string.
    if (ref $value) {
        # It's the wrong type. Display using normal format, and prefix
        # it with an error message.
        $retVal = join("\n",
                       CGI::blockquote("Result is not a string. Normal display used."),
                       $self->DisplayNormal($value));
    } else {
        # HTML-escape the string.
        $retVal = CGI::escapeHTML($value);
        # Put in markers for the major control characters.
        $retVal =~ s/\r/$Marks{CR}/g;
        $retVal =~ s/\t/$Marks{TAB}/g;
        # Mark each new-line character.
        $retVal =~ s/\n/$Marks{EOL}/g;
        # Put in markers for the other control characters.
        $retVal =~ s/[\x00-\x1F]/$Marks{ICKY}/g;
        # Denote we're preformatted.
        $retVal = CGI::pre($retVal);
    }
    # Return the result.
    return $retVal;
}

=head3 DisplayNormal

    my $html = $symbolMap->DisplayNormal($value);

Display the specified value in HTML. This method treats the value as a
single object.

=over 4

=item value

Value to display.

=item RETURN

Returns a display of the value.

=back

=cut

sub DisplayNormal {
    # Get the parameters.
    my ($self, $value) = @_;
    # The value is displayed in a single-cell table.
    my $retVal = CGI::table(CGI::Tr(CGI::th("Result")),
                            CGI::Tr($self->DisplayCell($value)));
    return $retVal;
}


=head3 DisplayThing

    my $html = $symbolMap->DisplayThing($value);

Display the specified value in HTML. The display is output as a recursive
numbered and/or definition list, with anchors and links for references that are
re-used.

=over 4

=item value

Value to display.

=item RETURN

Returns a recursive list of the pieces of the value.

=back

=cut

sub DisplayThing {
    # Get the parameters.
    my ($self, $value) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Check for a value. Note we quote the value for the string comparisons to
    # prevent newer PERLs from attempting to use an overloaded equality operator
    # should the value be a blessed object.
    if (! defined $value) {
        # No value, so display an undef.
        $retVal = UNDEF_HTML;
    } elsif ("$value" eq '') {
        # Empty string.
        $retVal = EMPTY_HTML;
    } elsif ("$value" eq ' ') {
        # Single space.
        $retVal = SPACE_HTML;
    } elsif ("$value" =~ /^\s+$/) {
        # Pure white space. This needs to be converted to something un-spacelike or
        # it really goofs up the display.
        $retVal = CGI::span({class => "marker"}, length($value) . " white chars");
    } elsif (! ref $value) {
        # Here we have a scalar. 
        $retVal = CGI::escapeHTML($value);
    } else { 
        # Here we have a structure. Get the name hash and the path.
        my $nameHash = $self->{nameHash};
        my $path = $self->{path};
        # Have we seen it before?
        if (exists $nameHash->{$value}) {
            # Yes. Get its name.
            my $name = $nameHash->{$value};
            # Format it into a link to the original output location.
            $retVal = CGI::strong($name) . ARROW_HTML . CGI::a({href => "#$name"}, 'link');
            # Check to see if it's on the path.
            if (grep { $_ eq $name } @$path) {
                # Yes, so flag it as circular.
                $retVal .= " " . CGI::span({class => "marker"}, "CIRCULAR!!");
            }
        } else {
            # Here it's new. We need to create a name for it.
            my $type = ref $value;
            my $name = $type . $self->{objectStats}->Add($type);
            $nameHash->{$value} = $name;
            # Output the object name as an anchored string. We attach a click event
            # to toggle the object value on and off.
            $retVal = CGI::a({ name => "$name", onClick => "TUToggle('OBJ$name')" },
                             $name) . "\n";
            # Remember it in the path stack.
            push @{$path}, $name;
            # Now we determine the underlying object type. This is
            # either HASH or ARRAY. Note that the following trick
            # will treat objects as either hashes or arrays depending
            # on what's been blessed.
            if ("$value" =~ /ARRAY/) {
                # Is this array empty?
                if (scalar(@$value) == 0) {
                    # Yes. Add an empty tag.
                    $retVal .= ARROW_HTML . ' (no members)';
                } else {
                    # An array is output as a numbered list. Here we use our first
                    # style class: "item".
                    $retVal .= CGI::ol({ start => 0, id => "OBJ$name" },
                                       join("\n", map { CGI::li(CGI::span({class => "item"}, $self->DisplayThing($_))) } @{$value} ));
                }
            } elsif ("$value" =~ /HASH/) {
                # Is this hash empty?
                my @keys = sort keys %$value;
                if (scalar(@keys) == 0) {
                    # Yes. Add an empty tag.
                    $retVal .= ARROW_HTML . ' (no members)';
                } else {
                    # Here we have a hash. A hash is output as a definition list.
                    my @lines = ();
                    for my $key (@keys) {
                        my $element = $value->{$key};
                        push @lines, CGI::dt(CGI::escapeHTML($key)),
                                     CGI::dd($self->DisplayThing($element));
                    }
                    $retVal .= CGI::dl({ id => "OBJ$name" }, join("\n", @lines));
                }
            } elsif ("$value" =~ /SCALAR/) {
                # Here we have a scalar reference. We dereference it by one level and output
                # it with a little arrow thing.
                $retVal .= ARROW_HTML . CGI::escapeHTML(${$value});
            } else {
                # Here we have something goofy like a glob, so we just display
                # its name. Note the paranoid trick of putting it in double
                # quotes to insure it's evaluated as a string.
                $retVal .= ARROW_HTML . CGI::escapeHTML("$value");
            }
            # Pop this name off the path stack.
            pop @{$path};
            # Add a trailing new-line to the return value.
            $retVal .= "\n";
        }
    }
    # Return the result.
    return $retVal;
}


=head3 DisplayMatrix

    my $html = $symbolMap->DisplayMatrix($value);

Display a hash or list of lists as an HTML table. Each sub-list is displayed as a
table row, one element per cell, with the key or index of the row in the first
column.

=over 4

=item value

Value to display, which should be a hash of lists or a list of lists.

=item RETURN

Returns the HTML text for a table indicating the contents of the specified
hash of lists.

=back

=cut

sub DisplayMatrix {
    # Get the parameters.
    my ($self, $value) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Check the object type.
    my $type = IsComplex($value);
    if (! $type) {
        # It's the wrong type. Display using normal format, and prefix
        # it with an error message.
        $retVal = join("\n",
                       CGI::blockquote("Result is not a HASH or ARRAY. Normal display used."),
                       $self->DisplayNormal($value));
    } else {
        # Here we have something we can work with. We'll build the table rows in
        # here.
        my @rows = ();
        # Determine how to traverse the value elements.
        if ($type eq 'ARRAY') {
            $retVal = CGI::p("Array reference found.");
            # Here we have an array. We believe it to be a list of lists. If any
            # element is not a list, it will be displayed normally in a single cell. The
            # whole thing is done as a table. Start with a header row.
            push @rows, CGI::Tr(CGI::th(['Idx', 'Value']));
            # Loop through the array elements.
            my $count = scalar @{$value};
            for (my $key = 0; $key < $count; $key++) {
                # Get the value for this element.
                my $element = $value->[$key];
                # Write out the row.
                push @rows, $self->MatrixRow($key, $element);
            }
        } else {
            $retVal = CGI::p("Hash reference found.");
            # Here we have a hash. We believe it to be a hash of lists. As before,
            # if any element is not a list, it will be displayed normally in a single
            # cell.
            push @rows, CGI::Tr(CGI::th(['Key', 'Value']));
            # Loop through the hash keys.
            for my $key (sort keys %{$value}) {
                # Get the value for this key.
                my $element = $value->{$key};
                # Write it out as a row.
                push @rows, $self->MatrixRow($key, $element);
            }
        }
        # Format the whole thing as a table.
        $retVal .= CGI::table(@rows);
    }
    # Return the result.
    return $retVal;
}

=head3 MatrixRow

    my $row = $symbolMap->MatrixRow($key, $value);

Return an HTML table row for the specified key and value. The value is
expected to be a list, and will be expanded one element per cell. The
first column will be formatted as a header and will contain the key. If
the key is a number it will be left-aligned; otherwise it will be
right-aligned.

=over 4

=item key

Key to be put into the first column.

=item value

Value to be displayed in the remaining columns. If this value is not a list
reference, there will be a single column after the first containing the value.

=item RETURN

Returns an HTML table row for displaying the key and value.

=back

=cut

sub MatrixRow {
    # Get the parameters.
    my ($self, $key, $value) = @_;
    # We'll accumulate table cells in here.
    my @cells = ();
    # The first task is to process the key.
    if ($key =~ /^\s*-?\d+\s*$/) {
        # Here the key is a number.
        push @cells, CGI::th({ align => 'right'}, $key);
    } else {
        # Here it's a string. We escape it for safety reasons.
        push @cells, CGI::th(CGI::escapeHTML($key));
    }
    # Now we check the value.
    my $type = IsComplex($value);
    if ($type ne 'ARRAY') {
        # We don't have an array here, so we treat the value as a single-element list.
        push @cells, $self->DisplayCell($value);
    } else {
        # We have an array, so we put each array element in a table cell.
        push @cells, map { $self->DisplayCell($_) } @{$value};
    }
    # Return the result.
    my $retVal = CGI::Tr(@cells);
    return $retVal;
}


=head3 DisplayTable

    my $html = $symbolMap->DisplayTable($value);

Display a hash or list of hashes as an HTML table. Each sub-hash is
displayed as a table row, one element per cell, with the key in the
first column. It is assumed all of the sub-hashes have the same
structure, and each sub-hash key will be an output column.

The maximum allowable number of columns is 100. At that point, this
rather severe formatting rule produces something seriously illegible.

=over 4

=item value

Value to display, which should be a hash of hashes, all hashes having the
same structure.

=item RETURN

Returns the HTML for a table indicating the contents of the hash of hashes.

=back

=cut

sub DisplayTable {
    # Get the parameters.
    my ($self, $value) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Check the object type.
    my $type = IsComplex($value);
    if (! $type) {
        # It's the wrong type. Display using normal format, and prefix
        # it with an error message.
        $retVal = join("\n",
                       CGI::blockquote("Result is not a HASH or ARRAY. Normal display used."),
                       $self->DisplayNormal($value));
    } else {
        # Here we have something we can work with. Our first task is to look at the
        # elements we'll be writing out.  We're going to play a little trick here and
        # convert everything to a hash with no undefined values. Removing empty
        # entries in the hash or array makes the output more concise and increases
        # the odds we'll be able to write output.
        my ($keyType, %valueMap);
        if ($type eq 'ARRAY') {
            # Get the array length.
            my $count = scalar @{$value};
            # Map the array into a hash.
            for (my $key = 0; $key < $count; $key++) {
                my $element = $value->[$key];
                if (defined $element) {
                    $valueMap{$key} = $value->[$key];
                }
            }
            # Denote that the keys are array indices.
            $keyType = "Idx";
        } else {
            # Extract the non-empty hash elements.
            for my $key (keys %{$value}) {
                my $element = $value->{$key};
                if (defined $element) {
                    $valueMap{$key} = $value->{$key};
                }
            }
            # Denote that the keys are hash keys.
            $keyType = "Key";
        }
        # Now we make our second pass through the data, verifying that each value
        # is a hash, and tracking the column names. If we find something that's not a hash,
        # or if we're seeing too many columns, we set an error flag and give up.
        my %columns = ();
        my $columnsFound = 0;
        my $okFlag = 1;
        my @keys = sort { Tracer::Cmp($a, $b) } keys %valueMap;
        my $n = scalar @keys;
        for (my $i = 0; $i < $n && $okFlag; $i++) {
            # Get the element with this key.
            my $key = $keys[$i];
            my $element = $valueMap{$key};
            # Check the type.
            if (IsComplex($value) ne 'HASH') {
                # Not a hash, so we have an error.
                $okFlag = 0;
                $retVal = CGI::blockquote("Table output failed: item with key \"" .
                                          CGI::escapeHTML($key) . "\" is not a Hash.");
            } else {
                # Here we have a hash, so we track its columns.
                for my $subKey (keys %{$element}) {
                    if (! $columns{$subKey}) {
                        $columns{$subKey} = 1;
                        $columnsFound++;
                    }
                }
                # If there are too many columns, we have an error.
                if ($columnsFound > $self->{maxCols}) {
                    $okFlag = 0;
                    $retVal = CGI::blockquote("Table output failed: $columnsFound columns were found, " .
                                              " the maximum number allowed is " . $self->{maxCols} . ".");
                }
            }
        }
        # At this point, either $okFlag is FALSE, and there's an error message in $retVal,
        # or we're good to go.
        if (! $okFlag) {
            # Display the results normally. The user deserves to see the outcome of the test.
            $retVal .= $self->DisplayNormal($value);
        } else {
            # Finally, we can write output. Sort the column names.
            my @cols = sort { Tracer::Cmp($a,$b) } keys %columns;
            # Start the table with a header row.
            my @rows = (CGI::Tr(CGI::th([ $keyType, map { CGI::escapeHTML($_) } @cols])));
            # Loop through the row keys.
            for my $rowKey (@keys) {
                # Get this row's hash.
                my $rowHash = $valueMap{$rowKey};
                # Get a safe copy of the key.
                my $safeKey = CGI::escapeHTML($rowKey);
                # Generate table cells for each known column key.
                my @cells = map { $self->DisplayCell($rowHash->{$_}) } @cols;
                # Push the result onto the table list.
                push @rows, CGI::Tr(CGI::th($safeKey), @cells);
            }
            # Form the rows into a table.
            $retVal = CGI::table(@rows);
        }
    }
    # Return the result.
    return $retVal;
}

=head3 DisplayCell

    my $cell = $symbolMap->DisplayCell($value);

Display the contents of a table cell. When we are displaying an object in
a table cell, the rules for formatting are slightly different. If the
value is undefined, we leave the cell blank. If the value is a number, we
align it to the right.

=over 4

=item value

Value to display.

=item RETURN

Returns the HTML for a single table cell.

=back

=cut

sub DisplayCell {
    # Get the parameters.
    my ($self, $value) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the maximum character width of a table cell.
    my $maxWidth = $self->{maxWidth};
    # Check the incoming value.
    if (! defined $value || "$value" eq '') {
        # An undefined or empty value is a blank cell.
        $retVal = CGI::td("&nbsp;");
    } elsif ("$value" =~ /^\s*-?\d+$/) {
        # Integers are right-aligned.
        $retVal = CGI::td({ align => 'right'}, $value);
    } elsif (ref $value) {
        # Complex value: display normally.
        $retVal = CGI::td($self->DisplayThing($value));
    } elsif (length $value < $maxWidth) {
        # Here we have an unvarnished, short string.
        $retVal = CGI::td(CGI::escapeHTML($value));
    } else {
        # Here we have a long string. We need to bust it up to prevent
        # the table cells from being too awful. First, we break on all
        # the white characters.
        my @pieces = split /\s+/, $value;
        # Now we want to split up long pieces. We'll also use this opportunity to do
        # Html-escaping. The output pieces will go in a list.
        my @outputPieces = ();
        for my $piece (@pieces) {
            # Set up a variable to contain the chunks we pull off.
            my $chunk;
            # Loop until the piece is small enough.
            while (length $piece > $maxWidth) {
                # Break off a chunk. Note that we are guaranteed to get two
                # nonempty strings here, thanks to the loop condition.
                ($chunk, $piece) = ($piece =~ /(.{0,$maxWidth})(.*)/);
                # Put this chunk in the output.
                push @outputPieces, CGI::escapeHTML($chunk) . BREAK_HTML;
            }
            # Output the residual. It's the last one, so there's no little break
            # indicator at the end.
            push @outputPieces, CGI::escapeHTML($piece);
        }
        # Finally, we create the table cell.
        $retVal = CGI::td(join(" ", @outputPieces));
    }
    # Return the result.
    return $retVal;
}



1;
