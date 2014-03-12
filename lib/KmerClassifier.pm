package KmerClassifier;

#
# This is a SAS component
#

use Data::Dumper;
use strict;
use IPC::Run qw(run start finish pump);
use gjoseqlib;

=head1 NAME

KmerClassifier

=head1 DESCRIPTION

This package wraps a set of kmer classifier directories and provides
a unified interface to them. It is intended to be used to create 
command-line tools for use directly in the SEED as well as in the implementation
of service-based interfaces against the data.

A classifier release is a directory that contains the following files:

=over 4

=item tree.nwk

The tree from which the classifier was created.

=item groups

2-column table containing the group ids and the genome IDs that comprise the group.

=item groups.tax

2-column table containing the group ids and their corresponding taxonomy strings.

=item processing_order

File containing the names of the kmer directories in the order that processing should
occur.

=back

It also contains one or more kmer directories. Each is named with a name that
may be meaningful to the curators of the classifier and contains a directory Data
that is configured for use with the kmer_search code.

=head1 CONSTRUCTOR METHODS

=over 4

=item $classifier = KmerClassifier->new($dir)

Create a new classifier object using data from directory C<$dir>.

=back

=cut

sub new
{
    my($class, $dir) = @_;

    -d $dir or die "Classifier directory $dir does not exist";

    #
    # Check for valid classifier directory.
    #
    if (! -f "$dir/groups" || ! -f "$dir/groups.tax" || ! -f "$dir/tree.nwk")
    {
	die "Invalid classifier directory $dir";
    }

    #
    # Find kmer directories.
    #
    my @dirs;
    for my $d (<$dir/*/Data>)
    {
	my($name) = $d =~ m,([^/]+)/Data$,;
	push(@dirs, $1);
    }

    if (@dirs == 0)
    {
	die "No kmer data directories found in $dir";
    }

    my %dirs = map { $_ => 1 } @dirs;
    my @order;
    if (open(F, "<", "$dir/processing_order"))
    {
	while (<F>)
	{
	    chomp;
	    if (/(\S+)/)
	    {
		if (!$dirs{$1})
		{
		    die "Processing order file $dir/processing_order refers to nonexistent kmer dir $1";
		}
		push(@order, $1);
	    }
	}
	close(F);
    }
    else
    {
	@order = @dirs;
    }

    my $self = {
	dir => $dir,
	kmer_dirs => \@dirs,
	processing_order => \@order,
    };
    return bless $self, $class;
}

=head1 ACCESSOR METHODS

=over 4

=item $groups = $classifier->groups()

Return the list of group IDs defined in this classifier.

=cut

sub groups
{
    my($self) = @_;

    $self->load_groups();

    return $self->{groups};
}

=item $group_membership = $classifier->group_membership_hash()

Return the hash from group ID to list of members.

=cut

sub group_membership_hash
{
    my($self) = @_;
    $self->load_groups;
    return $self->{group_members};
}

=back

=head1 COMPUTATION METHODS

=over 4

=item ($bins, $missed) = $classifier->classify($in_file, $out_fh);

Classify the data in C<$in_file>. Returns a hash of bins mapping from
read ID to classified group and a list of identifiers that were not called.

If $out_fh is set, write the matching reads to that filehandle along with
the kmer-dataset name that matched. Thus each line will be of the form

    read-id set-name nhits group1-hits1 group2-hits2 group3-hits3

=cut

sub classify
{
    my($self, $in_file, $out_fh) = @_;

    my $tmp_out = File::Temp->new();

    my %bins;
    my %missed;
    for my $kname (@{$self->{processing_order}})
    {
	my $kdir = "$self->{dir}/$kname/Data";
	-d $kdir or die "Kmer directory $kdir does not exist";

	my @cmd = ("kmer_search", "-p", "-d", $kdir);
	my $tmp;

	my @pipe;
	my $file_to_process;
	if (%missed)
	{
	    $tmp = File::Temp->new();
	    $file_to_process = $tmp . "";
	    close($tmp);
	    open(TMP, ">", $file_to_process) or die "cannot write temp file $file_to_process; $!";
	    open(DNA, "<", $in_file) or die "Cannot open $in_file: $!";
	    while (my($id, $def, $seq) = gjoseqlib::read_next_fasta_seq(\*DNA))
	    {
		if ($missed{$id})
		{
		    gjoseqlib::print_alignment_as_fasta(\*TMP, [$id, $def, $seq]);
		}
	    }
	    close(TMP);
	    close(DNA);
	}
	else
	{
	    $file_to_process = $in_file;
	}
	my $h = start(\@cmd,
		      '<', $file_to_process,
		      '>pipe', \*OUT);

	%missed = ();
	while (<OUT>)
	{
	    chomp;
	    my ($id, $nk, $m1, $m2, $m3) = split /\t/;
	    my ($best, $bestn) = split ("\-", $m1);
        
	    if ($nk > 0)
	    {
		$bins{$best} ++;
		if (ref($out_fh))
		{
		    print $out_fh join("\t", $id, $kname, $nk, $m1, $m2, $m3), "\n";
		}
	    }
	    else
	    {
		$missed{$id} = 1;
	    }
	}
	close(RAW);
	finish($h);
	undef $tmp;
    }
    return (\%bins, [keys %missed]);
}

=back

=head1 UTILITY METHODS

=over 4

=item $classifier->load_groups()

Internal method to load the group membership cache.

=cut

sub load_groups
{
    my($self) = @_;
    
    return if $self->{groups};
    
    my $l = $self->{groups} = [];
    my $tax = $self->{group_tax} = {};
    my $m = $self->{group_members} = {};

    open(F, "<", "$self->{dir}/groups") or die "Cannot open $self->{dir}/groups: $!";
    while (<F>)
    {
	chomp;
	my($id, @genomes) = split(/\t/);
	push(@$l, $id);
	$m->{$id} = [@genomes];
    }
    close(F);

    open(F, "<", "$self->{dir}/groups.tax") or die "Cannot open $self->{dir}/groups.tax: $!";
    while (<F>)
    {
	chomp;
	my($id, $tax_str) = split(/\t/);
	$tax->{$id} = $tax_str;
    }
    close(F);
}

1;
