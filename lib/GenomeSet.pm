
package GenomeSet;

#
# This class manages a set of genomes.
#
# These are typically stored in the local database
#

use Moose;

require SeedUtils;
require SapGenome;
require SapGenomeFactory;
require GenomeSetDB;

has 'id' => (isa => 'Str', is => 'ro', required => 1);
has 'name' => (isa => 'Str', is => 'ro', required => 1);
has 'db' => (isa => 'GenomeSetDB', is => 'ro', required => 1);

sub genome_ids
{
    my($self) = @_;

    return $self->db->dbh->selectcol_arrayref(qq(SELECT genome_id
						 FROM genome_set_entry
						 WHERE genome_set_id = ?
						 ORDER BY idx), undef, $self->id);
}

sub genomes
{
    my($self) = @_;
    return [map { SapGenomeFactory->get_genome($_) }
	    @{$self->genome_ids}];
}

sub reference_genomes
{
    my($self) = @_;

    my $ids = $self->db->dbh->selectcol_arrayref(qq(SELECT genome_id
						    FROM genome_set_entry
						    WHERE genome_set_id = ? AND is_reference
						    ORDER BY idx), undef, $self->id);

    return [map { SapGenomeFactory->get_genome($_) } @$ids];
}
    

sub add_genome
{
    my($self, $genome, $is_reference) = @_;
    $self->db->dbh->begin_work();
    my $glist = $self->genome_ids;
    if (! grep { $_ eq $genome } @$glist)
    {
	my $r = $self->db->dbh->selectcol_arrayref(qq(SELECT MAX(idx)
						      FROM genome_set_entry
						      WHERE genome_set_id = ?), undef, $self->id);
	my $idx = ($r && @$r && $r->[0]) ? ($r->[0] + 1) : 1;
	$self->db->dbh->do(qq(INSERT INTO genome_set_entry (genome_set_id, idx, genome_id, is_reference)
			      VALUES (?, ?, ?, ?)), undef,
			   $self->id, $idx, $genome, ($is_reference ? 1 : 0));
    }
    $self->db->dbh->commit();
}

=head3 $set->load_feature_sets($set_file)

Load a file of feature-correspondence data. This data will be organized as
2-tuples (set-id, feature-id).

=cut

sub load_feature_sets
{
    my($self, $set_file) = @_;

    my $fh;
    open($fh, "<", $set_file) or die "Cannot open $set_file: $!";

    my $dbh = $self->db->dbh;
    $dbh->begin_work();

    my $sth = $dbh->prepare(qq(INSERT INTO feature_set_entry (genome_set_id, feature_set_id, feature_id)
			       VALUES (?, ?, ?)));
    my $me = $self->id;
    while (<$fh>)
    {
	chomp;
	my($set_id, $fid) = split(/\t/);
	$sth->execute($me, $set_id, $fid);
    }
    undef $sth;
    $dbh->commit();
}

sub corresponding_features
{
    my($self, $fid, $lc) = @_;

    my $genome_ids = $self->genome_ids;
    my %by_id;
    $by_id{$genome_ids->[$_]} = $_ foreach 0..$#$genome_ids;
    
    my $res = $self->db->dbh->selectcol_arrayref(qq(SELECT f2.feature_id
						    FROM feature_set_entry f1 JOIN feature_set_entry f2
						    	USING (genome_set_id, feature_set_id)
						    WHERE f1.feature_id = ? AND
						          f2.feature_id != ? AND
						    	  f1.genome_set_id = ?), undef, $fid, $fid, $self->id);

    #
    # See if we got hits for all our genomes; if we did not, try
    # using the local correspondences to fill them in.
    #

    if ($lc)
    {
	my %genomes = map { $_ => 1 } @{$self->genome_ids};
	for my $hit (@$res)
	{
	    my $hg = SeedUtils::genome_of($hit);
	    delete $genomes{$hg};
	}
	if (%genomes)
	{
	    my $extra = $lc->corresponding_pegs(id => $fid, in_genome_list => [keys %genomes]);
	    push(@$res, map { $_->[0] } @$extra);
	}
    }

    @$res = sort { $by_id{SeedUtils::genome_of($a)} <=> $by_id{SeedUtils::genome_of($b)} } @$res;
    return $res;
	
}

=head3 $res = $set->get_aux_data($fid, $type)

Return the auxiliary data if any for this fid. If type is omitted all data types are returned.
Result is a list of pairs [type, data].

=cut

sub get_aux_data
{
    my($self, $fid, $type) = @_;
    my $sel = "";
    if ($type)
    {
	$sel = "AND data_type = " . $self->db->dbh->quote($type);
    }
	
    my $res = $self->db->dbh->selectall_arrayref(qq(SELECT data_type, data_tag, data
						    FROM feature_aux_data
						    WHERE genome_set_id = ? AND
						    	feature_id = ?
						    	$sel), undef, $self->id, $fid);
    return $res;
}

1;
