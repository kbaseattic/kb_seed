use strict;
use Data::Dumper;
use Getopt::Long;
use SeedEnv;

#
# This is a SAS Component
#


=head1 svr_sphinx_indexing

Use sphinx indexes to match a keyword query (returning a table [peg,weight,annotation]
By default it returns PEGs from pubSEED.  The -c option supports coreSEED instead.
------

Example:

    svr_sphinx_indexing -k 'ribosomal protein streptococcus s1p'

would produce a 3-column table.  The first column would contain
PEG IDs for genes that somehow matched the keywords.

=head2 Command-Line Options

=over 4

=item -k keywords

Make sure you enclose the list of keywords with apostrophes

=item -c

Use coreSEED, rather than pubSEED

=back

=head2 Output Format

The standard output is a 3-column tab-delimited file. 

    column 1:  a PEG ID
    column 2:  a weight (the higher, the more solid the match)					     
    column 3:  the annotation stored in the indexes (it may be out of date)

=cut


use Sphinx::Search;
use SeedSearch;

my $usage = "usage: svr_sphinx_indexing [-c] -k Keywords\n";
my $coreseed = 0;
my $keywords = '';

my $rc  = GetOptions('c'   => \$coreseed,
		     'k=s' => \$keywords);
if ((! $rc) || (! $keywords))
{ 
    print STDERR $usage; exit ;
}

my @params;
if ($coreseed)
{
    @params = ("aspen.mcs.anl.gov", 9312);
}
else
{
    @params = ("birch.mcs.anl.gov", 9312);
}
my $sphinx = Sphinx::Search->new();
$sphinx->SetServer(@params);
my @indexes = qw(feature_all_index);

my $page_start = 1;
my $page_size = 1000;  # you get back a max of 999 entries in any event
$sphinx->SetLimits($page_start, $page_size);
for my $idx (@indexes)
{
    $sphinx->AddQuery($keywords, $idx);
}
my $ret = $sphinx->RunQueries();
my $feature_out = $ret->[0];
my $n_found = $feature_out->{total_found};
for my $match (@{$feature_out->{matches}})
{
    my $anno = $match->{annotation};
    my $weight = $match->{weight};
    my $peg = SeedSearch::docid_to_fid($match->{doc});
    print "$peg\t$weight\t$anno\n";
}
