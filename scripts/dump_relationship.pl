use strict;
use Data::Dumper;
use File::Copy;
use Getopt::Long;
use XML::LibXML;
use Bio::KBase::CDMI::CDMI;
use String::CamelCase 'camelize';

#
# This is a SAS Component
#

=head1 NAME

dump_relationship

=head1 SYNOPSIS

dump_relationship relname > output

=head1 DESCRIPTION

Dump all the from/to data for the given relname. This command talks directly to the Sapling database
and thus must run within the KB infrastructure (in other words, this is not a general purpose command).

Example:

   dump_relationship relname > output

=head1 COMMAND-LINE OPTIONS

Usage: dump_relationship relname > output

=over 4

=item relname

Name of the relationship to dump.

=back

=head2 Output Format

Tab delimited file containing to and from links for the given relationship.

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

my $camelize;

my $rc = GetOptions(camelize => \$camelize);

$rc && @ARGV == 1 or die "Usage: $0 relname [--camelize]  > tab-sep-output\n";

my $relname = shift;

if ($camelize)
{
    $relname = camelize($relname);
}


my $cdmi = Bio::KBase::CDMI::CDMI->new;

my $dbh = $cdmi->{_dbh}->{_dbh};

my $sth = $dbh->prepare(qq(SELECT from_link, to_link from $relname), { mysql_use_result => 1 });
$sth->execute();
while (my $r = $sth->fetchrow_arrayref())
{
    print join("\t", @$r), "\n";
}




__DATA__
