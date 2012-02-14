package GenomeSetDB;

#
# Manage genome sets using a sqlite database.
#

use strict;
use Data::Dumper;
use DBI;
use Data::UUID;
use GenomeSet;
use Cwd 'abs_path';

use Moose;
use MooseX::Params::Validate;

has 'database_file' => (isa => 'Str', is => 'ro', required => 1);

has 'dbh' => (isa => 'DBI::db', is => 'ro', lazy => 1, builder => '_build_dbh');

has 'uuidgen' => (isa => 'Data::UUID', is => 'ro', lazy => 1,
		  default => sub { new Data::UUID });

sub _build_dbh
{
    my($self) = @_;
    my $dbh = DBI->connect("dbi:SQLite:" . $self->database_file);
    return $dbh;
}

sub enumerate
{
    my($self) = @_;

    my $res = $self->dbh->selectall_arrayref(qq(SELECT id, name
						FROM genome_set));
    my @out;
    for my $ent (@$res)
    {
	my ($id, $name) = @$ent;
	push(@out, GenomeSet->new(id => $id, name => $name, db => $self));
    }
    return @out;
}

sub get_set
{
    my($self, $id) = @_;

    my $res = $self->dbh->selectall_arrayref(qq(SELECT id, name
						FROM genome_set
						WHERE id = ?), undef, $id);
    if (@$res)
    {
	my ($id, $name) = @{$res->[0]};
	return GenomeSet->new(id => $id, name => $name, db => $self);
    }
    return undef;
}

sub create_set
{
    my($self, $name) = @_;

    my $id = $self->uuidgen->create_str();
    $self->dbh->do(qq(INSERT INTO genome_set (id, name)
		      VALUES (?, ?)), undef, $id, $name);
    return GenomeSet->new(id => $id, name => $name, db => $self);
}

sub delete_set
{
    my($self, $id) = @_;

    $self->dbh->do(qq(DELETE FROM genome_set_entry WHERE genome_set_id = ?), undef, $id);
    $self->dbh->do(qq(DELETE FROM feature_set_entry WHERE genome_set_id = ?), undef, $id);
    $self->dbh->do(qq(DELETE FROM feature_aux_data WHERE genome_set_id = ?), undef, $id);
    $self->dbh->do(qq(DELETE FROM genome_set WHERE id = ?), undef, $id);
}

#
# Load the genome set entries and peg mappings from a pangenome directory.
#
sub create_set_from_pangenome
{
    my($self, $pg_dir) = @_;

    my $path = abs_path($pg_dir);
    my $fh;
    open($fh, "<", "$pg_dir/pg.genomes") or die "Cannot open genomes file $pg_dir/pg.genomes: $!";
    my @genomes;
    my $idx = 0;
    while (<$fh>)
    {
	if (my($g) = /^(\d+\.\d+)$/)
	{
	    push(@genomes, [$g, 0, $idx]);
	}
	elsif (/^(\d+)?\t(\d+\.\d+)$/)
	{
	    push(@genomes, [$2, ($1 ? $1 : 0), $idx]);
	}
	else
	{
	    die "Bad line $. in $pg_dir/pg.genomes file\n";
	}
    }
    close($fh);

    @genomes = sort { $b->[1] <=> $a->[1] or $a->[2] <=> $b->[2] } @genomes;

    my $mappings = "$pg_dir/pg.sets";
    if (! -f $mappings)
    {
	die "peg mapping file $mappings does not exist";
    }

    my $name = "pangenome from $path";
    if (open(my $nfh, "<", "$pg_dir/NAME"))
    {
	$name = <$nfh>;
	chomp $name;
	close($nfh);
    }
    
    my $set = $self->create_set($name);
    $set->add_genome(@$_) foreach @genomes;

    #
    # Load the mappings.
    #
    $set->load_feature_sets($mappings);

    #
    # Load the alignment data.
    #
    for my $genome (@genomes)
    {
	my($genome, $ref) = @$genome;
	my $gdir = "$pg_dir/Genomes/$genome";
	my $snpdir = "$gdir/Features/snp";
	my $map = "$snpdir/snp2ali";

	if (open(my $mfh, "<", $map))
	{
	    my $sth = $self->dbh->prepare(qq(INSERT INTO feature_aux_data (genome_set_id, feature_id, data_type, data_tag, data)
					     VALUES (?, ?, 'alignment', ?, ?)));
					     
	    while (<$mfh>)
	    {
		chomp;
		my($fid, $ali_name, @dat) = split(/\t/);
		my $tag;
		my($type) = $ali_name =~ /\.(\w+)$/;
		if (@dat == 1)
		{
		    $tag = "of $type in feature $dat[0]";
		}
		elsif (@dat == 2)
		{
		    $tag = "of $type between features $dat[0] and $dat[1]";
		}
		    
		my $ali = "$snpdir/Alignments/$ali_name";
		if (open(my $ali_fh, "<", $ali))
		{
		    local $/;
		    my $txt = <$ali_fh>;
		    $sth->execute($set->id, $fid, $tag, $txt);
		}
	    }
	}
    }
    return $set;
}



sub init_schema
{
    my($self) = @_;
    my $dbh = $self->dbh;
    $dbh->do(qq(CREATE TABLE genome_set
		(
		 id VARCHAR(40) PRIMARY KEY,
		 name VARCHAR(255),
		 set_type VARCHAR(255)
		 )));
    $dbh->do(qq(CREATE INDEX genome_set_name ON genome_set(name)));
    $dbh->do(qq(
		CREATE TABLE genome_set_entry
		(
		 genome_set_id VARCHAR(40),
		 idx INTEGER,
		 is_reference BOOL,
		 genome_id VARCHAR(40),
		 PRIMARY KEY (genome_set_id, idx)
		 )));
    $dbh->do(qq(CREATE INDEX genome_set_entry_genome_id ON genome_set_entry(genome_id)));
    $dbh->do(qq(CREATE TABLE feature_set_entry
		(
		 genome_set_id VARCHAR(40),
		 feature_set_id INTEGER,
		 feature_id VARCHAR(128)
		 )));
    $dbh->do(qq(CREATE INDEX fse_fid ON feature_set_entry(genome_set_id, feature_id)));
    $dbh->do(qq(CREATE INDEX fse_fsid ON feature_set_entry(genome_set_id, feature_set_id)));

    #
    # Tables to support auxiliary data associated with pegs.
    # This auxiliary data is bound to a particular genome set, and will
    # thus only appear when that set is being viewed.
    #
    $dbh->do(qq(CREATE TABLE feature_aux_data
		(
		 genome_set_id VARCHAR(40),
		 feature_id VARCHAR(128),
		 data_type VARCHAR(32),
		 data_tag VARCHAR(255),
		 data TEXT
		 )));
    $dbh->do(qq(CREATE INDEX feature_aux_data_ix1 ON feature_aux_data(genome_set_id, feature_id)));
		 
}
		 

1;
