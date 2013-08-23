#!/usr/bin/perl -w
#
#	This is a SAS Component.
#
# Copyright (c) 2003-2011 University of Chicago and Fellowship
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

package MD5Computer;

=head1 MD5 Identifier Computation Helper

This module contains useful methods for computing MD5 identifiers for
bioinformatic objects. It is designed to be portable to non-SEED systems.

=head2 Terms

The database containing the genome information is called the I<source database>.
So, for example, when this module is being used by the SEED, the I<source
database> is the SEED data store.

This module can be used as an object to create a I<genome descriptor>. A
genome descriptor contains the MD5 identifiers of a genome's contigs, and can
be used to compute the genome's identifier as well as the identifiers of its
genes.

=cut

use strict;
use Digest::MD5;

=head2 Constructors

=head3 new

    my $descriptor = MD5Computer->new();

Create a new, blank genome descriptor.

=cut

sub new {

	# Get the parameters.
	my ($class) = @_;

	# Create the descriptor.
	my $retVal = { contigs => {} };

	# Bless and return it.
	bless $retVal, $class;
	return $retVal;
}

=head3 new_from_fasta

    my $descriptor = MD5Computer->new_from_fasta($fileName);

Create a fully-functional genome descriptor from a FASTA file containing all of
a genome's contigs.

=over 4

=item fileName

Name of the file containing the contig sequences in FASTA format, or an open filehandle
that can be used to read the sequences.

=back

=cut

sub new_from_fasta {

	# Get the parameters.
	my ( $class, $fileName ) = @_;

	# Create a blank descriptor.
	my $retVal = new($class);

	# Get an open handle to the FASTA file.
	my $ih;
	if ( !$fileName ) {

		# No filename was specified, so we use STDIN.
		$ih = \*STDIN;
	}
	elsif ( ref $fileName eq 'GLOB' ) {

		# Here we have an open file handle.
		$ih = $fileName;
	}
	else {

		# Here we open the file normally.
		open $ih, "<$fileName" || die "Cannot open contig FASTA: $!\n";
	}

	# We'll accumulate DNA chunks in here.
	my @dnaChunks;

	# This will hold the contig ID.
	my $contigID;
	while ( !eof $ih ) {

		# Read the input line and chomp off the new-line code.
		my $line = <$ih>;
		chomp $line;

		# Is this a header line?
		if ( $line =~ /^>(\S+)/ ) {

			# Yes. Output the previous contig (if any).
			if ($contigID) {
				$retVal->ProcessContig( $contigID, \@dnaChunks );
			}

			# Save the new contig ID.
			$contigID = $1;

			# Clear the DNA chunk holder.
			@dnaChunks = ();
		}
		else {

			# This is a data line, so store it as a DNA chunk.
			push @dnaChunks, $line;
		}
	}

	# Output the residual contig.
	if ($contigID) {
		$retVal->ProcessContig( $contigID, \@dnaChunks );
	}

	# Close the genome.
	$retVal->CloseGenome();

	# Return the result.
	return $retVal;
}

=head2 Genome Descriptor Methods

=head3 ProcessContig

    my $contigMD5 = $descriptor->ProcessContig($contigID, \@dnaChunks);

Store a contig in the descriptor. The contig ID will be computed from the incoming
DNA chunks, which must be presented in the order they occur in the contig and are
assumed to be contiguous. The chunks themselves will not be stored in the descriptor.

=over 4

=item contigID

Source database identifier for the relevant contig.

=item dnaChunks

Reference to a list of DNA chunks. The chunks must comprise all of the DNA sequences
in the contig, in order. Note that the DNA sequence can be passed in as a single
chunk in the form of a singleton list.

=item RETURN

Returns the MD5 identifier of the contig being stored in the descriptor.

=back

=cut

sub ProcessContig {

	# Get the parameters.m
	my ( $self, $contigID, $dnaChunks ) = @_;

	# Recover gracefully if the user forgot to pass in a list.
	if ( ref $dnaChunks ne 'ARRAY' ) {
		$dnaChunks = [$dnaChunks];
	}

	# Merge the DNA chunks and take the MD5.
	my $retVal = Digest::MD5::md5_hex( map { uc $_ } @$dnaChunks );

	# Store it in the contig hash.
	$self->StoreContig( $contigID, $retVal );

	# Return it to the caller.
	return $retVal;
}

=head3 StoreContig

    $descriptor->StoreContig($contigID, $contigMD5);

Store the MD5 identifier of a contig in the descriptor.

=over 4

=item contigID

Source database ID of the relevant contig.

=item contigMD5

MD5 identifier computed from the contig's DNA sequence.

=back

=cut

sub StoreContig {

	# Get the parameters.
	my ( $self, $contigID, $contigMD5 ) = @_;

	# Store the contig information in the contig hash.
	$self->{contigs}{$contigID} = $contigMD5;
}

=head3 CloseGenome

    my $genomeMD5 = $descriptor->CloseGenome();

Denote that all of this genome's contigs have been processed and return the whole
genome's MD5 identifier.

=cut

sub CloseGenome {

	# Get the parameters.
	my ($self) = @_;

	# Compute the MD5 for the genome.
	my $contigString = join( ",", sort values %{ $self->{contigs} } );
	my $retVal = Digest::MD5::md5_hex($contigString);

	# Save the result and return it.
	$self->{genome} = $retVal;
	return $retVal;
}

=head3 ComputeFeatureMD5

    my $md5 = $descriptor->ComputeFeatureMD5($type, @locations);

Compute the MD5 identifier for the specified feature. The feature is specified 
using a type and a list of location strings. Each location string contains a
contig ID, an underscore, the start of the location, the strand (C<+> or C<->), 
and the number of base pairs. The genome descriptor must have been previously 
closed by L</CloseGenome>. Note that the identifier is not a pure MD5, as it
contains the type as a prefix.

=over 4

=item type

Type of feature (e.g. C<peg>, C<opr>, C<rna>).

=item locations

A list of location strings. Each location string is formed by concatenating a contig ID,
an underscore (C<_>), a starting point, a strand character (C<+> or C<->), and a length
in base pairs. Note that most features will have only one location string.

=item RETURN

Returns the MD5 identifier for the feature, computed from the genome and contig data plus
the type and locations.

=back

=cut

sub ComputeFeatureMD5 {

	# Get the parameters.
	my ( $self, $type, @locations ) = @_;

	# Compute the genome ID.
	my $genomeID = $self->genomeMD5();

	# It's an error if it doesn't exist yet.
	die "Genome descriptor not closed.\n" if !defined $genomeID;

	# Loop through the locations, converting contig IDs to identifiers.
	my @md5Locations;
	for my $location (@locations) {

		# Parse the location string.
		if ( $location =~ /^(.+)_(\d+[+-]\d+)$/ ) {

			# Here the parse worked.
			my ( $contig, $suffix ) = ( $1, $2 );
			my $contigMD5 = $self->contigMD5($contig);
			if ( !defined $contigMD5 ) {

				# Here the contig was not found in the genome descriptor.
				die "Contig $contig not found.\n";
			}
			else {

				# The contig was found, so we substitute in its MD5.
				push @md5Locations, $contigMD5 . "_" . $suffix;
			}
		}
		else {

			# Here the location string was badly formed.
			die "Invalid location string: $location.\n";
		}
	}

	# Format the gene descriptor.
	my $geneString = $genomeID . ":" . join( ",", @md5Locations );

	# Get its MD5 identifier.
	my $retVal = Digest::MD5::md5_hex($geneString);
	
	# Prefix the type.
	$retVal = join("_", $type, $retVal);

	# Return the result.
	return $retVal;
}

=head3 contigMD5

    my $contigMD5 = $descriptor->contigMD5($contigID);

Return the MD5 identifier of the specified contig.

=over 4

=item contigID

Source database ID for the relevant contig.

=item RETURN

Returns the MD5 identifier for the named contig.

=back

=cut

sub contigMD5 {

	# Get the parameters.
	my ( $self, $contigID ) = @_;

	# Return the ID for the named contig.
	return $self->{contigs}{$contigID};
}

=head3 genomeMD5

    my $genomeMD5 = $descriptor->genomeMD5();

Return the MD5 identifier for the whole genome. If the genome has not been closed,
(via L</CloseGenome>) this method will return an undefined value.

=cut

sub genomeMD5 {

	# Get the parameters.
	my ($self) = @_;

        # Return the genome MD5 computed at close time. If the close never 
        # took place, this value will be undefined.
	return $self->{genome};
}

=head3 contigs

    my @contigIDs = $descriptor->contigs();

Return a list of the source database contig IDs for this genome.

=cut

sub contigs {

	# Get the parameters.
	my ($self) = @_;

	# Return the keys of the contig hash.
	return keys %{ $self->{contigs} };
}

=head2 Static Methods

=head3 ComputeProteinID

    my $md5 = MD5Computer::ComputeProteinID($sequence);

or

    my $md5 = $descriptor->ComputeProteinID($sequence);

Return the MD5 of a protein sequence.

=over 4

=item sequence

Protein sequence to convert.

=item RETURN

Returns the MD5 protein ID for the specified protein sequence.

=back

=cut

sub ComputeProteinID {

	# Get the parameters.
	shift if ref $_[0] eq __PACKAGE__;
	my ($sequence) = @_;

	# Convert the sequence to upper case and take the MD5.
	my $retVal = Digest::MD5::md5_hex( uc $sequence );

	# Return the result.
	return $retVal;
}

=head3 ProcessProteinFASTA

    my $geneHash = MD5Computer::ProcessProteinFASTA($fileName);

or

    my $geneHash = $descriptor->ProcessProteinFASTA($fileName);

Return a hash mapping the IDs in the specified protein FASTA to each
protein's MD5 protein ID.

=over 4

=item fileName

Name of the protein FASTA file, or an open file handle that can be used to read
the FASTA file.

=item RETURN

Returns a reference to a hash that maps each ID in the FASTA file to the MD5
protein ID for the associated protein sequence.

=back

=cut

sub ProcessProteinFASTA {

	# Get the parameters.
	shift if ref $_[0] eq __PACKAGE__;
	my ($fileName) = @_;

	# Get a handle to the FASTA file.
	my $ih;
	if ( ref $fileName eq 'GLOB' ) {
		$ih = $fileName;
	}
	else {
		open $ih, "<$fileName" || die "Could not open FASTA input: $!";
	}

	# Create the return hash.
	my $retVal = {};

	# These variables will hold the ID of the current protein and the amino acid
	# fragments.
	my ( $proteinID, @fragments );

	# Loop through the input.
	while ( !eof $ih ) {

		# Get the current line.
		my $line = <$ih>;
		chomp $line;

		# Is this a header line?
		if ( $line =~ /^>(\S+)/ ) {

			# Yes. Output the current protein, if any.
			if ( defined $proteinID ) {
				$retVal->{$proteinID} =
				  ComputeProteinID( join( "", @fragments ) );
			}

			# Save this protein ID and set up for its sequence fragments.
			$proteinID = $1;
			@fragments = ();
		}
		else {

			# No. Save this sequence fragment.
			push @fragments, $line;
		}
	}

	# Output the last protein, if any.
	if ( defined $proteinID ) {
		$retVal->{$proteinID} = ComputeProteinID( join( "", @fragments ) );
	}

	# Return the hash of proteins.
	return $retVal;
}

1;
