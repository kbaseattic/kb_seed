# -*- perl -*-

package GenBankToGTO;

#
# This is a SAS component.
#

########################################################################
# Copyright (c) 2003-2015 University of Chicago and Fellowship
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
########################################################################

=head1 NAME

GenBankToGTO::new - Build a new GTO from GenBank format data.

=head1 SYNOPSIS

  $gto = GenBankToGTO::new( \%options )

=head1 DESCRIPTION

Working on it.

=cut


use strict;
use warnings;
use GenomeTypeObject;
use gjogenbank;
use NCBI_sequence;
use Time::HiRes 'gettimeofday';
use Data::Dumper;

#===============================================================================
#  Build a GenomeTypeObject from GenBank data.
#
#     $gto = GenBankToGTO::new()     #  Build from text from STDIN 
#     $gto = GenBankToGTO::new( \%opt )
#
#  Data source options:
#
#    Accession and/or gi numbers:
#
#       accession   =>  $acc           #  Build from accession or gi number
#       accession   => \@acc           #  Build from accession and/or gi numbers
#
#    Already parsed genbank entries:
#
#       entry       =>  $parsed        #  Build from parsed entry
#       entry       => \@parsed        #  Build from parsed entries
#
#    GenBank format entries:
#
#       file        => ...             #  Same as flatfile
#
#       flatfile    =>  $file          #  Build from text in file
#       flatfile    => \@files         #  Build from text in files
#       flatfile    => \$string        #  Build from text in string reference
#       flatfile    => \@stringR       #  Build from text in string references
#       flatfile    => \*FH            #  Build from text in open file
#
#  Other options:
#
#       annotator   =>  $annotator     #  Associated with features
#                                      #      (D = 'GenBank_file_import')
#       EC_alias    =>  $bool          #  Add EC numbers as alias pairs (D = 1)
#       EC_func     =>  $bool          #  Add EC numbers to function (D = 1)
#       event       => \%anal_event    #  Analysis event for features; if id
#                                      #      id defined, it will be overwritten
#       GO_alias    =>  $bool          #  Add GO terms as alias pairs (D = 1)
#       id          =>  $gto_id        #  The id to be applied to the genome (D = 0.0)
#       time        =>  $float         #  Used for date stamps
#
#  This routine goes more deeply into the GTO structure than might be
#  desirable, but it is necessary if we are going to get as much data
#  transferred as possible.
#===============================================================================

sub new
{
    my ( $opts ) = @_;
    $opts ||= {};
    $opts->{ annotator } ||= 'GenBank_file_import';
    
    my @entries;

    if ( $opts->{ entry } )
    {
        my $ent = $opts->{ entry };
        @entries = ref( $ent ) eq 'ARRAY' ? @$ent
                 : ! ref( $ent )          ?  $ent
                 :                           ();
        @entries = grep { ref($_) eq 'HASH' } @entries;
        @entries or die "gto_from_genbank: No GenBank entries supplied with entry option.";
    }

    elsif ( $opts->{ accession } )
    {
        my $acc = $opts->{ accession };
        my @acc = ref( $acc ) eq 'ARRAY' ? @$acc : $acc;
        @acc or die "gto_from_genbank: No accession or gi numbers supplied with accession option.";
        my $genbank = NCBI_sequence::genbank( \@acc );
        $genbank or die "gto_from_genbank: No valid accession or gi numbers supplied with accession option.";
        @entries = gjogenbank::parse_genbank( \$genbank );
        @entries or die "gto_from_genbank: No valid accession or gi numbers supplied with accession option.";
    }

    else
    {
        my $file  = $opts->{ flatfile } || $opts->{ file } || \*STDIN;
        my @files = ref( $file ) eq 'ARRAY' ? @$file : $file;
        foreach ( @files )
        {
            push @entries, gjogenbank::parse_genbank( $_ );
        }
        @entries or die "gto_from_genbank: No valid files supplied with flatfile option.";
    }

    my $gto = GenomeTypeObject->new();

    $gto->{ id } = $opts->{ id } if defined $opts->{ id };

    #  We will keep things indexed to check for duplicate ids:

    $gto->update_indexes();

    #  Associate an analysis event with the imported features.  If an event
    #  definition is supplied by the user, its id will be overwritten by
    #  the call to add_analysis_event().

    my $time = $opts->{ time } ||= gettimeofday();

    my $event = $opts->{ event }
             || { tool_name      => "GenBankToGTO::new",
                  execution_time => $time,
                  parameters     => [],
                  hostname       => $gto->hostname
                };
    $opts->{ event } = $gto->add_analysis_event( $event );

    #
    # Determine which of VERSION, LOCUS, ACCESSION is unique for the purpose of naming
    # contigs.
    #

    my %namekey;
    for my $what (qw(VERSION LOCUS ACCESSION))
    {
	for my $entry (@entries)
	{
	    if (ref($entry->{$what}) && @{$entry->{$what}})
	    {
		$namekey{$what}->{$entry->{$what}->[0]}++;
	    }
	    elsif ($entry->{$what})
	    {
		$namekey{$what}->{$entry->{$what}}++;
	    }		
	}
    }
    print STDERR Dumper(\%namekey);
    my $contig_key;
    for my $what (qw(VERSION LOCUS ACCESSION))
    {
	if (keys %{$namekey{$what}} == @entries)
	{
	    $contig_key = $what;
	    last;
	}
    }

    if (!$contig_key)
    {
	die "Could not find a unique contig identifier";
    }


    #  Fill the GenomeTO one contig at a time:

    foreach my $entry ( @entries )
    {
        #  Add the GenBank entry contig and associated features.

        my $contig = add_contig( $gto, $entry, $contig_key, $opts );
    }

    $gto;
}


#===============================================================================
#  Add one contig to the GenomeTO
#
#    $contig = add_contig( $gto, $gb_entry, $contig_key, $opts );
#
#       $gto       is the GenomeTO being assembled.
#       $gb_entry  is the parsed GenBank entry.
# 	$contig_key is the entry field to use as the identifier for the contig
#       $opts      is not currently used, but it is passed just in case.
#
#       $contig    is the contig created and added to the GenomeTO
#
#===============================================================================
sub add_contig
{
    my ( $gto, $entry, $contig_key, $opts ) = @_;
    $opts ||= {};

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #  Preserve the GenBank data more or less directly:
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #
    #   typedef structure {
    #       list<string>   accession;
    #       list<string>   comment;
    #       string         date;
    #       list<string>   dblink;
    #       list<string>   dbsource;
    #       string         definition;
    #       string         division;
    #       string         geometry;
    #       int            gi;
    #       list<string>   keywords;
    #       string         locus;
    #       string         organism;
    #       string         origin;
    #       list<mapping<string, string>>  references;
    #       string         source;
    #       list<string>   taxonomy;
    #       list<string>   version;
    #   } genbank_locus;
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    my $locus = {};
    $locus->{ locus }      = $entry->{ LOCUS }      if $entry->{ LOCUS };
    $locus->{ division }   = $entry->{ division }   if $entry->{ division };
    $locus->{ date }       = $entry->{ date }       if $entry->{ date };
    $locus->{ definition } = $entry->{ DEFINITION } if $entry->{ DEFINITION };
    $locus->{ accession }  = $entry->{ ACCESSION }  if $entry->{ ACCESSION };
    $locus->{ version }    = $entry->{ VERSION }    if $entry->{ VERSION };
    $locus->{ dblink }     = $entry->{ DBLINK }     if $entry->{ DBLINK };
    $locus->{ dbsource }   = $entry->{ DBSOURCE }   if $entry->{ DBSOURCE };
    $locus->{ geometry }   = $entry->{ geometry }   if $entry->{ geometry };
    $locus->{ gi }         = $entry->{ gi }         if $entry->{ gi };
    $locus->{ keywords }   = $entry->{ KEYWORDS }   if $entry->{ KEYWORDS };
    $locus->{ source }     = $entry->{ SOURCE }     if $entry->{ SOURCE };
    $locus->{ organism }   = $entry->{ ORGANISM }   if $entry->{ ORGANISM };
    $locus->{ taxonomy }   = $entry->{ TAXONOMY }   if $entry->{ TAXONOMY };
    $locus->{ references } = $entry->{ REFERENCES } if $entry->{ REFERENCES };
    $locus->{ comment }    = $entry->{ COMMENT }    if $entry->{ COMMENT };
    $locus->{ origin }     = $entry->{ ORIGIN }     if $entry->{ ORIGIN };

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #  Create and populate the contig structure:
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #   typedef structure {
    #       contig_id      id;
    #       string         dna;
    #       int            genetic_code;
    #       string         cell_compartment;
    #       string         replicon_type;
    #       string         replicon_geometry;  /* circular / linear */
    #       bool           complete;
    #       genbank_locus  genbank_locus;
    #   } contig;
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    my $contig = {};

    $contig->{ genbank_locus } = $locus;
    
    $contig->{ id } = $entry->{$contig_key};
    if (ref($contig->{ id }))
    {
	$contig->{ id } = $contig->{ id }->[0];
    }
    
#    $CONTIG->{ id } = $locus->{ version }   && @{$locus->{ version }}   ? $locus->{ version }->[0]
#                    : $locus->{ accession } && @{$locus->{ accession }} ? $locus->{ accession }->[0]
#                    : $locus->{ locus }                                 ? $locus->{ locus }->[0]
#                    : die( "GenBank data without VERSION, ACCESSION or LOCUS" );

	$contig->{ replicon_geometry } = $entry->{ geometry } if $entry->{ geometry };

    my @sources = gjogenbank::features_of_type( $entry, 'source' );

    #  Try to get the cell compartment from the source features:
    my ( $comp ) = map { $_->[1]->{organelle} ? @{$_->[1]->{organelle}} : () }
                   @sources;
    $contig->{ cell_compartment } = $comp if $comp;

    #  Try to identify plasmids from the source features.  This is dicy due to
    #  submitters specifying their cloning vectors.
    my ( $plasmid ) = map { $_->[1]->{plasmid} ? @{$_->[1]->{plasmid}} : () }
                      @sources;
    $contig->{ replicon_type } = 'plasmid' if $plasmid;

    #  Try to get the genetic code from the CDS features.
    my @codes = map { $_->[1]->{transl_table} ? @{$_->[1]->{transl_table}} : () }
                gjogenbank::features_of_type( $entry, 'CDS' );
    my %cnt;
    foreach ( @codes ) { $cnt{$_}++ }
    my ( $code ) = sort { $cnt{$b} <=> $cnt{$a} } keys %cnt;
    $contig->{ genetic_code } = $code if $code;

    #  There is a problem with entries that use the new CONTIG keyword.
	$contig->{ dna } = $entry->{ SEQUENCE } if $entry->{ SEQUENCE };

    #  Completeness is dicy:
    $contig->{ complete } = 1  if is_complete( $entry );

    #  This call will push on the contig and update the index.
    $gto->add_contigs( [ $contig ] );

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #  Try to fill in missing parts of the genome data:
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #
    #   typedef structure {
    #   	genome_id      id;
    #   	string         scientific_name;
    #   	string         domain;
    #   	int            genetic_code;
    #   	string         source;
    #   	string         source_id;
    #   	string         taxonomy;
    #   	int            ncbi_taxonomy_id;
    #   	string         owner;
    #   	genome_quality_measure  quality;
    #   	list<contig>   contigs;
    #   	Handle         contigs_handle;
    #   	list<feature>  features;
    #   	list<close_genome>    close_genomes;
    #   	list<analysis_event>  analysis_events;
    #   } genomeTO;
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $gto->{ scientific_name } ||= $locus->{ organism };

    if ( $locus->{ taxonomy } )
    {
        shift @{ $locus->{ taxonomy } } if $locus->{ taxonomy }->[0] eq 'root';
        shift @{ $locus->{ taxonomy } } if $locus->{ taxonomy }->[0] eq 'cellular organisms';
        my $dom = $locus->{ taxonomy }->[0];
        $gto->{ domain } ||= $dom =~ /^Arch/i      ? 'Archaea'
                           : $dom =~ /^Bact/i      ? 'Bacteria'
                           : $dom =~ /^Eu[ck]a/i   ? 'Eukaryota'
                           : $dom =~ /^Vir/i       ? 'Virus'
                           : $dom =~ /^Environ/i   ? 'Environmental Sample'
                           : $dom =~ /^Un\S* Env/i ? 'Environmental Sample'
                           :                         'Unknown';
        $gto->{ taxonomy } ||= join( '; ', @{ $locus->{ taxonomy } } );
    }

    $gto->{ genetic_code } ||= $code if $code;

    if ( ! $gto->{ ncbi_taxonomy_id } )
    {
        my ( $taxid ) = map { /^taxon:(\S+)$/ ? $1 : () }
                        map { $_->[1]->{db_xref} ? @{$_->[1]->{db_xref}} : () }
                        @sources;
        $gto->{ ncbi_taxonomy_id } = $taxid  if $taxid;
    }

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    #  Okay, we have a contig, add the features:
    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    add_features( $gto, $entry, $contig->{id}, $opts );
}


sub is_complete
{
    my ( $entry ) = @_;

    return 1 if $entry->{ DEFINITION } =~ /complete (?:genome|sequence)/i;
    return 1 if $entry->{ DEFINITION } =~ /complete\.?$/i;
    return 1 if scalar( grep { /complete genome/i }           list( $entry->{ KEYWORDS } ) );
    return 1 if scalar( grep { /COMPLETENESS: full length/i } list( $entry->{ COMNENT } ) );

    return 0;
}


#===============================================================================
#  Add the features for one contig to the GenomeTO
#
#    $contig = add_features( $gto, $gb_entry, $contig_id, $opts );
#
#       $gto        is the GenomeTO being assembled.
#       $gb_entry   is the parsed GenBank entry.
#       $contig_id  ensures that the locations definitions to match the contig.
#       $opts       options and date passed through.
#
#===============================================================================
#    /*  Preserve the original feature data:
#     *
#     *     GenBank feature:  [ type, location, qualifiers ]
#     */
#   typedef tuple<string  genbank_type,
#                 string  genbank_location,
#                 mapping<string qualifier, list<string> values>  qualifiers
#                >
#           genbank_feature;
#
#
#   typedef structure {
#       bool           truncated_begin;
#       bool           truncated_end;
#       float          existence_confidence;   /* P-value this a real feature */
#       bool           frameshifted;
#       bool           selenoprotein;
#       bool           pyrrolysylprotein;
#       list<string>   overlap_rules;
#       float          existence_priority;
#       float          hit_count;
#       float          weighted_hit_count;
#       float          genemark_score;
#   } feature_quality_measure;
#
#
#   typedef structure {
#   	feature_id                       id;
#   	location                         location;
#   	feature_type                     type;
#   	string                           function;
#   	string                           function_id;
#   	string                           protein_translation;
#   	list<string>                     aliases;
#   	list<tuple<string source, string alias>>  alias_pairs;
#   	list<annotation>                 annotations;
#   	feature_quality_measure          quality;
#   	analysis_event_id                feature_creation_event;
#   	list<protein_family_assignment>  family_assignments;
#   	list<similarity_association>     similarity_associations;
#   	list<proposed_function>          proposed_functions;
#   	string                           genbank_type;
#   	genbank_feature                  genbank_feature;
#   } feature;
#
#===============================================================================
#  If there are GenBank feature types that we want to omit, put them here:

my %omit_type = map { lc($_) => 1 }
                qw( centromere
                    D_segment
                    gene
                    iDNA
                    J_segment
                    misc_difference
                    N_region
                    old_sequence
                    source
                    V_region
                    V_segment
                    variation
                    3'UTR
                    5'UTR
                  );

sub add_features
{
    my ( $gto, $entry, $cid, $opts ) = @_;
    $opts ||= {};

    #  Feature ids are based on the genome id.  If we do not yet have a
    #  genome id, we need to make one up.  In the style of the SEED, we
    #  will build from the NCBI taxon id, if available.

    $gto->{ id } ||= default( $gto->{ ncbi_taxonomy_id }, '0' ) . '.0';

    #  Get the list of GenBank features, adding the type to each:

    my @gb_ftrs = map { my $type = $_;
                        map { [ $type, @$_ ] } gjogenbank::features_of_type( $entry, $type )
                      }
                  grep { ! $omit_type{ $_ } }
                  gjogenbank::feature_types( $entry );

    foreach my $gb_ftr ( @gb_ftrs )
    {
        my $ftr = create_feature( $gto, $gb_ftr, $cid, $opts )
            or next;
        push @{ $gto->{ features } }, $ftr   if $ftr;

        my $id = $ftr->{ id };
        $gto->{_feature_index}->{$id} = $ftr  if $gto->{_feature_index};
    }

    $gto;
}


sub create_feature
{
    my ( $gto, $gb_ftr, $cid, $opts ) = @_;
    $opts ||= {};

    #  Testing for a defined type allows us arbitrary precision in filtering
    #  for the features that we want to keep.

    my $type = feature_type( $gb_ftr )
        or return undef;

    my $gb_type = $gb_ftr->[0];
    my $gb_qual = $gb_ftr->[2];

    #  If called within the overall context of this package, these are all
    #  defined:

    my $annotator = $opts->{ annotator } || 'GenBank_import';
    my $event     = $opts->{ event };
    my $time      = $opts->{ time }      ||= gettimeofday();

    my $ftr = {};

    $ftr->{ genbank_feature }     = $gb_ftr;
    $ftr->{ genbank_type }        = $gb_type;

    $ftr->{ type }                = $type;

    $ftr->{ id }                  = $gto->new_feature_id( $ftr->{ type } );

    add_location( $ftr, $cid, $gb_ftr );

    $ftr->{ function }            = feature_function( $gb_ftr );

    my ( $aliases, $pairs )       = feature_aliases( $gb_ftr, $opts );

    $ftr->{ aliases }             = $aliases                       if $aliases && @$aliases;

    $ftr->{ alias_pairs }         = $pairs                         if $pairs   && @$pairs;

    $ftr->{ analysis_event_id }   = $event                         if $event;

    $ftr->{ protein_translation } = $gb_qual->{ translation }->[0] if $gb_qual->{ translation };

    #  Annotations are just a list of 4-tuples:

    @{ $ftr->{ annotations } }    = map { [ $_, $annotator, $time, $event ] }
                                    feature_annotations( $ftr, $gb_ftr, $opts );

    #  Note that add_location() might, or might not, have initialized quality.

    update_feature_quality( $ftr, $gb_ftr, $opts );

    $ftr;
}


#
#  Feature type mapping:
#
#       CDS -> peg
#     .*RNA -> rna
#
sub feature_type
{
    my ( $gb_ftr ) = @_;
    local $_ = $gb_ftr->[0];  # type
    my $qual = $gb_ftr->[2];

    my $type;
    if    ( /^CDS$/i )                        { $type = 'peg' }
    elsif ( /RNA$/i )                         { $type = 'rna' }
    elsif ( $_ eq 'prim_transcript' )         { $type = 'rna' }
    elsif ( $_ eq 'misc_feature' )
    {
        if ( $qual->{ note } && $qual->{ note } =~ /prophage/i ) { $type = 'pp' }
        else                                  { $type = $_ }
    }
    else                                      { $type = $_ }

    $type;
}


sub add_location
{
    my ( $ftr, $cid, $gb_ftr ) = @_;
    my $gb_loc = $gb_ftr->[1];

    my ( $loc, $partial_5, $partial_3 ) = gjogenbank::genbank_loc_2_cbdl( $gb_loc, $cid );
    $ftr->{ location } = $loc;
    if ( $partial_5 || $partial_3 )
    {
        my $qual = $ftr->{ quality } ||= {};
        $qual->{ truncated_begin } = 1 if $partial_5;
        $qual->{ truncated_end }   = 1 if $partial_3;
    }
}


#
#  Clean interfaces to simple functions:
#
#      Expand a (possibly undefined) list reference.
#      Return a defined value, or a default.
#

sub list    { @{$_[0] || [] } }
sub default { defined $_[0] ? $_[0] : $_[1] }


sub feature_function
{
    my ( $gb_ftr, $opts ) = @_;
    $opts ||= {};
    my $add_EC = default( $opts->{ EC_func }, 1 );

    my $gb_type = $gb_ftr->[0];
    local $_    = $gb_ftr->[2];

    my $func = $_->{ product }  ? $_->{ product }->[0]
             : $_->{ function } ? $_->{ function }->[0]
             : $_->{ note }     ? $_->{ note }->[0]
             :                    "undefind $gb_type";

    my @EC;
    if ( $gb_type eq 'CDS' && $add_EC && ( @EC = list( $_->{EC_number} ) ) )
    {
        $func .= ' (EC ' . join( ')(EC ', @EC) . ')';
    }

    $func;
}


sub feature_aliases
{
    my ( $gb_ftr, $opts ) = @_;
    return () unless $gb_ftr && ref $gb_ftr eq 'ARRAY' && $gb_ftr->[2];
    $opts ||= {};

    my $EC = default( $opts->{ EC_alias }, 1 );
    my $GO = default( $opts->{ GO_alias }, 1 );

    my @aliases;
    my @alias_pairs;
    my $qual = $gb_ftr->[2];

    push @aliases,                               list( $qual->{ protein_id } );

    push @alias_pairs, map { [protein_id => $_] } list( $qual->{ protein_id } );

    push @alias_pairs, map { [locus_tag => $_] } list( $qual->{ locus_tag } );

    push @alias_pairs, map { [locus_tag => $_] } list( $qual->{ old_locus_tag } );

    push @alias_pairs, map { [gene      => $_] } list( $qual->{ gene } );

    push @alias_pairs, map { [gene      => $_] } map { split /; */ }
                                                 list( $qual->{ gene_synonym } );

    push @alias_pairs, map { /([^:]+):(.+)/ ? [$1 => $2] : () }
                                                 list( $qual->{ db_xref } );

    push @alias_pairs, map { [EC        => $_] } list( $qual->{ EC_number } )     if $EC;

    push @alias_pairs, map { [GO        => $_] } map  { /^GO:(\d+)\b/ ? $1 : () }
                                                 map  { split /; +/ }
                                                 map  { @{ $qual->{$_} } }
                                                 grep { /^GO_/ } keys %$qual      if $GO;

    #  Nice try, but they are just N-terminus verifications.
    push @alias_pairs, map { [PMID      => $_] } map  { split /, */ }
                                                 map  { / PMID +(\d+(?:,[\d+, ]*\d)?)$/ }
                                                 list( $qual->{ experiment } )    if 0;

    ( \@aliases, \@alias_pairs );
}


sub feature_annotations
{
    my ( $ftr, $gb_ftr, $opts ) = @_;
    $opts ||= {};

    my @anno;
    my $func = $ftr->{ function };
    my $qual = $gb_ftr->[2];

    push @anno, map { "Imported function:\n$_" } grep { $_ && $_ ne $func }
                                                 list( $qual->{ function } );

    push @anno, map { "Imported note:\n$_" }     grep { $_ && $_ ne $func }
                                                 list( $qual->{ note } );

    push @anno, "Set function to $func";

    wantarray ? @anno : \@anno;
}


sub update_feature_quality
{
    my ( $ftr, $gb_ftr, $opts ) = @_;
    $opts ||= {};

    my $quality = $ftr->{ quality } || {};
    my $qualif  = $gb_ftr->[2];

    $quality->{ selenoprotein }     = 1  if   scalar grep { /aa:Sec/i }    list( $qualif->{ transl_except } );
    $quality->{ pyrrolysylprotein } = 1  if   scalar grep { /aa:Pyl/i }    list( $qualif->{ transl_except } );
    $quality->{ pyrrolysylprotein } = 1  if ( scalar grep { /aa:OTHER/i }  list( $qualif->{ transl_except } ) )
                                            &&
                                            ( scalar grep { /\bPyl\b/i || /pyrrolysine/i } list( $qualif->{ note } ) );

    #  Further considerations:
    #
    #   bool   frameshifted;
    #   float  existence_priority;
    #
    #  We do not have a pseudo flag in the spec.  All of our frameshift,
    #  truncated, partial, ... comments would fit this flag.
    #
    # $quality->{ pseudo } = 1  if list( $qualif->{ pseudo } );
    # $quality->{ pseudo } = 1  if list( $qualif->{ pseudogene } );
    #

    #  If we have quality data, and it is not already in the feature, add it:

    $ftr->{ quality } ||= $quality  if keys %$quality;
}


1;
