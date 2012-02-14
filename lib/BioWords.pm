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

package BioWords;

    use strict;
    use Tracer;

=head1 BioWords Package

Microbiological Word Conflation Helper

=head2 Introduction

This object is in charge of managing keywords used to search the database. Its
purpose is to insure that if a user types something close to the correct word, a
usable result will be returned.

A keyword string consists of words separated by delimiters. A I<word> is an
uninterrupted sequence of letters, semidelimiters (currently only C<'>) and digits.
A word that begins with a letter is called a I<real word>. For each real word we
produce two alternate forms. The I<stem> represents the root form of the word
(e.g. C<skies> to C<ski>, C<following> to C<follow>). The I<phonex> is computed
from the stem by removing the vowels and equating consonants that produce similar
sounds. It is likely a mispelled word will have the same phonex as its real form.

In addition to computing stems and phonexes, this object also I<cleans> a
keyword. I<Cleaning> consists of converting upper-case letters to lower case and
converting certain delimiters. In particular, bar (C<|>), colon (C<:>), and
semi-colon (C<;>) are converted to a single quote (C<'>) and period (C<.>) and
hyphen (C<->) are converted to underscore (C<_>). The importance of this is that
the single quote and underscore are considered word characters by the search
software. The cleaning causes the names of chemical compounds and the IDs of
features and genomes to behave as words when searching.

Search words must be at least three characters long, so the stem of a real word with
only three letters is the word itself, and any real word with only two letters
is discarded. In addition, there is a list of I<stop words> that are discarded
by the keyword search. These will have an empty string for the stem and phonex.

Note that the stemming algorithm differs from the standard for English because
of the use of Greek and Latin words in chemical compound names and genome
taxonomies. The algorithm has been evolving in response to numerous experiments
and is almost certainly not in its last iteration.

The fields in this object are as follows.

=over 4

=item stems

Hash of the stems found so far. This is cleared by L</AnalyzeSearchExpression>,
so it can be used by clients to determine the number of search expressions
containing a particular stem.

=item cache

Reference to a hash that maps a pure word to a hash containing its stem, a count of
the number of times it has occurred, and its phonex. The hash is also used to keep
exceptions (which map to their predetermined stem) and stop words (which map to an
empty string). The cache should only be used when the number of words being
processed is small. If multiple millions of words are put into the cache, it
causes the application to hang.

=item stopFile

The name of a file containing the stop word list, one word per line. The stop
word file is read into the cache the first time we try to stem a pure word.
Once the file is read, this field is cleared so that we know it's handled.

=item exceptionFile

The name of a file containing exception rules, one rule per line. Each rule
consists of a space-delimited list of words followed by a single stem. The
exception file is read into the cache the first time we try to stem a pure word.
Once the file is read, this field is cleared so that we know it's handled.

=item cacheFlag

TRUE if incoming words should be cached, else FALSE.

=item VOWEL

The list of vowel characters (lower-case). This defaults to the value of the
compile-time constant VOWELS, but may be overridden by the constructor.

=item LETTER

The list of letter characters (lower-case). This defaults to the value of the
compile-time constant LETTERS, but may be overridden by the constructor. All
of the vowels should be included in the list of letters.

=item DIGIT

The list of digit characters (lower-case). This defaults to the value of the
compile-time constant DIGITS, but may be overridden by the constructor.

=item WORD

The list of all word-like characters. This is the union of the letters
and digits.

=back

We allow configuration of letters, digits, and vowels; but in general the
stemming and phonex algorithms are aware of the English language and what the
various letters mean. The main use of the configuration strings is to allow
flexibility in the treatment of special characters, such as underscore (C<_>) and
the single quote (C<'>). The defaults have all been chosen fairly carefully based
on empirical testing, but of course everything is subject to evolution.

=head2 Special Declarations

=head3 EMPTY

The EMPTY constant simply evaluates to the empty string. It makes the stemming
rules more readable.

=cut

use constant EMPTY => '';

=head3 SHORT

The SHORT constant specifies the minimum length for a word. A word shorter than
the minimum length is treated as a stop word.

=cut

use constant SHORT => 3;

=head3 VOWELS

String containing the characters that are considered vowels (lower case only).

=cut

use constant VOWELS => q(aeiou_);

=head3 LETTERS

String containing the characters that are considered letters (lower case only).

=cut

use constant LETTERS => q(abcdefghijklmnopqrstuvwxyz_);

=head3 DIGITS

String containing the characters that are considered digits (lower case only).

=cut

use constant DIGITS => q(0123456789');

=head3 new

    my $bw = BioWords->new(%options);

Construct a new BioWords object. The following options are supported.

=over 4

=item exceptions

Name of the exception file, or a reference to a hash containing the exception
rules. The default is to have no exceptions.

=item stops

Name of the stop word file, or a reference to a list containing the stop words.
The default is to have no stop words.

=item vowels

List of characters to be treated as vowels (lower-case only). The default is
a compile-time constant.

=item letters

List of characters to be treated as letters (lower-case only). The default is a
compile-time constant.

=item digits

List of characters to be treated as digits (lower-case only). The default is a
compile-time constant.

=item cache

If TRUE, then words will be cached when they are processed. If FALSE, the cache
will only be used for stopwords and exceptions. The default is TRUE.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, %options) = @_;
    # Get the options.
    my $exceptionOption = $options{exceptions} || "$FIG_Config::sproutData/Exceptions.txt";
    my $stopOption = $options{stops} || "$FIG_Config::sproutData/StopWords.txt";
    my $vowels = $options{vowels} || VOWELS;
    my $letters = $options{letters} || LETTERS;
    my $digits = $options{digits} || DIGITS;
    my $cacheFlag = (defined $options{cache} ? $options{cache} : 1);
    my $cache = {};
    # Create the BioWords object.
    my $retVal = { 
                    cache => $cache,
                    cacheFlag => $cacheFlag,
                    stopFile => undef,
                    exceptionFile => undef,
                    stems => {},
                    VOWEL => $vowels,
                    LETTER => $letters,
                    DIGIT => $digits,
                    WORD => "$letters$digits"
                 };
    # Now we need to deal with the craziness surrounding the exception hash and the stop word
    # list, both of which are loaded into the cache before we start processing anything
    # serious. The exceptions and stops could be passed in as hash references, in which case
    # we load them into the cache. Alternatively, they could be file names, which we save
    # to be read in when we need them. So, first, we check for an exception file name.
    if (! ref $exceptionOption) {
        # Here we have a file name. We store it in the object.
        $retVal->{exceptionFile} = $exceptionOption;
    } else {
        # Here we have a hash. Slurp it into the cache.
        for my $exceptionWord (keys %{$exceptionOption}) {
            Store($retVal, $exceptionWord, $exceptionOption->{$exceptionWord}, 0);
        }
    }
    # Now we check for a stopword file name.
    if (! ref $stopOption) {
        # Store it in the object.
        $retVal->{stopFile} = $stopOption;
    } else {
        # No file name, so slurp in the list of words.
        for my $stopWord (@{$stopOption}) {
            Stop($retVal, $stopWord);
        }
    }
    # Bless and return the object.
    bless $retVal, $class;
    return $retVal;
}

=head2 Public Methods

=head3 Stop

    $bio->Stop($word);

Denote that a word is a stop word.

=over 4

=item word

Word to be declared as a stop word.

=back

=cut

sub Stop {
    # Get the parameters.
    my ($self, $word) = @_;
    Trace("$word is a stop word.") if T(4);
    # Store the stop word.
    $self->{cache}->{$word} = {stem => EMPTY, phonex => EMPTY, count => 0 };
}

=head3 Store

    $bio->Store($word, $stem, $count);

Store a word in the cache. The word will be mapped to the
specified stem and its count will be set to the specified value. The phonex
will be computed automatically from the stem. This method can also be used to
store exceptions. In that case, the count should be C<0>.

=over 4

=item word

Word to be stored.

=item stem

Proposed stem.

=item count

Proposed count. This should be C<0> for exceptions and C<1> for normal
words. The default is C<1>.

=back

=cut

sub Store {
    # Get the parameters.
    my ($self, $word, $stem, $count) = @_;
    # Default the count.
    my $realCount = (defined $count ? $count : 1);
    # Get the phonex for the specified stem.
    my $phonex = $self->_phonex($stem);
    # Store the word in the cache.
    $self->{cache}->{$word} = { stem => $stem, phonex => $phonex, count => $realCount };
}

=head3 Split

    my @words = $bio->Split($string);

Split a string into keywords. A keyword is this context is either a
delimiter sequence or a combination of letters, digits, underscores
(C<_>), and isolated single quotes (C<'>). All letters are converted to
lower case, and any white space sequence inside the string is converted
to a single space. Prior to splitting the string, certain strings that
have special biological meaning are modified, and certain delimiters are
converted. This helps to resolve some ambiguities (e.g. which alias names
use colons and which use vertical bars) and makes strings such as EC
numbers appear to be singleton keywords. The list of keywords we output
can be rejoined and then passed unmodified to a keyword search; however,
before doing that the individual pure words should be stemmed and checked
for spelling.

=over 4

=item string

Input string to process.

=item RETURN

Returns a List of normalized keywords and delimiters.

=back

=cut

sub Split {
    # Get the parameters.
    my ($self, $string) = @_;
    # Convert letters to lower case and collapse the white space. Note that we use the "s" modifier on
    # the substitution so that new-lines are treated as white space, and we take precautions so that
    # an undefined input is treated as a null string (which saves us from compiler warnings).
    my $lowered = (defined($string) ? lc $string : "");
    $lowered =~ s/\s+/ /sg;
    # Connect the TC prefix to TC numbers.
    $lowered =~ s/TC ((?:\d+|-)(?:\.(?:\d+|-)){3})/TC_$1/g;
    # Trim the leading space (if any).
    $lowered =~ s/^ //;
    # Fix the periods in EC and TC numbers. Note here we are insisting on real
    # digits rather than the things we treat as digits. We are parsing for real EC
    # and TC numbers, not generalized strings, and the format is specific.
    $lowered =~ s/(\d+|\-)\.(\d+|-)\.(\d+|-)\.(\d+|-)/$1_$2_$3_$4/g;
    # Fix non-trailing periods.
    $lowered =~ s/\.([$self->{WORD}])/_$1/g;
    # Fix non-leading minus signs.
    $lowered =~ s/([$self->{WORD}])[\-]/$1_/g;
    # Fix interior vertical bars and colons
    $lowered =~ s/([$self->{WORD}])[|:]([$self->{WORD}])/$1'$2/g;
    # Now split up the list so that each keyword is in its own string. The delimiters between
    # are kept, so when we're done everything can be joined back together again.
    Trace("Normalized string is -->$lowered<--") if T(4);
    my @pieces = map { split(/([^$self->{WORD}]+)/, $_) } $lowered;
    # The last step is to separate spaces from the other delimiters.
    my @retVal;
    for my $piece (@pieces) {
        while (substr($piece,0,1) eq " ") {
            $piece = substr($piece, 1);
            push @retVal, " ";
        }
        while ($piece =~ /(.+?) (.*)/) {
            push @retVal, $1, " ";
            $piece = $2;
        }
        if ($piece ne "") {
            push @retVal, $piece;
        }
    }
    # Return the result.
    return @retVal;
}

=head3 Region1

    my $root = $bio->Region1($word);

Return the suffix region for a word. This is referred to as I<region 1>
in the literature on word stemming, and it consists of everything after
the first non-vowel that follows a vowel.

=over 4

=item word

Lower-case word whose suffix region is desired.

=item RETURN

Returns the suffix region, or the empty string if there is no suffix region.

=back

=cut

sub Region1 {
    # Get the parameters.
    my ($self, $word) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Look for the R1.
    if ($word =~ /[$self->{VOWEL}][^$self->{VOWEL}](.+)/i) {
        $retVal = $1;
    }
    # Return the result.
    return $retVal;
}

=head3 FindRule

    my ($prefix, $suffix, $replacement) = BioWords::FindRule($word, @rules);

Find the appropriate suffix rule for a word. Suffix rules are specified
as pairs in a list. Syntactically, the rule list may look like a hash,
but the order of the rules is important, so in fact it is a list. The
first rule whose key matches the suffix is applied. The part of the word
before the suffix, the suffix itself, and the value of the rule are all
passed back to the caller. If no rule matches, the prefix will be the
entire input word, and the suffix and replacement will be an empty string.

=over 4

=item word

Word to parse. It should already be normalized to lower case.

=item rules

A list of rules. Each rule is represented by two entries in the list-- a suffix
to match and a value to return.

=item RETURN

Returns a three-element list. The first element will be the portion of the word
before the matched suffix, the second element will be the suffix itself, and the
third will be the replacement recommended by the matched rule. If no rule
matches, the first element will be the whole word and the other two will be
empty strings.

=back

=cut

sub FindRule {
    # Get the parameters.
    my ($word, @rules) = @_;
    # Declare the return variables.
    my ($prefix, $suffix, $replacement) = ($word, EMPTY, EMPTY);
    # Search for a match. We'll stop on the first one.
    for (my $i = 0; ! $suffix && $i < $#rules; $i += 2) {
        my $len = length($rules[$i]);
        if ($rules[$i] eq substr($word, -$len)) {
            $prefix = substr($word, 0, length($word) - $len);
            $suffix = $rules[$i];
            $replacement = $rules[$i+1];
        }
    }
    # Return the results.
    return ($prefix, $suffix, $replacement);
}

=head3 Process

    my $stem = $biowords->Process($word);

Compute the stem of the specified word and record it in the cache.

=over 4

=item word

Word to be processed.

=item RETURN

Returns the stem of the word (which could be the original word itself. If the word
is a stop word, returns a null string.

=back

=cut

sub Process {
    # Get the parameters.
    my ($self, $word) = @_;
    # Verify that the cache is initialized.
    my $cache = $self->_initCache();
    # Declare the return variable.
    my $retVal;
    # Get the word in lower case and compute its length.
    my $lowered = lc $word;
    my $len = length $lowered;
    Trace("Processing \"$lowered\".") if T(4);
    # Check to see what type of word it is.
    if (! $self->IsWord($lowered)) {
        # It's delimiters. Return it unchanged and don't record it.
        $retVal = $lowered;
    } elsif ($len < $self->{SHORT}) {
        # It's too short. Treat it as a stop word.
        $retVal = EMPTY;
    } elsif (exists $cache->{$lowered}) {
        # It's already in the cache. Get the cache entry.
        my $entry = $cache->{$lowered};
        $retVal = $entry->{stem};
        # If it is NOT a stop word, count it.
        if ($retVal ne EMPTY) {
            $entry->{count}++;
        }
    } elsif ($len <= $self->{SHORT}) {
        # It's already the minimum length. The stem is the word itself.
        $retVal = $lowered;
        # Store it if we're using the cache.
        if ($self->{cacheFlag}) {
            $self->Store($lowered, $retVal, 1);
        }
    } else {
        # Here we have a new word. We compute the stem and store it.
        $retVal = $self->_stem($lowered);
        # Store the word if we're using the cache.
        if ($self->{cacheFlag}) {
            $self->Store($lowered, $retVal, 1);
        }
    }
    # We're done. If the stem is non-empty, add it to the stem list.
    if ($retVal ne EMPTY) {
        $self->{stems}->{$retVal} = 1;
        Trace("\"$word\" stems to \"$retVal\".") if T(3);
    } else {
        Trace("\"$word\" discarded by stemmer.") if T(3);
    }
    # Return the stem.
    return $retVal;
}

=head3 IsWord

    my $flag = $biowords->IsWord($word);

Return TRUE if the specified string is a word and FALSE if it is a
delimiter.

=over 4

=item word

String to examine.

=item RETURN

Returns TRUE if the string contains no delimiters, else FALSE.

=back

=cut

sub IsWord {
    # Get the parameters.
    my ($self, $word) = @_;
    # Test the word.
    my $retVal = ($word =~ /^[$self->{WORD}]+$/);
    # Return the result.
    return $retVal;
}

=head3 StemList

    my @stems = $biowords->StemList();

Return the list of stems found in the last search expression.

=cut

sub StemList {
    # Get the parameters.
    my ($self) = @_;
    # Return the keys of the stem hash.
    my @retVal = keys %{$self->{stems}};
    return @retVal;
}

=head3 StemLookup

    my ($stem, $phonex) = $biowords->StemLookup($word);

Return the stem and phonex for the specified word.

=over 4

=item word

Word whose stem and phonex are desired.

=item RETURN

Returns a two-element list. If the word is found in the cache, the
list will consist of the stem followed by the phonex. If the word
is a stop word, the list will consist of two empty strings.

=back

=cut

sub StemLookup {
    # Get the parameters.
    my ($self, $word) = @_;
    # Declare the return variables.
    my ($stem, $phonex);
    # Get the cache.
    my $cache = $self->{cache};
    # Check the cache for the word.
    if (exists $cache->{$word}) {
        # It's found. Return its data.
        ($stem, $phonex) = map { $_->{stem}, $_->{phonex} } $cache->{$word};
    } else {
        # It's not found. Compute the stem and phonex.
        my $lowered = lc $word;
        $stem = $self->Process($lowered);
        $phonex = $self->_phonex($stem);
    }
    # Return the results.
    return ($stem, $phonex);
}

=head3 WordList

    my $words = $biowords->WordList($keep);

Return a list of all of the words that were found by
L</AnalyzeSearchExpression>. Stop words will not be included.
Because the list could potentially contain millions of words, it is returned
as a list reference.

=cut

sub WordList {
    # Get the parameters.
    my ($self) = @_;
    # Get the cache.
    my $cache = $self->{cache};
    # Declare the return variable.
    my $retVal;
    # Extract the desired words from the cache.
    $retVal = [ grep { $cache->{$_}->{count} } keys %{$cache} ];
    # Return the result.
    return $retVal;
}


=head3 PrepareSearchExpression

    my $searchExpression = $bio->PrepareSearchExpression($string);

Convert an incoming string to a search expression. The string is split
into pieces, the pieces are stemmed and processed into the cache, and
then they are rejoined after certain adjustments are made. In particular,
words without an operator preceding them are prefixed with a plus (C<+>)
so that they are treated as required words.

=over 4

=item string

Search expression to prepare.

=item RETURN

Returns a modified version of the search expression with words converted to
stems, stop words eliminated, and plus signs placed before unmodified words.

=back

=cut

sub PrepareSearchExpression {
    # Get the parameters.
    my ($self, $string) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Analyze the search expression.
    my @parts = $self->AnalyzeSearchExpression($string);
    # Now we have to put the pieces back together. At any point, we need
    # to know if we are inside quotes or in the scope of an operator.
    my ($inQuotes, $activeOp) = (0, 0);
    for my $part (@parts) {
        # Is this a word?
        if ($part =~ /[a-z0-9]$/) {
            # Yes. If no operator is present, add a plus.
            if (! $activeOp && ! $inQuotes) {
                $retVal .= "+";
                $activeOp = 0;
            }
        } else {
            # Here we have one or more operators. We process them
            # individually.
            for my $op (split //, $part) {
                if ($op eq '"') {
                    # Here we have a quote.
                    if ($inQuotes) {
                        # A close quote turns off operator scope.
                        $inQuotes = 0;
                        $activeOp = 0;
                    } else {
                        # An open quote puts us in quote mode. Words inside
                        # quotes do not need the plus added, but the
                        # quote does.
                        $inQuotes = 1;
                        $retVal .= "+";
                    }
                } elsif ($op eq ' ') {
                    # Spaces detach us from the preceding operator.
                    $activeOp = 0;
                } else {
                    # Everything else puts us in operator scope.
                    $activeOp = 1;
                }
            }
        }
        # Add this part to the output string.
        $retVal .= $part;
    }
    # Return the result.
    return $retVal;
}

=head3 AnalyzeSearchExpression

    my @list = $bio->AnalyzeSearchExpression($string);

Analyze the components of a search expression and return them to the
caller. Statistical information about the words in the expression will
have been stored in the cache, and the return value will be a list of
stems and delimiters.

=over 4

=item string

Search expression to analyze.

=item RETURN

Returns a list of words and delimiters, in an order corresponding to the
original expression. Real words will have been converted to stems and
stop words will have been converted to empty strings.

=back

=cut

sub AnalyzeSearchExpression {
    # Get the parameters.
    my ($self, $string) = @_;
    # Clear the stem list.
    $self->{stems} = {};
    # Normalize and split the search expression.
    my @parts = $self->Split($string);
    # Declare the return variable.
    my @retVal;
    # Now we loop through the parts, processing them.
    for my $part (@parts) {
        my $stem = $self->Process($part);
        push @retVal, $stem;
        Trace("Stem of \"$part\" is \"$stem\".") if T(4);
    }
    # Return the result.
    return @retVal;
}

=head3 WildsOfEC

    my @ecWilds = BioWords::WildsOfEC($number);

Return a list of all of the possible wild-carded EC numbers that would
match the specified EC number.

=over 4

=item number

EC number to process.

=item RETURN

Returns a list consisting of the original EC number and all other
EC numbers that subsume it.

=back

=cut

sub WildsOfEC {
    # Get the parameters.
    my ($number) = @_;
    # Declare the return variable. It contains at the start the original
    # EC number.
    my @retVal = $number;
    # Bust the EC number into pieces.
    my @pieces = split /\./, $number;
    # Put it back together with hyphens.
    for (my $i = 1; $i <= $#pieces; $i++) {
        if ($pieces[$i] ne '-') {
            my @wildPieces;
            for (my $j = 0; $j <= $#pieces; $j++) {
                push @wildPieces, ($j < $i ? $pieces[$j] : '-');
            }
            push @retVal, join(".", @wildPieces);
        }
    }
    # Return the result.
    return @retVal;
}

=head3 ExtractECs

    my @ecThings = BioWords::ExtractECs($string);

Return any individual EC numbers found in the specified string.

=over 4

=item string

String containing potential EC numbers.

=item RETURN

Returns a list of all the EC numbers and subsuming EC numbers found in the string.

=back

=cut

sub ExtractECs {
    # Get the parameters.
    my ($string) = @_;
    # Find all the EC numbers in the string.
    my @ecs = ($string =~ /ec\s+(\d+(?:\.\d+|\.-){3})/gi);
    # Get the wild versions.
    my @retVal = map { WildsOfEC($_) } @ecs;
    # Return the result.
    return @retVal;
}

=head2 Internal Methods

=head3 _initCache

    my $cache = $biowords->_initCache();

Insure the cache is initialized. If exception and stop word files exist,
they will be read into memory and used to populate the cache. A reference to
the cache will be returned to the caller.

=cut

sub _initCache {
    # Get the parameters.
    my ($self) = @_;
    # Check for a stopword file.
    if ($self->{stopFile}) {
        # Read the file.
        my @lines = Tracer::GetFile($self->{stopFile});
        Trace(scalar(@lines) . " lines found in stop file.") if T(3);
        # Insert it into the cache.
        for my $line (@lines) {
            $self->Stop(lc $line);
        }
        # Denote that the stopword file has been processed.
        $self->{stopFile} = EMPTY;
    }
    # Check for an exception list.
    if ($self->{exceptionFile}) {
        # Read the file.
        my @lines = Tracer::GetFile($self->{exceptionFile});
        Trace(scalar(@lines) . " lines found in exception file.") if T(3);
        # Loop through the lines.
        for my $line (@lines) {
            # Extract the words.
            my @words = split /\s+/, $line;
            # Map all of the starting words to the last word.
            my $stem = pop @words;
            for my $word (@words) {
                $self->Store($word, $stem, 0);
            }
        }
        # Denote that the exception file has been procesed.
        $self->{exceptionFile} = EMPTY;
    }
    # Return the cache.
    return $self->{cache};
}

=head3 _stem

    my $stem = $biowords->_stem($word);

Compute the stem of an incoming word. This is an internal method that
does not check the cache or do any length checking.

=over 4

=item word

The word to stem. It must already have been converted to lower case.

=item RETURN

Returns the stem of the incoming word, which could possibly be the word itself.

=back

=cut

sub _stem {
    # Get the parameters.
    my ($self, $word) = @_;
    # Copy the word so we can mangle it.
    my $retVal = $word;
    # Convert consonant "y" to "j".
    $retVal =~ s/^y/j/;
    $retVal =~ s/([aeiou])y/$1j/g;
    # Convert vowel "y" to "i".
    $retVal =~ tr/y/i/;
    # Compute the R1 and R2 regions. R1 is everything after the first syllable,
    # and R2 is everything after the second syllable.
    my $r1 = $self->Region1($retVal);
    my $r2 = $self->Region1($r1);
    # Compute the physical locations of the regions.
    my $len = length $retVal;
    my $p1 = $len - length $r1;
    my $p2 = $len - length $r2;
    # These variables will be used by FindRule.
    my ($prefix, $suffix, $ruleValue);
    # Remove the genitive apostrophe.
    ($retVal, $suffix, $ruleValue) = FindRule($retVal, q('s') => EMPTY, q('s) => EMPTY, q(') => EMPTY);
    # Process latin endings.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, us => 'i', um => 'a', ae => 'a');
    $retVal = "$prefix$ruleValue";
    # Convert plurals to singular.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, sses => 'ss', ied => 'i', ies => 'i', s => 's');
    if ($ruleValue eq 'i') {
        # If the prefix length is one, we append an "e".
        if (length $prefix <= 1) {
            $ruleValue .= "e"
        }
    } elsif ($ruleValue eq 's') {
        # Here we have a naked "s" at the end. We null it out if the prefix ends in a
        # consonant or an 'e'. Nulling it will cause the "s" to be removed.
        if ($prefix =~ /[^aiou]$/) {
            $ruleValue = EMPTY;
        }
    }
    # Finish the singularization. The possibly-modified rule value is applied to the prefix.
    # If no rule applied, this has no effect, since the prefix is the whole word and the
    # rule value is the empty string.
    $retVal = "$prefix$ruleValue";
    # Catch the special "izing" construct.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, izing => 'is');
    $retVal = "$prefix$ruleValue";
    # Convert adverbs to adjectives.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, eedli => 'ee', eed => 'ee',
                                              ingli => EMPTY, ing => EMPTY, edli => EMPTY,
                                              ed => EMPTY);
    # These rules only apply in limited circumstances.
    if ($ruleValue eq 'ee') {
        # The "ee" replacement only applies if it occurs in region 1. If it does not
        # occur there, then we put the suffix back.
        if (length($prefix) < $p1) {
            $ruleValue = $suffix;
        }
    } elsif ($suffix) {
        # Here the rule value is the empty string. It only applies if there is a
        # vowel in the prefix.
        if ($prefix !~ /[aeiou]/) {
            # No vowel, so put the suffix back.
            $ruleValue = $suffix;
        } else {
            # The prefix is now the whole word, because the rule value is the empty
            # string. Check for ending mutations. We may need to add an "e" or
            # remove a doubled letter.
            ($prefix, $suffix, $ruleValue) = FindRule($prefix, at => 'ate', bl => 'ble', iz => 'ize',
                                                      bb => 'b', dd => 'd', ff => 'f', gg => 'g',
                                                      mm => 'n', nn => 'n', pp => 'p', rr => 'r',
                                                      tt => 't');
        }
    }
    # Apply the modifications.
    $retVal = "$prefix$ruleValue";
    # Now we get serious. Here we're looking for special suffixes.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, ational => 'ate', tional => 'tion',
                                              enci => 'ence', anci => 'ance', abli => 'able',
                                              entli => 'ent', ization => 'ize', izer => 'ize',
                                              ation => 'ate', ator => 'ate', alism => 'al',
                                              aliti => 'al', alli => 'al', fulness => 'ful',
                                              ousness => 'ous', ousli => 'ous', ivness => 'ive',
                                              iviti => 'ive', biliti => 'ble', bli => 'ble',
                                              logi => 'log', fulli => 'ful', lessli => 'less',
                                              cli => 'c', dli => 'd', eli => 'e', gli => 'g',
                                              hli => 'h', kli => 'k', mli => 'm', nli => 'n',
                                              rli => 'r', tli => 't', alize => 'al', icate => 'ic',
                                              iciti => 'ic', ical => 'ic');
    # These only apply if they are in R1.
    if ($ruleValue && length($prefix) >= $p1) {
        $retVal = "$prefix$ruleValue";
    }
    # Conflate "ence" to "ent" if it's in R2.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, ence => 'ent');
    if ($ruleValue && length($prefix) >= $p2) {
        $retVal = "$prefix$ruleValue";
    }
    # Now zap "ful", "ness", "ative", and "ize", but only if they're in R1.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, ful => EMPTY, ness => EMPTY, ize => EMPTY);
    if (length($prefix) >= $p1) {
        $retVal = $prefix;
    }
    # Now we have some suffixes that get deleted if they're in R2.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, ement => EMPTY, ment => EMPTY, able => EMPTY,
                                              ible => EMPTY, ance => EMPTY, ence => EMPTY,
                                              ant => EMPTY, ent => EMPTY, ism => EMPTY, ate => EMPTY,
                                              iti => EMPTY, ous => EMPTY, ive => EMPTY, ize => EMPTY,
                                              al => EMPTY, er => EMPTY, ic => EMPTY, sion => 's',
                                              tion => 't', alli => 'al');
    if (length($prefix) >= $p2) {
        $retVal = $prefix;
    }
    # Process the doubled L.
    ($prefix, $suffix, $ruleValue) = FindRule($retVal, ll => 'l');
    $retVal = "$prefix$ruleValue";
    # Check for an ending 'e'.
    $retVal =~ s/([$self->{VOWEL}][^$self->{VOWEL}]+)e$/$1/;
    # Return the result.
    return $retVal;
}

=head3 _phonex

    my $phonex = $biowords->_phonex($word);

Compute the phonetic version of a word. Vowels are ignored, doubled
letters are trimmed to singletons, and certain letters or letter
combinations are conflated. The resulting word is likely to match a
misspelling of the original.

This is an internal method. It does not check the cache and it assumes
the word has already been converted to lower case.

=over 4

=item word

Word whose phonetic translation is desired.

=item RETURN

Returns a more-or-less phonetic translation of the word.

=back

=cut

sub _phonex {
    # Get the parameters.
    my ($self, $word) = @_;
    # Declare the return variable.
    my $retVal = $word;
    # Handle some special cases. For typed IDs, we remove the type. For
    # horrible multi-part chemical names, remove everything in front of
    # the last underscore.
    if ($word =~ /_([$self->{LETTER}]+)$/ && length($1) > $self->{SHORT}) {
        $word = $1;
    } elsif ($word =~ /^[$self->{LETTER}]+'(.+)$/ && length($1) > $self->{SHORT}) {
        $word = $1;
    }
    # Convert the pesky sibilant combinatorials to their own private symbol.
    $retVal =~ s/sch|ch|sh/S/g;
    # Convert PH to F.
    $retVal =~ s/ph/f/g;
    # Remove silent constructs.
    $retVal =~ s/gh//g;
    $retVal =~ s/^ps/s/;
    # Convert soft G to J and soft C to S.
    $retVal =~ s/g(e|i)/j$1/g;
    $retVal =~ s/c(e|i)/s$1/g;
    # Convert C to K, S to Z, M to N.
    $retVal =~ tr/csm/kzn/;
    # Singlify doubled letters.
    $retVal =~ tr/a-z//s;
    # Split off the first letter.
    my $first = substr($retVal, 0, 1, "");
    # Delete the vowels.
    $retVal =~ s/[$self->{VOWEL}]//g;
    # Put the first letter back.
    $retVal = $first . $retVal;
    # Return the result.
    return $retVal;
}

1;
