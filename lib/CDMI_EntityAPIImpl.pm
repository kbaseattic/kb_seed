package CDMI_EntityAPIImpl;
use strict;

=head1 NAME

CDMI_EntityAPI

=head1 DESCRIPTION



=cut

#BEGIN_HEADER

use CDMI;

our $entity_field_defs = {
    'AlignmentTree' => {
	id => 1,
		    'alignment_method' => 1,
		    'alignment_parameters' => 1,
		    'alignment_properties' => 1,
		    'tree_method' => 1,
		    'tree_parameters' => 1,
		    'tree_properties' => 1,
	
    },
    'Annotation' => {
	id => 1,
		    'annotator' => 1,
		    'comment' => 1,
		    'annotation_time' => 1,
	
    },
    'AtomicRegulon' => {
	id => 1,
	
    },
    'Attribute' => {
	id => 1,
		    'description' => 1,
	
    },
    'Biomass' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
	
    },
    'BiomassCompound' => {
	id => 1,
		    'coefficient' => 1,
	
    },
    'Compartment' => {
	id => 1,
		    'abbr' => 1,
		    'mod_date' => 1,
		    'name' => 1,
	
    },
    'Complex' => {
	id => 1,
		    'name' => 1,
		    'mod_date' => 1,
	
    },
    'Compound' => {
	id => 1,
		    'label' => 1,
		    'abbr' => 1,
		    'ubiquitous' => 1,
		    'mod_date' => 1,
		    'uncharged_formula' => 1,
		    'formula' => 1,
		    'mass' => 1,
	
    },
    'Contig' => {
	id => 1,
		    'source_id' => 1,
	
    },
    'ContigChunk' => {
	id => 1,
		    'sequence' => 1,
	
    },
    'ContigSequence' => {
	id => 1,
		    'length' => 1,
	
    },
    'CoregulatedSet' => {
	id => 1,
		    'reason' => 1,
	
    },
    'Diagram' => {
	id => 1,
		    'name' => 1,
		    'content' => 1,
	
    },
    'EcNumber' => {
	id => 1,
		    'obsolete' => 1,
		    'replacedby' => 1,
	
    },
    'Experiment' => {
	id => 1,
		    'source' => 1,
	
    },
    'Family' => {
	id => 1,
		    'type' => 1,
		    'family_function' => 1,
	
    },
    'Feature' => {
	id => 1,
		    'feature_type' => 1,
		    'source_id' => 1,
		    'sequence_length' => 1,
		    'function' => 1,
	
    },
    'Genome' => {
	id => 1,
		    'pegs' => 1,
		    'rnas' => 1,
		    'scientific_name' => 1,
		    'complete' => 1,
		    'prokaryotic' => 1,
		    'dna_size' => 1,
		    'contigs' => 1,
		    'domain' => 1,
		    'genetic_code' => 1,
		    'gc_content' => 1,
		    'phenotype' => 1,
		    'md5' => 1,
		    'source_id' => 1,
	
    },
    'Identifier' => {
	id => 1,
		    'source' => 1,
		    'natural_form' => 1,
	
    },
    'Media' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
		    'type' => 1,
	
    },
    'Model' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
		    'version' => 1,
		    'type' => 1,
		    'status' => 1,
		    'reaction_count' => 1,
		    'compound_count' => 1,
		    'annotation_count' => 1,
	
    },
    'ModelCompartment' => {
	id => 1,
		    'compartment_index' => 1,
		    'label' => 1,
		    'pH' => 1,
		    'potential' => 1,
	
    },
    'OTU' => {
	id => 1,
	
    },
    'PairSet' => {
	id => 1,
		    'score' => 1,
	
    },
    'Pairing' => {
	id => 1,
	
    },
    'ProbeSet' => {
	id => 1,
	
    },
    'ProteinSequence' => {
	id => 1,
		    'sequence' => 1,
	
    },
    'Publication' => {
	id => 1,
		    'citation' => 1,
	
    },
    'Reaction' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
		    'abbr' => 1,
		    'equation' => 1,
		    'reversibility' => 1,
	
    },
    'ReactionRule' => {
	id => 1,
		    'direction' => 1,
		    'transproton' => 1,
	
    },
    'Reagent' => {
	id => 1,
		    'stoichiometry' => 1,
		    'cofactor' => 1,
		    'compartment_index' => 1,
		    'transport_coefficient' => 1,
	
    },
    'Requirement' => {
	id => 1,
		    'direction' => 1,
		    'transproton' => 1,
		    'proton' => 1,
	
    },
    'Role' => {
	id => 1,
		    'hypothetical' => 1,
	
    },
    'SSCell' => {
	id => 1,
	
    },
    'SSRow' => {
	id => 1,
		    'curated' => 1,
		    'region' => 1,
	
    },
    'Scenario' => {
	id => 1,
		    'common_name' => 1,
	
    },
    'Source' => {
	id => 1,
	
    },
    'Subsystem' => {
	id => 1,
		    'version' => 1,
		    'curator' => 1,
		    'notes' => 1,
		    'description' => 1,
		    'usable' => 1,
		    'private' => 1,
		    'cluster_based' => 1,
		    'experimental' => 1,
	
    },
    'SubsystemClass' => {
	id => 1,
	
    },
    'TaxonomicGrouping' => {
	id => 1,
		    'domain' => 1,
		    'hidden' => 1,
		    'scientific_name' => 1,
		    'alias' => 1,
	
    },
    'Variant' => {
	id => 1,
		    'role_rule' => 1,
		    'code' => 1,
		    'type' => 1,
		    'comment' => 1,
	
    },
    'Variation' => {
	id => 1,
		    'notes' => 1,
	
    },

};

our $entity_field_rels = {
    'AlignmentTree' => {
    },
    'Annotation' => {
    },
    'AtomicRegulon' => {
    },
    'Attribute' => {
    },
    'Biomass' => {
	    'name' => 'BiomassName',
    },
    'BiomassCompound' => {
    },
    'Compartment' => {
    },
    'Complex' => {
	    'name' => 'ComplexName',
    },
    'Compound' => {
    },
    'Contig' => {
    },
    'ContigChunk' => {
    },
    'ContigSequence' => {
    },
    'CoregulatedSet' => {
    },
    'Diagram' => {
	    'content' => 'DiagramContent',
    },
    'EcNumber' => {
    },
    'Experiment' => {
    },
    'Family' => {
	    'family_function' => 'FamilyFunction',
    },
    'Feature' => {
    },
    'Genome' => {
	    'phenotype' => 'GenomeSequencePhenotype',
    },
    'Identifier' => {
    },
    'Media' => {
    },
    'Model' => {
    },
    'ModelCompartment' => {
	    'label' => 'ModelCompartmentLabel',
    },
    'OTU' => {
    },
    'PairSet' => {
    },
    'Pairing' => {
    },
    'ProbeSet' => {
    },
    'ProteinSequence' => {
    },
    'Publication' => {
    },
    'Reaction' => {
    },
    'ReactionRule' => {
    },
    'Reagent' => {
    },
    'Requirement' => {
    },
    'Role' => {
    },
    'SSCell' => {
    },
    'SSRow' => {
    },
    'Scenario' => {
    },
    'Source' => {
    },
    'Subsystem' => {
    },
    'SubsystemClass' => {
    },
    'TaxonomicGrouping' => {
	    'alias' => 'TaxonomicGroupingAlias',
    },
    'Variant' => {
	    'role_rule' => 'VariantRole',
    },
    'Variation' => {
	    'notes' => 'VariationNotes',
    },

};

our $relationship_field_defs = {
    'AffectsLevelOf' => {
	to_link => 1, from_link => 1,
		    'level' => 1,
	
    },
    'IsAffectedIn' => {
	to_link => 1, from_link => 1,
		    'level' => 1,
	
    },
    'Aligns' => {
	to_link => 1, from_link => 1,
		    'begin' => 1,
		    'end' => 1,
		    'len' => 1,
		    'sequence_id' => 1,
		    'properties' => 1,
	
    },
    'IsAlignedBy' => {
	to_link => 1, from_link => 1,
		    'begin' => 1,
		    'end' => 1,
		    'len' => 1,
		    'sequence_id' => 1,
		    'properties' => 1,
	
    },
    'Concerns' => {
	to_link => 1, from_link => 1,
	
    },
    'IsATopicOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Contains' => {
	to_link => 1, from_link => 1,
	
    },
    'IsContainedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'Describes' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDescribedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Displays' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'IsDisplayedOn' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'Encompasses' => {
	to_link => 1, from_link => 1,
	
    },
    'IsEncompassedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'GeneratedLevelsFor' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'WasGeneratedFrom' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'HasAssertionFrom' => {
	to_link => 1, from_link => 1,
		    'function' => 1,
		    'expert' => 1,
	
    },
    'Asserts' => {
	to_link => 1, from_link => 1,
		    'function' => 1,
		    'expert' => 1,
	
    },
    'HasCompoundAliasFrom' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'UsesAliasForCompound' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'HasIndicatedSignalFrom' => {
	to_link => 1, from_link => 1,
		    'rma_value' => 1,
		    'level' => 1,
	
    },
    'IndicatesSignalFor' => {
	to_link => 1, from_link => 1,
		    'rma_value' => 1,
		    'level' => 1,
	
    },
    'HasMember' => {
	to_link => 1, from_link => 1,
	
    },
    'IsMemberOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasParticipant' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'ParticipatesIn' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'HasPresenceOf' => {
	to_link => 1, from_link => 1,
		    'concentration' => 1,
		    'minimum_flux' => 1,
		    'maximum_flux' => 1,
	
    },
    'IsPresentIn' => {
	to_link => 1, from_link => 1,
		    'concentration' => 1,
		    'minimum_flux' => 1,
		    'maximum_flux' => 1,
	
    },
    'HasReactionAliasFrom' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'UsesAliasForReaction' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'HasRepresentativeOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRepresentedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'HasResultsIn' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
	
    },
    'HasResultsFor' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
	
    },
    'HasSection' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSectionOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasStep' => {
	to_link => 1, from_link => 1,
	
    },
    'IsStepOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasUsage' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUsageOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasValueFor' => {
	to_link => 1, from_link => 1,
		    'value' => 1,
	
    },
    'HasValueIn' => {
	to_link => 1, from_link => 1,
		    'value' => 1,
	
    },
    'Includes' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
		    'abbreviation' => 1,
		    'auxiliary' => 1,
	
    },
    'IsIncludedIn' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
		    'abbreviation' => 1,
		    'auxiliary' => 1,
	
    },
    'IndicatedLevelsFor' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'HasLevelsFrom' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'Involves' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInvolvedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsARequirementIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsARequirementOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsAlignedIn' => {
	to_link => 1, from_link => 1,
		    'start' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsAlignmentFor' => {
	to_link => 1, from_link => 1,
		    'start' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsAnnotatedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Annotates' => {
	to_link => 1, from_link => 1,
	
    },
    'IsBindingSiteFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsBoundBy' => {
	to_link => 1, from_link => 1,
	
    },
    'IsClassFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInClass' => {
	to_link => 1, from_link => 1,
	
    },
    'IsCollectionOf' => {
	to_link => 1, from_link => 1,
		    'representative' => 1,
	
    },
    'IsCollectedInto' => {
	to_link => 1, from_link => 1,
		    'representative' => 1,
	
    },
    'IsComposedOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsComponentOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsComprisedOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Comprises' => {
	to_link => 1, from_link => 1,
	
    },
    'IsConfiguredBy' => {
	to_link => 1, from_link => 1,
	
    },
    'ReflectsStateOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsConsistentWith' => {
	to_link => 1, from_link => 1,
	
    },
    'IsConsistentTo' => {
	to_link => 1, from_link => 1,
	
    },
    'IsControlledUsing' => {
	to_link => 1, from_link => 1,
		    'effector' => 1,
	
    },
    'Controls' => {
	to_link => 1, from_link => 1,
		    'effector' => 1,
	
    },
    'IsCoregulatedWith' => {
	to_link => 1, from_link => 1,
		    'coefficient' => 1,
	
    },
    'HasCoregulationWith' => {
	to_link => 1, from_link => 1,
		    'coefficient' => 1,
	
    },
    'IsCoupledTo' => {
	to_link => 1, from_link => 1,
		    'co_occurrence_evidence' => 1,
		    'co_expression_evidence' => 1,
	
    },
    'IsCoupledWith' => {
	to_link => 1, from_link => 1,
		    'co_occurrence_evidence' => 1,
		    'co_expression_evidence' => 1,
	
    },
    'IsDefaultFor' => {
	to_link => 1, from_link => 1,
	
    },
    'RunsByDefaultIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDefaultLocationOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasDefaultLocation' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDeterminedBy' => {
	to_link => 1, from_link => 1,
		    'inverted' => 1,
	
    },
    'Determines' => {
	to_link => 1, from_link => 1,
		    'inverted' => 1,
	
    },
    'IsDividedInto' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDivisionOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsExemplarOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasAsExemplar' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFamilyFor' => {
	to_link => 1, from_link => 1,
	
    },
    'DeterminesFunctionOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFormedOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFormedInto' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFunctionalIn' => {
	to_link => 1, from_link => 1,
	
    },
    'HasFunctional' => {
	to_link => 1, from_link => 1,
	
    },
    'IsGroupFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInGroup' => {
	to_link => 1, from_link => 1,
	
    },
    'IsImplementedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Implements' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInPair' => {
	to_link => 1, from_link => 1,
	
    },
    'IsPairOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInstantiatedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInstanceOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsLocatedIn' => {
	to_link => 1, from_link => 1,
		    'ordinal' => 1,
		    'begin' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsLocusFor' => {
	to_link => 1, from_link => 1,
		    'ordinal' => 1,
		    'begin' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsModeledBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Models' => {
	to_link => 1, from_link => 1,
	
    },
    'IsNamedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Names' => {
	to_link => 1, from_link => 1,
	
    },
    'IsOwnerOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsOwnedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'IsProposedLocationOf' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'HasProposedLocationIn' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'IsProteinFor' => {
	to_link => 1, from_link => 1,
	
    },
    'Produces' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRealLocationOf' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'HasRealLocationIn' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'IsRegulatedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRegulatedSetOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRelevantFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRelevantTo' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRequiredBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Requires' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRoleOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasRole' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRowOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRoleFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSequenceOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasAsSequence' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSubInstanceOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Validates' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSuperclassOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSubclassOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsTargetOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Targets' => {
	to_link => 1, from_link => 1,
	
    },
    'IsTaxonomyOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInTaxa' => {
	to_link => 1, from_link => 1,
	
    },
    'IsTerminusFor' => {
	to_link => 1, from_link => 1,
		    'group_number' => 1,
	
    },
    'HasAsTerminus' => {
	to_link => 1, from_link => 1,
		    'group_number' => 1,
	
    },
    'IsTriggeredBy' => {
	to_link => 1, from_link => 1,
		    'optional' => 1,
		    'type' => 1,
	
    },
    'Triggers' => {
	to_link => 1, from_link => 1,
		    'optional' => 1,
		    'type' => 1,
	
    },
    'IsUsedAs' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUseOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Manages' => {
	to_link => 1, from_link => 1,
	
    },
    'IsManagedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'OperatesIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUtilizedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'Overlaps' => {
	to_link => 1, from_link => 1,
	
    },
    'IncludesPartOf' => {
	to_link => 1, from_link => 1,
	
    },
    'ParticipatesAs' => {
	to_link => 1, from_link => 1,
	
    },
    'IsParticipationOf' => {
	to_link => 1, from_link => 1,
	
    },
    'ProducedResultsFor' => {
	to_link => 1, from_link => 1,
	
    },
    'HadResultsProducedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'ProjectsOnto' => {
	to_link => 1, from_link => 1,
		    'gene_context' => 1,
		    'percent_identity' => 1,
		    'score' => 1,
	
    },
    'IsProjectedOnto' => {
	to_link => 1, from_link => 1,
		    'gene_context' => 1,
		    'percent_identity' => 1,
		    'score' => 1,
	
    },
    'Provided' => {
	to_link => 1, from_link => 1,
	
    },
    'WasProvidedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Shows' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'IsShownOn' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'Submitted' => {
	to_link => 1, from_link => 1,
	
    },
    'WasSubmittedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Uses' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUsedBy' => {
	to_link => 1, from_link => 1,
	
    },

};

our $relationship_field_rels = {
    'AffectsLevelOf' => {
    },
    'IsAffectedIn' => {
    },
    'Aligns' => {
    },
    'IsAlignedBy' => {
    },
    'Concerns' => {
    },
    'IsATopicOf' => {
    },
    'Contains' => {
    },
    'IsContainedIn' => {
    },
    'Describes' => {
    },
    'IsDescribedBy' => {
    },
    'Displays' => {
    },
    'IsDisplayedOn' => {
    },
    'Encompasses' => {
    },
    'IsEncompassedIn' => {
    },
    'GeneratedLevelsFor' => {
    },
    'WasGeneratedFrom' => {
    },
    'HasAssertionFrom' => {
    },
    'Asserts' => {
    },
    'HasCompoundAliasFrom' => {
    },
    'UsesAliasForCompound' => {
    },
    'HasIndicatedSignalFrom' => {
    },
    'IndicatesSignalFor' => {
    },
    'HasMember' => {
    },
    'IsMemberOf' => {
    },
    'HasParticipant' => {
    },
    'ParticipatesIn' => {
    },
    'HasPresenceOf' => {
    },
    'IsPresentIn' => {
    },
    'HasReactionAliasFrom' => {
    },
    'UsesAliasForReaction' => {
    },
    'HasRepresentativeOf' => {
    },
    'IsRepresentedIn' => {
    },
    'HasResultsIn' => {
    },
    'HasResultsFor' => {
    },
    'HasSection' => {
    },
    'IsSectionOf' => {
    },
    'HasStep' => {
    },
    'IsStepOf' => {
    },
    'HasUsage' => {
    },
    'IsUsageOf' => {
    },
    'HasValueFor' => {
    },
    'HasValueIn' => {
    },
    'Includes' => {
    },
    'IsIncludedIn' => {
    },
    'IndicatedLevelsFor' => {
    },
    'HasLevelsFrom' => {
    },
    'Involves' => {
    },
    'IsInvolvedIn' => {
    },
    'IsARequirementIn' => {
    },
    'IsARequirementOf' => {
    },
    'IsAlignedIn' => {
    },
    'IsAlignmentFor' => {
    },
    'IsAnnotatedBy' => {
    },
    'Annotates' => {
    },
    'IsBindingSiteFor' => {
    },
    'IsBoundBy' => {
    },
    'IsClassFor' => {
    },
    'IsInClass' => {
    },
    'IsCollectionOf' => {
    },
    'IsCollectedInto' => {
    },
    'IsComposedOf' => {
    },
    'IsComponentOf' => {
    },
    'IsComprisedOf' => {
    },
    'Comprises' => {
    },
    'IsConfiguredBy' => {
    },
    'ReflectsStateOf' => {
    },
    'IsConsistentWith' => {
    },
    'IsConsistentTo' => {
    },
    'IsControlledUsing' => {
    },
    'Controls' => {
    },
    'IsCoregulatedWith' => {
    },
    'HasCoregulationWith' => {
    },
    'IsCoupledTo' => {
    },
    'IsCoupledWith' => {
    },
    'IsDefaultFor' => {
    },
    'RunsByDefaultIn' => {
    },
    'IsDefaultLocationOf' => {
    },
    'HasDefaultLocation' => {
    },
    'IsDeterminedBy' => {
    },
    'Determines' => {
    },
    'IsDividedInto' => {
    },
    'IsDivisionOf' => {
    },
    'IsExemplarOf' => {
    },
    'HasAsExemplar' => {
    },
    'IsFamilyFor' => {
    },
    'DeterminesFunctionOf' => {
    },
    'IsFormedOf' => {
    },
    'IsFormedInto' => {
    },
    'IsFunctionalIn' => {
    },
    'HasFunctional' => {
    },
    'IsGroupFor' => {
    },
    'IsInGroup' => {
    },
    'IsImplementedBy' => {
    },
    'Implements' => {
    },
    'IsInPair' => {
    },
    'IsPairOf' => {
    },
    'IsInstantiatedBy' => {
    },
    'IsInstanceOf' => {
    },
    'IsLocatedIn' => {
    },
    'IsLocusFor' => {
    },
    'IsModeledBy' => {
    },
    'Models' => {
    },
    'IsNamedBy' => {
    },
    'Names' => {
    },
    'IsOwnerOf' => {
    },
    'IsOwnedBy' => {
    },
    'IsProposedLocationOf' => {
    },
    'HasProposedLocationIn' => {
    },
    'IsProteinFor' => {
    },
    'Produces' => {
    },
    'IsRealLocationOf' => {
    },
    'HasRealLocationIn' => {
    },
    'IsRegulatedIn' => {
    },
    'IsRegulatedSetOf' => {
    },
    'IsRelevantFor' => {
    },
    'IsRelevantTo' => {
    },
    'IsRequiredBy' => {
    },
    'Requires' => {
    },
    'IsRoleOf' => {
    },
    'HasRole' => {
    },
    'IsRowOf' => {
    },
    'IsRoleFor' => {
    },
    'IsSequenceOf' => {
    },
    'HasAsSequence' => {
    },
    'IsSubInstanceOf' => {
    },
    'Validates' => {
    },
    'IsSuperclassOf' => {
    },
    'IsSubclassOf' => {
    },
    'IsTargetOf' => {
    },
    'Targets' => {
    },
    'IsTaxonomyOf' => {
    },
    'IsInTaxa' => {
    },
    'IsTerminusFor' => {
    },
    'HasAsTerminus' => {
    },
    'IsTriggeredBy' => {
    },
    'Triggers' => {
    },
    'IsUsedAs' => {
    },
    'IsUseOf' => {
    },
    'Manages' => {
    },
    'IsManagedBy' => {
    },
    'OperatesIn' => {
    },
    'IsUtilizedIn' => {
    },
    'Overlaps' => {
    },
    'IncludesPartOf' => {
    },
    'ParticipatesAs' => {
    },
    'IsParticipationOf' => {
    },
    'ProducedResultsFor' => {
    },
    'HadResultsProducedBy' => {
    },
    'ProjectsOnto' => {
    },
    'IsProjectedOnto' => {
    },
    'Provided' => {
    },
    'WasProvidedBy' => {
    },
    'Shows' => {
    },
    'IsShownOn' => {
    },
    'Submitted' => {
    },
    'WasSubmittedBy' => {
    },
    'Uses' => {
    },
    'IsUsedBy' => {
    },

};

our $relationship_entities = {
    'AffectsLevelOf' => [ 'Experiment', 'AtomicRegulon' ],
    'IsAffectedIn' => [ 'AtomicRegulon', 'Experiment' ],
    'Aligns' => [ 'AlignmentTree', 'ProteinSequence' ],
    'IsAlignedBy' => [ 'ProteinSequence', 'AlignmentTree' ],
    'Concerns' => [ 'Publication', 'ProteinSequence' ],
    'IsATopicOf' => [ 'ProteinSequence', 'Publication' ],
    'Contains' => [ 'SSCell', 'Feature' ],
    'IsContainedIn' => [ 'Feature', 'SSCell' ],
    'Describes' => [ 'Subsystem', 'Variant' ],
    'IsDescribedBy' => [ 'Variant', 'Subsystem' ],
    'Displays' => [ 'Diagram', 'Reaction' ],
    'IsDisplayedOn' => [ 'Reaction', 'Diagram' ],
    'Encompasses' => [ 'Feature', 'Feature' ],
    'IsEncompassedIn' => [ 'Feature', 'Feature' ],
    'GeneratedLevelsFor' => [ 'ProbeSet', 'AtomicRegulon' ],
    'WasGeneratedFrom' => [ 'AtomicRegulon', 'ProbeSet' ],
    'HasAssertionFrom' => [ 'Identifier', 'Source' ],
    'Asserts' => [ 'Source', 'Identifier' ],
    'HasCompoundAliasFrom' => [ 'Source', 'Compound' ],
    'UsesAliasForCompound' => [ 'Compound', 'Source' ],
    'HasIndicatedSignalFrom' => [ 'Feature', 'Experiment' ],
    'IndicatesSignalFor' => [ 'Experiment', 'Feature' ],
    'HasMember' => [ 'Family', 'Feature' ],
    'IsMemberOf' => [ 'Feature', 'Family' ],
    'HasParticipant' => [ 'Scenario', 'Reaction' ],
    'ParticipatesIn' => [ 'Reaction', 'Scenario' ],
    'HasPresenceOf' => [ 'Media', 'Compound' ],
    'IsPresentIn' => [ 'Compound', 'Media' ],
    'HasReactionAliasFrom' => [ 'Source', 'Reaction' ],
    'UsesAliasForReaction' => [ 'Reaction', 'Source' ],
    'HasRepresentativeOf' => [ 'Genome', 'Family' ],
    'IsRepresentedIn' => [ 'Family', 'Genome' ],
    'HasResultsIn' => [ 'ProbeSet', 'Experiment' ],
    'HasResultsFor' => [ 'Experiment', 'ProbeSet' ],
    'HasSection' => [ 'ContigSequence', 'ContigChunk' ],
    'IsSectionOf' => [ 'ContigChunk', 'ContigSequence' ],
    'HasStep' => [ 'Complex', 'ReactionRule' ],
    'IsStepOf' => [ 'ReactionRule', 'Complex' ],
    'HasUsage' => [ 'Compound', 'BiomassCompound' ],
    'IsUsageOf' => [ 'BiomassCompound', 'Compound' ],
    'HasValueFor' => [ 'Experiment', 'Attribute' ],
    'HasValueIn' => [ 'Attribute', 'Experiment' ],
    'Includes' => [ 'Subsystem', 'Role' ],
    'IsIncludedIn' => [ 'Role', 'Subsystem' ],
    'IndicatedLevelsFor' => [ 'ProbeSet', 'Feature' ],
    'HasLevelsFrom' => [ 'Feature', 'ProbeSet' ],
    'Involves' => [ 'Reaction', 'Reagent' ],
    'IsInvolvedIn' => [ 'Reagent', 'Reaction' ],
    'IsARequirementIn' => [ 'Model', 'Requirement' ],
    'IsARequirementOf' => [ 'Requirement', 'Model' ],
    'IsAlignedIn' => [ 'Contig', 'Variation' ],
    'IsAlignmentFor' => [ 'Variation', 'Contig' ],
    'IsAnnotatedBy' => [ 'Feature', 'Annotation' ],
    'Annotates' => [ 'Annotation', 'Feature' ],
    'IsBindingSiteFor' => [ 'Feature', 'CoregulatedSet' ],
    'IsBoundBy' => [ 'CoregulatedSet', 'Feature' ],
    'IsClassFor' => [ 'SubsystemClass', 'Subsystem' ],
    'IsInClass' => [ 'Subsystem', 'SubsystemClass' ],
    'IsCollectionOf' => [ 'OTU', 'Genome' ],
    'IsCollectedInto' => [ 'Genome', 'OTU' ],
    'IsComposedOf' => [ 'Genome', 'Contig' ],
    'IsComponentOf' => [ 'Contig', 'Genome' ],
    'IsComprisedOf' => [ 'Biomass', 'BiomassCompound' ],
    'Comprises' => [ 'BiomassCompound', 'Biomass' ],
    'IsConfiguredBy' => [ 'Genome', 'AtomicRegulon' ],
    'ReflectsStateOf' => [ 'AtomicRegulon', 'Genome' ],
    'IsConsistentWith' => [ 'EcNumber', 'Role' ],
    'IsConsistentTo' => [ 'Role', 'EcNumber' ],
    'IsControlledUsing' => [ 'CoregulatedSet', 'Feature' ],
    'Controls' => [ 'Feature', 'CoregulatedSet' ],
    'IsCoregulatedWith' => [ 'Feature', 'Feature' ],
    'HasCoregulationWith' => [ 'Feature', 'Feature' ],
    'IsCoupledTo' => [ 'Family', 'Family' ],
    'IsCoupledWith' => [ 'Family', 'Family' ],
    'IsDefaultFor' => [ 'Compartment', 'Reaction' ],
    'RunsByDefaultIn' => [ 'Reaction', 'Compartment' ],
    'IsDefaultLocationOf' => [ 'Compartment', 'Reagent' ],
    'HasDefaultLocation' => [ 'Reagent', 'Compartment' ],
    'IsDeterminedBy' => [ 'PairSet', 'Pairing' ],
    'Determines' => [ 'Pairing', 'PairSet' ],
    'IsDividedInto' => [ 'Model', 'ModelCompartment' ],
    'IsDivisionOf' => [ 'ModelCompartment', 'Model' ],
    'IsExemplarOf' => [ 'Feature', 'Role' ],
    'HasAsExemplar' => [ 'Role', 'Feature' ],
    'IsFamilyFor' => [ 'Family', 'Role' ],
    'DeterminesFunctionOf' => [ 'Role', 'Family' ],
    'IsFormedOf' => [ 'AtomicRegulon', 'Feature' ],
    'IsFormedInto' => [ 'Feature', 'AtomicRegulon' ],
    'IsFunctionalIn' => [ 'Role', 'Feature' ],
    'HasFunctional' => [ 'Feature', 'Role' ],
    'IsGroupFor' => [ 'TaxonomicGrouping', 'TaxonomicGrouping' ],
    'IsInGroup' => [ 'TaxonomicGrouping', 'TaxonomicGrouping' ],
    'IsImplementedBy' => [ 'Variant', 'SSRow' ],
    'Implements' => [ 'SSRow', 'Variant' ],
    'IsInPair' => [ 'Feature', 'Pairing' ],
    'IsPairOf' => [ 'Pairing', 'Feature' ],
    'IsInstantiatedBy' => [ 'Compartment', 'ModelCompartment' ],
    'IsInstanceOf' => [ 'ModelCompartment', 'Compartment' ],
    'IsLocatedIn' => [ 'Feature', 'Contig' ],
    'IsLocusFor' => [ 'Contig', 'Feature' ],
    'IsModeledBy' => [ 'Genome', 'Model' ],
    'Models' => [ 'Model', 'Genome' ],
    'IsNamedBy' => [ 'ProteinSequence', 'Identifier' ],
    'Names' => [ 'Identifier', 'ProteinSequence' ],
    'IsOwnerOf' => [ 'Genome', 'Feature' ],
    'IsOwnedBy' => [ 'Feature', 'Genome' ],
    'IsProposedLocationOf' => [ 'Compartment', 'ReactionRule' ],
    'HasProposedLocationIn' => [ 'ReactionRule', 'Compartment' ],
    'IsProteinFor' => [ 'ProteinSequence', 'Feature' ],
    'Produces' => [ 'Feature', 'ProteinSequence' ],
    'IsRealLocationOf' => [ 'ModelCompartment', 'Requirement' ],
    'HasRealLocationIn' => [ 'Requirement', 'ModelCompartment' ],
    'IsRegulatedIn' => [ 'Feature', 'CoregulatedSet' ],
    'IsRegulatedSetOf' => [ 'CoregulatedSet', 'Feature' ],
    'IsRelevantFor' => [ 'Diagram', 'Subsystem' ],
    'IsRelevantTo' => [ 'Subsystem', 'Diagram' ],
    'IsRequiredBy' => [ 'Reaction', 'Requirement' ],
    'Requires' => [ 'Requirement', 'Reaction' ],
    'IsRoleOf' => [ 'Role', 'SSCell' ],
    'HasRole' => [ 'SSCell', 'Role' ],
    'IsRowOf' => [ 'SSRow', 'SSCell' ],
    'IsRoleFor' => [ 'SSCell', 'SSRow' ],
    'IsSequenceOf' => [ 'ContigSequence', 'Contig' ],
    'HasAsSequence' => [ 'Contig', 'ContigSequence' ],
    'IsSubInstanceOf' => [ 'Subsystem', 'Scenario' ],
    'Validates' => [ 'Scenario', 'Subsystem' ],
    'IsSuperclassOf' => [ 'SubsystemClass', 'SubsystemClass' ],
    'IsSubclassOf' => [ 'SubsystemClass', 'SubsystemClass' ],
    'IsTargetOf' => [ 'ModelCompartment', 'BiomassCompound' ],
    'Targets' => [ 'BiomassCompound', 'ModelCompartment' ],
    'IsTaxonomyOf' => [ 'TaxonomicGrouping', 'Genome' ],
    'IsInTaxa' => [ 'Genome', 'TaxonomicGrouping' ],
    'IsTerminusFor' => [ 'Compound', 'Scenario' ],
    'HasAsTerminus' => [ 'Scenario', 'Compound' ],
    'IsTriggeredBy' => [ 'Complex', 'Role' ],
    'Triggers' => [ 'Role', 'Complex' ],
    'IsUsedAs' => [ 'Reaction', 'ReactionRule' ],
    'IsUseOf' => [ 'ReactionRule', 'Reaction' ],
    'Manages' => [ 'Model', 'Biomass' ],
    'IsManagedBy' => [ 'Biomass', 'Model' ],
    'OperatesIn' => [ 'Experiment', 'Media' ],
    'IsUtilizedIn' => [ 'Media', 'Experiment' ],
    'Overlaps' => [ 'Scenario', 'Diagram' ],
    'IncludesPartOf' => [ 'Diagram', 'Scenario' ],
    'ParticipatesAs' => [ 'Compound', 'Reagent' ],
    'IsParticipationOf' => [ 'Reagent', 'Compound' ],
    'ProducedResultsFor' => [ 'ProbeSet', 'Genome' ],
    'HadResultsProducedBy' => [ 'Genome', 'ProbeSet' ],
    'ProjectsOnto' => [ 'ProteinSequence', 'ProteinSequence' ],
    'IsProjectedOnto' => [ 'ProteinSequence', 'ProteinSequence' ],
    'Provided' => [ 'Source', 'Subsystem' ],
    'WasProvidedBy' => [ 'Subsystem', 'Source' ],
    'Shows' => [ 'Diagram', 'Compound' ],
    'IsShownOn' => [ 'Compound', 'Diagram' ],
    'Submitted' => [ 'Source', 'Genome' ],
    'WasSubmittedBy' => [ 'Genome', 'Source' ],
    'Uses' => [ 'Genome', 'SSRow' ],
    'IsUsedBy' => [ 'SSRow', 'Genome' ],

};

#sub _init_instance
#{
#    my($self) = @_;
#    $self->{db} = CDMI->new(dbhost => 'seed-db-read', sock => '', DBD => '/home/parrello/FIGdisk/dist/releases/current/WinBuild/KSaplingDBD.xml');
#}

sub _validate_fields_for_entity
{
    my($self, $tbl, $fields, $ensure_id) = @_;

    my $valid_fields = $entity_field_defs->{$tbl};

    my $have_id;

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my @rel_fields;
    my @qfields;
    my @sfields;
    my @bad_fields;
    for my $field (@$fields)
    {
	$field =~ s/-/_/g;
	if (!$valid_fields->{$field})
	{
	    push(@bad_fields, $field);
	    next;
	}
	if (my $rel = $entity_field_rels->{$tbl}->{$field})
	{
	    push(@rel_fields, [$field, $rel]);
	}
	else
	{
	    push(@sfields, $field);
	    my $qfield = $q . $field . $q;
	    $have_id = 1 if $field eq 'id';
	    push(@qfields, $qfield);
	}
    }

    if (@bad_fields)
    {
	die "The following fields are invalid in entity $tbl: @bad_fields";
    }

    if (!$have_id && ($ensure_id || @rel_fields))
    {
	unshift(@sfields, 'id');
	unshift(@qfields, $q . 'id' . $q);
    }

    return(\@sfields, \@qfields, \@rel_fields);
}

sub _validate_fields_for_relationship
{
    my($self, $tbl, $fields, $link_field) = @_;

    my $valid_fields = $relationship_field_defs->{$tbl};

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my $have_id = 0;
    my @qfields;
    my @sfields;
    my @bad_fields;
    for my $field (@$fields)
    {
	$field =~ s/-/_/g;
	if (!$valid_fields->{$field})
	{
	    push(@bad_fields, $field);
	    next;
	}

	$have_id = 1 if $field eq $link_field;
	push(@sfields, $field);
	my $qfield = $q . $field . $q;
	push(@qfields, $qfield);
    }

    if (!$have_id)
    {
	unshift(@sfields, $link_field);
	unshift(@qfields, $q . $link_field . $q);
    }

    if (@bad_fields)
    {
	die "The following fields are invalid in relationship $tbl: @bad_fields";
    }

    return(\@sfields, \@qfields);
}

sub _get_entity
{
    my($self, $ctx, $tbl, $ids, $fields) = @_;

    my($sfields, $qfields, $rel_fields) = $self->_validate_fields_for_entity($tbl, $fields, 1);
    
    my $filter = "id IN (" . join(", ", map { '?' } @$ids) . ")";

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my $qstr = join(", ", @$qfields);
    my $qry = "SELECT $qstr FROM $q$tbl$q WHERE $filter";

    my $attrs = {};
    my $dbk = $cdmi->{_dbh};
    if ($dbk->dbms eq 'mysql')
    {
	$attrs->{mysql_use_result} = 1;
    }

    my $sth = $dbk->{_dbh}->prepare($qry, $attrs);
    
    # print STDERR "$qry\n";
    $sth->execute(@$ids);
    my $out = $sth->fetchall_hashref('id');

    #
    # Now query for the fields that are in separate relations.
    #
    for my $ent (@$rel_fields)
    {
	my($field, $rel) = @$ent;
	my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	$sth->execute(@$ids);
	while (my $row = $sth->fetchrow_arrayref())
	{
	    my($id, $val) = @$row;
	    push(@{$out->{$id}->{$field}}, $val);
	}
    }
    return $out;
}    

sub _get_relationship
{
    my($self, $ctx, $relationship, $table, $is_converse, $ids, $from_fields, $rel_fields, $to_fields) = @_;

    my($from_tbl, $to_tbl) = @{$relationship_entities->{$relationship}};
    if (!$from_tbl)
    {
	die "Unknown relationship $relationship";
    }

    my %link_name_map;
    my($from_link, $to_link);
    if ($is_converse)
    {
	($from_link, $to_link) = qw(to_link from_link);
	%link_name_map = ( from_link => 'to_link', to_link => 'from_link');
    }
    else
    {
	($from_link, $to_link) = qw(from_link to_link);
	%link_name_map = ( from_link => 'from_link', to_link => 'to_link');
    }
    for my $f (@$rel_fields)
    {
	if (!exists $link_name_map{$f})
	{
	    $link_name_map{$f} = $f;
	}
    }

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my($from_sfields, $from_qfields, $from_relfields) = $self->_validate_fields_for_entity($from_tbl, $from_fields, 0);
    my($to_sfields, $to_qfields, $to_relfields) = $self->_validate_fields_for_entity($to_tbl, $to_fields, 0);

    my @trans_rel_fields = map { $link_name_map{$_} } @$rel_fields;
    my($rel_sfields, $rel_qfields) = $self->_validate_fields_for_relationship($relationship, \@trans_rel_fields, $from_link);
    
    my $filter = "$from_link IN (" . join(", ", map { '?' } @$ids) . ")";

    my $from = "$q$table$q r ";
    if (@$from_qfields)
    {
	$from .= "JOIN $q$from_tbl$q f ON f.id = r.$from_link ";
    }
    if (@$to_qfields)
    {
	$from .= "JOIN $q$to_tbl$q t ON t.id = r.$to_link ";
    }

    my $qstr = join(", ",
		    (map { "f.$_" } @$from_qfields),
		    (map { "t.$_" }  @$to_qfields),
		    (map { "r.$_" } @$rel_qfields));

    my $qry = "SELECT $qstr FROM $from WHERE $filter";

    my $attrs = {};
    my $dbk = $cdmi->{_dbh};
    if ($dbk->dbms eq 'mysql')
    {
	$attrs->{mysql_use_result} = 1;
    }

    my $sth = $dbk->{_dbh}->prepare($qry, $attrs);
    
    # print STDERR "$qry\n";
    $sth->execute(@$ids);
    my $res = $sth->fetchall_arrayref();

    my $out = [];

    my(%from_keys_for_rel, %to_keys_for_rel);
    for my $ent (@$res)
    {
	my($fout, $rout, $tout) = ({}, {}, {});
	for my $fld (@$from_sfields)
	{
	    my $v = shift @$ent;
	    $fout->{$fld} = $v;
	}
	for my $fld (@$to_sfields)
	{
	    my $v = shift @$ent;
	    $tout->{$fld} = $v;
	}
	for my $fld (@$rel_sfields)
	{
	    my $v = shift @$ent;
	    $rout->{$link_name_map{$fld}} = $v;
	}
	my $row = [$fout, $rout, $tout];

	if (@$from_relfields)
	{
	    push(@{$from_keys_for_rel{$fout->{id}}}, $row);
	}

	if (@$to_relfields)
	{
	    push(@{$to_keys_for_rel{$tout->{id}}}, $row);
	}

	push(@$out, $row);
    }

    if (@$from_relfields)
    {
	my %ids = keys %from_keys_for_rel;
	my @ids = keys %ids;

	my $filter = "id IN (" . join(", ", map { '?' } @ids) . ")";

	for my $ent (@$from_relfields)
	{
	    my($field, $rel) = @$ent;
	    
	    my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	    $sth->execute(@ids);
	    while (my $row = $sth->fetchrow_arrayref())
	    {
		my($id, $val) = @$row;

		for my $row (@{$from_keys_for_rel{$id}})
		{
		    push(@{$row->[0]->{$field}}, $val);
		}
	    }
	}
    }

    if (@$to_relfields)
    {
	my %ids = keys %to_keys_for_rel;
	my @ids = keys %ids;

	my $filter = "id IN (" . join(", ", map { '?' } @ids) . ")";

	for my $ent (@$to_relfields)
	{
	    my($field, $rel) = @$ent;
	    
	    my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	    $sth->execute(@ids);
	    while (my $row = $sth->fetchrow_arrayref())
	    {
		my($id, $val) = @$row;

		for my $row (@{$to_keys_for_rel{$id}})
		{
		    push(@{$row->[2]->{$field}}, $val);
		}
	    }
	}
    }


    return $out;
}    

sub _all_entities
{
    my($self, $ctx, $tbl, $start, $count, $fields) = @_;

    my($sfields, $qfields, $rel_fields) = $self->_validate_fields_for_entity($tbl, $fields, 1);

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my $qstr = join(", ", @$qfields);

    my $attrs = {};
    my $dbk = $cdmi->{_dbh};
    my $limit;
    
    if ($dbk->dbms eq 'mysql')
    {
	$attrs->{mysql_use_result} = 1;
	$limit = "LIMIT $start, $count";
    }
    elsif ($dbk->dbms eq 'Pg')
    {
	$limit = "ORDER BY id LIMIT $count OFFSET $start";
    }

    my $qry = "SELECT $qstr FROM $q$tbl$q $limit";

    my $sth = $dbk->{_dbh}->prepare($qry, $attrs);
    
    # print STDERR "$qry\n";
    $sth->execute();
    my $out = $sth->fetchall_hashref('id');

    #
    # Now query for the fields that are in separate relations.
    #
    my @ids = keys %$out;
    if (@ids)
    {
	my $filter = "id IN (" . join(", ", map { '?' } @ids) . ")";
	
	for my $ent (@$rel_fields)
	{
	    my($field, $rel) = @$ent;
	    
	    my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	    $sth->execute(@ids);
	    while (my $row = $sth->fetchrow_arrayref())
	    {
		my($id, $val) = @$row;
		push(@{$out->{$id}->{$field}}, $val);
	    }
	}
    }

    return $out;
}    

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my($cdmi) = @args;
    if (! $cdmi) {
	$cdmi = CDMI->new();
    }
    $self->{db} = $cdmi;

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 get_entity_AlignmentTree

  $return = $obj->get_entity_AlignmentTree($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AlignmentTree
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AlignmentTree
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string


=end text



=item Description

An alignment arranges a group of protein sequences so that they
match. Each alignment is associated with a phylogenetic tree that
describes how the sequences developed and their evolutionary distance.
The actual tree and alignment FASTA are stored in separate flat files.
The Kbase will maintain a set of alignments and associated
trees.  The majority
of these will be based on protein sequences.  We will not have a comprehensive set
but we will have tens of thousands of such alignments, and we view them as an
imporant resource to support annotation.
The alignments/trees will include the tools and parameters used to construct
them.
Access to the underlying sequences and trees in a form convenient to existing
tools will be supported.

It has the following fields:

=over 4


=item alignment_method

The name of the program used to produce the alignment.


=item alignment_parameters

The parameters given to the program when producing the alignment.


=item alignment_properties

A colon-delimited string of key-value pairs containing additional
properties of the alignment.


=item tree_method

The name of the program used to produce the tree.


=item tree_parameters

The parameters given to the program when producing the tree.


=item tree_properties

A colon-delimited string of key-value pairs containing additional
properties of the tree.



=back

=back

=cut

sub get_entity_AlignmentTree
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_AlignmentTree

    $return = $self->_get_entity($ctx, 'AlignmentTree', $ids, $fields);

    #END get_entity_AlignmentTree
    return($return);
}




=head2 all_entities_AlignmentTree

  $return = $obj->all_entities_AlignmentTree($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AlignmentTree
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AlignmentTree
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_AlignmentTree
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_AlignmentTree

    $return = $self->_all_entities($ctx, 'AlignmentTree', $start, $count, $fields);

    #END all_entities_AlignmentTree
    return($return);
}




=head2 get_entity_Annotation

  $return = $obj->get_entity_Annotation($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Annotation
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Annotation
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string


=end text



=item Description

An annotation is a comment attached to a feature. Annotations
are used to track the history of a feature's functional assignments
and any related issues. The key is the feature ID followed by a
colon and a complemented ten-digit sequence number.

It has the following fields:

=over 4


=item annotator

name of the annotator who made the comment


=item comment

text of the annotation


=item annotation_time

date and time at which the annotation was made



=back

=back

=cut

sub get_entity_Annotation
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Annotation

    $return = $self->_get_entity($ctx, 'Annotation', $ids, $fields);

    #END get_entity_Annotation
    return($return);
}




=head2 all_entities_Annotation

  $return = $obj->all_entities_Annotation($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Annotation
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Annotation
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Annotation
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Annotation

    $return = $self->_all_entities($ctx, 'Annotation', $start, $count, $fields);

    #END all_entities_Annotation
    return($return);
}




=head2 get_entity_AtomicRegulon

  $return = $obj->get_entity_AtomicRegulon($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AtomicRegulon
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AtomicRegulon
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

An atomic regulon is an indivisible group of coregulated features
on a single genome. Atomic regulons are constructed so that a given feature
can only belong to one. Because of this, the expression levels for
atomic regulons represent in some sense the state of a cell.
An atomicRegulon is a set of protein-encoding genes that
are believed to have identical expression profiles (i.e.,
they will all be expressed or none will be expressed in the
vast majority of conditions).  These are sometimes referred
to as "atomic regulons".  Note that there are more common
notions of "coregulated set of genes" based on the notion
that a single regulatory mechanism impacts an entire set of
genes. Since multiple other mechanisms may impact
overlapping sets, the genes impacted by a regulatory
mechanism need not all share the same expression profile.
We use a distinct notion (CoregulatedSet) to reference sets
of genes impacted by a single regulatory mechanism (i.e.,
by a single transcription regulator).

It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_AtomicRegulon
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_AtomicRegulon

    $return = $self->_get_entity($ctx, 'AtomicRegulon', $ids, $fields);

    #END get_entity_AtomicRegulon
    return($return);
}




=head2 all_entities_AtomicRegulon

  $return = $obj->all_entities_AtomicRegulon($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AtomicRegulon
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_AtomicRegulon
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_AtomicRegulon
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_AtomicRegulon

    $return = $self->_all_entities($ctx, 'AtomicRegulon', $start, $count, $fields);

    #END all_entities_AtomicRegulon
    return($return);
}




=head2 get_entity_Attribute

  $return = $obj->get_entity_Attribute($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Attribute
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Attribute
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string


=end text



=item Description

An attribute describes a category of condition or characteristic for
an experiment. The goals of the experiment can be inferred from its values
for all the attributes of interest.
It has the following fields:

=over 4


=item description

Descriptive text indicating the nature and use of this attribute.



=back

=back

=cut

sub get_entity_Attribute
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Attribute

    $return = $self->_get_entity($ctx, 'Attribute', $ids, $fields);

    #END get_entity_Attribute
    return($return);
}




=head2 all_entities_Attribute

  $return = $obj->all_entities_Attribute($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Attribute
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Attribute
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Attribute
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Attribute

    $return = $self->_all_entities($ctx, 'Attribute', $start, $count, $fields);

    #END all_entities_Attribute
    return($return);
}




=head2 get_entity_Biomass

  $return = $obj->get_entity_Biomass($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Biomass
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Biomass
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string


=end text



=item Description

A biomass is a collection of compounds in a specific
ratio and in specific compartments that are necessary for a
cell to function properly. The prediction of biomasses is key
to the functioning of the model.
It has the following fields:

=over 4


=item mod_date

last modification date of the biomass data


=item name

descriptive name for this biomass



=back

=back

=cut

sub get_entity_Biomass
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Biomass

    $return = $self->_get_entity($ctx, 'Biomass', $ids, $fields);

    #END get_entity_Biomass
    return($return);
}




=head2 all_entities_Biomass

  $return = $obj->all_entities_Biomass($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Biomass
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Biomass
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub all_entities_Biomass
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Biomass

    $return = $self->_all_entities($ctx, 'Biomass', $start, $count, $fields);

    #END all_entities_Biomass
    return($return);
}




=head2 get_entity_BiomassCompound

  $return = $obj->get_entity_BiomassCompound($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_BiomassCompound
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_BiomassCompound
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description

A Biomass Compound represents the occurrence of a particular
compound in a biomass.
It has the following fields:

=over 4


=item coefficient

proportion of the biomass in grams per mole that
contains this compound



=back

=back

=cut

sub get_entity_BiomassCompound
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_BiomassCompound

    $return = $self->_get_entity($ctx, 'BiomassCompound', $ids, $fields);

    #END get_entity_BiomassCompound
    return($return);
}




=head2 all_entities_BiomassCompound

  $return = $obj->all_entities_BiomassCompound($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_BiomassCompound
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_BiomassCompound
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description



=back

=cut

sub all_entities_BiomassCompound
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_BiomassCompound

    $return = $self->_all_entities($ctx, 'BiomassCompound', $start, $count, $fields);

    #END all_entities_BiomassCompound
    return($return);
}




=head2 get_entity_Compartment

  $return = $obj->get_entity_Compartment($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compartment
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compartment
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string


=end text



=item Description

A compartment is a section of a single model that represents
the environment in which a reaction takes place (e.g. cell
wall).
It has the following fields:

=over 4


=item abbr

short abbreviated name for this compartment (usually
a single character)


=item mod_date

date and time of the last modification to the
compartment's definition


=item name

common name for the compartment



=back

=back

=cut

sub get_entity_Compartment
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Compartment

    $return = $self->_get_entity($ctx, 'Compartment', $ids, $fields);

    #END get_entity_Compartment
    return($return);
}




=head2 all_entities_Compartment

  $return = $obj->all_entities_Compartment($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compartment
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compartment
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Compartment
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Compartment

    $return = $self->_all_entities($ctx, 'Compartment', $start, $count, $fields);

    #END all_entities_Compartment
    return($return);
}




=head2 get_entity_Complex

  $return = $obj->get_entity_Complex($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Complex
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Complex
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string


=end text



=item Description

A complex is a set of chemical reactions that act in concert to
effect a role.
It has the following fields:

=over 4


=item name

name of this complex. Not all complexes have names.


=item mod_date

date and time of the last change to this complex's definition



=back

=back

=cut

sub get_entity_Complex
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Complex

    $return = $self->_get_entity($ctx, 'Complex', $ids, $fields);

    #END get_entity_Complex
    return($return);
}




=head2 all_entities_Complex

  $return = $obj->all_entities_Complex($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Complex
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Complex
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Complex
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Complex

    $return = $self->_all_entities($ctx, 'Complex', $start, $count, $fields);

    #END all_entities_Complex
    return($return);
}




=head2 get_entity_Compound

  $return = $obj->get_entity_Compound($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compound
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compound
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description

A compound is a chemical that participates in a reaction. Both
ligands and reaction components are treated as compounds.
It has the following fields:

=over 4


=item label

primary name of the compound, for use in displaying
reactions


=item abbr

shortened abbreviation for the compound name


=item ubiquitous

TRUE if this compound is found in most reactions, else FALSE


=item mod_date

date and time of the last modification to the
compound definition


=item uncharged_formula

a electrically neutral formula for the compound


=item formula

a pH-neutral formula for the compound


=item mass

atomic mass of the compound



=back

=back

=cut

sub get_entity_Compound
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Compound

    $return = $self->_get_entity($ctx, 'Compound', $ids, $fields);

    #END get_entity_Compound
    return($return);
}




=head2 all_entities_Compound

  $return = $obj->all_entities_Compound($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compound
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Compound
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description



=back

=cut

sub all_entities_Compound
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Compound

    $return = $self->_all_entities($ctx, 'Compound', $start, $count, $fields);

    #END all_entities_Compound
    return($return);
}




=head2 get_entity_Contig

  $return = $obj->get_entity_Contig($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Contig
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Contig
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string


=end text



=item Description

A contig is thought of as composing a part of the DNA associated with a specific
genome.  It is represented as an ID (including the genome ID) and a ContigSequence.
We do not think of strings of DNA from, say, a metgenomic sample as "contigs",
since there is no associated genome (these would be considered ContigSequences).
This use of the term "ContigSequence", rather than just "DNA sequence", may turn out
to be a bad idea.  For now, you should just realize that a Contig has an associated
genome, but a ContigSequence does not.

It has the following fields:

=over 4


=item source_id

ID of this contig from the core (source) database



=back

=back

=cut

sub get_entity_Contig
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Contig

    $return = $self->_get_entity($ctx, 'Contig', $ids, $fields);

    #END get_entity_Contig
    return($return);
}




=head2 all_entities_Contig

  $return = $obj->all_entities_Contig($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Contig
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Contig
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Contig
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Contig

    $return = $self->_all_entities($ctx, 'Contig', $start, $count, $fields);

    #END all_entities_Contig
    return($return);
}




=head2 get_entity_ContigChunk

  $return = $obj->get_entity_ContigChunk($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigChunk
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigChunk
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description

ContigChunks are strings of DNA thought of as being a string in a 4-character alphabet
with an associated ID.  We allow a broader alphabet that includes U (for RNA) and
the standard ambiguity characters.
The notion of ContigChunk was introduced to avoid transferring/manipulating
huge contigs to access small substrings.  A ContigSequence is formed by
concatenating a set of one or more ContigChunks.  Thus, ContigChunks are the
basic units moved from the database to memory.  Their existence should be
hidden from users in most circumstances (users are expected to request
substrings of ContigSequences, and the Kbase software locates the appropriate
ContigChunks).

It has the following fields:

=over 4


=item sequence

base pairs that make up this sequence



=back

=back

=cut

sub get_entity_ContigChunk
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_ContigChunk

    $return = $self->_get_entity($ctx, 'ContigChunk', $ids, $fields);

    #END get_entity_ContigChunk
    return($return);
}




=head2 all_entities_ContigChunk

  $return = $obj->all_entities_ContigChunk($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigChunk
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigChunk
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_ContigChunk
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_ContigChunk

    $return = $self->_all_entities($ctx, 'ContigChunk', $start, $count, $fields);

    #END all_entities_ContigChunk
    return($return);
}




=head2 get_entity_ContigSequence

  $return = $obj->get_entity_ContigSequence($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigSequence
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigSequence
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int


=end text



=item Description

ContigSequences are strings of DNA.  Contigs have an associated
genome, but ContigSequences do not..   We can think of random samples of DNA as a set of ContigSequences.
There are no length constraints imposed on ContigSequences -- they can be either
very short or very long.  The basic unit of data that is moved to/from the database
is the ContigChunk, from which ContigSequences are formed. The key
of a ContigSequence is the sequence's MD5 identifier.

It has the following fields:

=over 4


=item length

number of base pairs in the contig



=back

=back

=cut

sub get_entity_ContigSequence
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_ContigSequence

    $return = $self->_get_entity($ctx, 'ContigSequence', $ids, $fields);

    #END get_entity_ContigSequence
    return($return);
}




=head2 all_entities_ContigSequence

  $return = $obj->all_entities_ContigSequence($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigSequence
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ContigSequence
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int


=end text



=item Description



=back

=cut

sub all_entities_ContigSequence
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_ContigSequence

    $return = $self->_all_entities($ctx, 'ContigSequence', $start, $count, $fields);

    #END all_entities_ContigSequence
    return($return);
}




=head2 get_entity_CoregulatedSet

  $return = $obj->get_entity_CoregulatedSet($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_CoregulatedSet
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_CoregulatedSet
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string


=end text



=item Description

We need to represent sets of genes that are coregulated via some
regulatory mechanism.  In particular, we wish to represent genes
that are coregulated using transcription binding sites and
corresponding transcription regulatory proteins.
We represent a coregulated set (which may, or may not, be considered
an atomic regulon) using CoregulatedSet.

It has the following fields:

=over 4


=item reason

Description of how this coregulated set was derived.



=back

=back

=cut

sub get_entity_CoregulatedSet
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_CoregulatedSet

    $return = $self->_get_entity($ctx, 'CoregulatedSet', $ids, $fields);

    #END get_entity_CoregulatedSet
    return($return);
}




=head2 all_entities_CoregulatedSet

  $return = $obj->all_entities_CoregulatedSet($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_CoregulatedSet
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_CoregulatedSet
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_CoregulatedSet
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_CoregulatedSet

    $return = $self->_all_entities($ctx, 'CoregulatedSet', $start, $count, $fields);

    #END all_entities_CoregulatedSet
    return($return);
}




=head2 get_entity_Diagram

  $return = $obj->get_entity_Diagram($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Diagram
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Diagram
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string


=end text



=item Description

A functional diagram describes a network of chemical
reactions, often comprising a single subsystem.
It has the following fields:

=over 4


=item name

descriptive name of this diagram


=item content

content of the diagram, in PNG format



=back

=back

=cut

sub get_entity_Diagram
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Diagram

    $return = $self->_get_entity($ctx, 'Diagram', $ids, $fields);

    #END get_entity_Diagram
    return($return);
}




=head2 all_entities_Diagram

  $return = $obj->all_entities_Diagram($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Diagram
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Diagram
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub all_entities_Diagram
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Diagram

    $return = $self->_all_entities($ctx, 'Diagram', $start, $count, $fields);

    #END all_entities_Diagram
    return($return);
}




=head2 get_entity_EcNumber

  $return = $obj->get_entity_EcNumber($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_EcNumber
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_EcNumber
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string


=end text



=item Description

EC numbers are assigned by the Enzyme Commission, and consist
of four numbers separated by periods, each indicating a successively
smaller cateogry of enzymes.
It has the following fields:

=over 4


=item obsolete

This boolean indicates when an EC number is obsolete.


=item replacedby

When an obsolete EC number is replaced with another EC number, this string will
hold the name of the replacement EC number.



=back

=back

=cut

sub get_entity_EcNumber
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_EcNumber

    $return = $self->_get_entity($ctx, 'EcNumber', $ids, $fields);

    #END get_entity_EcNumber
    return($return);
}




=head2 all_entities_EcNumber

  $return = $obj->all_entities_EcNumber($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_EcNumber
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_EcNumber
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_EcNumber
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_EcNumber

    $return = $self->_all_entities($ctx, 'EcNumber', $start, $count, $fields);

    #END all_entities_EcNumber
    return($return);
}




=head2 get_entity_Experiment

  $return = $obj->get_entity_Experiment($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Experiment
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Experiment
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description

An experiment is a combination of conditions for which gene expression
information is desired. The result of the experiment is a set of expression
levels for features under the given conditions.
It has the following fields:

=over 4


=item source

Publication or lab relevant to this experiment.



=back

=back

=cut

sub get_entity_Experiment
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Experiment

    $return = $self->_get_entity($ctx, 'Experiment', $ids, $fields);

    #END get_entity_Experiment
    return($return);
}




=head2 all_entities_Experiment

  $return = $obj->all_entities_Experiment($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Experiment
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Experiment
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Experiment
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Experiment

    $return = $self->_all_entities($ctx, 'Experiment', $start, $count, $fields);

    #END all_entities_Experiment
    return($return);
}




=head2 get_entity_Family

  $return = $obj->get_entity_Family($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string


=end text



=item Description

The Kbase will support the maintenance of protein families (as sets of Features
with associated translations).  We are initially only supporting the notion of a family
as composed of a set of isofunctional homologs.  That is, the families we
initially support should be thought of as containing protein-encoding genes whose
associated sequences all implement the same function
(we do understand that the notion of "function" is somewhat ambiguous, so let
us sweep this under the rug by calling a functional role a "primitive concept").
We currently support families in which the members are
translations of features, and we think of Features as
having an associated function. Identical protein sequences
as products of translating distinct genes may or may not
have identical functions, and we allow multiple members of
the same Family to share identical protein sequences.  This
may be justified, since in a very, very, very few cases
identical proteins do, in fact, have distinct functions.
We would prefer to reach the point where our Families are
sets of protein sequence, rather than sets of
protein-encoding Features.

It has the following fields:

=over 4


=item type

type of protein family (e.g. FIGfam, equivalog)


=item family_function

optional free-form description of the family. For function-based
families, this would be the functional role for the family
members.



=back

=back

=cut

sub get_entity_Family
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Family

    $return = $self->_get_entity($ctx, 'Family', $ids, $fields);

    #END get_entity_Family
    return($return);
}




=head2 all_entities_Family

  $return = $obj->all_entities_Family($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub all_entities_Family
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Family

    $return = $self->_all_entities($ctx, 'Family', $start, $count, $fields);

    #END all_entities_Family
    return($return);
}




=head2 get_entity_Feature

  $return = $obj->get_entity_Feature($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

A feature (sometimes also called a gene) is a part of a
genome that is of special interest. Features may be spread across
multiple DNA sequences (contigs) of a genome, but never across more
than one genome. Each feature in the database has a unique
ID that functions as its ID in this table.
Normally a Feature is just a single contigous region on a contig.
Features have types, and an appropriate choice of available types
allows the support of protein-encoding genes, exons, RNA genes,
binding sites, pathogenicity islands, or whatever.

It has the following fields:

=over 4


=item feature_type

Code indicating the type of this feature. Among the
codes currently supported are "peg" for a protein encoding
gene, "bs" for a binding site, "opr" for an operon, and so
forth.


=item source_id

ID for this feature in its original source (core)
database


=item sequence_length

Number of base pairs in this feature.


=item function

Functional assignment for this feature. This will
often indicate the feature's functional role or roles, and
may also have comments.



=back

=back

=cut

sub get_entity_Feature
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Feature

    $return = $self->_get_entity($ctx, 'Feature', $ids, $fields);

    #END get_entity_Feature
    return($return);
}




=head2 all_entities_Feature

  $return = $obj->all_entities_Feature($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Feature
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Feature

    $return = $self->_all_entities($ctx, 'Feature', $start, $count, $fields);

    #END all_entities_Feature
    return($return);
}




=head2 get_entity_Genome

  $return = $obj->get_entity_Genome($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Genome
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Genome
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description

The Kbase houses a large and growing set of genomes.  We often have multiple
genomes that have identical DNA.  These usually have distinct gene calls and
annotations, but not always.  We consider the Kbase to be a framework for
managing hundreds of thousands of genomes and offering the tools needed to
support compartive analysis on large sets of genomes, some of which are
virtually identical.
Each genome has an MD5 value computed from the DNA that is associated with the genome.
Hence, it is easy to recognize when you have identical genomes, perhaps annotated
by distinct groups.

It has the following fields:

=over 4


=item pegs

Number of protein encoding genes for this genome.


=item rnas

Number of RNA features found for this organism.


=item scientific_name

Full genus/species/strain name of the genome sequence.


=item complete

TRUE if the genome sequence is complete, else FALSE


=item prokaryotic

TRUE if this is a prokaryotic genome sequence, else FALSE


=item dna_size

Number of base pairs in the genome sequence.


=item contigs

Number of contigs for this genome sequence.


=item domain

Domain for this organism (Archaea, Bacteria, Eukaryota,
Virus, Plasmid, or Environmental Sample).


=item genetic_code

Genetic code number used for protein translation on most
of this genome sequence's contigs.


=item gc_content

Percent GC content present in the genome sequence's
DNA.


=item phenotype

zero or more strings describing phenotypic information
about this genome sequence


=item md5

MD5 identifier describing the genome's DNA sequence


=item source_id

identifier assigned to this genome by the original
source



=back

=back

=cut

sub get_entity_Genome
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Genome

    $return = $self->_get_entity($ctx, 'Genome', $ids, $fields);

    #END get_entity_Genome
    return($return);
}




=head2 all_entities_Genome

  $return = $obj->all_entities_Genome($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Genome
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Genome
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Genome
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Genome

    $return = $self->_all_entities($ctx, 'Genome', $start, $count, $fields);

    #END all_entities_Genome
    return($return);
}




=head2 get_entity_Identifier

  $return = $obj->get_entity_Identifier($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Identifier
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Identifier
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string


=end text



=item Description

An identifier is an alternate name for a protein sequence.
The identifier is typically stored in a prefixed form that
indicates the database it came from.
It has the following fields:

=over 4


=item source

Specific type of the identifier, such as its source
database or category. The type can usually be decoded to
convert the identifier to a URL.


=item natural_form

Natural form of the identifier. This is how the identifier looks
without the identifying prefix (if one is present).



=back

=back

=cut

sub get_entity_Identifier
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Identifier

    $return = $self->_get_entity($ctx, 'Identifier', $ids, $fields);

    #END get_entity_Identifier
    return($return);
}




=head2 all_entities_Identifier

  $return = $obj->all_entities_Identifier($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Identifier
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Identifier
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Identifier
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Identifier

    $return = $self->_all_entities($ctx, 'Identifier', $start, $count, $fields);

    #END all_entities_Identifier
    return($return);
}




=head2 get_entity_Media

  $return = $obj->get_entity_Media($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Media
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Media
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string


=end text



=item Description

A media describes the chemical content of the solution in which cells
are grown in an experiment or for the purposes of a model. The key is the
common media name. The nature of the media is described by its relationship
to its constituent compounds.
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to the media's
definition


=item name

descriptive name of the media


=item type

type of the medium (aerobic or anaerobic)



=back

=back

=cut

sub get_entity_Media
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Media

    $return = $self->_get_entity($ctx, 'Media', $ids, $fields);

    #END get_entity_Media
    return($return);
}




=head2 all_entities_Media

  $return = $obj->all_entities_Media($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Media
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Media
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Media
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Media

    $return = $self->_all_entities($ctx, 'Media', $start, $count, $fields);

    #END all_entities_Media
    return($return);
}




=head2 get_entity_Model

  $return = $obj->get_entity_Model($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Model
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Model
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int


=end text



=item Description

A model specifies a relationship between sets of features and
reactions in a cell. It is used to simulate cell growth and gene
knockouts to validate annotations.
It has the following fields:

=over 4


=item mod_date

date and time of the last change to the model data


=item name

descriptive name of the model


=item version

revision number of the model


=item type

ask Chris


=item status

indicator of whether the model is stable, under
construction, or under reconstruction


=item reaction_count

number of reactions in the model


=item compound_count

number of compounds in the model


=item annotation_count

number of annotations used to build the model



=back

=back

=cut

sub get_entity_Model
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Model

    $return = $self->_get_entity($ctx, 'Model', $ids, $fields);

    #END get_entity_Model
    return($return);
}




=head2 all_entities_Model

  $return = $obj->all_entities_Model($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Model
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Model
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int


=end text



=item Description



=back

=cut

sub all_entities_Model
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Model

    $return = $self->_all_entities($ctx, 'Model', $start, $count, $fields);

    #END all_entities_Model
    return($return);
}




=head2 get_entity_ModelCompartment

  $return = $obj->get_entity_ModelCompartment($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ModelCompartment
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ModelCompartment
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float


=end text



=item Description

The Model Compartment represents a section of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.
It has the following fields:

=over 4


=item compartment_index

number used to distinguish between different
instances of the same type of compartment in a single
model. Within a model, any two instances of the same
compartment must have difference compartment index
values.


=item label

description used to differentiate between instances
of the same compartment in a single model


=item pH

pH used to determine proton balance in this
compartment


=item potential

ask Chris



=back

=back

=cut

sub get_entity_ModelCompartment
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_ModelCompartment

    $return = $self->_get_entity($ctx, 'ModelCompartment', $ids, $fields);

    #END get_entity_ModelCompartment
    return($return);
}




=head2 all_entities_ModelCompartment

  $return = $obj->all_entities_ModelCompartment($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ModelCompartment
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ModelCompartment
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float


=end text



=item Description



=back

=cut

sub all_entities_ModelCompartment
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_ModelCompartment

    $return = $self->_all_entities($ctx, 'ModelCompartment', $start, $count, $fields);

    #END all_entities_ModelCompartment
    return($return);
}




=head2 get_entity_OTU

  $return = $obj->get_entity_OTU($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_OTU
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_OTU
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

An OTU (Organism Taxonomic Unit) is a named group of related
genomes.
It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_OTU
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_OTU

    $return = $self->_get_entity($ctx, 'OTU', $ids, $fields);

    #END get_entity_OTU
    return($return);
}




=head2 all_entities_OTU

  $return = $obj->all_entities_OTU($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_OTU
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_OTU
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_OTU
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_OTU

    $return = $self->_all_entities($ctx, 'OTU', $start, $count, $fields);

    #END all_entities_OTU
    return($return);
}




=head2 get_entity_PairSet

  $return = $obj->get_entity_PairSet($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_PairSet
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_PairSet
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int


=end text



=item Description

A PairSet is a precompute set of pairs or genes.  Each pair occurs close to
one another of the chromosome.  We believe that all of the first members
of the pairs correspond to one another (are quite similar), as do all of
the second members of the pairs.  These pairs (from prokaryotic genomes)
offer on of the most powerful clues relating to uncharacterized genes/peroteins.

It has the following fields:

=over 4


=item score

Score for this evidence set. The score indicates the
number of significantly different genomes represented by the
pairings.



=back

=back

=cut

sub get_entity_PairSet
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_PairSet

    $return = $self->_get_entity($ctx, 'PairSet', $ids, $fields);

    #END get_entity_PairSet
    return($return);
}




=head2 all_entities_PairSet

  $return = $obj->all_entities_PairSet($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_PairSet
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_PairSet
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int


=end text



=item Description



=back

=cut

sub all_entities_PairSet
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_PairSet

    $return = $self->_all_entities($ctx, 'PairSet', $start, $count, $fields);

    #END all_entities_PairSet
    return($return);
}




=head2 get_entity_Pairing

  $return = $obj->get_entity_Pairing($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Pairing
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Pairing
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

A pairing indicates that two features are found
close together in a genome. Not all possible pairings are stored in
the database; only those that are considered for some reason to be
significant for annotation purposes.The key of the pairing is the
concatenation of the feature IDs in alphabetical order with an
intervening colon.
It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_Pairing
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Pairing

    $return = $self->_get_entity($ctx, 'Pairing', $ids, $fields);

    #END get_entity_Pairing
    return($return);
}




=head2 all_entities_Pairing

  $return = $obj->all_entities_Pairing($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Pairing
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Pairing
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Pairing
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Pairing

    $return = $self->_all_entities($ctx, 'Pairing', $start, $count, $fields);

    #END all_entities_Pairing
    return($return);
}




=head2 get_entity_ProbeSet

  $return = $obj->get_entity_ProbeSet($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProbeSet
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProbeSet
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

A probe set is a device containing multiple probe sequences for use
in gene expression experiments.
It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_ProbeSet
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_ProbeSet

    $return = $self->_get_entity($ctx, 'ProbeSet', $ids, $fields);

    #END get_entity_ProbeSet
    return($return);
}




=head2 all_entities_ProbeSet

  $return = $obj->all_entities_ProbeSet($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProbeSet
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProbeSet
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_ProbeSet
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_ProbeSet

    $return = $self->_all_entities($ctx, 'ProbeSet', $start, $count, $fields);

    #END all_entities_ProbeSet
    return($return);
}




=head2 get_entity_ProteinSequence

  $return = $obj->get_entity_ProteinSequence($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description

We use the concept of ProteinSequence as an amino acid string with an associated
MD5 value.  It is easy to access the set of Features that relate to a ProteinSequence.
While function is still associated with Features (and may be for some time), publications
are associated with ProteinSequences (and the inferred impact on Features is through
the relationship connecting ProteinSequences to Features).

It has the following fields:

=over 4


=item sequence

The sequence contains the letters corresponding to
the protein's amino acids.



=back

=back

=cut

sub get_entity_ProteinSequence
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_ProteinSequence

    $return = $self->_get_entity($ctx, 'ProteinSequence', $ids, $fields);

    #END get_entity_ProteinSequence
    return($return);
}




=head2 all_entities_ProteinSequence

  $return = $obj->all_entities_ProteinSequence($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_ProteinSequence
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_ProteinSequence

    $return = $self->_all_entities($ctx, 'ProteinSequence', $start, $count, $fields);

    #END all_entities_ProteinSequence
    return($return);
}




=head2 get_entity_Publication

  $return = $obj->get_entity_Publication($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Publication
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Publication
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string


=end text



=item Description

Annotators attach publications to ProteinSequences.  The criteria we have used
to gather such connections is a bit nonstandard.  We have sought to attach publications
to ProteinSequences when the publication includes an expert asserting a belief or estimate
of function.  The paper may not be the original characterization.  Further, it may not
even discuss a sequence protein (much of the lietarture is very valuable, but reports
work on proteins in strains that have not yet been sequenced).  On the other hand,
reports of sequencing regions of a chromosome (with no specific assertion of a
clear function) should not be attached.  The attached publications give an ID (usually a
Pubmed ID),  a URL to the paper (when we have it), and a title (when we have it).

It has the following fields:

=over 4


=item citation

Hyperlink of the article. The text is the article title.



=back

=back

=cut

sub get_entity_Publication
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Publication

    $return = $self->_get_entity($ctx, 'Publication', $ids, $fields);

    #END get_entity_Publication
    return($return);
}




=head2 all_entities_Publication

  $return = $obj->all_entities_Publication($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Publication
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Publication
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Publication
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Publication

    $return = $self->_all_entities($ctx, 'Publication', $start, $count, $fields);

    #END all_entities_Publication
    return($return);
}




=head2 get_entity_Reaction

  $return = $obj->get_entity_Reaction($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reaction
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reaction
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description

A reaction is a chemical process that converts one set of
compounds (substrate) to another set (products).
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to this reaction's
definition


=item name

descriptive name of this reaction


=item abbr

abbreviated name of this reaction


=item equation

displayable formula for the reaction


=item reversibility

direction of this reaction (> for forward-only,
< for backward-only, = for bidirectional)



=back

=back

=cut

sub get_entity_Reaction
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Reaction

    $return = $self->_get_entity($ctx, 'Reaction', $ids, $fields);

    #END get_entity_Reaction
    return($return);
}




=head2 all_entities_Reaction

  $return = $obj->all_entities_Reaction($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reaction
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reaction
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Reaction
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Reaction

    $return = $self->_all_entities($ctx, 'Reaction', $start, $count, $fields);

    #END all_entities_Reaction
    return($return);
}




=head2 get_entity_ReactionRule

  $return = $obj->get_entity_ReactionRule($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ReactionRule
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ReactionRule
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float


=end text



=item Description

A reaction rule represents the way a reaction takes place
within the context of a model.
It has the following fields:

=over 4


=item direction

reaction directionality (> for forward, < for
backward, = for bidirectional) with respect to this complex


=item transproton

ask Chris



=back

=back

=cut

sub get_entity_ReactionRule
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_ReactionRule

    $return = $self->_get_entity($ctx, 'ReactionRule', $ids, $fields);

    #END get_entity_ReactionRule
    return($return);
}




=head2 all_entities_ReactionRule

  $return = $obj->all_entities_ReactionRule($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ReactionRule
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_ReactionRule
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float


=end text



=item Description



=back

=cut

sub all_entities_ReactionRule
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_ReactionRule

    $return = $self->_all_entities($ctx, 'ReactionRule', $start, $count, $fields);

    #END all_entities_ReactionRule
    return($return);
}




=head2 get_entity_Reagent

  $return = $obj->get_entity_Reagent($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reagent
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reagent
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float


=end text



=item Description

This entity represents a compound as it is used by
a specific reaction. A reaction involves many compounds, and a
compound can be involved in many reactions. The reagent
describes the use of the compound by a specific reaction.
It has the following fields:

=over 4


=item stoichiometry

Number of molecules of the compound that participate
in a single instance of the reaction. For example, if a
reaction produces two water molecules, the stoichiometry of
water for the reaction would be two. When a reaction is
written on paper in chemical notation, the stoichiometry is
the number next to the chemical formula of the
compound. The value is negative for substrates and positive
for products.


=item cofactor

TRUE if the compound is a cofactor; FALSE if it is a major
component of the reaction.


=item compartment_index

Abstract number that groups this reagent into a
compartment. Each group can then be assigned to real
compartments when doing comparative analysis.


=item transport_coefficient

Number of reagents of this type transported.
A positive value implies transport into the reactions
default compartment; a negative value implies export
to the reagent's specified compartment.



=back

=back

=cut

sub get_entity_Reagent
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Reagent

    $return = $self->_get_entity($ctx, 'Reagent', $ids, $fields);

    #END get_entity_Reagent
    return($return);
}




=head2 all_entities_Reagent

  $return = $obj->all_entities_Reagent($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reagent
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Reagent
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float


=end text



=item Description



=back

=cut

sub all_entities_Reagent
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Reagent

    $return = $self->_all_entities($ctx, 'Reagent', $start, $count, $fields);

    #END all_entities_Reagent
    return($return);
}




=head2 get_entity_Requirement

  $return = $obj->get_entity_Requirement($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Requirement
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Requirement
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float


=end text



=item Description

A requirement describes the way a reaction fits
into a model.
It has the following fields:

=over 4


=item direction

reaction directionality (> for forward, < for
backward, = for bidirectional) with respect to this model


=item transproton

ask Chris


=item proton

ask Chris



=back

=back

=cut

sub get_entity_Requirement
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Requirement

    $return = $self->_get_entity($ctx, 'Requirement', $ids, $fields);

    #END get_entity_Requirement
    return($return);
}




=head2 all_entities_Requirement

  $return = $obj->all_entities_Requirement($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Requirement
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Requirement
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float


=end text



=item Description



=back

=cut

sub all_entities_Requirement
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Requirement

    $return = $self->_all_entities($ctx, 'Requirement', $start, $count, $fields);

    #END all_entities_Requirement
    return($return);
}




=head2 get_entity_Role

  $return = $obj->get_entity_Role($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Role
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Role
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description

A role describes a biological function that may be fulfilled
by a feature. One of the main goals of the database is to assign
features to roles. Most roles are effected by the construction of
proteins. Some, however, deal with functional regulation and message
transmission.
It has the following fields:

=over 4


=item hypothetical

TRUE if a role is hypothetical, else FALSE



=back

=back

=cut

sub get_entity_Role
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Role

    $return = $self->_get_entity($ctx, 'Role', $ids, $fields);

    #END get_entity_Role
    return($return);
}




=head2 all_entities_Role

  $return = $obj->all_entities_Role($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Role
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Role
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description



=back

=cut

sub all_entities_Role
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Role

    $return = $self->_all_entities($ctx, 'Role', $start, $count, $fields);

    #END all_entities_Role
    return($return);
}




=head2 get_entity_SSCell

  $return = $obj->get_entity_SSCell($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSCell
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSCell
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

An SSCell (SpreadSheet Cell) represents a role as it occurs
in a subsystem spreadsheet row. The key is a colon-delimited triple
containing an MD5 hash of the subsystem ID followed by a genome ID
(with optional region string) and a role abbreviation.
It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_SSCell
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_SSCell

    $return = $self->_get_entity($ctx, 'SSCell', $ids, $fields);

    #END get_entity_SSCell
    return($return);
}




=head2 all_entities_SSCell

  $return = $obj->all_entities_SSCell($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSCell
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSCell
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_SSCell
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_SSCell

    $return = $self->_all_entities($ctx, 'SSCell', $start, $count, $fields);

    #END all_entities_SSCell
    return($return);
}




=head2 get_entity_SSRow

  $return = $obj->get_entity_SSRow($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSRow
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSRow
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string


=end text



=item Description

An SSRow (that is, a row in a subsystem spreadsheet) represents a collection of
functional roles present in the Features of a single Genome.  The roles are part
of a designated subsystem, and the fids associated with each role are included in the row,
That is, a row amounts to an instance of a subsystem as it exists in a specific, designated
genome.

It has the following fields:

=over 4


=item curated

This flag is TRUE if the assignment of the molecular
machine has been curated, and FALSE if it was made by an
automated program.


=item region

Region in the genome for which the machine is relevant.
Normally, this is an empty string, indicating that the machine
covers the whole genome. If a subsystem has multiple machines
for a genome, this contains a location string describing the
region occupied by this particular machine.



=back

=back

=cut

sub get_entity_SSRow
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_SSRow

    $return = $self->_get_entity($ctx, 'SSRow', $ids, $fields);

    #END get_entity_SSRow
    return($return);
}




=head2 all_entities_SSRow

  $return = $obj->all_entities_SSRow($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSRow
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SSRow
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_SSRow
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_SSRow

    $return = $self->_all_entities($ctx, 'SSRow', $start, $count, $fields);

    #END all_entities_SSRow
    return($return);
}




=head2 get_entity_Scenario

  $return = $obj->get_entity_Scenario($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Scenario
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Scenario
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string


=end text



=item Description

A scenario is a partial instance of a subsystem with a
defined set of reactions. Each scenario converts input compounds to
output compounds using reactions. The scenario may use all of the
reactions controlled by a subsystem or only some, and may also
incorporate additional reactions. Because scenario names are not
unique, the actual scenario ID is a number.
It has the following fields:

=over 4


=item common_name

Common name of the scenario. The name, rather than the ID
number, is usually displayed everywhere.



=back

=back

=cut

sub get_entity_Scenario
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Scenario

    $return = $self->_get_entity($ctx, 'Scenario', $ids, $fields);

    #END get_entity_Scenario
    return($return);
}




=head2 all_entities_Scenario

  $return = $obj->all_entities_Scenario($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Scenario
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Scenario
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Scenario
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Scenario

    $return = $self->_all_entities($ctx, 'Scenario', $start, $count, $fields);

    #END all_entities_Scenario
    return($return);
}




=head2 get_entity_Source

  $return = $obj->get_entity_Source($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Source
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Source
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

A source is a user or organization that is permitted to
assign its own identifiers or to submit bioinformatic objects
to the database.
It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_Source
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Source

    $return = $self->_get_entity($ctx, 'Source', $ids, $fields);

    #END get_entity_Source
    return($return);
}




=head2 all_entities_Source

  $return = $obj->all_entities_Source($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Source
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Source
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Source
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Source

    $return = $self->_all_entities($ctx, 'Source', $start, $count, $fields);

    #END all_entities_Source
    return($return);
}




=head2 get_entity_Subsystem

  $return = $obj->get_entity_Subsystem($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Subsystem
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Subsystem
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description

A subsystem is a set of functional roles that have been annotated simultaneously (e.g.,
the roles present in a specific pathway), with an associated subsystem spreadsheet
which encodes the fids in each genome that implement the functional roles in the
subsystem.

It has the following fields:

=over 4


=item version

version number for the subsystem. This value is
incremented each time the subsystem is backed up.


=item curator

name of the person currently in charge of the
subsystem


=item notes

descriptive notes about the subsystem


=item description

description of the subsystem's function in the
cell


=item usable

TRUE if this is a usable subsystem, else FALSE. An
unusable subsystem is one that is experimental or is of
such low quality that it can negatively affect analysis.


=item private

TRUE if this is a private subsystem, else FALSE. A
private subsystem has valid data, but is not considered ready
for general distribution.


=item cluster_based

TRUE if this is a clustering-based subsystem, else
FALSE. A clustering-based subsystem is one in which there is
functional-coupling evidence that genes belong together, but
we do not yet know what they do.


=item experimental

TRUE if this is an experimental subsystem, else FALSE.
An experimental subsystem is designed for investigation and
is not yet ready to be used in comparative analysis and
annotation.



=back

=back

=cut

sub get_entity_Subsystem
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Subsystem

    $return = $self->_get_entity($ctx, 'Subsystem', $ids, $fields);

    #END get_entity_Subsystem
    return($return);
}




=head2 all_entities_Subsystem

  $return = $obj->all_entities_Subsystem($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Subsystem
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Subsystem
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description



=back

=cut

sub all_entities_Subsystem
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Subsystem

    $return = $self->_all_entities($ctx, 'Subsystem', $start, $count, $fields);

    #END all_entities_Subsystem
    return($return);
}




=head2 get_entity_SubsystemClass

  $return = $obj->get_entity_SubsystemClass($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

Subsystem classes impose a hierarchical organization on the
subsystems.
It has the following fields:

=over 4



=back

=back

=cut

sub get_entity_SubsystemClass
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_SubsystemClass

    $return = $self->_get_entity($ctx, 'SubsystemClass', $ids, $fields);

    #END get_entity_SubsystemClass
    return($return);
}




=head2 all_entities_SubsystemClass

  $return = $obj->all_entities_SubsystemClass($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_SubsystemClass
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_SubsystemClass

    $return = $self->_all_entities($ctx, 'SubsystemClass', $start, $count, $fields);

    #END all_entities_SubsystemClass
    return($return);
}




=head2 get_entity_TaxonomicGrouping

  $return = $obj->get_entity_TaxonomicGrouping($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string


=end text



=item Description

We associate with most genomes a "taxonomy" based on the NCBI taxonomy.
This includes, for each genome, a list of ever larger taxonomic groups.

It has the following fields:

=over 4


=item domain

TRUE if this is a domain grouping, else FALSE.


=item hidden

TRUE if this is a hidden grouping, else FALSE. Hidden groupings
are not typically shown in a lineage list.


=item scientific_name

Primary scientific name for this grouping. This is the name used
when displaying a taxonomy.


=item alias

Alternate name for this grouping. A grouping
may have many alternate names. The scientific name should also
be in this list.



=back

=back

=cut

sub get_entity_TaxonomicGrouping
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_TaxonomicGrouping

    $return = $self->_get_entity($ctx, 'TaxonomicGrouping', $ids, $fields);

    #END get_entity_TaxonomicGrouping
    return($return);
}




=head2 all_entities_TaxonomicGrouping

  $return = $obj->all_entities_TaxonomicGrouping($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub all_entities_TaxonomicGrouping
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_TaxonomicGrouping

    $return = $self->_all_entities($ctx, 'TaxonomicGrouping', $start, $count, $fields);

    #END all_entities_TaxonomicGrouping
    return($return);
}




=head2 get_entity_Variant

  $return = $obj->get_entity_Variant($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variant
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variant
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string


=end text



=item Description

Each subsystem may include the designation of distinct variants.  Thus,
there may be three closely-related, but distinguishable forms of histidine
degradation.  Each form would be called a "variant", with an associated code,
and all genomes implementing a specific variant can easily be accessed.

It has the following fields:

=over 4


=item role_rule

a space-delimited list of role IDs, in alphabetical order,
that represents a possible list of non-auxiliary roles applicable to
this variant. The roles are identified by their abbreviations. A
variant may have multiple role rules.


=item code

the variant code all by itself


=item type

variant type indicating the quality of the subsystem
support. A type of "vacant" means that the subsystem
does not appear to be implemented by the variant. A
type of "incomplete" means that the subsystem appears to be
missing many reactions. In all other cases, the type is
"normal".


=item comment

commentary text about the variant



=back

=back

=cut

sub get_entity_Variant
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Variant

    $return = $self->_get_entity($ctx, 'Variant', $ids, $fields);

    #END get_entity_Variant
    return($return);
}




=head2 all_entities_Variant

  $return = $obj->all_entities_Variant($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variant
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variant
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string


=end text



=item Description



=back

=cut

sub all_entities_Variant
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Variant

    $return = $self->_all_entities($ctx, 'Variant', $start, $count, $fields);

    #END all_entities_Variant
    return($return);
}




=head2 get_entity_Variation

  $return = $obj->get_entity_Variation($ids, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variation
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variation
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string


=end text



=item Description

A variation describes a set of aligned regions
in two or more contigs.
It has the following fields:

=over 4


=item notes

optional text description of what the variation
means



=back

=back

=cut

sub get_entity_Variation
{
    my($self, $ids, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_entity_Variation

    $return = $self->_get_entity($ctx, 'Variation', $ids, $fields);

    #END get_entity_Variation
    return($return);
}




=head2 all_entities_Variation

  $return = $obj->all_entities_Variation($start, $count, $fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variation
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$start is an int
$count is an int
$fields is a reference to a list where each element is a string
$return is a reference to a hash where the key is a string and the value is a fields_Variation
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub all_entities_Variation
{
    my($self, $start, $count, $fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN all_entities_Variation

    $return = $self->_all_entities($ctx, 'Variation', $start, $count, $fields);

    #END all_entities_Variation
    return($return);
}




=head2 get_relationship_AffectsLevelOf

  $return = $obj->get_relationship_AffectsLevelOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_AffectsLevelOf
	2: a fields_AtomicRegulon
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_AffectsLevelOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level has a value which is an int
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_AffectsLevelOf
	2: a fields_AtomicRegulon
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_AffectsLevelOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level has a value which is an int
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This relationship indicates the expression level of an atomic regulon
for a given experiment.
It has the following fields:

=over 4


=item level

Indication of whether the feature is expressed (1), not expressed (-1),
or unknown (0).



=back

=back

=cut

sub get_relationship_AffectsLevelOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_AffectsLevelOf

    $return = $self->_get_relationship($ctx, 'AffectsLevelOf', 'AffectsLevelOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_AffectsLevelOf
    return($return);
}




=head2 get_relationship_IsAffectedIn

  $return = $obj->get_relationship_IsAffectedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_AffectsLevelOf
	2: a fields_Experiment
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_AffectsLevelOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level has a value which is an int
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_AffectsLevelOf
	2: a fields_Experiment
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_AffectsLevelOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level has a value which is an int
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsAffectedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsAffectedIn

    $return = $self->_get_relationship($ctx, 'IsAffectedIn', 'AffectsLevelOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAffectedIn
    return($return);
}




=head2 get_relationship_Aligns

  $return = $obj->get_relationship_Aligns($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AlignmentTree
	1: a fields_Aligns
	2: a fields_ProteinSequence
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string
fields_Aligns is a reference to a hash where the following keys are defined:
	id has a value which is a string
	begin has a value which is an int
	end has a value which is an int
	len has a value which is an int
	sequence_id has a value which is a string
	properties has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AlignmentTree
	1: a fields_Aligns
	2: a fields_ProteinSequence
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string
fields_Aligns is a reference to a hash where the following keys are defined:
	id has a value which is a string
	begin has a value which is an int
	end has a value which is an int
	len has a value which is an int
	sequence_id has a value which is a string
	properties has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description

This relationship connects each alignment to its constituent protein
sequences. Each alignment contains many protein sequences, and a single
sequence can be in many alignments. Parts of a single protein can occur
in multiple places in an alignment. The sequence-id field is used to
keep these unique, and is the string that represents the sequence in the
alignment and tree text.
It has the following fields:

=over 4


=item begin

location within the sequence at which the aligned portion begins


=item end

location within the sequence at which the aligned portion ends


=item len

length of the sequence within the alignment


=item sequence_id

identifier for this sequence in the alignment


=item properties

additional information about this sequence's participation in the
alignment



=back

=back

=cut

sub get_relationship_Aligns
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Aligns

    $return = $self->_get_relationship($ctx, 'Aligns', 'Aligns', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Aligns
    return($return);
}




=head2 get_relationship_IsAlignedBy

  $return = $obj->get_relationship_IsAlignedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_Aligns
	2: a fields_AlignmentTree
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_Aligns is a reference to a hash where the following keys are defined:
	id has a value which is a string
	begin has a value which is an int
	end has a value which is an int
	len has a value which is an int
	sequence_id has a value which is a string
	properties has a value which is a string
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_Aligns
	2: a fields_AlignmentTree
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_Aligns is a reference to a hash where the following keys are defined:
	id has a value which is a string
	begin has a value which is an int
	end has a value which is an int
	len has a value which is an int
	sequence_id has a value which is a string
	properties has a value which is a string
fields_AlignmentTree is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alignment_method has a value which is a string
	alignment_parameters has a value which is a string
	alignment_properties has a value which is a string
	tree_method has a value which is a string
	tree_parameters has a value which is a string
	tree_properties has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsAlignedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsAlignedBy

    $return = $self->_get_relationship($ctx, 'IsAlignedBy', 'Aligns', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAlignedBy
    return($return);
}




=head2 get_relationship_Concerns

  $return = $obj->get_relationship_Concerns($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Publication
	1: a fields_Concerns
	2: a fields_ProteinSequence
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string
fields_Concerns is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Publication
	1: a fields_Concerns
	2: a fields_ProteinSequence
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string
fields_Concerns is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description

This relationship connects a publication to the protein
sequences it describes.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Concerns
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Concerns

    $return = $self->_get_relationship($ctx, 'Concerns', 'Concerns', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Concerns
    return($return);
}




=head2 get_relationship_IsATopicOf

  $return = $obj->get_relationship_IsATopicOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_Concerns
	2: a fields_Publication
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_Concerns is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_Concerns
	2: a fields_Publication
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_Concerns is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Publication is a reference to a hash where the following keys are defined:
	id has a value which is a string
	citation has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsATopicOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsATopicOf

    $return = $self->_get_relationship($ctx, 'IsATopicOf', 'Concerns', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsATopicOf
    return($return);
}




=head2 get_relationship_Contains

  $return = $obj->get_relationship_Contains($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSCell
	1: a fields_Contains
	2: a fields_Feature
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Contains is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSCell
	1: a fields_Contains
	2: a fields_Feature
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Contains is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects a subsystem spreadsheet cell to the features
that occur in it. A feature may occur in many machine roles and a
machine role may contain many features. The subsystem annotation
process is essentially the maintenance of this relationship.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Contains
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Contains

    $return = $self->_get_relationship($ctx, 'Contains', 'Contains', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Contains
    return($return);
}




=head2 get_relationship_IsContainedIn

  $return = $obj->get_relationship_IsContainedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_Contains
	2: a fields_SSCell
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_Contains is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_Contains
	2: a fields_SSCell
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_Contains is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsContainedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsContainedIn

    $return = $self->_get_relationship($ctx, 'IsContainedIn', 'Contains', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsContainedIn
    return($return);
}




=head2 get_relationship_Describes

  $return = $obj->get_relationship_Describes($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_Describes
	2: a fields_Variant
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_Describes is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_Describes
	2: a fields_Variant
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_Describes is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string


=end text



=item Description

This relationship connects a subsystem to the individual
variants used to implement it. Each variant contains a slightly
different subset of the roles in the parent subsystem.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Describes
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Describes

    $return = $self->_get_relationship($ctx, 'Describes', 'Describes', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Describes
    return($return);
}




=head2 get_relationship_IsDescribedBy

  $return = $obj->get_relationship_IsDescribedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Variant
	1: a fields_Describes
	2: a fields_Subsystem
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string
fields_Describes is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Variant
	1: a fields_Describes
	2: a fields_Subsystem
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string
fields_Describes is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsDescribedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDescribedBy

    $return = $self->_get_relationship($ctx, 'IsDescribedBy', 'Describes', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDescribedBy
    return($return);
}




=head2 get_relationship_Displays

  $return = $obj->get_relationship_Displays($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_Displays
	2: a fields_Reaction
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_Displays is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_Displays
	2: a fields_Reaction
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_Displays is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description

This relationship connects a diagram to its reactions. A
diagram shows multiple reactions, and a reaction can be on many
diagrams.
It has the following fields:

=over 4


=item location

Location of the reaction's node on the diagram.



=back

=back

=cut

sub get_relationship_Displays
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Displays

    $return = $self->_get_relationship($ctx, 'Displays', 'Displays', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Displays
    return($return);
}




=head2 get_relationship_IsDisplayedOn

  $return = $obj->get_relationship_IsDisplayedOn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_Displays
	2: a fields_Diagram
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_Displays is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_Displays
	2: a fields_Diagram
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_Displays is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsDisplayedOn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDisplayedOn

    $return = $self->_get_relationship($ctx, 'IsDisplayedOn', 'Displays', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDisplayedOn
    return($return);
}




=head2 get_relationship_Encompasses

  $return = $obj->get_relationship_Encompasses($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_Encompasses
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_Encompasses is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_Encompasses
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_Encompasses is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This relationship connects a feature to a related
feature; for example, it would connect a gene to its
constituent splice variants, and the splice variants to their
exons.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Encompasses
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Encompasses

    $return = $self->_get_relationship($ctx, 'Encompasses', 'Encompasses', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Encompasses
    return($return);
}




=head2 get_relationship_IsEncompassedIn

  $return = $obj->get_relationship_IsEncompassedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_Encompasses
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_Encompasses is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_Encompasses
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_Encompasses is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsEncompassedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsEncompassedIn

    $return = $self->_get_relationship($ctx, 'IsEncompassedIn', 'Encompasses', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsEncompassedIn
    return($return);
}




=head2 get_relationship_GeneratedLevelsFor

  $return = $obj->get_relationship_GeneratedLevelsFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_GeneratedLevelsFor
	2: a fields_AtomicRegulon
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_GeneratedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_GeneratedLevelsFor
	2: a fields_AtomicRegulon
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_GeneratedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This relationship connects an atomic regulon to a probe set from which experimental
data was produced for its features. It contains a vector of the expression levels.
It has the following fields:

=over 4


=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in
sequence order.



=back

=back

=cut

sub get_relationship_GeneratedLevelsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_GeneratedLevelsFor

    $return = $self->_get_relationship($ctx, 'GeneratedLevelsFor', 'GeneratedLevelsFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_GeneratedLevelsFor
    return($return);
}




=head2 get_relationship_WasGeneratedFrom

  $return = $obj->get_relationship_WasGeneratedFrom($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_GeneratedLevelsFor
	2: a fields_ProbeSet
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_GeneratedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_GeneratedLevelsFor
	2: a fields_ProbeSet
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_GeneratedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_WasGeneratedFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_WasGeneratedFrom

    $return = $self->_get_relationship($ctx, 'WasGeneratedFrom', 'GeneratedLevelsFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasGeneratedFrom
    return($return);
}




=head2 get_relationship_HasAssertionFrom

  $return = $obj->get_relationship_HasAssertionFrom($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Identifier
	1: a fields_HasAssertionFrom
	2: a fields_Source
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string
fields_HasAssertionFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	function has a value which is a string
	expert has a value which is an int
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Identifier
	1: a fields_HasAssertionFrom
	2: a fields_Source
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string
fields_HasAssertionFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	function has a value which is a string
	expert has a value which is an int
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

Sources (users) can make assertions about identifiers using the annotation clearinghouse.
When a user makes a new assertion about an identifier, it erases the old one.
It has the following fields:

=over 4


=item function

The function is the text of the assertion made about the identifier.


=item expert

TRUE if this is an expert assertion, else FALSE



=back

=back

=cut

sub get_relationship_HasAssertionFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasAssertionFrom

    $return = $self->_get_relationship($ctx, 'HasAssertionFrom', 'HasAssertionFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAssertionFrom
    return($return);
}




=head2 get_relationship_Asserts

  $return = $obj->get_relationship_Asserts($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_HasAssertionFrom
	2: a fields_Identifier
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasAssertionFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	function has a value which is a string
	expert has a value which is an int
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_HasAssertionFrom
	2: a fields_Identifier
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasAssertionFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	function has a value which is a string
	expert has a value which is an int
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Asserts
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Asserts

    $return = $self->_get_relationship($ctx, 'Asserts', 'HasAssertionFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Asserts
    return($return);
}




=head2 get_relationship_HasCompoundAliasFrom

  $return = $obj->get_relationship_HasCompoundAliasFrom($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_HasCompoundAliasFrom
	2: a fields_Compound
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasCompoundAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_HasCompoundAliasFrom
	2: a fields_Compound
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasCompoundAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description

This relationship connects a source (database or organization)
with the compounds for which it has assigned names (aliases).
The alias itself is stored as intersection data.
It has the following fields:

=over 4


=item alias

alias for the compound assigned by the source



=back

=back

=cut

sub get_relationship_HasCompoundAliasFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasCompoundAliasFrom

    $return = $self->_get_relationship($ctx, 'HasCompoundAliasFrom', 'HasCompoundAliasFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasCompoundAliasFrom
    return($return);
}




=head2 get_relationship_UsesAliasForCompound

  $return = $obj->get_relationship_UsesAliasForCompound($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_HasCompoundAliasFrom
	2: a fields_Source
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_HasCompoundAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_HasCompoundAliasFrom
	2: a fields_Source
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_HasCompoundAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_UsesAliasForCompound
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_UsesAliasForCompound

    $return = $self->_get_relationship($ctx, 'UsesAliasForCompound', 'HasCompoundAliasFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_UsesAliasForCompound
    return($return);
}




=head2 get_relationship_HasIndicatedSignalFrom

  $return = $obj->get_relationship_HasIndicatedSignalFrom($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_HasIndicatedSignalFrom
	2: a fields_Experiment
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_HasIndicatedSignalFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	rma_value has a value which is a float
	level has a value which is an int
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_HasIndicatedSignalFrom
	2: a fields_Experiment
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_HasIndicatedSignalFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	rma_value has a value which is a float
	level has a value which is an int
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description

This relationship connects an experiment to a feature. The feature
expression levels inferred from the experimental results are stored here.
It has the following fields:

=over 4


=item rma_value

Normalized expression value for this feature under the experiment's
conditions.


=item level

Indication of whether the feature is expressed (1), not expressed (-1),
or unknown (0).



=back

=back

=cut

sub get_relationship_HasIndicatedSignalFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasIndicatedSignalFrom

    $return = $self->_get_relationship($ctx, 'HasIndicatedSignalFrom', 'HasIndicatedSignalFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasIndicatedSignalFrom
    return($return);
}




=head2 get_relationship_IndicatesSignalFor

  $return = $obj->get_relationship_IndicatesSignalFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_HasIndicatedSignalFrom
	2: a fields_Feature
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_HasIndicatedSignalFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	rma_value has a value which is a float
	level has a value which is an int
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_HasIndicatedSignalFrom
	2: a fields_Feature
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_HasIndicatedSignalFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	rma_value has a value which is a float
	level has a value which is an int
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IndicatesSignalFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IndicatesSignalFor

    $return = $self->_get_relationship($ctx, 'IndicatesSignalFor', 'HasIndicatedSignalFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IndicatesSignalFor
    return($return);
}




=head2 get_relationship_HasMember

  $return = $obj->get_relationship_HasMember($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_HasMember
	2: a fields_Feature
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_HasMember is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_HasMember
	2: a fields_Feature
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_HasMember is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects each feature family to its
constituent features. A family always has many features, and a
single feature can be found in many families.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_HasMember
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasMember

    $return = $self->_get_relationship($ctx, 'HasMember', 'HasMember', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasMember
    return($return);
}




=head2 get_relationship_IsMemberOf

  $return = $obj->get_relationship_IsMemberOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_HasMember
	2: a fields_Family
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_HasMember is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_HasMember
	2: a fields_Family
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_HasMember is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsMemberOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsMemberOf

    $return = $self->_get_relationship($ctx, 'IsMemberOf', 'HasMember', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsMemberOf
    return($return);
}




=head2 get_relationship_HasParticipant

  $return = $obj->get_relationship_HasParticipant($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_HasParticipant
	2: a fields_Reaction
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_HasParticipant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is an int
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_HasParticipant
	2: a fields_Reaction
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_HasParticipant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is an int
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description

A scenario consists of many participant reactions that
convert the input compounds to output compounds. A single reaction
may participate in many scenarios.
It has the following fields:

=over 4


=item type

Indicates the type of participaton. If 0, the
reaction is in the main pathway of the scenario. If 1, the
reaction is necessary to make the model work but is not in
the subsystem. If 2, the reaction is part of the subsystem
but should not be included in the modelling process.



=back

=back

=cut

sub get_relationship_HasParticipant
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasParticipant

    $return = $self->_get_relationship($ctx, 'HasParticipant', 'HasParticipant', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasParticipant
    return($return);
}




=head2 get_relationship_ParticipatesIn

  $return = $obj->get_relationship_ParticipatesIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_HasParticipant
	2: a fields_Scenario
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_HasParticipant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is an int
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_HasParticipant
	2: a fields_Scenario
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_HasParticipant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is an int
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_ParticipatesIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_ParticipatesIn

    $return = $self->_get_relationship($ctx, 'ParticipatesIn', 'HasParticipant', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ParticipatesIn
    return($return);
}




=head2 get_relationship_HasPresenceOf

  $return = $obj->get_relationship_HasPresenceOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Media
	1: a fields_HasPresenceOf
	2: a fields_Compound
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string
fields_HasPresenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	concentration has a value which is a float
	minimum_flux has a value which is a float
	maximum_flux has a value which is a float
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Media
	1: a fields_HasPresenceOf
	2: a fields_Compound
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string
fields_HasPresenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	concentration has a value which is a float
	minimum_flux has a value which is a float
	maximum_flux has a value which is a float
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description

This relationship connects a media to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.
It has the following fields:

=over 4


=item concentration

concentration of the compound in the media


=item minimum_flux

minimum flux of the compound for this media


=item maximum_flux

maximum flux of the compound for this media



=back

=back

=cut

sub get_relationship_HasPresenceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasPresenceOf

    $return = $self->_get_relationship($ctx, 'HasPresenceOf', 'HasPresenceOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasPresenceOf
    return($return);
}




=head2 get_relationship_IsPresentIn

  $return = $obj->get_relationship_IsPresentIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_HasPresenceOf
	2: a fields_Media
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_HasPresenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	concentration has a value which is a float
	minimum_flux has a value which is a float
	maximum_flux has a value which is a float
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_HasPresenceOf
	2: a fields_Media
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_HasPresenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	concentration has a value which is a float
	minimum_flux has a value which is a float
	maximum_flux has a value which is a float
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsPresentIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsPresentIn

    $return = $self->_get_relationship($ctx, 'IsPresentIn', 'HasPresenceOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsPresentIn
    return($return);
}




=head2 get_relationship_HasReactionAliasFrom

  $return = $obj->get_relationship_HasReactionAliasFrom($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_HasReactionAliasFrom
	2: a fields_Reaction
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasReactionAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_HasReactionAliasFrom
	2: a fields_Reaction
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasReactionAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description

This relationship connects a source (database or organization)
with the reactions for which it has assigned names (aliases).
The alias itself is stored as intersection data.
It has the following fields:

=over 4


=item alias

alias for the reaction assigned by the source



=back

=back

=cut

sub get_relationship_HasReactionAliasFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasReactionAliasFrom

    $return = $self->_get_relationship($ctx, 'HasReactionAliasFrom', 'HasReactionAliasFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasReactionAliasFrom
    return($return);
}




=head2 get_relationship_UsesAliasForReaction

  $return = $obj->get_relationship_UsesAliasForReaction($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_HasReactionAliasFrom
	2: a fields_Source
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_HasReactionAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_HasReactionAliasFrom
	2: a fields_Source
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_HasReactionAliasFrom is a reference to a hash where the following keys are defined:
	id has a value which is a string
	alias has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_UsesAliasForReaction
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_UsesAliasForReaction

    $return = $self->_get_relationship($ctx, 'UsesAliasForReaction', 'HasReactionAliasFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_UsesAliasForReaction
    return($return);
}




=head2 get_relationship_HasRepresentativeOf

  $return = $obj->get_relationship_HasRepresentativeOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_HasRepresentativeOf
	2: a fields_Family
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_HasRepresentativeOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_HasRepresentativeOf
	2: a fields_Family
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_HasRepresentativeOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string


=end text



=item Description

This relationship connects a genome to the FIGfam protein families
for which it has representative proteins. This information can be computed
from other relationships, but it is provided explicitly to allow fast access
to a genome's FIGfam profile.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_HasRepresentativeOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasRepresentativeOf

    $return = $self->_get_relationship($ctx, 'HasRepresentativeOf', 'HasRepresentativeOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasRepresentativeOf
    return($return);
}




=head2 get_relationship_IsRepresentedIn

  $return = $obj->get_relationship_IsRepresentedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_HasRepresentativeOf
	2: a fields_Genome
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_HasRepresentativeOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_HasRepresentativeOf
	2: a fields_Genome
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_HasRepresentativeOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsRepresentedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRepresentedIn

    $return = $self->_get_relationship($ctx, 'IsRepresentedIn', 'HasRepresentativeOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRepresentedIn
    return($return);
}




=head2 get_relationship_HasResultsIn

  $return = $obj->get_relationship_HasResultsIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_HasResultsIn
	2: a fields_Experiment
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasResultsIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_HasResultsIn
	2: a fields_Experiment
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_HasResultsIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description

This relationship connects a probe set to the experiments that were
applied to it.
It has the following fields:

=over 4


=item sequence

Sequence number of this experiment in the various result vectors.



=back

=back

=cut

sub get_relationship_HasResultsIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasResultsIn

    $return = $self->_get_relationship($ctx, 'HasResultsIn', 'HasResultsIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasResultsIn
    return($return);
}




=head2 get_relationship_HasResultsFor

  $return = $obj->get_relationship_HasResultsFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_HasResultsIn
	2: a fields_ProbeSet
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_HasResultsIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_HasResultsIn
	2: a fields_ProbeSet
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_HasResultsIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HasResultsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasResultsFor

    $return = $self->_get_relationship($ctx, 'HasResultsFor', 'HasResultsIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasResultsFor
    return($return);
}




=head2 get_relationship_HasSection

  $return = $obj->get_relationship_HasSection($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ContigSequence
	1: a fields_HasSection
	2: a fields_ContigChunk
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int
fields_HasSection is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ContigSequence
	1: a fields_HasSection
	2: a fields_ContigChunk
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int
fields_HasSection is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description

This relationship connects a contig's sequence to its DNA
sequences.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_HasSection
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasSection

    $return = $self->_get_relationship($ctx, 'HasSection', 'HasSection', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasSection
    return($return);
}




=head2 get_relationship_IsSectionOf

  $return = $obj->get_relationship_IsSectionOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ContigChunk
	1: a fields_HasSection
	2: a fields_ContigSequence
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_HasSection is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ContigChunk
	1: a fields_HasSection
	2: a fields_ContigSequence
fields_ContigChunk is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_HasSection is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsSectionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsSectionOf

    $return = $self->_get_relationship($ctx, 'IsSectionOf', 'HasSection', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSectionOf
    return($return);
}




=head2 get_relationship_HasStep

  $return = $obj->get_relationship_HasStep($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Complex
	1: a fields_HasStep
	2: a fields_ReactionRule
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string
fields_HasStep is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Complex
	1: a fields_HasStep
	2: a fields_ReactionRule
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string
fields_HasStep is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float


=end text



=item Description

This relationship connects a complex to the reaction
rules for the reactions that work together to make the complex
happen.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_HasStep
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasStep

    $return = $self->_get_relationship($ctx, 'HasStep', 'HasStep', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasStep
    return($return);
}




=head2 get_relationship_IsStepOf

  $return = $obj->get_relationship_IsStepOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ReactionRule
	1: a fields_HasStep
	2: a fields_Complex
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
fields_HasStep is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ReactionRule
	1: a fields_HasStep
	2: a fields_Complex
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
fields_HasStep is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsStepOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsStepOf

    $return = $self->_get_relationship($ctx, 'IsStepOf', 'HasStep', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsStepOf
    return($return);
}




=head2 get_relationship_HasUsage

  $return = $obj->get_relationship_HasUsage($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_HasUsage
	2: a fields_BiomassCompound
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_HasUsage is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_HasUsage
	2: a fields_BiomassCompound
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_HasUsage is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description

This relationship connects a biomass compound specification
to the compounds for which it is relevant.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_HasUsage
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasUsage

    $return = $self->_get_relationship($ctx, 'HasUsage', 'HasUsage', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasUsage
    return($return);
}




=head2 get_relationship_IsUsageOf

  $return = $obj->get_relationship_IsUsageOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_BiomassCompound
	1: a fields_HasUsage
	2: a fields_Compound
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float
fields_HasUsage is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_BiomassCompound
	1: a fields_HasUsage
	2: a fields_Compound
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float
fields_HasUsage is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_IsUsageOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsUsageOf

    $return = $self->_get_relationship($ctx, 'IsUsageOf', 'HasUsage', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUsageOf
    return($return);
}




=head2 get_relationship_HasValueFor

  $return = $obj->get_relationship_HasValueFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_HasValueFor
	2: a fields_Attribute
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_HasValueFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	value has a value which is a string
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_HasValueFor
	2: a fields_Attribute
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_HasValueFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	value has a value which is a string
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string


=end text



=item Description

This relationship connects an experiment to its attributes. The attribute
values are stored here.
It has the following fields:

=over 4


=item value

Value of this attribute in the given experiment. This is always encoded
as a string, but may in fact be a number.



=back

=back

=cut

sub get_relationship_HasValueFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasValueFor

    $return = $self->_get_relationship($ctx, 'HasValueFor', 'HasValueFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasValueFor
    return($return);
}




=head2 get_relationship_HasValueIn

  $return = $obj->get_relationship_HasValueIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Attribute
	1: a fields_HasValueFor
	2: a fields_Experiment
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string
fields_HasValueFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	value has a value which is a string
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Attribute
	1: a fields_HasValueFor
	2: a fields_Experiment
fields_Attribute is a reference to a hash where the following keys are defined:
	id has a value which is a string
	description has a value which is a string
fields_HasValueFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	value has a value which is a string
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HasValueIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasValueIn

    $return = $self->_get_relationship($ctx, 'HasValueIn', 'HasValueFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasValueIn
    return($return);
}




=head2 get_relationship_Includes

  $return = $obj->get_relationship_Includes($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_Includes
	2: a fields_Role
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_Includes is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
	abbreviation has a value which is a string
	auxiliary has a value which is an int
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_Includes
	2: a fields_Role
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_Includes is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
	abbreviation has a value which is a string
	auxiliary has a value which is an int
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description

A subsystem is defined by its roles. The subsystem's variants
contain slightly different sets of roles, but all of the roles in a
variant must be connected to the parent subsystem by this
relationship. A subsystem always has at least one role, and a role
always belongs to at least one subsystem.
It has the following fields:

=over 4


=item sequence

Sequence number of the role within the subsystem.
When the roles are formed into a variant, they will
generally appear in sequence order.


=item abbreviation

Abbreviation for this role in this subsystem. The
abbreviations are used in columnar displays, and they also
appear on diagrams.


=item auxiliary

TRUE if this is an auxiliary role, or FALSE if this role
is a functioning part of the subsystem.



=back

=back

=cut

sub get_relationship_Includes
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Includes

    $return = $self->_get_relationship($ctx, 'Includes', 'Includes', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Includes
    return($return);
}




=head2 get_relationship_IsIncludedIn

  $return = $obj->get_relationship_IsIncludedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_Includes
	2: a fields_Subsystem
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_Includes is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
	abbreviation has a value which is a string
	auxiliary has a value which is an int
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_Includes
	2: a fields_Subsystem
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_Includes is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is an int
	abbreviation has a value which is a string
	auxiliary has a value which is an int
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsIncludedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsIncludedIn

    $return = $self->_get_relationship($ctx, 'IsIncludedIn', 'Includes', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsIncludedIn
    return($return);
}




=head2 get_relationship_IndicatedLevelsFor

  $return = $obj->get_relationship_IndicatedLevelsFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_IndicatedLevelsFor
	2: a fields_Feature
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IndicatedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_IndicatedLevelsFor
	2: a fields_Feature
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IndicatedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects a feature to a probe set from which experimental
data was produced for the feature. It contains a vector of the expression levels.
It has the following fields:

=over 4


=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in
sequence order.



=back

=back

=cut

sub get_relationship_IndicatedLevelsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IndicatedLevelsFor

    $return = $self->_get_relationship($ctx, 'IndicatedLevelsFor', 'IndicatedLevelsFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IndicatedLevelsFor
    return($return);
}




=head2 get_relationship_HasLevelsFrom

  $return = $obj->get_relationship_HasLevelsFrom($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IndicatedLevelsFor
	2: a fields_ProbeSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IndicatedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IndicatedLevelsFor
	2: a fields_ProbeSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IndicatedLevelsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	level_vector has a value which is a countVector
countVector is a string
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HasLevelsFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasLevelsFrom

    $return = $self->_get_relationship($ctx, 'HasLevelsFrom', 'IndicatedLevelsFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasLevelsFrom
    return($return);
}




=head2 get_relationship_Involves

  $return = $obj->get_relationship_Involves($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_Involves
	2: a fields_Reagent
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_Involves is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_Involves
	2: a fields_Reagent
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_Involves is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float


=end text



=item Description

This relationship connects a reaction to the
reagents representing the compounds that participate in it.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Involves
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Involves

    $return = $self->_get_relationship($ctx, 'Involves', 'Involves', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Involves
    return($return);
}




=head2 get_relationship_IsInvolvedIn

  $return = $obj->get_relationship_IsInvolvedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reagent
	1: a fields_Involves
	2: a fields_Reaction
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float
fields_Involves is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reagent
	1: a fields_Involves
	2: a fields_Reaction
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float
fields_Involves is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsInvolvedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInvolvedIn

    $return = $self->_get_relationship($ctx, 'IsInvolvedIn', 'Involves', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInvolvedIn
    return($return);
}




=head2 get_relationship_IsARequirementIn

  $return = $obj->get_relationship_IsARequirementIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_IsARequirementIn
	2: a fields_Requirement
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_IsARequirementIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_IsARequirementIn
	2: a fields_Requirement
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_IsARequirementIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float


=end text



=item Description

This relationship connects a model to its requirements.
A requirement represents the use of a reaction in a single model.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsARequirementIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsARequirementIn

    $return = $self->_get_relationship($ctx, 'IsARequirementIn', 'IsARequirementIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsARequirementIn
    return($return);
}




=head2 get_relationship_IsARequirementOf

  $return = $obj->get_relationship_IsARequirementOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Requirement
	1: a fields_IsARequirementIn
	2: a fields_Model
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float
fields_IsARequirementIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Requirement
	1: a fields_IsARequirementIn
	2: a fields_Model
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float
fields_IsARequirementIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsARequirementOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsARequirementOf

    $return = $self->_get_relationship($ctx, 'IsARequirementOf', 'IsARequirementIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsARequirementOf
    return($return);
}




=head2 get_relationship_IsAlignedIn

  $return = $obj->get_relationship_IsAlignedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsAlignedIn
	2: a fields_Variation
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsAlignedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	start has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsAlignedIn
	2: a fields_Variation
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsAlignedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	start has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string


=end text



=item Description

This relationship connects each variation to the
contig regions that it aligns.
It has the following fields:

=over 4


=item start

start location of region


=item len

length of region


=item dir

direction of region (+ or -)



=back

=back

=cut

sub get_relationship_IsAlignedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsAlignedIn

    $return = $self->_get_relationship($ctx, 'IsAlignedIn', 'IsAlignedIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAlignedIn
    return($return);
}




=head2 get_relationship_IsAlignmentFor

  $return = $obj->get_relationship_IsAlignmentFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Variation
	1: a fields_IsAlignedIn
	2: a fields_Contig
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string
fields_IsAlignedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	start has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Variation
	1: a fields_IsAlignedIn
	2: a fields_Contig
fields_Variation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	notes has a value which is a reference to a list where each element is a string
fields_IsAlignedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	start has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsAlignmentFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsAlignmentFor

    $return = $self->_get_relationship($ctx, 'IsAlignmentFor', 'IsAlignedIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAlignmentFor
    return($return);
}




=head2 get_relationship_IsAnnotatedBy

  $return = $obj->get_relationship_IsAnnotatedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsAnnotatedBy
	2: a fields_Annotation
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsAnnotatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsAnnotatedBy
	2: a fields_Annotation
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsAnnotatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string


=end text



=item Description

This relationship connects a feature to its annotations. A
feature may have multiple annotations, but an annotation belongs to
only one feature.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsAnnotatedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsAnnotatedBy

    $return = $self->_get_relationship($ctx, 'IsAnnotatedBy', 'IsAnnotatedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAnnotatedBy
    return($return);
}




=head2 get_relationship_Annotates

  $return = $obj->get_relationship_Annotates($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Annotation
	1: a fields_IsAnnotatedBy
	2: a fields_Feature
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string
fields_IsAnnotatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Annotation
	1: a fields_IsAnnotatedBy
	2: a fields_Feature
fields_Annotation is a reference to a hash where the following keys are defined:
	id has a value which is a string
	annotator has a value which is a string
	comment has a value which is a string
	annotation_time has a value which is a string
fields_IsAnnotatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Annotates
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Annotates

    $return = $self->_get_relationship($ctx, 'Annotates', 'IsAnnotatedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Annotates
    return($return);
}




=head2 get_relationship_IsBindingSiteFor

  $return = $obj->get_relationship_IsBindingSiteFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsBindingSiteFor
	2: a fields_CoregulatedSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsBindingSiteFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsBindingSiteFor
	2: a fields_CoregulatedSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsBindingSiteFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string


=end text



=item Description

This relationship connects a coregulated set to the
binding site to which its feature attaches.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsBindingSiteFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsBindingSiteFor

    $return = $self->_get_relationship($ctx, 'IsBindingSiteFor', 'IsBindingSiteFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsBindingSiteFor
    return($return);
}




=head2 get_relationship_IsBoundBy

  $return = $obj->get_relationship_IsBoundBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_CoregulatedSet
	1: a fields_IsBindingSiteFor
	2: a fields_Feature
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string
fields_IsBindingSiteFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_CoregulatedSet
	1: a fields_IsBindingSiteFor
	2: a fields_Feature
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string
fields_IsBindingSiteFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsBoundBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsBoundBy

    $return = $self->_get_relationship($ctx, 'IsBoundBy', 'IsBindingSiteFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsBoundBy
    return($return);
}




=head2 get_relationship_IsClassFor

  $return = $obj->get_relationship_IsClassFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SubsystemClass
	1: a fields_IsClassFor
	2: a fields_Subsystem
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsClassFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SubsystemClass
	1: a fields_IsClassFor
	2: a fields_Subsystem
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsClassFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description

This relationship connects each subsystem class with the
subsystems that belong to it. A class can contain many subsystems,
but a subsystem is only in one class. Some subsystems are not in any
class, but this is usually a temporary condition.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsClassFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsClassFor

    $return = $self->_get_relationship($ctx, 'IsClassFor', 'IsClassFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsClassFor
    return($return);
}




=head2 get_relationship_IsInClass

  $return = $obj->get_relationship_IsInClass($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_IsClassFor
	2: a fields_SubsystemClass
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_IsClassFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_IsClassFor
	2: a fields_SubsystemClass
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_IsClassFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsInClass
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInClass

    $return = $self->_get_relationship($ctx, 'IsInClass', 'IsClassFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInClass
    return($return);
}




=head2 get_relationship_IsCollectionOf

  $return = $obj->get_relationship_IsCollectionOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_OTU
	1: a fields_IsCollectionOf
	2: a fields_Genome
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsCollectionOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	representative has a value which is an int
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_OTU
	1: a fields_IsCollectionOf
	2: a fields_Genome
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsCollectionOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	representative has a value which is an int
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description

A genome belongs to only one genome set. For each set, this relationship marks the genome to be used as its representative.
It has the following fields:

=over 4


=item representative

TRUE for the representative genome of the set, else FALSE.



=back

=back

=cut

sub get_relationship_IsCollectionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsCollectionOf

    $return = $self->_get_relationship($ctx, 'IsCollectionOf', 'IsCollectionOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCollectionOf
    return($return);
}




=head2 get_relationship_IsCollectedInto

  $return = $obj->get_relationship_IsCollectedInto($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsCollectionOf
	2: a fields_OTU
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsCollectionOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	representative has a value which is an int
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsCollectionOf
	2: a fields_OTU
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsCollectionOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	representative has a value which is an int
fields_OTU is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsCollectedInto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsCollectedInto

    $return = $self->_get_relationship($ctx, 'IsCollectedInto', 'IsCollectionOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCollectedInto
    return($return);
}




=head2 get_relationship_IsComposedOf

  $return = $obj->get_relationship_IsComposedOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsComposedOf
	2: a fields_Contig
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsComposedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsComposedOf
	2: a fields_Contig
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsComposedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string


=end text



=item Description

This relationship connects a genome to its
constituent contigs. Unlike contig sequences, a
contig belongs to only one genome.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsComposedOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsComposedOf

    $return = $self->_get_relationship($ctx, 'IsComposedOf', 'IsComposedOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsComposedOf
    return($return);
}




=head2 get_relationship_IsComponentOf

  $return = $obj->get_relationship_IsComponentOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsComposedOf
	2: a fields_Genome
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsComposedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsComposedOf
	2: a fields_Genome
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsComposedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsComponentOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsComponentOf

    $return = $self->_get_relationship($ctx, 'IsComponentOf', 'IsComposedOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsComponentOf
    return($return);
}




=head2 get_relationship_IsComprisedOf

  $return = $obj->get_relationship_IsComprisedOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Biomass
	1: a fields_IsComprisedOf
	2: a fields_BiomassCompound
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string
fields_IsComprisedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Biomass
	1: a fields_IsComprisedOf
	2: a fields_BiomassCompound
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string
fields_IsComprisedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description

This relationship connects a biomass to the compound
specifications that define it.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsComprisedOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsComprisedOf

    $return = $self->_get_relationship($ctx, 'IsComprisedOf', 'IsComprisedOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsComprisedOf
    return($return);
}




=head2 get_relationship_Comprises

  $return = $obj->get_relationship_Comprises($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_BiomassCompound
	1: a fields_IsComprisedOf
	2: a fields_Biomass
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float
fields_IsComprisedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_BiomassCompound
	1: a fields_IsComprisedOf
	2: a fields_Biomass
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float
fields_IsComprisedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_Comprises
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Comprises

    $return = $self->_get_relationship($ctx, 'Comprises', 'IsComprisedOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Comprises
    return($return);
}




=head2 get_relationship_IsConfiguredBy

  $return = $obj->get_relationship_IsConfiguredBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsConfiguredBy
	2: a fields_AtomicRegulon
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsConfiguredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsConfiguredBy
	2: a fields_AtomicRegulon
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsConfiguredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This relationship connects a genome to the atomic regulons that
describe its state.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsConfiguredBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsConfiguredBy

    $return = $self->_get_relationship($ctx, 'IsConfiguredBy', 'IsConfiguredBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsConfiguredBy
    return($return);
}




=head2 get_relationship_ReflectsStateOf

  $return = $obj->get_relationship_ReflectsStateOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_IsConfiguredBy
	2: a fields_Genome
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsConfiguredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_IsConfiguredBy
	2: a fields_Genome
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsConfiguredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_ReflectsStateOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_ReflectsStateOf

    $return = $self->_get_relationship($ctx, 'ReflectsStateOf', 'IsConfiguredBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ReflectsStateOf
    return($return);
}




=head2 get_relationship_IsConsistentWith

  $return = $obj->get_relationship_IsConsistentWith($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_EcNumber
	1: a fields_IsConsistentWith
	2: a fields_Role
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string
fields_IsConsistentWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_EcNumber
	1: a fields_IsConsistentWith
	2: a fields_Role
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string
fields_IsConsistentWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description

This relationship connects a functional role to the EC numbers consistent
with the chemistry described in the role.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsConsistentWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsConsistentWith

    $return = $self->_get_relationship($ctx, 'IsConsistentWith', 'IsConsistentWith', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsConsistentWith
    return($return);
}




=head2 get_relationship_IsConsistentTo

  $return = $obj->get_relationship_IsConsistentTo($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsConsistentWith
	2: a fields_EcNumber
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsConsistentWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsConsistentWith
	2: a fields_EcNumber
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsConsistentWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_EcNumber is a reference to a hash where the following keys are defined:
	id has a value which is a string
	obsolete has a value which is an int
	replacedby has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsConsistentTo
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsConsistentTo

    $return = $self->_get_relationship($ctx, 'IsConsistentTo', 'IsConsistentWith', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsConsistentTo
    return($return);
}




=head2 get_relationship_IsControlledUsing

  $return = $obj->get_relationship_IsControlledUsing($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_CoregulatedSet
	1: a fields_IsControlledUsing
	2: a fields_Feature
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string
fields_IsControlledUsing is a reference to a hash where the following keys are defined:
	id has a value which is a string
	effector has a value which is an int
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_CoregulatedSet
	1: a fields_IsControlledUsing
	2: a fields_Feature
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string
fields_IsControlledUsing is a reference to a hash where the following keys are defined:
	id has a value which is a string
	effector has a value which is an int
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects a coregulated set to the
protein that is used as its transcription factor.
It has the following fields:

=over 4


=item effector

TRUE if this transcription factor is an effector
(up-regulates), FALSE if it is a suppressor (down-regulates)



=back

=back

=cut

sub get_relationship_IsControlledUsing
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsControlledUsing

    $return = $self->_get_relationship($ctx, 'IsControlledUsing', 'IsControlledUsing', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsControlledUsing
    return($return);
}




=head2 get_relationship_Controls

  $return = $obj->get_relationship_Controls($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsControlledUsing
	2: a fields_CoregulatedSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsControlledUsing is a reference to a hash where the following keys are defined:
	id has a value which is a string
	effector has a value which is an int
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsControlledUsing
	2: a fields_CoregulatedSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsControlledUsing is a reference to a hash where the following keys are defined:
	id has a value which is a string
	effector has a value which is an int
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Controls
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Controls

    $return = $self->_get_relationship($ctx, 'Controls', 'IsControlledUsing', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Controls
    return($return);
}




=head2 get_relationship_IsCoregulatedWith

  $return = $obj->get_relationship_IsCoregulatedWith($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsCoregulatedWith
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsCoregulatedWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsCoregulatedWith
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsCoregulatedWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description

This relationship connects a feature with another feature in the
same genome with which it appears to be coregulated as a result of
expression data analysis.
It has the following fields:

=over 4


=item coefficient

Pearson correlation coefficient for this coregulation.



=back

=back

=cut

sub get_relationship_IsCoregulatedWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsCoregulatedWith

    $return = $self->_get_relationship($ctx, 'IsCoregulatedWith', 'IsCoregulatedWith', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCoregulatedWith
    return($return);
}




=head2 get_relationship_HasCoregulationWith

  $return = $obj->get_relationship_HasCoregulationWith($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsCoregulatedWith
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsCoregulatedWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsCoregulatedWith
	2: a fields_Feature
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsCoregulatedWith is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_HasCoregulationWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasCoregulationWith

    $return = $self->_get_relationship($ctx, 'HasCoregulationWith', 'IsCoregulatedWith', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasCoregulationWith
    return($return);
}




=head2 get_relationship_IsCoupledTo

  $return = $obj->get_relationship_IsCoupledTo($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_IsCoupledTo
	2: a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_IsCoupledTo is a reference to a hash where the following keys are defined:
	id has a value which is a string
	co_occurrence_evidence has a value which is an int
	co_expression_evidence has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_IsCoupledTo
	2: a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_IsCoupledTo is a reference to a hash where the following keys are defined:
	id has a value which is a string
	co_occurrence_evidence has a value which is an int
	co_expression_evidence has a value which is an int


=end text



=item Description

This relationship connects two FIGfams that we believe to be related
either because their members occur in proximity on chromosomes or because
the members are expressed together. Such a relationship is evidence the
functions of the FIGfams are themselves related. This relationship is
commutative; only the instance in which the first FIGfam has a lower ID
than the second is stored.
It has the following fields:

=over 4


=item co_occurrence_evidence

number of times members of the two FIGfams occur close to each
other on chromosomes


=item co_expression_evidence

number of times members of the two FIGfams are co-expressed in
expression data experiments



=back

=back

=cut

sub get_relationship_IsCoupledTo
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsCoupledTo

    $return = $self->_get_relationship($ctx, 'IsCoupledTo', 'IsCoupledTo', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCoupledTo
    return($return);
}




=head2 get_relationship_IsCoupledWith

  $return = $obj->get_relationship_IsCoupledWith($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_IsCoupledTo
	2: a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_IsCoupledTo is a reference to a hash where the following keys are defined:
	id has a value which is a string
	co_occurrence_evidence has a value which is an int
	co_expression_evidence has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_IsCoupledTo
	2: a fields_Family
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_IsCoupledTo is a reference to a hash where the following keys are defined:
	id has a value which is a string
	co_occurrence_evidence has a value which is an int
	co_expression_evidence has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsCoupledWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsCoupledWith

    $return = $self->_get_relationship($ctx, 'IsCoupledWith', 'IsCoupledTo', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCoupledWith
    return($return);
}




=head2 get_relationship_IsDefaultFor

  $return = $obj->get_relationship_IsDefaultFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsDefaultFor
	2: a fields_Reaction
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsDefaultFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsDefaultFor
	2: a fields_Reaction
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsDefaultFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description

This relationship connects a reaction to the compartment
in which it runs by default.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsDefaultFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDefaultFor

    $return = $self->_get_relationship($ctx, 'IsDefaultFor', 'IsDefaultFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDefaultFor
    return($return);
}




=head2 get_relationship_RunsByDefaultIn

  $return = $obj->get_relationship_RunsByDefaultIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_IsDefaultFor
	2: a fields_Compartment
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_IsDefaultFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_IsDefaultFor
	2: a fields_Compartment
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_IsDefaultFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_RunsByDefaultIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_RunsByDefaultIn

    $return = $self->_get_relationship($ctx, 'RunsByDefaultIn', 'IsDefaultFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_RunsByDefaultIn
    return($return);
}




=head2 get_relationship_IsDefaultLocationOf

  $return = $obj->get_relationship_IsDefaultLocationOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsDefaultLocationOf
	2: a fields_Reagent
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsDefaultLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsDefaultLocationOf
	2: a fields_Reagent
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsDefaultLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float


=end text



=item Description

This relationship connects a reagent to the compartment
which is its default location during the reaction.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsDefaultLocationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDefaultLocationOf

    $return = $self->_get_relationship($ctx, 'IsDefaultLocationOf', 'IsDefaultLocationOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDefaultLocationOf
    return($return);
}




=head2 get_relationship_HasDefaultLocation

  $return = $obj->get_relationship_HasDefaultLocation($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reagent
	1: a fields_IsDefaultLocationOf
	2: a fields_Compartment
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float
fields_IsDefaultLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reagent
	1: a fields_IsDefaultLocationOf
	2: a fields_Compartment
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float
fields_IsDefaultLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HasDefaultLocation
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasDefaultLocation

    $return = $self->_get_relationship($ctx, 'HasDefaultLocation', 'IsDefaultLocationOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasDefaultLocation
    return($return);
}




=head2 get_relationship_IsDeterminedBy

  $return = $obj->get_relationship_IsDeterminedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_PairSet
	1: a fields_IsDeterminedBy
	2: a fields_Pairing
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int
fields_IsDeterminedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	inverted has a value which is an int
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_PairSet
	1: a fields_IsDeterminedBy
	2: a fields_Pairing
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int
fields_IsDeterminedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	inverted has a value which is an int
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

A functional coupling evidence set exists because it has
pairings in it, and this relationship connects the evidence set to
its constituent pairings. A pairing cam belong to multiple evidence
sets.
It has the following fields:

=over 4


=item inverted

A pairing is an unordered pair of protein sequences,
but its similarity to other pairings in a pair set is
ordered. Let (A,B) be a pairing and (X,Y) be another pairing
in the same set. If this flag is FALSE, then (A =~ X) and (B
=~ Y). If this flag is TRUE, then (A =~ Y) and (B =~
X).



=back

=back

=cut

sub get_relationship_IsDeterminedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDeterminedBy

    $return = $self->_get_relationship($ctx, 'IsDeterminedBy', 'IsDeterminedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDeterminedBy
    return($return);
}




=head2 get_relationship_Determines

  $return = $obj->get_relationship_Determines($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Pairing
	1: a fields_IsDeterminedBy
	2: a fields_PairSet
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsDeterminedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	inverted has a value which is an int
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Pairing
	1: a fields_IsDeterminedBy
	2: a fields_PairSet
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsDeterminedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	inverted has a value which is an int
fields_PairSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	score has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_Determines
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Determines

    $return = $self->_get_relationship($ctx, 'Determines', 'IsDeterminedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Determines
    return($return);
}




=head2 get_relationship_IsDividedInto

  $return = $obj->get_relationship_IsDividedInto($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_IsDividedInto
	2: a fields_ModelCompartment
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_IsDividedInto is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_IsDividedInto
	2: a fields_ModelCompartment
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_IsDividedInto is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float


=end text



=item Description

This relationship connects a model to the cell compartments
that participate in the model.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsDividedInto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDividedInto

    $return = $self->_get_relationship($ctx, 'IsDividedInto', 'IsDividedInto', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDividedInto
    return($return);
}




=head2 get_relationship_IsDivisionOf

  $return = $obj->get_relationship_IsDivisionOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsDividedInto
	2: a fields_Model
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsDividedInto is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsDividedInto
	2: a fields_Model
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsDividedInto is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsDivisionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsDivisionOf

    $return = $self->_get_relationship($ctx, 'IsDivisionOf', 'IsDividedInto', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDivisionOf
    return($return);
}




=head2 get_relationship_IsExemplarOf

  $return = $obj->get_relationship_IsExemplarOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsExemplarOf
	2: a fields_Role
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsExemplarOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsExemplarOf
	2: a fields_Role
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsExemplarOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description

This relationship links a role to a feature that provides a typical
example of how the role is implemented.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsExemplarOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsExemplarOf

    $return = $self->_get_relationship($ctx, 'IsExemplarOf', 'IsExemplarOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsExemplarOf
    return($return);
}




=head2 get_relationship_HasAsExemplar

  $return = $obj->get_relationship_HasAsExemplar($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsExemplarOf
	2: a fields_Feature
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsExemplarOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsExemplarOf
	2: a fields_Feature
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsExemplarOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HasAsExemplar
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasAsExemplar

    $return = $self->_get_relationship($ctx, 'HasAsExemplar', 'IsExemplarOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAsExemplar
    return($return);
}




=head2 get_relationship_IsFamilyFor

  $return = $obj->get_relationship_IsFamilyFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_IsFamilyFor
	2: a fields_Role
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_IsFamilyFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Family
	1: a fields_IsFamilyFor
	2: a fields_Role
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string
fields_IsFamilyFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description

This relationship connects an isofunctional family to the roles that
make up its assigned function.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsFamilyFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsFamilyFor

    $return = $self->_get_relationship($ctx, 'IsFamilyFor', 'IsFamilyFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFamilyFor
    return($return);
}




=head2 get_relationship_DeterminesFunctionOf

  $return = $obj->get_relationship_DeterminesFunctionOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsFamilyFor
	2: a fields_Family
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsFamilyFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsFamilyFor
	2: a fields_Family
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsFamilyFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Family is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
	family_function has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_DeterminesFunctionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_DeterminesFunctionOf

    $return = $self->_get_relationship($ctx, 'DeterminesFunctionOf', 'IsFamilyFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_DeterminesFunctionOf
    return($return);
}




=head2 get_relationship_IsFormedOf

  $return = $obj->get_relationship_IsFormedOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_IsFormedOf
	2: a fields_Feature
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsFormedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_AtomicRegulon
	1: a fields_IsFormedOf
	2: a fields_Feature
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsFormedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects each feature to the atomic regulon to
which it belongs.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsFormedOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsFormedOf

    $return = $self->_get_relationship($ctx, 'IsFormedOf', 'IsFormedOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFormedOf
    return($return);
}




=head2 get_relationship_IsFormedInto

  $return = $obj->get_relationship_IsFormedInto($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsFormedOf
	2: a fields_AtomicRegulon
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsFormedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsFormedOf
	2: a fields_AtomicRegulon
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsFormedOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_AtomicRegulon is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsFormedInto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsFormedInto

    $return = $self->_get_relationship($ctx, 'IsFormedInto', 'IsFormedOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFormedInto
    return($return);
}




=head2 get_relationship_IsFunctionalIn

  $return = $obj->get_relationship_IsFunctionalIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsFunctionalIn
	2: a fields_Feature
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsFunctionalIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsFunctionalIn
	2: a fields_Feature
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsFunctionalIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects a role with the features in which
it plays a functional part.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsFunctionalIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsFunctionalIn

    $return = $self->_get_relationship($ctx, 'IsFunctionalIn', 'IsFunctionalIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFunctionalIn
    return($return);
}




=head2 get_relationship_HasFunctional

  $return = $obj->get_relationship_HasFunctional($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsFunctionalIn
	2: a fields_Role
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsFunctionalIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsFunctionalIn
	2: a fields_Role
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsFunctionalIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_HasFunctional
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasFunctional

    $return = $self->_get_relationship($ctx, 'HasFunctional', 'IsFunctionalIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasFunctional
    return($return);
}




=head2 get_relationship_IsGroupFor

  $return = $obj->get_relationship_IsGroupFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_TaxonomicGrouping
	1: a fields_IsGroupFor
	2: a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string
fields_IsGroupFor is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_TaxonomicGrouping
	1: a fields_IsGroupFor
	2: a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string
fields_IsGroupFor is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

The recursive IsGroupFor relationship organizes
taxonomic groupings into a hierarchy based on the standard organism
taxonomy.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsGroupFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsGroupFor

    $return = $self->_get_relationship($ctx, 'IsGroupFor', 'IsGroupFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsGroupFor
    return($return);
}




=head2 get_relationship_IsInGroup

  $return = $obj->get_relationship_IsInGroup($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_TaxonomicGrouping
	1: a fields_IsGroupFor
	2: a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string
fields_IsGroupFor is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_TaxonomicGrouping
	1: a fields_IsGroupFor
	2: a fields_TaxonomicGrouping
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string
fields_IsGroupFor is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsInGroup
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInGroup

    $return = $self->_get_relationship($ctx, 'IsInGroup', 'IsGroupFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInGroup
    return($return);
}




=head2 get_relationship_IsImplementedBy

  $return = $obj->get_relationship_IsImplementedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Variant
	1: a fields_IsImplementedBy
	2: a fields_SSRow
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string
fields_IsImplementedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Variant
	1: a fields_IsImplementedBy
	2: a fields_SSRow
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string
fields_IsImplementedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string


=end text



=item Description

This relationship connects a variant to the physical machines
that implement it in the genomes. A variant is implemented by many
machines, but a machine belongs to only one variant.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsImplementedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsImplementedBy

    $return = $self->_get_relationship($ctx, 'IsImplementedBy', 'IsImplementedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsImplementedBy
    return($return);
}




=head2 get_relationship_Implements

  $return = $obj->get_relationship_Implements($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSRow
	1: a fields_IsImplementedBy
	2: a fields_Variant
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string
fields_IsImplementedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSRow
	1: a fields_IsImplementedBy
	2: a fields_Variant
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string
fields_IsImplementedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Variant is a reference to a hash where the following keys are defined:
	id has a value which is a string
	role_rule has a value which is a reference to a list where each element is a string
	code has a value which is a string
	type has a value which is a string
	comment has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Implements
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Implements

    $return = $self->_get_relationship($ctx, 'Implements', 'IsImplementedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Implements
    return($return);
}




=head2 get_relationship_IsInPair

  $return = $obj->get_relationship_IsInPair($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsInPair
	2: a fields_Pairing
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsInPair is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsInPair
	2: a fields_Pairing
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsInPair is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

A pairing contains exactly two protein sequences. A protein
sequence can belong to multiple pairings. When going from a protein
sequence to its pairings, they are presented in alphabetical order
by sequence key.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsInPair
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInPair

    $return = $self->_get_relationship($ctx, 'IsInPair', 'IsInPair', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInPair
    return($return);
}




=head2 get_relationship_IsPairOf

  $return = $obj->get_relationship_IsPairOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Pairing
	1: a fields_IsInPair
	2: a fields_Feature
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsInPair is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Pairing
	1: a fields_IsInPair
	2: a fields_Feature
fields_Pairing is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsInPair is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsPairOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsPairOf

    $return = $self->_get_relationship($ctx, 'IsPairOf', 'IsInPair', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsPairOf
    return($return);
}




=head2 get_relationship_IsInstantiatedBy

  $return = $obj->get_relationship_IsInstantiatedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsInstantiatedBy
	2: a fields_ModelCompartment
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsInstantiatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsInstantiatedBy
	2: a fields_ModelCompartment
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsInstantiatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float


=end text



=item Description

This relationship connects a compartment to the instances
of that compartment that occur in models.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsInstantiatedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInstantiatedBy

    $return = $self->_get_relationship($ctx, 'IsInstantiatedBy', 'IsInstantiatedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInstantiatedBy
    return($return);
}




=head2 get_relationship_IsInstanceOf

  $return = $obj->get_relationship_IsInstanceOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsInstantiatedBy
	2: a fields_Compartment
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsInstantiatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsInstantiatedBy
	2: a fields_Compartment
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsInstantiatedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsInstanceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInstanceOf

    $return = $self->_get_relationship($ctx, 'IsInstanceOf', 'IsInstantiatedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInstanceOf
    return($return);
}




=head2 get_relationship_IsLocatedIn

  $return = $obj->get_relationship_IsLocatedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsLocatedIn
	2: a fields_Contig
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsLocatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ordinal has a value which is an int
	begin has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsLocatedIn
	2: a fields_Contig
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsLocatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ordinal has a value which is an int
	begin has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string


=end text



=item Description

A feature is a set of DNA sequence fragments. Most features
are a single contiquous fragment, so they are located in only one
DNA sequence; however, fragments have a maximum length, so even a
single contiguous feature may participate in this relationship
multiple times. A few features belong to multiple DNA sequences. In
that case, however, all the DNA sequences belong to the same genome.
A DNA sequence itself will frequently have thousands of features
connected to it.
It has the following fields:

=over 4


=item ordinal

Sequence number of this segment, starting from 1
and proceeding sequentially forward from there.


=item begin

Index (1-based) of the first residue in the contig
that belongs to the segment.


=item len

Length of this segment.


=item dir

Direction (strand) of the segment: "+" if it is
forward and "-" if it is backward.



=back

=back

=cut

sub get_relationship_IsLocatedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsLocatedIn

    $return = $self->_get_relationship($ctx, 'IsLocatedIn', 'IsLocatedIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsLocatedIn
    return($return);
}




=head2 get_relationship_IsLocusFor

  $return = $obj->get_relationship_IsLocusFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsLocatedIn
	2: a fields_Feature
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsLocatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ordinal has a value which is an int
	begin has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsLocatedIn
	2: a fields_Feature
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsLocatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
	ordinal has a value which is an int
	begin has a value which is an int
	len has a value which is an int
	dir has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsLocusFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsLocusFor

    $return = $self->_get_relationship($ctx, 'IsLocusFor', 'IsLocatedIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsLocusFor
    return($return);
}




=head2 get_relationship_IsModeledBy

  $return = $obj->get_relationship_IsModeledBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsModeledBy
	2: a fields_Model
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsModeledBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsModeledBy
	2: a fields_Model
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsModeledBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int


=end text



=item Description

A genome can be modeled by many different models, but a model belongs
to only one genome.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsModeledBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsModeledBy

    $return = $self->_get_relationship($ctx, 'IsModeledBy', 'IsModeledBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsModeledBy
    return($return);
}




=head2 get_relationship_Models

  $return = $obj->get_relationship_Models($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_IsModeledBy
	2: a fields_Genome
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_IsModeledBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_IsModeledBy
	2: a fields_Genome
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_IsModeledBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Models
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Models

    $return = $self->_get_relationship($ctx, 'Models', 'IsModeledBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Models
    return($return);
}




=head2 get_relationship_IsNamedBy

  $return = $obj->get_relationship_IsNamedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_IsNamedBy
	2: a fields_Identifier
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_IsNamedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_IsNamedBy
	2: a fields_Identifier
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_IsNamedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string


=end text



=item Description

The normal case is that an identifier names a single
protein sequence, while a protein sequence can have many identifiers,
but some identifiers name multiple sequences.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsNamedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsNamedBy

    $return = $self->_get_relationship($ctx, 'IsNamedBy', 'IsNamedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsNamedBy
    return($return);
}




=head2 get_relationship_Names

  $return = $obj->get_relationship_Names($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Identifier
	1: a fields_IsNamedBy
	2: a fields_ProteinSequence
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string
fields_IsNamedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Identifier
	1: a fields_IsNamedBy
	2: a fields_ProteinSequence
fields_Identifier is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
	natural_form has a value which is a string
fields_IsNamedBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Names
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Names

    $return = $self->_get_relationship($ctx, 'Names', 'IsNamedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Names
    return($return);
}




=head2 get_relationship_IsOwnerOf

  $return = $obj->get_relationship_IsOwnerOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsOwnerOf
	2: a fields_Feature
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsOwnerOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsOwnerOf
	2: a fields_Feature
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsOwnerOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects a genome to the features it
contains. Though technically redundant (the information is
available from the feature's contigs), it simplifies the
extremely common process of finding all features for a
genome.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsOwnerOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsOwnerOf

    $return = $self->_get_relationship($ctx, 'IsOwnerOf', 'IsOwnerOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsOwnerOf
    return($return);
}




=head2 get_relationship_IsOwnedBy

  $return = $obj->get_relationship_IsOwnedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsOwnerOf
	2: a fields_Genome
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsOwnerOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsOwnerOf
	2: a fields_Genome
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsOwnerOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsOwnedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsOwnedBy

    $return = $self->_get_relationship($ctx, 'IsOwnedBy', 'IsOwnerOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsOwnedBy
    return($return);
}




=head2 get_relationship_IsProposedLocationOf

  $return = $obj->get_relationship_IsProposedLocationOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsProposedLocationOf
	2: a fields_ReactionRule
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsProposedLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compartment
	1: a fields_IsProposedLocationOf
	2: a fields_ReactionRule
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
fields_IsProposedLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float


=end text



=item Description

This relationship connects a reaction as it is used in
a complex to the compartments in which it usually takes place.
Most reactions take place in a single compartment. Transporters
take place in two compartments.
It has the following fields:

=over 4


=item type

role of the compartment in the reaction: 'primary'
if it is the sole or starting compartment, 'secondary' if
it is the ending compartment in a multi-compartmental
reaction



=back

=back

=cut

sub get_relationship_IsProposedLocationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsProposedLocationOf

    $return = $self->_get_relationship($ctx, 'IsProposedLocationOf', 'IsProposedLocationOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsProposedLocationOf
    return($return);
}




=head2 get_relationship_HasProposedLocationIn

  $return = $obj->get_relationship_HasProposedLocationIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ReactionRule
	1: a fields_IsProposedLocationOf
	2: a fields_Compartment
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
fields_IsProposedLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ReactionRule
	1: a fields_IsProposedLocationOf
	2: a fields_Compartment
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
fields_IsProposedLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_Compartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	abbr has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HasProposedLocationIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasProposedLocationIn

    $return = $self->_get_relationship($ctx, 'HasProposedLocationIn', 'IsProposedLocationOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasProposedLocationIn
    return($return);
}




=head2 get_relationship_IsProteinFor

  $return = $obj->get_relationship_IsProteinFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_IsProteinFor
	2: a fields_Feature
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_IsProteinFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_IsProteinFor
	2: a fields_Feature
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_IsProteinFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description

This relationship connects a peg feature to the protein
sequence it produces (if any). Only peg features participate in this
relationship. A single protein sequence will frequently be produced
by many features.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsProteinFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsProteinFor

    $return = $self->_get_relationship($ctx, 'IsProteinFor', 'IsProteinFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsProteinFor
    return($return);
}




=head2 get_relationship_Produces

  $return = $obj->get_relationship_Produces($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsProteinFor
	2: a fields_ProteinSequence
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsProteinFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsProteinFor
	2: a fields_ProteinSequence
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsProteinFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Produces
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Produces

    $return = $self->_get_relationship($ctx, 'Produces', 'IsProteinFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Produces
    return($return);
}




=head2 get_relationship_IsRealLocationOf

  $return = $obj->get_relationship_IsRealLocationOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsRealLocationOf
	2: a fields_Requirement
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsRealLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsRealLocationOf
	2: a fields_Requirement
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsRealLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float


=end text



=item Description

This relationship connects a model's instance of a reaction
to the compartments in which it takes place. Most instances
take place in a single compartment. Transporters use two compartments.
It has the following fields:

=over 4


=item type

role of the compartment in the reaction: 'primary'
if it is the sole or starting compartment, 'secondary' if
it is the ending compartment in a multi-compartmental
reaction



=back

=back

=cut

sub get_relationship_IsRealLocationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRealLocationOf

    $return = $self->_get_relationship($ctx, 'IsRealLocationOf', 'IsRealLocationOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRealLocationOf
    return($return);
}




=head2 get_relationship_HasRealLocationIn

  $return = $obj->get_relationship_HasRealLocationIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Requirement
	1: a fields_IsRealLocationOf
	2: a fields_ModelCompartment
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float
fields_IsRealLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Requirement
	1: a fields_IsRealLocationOf
	2: a fields_ModelCompartment
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float
fields_IsRealLocationOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
	type has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_HasRealLocationIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasRealLocationIn

    $return = $self->_get_relationship($ctx, 'HasRealLocationIn', 'IsRealLocationOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasRealLocationIn
    return($return);
}




=head2 get_relationship_IsRegulatedIn

  $return = $obj->get_relationship_IsRegulatedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsRegulatedIn
	2: a fields_CoregulatedSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsRegulatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Feature
	1: a fields_IsRegulatedIn
	2: a fields_CoregulatedSet
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string
fields_IsRegulatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string


=end text



=item Description

This relationship connects a feature to the set of coregulated features.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsRegulatedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRegulatedIn

    $return = $self->_get_relationship($ctx, 'IsRegulatedIn', 'IsRegulatedIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRegulatedIn
    return($return);
}




=head2 get_relationship_IsRegulatedSetOf

  $return = $obj->get_relationship_IsRegulatedSetOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_CoregulatedSet
	1: a fields_IsRegulatedIn
	2: a fields_Feature
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string
fields_IsRegulatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_CoregulatedSet
	1: a fields_IsRegulatedIn
	2: a fields_Feature
fields_CoregulatedSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
	reason has a value which is a string
fields_IsRegulatedIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Feature is a reference to a hash where the following keys are defined:
	id has a value which is a string
	feature_type has a value which is a string
	source_id has a value which is a string
	sequence_length has a value which is an int
	function has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsRegulatedSetOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRegulatedSetOf

    $return = $self->_get_relationship($ctx, 'IsRegulatedSetOf', 'IsRegulatedIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRegulatedSetOf
    return($return);
}




=head2 get_relationship_IsRelevantFor

  $return = $obj->get_relationship_IsRelevantFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_IsRelevantFor
	2: a fields_Subsystem
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_IsRelevantFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_IsRelevantFor
	2: a fields_Subsystem
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_IsRelevantFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description

This relationship connects a diagram to the subsystems that are depicted on
it. Only diagrams which are useful in curating or annotation the subsystem are
specified in this relationship.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsRelevantFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRelevantFor

    $return = $self->_get_relationship($ctx, 'IsRelevantFor', 'IsRelevantFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRelevantFor
    return($return);
}




=head2 get_relationship_IsRelevantTo

  $return = $obj->get_relationship_IsRelevantTo($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_IsRelevantFor
	2: a fields_Diagram
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_IsRelevantFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_IsRelevantFor
	2: a fields_Diagram
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_IsRelevantFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsRelevantTo
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRelevantTo

    $return = $self->_get_relationship($ctx, 'IsRelevantTo', 'IsRelevantFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRelevantTo
    return($return);
}




=head2 get_relationship_IsRequiredBy

  $return = $obj->get_relationship_IsRequiredBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_IsRequiredBy
	2: a fields_Requirement
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_IsRequiredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_IsRequiredBy
	2: a fields_Requirement
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_IsRequiredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float


=end text



=item Description

This relationship links a reaction to the way it is used in a model.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsRequiredBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRequiredBy

    $return = $self->_get_relationship($ctx, 'IsRequiredBy', 'IsRequiredBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRequiredBy
    return($return);
}




=head2 get_relationship_Requires

  $return = $obj->get_relationship_Requires($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Requirement
	1: a fields_IsRequiredBy
	2: a fields_Reaction
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float
fields_IsRequiredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Requirement
	1: a fields_IsRequiredBy
	2: a fields_Reaction
fields_Requirement is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
	proton has a value which is a float
fields_IsRequiredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Requires
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Requires

    $return = $self->_get_relationship($ctx, 'Requires', 'IsRequiredBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Requires
    return($return);
}




=head2 get_relationship_IsRoleOf

  $return = $obj->get_relationship_IsRoleOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsRoleOf
	2: a fields_SSCell
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsRoleOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsRoleOf
	2: a fields_SSCell
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsRoleOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This relationship connects a role to the machine roles that
represent its appearance in a molecular machine. A machine role has
exactly one associated role, but a role may be represented by many
machine roles.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsRoleOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRoleOf

    $return = $self->_get_relationship($ctx, 'IsRoleOf', 'IsRoleOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRoleOf
    return($return);
}




=head2 get_relationship_HasRole

  $return = $obj->get_relationship_HasRole($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSCell
	1: a fields_IsRoleOf
	2: a fields_Role
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsRoleOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSCell
	1: a fields_IsRoleOf
	2: a fields_Role
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsRoleOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_HasRole
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasRole

    $return = $self->_get_relationship($ctx, 'HasRole', 'IsRoleOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasRole
    return($return);
}




=head2 get_relationship_IsRowOf

  $return = $obj->get_relationship_IsRowOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSRow
	1: a fields_IsRowOf
	2: a fields_SSCell
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string
fields_IsRowOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSRow
	1: a fields_IsRowOf
	2: a fields_SSCell
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string
fields_IsRowOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This relationship connects a subsystem spreadsheet row to its
constituent spreadsheet cells.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsRowOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRowOf

    $return = $self->_get_relationship($ctx, 'IsRowOf', 'IsRowOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRowOf
    return($return);
}




=head2 get_relationship_IsRoleFor

  $return = $obj->get_relationship_IsRoleFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSCell
	1: a fields_IsRowOf
	2: a fields_SSRow
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsRowOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSCell
	1: a fields_IsRowOf
	2: a fields_SSRow
fields_SSCell is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsRowOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsRoleFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsRoleFor

    $return = $self->_get_relationship($ctx, 'IsRoleFor', 'IsRowOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRoleFor
    return($return);
}




=head2 get_relationship_IsSequenceOf

  $return = $obj->get_relationship_IsSequenceOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ContigSequence
	1: a fields_IsSequenceOf
	2: a fields_Contig
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int
fields_IsSequenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ContigSequence
	1: a fields_IsSequenceOf
	2: a fields_Contig
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int
fields_IsSequenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string


=end text



=item Description

This relationship connects a Contig as it occurs in a
genome to the Contig Sequence that represents the physical
DNA base pairs. A contig sequence may represent many contigs,
but each contig has only one sequence.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsSequenceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsSequenceOf

    $return = $self->_get_relationship($ctx, 'IsSequenceOf', 'IsSequenceOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSequenceOf
    return($return);
}




=head2 get_relationship_HasAsSequence

  $return = $obj->get_relationship_HasAsSequence($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsSequenceOf
	2: a fields_ContigSequence
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsSequenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Contig
	1: a fields_IsSequenceOf
	2: a fields_ContigSequence
fields_Contig is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source_id has a value which is a string
fields_IsSequenceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ContigSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	length has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_HasAsSequence
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasAsSequence

    $return = $self->_get_relationship($ctx, 'HasAsSequence', 'IsSequenceOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAsSequence
    return($return);
}




=head2 get_relationship_IsSubInstanceOf

  $return = $obj->get_relationship_IsSubInstanceOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_IsSubInstanceOf
	2: a fields_Scenario
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_IsSubInstanceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_IsSubInstanceOf
	2: a fields_Scenario
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_IsSubInstanceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string


=end text



=item Description

This relationship connects a scenario to its subsystem it
validates. A scenario belongs to exactly one subsystem, but a
subsystem may have multiple scenarios.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsSubInstanceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsSubInstanceOf

    $return = $self->_get_relationship($ctx, 'IsSubInstanceOf', 'IsSubInstanceOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSubInstanceOf
    return($return);
}




=head2 get_relationship_Validates

  $return = $obj->get_relationship_Validates($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_IsSubInstanceOf
	2: a fields_Subsystem
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_IsSubInstanceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_IsSubInstanceOf
	2: a fields_Subsystem
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_IsSubInstanceOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_Validates
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Validates

    $return = $self->_get_relationship($ctx, 'Validates', 'IsSubInstanceOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Validates
    return($return);
}




=head2 get_relationship_IsSuperclassOf

  $return = $obj->get_relationship_IsSuperclassOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SubsystemClass
	1: a fields_IsSuperclassOf
	2: a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsSuperclassOf is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SubsystemClass
	1: a fields_IsSuperclassOf
	2: a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsSuperclassOf is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description

This is a recursive relationship that imposes a hierarchy on
the subsystem classes.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsSuperclassOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsSuperclassOf

    $return = $self->_get_relationship($ctx, 'IsSuperclassOf', 'IsSuperclassOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSuperclassOf
    return($return);
}




=head2 get_relationship_IsSubclassOf

  $return = $obj->get_relationship_IsSubclassOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SubsystemClass
	1: a fields_IsSuperclassOf
	2: a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsSuperclassOf is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SubsystemClass
	1: a fields_IsSuperclassOf
	2: a fields_SubsystemClass
fields_SubsystemClass is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_IsSuperclassOf is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsSubclassOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsSubclassOf

    $return = $self->_get_relationship($ctx, 'IsSubclassOf', 'IsSuperclassOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSubclassOf
    return($return);
}




=head2 get_relationship_IsTargetOf

  $return = $obj->get_relationship_IsTargetOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsTargetOf
	2: a fields_BiomassCompound
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsTargetOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ModelCompartment
	1: a fields_IsTargetOf
	2: a fields_BiomassCompound
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float
fields_IsTargetOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float


=end text



=item Description

This relationship connects a compound in a biomass to the
compartment in which it is supposed to appear.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsTargetOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsTargetOf

    $return = $self->_get_relationship($ctx, 'IsTargetOf', 'IsTargetOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTargetOf
    return($return);
}




=head2 get_relationship_Targets

  $return = $obj->get_relationship_Targets($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_BiomassCompound
	1: a fields_IsTargetOf
	2: a fields_ModelCompartment
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float
fields_IsTargetOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_BiomassCompound
	1: a fields_IsTargetOf
	2: a fields_ModelCompartment
fields_BiomassCompound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	coefficient has a value which is a float
fields_IsTargetOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ModelCompartment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	compartment_index has a value which is an int
	label has a value which is a reference to a list where each element is a string
	pH has a value which is a float
	potential has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_Targets
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Targets

    $return = $self->_get_relationship($ctx, 'Targets', 'IsTargetOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Targets
    return($return);
}




=head2 get_relationship_IsTaxonomyOf

  $return = $obj->get_relationship_IsTaxonomyOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_TaxonomicGrouping
	1: a fields_IsTaxonomyOf
	2: a fields_Genome
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string
fields_IsTaxonomyOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_TaxonomicGrouping
	1: a fields_IsTaxonomyOf
	2: a fields_Genome
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string
fields_IsTaxonomyOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description

A genome is assigned to a particular point in the taxonomy tree, but not
necessarily to a leaf node. In some cases, the exact species and strain is
not available when inserting the genome, so it is placed at the lowest node
that probably contains the actual genome.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsTaxonomyOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsTaxonomyOf

    $return = $self->_get_relationship($ctx, 'IsTaxonomyOf', 'IsTaxonomyOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTaxonomyOf
    return($return);
}




=head2 get_relationship_IsInTaxa

  $return = $obj->get_relationship_IsInTaxa($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsTaxonomyOf
	2: a fields_TaxonomicGrouping
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsTaxonomyOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_IsTaxonomyOf
	2: a fields_TaxonomicGrouping
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_IsTaxonomyOf is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_TaxonomicGrouping is a reference to a hash where the following keys are defined:
	id has a value which is a string
	domain has a value which is an int
	hidden has a value which is an int
	scientific_name has a value which is a string
	alias has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsInTaxa
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsInTaxa

    $return = $self->_get_relationship($ctx, 'IsInTaxa', 'IsTaxonomyOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInTaxa
    return($return);
}




=head2 get_relationship_IsTerminusFor

  $return = $obj->get_relationship_IsTerminusFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_IsTerminusFor
	2: a fields_Scenario
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_IsTerminusFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	group_number has a value which is an int
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_IsTerminusFor
	2: a fields_Scenario
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_IsTerminusFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	group_number has a value which is an int
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string


=end text



=item Description

A terminus for a scenario is a compound that acts as its
input or output. A compound can be the terminus for many scenarios,
and a scenario will have many termini. The relationship attributes
indicate whether the compound is an input to the scenario or an
output. In some cases, there may be multiple alternative output
groups. This is also indicated by the attributes.
It has the following fields:

=over 4


=item group_number

If zero, then the compound is an input. If one, the compound is
an output. If two, the compound is an auxiliary output.



=back

=back

=cut

sub get_relationship_IsTerminusFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsTerminusFor

    $return = $self->_get_relationship($ctx, 'IsTerminusFor', 'IsTerminusFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTerminusFor
    return($return);
}




=head2 get_relationship_HasAsTerminus

  $return = $obj->get_relationship_HasAsTerminus($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_IsTerminusFor
	2: a fields_Compound
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_IsTerminusFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	group_number has a value which is an int
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_IsTerminusFor
	2: a fields_Compound
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_IsTerminusFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
	group_number has a value which is an int
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_HasAsTerminus
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HasAsTerminus

    $return = $self->_get_relationship($ctx, 'HasAsTerminus', 'IsTerminusFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAsTerminus
    return($return);
}




=head2 get_relationship_IsTriggeredBy

  $return = $obj->get_relationship_IsTriggeredBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Complex
	1: a fields_IsTriggeredBy
	2: a fields_Role
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string
fields_IsTriggeredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	optional has a value which is an int
	type has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Complex
	1: a fields_IsTriggeredBy
	2: a fields_Role
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string
fields_IsTriggeredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	optional has a value which is an int
	type has a value which is a string
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int


=end text



=item Description

A complex can be triggered by many roles. A role can
trigger many complexes.
It has the following fields:

=over 4


=item optional

TRUE if the role is not necessarily required to trigger the
complex, else FALSE


=item type

ask Chris



=back

=back

=cut

sub get_relationship_IsTriggeredBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsTriggeredBy

    $return = $self->_get_relationship($ctx, 'IsTriggeredBy', 'IsTriggeredBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTriggeredBy
    return($return);
}




=head2 get_relationship_Triggers

  $return = $obj->get_relationship_Triggers($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsTriggeredBy
	2: a fields_Complex
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsTriggeredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	optional has a value which is an int
	type has a value which is a string
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Role
	1: a fields_IsTriggeredBy
	2: a fields_Complex
fields_Role is a reference to a hash where the following keys are defined:
	id has a value which is a string
	hypothetical has a value which is an int
fields_IsTriggeredBy is a reference to a hash where the following keys are defined:
	id has a value which is a string
	optional has a value which is an int
	type has a value which is a string
fields_Complex is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a reference to a list where each element is a string
	mod_date has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_Triggers
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Triggers

    $return = $self->_get_relationship($ctx, 'Triggers', 'IsTriggeredBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Triggers
    return($return);
}




=head2 get_relationship_IsUsedAs

  $return = $obj->get_relationship_IsUsedAs($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_IsUsedAs
	2: a fields_ReactionRule
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_IsUsedAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reaction
	1: a fields_IsUsedAs
	2: a fields_ReactionRule
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string
fields_IsUsedAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float


=end text



=item Description

This relationship connects a reaction to its usage in
specific complexes.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_IsUsedAs
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsUsedAs

    $return = $self->_get_relationship($ctx, 'IsUsedAs', 'IsUsedAs', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUsedAs
    return($return);
}




=head2 get_relationship_IsUseOf

  $return = $obj->get_relationship_IsUseOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ReactionRule
	1: a fields_IsUsedAs
	2: a fields_Reaction
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
fields_IsUsedAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ReactionRule
	1: a fields_IsUsedAs
	2: a fields_Reaction
fields_ReactionRule is a reference to a hash where the following keys are defined:
	id has a value which is a string
	direction has a value which is a string
	transproton has a value which is a float
fields_IsUsedAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reaction is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	abbr has a value which is a string
	equation has a value which is a string
	reversibility has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsUseOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsUseOf

    $return = $self->_get_relationship($ctx, 'IsUseOf', 'IsUsedAs', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUseOf
    return($return);
}




=head2 get_relationship_Manages

  $return = $obj->get_relationship_Manages($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_Manages
	2: a fields_Biomass
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_Manages is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Model
	1: a fields_Manages
	2: a fields_Biomass
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int
fields_Manages is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string


=end text



=item Description

This relationship connects a model to the biomasses
that are monitored to determine whether or not the model
is effective.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Manages
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Manages

    $return = $self->_get_relationship($ctx, 'Manages', 'Manages', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Manages
    return($return);
}




=head2 get_relationship_IsManagedBy

  $return = $obj->get_relationship_IsManagedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Biomass
	1: a fields_Manages
	2: a fields_Model
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string
fields_Manages is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Biomass
	1: a fields_Manages
	2: a fields_Model
fields_Biomass is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a reference to a list where each element is a string
fields_Manages is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Model is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	version has a value which is an int
	type has a value which is a string
	status has a value which is a string
	reaction_count has a value which is an int
	compound_count has a value which is an int
	annotation_count has a value which is an int


=end text



=item Description



=back

=cut

sub get_relationship_IsManagedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsManagedBy

    $return = $self->_get_relationship($ctx, 'IsManagedBy', 'Manages', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsManagedBy
    return($return);
}




=head2 get_relationship_OperatesIn

  $return = $obj->get_relationship_OperatesIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_OperatesIn
	2: a fields_Media
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_OperatesIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Experiment
	1: a fields_OperatesIn
	2: a fields_Media
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string
fields_OperatesIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string


=end text



=item Description

This relationship connects an experiment to the media in which the
experiment took place.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_OperatesIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_OperatesIn

    $return = $self->_get_relationship($ctx, 'OperatesIn', 'OperatesIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_OperatesIn
    return($return);
}




=head2 get_relationship_IsUtilizedIn

  $return = $obj->get_relationship_IsUtilizedIn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Media
	1: a fields_OperatesIn
	2: a fields_Experiment
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string
fields_OperatesIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Media
	1: a fields_OperatesIn
	2: a fields_Experiment
fields_Media is a reference to a hash where the following keys are defined:
	id has a value which is a string
	mod_date has a value which is a string
	name has a value which is a string
	type has a value which is a string
fields_OperatesIn is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Experiment is a reference to a hash where the following keys are defined:
	id has a value which is a string
	source has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsUtilizedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsUtilizedIn

    $return = $self->_get_relationship($ctx, 'IsUtilizedIn', 'OperatesIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUtilizedIn
    return($return);
}




=head2 get_relationship_Overlaps

  $return = $obj->get_relationship_Overlaps($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_Overlaps
	2: a fields_Diagram
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_Overlaps is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Scenario
	1: a fields_Overlaps
	2: a fields_Diagram
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string
fields_Overlaps is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string


=end text



=item Description

A Scenario overlaps a diagram when the diagram displays a
portion of the reactions that make up the scenario. A scenario may
overlap many diagrams, and a diagram may be include portions of many
scenarios.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Overlaps
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Overlaps

    $return = $self->_get_relationship($ctx, 'Overlaps', 'Overlaps', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Overlaps
    return($return);
}




=head2 get_relationship_IncludesPartOf

  $return = $obj->get_relationship_IncludesPartOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_Overlaps
	2: a fields_Scenario
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_Overlaps is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_Overlaps
	2: a fields_Scenario
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_Overlaps is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Scenario is a reference to a hash where the following keys are defined:
	id has a value which is a string
	common_name has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IncludesPartOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IncludesPartOf

    $return = $self->_get_relationship($ctx, 'IncludesPartOf', 'Overlaps', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IncludesPartOf
    return($return);
}




=head2 get_relationship_ParticipatesAs

  $return = $obj->get_relationship_ParticipatesAs($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_ParticipatesAs
	2: a fields_Reagent
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_ParticipatesAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_ParticipatesAs
	2: a fields_Reagent
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_ParticipatesAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float


=end text



=item Description

This relationship connects a compound to the reagents
that represent its participation in reactions.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_ParticipatesAs
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_ParticipatesAs

    $return = $self->_get_relationship($ctx, 'ParticipatesAs', 'ParticipatesAs', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ParticipatesAs
    return($return);
}




=head2 get_relationship_IsParticipationOf

  $return = $obj->get_relationship_IsParticipationOf($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reagent
	1: a fields_ParticipatesAs
	2: a fields_Compound
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float
fields_ParticipatesAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Reagent
	1: a fields_ParticipatesAs
	2: a fields_Compound
fields_Reagent is a reference to a hash where the following keys are defined:
	id has a value which is a string
	stoichiometry has a value which is a float
	cofactor has a value which is an int
	compartment_index has a value which is an int
	transport_coefficient has a value which is a float
fields_ParticipatesAs is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_IsParticipationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsParticipationOf

    $return = $self->_get_relationship($ctx, 'IsParticipationOf', 'ParticipatesAs', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsParticipationOf
    return($return);
}




=head2 get_relationship_ProducedResultsFor

  $return = $obj->get_relationship_ProducedResultsFor($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_ProducedResultsFor
	2: a fields_Genome
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProducedResultsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProbeSet
	1: a fields_ProducedResultsFor
	2: a fields_Genome
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProducedResultsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description

This relationship connects a probe set to a genome for which it was
used to produce experimental results. In general, a probe set is used for
only one genome and vice versa, but this is not a requirement.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_ProducedResultsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_ProducedResultsFor

    $return = $self->_get_relationship($ctx, 'ProducedResultsFor', 'ProducedResultsFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ProducedResultsFor
    return($return);
}




=head2 get_relationship_HadResultsProducedBy

  $return = $obj->get_relationship_HadResultsProducedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_ProducedResultsFor
	2: a fields_ProbeSet
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_ProducedResultsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_ProducedResultsFor
	2: a fields_ProbeSet
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_ProducedResultsFor is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_ProbeSet is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_HadResultsProducedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_HadResultsProducedBy

    $return = $self->_get_relationship($ctx, 'HadResultsProducedBy', 'ProducedResultsFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HadResultsProducedBy
    return($return);
}




=head2 get_relationship_ProjectsOnto

  $return = $obj->get_relationship_ProjectsOnto($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_ProjectsOnto
	2: a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_ProjectsOnto is a reference to a hash where the following keys are defined:
	id has a value which is a string
	gene_context has a value which is an int
	percent_identity has a value which is a float
	score has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_ProjectsOnto
	2: a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_ProjectsOnto is a reference to a hash where the following keys are defined:
	id has a value which is a string
	gene_context has a value which is an int
	percent_identity has a value which is a float
	score has a value which is a float


=end text



=item Description

This relationship connects two protein sequences for which a clear
bidirectional best hit exists in known genomes. The attributes of the
relationship describe how good the relationship is between the proteins.
The relationship is bidirectional and symmetric, but is only stored in
one direction (lower ID to higher ID).
It has the following fields:

=over 4


=item gene_context

number of homologous genes in the immediate context of the
two proteins, up to a maximum of 10


=item percent_identity

percent match between the two protein sequences


=item score

score describing the strength of the projection, from 0 to 1,
where 1 is the best



=back

=back

=cut

sub get_relationship_ProjectsOnto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_ProjectsOnto

    $return = $self->_get_relationship($ctx, 'ProjectsOnto', 'ProjectsOnto', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ProjectsOnto
    return($return);
}




=head2 get_relationship_IsProjectedOnto

  $return = $obj->get_relationship_IsProjectedOnto($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_ProjectsOnto
	2: a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_ProjectsOnto is a reference to a hash where the following keys are defined:
	id has a value which is a string
	gene_context has a value which is an int
	percent_identity has a value which is a float
	score has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_ProteinSequence
	1: a fields_ProjectsOnto
	2: a fields_ProteinSequence
fields_ProteinSequence is a reference to a hash where the following keys are defined:
	id has a value which is a string
	sequence has a value which is a string
fields_ProjectsOnto is a reference to a hash where the following keys are defined:
	id has a value which is a string
	gene_context has a value which is an int
	percent_identity has a value which is a float
	score has a value which is a float


=end text



=item Description



=back

=cut

sub get_relationship_IsProjectedOnto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsProjectedOnto

    $return = $self->_get_relationship($ctx, 'IsProjectedOnto', 'ProjectsOnto', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsProjectedOnto
    return($return);
}




=head2 get_relationship_Provided

  $return = $obj->get_relationship_Provided($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_Provided
	2: a fields_Subsystem
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Provided is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_Provided
	2: a fields_Subsystem
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Provided is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int


=end text



=item Description

This relationship connects a source (core) database
to the subsystems it submitted to the knowledge base.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Provided
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Provided

    $return = $self->_get_relationship($ctx, 'Provided', 'Provided', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Provided
    return($return);
}




=head2 get_relationship_WasProvidedBy

  $return = $obj->get_relationship_WasProvidedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_Provided
	2: a fields_Source
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_Provided is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Subsystem
	1: a fields_Provided
	2: a fields_Source
fields_Subsystem is a reference to a hash where the following keys are defined:
	id has a value which is a string
	version has a value which is an int
	curator has a value which is a string
	notes has a value which is a string
	description has a value which is a string
	usable has a value which is an int
	private has a value which is an int
	cluster_based has a value which is an int
	experimental has a value which is an int
fields_Provided is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_WasProvidedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_WasProvidedBy

    $return = $self->_get_relationship($ctx, 'WasProvidedBy', 'Provided', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasProvidedBy
    return($return);
}




=head2 get_relationship_Shows

  $return = $obj->get_relationship_Shows($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_Shows
	2: a fields_Compound
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_Shows is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Diagram
	1: a fields_Shows
	2: a fields_Compound
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string
fields_Shows is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float


=end text



=item Description

This relationship indicates that a compound appears on a
particular diagram. The same compound can appear on many diagrams,
and a diagram always contains many compounds.
It has the following fields:

=over 4


=item location

Location of the compound's node on the diagram.



=back

=back

=cut

sub get_relationship_Shows
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Shows

    $return = $self->_get_relationship($ctx, 'Shows', 'Shows', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Shows
    return($return);
}




=head2 get_relationship_IsShownOn

  $return = $obj->get_relationship_IsShownOn($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_Shows
	2: a fields_Diagram
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_Shows is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Compound
	1: a fields_Shows
	2: a fields_Diagram
fields_Compound is a reference to a hash where the following keys are defined:
	id has a value which is a string
	label has a value which is a string
	abbr has a value which is a string
	ubiquitous has a value which is an int
	mod_date has a value which is a string
	uncharged_formula has a value which is a string
	formula has a value which is a string
	mass has a value which is a float
fields_Shows is a reference to a hash where the following keys are defined:
	id has a value which is a string
	location has a value which is a rectangle
rectangle is a string
fields_Diagram is a reference to a hash where the following keys are defined:
	id has a value which is a string
	name has a value which is a string
	content has a value which is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsShownOn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsShownOn

    $return = $self->_get_relationship($ctx, 'IsShownOn', 'Shows', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsShownOn
    return($return);
}




=head2 get_relationship_Submitted

  $return = $obj->get_relationship_Submitted($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_Submitted
	2: a fields_Genome
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Submitted is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Source
	1: a fields_Submitted
	2: a fields_Genome
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Submitted is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description

This relationship connects a genome to the
core database from which it was loaded.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Submitted
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Submitted

    $return = $self->_get_relationship($ctx, 'Submitted', 'Submitted', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Submitted
    return($return);
}




=head2 get_relationship_WasSubmittedBy

  $return = $obj->get_relationship_WasSubmittedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_Submitted
	2: a fields_Source
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_Submitted is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_Submitted
	2: a fields_Source
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_Submitted is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Source is a reference to a hash where the following keys are defined:
	id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_WasSubmittedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_WasSubmittedBy

    $return = $self->_get_relationship($ctx, 'WasSubmittedBy', 'Submitted', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasSubmittedBy
    return($return);
}




=head2 get_relationship_Uses

  $return = $obj->get_relationship_Uses($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_Uses
	2: a fields_SSRow
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_Uses is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_Genome
	1: a fields_Uses
	2: a fields_SSRow
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string
fields_Uses is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string


=end text



=item Description

This relationship connects a genome to the machines that form
its metabolic pathways. A genome can use many machines, but a
machine is used by exactly one genome.
It has the following fields:

=over 4



=back

=back

=cut

sub get_relationship_Uses
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_Uses

    $return = $self->_get_relationship($ctx, 'Uses', 'Uses', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Uses
    return($return);
}




=head2 get_relationship_IsUsedBy

  $return = $obj->get_relationship_IsUsedBy($ids, $from_fields, $rel_fields, $to_fields)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSRow
	1: a fields_Uses
	2: a fields_Genome
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string
fields_Uses is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is a string
$from_fields is a reference to a list where each element is a string
$rel_fields is a reference to a list where each element is a string
$to_fields is a reference to a list where each element is a string
$return is a reference to a list where each element is a reference to a list containing 3 items:
	0: a fields_SSRow
	1: a fields_Uses
	2: a fields_Genome
fields_SSRow is a reference to a hash where the following keys are defined:
	id has a value which is a string
	curated has a value which is an int
	region has a value which is a string
fields_Uses is a reference to a hash where the following keys are defined:
	id has a value which is a string
fields_Genome is a reference to a hash where the following keys are defined:
	id has a value which is a string
	pegs has a value which is an int
	rnas has a value which is an int
	scientific_name has a value which is a string
	complete has a value which is an int
	prokaryotic has a value which is an int
	dna_size has a value which is an int
	contigs has a value which is an int
	domain has a value which is a string
	genetic_code has a value which is an int
	gc_content has a value which is a float
	phenotype has a value which is a reference to a list where each element is a string
	md5 has a value which is a string
	source_id has a value which is a string


=end text



=item Description



=back

=cut

sub get_relationship_IsUsedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_APIServer::CallContext;
    my($return);
    #BEGIN get_relationship_IsUsedBy

    $return = $self->_get_relationship($ctx, 'IsUsedBy', 'Uses', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUsedBy
    return($return);
}




=head1 TYPES



=head2 annotator

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 annotation_time

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 comment

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 fid

=over 4



=item Description

A fid is a "feature id".  A feature represents an ordered list of regions from
the contigs of a genome.  Features all have types.  This allows you to speak
of not only protein-encoding genes (PEGs) and RNAs, but also binding sites,
large regions, etc.  The location of a fid is defined as a list of
"location of a contiguous DNA string" pieces (see the description of the
type "location")


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 protein_family

=over 4



=item Description

A protein_family is thought of as a set of isofunctional, homologous protein sequences.
This is not exactly what other groups have meant by "protein families".  There is no
hierarchy of super-family, family, sub-family.  We plan on loading different collections
of protein families, but in many cases there will need to be a transformation into the
concept used by Kbase.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 role

=over 4



=item Description

The concept of "role" or "functional role" is basically an atomic functional unit.
The "function of a protein" is made up of one or more roles.  That is, a bifunctional protein
with an assigned function of

   5-Enolpyruvylshikimate-3-phosphate synthase (EC 2.5.1.19) / Cytidylate kinase (EC 2.7.4.14)

would implement two distinct roles (the "function1 / function2" notation is intended to assert
that the initial part of the protein implements function1, and the terminal part of the protein
implements function2).  It is worth noting that a protein often implements multiple roles due
to broad specificity.  In this case, we suggest describing the protein function as

     function1 @ function2

That is the ' / ' separator is used to represent multiple roles implemented by distinct
domains of the protein, while ' @ ' is used to represent multiple roles implemented by
distinct domains.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 subsystem

=over 4



=item Description

A substem is composed of two components: a set of roles that are gathered to be annotated
simultaneously and a spreadsheet depicting the proteins within each genome that implement
the roles.  The set of roles may correspond to a pathway, a complex, an inventory (say, "transporters")
or whatever other principle an annotator used to formulate the subsystem.

The subsystem spreadsheet is a list of "rows", each representing the subsytem in a specific genome.
Each row includes a variant code (indicating what version of the molecular machine exists in the
genome) and cells.  Each cell is a 2-tuple:

     [role,protein-encoding genes that implement the role in the genome]

Annotators construct subsystems, and in the process impose a controlled vocabulary
for roles and functions.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 variant

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 variant_of_subsystem

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a subsystem
1: a variant

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a subsystem
1: a variant


=end text

=back



=head2 variant_subsystem_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a variant_of_subsystem
</pre>

=end html

=begin text

a reference to a list where each element is a variant_of_subsystem

=end text

=back



=head2 type_of_fid

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 types_of_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a type_of_fid
</pre>

=end html

=begin text

a reference to a list where each element is a type_of_fid

=end text

=back



=head2 length

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 begin

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 strand

=over 4



=item Description

In encodings of locations, we often specify strands.  We specify the strand
as '+' or '-'


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 contig

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 region_of_dna

=over 4



=item Description

A region of DNA is maintained as a tuple of four components:

                the contig
                the beginning position (from 1)
                the strand
                the length

           We often speak of "a region".  By "location", we mean a sequence
           of regions from the same genome (perhaps from distinct contigs).


=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: a contig
1: a begin
2: a strand
3: a length

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: a contig
1: a begin
2: a strand
3: a length


=end text

=back



=head2 location

=over 4



=item Description

a "location" refers to a sequence of regions


=item Definition

=begin html

<pre>
a reference to a list where each element is a region_of_dna
</pre>

=end html

=begin text

a reference to a list where each element is a region_of_dna

=end text

=back



=head2 locations

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a location
</pre>

=end html

=begin text

a reference to a list where each element is a location

=end text

=back



=head2 region_of_dna_string

=over 4



=item Description

we often need to represent regions or locations as
strings.  We would use something like

     contigA_200+100,contigA_402+188

to represent a location composed of two regions


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 region_of_dna_strings

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a region_of_dna_string
</pre>

=end html

=begin text

a reference to a list where each element is a region_of_dna_string

=end text

=back



=head2 location_string

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 dna

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 function

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 protein

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 md5

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 genome

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 taxonomic_group

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 annotation

=over 4



=item Description

The Kbase stores annotations relating to features.  Each annotation
is a 3-tuple:

     the text of the annotation (often a record of assertion of function)

     the annotator attaching the annotation to the feature

     the time (in seconds from the epoch) at which the annotation was attached


=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a comment
1: an annotator
2: an annotation_time

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a comment
1: an annotator
2: an annotation_time


=end text

=back



=head2 pubref

=over 4



=item Description

The Kbase will include a growing body of literature supporting protein
functions, asserted phenotypes, etc.  References are encoded as 3-tuples:

     an id (often a PubMed ID)

     a URL to the paper

     a title of the paper

The URL and title are often missing (but, can usually be inferred from the pubmed ID).


=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a string
1: a string
2: a string

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a string
1: a string
2: a string


=end text

=back



=head2 scored_fid

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a float

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a float


=end text

=back



=head2 annotations

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is an annotation
</pre>

=end html

=begin text

a reference to a list where each element is an annotation

=end text

=back



=head2 pubrefs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a pubref
</pre>

=end html

=begin text

a reference to a list where each element is a pubref

=end text

=back



=head2 roles

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a role
</pre>

=end html

=begin text

a reference to a list where each element is a role

=end text

=back



=head2 optional

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 role_with_flag

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a role
1: an optional

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a role
1: an optional


=end text

=back



=head2 roles_with_flags

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a role_with_flag
</pre>

=end html

=begin text

a reference to a list where each element is a role_with_flag

=end text

=back



=head2 scored_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a scored_fid
</pre>

=end html

=begin text

a reference to a list where each element is a scored_fid

=end text

=back



=head2 proteins

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a protein
</pre>

=end html

=begin text

a reference to a list where each element is a protein

=end text

=back



=head2 functions

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a function
</pre>

=end html

=begin text

a reference to a list where each element is a function

=end text

=back



=head2 taxonomic_groups

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a taxonomic_group
</pre>

=end html

=begin text

a reference to a list where each element is a taxonomic_group

=end text

=back



=head2 subsystems

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a subsystem
</pre>

=end html

=begin text

a reference to a list where each element is a subsystem

=end text

=back



=head2 contigs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a contig
</pre>

=end html

=begin text

a reference to a list where each element is a contig

=end text

=back



=head2 md5s

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a md5
</pre>

=end html

=begin text

a reference to a list where each element is a md5

=end text

=back



=head2 genomes

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a genome
</pre>

=end html

=begin text

a reference to a list where each element is a genome

=end text

=back



=head2 pair_of_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a fid

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a fid


=end text

=back



=head2 pairs_of_fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a pair_of_fids
</pre>

=end html

=begin text

a reference to a list where each element is a pair_of_fids

=end text

=back



=head2 protein_families

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a protein_family
</pre>

=end html

=begin text

a reference to a list where each element is a protein_family

=end text

=back



=head2 score

=over 4



=item Definition

=begin html

<pre>
a float
</pre>

=end html

=begin text

a float

=end text

=back



=head2 evidence

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a pair_of_fids
</pre>

=end html

=begin text

a reference to a list where each element is a pair_of_fids

=end text

=back



=head2 fids

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid
</pre>

=end html

=begin text

a reference to a list where each element is a fid

=end text

=back



=head2 row

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a variant
1: a reference to a hash where the key is a role and the value is a fids

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a variant
1: a reference to a hash where the key is a role and the value is a fids


=end text

=back



=head2 fid_function_pair

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a fid
1: a function

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a fid
1: a function


=end text

=back



=head2 fid_function_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fid_function_pair
</pre>

=end html

=begin text

a reference to a list where each element is a fid_function_pair

=end text

=back



=head2 fc_protein_family

=over 4



=item Description

A functionally coupled protein family identifies a family, a score, and a function
(of the related family)


=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a protein_family
1: a score
2: a function

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a protein_family
1: a score
2: a function


=end text

=back



=head2 fc_protein_families

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a fc_protein_family
</pre>

=end html

=begin text

a reference to a list where each element is a fc_protein_family

=end text

=back



=head2 aux

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 fields

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 complex

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 complex_with_flag

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a complex
1: an optional

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a complex
1: an optional


=end text

=back



=head2 complexes_with_flags

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a complex_with_flag
</pre>

=end html

=begin text

a reference to a list where each element is a complex_with_flag

=end text

=back



=head2 complexes

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a complex
</pre>

=end html

=begin text

a reference to a list where each element is a complex

=end text

=back



=head2 name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 reaction

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 reactions

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a reaction
</pre>

=end html

=begin text

a reference to a list where each element is a reaction

=end text

=back



=head2 complex_data

=over 4



=item Description

Reactions do not connect directly to roles.  Rather, the conceptual model is that one or more roles
together form a complex.  A complex implements one or more reactions.  The actual data relating
to a complex is spread over two entities: Complex and ReactionComplex. It is convenient to be
able to offer access to the complex name, the reactions it implements, and the roles that make it up
in a single invocation.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
complex_name has a value which is a name
complex_roles has a value which is a roles_with_flags
complex_reactions has a value which is a reactions

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
complex_name has a value which is a name
complex_roles has a value which is a roles_with_flags
complex_reactions has a value which is a reactions


=end text

=back



=head2 genome_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
complete has a value which is an int
contigs has a value which is an int
dna_size has a value which is an int
gc_content has a value which is a float
genetic_code has a value which is an int
pegs has a value which is an int
rnas has a value which is an int
scientific_name has a value which is a string
taxonomy has a value which is a string
genome_md5 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
complete has a value which is an int
contigs has a value which is an int
dna_size has a value which is an int
gc_content has a value which is a float
genetic_code has a value which is an int
pegs has a value which is an int
rnas has a value which is an int
scientific_name has a value which is a string
taxonomy has a value which is a string
genome_md5 has a value which is a string


=end text

=back



=head2 regulon_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
regulon_id has a value which is a string
regulon_set has a value which is a fids
tfs has a value which is a fids

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
regulon_id has a value which is a string
regulon_set has a value which is a fids
tfs has a value which is a fids


=end text

=back



=head2 regulons_data

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a regulon_data
</pre>

=end html

=begin text

a reference to a list where each element is a regulon_data

=end text

=back



=head2 feature_data

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
feature_id has a value which is a fid
genome_name has a value which is a string
feature_function has a value which is a string
feature_length has a value which is an int
feature_publications has a value which is a pubrefs
feature_location has a value which is a location

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
feature_id has a value which is a fid
genome_name has a value which is a string
feature_function has a value which is a string
feature_length has a value which is an int
feature_publications has a value which is a pubrefs
feature_location has a value which is a location


=end text

=back



=head2 expert

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 source

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 function_assertion

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: an id
1: a function
2: a source
3: an expert

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: an id
1: a function
2: a source
3: an expert


=end text

=back



=head2 function_assertions

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a function_assertion
</pre>

=end html

=begin text

a reference to a list where each element is a function_assertion

=end text

=back



=head2 regulon

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 regulon_size

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 regulon_size_pair

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a regulon
1: a regulon_size

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a regulon
1: a regulon_size


=end text

=back



=head2 regulon_size_pairs

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a regulon_size_pair
</pre>

=end html

=begin text

a reference to a list where each element is a regulon_size_pair

=end text

=back



=head2 regulons

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a regulon
</pre>

=end html

=begin text

a reference to a list where each element is a regulon

=end text

=back



=head2 protein_sequence

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 dna_sequence

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 name_parameter

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ss_var_role_tuple

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a subsystem
1: a variant
2: a role

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a subsystem
1: a variant
2: a role


=end text

=back



=head2 ss_var_role_tuples

=over 4



=item Definition

=begin html

<pre>
a reference to a list where each element is a ss_var_role_tuple
</pre>

=end html

=begin text

a reference to a list where each element is a ss_var_role_tuple

=end text

=back



=head2 genome_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 entity_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 weight

=over 4



=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 field_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 search_hit

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: a weight
1: a reference to a hash where the key is a field_name and the value is a string

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: a weight
1: a reference to a hash where the key is a field_name and the value is a string


=end text

=back



=head2 diamond

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 countVector

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 rectangle

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 fields_AlignmentTree

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
alignment_method has a value which is a string
alignment_parameters has a value which is a string
alignment_properties has a value which is a string
tree_method has a value which is a string
tree_parameters has a value which is a string
tree_properties has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
alignment_method has a value which is a string
alignment_parameters has a value which is a string
alignment_properties has a value which is a string
tree_method has a value which is a string
tree_parameters has a value which is a string
tree_properties has a value which is a string


=end text

=back



=head2 fields_Annotation

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
annotator has a value which is a string
comment has a value which is a string
annotation_time has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
annotator has a value which is a string
comment has a value which is a string
annotation_time has a value which is a string


=end text

=back



=head2 fields_AtomicRegulon

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Attribute

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
description has a value which is a string


=end text

=back



=head2 fields_Biomass

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a reference to a list where each element is a string


=end text

=back



=head2 fields_BiomassCompound

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
coefficient has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
coefficient has a value which is a float


=end text

=back



=head2 fields_Compartment

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
abbr has a value which is a string
mod_date has a value which is a string
name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
abbr has a value which is a string
mod_date has a value which is a string
name has a value which is a string


=end text

=back



=head2 fields_Complex

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
name has a value which is a reference to a list where each element is a string
mod_date has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
name has a value which is a reference to a list where each element is a string
mod_date has a value which is a string


=end text

=back



=head2 fields_Compound

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
label has a value which is a string
abbr has a value which is a string
ubiquitous has a value which is an int
mod_date has a value which is a string
uncharged_formula has a value which is a string
formula has a value which is a string
mass has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
label has a value which is a string
abbr has a value which is a string
ubiquitous has a value which is an int
mod_date has a value which is a string
uncharged_formula has a value which is a string
formula has a value which is a string
mass has a value which is a float


=end text

=back



=head2 fields_Contig

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
source_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
source_id has a value which is a string


=end text

=back



=head2 fields_ContigChunk

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is a string


=end text

=back



=head2 fields_ContigSequence

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
length has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
length has a value which is an int


=end text

=back



=head2 fields_CoregulatedSet

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
reason has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
reason has a value which is a string


=end text

=back



=head2 fields_Diagram

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
name has a value which is a string
content has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
name has a value which is a string
content has a value which is a reference to a list where each element is a string


=end text

=back



=head2 fields_EcNumber

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
obsolete has a value which is an int
replacedby has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
obsolete has a value which is an int
replacedby has a value which is a string


=end text

=back



=head2 fields_Experiment

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
source has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
source has a value which is a string


=end text

=back



=head2 fields_Family

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string
family_function has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string
family_function has a value which is a reference to a list where each element is a string


=end text

=back



=head2 fields_Feature

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
feature_type has a value which is a string
source_id has a value which is a string
sequence_length has a value which is an int
function has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
feature_type has a value which is a string
source_id has a value which is a string
sequence_length has a value which is an int
function has a value which is a string


=end text

=back



=head2 fields_Genome

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
pegs has a value which is an int
rnas has a value which is an int
scientific_name has a value which is a string
complete has a value which is an int
prokaryotic has a value which is an int
dna_size has a value which is an int
contigs has a value which is an int
domain has a value which is a string
genetic_code has a value which is an int
gc_content has a value which is a float
phenotype has a value which is a reference to a list where each element is a string
md5 has a value which is a string
source_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
pegs has a value which is an int
rnas has a value which is an int
scientific_name has a value which is a string
complete has a value which is an int
prokaryotic has a value which is an int
dna_size has a value which is an int
contigs has a value which is an int
domain has a value which is a string
genetic_code has a value which is an int
gc_content has a value which is a float
phenotype has a value which is a reference to a list where each element is a string
md5 has a value which is a string
source_id has a value which is a string


=end text

=back



=head2 fields_Identifier

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
source has a value which is a string
natural_form has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
source has a value which is a string
natural_form has a value which is a string


=end text

=back



=head2 fields_Media

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a string
type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a string
type has a value which is a string


=end text

=back



=head2 fields_Model

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a string
version has a value which is an int
type has a value which is a string
status has a value which is a string
reaction_count has a value which is an int
compound_count has a value which is an int
annotation_count has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a string
version has a value which is an int
type has a value which is a string
status has a value which is a string
reaction_count has a value which is an int
compound_count has a value which is an int
annotation_count has a value which is an int


=end text

=back



=head2 fields_ModelCompartment

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
compartment_index has a value which is an int
label has a value which is a reference to a list where each element is a string
pH has a value which is a float
potential has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
compartment_index has a value which is an int
label has a value which is a reference to a list where each element is a string
pH has a value which is a float
potential has a value which is a float


=end text

=back



=head2 fields_OTU

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_PairSet

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
score has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
score has a value which is an int


=end text

=back



=head2 fields_Pairing

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_ProbeSet

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_ProteinSequence

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is a string


=end text

=back



=head2 fields_Publication

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
citation has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
citation has a value which is a string


=end text

=back



=head2 fields_Reaction

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a string
abbr has a value which is a string
equation has a value which is a string
reversibility has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
mod_date has a value which is a string
name has a value which is a string
abbr has a value which is a string
equation has a value which is a string
reversibility has a value which is a string


=end text

=back



=head2 fields_ReactionRule

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
direction has a value which is a string
transproton has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
direction has a value which is a string
transproton has a value which is a float


=end text

=back



=head2 fields_Reagent

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
stoichiometry has a value which is a float
cofactor has a value which is an int
compartment_index has a value which is an int
transport_coefficient has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
stoichiometry has a value which is a float
cofactor has a value which is an int
compartment_index has a value which is an int
transport_coefficient has a value which is a float


=end text

=back



=head2 fields_Requirement

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
direction has a value which is a string
transproton has a value which is a float
proton has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
direction has a value which is a string
transproton has a value which is a float
proton has a value which is a float


=end text

=back



=head2 fields_Role

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
hypothetical has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
hypothetical has a value which is an int


=end text

=back



=head2 fields_SSCell

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_SSRow

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
curated has a value which is an int
region has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
curated has a value which is an int
region has a value which is a string


=end text

=back



=head2 fields_Scenario

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
common_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
common_name has a value which is a string


=end text

=back



=head2 fields_Source

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Subsystem

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
version has a value which is an int
curator has a value which is a string
notes has a value which is a string
description has a value which is a string
usable has a value which is an int
private has a value which is an int
cluster_based has a value which is an int
experimental has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
version has a value which is an int
curator has a value which is a string
notes has a value which is a string
description has a value which is a string
usable has a value which is an int
private has a value which is an int
cluster_based has a value which is an int
experimental has a value which is an int


=end text

=back



=head2 fields_SubsystemClass

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_TaxonomicGrouping

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
domain has a value which is an int
hidden has a value which is an int
scientific_name has a value which is a string
alias has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
domain has a value which is an int
hidden has a value which is an int
scientific_name has a value which is a string
alias has a value which is a reference to a list where each element is a string


=end text

=back



=head2 fields_Variant

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
role_rule has a value which is a reference to a list where each element is a string
code has a value which is a string
type has a value which is a string
comment has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
role_rule has a value which is a reference to a list where each element is a string
code has a value which is a string
type has a value which is a string
comment has a value which is a string


=end text

=back



=head2 fields_Variation

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
notes has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
notes has a value which is a reference to a list where each element is a string


=end text

=back



=head2 fields_AffectsLevelOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
level has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
level has a value which is an int


=end text

=back



=head2 fields_Aligns

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
begin has a value which is an int
end has a value which is an int
len has a value which is an int
sequence_id has a value which is a string
properties has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
begin has a value which is an int
end has a value which is an int
len has a value which is an int
sequence_id has a value which is a string
properties has a value which is a string


=end text

=back



=head2 fields_Concerns

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Contains

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Describes

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Displays

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
location has a value which is a rectangle

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
location has a value which is a rectangle


=end text

=back



=head2 fields_Encompasses

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_GeneratedLevelsFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
level_vector has a value which is a countVector

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
level_vector has a value which is a countVector


=end text

=back



=head2 fields_HasAssertionFrom

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
function has a value which is a string
expert has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
function has a value which is a string
expert has a value which is an int


=end text

=back



=head2 fields_HasCompoundAliasFrom

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
alias has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
alias has a value which is a string


=end text

=back



=head2 fields_HasIndicatedSignalFrom

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
rma_value has a value which is a float
level has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
rma_value has a value which is a float
level has a value which is an int


=end text

=back



=head2 fields_HasMember

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_HasParticipant

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is an int


=end text

=back



=head2 fields_HasPresenceOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
concentration has a value which is a float
minimum_flux has a value which is a float
maximum_flux has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
concentration has a value which is a float
minimum_flux has a value which is a float
maximum_flux has a value which is a float


=end text

=back



=head2 fields_HasReactionAliasFrom

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
alias has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
alias has a value which is a string


=end text

=back



=head2 fields_HasRepresentativeOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_HasResultsIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is an int


=end text

=back



=head2 fields_HasSection

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_HasStep

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_HasUsage

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_HasValueFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
value has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
value has a value which is a string


=end text

=back



=head2 fields_Includes

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is an int
abbreviation has a value which is a string
auxiliary has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
sequence has a value which is an int
abbreviation has a value which is a string
auxiliary has a value which is an int


=end text

=back



=head2 fields_IndicatedLevelsFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
level_vector has a value which is a countVector

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
level_vector has a value which is a countVector


=end text

=back



=head2 fields_Involves

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsARequirementIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsAlignedIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
start has a value which is an int
len has a value which is an int
dir has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
start has a value which is an int
len has a value which is an int
dir has a value which is a string


=end text

=back



=head2 fields_IsAnnotatedBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsBindingSiteFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsClassFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsCollectionOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
representative has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
representative has a value which is an int


=end text

=back



=head2 fields_IsComposedOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsComprisedOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsConfiguredBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsConsistentWith

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsControlledUsing

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
effector has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
effector has a value which is an int


=end text

=back



=head2 fields_IsCoregulatedWith

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
coefficient has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
coefficient has a value which is a float


=end text

=back



=head2 fields_IsCoupledTo

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
co_occurrence_evidence has a value which is an int
co_expression_evidence has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
co_occurrence_evidence has a value which is an int
co_expression_evidence has a value which is an int


=end text

=back



=head2 fields_IsDefaultFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsDefaultLocationOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsDeterminedBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
inverted has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
inverted has a value which is an int


=end text

=back



=head2 fields_IsDividedInto

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsExemplarOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsFamilyFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsFormedOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsFunctionalIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsGroupFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsImplementedBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsInPair

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsInstantiatedBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsLocatedIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
ordinal has a value which is an int
begin has a value which is an int
len has a value which is an int
dir has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
ordinal has a value which is an int
begin has a value which is an int
len has a value which is an int
dir has a value which is a string


=end text

=back



=head2 fields_IsModeledBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsNamedBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsOwnerOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsProposedLocationOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string


=end text

=back



=head2 fields_IsProteinFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsRealLocationOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
type has a value which is a string


=end text

=back



=head2 fields_IsRegulatedIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsRelevantFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsRequiredBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsRoleOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsRowOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsSequenceOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsSubInstanceOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsSuperclassOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsTargetOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsTaxonomyOf

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_IsTerminusFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
group_number has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
group_number has a value which is an int


=end text

=back



=head2 fields_IsTriggeredBy

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
optional has a value which is an int
type has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
optional has a value which is an int
type has a value which is a string


=end text

=back



=head2 fields_IsUsedAs

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Manages

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_OperatesIn

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Overlaps

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_ParticipatesAs

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_ProducedResultsFor

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_ProjectsOnto

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
gene_context has a value which is an int
percent_identity has a value which is a float
score has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
gene_context has a value which is an int
percent_identity has a value which is a float
score has a value which is a float


=end text

=back



=head2 fields_Provided

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Shows

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
location has a value which is a rectangle

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
location has a value which is a rectangle


=end text

=back



=head2 fields_Submitted

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=head2 fields_Uses

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string


=end text

=back



=cut

1;
