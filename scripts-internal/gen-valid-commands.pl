#
# generate the valid-commands block that goes into the
# InvocationService implementation.
#

use strict;
use Template;
use Data::Dumper;

my @groups;

my @dirs = ([modeling_scripts => 'Modeling scripts'],
	    [tree_scripts => 'Alignments and Trees scripts'],
            [scripts => 'CDMI Scripts'],
	    [anno_scripts => 'Annotation service scripts'],
	    [er_scripts => 'Entity Relationship scripts'],
#	    [iscripts => 'Iris Scripts'],
	    );


for my $dirent (@dirs)
{
    my($dir, $what) = @$dirent;
    my $items = [];
    my $group = { name => $dir, title => $what, items => $items };
    push(@groups, $group);

    opendir(D, $dir) or die "cannot opendir $dir: $!";
    my @list = sort { $a cmp $b } map { s/\.pl$//; $_ } grep { /^[a-zA-Z0-9_].*\.pl$/ } readdir(D);

    if (open(MORE, "<", "$dir/ADDITIONAL_SCRIPTS"))
    {
	while (<MORE>)
	{
	    if (/([a-zA-Z0-9_].*)\.pl/)
	    {
		push(@list, $1);
	    }
	}
	close(MORE);
    }
    
    for my $cmd (sort { $a cmp $b } @list)
    {
	my $item = { cmd => $cmd, link => '' };
	push(@$items, $item);
    }
}

my %data = ( groups => \@groups );
#print Dumper(\%data);
my $tmpl = Template->new();
$tmpl->process("ValidCommands.pm.tt", \%data);
