package Bio::KBase::CDMI::Service;

use Data::Dumper;
use Moose;
use JSON;
use Bio::KBase::Log;

extends 'RPC::Any::Server::JSONRPC::PSGI';

has 'instance_dispatch' => (is => 'ro', isa => 'HashRef');
has 'user_auth' => (is => 'ro', isa => 'UserAuth');
has 'valid_methods' => (is => 'ro', isa => 'HashRef', lazy => 1,
			builder => '_build_valid_methods');
has 'loggers' => (is => 'ro', required => 1, builder => '_build_loggers');

our $CallContext;

our %return_counts = (
        'fids_to_annotations' => 1,
        'fids_to_functions' => 1,
        'fids_to_literature' => 1,
        'fids_to_protein_families' => 1,
        'fids_to_roles' => 1,
        'fids_to_subsystems' => 1,
        'fids_to_co_occurring_fids' => 1,
        'fids_to_locations' => 1,
        'locations_to_fids' => 1,
        'alleles_to_bp_locs' => 1,
        'region_to_fids' => 1,
        'region_to_alleles' => 1,
        'alleles_to_traits' => 1,
        'traits_to_alleles' => 1,
        'ous_with_trait' => 1,
        'locations_to_dna_sequences' => 1,
        'proteins_to_fids' => 1,
        'proteins_to_protein_families' => 1,
        'proteins_to_literature' => 1,
        'proteins_to_functions' => 1,
        'proteins_to_roles' => 1,
        'roles_to_proteins' => 1,
        'roles_to_subsystems' => 1,
        'roles_to_protein_families' => 1,
        'fids_to_coexpressed_fids' => 1,
        'protein_families_to_fids' => 1,
        'protein_families_to_proteins' => 1,
        'protein_families_to_functions' => 1,
        'protein_families_to_co_occurring_families' => 1,
        'co_occurrence_evidence' => 1,
        'contigs_to_sequences' => 1,
        'contigs_to_lengths' => 1,
        'contigs_to_md5s' => 1,
        'md5s_to_genomes' => 1,
        'genomes_to_md5s' => 1,
        'genomes_to_contigs' => 1,
        'genomes_to_fids' => 1,
        'genomes_to_taxonomies' => 1,
        'genomes_to_subsystems' => 1,
        'subsystems_to_genomes' => 1,
        'subsystems_to_fids' => 1,
        'subsystems_to_roles' => 1,
        'subsystems_to_spreadsheets' => 1,
        'all_roles_used_in_models' => 1,
        'complexes_to_complex_data' => 1,
        'genomes_to_genome_data' => 1,
        'fids_to_regulon_data' => 1,
        'regulons_to_fids' => 1,
        'fids_to_feature_data' => 1,
        'equiv_sequence_assertions' => 1,
        'fids_to_atomic_regulons' => 1,
        'atomic_regulons_to_fids' => 1,
        'fids_to_protein_sequences' => 1,
        'fids_to_proteins' => 1,
        'fids_to_dna_sequences' => 1,
        'roles_to_fids' => 1,
        'reactions_to_complexes' => 1,
        'aliases_to_fids' => 1,
        'aliases_to_fids_by_source' => 1,
        'source_ids_to_fids' => 1,
        'external_ids_to_fids' => 1,
        'reaction_strings' => 1,
        'roles_to_complexes' => 1,
        'complexes_to_roles' => 1,
        'fids_to_subsystem_data' => 1,
        'representative' => 1,
        'otu_members' => 1,
        'otus_to_representatives' => 1,
        'fids_to_genomes' => 1,
        'text_search' => 1,
        'corresponds' => 1,
        'corresponds_from_sequences' => 1,
        'close_genomes' => 1,
        'representative_sequences' => 2,
        'align_sequences' => 1,
        'build_tree' => 1,
        'alignment_by_id' => 1,
        'tree_by_id' => 1,
        'all_entities' => 1,
        'all_relationships' => 1,
        'get_entity' => 1,
        'get_relationship' => 1,
        'get_all' => 1,
        'get_entity_Alignment' => 1,
        'query_entity_Alignment' => 1,
        'all_entities_Alignment' => 1,
        'get_entity_AlignmentAttribute' => 1,
        'query_entity_AlignmentAttribute' => 1,
        'all_entities_AlignmentAttribute' => 1,
        'get_entity_AlignmentRow' => 1,
        'query_entity_AlignmentRow' => 1,
        'all_entities_AlignmentRow' => 1,
        'get_entity_AlleleFrequency' => 1,
        'query_entity_AlleleFrequency' => 1,
        'all_entities_AlleleFrequency' => 1,
        'get_entity_Annotation' => 1,
        'query_entity_Annotation' => 1,
        'all_entities_Annotation' => 1,
        'get_entity_Assay' => 1,
        'query_entity_Assay' => 1,
        'all_entities_Assay' => 1,
        'get_entity_Association' => 1,
        'query_entity_Association' => 1,
        'all_entities_Association' => 1,
        'get_entity_AssociationDataset' => 1,
        'query_entity_AssociationDataset' => 1,
        'all_entities_AssociationDataset' => 1,
        'get_entity_AssociationDetectionType' => 1,
        'query_entity_AssociationDetectionType' => 1,
        'all_entities_AssociationDetectionType' => 1,
        'get_entity_AtomicRegulon' => 1,
        'query_entity_AtomicRegulon' => 1,
        'all_entities_AtomicRegulon' => 1,
        'get_entity_Attribute' => 1,
        'query_entity_Attribute' => 1,
        'all_entities_Attribute' => 1,
        'get_entity_Biomass' => 1,
        'query_entity_Biomass' => 1,
        'all_entities_Biomass' => 1,
        'get_entity_CodonUsage' => 1,
        'query_entity_CodonUsage' => 1,
        'all_entities_CodonUsage' => 1,
        'get_entity_Complex' => 1,
        'query_entity_Complex' => 1,
        'all_entities_Complex' => 1,
        'get_entity_Compound' => 1,
        'query_entity_Compound' => 1,
        'all_entities_Compound' => 1,
        'get_entity_CompoundInstance' => 1,
        'query_entity_CompoundInstance' => 1,
        'all_entities_CompoundInstance' => 1,
        'get_entity_ConservedDomainModel' => 1,
        'query_entity_ConservedDomainModel' => 1,
        'all_entities_ConservedDomainModel' => 1,
        'get_entity_Contig' => 1,
        'query_entity_Contig' => 1,
        'all_entities_Contig' => 1,
        'get_entity_ContigChunk' => 1,
        'query_entity_ContigChunk' => 1,
        'all_entities_ContigChunk' => 1,
        'get_entity_ContigSequence' => 1,
        'query_entity_ContigSequence' => 1,
        'all_entities_ContigSequence' => 1,
        'get_entity_CoregulatedSet' => 1,
        'query_entity_CoregulatedSet' => 1,
        'all_entities_CoregulatedSet' => 1,
        'get_entity_Diagram' => 1,
        'query_entity_Diagram' => 1,
        'all_entities_Diagram' => 1,
        'get_entity_EcNumber' => 1,
        'query_entity_EcNumber' => 1,
        'all_entities_EcNumber' => 1,
        'get_entity_Effector' => 1,
        'query_entity_Effector' => 1,
        'all_entities_Effector' => 1,
        'get_entity_Environment' => 1,
        'query_entity_Environment' => 1,
        'all_entities_Environment' => 1,
        'get_entity_Experiment' => 1,
        'query_entity_Experiment' => 1,
        'all_entities_Experiment' => 1,
        'get_entity_ExperimentMeta' => 1,
        'query_entity_ExperimentMeta' => 1,
        'all_entities_ExperimentMeta' => 1,
        'get_entity_ExperimentalUnit' => 1,
        'query_entity_ExperimentalUnit' => 1,
        'all_entities_ExperimentalUnit' => 1,
        'get_entity_ExperimentalUnitGroup' => 1,
        'query_entity_ExperimentalUnitGroup' => 1,
        'all_entities_ExperimentalUnitGroup' => 1,
        'get_entity_Family' => 1,
        'query_entity_Family' => 1,
        'all_entities_Family' => 1,
        'get_entity_Feature' => 1,
        'query_entity_Feature' => 1,
        'all_entities_Feature' => 1,
        'get_entity_Genome' => 1,
        'query_entity_Genome' => 1,
        'all_entities_Genome' => 1,
        'get_entity_Locality' => 1,
        'query_entity_Locality' => 1,
        'all_entities_Locality' => 1,
        'get_entity_LocalizedCompound' => 1,
        'query_entity_LocalizedCompound' => 1,
        'all_entities_LocalizedCompound' => 1,
        'get_entity_Location' => 1,
        'query_entity_Location' => 1,
        'all_entities_Location' => 1,
        'get_entity_LocationInstance' => 1,
        'query_entity_LocationInstance' => 1,
        'all_entities_LocationInstance' => 1,
        'get_entity_Measurement' => 1,
        'query_entity_Measurement' => 1,
        'all_entities_Measurement' => 1,
        'get_entity_MeasurementDescription' => 1,
        'query_entity_MeasurementDescription' => 1,
        'all_entities_MeasurementDescription' => 1,
        'get_entity_Media' => 1,
        'query_entity_Media' => 1,
        'all_entities_Media' => 1,
        'get_entity_Model' => 1,
        'query_entity_Model' => 1,
        'all_entities_Model' => 1,
        'get_entity_OTU' => 1,
        'query_entity_OTU' => 1,
        'all_entities_OTU' => 1,
        'get_entity_ObservationalUnit' => 1,
        'query_entity_ObservationalUnit' => 1,
        'all_entities_ObservationalUnit' => 1,
        'get_entity_Ontology' => 1,
        'query_entity_Ontology' => 1,
        'all_entities_Ontology' => 1,
        'get_entity_Operon' => 1,
        'query_entity_Operon' => 1,
        'all_entities_Operon' => 1,
        'get_entity_PairSet' => 1,
        'query_entity_PairSet' => 1,
        'all_entities_PairSet' => 1,
        'get_entity_Pairing' => 1,
        'query_entity_Pairing' => 1,
        'all_entities_Pairing' => 1,
        'get_entity_Parameter' => 1,
        'query_entity_Parameter' => 1,
        'all_entities_Parameter' => 1,
        'get_entity_Person' => 1,
        'query_entity_Person' => 1,
        'all_entities_Person' => 1,
        'get_entity_Platform' => 1,
        'query_entity_Platform' => 1,
        'all_entities_Platform' => 1,
        'get_entity_ProbeSet' => 1,
        'query_entity_ProbeSet' => 1,
        'all_entities_ProbeSet' => 1,
        'get_entity_ProteinSequence' => 1,
        'query_entity_ProteinSequence' => 1,
        'all_entities_ProteinSequence' => 1,
        'get_entity_Protocol' => 1,
        'query_entity_Protocol' => 1,
        'all_entities_Protocol' => 1,
        'get_entity_Publication' => 1,
        'query_entity_Publication' => 1,
        'all_entities_Publication' => 1,
        'get_entity_Reaction' => 1,
        'query_entity_Reaction' => 1,
        'all_entities_Reaction' => 1,
        'get_entity_ReactionInstance' => 1,
        'query_entity_ReactionInstance' => 1,
        'all_entities_ReactionInstance' => 1,
        'get_entity_Regulator' => 1,
        'query_entity_Regulator' => 1,
        'all_entities_Regulator' => 1,
        'get_entity_Regulog' => 1,
        'query_entity_Regulog' => 1,
        'all_entities_Regulog' => 1,
        'get_entity_RegulogCollection' => 1,
        'query_entity_RegulogCollection' => 1,
        'all_entities_RegulogCollection' => 1,
        'get_entity_Regulome' => 1,
        'query_entity_Regulome' => 1,
        'all_entities_Regulome' => 1,
        'get_entity_Regulon' => 1,
        'query_entity_Regulon' => 1,
        'all_entities_Regulon' => 1,
        'get_entity_ReplicateGroup' => 1,
        'query_entity_ReplicateGroup' => 1,
        'all_entities_ReplicateGroup' => 1,
        'get_entity_Role' => 1,
        'query_entity_Role' => 1,
        'all_entities_Role' => 1,
        'get_entity_SSCell' => 1,
        'query_entity_SSCell' => 1,
        'all_entities_SSCell' => 1,
        'get_entity_SSRow' => 1,
        'query_entity_SSRow' => 1,
        'all_entities_SSRow' => 1,
        'get_entity_Sample' => 1,
        'query_entity_Sample' => 1,
        'all_entities_Sample' => 1,
        'get_entity_SampleAnnotation' => 1,
        'query_entity_SampleAnnotation' => 1,
        'all_entities_SampleAnnotation' => 1,
        'get_entity_Scenario' => 1,
        'query_entity_Scenario' => 1,
        'all_entities_Scenario' => 1,
        'get_entity_Series' => 1,
        'query_entity_Series' => 1,
        'all_entities_Series' => 1,
        'get_entity_Source' => 1,
        'query_entity_Source' => 1,
        'all_entities_Source' => 1,
        'get_entity_Strain' => 1,
        'query_entity_Strain' => 1,
        'all_entities_Strain' => 1,
        'get_entity_StudyExperiment' => 1,
        'query_entity_StudyExperiment' => 1,
        'all_entities_StudyExperiment' => 1,
        'get_entity_Subsystem' => 1,
        'query_entity_Subsystem' => 1,
        'all_entities_Subsystem' => 1,
        'get_entity_SubsystemClass' => 1,
        'query_entity_SubsystemClass' => 1,
        'all_entities_SubsystemClass' => 1,
        'get_entity_TaxonomicGrouping' => 1,
        'query_entity_TaxonomicGrouping' => 1,
        'all_entities_TaxonomicGrouping' => 1,
        'get_entity_TimeSeries' => 1,
        'query_entity_TimeSeries' => 1,
        'all_entities_TimeSeries' => 1,
        'get_entity_Trait' => 1,
        'query_entity_Trait' => 1,
        'all_entities_Trait' => 1,
        'get_entity_Tree' => 1,
        'query_entity_Tree' => 1,
        'all_entities_Tree' => 1,
        'get_entity_TreeAttribute' => 1,
        'query_entity_TreeAttribute' => 1,
        'all_entities_TreeAttribute' => 1,
        'get_entity_TreeNodeAttribute' => 1,
        'query_entity_TreeNodeAttribute' => 1,
        'all_entities_TreeNodeAttribute' => 1,
        'get_entity_Variant' => 1,
        'query_entity_Variant' => 1,
        'all_entities_Variant' => 1,
        'get_relationship_AffectsLevelOf' => 1,
        'get_relationship_IsAffectedIn' => 1,
        'get_relationship_Aligned' => 1,
        'get_relationship_WasAlignedBy' => 1,
        'get_relationship_AssertsFunctionFor' => 1,
        'get_relationship_HasAssertedFunctionFrom' => 1,
        'get_relationship_AssociationFeature' => 1,
        'get_relationship_FeatureInteractsIn' => 1,
        'get_relationship_CompoundMeasuredBy' => 1,
        'get_relationship_MeasuresCompound' => 1,
        'get_relationship_Concerns' => 1,
        'get_relationship_IsATopicOf' => 1,
        'get_relationship_ConsistsOfCompounds' => 1,
        'get_relationship_ComponentOf' => 1,
        'get_relationship_Contains' => 1,
        'get_relationship_IsContainedIn' => 1,
        'get_relationship_ContainsAlignedDNA' => 1,
        'get_relationship_IsAlignedDNAComponentOf' => 1,
        'get_relationship_ContainsAlignedProtein' => 1,
        'get_relationship_IsAlignedProteinComponentOf' => 1,
        'get_relationship_ContainsExperimentalUnit' => 1,
        'get_relationship_GroupedBy' => 1,
        'get_relationship_Controls' => 1,
        'get_relationship_IsControlledUsing' => 1,
        'get_relationship_DefaultControlSample' => 1,
        'get_relationship_SamplesDefaultControl' => 1,
        'get_relationship_Describes' => 1,
        'get_relationship_IsDescribedBy' => 1,
        'get_relationship_DescribesAlignment' => 1,
        'get_relationship_HasAlignmentAttribute' => 1,
        'get_relationship_DescribesMeasurement' => 1,
        'get_relationship_IsDefinedBy' => 1,
        'get_relationship_DescribesTree' => 1,
        'get_relationship_HasTreeAttribute' => 1,
        'get_relationship_DescribesTreeNode' => 1,
        'get_relationship_HasNodeAttribute' => 1,
        'get_relationship_DetectedWithMethod' => 1,
        'get_relationship_DetectedBy' => 1,
        'get_relationship_Displays' => 1,
        'get_relationship_IsDisplayedOn' => 1,
        'get_relationship_Encompasses' => 1,
        'get_relationship_IsEncompassedIn' => 1,
        'get_relationship_EvaluatedIn' => 1,
        'get_relationship_IncludesStrain' => 1,
        'get_relationship_FeatureIsTranscriptionFactorFor' => 1,
        'get_relationship_HasTranscriptionFactorFeature' => 1,
        'get_relationship_FeatureMeasuredBy' => 1,
        'get_relationship_MeasuresFeature' => 1,
        'get_relationship_Formulated' => 1,
        'get_relationship_WasFormulatedBy' => 1,
        'get_relationship_GeneratedLevelsFor' => 1,
        'get_relationship_WasGeneratedFrom' => 1,
        'get_relationship_GenomeParentOf' => 1,
        'get_relationship_DerivedFromGenome' => 1,
        'get_relationship_HasAliasAssertedFrom' => 1,
        'get_relationship_AssertsAliasFor' => 1,
        'get_relationship_HasCompoundAliasFrom' => 1,
        'get_relationship_UsesAliasForCompound' => 1,
        'get_relationship_HasEffector' => 1,
        'get_relationship_IsEffectorFor' => 1,
        'get_relationship_HasExperimentalUnit' => 1,
        'get_relationship_IsExperimentalUnitOf' => 1,
        'get_relationship_HasExpressionSample' => 1,
        'get_relationship_SampleBelongsToExperimentalUnit' => 1,
        'get_relationship_HasGenomes' => 1,
        'get_relationship_IsInRegulogCollection' => 1,
        'get_relationship_HasIndicatedSignalFrom' => 1,
        'get_relationship_IndicatesSignalFor' => 1,
        'get_relationship_HasKnockoutIn' => 1,
        'get_relationship_KnockedOutIn' => 1,
        'get_relationship_HasMeasurement' => 1,
        'get_relationship_IsMeasureOf' => 1,
        'get_relationship_HasMember' => 1,
        'get_relationship_IsMemberOf' => 1,
        'get_relationship_HasParameter' => 1,
        'get_relationship_OfEnvironment' => 1,
        'get_relationship_HasParticipant' => 1,
        'get_relationship_ParticipatesIn' => 1,
        'get_relationship_HasPresenceOf' => 1,
        'get_relationship_IsPresentIn' => 1,
        'get_relationship_HasProteinMember' => 1,
        'get_relationship_IsProteinMemberOf' => 1,
        'get_relationship_HasReactionAliasFrom' => 1,
        'get_relationship_UsesAliasForReaction' => 1,
        'get_relationship_HasRegulogs' => 1,
        'get_relationship_IsInCollection' => 1,
        'get_relationship_HasRepresentativeOf' => 1,
        'get_relationship_IsRepresentedIn' => 1,
        'get_relationship_HasRequirementOf' => 1,
        'get_relationship_IsARequirementOf' => 1,
        'get_relationship_HasResultsIn' => 1,
        'get_relationship_HasResultsFor' => 1,
        'get_relationship_HasSection' => 1,
        'get_relationship_IsSectionOf' => 1,
        'get_relationship_HasStep' => 1,
        'get_relationship_IsStepOf' => 1,
        'get_relationship_HasTrait' => 1,
        'get_relationship_Measures' => 1,
        'get_relationship_HasUnits' => 1,
        'get_relationship_IsLocated' => 1,
        'get_relationship_HasUsage' => 1,
        'get_relationship_IsUsageOf' => 1,
        'get_relationship_HasValueFor' => 1,
        'get_relationship_HasValueIn' => 1,
        'get_relationship_HasVariationIn' => 1,
        'get_relationship_IsVariedIn' => 1,
        'get_relationship_Impacts' => 1,
        'get_relationship_IsImpactedBy' => 1,
        'get_relationship_ImplementsReaction' => 1,
        'get_relationship_ImplementedBasedOn' => 1,
        'get_relationship_Includes' => 1,
        'get_relationship_IsIncludedIn' => 1,
        'get_relationship_IncludesAdditionalCompounds' => 1,
        'get_relationship_IncludedIn' => 1,
        'get_relationship_IncludesAlignmentRow' => 1,
        'get_relationship_IsAlignmentRowIn' => 1,
        'get_relationship_IncludesPart' => 1,
        'get_relationship_IsPartOf' => 1,
        'get_relationship_IndicatedLevelsFor' => 1,
        'get_relationship_HasLevelsFrom' => 1,
        'get_relationship_Involves' => 1,
        'get_relationship_IsInvolvedIn' => 1,
        'get_relationship_IsAnnotatedBy' => 1,
        'get_relationship_Annotates' => 1,
        'get_relationship_IsAssayOf' => 1,
        'get_relationship_IsAssayedBy' => 1,
        'get_relationship_IsClassFor' => 1,
        'get_relationship_IsInClass' => 1,
        'get_relationship_IsCollectionOf' => 1,
        'get_relationship_IsCollectedInto' => 1,
        'get_relationship_IsComposedOf' => 1,
        'get_relationship_IsComponentOf' => 1,
        'get_relationship_IsComprisedOf' => 1,
        'get_relationship_Comprises' => 1,
        'get_relationship_IsConfiguredBy' => 1,
        'get_relationship_ReflectsStateOf' => 1,
        'get_relationship_IsConservedDomainModelFor' => 1,
        'get_relationship_HasConservedDomainModel' => 1,
        'get_relationship_IsConsistentWith' => 1,
        'get_relationship_IsConsistentTo' => 1,
        'get_relationship_IsContextOf' => 1,
        'get_relationship_HasEnvironment' => 1,
        'get_relationship_IsCoregulatedWith' => 1,
        'get_relationship_HasCoregulationWith' => 1,
        'get_relationship_IsCoupledTo' => 1,
        'get_relationship_IsCoupledWith' => 1,
        'get_relationship_IsDatasetFor' => 1,
        'get_relationship_HasAssociationDataset' => 1,
        'get_relationship_IsDeterminedBy' => 1,
        'get_relationship_Determines' => 1,
        'get_relationship_IsDividedInto' => 1,
        'get_relationship_IsDivisionOf' => 1,
        'get_relationship_IsExecutedAs' => 1,
        'get_relationship_IsExecutionOf' => 1,
        'get_relationship_IsExemplarOf' => 1,
        'get_relationship_HasAsExemplar' => 1,
        'get_relationship_IsFamilyFor' => 1,
        'get_relationship_DeterminesFunctionOf' => 1,
        'get_relationship_IsFormedOf' => 1,
        'get_relationship_IsFormedInto' => 1,
        'get_relationship_IsFunctionalIn' => 1,
        'get_relationship_HasFunctional' => 1,
        'get_relationship_IsGroupFor' => 1,
        'get_relationship_IsInGroup' => 1,
        'get_relationship_IsGroupingOf' => 1,
        'get_relationship_InAssociationDataset' => 1,
        'get_relationship_IsImplementedBy' => 1,
        'get_relationship_Implements' => 1,
        'get_relationship_IsInOperon' => 1,
        'get_relationship_OperonContains' => 1,
        'get_relationship_IsInPair' => 1,
        'get_relationship_IsPairOf' => 1,
        'get_relationship_IsInstantiatedBy' => 1,
        'get_relationship_IsInstanceOf' => 1,
        'get_relationship_IsLocatedIn' => 1,
        'get_relationship_IsLocusFor' => 1,
        'get_relationship_IsMeasurementMethodOf' => 1,
        'get_relationship_WasMeasuredBy' => 1,
        'get_relationship_IsModeledBy' => 1,
        'get_relationship_Models' => 1,
        'get_relationship_IsModifiedToBuildAlignment' => 1,
        'get_relationship_IsModificationOfAlignment' => 1,
        'get_relationship_IsModifiedToBuildTree' => 1,
        'get_relationship_IsModificationOfTree' => 1,
        'get_relationship_IsOwnerOf' => 1,
        'get_relationship_IsOwnedBy' => 1,
        'get_relationship_IsParticipatingAt' => 1,
        'get_relationship_ParticipatesAt' => 1,
        'get_relationship_IsProteinFor' => 1,
        'get_relationship_Produces' => 1,
        'get_relationship_IsReagentIn' => 1,
        'get_relationship_Targets' => 1,
        'get_relationship_IsRealLocationOf' => 1,
        'get_relationship_HasRealLocationIn' => 1,
        'get_relationship_IsReferencedBy' => 1,
        'get_relationship_UsesReference' => 1,
        'get_relationship_IsRegulatedIn' => 1,
        'get_relationship_IsRegulatedSetOf' => 1,
        'get_relationship_IsRegulatorFor' => 1,
        'get_relationship_HasRegulator' => 1,
        'get_relationship_IsRegulatorForRegulon' => 1,
        'get_relationship_ReglonHasRegulator' => 1,
        'get_relationship_IsRegulatorySiteFor' => 1,
        'get_relationship_HasRegulatorySite' => 1,
        'get_relationship_IsRelevantFor' => 1,
        'get_relationship_IsRelevantTo' => 1,
        'get_relationship_IsRepresentedBy' => 1,
        'get_relationship_DefinedBy' => 1,
        'get_relationship_IsRoleOf' => 1,
        'get_relationship_HasRole' => 1,
        'get_relationship_IsRowOf' => 1,
        'get_relationship_IsRoleFor' => 1,
        'get_relationship_IsSequenceOf' => 1,
        'get_relationship_HasAsSequence' => 1,
        'get_relationship_IsSourceForAssociationDataset' => 1,
        'get_relationship_AssociationDatasetSourcedBy' => 1,
        'get_relationship_IsSubInstanceOf' => 1,
        'get_relationship_Validates' => 1,
        'get_relationship_IsSummarizedBy' => 1,
        'get_relationship_Summarizes' => 1,
        'get_relationship_IsSuperclassOf' => 1,
        'get_relationship_IsSubclassOf' => 1,
        'get_relationship_IsTaxonomyOf' => 1,
        'get_relationship_IsInTaxa' => 1,
        'get_relationship_IsTerminusFor' => 1,
        'get_relationship_HasAsTerminus' => 1,
        'get_relationship_IsTriggeredBy' => 1,
        'get_relationship_Triggers' => 1,
        'get_relationship_IsUsedToBuildTree' => 1,
        'get_relationship_IsBuiltFromAlignment' => 1,
        'get_relationship_Manages' => 1,
        'get_relationship_IsManagedBy' => 1,
        'get_relationship_OntologyForSample' => 1,
        'get_relationship_SampleHasOntology' => 1,
        'get_relationship_OperatesIn' => 1,
        'get_relationship_IsUtilizedIn' => 1,
        'get_relationship_OrdersExperimentalUnit' => 1,
        'get_relationship_IsTimepointOf' => 1,
        'get_relationship_Overlaps' => 1,
        'get_relationship_IncludesPartOf' => 1,
        'get_relationship_ParticipatesAs' => 1,
        'get_relationship_IsParticipationOf' => 1,
        'get_relationship_PerformedExperiment' => 1,
        'get_relationship_PerformedBy' => 1,
        'get_relationship_PersonAnnotatedSample' => 1,
        'get_relationship_SampleAnnotatedBy' => 1,
        'get_relationship_PlatformWithSamples' => 1,
        'get_relationship_SampleRunOnPlatform' => 1,
        'get_relationship_ProducedResultsFor' => 1,
        'get_relationship_HadResultsProducedBy' => 1,
        'get_relationship_ProtocolForSample' => 1,
        'get_relationship_SampleUsesProtocol' => 1,
        'get_relationship_Provided' => 1,
        'get_relationship_WasProvidedBy' => 1,
        'get_relationship_PublishedAssociation' => 1,
        'get_relationship_AssociationPublishedIn' => 1,
        'get_relationship_PublishedExperiment' => 1,
        'get_relationship_ExperimentPublishedIn' => 1,
        'get_relationship_PublishedProtocol' => 1,
        'get_relationship_ProtocolPublishedIn' => 1,
        'get_relationship_RegulogHasRegulon' => 1,
        'get_relationship_RegulonIsInRegolog' => 1,
        'get_relationship_RegulomeHasGenome' => 1,
        'get_relationship_GenomeIsInRegulome' => 1,
        'get_relationship_RegulomeHasRegulon' => 1,
        'get_relationship_RegulonIsInRegolome' => 1,
        'get_relationship_RegulomeSource' => 1,
        'get_relationship_CreatedRegulome' => 1,
        'get_relationship_RegulonHasOperon' => 1,
        'get_relationship_OperonIsInRegulon' => 1,
        'get_relationship_SampleAveragedFrom' => 1,
        'get_relationship_SampleComponentOf' => 1,
        'get_relationship_SampleContactPerson' => 1,
        'get_relationship_PersonPerformedSample' => 1,
        'get_relationship_SampleHasAnnotations' => 1,
        'get_relationship_AnnotationsForSample' => 1,
        'get_relationship_SampleInSeries' => 1,
        'get_relationship_SeriesWithSamples' => 1,
        'get_relationship_SampleMeasurements' => 1,
        'get_relationship_MeasurementInSample' => 1,
        'get_relationship_SamplesInReplicateGroup' => 1,
        'get_relationship_ReplicateGroupsForSample' => 1,
        'get_relationship_SeriesPublishedIn' => 1,
        'get_relationship_PublicationsForSeries' => 1,
        'get_relationship_Shows' => 1,
        'get_relationship_IsShownOn' => 1,
        'get_relationship_StrainParentOf' => 1,
        'get_relationship_DerivedFromStrain' => 1,
        'get_relationship_StrainWithPlatforms' => 1,
        'get_relationship_PlatformForStrain' => 1,
        'get_relationship_StrainWithSample' => 1,
        'get_relationship_SampleForStrain' => 1,
        'get_relationship_Submitted' => 1,
        'get_relationship_WasSubmittedBy' => 1,
        'get_relationship_SupersedesAlignment' => 1,
        'get_relationship_IsSupersededByAlignment' => 1,
        'get_relationship_SupersedesTree' => 1,
        'get_relationship_IsSupersededByTree' => 1,
        'get_relationship_Treed' => 1,
        'get_relationship_IsTreeFrom' => 1,
        'get_relationship_UsedIn' => 1,
        'get_relationship_HasMedia' => 1,
        'get_relationship_Uses' => 1,
        'get_relationship_IsUsedBy' => 1,
        'get_relationship_UsesCodons' => 1,
        'get_relationship_AreCodonsFor' => 1,
        'version' => 1,
);



sub _build_valid_methods
{
    my($self) = @_;
    my $methods = {
        'fids_to_annotations' => 1,
        'fids_to_functions' => 1,
        'fids_to_literature' => 1,
        'fids_to_protein_families' => 1,
        'fids_to_roles' => 1,
        'fids_to_subsystems' => 1,
        'fids_to_co_occurring_fids' => 1,
        'fids_to_locations' => 1,
        'locations_to_fids' => 1,
        'alleles_to_bp_locs' => 1,
        'region_to_fids' => 1,
        'region_to_alleles' => 1,
        'alleles_to_traits' => 1,
        'traits_to_alleles' => 1,
        'ous_with_trait' => 1,
        'locations_to_dna_sequences' => 1,
        'proteins_to_fids' => 1,
        'proteins_to_protein_families' => 1,
        'proteins_to_literature' => 1,
        'proteins_to_functions' => 1,
        'proteins_to_roles' => 1,
        'roles_to_proteins' => 1,
        'roles_to_subsystems' => 1,
        'roles_to_protein_families' => 1,
        'fids_to_coexpressed_fids' => 1,
        'protein_families_to_fids' => 1,
        'protein_families_to_proteins' => 1,
        'protein_families_to_functions' => 1,
        'protein_families_to_co_occurring_families' => 1,
        'co_occurrence_evidence' => 1,
        'contigs_to_sequences' => 1,
        'contigs_to_lengths' => 1,
        'contigs_to_md5s' => 1,
        'md5s_to_genomes' => 1,
        'genomes_to_md5s' => 1,
        'genomes_to_contigs' => 1,
        'genomes_to_fids' => 1,
        'genomes_to_taxonomies' => 1,
        'genomes_to_subsystems' => 1,
        'subsystems_to_genomes' => 1,
        'subsystems_to_fids' => 1,
        'subsystems_to_roles' => 1,
        'subsystems_to_spreadsheets' => 1,
        'all_roles_used_in_models' => 1,
        'complexes_to_complex_data' => 1,
        'genomes_to_genome_data' => 1,
        'fids_to_regulon_data' => 1,
        'regulons_to_fids' => 1,
        'fids_to_feature_data' => 1,
        'equiv_sequence_assertions' => 1,
        'fids_to_atomic_regulons' => 1,
        'atomic_regulons_to_fids' => 1,
        'fids_to_protein_sequences' => 1,
        'fids_to_proteins' => 1,
        'fids_to_dna_sequences' => 1,
        'roles_to_fids' => 1,
        'reactions_to_complexes' => 1,
        'aliases_to_fids' => 1,
        'aliases_to_fids_by_source' => 1,
        'source_ids_to_fids' => 1,
        'external_ids_to_fids' => 1,
        'reaction_strings' => 1,
        'roles_to_complexes' => 1,
        'complexes_to_roles' => 1,
        'fids_to_subsystem_data' => 1,
        'representative' => 1,
        'otu_members' => 1,
        'otus_to_representatives' => 1,
        'fids_to_genomes' => 1,
        'text_search' => 1,
        'corresponds' => 1,
        'corresponds_from_sequences' => 1,
        'close_genomes' => 1,
        'representative_sequences' => 1,
        'align_sequences' => 1,
        'build_tree' => 1,
        'alignment_by_id' => 1,
        'tree_by_id' => 1,
        'all_entities' => 1,
        'all_relationships' => 1,
        'get_entity' => 1,
        'get_relationship' => 1,
        'get_all' => 1,
        'get_entity_Alignment' => 1,
        'query_entity_Alignment' => 1,
        'all_entities_Alignment' => 1,
        'get_entity_AlignmentAttribute' => 1,
        'query_entity_AlignmentAttribute' => 1,
        'all_entities_AlignmentAttribute' => 1,
        'get_entity_AlignmentRow' => 1,
        'query_entity_AlignmentRow' => 1,
        'all_entities_AlignmentRow' => 1,
        'get_entity_AlleleFrequency' => 1,
        'query_entity_AlleleFrequency' => 1,
        'all_entities_AlleleFrequency' => 1,
        'get_entity_Annotation' => 1,
        'query_entity_Annotation' => 1,
        'all_entities_Annotation' => 1,
        'get_entity_Assay' => 1,
        'query_entity_Assay' => 1,
        'all_entities_Assay' => 1,
        'get_entity_Association' => 1,
        'query_entity_Association' => 1,
        'all_entities_Association' => 1,
        'get_entity_AssociationDataset' => 1,
        'query_entity_AssociationDataset' => 1,
        'all_entities_AssociationDataset' => 1,
        'get_entity_AssociationDetectionType' => 1,
        'query_entity_AssociationDetectionType' => 1,
        'all_entities_AssociationDetectionType' => 1,
        'get_entity_AtomicRegulon' => 1,
        'query_entity_AtomicRegulon' => 1,
        'all_entities_AtomicRegulon' => 1,
        'get_entity_Attribute' => 1,
        'query_entity_Attribute' => 1,
        'all_entities_Attribute' => 1,
        'get_entity_Biomass' => 1,
        'query_entity_Biomass' => 1,
        'all_entities_Biomass' => 1,
        'get_entity_CodonUsage' => 1,
        'query_entity_CodonUsage' => 1,
        'all_entities_CodonUsage' => 1,
        'get_entity_Complex' => 1,
        'query_entity_Complex' => 1,
        'all_entities_Complex' => 1,
        'get_entity_Compound' => 1,
        'query_entity_Compound' => 1,
        'all_entities_Compound' => 1,
        'get_entity_CompoundInstance' => 1,
        'query_entity_CompoundInstance' => 1,
        'all_entities_CompoundInstance' => 1,
        'get_entity_ConservedDomainModel' => 1,
        'query_entity_ConservedDomainModel' => 1,
        'all_entities_ConservedDomainModel' => 1,
        'get_entity_Contig' => 1,
        'query_entity_Contig' => 1,
        'all_entities_Contig' => 1,
        'get_entity_ContigChunk' => 1,
        'query_entity_ContigChunk' => 1,
        'all_entities_ContigChunk' => 1,
        'get_entity_ContigSequence' => 1,
        'query_entity_ContigSequence' => 1,
        'all_entities_ContigSequence' => 1,
        'get_entity_CoregulatedSet' => 1,
        'query_entity_CoregulatedSet' => 1,
        'all_entities_CoregulatedSet' => 1,
        'get_entity_Diagram' => 1,
        'query_entity_Diagram' => 1,
        'all_entities_Diagram' => 1,
        'get_entity_EcNumber' => 1,
        'query_entity_EcNumber' => 1,
        'all_entities_EcNumber' => 1,
        'get_entity_Effector' => 1,
        'query_entity_Effector' => 1,
        'all_entities_Effector' => 1,
        'get_entity_Environment' => 1,
        'query_entity_Environment' => 1,
        'all_entities_Environment' => 1,
        'get_entity_Experiment' => 1,
        'query_entity_Experiment' => 1,
        'all_entities_Experiment' => 1,
        'get_entity_ExperimentMeta' => 1,
        'query_entity_ExperimentMeta' => 1,
        'all_entities_ExperimentMeta' => 1,
        'get_entity_ExperimentalUnit' => 1,
        'query_entity_ExperimentalUnit' => 1,
        'all_entities_ExperimentalUnit' => 1,
        'get_entity_ExperimentalUnitGroup' => 1,
        'query_entity_ExperimentalUnitGroup' => 1,
        'all_entities_ExperimentalUnitGroup' => 1,
        'get_entity_Family' => 1,
        'query_entity_Family' => 1,
        'all_entities_Family' => 1,
        'get_entity_Feature' => 1,
        'query_entity_Feature' => 1,
        'all_entities_Feature' => 1,
        'get_entity_Genome' => 1,
        'query_entity_Genome' => 1,
        'all_entities_Genome' => 1,
        'get_entity_Locality' => 1,
        'query_entity_Locality' => 1,
        'all_entities_Locality' => 1,
        'get_entity_LocalizedCompound' => 1,
        'query_entity_LocalizedCompound' => 1,
        'all_entities_LocalizedCompound' => 1,
        'get_entity_Location' => 1,
        'query_entity_Location' => 1,
        'all_entities_Location' => 1,
        'get_entity_LocationInstance' => 1,
        'query_entity_LocationInstance' => 1,
        'all_entities_LocationInstance' => 1,
        'get_entity_Measurement' => 1,
        'query_entity_Measurement' => 1,
        'all_entities_Measurement' => 1,
        'get_entity_MeasurementDescription' => 1,
        'query_entity_MeasurementDescription' => 1,
        'all_entities_MeasurementDescription' => 1,
        'get_entity_Media' => 1,
        'query_entity_Media' => 1,
        'all_entities_Media' => 1,
        'get_entity_Model' => 1,
        'query_entity_Model' => 1,
        'all_entities_Model' => 1,
        'get_entity_OTU' => 1,
        'query_entity_OTU' => 1,
        'all_entities_OTU' => 1,
        'get_entity_ObservationalUnit' => 1,
        'query_entity_ObservationalUnit' => 1,
        'all_entities_ObservationalUnit' => 1,
        'get_entity_Ontology' => 1,
        'query_entity_Ontology' => 1,
        'all_entities_Ontology' => 1,
        'get_entity_Operon' => 1,
        'query_entity_Operon' => 1,
        'all_entities_Operon' => 1,
        'get_entity_PairSet' => 1,
        'query_entity_PairSet' => 1,
        'all_entities_PairSet' => 1,
        'get_entity_Pairing' => 1,
        'query_entity_Pairing' => 1,
        'all_entities_Pairing' => 1,
        'get_entity_Parameter' => 1,
        'query_entity_Parameter' => 1,
        'all_entities_Parameter' => 1,
        'get_entity_Person' => 1,
        'query_entity_Person' => 1,
        'all_entities_Person' => 1,
        'get_entity_Platform' => 1,
        'query_entity_Platform' => 1,
        'all_entities_Platform' => 1,
        'get_entity_ProbeSet' => 1,
        'query_entity_ProbeSet' => 1,
        'all_entities_ProbeSet' => 1,
        'get_entity_ProteinSequence' => 1,
        'query_entity_ProteinSequence' => 1,
        'all_entities_ProteinSequence' => 1,
        'get_entity_Protocol' => 1,
        'query_entity_Protocol' => 1,
        'all_entities_Protocol' => 1,
        'get_entity_Publication' => 1,
        'query_entity_Publication' => 1,
        'all_entities_Publication' => 1,
        'get_entity_Reaction' => 1,
        'query_entity_Reaction' => 1,
        'all_entities_Reaction' => 1,
        'get_entity_ReactionInstance' => 1,
        'query_entity_ReactionInstance' => 1,
        'all_entities_ReactionInstance' => 1,
        'get_entity_Regulator' => 1,
        'query_entity_Regulator' => 1,
        'all_entities_Regulator' => 1,
        'get_entity_Regulog' => 1,
        'query_entity_Regulog' => 1,
        'all_entities_Regulog' => 1,
        'get_entity_RegulogCollection' => 1,
        'query_entity_RegulogCollection' => 1,
        'all_entities_RegulogCollection' => 1,
        'get_entity_Regulome' => 1,
        'query_entity_Regulome' => 1,
        'all_entities_Regulome' => 1,
        'get_entity_Regulon' => 1,
        'query_entity_Regulon' => 1,
        'all_entities_Regulon' => 1,
        'get_entity_ReplicateGroup' => 1,
        'query_entity_ReplicateGroup' => 1,
        'all_entities_ReplicateGroup' => 1,
        'get_entity_Role' => 1,
        'query_entity_Role' => 1,
        'all_entities_Role' => 1,
        'get_entity_SSCell' => 1,
        'query_entity_SSCell' => 1,
        'all_entities_SSCell' => 1,
        'get_entity_SSRow' => 1,
        'query_entity_SSRow' => 1,
        'all_entities_SSRow' => 1,
        'get_entity_Sample' => 1,
        'query_entity_Sample' => 1,
        'all_entities_Sample' => 1,
        'get_entity_SampleAnnotation' => 1,
        'query_entity_SampleAnnotation' => 1,
        'all_entities_SampleAnnotation' => 1,
        'get_entity_Scenario' => 1,
        'query_entity_Scenario' => 1,
        'all_entities_Scenario' => 1,
        'get_entity_Series' => 1,
        'query_entity_Series' => 1,
        'all_entities_Series' => 1,
        'get_entity_Source' => 1,
        'query_entity_Source' => 1,
        'all_entities_Source' => 1,
        'get_entity_Strain' => 1,
        'query_entity_Strain' => 1,
        'all_entities_Strain' => 1,
        'get_entity_StudyExperiment' => 1,
        'query_entity_StudyExperiment' => 1,
        'all_entities_StudyExperiment' => 1,
        'get_entity_Subsystem' => 1,
        'query_entity_Subsystem' => 1,
        'all_entities_Subsystem' => 1,
        'get_entity_SubsystemClass' => 1,
        'query_entity_SubsystemClass' => 1,
        'all_entities_SubsystemClass' => 1,
        'get_entity_TaxonomicGrouping' => 1,
        'query_entity_TaxonomicGrouping' => 1,
        'all_entities_TaxonomicGrouping' => 1,
        'get_entity_TimeSeries' => 1,
        'query_entity_TimeSeries' => 1,
        'all_entities_TimeSeries' => 1,
        'get_entity_Trait' => 1,
        'query_entity_Trait' => 1,
        'all_entities_Trait' => 1,
        'get_entity_Tree' => 1,
        'query_entity_Tree' => 1,
        'all_entities_Tree' => 1,
        'get_entity_TreeAttribute' => 1,
        'query_entity_TreeAttribute' => 1,
        'all_entities_TreeAttribute' => 1,
        'get_entity_TreeNodeAttribute' => 1,
        'query_entity_TreeNodeAttribute' => 1,
        'all_entities_TreeNodeAttribute' => 1,
        'get_entity_Variant' => 1,
        'query_entity_Variant' => 1,
        'all_entities_Variant' => 1,
        'get_relationship_AffectsLevelOf' => 1,
        'get_relationship_IsAffectedIn' => 1,
        'get_relationship_Aligned' => 1,
        'get_relationship_WasAlignedBy' => 1,
        'get_relationship_AssertsFunctionFor' => 1,
        'get_relationship_HasAssertedFunctionFrom' => 1,
        'get_relationship_AssociationFeature' => 1,
        'get_relationship_FeatureInteractsIn' => 1,
        'get_relationship_CompoundMeasuredBy' => 1,
        'get_relationship_MeasuresCompound' => 1,
        'get_relationship_Concerns' => 1,
        'get_relationship_IsATopicOf' => 1,
        'get_relationship_ConsistsOfCompounds' => 1,
        'get_relationship_ComponentOf' => 1,
        'get_relationship_Contains' => 1,
        'get_relationship_IsContainedIn' => 1,
        'get_relationship_ContainsAlignedDNA' => 1,
        'get_relationship_IsAlignedDNAComponentOf' => 1,
        'get_relationship_ContainsAlignedProtein' => 1,
        'get_relationship_IsAlignedProteinComponentOf' => 1,
        'get_relationship_ContainsExperimentalUnit' => 1,
        'get_relationship_GroupedBy' => 1,
        'get_relationship_Controls' => 1,
        'get_relationship_IsControlledUsing' => 1,
        'get_relationship_DefaultControlSample' => 1,
        'get_relationship_SamplesDefaultControl' => 1,
        'get_relationship_Describes' => 1,
        'get_relationship_IsDescribedBy' => 1,
        'get_relationship_DescribesAlignment' => 1,
        'get_relationship_HasAlignmentAttribute' => 1,
        'get_relationship_DescribesMeasurement' => 1,
        'get_relationship_IsDefinedBy' => 1,
        'get_relationship_DescribesTree' => 1,
        'get_relationship_HasTreeAttribute' => 1,
        'get_relationship_DescribesTreeNode' => 1,
        'get_relationship_HasNodeAttribute' => 1,
        'get_relationship_DetectedWithMethod' => 1,
        'get_relationship_DetectedBy' => 1,
        'get_relationship_Displays' => 1,
        'get_relationship_IsDisplayedOn' => 1,
        'get_relationship_Encompasses' => 1,
        'get_relationship_IsEncompassedIn' => 1,
        'get_relationship_EvaluatedIn' => 1,
        'get_relationship_IncludesStrain' => 1,
        'get_relationship_FeatureIsTranscriptionFactorFor' => 1,
        'get_relationship_HasTranscriptionFactorFeature' => 1,
        'get_relationship_FeatureMeasuredBy' => 1,
        'get_relationship_MeasuresFeature' => 1,
        'get_relationship_Formulated' => 1,
        'get_relationship_WasFormulatedBy' => 1,
        'get_relationship_GeneratedLevelsFor' => 1,
        'get_relationship_WasGeneratedFrom' => 1,
        'get_relationship_GenomeParentOf' => 1,
        'get_relationship_DerivedFromGenome' => 1,
        'get_relationship_HasAliasAssertedFrom' => 1,
        'get_relationship_AssertsAliasFor' => 1,
        'get_relationship_HasCompoundAliasFrom' => 1,
        'get_relationship_UsesAliasForCompound' => 1,
        'get_relationship_HasEffector' => 1,
        'get_relationship_IsEffectorFor' => 1,
        'get_relationship_HasExperimentalUnit' => 1,
        'get_relationship_IsExperimentalUnitOf' => 1,
        'get_relationship_HasExpressionSample' => 1,
        'get_relationship_SampleBelongsToExperimentalUnit' => 1,
        'get_relationship_HasGenomes' => 1,
        'get_relationship_IsInRegulogCollection' => 1,
        'get_relationship_HasIndicatedSignalFrom' => 1,
        'get_relationship_IndicatesSignalFor' => 1,
        'get_relationship_HasKnockoutIn' => 1,
        'get_relationship_KnockedOutIn' => 1,
        'get_relationship_HasMeasurement' => 1,
        'get_relationship_IsMeasureOf' => 1,
        'get_relationship_HasMember' => 1,
        'get_relationship_IsMemberOf' => 1,
        'get_relationship_HasParameter' => 1,
        'get_relationship_OfEnvironment' => 1,
        'get_relationship_HasParticipant' => 1,
        'get_relationship_ParticipatesIn' => 1,
        'get_relationship_HasPresenceOf' => 1,
        'get_relationship_IsPresentIn' => 1,
        'get_relationship_HasProteinMember' => 1,
        'get_relationship_IsProteinMemberOf' => 1,
        'get_relationship_HasReactionAliasFrom' => 1,
        'get_relationship_UsesAliasForReaction' => 1,
        'get_relationship_HasRegulogs' => 1,
        'get_relationship_IsInCollection' => 1,
        'get_relationship_HasRepresentativeOf' => 1,
        'get_relationship_IsRepresentedIn' => 1,
        'get_relationship_HasRequirementOf' => 1,
        'get_relationship_IsARequirementOf' => 1,
        'get_relationship_HasResultsIn' => 1,
        'get_relationship_HasResultsFor' => 1,
        'get_relationship_HasSection' => 1,
        'get_relationship_IsSectionOf' => 1,
        'get_relationship_HasStep' => 1,
        'get_relationship_IsStepOf' => 1,
        'get_relationship_HasTrait' => 1,
        'get_relationship_Measures' => 1,
        'get_relationship_HasUnits' => 1,
        'get_relationship_IsLocated' => 1,
        'get_relationship_HasUsage' => 1,
        'get_relationship_IsUsageOf' => 1,
        'get_relationship_HasValueFor' => 1,
        'get_relationship_HasValueIn' => 1,
        'get_relationship_HasVariationIn' => 1,
        'get_relationship_IsVariedIn' => 1,
        'get_relationship_Impacts' => 1,
        'get_relationship_IsImpactedBy' => 1,
        'get_relationship_ImplementsReaction' => 1,
        'get_relationship_ImplementedBasedOn' => 1,
        'get_relationship_Includes' => 1,
        'get_relationship_IsIncludedIn' => 1,
        'get_relationship_IncludesAdditionalCompounds' => 1,
        'get_relationship_IncludedIn' => 1,
        'get_relationship_IncludesAlignmentRow' => 1,
        'get_relationship_IsAlignmentRowIn' => 1,
        'get_relationship_IncludesPart' => 1,
        'get_relationship_IsPartOf' => 1,
        'get_relationship_IndicatedLevelsFor' => 1,
        'get_relationship_HasLevelsFrom' => 1,
        'get_relationship_Involves' => 1,
        'get_relationship_IsInvolvedIn' => 1,
        'get_relationship_IsAnnotatedBy' => 1,
        'get_relationship_Annotates' => 1,
        'get_relationship_IsAssayOf' => 1,
        'get_relationship_IsAssayedBy' => 1,
        'get_relationship_IsClassFor' => 1,
        'get_relationship_IsInClass' => 1,
        'get_relationship_IsCollectionOf' => 1,
        'get_relationship_IsCollectedInto' => 1,
        'get_relationship_IsComposedOf' => 1,
        'get_relationship_IsComponentOf' => 1,
        'get_relationship_IsComprisedOf' => 1,
        'get_relationship_Comprises' => 1,
        'get_relationship_IsConfiguredBy' => 1,
        'get_relationship_ReflectsStateOf' => 1,
        'get_relationship_IsConservedDomainModelFor' => 1,
        'get_relationship_HasConservedDomainModel' => 1,
        'get_relationship_IsConsistentWith' => 1,
        'get_relationship_IsConsistentTo' => 1,
        'get_relationship_IsContextOf' => 1,
        'get_relationship_HasEnvironment' => 1,
        'get_relationship_IsCoregulatedWith' => 1,
        'get_relationship_HasCoregulationWith' => 1,
        'get_relationship_IsCoupledTo' => 1,
        'get_relationship_IsCoupledWith' => 1,
        'get_relationship_IsDatasetFor' => 1,
        'get_relationship_HasAssociationDataset' => 1,
        'get_relationship_IsDeterminedBy' => 1,
        'get_relationship_Determines' => 1,
        'get_relationship_IsDividedInto' => 1,
        'get_relationship_IsDivisionOf' => 1,
        'get_relationship_IsExecutedAs' => 1,
        'get_relationship_IsExecutionOf' => 1,
        'get_relationship_IsExemplarOf' => 1,
        'get_relationship_HasAsExemplar' => 1,
        'get_relationship_IsFamilyFor' => 1,
        'get_relationship_DeterminesFunctionOf' => 1,
        'get_relationship_IsFormedOf' => 1,
        'get_relationship_IsFormedInto' => 1,
        'get_relationship_IsFunctionalIn' => 1,
        'get_relationship_HasFunctional' => 1,
        'get_relationship_IsGroupFor' => 1,
        'get_relationship_IsInGroup' => 1,
        'get_relationship_IsGroupingOf' => 1,
        'get_relationship_InAssociationDataset' => 1,
        'get_relationship_IsImplementedBy' => 1,
        'get_relationship_Implements' => 1,
        'get_relationship_IsInOperon' => 1,
        'get_relationship_OperonContains' => 1,
        'get_relationship_IsInPair' => 1,
        'get_relationship_IsPairOf' => 1,
        'get_relationship_IsInstantiatedBy' => 1,
        'get_relationship_IsInstanceOf' => 1,
        'get_relationship_IsLocatedIn' => 1,
        'get_relationship_IsLocusFor' => 1,
        'get_relationship_IsMeasurementMethodOf' => 1,
        'get_relationship_WasMeasuredBy' => 1,
        'get_relationship_IsModeledBy' => 1,
        'get_relationship_Models' => 1,
        'get_relationship_IsModifiedToBuildAlignment' => 1,
        'get_relationship_IsModificationOfAlignment' => 1,
        'get_relationship_IsModifiedToBuildTree' => 1,
        'get_relationship_IsModificationOfTree' => 1,
        'get_relationship_IsOwnerOf' => 1,
        'get_relationship_IsOwnedBy' => 1,
        'get_relationship_IsParticipatingAt' => 1,
        'get_relationship_ParticipatesAt' => 1,
        'get_relationship_IsProteinFor' => 1,
        'get_relationship_Produces' => 1,
        'get_relationship_IsReagentIn' => 1,
        'get_relationship_Targets' => 1,
        'get_relationship_IsRealLocationOf' => 1,
        'get_relationship_HasRealLocationIn' => 1,
        'get_relationship_IsReferencedBy' => 1,
        'get_relationship_UsesReference' => 1,
        'get_relationship_IsRegulatedIn' => 1,
        'get_relationship_IsRegulatedSetOf' => 1,
        'get_relationship_IsRegulatorFor' => 1,
        'get_relationship_HasRegulator' => 1,
        'get_relationship_IsRegulatorForRegulon' => 1,
        'get_relationship_ReglonHasRegulator' => 1,
        'get_relationship_IsRegulatorySiteFor' => 1,
        'get_relationship_HasRegulatorySite' => 1,
        'get_relationship_IsRelevantFor' => 1,
        'get_relationship_IsRelevantTo' => 1,
        'get_relationship_IsRepresentedBy' => 1,
        'get_relationship_DefinedBy' => 1,
        'get_relationship_IsRoleOf' => 1,
        'get_relationship_HasRole' => 1,
        'get_relationship_IsRowOf' => 1,
        'get_relationship_IsRoleFor' => 1,
        'get_relationship_IsSequenceOf' => 1,
        'get_relationship_HasAsSequence' => 1,
        'get_relationship_IsSourceForAssociationDataset' => 1,
        'get_relationship_AssociationDatasetSourcedBy' => 1,
        'get_relationship_IsSubInstanceOf' => 1,
        'get_relationship_Validates' => 1,
        'get_relationship_IsSummarizedBy' => 1,
        'get_relationship_Summarizes' => 1,
        'get_relationship_IsSuperclassOf' => 1,
        'get_relationship_IsSubclassOf' => 1,
        'get_relationship_IsTaxonomyOf' => 1,
        'get_relationship_IsInTaxa' => 1,
        'get_relationship_IsTerminusFor' => 1,
        'get_relationship_HasAsTerminus' => 1,
        'get_relationship_IsTriggeredBy' => 1,
        'get_relationship_Triggers' => 1,
        'get_relationship_IsUsedToBuildTree' => 1,
        'get_relationship_IsBuiltFromAlignment' => 1,
        'get_relationship_Manages' => 1,
        'get_relationship_IsManagedBy' => 1,
        'get_relationship_OntologyForSample' => 1,
        'get_relationship_SampleHasOntology' => 1,
        'get_relationship_OperatesIn' => 1,
        'get_relationship_IsUtilizedIn' => 1,
        'get_relationship_OrdersExperimentalUnit' => 1,
        'get_relationship_IsTimepointOf' => 1,
        'get_relationship_Overlaps' => 1,
        'get_relationship_IncludesPartOf' => 1,
        'get_relationship_ParticipatesAs' => 1,
        'get_relationship_IsParticipationOf' => 1,
        'get_relationship_PerformedExperiment' => 1,
        'get_relationship_PerformedBy' => 1,
        'get_relationship_PersonAnnotatedSample' => 1,
        'get_relationship_SampleAnnotatedBy' => 1,
        'get_relationship_PlatformWithSamples' => 1,
        'get_relationship_SampleRunOnPlatform' => 1,
        'get_relationship_ProducedResultsFor' => 1,
        'get_relationship_HadResultsProducedBy' => 1,
        'get_relationship_ProtocolForSample' => 1,
        'get_relationship_SampleUsesProtocol' => 1,
        'get_relationship_Provided' => 1,
        'get_relationship_WasProvidedBy' => 1,
        'get_relationship_PublishedAssociation' => 1,
        'get_relationship_AssociationPublishedIn' => 1,
        'get_relationship_PublishedExperiment' => 1,
        'get_relationship_ExperimentPublishedIn' => 1,
        'get_relationship_PublishedProtocol' => 1,
        'get_relationship_ProtocolPublishedIn' => 1,
        'get_relationship_RegulogHasRegulon' => 1,
        'get_relationship_RegulonIsInRegolog' => 1,
        'get_relationship_RegulomeHasGenome' => 1,
        'get_relationship_GenomeIsInRegulome' => 1,
        'get_relationship_RegulomeHasRegulon' => 1,
        'get_relationship_RegulonIsInRegolome' => 1,
        'get_relationship_RegulomeSource' => 1,
        'get_relationship_CreatedRegulome' => 1,
        'get_relationship_RegulonHasOperon' => 1,
        'get_relationship_OperonIsInRegulon' => 1,
        'get_relationship_SampleAveragedFrom' => 1,
        'get_relationship_SampleComponentOf' => 1,
        'get_relationship_SampleContactPerson' => 1,
        'get_relationship_PersonPerformedSample' => 1,
        'get_relationship_SampleHasAnnotations' => 1,
        'get_relationship_AnnotationsForSample' => 1,
        'get_relationship_SampleInSeries' => 1,
        'get_relationship_SeriesWithSamples' => 1,
        'get_relationship_SampleMeasurements' => 1,
        'get_relationship_MeasurementInSample' => 1,
        'get_relationship_SamplesInReplicateGroup' => 1,
        'get_relationship_ReplicateGroupsForSample' => 1,
        'get_relationship_SeriesPublishedIn' => 1,
        'get_relationship_PublicationsForSeries' => 1,
        'get_relationship_Shows' => 1,
        'get_relationship_IsShownOn' => 1,
        'get_relationship_StrainParentOf' => 1,
        'get_relationship_DerivedFromStrain' => 1,
        'get_relationship_StrainWithPlatforms' => 1,
        'get_relationship_PlatformForStrain' => 1,
        'get_relationship_StrainWithSample' => 1,
        'get_relationship_SampleForStrain' => 1,
        'get_relationship_Submitted' => 1,
        'get_relationship_WasSubmittedBy' => 1,
        'get_relationship_SupersedesAlignment' => 1,
        'get_relationship_IsSupersededByAlignment' => 1,
        'get_relationship_SupersedesTree' => 1,
        'get_relationship_IsSupersededByTree' => 1,
        'get_relationship_Treed' => 1,
        'get_relationship_IsTreeFrom' => 1,
        'get_relationship_UsedIn' => 1,
        'get_relationship_HasMedia' => 1,
        'get_relationship_Uses' => 1,
        'get_relationship_IsUsedBy' => 1,
        'get_relationship_UsesCodons' => 1,
        'get_relationship_AreCodonsFor' => 1,
        'version' => 1,
    };
    return $methods;
}

my $DEPLOY = 'KB_DEPLOYMENT_CONFIG';
my $SERVICE = 'KB_SERVICE_NAME';

sub get_config_file
{
    my ($self) = @_;
    if(!defined $ENV{$DEPLOY}) {
        return undef;
    }
    return $ENV{$DEPLOY};
}

sub get_service_name
{
    my ($self) = @_;
    if(!defined $ENV{$SERVICE}) {
        return undef;
    }
    return $ENV{$SERVICE};
}

sub logcallback
{
    my ($self) = @_;
    $self->loggers()->{serverlog}->set_log_file(
        $self->{loggers}->{userlog}->get_log_file());
}

sub log
{
    my ($self, $level, $context, $message) = @_;
    my $user = defined($context->user_id()) ? $context->user_id(): undef; 
    $self->loggers()->{serverlog}->log_message($level, $message, $user, 
        $context->module(), $context->method(), $context->call_id(),
        $context->client_ip());
}

sub _build_loggers
{
    my ($self) = @_;
    my $submod = $self->get_service_name() || 'CDMI_API';
    my $loggers = {};
    my $callback = sub {$self->logcallback();};
    $loggers->{userlog} = Bio::KBase::Log->new(
            $submod, {}, {ip_address => 1, authuser => 1, module => 1,
            method => 1, call_id => 1, changecallback => $callback,
            config => $self->get_config_file()});
    $loggers->{serverlog} = Bio::KBase::Log->new(
            $submod, {}, {ip_address => 1, authuser => 1, module => 1,
            method => 1, call_id => 1,
            logfile => $loggers->{userlog}->get_log_file()});
    $loggers->{serverlog}->set_log_level(6);
    return $loggers;
}

#override of RPC::Any::Server
sub handle_error {
    my ($self, $error) = @_;
    
    unless (ref($error) eq 'HASH' ||
           (blessed $error and $error->isa('RPC::Any::Exception'))) {
        $error = RPC::Any::Exception::PerlError->new(message => $error);
    }
    my $output;
    eval {
        my $encoded_error = $self->encode_output_from_exception($error);
        $output = $self->produce_output($encoded_error);
    };
    
    return $output if $output;
    
    die "$error\n\nAlso, an error was encountered while trying to send"
        . " this error: $@\n";
}

#override of RPC::Any::JSONRPC
sub encode_output_from_exception {
    my ($self, $exception) = @_;
    my %error_params;
    if (ref($exception) eq 'HASH') {
        %error_params = %{$exception};
        if(defined($error_params{context})) {
            my @errlines;
            $errlines[0] = $error_params{message};
            push @errlines, split("\n", $error_params{data});
            $self->log($Bio::KBase::Log::ERR, $error_params{context}, \@errlines);
            delete $error_params{context};
        }
    } else {
        %error_params = (
            message => $exception->message,
            code    => $exception->code,
        );
    }
    my $json_error;
    if ($self->_last_call) {
        $json_error = $self->_last_call->return_error(%error_params);
    }
    # Default to default_version. This happens when we throw an exception
    # before inbound parsing is complete.
    else {
        $json_error = $self->_default_error(%error_params);
    }
    return $self->encode_output_from_object($json_error);
}

sub call_method {
    my ($self, $data, $method_info) = @_;

    my ($module, $method, $modname) = @$method_info{qw(module method modname)};
    
    my $ctx = Bio::KBase::CDMI::ServiceContext->new($self->{loggers}->{userlog},
                           client_ip => $self->_plack_req->address);
    $ctx->module($modname);
    $ctx->method($method);
    $ctx->call_id($self->{_last_call}->{id});
    
    my $args = $data->{arguments};

    # Service CDMI_API does not require authentication.
    my $new_isa = $self->get_package_isa($module);
    no strict 'refs';
    local @{"${module}::ISA"} = @$new_isa;
    local $CallContext = $ctx;
    my @result;
    {
        my $err;
        eval {
            $self->log($Bio::KBase::Log::INFO, $ctx, "start method");
            @result = $module->$method(@{ $data->{arguments} });
            $self->log($Bio::KBase::Log::INFO, $ctx, "end method");
        };
        if ($@)
        {
            my $err = $@;
            my $nicerr;
            if(ref($err) eq "Bio::KBase::Exceptions::KBaseException") {
                $nicerr = {code => -32603, # perl error from RPC::Any::Exception
                           message => $err->error,
                           data => $err->trace->as_string,
                           context => $ctx
                           };
            } else {
                my $str = "$err";
                $str =~ s/Bio::KBase::CDMI::Service::call_method.*//s; # is this still necessary? not sure
                my $msg = $str;
                $msg =~ s/ at [^\s]+.pm line \d+.\n$//;
                $nicerr =  {code => -32603, # perl error from RPC::Any::Exception
                            message => $msg,
                            data => $str,
                            context => $ctx
                            };
            }
            die $nicerr;
        }
    }
    my $result;
    if ($return_counts{$method} == 1)
    {
        $result = [[$result[0]]];
    }
    else
    {
        $result = \@result;
    }
    return $result;
}


sub get_method
{
    my ($self, $data) = @_;
    
    my $full_name = $data->{method};
    
    $full_name =~ /^(\S+)\.([^\.]+)$/;
    my ($package, $method) = ($1, $2);
    
    if (!$package || !$method) {
	$self->exception('NoSuchMethod',
			 "'$full_name' is not a valid method. It must"
			 . " contain a package name, followed by a period,"
			 . " followed by a method name.");
    }

    if (!$self->valid_methods->{$method})
    {
	$self->exception('NoSuchMethod',
			 "'$method' is not a valid method in service CDMI_API.");
    }
	
    my $inst = $self->instance_dispatch->{$package};
    my $module;
    if ($inst)
    {
	$module = $inst;
    }
    else
    {
	$module = $self->get_module($package);
	if (!$module) {
	    $self->exception('NoSuchMethod',
			     "There is no method package named '$package'.");
	}
	
	Class::MOP::load_class($module);
    }
    
    if (!$module->can($method)) {
	$self->exception('NoSuchMethod',
			 "There is no method named '$method' in the"
			 . " '$package' package.");
    }
    
    return { module => $module, method => $method, modname => $package };
}

package Bio::KBase::CDMI::ServiceContext;

use strict;

=head1 NAME

Bio::KBase::CDMI::ServiceContext

head1 DESCRIPTION

A KB RPC context contains information about the invoker of this
service. If it is an authenticated service the authenticated user
record is available via $context->user. The client IP address
is available via $context->client_ip.

=cut

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(user_id client_ip authenticated token
                             module method call_id));

sub new
{
    my($class, $logger, %opts) = @_;
    
    my $self = {
        %opts,
    };
    $self->{_logger} = $logger;
    $self->{_debug_levels} = {7 => 1, 8 => 1, 9 => 1,
                              'DEBUG' => 1, 'DEBUG2' => 1, 'DEBUG3' => 1};
    return bless $self, $class;
}

sub _get_user
{
    my ($self) = @_;
    return defined($self->user_id()) ? $self->user_id(): undef; 
}

sub _log
{
    my ($self, $level, $message) = @_;
    $self->{_logger}->log_message($level, $message, $self->_get_user(),
        $self->module(), $self->method(), $self->call_id(),
        $self->client_ip());
}

sub log_err
{
    my ($self, $message) = @_;
    $self->_log($Bio::KBase::Log::ERR, $message);
}

sub log_info
{
    my ($self, $message) = @_;
    $self->_log($Bio::KBase::Log::INFO, $message);
}

sub log_debug
{
    my ($self, $message, $level) = @_;
    if(!defined($level)) {
        $level = 1;
    }
    if($self->{_debug_levels}->{$level}) {
    } else {
        if ($level =~ /\D/ || $level < 1 || $level > 3) {
            die "Invalid log level: $level";
        }
        $level += 6;
    }
    $self->_log($level, $message);
}

sub set_log_level
{
    my ($self, $level) = @_;
    $self->{_logger}->set_log_level($level);
}

sub get_log_level
{
    my ($self) = @_;
    return $self->{_logger}->get_log_level();
}

sub clear_log_level
{
    my ($self) = @_;
    $self->{_logger}->clear_user_log_level();
}

1;
