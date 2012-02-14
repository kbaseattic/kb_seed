#!/usr/bin/env perl -w
#
#   svr_NCBI_taxonomy [options]   taxid ...
#   svr_NCBI_taxonomy [options] < taxids
#

#
# This is a SAS Component
#

=head1 svr_NCBI_taxonomy

Get taxonomy information from NCBI

=head2 Usage

=over 4

    svr_NCBI_taxonomy  [options]  taxid ...        > tab_separated_data

    svr_NCBI_taxonomy  [options]  < file_of_taxids > tab_separated_data

=back

=head2 Command-Line Options

=head3 General Options

=over 4

=item C<-   -->

Marks the end of the flags.

=item C<-x   --Id>

Include taxid at start of each output line (always true for multiple taxa)

=back

=head3 Options that Select Returned Data

If multiple options are specified, each value is prefixed with its key.
Items are reported in the order requested.

=over 4

=item C<-.   --All>

All available data from the set of options listed below.

=item C<-a   --LineageAbbrev>

Abbreviated lineage as semicolon separated names.  This might not be quite what you expect when the taxon is a division finer than a species because it does not taxonomy may not include the name.  See C<-A (--LineageAbbrevPlus)> below.

=item C<-A   --LineageAbbrevPlus>

Abbreviated linage plus any suffix of additional terms present in the full lineage as semicolon separated names (D).

=item C<-c   --CommonName>

Common name

=item C<-d   --Division>

Name of the GenBank division.  This is the full work, not the 3 letter abbreviation used in the GenBank entry.

=item C<-f   --Lineage>

Full lineage as semicolon separated names.

=item C<-g   --GeneticCode> 

Genetic code number.

=item C<-i   --LineageAbbrevIds>

Abbreviated lineage as tab separated taxids.

=item C<-I   --LineageAbbrevPlusIds>

Abbreviated lineage plus full lineage suffix as tab separated taxids.

=item C<-l   --LineageIds>

Full lineage as tab separated taxids.

=item C<-m   --MitochondrialGeneticCode>

Mitochondrial genetic code number.

=item C<-n   --LineageNames>

Full lineage as tab separated names.

=item C<-p   --Parent>

Parent taxid.

=item C<-r   --Rank>

Taxonomic rank

=item C<-s   --ScientificName>

Scientific name

=item C<-t   --LineageAbbrevNames>

Abbreviated lineage as tab separated names.

=item C<-T   --LineageAbbrevPlusNames>

Abbreviated lineage plus full lineage suffix as tab separated names.

=back

=head3 Summary of lineage type and format flags:

    -------------------------------------------------
                                   Lineage
                           --------------------------
    Format                 Full    Abbrev  AbbrevPlus
    -------------------------------------------------
    name; name; ...         -f       -a       -A
    name \t name \t ...     -n       -t       -T       
    taxid \t taxid \t ...   -l       -i       -I
    -------------------------------------------------

=head2 Output Format

The output is one or more tab-delimited fields.

If the C<-x> flag is included, or more than one taxon_id is specified, the
taxon_id is the first column.

If more than one data type is requested, the next column is the keyword for
the data on the line.

The requested data follow.

=head2 Examples

=head3 Scientific Name:

 svr_NCBI_taxonomy -s 83333
 Escherichia coli K-12

=head3 Comparison of the NCBI abbreviated lineage (C<-a>) to the abbreviated lineage plus suffix from full lineage (C<-A>); note the addition of the species binomial from the full lineage (C<-f>):

 svr_NCBI_taxonomy -saAf 83333
 ScientificName	Escherichia coli K-12
 LineageAbbrev	Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia
 LineageAbbrevPlus	Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia; Escherichia coli
 Lineage	cellular organisms; Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia; Escherichia coli

=head3 Multiple taxids:

 svr_NCBI_taxonomy -s 83333 83334
 83333	Escherichia coli K-12
 83334	Escherichia coli O157:H7

=head3 If I can do multiple taxids, why not the whole lineage (evil way to get a nice listing)?

 svr_NCBI_taxonomy -s `svr_NCBI_taxonomy -l 83333` 83333
 131567	cellular organisms
 2	Bacteria
 1224	Proteobacteria
 1236	Gammaproteobacteria
 91347	Enterobacteriales
 543	Enterobacteriaceae
 561	Escherichia
 562	Escherichia coli
 83333	Escherichia coli K-12

=head3 Everything we can get:

 svr_NCBI_taxonomy --All 83333
 Division	Bacteria
 GeneticCode	11
 Lineage	cellular organisms; Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia; Escherichia coli
 LineageIds	131567	2	1224	1236	91347	543	561	562
 LineageNames	cellular organisms	Bacteria	Proteobacteria	Gammaproteobacteria	Enterobacteriales	Enterobacteriaceae	Escherichia	Escherichia coli
 LineageAbbrev	Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia
 LineageAbbrevIds	2	1224	1236	91347	543	561
 LineageAbbrevNames	Bacteria	Proteobacteria	Gammaproteobacteria	Enterobacteriales	Enterobacteriaceae	Escherichia
 LineageAbbrevPlus	Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacteriales; Enterobacteriaceae; Escherichia; Escherichia coli
 LineageAbbrevPlusIds	2	1224	1236	91347	543	561	562
 LineageAbbrevPlusNames	Bacteria	Proteobacteria	Gammaproteobacteria	Enterobacteriales	Enterobacteriaceae	Escherichia	Escherichia coli
 Parent	562
 Rank	no rank
 ScientificName	Escherichia coli K-12

=cut

use strict;
use NCBI_taxonomy;
use SeedAware;
use Data::Dumper;

my $usage = <<'End_of_Usage';
svr_NCBI_taxonomy - retrieve taxonomy information from NCBI

Usage:  svr_NCBI_taxonomy  [options]  taxid ...        > tab_separated_data

        svr_NCBI_taxonomy  [options]  < file_of_taxids > tab_separated_data

Options:

    -x  #  Include taxid at start of output line (D = true for multiple taxa)

Options that select data item(s) returned.  If more than one is included,
output lines include a label for the datum, then the value(s).

    -   --                          End of flags
    -.  --All                       All data
    -a  --LineageAbbrev             Abbreviated lineage as semicolon separated names
    -A  --LineageAbbrevPlus         Abbreviated linage plus full lineage suffix as
                                          semicolon separated names (D)
    -c  --CommonName                Common name
    -d  --Division                  GenBank division (full name, not 3 letters)
    -f  --Lineage                   Full lineage as semicolon separated names
    -g  --GeneticCode               Genetic code
    -i  --LineageAbbrevIds          Abbreviated lineage as tab separated taxids
    -I  --LineageAbbrevPlusIds      Abbreviated lineage plus full lineage suffix
                                          as tab separated taxids
    -l  --LineageIds                Full lineage as tab separated taxids
    -m  --MitochondrialGeneticCode  Mitochondrial genetic code
    -n  --LineageNames              Full lineage as tab separated names
    -p  --Parent                    Parent taxid
    -r  --Rank                      Rank
    -s  --ScientificName            Scientific name
    -t  --LineageAbbrevNames        Abbreviated lineage as tab separated names
    -T  --LineageAbbrevPlusNames    Abbreviated lineage plus full lineage suffix
                                        as tab separated names


Summary of lineages type and format flags:
-------------------------------------------------
                               Lineage
                       --------------------------
Format                 Full    Abbrev  AbbrevPlus
-------------------------------------------------
name; name; ...         -f       -a       -A
name \t name \t ...     -n       -t       -T       
taxid \t taxid \t ...   -l       -i       -I
-------------------------------------------------

End_of_Usage

#  Set up long flag names in a way that allows synonym translation:

my %longflag =
    (
      CommonName                => 'CommonName',
      Division                  => 'Division',
      GeneticCode               => 'GeneticCode',
      Lineage                   => 'Lineage',
      LineageAbbrev             => 'LineageAbbrev',
      LineageAbbrevIds          => 'LineageAbbrevIds',
      LineageAbbrevNames        => 'LineageAbbrevNames',
      LineageAbbrevPlus         => 'LineageAbbrevPlus',
      LineageAbbrevPlusIds      => 'LineageAbbrevPlusIds',
      LineageAbbrevPlusNames    => 'LineageAbbrevPlusNames',
      LineageIds                => 'LineageIds',
      LineageNames              => 'LineageNames',
      MitochondrialGeneticCode => ' MitochondrialGeneticCode',
      Parent                    => 'Parent',
      Rank                      => 'Rank',
      ScientificName            => 'ScientificName'
    );

my $all      = 0;
my @requests = ();
my $show_id  = 0;

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    local $_ = shift;
    if ( $_ eq '' || $_ eq '-' ) { last }

    if ( s/^-// )
    {
        if ( $longflag{ $_ } ) { push @requests, $longflag{ $_ }; next }
        if ( $_ eq 'All' )     { $all     = 1; next }
        if ( $_ eq 'Id' )      { $show_id = 1; next }
        print STDERR "Bad long flag '$_'.\n\n", $usage;
        exit;
    }

    while ( /./ )
    {
        #  Order does not matter
        if ( s/\.//g ) { $all     = 1 }
        if ( s/x//g  ) { $show_id = 1 }

        #  Order does matter
        if ( s/^a// ) { push @requests, 'LineageAbbrev'          ; next }
        if ( s/^A// ) { push @requests, 'LineageAbbrevPlus'      ; next }
        if ( s/^c// ) { push @requests, 'CommonName'             ; next }
        if ( s/^d// ) { push @requests, 'Division'               ; next }
        if ( s/^f// ) { push @requests, 'Lineage'                ; next }
        if ( s/^g// ) { push @requests, 'GeneticCode'            ; next }
        if ( s/^i// ) { push @requests, 'LineageAbbrevIds'       ; next }
        if ( s/^I// ) { push @requests, 'LineageAbbrevPlusIds'   ; next }
        if ( s/^l// ) { push @requests, 'LineageIds'             ; next }
        if ( s/^m// ) { push @requests, 'MitoGeneticCode'        ; next }
        if ( s/^n// ) { push @requests, 'LineageNames'           ; next }
        if ( s/^p// ) { push @requests, 'Parent'                 ; next }
        if ( s/^r// ) { push @requests, 'Rank'                   ; next }
        if ( s/^s// ) { push @requests, 'ScientificName'         ; next }
        if ( s/^t// ) { push @requests, 'LineageAbbrevNames'     ; next }
        if ( s/^T// ) { push @requests, 'LineageAbbrevPlusNames' ; next }

        if ( m/./ )
        {
            print STDERR "Bad flag '$_'.\n\n", $usage;
            exit;
        }
    }
}

@requests = qw( CommonName
                Division
                GeneticCode
                Lineage
                LineageIds
                LineageNames
                LineageAbbrev
                LineageAbbrevIds
                LineageAbbrevNames
                LineageAbbrevPlus
                LineageAbbrevPlusIds
                LineageAbbrevPlusNames
                MitochondrialGeneticCode
                Parent
                Rank
                ScientificName
              ) if $all;

@requests = ( 'LineageAbbrevPlus' ) if ! @requests;

my @taxids = grep { $_ }
             ( @ARGV ? @ARGV : map { chomp; ( split )[0] } <> );

@taxids or print STDERR "No taxon id supplied.\n\n", $usage and exit;
$show_id = 1 if @taxids > 1;

foreach my $taxid ( @taxids )
{
    my $data = NCBI_taxonomy::taxonomy( $taxid, { hash => 1 } );
    my @values;
    foreach ( @requests )
    {
        @values = @{ $data->{ $_ } || [] } or next;
        print join( "\t", ( $show_id      ? $taxid : () ),
                          ( @requests > 1 ? $_     : () ),
                          @values
                  ), "\n";
    }
}
