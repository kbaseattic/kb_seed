package LocalCorrespondences;

use strict;
use Data::Dumper;
use DBI;
use CorrTableEntry;
use SAP;
use GenomeSet;
use Fcntl ':seek';

use Moose;
use MooseX::Params::Validate;

has 'sap' => (isa => 'SAP', is => 'ro', required => 1);
has 'database_file' => (isa => 'Str', is => 'ro', required => 1);

has 'dbh' => (isa => 'DBI::db', is => 'ro', lazy => 1, builder => '_build_dbh');

use constant ARROW_FLIP => { '->' => '<-', '<=>' => '<=>', '<-' => '->' };
use constant VALID_COMPS => {
    psc => '<',
    iden => '>',
    hitinfo => '=',
};
	

sub _build_dbh
{
    my($self) = @_;
    my $dbh = DBI->connect("dbi:SQLite:" . $self->database_file);
    return $dbh;
}

sub corresponding_pegs
{
    my($self, %params) = validated_hash(\@_,
					id => { isa => 'Str' },
					psc => { isa => 'Num', optional => 1 },
					iden => { isa => 'Num', optional => 1 },
					hitinfo => { isa => 'Str', optional => 1, default => '<=>' },
					full => { isa => 'Bool', default => 0, optional => 1 },
					as_corr_entry => { isa => 'Bool', default => 0, optional => 1 },
					in_set => { isa => 'Maybe[GenomeSet]', optional => 1 },
					in_genome_list => { isa => 'Maybe[ArrayRef[Str]]', optional => 1 },
					);

    my @where;
    my @qparams;

    $params{full} = 1 if $params{as_corr_entry};
    
    for my $tblkey (keys %{VALID_COMPS()})
    {
	if (exists($params{$tblkey}))
	{
	    push(@where, "$tblkey " . VALID_COMPS->{$tblkey} . " ?");
	    push(@qparams, $params{$tblkey});
	}
    }

    my @fields = qw(hitinfo iden psc);
    push(@fields, 'data') if ($params{full});

    my @out;

    #
    # Query forward
    #

    my @Qfields = ("id2", @fields);
    my @Qwhere = ("id1 = ?", @where);
    my @Qparams = ($params{id}, @qparams);

    my $where = join(" AND ", @Qwhere);
    my $fields = join(", ", @Qfields);

    $self->dbh->begin_work();

    my $q = qq(SELECT $fields
	       FROM corr
	       WHERE $where);
#    print "q=$q\n";
#    print "Params: \n";
#    print "\t$_\n" foreach @Qparams;
    my $res = $self->dbh->selectall_arrayref($q, undef, @Qparams);

    if ($params{as_corr_entry})
    {
	push(@out, map { CorrTableEntry->new($_->[4]) } @$res);
    }
    else
    {
	push(@out, @$res);
    }

    #
    # Query backward
    #
    @Qfields = ("id1", @fields);
    @Qwhere = ("id2 = ?", @where);
    @Qparams = ($params{id}, @qparams);

    $where = join(" AND ", @Qwhere);
    $fields = join(", ", @Qfields);
    
    $q = qq(SELECT $fields
	       FROM corr
	       WHERE $where);
#    print "q=$q\n";
#    print "Params: \n";
#    print "\t$_\n" foreach @Qparams;
    $res = $self->dbh->selectall_arrayref($q, undef, @Qparams);

    if ($params{as_corr_entry})
    {
	push(@out, map {
	    my $e = CorrTableEntry->new($_->[4]);
	    ReverseGeneCorrespondenceRow($e);
	    $e;
	} @$res);
    }
    else
    {
	push(@out, @$res);
    }

    #
    # If we have a genome set, filter on it.
    #
    my $limit_re;
    if ($params{in_set})
    {
	$limit_re = join("|", map { quotemeta($_) } @{$params{in_set}->genome_ids});
    }
    elsif ($params{in_genome_list})
    {
	$limit_re = join("|", map { quotemeta($_) } @{$params{in_genome_list}});
    }
    if ($limit_re)
    {
	if ($params{as_corr_entry})
	{
	    @out = grep { $_->id2 =~ /fig\|($limit_re)\./} @out;
	}
	else
	{
	    @out = grep { $_->[0] =~ /fig\|($limit_re)\./} @out;
	}
    }
						     
    #
    # Ensure we have local data about these pegs.
    #

    my @pegs = $params{as_corr_entry} ?
	(map { $_->id2 } @out) :
	    (map { $_->[0] } @out);

    my @ipegs = SapFeatureFactory->instance->get_features(fids => \@pegs, inflate => 1);

    my %ok;
    $ok{$_->fid} = 1 foreach grep { defined($_->location) } @ipegs;

    $self->dbh->commit();

    if ($params{as_corr_entry})
    {
	return [ grep { $ok{$_->id2 } } @out ];
    }
    else
    {
	return [ grep { $ok{$_->[0]} } @out ];
    }
}

sub init_schema
{
    my($self) = @_;
    my $dbh = $self->dbh;
    $dbh->do(qq(DROP TABLE corr));
    $dbh->do(qq(CREATE TABLE corr
		(
		 id1 varchar(64),
		 id2 varchar(64),
		 hitinfo varchar(4),
		 iden integer,
		 psc float,
		 data varchar(255)
		)));
    $dbh->do(qq(create index corr_idx on corr(id1)));
    $dbh->do(qq(create index corr_idx2 on corr(id2)));
}

sub load_file
{
    my($self, $g, $g2, $ref) = @_;

    if (!open(R, "<", $ref))
    {
	
	warn "cannot open $ref: $!";
	return;
    }

    $self->dbh->begin_work();
    my $sth = $self->dbh->prepare(qq(INSERT INTO corr (id1, id2, hitinfo, iden, psc, data)
				     VALUES (?, ?, ?, ?, ?, ?)));


    my $flip;
    if ($g)
    {
	$g = MustFlipGenomeIDs($g, $g2);
    }
    else
    {
	my $l = <R>;
	if ($l =~ /^fig\|(\d+\.\d+)\S+\tfig\|(\d+\.\d+)/)
	{
	    $flip = MustFlipGenomeIDs($1, $2);
	    print "$1 $2 flip=$flip\n";
	}
	seek(R, 0, SEEK_SET);
    }
    
    while (defined(my $row = <R>))
    {
	chomp $row;
	my @a = split(/\t/, $row);
	
	if ($flip)
	{
	    ReverseGeneCorrespondenceRow(\@a);
	    $row = join("\t", @a);
	}
	
	my $id1 = $a[0];
	my $id2 = $a[1];
	my $hitinfo = $a[8];
	my $iden = $a[9];
	my $psc = $a[10];
	
	#		$a[3] =~ s/fig\|//g;
	
	#		my $data = join("\t", @a[2,3,4,5,6,7,11-$#a]);
	
	if (!$id1 && $id2)
	{
	    warn "Bad line $. in $ref\n";
	    next;
	}
	#		my $comp = compress($_);
	#		my $dlen = length($_);
	#		my $clen = length($comp);
	
	#		print "$id1 $id2 => $iden $psc\n";
	
	#		$id1 =~ s/^fig\|//;
	#		$id2 =~ s/^fig\|//;
	
	
	$sth->execute($id1, $id2, $hitinfo, $iden, $psc, $row);
	
    }
    $self->dbh->commit();
}

sub ReverseGeneCorrespondenceRow {
    # Get the parameters.
    my ($row) = @_;
    # Flip the row in place.
    ($row->[1], $row->[0], $row->[2], $row->[3], $row->[5], $row->[4], $row->[7],
     $row->[6], $row->[8], $row->[9], $row->[10], $row->[14],
     $row->[15], $row->[16], $row->[11], $row->[12], $row->[13], $row->[17]) = @$row;
    # Flip the arrow.
    $row->[8] = ARROW_FLIP->{$row->[8]};
    # Flip the pairs.
    my @elements = split /,/, $row->[3];
    $row->[3] = join(",", map { join(":", reverse split /:/, $_) } @elements);
}
sub MustFlipGenomeIDs {
    # Get the parameters.
    my ($genome1, $genome2) = @_;
    # Return an indication.
    return ($genome1 gt $genome2);
}

1;
