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

=head1 Codon Usage Load Script for CDMI

    CDMILoadCodonUsage [options] <dir>

=head2 Introduction

This script processes codon usage data files and loads them
into the Kbase Central Data Model.

=over 4

=item CodonUsage.tab

Each record in this file represents an instance of the B<CodonUsage>
entity that has a preallocated KBase ID in the form of "kb|cu.xxx".
The fields are:

  (0) kb-cu-id (id)
  (1) frequencies
  (2) genetic-doe
  (3) type
  (4) subtype

=item UsesCodons.tab

Each record in this file represents an instance of the B<UsesCodons>
relationship connecting B<Genome> and B<CodonUsage>. The fields are:

  (0) kb-genome-id (from-link)
  (1) kb-cu-id     (to-link)

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

my $clear;
my $dry;

my $cdmi   = Bio::KBase::CDMI::CDMI->new_for_script(clear => \$clear, dry => \$dry);
my $loader = Bio::KBase::CDMI::CDMILoader->new($cdmi);

my $dir = shift @ARGV;
   $dir or die "No input directory specified.";
-d $dir or die "Invalid input directory $dir.";

my ($load_recipes, $stage) = validate_exchange( -dir => $dir );

my @tables = map { $_->[2] } @$load_recipes;
# print "Tables = ". join(", ", @tables) . "\n"; exit;

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
        ( 'CodonUsage.tab' => [ 'Mandatory',
                                [ kb_cu_id     => qr/^kb\|cu\.\d+$/,
                                  frequencies  => qr/^[.0-9,|]+$/,
                                  genetic_code => 'uint',
                                  type         => qr/^(average|modal|high-expression|nonnative)$/,
                                  subtype      => qr/^\d*$/ ] ],

          'UsesCodons.tab' => [ 'Mandatory',
                                [ kb_genome_id => qr/^kb\|g\.\d+$/,
                                  kb_cu_id     => qr/^kb\|cu\.\d+$/ ] ]
                                  
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


    # Input: CodonUsage.tab
    # Table: CodonUsage

    # Verify the kb_cu_ids are registered with KBase

    my @kb_cu_ids     = unique_fields_in_file("$dir/CodonUsage.tab", 0);
    my $extern_cu_ids = $IDserverO->kbase_ids_to_external_ids(\@kb_cu_ids);
    my @bad_cu_ids   = grep { ! $extern_cu_ids->{$_} } @kb_cu_ids;

    if (@bad_cu_ids) {
        print MESSAGE "ERROR: CodonUsage.tab: found unregistered KBase Codon Usage IDs: \n";
        print MESSAGE map { "    $_\n" } @bad_cu_ids;
        $success = 0;
    }

    push @load_recipes, [ $dir, 'CodonUsage.tab', 'CodonUsage',
                          { id => 0, frequencies => 1, genetic_code => 2, type => 3,
                            subtype => [ 4, 'copy', '' ] } ];

    # Input: UsesCodons.tab
    # Table: UsesCodons

    # Verify the kb_genome_ids are registered with KBase

    my @kb_genome_ids     = unique_fields_in_file("$dir/UsesCodons.tab", 0);
    my $extern_genome_ids = $IDserverO->kbase_ids_to_external_ids(\@kb_genome_ids);
    my @bad_genome_ids   = grep { ! $extern_genome_ids->{$_} } @kb_genome_ids;

    if (@bad_genome_ids) {
        print MESSAGE "ERROR: UsesCodons.tab: found unregistered KBase Genome IDs: \n";
        print MESSAGE map { "    $_\n" } @bad_genome_ids;
        $success = 0;
    }

    push @load_recipes, [ $dir, 'UsesCodons.tab', 'UsesCodons',
                          { from_link => 0, to_link => 1 } ];

    #
    # Total tables (2) = 1 entity tables + 1 relationship tables
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
