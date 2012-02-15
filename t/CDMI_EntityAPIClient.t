use strict;
use warnings;
use Test::More;
use strict;
use Data::Dumper;
use Carp;
use CDMI_EntityAPIClient;

#  Test 1 - Is the object in the right class?
my $cdmie = CDMI_EntityAPIClient->new("http://140.221.92.46:5000");
ok( defined $cdmie, "Can the CDMI_EntityAPIClient be created?" );               
#  Test 2 - Is the object in the right class?
isa_ok( $cdmie, 'CDMI_EntityAPIClient', "Is it in the right class" );
#  Test 3 - Can object do all the methods?
can_ok($cdmie, qw[    
	get_entity_AlignmentTree
    all_entities_AlignmentTree
    get_entity_Annotation
    all_entities_Annotation
    get_entity_AtomicRegulon
    all_entities_AtomicRegulon
    get_entity_Attribute
    all_entities_Attribute
    get_entity_Biomass
    all_entities_Biomass
    get_entity_BiomassCompound
    all_entities_BiomassCompound
    get_entity_Compartment
    all_entities_Compartment
    get_entity_Complex
    all_entities_Complex
    get_entity_Compound
    all_entities_Compound
    get_entity_Contig
    all_entities_Contig
    get_entity_ContigChunk
    all_entities_ContigChunk
    get_entity_ContigSequence
    all_entities_ContigSequence
    get_entity_CoregulatedSet
    all_entities_CoregulatedSet
    get_entity_Diagram
    all_entities_Diagram
    get_entity_EcNumber
    all_entities_EcNumber
    get_entity_Experiment
    all_entities_Experiment
    get_entity_Family
    all_entities_Family
    get_entity_Feature
    all_entities_Feature
    get_entity_Genome
    all_entities_Genome
    get_entity_Identifier
    all_entities_Identifier
    get_entity_Media
    all_entities_Media
    get_entity_Model
    all_entities_Model
    get_entity_ModelCompartment
    all_entities_ModelCompartment
    get_entity_OTU
    all_entities_OTU
    get_entity_PairSet
    all_entities_PairSet
    get_entity_Pairing
    all_entities_Pairing
    get_entity_ProbeSet
    all_entities_ProbeSet
    get_entity_ProteinSequence
    all_entities_ProteinSequence
    get_entity_Publication
    all_entities_Publication
    get_entity_Reaction
    all_entities_Reaction
    get_entity_ReactionRule
    all_entities_ReactionRule
    get_entity_Reagent
    all_entities_Reagent
    get_entity_Requirement
    all_entities_Requirement
    get_entity_Role
    all_entities_Role
    get_entity_SSCell
    all_entities_SSCell
    get_entity_SSRow
    all_entities_SSRow
    get_entity_Scenario
    all_entities_Scenario
    get_entity_Source
    all_entities_Source
    get_entity_Subsystem
    all_entities_Subsystem
    get_entity_SubsystemClass
    all_entities_SubsystemClass
    get_entity_TaxonomicGrouping
    all_entities_TaxonomicGrouping
    get_entity_Variant
    all_entities_Variant
    get_entity_Variation
    all_entities_Variation
    get_relationship_AffectsLevelOf
    get_relationship_IsAffectedIn
    get_relationship_Aligns
    get_relationship_IsAlignedBy
    get_relationship_Concerns
    get_relationship_IsATopicOf
    get_relationship_Contains
    get_relationship_IsContainedIn
    get_relationship_Describes
    get_relationship_IsDescribedBy
    get_relationship_Displays
    get_relationship_IsDisplayedOn
    get_relationship_Encompasses
    get_relationship_IsEncompassedIn
    get_relationship_GeneratedLevelsFor
    get_relationship_WasGeneratedFrom
    get_relationship_HasAssertionFrom
    get_relationship_Asserts
    get_relationship_HasCompoundAliasFrom
    get_relationship_UsesAliasForCompound
    get_relationship_HasIndicatedSignalFrom
    get_relationship_IndicatesSignalFor
    get_relationship_HasMember
    get_relationship_IsMemberOf
    get_relationship_HasParticipant
    get_relationship_ParticipatesIn
    get_relationship_HasPresenceOf
    get_relationship_IsPresentIn
    get_relationship_HasReactionAliasFrom
    get_relationship_UsesAliasForReaction
    get_relationship_HasRepresentativeOf
    get_relationship_IsRepresentedIn
    get_relationship_HasResultsIn
    get_relationship_HasResultsFor
    get_relationship_HasSection
    get_relationship_IsSectionOf
    get_relationship_HasStep
    get_relationship_IsStepOf
    get_relationship_HasUsage
    get_relationship_IsUsageOf
    get_relationship_HasValueFor
    get_relationship_HasValueIn
    get_relationship_Includes
    get_relationship_IsIncludedIn
    get_relationship_IndicatedLevelsFor
    get_relationship_HasLevelsFrom
    get_relationship_Involves
    get_relationship_IsInvolvedIn
    get_relationship_IsARequirementIn
    get_relationship_IsARequirementOf
    get_relationship_IsAlignedIn
    get_relationship_IsAlignmentFor
    get_relationship_IsAnnotatedBy
    get_relationship_Annotates
    get_relationship_IsBindingSiteFor
    get_relationship_IsBoundBy
    get_relationship_IsClassFor
    get_relationship_IsInClass
    get_relationship_IsCollectionOf
    get_relationship_IsCollectedInto
    get_relationship_IsComposedOf
    get_relationship_IsComponentOf
    get_relationship_IsComprisedOf
    get_relationship_Comprises
    get_relationship_IsConfiguredBy
    get_relationship_ReflectsStateOf
    get_relationship_IsConsistentWith
    get_relationship_IsConsistentTo
    get_relationship_IsControlledUsing
    get_relationship_Controls
    get_relationship_IsCoregulatedWith
    get_relationship_HasCoregulationWith
    get_relationship_IsCoupledTo
    get_relationship_IsCoupledWith
    get_relationship_IsDefaultFor
    get_relationship_RunsByDefaultIn
    get_relationship_IsDefaultLocationOf
    get_relationship_HasDefaultLocation
    get_relationship_IsDeterminedBy
    get_relationship_Determines
    get_relationship_IsDividedInto
    get_relationship_IsDivisionOf
    get_relationship_IsExemplarOf
    get_relationship_HasAsExemplar
    get_relationship_IsFamilyFor
    get_relationship_DeterminesFunctionOf
    get_relationship_IsFormedOf
    get_relationship_IsFormedInto
    get_relationship_IsFunctionalIn
    get_relationship_HasFunctional
    get_relationship_IsGroupFor
    get_relationship_IsInGroup
    get_relationship_IsImplementedBy
    get_relationship_Implements
    get_relationship_IsInPair
    get_relationship_IsPairOf
    get_relationship_IsInstantiatedBy
    get_relationship_IsInstanceOf
    get_relationship_IsLocatedIn
    get_relationship_IsLocusFor
    get_relationship_IsModeledBy
    get_relationship_Models
    get_relationship_IsNamedBy
    get_relationship_Names
    get_relationship_IsOwnerOf
    get_relationship_IsOwnedBy
    get_relationship_IsProposedLocationOf
    get_relationship_HasProposedLocationIn
    get_relationship_IsProteinFor
    get_relationship_Produces
    get_relationship_IsRealLocationOf
    get_relationship_HasRealLocationIn
    get_relationship_IsRegulatedIn
    get_relationship_IsRegulatedSetOf
    get_relationship_IsRelevantFor
    get_relationship_IsRelevantTo
    get_relationship_IsRequiredBy
    get_relationship_Requires
    get_relationship_IsRoleOf
    get_relationship_HasRole
    get_relationship_IsRowOf
    get_relationship_IsRoleFor
    get_relationship_IsSequenceOf
    get_relationship_HasAsSequence
    get_relationship_IsSubInstanceOf
    get_relationship_Validates
    get_relationship_IsSuperclassOf
    get_relationship_IsSubclassOf
    get_relationship_IsTargetOf
    get_relationship_Targets
    get_relationship_IsTaxonomyOf
    get_relationship_IsInTaxa
    get_relationship_IsTerminusFor
    get_relationship_HasAsTerminus
    get_relationship_IsTriggeredBy
    get_relationship_Triggers
    get_relationship_IsUsedAs
    get_relationship_IsUseOf
    get_relationship_Manages
    get_relationship_IsManagedBy
    get_relationship_OperatesIn
    get_relationship_IsUtilizedIn
    get_relationship_Overlaps
    get_relationship_IncludesPartOf
    get_relationship_ParticipatesAs
    get_relationship_IsParticipationOf
    get_relationship_ProducedResultsFor
    get_relationship_HadResultsProducedBy
    get_relationship_ProjectsOnto
    get_relationship_IsProjectedOnto
    get_relationship_Provided
    get_relationship_WasProvidedBy
    get_relationship_Shows
    get_relationship_IsShownOn
    get_relationship_Submitted
    get_relationship_WasSubmittedBy
    get_relationship_Uses
    get_relationship_IsUsedBy
]);
#  ENTITY TESTS: First we create a list of all entities we want to test;
my $entities = [qw[    
	AlignmentTree
	Annotation
	AtomicRegulon
	Attribute
	Biomass
	BiomassCompound
	Compartment
	Complex
	Compound
	Contig
	ContigChunk
	ContigSequence
	CoregulatedSet
	Diagram
	EcNumber
	Experiment
	Family
	Feature
	Genome
	Identifier
	Media
	Model
	ModelCompartment
	OTU
	PairSet
	Pairing
	ProbeSet
	ProteinSequence
	Publication
	Reaction
	ReactionRule
	Reagent
	Requirement
	Role
	SSCell
	SSRow
	Scenario
	Source
	Subsystem
	SubsystemClass
	TaxonomicGrouping
	Variant
	Variation
]];
#  ENTITY TESTS: Now we test each entity one at a time;
my $entityResults;
for (my $i=0; $i < @{$entities}; $i++) {
	my $entity = $entities->[$i];
	print "Now testing etity: ".$entity."\n";
	my $function = "all_entities_".$entity;
	my $output;
	my $result = eval {
		$output = $cdmie->$function(0,10,["id"]);
		return 1;
	};
	#  Test 4 - Does the all_entities function run?
	ok( $result == 1, "Did all_entities_".$entity." successfully run?" );
	#  Test 5 - Does the all_entities function return results?
	ok( defined $output, "Does the all_entities_".$entity." call return results?" );
	$entityResults->{$entity}->{count} = keys(%{$output});
	if ($entityResults->{$entity}->{count} == 0) {
		print "No objects of type ".$entity." in database. No further tests of this object are possible.\n";
	} else {
		my $objectList = [keys(%{$output})];
		my $object = $output->{$objectList->[0]};
		#  Test 6 - Does the all_entities function return an "id" as requested?
		ok( defined $object->{id}, "Does all_entities_".$entity." return an id of the first object?" );
		my $result = eval {
			$function = "get_entity_".$entity;
			$output = $cdmie->$function([$object->{id}],["id"]);
			return 1;
		};
		#  Test 7 - Does the get_entity function run?
		ok( $result == 1, "Did get_entity_".$entity." successfully run?" );
		ok( defined $output->{$object->{id}}->{id}, "Does get_entity_".$entity." return an id of the first object?" );
	}
}