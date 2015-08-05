use Data::Dumper;
eval {
    require FIG_Config;
};
use File::Basename;
use strict;
use IPC::Run 'run';
use Getopt::Long::Descriptive;
use File::Temp 'tempfile';
use gjoseqlib;
use Bio::SearchIO;
use Digest::MD5 'md5_hex';
use DBI;

my $default_db_dir;
$default_db_dir = $FIG_Config::specialty_genes_database if $FIG_Config::specialty_genes_database;

my $cache_db = $FIG_Config::specialty_genes_cache_db;
my $cache_host = $FIG_Config::specialty_genes_cache_dbhost;
my $cache_user = $FIG_Config::specialty_genes_cache_dbuser;
my $cache_pass = $FIG_Config::specialty_genes_cache_dbpass;

my ($opt, $usage) = describe_options("%c %o",
				     ["in|i=s", "Input data file"],
				     ["out|o=s", "Output file"],
				     ["report|r=s", "Raw BLAST output file"],
				     ["description=s", "Show descriptions", { default => 'N' }],
				     ["db=s@", "Database name"],
				     ["db-dir=s", "Database directory", { default => $default_db_dir}],
				     ["filter=s", "Filter outputs (Y or N)", { default => 'Y' }],
				     ["evalue=s", "Base evalue to use for analysis", { default => 0.0001 }],
				     ["parallel=i", "Number of threads to use", { default => 1 }],
				     ["no-cache", "Disable cache"],
				     ["cache-db=s", "Name of cache database"],
				     ["cache-host=s", "Name of cache host"],
				     ["cache-user=s", "Name of cache user"],
				     ["cache-pass=s", "Name of cache password"],
				     ["help|h", "Print this help message"],
				    { show_defaults => 1 });

print($usage->text), exit if $opt->help;
print($usage->text), exit 1 if (@ARGV != 0);

$cache_db = $opt->cache_db || $cache_db;
$cache_host = $opt->cache_host || $cache_host;
$cache_user = $opt->cache_user || $cache_user;
$cache_pass = $opt->cache_pass || $cache_pass;

my $sth;
my $sth_miss;
my $dbh;
if (!$opt->no_cache)
{
    $dbh = DBI->connect("dbi:mysql:$cache_db;host=$cache_host", $cache_user, $cache_pass);
    $dbh or die "Error connecting: " . DBI->errstr;

    $sth = $dbh->prepare(qq(INSERT INTO specialty_gene
			   (query_md5, database_name, sub_id, query_coverage, sub_coverage, identity, p_value)
			   VALUES (?, ?, ?, ?, ?, ?, ?)));

    $sth_miss = $dbh->prepare(qq(INSERT INTO specialty_gene
				 (query_md5, database_name, sub_id)
				 VALUES (?, ?, NULL)));
}

my $db_dir = $opt->db_dir;

$db_dir or die "Database directory must be specified.\n";
-d $db_dir or die "Database directory $db_dir not found.\n";

my $in_file = $opt->in;
$in_file or die "Input file not specified.\n";
-f $in_file or die "Input file $in_file not found.\n";

my $out = $opt->out;
my $out_fh;
if ($out)
{
    open($out_fh, ">", $out) or die "Cannot write output file $out: $!";
}
else
{
    $out_fh = \*STDOUT;
}

my @db = @{$opt->db || []};

#
# Enumerate available databases;
#

my @avail_dbs = <$db_dir/*.faa>;
my @avail_names = map { basename($_, '.faa') } @avail_dbs;
my %avail_names = map { $_ => 1 } @avail_names;

if (@db == 0 || grep { $_ eq 'all' } @db)
{
    @db = @avail_names;
}
else
{
    my @err;
    for my $d (@db)
    {
	if (!$avail_names{$d})
	{
	    push @err, "Database $d is not available\n";
	    next;
	}
    }
    die join("", @err) if @err;
}

my $raw_blast;
my $raw_blast_fh;
if ($opt->report)
{
    $raw_blast = $opt->report;
    open($raw_blast_fh, ">". $raw_blast) or die "Cannot write $raw_blast: $!";
}
else
{
    ($raw_blast_fh, $raw_blast) = tempfile();
}

#
# Make a pass over the input file collecting MD5s of the proteins.
#

open(IN, "<", $in_file) or die "Cannot open $in_file: $!";

my %md5;
my %id_to_md5;
my @ids;
while (my($id, $def, $seq) = read_next_fasta_seq(\*IN))
{
    my $md5 = md5_hex($seq);
    $id_to_md5{$id} = $md5;
    $md5{$md5}->{$id} = 1;
    push(@ids, $id);
}
close(IN);

my %val;
if (%md5 && @db)
{
    my @md5 = keys %md5;
    my $q = join(", ", map { "?" } @md5);
    my $dbq = join(", ", map { "?" } @db);

    my $res = $dbh->selectall_arrayref(qq(SELECT query_md5, database_name, sub_id, query_coverage, sub_coverage, identity, p_value
					  FROM specialty_gene
					  WHERE query_md5 IN ( $q ) AND
					  	database_name IN ( $dbq )
					 ),
				       undef,
				       @md5, @db);
    for my $ent (@$res)
    {
	my($md5, $db, $sub, $qcov, $scov, $iden, $pv) = @$ent;
	$val{$db}->{$md5} = $ent;
    }
}

my $header;
if ($opt->description eq 'Y') {
    $header = "QID\tQAnnotation\tQOrganism\tDatabase\tSubID\tSubAnnotation\tSubOrganism\tQueryCoverage\tSubCoverage\tIdentity\tP-Value\n";
} else {
    $header = "QID\tDatabase\tSubID\tQueryCoverage\tSubCoverage\tIdentity\tP-Value\n" ;
}
print $out_fh $header;

my %hits;
my %to_compute;

for my $db (@db)
{
    my $db_file = "$db_dir/$db";
    -f "$db_file.faa" or die "DB file $db_file.faa missing\n";

    my $existing = $val{$db};
    my($tmp_fh, $tmp) = tempfile();

    my $count = my $do = 0;

    open(IN, "<", $in_file) or die "Cannot open $in_file: $!";
    while (my($id, $def, $seq) = read_next_fasta_seq(\*IN))
    {
	$count++;
	my $md5 = $id_to_md5{$id};
	if (!$existing->{$md5} && !$to_compute{$db}->{$md5})
	{
	    print $tmp_fh ">$md5\n$seq\n";
	    $do++;
	    $to_compute{$db}->{$md5}++;
	}
    }
    close(IN);
    close($tmp_fh);

    print STDERR "Compute $db: $do of $count\n";
#    print "\t", join(" ", map { keys %{$md5{$_}}} keys %to_compute), "\n";

    if ($do)
    {
	my @blastcmd = ("blastp", "-query", $tmp, "-db", $db_file,
			"-num_threads", $opt->parallel,
			"-num_alignments", 1, "-num_descriptions", 1,  "-evalue", $opt->evalue, "-outfmt", 0);
	
	my $ok = run(\@blastcmd, '>>', $raw_blast_fh);
	
	if (!$ok)
	{
	    die "Blast failed with $?: $@blastcmd\n";
	}
    }
    unlink($tmp) or warn "Unlink $tmp failed: $!";
}
close($raw_blast_fh);

my $in = new Bio::SearchIO(-format => 'blast', -file=> $raw_blast);

while( my $result = $in->next_result ) {

    # $result is a Bio::Search::Result::ResultI compliant object

    while( my $hit = $result->next_hit ) {
	# $hit is a Bio::Search::Hit::HitI compliant object
	
	while( my $hsp = $hit->next_hsp ) {
	    # $hsp is a Bio::Search::HSP::HSPI compliant object
	    
	    $result->query_name;
	    $result->database_name;
	    $hit->name;
	    $hsp->query;
	    $hsp->hit;
	    $hsp->length('query');
	    $hsp->length('hit');
	    $hsp->length('total');
	    $hsp->percent_identity;
	    $hsp->start('query');
	    $hsp->end('query');
	    $hsp->start('hit');
	    $hsp->start('hit');
	    $hsp->pvalue;
	    $hsp->significance;
	    $hsp->score;
	    $hsp->bits;
	    
	    my $qid = $result->query_name;
	    my ($qAnnot, $qOrg) = ($result->query_description, "");
	    ($qAnnot, $qOrg) = $result->query_description=~/(.*)\s*\[(.*)\]/ if $result->query_description=~/(.*)\s*\[(.*)\]/;
	    
	    my $database=$result->database_name;
	    
	    my $sid = $hit->name;
	    my ($sAnnot, $sOrg) = ($hit->description, "");
	    ($sAnnot, $sOrg) = $hit->description=~/(.*)\s*\[(.*)\]/ if $hit->description=~/(.*)\s*\[(.*)\]/;
	    
	    my $id=int(abs($hsp->percent_identity));	
	    my $qcov=int(abs( $hsp->length('query') * 100 / $result->query_length ));
	    my $scov=int(abs( $hsp->length('hit') * 100 / $hit->length ));
	    my $pvalue = $hsp->significance;
	    
	    my $sim = "";
	    if ($opt->description eq 'Y'){
		$sim = "$qid\t$qAnnot\t$qOrg\t$database\t$sid\t$sAnnot\t$sOrg\t$qcov\t$scov\t$id\t$pvalue\n";
	    }else{
		$sim = "$qid\t$database\t$sid\t$qcov\t$scov\t$id\t$pvalue\n";
	    }
	    
	    $val{$database}->{$qid} = [$qid, $database, $sid, $qcov, $scov, $id, $pvalue];
	}  
    }
}
if (!$opt->report)
{
    unlink($raw_blast);
}
# print Dumper(\%val, \%id_to_md5);

for my $db (@db)
{
    my $v = $val{$db};
    for my $id (@ids)
    {
	my $md5 = $id_to_md5{$id};
	my $ent = $v->{$md5};
	if (!ref($ent))
	{
	    if ($to_compute{$db}->{$md5})
	    {
		# we computed this and had no hit
		# print "Update $db $md5 no hi\n";
		$sth_miss->execute($md5, $db);
	    }
	    else
	    {
		warn "missing ent, but no computed flag $db $id $md5\n";
	    }
	    next;
	}
	if ($to_compute{$db}->{$md5})
	{
	    # print "Update $db $md5 @$ent\n";
	    if ($sth)
	    {
		$sth->execute(@$ent);
	    }
	}
	my(undef, undef, $sid, $qcov, $scov, $iden, $pvalue) = @$ent;
	if ($sid)
	{
	    
	    if ($opt->filter eq 'Y'){
		if ($db =~ /Human/i)
		{
		    next unless ($qcov>=50 || $scov>=50) && $iden>=50;
		}
		else
		{
		    next unless ($qcov>=80 || $scov>=80) && $iden>=80 ;
		}
	    }
	    print $out_fh join("\t", $id, @$ent[1..$#$ent]), "\n";
	}
    }
}
	
close($out_fh);


__END__

; Schema


CREATE TABLE specialty_gene
(
	query_md5	CHAR(33),
	database_name	VARCHAR(100),
	sub_id		VARCHAR(255),
	sub_organism	VARCHAR(255),
	query_coverage	FLOAT,
	sub_coverage	FLOAT,
	identity	FLOAT,
	p_value		FLOAT,
	PRIMARY KEY (query_md5, database_name)
);
