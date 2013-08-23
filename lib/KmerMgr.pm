package KmerMgr;

# This is a SAS component.

=head1 KmerMgr

The KmerMgr is the module responsible for maintaining the set of currently-available
Kmer data sets. 

We maintain a notion of the current "default" dataset, which is
assumed to be the most recent / accurate data.

The KmerMgr supports the following operations:

=over 4

=item Add a dataset.  

Takes as input the name of a directory
(e.g. /vol/figfam-prod/Release94). Verifies that the given data
directory is a contains valid Kmer data, and adds it to the list of
datasets available for use in computation.

The base name of the dataset directory is used as the name of the dataset. 

=item Remove a dataset.

Given the name of a data set, remove it from the active list

=item Get the current default dataset.

=item Set the current default data set.

=item Given a dataset name, retrieve the KmersC object that allows data analysis against that data set.

=back

Note: it is not sufficient to make these changes in any one instance
of the KmerMgr.  In a production system, there will be multiple
instances of annotation server applications which are using the kmer
database.

We have several alternatives to solve this problem.

One is to make all instances of the kmer manager listen to a common
data stream, like the central event queue used for request
distribution. This will result in more timely changes to the
individual managers, but rquires the event channel be available.

A simpler solution is to keep the state of available datasets, default
data set, etc, in a persistent database whcih supports concurrent
access. The database keeps a last-modified timestamp for the current
state. At each entry into the kmers code, a method is invoked on the
kmer mgr instance which checks the last modification date that the
instance saw with the last modified date in the database file. If
there was an update, the states of the running instance and the
database current state are reconciled.

This architecture allows the management of the kmer datasets to be
performed as a local file operation, instand of requring it to be a
network operation requiring authentication, etc. It is inhernetly a
local operation since the events triggering any changes are already
operating in side the bio computing environment. These event triggers
are tied to the kmer update process, where each time a new kmer
dataset is computed and verified we add it to the kmer mgr and set it
as the new default.

We also do housecleaning on the kmer datasets, purging them after some
point in time.

NOTE: if we are going to be doing purging, there may be issues with
RAST where a user may not be able to rerun data that was run
originally against a later-purged kmer dataset.

NOTE 2: We can do this without an explicit database. 

We will create a directory /vol/figfam-prod/ACTIVE which contains
symbolic links to the currently-active releases.

We also create a symbolic link /vol/figfam-prod/DEFAULT which links
to the current default release.

The add/remove dataset methods and the set_default method manipulate
these links. 

=head2 Methods

=head3 new

  my $mgr = KmerMgr->new(base_dir => $path)

$path defines the base directory for the figfam/Kmer releases. 

=head3 base_dir

Returns the base directory holding the Kmer data releases.

=head3 datasets

  @list = $kmgr->datasets()

Return the current list of dataset names.

=head3 add_dataset

  $kmgr->add_dataset($directory)

Add a new dataset to the set of managed datasets. 

=head3 remove_dataset($name)

Remove the named dataset from the set of managed datasets.

=head3 set_default_dataset($name)

Set the named dataset as the default dataset.

=head3 default_dataset

Return the name of the default dataset.

=head3 get_kmer_object($name)

Retrieve the KmersC analysis module for the given dataset name.


=cut

use strict;
use Kmers;
use File::Basename;
use File::stat;
use Data::Dumper;

# This is a SAS component.

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(base_dir active_dir default_path active_kmers last_scan scan_interval
			     timestamp_file last_modtime));

sub new
{
    my($class, %args) = @_;

    (my $base = $args{base_dir}) ne '' or die "KmerMgr: base_dir must be specified";
    -d $base or die "KmerMgr: base_dir $base does not exist";
    
    my $self = {
	%args,
	active_dir => "$base/ACTIVE",
	timestamp_file => "$base/ACTIVE/TIMESTAMP",
	default_path => "$base/DEFAULT",
	default_dataset => undef,
	datasets => {},
	active_kmers => {},
	last_scan => time,
	last_modtime => undef,
	scan_interval => 120,
    };

    bless $self, $class;
    $self->scan_kmers();

    return $self;
}

sub scan_kmers
{
    my($self) = @_;

    my $dh;
    if (!opendir($dh, $self->active_dir))
    {
	warn "Cannot opendir " . $self->active_dir . ": $!";
    }

    my %ds;
    my $max_release;
 RELEASE:
    while (my $p = readdir($dh))
    {
	my $path = $self->active_dir . "/" . $p;
	next unless -l $path;

	my %tables;

	my $seti_path = "$path/setI.db";
	my $fri_path = "$path/FRI.db";
	my $extra_fasta_path = "$path/extra_prok_seqs.fasta";
	undef $extra_fasta_path unless -f $extra_fasta_path;
	
	for my $pth ($seti_path, $fri_path)
	{
	    if (! -f $pth)
	    {
		warn "Skipping $p: $pth does not exist\n";
		next RELEASE;
	    }
	}
	

	if (opendir(my $mdh, "$path/Merged"))
	{
	    for my $k (sort { $a <=> $b } grep { /^\d+$/ } readdir($mdh) )
	    {
		my $kp = "$path/Merged/$k/table.binary";
		if (-f $kp)
		{
		    $tables{$k} = $kp;
		}
	    }
	    closedir($mdh);
	}
	if (%tables)
	{
	    $ds{$p} = { seti => $seti_path, fri => $fri_path, tables => \%tables, extra_fasta_path => $extra_fasta_path };
	    $max_release = $p if $p gt $max_release;
	}
    }

    #
    # Remove any active kmer datasets that are no longer valid.
    #
    my $active = $self->active_kmers;
    for my $rel (keys %$active)
    {
	if (!$ds{$rel}->{tables})
	{
	    delete $active->{$rel};
	    print STDERR "On scan, deleted active kmer $rel\n";
	}
    }

    %{$self->{datasets}} = %ds;

    my $default = readlink($self->default_path);
    
    if ($default)
    {
	$self->{default_dataset} = basename($default);
    }
    else
    {
	warn "No default found, using max $max_release\n";
	$self->{default_dataset} = $max_release;
    }
}

sub add_dataset
{
    my($self, $dir) = @_;

    if (! -d $dir)
    {
	warn "add_dataset: $dir does not exist\n";
	return;
    }
    my $name = basename($dir);

    print STDERR "Adding dataset $name\n";

    my $p = $self->active_dir . "/" . $name;
    if (my $cur = readlink($p))
    {
	if ($cur ne $dir)
	{
	    print STDERR "Retargeting existing dataset path $cur to $dir\n";
	    unlink($p);
	}
	else
	{
	    print STDERR "Dataset $name already points to $dir\n";
	    return;
	}
    }
    if (!symlink($dir, $p))
    {
	print STDERR "Failed to symlink $dir to $p: $!\n";
	return;
    }
    $self->update_timestamp_file();
    $self->scan_kmers();
}

sub remove_dataset
{
    my($self, $name) = @_;

    my $p = $self->active_dir . "/" . $name;
    
    if (my $cur = readlink($p))
    {
	print STDERR "Removing dataset $name => $cur\n";
	unlink($p);
    }
    else
    {
	print STDERR "Dataset $name does not exist\n";
	return;
    }

    if ($self->default_dataset eq $name)
    {
	unlink($self->default_path);
    }
    $self->update_timestamp_file();
    $self->scan_kmers();
}

sub datasets
{
    my($self) = @_;
    return keys %{$self->{datasets}};
}

sub set_default_dataset
{
    my($self, $name) = @_;

    my $p = $self->active_dir . "/" . $name;

    my $cur = readlink($p);

    if (!$cur)
    {
	print STDERR "set_default_dataset: $name is not a valid dataset\n";
	return;
    }

    my $cur_def = readlink($self->default_path);
    if ($cur_def)
    {
	unlink($self->default_path);
    }
    if (!symlink($p, $self->default_path))
    {
	print STDERR "Failure to symlink $p to " . $self->default_path . ":  $!";
    }

    $self->update_timestamp_file();
    $self->scan_kmers();
	
}

sub default_dataset
{
    my($self) = @_;
    $self->check_scan();
    return $self->{default_dataset};
}

sub check_scan
{
    my($self) = @_;

    #
    # If it has been scan_interval seconds since the last time we checked,
    # see if the timestamp file has been updated. If it has do a full scan
    # of the kmers dirs. Otherwise reset the last-check time.
    #
    
    my $now = time;
    if (($now - $self->last_scan) > $self->scan_interval)
    {
	my $mod = stat($self->timestamp_file);
	print STDERR "checkscan mod $mod " . ($mod ? $mod->mtime : "?") . "\n";
	if (!$mod || $mod->mtime > $self->last_modtime)
	{
	    print STDERR "checkscan do scan\n";
	    $self->scan_kmers();
	}
	$self->last_scan($now);
    }
}

sub update_timestamp_file
{
    my($self, $now) = @_;

    $now ||= time;

    unlink($self->timestamp_file);
    if (open(my $fh, ">", $self->timestamp_file))
    {
	print $fh "$now\n";
	close($fh);
    }
    else
    {
	warn "Cannot write " . $self->timestamp_file . ": $!";
    }
}

sub get_default_kmer_object
{
    my($self) = @_;

    my $def = $self->default_dataset;
    return $self->get_kmer_object($def);
}

sub get_active_datasets
{
    my($self) = @_;

    my $res = {};
    for my $name (sort { $a cmp $b } keys %{$self->{datasets}})
    {
	$res->{$name} = [ sort { $a <=> $b } keys %{$self->{datasets}->{$name}->{tables}} ];
    }
    return [$self->default_dataset, $res];
}

sub get_kmer_object
{
    my($self, $name) = @_;

    if (my $cur = $self->active_kmers->{$name})
    {
	return $cur;
    }

    my $info = $self->{datasets}->{$name};
    if (!$info || !$info->{tables})
    {
	die "No kmers available for $name\n";
    }

    my $kmer_obj = Kmers->new(-frIdb => $info->{fri},
			  -setIdb => $info->{seti},
			  -table => $info->{tables});

    $self->active_kmers->{$name} = $kmer_obj;
    return $kmer_obj;
}

sub get_extra_fasta_path
{
    my($self, $name) = @_;
    my $p = $self->{datasets}->{$name}->{extra_fasta_path};
    return $p;
}


1;
