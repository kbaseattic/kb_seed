# -*- perl -*-
########################################################################
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
########################################################################

#
# This is a SAS component
#

package DBKernel;

use strict;
use DBI;
use Tracer;
use Data::Dumper;
use FileHandle;
use Carp;

=head1 Reduced-Instruction Database Kernel

This is a reduced-function subset of the B<DBRtns> package that was created for
reasons that made sense to Bruce before they changed his medication but which he
cannot now remember. At some point it will be merged into DBRtns proper. For now,
it functions as the DBRtns base class.

=cut

#

=head2 Public Methods

=head3 new

    my $dbh = DBKernel->new($dbms, $dbname, $dbuser, $dbpass, $dbport, $dbhost, $dbsock);

Construct a database object. This process creates a standard PERL DBI handle and
caches it for our use.

=over 4

=item dbms

The name of the DBMS system. Currently, this is either C<mysql> for MySQL or
C<Pg> for PostGres.

=item dbname

The name of the database to use., or a connect string to use. If a connect string is
specified, only the user and password parameters are used.

=item dbuser

The user whose credentials should be used to open the database.

=item dbpass

Password associated with the specified user.

=item dbport

TCP/IP port to use. Usually this is 3306.

=item dbhost

Hostname of the database server to use. Undefined means  to use the local host (note
that this may be different than a hostname of localhost - postgres, for instance, will
use a more efficient mechansim if no hostname is specified).

=item dbsock

Pathname to the Unix socket the database is listening on. Undefined means the local host.

=item RETURN

A newly-constructed object connected to the specified database.

=back

=cut
sub new {
    my ($class, $dbms, $dbname, $dbuser, $dbpass, $dbport, $dbhost, $dbsock) = @_;

    my @opts;

    if (defined($dbport))
    {
        push(@opts, "port=${dbport}");
    }

    if ($dbms eq "mysql")
    {
        if ($dbhost)
	{
	    push(@opts, "hostname=$dbhost");
	}
	if ($dbsock)
	{
	    push(@opts, "mysql_socket=$dbsock");
	}
    }
    elsif ($dbms eq "Pg")
    {
	if (defined($dbhost))
	{
	    push(@opts, "host=$dbhost");
	}
    }


    #
    # Late-model mysql needs to have the client enable loading from local files.
    #
    if ($dbms eq "mysql") {
        push(@opts, "mysql_local_infile=1");
    }

    # Decide if this is a pre-index or post-index DBMS. The "preIndex" variable in
    # FIG_Config determines whether this is a pre-index or post-index. This capability
    # was introduced for performance testing.
    my $preload = $FIG_Config::preIndex;
    # Now connect to the database.
    my $data_source;
    if ($dbname =~ /^DBI:/) {
    	$data_source = $dbname;
    } else {
    	my $opts = join(";", @opts);
    	$data_source = "DBI:$dbms(AutoCommit => 1):dbname=$dbname;$opts";
    }
    Trace("Connect string is: $data_source") if T(3);
    my $dbh = Connect($data_source, $dbuser, $dbpass, $dbms);
    bless {
	_connect => [$data_source, $dbuser, $dbpass],
        _dbh => $dbh,
        _dbms => $dbms,
        _preIndex => $preload,
        _host => ($dbhost || "localhost"),
	_retries => 0,
    }, $class;
}

=head3 Connect

    my $dbh = DBKernel::Connect($data_source, $dbuser, $dbpass, $dbms);

Connect to the database using the specified information. This method has
been separated out from the constructor to make it possible to reconnect
after a connection failure.

=over 4

=item data_source

Connection string for the database itself.

=item dbuser

User name for accessing the database.

=item dbpass

Password for the user name.

=item dbms

Database type (C<mysql>, C<Pg>, C<SQLite>).

=item RETURN

Returns the handle to the database.

=back

=cut

sub Connect {
    my ($data_source, $dbuser, $dbpass, $dbms) = @_;
    my $retVal = DBI->connect( $data_source, $dbuser, $dbpass );
    if (! $retVal) {
        my $msg = ErrorMessage($dbms);
        Confess($msg);
    }
    $retVal->{PrintError} = 1;
    $retVal->{RaiseError} = 0;
    if ($dbms eq "Pg") {
        $retVal->do(qq(SET "ENABLE_SEQSCAN" TO "OFF"));
        $retVal->do(qq(SET DATESTYLE TO Postgres,US));
    } elsif ($dbms eq "SQLite") {
        $retVal->do("pragma synchronous = OFF;");
	$retVal->{sqlite_see_if_its_a_number} = 1;
    } elsif ($dbms eq "mysql") {
        $retVal->{mysql_auto_reconnect} = 1;
    }
    return $retVal;
}

=head3 set_retries

    $db->set_retries($count);

Specify the number of times a SELECT should be retried before failing.

=cut

sub set_retries {
    my ($self, $count) = @_;
    $self->{_retries} = $count;
}

=head3 dbms

    my $dbms = $db->dbms;

Return the name of the DBMS used to open this database handle. Currently this
is C<mysql> or C<Pg> (PostGres).

=cut

sub dbms {
    return $_[0]->{_dbms};
}

=head3 test_mode

    $db->test_mode();

Denote that this connection is in test mode. Certain
performance-enhancing features may be disabled in test mode.

=cut

sub test_mode {
    # Get the parameters.
    my ($self) = @_;
    # Denote that we're in test mode.
    $self->{testFlag} = 1;
    # If we're mySQL, turn off the query cache.
    if ($self->{_dbms} eq 'mysql') {
	$self->{_dbh}->do("SET SESSION query_cache_type = OFF");
    }
}


=head3 set_readonly_handle

C<<$db->set_readonly_handle($readonly_db); >>

Set up a DBKernel instance that should be use to make readonly (select) queries
with. This is used in a mirroring setup where any queries that change the database
are made on an external database, but readonly queries can be made on a local mirror
for better performance.

=cut

sub set_readonly_handle
{
    my($self, $h) = @_;

#warn "setting readonly handle for db\n";

    $self->{_ro_dbobj} = $h;
    $self->{_ro_dbh} = $h->{_dbh};
}

=head3 set_raise_exceptions

    my $oldValue = $db->set_raise_exceptions($newValue);

Set the B<RaiseError> flag to a new value. If the flag is C<1>, then a database
error will throw an exception. If it is C<0>, an error will be reflected by a
return value.

=over 4

=item newValue

C<1> if you want errors to throw an exception, C<0> if you want to continue
processing after errors.

=item RETURN

Returns the previous value of the flag.

=back

=cut

sub set_raise_exceptions {
    my($self, $enable) = @_;
    my $dbh = $self->{_dbh};
    my $old = $dbh->{RaiseError};
    $dbh->{RaiseError} = $enable;
    return $old;
}

=head3 CreateDB

    DBKernel::CreateDB($dbname);

Drop and create a database with the specified name. If the drop fails it will generate
an error message, but will not be considered an error.

This method is deprecated, since the database will be created without the necessary
security privileges.

=over 4

=item dbname

Name of the database to drop and create.

=back

=cut

sub CreateDB {
    # Get the database name.
    my ($dbname) = @_;
    # Check the database type, since we'll be doing direct database utility calls.
    if ($FIG_Config::dbms eq "Pg") {
        my $dbport = $FIG_Config::dbport;
        my $dbuser = $FIG_Config::dbuser;
        Trace("Dropping old database $dbname (failure is okay)") if T(2);
        system("dropdb -p $dbport -U $dbuser $dbname");
        Trace("Creating new database: $dbname $dbuser $dbport") if T(2);
        &FIG::run("createdb -p $dbport -U $dbuser $dbname");
    } elsif ($FIG_Config::dbms eq "mysql") {
        Trace("Dropping old database $dbname (failure is okay).") if T(2);
        system("mysqladmin -u $FIG_Config::dbuser -p drop $dbname");
        Trace("Creating new database: $dbname $FIG_Config::dbuser") if T(2);
        &FIG::run("mysqladmin -u $FIG_Config::dbuser -p create $dbname");
    }

}


=head3 SQL

    my $rv = $db->SQL($sql, $verbose, @bind_values);

Execute an SQL statement. If used for a SELECT statement, the entire result set will be
returned via an array reference. If used for another statement type, the result will be
a count of the number of rows affected. Note that the type of statement is determined by
a simple case-insensitive prefix match. If the first 6 characters of the command are
C<SELECT> in any combination of upper- and lower-case, then the statement is treated as
a query; otherwise it's treated as a command.

=over 4

=item sql

SQL statement to execute.

=item verbose

C<1> if the command should be traced, else C<0>. This option is deprecated. You
can cause SQL commands to be traced by setting the trace level for C<DBKernel>
to 3 (information).

=item bind_values1, bind_values2, ... bind_valuesN

List of bound values to be used to replace the parameter markers (C<?>) in the
SQL statement.

=item RETURN

For a C<SELECT> statement, returns a reference to a list of lists. Each element in
the big list is a result row; the elements inside a result row correspond to the
columns of the query.

For a command, returns the number of rows affected. If no rows are affected,
a I<true 0> is returned (that is, the return value acts as 0 when used numerically and
TRUE when used in a boolean expression). If an error occurs, this method will
throw an exception.

=back

=cut
sub SQL {
    my($self,$sql,$verbose, @bind_values) = @_;

    if ($verbose) {
        Trace("Executing SQL statement: $sql") if T(0);
    }

    my $dbh  = $self->{_dbh};
    my $retVal;
    if ($sql =~ /^\s*select/i) {

        # Choose to use the readonly handle if one exists.

        my $ro = $self->{_ro_dbh};
        if (ref($ro))
        {
            $dbh = $ro if ref($ro);
            #warn "using RO for $sql\n";
        }
        # We may need to try multiple times.
        my $tries_left = $self->{_retries};
        # In MySQL test mode, we turn off query caching.
        # If we run out of retries, we'll confess. Otherwise, $retVal will get a
        # value put in it.
        while (! defined $retVal) {
            Trace("Executing SQL query: $sql") if T(SQL => 3);
            eval {
                $retVal = $dbh->selectall_arrayref($sql, undef, @bind_values);
            };
            if ($@) {
                Confess("Query failed: $@");
            } elsif (! defined $retVal) {
                # We have a soft error. Save the message.
                my $msg = $dbh->errstr;
                # See if we can retry. A retry is possible if the error is
                # timeout or connection-related.
                if ($tries_left && $msg =~ /connect|gone|lost|timeout/) {
                    # Yes. Attempt a reconect.
                    $self->Reconnect();
                    # Get back the database handle.
                    $dbh = $self->{_dbh};
                    # Denote we've used up a retry.
                    $tries_left--;
                } else {
                    # We can't recover, so confess.
                    Confess("SELECT failed: $msg");
                }
                Confess("Query failed: " . $dbh->errstr);
            } else {
                Trace(@{$retVal} . " rows returned from query.") if T(SQL => 3);
            }
        }
    } else {
        Trace("Executing SQL command: $sql") if T(SQL => 3);
        eval {
            $retVal = $dbh->do($sql, undef, @bind_values);
        };
        if ($@) {
            Confess("Query '$sql' failed: $@");
        } elsif (! defined $retVal) {
            Confess("Query failed: " . $dbh->errstr);
        } else {
            Trace("$retVal rows altered by command.") if T(SQL => 3);
        }
    }
    return $retVal;
}

sub SQL_returning_hash {
    my($self,$sql,$key, $verbose, @bind_values) = @_;

    if ($verbose) {
        Trace("Executing SQL statement: $sql") if T(0);
    }

    my $dbh  = $self->{_dbh};
    my $retVal;
    if ($sql =~ /^\s*select/i) {

        # Choose to use the readonly handle if one exists.

        my $ro = $self->{_ro_dbh};
        if (ref($ro))
        {
            $dbh = $ro if ref($ro);
            #warn "using RO for $sql\n";
        }
        # We may need to try multiple times.
        my $tries_left = $self->{_retries};
        # In MySQL test mode, we turn off query caching.
        # If we run out of retries, we'll confess. Otherwise, $retVal will get a
        # value put in it.
        while (! defined $retVal) {
            Trace("Executing SQL query: $sql") if T(SQL => 3);
            eval {
                $retVal = $dbh->selectall_hashref($sql, $key, undef, @bind_values);
            };
            if ($@) {
                Confess("Query failed: $@");
            } elsif (! defined $retVal) {
                # We have a soft error. Save the message.
                my $msg = $dbh->errstr;
                # See if we can retry. A retry is possible if the error is
                # timeout or connection-related.
                if ($tries_left && $msg =~ /connect|gone|lost|timeout/) {
                    # Yes. Attempt a reconect.
                    $self->Reconnect();
                    # Get back the database handle.
                    $dbh = $self->{_dbh};
                    # Denote we've used up a retry.
                    $tries_left--;
                } else {
                    # We can't recover, so confess.
                    Confess("SELECT failed: $msg");
                }
                Confess("Query failed: " . $dbh->errstr);
            } else {
                Trace(@{$retVal} . " rows returned from query.") if T(SQL => 3);
            }
        }
    } else {
        Trace("Executing SQL command: $sql") if T(SQL => 3);
        eval {
            $retVal = $dbh->do($sql, undef, @bind_values);
        };
        if ($@) {
            Confess("Query '$sql' failed: $@");
        } elsif (! defined $retVal) {
            Confess("Query failed: " . $dbh->errstr);
        } else {
            Trace("$retVal rows altered by command.") if T(SQL => 3);
        }
    }
    return $retVal;
}

=head3 show_create_table

    my $createString = $db->show_create_table($tableName);

Return the CREATE TABLE string for the specified relation.

=over 4

=item tableName

Name of the SQL table whose creation string is desired.

=item RETURN

Returns a CREATE TABLE statement in SQL that can be used to re-create
the specified table.

=back

=cut

sub show_create_table {
    # Get the parameters.
    my ($self, $tableName) = @_;
    # Declare the return variable.
    my $retVal = "";
    # Execute a SHOW CREATE TABLE statement.
    my $result = $self->{_dbh}->selectall_arrayref("SHOW CREATE TABLE $tableName");
    # Extract the result.
    if ($result->[0]) {
        $retVal = $result->[0][1];
    }
    # Return it.
    return $retVal;
}

=head3 Reconnect

    $db->Reconnect();

Attempt to reconnect to the database. This is useful when it appears that the
connection has been lost.

=cut

sub Reconnect {
    # Get the parameters.
    my ($self) = @_;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Force a close just in case.
    eval { $dbh->disconnect() };
    # Reconnect.
    Trace("Reconnecting after error.") if T(1);
    $dbh = Connect(@{$self->{_connect}}, $self->{_dbms});
    # Save the new handle.
    $self->{_dbh} = $dbh;

}

=head3 ErrorMessage

    my $msg = $db->ErrorMessage($handle);

Return the error message on the specified handle. Some analysis will be
performed to determine whether the error is on the server or is the fault
of the client. If no handle is supplied, then the error information will
be taken from he last DBI request. If this method is called statically,
the DBMS type should be supplied as the first parameter.

=over 4

=item handle

Handle on which the error occurred.

=item RETURN

Returns the appropriate error message with a message prefix of C<DBServer Error>
if it looks like the error permits a retry.

=back

=cut

use constant MYSQL_RETRY_ERRORS =>
    { 2002 => 1, 2006 => 1, 2013 => 1, 2055 => 1, 1040 => 1, 19 => 1 };

sub ErrorMessage {
    # Get the parameters.
    my ($self, $handle) = @_;
    # Get the error message, number, and DBMS type.
    my ($num, $msg, $dbms);
    if (defined $handle) {
        ($num, $msg) = ($handle->err, $handle->errstr);
    } else {
        ($num, $msg) = (DBI::err, DBI::errstr);
    }
    if (ref $self) {
        $dbms = $self->{_dbms};
    } else {
        $dbms = $self;
    }
    # Declare the return variable.
    my $retVal;
    # Is this MySQL?
    if ($dbms eq 'mysql') {
        # Yes. Check the error number.
        Trace("Database error check. Error number is $num.") if T(3);
        if (MYSQL_RETRY_ERRORS->{$num}) {
            # Here it's a server-related error.
            $retVal = "DBServer Error: ";
        } else {
            # Otherwise, it's a normal error.
            $retVal = "MySQL Error: ";
        }
    } else {
        # Here all errors are normal.
        $retVal = "Database Error: ";
    }
    # Add the message text to the error.
    $retVal .= $msg;
    # Return the result.
    return $retVal;
}




=head3 SetUsing

    my $usingClause = $db->SetUsing(@tableNames);

Return the body of a DELETE statement that is appropriate to the
particular DBMS. For example, in MySQL the USING statement must contain the
name of the table being deleted, but in PostGres it cannot contain the
name of the table being deleted. The delete statement returned will
not contain a WHERE; that must be added by the client.

=over 4

=item $tableName1, $tableName2, ... $tableNameN

List of the names of the tables involved. The last table is the one being
deleted.

=item RETURN

Returns a DELETE statement that allows deletion of the last table named
using a WHERE clause that may contain fields from any of the tables in
the list.

=back

=cut
#: Return Type $;
sub SetUsing {
    # Get the parameters.
    my ($self, @tableNames) = @_;
    # Count the tables.
    my $N = $#tableNames;
    my $q = $self->quote();
    # Declare the return variable.
    my $retVal = "DELETE FROM $q$tableNames[$N]$q";
    if ($N > 0) {
        if ($self->{_dbms} eq "Pg") {
            # It's PostGres, so pop off the target table's name to keep it
            # out of the USING clause.
            pop @tableNames;
        }
        $retVal .= " USING " . join(", ", map { $q . $_ . $q } @tableNames);
    }
    # Return the result.
    return $retVal;
}

=head3 get_tables

    my @tableNames = $db->get_tables();

Return a list of the table names for the current database. If there are no tables, an
empty list will be returned.

It is worth remembering that most DBMS packages are case-insensitive with respect to
column and table names. Therefore, when manipulating this list, be sure to do
case-insensitive matching. For example, if you want to find out if there's a table named
C<Genome>, PostGres will have changed the name to C<genome>, and Paradox will have changed
the name to C<GENOME>. MySQL's behaviour depends on the collating sequence and character
set selected when the database was created, which is almost worse.

=cut

sub get_tables {

    my($self) = @_;

    if (ref($self->{table_cache}) eq "ARRAY")
    {
	return @{$self->{table_cache}};
    }

    my $dbh = $self->{_dbh};

    my $quote = $dbh->get_info(29); # SQL_IDENTIFIER_QUOTE_CHAR

    my @tables = $dbh->tables();

    #
    # Mysql might have names in the form '`metagenome`.`protein_sequence_seeks`'
    # Similary, Postgres with '"metagenome"', etc.
    my @ret;
    if ($self->{_dbms} eq 'mysql')
    {
	@ret =  map {
	    if ($quote)
	    {
		if (/^($quote[^$quote]*$quote\.)?$quote([^$quote]*)$quote/)
		{
		    $2;
		}
		else
		{
		    $_;
		}
	    }
	    else
	    {
		s/^[^.]+\.//;
		$_;
	    }
	   } @tables;
    }
    elsif ($self->{_dbms} eq 'Pg') {
        for my $table (@tables) {
            if ($table =~ /public\.(.+)/) {
                my $name = $1;
                $name =~ s/$quote//g;
                push @ret, $name;
            }
        }
    }
    else
    {
	@ret =  map { $quote ne "" && s/^$quote(.*?)$quote$/$1/; s/^[^.]+\.//; $_ } @tables;
    }

    $self->{table_cache} = [@ret];

    return @ret;
}

=head3 table_columns

    my @cols = $db->table_columns($table);

Return a list of the columns in the specified table.

NOTE: this has only been tested with MySQL so far, though it's supposed
to work with all of the DBMS types.

=over 4

=item table

Name of the table whose columns are desired.

=item RETURN

Returns a list of 3-tuples containing the name, SQL type, and
nullability flag for each column of the table.

=back

=cut

sub table_columns {
    # Get the parameters.
    my ($self, $table) = @_;
    # Get a statement handle for the specified table.
    my $sth = $self->{_dbh}->column_info(undef, $table, undef, undef);
    # The results will go in here.
    my @retVal;
    # Loop through the columns.
    while (my $row = $sth->fetchrow_hashref) {
        # Get the column name.
        my $name = $row->{COLUMN_NAME};
        # Compute the data type.
        my $type = $row->{TYPE_NAME};
        if ($type =~ /CHAR$/i) {
            $type .= "(" . $row->{COLUMN_SIZE} . ")";
        }
        # Compute the nullability.
        my $nullable = ($row->{IS_NULLABLE} eq 'YES');
        # Compute the column's position.
        my $pos = $row->{ORDINAL_POSITION} - 1;
        # Store all this information.
        $retVal[$pos] = [$name, $type, $nullable];
    }
    # Return the result.
    return @retVal;
}

=head3 table_exists

    my $existFlag = $db->table_exists($table);

Return TRUE if the specified table exists in the database, else FALSE. The table
name is considered case-insensitive, for reasons explained in L</get_tables>.

=over 4

=item table

Name of the table whose existence is under question.

=item RETURN

Returns C<1> if the specified table exists in the database, else FALSE.

=back

=cut

sub table_exists {

    my($self, $table) = @_;
    $table = lc $table;
    my @tables = $self->get_tables();
    return (grep { $table eq lc $_ } @tables) > 0;
}

=head3 drop_table

    $db->drop_table(tbl => $table);

Remove the named table from the database if it exists.

=over 4

=item table

Name of the table to be dropped.

=back

=cut

sub drop_table {
    my $self = shift @_;
    my %arg  = @_;
    my $tbl  = $arg{tbl};
    my $dbh  = $self->{_dbh};
    my $dbms = $self->{_dbms};
    my $cmd;

    #
    # Invalidate table cache.
    #
    delete $self->{table_cache};

    if ($dbms eq "mysql" || $dbms eq "Pg") {
        $cmd = "DROP TABLE IF EXISTS $tbl;" ;
    } else {
        if ($self->table_exists($tbl)) {
            $cmd = "DROP TABLE $tbl;" ;
        }
    }
    if ($cmd) {
        Trace("Executing drop command $cmd.") if T(3);
        if ($dbh->do($cmd)) {
            Trace("Table $tbl dropped.") if T(2);
        } else {
            Trace("Error dropping table: " . $dbh->errstr) if T(0);
        }
    }
}

=head3 index_mod

    my $fieldString = $dbh->index_mod($fldName, $mod);

Create a field specification for indexing the first I<n> characters of
a field.

=over 4

=item fldName

Name of the field whose specification is to be created.

=item mod

Number of characters to index from the beginning of the field.

=item RETURN

Returns a string that can be used to represent the field in a CREATE INDEX
statement.

=back

=cut

sub index_mod {
    # Get the parameters.
    my ($self, $fldName, $mod) = @_;
    # Declare the return value. The default is just the field name with the
    # modifier in parens.
    my $retVal = "$fldName($mod)";
    # For Postgres, we use an alternate syntax.
    if ($self->{_dbms} eq 'Pg') {
        $retVal = "(substring($fldName, 0, $mod))";
    }
    # Return the result.
    return $retVal;
}

=head3 create_table

    $db->create_table(tbl => $table, flds => $flds, estimates => [$rowSize, $rowCount]);

Create a new table with the specified name and the specified fields. The
fields are specified in the form of the string that appears between the
parentheses in a C<CREATE TABLE> statement. So, for example, to create
a table called C<Genome> with a 20-character ID, a 255-character name, an
index number, and a long text sequence field, you would code

    $db->create_table(tbl => 'Genome',
        flds => 'id VARCHAR(20) NOT NULL PRIMARY KEY, ' .
                'name VARCHAR(255), indexNum INT, seq TEXT');

This method does not return a result. If the table creation fails for any
reason, it will throw an exception.

If MySQL is being used and the C<estimates> option is specified, the table will be
created using MyISAM.

=over 4

=item tbl

Name to give to the new table.

=item flds

Field specifications for the new table. This should be a single string that
consists of a comma-delimited list of the I<create-definition> syntactic unit
for SQL. In MySQL 4.1, it's defined as follows.

    create_definition:
        column_definition
      | [CONSTRAINT [symbol]] PRIMARY KEY [index_type] (index_col_name,...)
      | KEY [index_name] [index_type] (index_col_name,...)
      | INDEX [index_name] [index_type] (index_col_name,...)
      | [CONSTRAINT [symbol]] UNIQUE [INDEX]
            [index_name] [index_type] (index_col_name,...)
      | [FULLTEXT|SPATIAL] [INDEX] [index_name] (index_col_name,...)
      | [CONSTRAINT [symbol]] FOREIGN KEY
            [index_name] (index_col_name,...) [reference_definition]
      | CHECK (expr)

    column_definition:
        col_name type [NOT NULL | NULL] [DEFAULT default_value]
            [AUTO_INCREMENT] [UNIQUE [KEY] | [PRIMARY] KEY]
            [COMMENT 'string'] [reference_definition]

=item rowSize

Average expected row size.

=item rowCount

Estimated maximum number of rows.

=back

=cut

sub create_table {
    my $self = shift @_;
    my %arg  = @_;
    my $tbl  = $arg{tbl};
    my $flds = $arg{flds};
    my $dbh  = $self->{_dbh};
    my $dbms = $self->{_dbms};
    my $options = "";

    #
    # Invalidate table cache.
    #

    delete $self->{table_cache};

    if ($self->{_dbms} eq "mysql")
    {
	if (not $FIG_Config::mysql_v3)
	{
	    $options = " DEFAULT CHARSET latin1 COLLATE latin1_bin";
	}
         if (defined $arg{estimates} && !defined($FIG_Config::disable_dbkernel_size_estimates)) {
             my ($rowSize, $rowCount) = @{$arg{estimates}};
 	    if (not $FIG_Config::mysql_v3)
 	    {
 	        my $engine = $FIG_Config::default_mysql_engine || 'MyISAM';
 		$options .= " ENGINE = $engine";
 	    }
             $options .= " AVG_ROW_LENGTH = $rowSize MAX_ROWS = $rowCount";
        }
    }
    my $cmd = "CREATE TABLE $tbl ( $flds )$options;";
    Trace("Creating table: $cmd") if T(SQL => 2);
    $dbh->do($cmd) ||
        Confess("Error creating table $tbl: " . $dbh->errstr);
}

=head3 load_table

    my $rowCount = $db->load_table(file => $file, tbl => $tbl, delim => $delim, style => $style);

Load a table from a file. This is the fastest way to load a large table, and for best
results it should be done before any indexes are created for it. For MySQL, the file
must contain one row per line, and the fields within a row should be tab-delimited.
For PostGres, you can specify a different delimiter string using the C<delim> option.

=over 4

=item file

Fully-qualified name of the file containing the data to load. The file must contain
one line per table row, and the fields in each row must be presented in the order in
which the columns were specified in the L</create_table> method.

=item tbl

Name of the table into which the data should be loaded.

=item delim (optional)

String separating the fields on a single line. The default is a tab (C<\t>). This
must be a single character so that it will work with all of the different database
technologies.

=item style (optional)

Style of load. The default is a normal LOAD DATA INFILE. In MySQL, the
option C<CONCURRENT> or C<LOW_PRIORITY> can be used to modify the way the load
works. C<LOW_PRIORITY> causes the load to wait until the table is no longer
being accessed, and C<CONCURRENT> attempts to allow other users to read the
table while the load is in progress.

=item dup (optional)

If C<ignore>, duplicate rows are discarded automatically; if C<replace>, duplicate rows
replace the previous instance. If omitted, duplicate rows cause an error. 

=item RETURN

Returns the number of rows loaded. If no rows were loaded, will return a true 0, that is,
it will return a value that evaluates to 0 numerically but is treated as TRUE when used in
a boolean expressing. If an error occurs, will return C<undef>.

=back

=cut

sub load_table {
    my $self     = shift @_;
    my %defaults = ( delim => "\\t" );
    my %arg      = (%defaults, @_);
    my $file     = $arg{file};
    my $tbl      = $arg{tbl};
    my $delim    = $arg{delim};
    my $dbh  = $self->{_dbh};
    my $dbms = $self->{_dbms};
    my $style = $arg{style} || '';
    my $local = $arg{'local'} || $FIG_Config::load_mode || '';
    my $rv;
    # Convert "normal" load mode to null.
    if ($style eq 'normal') {
	$style = '';
    }
    if ($file) {
        if ($dbms eq "mysql") {
            Trace("Loading $tbl into MySQL using file $file and style $style.") if T(2);
            # Fix the file name for windows.
            $file =~ tr/\\/\//;
            # Decide whether this is a local file or a server file.
            if ($self->{_host} ne "localhost" && ! $local) {
                $local = "LOCAL";
            }
            # Decide whether we are ignoring duplicates.
            my $ignore_mode = "";
            if ($arg{dup}) {
            	$ignore_mode = uc $arg{dup};
            }
	    	my $sql = "LOAD DATA $style $local INFILE '$file' $ignore_mode INTO TABLE $tbl FIELDS TERMINATED BY '$delim';";
	    	Trace("SQL command: $sql") if T(SQL => 2);
            $rv = $dbh->do($sql);
        } elsif ($dbms eq "Pg") {
            Trace("Loading $tbl into PostGres using file $file.") if T(2);
	    my $sql = "COPY $tbl FROM '$file' WITH DELIMITER '$delim' NULL AS '\\N';";
	    Trace("SQL command: $sql") if T(SQL => 2);
            $rv = $dbh->do($sql);
        }
        elsif ($dbms eq 'SQLite')
        {
            #
            # SQLite needs to do the bulk inserts using INSERT. We enclose it in a transaction,
            # committing every 10000 rows.
            #

            my $fh = new FileHandle("<$file");
            $fh or Confess("load_table: cannot open $file");

            local $dbh->{AutoCommit} = 0;

            #
            # Determine the columns of the table.
            #

            my $sth = $dbh->prepare("select * from $tbl where 1 = 0");
            $sth->execute();
            my @cols = @{$sth->{NAME}};
            print "GOt table columns @cols\n";
            my $n_cols = @cols;

            my $qs = join(", ", map { "?" } @cols);

            my $qry = "INSERT INTO $tbl VALUES($qs)";
            my $stmt = $dbh->prepare($qry);
            $stmt or Confess("Prepare '$qry' failed");

            my $row = 0;
            while (<$fh>)
            {
                chomp;
                my @a = split(/\t/);
                #
                # Need to force size of @a to make insert not complain.
                #
                $#a = $n_cols - 1;

                $stmt->execute(@a);
                $row++;
                if ($row % 10000 == 0)
                {
                    $dbh->commit();
                }
            }
            print "sqlite inserted $row rows\n";
            $rv = $row;
        }
        else
        {
            Confess "Attempting load_table on unsupported database $dbms\n";
        }
        if (!defined $rv) {
            my $errno = $dbh->err;
            my $errorMessage = $dbh->errstr;
            Trace("Error in $tbl load ($errno): $errorMessage") if T(0);
        } elsif ($rv >= 0) {
            Trace("$rv rows loaded into $tbl.") if T(3);
        } else {
            Trace("Row loaded into $tbl.") if T(3);
        }
    }
    return $rv;
}

=head3 create_index

    $db->create_index(tbl => $tbl, idx => $idx, flds => $flds, type => $type, kind => $unique);

Create an index on a table. For a large table, this should be done after the table is loaded
so that the load performance is not seriously degraded.

The C<flds> parameter should contain a comma-delimited list of field names, representing
the fields in the index from most significant to least significant. The field names can
be qualified with a direction-- C<ASC> for ascending (the default), or C<DESC> for descending.
For example, the following call creates a unique index on the Genome table that uses the
name field followed by the index number, with the highest index number coming first.

    $db->create_index(tbl => 'Genome', idx => 'idxGenomeName',
        flds => 'name, indexNum DESC', kind => 'unique');

=over 4

=item tbl

Name of the table for which the index is being created.

=item idx

Name to give to the index.

=item flds

Field specifier for the index. This should be a single, comma-delimited string containing
the field names and their associated direction qualifiers (C<ASC> for ascending or C<DESC>
for descending). If a direction qualifier is omitted for a particular field, the direction
defaults to C<ASC>.

=item type (optional, PostGres only)

Type of index.

=item kind (optional)

C<unique> for a unique index, C<primary> for a primary index, C<fulltext> for a
full-text index. If omitted, an ordinary non-unique index is created. Note that
only MySQL supports full-text indexes.

=item RETURN

Returns a defined value if successful, and an undefined value if an error occurred.

=back

=cut

sub create_index {
    my $self = shift @_;
    my %arg  = @_;
    my $tbl  = $arg{tbl};
    my $idx  = $arg{idx};
    my $flds = $arg{flds};
    my $type = $arg{type};
    my $dbh  = $self->{_dbh};
    my $dbms = $self->{_dbms};
    # Drop the index if it already exists. We expect it to not exist,
    # so we kill the warning messages.
    my $printError = $dbh->{PrintError};
    $dbh->{PrintError} = 0;
    $self->drop_index(idx => $idx, tbl => $tbl);
    $dbh->{PrintError} = $printError;
    # Now we can create the index safely.
    my $uniqueFlag = ($arg{kind} ? "$arg{kind}" : "");
    # If this is SQLite, fix the field list.
    if ($dbms eq "SQLite") {
	$flds =~ s/\(\d+\)//g;
    }
    # Build the create command.
    my $cmd;
    if ($dbms eq "mysql") {
        $cmd = "ALTER TABLE $tbl ADD $uniqueFlag KEY $idx";
    } else {
        if (lc($uniqueFlag) eq 'primary') {
            $uniqueFlag = 'unique';
        }
        $cmd = "CREATE $uniqueFlag INDEX $idx ON $tbl";
        if ($type && $dbms eq "Pg") {
            $cmd .= " USING $type ";
        }
    }
    $cmd .= " ( $flds );";
    # If this is Postgres, descending indexes are not allowed.
    if ($dbms eq "Pg") {
        $cmd =~ s/\s+DESC//g;
    }
    Trace("Creating index: $cmd") if T(SQL => 2);
    my $rv = $dbh->do($cmd);
    return $rv;
}

=head3 drop_index

    $db->drop_index(tbl => $tbl, idx => $idx);

Drop an index on a table. This will remove the index.

=over 4

=item tbl

Name of the table from which the index is being dropped. Note that this is only required or used for mysql databases

=item idx

Name of the index.

=item RETURN

Returns a defined value if successful, and an undefined value if an error occurred.

=back

=cut

sub drop_index {
    my $self = shift @_;
    my %arg  = @_;
    my $tbl  = $arg{tbl};
    my $idx  = $arg{idx};
    my $dbh  = $self->{_dbh};
    my $dbms = $self->{_dbms};
    my $res;
    if ($dbms eq "mysql")
    {
     unless ($idx && $tbl)
     {
      print STDERR "Both Index name and table must be specified for them to be dropped\n";
      return undef;
     }
     $res=$dbh->do("DROP INDEX $idx on $tbl");
    }
    elsif ($dbms eq "Pg" or $dbms eq "SQLite")
    {
     unless ($idx)
     {
      print STDERR "An index must be specified to be dropped\n";
      return undef;
     }
     $res=$dbh->do("DROP INDEX $idx");
    }
    else
    {
	Confess "Attempting drop_index on unsupported database $dbms\n";
    }
    return $res;
}

=head3 error_message

    my $message = $dbh->error_message();

Return the error message (if any) from the last database call.

=cut

sub error_message {
    my ($self) = @_;
    return $self->{_dbh}->errstr();
}

=head3 truncate_table

    $dbh->truncate_table($tableName);

Issue a command to delete all the records in the specified table. This works slightly
differently in SQLite, which has no TRUNCATE command.

=over 4

=item tableName

Name of the SQL table to truncate.

=back

=cut

sub truncate_table {
    my ($self, $tableName) = @_;
    if ($self->{_dbms} eq 'SQLite') {
	$self->SQL("DELETE FROM $tableName");
	$self->SQL("VACUUM");
    } else {
	$self->SQL("TRUNCATE TABLE $tableName");
    }
}

=head3 DESTROY

This is the destructor for the database kernel object, and it releases the database
handle to conserve resources.

=cut

sub DESTROY {
    my($self) = @_;

    my($dbh);
    if ($dbh = $self->{_dbh}) {
        $dbh->disconnect;
    }

}

=head3 prepare_command

Prepare a command for use against the database.

=over 4

=item commandText

Text of the command to be prepared.

=item RETURN

Returns a statement handle that can be used to execute the command.

=back

=cut

sub prepare_command {
    # Get the parameters.
    my ($self, $commandText, $attrs) = @_;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Prepare the command.
    my $sth = $dbh->prepare($commandText, $attrs) ||
        Confess("Command failed: $commandText\n");
    # Return it to the caller.
    return $sth;
}

=head3 set_demand_driven

    $dbh->set_demand_driven($flag);

Set the database to demand-driven mode. This means that queries will be
processed as results are demanded rather than being cached in memory when
the query is executed. Currently, this only works for MySQL.

=over 4

=item flag

TRUE to make the database demand-driven, else FALSE.

=back

=cut

sub set_demand_driven {
    # Get the parameters.
    my ($self, $flag) = @_;
    # Is this MySQL?
    if ($self->{_dbms} eq 'mysql') {
        # Yes, we can set the value. Convert it from boolean to an integer.
        my $flagValue = ($flag ? 1 : 0);
        # Store it in the handle.
        $self->{_dbh}->{mysql_use_result} = $flagValue;
        Trace("Queries will be demand-driven.") if $flag && T(SQL => 2);
    }
}


=head3 begin_tran

Begin a database transaction.

=cut

sub begin_tran {
    # Get the parameters.
    my ($self) = @_;
    # Turn off auto-commit.
    my $dbh = $self->{_dbh};
    $dbh->{AutoCommit} = 0;
}

=head3 commit_tran

Commit a database transaction.

=cut

sub commit_tran {
    # Get the parameters.
    my ($self) = @_;
    # Commit the transaction.
    my $dbh = $self->{_dbh};
    $dbh->commit;
    # Turn auto-commit back on.
    $dbh->{AutoCommit} = 1;
}

=head3 roll_tran

Roll back a database transaction.

=cut

sub roll_tran {
    # Get the parameters.
    my ($self) = @_;
    # Roll back the transaction.
    my $dbh = $self->{_dbh};
    $dbh->rollback;
    # Turn auto-commit back on.
    $dbh->{AutoCommit} = 1;
}

=head3 reload_table

    $dbh->reload_table($mode, $table, $flds, $xflds, $fileName, $keyList, $keyName, $estimates);

Reload a database table from a sequential file. If I<$mode> is C<all>, the table
will be dropped and re-created. If I<$mode> is C<some>, the data for the individual
items in I<$keyList> will be deleted before the table is loaded. Thus, the load
process is optimized for the type of reload.

This method can be used to drop and re-create a table without loading: simply
omit the I<$fileName> parameter. In this case, I<$keyList> and I<$keyName> are
ignored, since they specify what to do if the table is not dropped. If this
option is used, the load must be finished by calling L</finish_load>.

=over 4

=item mode

C<all> if we are reloading the entire table, C<some> if we are only reloading
specific entries.

=item table

Name of the table to reload.

=item flds

String defining the table columns, in SQL format. In general, this is a
comma-delimited set of field specifiers, each specifier consisting of the
field name followed by the field type and any optional qualifiers (such as
C<NOT NULL> or C<DEFAULT>); however, it can be anything that would appear
between the parentheses in a C<CREATE TABLE> statement. The order in which
the fields are specified is important, since it is presumed that is the
order in which they are appearing in the load file.

=item xflds

Reference to a hash that describes the indexes. The hash is keyed by index name.
The value is the index's field list. This is a comma-delimited list of field names
in order from most significant to least significant. If a field is to be indexed
in descending order, its name should be followed by the qualifier C<DESC>. For
example, the following I<$xflds> value will create two indexes, one for name followed
by creation date in reverse chronological order, and one for ID.

    { name_index => "name, createDate DESC", id_index => "id" }

=item fileName (optional)

Fully-qualified name of the file containing the data to load. Each line of the
file must correspond to a record, and the fields must be arranged in order and
tab-delimited. If the file name is omitted, the table is dropped and re-created
but not loaded. The user must then call L</finish_load> to finish the load
 process.

=item keyList (optional)

Reference to a list of the IDs for the objects being reloaded. This parameter is
only used if I<$mode> is C<some>.

=item keyName (optional)

Name of the key field containing the IDs in the keylist. If omitted, C<genome> is
assumed.

=item estimates (optional)

For a Mysql database, the estimated row size and row count. Used for creating
large MyISAM tables. A pair [$row_size, $row_count].

=back

=cut

sub reload_table {
    # Get the parameters.
    my ($self, $mode, $table, $flds, $xflds, $fileName, $keyList, $keyName, $estimates) = @_;
    # Create the return value. It defaults to unsuccessful. with no rows
    # loaded.
    my $retVal = 0E0;
    # Insure we can recover from errors.
    eval {
        # If we're in ALL mode, we drop and re-create the table. Otherwise,
        # we delete the obsolete objects.
	#
	# Before deleting the obsolete objs, we need to see if the table already exists.
	# We could have  updated the code such that we are now doing a reload on a
	# portion of a table that we haven't made yet.
	#

        if ( $mode eq 'all') {
            Trace("Recreating $table.") if T(Load => 2);
            $self->drop_table( tbl  => $table );
            $self->create_table( tbl  => $table, flds => $flds, estimates => $estimates );
            # For pre-indexed DBMSs, we want to create the indexes here.
            if ($self->{_preIndex}) {
                $self->create_indexes($table, $xflds);
            }
	} elsif (not $self->table_exists($table)) {
            $self->create_table( tbl  => $table, flds => $flds, estimates => $estimates );
            # For pre-indexed DBMSs, we want to create the indexes here.
            if ($self->{_preIndex}) {
                $self->create_indexes($table, $xflds);
            }
        } else {
            Trace("Clearing obsolete data from $table.") if T(Load => 2);
            foreach my $key ( @{$keyList} ) {
                local $self->{_dbh}->{RaiseError} = 1;
                my $qry = "DELETE FROM $table WHERE ( $keyName = \'$key\' )";

                eval {
                    $self->SQL($qry);
                };
                if ($@)
                {
                    warn "DB error on query $qry: $@\n";
                }
            }
        }
        # Only proceed if we want to load the table here.
        if ($fileName) {
            # The table is now ready for loading.
            Trace("Loading $table from $fileName.") if T(Load => 2);
            if (! -s $fileName) {
                Trace("Load file \'$fileName\' empty or not found.") if T(Load => 2);
            } else {
                my $count = $self->load_table( tbl  => $table, file => $fileName );
                Trace("$table loaded with $count rows.") if T(Load => 2);
            }
            # Do the post-processing. This will create the indexes if
            # we have not already done so.
            $self->finish_load($mode, $table, $xflds);
        } else {
            # The user is loading the table. Save the index info for the finish.
            $self->{_indexList} = $xflds;
        }
    };
    # Check for errors.
    if ($@) {
        Confess("Error loading $table: $@");
    }
}

=head3 last_insert_id

    my $id = $db->last_insert_id();

Return the ID of the last auto-increment record inserted.

=cut

sub last_insert_id {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal = $self->{_dbh}->last_insert_id(undef, undef, undef, undef);
    # Return the result.
    return $retVal;
}


=head3 finish_load

    my  = $db->finish_load($mode, $table, $indexes);

Finish up a table load. Unless the mode is C<all>, there's nothing to be done
here. If the mode is C<all> and the indexes need to be created after loading,
then they will be created here. Otherwise, nothing happens.

A C<finish_load> should only be called after starting a load with L</reload_table>.
If the data to load is in a single text file, then C<reload_table> can do the
entire job in place. In some cases, however, the load is coming from multiple
files and must be done manually by the client. When this happens, the
C<finish_load> method is used to perform any post-processing required by the
load.

=over 4

=item mode

C<all> if we are reloading the entire table, else C<some>.

=item table

Name of the table being loaded.

=item indexes

Reference to a hash describing the indexes (see L</reload_table> for details).
If omitted, the index specification from the last call to C<reload_table> will
be used.

=back

=cut
#: Return Type ;
sub finish_load {
    # Get the parameters.
    my ($self, $mode, $table, $indexes) = @_;
    # Default the index hash.
    if (!$indexes) {
        $indexes = $self->{_indexList};
    }
    if ($mode eq 'all' && !$self->{_preIndex}) {
        $self->create_indexes($table, $indexes);
    }
    # Analyze the table to speed queries.

    if (!$ENV{DBKERNEL_DEFER_VACUUM})
    {
	$self->vacuum_it($table);
    }
}

=head3 create_indexes

    $db->create_indexes($table, \%indexes, $noVacuum);

Create the indexes for a table. The list of indexes is expressed as a hash. The
key of the hash is the index name, and the value of the hash is the field list.

=over 4

=item table

Name of the table for which the indexes are to be created.

=item indexes

Reference to a hash that describes the indexes. The hash is keyed by index name.
The value is the index's field list. This is a comma-delimited list of field names
in order from most significant to least significant. If a field is to be indexed
in descending order, its name should be followed by the qualifier C<DESC>. For
example, the following I<$indexes> value will create two indexes, one for name followed
by creation date in reverse chronological order, and one for ID.

    { name_index => "name, createDate DESC", id_index => "id" }

=back

=cut
#: Return Type ;
sub create_indexes {
    # Get the parameters.
    my ($self, $table, $indexes) = @_;
    Trace("Creating indexes for $table.") if T(Load => 2);
    # Loop through the indexes in the index hash.
    for my $idxName (keys %{$indexes}) {
        Trace("Creating index $idxName.") if T(Load => 3);
        # Insure we can recover from errors.
        eval {
            $self->create_index( idx  => $idxName,
                tbl  => $table,
                type => "btree",
                flds => $indexes->{$idxName}
            );
        };
        if ($@) {
            Confess("Error creating index $idxName in $table: $@");
        }
    }
}

=head3 vacuum_it

    $db->vacuum_it($table1, $table2, ... $tableN);

Analyze the specified tables to improve the query performance.

=over 4

=item table1, table2, ... $tableN

List of tables to analyze.

=back

=cut

sub vacuum_it {
    my($self,@tables) = @_;
    my($table);

    my $dbh  = $self->{_dbh};
    my $dbms = $self->{_dbms};
    if (@tables == 0) {
        # Eventually we need to loop through all the tables for MySQL here.
        if ($dbms eq "Pg") {
            $self->SQL("VACUUM ANALYZE");
        }
    } else {
        foreach $table (@tables) {
            Trace("Analyzing table $table.") if T(2);
            if ($dbms eq "Pg") {
                $self->SQL("VACUUM ANALYZE $table");
            } elsif ($dbms eq "mysql") {
                $self->SQL("ANALYZE TABLE $table");
            }
        }
    }
}

=head3 flush_tables

    $db->flush_tables();

Flush the internal table cache. It is a good idea to do this periodically during a load.
Currently, only MySQL supports it.

=cut

sub flush_tables {
    # Get the parameters.
    my ($self) = @_;
    # Get the database type.
    my $dbms = $self->{_dbms};
    # If we're MySQL, execute the flush.
    if ($dbms eq "mysql") {
        $self->SQL("FLUSH TABLES");
    }
}

=head3 quote

	my $q = $db->quote();

Return the quote character used by this DBMS.

=cut

sub quote {
	my ($self) = @_;
	my $dbh = $self->{_dbh};
	return $dbh->get_info(29) || "";
}

=head3 estimate_table_size

    $db->estimate_table_size([list of files]);

Estimate the average row size and number of rows for the given set of files. Does this by reading the
first 100 lines of the first file, computing the total size of all the files, and extrapolating.

Returns ($row_size, $num_rows).

=cut

sub estimate_table_size
{
    my($self, $files) = @_;

    my $total_size = 0;
    foreach my $file (@$files) {
        my $size = -s $file;

        if (!defined($size))
        {
            confess "Cannot read $file: $!";
        }

        $total_size += $size;
    }

    #
    # Read 100 lines of the first file to get an average.
    #

    my($row_size, $max_rows);

    if (open(F, "<$files->[0]"))
    {
        my($count, $tot);
        while (<F>)
        {
            last if $. == 100;
            $count++;
            $tot += length($_);
        }
        close(F);
        $row_size = int($tot / $count);
    }
    else
    {
        confess "Cannot open $files->[0] for reading: $!\n";
    }

    $max_rows = int(1.1 * $total_size / $row_size);

    return ($row_size, $max_rows);
}

sub dbh
{
    my($self) = @_;
    return $self->{_dbh};
}

1;
