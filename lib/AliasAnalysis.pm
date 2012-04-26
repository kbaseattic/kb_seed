#!/usr/bin/perl -w

#
# This is a SAS component.
#

package AliasAnalysis;

    use strict;
    use Tracer;
    use base qw(Exporter);
    use vars qw(@EXPORT);
    @EXPORT = qw(AliasCheck);

=head1 Alias Analysis Module

=head2 Introduction

This module encapsulates data about aliases. For each alias, it tells us how to generate
the appropriate link, what the type is for the alias, its export format, and its display
format. To add new alias types, we simply update this package.

An alias has three forms. The I<internal> form is how the alias is stored in the database.
The I<export> form is the form into which it should be translated when being exported to
BRC databases. The I<natural> form is the form it takes in its own environment. For
example, C<gi|15675083> is the internal form of a GenBank ID. Its export form is
C<NCBI_gi:15675083>, and its natural form is simply C<15675083>.

=head2 The Alias Table

The alias table is a hash of hashes. Each sub-hash relates to a specific type of alias, and
the key names the alias type (e.g. C<uniprot>, C<KEGG>). The sub-hashes have three fields.

=over 4

=item pattern

This is a regular expression that will match aliases of the specified type in their internal
forms.

=item convert

This field is a hash of conversions. The key for each is the conversion type and the
data is a replacement expression. These replacement expressions rely on the pattern match
having just taken place and use the C<$1>, C<$2>, ... variables to get text from the
alias's internal form. An alias's natural form, export form, and URL are all implemented as
different types of conversions. New conversion types can be created at
will be updating the table without having to worry about changing any code. Note that for
the URL conversion, a value of C<undef> means no URL is available.

=item normalize

This is a prefix that can be used to convert an alias from its natural form to its
internal form.

=item home

This is the URL of the alias's home web site.

=item curated

This is the external database name used when the alias appears as a corresponding ID.
If the alias type is not supported by the corresponding ID effort, this value is
undefined.

=back

At some point the Alias Table may be converted from an inline hash to an external XML file.

=cut

my %AliasTable = (
        RefSeq => {
            pattern     =>  '(?:ref\|)?([NXYZA]P_[0-9\.]+)',
            home        =>  'http://www.ncbi.nlm.nih.gov',
            convert     =>  { natural   => '$1',
                              export    => 'RefSeq_Prot:$1',
                              url       => 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=protein;cmd=search;term=$1',
                            },
            normalize   =>  '',
            },
        NCBI => {
            pattern     =>  'gi\|(\d+)',
            home        =>  'http://www.ncbi.nlm.nih.gov',
            convert     =>  { natural    => '$1',
                              export     => 'NCBI_gi:$1',
                              url        => 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve;db=Protein&list_uids=$1;dopt=GenPept',
                           },
            normalize   => 'gi|',
            },
        CMR => {
            pattern     =>  'cmr\|(.+)',
            home        =>  'http://cmr.jcvi.org',
            convert     =>  { natural    => '$1',
                              export     => 'cmr|$1',
                              url        => 'http://cmr.jcvi.org/tigr-scripts/CMR/shared/GenePage.cgi?locus=$1',
                            },
            normalize   =>  'cmr|',
        },
        IMG => {
            pattern     =>  'img\|(\d+)',
            home        =>  'http://img.jgi.doe.gov',
            convert     =>  { natural    => '$1',
                              export     => 'img|$1',
                              url        => 'http://img.jgi.doe.gov/cgi-bin/w/main.cgi?page=geneDetail&gene_oid=$1',
                            },
            normalize   =>  'img|',
        },
        SwissProt => {
            pattern     =>  'sp\|([A-Z0-9]{6})',
            home        =>  'http://us.expasy.org',
            convert     =>  { natural   => '$1',
                              export    => 'Swiss-Prot:$1',
                              url       => 'http://us.expasy.org/cgi-bin/get-sprot-entry?$1',
                            },
            normalize   => 'sp|',
            },
        UniProt => {
            pattern     =>  'uni\|([A-Z0-9_]+?)',
            home        =>  'http://www.uniprot.org',
            convert     =>  { natural   => '$1',
                              export    => 'UniProtKB:$1',
                              url       => 'http://www.ebi.uniprot.org/uniprot-srv/uniProtView.do?proteinAc=$1',
                            },
            normalize   =>  'uni|',
            },
        KEGG => {
            pattern     =>  'kegg\|(([a-z]{2,4}):([a-zA-Z_0-9]+))',
            home        =>  'http://www.genome.ad.jp',
            convert     =>  { natural   => '$1',
                              export    => 'KEGG:$2+$3',
                              url       => 'http://www.genome.ad.jp/dbget-bin/www_bget?$2+$3',
                            },
            normalize   =>  'kegg|',
            },
        LocusTag => {
            pattern     =>  'LocusTag:([A-Za-z]{2,3}\d+)',
            convert     =>  { natural   => '$1',
                              export    => 'Locus_Tag:$1',
                              url       => undef,
                            },
            normalize   =>  'LocusTag:',
            },
        GeneID => {
            pattern     =>  'GeneID:(\d+)',
            convert     =>  { natural   => '$1',
                              export    => 'GeneID:$1',
                              url       => undef,
                            },
            normalize   =>  'GeneID:',
            },
        Trembl => {
            pattern     =>  'tr\|([a-zA-Z0-9]+)',
            home        =>  'http://ca.expasy.org',
            convert     =>  { natural   => '$1',
                              export    => 'TrEMBL:$1',
                              url       => 'http://ca.expasy.org/uniprot/$1',
                            },
            normalize   =>  'tr|',
            },
        GENE => {
            pattern     =>  'GENE:([a-zA-Z]{3,4}(?:-\d+)?)',
            convert     =>  { natural   => '$1',
                              export    => 'GENE:$1',
                              url       => undef,
                            },
            normalize   =>  'GENE:',
            },
        ERIC => {
            pattern     => 'eric\|(\w+\-\d+)',
            convert     => { natural    => '$1',
                             export     => 'eric|$1',
                             url        => 'http://asap.ahabs.wisc.edu/asap/feature_info.php?FeatureID=$1',
            },
        }
    );

=head3 BlackList

The Black List contains a list of alias types that should be discarded during
alias processing. Any normalized alias whose prefix matches one of the names
in the list will be discarded (see L</AliasCheck>).

=cut

my %BlackList = map { lc($_) => 1 } qw(InterPro);

=head2 Public Methods

=head3 AliasCheck

    my $okFlag = AliasCheck($alias);

Return TRUE if the specified alias is acceptable, FALSE if it is
blacklisted.

=over 4

=item alias

Alias to check, in normalized (internal) form.

=item RETURN

Returns TRUE if the alias's type is acceptable, FALSE if it is found in the blacklist.

=back

=cut

sub AliasCheck {
    # Get the parameters.
    my ($alias) = @_;
    # Declare the return variable.
    my $retVal = 1;
    # Check for a prefix.
    if ($alias =~ /^([^|:]+)/) {
        # Check the prefix against the black list.
        my $prefix = lc $1;
        Trace("Prefix for $alias is $prefix.") if T(3);
        if ($BlackList{$prefix}) {
            $retVal = 0;
        }
    }
    # Return the result.
    return $retVal;
}


=head3 AliasTypes

    my @aliasTypes = AliasAnalysis::AliasTypes();

Return a list of the alias types. The list can be used to create a menu or dropdown
for selecting a preferred alias.

=cut

sub AliasTypes {
    return sort keys %AliasTable;
}


=head3 Find

    my $aliasFound = AliasAnalysis::Find($type, \@aliases);

Find the first alias of the specified type in the list.

=over 4

=item type

Type of alias desired. This must be one of the keys in C<%AliasTable>.

=item aliases

Reference of a list containing alias names. The first alias name that matches
the structure of the specified alias type will be returned. The incoming
aliases are presumed to be in internal form.

=item RETURN

Returns the natural form of the desired alias, or C<undef> if no alias of
the specified type could be found.

=back

=cut

sub Find {
    # Get the parameters.
    my ($type, $aliases) = @_;
    # Declare the return variable.
    my $retVal;
    # Insure we have a valid alias type.
    if (! exists $AliasTable{$type}) {
        Confess("Invalid aliase type \"$type\" specified.");
    } else {
        # Get the pattern for the specified alias type.
        my $pattern = $AliasTable{$type}->{pattern};
        Trace("Alias pattern is /$pattern/.") if T(3);
        # Search for matching aliases. We can't use GREP here because we want
        # to stop as soon as we find a match. That way, the $1,$2.. variables
        # will be set properly.
        my $found;
        for my $alias (@$aliases) { last if $found;
            Trace("Matching against \"$alias\".") if T(4);
            if ($alias =~ /^$pattern$/) {
                Trace("Match found.") if T(4);
                # Here we have a match. Return the matching alias's natural form.
                $retVal = eval($AliasTable{$type}->{convert}->{natural});
                $found = 1;
            }
        }
    }
    # Return the value found.
    return $retVal;
}

=head3 Normalize

    my $normalized = AliasAnalysis::Normalize($type => $naturalName);

Convert an alias of the specified typefrom its natural form to its internal
form.

=over 4

=item type

Type of the relevant alias.

=item naturalName

Natural-form alias to be converted to internal form.

=item RETURN

Returns the normalized alias, or the original value if the alias type
is not recognized.

=back

=cut

sub Normalize {
    # Get the parameters.
    my ($type, $naturalName) = @_;
    # Declare the return variable.
    my $retVal = $naturalName;
    # Only proceed if the specified type is valid.
    if (exists $AliasTable{$type}) {
        # Normalize the name.
        $retVal = $AliasTable{$type}->{normalize} . $naturalName;
    }
    # Return the result.
    return $retVal;
}


=head3 Type

    my $naturalName = AliasAnalysis::Type($type => $name);

Return the natural name of an alias if it is of the specified type, and C<undef> otherwise.
Note that the result of this method will be TRUE if the alias is an internal form of the named
type and FALSE otherwise.

=over 4

=item type

Relevant alias type.

=item name

Internal-form alias to be matched to the specified type.

=item RETURN

Returns the natural form of the alias if it is of the specified type, and C<undef> otherwise.

=back

=cut

sub Type {
    # Get the parameters.
    my ($type, $name) = @_;
    # Declare the return variable. If there is no match, it will stay undefined.
    my $retVal;
    # Check the alias type.
    my $pattern = $AliasTable{$type}->{pattern};
    if ($name =~ /^$pattern$/) {
        # We have a match, so we return the natural form of the alias.
        $retVal = eval($AliasTable{$type}->{convert}->{natural});
    }
    # Return the result.
    return $retVal;
}

=head3 Format

    my $htmlText = AliasAnalysis::Format($type => $alias);

Return the converted form of an alias. The alias will be compared against
the patterns in the type table to determine which type of alias it is. Then
the named conversion will be applied. If the alias is not of a recognized
type, an undefined value will be returned.

=over 4

=item type

Type of conversion desired (C<natural>, C<export>, C<url>, C<internal>)

=item alias

Alias to be converted.

=item RETURN

Returns the converted alias, or C<undef> if the alias is not of a known type
or is of a type that does not support the specified conversion.

=back

=cut

sub Format {
    # Get the parameters.
    my ($type, $alias) = @_;
    # Declare the return variable.
    my $retVal;
    # This flag will be used to stop the loop.
    my $found;
    # Check this alias against all the known types.
    for my $aliasType (keys %AliasTable) { last if $found;
        # Get the conversion expression for this alias type.
        my $convertExpression = $AliasTable{$aliasType}->{convert}->{$type};
        # Check to see if we found the right type.
        my $pattern = $AliasTable{$aliasType}->{pattern};
        Trace("Matching \"$alias\" to /$pattern/.") if T(4);
        if ($alias =~ /^$pattern$/) {
            # Here we did. Denote we found the type.
            $found = 1;
            # Insure this type supports the conversion.
            if ($convertExpression) {
                # It does, so do the conversion.
                $retVal = eval("\"$convertExpression\"");
                Trace("Convert expression was \"$convertExpression\".") if T(3);
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 TypeOf

    my $type = AliasAnalysis::TypeOf($alias);

Return the type of the specified alias, or C<undef> if the alias is not
of a recognized type.

=over 4

=item alias

Alias (in internal form) whose type is desired.

=item RETURN

Returns the type of the specified alias, or C<undef> if the alias is of an
unknown type.

=back

=cut

sub TypeOf {
    # Get the parameters.
    my ($alias) = @_;
    # Declare the return variable.
    my $retVal;
    # Check this alias against all the known types.
    for my $aliasType (keys %AliasTable) { last if defined $retVal;
        # Check to see if we found the right type.
        my $pattern = $AliasTable{$aliasType}->{pattern};
        Trace("Matching \"$alias\" to /$pattern/.") if T(4);
        if ($alias =~ /^$pattern$/) {
            # Here we did. Denote we found the type.
            $retVal = $aliasType;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 IsNatural

    my $normalized = AliasAnalysis::IsNatural($type => $natural);

Return the normalized form of an alias if it is a natural name of the
specified type, or an undefined value otherwise. This is useful for
determining if a particular identifier is a natural alias.

=over 4

=item type

Type of alias name to check.

=item natural

Natural-form alias name to check.

=item RETURN

Returns the normalized alias if the incoming value is a natural-form identifier
of the specified type, or C<undef> otherwise.

=back

=cut

sub IsNatural {
    # Get the parameters.
    my ($type, $natural) = @_;
    # Declare the return variable.
    my $retVal;
    # Attempt to convert the incoming value to its normalized form.
    my $normalized = $AliasTable{$type}->{normalize} . $natural;
    # Get the pattern for this alias type.
    my $pattern = $AliasTable{$type}->{pattern};
    if ($normalized =~ /^$pattern$/) {
        # Here we have a match, so return the normalized form.
        $retVal = $normalized;
    }
    # Return the result.
    return $retVal;
}


=head3 FormatHtml

    my $htmlText = AliasAnalysis::FormatHtml(@aliases);

Create an html string that contains the specified aliases in a comma-separated list
with hyperlinks where available. The aliases are expected to be in internal form and
will stay that way.

=over 4

=item aliases

A list of aliases in internal form that are to be formatted into HTML.

=item RETURN

Returns a string containing the aliases in a comma-separated list, with hyperlinks
present on those for which hyperlinks are available.

=back

=cut

sub FormatHtml {
    # Get the parameters.
    my (@aliases) = @_;
    # Set up the output list. The hyperlinked aliases will be put in here, and then
    # srung together before returning to the caller.
    my @retVal = ();
    # Loop through the incoming aliases.
    for my $alias (@aliases) {
        # We'll put our result string in here.
        my $aliasResult;
        # Compute the alias's URL.
        my $url = Format(url => $alias);
        # Check to see if a URL does indeed exist.
        if ($url) {
            # Yes, hyperlink the alias.
            $aliasResult = "<a href=\"$url\">$alias</a>";
        } else {
            # No, return the raw alias.
            $aliasResult = $alias;
        }
        # Push the result into the return list.
        push @retVal, $aliasResult;
    }
    # Convert the aliases into a comma-separated string.
    return join(", ", @retVal);
}

=head3 AnalyzeClearinghouseArray

    my @aliases = AliasAnalysis::AnalyzeClearinghouseArray($orgName, $array);

Analyze a response array from the %FIG{Annotation Clearinghouse}%. The
response array is a list of tuples containing identifiers of essentially
identical proteins along with the name of the relevant organism, its
assignment, and other data. This method looks at the identifier and
organism name in each tuple, and if the organism name matches, it checks
to see if the identifier is of a recognized alias type. If it is, then
the identifier is added to the output list. The net effect is to harvest
the response array for aliases of the %FIG{protein encoding group}% used
to obtain the response array from the clearinghouse.

=over 4

=item orgName

Name of the genome of interest.

=item array

Array of Annotation Clearinghouse tuples. The aliases will be harvested
from this array. In the array, the first element in each tuple is an
identifier and the fourth is a genome name.

=item RETURN

Returns a list of aliases from the incoming aray of tuples.

=back

=cut

sub AnalyzeClearinghouseArray {
    # Get the parameters.
    my ($orgName, $array) = @_;
    # Declare the return variable.
    my @retVal;
    # Loop through the response array, keeping aliases that look good.
    for my $result (@$array) {
        # Get the useful pieces of this result.
        my ($alias, undef, undef, $org) = @$result;
        # Is this ID for the correct organism?
        if ($org eq $orgName) {
            # Yes. If it's refseq, throw away the prefix.
            if ($alias =~ /^ref\|(.+)/) {
                $alias = $1;
            }
            # Is it a recognized type?
            my $type = TypeOf($alias);
            if ($type) {
                # It's a recognized alias type and its for the correct
                # organism, so keep it.
                push @retVal, $alias;
            }
        }
    }
    # Return the result.
    return @retVal;
}


1;
