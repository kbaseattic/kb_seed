package NCBI_sequence;

#
# This is a SAS Component
#

#===============================================================================
#  Get information from the NCBI sequence databases.
#
#  The ids can be GenInfo numbers and/or accession numbers.  For the most part,
#  version numbers will also work, but they have a greater chance of missing
#  an entry (access to old versions is limited).
#
#      \%data = sequence(  $id,  { hash =>  1     } )
#      \%data = sequence( \@ids, { hash =>  1     } )
#
#       @data = sequence(  $id,  { key  =>  $key  } )
#       @data = sequence( \@ids, { key  =>  $key  } )
#      \@data = sequence(  $id,  { key  =>  $key  } )
#      \@data = sequence( \@ids, { key  =>  $key  } )
#
#       @data = sequence(  $id,  { keys => \@keys } )
#       @data = sequence( \@ids, { keys => \@keys } )
#      \@data = sequence(  $id,  { keys => \@keys } )
#      \@data = sequence( \@ids, { keys => \@keys } )
#
#      \@xml  = sequence(  $id,  { xml  =>  1     } )
#      \@xml  = sequence( \@ids, { xml  =>  1     } )
#
#  Keys:
#
#      AccessionNumber  # Accession number with version
#      Definition       # The definition line without the organism name
#      DefinitionLine   # Entry definition line
#      GenInfoNumber    # GenInfo number
#      OrganismName     # Scientific name
#      OrganismLineage  # Abbreviated lineage for the taxon (not present in XML)
#      OrganismTaxId    # Taxonomy id
#      Sequence         # Sequence
#      SourceDBId       # The identifier in the source database
#
#  In the first form, a hash reference is returned with the keys listed above.
#  Each returned value is a single value.
#
#  The second form returns the data associated with a given key from the above
#  list.  If the option taxonomy => 1 is added to the request, taxonomic
#  information is integrated into the hash with the following keys:
#
#  The last form returns the XML hierarchy in perl lists of the form:
#
#      [ tag, [ enclosed_items, ... ] ]
#
#-------------------------------------------------------------------------------
#  Get GenBank format nucleotide sequence entries from NCBI:
#
#    $genbank = genbank(  $id  );
#    $genbank = genbank(  @ids );
#    $genbank = genbank( \@ids );
#
#  IDs can be any combination of GenInfo numbers, accession numbers, or
#  (with caveats) version numbers.  It is up to the calling routine to
#  define a reasonable batch size.
#
#-------------------------------------------------------------------------------
#  Get gi numbers for sequence accession numbers:
#
#    @giids = acc2gi(  $acc, $database );
#   \@giids = acc2gi(  $acc, $database );
#    @giids = acc2gi( \@acc, $database );
#   \@giids = acc2gi( \@acc, $database );
#
#  Database should be 'protein' or 'nucleotide'.  If it is not supplied,
#  the program can figure it out for some accession numbers.  If it cannot
#  be guessed for any accession numbers, the routine will try nucleotide,
#  and if there are no results, it will try protein.
#
#  Version numbers are accepted, but are strictly matched and might not give
#  the results expected.
#
#-------------------------------------------------------------------------------
#  Functions for doing the major steps:
#-------------------------------------------------------------------------------
#  Get and parse the XML for an NCBI taxonomy entry:
#
#      $xml = sequence_xml( $giid )
#
#  The XML is composed of items of the form:
#
#      [ tag, [ content, ... ] ]
#
#  Extract specific items from the NCBI taxonomy by keyword:
#
#      @key_valuelist = sequence_data( $xml, @data_keys );
#
#  Extract a specific item from the NCBI data by complete path through
#  XML tags.
#
#      @values = sequence_datum( $xml, @path );
#
#-------------------------------------------------------------------------------

use strict;
use SeedAware;
use NCBI_taxonomy;
use LWP::Simple;
use URI::Escape;
use Data::Dumper;

#
#  This hash is used to store paths to specific data.
#
my %path = ( AccessionNumber => [ qw( TSeq TSeq_accver   ) ],
             DefinitionLine  => [ qw( TSeq TSeq_defline  ) ], # now definition
             GenInfoNumber   => [ qw( TSeq TSeq_gi       ) ],
             OrganismName    => [ qw( TSeq TSeq_orgname  ) ],
             OrganismTaxId   => [ qw( TSeq TSeq_taxid    ) ],
             SeqType         => [ qw( TSeq TSeq_seqtype  ) ],
             Sequence        => [ qw( TSeq TSeq_sequence ) ],
             SourceDbId      => [ qw( TSeq TSeq_sid      ) ],
           );

my %okay = map { $_ => 1 } keys %path, qw( Definition OrganismLineage );


sub sequence
{
    my $ids = shift;
    return wantarray ? () : []  unless $ids;

    my @ids = grep { /^\S+$/ }                  #  No white space in ids
              ref $ids eq 'ARRAY' ? @$ids : ( $ids );
    return wantarray ? () : []  unless @ids;

    my @giids;
    my @accs;
    foreach my $id ( @ids )
    {
        $id =~ s/^gi[:|]//i;
        if  ( $id =~ /^\d+$/ ) { push @giids, $id; next }
        $id =~ s/^w+[:|]//;
        push @accs, $id if $id =~ /^[A-Z]\w+(?:\.\d+)?$/i;
    }
    push @giids, acc2gi( \@accs ) if @accs;
    return wantarray ? () : []  unless @giids;

    my $options = ( ! @_ || ! $_[0] )           ? {}                     # no request
                : ( ! ref( $_[0] ) )            ? { keys => [ $_[0] ] }  # scalar = keyword
                : (   ref( $_[0] ) eq 'ARRAY' ) ? { keys => $_[0]     }  # array ref
                : (   ref( $_[0] ) ne 'HASH' )  ? {}                     # bad ref type
                :                                 $_[0];                 # hash ref

    my $keys = $options->{ keys } || $options->{ key } || 'Sequence';
    my @keys = grep { $_ && $okay{ $_ } } ( ( ref $keys eq 'ARRAY' ) ? @$keys : ( $keys ) );
    @keys = qw( Sequence ) if ! @keys;

    my $taxonomy = $options->{ taxonomy } || grep { m/Lineage/i } @keys;

    #  XML

    my $xml = sequence_xml( join( ',', @giids ), $options->{ db } );
    # print STDERR Dumper( $xml ); exit;

    return wantarray ? () : []  unless $xml && ref( $xml ) eq 'ARRAY' &&  @$xml;

    return $xml  if $options->{ xml };

    shift @$xml;
    my @results;
    my %taxonomy;
    foreach my $sequence_xml ( @$xml )
    {
        #  Hash of keys and values

        my %results = ();
        foreach my $key ( keys %path )
        {
            my @values = sequence_datum( $sequence_xml, @{ $path{ $key } } );
            $results{ $key } = $values[0] if @values;
        }

        my $definition = $results{ DefinitionLine };
        my $orgname    = $results{ OrganismName };
        if ( $definition && $orgname )
        {
            my $orgsuffix = quotemeta( "[$orgname]" );
            $definition   =~ s/\s+$orgsuffix$//;
            $results{ DefinitionLine } = "$definition [$orgname]";
        }
        $results{ Definition } = $definition;

        my $taxid = $results{ OrganismTaxId };
        if ( $taxonomy && $taxid )
        {
            $results{ OrganismLineage } = $taxonomy{ $taxid } ||= NCBI_taxonomy::lineage_abbreviated( $taxid );
        }

        push @results, $options->{ hash } ? \%results : [ map { $results{ $_ } } @keys ];
    }

    wantarray ? @results : \@results;
}


#-------------------------------------------------------------------------------
#  Get and parse the NCBI XML for a taxonomy entry:
#
#    $xml = sequence_xml( $gi_ids, $database );
#
#  The XML is composed of items of the form:
#
#      [ tag, [ content, ... ] ]
#
#-------------------------------------------------------------------------------

sub sequence_xml
{
    my $url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi';
    my $ids = shift;

    #  Since gi numbers are unique across the databases, this option does
    #  not really matter.

    my $db  = ( ( shift || '' ) =~ /^n/i ) ? 'nucleotide' : 'protein';

    my %param = ( db      => $db,
                  id      => $ids,
                  rettype => 'fasta',
                  retmode => 'xml',
                );
    my $request = join( '&', map { "$_=" . uri_escape( $param{$_}||'' ) }
                             qw( db id rettype retmode )
                      );

    my $pass = 0;
    my @return = #  Remove XML header
                 grep { /./ && ! /^<[?!]/ && ! /^<\/?pre>/ }
                 map  { s/^\s+//; s/\s+$//; $_ }
                 map  { chomp; split /\n/ }
                 LWP::Simple::get( "$url?$request" );

    ( xml_items( \@return, undef ) )[0];
}


#  This is a very crude parser that handles NCBI XML:

sub xml_items
{
    my ( $list, $close ) = @_;
    my @items = defined $close ? ( $close ) : ();
    while ( my $item = xml_item( $list, $close ) ) { push @items, $item }
    @items;
}


sub xml_item
{
    my ( $list, $close ) = @_;
    local $_ = shift @$list;
    return undef if ! $_ || defined $close && /^<\/$close>/;
    die "Bad closing tag '$_'." if /^<\//;
    return( [ $1, xml_unescape($2) ] ) if /^<(\S+)>(.*)<\/(\S+)>$/ && $1 eq $3;
    return( [ $1, $2 ] ) if /^<(\S+) value="(.*)"\/>$/;
    return( [ $1, $1 ] ) if /^<(\S+)\s*\/>$/;
    die "Bad line '$_'." if ! /^<(\S+)>$/;
    [ xml_items( $list, $1 ) ];
}


#-------------------------------------------------------------------------------
#  Get GenBank format nucleotide sequence entries from NCBI:
#
#    $genbank = genbank(  $id  );
#    $genbank = genbank(  @ids );
#    $genbank = genbank( \@ids );
#
#  IDs can be any combination of GenInfo numbers, accession numbers, or
#  (with caveats) version numbers.  It is up to the calling routine to
#  define a reasonable batch size.
#-------------------------------------------------------------------------------

sub genbank
{
    my $url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi';
    my $db  = 'nucleotide';

    my @ids = grep { $_ }
              ref( $_[0] ) ? @{$_[0]} : @_;

    my @giids;
    my @accs;
    foreach my $id ( @ids )
    {
        $id =~ s/^\s+//;
        $id =~ s/\s+$//;
        $id =~ s/^gi[:|]//i;
        if  ( $id =~ /^\d+$/ ) { push @giids, $id; next }
        $id =~ s/^w+[:|]//;
        push @accs, $id if $id =~ /^[A-Z]\w+(?:\.\d+)?$/i;
    }
    push @giids, NCBI_sequence::acc2gi( \@accs, $db ) if @accs;

    return undef unless @giids;

    my %param = ( db      => $db,
                  id      => join( ',', @giids ),
                  rettype => 'gbwithparts',
                  retmode => 'text',
                );
    my $request = join( '&', map { "$_=" . uri_escape( $param{$_}||'' ) }
                             qw( db id rettype retmode )
                      );

    LWP::Simple::get( "$url?$request" );
}


#-------------------------------------------------------------------------------
#  Get gi numbers for sequence accession numbers:
#-------------------------------------------------------------------------------
#
#    @giids = acc2gi(  $acc, $database );
#   \@giids = acc2gi(  $acc, $database );
#    @giids = acc2gi( \@acc, $database );
#   \@giids = acc2gi( \@acc, $database );
#
#   Database should be 'protein' or 'nucleotide'.  If it is not supplied,
#   for some accession numbers the program can figure it out.  For the others,
#   it will try one, and if there are no results, it will try the other.
#   Version numbers are accepted, but are strictly matched and might not give
#   the results expected.
#-------------------------------------------------------------------------------
sub acc2gi
{
    my ( $acc, $db ) = @_;

    my $service = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi';

    my @acc = map { s/^\s+//; s/\s.*$//; /^\w+(?:\.\d+)?$/ ? $_ : () }
              map { split /,/ }
              ref($acc) eq 'ARRAY' ? @$acc : ($acc);


    my @db = $db ? ( $db ) : ();
    if ( @db < 1 )
    {
        @db = scalar( grep { /^NC_/i }       @acc ) ? qw( nucleotide )
            : scalar( grep { /^[NWXYZ]P_/i } @acc ) ? qw( protein )
            : scalar( grep { /^[PQ]\d/i }    @acc ) ? qw( protein )
            :                                         qw( nucleotide protein );
    }

    my @ids;
    while ( @acc )
    {
        my $query  = join( ' OR ', map { /^(\w+)\.\d+$/ ? "($1\[ACCN\] AND $_\[ALL\])"  # version
                                                        : "$_\[ACCN\]"                  # accession
                                       }
                                   @acc <= 150 ? splice @acc, 0 : splice @acc, 0, 100
                         );
        my @new;
        foreach my $db ( @db )
        {
            my $resp = LWP::Simple::get( "$service?db=$db&term=$query" );
            @new = $resp =~ /\<Id\>(\d+)\<\/Id\>/g;
            next if ! @new;
            @db = ( $db );
            last;
        }

        push @ids, @new;
    }

    wantarray ? @ids : \@ids;
}


#-------------------------------------------------------------------------------
#  Extract items from the taxonomy:
#-------------------------------------------------------------------------------
#
#  @key_valuelist = sequence_data( $xml, @data_keys );
#
sub sequence_data
{
    my $xml = shift;
    return () unless $xml && ref $xml eq 'ARRAY' && @$xml > 1;
    map { [ $_, [ sequence_datum( $xml, @{$path{$_}} ) ] ] } grep { $path{$_} } @_;
}


#
#  @values = sequence_datum( $xml, @path );
#
sub sequence_datum
{
    my ( $xml, @path ) = @_;

    return () unless $xml && ref $xml eq 'ARRAY' && @$xml > 1 && @path;

    my $match = $xml->[0] eq $path[0];
    return () unless $match || ( $xml->[0] eq 'TSeqSet' );

    shift @path if $match;

    @path ? map  { sequence_datum( $_, @path ) } @$xml[ 1 .. (@$xml-1) ]
          : grep { defined() && ! ref() }       @$xml[ 1 .. (@$xml-1) ];
}


#-------------------------------------------------------------------------------
#  Auxiliary functions:
#-------------------------------------------------------------------------------
#  Unescape XML body:
#
#  http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
#
my %predef_ent;
BEGIN {
%predef_ent =
    ( # XML predefined entities:
      amp    => '&',
      apos   => "'",
      gt     => '>',
      lt     => '<',
      quot   => '"',

      # HTML predefined entities:
      nbsp   => ' ',
      iexcl  => '¡',
      cent    => '¢',
      pound   => '£',
      curren  => '¤',
      yen     => '¥',
      brvbar  => '¦',
      sect    => '§',
      uml     => '¨',
      copy    => '©',
      ordf    => 'ª',
      laquo   => '«',
      not     => '¬',
      shy     => ' ',
      reg     => '®',
      macr    => '¯',
      deg     => '°',
      plusmn  => '±',
      sup2    => '²',
      sup3    => '³',
      acute   => '´',
      micro   => 'µ',
      para    => '¶',
      middot  => '·',
      cedil   => '¸',
      sup1    => '¹',
      ordm    => 'º',
      raquo   => '»',
      frac14  => '¼',
      frac12  => '½',
      frac34  => '¾',
      iquest  => '¿',
      Agrave  => 'À',
      Aacute  => 'Á',
      Acirc   => 'Â',
      Atilde  => 'Ã',
      Auml    => 'Ä',
      Aring   => 'Å',
      AElig   => 'Æ',
      Ccedil  => 'Ç',
      Egrave  => 'È',
      Eacute  => 'É',
      Ecirc   => 'Ê',
      Euml    => 'Ë',
      Igrave  => 'Ì',
      Iacute  => 'Í',
      Icirc   => 'Î',
      Iuml    => 'Ï',
      ETH     => 'Ð',
      Ntilde  => 'Ñ',
      Ograve  => 'Ò',
      Oacute  => 'Ó',
      Ocirc   => 'Ô',
      Otilde  => 'Õ',
      Ouml    => 'Ö',
      times   => '×',
      Oslash  => 'Ø',
      Ugrave  => 'Ù',
      Uacute  => 'Ú',
      Ucirc   => 'Û',
      Uuml    => 'Ü',
      Yacute  => 'Ý',
      THORN   => 'Þ',
      szlig   => 'ß',
      agrave  => 'à',
      aacute  => 'á',
      acirc   => 'â',
      atilde  => 'ã',
      auml    => 'ä',
      aring   => 'å',
      aelig   => 'æ',
      ccedil  => 'ç',
      egrave  => 'è',
      eacute  => 'é',
      ecirc   => 'ê',
      euml    => 'ë',
      igrave  => 'ì',
      iacute  => 'í',
      icirc   => 'î',
      iuml    => 'ï',
      eth     => 'ð',
      ntilde  => 'ñ',
      ograve  => 'ò',
      oacute  => 'ó',
      ocirc   => 'ô',
      otilde  => 'õ',
      ouml    => 'ö',
      divide  => '÷',
      oslash  => 'ø',
      ugrave  => 'ù',
      uacute  => 'ú',
      ucirc   => 'û',
      uuml    => 'ü',
      yacute  => 'ý',
      thorn   => 'þ',
      yuml    => 'ÿ',
      OElig   => 'Œ',
      oelig   => 'œ',
      Scaron  => 'Š',
      scaron  => 'š',
      Yuml    => 'Ÿ',
      fnof    => 'ƒ',
      circ    => 'ˆ',
      tilde   => '˜',
      Alpha   => 'Α',
      Beta    => 'Β',
      Gamma   => 'Γ',
      Delta   => 'Δ',
      Epsilon => 'Ε',
      Zeta    => 'Ζ',
      Eta     => 'Η',
      Theta   => 'Θ',
      Iota    => 'Ι',
      Kappa   => 'Κ',
      Lambda  => 'Λ',
      Mu      => 'Μ',
      Nu      => 'Ν',
      Xi      => 'Ξ',
      Omicron => 'Ο',
      Pi      => 'Π',
      Rho     => 'Ρ',
      Sigma   => 'Σ',
      Tau     => 'Τ',
      Upsilon => 'Υ',
      Phi     => 'Φ',
      Chi     => 'Χ',
      Psi     => 'Ψ',
      Omega   => 'Ω',
      alpha   => 'α',
      beta    => 'β',
      gamma   => 'γ',
      delta   => 'δ',
      epsilon => 'ε',
      zeta    => 'ζ',
      eta     => 'η',
      theta   => 'θ',
      iota    => 'ι',
      kappa   => 'κ',
      lambda  => 'λ',
      mu      => 'μ',
      nu      => 'ν',
      xi      => 'ξ',
      omicron => 'ο',
      pi      => 'π',
      rho     => 'ρ',
      sigmaf  => 'ς',
      sigma   => 'σ',
      tau     => 'τ',
      upsilon => 'υ',
      phi     => 'φ',
      chi     => 'χ',
      psi     => 'ψ',
      omega   => 'ω',
      thetasym => 'ϑ',
      upsih   => 'ϒ',
      piv     => 'ϖ',
      ensp    => ' ',
      emsp    => ' ',
      thinsp  => ' ',
      zwnj    => ' ',
      zwj     => ' ',
      lrm     => ' ',
      rlm     => ' ',
      ndash   => '–',
      mdash   => '—',
      lsquo   => '‘',
      rsquo   => '’',
      sbquo   => '‚',
      ldquo   => '“',
      rdquo   => '”',
      bdquo   => '„',
      dagger  => '†',
      Dagger  => '‡',
      bull    => '•',
      hellip  => '…',
      permil  => '‰',
      prime   => '′',
      Prime   => '″',
      lsaquo  => '‹',
      rsaquo  => '›',
      oline   => '‾',
      frasl   => '⁄',
      euro    => '€',
      image   => 'ℑ',
      weierp  => '℘',
      real    => 'ℜ',
      trade   => '™',
      alefsym => 'ℵ',
      larr    => '←',
      uarr    => '↑',
      rarr    => '→',
      darr    => '↓',
      harr    => '↔',
      crarr   => '↵',
      lArr    => '⇐',
      uArr    => '⇑',
      rArr    => '⇒',
      dArr    => '⇓',
      hArr    => '⇔',
      forall  => '∀',
      part    => '∂',
      exist   => '∃',
      empty   => '∅',
      nabla   => '∇',
      isin    => '∈',
      notin   => '∉',
      ni      => '∋',
      prod    => '∏',
      sum     => '∑',
      minus   => '−',
      lowast  => '∗',
      radic   => '√',
      prop    => '∝',
      infin   => '∞',
      ang     => '∠',
      and     => '∧',
      or      => '∨',
      cap     => '∩',
      cup     => '∪',
      int     => '∫',
      there4  => '∴',
      sim     => '∼',
      cong    => '≅',
      asymp   => '≈',
      ne      => '≠',
      equiv   => '≡',
      le      => '≤',
      ge      => '≥',
      sub     => '⊂',
      sup     => '⊃',
      nsub    => '⊄',
      sube    => '⊆',
      supe    => '⊇',
      oplus   => '⊕',
      otimes  => '⊗',
      perp    => '⊥',
      sdot    => '⋅',
      lceil   => '⌈',
      rceil   => '⌉',
      lfloor  => '⌊',
      rfloor  => '⌋',
      lang    => '〈',
      rang    => '〉',
      loz     => '◊',
      spades  => '♠',
      clubs   => '♣',
      hearts  => '♥',
      diams   => '♦',
    );
}


sub xml_unescape
{
    local $_ = shift;
    s/&#(\d+);/chr($1)/eg;                 #  Numeric character (html)
    s/&#x([\dA-Fa-f]+);/chr(hex($1))/eg;   #  Numeric character (xml)
    s/&(\w+);/$predef_ent{$1}||"&$1;"/eg;  #  Predefined entity
    $_;
}


1;

