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

# This is a SAS component.

package FFs;
no warnings 'redefine';

use Sim;
use strict;
use DB_File;
our $have_fig;
eval {
    require FIG;
    $have_fig = 1;
};
use SeedUtils;
use ANNOserver;

use FF;
use Tracer;

use Data::Dumper;
use Carp;
use Digest::MD5;

# This is the constructor.  Presumably, $class is 'FFs'.  
#

sub new {
    my($class,$fam_data,$fig) = @_;

    my $figfams = {};

    defined($fam_data) || return undef;
    $figfams->{dir} = $fam_data;
    $figfams->{blast_dir} = $fam_data;
    if ($have_fig && !$fig)
    {
	$figfams->{fig} = new FIG;
    }

    # If the tables are not installed, we really don't need to fail 8 times -- GJO
    $figfams->{function2families} = &SeedUtils::open_berk_table("$fam_data/function2families.db", -results_as_list => 1);
    if ( $figfams->{function2families} )
    {
        $figfams->{function2index} = &SeedUtils::open_berk_table("$fam_data/function2index.db");
        $figfams->{role2families} = &SeedUtils::open_berk_table("$fam_data/role2families.db",  -results_as_list => 1);
        $figfams->{genome2families} = &SeedUtils::open_berk_table("$fam_data/genome2families.db",  -results_as_list => 1);
        $figfams->{peg2family} = &SeedUtils::open_berk_table("$fam_data/peg2family.db");
        $figfams->{family2function} = &SeedUtils::open_berk_table("$fam_data/family2function.db");
        $figfams->{family2pegs} = &SeedUtils::open_berk_table("$fam_data/family2pegs.db", -results_as_list => 1);
        $figfams->{proteinlengths} = &SeedUtils::open_berk_table("$fam_data/length.btree");
	$figfams->{translation} = &SeedUtils::open_berk_table("$fam_data/translation.btree");
    }

    bless $figfams,$class;
    return $figfams;
}

#sub DESTROY {
#    my ($self) = @_;
#    delete $self->{fig};
#}


sub PDB_connections {
    my($self,$fam,$raw) = @_;

    return [];
#     $self->check_db_PDB_connections;
#     my $sims = $self->{PDB_connections_db}->{$fam};
#     my @sims = map { $_ =~ /pdb\|([0-9a-zA-Z]+)/; [$1,[split(/\t/,$_)]] } split(/\n/,$sims);
#     if (! $raw)  { @sims = map { $_->[0] } grep { ($_->[1]->[11] > 0.5) && ((($_->[1]->[4] - $_->[1]->[3]) / $_->[1]->[5]) > 0.8) } @sims}
#     return \@sims;
}

sub figfam
{
    my($self, $figfam_id) = @_;
    return FF->new($figfam_id, $self);
}

sub families_with_function {
    my($self,$function) = @_;

    return @{$self->{function2families}->{$function} || []};
}

sub families_implementing_role {
    my($self,$role) = @_;
    return @{$self->{role2families}->{$role} || []};
}

sub family_containing_peg {
    my($self,$peg) = @_;

    return $self->{peg2family}->{$peg};
}

sub families_containing_peg {
    my($self,$peg) = @_;

    return ($self->family_containing_peg($peg));
}

sub families_in_genome {
    my($self,$genome) = @_;

    return @{$self->{genome2families}->{$genome} || []};
}

sub all_families {
    my($self) = @_;

    return sort keys %{$self->{family2function} || {}};
}

sub place_in_family {
    my($self,$seq) = @_;

    my $anno = new ANNOserver();

    my $handle = $anno->assign_function_to_prot(-hitThreshold => 3, -seqHitThreshold => 2, -kmer => 8, -input => [['id', undef, $seq]]);
    my $res = $handle->get_next();

    if (!@$res || !defined($res->[1]))
    {
	return undef;
    }
    my $function  = $res->[1];
    my $figfam_id = $res->[7];
    my $sims = [];
    if ($figfam_id)
    {
	return (FF->new($figfam_id, $self), $sims);
    }
    else
    {
	return (undef,$sims);
    }
}


sub index_for_function
{
    my($self,$function) = @_;

    return $self->{function2index}->{$function};
}


=head3
usage: $figfams->family_functions();

returns a hash of all the functions for all figfams from the family.functions file

=cut

sub family_functions {
    my($self) = @_;
    return $self->{family2function};
}

sub family_pegs {
    my($self, $fam) = @_;
    return $self->{family2pegs}->{$fam};
}

sub family_function {
    my($self, $fam) = @_;
    return $self->{family2function}->{$fam};
}

sub sz_family {
    my($self, $fam) = @_;
    my $pegs = $self->family_pegs($fam);
    return scalar(@$pegs);
}




### The following methods were added by Rob. 
#  
#  They are mainly used by the RTMG assignment to DNA
#  sequences.
#
#  May 8, 2012

=head3 av_prot_length

Return the average protein length for a given family.

my $len = $figfams->av_prot_length($fam);

Note that you can limit the number of proteins looked through with the optional how_many
(Set it to 0 to look through all proteins). In practice you only need a sample of ~50-100 proteins to know the length

=cut

sub av_prot_length {
    my($self, $fam, $how_many) = @_;
    (defined $how_many) or ($how_many=0);
    if (defined $self->{av_prot_len}->{$fam}) {return $self->{av_prot_len}->{$fam}}
    my ($tot, $n)=(0,0);
    foreach my $peg (@{$self->{family2pegs}->{$fam}}) {
	my $l = $self->{proteinlengths}->{$peg};
	if (defined $l) {
	    $tot += $l;
	    $n++;
	}
	last if ($n == $how_many);
    }
    if ($n) {$self->{av_prot_len}->{$fam} = $tot/$n}
    else {$self->{av_prot_len}->{$fam} = 0}

    return $self->{av_prot_len}->{$fam};
}



=head3 genomes_in_family

Returns a hashref of all genomes in a family. The keys are the genome IDs and the values are the number of occurrences

usage: my $genomeRef = $figfams->genomes_in_family($fam);

Note that you can limit the number of proteins we look through with an additional parameter:
my $genomeRef = $figfams->genomes_in_family($fam, 100);

=cut

sub genomes_in_family {
    my($self, $fam, $how_many) = @_;
    if ($self->{genomes_in_family}->{$fam}) {return $self->{genomes_in_family}->{$fam}}
    my %genomes;
    my @pegs = @{$self->{family2pegs}->{$fam}};
    if ($how_many) {@pegs = splice(@pegs, 0, $how_many)}
    foreach my $peg (@pegs) {
	    $genomes{$self->{fig}->genome_of($peg)}++;
    }
    $self->{genomes_in_family}->{$fam} = \%genomes;
    return \%genomes;
}


=head3 genus_for_family 

The most abundant Genus in the family. This is taken as the first word of the genus/species of the genomeID!

my $genus = $family->genus_for_family($fam);

Note that you can limit the number of proteins we look through with an additional parameter:
my $genus = $family->genus_for_family($fam, 100);

=cut

sub genus_for_family {
	my($self, $fam, $how_many) = @_;
	if ($self->{genus_for_family}->{$fam}) {return $self->{genus_for_family}->{$fam}}
	my $genomes = $self->genomes_in_family($fam, $how_many);
	my %genus;
	foreach my $genomeID (keys %$genomes) {
		my @gsp = split /\b/, $self->{'fig'}->genus_species($genomeID);
		$genus{$gsp[0]}+=$genomes->{$genomeID};
	}
	my @genera = sort {$genus{$b} <=> $genus{$a}} keys %genus;
	$self->{genus_for_family}->{$fam}=$genera[0];
	return $self->{genus_for_family}->{$fam};
}

=head3 last_common_ancestor($family)

The last common ancestor for the family based on the taxonomy of the genomes in the family

my $lca = $family->last_common_ancestor($family);
		
This gives the last common ancestor of the family, by parsing the taxonomy and working from that. We, unfortunately, just separate the tax id by ";" rather than a taxonomic hierarchy.

=cut

sub last_common_ancestor {
	my($self, $fam, $how_many) = @_;
	if ($self->{lca_for_family}->{$fam}) {return $self->{lca_for_family}->{$fam}}
	my $genomes = $self->genomes_in_family($fam, $how_many);
	my @order;
	my $haveorder;
	my %lca;
	my $ngenomes;
	foreach my $gid (keys %$genomes) {
		my $tax = $self->{'fig'}->taxonomy_of($gid);
		#next if ($tax =~ /^\s*$/);
		next unless ($tax);
		$ngenomes++;
		# remove any terminal ; from tax strings
		$tax =~ s/\s*\;\s*$//;
		my $rindex = rindex($tax, ";");
		while ($rindex > -1) {
			if (!$haveorder) {push @order, $tax}
			$lca{$tax}++;
			$tax = substr($tax, 0, $rindex);
			$rindex = rindex($tax, ";");
		}
		if (!$haveorder) {push @order, $tax}
		$lca{$tax}++;
		$haveorder=1;
	}

	$self->{lca_for_family}->{$fam} = "root";

	foreach my $test (@order) {
		if ($lca{$test} == $ngenomes) {
			$self->{lca_for_family}->{$fam} = "root; ", $test;
			last;
		}
	}
	return $self->{lca_for_family}->{$fam};
}




1;
