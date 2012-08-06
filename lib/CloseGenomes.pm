package CloseGenomes;

# This package was done in June-July of 2012.  It is an attempt to support "close genomes"
# requests in both the SEED and the KBase environments.

# This is a SAS component.

use strict;
use warnings;
use Data::Dumper;
use Carp;

use SAPserver;
use ANNOserver;
use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

use gjoseqlib;
use find_special_proteins;
use SeedUtils;

sub close_genomes_and_hits {
    my ($contigsL, $parms) = @_;
    $parms ||= {};
    print STDERR ("In close_genomes_and_hits:\n", Dumper($parms)) if $ENV{VERBOSE};
    
    my $coding_regions = &get_coding_regions($contigsL,$parms);
    my $universal_functions = &get_univ;
    my %contigH = map { $_->[0] => $_->[2] } @$contigsL;
    
    my $args = { -contigs => \%contigH,
		 -univ    => $universal_functions,
		 -n       => $parms->{-n} || 3,
		 -coding  => $coding_regions
		 };
    
    map { print STDERR "copying \'$_\'\n" if $ENV{VERBOSE};
	  $args->{$_} = $parms->{$_}
      } (keys %$parms);
    
    my $close = &get_close_genomes($args);
    return  ($close,$coding_regions);
}

sub get_univ {

my $univ = ['Alanyl-tRNA synthetase (EC 6.1.1.7)',
            'Arginyl-tRNA synthetase (EC 6.1.1.19)',
            'Asparaginyl-tRNA synthetase (EC 6.1.1.22)',
            'Aspartyl-tRNA synthetase (EC 6.1.1.12)',
            'Cysteinyl-tRNA synthetase (EC 6.1.1.16)',
            'Glutamyl-tRNA synthetase (EC 6.1.1.17)',
            'Glycyl-tRNA synthetase (EC 6.1.1.14)',
            'Glycyl-tRNA synthetase alpha chain (EC 6.1.1.14)',
            'Glycyl-tRNA synthetase beta chain (EC 6.1.1.14)',
            'Histidyl-tRNA synthetase (EC 6.1.1.21)',
            'Isoleucyl-tRNA synthetase (EC 6.1.1.5)',
            'Leucyl-tRNA synthetase (EC 6.1.1.4)',
            'Lysyl-tRNA synthetase (class II) (EC 6.1.1.6)',
            'Methionyl-tRNA synthetase (EC 6.1.1.10)',
            'Phenylalanyl-tRNA synthetase alpha chain (EC 6.1.1.20)',
            'Phenylalanyl-tRNA synthetase beta chain (EC 6.1.1.20)',
            'Prolyl-tRNA synthetase (EC 6.1.1.15)',
            'Seryl-tRNA synthetase (EC 6.1.1.11)',
            'Threonyl-tRNA synthetase (EC 6.1.1.3)',
            'Tryptophanyl-tRNA synthetase (EC 6.1.1.2)',
            'Tyrosyl-tRNA synthetase (EC 6.1.1.1)',
            'Valyl-tRNA synthetase (EC 6.1.1.9)',
            'LSU ribosomal protein L10p (P0)',
            'LSU ribosomal protein L13p (L13Ae)',
            'LSU ribosomal protein L14p (L23e)',
            'LSU ribosomal protein L15p (L27Ae)',
            'LSU ribosomal protein L16p (L10e)',
            'LSU ribosomal protein L17p',
            'LSU ribosomal protein L18p (L5e)',
            'LSU ribosomal protein L19p',
            'LSU ribosomal protein L1p (L10Ae)',
            'LSU ribosomal protein L20p',
            'LSU ribosomal protein L21p',
            'LSU ribosomal protein L22p (L17e)',
            'LSU ribosomal protein L23p (L23Ae)',
            'LSU ribosomal protein L24p (L26e)',
            'LSU ribosomal protein L27p',
            'LSU ribosomal protein L28p',
            'LSU ribosomal protein L29p (L35e)',
            'LSU ribosomal protein L2p (L8e)',
            'LSU ribosomal protein L30p (L7e)',
            'LSU ribosomal protein L31p',
            'LSU ribosomal protein L32p',
            'LSU ribosomal protein L33p',
            'LSU ribosomal protein L34p',
            'LSU ribosomal protein L35p',
            'LSU ribosomal protein L36p',
            'LSU ribosomal protein L3p (L3e)',
            'LSU ribosomal protein L4p (L1e)',
            'LSU ribosomal protein L5p (L11e)',
            'LSU ribosomal protein L6p (L9e)',
            'LSU ribosomal protein L7/L12 (P1/P2)',
            'LSU ribosomal protein L9p',
            'SSU ribosomal protein S10p (S20e)',
            'SSU ribosomal protein S11p (S14e)',
            'SSU ribosomal protein S12p (S23e)',
            'SSU ribosomal protein S13p (S18e)',
            'SSU ribosomal protein S14p (S29e)',
            'SSU ribosomal protein S15p (S13e)',
            'SSU ribosomal protein S16p',
            'SSU ribosomal protein S17p (S11e)',
            'SSU ribosomal protein S18p',
            'SSU ribosomal protein S19p (S15e)',
            'SSU ribosomal protein S20p',
            'SSU ribosomal protein S21p',
            'SSU ribosomal protein S2p (SAe)',
            'SSU ribosomal protein S3p (S3e)',
            'SSU ribosomal protein S4p (S9e)',
            'SSU ribosomal protein S5p (S2e)',
            'SSU ribosomal protein S6p',
            'SSU ribosomal protein S7p (S5e)',
            'SSU ribosomal protein S8p (S15Ae)',
            'SSU ribosomal protein S9p (S16e)'
	    ];

    return $univ;
}

sub get_coding_regions {
    my ($contigsL, $parms) = @_;
    print STDERR ("In get_coding_regions:\n", Dumper($parms)) if $ENV{VERBOSE};
    
#    my $VAR1;
#    my $stuff = &SeedUtils::file_read(q(buchnera.probable_coding));
#    eval($stuff);
#    return $VAR1;

    #...something seems to clobber the contents of $contigsL in ANNOserver::assign_functions_to_dna,
    # so clone a local copy to pass to this routine
    my $args = {
	-input   => [ @$contigsL ],
	-kmer    => $parms->{-kmers}   || 8,
	-minHits => $parms->{-minHits} || 10,
	-maxGap  => $parms->{-maxGap}  || 150,
	(defined($parms->{-kmerDataset}) ? (q(-kmerDataset) => $parms->{-kmerDataset}) : ()),
    };
#   print STDERR ("In get_coding_regions:\n", Dumper($args)) if $ENV{VERBOSE};
    
    my $annoObj;
    if (defined($parms->{-annoObj})) {
	$annoObj = $parms->{-annoObj};
    }
    else {
	$annoObj = ANNOserver->new( defined($parms->{-url}) ? (q(url) => $parms->{-url}) : () );
    }
    
    my $hit;
    my $result = [];
    
#   print STDERR ("Before assign_functions_to_dna, size of \@$contigsL is: ", (scalar @$contigsL), "\n");
    my $annoH = $annoObj->assign_functions_to_dna($args);
    while (defined($hit = $annoH->get_next())) {
	# Each item sent back by the result handle is a 2-tuple
	# containing an incoming contig ID and a reference to a list of hit regions.
	# Each hit region is a 5-tuple consisting of the number of matches to the function,
	# the start location, the stop location, the proposed function,
	# and the name of the Genome Set (OTU) from which the gene is likely to have originated.
	
	# $result = [ [Contig,Beg,End,Kmer-hits,Function], ... ]
	push @$result, [ $hit->[0], $hit->[1]->[1], $hit->[1]->[2], $hit->[1]->[0], $hit->[1]->[3] ];  
    }
#   print STDERR ("After assign_functions_to_dna, size of \@\$contigsL is: ", (scalar @$contigsL), "\n");
#   print STDERR ("Before returning from get_coding_regions:\n", Dumper($args));
    
    return $result;
}


sub get_families_with_function {
    my ($function, $parms) = @_; 
    
    if ($parms->{-source} eq 'SEED')
    {
	my $sapObj = $parms->{-sapObj};
	my $result = $sapObj->all_figfams(-functions => [$function]);
#	print STDERR "Families with function $function\n",join(",",sort keys(%$result)),"\n";
	return [ keys %$result ];
    }
    else
    {
	my $csObj = $parms->{-csObj};
	my @roles = &SeedUtils::roles_of_function($function);
	my $role_to_figfamsH = $csObj->roles_to_protein_families(\@roles);
	my %fams;
	foreach my $role (@roles)
	{
	    my $ffs = $role_to_figfamsH->{$role};
	    foreach my $figfam (@$ffs)
	    {
		$fams{$figfam} = 1;
	    }
	}
#	print STDERR "Families with function $function\n",join(",",sort keys(%fams)),"\n";
	return [keys(%fams)];
    }
}

sub get_figfam_members_sequences {
# returns a pointer to a list of 3-tuples representing the sequences.
    my ($familyListP, $parms) = @_;
    
    if ($parms->{-source} eq 'SEED')
    {
	my $sapObj = $parms->{-sapObj};
	my $fidListP = [];
	foreach my $fam (@$familyListP) {
	    my $fidsP = $sapObj->figfam_fids( -id => $fam);
	    push @$fidListP, @$fidsP;
	}
	my $fidSeqHashP = $sapObj->ids_to_sequences(-ids => $fidListP, -protein => 1);
	return [ map { [$_, undef, $fidSeqHashP->{$_}] } (keys %$fidSeqHashP) ];
    }
    else
    {
	my $csObj = $parms->{-csObj};
        my $famH  = $csObj->protein_families_to_fids($familyListP);
	my %fids;
	foreach my $fam (keys(%$famH))
	{
	    foreach $_ (@{$famH->{$fam}})
	    {
		$fids{$_} = 1;
	    }
	}
	my $fidH = $csObj->fids_to_protein_sequences([keys(%fids)]);
	return [ map { [$_,undef,$fidH->{$_}] } keys(%$fidH)];
    }
}

sub get_figfam_members_sequences_SEED {
# returns a pointer to a list of 3-tuples representing the sequences.
    my ($familyListP, $parms) = @_;
    
    my $sapObj;
    if (defined($parms->{-sapObj})) {
	$sapObj = $parms->{-sapObj};
    }
    else {
	$sapObj = SAPserver->new();
    }

    my $fidListP = [];
    foreach my $fam (@$familyListP) {
	my $fidsP = $sapObj->figfam_fids( -id => $fam);
	push @$fidListP, @$fidsP;
    }
    
    my $fidSeqHashP = $sapObj->ids_to_sequences(-ids => $fidListP, -protein => 1);
    
    return [ map { [$_, undef, $fidSeqHashP->{$_}] } (keys %$fidSeqHashP) ];
}


sub get_close_genomes {
    my ($args) = @_;
    my ($contigsH, $probable_coding_regionsL, $universal_funcsL, $num_funcs);
    print STDERR ("In get_close_genomes:\n", Dumper($args)) if $ENV{VERBOSE};
    
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Check that mandatory arguments are defined,
#   and put them into named variables...
#-----------------------------------------------------------------------
    my $trouble = 0;
    if (not defined($contigsH = $args->{-contigs})) {
	$trouble = 1;
	warn "No contigs hash provided";
    }
	
    if (not defined($probable_coding_regionsL = $args->{-coding})) {
	$trouble = 1;
	warn "No probable coding regions provided";
    }

    if (not defined($universal_funcsL = $args->{-univ})) {
	$trouble = 1;
	warn "No pointer to list of \"universal\" functions provided";
    }

    if (not defined($num_funcs = $args->{-n})) {
	$trouble = 1;
	warn "No number of universal functions to use for estimate specified";
    }
    
    die "aborting due to missing parameters" if $trouble;
#=======================================================================

    my %univ_funcs = map { $_ => 1 } @$universal_funcsL;
    my @poss_regions = 	sort { abs($b->[2]-$b->[1]) <=> abs($a->[2]-$a->[1]) } 
                        grep { $univ_funcs{$_->[4] } } @$probable_coding_regionsL;
    my $count = 0;
    my %genome_counts;
    while (($count < $num_funcs) && (my $tuple = shift @poss_regions))
    {
	my ($contig,$beg,$end,undef,$func) = @$tuple;
	my $dna_seq = ($beg < $end) ? substr($contigsH->{$contig},$beg-1,($end+1-$beg))
	    : &SeedUtils::reverse_comp(substr($contigsH->{$contig},$end-1,$beg+1-$end));
	my $fams = &get_families_with_function($func,$args);
	my $example_seqs = &get_figfam_members_sequences($fams,$args);
	if (@$example_seqs > 20) {
	    &get_sims(['new','',$dna_seq],$example_seqs,\%genome_counts);
	    ++$count;
	}
    }

#   print STDERR &Dumper(['genome_counts',\%genome_counts]);
    my @genomes = sort { $b->[1] <=> $a->[1] }
                  map { [$_, &sum_up($genome_counts{$_})] }
                  keys(%genome_counts);
    return \@genomes;
}

sub sum_up {
    my($x) = @_;
    my $sum_score = 0;
    my $ali_chars = 0;
    foreach my $x (@$x) {
	$sum_score += $x->[0] * $x->[1];
	$ali_chars += $x->[1];
    }
    return $sum_score / $ali_chars;
}

use BlastInterface;
sub get_sims {
    my($seq,$db,$genome_counts) = @_;

    my @sims = &BlastInterface::blast($seq,$db,'blastx',{});
    foreach my $sim (@sims)
    {
	if ($sim->iden > 50)
	{
	    #...should probably use bsc instead of iden; test this
	    push(@{$genome_counts->{&genome_of_fid($sim->id2)}}, [$sim->iden, $sim->ln1, $sim->bsc]);
	}
    }
}

sub genome_of_fid {
    my($fid) = @_;

    if ($fid =~ /^fig\|(\d+\.\d+)\.peg/) { return $1 }
    if ($fid =~ /^(kb\|g.\d+)/)          { return $1 }
    return undef;
}

1;

