#!/usr/bin/env perl -w
#
#   svr_NCBI_sequence [options] geninfo ...
#
#   http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=347943457&rettype=fasta&retmode=xml
#

#
# This is a SAS Component
#

use strict;
use NCBI_sequence;
use gjoseqlib  qw( DNA_subseq );
use SeedAware;
use Data::Dumper;


my $usage = <<'End_of_Usage';

svr_NCBI_sequence - retrieve sequence data from NCBI

Usage:

    svr_NCBI_sequence    [options]    id ...         > tab_sep_entry_data
    svr_NCBI_sequence    [options]  < id_file        > tab_sep_entry_data
    svr_NCBI_sequence -f [options]    id ...         > fasta_file
    svr_NCBI_sequence -f [options]  < id_file        > fasta_file
    svr_NCBI_sequence -G              id ...         > GenBank_file
    svr_NCBI_sequence -G            < id_file        > GenBank_file
    svr_NCBI_sequence -e [options]    location ...   > extracted_fasta_entries
    svr_NCBI_sequence -e [options]  < location_file  > extracted_fasta_entries

The IDs can be GenInfo numbers and/or accession numbers.  For the most part,
version numbers will also work, but they have a greater chance of missing
an entry (access to old versions is limited).  Database prefixes are stripped;
the id should unique within the Entrez system.

It is up to the user to determine a reasonable batch size for multiple ID
requests.

Locations can be:

    contigID_beg_end,...      # SEED style
    contigID_beg±len,...      # Sapling/KBase style
    contigID \t beg \t end

Options:

   Data output formats:

    -f    #  Fasta format.  This alters the data items included. Implicit
          #     with -e, or requests that look like subsequence locations.
    -G    #  GenBank entry; essentially all other requests are ignored
    -h    #  Include a header row on multicolumn output
    -k    #  Key-value pair format (D is tab separated fields on one line)
    -r    #  Raw key value pairs from the TinySeq XML

   Options that select data item(s) reported.  If more than one is included,
   output lines include the key, then value(s).

    -A    #  All data (other requests are ignored)
    -a    #  GenBank accession number
    -d    #  Definition (description, ... whatever you want to call it)
    -e    #  Extracted subsequences by interpretting ids as SEED, Sapling, or
          #     tab separated id, begin, and end locations in the sequences.
          #     Output format is forced to fasta. This behavior is also induced
          #     by input requests that look like locations.
    -g    #  GenInfo number (added by default at start of multisequence data)
    -i    #  Accession number for source database
    -l    #  Source organism lineage
    -n    #  Source organism name
    -s    #  Sequence
    -t    #  Source organism taxonomy id

   Options that select the Entrez database (but they do not seem to matter):

    -N    #  Nucleotide database
    -P    #  Protein database

   Options that effect program behavior:

    -w    #  Suppress warning messages

End_of_Usage

my @fasta   = qw( GenInfoNumber DefinitionLine Sequence SeqType );
my @all     = qw( GenInfoNumber AccessionNumber SourceDbId Definition OrganismName OrganismTaxId OrganismLineage Sequence );
my @default = qw( GenInfoNumber DefinitionLine Sequence );
my %is_id   = map { $_ => 1 } qw( GenInfoNumber AccessionNumber SourceDbId );

my $all      = 0;
my $extract  = 0;
my $fasta    = 0;
my $genbank  = 0;
my $header   = 0;
my $key_val  = 0;
my $db       = 'protein';
my $raw      = 0;
my @requests = ();
my $taxonomy = 0;
my $warn     = 1;

while ( @ARGV && $ARGV[0] =~ s/^-// )
{
    local $_ = shift;
    while ( /./ )
    {
        #  Order does not matter
        if ( s/A//g ) { $all     = 1 }
        if ( s/e//g ) { $extract = 1; $fasta = 1 }
        if ( s/f//g ) { $fasta   = 1 }
        if ( s/G//g ) { $genbank = 1 }
        if ( s/h//g ) { $header  = 1 }
        if ( s/k//g ) { $key_val = 1 }
        if ( s/N//g ) { $db      = 'nucleotide' }
        if ( s/P//g ) { $db      = 'protein' }
        if ( s/r//g ) { $raw     = 1 } 
        if ( s/w//g ) { $warn    = 0 } 

        #  Order does matter
        if ( s/^a// ) { push @requests, 'AccessionNumber'               ; next }
        if ( s/^d// ) { push @requests, 'Definition'                    ; next }
        if ( s/^g// ) { push @requests, 'GenInfoNumber'                 ; next }
        if ( s/^i// ) { push @requests, 'SourceDbId'                    ; next }
        if ( s/^l// ) { push @requests, 'OrganismLineage'; $taxonomy = 1; next }
        if ( s/^n// ) { push @requests, 'OrganismName'                  ; next }
        if ( s/^s// ) { push @requests, 'Sequence'                      ; next }
        if ( s/^t// ) { push @requests, 'OrganismTaxId'                 ; next }

        if ( m/./ )
        {
            print STDERR "Bad flag '$_'.\n\n", $usage;
            exit;
        }
    }
}

if ( $fasta + $genbank + $raw > 1 )
{
    print STDERR "Invalid combination of data formats:\n";
    print STDERR "   'extract'\n"  if $extract;
    print STDERR "   'fasta'\n"    if $fasta && ! $extract;
    print STDERR "   'genbank'\n"  if $genbank;
    print STDERR "   'raw'\n"      if $raw;
    print STDERR $usage;
    exit;
}

my @ids = map  { s/^\s+//; $_ }
          grep { $_ && /\w/ }
          ( @ARGV ? @ARGV : map { chomp; $_ } <> );

#  Do these look like raw gi numbers, or locations to extract?
foreach ( @ids )
{
    if ( /^\S+_\d+[-+_]\d+\b/ || /^\S+\t\d+\t\d+\b/ )
    {
        $extract = $fasta = 1;
        last;
    }
}

if ( $extract + $genbank + $raw > 1 )
{
    print STDERR "An id looks like a subsequence specification, which is incompatible with:\n";
    print STDERR "   'genbank'\n"  if $genbank;
    print STDERR "   'raw'\n"      if $raw;
    print STDERR $usage;
    exit;
}


if ( $genbank )
{
    print NCBI_sequence::genbank( \@ids ) || '';
    exit;
}

#  A location is a list of subsequences to assemble: [ [ id, beg, end ], ... ]
#  The complete sequence is indicated by [].
#  All locations within a given sequence are collected together in %locations.
#  @ids is the list of sequences that must be retrieved.

my %locations;
my @ids2;
if ( $extract )
{
    foreach ( @ids )
    {
        my $id;
        my @parts;

        #  Sapling or SEED style
        if ( /^\S+_\d+[-+_]\d+\b/ )
        {
            @parts = map { SEED_loc($_) || Sapling_loc($_) || literal($_) }
                     split /,\s*/;
            foreach ( @parts )
            {
                next if $_ && ! ref $_;
                if ( ! ( $_ && $_->[0] ) ) { $id = ''; last }
                #  Remove database id, if present
                $_->[0] =~ s/^\w+[:|]//;
                
                $id ||= $_->[0];
                if ( $id ne $_->[0] ) { $id = ''; last }
            }
        }

        #  id \t beg \t end
        elsif ( /^(?:\w+[:|])?(\S*)\t(\d+)\t(\d+)\b/ )
        {
            $id = $1;
            @parts = ( [ $1, $2, $3 ] );
        }

        #  just an id
        elsif ( /^(?:\w+[:|])?(\S*)/ )
        {
            $id = $1;
        }

        print STDERR "Bad identifier syntax: $_\n"  if ! $id && $warn;
        next if ! $id;

        #  Locations are indexed by a versionless id
        my $id2 = $id;
        $id2 =~ s/\.\d+$//;
        push @ids2, $id if ! $locations{ $id2 };
        push @{$locations{ $id2 }}, \@parts;
    }
}
else
{
    foreach ( @ids )
    {
        my ( $id ) = /^(?:\w+[:|])?(\S*)/;
        if ( ! $id )
        {
            print STDERR "Bad gi number: $_\n" if $warn;
            next;
        }
        next if $locations{ $id };
        $locations{ $id } = [[]];
        push @ids2, $id;
    }
}
@ids = @ids2;

@ids or print STDERR "No valid id supplied.\n\n", $usage and exit;

if ( $raw && ! $fasta )
{
    foreach my $id ( @ids )
    {
        my $data = NCBI_sequence::sequence( $id, { xml => 1 } );
        write_raw( $data );
        print "\n";
    }
    exit;
}

my $id_field = 0;
if ( $fasta )
{
    #  Do any ids look like accession numbers?  If so, this id default id type.
    my $acc = grep { /^[A-Z]/i } @ids;
    my $id = scalar( grep { /Accession/i  } @requests ) ? 'AccessionNumber'
           : scalar( grep { /Source.*Id/i } @requests ) ? 'SourceDbId'
           : scalar( grep { /GenInfo/i    } @requests ) ? 'GenInfoNumber'
           : 2 * $acc >= @ids                           ? 'AccessionNumber'
           :                                              'GenInfoNumber';
    @requests = ( $id, @fasta[1..3] );

    #  If we are extracting data from accession numbers, we need that in the
    #  returned data, regardless of the format request.
    if ( $acc && $extract && $requests[0] !~ /^Acc/i )
    {
        push @requests, 'AccessionNumber';
        $id_field = 4;
    }
    
}
elsif ( $all )
{
    @requests = @all;
}
elsif ( ! @requests )
{
    @requests = @default;
}
else
{
    unshift @requests, 'GenInfoNumber' if @ids > 1 && ! ( grep { $is_id{ $_ } } @requests );
}

if ( $header && ! $fasta && ! $key_val ) { print join( "\t", @requests ), "\n" }

while ( @ids )
{
    #  If there are fewer than 150 ids, get them all, otherwise get next 100:
    my $ids  = join( ',', splice @ids, 0, ( @ids <= 150 ? @ids : 100 ) );
    my @data = NCBI_sequence::sequence( $ids, { keys => \@requests, taxonomy => $taxonomy, db => $db } );

    foreach my $data ( @data )
    {
        if ( $fasta && $extract )
        {
            my $id = $data->[$id_field];
            $id =~ s/\.\d+$//;
            foreach my $loc ( @{ $locations{ $id } || [[]] } )
            {
                #
                #  $data = [ $id, $def, $seq, $seqtype [, $acc ] ]
                #
                my @parts = @$loc;
                if ( ! @parts )
                {
                    print ">$data->[0] $data->[1]\n";
                    print join( "\n", $data->[2] =~ m/(.{1,60})/g ), "\n";
                }
                else
                {
                    my $len = length( $data->[2] );
                    foreach ( @parts )
                    {
                        $_->[1] = 1    if $_->[1] < 1;
                        $_->[2] = 1    if $_->[2] < 1;
                        $_->[1] = $len if $_->[1] eq '$' || $_->[1] > $len;
                        $_->[2] = $len if $_->[2] eq '$' || $_->[2] > $len;
                    }
                    my $id  = join( ',', map { ref($_) ? "$_->[0]_$_->[1]_$_->[2]" : $_ } @parts );
                    my $seq = join( '',  map { ref($_) ? subseq( $data, $_ )       : $_ } @parts );
                    print ">$id $data->[1]\n";
                    print join( "\n", $seq =~ m/(.{1,60})/g ), "\n";
                }
            }
        }
        elsif ( $fasta )
        {
            print ">$data->[0] $data->[1]\n";
            print join( "\n", $data->[2] =~ m/(.{1,60})/g ), "\n";
        }
        elsif ( $key_val )
        {
            foreach ( @requests )
            {
                my $value = shift @$data;
                print "$_\t$value\n";
            }
            print "\n";
        }
        else
        {
            print join( "\t", @$data ), "\n";
        }
    }
}

exit;


sub SEED_loc    { $_[0] =~ /^(\S+)_(\d+|\$)_(\d+|\$)\b/ ? [ $1, $2, $3 ] : '' }

sub Sapling_loc { $_[0] =~ /^(\S+)_(\d+)([-+])(\d+)\b/  ? [ $1, $2, ($3 eq '+') ? $2+$4-1 : $2-$4+1 ] : '' }

sub literal     { $_[0] =~ /^([A-Z]+)\b/i ? $1 : '' }


sub subseq
{
    my ( $data, $loc ) = @_;
    $data->[3] =~ /^n/ ? gjoseqlib::DNA_subseq( \$data->[2], $loc->[1], $loc->[2] )
                       : gjoseqlib::aa_subseq(  \$data->[2], $loc->[1], $loc->[2] )
}


sub write_raw
{
    local $_ = $_[0];
    return unless ( $_ && ref $_ eq 'ARRAY' && @$_ > 1 );
    my ( $key, @vals ) = @$_;
    foreach my $val ( @vals )
    {
        if ( $val && ref $val eq 'ARRAY' ) { write_raw( $val ) }
        else { print "$key\t$val\n" }
    }
}
