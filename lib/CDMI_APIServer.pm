package CDMI_APIServer;

use Data::Dumper;
use Moose;
use KBRpcContext;

extends 'RPC::Any::Server::JSONRPC::PSGI';

has 'instance_dispatch' => (is => 'ro', isa => 'HashRef');
has 'user_auth' => (is => 'ro', isa => 'UserAuth');
has 'valid_methods' => (is => 'ro', isa => 'HashRef', lazy => 1,
			builder => '_build_valid_methods');

our $CallContext;

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
        'complex_data' => 1,
        'equiv_sequence_assertions' => 1,
        'fids_to_regulons' => 1,
        'regulons_to_fids' => 1,
        'fids_to_protein_sequences' => 1,
        'fids_to_proteins' => 1,
        'fids_to_dna_sequences' => 1,
        'roles_to_fids' => 1,
        'reactions_to_complexes' => 1,
        'reaction_strings' => 1,
        'roles_to_complexes' => 1,
        'fids_to_subsystem_data' => 1,
        'representative' => 1,
        'otu_members' => 1,
        'text_search' => 1,
    };
    return $methods;
}

sub call_method {
    my ($self, $data, $method_info) = @_;
    my ($module, $method) = @$method_info{qw(module method)};
    
    my $ctx = KBRpcContext->new(client_ip => $self->_plack_req->address);
    
    my $args = $data->{arguments};
    if (@$args == 1 && ref($args->[0]) eq 'HASH')
    {
	my $actual_args = $args->[0]->{args};
	my $token = $args->[0]->{auth_token};
	$data->{arguments} = $actual_args;
	
	
        # Module CDMI_API does not require authentication.
	
    }
    
    my $new_isa = $self->get_package_isa($module);
    no strict 'refs';
    local @{"${module}::ISA"} = @$new_isa;
    local $CallContext = $ctx;
    my @result = $module->$method(@{ $data->{arguments} });
    return \@result;
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
			 "'$method' is not a valid method in module CDMI_API.");
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
    
    return { module => $module, method => $method };
}

1;
