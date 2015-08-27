package Stats;

    use strict;
    use Carp;

#
# This is a SAS component
#

=head1 Statistical Reporting Object

=head2 Introduction

This package defines an object that can be used to track one or more totals and a list of
messages. The object is intially created in a blank state. Use the L</Add> method to add a
value to one of the totals. Use the L</AddMessage> method to add a message. The messages
will be returned as one long string with new-lines separating the individual messages. To
retrieve a counter value, use the L</Ask> method.

=cut

#: Constructor Stats->new();

=head2 Public Methods

=head3 new

    my $stats = Stats->new($name1, $name2, ... $nameN);

This is the constructor for the statistical reporting object. It returns an object
with no messages and zero or more counters, all set to 0. Note that there is no
need to prime the counters in this constructor, so

    my $stats = Stats->new();

is perfectly legal. In that case, the counters are created as they are needed. The advantage
to specifying names in the constructor is that they will appear on the output as having a
zero value when the statistics object is printed or dumped.

=over 4

=item name1, name2, ... nameN

Names of the counters to pre-create.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, @names) = @_;
    # Put the specified counters into a hash.
    my %map = map { $_ => 0 } @names;
    # Create the new statistics object.
    my $self = { Messages => "", Map => \%map };
    # Bless and return it.
    bless $self;
    return $self;
}

=head3 Add

    my $newValue = $stats->Add($name, $value);

Add the specified value to the counter with the specified name. If the counter does not
exist, it will be created with a value of 0.

=over 4

=item name

Name of the counter to be created or updated.

=item value

Value to add to the counter. If omitted, a value of C<1> will be assumed.

=item RETURN

Returns the new value of the counter.

=back

=cut
#: Return Type $;
sub Add {
    # Get the parameters.
    my ($self, $name, $value) = @_;
    # Note that we can't use a simple "!$value", because then 0 would
    # be translated to 1.
    if (!defined $value) {
        $value = 1;
    }
    # Get the counter's current value. If it doesn't exist, use 0.
    my $current = $self->{Map}->{$name} || 0;
    # Update the counter by adding the value.
    my $retVal = $current + $value;
    $self->{Map}->{$name} = $retVal;
    # Return the new value.
    return $retVal;
}

=head3 Accumulate

    $stats->Accumulate($other);

Roll another statistics object's values into this object. The messages will be added to our message
list, and the values of the counters will be added together. If a counter exists only in this object,
it will not be affected. If a counter exists only in the other object, it will be copied into this
one.

=over 4

=item other

Other statistical object whose values are to be merged into this object.

=back

=cut

sub Accumulate {
    # Get the parameters.
    my ($self, $other) = @_;
    # Loop through the other object's values, merging them in.
    my $otherMap = $other->{Map};
    for my $key (keys %{$otherMap}) {
        $self->Add($key, $otherMap->{$key});
    }
    $self->AddMessage($other->{Messages});
}

=head3 Messages

    my @text = $stats->Messages();

Return a list of the messages stored in this object.

=cut

sub Messages {
    # Get the parameters.
    my ($self) = @_;
    # Split up the messages.
    my @retVal = split /\n/, $self->{Messages};
    # Return the result.
    return @retVal;
}

=head3 Ask

    my $counter = $stats->Ask($name);

Return the value of the named counter.

=over 4

=item name

Name of the counter whose value is desired.

=item RETURN

Returns the value of the named counter, or C<0> if the counter does not
exist.

=back

=cut

sub Ask {
    # Get the parameters.
    my ($self, $name) = @_;
    # Clear the return value.
    my $retVal = 0;
    # Get the map.
    my $map = $self->{Map};
    # If the counter exists, extract its value. This process insures that
    # non-existent statistical keys don't get created in the hash.
    if (exists $map->{$name}) {
        $retVal = $map->{$name};
    }
    # Return the result.
    return $retVal;
}

=head3 AddMessage

    $stats->AddMessage($text);

Add a message to the statistical object's message queue.

=over 4

=item text

The text of the message to add.

=back

=cut

sub AddMessage {
    # Get the parameters.
    my ($self, $text) = @_;
    # Perform an intelligent joining.
    my $current = $self->{Messages};
    # Only proceed if there's text being added. An empty message can be ignored.
    if ($text) {
        if (!$current) {
            # The first message is added unvarnished.
            $self->{Messages} = $text;
        } else {
            # Here we have a message to append to existing text.
            $self->{Messages} = "$current\n$text";
        }
    }
}

=head3 Show

    my $dataList = $stats->Show();

Display the statistics and messages in this object as a series of lines of text.

=cut
#: Return Type $;
sub Show {
    # Get the parameters.
    my ($self) = @_;
    # Create the return variable.
    my $retVal = "";
    # Get the map.
    my $map = $self->{Map};
    # Get the key list.
    my @keys = sort keys %{$map};
    # Only proceed if there are any keys to display.
    if (scalar @keys) {
        # Convert all the statistics to integers.
        my %intMap;
        for my $statKey (@keys) {
            $intMap{$statKey} = sprintf("%d", $map->{$statKey});
        }
        # Compute the key size.
        my $keySize = Max(map { length $_ } @keys) + 1;
        my $statSize = Max(map { length "$intMap{$_}" } @keys) + 1;
        # Loop through the statistics.
        for my $statKey (@keys) {
            # Add the statistic and its value.
            $retVal .= Pad($statKey, $keySize) .
                       Pad($intMap{$statKey}, $statSize, 'left') . "\n";
        }
    }
    # Display the messages.
    $retVal .= "\n" . $self->{Messages} . "\n";
    # Return the result.
    return $retVal;
}

=head3 Display

    my $dataList = $stats->Display();

Display the statistics in this object as a single line of text.

=cut
#: Return Type $;
sub Display {
    # Get the parameters.
    my ($self) = @_;
    # Create the return variable.
    my $retVal = "";
    # Get the map.
    my $map = $self->{Map};
    # Loop through the statistics.
    for my $statKey (sort keys %{$map}) {
        # Add the statistic and its value.
        my $statValue = $map->{$statKey};
        $retVal .= " $statKey = $statValue;";
    }
    # Return the result.
    return $retVal;
}

=head3 Map

    my $mapHash = $stats->Map();

Return a hash mapping each statistical key to its total.

=cut

sub Map {
    # Get the parameters.
    my ($self) = @_;
    # Return the map.
    return $self->{Map};
}

=head3 SortedResults

    my @sortedKeys = $stats->SortedResults();

Return a list of the statistical keys, sorted in order from largest to
smallest.

=cut

sub SortedResults {
    # Get the parameters.
    my ($self) = @_;
    # Get the map.
    my $map = $self->{Map};
    # Sort the keys. We negate because we want the highest values first.
    my @retVal = sort { -($map->{$a} <=> $map->{$b}) } keys %{$map};
    # Return the result.
    return @retVal;
}

=head3 Check

    my $flag = $stats->Check($counter => $period);

Increment the specified statistic and return TRUE if the result is a
multiple of the specified period. This is a helpful method for generating
periodic trace messages. For example,

    print $stats->Ask('frogs') . " frogs processed.\n" if $stats->Check(frogs => 100) && T(3);

will generate a trace message at level 3 for every 100 frogs processed.

=over 4

=item counter

Name of the relevant statistic.

=item period

Periodicity value.

=item RETURN

Returns TRUE if the new value of the statistic is a multiple of the periodicity, else FALSE.

=back

=cut

sub Check {
    # Get the parameters.
    my ($self, $counter, $period) = @_;
    # Increment the statistic.
    my $count = $self->Add($counter => 1);
    # Check the new value against the periodicity.
    my $retVal = ($count % $period == 0);
    # Return the result.
    return $retVal;
}

=head3 Clear

    $stats->Clear();

Reset all the statistics to zero.

=cut

sub Clear {
    # Get the parameters.
    my ($self) = @_;
    # Run through the map, clearing values.
    my $map = $self->{Map};
    for my $key (keys %$map) {
        $map->{$key} = 0;
    }
}

=head3 Progress

    my $percent = $stats->Progress($counter => $total);

Increment a statistic and return the percent progress toward a specified
total.

=over 4

=item counter

Name of the relevant statistic.

=item total

Total number of objects being counted.

=item RETURN

Returns the percent of the total objects processed, including the current one.

=back

=cut

sub Progress {
    # Get the parameters.
    my ($self, $counter, $total) = @_;
    # Compute the return value.
    my $retVal = $self->Add($counter => 1) * 100 / $total;
    # Return the result.
    return $retVal;
}

=head3 Max

    my $max = Max($value1, $value2, ... $valueN);

Return the maximum argument. The arguments are treated as numbers.

=over 4

=item $value1, $value2, ... $valueN

List of numbers to compare.

=item RETURN

Returns the highest number in the list.

=back

=cut

sub Max {
    # Get the parameters. Note that we prime the return value with the first parameter.
    my ($retVal, @values) = @_;
    # Loop through the remaining parameters, looking for the highest.
    for my $value (@values) {
        if ($value > $retVal) {
            $retVal = $value;
        }
    }
    # Return the maximum found.
    return $retVal;
}

=head3 Pad

    my $paddedString = Stats::Pad($string, $len, $left, $padChar);

Pad a string to a specified length. The pad character will be a
space, and the padding will be on the right side unless specified
in the third parameter.

=over 4

=item string

String to be padded.

=item len

Desired length of the padded string.

=item left (optional)

TRUE if the string is to be left-padded; otherwise it will be padded on the right.

=item padChar (optional)

Character to use for padding. The default is a space.

=item RETURN

Returns a copy of the original string with the pad character added to the
specified end so that it achieves the desired length.

=back

=cut

sub Pad {
    # Get the parameters.
    my ($string, $len, $left, $padChar) = @_;
    # Compute the padding character.
    if (! defined $padChar) {
        $padChar = " ";
    }
    # Compute the number of spaces needed.
    my $needed = $len - length $string;
    # Copy the string into the return variable.
    my $retVal = $string;
    # Only proceed if padding is needed.
    if ($needed > 0) {
        # Create the pad string.
        my $pad = $padChar x $needed;
        # Affix it to the return value.
        if ($left) {
            $retVal = $pad . $retVal;
        } else {
            $retVal .= $pad;
        }
    }
    # Return the result.
    return $retVal;
}


1;
