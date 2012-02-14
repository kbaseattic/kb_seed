
package GenomeLoader;

=head1 NAME

GenomeLoader - class for loading genomes into myRAST

=head2 DESCRIPTION

A GenomeLoader is a simple class that wraps up the creation of
needed prerequisites for loading a genome into Sapling as well
as the Sapling calls needed to do it.

=cut

use strict;
use Moose;
use myRAST;
use File::Basename;
use SaplingGenomeLoader;

has 'all_genomes' => (isa => 'HashRef', is => 'rw', lazy => 1,
		      builder => '_build_all_genomes');

sub _build_all_genomes
{
    my($self) = @_;
    return myRAST->instance->sap->all_genomes();
}

sub genome_present
{
    my($self, $genome) = @_;
    return $self->all_genomes->{$genome};
}

sub load_genome
{
    my($self, $dir, $force) = @_;
    
    my $genome = basename($dir);

    if ($genome !~ /^\d+\.\d+$/)
    {
	warn "Invalid genome dir $dir\n";
	return undef;
    }
    
    if (my $name = $self->genome_present($genome) && !$force)
    {
	warn "Already have $genome $name\n";
	return;
    }

    #
    # push empty subsystems in if missing.
    #
    if (! -d "$dir/Subsystems")
    {
	mkdir("$dir/Subsystems");
	print STDERR "Create $dir/Subsystems\n";
    }

    for my $f (qw(subsystems bindings))
    {
	my $p = "$dir/Subsystems/$f";
	if (! -f $p)
	{
	    print STDERR "Create empty $p\n";
	    open(P, ">", $p);
	    close(P);
	}
    }

    my $name;
    if (open(G, "<", "$dir/GENOME"))
    {
	$name = <G>;
	chomp $name;
	close(G);
    }
    else
    {
	$name = "genome $genome";
	open(G, ">", "$dir/GENOME");
	print G "$name\n";
	close(G);
    }

    if (! -f "$dir/TAXONOMY")
    {
	open(G, ">", "$dir/TAXONOMY");
	print G "$name\n";
	close(G);
    }

    my $sapling = myRAST->instance->sapling;
    
    $sapling->BeginTran();
    my $stats = SaplingGenomeLoader::Process($sapling, $genome, $dir, 1);
    $sapling->CommitTran();
    if (open(X, ">", "$dir/SAPLING_LOAD_STATS"))
    {
	print X "Genome load stats:\n " . $stats->Show();
	close(X);
    }
    else
    {
	warn "Cannot open $dir/SAPLING_LOAD_STATS: $!";
    }
    return 1;
}

sub load_pangenome
{
    my($self, $pg_dir, $force, $status_cb) = @_;
    $status_cb //= sub { print @_; };

    -d $pg_dir or die "Pangenome dir $pg_dir does not exist\n";

    my $gsdb = myRAST->instance->genome_set_db;
    my $sap = myRAST->instance->sap;

    opendir(D, "$pg_dir/Genomes") or die "Cannot open $pg_dir/Genomes: $!";

    my @genomes = sort { $a <=> $b } grep { /^\d+\.\d+$/ && -d "$pg_dir/Genomes/$_" } readdir(D);

    my $n = @genomes;
    for my $i (0..$#genomes)
    {
	my $genome = $genomes[$i];
	if ($self->genome_present($genome) && !$force)
	{
	    $status_cb->("Genome $genome is already loaded\n");
	    next;
	}

	my $dir = "$pg_dir/Genomes/$genome";
	$status_cb->("Loading genome " . ($i + 1) . " of $n from $dir\n");
	my $ok = $self->load_genome($dir, $force);
	if ($ok)
	{
	    $status_cb->("Genome loaded\n");
	}
	else
	{
	    $status_cb->("Error loading genome\n");
	}
    }

    my $set = $gsdb->create_set_from_pangenome($pg_dir);
    print "created set " . $set->id . " " . $set->name . "\n";
}

1;
