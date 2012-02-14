#!/usr/bin/perl -w

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
#use FIGMODEL;

package ModelSaplingLoader;
    use strict;
    use Tracer;
    use ERDB;
    use base 'BaseSaplingLoader';

=head1 Sapling Model Load Group Class

=head2 Introduction

The Model Load Group includes a small set of tables that describe reactions and compounds
and how they relate to the models in the main model database.

=head3 new

    my $sl = ModelSaplingLoader->new($erdb, $options);

Construct a new ModelSaplingLoader object.

=over 4

=item erdb

L<Sapling> object for the database being loaded.

=item options

Reference to a hash of command-line options.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $erdb, $options) = @_;
    # Create the table list.
    my @tables = qw(Compound Reaction EcNumber Model Media IsTriggeredBy
                    IsCategorizedInto IsConsistentWith IsModeledBy Involves
                    IsRequiredBy Complex ComplexName IsSetOf IsExemplarOf);
    # Create the BaseSaplingLoader object.
    my $retVal = BaseSaplingLoader::new($class, $erdb, $options, @tables);
    # Create the reaction tracking hash.
    $retVal->{reactions} = {};
    # Return it.
    return $retVal;
}

=head2 Public Methods

=head3 Generate

    $sl->Generate();

Generate the data for the model files.

=cut

sub Generate {
    # Get the parameters.
    my ($self) = @_;
    # Get the database object.
    my $erdb = $self->db();
    # Is this the global section?
    if ($self->global()) {
        # Load the tables from the model dump files.
        $self->LoadModelFiles();
    } else {
        # Get the section ID.
        my $genomeID = $self->section();
        #NO GENOME SPECIFIC MODEL STUFF
    }
}

=head3 LoadModelFiles

    $sl->LoadModelFiles();

Load the data from the six model dump files.

=cut

# hash of ubiquitous compounds.
use constant UBIQUITOUS => {
    cpd00001 => 'OH-',
    cpd00002 => 'ATP',
    cpd00003 => 'Nicotinamideadeninedinucleotide',
    cpd00004 => 'Nicotinamideadeninedinucleotide-reduced',
    cpd00005 => 'Nicotinamideadeninedinucleotidephosphate-reduced',
    cpd00006 => 'Nicotinamideadeninedinucleotidephosphate',
    cpd00007 => 'Oxygen',
    cpd00008 => 'ADP',
    cpd00009 => 'Orthophosphoric acid',
    cpd00010 => 'CoenzymeA',
    cpd00011 => 'Carbon dioxide',
    cpd00012 => 'PPi',
    cpd00018 => 'AMP',
    cpd00020 => 'Pyruvic Acid',
    cpd00022 => 'Acetyl-CoA',
    cpd00025 => 'Hydrogen peroxide',
    cpd00067 => 'H+',
    cpd00971 => 'Sodium',
    cpd15352 => '2-Demethylmenaquinone',
    cpd15353 => '2-Demethylmenaquinol',
    cpd15499 => 'Menaquinol',
    cpd15500 => 'Menaquinone',
    cpd15560 => 'Ubiquinone-8',
    cpd15561 => 'Ubiquinol-8',
};

sub LoadModelFiles {
    # Get the parameters.
    my ($self) = @_;
    # Get the sapling database.
    my $erdb = $self->db();
    # Get the model dump file directory.
    my $dir = $erdb->LoadDirectory() . "/models";
    # First we read the compounds.
    my $ih = $self->CheckFile("$dir/CompoundName.txt", qw(CompoundID Name));
    while (! eof $ih) {
        # Get the next compound.
        my ($id, $label) = $self->ReadLine($ih);
        # Create a compound record for it.
        $self->PutE(Compound => $id, label => $label, ubiquitous => (UBIQUITOUS->{$id} ? 1 : 0));
    }
    # Next, the compound-reactions relationship. We create the reactions here, too.
    $ih = $self->CheckFile("$dir/CompoundReaction.txt", qw(CompoundID ReactionID
                           Stoichiometry Cofactor));
    while (! eof $ih) {
        # Get the next link.
        my ($compound, $reaction, $stoich, $cofactor) = $self->ReadLine($ih);
        # Insure the reaction exists.
        $self->CreateReaction($reaction);
        # Check for product or substrate.
        my $product;
        if ($stoich < 0) {
            $product = 0;
            $stoich = -$stoich;
        } else {
            $product = 1;
        }
        # Connect the reaction to the compound.
        $self->PutR(Involves => $reaction, $compound, product => $product,
                    stoichiometry => $stoich, cofactor => $cofactor);
    }
    # Before we go on, we need to get a map of the modelSEED role IDs to
    # the SEED role IDs. This is found in the Role.txt file, along with the
    # exemplar data.
    my %roleHash;
    $ih = $self->CheckFile("$dir/Role.txt", qw(RoleID Name ExemplarID));
    while (! eof $ih) {
        # Get the next role's record.
        my ($roleID, $role, $exemplarList) = $self->ReadLine($ih);
        # Map the role ID to the role name (which is the SEED's ID).
        $roleHash{$roleID} = $role;
        # If there is are exemplars, store them.
        if ($exemplarList && $exemplarList ne 'NONE') {
            for my $exemplar (split /\s*,\s*/, $exemplarList) {
                $self->PutR(IsExemplarOf => $exemplar, $role);
            }
        }
    }
    # The next step is to create the complexes. We load into memory a
    # hash mapping the complexes to their reactions. This is later 
    # used to insure we have reaction-to-role coverage.
    my %cpxHash;
    $ih = $self->CheckFile("$dir/ReactionComplex.txt", qw(ReactionID ComplexID));
    while (! eof $ih) {
        # Get the next reaction/complex pair.
        my ($rxn, $cpx) = $self->ReadLine($ih);
        # Is this a new complex?
        if (! exists $cpxHash{$cpx}) {
            # Yes. Create a record for it.
            $self->PutE(Complex => $cpx);
            $cpxHash{$cpx} = [];
        }
        # Insure the reaction exists.
        $self->CreateReaction($rxn);
        # Connect the complex to the reaction.
        $self->PutR(IsSetOf => $cpx, $rxn);
        push @{$cpxHash{$cpx}}, $rxn;
    }
    # Here we connect the complexes to the roles. Along the way, we
    # create a hash listing of all of a reaction's roles. That hash
    # will be used to check for missing reaction/role links later on.
    my %rxnHash;
    $ih = $self->CheckFile("$dir/ComplexRole.txt", qw(RoleID ComplexID));
    while (! eof $ih) {
        # Get the next role/complex pair.
        my ($roleID, $cpx) = $self->ReadLine($ih);
        # Connect the role to the complex.
        $self->PutR(IsTriggeredBy => $cpx, $roleHash{$roleID}, optional => 0);
        # Denote that this role is connected to the complex's reactions.
        for my $rxn (@{$cpxHash{$cpx}}) {
            push @{$rxnHash{$rxn}}, $roleID;
        }
    }
    # We don't need the complex hash any more. Instead, we're going to
    # use it to track single-reaction complexes we create.
    %cpxHash = ();
    # Now we fill in the missing reaction-to-role connections.
    $ih = $self->CheckFile("$dir/ReactionRole.txt", qw(ReactionID Role));
    while (! eof $ih) {
        # Get the next reaction/role pair.
        my ($reaction, $role) = $self->ReadLine($ih);
        # Insure the reaction exists.
        $self->CreateReaction($reaction);
        # Is this reaction already connected to this role?
        my $roleList = $rxnHash{$reaction};
        if (! $roleList || ! (grep { $roleHash{$_} eq $role } @{$rxnHash{$reaction}})) {
            # No, so we have to do it the hard way.
            if (! exists $cpxHash{$reaction}) {
                # Here the reaction has not had a complex created, so we
                # must create one.
                $self->Add(pseudoComplex => 1);
                $self->PutE(Complex => $reaction);
                $self->PutR(IsSetOf => $reaction, $reaction);
            }
            # Connect the reaction's complex to this role.
            $self->PutR(IsTriggeredBy => $reaction, $role);
            $self->Add(missingTrigger => 1);
        }
    }
    # Now we create the models.
    $ih = $self->CheckFile("$dir/ModelGenome.txt", qw(ModelID Name GenomeID));
    while (! eof $ih) {
        # Get the next model.
        my ($model, $name, $genome) = $self->ReadLine($ih);
        # Create the model.
        $self->PutE(Model => $model);
        # Connect it to the genome. Again, the genomes are created elsewhere.
        $self->PutR(IsModeledBy => $genome, $model);
    }
    # Next we connect the reactions to models.
    $ih = $self->CheckFile("$dir/ModelReaction.txt", qw(ModelID ReactionID));
    while (! eof $ih) {
        # Get the next line.
        my ($model, $reaction) = $self->ReadLine($ih);
        # Only proceed if a reaction is present.
        if ($reaction) {
            # Insure the reaction exists.
            $self->CreateReaction($reaction);
            # Connect the reaction to the model.
            $self->PutR(IsRequiredBy => $reaction, $model);
        }
    }
}

=head3 CheckFile

    my $ih = $sl->CheckFile($fileName, @fieldNames);

Read the header record of the specified file and verify that the field names match
the names in the input list. If they do not, an error will be thrown; if they do, an
open file handle will be returned, positioned on the first data record.

=over 4

=item fileName

Name for the input file. The file is in standard tab-delimited format. The first record
contains the field names and the remaining records contain the data.

=item fieldNames

List of the field names expected, in order.

=item RETURN

Returns the open file handle if successful. If there is a mismatch, throws an error.

=back

=cut

sub CheckFile {
    # Get the parameters.
    my ($self, $fileName, @fieldNames) = @_;
    # Open the file.
    my $retVal = Open(undef, "<$fileName");
    $self->Add(files => 1);
    # Read in the file header.
    my @actualFields = Tracer::GetLine($retVal);
    # This will be set to TRUE if there's a mismatch.
    my $error = 0;
    for (my $i = 0; $i <= $#fieldNames; $i++) {
        if ($fieldNames[$i] ne $actualFields[$i]) {
            Trace("Field match error: expected $fieldNames[$i], found $actualFields[$i].") if T(0);
            $error = 1;
        }
    }
    # Was there an error?
    if ($error) {
        # Yes, so abort.
        Confess("Invalid field name header in $fileName.");
    } else {
        # No, so trace the open.
        Trace("Processing $fileName.") if T(ERDBLoadGroup => 2);
    }
    # Return the file handle.
    return $retVal;
}

=head3 ReadLine

    my @fields = $sl->ReadLine($ih);

Read a line of data from an input file.

=over 4

=item ih

Open file handle for the input file.

=item RETURN

Returns a list of the field values for the next record in the file.

=back

=cut

sub ReadLine {
    # Get the parameters.
    my ($self, $ih) = @_;
    # Read the line.
    my @retVal = Tracer::GetLine($ih);
    # Count this record.
    $self->Track(records => $retVal[0], 1000);
    # Return the data.
    return @retVal;
}


=head3 CheckReaction

    $sl->CheckReaction($reaction);

Insure we have created a rectord for the specified reaction.

=over 4

=item reaction

ID of the reaction in question.

=back

=cut

sub CreateReaction {
    # Get the parameters.
    my ($self, $reaction) = @_;
    # Get the reaction hash.
    my $reactionH = $self->{reactions};
    # See if this reaction is new.
    if (! $reactionH->{$reaction}) {
        # It is, so create it.
        $self->PutE(Reaction => $reaction);
        # Insure we don't create it again.
        $reactionH->{$reaction} = 1;
    }
}

1;
