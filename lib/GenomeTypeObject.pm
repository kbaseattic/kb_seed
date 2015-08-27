# -*- perl -*-

package GenomeTypeObject;

#
# This is a SAS component.
#

########################################################################
# Copyright (c) 2003-2013 University of Chicago and Fellowship
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

GenomeTypeObject - a helper class for manipulating GenomeAnnotation service genome objects.

=head1 SYNOPSIS

  $obj = GenomeTypeObject->new()

  $obj = GenomeTypeObject->initialize($raw_genome_object)

=head1 DESCRIPTION

The C<GenomeTypeObject> class wraps a number of common operations to be performed
against the genome object as defined in the KBase GenomeAnnotation service.

To use the methods here it is sufficient to just bless the JSON object containing
the genome data into the GenomeTypeObject class, but it is more efficient to initialize
it using the initialize method:

  $obj = GenomeTypeObject->initialize($raw_json)

Doing this will create internal indexes on the feature and contig data structures
to accelerate access to individual data items.

Before using the genome object as a raw JSON object again, however, you must invoke
the C<prepare_for_return()> method which strips these indexes out of the data object.

=cut


use strict;
use warnings;
use SeedUtils;
require SeedAware;
use File::Temp;
use File::Slurp;
use JSON::XS;
use gjoseqlib;
use Time::HiRes 'gettimeofday';
use IDclient;
use BasicLocation;
use IO::Handle;
use Data::Dumper;

our $have_unbless;
eval {
    require Data::Structure::Util;
    Data::Structure::Util->import('unbless');
    $have_unbless = 1;
};
use base 'Class::Accessor';

our $have_UUID;
our $have_Data_UUID;
eval {
    require UUID;
    $have_UUID = 1;
};
eval {
    require Data::UUID;
    $have_Data_UUID = 1;
};

__PACKAGE__->mk_accessors(qw(id_client));

=head2 $obj = GenomeTypeObject->new()

Create a new empty genome object.

=cut

#
#     my $gto = GenomeTypeObject->new()          #  An empty GenomeTypeObject
#     my $gto = GenomeTypeObject->new( \%opt )   #  An object filled from
#                                                #     specified source
#
#   Options:
#
#       file  =>  $filename           #  Build from JSON text in file
#       file  => \*FILEHANDLE         #  Build from JSON text in open file
#       file  => \$string             #  Build from JSON text in string ref
#       gid   =>  $SEED_genome_ID     #  Build from a SEED genome; one or more
#                                     #    SEEDs can be specified by seed option
#                                     #    (D = [core, pseed, pubseed])
#       json  =>  $JSON_text_string   #  Build from a JSON text string
#       json  => \@JSON_text_lines    #  Build from JSON text lines
#       seed  =>  $SEED_name          #  SEED to use for genome ID
#       seed  =>  $SEED_URL           #  SEED to use for genome ID
#       seed  => \@SEED_names_URLs    #  Search multiple SEEDs, in order
#       stdin =>  $bool               #  Build from JSON text on STDIN
#                                     #     (same as file => \*STDIN)
#
sub new
{
    my( $class, $opts ) = @_;
    $opts ||= {};

    my $self;
    if ( $opts->{ file } )
    {
        $self = $class->create_from_file( $opts->{ file } );
    }
    elsif ( $opts->{ stdin } )
    {
        $self = $class->create_from_file( \*STDIN );
    }
    elsif ( $opts->{ json } )
    {
        $self = $class->create_from_json( $opts->{ json } );
    }
    elsif ( $opts->{ gid } )
    {
        my $seed = $opts->{ seed };
        my @seeds = ! $seed               ? ()         # None specified
                  : ref($seed) eq 'ARRAY' ? @$seed     # List specified
                  :                         ( $seed ); # One specified

        $self = $class->fetch_from_seed( $opts->{ gid }, @seeds );
    }
    else
    {
        my $raw = { contigs         => [],
                    features        => [],
                    close_genomes   => [],
                    analysis_events => []
                  };
        $self = $class->initialize_without_indexes( $raw );
    }

    return $self;
}


=head2 $obj = GenomeTypeObject->create_from_file($filename)

Load the given file, assumed to contain the JSON form of a genome object, and
return as a GenomeTypeObject instance.

The resulting object has not had the C<initialize> method invoked on it.

=cut

#
#    $gto = GenomeTypeObject->create_from_file(  $filename )
#    $gto = GenomeTypeObject->create_from_file( \*filehandle )
#    $gto = GenomeTypeObject->create_from_file( \$string )
#    $gto = GenomeTypeObject->create_from_file( )                # D = STDIN
#
sub create_from_file
{
    my($class, $file) = @_;

    $class
        or print STDERR "create_from_file() called without class.\n"
            and return undef;

    #  Read the data:

    my $raw = SeedUtils::read_encoded_object( $file );

    #  Return the blessed and initialized object:

    $raw ? $class->initialize( $raw ) : undef;
}


=head2 $obj->destroy_to_file($filename)

Write the given object in JSON form to the specified file.
The object will be rendered unusable (i.e., unblessed)

=cut

#
#    GenomeTypeObject->destroy_to_file(  $filename   [, \%options] )
#    GenomeTypeObject->destroy_to_file( \*filehandle [, \%options] )
#    GenomeTypeObject->destroy_to_file( \$string     [, \%options] )
#    GenomeTypeObject->destroy_to_file(              [  \%options] ) # D = STDOUT
#
#   Options:
#
#        condensed => $bool   #  If true, do not invoke 'pretty'
#        pretty    => $bool   #  If explicitly false, do not invoke 'pretty'
#
sub destroy_to_file
{
    my $opts = ( @_ > 1 && ref( $_[-1]) eq 'HASH' ) ? pop( @_ ) : {};

    my ( $self, $fileName ) = @_;

    #  Remove our local files (e.g., indices) and unbless the object.
    #  When unbless exists, this works without the assignment, but without
    #  unbless, a reference to a new (never blessed) hash is returned.

    my $raw = $self->prepare_for_return;

    #  Write it

    SeedUtils::write_encoded_object( $raw, $fileName, $opts );
}


#
#    $gto = GenomeTypeObject->create_from_json(  $textstr )
#    $gto = GenomeTypeObject->create_from_json( \@textlines )
#
sub create_from_json
{
    my( $class, $text ) = @_;

    $class
        or print STDERR "create_from_json() called without class.\n"
            and return undef;

    #  Process the text:

    $text = join( ' ', @$text ) if $text && ref($text) eq 'ARRAY';
    $text && $text =~ /\S/
        or print STDERR "create_from_json() called without text data.\n"
            and return undef;


    #  Create the perl structure:

    my $raw = JSON::XS->new->utf8(0)->decode( $text );

    #  Return the blessed and initialized object:

    $raw ? $class->initialize( $raw ) : undef;
}


sub fetch_from_seed
{
    my ( $class, $gid, @seeds ) = @_;

    eval { require LWP::Simple; }
        or print STDERR "fetch_from_seed failed in 'require LWP::Simple'.\n"
            and return undef;

    my @where;

    # Map SEED name(s) to URL(s):

    #  This handles user-supplied SEED names and URLs
    if ( @seeds && ( eval { require SeedURLs; } ) )
    {
        @where = map { SeedURLs::url( $_ ) } @seeds;
    }

    #  This handles just URLs
    elsif ( @seeds )
    {
        my $error = 0;
        foreach ( @seeds )
        {
            if ( m/^http/i )
            {
                push @where, $_;
            }
            else
            {
                print STDERR "fetch_from_seed(): Invalid SEED '$_'.\n";
                print STDERR "Unable to process SEED names without SeedURLs.pm, use URLs instead.\n" unless $error++;
            }
        }
    }

    #  Default SEEDs to search
    elsif ( eval { require SeedURLs; } )
    {
        @where = map { SeedURLs::url( $_ ) }
                 qw( core pseed pubseed );
    }
    else
    {
        @where = qw( http://core.theseed.org/FIG
                     http://pseed.theseed.org
                     http://pubseed.theseed.org
                   );
    }

    my $raw;

    #  Work through SEEDs to find the genome
    foreach my $where ( @where )
    {
        # Get the JSON text:

        my $text = LWP::Simple::get( "$where/genome_object.cgi?genome=$gid" )
            or next;

        #  Create the perl structure:

        $raw = JSON::XS->new->utf8(0)->decode( $text );

        last if $raw;
    }

    $raw ? $class->initialize( $raw ) : undef;
}


=head2 $obj->set_metadata({ ... });

Set the metadata fields on this genome object based on a metadata
object as defined in the GenomeAnnotation typespec:

 typedef structure
 {
  genome_id id;
  string scientific_name;
  string domain;
  int genetic_code;
  string source;
  string source_id;
  int ncbi_taxonomy_id;
  string taxonomy;
  string owner;
 } genome_metadata

=cut

sub set_metadata
{
    my($self, $meta) = @_;

    my @keys = qw(id scientific_name domain genetic_code source source_id taxonomy ncbi_taxonomy_id owner);
    for my $k (@keys)
    {
        if (exists($meta->{$k}))
        {
            $self->{$k} = $meta->{$k};
        }
    }
    return $self;
}

sub initialize
{
    my($class, $self) = @_;

    $self = $class->initialize_without_indexes($self);
    $self->update_indexes();

    return $self;
}

sub initialize_without_indexes
{
    my($class, $self) = @_;

    bless $self, $class;

    $self->setup_id_allocation();

    return $self;
}


sub setup_id_allocation
{
    my($self) = @_;
    $self->{_id_client} ||= IDclient->new($self);
    return $self;
}


sub prepare_for_return
{
    my($self) = @_;

    delete $self->{$_} foreach  grep { /^_/ } keys %$self;

    #
    # There are still some invocations of &GenomeTypeObject::prepare_for_return(obj)
    #
    if (ref($self) && ref($self) ne 'HASH')
    {
        if ($have_unbless)
        {
            unbless $self;
            return $self;
        }
        else
        {
            return { %$self };
        }
    }
    else
    {
        return $self;
    }
}


sub hostname
{
    my($self) = @_;

    return $self->{hostname} if $self->{hostname};
    $self->{hostname} = SeedAware::run_gathering_output( 'hostname' );
    chomp $self->{hostname};
    return $self->{hostname};
}


sub update_indexes
{
    my($self) = @_;

    #
    # Create feature index.
    #
    $self->update_feature_index();

    #
    # Create contig index.
    #
    $self->update_contig_index();

    #
    # Event index.
    #
    $self->update_event_index();

    return $self;
}


sub update_feature_index
{
    my($self) = @_;

    my $feature_index = $self->{_feature_index} = {};
    for my $feature ($self->features)
    {
        $feature_index->{$feature->{id}} = $feature;
    }

    if ( keys %$feature_index != @{$self->features} )
    {
        my $nftr = $self->features;
        my $nind = keys %$feature_index;
        die "Number of features ($nftr) not equal to index size ($nind). Duplicate ids?";
    }

    return $feature_index;
}


sub update_contig_index
{
    my($self) = @_;

    my $contig_index = $self->{_contig_index} = {};
    for my $contig ($self->contigs)
    {
        $contig_index->{$contig->{id}} = $contig;
    }

    if ( keys %$contig_index != @{$self->contigs} )
    {
        my $ncnt = $self->contigs;
        my $nind = keys %$contig_index;
        die "Number of contigs ($ncnt) not equal to index size ($nind). Duplicate ids?";
    }

    return $contig_index;
}


sub update_event_index
{
    my($self) = @_;

    my $event_index = $self->{_event_index} = {};
    for my $e ( @{$self->{analysis_events}} )
    {
        $event_index->{$e->{id}} = $e;
    }

    if ( keys %$event_index != @{ $self->{analysis_events} } )
    {
        my $nevt = @{$self->{analysis_events}};
        my $nind = keys %$event_index;
        die "Number of analysis events ($nevt) not equal to index size ($nind). Duplicate ids?";
    }

    return $event_index;
}


#
#      @features = $genomeTO->features
#     \@features = $genomeTO->features   # ref is to original list
#
sub features
{
    my($self) = @_;
    wantarray ? @{$self->{features}} : $self->{features};
}


#
#  Return the number of features
#
sub n_features
{
    my $genomeTO = shift;
    scalar @{ $genomeTO->{features} || [] };
}


#
#  Get the ids of features of specified type(s)
#
#     @fids = $genomeTO->fids_of_type( @types );
#    \@fids = $genomeTO->fids_of_type( @types );
#
sub fids_of_type
{
    my $genomeTO = shift;
    my @fids;
    if ( @_ )
    {
        my %keep = map { $_ => 1 } @_;
        @fids = map { $keep{ $_->{type} } ? $_->{id} : () }
                $genomeTO->features;
    }

    wantarray ? @fids : \@fids;
}


#
#  Get lists of feature ids, keyed by feature type
#
#    \%fids_by_type = $genomeTO->fids_by_type();
#
sub fids_by_type
{
    my ( $genomeTO ) = @_;

    my %by_type;
    foreach ( $genomeTO->features )
    {
        push @{ $by_type{$_->{type}} }, $_->{id};
    }

    \%by_type;
}


#
#      @contigs = $genomeTO->contigs
#     \@contigs = $genomeTO->contigs   # ref is to original list
#
sub contigs
{
    my($self) = @_;
    wantarray ? @{$self->{contigs}} : $self->{contigs};
}


#
#  Return the number of contigs
#
sub n_contigs
{
    my $genomeTO = shift;
    scalar @{ $genomeTO->{contigs} || [] };
}


#
#      @analysis_events = $genomeTO->analysis_events
#     \@analysis_events = $genomeTO->analysis_events   # ref is to original list
#
sub analysis_events
{
    my($self) = @_;
    wantarray ? @{$self->{analysis_events}} : $self->{analysis_events};
}


#
#  Return the number of analysis events
#
sub n_analysis_events
{
    my $genomeTO = shift;
    scalar @{ $genomeTO->{analysis_events} || [] };
}


=head2 $obj->add_contigs($contigs)

Add the given set of contigs to this genome object. C<$contigs> is a list of contig
objects, which we add to the genome object without further inspection.

=cut

sub add_contigs
{
    my($self, $contigs) = @_;
    $contigs && ref($contigs) eq 'ARRAY'
        or return 0;

    my $index = $self->{_contig_index} || $self->update_contig_index();

    my $status = 1;
    foreach ( @$contigs )
    {
        my $id = $_->{id};
        if ( $index->{ $id } )
        {
            $status = 0;
            die( qq(Attempt to add duplicate contig id '$id'.) );
        }
        else
        {
            push( @{$self->{contigs}}, $_ );
            $index->{ $id } = $_;
        }
    }

    return $status;
}

=head2 $obj->add_features_from_list($features)

Add the given features to the genome. Features here are instances of the compact_tuple type:

 typedef tuple <string id, string location, string feature_type, string function, string aliases> compact_feature;

used in the importation of features from an external source via a tab-separated text file.

We create an event for this import so that the source of the features so added is tracked.

Returns a hash mapping from the feature ID in the list to the allocated feature ID.

=cut

sub add_features_from_list
{
    my($self, $features, $parms) = @_;

    my %parms = $parms && ref($parms) eq 'HASH' ? %$parms : {};

    my $event = {
        tool_name => "add_features_from_list",
        execution_time => scalar gettimeofday,
        parameters => [],
        hostname => $self->hostname,
    };

    my $event_id = $self->add_analysis_event($event);
    $parms{ -analysis_event_id } = $event_id;

    my $map = {};

    for my $f (@$features)
    {
        my($id, $loc_str, $type, $func, $aliases_str) = @$f;

        my @aliases = grep { /\S/ }
                      split(/,/, $aliases_str || '');
        my @locs = map { my $l = BasicLocation->new($_);
                         [ $l->Contig, $l->Begin, $l->Dir, $l->Length ]
                       }
                   split(/,/, $loc_str);

        $parms{ -type }     =  $type;
        $parms{ -location } = \@locs;
        $parms{ -function } =  $func;
        $parms{ -aliases }  = \@aliases;

        my $new_id = $self->add_feature( \%parms );
        $map->{$id} = $new_id;
    }
    return $map;
}


=head2 $obj->add_feature($params)

Add a new feature. The details of the feature are defined in the parameters hash. It has the following
keys:

=over 4

=item -id

Identifier for this feature. If not provided, a new identifier will be
created based on the genome id, the type of the feature and the current largest identifier for
that feature type.

=back

=cut

sub add_feature {
    my ($self, $parms) = @_;
    my $genomeTO = $self;
    print STDERR (Dumper($parms), qq(\n\n)) if $ENV{DEBUG};

    my $id = $parms->{-id};
    my $id_client   = $parms->{-id_client};
    my $id_prefix   = $parms->{-id_prefix};
    my $type        = $parms->{-type}       or die "No feature-type -type";
    my $id_type	    = $parms->{-id_type};
    my $location    = $parms->{-location}   or die "No feature location -location";
    my $function    = $parms->{-function};
    my $annotator   = $parms->{-annotator}  || q(Unknown);
    my $annotation  = $parms->{-annotation} || q(Add feature);
    my $translation = $parms->{-protein_translation};
    my $event_id    = $parms->{-analysis_event_id};
    my $quality     = $parms->{-quality_measure};
    my $aliases     = $parms->{-aliases};

    if (!defined($id))
    {
        if (!defined($id_prefix))
        {
            $id_prefix = $self->{id};
        }
        if (!defined($id_client))
        {
            $id_client = $self->{_id_client};
        }

        #
        # If our id prefix is a bare \d+\.\d+ genome ID, prefix the
        # id prefix with fig| to create SEED style identifiers.
        #

        if ($id_prefix =~ /^\d+\.\d+$/)
        {
            $id_prefix = "fig|" . $id_prefix;
        }

        my $typed_prefix = "$id_prefix." . (defined($id_type) ? $id_type : $type);
        my $next_num     = $id_client->allocate_id_range($typed_prefix, 1);
        # print STDERR Dumper($typed_prefix, $next_num);

        if (defined($next_num)) {
            print STDERR "Allocated id for typed-prefix \'$typed_prefix\' starting from $next_num\n" if $ENV{DEGUG};
        }
        else {
            die "Could not get a new ID with typed-prefix \"$typed_prefix\"";
        }
        $id = join(".", $typed_prefix, $next_num);
    }

    if (not defined $genomeTO->{features}) {
        $genomeTO->{features} = [];
    }
    my $features  = $genomeTO->{features};

    my $feature =  { id   => $id,
                     type => $type,
                     location => $location,
                     annotations => [[ $annotation,
                                       $annotator,
                                       time(),
                                       ]],
    };

    $feature->{quality} = $quality if $quality;
    $feature->{feature_creation_event} = $event_id if $event_id;
    $feature->{aliases} = $aliases if $aliases;

    $function = SeedUtils::canonical_function( $function ) if defined $function;

    if (defined $function && length $function) {
        $feature->{function} = $function;
        push @ { $feature->{annotations} }, [ "Set function to $function",
                                              $annotator,
                                              time(),
                                              ];
    }

    if ($translation) {
        $feature->{protein_translation} = $translation;
    }

    push @$features, $feature;

    $genomeTO->{_feature_index}->{$id} = $feature  if $genomeTO->{_feature_index};

    return $feature;
}


=head2 $obj->write_protein_translations_to_file($filename)

Write the protein translations to a FASTA file.

=cut

sub write_protein_translations_to_file
{
    my($self, $filename) = @_;

    my $fh;
    open($fh, ">", $filename) or die "Cannot write $filename: $!";

    for my $feature (@{$self->{features}})
    {
        my $trans = $feature->{protein_translation};
        if ($trans)
        {
            write_fasta($fh, [$feature->{id}, undef, $trans]);
        }
    }
    close($fh);
}

=head2 $obj->write_contigs_to_file($filename)

Write the contigs to a FASTA file.

=cut

sub write_contigs_to_file
{
    my ($self, $filename) = @_;

    my $fh;
    open($fh, ">", $filename) or die "Cannot write $filename: $!";

    for my $ctg (@{$self->{contigs}})
    {
        write_fasta($fh, [$ctg->{id}, undef, $ctg->{dna}]);
    }
    close($fh);
}

sub write_feature_locations_to_file
{
    my($self, $filename, @feature_types) = @_;

    my %feature_types = map { $_ => 1 } @feature_types;

    my $fh;
    open($fh, ">", $filename) or die "Cannot write $filename: $!";

    for my $feature (@{$self->{features}})
    {
        next if (@feature_types && ! $feature_types{$feature->{type}});

        my $loc = $feature->{location};
        my $loc_str = join(",", map { my $b = BasicLocation->new(@$_); $b->String() } @$loc);
        print $fh "$feature->{id}\t$loc_str\n";
    }
    close($fh);
}

#
# $filter is an optional parameter that is a code ref.
# It is invoked for each feature; only those features that
# have a translation and for which the filter returns true are written.
#
sub extract_protein_sequences_to_temp_file
{
    my($self, $filter) = @_;

    my($fh, $fn) = tmpnam();

    for my $feature (@{$self->{features}})
    {
        my $trans = $feature->{protein_translation};
        if (ref($filter))
        {
            if ($filter->($feature))
            {
                print STDERR "keeping $feature->{id} $feature->{function}\n";
            }
            else
            {
                print STDERR "skippinging $feature->{id} $feature->{function}\n";
                next;
            }
        }
        if ($trans)
        {
            write_fasta($fh, [$feature->{id}, undef, $trans]);
        }
    }
    close($fh);
    return $fn;
}

sub extract_contig_sequences_to_temp_file
{
    my($self) = @_;

    my($fh, $fn) = tmpnam();

    for my $ctg (@{$self->{contigs}})
    {
        write_fasta($fh, [$ctg->{id}, undef, $ctg->{dna}]);
    }
    close($fh);
    return $fn;
}

sub compute_contigs_gc
{
    my($self) = @_;

    my %gc;
    my $gc = 0;
    my $at = 0;
    for my $ctg (@{$self->{contigs}})
    {
        my $this_gc = ($ctg->{dna} =~ tr/gcGC//);
        my $this_at = ($ctg->{dna} =~ tr/atAT//);
        my $div = $this_gc + $this_at;
        $gc{$ctg->{id}} = 100 * $this_gc / $div if $div;
        $gc += $this_gc;
        $at += $this_at;
    }

    my $div = $gc + $at;
    my $all_gc = 100 * $gc / $div if $div;
    return($all_gc, \%gc);
}

sub write_temp_seed_dir
{
    my($self, $options) = @_;

    my $tmp = File::Temp->newdir(undef, CLEANUP => 1);

    $self->write_seed_dir($tmp, $options);
    return $tmp;
}

sub write_seed_dir
{
    my($self, $dir, $options) = @_;

    open(my $ctg_fh, ">", "$dir/contigs") or die "Cannot create $dir/contigs: $!";
    for my $contig (@{$self->{contigs}})
    {
        write_fasta($ctg_fh, [$contig->{id}, undef, $contig->{dna}]);
    }
    close($ctg_fh);

    #
    # Some individual file metadata.
    #
    my $write_md = sub { my($name, $value) = @_;
                         my $fh;
                         open($fh, ">", "$dir/$name") or die "Cannot open $dir/$name: $!";
                         print $fh "$value\n";
                         close($fh);
                    };
    $write_md->("GENETIC_CODE", $self->{genetic_code});
    $write_md->("GENOME", $self->{scientific_name});
    $write_md->("TAXONOMY", $self->{taxonomy}) if $self->{taxonomy};

    my $features = $self->{features};
    my %types = map { $_->{type} => 1 } @$features;

    my %typemap;
    if ($options->{map_CDS_to_peg})
    {
        delete $types{CDS};
        $types{peg} = 1;
    }
    my @types = keys %types;
    $typemap{$_} = $_ foreach @types;
    $typemap{CDS} = 'peg' if $options->{map_CDS_to_peg};
    print Dumper(\@types, \%typemap);

    #
    # closest.genomes file.
    #

    my $close = $self->{close_genomes};
    if (ref($close) && @$close)
    {
        open(my $close_fh, ">", "$dir/closest.genomes") or die "cannot open $dir/closest.genomes: $!";
        for my $c (@$close)
        {
            print $close_fh join("\t", $c->{genome_id}, $c->{closeness_measure}, $c->{genome_name}), "\n";
        }
        close($close_fh);
    }

    my $fn_file = $options->{assigned_functions_file};
    $fn_file = "assigned_functions" if !$fn_file;

    open(my $func_fh, ">", "$dir/$fn_file") or die "Cannot create $dir/fn_file: $!";
    open(my $anno_fh, ">", "$dir/annotations") or die "Cannot create $dir/annotations: $!";

    mkdir("$dir/Features");

    my(%tbl_fh, %fasta_fh);

    for my $type (@types)
    {
        my $tdir = "$dir/Features/$type";
        -d $tdir or mkdir($tdir) or die "Cannot mkdir $tdir: $!";

        my $fh;
        open($fh, ">", "$tdir/tbl") or die "Cannot create $dir/tbl:$ !";
        $tbl_fh{$type} = $fh;

        my $fafh;
        open($fafh, ">", "$tdir/fasta") or die "Cannot create $dir/fasta:$ !";
        $fasta_fh{$type} = $fafh;
    }

    #     "location" : [
    #        [
    #           "kb|g.140.c.0",
    #           "631472",
    #           "+",
    #           3216
    #        ]
    #     ],

    for my $feature (@$features)
    {
        my $fid = $feature->{id};
        my $type = $feature->{type};
        my @aliases;

        if ($options->{correct_fig_id} && $fid =~ /^\d+\.\d+\.$type/)
        {
            $fid = "fig|$fid";
        }
        if ($type eq 'CDS' && $options->{map_CDS_to_peg})
        {
            $type = 'peg';
            $fid =~ s/\.CDS\./.peg./;
        }
        my $function = $feature->{function} || "hypothetical protein";
        print $func_fh "$fid\t$function\n";

        my $loc = $feature->{location};

        my @bloc;
        for my $loc_part (@$loc)
        {
            my($ctg, $start, $strand, $len) = @$loc_part;
            my $bl = BasicLocation->new($ctg, $start, $strand, $len);
            push(@bloc, $bl);
        }
        my $sloc = join(",", map { $_->SeedString() } @bloc);

        print { $tbl_fh{$type} } join("\t", $fid, $sloc, @aliases), "\n";

        if ($feature->{protein_translation})
        {
            write_fasta($fasta_fh{$type}, [$fid, undef, $feature->{protein_translation}]);
        }
        else
        {
            write_fasta($fasta_fh{$type}, [$fid, undef, $self->get_feature_dna($feature->{id})]);
        }

        # typedef tuple<string comment, string annotator, int annotation_time, analysis_event_id> annotation;

        for my $anno (@{$feature->{annotations}})
        {
            my($txt, $annotator, $time, $event_id) = @$anno;
            print $anno_fh join("\n", $fid, $time, $annotator, $txt);
            print $anno_fh "\n" if substr($txt, -1) ne "\n";
            print $anno_fh "//\n";
        }

    }

    for my $type (@types)
    {
        $fasta_fh{$type}->close();
        $tbl_fh{$type}->close();
    }
    close($anno_fh);
    close($func_fh);
}


sub add_analysis_event
{
    my($self, $event) = @_;

    if (ref($event) ne 'HASH')
    {
        die "GenomeTypeObject::add_analysis_event: event must be a hash reference";
    }

    my $uuid_str = create_uuid();

    $event->{id} = $uuid_str;

    push @{$self->analysis_events}, $event;

    if ( $self->{_event_index} )
    {
        $self->{_event_index}->{$uuid_str} = $event;
    }

    return $uuid_str;
}


#
#     $func = $genomeTO->update_function( $user, $fid,     $function, $event_id )
#     $func = $genomeTO->update_function( $user, $feature, $function, $event_id )
#
sub update_function
{
    my($self, $user, $fid, $function, $event_id) = @_;

    return undef unless $user && $fid && defined($function);

    $function = SeedUtils::canonical_function( $function );

    my $feature = ref($fid) eq 'HASH' ? $fid : $self->find_feature($fid)
        or return undef;

    $self->add_annotation( $feature,
                           "Function updated to $function",
                           $user,
                           $event_id
                         );

    $feature->{function} = $function;
}


#
#     $genomeTO->propose_function( $user, $fid,     $function, $score_0_to_1, $event_id )
#     $genomeTO->propose_function( $user, $feature, $function, $score_0_to_1, $event_id )
#         # recorded as annotation: "Proposed function: $function [score=$score]"
#

sub propose_function
{
    my( $self, $user, $fid, $function, $score, $event_id ) = @_;

    return undef unless $user && $fid && defined($function) && $score;

    $function = SeedUtils::canonical_function( $function );
    return undef unless length( $function );

    $self->add_annotation( $fid,
                           "Proposed function: $function [score=$score]",
                           $user,
                           $event_id
                         );
}

#
#     $genomeTO->add_annotation( $fid, $annotation, $user )
#     $genomeTO->add_annotation( $fid, $annotation, $user, $event_id )
#
sub add_annotation
{
    my( $self, $fid, $text, $user, $event_id ) = @_;

    return undef unless $fid && defined($text) && $text =~ /\S/ && $user;

    my $feature = ref($fid) eq 'HASH' ? $fid : $self->find_feature($fid)
        or return undef;

    # No leading or trailing whitespace:

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    length $text or return undef;

    my $annotation = [ $text, $user, scalar gettimeofday, $event_id ];

    push @{$feature->{annotations}}, $annotation;

    $text;
}


sub find_feature
{
    my($self, $fid) = @_;
    defined( $fid ) or return undef;

    #  Get the index, or build it:

    my $index = $self->{_feature_index} || $self->update_feature_index;

    #  Return feature, or if index is the wrong size, rebuild and try again.
    #  Note that two features with the same id will really mess this up,
    #  but it will mess up many other things, too.

    return $index->{$fid}
        || ( keys %$index != @{$self->{features}} && $self->update_feature_index->{$fid} )
        || undef;
}


sub find_contig
{
    my($self, $contig) = @_;
    defined( $contig ) or return undef;

    #  Get the index, or build it:

    my $index = $self->{_contig_index} || $self->update_contig_index;

    #  Return contig, or if index is the wrong size, rebuild and try again.
    #  Note that two contigs with the same id will really mess this up,
    #  but it will mess up many other things, too.

    return $index->{$contig}
        || ( keys %$index != $self->n_contigs && $self->update_contig_index->{$contig} )
        || undef;;
}


sub find_analysis_event
{
    my($self, $event_id) = @_;
    defined( $event_id ) or return undef;

    #  Get the index, or build it:

    my $index = $self->{_analysis_index} || $self->update_event_index;

    #  Return event, or if index is the wrong size, rebuild and try again.
    #  Note that two events with the same id will really mess this up,
    #  but it will mess up many other things, too.

    return $index->{$event_id}
        || ( keys %$index != $self->n_analysis_events && $self->update_event_index->{$event_id} )
        || undef;;
}


sub get_feature_dna
{
    my($self, $feature) = @_;
    defined( $feature ) or return undef;

    my @seq;

    if (!ref($feature))
    {
        $feature = $self->find_feature($feature)
            or return undef;
    }

    foreach my $loc (@{$feature->{location}})
    {
        my($contig, $beg, $strand, $len) = @$loc;

        my $cobj = $self->find_contig($contig);

        if ($strand eq '+' || $len == 1)
        {

            push(@seq, substr($cobj->{dna}, $beg - 1, $len));
        }
        else
        {
            push(@seq, &SeedUtils::reverse_comp(substr($cobj->{dna}, $beg - $len, $len)));
        }
    }
    return join("", @seq);

}


sub create_uuid
{
    if ($have_UUID)
    {
        my($uuid, $uuid_str);
        UUID::generate($uuid);
        UUID::unparse($uuid, $uuid_str);
        return $uuid_str;
    }
    elsif ($have_Data_UUID)
    {
        return Data::UUID->new->create_str();
    }
    else
    {
        die "No UUID generator found";
    }
}

sub seed_location_to_location_list
{
    my($loc_str) = @_;

    my @locs = map { my $l = BasicLocation->new($_);
                     [ $l->Contig, $l->Begin, $l->Dir, $l->Length ] } split(/,/, $loc_str);
    return wantarray ? @locs : \@locs;
}

#
# Renumber the features such that they are in order along the contigs.
#
# We use the order of the contigs in the contigs to set the overall ordering.
#
sub renumber_features
{
    my($self, $user, $event_id) = @_;

    my %contig_order;
    my $i = 0;
    for my $c (@{$self->{contigs}})
    {
        $contig_order{$c->{id}} = $i++;
    }


    my @f = sort {
        my($ac, $apos) = sort_position($a);
        my($bc, $bpos) = sort_position($b);
        ($a->{type} cmp $b->{type}) or
        ($contig_order{$ac} <=> $contig_order{$bc}) or
        $apos <=> $bpos } @{$self->{features}};

    my $nf = [];

    my $id = 1;
    my $last_type = '';
    for my $f (@f)
    {
        my $loc = join(",",map { my($contig,$beg,$strand,$len) = @$_;
                                 "$contig\_$beg$strand$len"
                               } @{$f->{location}});

        my($c, $left) = sort_position($f);

        if ($f->{type} ne $last_type)
        {
            $id = 1;
            $last_type = $f->{type};
        }
        if ($f->{id} =~ /(.*\.)(\d+)$/)
        {
            my $new_id = $1 . $id++;

            my $annotation = ["Feature renumbered from $f->{id} to $new_id", $user, scalar gettimeofday, $event_id];
            push(@{$f->{annotations}}, $annotation);

            $f->{id} = $new_id;
        }
        else
        {
            warn "Cannot renumber feature with id $f->{id}\n";
        }

        push(@$nf, $f);

        # print join("\t", $f->{id}, $c, $left, $loc), "\n";

    }
    $self->{features} = $nf;
}

#
# compute the contig and coordinate to use for sorting for this feature.
#
sub sort_position
{
    my($f) = @_;
    my $min;
    my $contig;

    for my $l (@{$f->{location}})
    {
        my($c, $beg, $str, $len) = @$l;
        $contig = $c;
        my $left;
        if ($str eq '+')
        {
            $left = $beg;
        }
        else
        {
            $left = $beg - $len + 1;
        }
        $min = (defined($min) && $min < $left) ? $min : $left;
    }
    return ($contig, $min);
}


#
#  Sort features my midpoint:
#
#    @sorted = sort_features_by_midpoint( @features )
#
sub sort_features_by_midpoint
{
    return map  { $_->[0] }
           sort { lc $a->[1] cmp lc $b->[1]    # contig (lowercase)
               ||    $a->[1] cmp    $b->[1]    # contig
               ||    $a->[2] <=>    $b->[2]    # midpoint (left to right)
               ||    $a->[3] cmp    $b->[3]    # direction
               ||    $b->[4] <=>    $a->[4]    # length (long to short)
                }
           map  { [ $_, mid_point( $_ ) ] }
           @_;
}

#
# compute the [ contig, midpoint, direction, length ] for a feature.
#
sub mid_point
{
    my( $f ) = @_;

    my ( $contig, $min, $max, $dir );

    for my $l (@{$f->{location}})
    {
        my( $c, $beg, $str, $len ) = @$l;
        $len ||= 1;

        if    ( ! defined $contig ) { $contig = $c }
        elsif ( $contig ne $c )     { next }

        if    ( ! defined $dir )    { $dir = $str }
        elsif ( $dir ne $str )      { next }

        if ($str eq '+')
        {
            if    ( ! defined $min ) { $min = $beg }
            elsif ( $beg < $min )    { last }

            my $right = $beg + $len - 1;
            if ( ! defined $max || $right >= $max ) { $max = $right }
        }
        else
        {
            if    ( ! defined $max ) { $max = $beg }
            elsif ( $beg > $max )    { last }

            my $left = $beg - $len + 1;
            if ( ! defined $min || $left <= $min ) { $min = $left }
        }
    }

    my @cont_mid_dir_len = ( $contig, 0.5 * ($min+$max), $dir, $max-$min+1 );

    wantarray ? @cont_mid_dir_len : \@cont_mid_dir_len;
}

sub get_creation_info
{
    my($self, $feature) = @_;

    my $fcid = $feature->{feature_creation_event};
    my $cevent = $self->{_event_index}->{$fcid} if $fcid;

    my $anno_id;
    my $anno_tool;
    for my $anno (@{$feature->{annotations}})
    {
        my($str, $tool, $date, $eid) = @$anno;
        if ($str =~ /Function updated/ && defined($eid) && $eid)
        {
            $anno_id = $eid;
            $anno_tool = $tool;
        }
    }
    my $aevent = $self->{_event_index}->{$anno_id} if $anno_id;
    return($cevent, $aevent, $anno_tool);
}

#
#  Feature data access:
#
#  Existing:
#
#     $genomeTO->update_function( $user, $fid, $function, $event_id )
#
#     # hash keyed by type, with lists of feature ids of that type
#    \%fids_by_type = $genomeTO->fids_by_type()
#
#     @fids = $genomeTO->fids_of_type( @types )
#    \@fids = $genomeTO->fids_of_type( @types )
#
#     $done = $genomeTO->delete_feature( $fid )
#
#     $type = $genomeTO->feature_type( $fid )
#
#     $loc  = $genomeTO->feature_location( $fid )
#
#     $func = $genomeTO->feature_function( $fid )
#
#     @anno = $genomeTO->feature_annotations( $fid )
#    \@anno = $genomeTO->feature_annotations( $fid )
#
#    \%qual = $genomeTO->feature_quality_data( $fid )
#


sub delete_feature
{
    my ( $genomeTO, $fid ) = @_;
    $genomeTO && $fid
        or return undef;

    my $ind = 0;
    foreach my $ftr ( $genomeTO->features )
    {
        last if ( $ftr->{id} eq $fid );
        $ind++;
    }

    my $done = ( $ind < $genomeTO->n_features ) ? 1 : 0;
    if ( $done )
    {
        splice @{$genomeTO->features}, $ind, 1;
        my $feature_index = $genomeTO->{_feature_index};
        delete $feature_index->{ $fid } if $feature_index;
    }

    return $done;
}


sub feature_type
{
    my $ftr;
    if ( ref($_[0]) eq 'GenomeTypeObject' )
    {
        my ( $genomeTO, $fid ) = @_;
        $ftr = $genomeTO->find_feature($fid);
    }
    elsif ( ref($_[0]) eq 'HASH' )
    {
        $ftr = shift;
    }

    $ftr ? $ftr->{type} : undef;
}


sub feature_location
{
    my $ftr;
    if ( ref($_[0]) eq 'GenomeTypeObject' )
    {
        my ( $genomeTO, $fid ) = @_;
        $ftr = $genomeTO->find_feature($fid);
    }
    elsif ( ref($_[0]) eq 'HASH' )
    {
        $ftr = shift;
    }

    $ftr ? $ftr->{location} : undef;
}


sub feature_function
{
    my $ftr;
    if ( ref($_[0]) eq 'GenomeTypeObject' )
    {
        my ( $genomeTO, $fid ) = @_;
        $ftr = $genomeTO->find_feature($fid);
    }
    elsif ( ref($_[0]) eq 'HASH' )
    {
        $ftr = shift;
    }

    $ftr ? $ftr->{function} : undef;
}


#
#     @anno = $genomeTO->feature_annotations( $fid )
#    \@anno = $genomeTO->feature_annotations( $fid )
#
sub feature_annotations
{
    my $ftr;
    if ( ref($_[0]) eq 'GenomeTypeObject' )
    {
        my ( $genomeTO, $fid ) = @_;
        $ftr = $genomeTO->find_feature($fid);
    }
    elsif ( ref($_[0]) eq 'HASH' )
    {
        $ftr = shift;
    }

    my $anno = $ftr ? $ftr->{annotations} : [];

    wantarray ? @$anno : $anno;
}


#
#     @func_scr_user_date_tool = $genomeTO->feature_proposed_functions( $fid )
#    \@func_scr_user_date_tool = $genomeTO->feature_proposed_functions( $fid )
#     @func_scr_user_date_tool = $genomeTO->feature_proposed_functions( $feature )
#    \@func_scr_user_date_tool = $genomeTO->feature_proposed_functions( $feature )
#
#     $annotation = [ $text, $user, scalar gettimeofday, $event_id ]
#
sub proposed_functions
{
    my $genomeTO = shift;
    my @prop = map { $_->[4] = ( $genomeTO->find_analysis_event($_->[4]) || {} )->{tool};
                     $_;
                   }
               map { $_->[0] =~ /^Proposed function: (.+) \[score=(\S+)\]$/
                     ? [ $1, $2, @$_[1,2,3] ]
                     : ()
                   }
               $genomeTO->feature_annotations( @_ );

    wantarray ? @prop : \@prop;
}


#
#  Feature quality data:
#
#    {
#      existence_confidence =>  $P_value,  # absolute probability estimate
#      existence_priority   =>  $float,    # priority in overlap removal
#      frameshifted         =>  $bool,
#      genemark_score       =>  $float,
#      hit_count            =>  $float,    # kmer hits (for priority)
#      overlap_rules        => \@rules,    # overlap resolution
#      pyrrolysylprotein    =>  $bool,     # raises priority
#      selenoprotein        =>  $bool,     # raises priority
#      truncated_begin      =>  $bool,
#      truncated_end        =>  $bool,
#      weighted_hit_count   =>  $float     # weighted kmers
#   }

sub feature_quality_data
{
    my $ftr;
    if ( ref($_[0]) eq 'GenomeTypeObject' )
    {
        my ( $genomeTO, $fid ) = @_;
        $ftr = $genomeTO->find_feature($fid);
    }
    elsif ( ref($_[0]) eq 'HASH' )
    {
        $ftr = shift;
    }

    $ftr ? $ftr->{quality} : {};
}


1;
