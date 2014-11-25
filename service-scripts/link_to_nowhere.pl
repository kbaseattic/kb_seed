#!/usr/bin/perl -w
#-------------------------------------------------------------------
#
#	Description:	Test Relationship links for orphans
#						(links pointing to non-existant records)
#					List of relationships to test is defined manually
#
#-------------------------------------------------------------------

use DBI;
use strict;
use warnings;

my $ver = 4; 
my $db = "kbase_sapling_v$ver";
my $user = 'kbase_sapselect';
my $pass = 'oiwn22&dmwWEe';
my $host = "db$ver.chicago.kbase.us";

my $dbh = DBI->connect("dbi:mysql:database=$db;host=$host",$user,$pass)
	or die "Connection Error: $DBI::errstr\n";

open (OUT,">./Links.v$ver.dat") || die "Did not create Links.v$ver.dat";
print OUT "Relationship Table\tLink Type\tLinked Table\tField\tCount\tSQL\n" ;

#
#       Sets of Relationship : from_link table : to_link table
#       Grouped by image page on the ER diagram
#		This is to make it easier to verify that we have all the relationships
#       Comment out the ones that are not needed right now
#

my @test_Main = (
"IsProteinFor:ProteinSequence:Feature",
"Concerns:Publication:ProteinSequence",
"IsFunctionalIn:Role:Feature",
"IsLocatedIn:Feature:Contig",
"IsSequenceOf:ContigSequence:Contig",
"HasSection:ContigSequence:ContigChunk",
"HasAliasAssertedFrom:Feature:Source",
"Encompasses:Feature:Feature",
"IsOwnerOf:Genome:Feature",
"IsComposedOf:Genome:Contig",
"Submitted:Source:Genome",
"IsTaxonomyOf:TaxonomicGrouping:Genome",
"IsCollectionOf:OTU:Genome",
"IsGroupFor:TaxonomicGrouping:TaxonomicGrouping",
);

my @test_Chemistry = (
"Shows:Diagram:Compound",
"IsTerminusFor:Compound:Scenario",
"Displays:Diagram:Reaction",
"IsTriggeredBy:Complex:Role",
"IsConsistentWith:EcNumber:Role",
"HasParticipant:Scenario:Reaction",
"IsExemplarOf:Feature:Role",
"Overlaps:Scenario:Diagram",
"IsRelevantFor:Diagram:Subsystem",
"Includes:Subsystem:Role",
"IsSubInstanceOf:Subsystem:Scenario",
"IsClassFor:SubsystemClass:Subsystem",
"IsSuperclassOf:SubsystemClass:SubsystemClass",
);

my @test_Anno = (
"AssertsFunctionFor:Source:ProteinSequence",
"IsAnnotatedBy:Feature:Annotation",
"HasProteinMember:Family:ProteinSequence",
"IsInPair:Feature:Pairing",
"HasMember:Family:Feature",
"HasRepresentativeOf:Genome:Family",
"IsFamilyFor:Family:Role",
"IsDeterminedBy:PairSet:Pairing",
"IsCoupledTo:Family:Family",
);

my @test_Models = (
"IsInstantiatedBy:Location:LocationInstance",
"IsParticipatingAt:Location:LocalizedCompound",
"ParticipatesAs:Compound:LocalizedCompound",
"HasPresenceOf:Media:Compound",
"IsDividedInto:Model:LocationInstance",
"IsRealLocationOf:LocationInstance:CompoundInstance",
"HasUsage:LocalizedCompound:CompoundInstance",
"Involves:Reaction:LocalizedCompound",
"HasCompoundAliasFrom:Source:Compound",
"Manages:Model:Biomass",
"IsComprisedOf:Biomass:CompoundInstance",
"HasReactionAliasFrom:Source:Reaction",
"IsModeledBy:Genome:Model",
"HasRequirementOf:Model:ReactionInstance",
"IsReagentIn:CompoundInstance:ReactionInstance",
"IsExecutedAs:Reaction:ReactionInstance",
"HasStep:Complex:Reaction",
"ImplementsReaction:Feature:ReactionInstance",
);

my @test_Expression = (
"IsCoregulatedWith:Feature:Feature",
"IsFormedOf:AtomicRegulon:Feature",
"IndicatedLevelsFor:ProbeSet:Feature",
"ProducedResultsFor:ProbeSet:Genome",
"IsConfiguredBy:Genome:AtomicRegulon",
"IsRegulatedIn:Feature:CoregulatedSet",
"Controls:Feature:CoregulatedSet",
"HasIndicatedSignalFrom:Feature:Experiment",
"HasResultsIn:ProbeSet:Experiment",
"GeneratedLevelsFor:ProbeSet:AtomicRegulon",
"AffectsLevelOf:Experiment:AtomicRegulon",
"HasValueFor:Experiment:Attribute",
"OperatesIn:Experiment:Media", 
);

my @test_Align = (
"SupersedesAlignment:Alignment:Alignment",
"DescribesAlignment:AlignmentAttribute:Alignment",
"IncludesAlignmentRow:Alignment:AlignmentRow",
"Aligned:Source:Alignment",
"IsUsedToBuildTree:Alignment:Tree",
"IsModifiedToBuildAlignment:Alignment:Alignment",
"ContainsAlignedProtein:AlignmentRow:ProteinSequence",
"ContainsAlignedDNA:AlignmentRow:ContigSequence",
"Treed:Source:Tree",
"DescribesTree:TreeAttribute:Tree",
"IsModifiedToBuildTree:Tree:Tree",
"DescribesTreeNode:TreeNodeAttribute:Tree",
"SupersedesTree:Tree:Tree",
"UsesCodons:Genome:CodonUsage",
);

my @test_Subsystem = (
"Provided:Source:Subsystem",
"Includes:Subsystem:Role",
"IsRoleOf:Role:SSCell",
"Contains:SSCell:Feature",
"Describes:Subsystem:Variant",
"IsRowOf:SSRow:SSCell",
"IsImplementedBy:Variant:SSRow",
"Uses:Genome:SSRow",
);

my @test_GenoPheno = (
"IsSummarizedBy:Contig:AlleleFrequency",
"Impacts:Trait:Contig",
"HasVariationIn:Contig:ObservationalUnit:Contig",
"HasTrait:ObservationalUnit:Trait",
"IsReferencedBy:Genome:ObservationalUnit",
"IncludesPart:StudyExperiment:ObservationalUnit",
"IsAssayOf:Assay:StudyExperiment",
"IsRepresentedBy:TaxonomicGrouping:ObservationalUnit",
"HasUnits:Locality:ObservationalUnit",
);

my @test_MicrobePheno = (
#"BelongsTo:Strain:ExperimentalUnit",
"HasKnockoutIn:Strain:Feature",
#"DerivedFromStrain:Strain:Strain",
"GenomeParentOf:Genome:Strain",
#"PerformedExperiment:Person:PhenotypeExperiment",
#"HasExperimentalUnit:PhenotypeExperiment:ExperimentalUnit",
"HasMeasurement:ExperimentalUnit:Measurement",
#"UsedInExperimentalUnit:Environment:ExperimentalUnit",
#"UsedBy:Media:Environment",
#"PublishedExperiment:Publication:PhenotypeExperiment",
"IsMeasurementMethodOf:Protocol:Measurement",
#"HasAssociatedMeasurement:PhenotypeDescription:Measurement",
"IncludesAdditionalCompounds:Environment:Compound",
"ConsistsOfCompounds:Compound:Compound",
);

&test("MainLinks",@test_Main);
&test("ChemistryLinks",@test_Chemistry);
&test("AnnoLinks",@test_Anno);
&test("ModelsLinks",@test_Models);
&test("ExpressionLinks",@test_Expression);
&test("AlignLinks",@test_Align);
&test("SubsystemLinks",@test_Subsystem);
&test("GenoPhenoLinks",@test_GenoPheno);
&test("MicrobePhenoLinks",@test_MicrobePheno);

close OUT;

#
#	Set up the Relaationship : From_link : To_link tests
#
sub test
{
	my ($out,@tests) = @_;

	foreach my $test (@tests)
	{
		print "$out TEST=$test\n";
		my ($relationship,$from,$to) = split(/:/,$test);
		my $sql = "select distinct r.from_link from $relationship r where r.from_link not in (select id from $from);";
		&query($relationship,'from_link',$from,$sql);
	
		$sql = "select distinct r.to_link from $relationship r where r.to_link not in (select id from $to);";
		&query($relationship,'to_link',$to,$sql);
	}
}

#
#	Submit the query and output the results
#
sub query
{
	my ($table,$link_type,$link_table,$sql) = @_;
	my $sth = $dbh->prepare($sql);
	$sth->execute or die "SQL Error: $DBI::errstr\n";
		
	my $count = 0;
	while (my @row = $sth->fetchrow_array) 
	{
#		print "@row\n";
		$count++;
	}
	print OUT "$table\t$link_type\t$link_table\tid\t$count\t$sql\n" if ($count > 0);
}
