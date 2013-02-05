use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

representative_sequences

=head1 SYNOPSIS

representative_sequences [arguments] < input > output

=head1 DESCRIPTION

Example:

    representative_sequences [arguments] < input > output

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: representative_sequences [arguments] < input > output


    --e string
    --o string
    -c num        Select the identifier from column num
    --d string
    --f string
    --m integer
    --s value

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use SeedUtils;

our $usage = "usage: representative_sequences [arguments] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $existing;
my $order;
my $b_arg;
my $cluster_alg;
my $clusterD;
my $clusterF;
my $simM;
my $sim_cutoff;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('e=s' => \$existing,
						       'o=s' => \$order,
						       'b'   => \$b_arg,
						       'c=i' => \$cluster_alg,
						       'd=s' => \$clusterD,
						       'f=s' => \$clusterF,
						       'm=i' => \$simM,
						       's=f' => \$sim_cutoff);
if (! $kbO) { print STDERR $usage; exit }
my $options = {};
my @existing_seed;
if ($existing)
{
    if (! (-s $existing))
    {
	print STDERR "The file of existing representatives does not exist\n";
	print STDERR $usage;
	exit;
    }
    @existing_seed = &gjoseqlib::read_fasta($existing);
    $options->{existing_reps} = \@existing_seed;
}

if ($b_arg)
{
    $options->{order} = 1;  # 1 means "long-to-short"
}
if ($order)
{
    $options->{order} = $order;
}
if ($cluster_alg)          { $options->{alg} = $cluster_alg }
if ($simM)                 { $options->{type_sim} = $simM   }
if ($sim_cutoff)           { $options->{cutoff} = $sim_cutoff   }
my $fasta = &gjoseqlib::read_fasta;
my %to_seq = map { $_->[0] => $_ } @$fasta;
my($reps,$clusters) = $kbO->representative_sequences($fasta,$options);
my @fasta_reps = map { $to_seq{$_} } @$reps;
&gjoseqlib::print_alignment_as_fasta(\@fasta_reps);
if ($clusterD)
{
    my $file = "group000001";
    (-d $clusterD) || mkdir($clusterD,0777) || die "could not make $clusterD";
    foreach my $clust (sort { @$b <=> @$a } @$clusters)
    {
	my @fasta_cluster = map { $to_seq{$_} } @$clust;
	&gjoseqlib::print_alignment_as_fasta("$clusterD/$file",\@fasta_cluster);
	$file++;
    }
}

if ($clusterF)
{
    open(CLUSTERS,">",$clusterF) || die "could not open $clusterF";
    foreach my $clust (sort { @$b <=> @$a } @$clusters)
    {
	print CLUSTERS join("\t",@$clust),"\n";
    }
    close(CLUSTERS);
}

__DATA__
