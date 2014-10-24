use strict;
use DBI;
use FIG;
use Data::Dumper;
use File::Basename;
use File::Temp 'tempfile';

my $fig = FIG->new();

#
# Load precomputed specialty gene data into the cache database.
#

my $cache_db = 'specialty_gene_cache';
my $cache_host = 'seed-db-write.mcs.anl.gov';
my $cache_user = 'seed';
my $cache_pass;

my $dbh = DBI->connect("dbi:mysql:$cache_db;host=$cache_host", $cache_user, $cache_pass, { mysql_local_infile => 1 } );
$dbh or die "Error connecting: " . DBI->errstr;

my %dbs;

#
# This code reads the non-description form as that is what we've computed.
#

my $sth = $dbh->prepare(qq(INSERT INTO specialty_gene
			   (query_md5, database_name, sub_id, query_coverage, sub_coverage, identity, p_value)
			   VALUES (?, ?, ?, ?, ?, ?, ?)));

my $sth_miss = $dbh->prepare(qq(INSERT INTO specialty_gene
			   (query_md5, database_name, sub_id)
			   VALUES (?, ?, NULL)));

# QID	Database	SubID	QueryCoverage	SubCoverage	Identity	P-Value

#
# First cache what we already have.
#

#
# Collect MD5 mappings of all pegs we are loading.
#
my %peg_to_md5;

for my $file (@ARGV)
{
    my $g = basename($file);
    if ($g !~ /^\d+\.\d+$/)
    {
	print STDERR "Skip $file\n";
	next;
    }
    open(F, "<", $file) or die "Cannot open $file: $!";

    my $l = <F>;

    my @pegs;
    while (defined($l = <F>))
    {
	my($qid, $db, $subid, $qcov, $scov, $iden, $pv) = split(/\t/, $l);

	push(@pegs, $qid);
    }
    close(F);

    my $md5s = $fig->md5_of_peg_bulk(\@pegs);
    $peg_to_md5{$_} = $md5s->{$_} foreach keys %$md5s;
}

my %seen;
print "Load cache\n";
{
    my %md5;
    $md5{$_} = 1 foreach values %peg_to_md5;
    my @md5s = keys %md5;
    
    while (@md5s)
    {
	my @chunk = splice(@md5s, 0, 1000);

	my $q = join(",", map { '?' } @chunk);
	my $xsth = $dbh->prepare(qq(SELECT query_md5, database_name FROM specialty_gene
				    WHERE query_md5 IN ($q)),
			     { "mysql_use_result" => 1});
	$xsth->execute(@chunk);
	while (my $row = $xsth->fetchrow_arrayref())
	{
	    $seen{$row->[0], $row->[1]} = 1;
	}
    }
}

my %genomes;

for my $file (@ARGV)
{
    my $g = basename($file);
    if ($g !~ /^\d+\.\d+$/)
    {
	print STDERR "Skip $file\n";
	next;
    }
    $genomes{$g} = 1;
    open(F, "<", $file) or die "Cannot open $file: $!";

    my $l = <F>;

    print STDERR "Load $file\n";

    while (defined($l = <F>))
    {
	my($qid, $db, $subid, $qcov, $scov, $iden, $pv) = split(/\t/, $l);
	if (!$db)
	{
	    if ($subid =~ /^([^|]+)\|/)
	    {
		$db = $1;
	    }
	}
	
	my $md5 = $peg_to_md5{$qid};
	if ($pv eq '')
	{
	    warn "Bad line $. of $file\n";
	    next;
	}
	if (!$md5)
	{
	    warn "No md5 for $qid\n";
	    next;
	}
	$dbs{$db}++;
	if (!$seen{$md5, $db})
	{
	    $sth->execute($md5, $db, $subid, $qcov, $scov, $iden, $pv);
	    $seen{$md5, $db}++;
	}
    }
}

my($load_fh, $load_file) = tempfile();
print "Creating $load_file\n";

for my $g (sort { FIG::by_genome_id($a, $b) } keys %genomes)
{
    my @pegs = $fig->pegs_of($g);
    my $md5s = $fig->md5_of_peg_bulk(\@pegs);

    for my $peg (@pegs)
    {
	my $md5 = $md5s->{$peg};
	if (!$md5)
	{
	    warn "No md5 for $peg\n";
	    next;
	}
	for my $db (keys %dbs)
	{
	    if (!$seen{$md5, $db})
	    {
		print $load_fh "$md5\t$db\n";
		$seen{$md5, $db} = 1;
	    }
	}
    }
}
close($load_fh);

print "Loading $load_file\n";
$dbh->do("LOAD DATA LOCAL INFILE '$load_file' INTO TABLE specialty_gene (query_md5, database_name)");


