use strict;
use Data::Dumper;
use Carp;
use CDMI_APIClient;
use CDMI_EntityAPIClient;



#  Test 1 - Is the object in the right class?
my $cdmi = CDMI_APIClient->new("http://140.221.92.46:5000");
ok( defined $obj, "Can the CDMI_APIClient be created?" );               
#  Test 2 - Is the object in the right class?
isa_ok( $obj, 'CDMI_APIClient', "Is it in the right class" );
#  Test 3 - Can object do all the methods?
can_ok($obj, qw[    
	all_roles_used_in_models
    co_occurrence_evidence
    complexes_to_complex_data
    contigs_to_lengths
    contigs_to_md5s
    contigs_to_sequences
    equiv_sequence_assertions
    fids_to_annotations
    fids_to_co_occurring_fids
    fids_to_coexpressed_fids
    fids_to_dna_sequences
    fids_to_feature_data
    fids_to_functions
    fids_to_genomes
    fids_to_literature
    fids_to_locations
    fids_to_protein_families
    fids_to_protein_sequences
    fids_to_proteins
    fids_to_regulons
    fids_to_roles
    fids_to_subsystem_data
    fids_to_subsystems
    genomes_to_contigs
    genomes_to_fids
    genomes_to_md5s
    genomes_to_subsystems
    genomes_to_taxonomies
    locations_to_dna_sequences
    locations_to_fids
    md5s_to_genomes
    otu_members
    protein_families_to_co_occurring_families
    protein_families_to_fids
    protein_families_to_functions
    protein_families_to_proteins
    proteins_to_fids
    proteins_to_functions
    proteins_to_literature
    proteins_to_protein_families
    proteins_to_roles
    reaction_strings
    reactions_to_complexes
    regulons_to_fids
    representative
    roles_to_complexes
    roles_to_fids
    roles_to_protein_families
    roles_to_proteins
    roles_to_subsystems
    subsystems_to_fids
    subsystems_to_genomes
    subsystems_to_roles
    subsystems_to_spreadsheets
    text_search
]);
#  Test 1 - Is the object in the right class?
my $cdmi = CDMI_APIClient->new("http://140.221.92.46:5000");
ok( defined $obj, "Can the CDMI_APIClient be created?" );               
#  Test 2 - Is the object in the right class?
isa_ok( $obj, 'CDMI_APIClient', "Is it in the right class" );
#  Test 3 - Can object do all the methods?
can_ok($obj, qw[    
	all_roles_used_in_models
    co_occurrence_evidence
    complexes_to_complex_data
    contigs_to_lengths
    contigs_to_md5s
    contigs_to_sequences
    equiv_sequence_assertions
    fids_to_annotations
    fids_to_co_occurring_fids
    fids_to_coexpressed_fids
    fids_to_dna_sequences
    fids_to_feature_data
    fids_to_functions
    fids_to_genomes
    fids_to_literature
    fids_to_locations
    fids_to_protein_families
    fids_to_protein_sequences
    fids_to_proteins
    fids_to_regulons
    fids_to_roles
    fids_to_subsystem_data
    fids_to_subsystems
    genomes_to_contigs
    genomes_to_fids
    genomes_to_md5s
    genomes_to_subsystems
    genomes_to_taxonomies
    locations_to_dna_sequences
    locations_to_fids
    md5s_to_genomes
    otu_members
    protein_families_to_co_occurring_families
    protein_families_to_fids
    protein_families_to_functions
    protein_families_to_proteins
    proteins_to_fids
    proteins_to_functions
    proteins_to_literature
    proteins_to_protein_families
    proteins_to_roles
    reaction_strings
    reactions_to_complexes
    regulons_to_fids
    representative
    roles_to_complexes
    roles_to_fids
    roles_to_protein_families
    roles_to_proteins
    roles_to_subsystems
    subsystems_to_fids
    subsystems_to_genomes
    subsystems_to_roles
    subsystems_to_spreadsheets
    text_search
]);

my $cdmie = CDMI_EntityAPIClient->new("http://140.221.92.46:5000");

my $results = $cdmie->all_entities_Genome(0, 100, ["id"]);



$results = $cdmi->text_search("coli", 0, 100, []);
print STDOUT Data::Dumper->Dump([$results]);