#!/usr/bin/env perl -w
#
#  svr_translations_of [-c column] [-fasta] [-function] [-genome] < ids
#

#
# This is a SAS Component
#

=head1 svr_translations_of

Get translations from ids

=head2 Usage

=over 4

    svr_translations_of [-c column] [-fasta] [-function] [-genome] < ids

=back

=head2 Command-Line Options

=over 4

=item C<-a>

Include assigned functions in fasta header, or as penultimate column in tab delimited output.  Same as C<-function>

=item C<-c column>

Take ids from specified column of tab delimited input

=item C<-f>

Output in fasta format, not tab delimited columns.  Same as C<-fasta>

=item C<-fasta>

Output in fasta format, not tab delimited columns.

=item C<-function>

Include assigned functions in fasta header, or as penultimate column in tab delimited output.

=item C<-g>

Include genome name in square brackets at end of function.  Same as C<-genome>

=item C<-genome>

Include genome name in square brackets at end of function.

=back

=head2 Examples:

=head3 Default output of tab delimited pairs of id and sequence for I<E. coli> K12 genome:

 svr_all_features 83333.1 peg | svr_translations_of > id_tab_seq

=head3 FASTA format output with function and genome name:

 svr_all_features 83333.1 peg | svr_translations_of -fasta -function -genome > annotated_fasta

=head3 FASTA format output with function and genome name, using short options run together:

 svr_all_features 83333.1 peg | svr_translations_of -afg > annotated_fasta

=cut


use strict;
use Data::Dumper;
use Carp;

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();

my $usage = <<End_of_Usage;

Get translations from ids:

usage: svr_translations_of [-c column] [-fasta] [-function] [-genome] < ids

Options:

   -a           #  Annotations.  Same as -function
   -c  column   #  Take ids from specified column of tab delimited input
   -f           #  Same as -fasta
   -fasta       #  Output is fasta format, not tab delimited columns
   -function    #  Include assigned functions in fasta header, or as
                #      penultimate column of tab delimited output
   -g           #  Same as -genome
   -genome      #  Add genome name in square brackets at end of each function

Examples:

    svr_all_features 83333.1 peg | svr_translations_of > id_tab_seq

    svr_all_features 83333.1 peg | svr_translations_of -a -f -g > annotated_fasta

    svr_all_features 83333.1 peg | svr_translations_of -afg > annotated_fasta

End_of_Usage

my $column;
my $fasta  = 0;
my $funcs  = 0;
my $genome = 0;

while ( $ARGV[0] && ($ARGV[0] =~ s/^-//))
{
    $_ = shift @ARGV;
    if    ($_ =~ s/^c//)       { $column = /./ ? $_ : shift @ARGV; next }
    elsif ($_ =~ /^fasta/)     { $fasta  = 1; next }
    elsif ($_ =~ /^function/)  { $funcs  = 1; next }
    elsif ($_ =~ /^genome/)    { $genome = 1; next }

    if ($_ =~ s/a//g) { $funcs  = 1 }
    if ($_ =~ s/f//g) { $fasta  = 1 }
    if ($_ =~ s/g//g) { $genome = 1 }
    if ($_ =~ /./ )   { print STDERR "Bad Flag: -$_\n", $usage; die }
}

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
if (@lines) {
    if (! $column)  { $column = @{$lines[0]} }
    my @fids = map { $_->[$column-1] } @lines;
    
    my $funcH = $funcs ? $sapObject->ids_to_functions( -ids => \@fids ) : {};

    if ( $genome )
    {
        my $genomeH = $sapObject->ids_to_genomes( -ids => \@fids, -name => 1 );
        foreach ( @fids )
        {
            my $func = $funcH->{ $_ };
            $funcH->{ $_ } = ( defined $func && $func =~ /\S/ ? "$func " : '' )
                           . '[' . ($genomeH->{$_} || 'unknown') . ']';
                                   
        }
        $funcs = 1;
    }

    if (! $fasta) {
	my $seqsH = $sapObject->ids_to_sequences(-ids => \@fids, -protein => 1);

	foreach $_ ( @lines )
	{
	    my $id = $_->[$column-1];
	    print join( "\t",  @$_,
	                       ( $funcs ? $funcH->{$id} || '' : () ),
	                       $seqsH->{$id} || ''
	              ),
	          "\n";
	}
    } else {
	my $seqsH = $sapObject->ids_to_sequences(-ids     => \@fids,
						 -fasta   => 1,
						 -protein => 1,
						 ( $funcs ? ( -comments => $funcH ) : () )
						);
	foreach $_ ( @fids )
	{
	    print $seqsH->{ $_ };
	}
    }
}
