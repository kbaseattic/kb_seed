use Bio::KBase::CDMI::CDMI;
use strict;
use Data::Dumper;
use Encode;

my $cdmi = Bio::KBase::CDMI::CDMI->new_for_script();
my $q = $cdmi->{_dbh}->quote;

@ARGV == 1 or die "Usage: $0 entity-to-index\n";

my $entity_name = shift;

my $ehash = $cdmi->GetObjectsTable('entity');
my $entity = $ehash->{$entity_name};

my @field_names;
my @index_names;
my @index_types;
my @join;

push(@field_names, 'me.id');
push(@index_names, 'kbid');
push(@index_types, 'attr="string"');

if ($entity->{FulltextIndexes})
{
    my $ixlist = $entity->{FulltextIndexes}->{FulltextIndex};
    $ixlist = [$ixlist] unless ref($ixlist) eq 'ARRAY';
    for my $ix (@$ixlist)
    {
	if ($ix->{type} eq 'field')
	{
	    my $f = $ix->{name};
	    $f =~ s/-/_/g;
	    push(@field_names, "me.$q$f$q");
	    push(@index_names, $f);
	    if ($ix->{in_result})
	    {
		push(@index_types, 'attr="string"');
	    }
	    else
	    {
		push(@index_types, '');
	    }
	}
	elsif ($ix->{type} eq 'related_field')
	{
	    my $jidx = scalar(@join) + 1;

	    if ($ix->{path} =~ /^(\S+)\s+(\S+)\s+(\S+)$/)
	    {
		my($rel, $targ, $rel2) = ($1, $2, $3);
		my $real_rel = $cdmi->_Resolve($rel);
		my $real_rel2 = $cdmi->_Resolve($rel2);

		my($from, $to) = ("from_link", "to_link");
		($from, $to) = ($to, $from) if $real_rel ne $rel;

		my($from2, $to2) = ("from_link", "to_link");
		($from2, $to2) = ($to2, $from2) if $real_rel2 ne $rel2;

		my $R = "r$jidx";
		my $T = "t$jidx";
		my $R2 = "rr$jidx";

		my $join = "LEFT OUTER JOIN $real_rel $R ON me.id = $R.$from JOIN $targ $T ON $T.id = $R.$to";
		$join .= " JOIN $real_rel2 $R2 ON $T.id = $R2.$from2";
		push(@join, $join);

		my $flist = $ix->{UseField};
		$flist = [$flist] if ref($flist) ne 'ARRAY';
		for my $fent (@$flist)
		{
		    my $f = $fent->{field};
		    $f =~ s/-/_/g;
		    push(@field_names, "$R2.$q$f$q");
		    push(@index_names, $fent->{name});
		    if ($fent->{in_result})
		    {
			push(@index_types, 'attr="string"');
		    }
		    else
		    {
			push(@index_types, '');
		    }
		}
	    }
	    elsif ($ix->{path} =~ /^(\S+)\s+(\S+)$/)
	    {
		my($rel, $targ) = ($1, $2);
		my $real_rel = $cdmi->_Resolve($rel);

		my($from, $to) = ("from_link", "to_link");
		($from, $to) = ($to, $from) if $real_rel ne $rel;

		my $R = "r$jidx";
		my $T = "t$jidx";

		my $join = "LEFT OUTER JOIN $real_rel $R ON me.id = $R.$from JOIN $targ $T ON $T.id = $R.$to";
		push(@join, $join);

		my $flist = $ix->{UseField};
		$flist = [$flist] if ref($flist) ne 'ARRAY';
		for my $fent (@$flist)
		{
		    my $f = $fent->{field};
		    $f =~ s/-/_/g;
		    push(@field_names, "$T.$q$f$q");
		    push(@index_names, $fent->{name});
		    if ($fent->{in_result})
		    {
			push(@index_types, 'attr="string"');
		    }
		    else
		    {
			push(@index_types, '');
		    }
		}
	    }
	    elsif ($ix->{path} =~ /^(\S+)$/)
	    {
		my($rel) = ($1);
		my $real_rel = $cdmi->_Resolve($rel);

		my($from, $to) = ("from_link", "to_link");
		($from, $to) = ($to, $from) if $real_rel ne $rel;

		my $R = "r$jidx";

		my $join = "LEFT OUTER JOIN $real_rel $R ON me.id = $R.$from";
		push(@join, $join);

		my $flist = $ix->{UseField};
		$flist = [$flist] if ref($flist) ne 'ARRAY';
		for my $fent (@$flist)
		{
		    my $f = $fent->{field};
		    $f =~ s/-/_/g;
		    push(@field_names, "$R.$q$f$q");
		    push(@index_names, $fent->{name});
		    if ($fent->{in_result})
		    {
			push(@index_types, 'attr="string"');
		    }
		    else
		    {
			push(@index_types, '');
		    }
		}
	    }
	    else
	    {
		die "Unsupported path $ix->{path}";
	    }
	}
    }
}
else
{
    while (my($fname, $field) = each %{$entity->{Fields}})
    {
	if ($field->{fulltext_index})
	{
	    $fname =~ s/-/_/g;
	    push(@field_names, "$q$fname$q");
	    push(@index_names, $fname);
	    push(@index_types, 'attr="string"');
	}
    }
}
exit 0 unless @index_names;


print <<END;
<?xml version="1.0" encoding="utf-8"?>
<sphinx:docset>
<sphinx:schema>
END

for my $i (0..$#index_names)
{
    print "  <sphinx:field name=\"$index_names[$i]\" $index_types[$i]/>\n";
}
print "</sphinx:schema>\n";

my $dbh = $cdmi->{_dbh}->{_dbh};
my %attrs;
if ($cdmi->{_dbh}->dbms eq 'mysql')
{
    $attrs{mysql_use_result} = 1;
}

my $fname_str = join(", ", @field_names);

my $qry = qq(SELECT $fname_str FROM $entity_name me @join);
print STDERR "$qry\n";
my $sth = $dbh->prepare($qry, \%attrs);
$sth->execute();
my $docid = 1;
while (my $row = $sth->fetchrow_arrayref())
{
    print "<sphinx:document id='$docid'>\n";
    for (my $i = 0; $i < @field_names; $i++)
    {
	print "<$index_names[$i]>" . escape($row->[$i]) . "</$index_names[$i]>\n";
    }
    print "</sphinx:document>\n";
    $docid++;
}
print "</sphinx:docset>\n";

sub escape
{
    my($s) = @_;
    return "" unless defined($s);
    $s =~ s/\\n/\n/g;
    $s = encode_utf8($s);
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}
