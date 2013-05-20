#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;
use Data::Dumper;

use Bio::KBase::CDMI::Client;

############
#
# CONFIGURE THESE
#
#my $url         = 'http://140.221.92.46:5000';
use lib "t/server-tests";
use CDMITestConfig qw(getHost getPort);

use JSON -support_by_pp;

my $host=getHost(); my $port=getPort();
print "-> attempting to connect to:'".$host.":".$port."'\n";
my $cdmi  = Bio::KBase::CDMI::Client->new($host.":".$port);

#check that basic tables are included, not an exhaustive test so it doesn't
#break on future database changes

my $allent = $cdmi->all_entities();
my %allenth = map {$_ => 1} @$allent;

ok($allenth{'Genome'}, 'Genome entity exists');
ok($allenth{'Contig'}, 'Contig entity exists');


my $allrel = $cdmi->all_relationships();
my %allrelh = map {$_ => 1} @$allrel;

ok($allrelh{'IsLocatedIn'}, 'IsLocatedIn relationship exists');
ok($allrelh{'IsLocusFor'}, 'IsLocusFor relationship exists');

my $nada = $cdmi->get_entity(['foo']);
is_deeply($nada, {}, 'Invalid entity name returns empty DS');

my $pub = $cdmi->get_entity(['foo', 'Publication']);

my $expected = {
          'Publication' => {
                             'fields' => {
                                           'link' => {
                                                       'notes' => 'URL of the article, DOI preferred',
                                                       'name' => 'link',
                                                       'type' => 'string'
                                                     },
                                           'pubdate' => {
                                                          'notes' => 'publication date of the article',
                                                          'name' => 'pubdate',
                                                          'type' => 'date'
                                                        },
                                           'id' => {
                                                     'notes' => 'Unique identifier for this [b]Publication[/b].',
                                                     'name' => 'id',
                                                     'type' => 'string'
                                                   },
                                           'title' => {
                                                        'notes' => 'title of the article, or (unknown) if the title is not known',
                                                        'name' => 'title',
                                                        'type' => 'string'
                                                      }
                                         },
                             'name' => 'Publication',
                             'relationships' => [
                                                  [
                                                    'PublishedProtocol',
                                                    'Protocol'
                                                  ],
                                                  [
                                                    'Concerns',
                                                    'ProteinSequence'
                                                  ],
                                                  [
                                                    'PublishedExperiment',
                                                    'ExperimentMeta'
                                                  ]
                                                ]
                           }
        };


is_deeply($pub, $expected, 'Check publication entity');

$nada = $cdmi->get_relationship(['foo']);
is_deeply($nada, {}, 'Invalid relationship name returns empty DS');

my $ili = $cdmi->get_relationship(['foo', 'IsLocatedIn']);

$expected = {
          'IsLocatedIn' => {
                             'to_entity' => 'Contig',
                             'real_table' => 1,
                             'fields' => {
                                           'len' => {
                                                      'notes' => 'Length of this segment.',
                                                      'name' => 'len',
                                                      'type' => 'int'
                                                    },
                                           'ordinal' => {
                                                          'notes' => 'Sequence number of this segment, starting from 1 and proceeding sequentially forward from there.',
                                                          'name' => 'ordinal',
                                                          'type' => 'int'
                                                        },
                                           'to-link' => {
                                                          'notes' => '[b]id[/b] of the target [b][link #Contig]Contig[/link][/b].',
                                                          'name' => 'to-link',
                                                          'type' => 'string'
                                                        },
                                           'begin' => {
                                                        'notes' => 'Index (1-based) of the first residue in the contig that belongs to the segment.',
                                                        'name' => 'begin',
                                                        'type' => 'int'
                                                      },
                                           'from-link' => {
                                                            'notes' => '[b]id[/b] of the source [b][link #Feature]Feature[/link][/b].',
                                                            'name' => 'from-link',
                                                            'type' => 'string'
                                                          },
                                           'dir' => {
                                                      'notes' => 'Direction (strand) of the segment: "+" if it is forward and "-" if it is backward.',
                                                      'name' => 'dir',
                                                      'type' => 'char'
                                                    }
                                         },
                             'name' => 'IsLocatedIn',
                             'from_entity' => 'Feature',
                             'converse' => 'IsLocusFor'
                           }
        };

is_deeply($ili, $expected, 'Correct IsLocatedIn information');

my $ilf = $cdmi->get_relationship(['foo', 'IsLocusFor']);

#print Dumper($ilf);

$expected = {
          'IsLocusFor' => {
                            'to_entity' => 'Feature',
                            'real_table' => 0,
                            'fields' => {
                                          'len' => {
                                                     'notes' => 'Length of this segment.',
                                                     'name' => 'len',
                                                     'type' => 'int'
                                                   },
                                          'ordinal' => {
                                                         'notes' => 'Sequence number of this segment, starting from 1 and proceeding sequentially forward from there.',
                                                         'name' => 'ordinal',
                                                         'type' => 'int'
                                                       },
                                          'to-link' => {
                                                         'notes' => '[b]id[/b] of the source [b][link #Feature]Feature[/link][/b].',
                                                         'name' => 'to-link',
                                                         'type' => 'string'
                                                       },
                                          'begin' => {
                                                       'notes' => 'Index (1-based) of the first residue in the contig that belongs to the segment.',
                                                       'name' => 'begin',
                                                       'type' => 'int'
                                                     },
                                          'from-link' => {
                                                           'notes' => '[b]id[/b] of the target [b][link #Contig]Contig[/link][/b].',
                                                           'name' => 'from-link',
                                                           'type' => 'string'
                                                         },
                                          'dir' => {
                                                     'notes' => 'Direction (strand) of the segment: "+" if it is forward and "-" if it is backward.',
                                                     'name' => 'dir',
                                                     'type' => 'char'
                                                   }
                                        },
                            'name' => 'IsLocusFor',
                            'from_entity' => 'Contig',
                            'converse' => 'IsLocatedIn'
                          }
        };

is_deeply($ilf, $expected, 'Correct IsLocusFor information');

done_testing();
