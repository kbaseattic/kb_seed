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

use strict;

use Bio::KBase;
use Bio::KBase::CDMI::CDMILoader;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMIClient;

=head1 Alignment and Tree Data Load Script for CDMI

    CDMILoadAlignments [options] <dir>

=head2 Introduction

This script processes Alignment and Tree data files and loads them
into the Kbase Central Data Model.

The following files are processed by this script. All are
tab-delimited files without a heading line. Unless otherwise noted,
all files are required.

The exchange format for Alignments and Trees can be found on the KBase
wiki page: https://trac.kbase.us/projects/kbase/wiki/ExchangeFormatTrees

=over 4

=item Alignment.tab

Each record in this file represents an instance of the B<Alignment>
entity that has a preallocated KBase ID in the form of "kb|aln.xxx".
The fields are:

  (0) kb-aln-id
  (1) n-rows
  (2) n-cols
  (3) status
  (4) is-concatenation
  (5) sequence-type
  (6) timestamp
  (7) method
  (8) parameters
  (9) protocol
 (10) source-db  # source-db exists as a relationship "Aligned" to the Source entity
 (11) source-db-aln-id

This file is used to load two data tables.

The B<Alignment> entity table uses the following fields:

  (0) id        (renamed from kb-aln-id)
  (1..9)
 (11) source-id (renamed from source-db-aln-id)

The B<Aligned> relationship table (connecting B<Source> to
B<Alignment>) uses the following fields:

  (0) to-link   (renamed from kb-aln-id)
 (10) from-link (renamed from source-db)


=item Tree.tab

Each record in this file represents an instance of the B<Tree> entity
that should reference an alignment, and has been assigned a KBase ID
in the form of "kb|tree.xxx". Each record in thie file also represents
an instance of the B<IsUsedToBuildTree> relationship between
B<Alignment> and B<Tree>. The fields are:

  (0) kb-tree-id
  (1) kb-aln-id
  (2) status
  (3) data-type
  (4) timestamp
  (5) method
  (6) parameters
  (7) protocol
  (8) source-db
  (9) source-db-tree-id
  
This file is used to load three data tables.

The B<Tree> entity table uses the following fields:

  (0) id        (renamed from kb-tree-id)
  (2..7)
  (9) source-id (renamed from source-db-tree-id)
  (+) newick    (newick string of Raw_Tree_Files/kb-tree-id.newick)

The B<Treed> relationship table (connecting B<Source> to B<Tree>) uses
the following fields: 

  (0) to-link   (renamed from kb-tree-id)
  (8) from-link (renamed from kb-aln-id)

The B<IsUsedToBuildTree> relationship table (connecting B<Alignment>
to B<Tree>) uses the following fields:

  (0) to-link   (renamed from kb-tree-id)
  (1) from-link (renamed from kb-aln-id)


=item AlignmentRow.tab

Each line corresponds to a unique B<AlignmentRow> entity that must
map to an alignment described in "Alignment.tab". IDs for this
particular alignment row (the row-id field) are provided by the input
data, and may not be unique across all of KBase (but must be unique
within the alignment/tree). The fileds are:

  (0) kb-aln-id 
  (1) row-number
  (2) row-id
  (3) row-description
  (4) n-components
  (5) beg-pos-in-aln
  (6) end-pos-in-aln
  (7) md5-of-ungapped-seq

This file is used to load two data tables.

The B<AlignmentRow> entity table uses the following fields:

  (+) id                       (constructed from kb-aln-id and row-number, eg, kb|aln.xxx.y)
  (1..4) 
  (5) beg-pos-aln              (renamed from beg-pos-in-aln)
  (6) end-pos-aln              (renamed from end-pos-in-aln)
  (7) md5-of-ungapped-sequence (renamed from md5-of-ungapped-seq)
  (+) sequence                 (sequence string from Raw_Alignment_Files/kb-aln-id.fasta: the row-number-th sequence)

The B<IncludesAlignmentRow> reltionship table (connecting B<Alignment> to 
B<AligmentRow>) uses the following fields:

  (0) from-link (renamed from kb-aln-id)
  (+) to-link   (id in AlignmentRow constructed from kb-aln-id and row-number)


=item ContainsAlignedProtein.tab

Each record in this file represents an instance of the
B<ContainsAlignedProtein> relationship between B<AlignmentRow> and
B<ProteinSequence>. Each line must map to an alignment described in
"Alignment.tab". Parsing assumes that alignment rows will be in
ascending order by the "alignment-row" number, then the
"index-in-concatenation" number. The fileds are:

  (0) kb-aln-id
  (1) aln-row-number
  (2) index-in-concatenation
  (3) parent-seq-id
  (4) beg-pos-in-parent
  (5) end-pos-in-parent
  (6) parent-seq-len
  (7) beg-pos-in-aln
  (8) end-pos-in-aln
  (9) kb-feature-id

This file is used to load one data table.

The B<ContainsAlignedProtein> reltionship table (connecting B<AlignmentRow> to 
B<ProteinSequence>) uses the following fields:

  (+) from-link      (id in AlignmentRow constructed from kb-aln-id and aln-row-number)
  (2) 
  (3) to-link        (renamed from parent-seq-id)
  (4..6) 
  (7) beg-pos-aln (renamed from beg-pos-in-aln)
  (8) end-pos-aln (renamed from end-pos-in-aln)
  (9)


=item ContainsAlignedNucleotides.tab

This table describes the B<ContainsAlignedDNA>
relationship. Each line corresponds to a unique element of an
alignment row (e.g. a particular DNA sequence) that must map to an
alignment described in "Alignment.tab". Parsing assumes that alignment
rows will be in ascending order by the "alignment-row" number, then
the "index-in-concatenation" number.

  (0) kb-aln-id
  (1) aln-row-number
  (2) index-in-concatenation
  (3) parent-seq-id (to-link)
  (4) beg-pos-in-parent
  (5) end-pos-in-parent
  (6) parent-seq-len
  (7) beg-pos-in-aln
  (8) end-pos-in-aln
  (9) kb-feature-id

This optional file is used to load one data table.

The B<ContainsAlignedDNA> reltionship table (connecting B<AlignmentRow> to 
B<ContigSequence>) uses the following fields:

  (+) from-link      (id in AlignmentRow constructed from kb-aln-id and row-number)
  (2) 
  (3) to-link        (renamed from parent-seq-id)
  (4..6) 
  (7) beg-pos-in-aln (renamed from beg-pos-aln)
  (8) end-pos-in-aln (renamed from end-pos-aln)
  (9)


=item AlignmentSuccessor.tab

This file provides information about B<Alignment>s which have
superseded existing alignments in KBase. Each line represents an
instance of the B<SupersedesAlignment> relationship between
two B<Alignment>s. The fields are:

  (0) original-aln-id
  (1) successor-aln-id
  (2) successor-type

This optional file is used to load one data table.

The B<SupersedesAlignment> relationship table uses the following
fields:

  (0) from-link (renamed from original-aln-id)
  (1) to-link   (renamed from successor-aln-id)
  (2) 

=item TreeSuccessor.tab

This file provides information about B<Tree>s which have
superseded existing trees in KBase. Each line represents an
instance of the B<SupersedesTree> relationship between
two B<Tree>s. The fields are:

  (0) original-aln-id
  (1) successor-aln-id
  (2) successor-type

This optional file is used to load one data table.

The B<SupersedesTree> relationship table uses the following
fields:

  (0) from-link (renamed from original-tree-id)
  (1) to-link   (renamed from successor-tree-id)
  (2) 


=item AlignmentModification.tab

Thie file provides information about B<Alignment>s which have been
created by modifications to other alignments in KBase or that are
being loaded. Each line represents an instance of the
B<IsModifiedToBuildAlignment> relationship between two
B<Alignment>s. The fields are:

  (0) original-aln-id
  (1) modified-aln-id
  (2) modification-type
  (3) modification-value

This optional file is used to load one data table.

The B<IsModifiedToBuildAlignment> relationship table uses the
following fields:

  (0) from-link (renamed from original-aln-id)
  (1) to-link   (renamed from successor-aln-id)
  (2..3) 


=item TreeModification.tab

This file provides information about B<Tree>s which have been created
by modifications to other trees in KBase or that are being
loaded. Each line represents an instance of the
B<IsModifiedToBuildTree> relationship between two B<Tree>s. The fields
are:

  (0) original-aln-id
  (1) modified-aln-id
  (2) modification-type
  (3) modification-value

This optional file is used to load one data table.

The B<IsModifiedToBuildTree> relationship table uses the
following fields:

  (0) from-link (renamed from original-tree-id)
  (1) to-link   (renamed from successor-tree-id)
  (2..3) 


=item AlignmentAttribute.tab

Each record in thie file also represents an instance of the
B<DescribesAlignment> relationship between B<AlignmentAttribute> and
B<Alignment>. There may be zero, one or multiple lines describing
attributes for each alignment. The fields are:

  (0) kb-aln-id
  (1) key
  (2) value

This optional file is used to load two data tables.

The B<DescribesAlignment> relationship table uses the following
fields:

  (0) to-link   (renamed from kb-aln-id)
  (1) from-link (renamed from key)
  (2)

The set of unique keys (column 1) in this file is also used to fill
the B<AlignmentAttribute> entity table. The field is:

  (+) id (unique occurrences of the key field)


=item TreeAttribute.tab

Each record in thie file also represents an instance of the
B<DescribesTree> relationship between B<TreeAttribute> and
B<Tree>. There may be zero, one or multiple lines describing
attributes for each tree. The fields are:

  (0) kb-tree-id
  (1) key
  (2) value

This optional file is used to load two data tables.

The B<DescribesTree> relationship table uses the following
fields:

  (0) to-link   (renamed from kb-tree-id)
  (1) from-link (renamed from key)
  (2)

The set of unique keys (column 1) in this file is also used to fill
the B<TreeAttribute> entity table. The field is:

  (+) id (unique occurrences of the key field)


=item TreeNodeAttribute.tab

Each line in this file provides any additional meta information about
a node in a tree. Each line represents an instance of the
B<TreeNodeAttribute> entity and its associated B<DescribesTreeNode>
relationship. There may be zero, one or multiple lines describing
attributes for each tree node. The fields are:

  (0) kb-tree-id
  (1) node-id
  (2) key
  (3) value

This optional file is used to load two data tables.

The B<DescribesTreeNode> relationship table (connecting
B<TreeNodeAttribute> to B<Tree>) uses the following fields:

  (0) to-link   (renamed from kb-tree-id)
  (1)
  (2) from-link (renamed from key)
  (3)

The set of unique keys (column 2) in this file is also used to fill
the B<TreeNodeAttribute> entity table. The field is:

  (+) id (unique occurrences of the key field)


=back

=head2 Command-Line Options

The command-line options are those specified in L<Bio::KBase::CDMI::CDMI/new_for_script>
plus the following.

=over 4

=item clear

Recreate the tables before loading. This removes all existing data.
If this option is not specified, errors may occur if chemistry data
already present in the database is loaded. 

=over 4

=item dry

Dry run. Validate the exchange data only.

=back

=head2 Positional Parameters

=over 4

=item dir

Name of the input directory containing the alignment and tree data files.

=back

=cut

use Data::Dumper;
use File::Temp;
use File::Path;
use IO::File;
use IO::Handle;

use gjoseqlib;

# All Tables (19)
#
# Entities (6)
#   Alignment
#   AlignmentRow
#   Tree
#   AlignmentAttribute
#   TreeAttribute
#   TreeNodeAttribute

# Relationships (13)
#   IncludesAlignmentRow
#   ContainsAlignedProtein
#   ContainsAlignedDNA
#   IsUsedToBuildTree
#   Aligned
#   Treed
#   SupersedesAlignment
#   SupersedesTree
#   IsModifiedToBuildAlignment
#   IsModifiedToBuildTree
#   DescribesAlignment
#   DescribesTree
#   DescribesTreeNode

my $clear;
my $dry;

my $cdmi   = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear, dry => \$dry);
my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);

my $dir = shift @ARGV;
   $dir or die "No input directory specified.";
-d $dir or die "Invalid input directory $dir.";

my ($load_recipes, $stage) = validate_exchange( -dir => $dir );

my @tables = map { $_->[2] } @$load_recipes;


print "Connecting to database...\n";

my $stats = $loader->stats;

if ($clear) {
    for my $table (@tables) {
        print "Recreating $table.\n";
        $cdmi->CreateTable($table, 1);
    }
}

unless ($dry) {
    $loader->SetRelations(@tables);

    for my $recipe (@$load_recipes) {
        $loader->SimpleLoad(@$recipe, 0);
    }

    $loader->LoadRelations();
}

File::Path::rmtree($stage) if $stage ne $dir;


# Command line: CDMILoadAlignments --develop --clear dir


#-------------------------------------------------------------------------------
#  ( \@simple_load_recipes, $staging_dir ) = validate_exchange( \%parameters );
#
#  Parameters:
#
#    -dir     => directory_name   #  D = '.'
#    -stage   => staging_dir      #  D = directory created using File::Spec::tmpdir()
#    -log     => file_or_fh       #  message log file location (D = STDOUT)
#
#-------------------------------------------------------------------------------

sub validate_exchange
{
    my $params = $_[0] && ref( $_[0] ) eq 'HASH' ? shift
               : @_ && ( @_ % 2 ) == 0           ? { @_ }
               :                                   {};

    my $dir   = $params->{ -dir }   || '.';
    my $stage = $params->{ -stage } || File::Temp->tempdir( 'AT-XXXXX', CLEANUP => 0 );
    my $log   = exists( $params->{ -log } ) ? $params->{ -log } : \*STDOUT;

    if ( ref($log) eq 'GLOB' ) { open( MESSAGE, '>&', $log ) }
    else                       { open( MESSAGE, '>',  $log ) }

    #
    # We are going to make a quick pass through the exchange files to
    # verify field syntax using regex pattern matching.
    #
    
    my @exchange_syntax = 
        ( 'Alignment.tab' => [ 'Mandatory',
                               [ kb_aln_id        => qr/^kb\|aln\.\d+$/,
                                 n_rows           => 'natural',
                                 n_cols           => 'natural',
                                 status           => qr/^(active|superseded|bad)$/,
                                 is_concatenation => 'bool',
                                 sequence_type    => qr/^(Protein|DNA|RNA|Mixed)$/,
                                 timestamp        => 'time',
                                 method           => 'text',
                                 parameters       => 'text',
                                 protocol         => 'text',
                                 source_db        => 'source',
                                 source_db_aln_id => 'string' ] ],

          'AlignmentRow.tab' => [ 'Mandatory',
                                  [ kb_aln_id           => qr/^kb\|aln\.\d+$/,
                                    row_number          => 'natural',
                                    row_id              => 'string',
                                    row_description     => 'free',
                                    n_components        => 'natural',
                                    beg_pos_in_aln      => 'natural',
                                    end_pos_in_aln      => 'natural',
                                    md5_of_ungapped_seq => 'md5' ] ],

          'Tree.tab' => [ 'Mandatory',
                          [ kb_tree_id        => qr/^kb\|tree\.\d+$/,
                            kb_aln_id         => qr/^kb\|aln\.\d+$/,
                            status            => qr/^(active|superseded|bad)$/,
                            data_type         => qr/^(sequence_alignment|taxonomy|gene_content)$/,
                            timestamp         => 'time',
                            method            => 'text',
                            parameters        => 'text',
                            protocol          => 'text',
                            source_db         => 'source',
                            source_db_tree_id => 'string' ] ],

          'ContainsAlignedProtein.tab' => [ 'Mandatory',
                                            [ kb_aln_id              => qr/^kb\|aln\.\d+$/,
                                              aln_row_number         => 'natural',
                                              index_in_concatenation => 'natural',
                                              parent_seq_id          => 'md5',
                                              beg_pos_in_parent      => 'natural',
                                              end_pos_in_parent      => 'natural',
                                              parent_seq_len         => 'natural',
                                              beg_pos_in_aln         => 'natural',
                                              end_pos_in_aln         => 'natural',
                                              kb_feature_id          => 'free'
                                            ] ],
          

          'ContainsAlignedNucleotides.tab' => [  'Optional',
                                                 [ kb_aln_id              => qr/^kb\|aln\.\d+$/,
                                                   aln_row_number         => 'natural',
                                                   index_in_concatenation => 'natural',
                                                   parent_seq_id          => 'md5',
                                                   beg_pos_in_parent      => 'natural',
                                                   end_pos_in_parent      => 'natural',
                                                   parent_seq_len         => 'natural',
                                                   beg_pos_in_aln         => 'natural',
                                                   end_pos_in_aln         => 'natural',
                                                   kb_feature_id          => 'free'
                                                 ] ],

          'AlignmentAttribute.tab' => [ 'Optional',
                                        [ kb_aln_id => qr/^kb\|aln\.\d+$/,
                                          key       => 'string',
                                          value     => 'text' ] ],

          'TreeAttribute.tab' => [  'Optional',
                                    [ kb_tree_id => qr/^kb\|tree\.\d+$/,
                                      key        => 'string',
                                      value      => 'text' ] ],
          
          'TreeNodeAttribute.tab' => [  'Optional',
                                        [ kb_tree_id => qr/^kb\|tree\.\d+$/,
                                          node_id    => 'string',
                                          key        => 'string',
                                          value      => 'text' ] ],
          
          'AlignmentSuccessor.tab' => [ 'Optional',
                                        [ original_aln_id  => qr/^kb\|aln\.\d+$/,
                                          successor_aln_id => qr/^kb\|aln\.\d+$/,
                                          successor_type   => qr/^(strict|partial)$/ ] ],
          
          'TreeSuccessor.tab' => [  'Optional',
                                    [ original_tree_id  => qr/^kb\|tree\.\d+$/,
                                      successor_tree_id => qr/^kb\|tree\.\d+$/,
                                      successor_type    => qr/^(strict|partial)$/ ] ],

          'AlignmentModification.tab' => [ 'Optional',
                                           [ original_aln_id    => qr/^kb\|aln\.\d+$/,
                                             modified_aln_id    => qr/^kb\|aln\.\d+$/,
                                             modification_type  => 'string',
                                             modification_value => 'text' ] ],
          
          'TreeModification.tab' => [ 'Optional',
                                      [ original_tree_id    => qr/^kb\|tree\.\d+$/,
                                        modified_tree_id   => qr/^kb\|tree\.\d+$/,
                                        modification_type  => 'string',
                                        modification_value => 'text' ] ]
        );

    my $success = 1;
    for (my $i = 0; $i < $#exchange_syntax; $i += 2) {
        my ($fname, $syntax) = @exchange_syntax[$i, $i+1];
        $success = 0 unless verify_syntax("$dir/$fname", $syntax, \*MESSAGE);
    }
    
    $success or die "Abort: syntax error found in exchange files.\n";


    #
    # We are going to verify individual exchange files more carefully
    # and prepare staging files in order to use the SimpleLoad() utility.
    #


    # A simple load recipe is defined as a 4-tuple:
    #   [ data_file_directory,
    #     data_file_name,
    #     database_table_name,
    #     field_key_to_0_column_based_index_hash ]

    my @load_recipes;


    #  Get server access objects

    my $CDMIO     = Bio::KBase->central_store();
    my $IDserverO = Bio::KBase->id_server();


    # Input: Alignment.tab
    # Table: Alignment, Aligned

    # Verify the kb_aln_ids are registered with KBase

    # my @kb_aln_ids     = unique_fields_in_file("$dir/Alignment.tab", 0);
    # my $extern_aln_ids = $IDserverO->kbase_ids_to_external_ids(\@kb_aln_ids);

    # my @bad_aln_ids = grep { !$extern_aln_ids->{$_} } @kb_aln_ids;

    # if (@bad_aln_ids) {
    #     print MESSAGE "ERROR: Alignment.tab: found unregistered KBase alignment IDs: \n";
    #     print MESSAGE map { "    $_\n" } @bad_aln_ids;
    #     $success = 0;
    # }

    push @load_recipes, [ $dir, 'Alignment.tab', 'Alignment',
                          { id => 0, n_rows => 1, n_cols => 2, status => 3,
                            is_concatenation => 4, sequence_type => 5,
                            timestamp => 6, method => 7, parameters => 8,
                            protocol => 9, source_id => 10 } ];

    push @load_recipes, [ $dir, 'Alignment.tab', 'Aligned',
                          { to_link => 0, from_link => 10 } ];


    # Input: Tree.tab, Raw_Tree_Files/*.newick
    # Table: Tree, Treed, IsUsedToBuildTree
    # Temp:  Tree.tmp  

    # Verify the kb_tree_ids are registered with KBase
    
    # my @kb_tree_ids     = unique_fields_in_file("$dir/Tree.tab", 0);
    # my $extern_tree_ids = $IDserverO->kbase_ids_to_external_ids(\@kb_tree_ids);
    
    # my @bad_tree_ids = grep { !$extern_tree_ids->{$_} } @kb_tree_ids;

    # if (@bad_tree_ids) {
    #     print MESSAGE "ERROR: Tree.tab: found unregistered KBase tree IDs: \n";
    #     print MESSAGE map { "    $_\n" } @bad_tree_ids;
    #     $success = 0;
    # }

    # Verify the kb_aln_ids in the tree file are registered with KBase

    # @kb_aln_ids     = unique_fields_in_file("$dir/Tree.tab", 1);
    # @kb_aln_ids     = grep { !$extern_aln_ids->{$_} } @kb_aln_ids;
    # $extern_aln_ids = $IDserverO->kbase_ids_to_external_ids(\@kb_aln_ids);
    # @bad_aln_ids    = grep { !$extern_aln_ids->{$_} } @kb_aln_ids;

    # if (@bad_aln_ids) {
    #     print MESSAGE "ERROR: Alignment.tab: found unregistered KBase alignment IDs: \n";
    #     print MESSAGE map { "    $_\n" } @bad_aln_ids;
    #     $success = 0;
    # }

    my $fname = "Tree.tab";
    my $tmpfile = "Tree.tmp";
    my $fh    = IO::File->new("$stage/$tmpfile", "w");
    my $line  = 0;
    open(F, "<$dir/$fname") or die "Could not open $dir/$fname.";
    while (<F>) {
        chomp; $line++;
        my @fields = split /\t/;
        my $kb_tree_id = $fields[0];
        my $newick_file = "$dir/Raw_Tree_Files/$kb_tree_id.newick";
        unless (-e $newick_file) {
            print MESSAGE "ERROR: Tree.tab: line $line: newick tree not found: $newick_file.\n";
            $success = 0; next;
        }
        my $newick = `cat "$newick_file"`;
        if ($newick !~ /^\(.*\).*;\s*$/) {
            print MESSAGE "ERROR: Tree.tab: line $line: invalid newick format: $newick_file.\n";
            $success = 0; next;
        }
        print $fh join("\t", @fields[0, 2..7, 9], $newick);
    }
    close(F);
    
    push @load_recipes, [ $stage, $tmpfile, 'Tree',
                          { id => 0, status => 1, data_type => 2,
                            timestamp => 3, method => 4, parameters => 5,
                            protocol => 6, source_id => 7, newick => 8 } ];

    push @load_recipes, [ $dir, 'Tree.tab', 'Treed',
                          { to_link => 0, from_link => 8 } ];

    push @load_recipes, [ $dir, 'Tree.tab', 'IsUsedToBuildTree',
                          { to_link => 0, from_link => 1 } ];
    

    # Input: AlignmentRow.tab, Raw_Alignment_Files/*.fasta
    # Table: AlignmentRow, IncludesAlignmentRow
    # Temp:  AlignmentRow.tmp, IncludesAlignmentRow.tmp

    my $fname = "AlignmentRow.tab";
    my $tmpf1 = "AlignmentRow.tmp";
    my $tmpf2 = "IncludesAlignmentRow.tmp";
    my $fh1   = IO::File->new("$stage/$tmpf1", "w");
    my $fh2   = IO::File->new("$stage/$tmpf2", "w");
    my %first_line;
    my $line  = 0;
    my ($last_aln_id, $last_row_number);

    open(F, "<$dir/$fname") or die "Could not open $dir/$fname.";
    while (<F>) {
        chomp; $line++;
        my @fields = split /\t/;
        my ($kb_aln_id, $row_number, $row_id, $beg, $end, $md5) = @fields[0..2, 5..7];        
        my $id    = "$kb_aln_id.$row_number";
        my $fasta = "$dir/Raw_Alignment_Files/$kb_aln_id.fasta";

        if ($kb_aln_id ne $last_aln_id) {
            %first_line = undef;
            $last_row_number = 0;
        }

        unless (-e $fasta) {
            print MESSAGE "ERROR: AlignmentRow.tab: line $line: fasta file not found: $fasta.\n";
            $success = 0; next;
        }

        if ($row_number != $last_row_number + 1) {
            print MESSAGE "ERROR: AlignmentRow.tab: line $line: incorrect row number: $row_number.\n";
            $success = 0; next;
        }

        my $seq_entry = gjoseqlib::read_next_fasta_seq($fasta);
        my $seq_row   = $seq_entry->[2];
        my $seq_len   = length($seq_row);
        if (!$seq_entry || $seq_len == 0) {
            print MESSAGE "ERROR: AlignmentRow.tab: line $line: could not read sequence entry corresponding to $id in $fasta.\n";
            $success = 0; next;
        }

        if ($beg > $seq_len || $end > $seq_len) {
            print MESSAGE "ERROR: AlignmentRow.tab: line $line: seq length=$seq_len, beg_pos_in_aln=$beg, end_pos_in_aln=$end.\n";
            $success = 0; next;
        }

        if ($seq_entry->[0] ne $row_id) {
            print MESSAGE "ERROR: AlignmentRow.tab: line $line: row IDs don't match ('$seq_entry->[0]' vs '$row_id') in $fasta.\n";
            $success = 0; next;
        }

        if ($first_line{$row_id}) {
            print MESSAGE "ERROR: AlignmentRow.tab: line $line: row ID '$row_id' not unique in $kb_aln_id: first appeared in line $line.\n";
            $success = 0; next;
        }
        $first_line{$row_id} = $line;


        # Verify the first 10 rows in greater detail

        if ($line <= 1) {      
            my ($beg_, $end_, $md5_) = seq_summary($seq_row);
            if ($md5_ ne $md5) {
                print MESSAGE "ERROR: AlignmentRow.tab: line $line: MD5 does not correspond to sequences in $fasta.\n";
                $success = 0; next;
            }
            if ($beg_ != $beg) {
                print MESSAGE "ERROR: AlignmentRow.tab: line $line: incorrect beg-pos-in-aln (column 5): $beg (should be $beg_).\n";
                $success = 0; next;
            }
            if ($end_ != $end) {
                print MESSAGE "ERROR: AlignmentRow.tab: line $line: incorrect end-pos-in-aln (column 6): $end (should be $end_).\n";
                $success = 0; next;
            }
            my %bad_seq_char = map { $_ => 1 } $seq_row =~ /([^-A-Za-z])/g;
            if ( keys %bad_seq_char )
            {
                printf MESSAGE "WARNING: AlignmentRow.tab: line $line: bad sequence characters (%s): ",
                    join( ', ', sort keys %bad_seq_char ), "\n";
            }
        }

        print $fh1 join("\t", $id, @fields[1..7], $seq_entry->[2])."\n";
        print $fh2 join("\t", $kb_aln_id, $id)."\n";

        $last_aln_id = $kb_aln_id;
        $last_row_number = $row_number;
    }
    close(F);

    push @load_recipes, [ $stage, $tmpf1, 'AlignmentRow',
                          { id => 0, row_number => 1, row_id => 2,
                            row_description => [3, 'copy', ''],    # make the null string the default value
                            n_components => 4, beg_pos_aln => 5, end_pos_aln => 6,
                            md5_of_ungapped_sequence => 7, sequence => 8 } ];

    push @load_recipes, [ $stage, $tmpf2, 'IncludesAlignmentRow',
                          { from_link => 0, to_link => 1 } ];


    # Input: ContainsAlignedProtein.tab, NewProteinSequence.fasta
    # Table: ContainsAlignedProtein
    # Temp:  ContainsAlignedProtein.tmp  

    my $fname   = "ContainsAlignedProtein.tab";
    my $tmpfile = "ContainsAlignedProtein.tmp";
    my $fh      = IO::File->new("$stage/$tmpfile", "w");
    my $line    = 0;
    my (%seen_md5, %seen_feature);
    
    open(F, "<$dir/$fname") or die "Could not open $dir/$fname.";
    while (<F>) {
        chomp; $line++;
        my @fields = split /\t/;
        my ($kb_aln_id, $aln_row_number, $parent_seq_id, $kb_feature_id) = @fields[0..1, 3, 9];        
        my $id    = "$kb_aln_id.$aln_row_number";

        $seen_md5{$parent_seq_id}++;
        $seen_feature{$kb_feature_id}++ if $kb_feature_id;

        print $fh join("\t", $id, @fields[2..9])."\n"; 
    }
    close(F);

    # Verify the parent MD5s exist in KBase or the NewProteinSequence.fasta file

    my %md5_in_kbase;

    my @parent_md5s = keys %seen_md5;
    my @kb_features = keys %seen_feature;

    my @protein_found_in_kbase = verify_KB_has_ProteinSequence($CDMIO, \@parent_md5s);

    foreach ( @protein_found_in_kbase ) { $md5_in_kbase{$_} = 1; }

    my @not_in_kbase = grep { ! $md5_in_kbase{$_} } @parent_md5s;
    my @new_proteins = gjoseqlib::read_fasta("$dir/NewProteinSequence.fasta") if -s "$dir/NewProteinSequence.fasta";

    if (@new_proteins < @not_in_kbase) {
        printf MESSAGE "ERROR: ContainsAlignedProtein.tab contains %d new protein sequences, but NewProteinSequence.fasta provides only %d.\n", scalar@not_in_kbase, scalar@new_proteins;
        $success = 0; next;
    }

    # Verify the kb_feature_ids are registered

    my $feature_in_kbase = $CDMIO->get_entity_Feature(\@kb_features, []) if @kb_features;
    my @bad_features = grep { !$feature_in_kbase->{$_} } @kb_features;
    
    if (@bad_features) {
        print MESSAGE "ERROR: ContainsAlignedProtein.tab: found unregistered KBase feature IDs: \n";
        print MESSAGE map { "    $_\n" } @bad_features;
        $success = 0;
    }
    
    push @load_recipes, [ $stage, $tmpfile, 'ContainsAlignedProtein',
                          { from_link => 0, index_in_concatenation => 1,
                            to_link => 2, beg_pos_in_parent => 3,
                            end_pos_in_parent => 4, parent_seq_len => 5,
                            beg_pos_aln => 6, end_pos_aln => 7,
                            kb_feature_id => [8, 'copy', ''] } ];  # make the null string the default value


    # Input: ContainsAlignedNucleotides.tab, NewContigSequence.fasta
    # Table: ContainsAlignedDNA
    # Temp:  ContainsAlignedNucleotides.tmp

    if (-s "$dir/ContainsAlignedNucleotides.tab") {
        my $fname   = "ContainsAlignedNucleotides.tab"; 
        my $tmpfile = "ContainsAlignedNucleotides.tmp";
        my $fh      = IO::File->new("$stage/$tmpfile", "w");
        my $line    = 0;
        my (%seen_md5, %seen_feature);

        open(F, "<$dir/$fname") or die "Could not open $dir/$fname.";
        while (<F>) {
            chomp; $line++;
            my @fields = split /\t/;
            my ($kb_aln_id, $aln_row_number, $parent_seq_id, $kb_feature_id) = @fields[0..1, 3, 9];        
            my $id    = "$kb_aln_id.$aln_row_number";

            $seen_md5{$parent_seq_id}++;
            $seen_feature{$kb_feature_id}++ if $kb_feature_id;

            print $fh join("\t", $id, @fields[2..9])."\n";
        }
        close(F);


        # Verify the parent MD5s exist in KBase or the NewContigSequence.fasta file

        my %md5_in_kbase;

        my @parent_md5s = keys %seen_md5;
        my @kb_features = keys %seen_feature;

        my @contig_found_in_kbase = verify_KB_has_ContigSequence($CDMIO, \@parent_md5s);

        foreach ( @contig_found_in_kbase ) {
            $md5_in_kbase{$_} = 1;
        }

        my @not_in_kbase = grep { ! $md5_in_kbase{$_} } @parent_md5s;
        my @new_contigs = gjoseqlib::read_fasta("$dir/NewContigSequence.fasta") if -s "$dir/NewContigSequence.fasta";

        if (@new_contigs < @not_in_kbase) {
            printf MESSAGE "ERROR: ContainsAlignedNucleotides.tab contains %d new contigu sequences, but NewNucleotideSequence.fasta provides only %d.\n", scalar@not_in_kbase, scalar@new_contigs;
            $success = 0; next;
        }

        # Verify the kb_feature_ids are registered

        my $feature_in_kbase = $CDMIO->get_entity_Feature(\@kb_features, []) if @kb_features;
        my @bad_features = grep { !$feature_in_kbase->{$_} } @kb_features;

        if (@bad_features) {
            print MESSAGE "ERROR: ContainsAlignedNucleotides.tab: found unregistered KBase feature IDs: \n";
            print MESSAGE map { "    $_\n" } @bad_features;
            $success = 0;
        }
    
        push @load_recipes, [ $stage, $tmpfile, 'ContainsAlignedDNA',
                              { from_link => 0, index_in_concatenation => 1,
                                to_link => 2, beg_pos_in_parent => 3,
                                end_pos_in_parent => 4, parent_seq_len => 5,
                                beg_pos_aln => 6, end_pos_aln => 7, kb_feature_id => 8 } ];
    }


    # Input: AlignmentSuccessor.tab
    # Table: SupersedesAlignment

    if (-s "$dir/AlignmentSuccessor.tab") {
        push @load_recipes, [ $dir, 'AlignmentSuccessor.tab', 'SupersedesAlignment',
                              { from_link => 0, to_link => 1, successor_type => 2 } ];
    }


    # Input: TreeSuccessor.tab
    # Table: SupersedesTree

    if (-s "$dir/TreeSuccessor.tab") {
        push @load_recipes, [ $dir, 'TreeSuccessor.tab', 'SupersedesTree',
                              { from_link => 0, to_link => 1, successor_type => 2 } ];
    }


    # Input: AlignmentModification.tab
    # Table: IsModifiedToBuildAlignment

    if (-s "$dir/AlignmentModification.tab") {
        push @load_recipes, [ $dir, 'AlignmentModification.tab', 'IsModifiedToBuildAlignment',
                              { from_link => 0, to_link => 1,
                                modification_type => 2, modification_value => 3 } ];
    }

    # Input: TreeModification.tab
    # Table: IsModifiedToBuildTree

    if (-s "$dir/TreeModification.tab") {
        push @load_recipes, [ $dir, 'TreeModification.tab', 'IsModifiedToBuildTree',
                              { from_link => 0, to_link => 1,
                                modification_type => 2, modification_value => 3 } ];
    }


    # Input: AlignmentAttribute.tab
    # Table: AlignmentAttribute, DescribesAlignment
    # Temp:  AlignmentAttribute.tmp

    my $fname = 'AlignmentAttribute.tab';
    if (-s "$dir/$fname") {
        my $tmpfile = "AlignmentAttribute.tmp";
        my $fh      = IO::File->new("$stage/$tmpfile", "w");
        my @attr_keys = unique_fields_in_file("$dir/$fname", 1);
        print $fh map { $_."\n" } @attr_keys;

        push @load_recipes, [ $stage, $tmpfile, 'AlignmentAttribute',
                              { id => 0 } ];

        push @load_recipes, [ $dir, 'AlignmentAttribute.tab', 'DescribesAlignment', 
                              { to_link => 0, from_link => 1, value => 2 } ];
    }


    # Input: TreeAttribute.tab
    # Table: TreeAttribute, DescribesTree
    # Temp:  TreeAttribute.tmp

    my $fname = 'TreeAttribute.tab';
    if (-s "$dir/$fname") {
        my $tmpfile = "TreeAttribute.tmp";
        my $fh      = IO::File->new("$stage/$tmpfile", "w");
        my @attr_keys = unique_fields_in_file("$dir/$fname", 1);
        print $fh map { $_."\n" } @attr_keys;

        push @load_recipes, [ $stage, $tmpfile, 'TreeAttribute',
                              { id => 0 } ];

        push @load_recipes, [ $dir, 'TreeAttribute.tab', 'DescribesTree', 
                              { to_link => 0, from_link => 1, value => 2 } ];
    }


    # Input: TreeNodeAttribute.tab
    # Table: TreeNodeAttribute, DescribesTreeNode
    # Temp:  TreeNodeAttribute.tmp

    my $fname = 'TreeAttributeNode.tab';
    if (-s "$dir/$fname") {
        my $tmpfile = "TreeAttributeNode.tmp";
        my $fh      = IO::File->new("$stage/$tmpfile", "w");
        my @attr_keys = unique_fields_in_file("$dir/$fname", 2);
        print $fh map { $_."\n" } @attr_keys;

        push @load_recipes, [ $stage, $tmpfile, 'TreeNodeAttribute',
                              { id => 0 } ];

        push @load_recipes, [ $dir, 'TreeNodeAttribute.tab', 'DescribesTreeNode', 
                              { to_link => 0, node_id => 1,
                                from_link => 2, value => 3 } ];
    }

    #
    # Total tables loaded (19) = 6 entity tables + 13 relationship tables
    #
    
    $success or die "Abort: errors found in exchange files.\n";

    (\@load_recipes, $stage);
}


sub verify_syntax
{
    my ($fname, $syntax, $fh) = @_;

    $fh ||= \*STDOUT;
    $fh->autoflush;

    my $optional = $syntax->[0] =~ /(^M)/ ? 0 : 1;
    my $format   = $syntax->[1];

    return 1 if $optional && !-s $fname;

    print $fh "Checking syntax in $fname...\n";

    my $n_fields = scalar@$format / 2;
    my $n_rows   = 0;
    my $success  = 1;
    my $line     = 0;

    my (%msg_count, %msg_line, @msgs);

    open(F, "<$fname") or die "Could not open $fname";
    while (<F>) {
        $line++;
        $n_rows++;
        my @fields = split /\t/;
        if (@fields != $n_fields) {
            my $msg = sprintf "found rows with %d fields (should be $n_fields).", scalar@fields;
            push @msgs, $msg if !$msg_count{$msg}++;
            push @{$msg_line{$msg}}, $line;
            $success = 0;
        }
    }
    close(F);

    $line = 0;
    open(F, "<$fname") or die "Could not open $fname";
    while (<F>) {
        $line++;
        chomp;
        my @fields = split /\t/;
        for (my $i = 0; $i < $n_fields; $i++) {
            my $key     = $format->[$i*2];
            my $pattern = pattern_lookup($format->[$i*2+1]);
            my $field   = $fields[$i];
            if ($field !~ /$pattern/) {
                my $readable = $pattern; $readable =~ s/^\(\?[xism-]{5}:(.*)\)$/$1/;
                my $msg = sprintf "incorrect syntax in field (%d) $key: '$field' (should match qr/$readable/).", $i+1;
                push @msgs, $msg if !$msg_count{$msg}++;
                push @{$msg_line{$msg}}, $line;
                $success = 0;
            }
        }
    }
    close(F);

    if (!$success) {
        for my $msg (@msgs) {
            if ($msg_count{$msg} == $n_rows) {
                print $fh "ERROR: $fname: all lines: $msg\n";
            } else {
                for my $line (@{$msg_line{$msg}}) {
                    print $fh "ERROR: $fname: line $line: $msg\n";
                }
            }
        }
    }

    return $success;
}


my $predefined_patterns;

sub pattern_lookup 
{
    my ($str) = @_;
    return $str if $str =~ /^\(\?[xism-]{5}:.*\)$/; # str is a user-defined pattern: qr/pattern/

    $predefined_patterns ||= { int     => qr/^-?\d+$/,             # includes negative
                               uint    => qr/^\d+$/,               # 0 and positive 
                               natural => qr/^[1-9]\d*$/,          # natural number
                               bool    => qr/^[01]$/,              # 0 or 1
                               time    => qr/^\d{10}$/,            # unix timestamp, eg, 1347648951
                               string  => qr/./,                   # string containing no whitespace 
                               text    => qr/./,                   # nonblank text
                               free    => qr/.*/,                  # free text
                               md5     => qr/^[0-9a-z]{32}$/i,     # MD5 
                               source  => qr/^(SEED|MOL(:Tree)?)$/ # TODO: should be modified to match all known sources from all_entities_Source(),
                                                                   # but all_entities_Source() currently returns invalid IDs such as '1', 'name', etc
                             };

    my $pattern = $predefined_patterns->{$str}
        or die "Regex pattern '$str' is not predefined.\n";
    
    return $pattern;
}


#-------------------------------------------------------------------------------
#
# Get unique occurrences of a field from a file
#
#  ( \@uniq_fields ) = unique_fields_in_file( $file_name, $column_number );
#
#    $column_number is 0-based.
#
#-------------------------------------------------------------------------------

sub unique_fields_in_file 
{
    my ($fname, $column) = @_;

    open(F, "<$fname") or die "Could not open $fname";
    my %seen;
    my @uniq_fields = map { $seen{$_}++ ? () : $_ } map { [ split/\t/ ]->[$column] } <F>;
    close(F);
    
    wantarray ? @uniq_fields : \@uniq_fields;
}


sub seq_summary
{
    local $_        = uc $_[0];
    my ($pre, $suf) = /^(-*)[^-].*[^-](-*)$/;
    my $beg         = length($pre) + 1;
    my $end         = length($_) - length($suf);
    
    s/[^A-Z]+//g;
#   s/U/T/g if ! /[EFILPQXZ]/;
    my $md5 = Digest::MD5::md5_hex( $_ );

    ( $beg, $end, $md5 );
}


sub verify_KB_has_ProteinSequence
{
    my ( $CDMIO, $ids ) = @_;

    my @has;
    if ( ! $CDMIO || ! $ids || ( ref($ids) ne 'ARRAY' ) )
    {
        print STDERR "ERROR: Bad arguments in call to verify_KB_has_ProteinSequence()\n";
    }
    elsif ( @$ids )
    {
        my $have = $CDMIO->get_entity_ProteinSequence( $ids, [] ) || {};
        @has = sort keys %$have;
    }

    wantarray ? @has : \@has;
}


sub verify_KB_has_ContigSequence
{
    my ( $CDMIO, $ids ) = @_;

    my @has;
    if ( ! $CDMIO || ! $ids || ( ref($ids) ne 'ARRAY' ) )
    {
        print STDERR "ERROR: Bad arguments in call to verify_KB_has_ContigSequence()\n";
    }
    elsif ( @$ids )
    {
        my $have = $CDMIO->get_entity_ContigSequence( $ids, [] ) || {};
        @has = sort keys %$have;
    }

    wantarray ? @has : \@has;
}

sub verify_KB_has_Feature
{
    my ( $CDMIO, $ids ) = @_;

    my @has;
    if ( ! $CDMIO || ! $ids || ( ref($ids) ne 'ARRAY' ) )
    {
        print MESSAGE "ERROR: Bad arguments in call to verify_KB_has_Feature()\n";
    }
    elsif ( @$ids )
    {
        my $have = $CDMIO->get_entity_Feature( $ids, [] ) || {};
        @has = sort keys %$have;
    }

    wantarray ? @has : \@has;
}

