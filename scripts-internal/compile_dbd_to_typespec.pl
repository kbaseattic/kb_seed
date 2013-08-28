use strict;
use Data::Dumper;
use XML::LibXML;
#use String::CamelCase 'decamelize';
use Template;
#use Bio::KBase::KIDL::KBT;
use Bio::KBase::CDMI::Templates::TemplateUtil;
use Getopt::Long;

=head1 NAME

compile_dbd_to_typespec

=head1 SYNOPSIS

compile_dbd_to_typespec service-name module-name DBD-xml-file spec-file impl-file bin-dir

=head1 DESCRIPTION

compile_dbd_to_typespec creates the type specification, implementation module, and command
line scripts for an ERDB database as defined by its XML specification.

=head1 COMMAND-LINE OPTIONS

Usage: compile_dbd_to_typespec [--doc documentation-file] service-name module-name DBD-xml-file spec-file impl-file bin-dir

=head1 AUTHORS

Robert Olson, Argonne National Laboratory, olson@mcs.anl.gov

=cut

my $help;
my $doc_file;
my $rc = GetOptions("h|help" => \$help,
		    "doc=s" => \$doc_file);    

if (!$rc || $help || @ARGV < 6)
{
    seek(DATA, 0, 0);
    while (<DATA>)
    {
	last if /^=head1 COMMAND-LINE /;
    }
    while (<DATA>)
    {
	last if /^=/;
	print $_;
    }
    exit($help ? 0 : 1);
}


my $service = shift;
my $module = shift;
my $in_file = shift;
my $out_file = shift;
my $impl_file = shift;
my $bin_dir = shift;

-d $bin_dir or die "bin-dir $bin_dir does not exist\n";

my $doc = XML::LibXML->new->parse_file($in_file);
$doc or die "cannot parse $in_file\n";

my %type_map = (boolean	    => 'int',
		'semi-boolean'	=> 'string',
		char	    => 'string',
		countVector => 'countVector',
		counter	    => 'int',
		date	    => 'string',
		diamond	    => 'diamond',
		dna	    => 'string',
		float	    => 'float',
		image	    => 'string',
		int	    => 'int',
		link	    => 'string',
		rectangle   => 'rectangle',
		string	    => 'string',
		'long-string'	    => 'string',
		text	    => 'string',
		);


my %kids;
my %names;

for my $r ($doc->findnodes('//Relationships/Relationship'))
{
    my $n = $r->getAttribute("name");
    my $arity = $r->getAttribute("arity");
    my $from = $r->getAttribute("from");
    my $to = $r->getAttribute("to");
    my $converse = $r->getAttribute("converse");
    
    die "Duplicate name detected in relationship: $n" if $names{$n};
    die "Duplicate name detected in converse relationship: $converse" if $names{$converse};
	
	$names{$n} = 1;
	$names{$converse} = 1;
	
    push(@{$kids{$from}}, {name => $n, to => $to});
    push(@{$kids{$to}}, {name => $converse, to => $from});
}

for my $e ($doc->findnodes('//Entities/Entity')) 
{
	my $n = $e->getAttribute("name");
	die "Duplicate name detected in entity: $n" if $names{$n};
	$names{$n} = 1
}

my $entities = [];
my $relationships = [];
my $template_data = {
    entities => $entities,
    entities_by_name => {},
    relationships => $relationships,
    module => $module,
    service => $service,
};

open(IMPL, ">", $impl_file) or die "cannot write $impl_file: $!";

for my $e (sort { $a->getAttribute("name") cmp $b->getAttribute("name") }  $doc->findnodes('//Entities/Entity'))
{
    my $n = $e->getAttribute("name");
    my @cnode = $e->getChildrenByTagName("Notes");
    my $com = join("\n", map { my $s = $_->textContent; $s =~ s/^\s*//gm; $s } @cnode);
    my $keyType = $e->getAttribute("keyType");
    # my $nn = decamelize($n);
    my $nn = $n;

    my $field_map = [];

    my $edata = {
	name 	     => $nn,
	sapling_name => $n,
	field_map    => $field_map,
	comment      => $com,
	key_type     => $keyType,
    };
    push(@$entities, $edata);
    $template_data->{entities_by_name}->{$n} = $edata;

    my @fields = $e->findnodes('Fields/Field');
    # next if @fields == 0;

    my $id_ftype = $type_map{$keyType};

    #
    # Relationship linkages.
    #
    $edata->{relationships} = [ sort { $a->{name} cmp $b->{name} } @{$kids{$n}} ];

    $com .= "\nIt has the following fields:\n\n=over 4\n\n";
    for my $f (@fields)
    {
	my $fn = $f->getAttribute("name");
	# my $fnn = decamelize($fn);
	my $fnn = $fn;

	my $field_rel = $f->getAttribute("relation");

	$fnn =~ s/-/_/g;

	my $ftype = $type_map{$f->getAttribute("type")};

	my $field_ent = {
	    name => $fnn,
	    sapling_name => $fn,
	    type => $f->getAttribute("type"),
	    mapped_type => $ftype,
	};
	
	push(@$field_map,$field_ent);
	
	if ($field_rel)
	{
	    $field_ent->{field_rel} = $field_rel;
	}

	my @fcnode = $f->getChildrenByTagName("Notes");
	my $fcom = join("\n", map { my $s = $_->textContent; $s =~ s/^\s*//gm; $s } @fcnode);
	$field_ent->{notes} = $fcom;
	$field_ent->{notes} =~ s/\n/ /gs;

	$com .= "\n=item $fnn\n\n$fcom\n\n";
    }

    $edata->{field_list} = join(", ", map { "'$_->{name}'" } @$field_map);
    $com .= "\n\n=back\n\n";
}

for my $e (sort { $a->getAttribute("name") cmp $b->getAttribute("name") }  $doc->findnodes('//Relationships/Relationship'))
{
    my $n = $e->getAttribute("name");
    my $from = $e->getAttribute("from");
    my $to = $e->getAttribute("to");
    my $converse = $e->getAttribute("converse");
    
    my @cnode = $e->getChildrenByTagName("Notes");
    my $com = join("\n", map { my $s = $_->textContent; $s =~ s/^\s*//gm; $s } @cnode);

    # my $nn = decamelize($n);
    my $nn = $n;

    my $field_map = [];

    my $from_ftype = $type_map{$template_data->{entities_by_name}->{$from}->{key_type}};
    my $to_ftype = $type_map{$template_data->{entities_by_name}->{$to}->{key_type}};

    my $edata = {
	name 	     => $nn,
	sapling_name => $n,
	field_map    => $field_map,
	from_type    => $from_ftype,
	to_type      => $to_ftype,
	relation     => $nn,
	is_converse  => 0,
	converse_name => $converse,
	from 	     => $from,
	to 	     => $to,
	comment      => $com,
	from_data    => $template_data->{entities_by_name}->{$from},
	to_data      => $template_data->{entities_by_name}->{$to},
    };
    push(@$relationships, $edata);

    my $rev_edata = {
	name 	     => $converse,
	sapling_name => $converse,
	relation     => $nn,
	from_type    => $to_ftype,
	to_type      => $from_ftype,
	is_converse  => 1,
	forward_name => $nn,
	field_map    => $field_map,
	from 	     => $to,
	to 	     => $from,
	comment      => $com,
	from_data    => $template_data->{entities_by_name}->{$to},
	to_data      => $template_data->{entities_by_name}->{$from},
    };
    push(@$relationships, $rev_edata);

    my @fields = $e->findnodes('Fields/Field');

    $com .= "\nIt has the following fields:\n\n=over 4\n\n";
    for my $f (@fields)
    {
	my $fn = $f->getAttribute("name");
	# my $fnn = decamelize($fn);
	my $fnn = $fn;

	my $field_rel = $f->getAttribute("relation");
	$fnn =~ s/-/_/g;

	my $ftype = $type_map{$f->getAttribute("type")};

	my $field_ent = {
	    name => $fnn,
	    sapling_name => $fn,
	    type => $f->getAttribute("type"),
	    mapped_type => $ftype,
	};
	push(@$field_map,$field_ent);

	
	if ($field_rel)
	{
	    $field_ent->{field_rel} = $field_rel;
	}

	my @fcnode = $f->getChildrenByTagName("Notes");
	my $fcom = join("\n", map { my $s = $_->textContent; $s =~ s/^\s*//gm; $s } @fcnode);

	$com .= "\n=item $fnn\n\n$fcom\n\n";

	$field_ent->{notes} = $fcom;
	$field_ent->{notes} =~ s/\n/ /gs;
    }

    $edata->{field_list} = join(", ", map { "'$_->{name}'" } @$field_map);
    $rev_edata->{field_list} = join(", ", map { "'$_->{name}'" } @$field_map);
    $com .= "\n\n=back\n\n";
}

# print Dumper($template_data);

# Templates were previously deployed with typecomp, and could be found by finding the typecomp
# install directory.  The templates have been migrated to the kb_seed repo, and as such are found
# by a similar method in Bio::KBase::CDMI -msneddon
#my $tmpl_dir = Bio::KBase::KIDL::KBT->install_path;  #previous template location lookup
my $tmpl_dir = Bio::KBase::CDMI::Templates::TemplateUtil->install_path;

my $tmpl = Template->new({ OUTPUT_PATH => '.',
			       ABSOLUTE => 1,
			   });

open(my $fh, ">", $out_file) or die "Cannot open $out_file for writing: $!";
$tmpl->process("$tmpl_dir/sapling_spec.tt", $template_data, $fh) || die Template->error;
close($fh);
if ($doc_file)
{
    open(my $fh, ">", $doc_file) or die "Cannot open $doc_file for writing: $!";
    $tmpl->process("$tmpl_dir/sapling_doc.tt", $template_data, $fh) || die Template->error;
    close($fh);
}

# we now require a prefix before script names; here we add the prefix, but generate
# a list of script names in the old deprecated style which can be used to generate
# the new COMMANDS.json format -msneddon
my $prefix = 'er';
my $deprecated_cmd_list = [];


for my $entity (@{$entities})
{
    my %d = %$template_data;
    $d{entity} = $entity;
    
    open(my $fh, ">", "$bin_dir/$prefix-get-entity-$entity->{name}.pl") or die "cannot write $bin_dir/$prefix-get-entity-$entity->{name}.pl: $!";
    push(@$deprecated_cmd_list, {
                                 old_style_name=>"get_entity_$entity->{name}",
                                 new_style_name=>"$prefix-get-entity-$entity->{name}",
                                 file_name=>"$bin_dir/$prefix-get-entity-$entity->{name}.pl",
                                 } );
    $tmpl->process("$tmpl_dir/get_entity.tt", \%d, $fh) || die Template->error;
    close($fh);
    
    open(my $fh, ">", "$bin_dir/$prefix-all-entities-$entity->{name}.pl") or die "cannot write $bin_dir/$prefix-all-entities-$entity->{name}.pl: $!";
    push(@$deprecated_cmd_list, {
                                 old_style_name=>"all_entities_$entity->{name}",
                                 new_style_name=>"$prefix-all-entities-$entity->{name}",
                                 file_name=>"$bin_dir/$prefix-all-entities-$entity->{name}.pl",
                                 } );
    $tmpl->process("$tmpl_dir/all_entities.tt", \%d, $fh) || die Template->error;
    close($fh);
    
    open(my $fh, ">", "$bin_dir/$prefix-query-entity-$entity->{name}.pl") or die "cannot write $bin_dir/$prefix-query-entity-$entity->{name}.pl: $!";
    push(@$deprecated_cmd_list, {
                                 old_style_name=>"query_entity_$entity->{name}",
                                 new_style_name=>"$prefix-query-entity-$entity->{name}",
                                 file_name=>"$bin_dir/$prefix-query-entity-$entity->{name}.pl",
                                 } );
    $tmpl->process("$tmpl_dir/query_entity.tt", \%d, $fh) || die Template->error;
    close($fh);
}

for my $rel (@{$relationships})
{
    my %d = %$template_data;
    $d{relationship} = $rel;
    open(my $fh, ">", "$bin_dir/$prefix-get-relationship-$rel->{name}.pl") or die "cannot write $bin_dir/$prefix-get-relationship-$rel->{name}.pl: $!";
    push(@$deprecated_cmd_list, {
                                 old_style_name=>"get_relationship_$rel->{name}",
                                 new_style_name=>"$prefix-get-relationship-$rel->{name}",
                                 file_name=>"$bin_dir/$prefix-get-relationship-$rel->{name}.pl",
                                 } );
    $tmpl->process("$tmpl_dir/get_relationship.tt", \%d, $fh) || die Template->error;
    close($fh);
}
$tmpl->process("$tmpl_dir/sapling_impl.tt", $template_data, \*IMPL) || die Template->error;

# finally, we use the deprecated file list to generate the COMMANDS.json file -msneddon
my $deprecated_cmd_data = {deprecated_cmd_list=>$deprecated_cmd_list};
open(my $deprecated_list_fh, ">", "COMMANDS.json") or die "cannot write COMMANDS.json: $!";
$tmpl->process("$tmpl_dir/commands_json.tt",$deprecated_cmd_data, $deprecated_list_fh) || die Template->error;


__DATA__
