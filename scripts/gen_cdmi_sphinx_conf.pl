use strict;
use Data::Dumper;
use Template;
use XML::Simple;

@ARGV > 2 or die "Usage: $0 DBD-file template-file [defines]\n";

my $dbd_file = shift;
my $template_file = shift;

-f $dbd_file or die "DBD file $dbd_file does not exist\n";
-f $template_file or die "template file $template_file does not exist\n";


my %params;

while (@ARGV)
{
    my $arg = shift;
    $arg eq '--define' || die "Invalid argument $arg";
    $arg = shift;
    my($k, $v) = split(/=/, $arg, 2);
    $k && $v or die "Invalid argument $arg";
    $params{$k} = $v;
}

my $dbd = XMLin($dbd_file);
$dbd or die "Cannot read dbd file $dbd_file: $!";

my $ehash = $dbd->{Entities}->{Entity};

my $entities = [];
while (my($entity_name, $entity) = each %$ehash)
{
    next unless $entity->{FulltextIndexes};

    push(@$entities, $entity_name);
}
print STDERR "@$entities\n";

$params{entities} = $entities;

print STDERR Dumper(\%params);

my $templ = Template->new;
$templ->process($template_file, \%params) || die Template->error;
