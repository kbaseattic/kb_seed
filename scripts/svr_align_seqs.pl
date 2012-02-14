
#
# This is a SAS Component
#

#
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
#

use strict;
use Data::Dumper;
use Carp;
use Getopt::Long;
Getopt::Long::Configure("pass_through");

=head1 svr_align_seqs

    svr_align_seqs [options] < seqs.fa > ali.fa

This script takes a FASTA file from the standard input, aligns the
sequences using Clustal, MUSCLE or MAFFT, and writes the alignment in
the FASTA format to the standard output.

Examples:
   
  Use MUSCLE to align sequences in seqs.fa:

    svr_align_seqs -tool=muscle < seqs.fa > ali.fa

  Use MAFFT to do profile alignment of seqs.fa with seed alignment in profile.fa:
   
    svr_align_seqs -tool=mafft -profile=profile.fa < seqs.fa > ali.fa

=head2 Command-Line Options

=head3 Common options

=over 4

=item -tool

Alignment program to use. Supported tools: mafft, muscle, clustal (default). 

=item -profile

FASTA file name of skeleton alignment to be aligned with input
sequences. Supported in MUSCLE and MAFFT.

=item -version

Print tool version information. Supported in MUSCLE and MAFFT.

=item -z

Use clustal to align ends (zero end gap penalty).

=back

=head3 MUSCLE options

  Supported values: anchorspacing center cluster1 cluster2 diagbreak diaglength diagmargin distance1 distance2 gapopen log loga matrix maxhours maxiters maxmb maxtrees minbestcolscore minsmoothscore objscore refinewindow root1 root2 scorefile seqtype smoothscorecell smoothwindow spscore SUEFF usetree weight1 weight2

  Supported flags: anchors brenner cluster dimer diags diags1 diags2 le noanchors quiet sp spn stable sv verbose

=head3 MAFFT options

  Algorithm aliases: -alg (linsi | einsi | ginsi | nwnsi | nwns | fftnsi | fftns (D)) (in descending order or accuracy)

  Supported values: aamatrix bl ep groupsize jtt lap lep lepx LOP LEXP maxiterate op partsize retree tm thread weighti

  Supported flags: 6merpair amino anysymbol auto clustalout dpparttree fastapair fastaparttree fft fmodel genafpair globalpair inputorder localpair memsave nofft noscore nuc parttree quiet reorder treeout

=head2 Output Format

The standard output is the alignment in the FASTA format.

=cut

use ATserver;
use AlignTree;
use gjoalignment;
use gjoseqlib;

my $usage = <<"End_of_Usage";

Usage: svr_align_seqs [options] < seqs.fa > ali.fa

       -tool     clustal (D), muscle, mafft
       -l        align sequences locally 
       -version  print remote or local tool's version information
       -z        use clustal to align ends (zero end gap penalty).

     Common options supported by muscle and mafft

       -profile  FASTA file name of skeleton alignment to be aligned with input sequences

     Tool-specific options

        Muscle options:
         Values: anchorspacing center cluster1 cluster2 diagbreak diaglength diagmargin
                 distance1 distance2 gapopen log loga matrix maxhours maxiters maxmb
                 maxtrees minbestcolscore minsmoothscore objscore refinewindow root1
                 root2 scorefile seqtype smoothscorecell smoothwindow spscore SUEFF
                 usetree weight1 weight2
         Flags:  anchors brenner cluster dimer diags diags1 diags2 le noanchors quiet
                 sp spn stable sv verbose

        Mafft options:
         Algorithm aliases: -alg (linsi | einsi | ginsi | nwnsi | nwns | fftnsi | fftns (D))
                 (in descending order or accuracy)
         Values: aamatrix bl ep groupsize jtt lap lep lepx LOP LEXP maxiterate
                 op partsize retree thread tm weighti
         Flags:  6merpair amino anysymbol auto clustalout dpparttree fastapair fastaparttree
                 fft fmodel genafpair globalpair inputorder localpair memsave nofft
                 noscore nuc parttree quiet reorder treeout

End_of_Usage

my $help;
my $version;
my $profileF; 
my $local;
my $tool;
my $url;
my $zero;
my ($clustal, $mafft, $muscle);
my $keep;
my $opted = GetOptions("h|help"         => \$help,
                       "l|local"        => \$local,
                       "url=s"          => \$url,
                       "version"        => \$version,
                       "tool|program=s" => \$tool,
                       "clustal"        => \$clustal,
                       "mafft"          => \$mafft,
                       "muscle"         => \$muscle,
                       "profile=s"      => \$profileF,
                       "k"              => \$keep,        # keep original ordering
                       "z|zero"         => \$zero,
                       '<>'             => \&remaining_options
                      );

$help and die $usage;

my $opts;    

if ($profileF) {
    my $profile = gjoseqlib::read_fasta($profileF);
    $opts->{profile} = $profile;
}

if    ($mafft)  { $tool   = "mafft"   }
elsif ($muscle) { $tool   = "muscle"  }
else            { $tool ||= "clustal" }

my %mafft_val = map { $_ => 1 }
                qw( alg algorithm

                    aamatrix
                    bl
                    ep
                    groupsize
                    jtt
                    lap
                    lep
                    lepx
                    LOP
                    LEXP
                    maxiterate
                    op
                    partsize
                    retree
                    thread
                    tm
                    weighti
                 );

my %mafft_flag = map { $_ => 1 }
                 qw( 6merpair
                     amino
                     anysymbol
                     auto
                     clustalout
                     dpparttree
                     fastapair
                     fastaparttree
                     fft
                     fmodel
                     genafpair
                     globalpair
                     inputorder
                     localpair
                     memsave
                     nofft
                     noscore
                     nuc
                     parttree
                     quiet
                     reorder
                     treeout
                  );

my %muscle_val  = map { $_ => 1 }
                  qw( anchorspacing
                      center
                      cluster1
                      cluster2
                      diagbreak
                      diaglength
                      diagmargin
                      distance1
                      distance2
                      gapopen
                      log
                      loga
                      matrix
                      maxhours
                      maxiters
                      maxmb
                      maxtrees
                      minbestcolscore
                      minsmoothscore
                      objscore
                      refinewindow
                      root1
                      root2
                      scorefile
                      seqtype
                      smoothscorecell
                      smoothwindow
                      spscore
                      SUEFF
                      usetree
                      weight1
                      weight2
                   );

my %muscle_flag = map { $_ => 1 }
                  qw( anchors
                      brenner
                      cluster
                      dimer
                      diags
                      diags1
                      diags2
                      le
                      noanchors
                      quiet
                      sp
                      spn
                      stable
                      sv
                      verbose
                   );


my @prog_args;;

my $prog_vals;
my $prog_flags;


if    ($tool =~ /mafft/i)  { $prog_vals = \%mafft_val;  $prog_flags = \%mafft_flag;  }
elsif ($tool =~ /muscle/i) { $prog_vals = \%muscle_val; $prog_flags = \%muscle_flag; }

my $opts = process_prog_args(\@prog_args);

$opts->{tool}         = $tool;
$opts->{version}      = $version;
$opts->{seqs}         = gjoseqlib::read_fasta() unless $version;
$opts->{clustal_ends} = 1 if $zero;

my $AT;
my $rv;

if ($local) {
    $rv = AlignTree::align_sequences($opts);
} else {
    $AT = ATserver->new(url => $url);
    $rv = $AT->align_seqs($opts)->{rv};
}

if ($version) {
    print "$rv\n";
} else {
    if ($keep) # if you wish to preserve the original order of the sequences
    {
        my $pos = {};
        my $seqs = $opts->{seqs};
        for (my $i=0; ($i < @$seqs); $i++)
        {
            $pos->{$seqs->[$i]->[0]} = $i;
        }
        my @tmp = sort { $pos->{$a->[0]} <=> $pos->{$b->[0]} } @$rv;
        $rv = \@tmp;
    }
    gjoseqlib::print_alignment_as_fasta($rv);  
} 

sub remaining_options {
    push @prog_args, $_[0];
}

sub process_prog_args {
    my @args = @{$_[0]};
    my %opts;
    while ((shift @args) =~ /^-(\S+)/) {
        my $arg = $1;
        if (defined($prog_vals) && defined($prog_flags)) {
            if ($prog_vals->{$arg}) {
                $opts{$arg} = shift @args;
            } elsif ($prog_flags->{$arg}) {
                $opts{$arg} = 1;
            } else {
                die "Bad flag: '$arg'\n" . $usage;
            }
        } else {
            if (@args > 0 && $args[0] !~ /^-/) {
                $opts{$arg} = shift @args;
            } else {
                $opts{$arg} = 1;
            }
        }
    }
    return \%opts;
}
