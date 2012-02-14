
=head1 NAME

dtr_setup_database - set up a new myRAST database

=head1 DESCRIPTION

Interactively set up a new database instance to use for myRAST. Creates
the database instance, initializes a Sapling in it, and creates the
myrast.cfg with the appropriate settings.

=cut

use strict;
use DBI;
use Text::Wrap;
use Term::ReadKey;
use Data::Dumper;
use myRAST;

my @dbs = qw(Pg mysql);
my %dbname = (Pg => "Postgres",
	      mysql => 'MySQL');

my %dbname_blacklist = (Pg => { postgres => 1, template0 => 1, template1 => 1},
			mysql => { mysql => 1, information_schema => 1, performance_schema => 1, test => 1 },
			);

my $config = myRAST->instance->config;

my $cur_dbms = $config->param('myrast.sapling_dbms');

if ($cur_dbms eq 'Pg' || $cur_dbms eq 'mysql')
{
    my $continue = prompt_yesno("A $dbname{$cur_dbms} database is already configured; do you wish to change the configuration? ");
    if (!$continue)
    {
	print "OK, exiting.\n";
	exit;
    }

    myRAST->instance->backup_config();
}

my $db = prompt_hash("Which database do you wish to configure? ", \%dbname);

#
# Check to see if we are able to use the database. "Use" means that we can
# load the DBI module for it. If we cannot, attempt to find a running server
# and ...



my $dbname;
while (1)
{
    $dbname = prompt('Desired database name? [myrast] ');
    $dbname ||= 'myrast';
    if ($dbname_blacklist{$db}->{$dbname})
    {
	print "$dbname is not a valid database name for this database server\n";
	next;
    }
    elsif ($dbname =~ /^[a-zA-Z][a-zA-Z0-9_]+$/)
    {
	last;
    }
    
    print wrap('', '',
	       "Database name must have no spaces and consist of letters, numbers, and _ only\n");
}

my $admin_dbh;
my($admin_user, $admin_pw);

my $myrast_user = "myrast";
my $myrast_pw = "myrast";

my $dbport;

if ($db eq 'Pg')
{
    $dbport = 5432;
    
    $admin_user = 'postgres';
    $admin_pw = prompt_pw('Database administrator password? ');

    eval {
	$admin_dbh = DBI->connect("dbi:Pg:database=template1", $admin_user, $admin_pw,
			      { RaiseError => 0, PrintError => 0 });
    };
    if (!$admin_dbh)
    {
	print "Unable to connect to postgres database:\n$@\n$DBI::errstr\n";
	exit;
    }

    #
    # See if this database exists.
    #
    my $res = $admin_dbh->selectall_arrayref(qq(SELECT *
						FROM pg_database
						WHERE datname = ?), undef, $dbname);
    if (@$res)
    {
	my $ok = prompt_yesno("Database $dbname already exists. If you continue we will destroy this database. Do you wish to continue and destroy the existing database $dbname? ");
	if (!$ok)
	{
	    print "OK, exiting.\n";
	    exit;
	}
	$admin_dbh->do(qq(DROP DATABASE $dbname));
    }

    $admin_dbh->do(qq(CREATE USER $myrast_user WITH UNENCRYPTED PASSWORD '$myrast_pw'));
    
    $admin_dbh->do(qq(CREATE DATABASE $dbname OWNER $myrast_user));

}
elsif ($db eq 'mysql')
{
    $dbport = 3306;
    
    $admin_user = 'root';
    $admin_pw = prompt_pw('Database administrator password? ');

    eval {
	$admin_dbh = DBI->connect("dbi:mysql:test", $admin_user, $admin_pw,
			      { RaiseError => 0, PrintError => 0 });
    };
    if (!$admin_dbh)
    {
	print "Unable to connect to mysql database:\n$@\n$DBI::errstr\n";
	exit;
    }

    #
    # See if this database exists.
    #
    my $res = $admin_dbh->selectcol_arrayref(qq(SHOW DATABASES));
    my %cur_dbs = map { $_ => 1 } @$res;

    if ($cur_dbs{$dbname})
    {
	my $ok = prompt_yesno("Database $dbname already exists. If you continue we will destroy this database. Do you wish to continue and destroy the existing database $dbname? ");
	if (!$ok)
	{
	    print "OK, exiting.\n";
	    exit;
	}
	$admin_dbh->do(qq(DROP DATABASE $dbname));
    }

    $admin_dbh->do(qq(CREATE DATABASE $dbname));
    $admin_dbh->do(qq(GRANT ALL PRIVILEGES ON $dbname.*
		      TO '$myrast_user'\@'localhost'
		      IDENTIFIED BY '$myrast_pw'));
}

#
# We now have a database created. Update the config and 
# write it out.
#

$config->param('myrast.sapling_dbms', $db);
$config->param('myrast.sapling_dbname', $dbname);
$config->param('myrast.sapling_dbport', $dbport);
$config->param('myrast.sapling_dbuser', $myrast_user);
$config->param('myrast.sapling_dbpass', $myrast_pw);

myRAST->instance->write_config($config);

my $sapling = myRAST->instance->sapling();
print "Creating tables ...\n";
$sapling->CreateTables();
print "Setup complete.\n";
    
sub prompt_hash
{
    my($msg, $kvhash) = @_;

    my $str = join(" ", values %$kvhash);
    while (1)
    {
	my $x = prompt("$msg ($str) ");
	
	my $re = qr/^$x/i;

	my @k;
	while (my($k, $v) = each(%$kvhash))
	{
	    if ($v =~ $re)
	    {
		push(@k, $k);
	    }
	}
	if (@k == 0)
	{
	    print "Unknown value $x\n";
	}
	elsif (@k > 1)
	{
	    print "Ambiguous value $x\n";
	}
	else
	{
	    return $k[0];
	}
    }
}
    

sub prompt_yesno
{
    my($msg) = @_;
    my $x = prompt($msg);
    return $x =~ /^y/i;
}

sub prompt_pw
{
    my($msg) = @_;
    ReadMode('noecho');
    my $ret = prompt($msg);
    ReadMode('restore');
    return $ret;
}

sub prompt
{
    my($msg) = @_;
    my $txt = wrap('', '', $msg);
    print $txt;
    my $inp = <STDIN>;
    chomp $inp;
    $inp =~ s/^\s*//;
    $inp =~ s/\s*$//;

    return $inp;
}
