package SproutQuery;

use strict;
use Tracer;
use Sprout;
use ERDB;
use SFXlate;

my $sprout = SFXlate->new_sprout_only();
my $erdb = $sprout;
my $dbh = $erdb->{_dbh};

sub get_field {

    my($table, $field, $limit) = @_;

    my $rv = $dbh->SQL("SELECT $field FROM $table");
    return map { $_->[0] } @$rv;

}
