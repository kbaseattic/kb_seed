#!/usr/bin/perl -w

#
# This is a SAS Component
#

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

use strict;
use Data::Dumper;
use SAPserver;
use Getopt::Long;
#use Pod::Usage;
use SeedUtils;
use gjoseqlib;
my $have_soap;
eval {
    require SOAP::Lite;
    $have_soap = 1;
};

=head1 svr_export_as_seed_dir

=head2 Introduction

    svr_export_as_seed_dir [-assign-new-name] output-dir < genome-list 

Export one or more genomes as SEED format directories.

=head2 Command-Line Options

=over 4
    
=item -assign-new-name

If specified, the genomes as exported will be given new genome IDs.

=item output-dir

Directory into which the genome directories should be exported.

=back

=cut

# Get the command-line options and parameters.
my $assign_new_name = 0;
my $output_dir;
my $help;
my $url = "";

my $rc = GetOptions("assign-new-name" => \$assign_new_name,
                    "help" => \$help,
		    "url=s" => \$url);

if (@ARGV != 1 || !$rc || $help)
{
    #pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});  
    my $usage = [ "$0 [options] output-dir < genome-list",
		  "\tOPTIONAL",
		  "\t-assign-new-name\tassign new names to all genomes",
		  "\t-url\tANNO server URL",
		  "\t-help\tdisplay command-line options", ""];
    
    print join "\n", @$usage;
    exit;
}

if ($assign_new_name && !$have_soap)
{
    die "You asked to assign a new name, but SOAP::Lite is not\n" .
	"available in your perl environment so this option is not available.\n";
}

# Create a FIGfam server object.
my $sap = SAPserver->new(url => $url);

my $output_dir = shift;

-d $output_dir or die "Output directory $output_dir does not exist\n";

my @genomes;
while (<>)
{
    chomp;
    if (!/^(\d+\.\d+)$/)
    {
	die "Invalid input at line $.\n";
    }
    push(@genomes, $1);
}

my $contigs = $sap->genome_contigs({ -ids => \@genomes });
my $gdata = $sap->genome_data({ -ids => \@genomes, -data => [qw(complete domain genetic-code)] });
my $gname = $sap->genome_names({ -ids => \@genomes });
my $tax = $sap->taxonomy_of({ -ids => \@genomes });
my $ss = $sap->genomes_to_subsystems({ -ids => \@genomes, -all => 1 });

my $proxy;
if ($assign_new_name)
{
    $proxy = SOAP::Lite->uri('http://www.soaplite.com/Scripts')-> proxy('http://clearinghouse.theseed.org/Clearinghouse/clearinghouse_services.cgi');
}

for my $genome (@genomes)
{
    my $new_genome = $genome;
    my $fix_name;
    if ($assign_new_name)
    {
	my($tax) = $genome =~ /^(\d+)\./;
	my $rep = $proxy->register_genome($tax);
	if ($rep->fault)
	{
	    die "Failure to register new genome ID: " . $rep->faultcode . " " . $rep->faultstring;
	}
	my $suffix = $rep->result;
	$new_genome = "$tax.$suffix";
	$fix_name = sub { my($a) = @_; $a =~ s/\b$genome\b/$new_genome/g; return $a };
    }
    else
    {
	$fix_name = sub { my($a) = @_; return $a; };
    }
    print STDERR "Write $genome (new=$new_genome)\n";
    
    my $dir = init_seed_dir($genome, $new_genome);
    
    write_contigs($genome, $new_genome, $fix_name, $dir);

    my $fhash = $sap->all_features({ -ids => $genome });

    my $features = $fhash->{$genome};

    write_features($genome, $new_genome, $fix_name, $dir, $features);

    write_subsystems($genome, $new_genome, $fix_name, $dir, $features);
}

sub init_seed_dir
{
    my($genome, $new_genome) = @_;
    
    my $dir = "$output_dir/$new_genome";

    SeedUtils::verify_dir($dir);

    open(G, ">", "$dir/GENOME");
    print G "$gname->{$genome}\n";
    close(G);

    open(F, ">", "$dir/COMPLETE");
    print F "$gdata->{$genome}->[0]\n";
    close(F);

    open(F, ">", "$dir/GENETIC_CODE");
    print F "$gdata->{$genome}->[2]\n";
    close(F);

    open(F, ">", "$dir/TAXONOMY");
    print F join("; ", @{$tax->{$genome}}), "\n";
    close(F);

    &SeedUtils::verify_dir("$dir/Features");

    return $dir;
}

sub write_contigs
{
    my($genome, $new_genome, $fix_name, $dir) = @_;
    
    open(C, ">", "$dir/contigs") or die "Cannot write $dir/contigs: $!";

    my $contig_data = $sap->contig_sequences(-ids => $contigs->{$genome});

    for my $contig (keys %$contig_data)
    {
	my $ncontig = $fix_name->($contig);
	print_alignment_as_fasta(\*C, [$ncontig, undef, $contig_data->{$contig}]);
    }
    close(C);
}

sub write_features
{
    my($genome, $new_genome, $fix_name, $dir, $features) = @_;

    my %by_type;

    my $locs = $sap->fid_locations({ -ids => $features });
    my $funcs = $sap->ids_to_functions({ -ids => $features });

    my $prots = $sap->fids_to_proteins({ -ids => $features, -sequence => 1});

    my $annos = $sap->ids_to_annotations({ -ids => $features });

    my @non_prot;

    open(AFUN, ">", "$dir/assigned_functions") or die "cannot write $dir/assigned_functions: $!";
    open(ANNO, ">", "$dir/annotations") or die "cannot write $dir/annotations: $!";

    for my $f (sort { SeedUtils::by_fig_id($a, $b) } @$features)
    {
	my $nf = $fix_name->($f);
	
	push(@{$by_type{SeedUtils::type_of($f)}}, $f);
	push(@non_prot, $f) if ! exists($prots->{$f});
	my $func = $funcs->{$f};
	print AFUN "$nf\t$func\n" if $func;
	if (ref($annos->{$f}))
	{
	    for my $ent (@{$annos->{$f}})
	    {
		my($txt, $annotator, $ts) = @$ent;
		$txt .= "\n" unless $txt =~ /\n$/;
		print ANNO join("\n", $nf, $ts, $annotator, $txt), "//\n";
	    }
	}
    }

    close(AFUN);
    close(ANNO);

    my $dna = $sap->ids_to_sequences({ -ids => \@non_prot });

    for my $type (keys %by_type)
    {
	write_features_of_type($genome, $fix_name, $dir, $type, $by_type{$type}, $locs, $prots, $dna);
    }
}

sub write_features_of_type
{
    my($genome, $fix_name, $dir, $type, $features, $locs, $prots, $dna) = @_;

    my $fdir = "$dir/Features/$type";
    SeedUtils::verify_dir($fdir);

    open(F, ">", "$fdir/fasta") or die "cannot write $fdir/fasta: $!";
    open(T, ">", "$fdir/tbl") or die "cannot write $fdir/tbl: $!";

    for my $fid (@$features)
    {
	my $nfid = $fix_name->($fid);
	#
	# Fasta
	#
	print_alignment_as_fasta(\*F, [$nfid, undef, ($prots->{$fid} or $dna->{$fid})]);

	#
	# Tbl
	# Need to translate Sapling style locations to SEED style locations
	#

	my $loc = join(",", map { translate_loc($fix_name, $_) } @{$locs->{$fid}});

	print T join("\t", $nfid, $loc), "\n";
	
    }
    close(F);
    close(T);
}

sub translate_loc
{
    my($fix_name, $loc) = @_;
    my($contig, $min, $max, $dir) = SeedUtils::boundaries_of($loc);
    ($min, $max) = ($max, $min) if ($dir eq '-');
    return join("_", $fix_name->($contig), $min, $max);
}

sub write_subsystems
{
    my($genome, $new_genome, $fix_name, $dir, $features) = @_;

    my $sdir = "$dir/Subsystems";
    SeedUtils::verify_dir($sdir);
    open(SUBSYSTEMS, ">", "$sdir/subsystems") or die "cannot write $sdir/subsystems";
    open(BINDINGS, ">", "$sdir/bindings") or die "cannot write $sdir/subsystems";

    my $bindings = $sap->ids_to_subsystems(-ids => $features);

    for my $fid (sort { SeedUtils::by_fig_id($a, $b) } keys %$bindings)
    {
	for my $b (@{$bindings->{$fid}})
	{
	    my($role, $ss_name) = @$b;
	    $ss_name =~ s/ /_/g;
	    print BINDINGS join("\t", $ss_name, $role, $fix_name->($fid)), "\n";
	}
    }
    close(BINDINGS);

    for my $ss_ent (@{$ss->{$genome}})
    {
	my($ss_name, $vc) = @$ss_ent;
	$ss_name =~ s/ /_/g;
	print SUBSYSTEMS "$ss_name\t$vc\n";
    }
    close(SUBSYSTEMS);
}
