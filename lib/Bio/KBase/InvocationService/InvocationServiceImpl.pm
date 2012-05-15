package Bio::KBase::InvocationService::InvocationServiceImpl;
use strict;
use Bio::KBase::Exceptions;

=head1 NAME

InvocationService

=head1 DESCRIPTION



=cut

#BEGIN_HEADER
use IPC::Run;
use Data::Dumper;
use Digest::MD5 'md5_hex';    
use Bio::KBase::InvocationService::PipelineGrammar;
use POSIX qw(strftime);
use Cwd;
use Cwd 'abs_path';
use File::Path;
use File::Basename;

my @valid_commands = qw(
	all_roles_used_in_models atomic_regulons_to_fids close_genomes co_occurrence_evidence 
	complexes_to_complex_data complexes_to_roles contigs_to_lengths contigs_to_md5s 
	contigs_to_sequences corresponds equiv_sequence_assertions fids_to_annotations 
	fids_to_atomic_regulons fids_to_co_occurring_fids fids_to_coexpressed_fids 
	fids_to_dna_sequences fids_to_feature_data fids_to_functions fids_to_genomes 
	fids_to_literature fids_to_locations fids_to_protein_families fids_to_protein_sequences 
	fids_to_proteins fids_to_regulon_data fids_to_roles fids_to_subsystem_data 
	fids_to_subsystems genomes_to_contigs genomes_to_fids genomes_to_genome_data 
	genomes_to_md5s genomes_to_subsystems genomes_to_taxonomies locations_to_dna_sequences 
	locations_to_fids md5s_to_genomes otu_members protein_families_to_co_occurring_families 
	protein_families_to_fids protein_families_to_functions protein_families_to_proteins 
	proteins_to_fids proteins_to_functions proteins_to_literature proteins_to_protein_families 
	proteins_to_roles reaction_strings reactions_to_complexes regulons_to_fids 
	representative representative_sequences roles_to_complexes roles_to_fids 
	roles_to_protein_families roles_to_proteins roles_to_subsystems subsystems_to_fids 
	subsystems_to_genomes subsystems_to_roles subsystems_to_spreadsheets text_search 
	
	all_entities_AlignmentTree all_entities_AlleleFrequency all_entities_Annotation 
	all_entities_Assay all_entities_AtomicRegulon all_entities_Attribute all_entities_Biomass 
	all_entities_BiomassCompound all_entities_Compartment all_entities_Complex 
	all_entities_Compound all_entities_Contig all_entities_ContigChunk all_entities_ContigSequence 
	all_entities_CoregulatedSet all_entities_Diagram all_entities_EcNumber all_entities_Experiment 
	all_entities_Family all_entities_Feature all_entities_Genome all_entities_Identifier 
	all_entities_Locality all_entities_Media all_entities_Model all_entities_ModelCompartment 
	all_entities_OTU all_entities_ObservationalUnit all_entities_PairSet all_entities_Pairing 
	all_entities_ProbeSet all_entities_ProteinSequence all_entities_Publication 
	all_entities_Reaction all_entities_ReactionRule all_entities_Reagent all_entities_Requirement 
	all_entities_Role all_entities_SSCell all_entities_SSRow all_entities_Scenario 
	all_entities_Source all_entities_StudyExperiment all_entities_Subsystem all_entities_SubsystemClass 
	all_entities_TaxonomicGrouping all_entities_Trait all_entities_Variant all_entities_Variation 
	get_entity_AlignmentTree get_entity_AlleleFrequency get_entity_Annotation 
	get_entity_Assay get_entity_AtomicRegulon get_entity_Attribute get_entity_Biomass 
	get_entity_BiomassCompound get_entity_Compartment get_entity_Complex get_entity_Compound 
	get_entity_Contig get_entity_ContigChunk get_entity_ContigSequence get_entity_CoregulatedSet 
	get_entity_Diagram get_entity_EcNumber get_entity_Experiment get_entity_Family 
	get_entity_Feature get_entity_Genome get_entity_Identifier get_entity_Locality 
	get_entity_Media get_entity_Model get_entity_ModelCompartment get_entity_OTU 
	get_entity_ObservationalUnit get_entity_PairSet get_entity_Pairing get_entity_ProbeSet 
	get_entity_ProteinSequence get_entity_Publication get_entity_Reaction get_entity_ReactionRule 
	get_entity_Reagent get_entity_Requirement get_entity_Role get_entity_SSCell 
	get_entity_SSRow get_entity_Scenario get_entity_Source get_entity_StudyExperiment 
	get_entity_Subsystem get_entity_SubsystemClass get_entity_TaxonomicGrouping 
	get_entity_Trait get_entity_Variant get_entity_Variation get_relationship_AffectsLevelOf 
	get_relationship_Aligns get_relationship_Annotates get_relationship_Asserts 
	get_relationship_AssertsFunctionFor get_relationship_Comprises get_relationship_Concerns 
	get_relationship_Contains get_relationship_Controls get_relationship_DefinedBy 
	get_relationship_Describes get_relationship_Determines get_relationship_DeterminesFunctionOf 
	get_relationship_Displays get_relationship_Encompasses get_relationship_Formulated 
	get_relationship_GeneratedLevelsFor get_relationship_HadResultsProducedBy 
	get_relationship_HasAsExemplar get_relationship_HasAsSequence get_relationship_HasAsTerminus 
	get_relationship_HasAssertedFunctionFrom get_relationship_HasAssertionFrom 
	get_relationship_HasCompoundAliasFrom get_relationship_HasCoregulationWith 
	get_relationship_HasDefaultLocation get_relationship_HasFunctional get_relationship_HasIndicatedSignalFrom 
	get_relationship_HasLevelsFrom get_relationship_HasMember get_relationship_HasParticipant 
	get_relationship_HasPresenceOf get_relationship_HasProposedLocationIn get_relationship_HasProteinMember 
	get_relationship_HasReactionAliasFrom get_relationship_HasRealLocationIn 
	get_relationship_HasRepresentativeOf get_relationship_HasResultsFor get_relationship_HasResultsIn 
	get_relationship_HasRole get_relationship_HasSection get_relationship_HasStep 
	get_relationship_HasTrait get_relationship_HasUnits get_relationship_HasUsage 
	get_relationship_HasValueFor get_relationship_HasValueIn get_relationship_HasVariant 
	get_relationship_HasVariation get_relationship_Impacts get_relationship_Implements 
	get_relationship_Imported get_relationship_Includes get_relationship_IncludesPart 
	get_relationship_IncludesPartOf get_relationship_IndicatedLevelsFor get_relationship_IndicatesSignalFor 
	get_relationship_Involves get_relationship_IsARequirementIn get_relationship_IsARequirementOf 
	get_relationship_IsATopicOf get_relationship_IsAffectedIn get_relationship_IsAlignedBy 
	get_relationship_IsAlignedIn get_relationship_IsAlignmentFor get_relationship_IsAnnotatedBy 
	get_relationship_IsBindingSiteFor get_relationship_IsBoundBy get_relationship_IsClassFor 
	get_relationship_IsCollectedInto get_relationship_IsCollectionOf get_relationship_IsComponentOf 
	get_relationship_IsComposedOf get_relationship_IsComprisedOf get_relationship_IsConfiguredBy 
	get_relationship_IsConsistentTo get_relationship_IsConsistentWith get_relationship_IsContainedIn 
	get_relationship_IsControlledUsing get_relationship_IsCoregulatedWith get_relationship_IsCoupledTo 
	get_relationship_IsCoupledWith get_relationship_IsDefaultFor get_relationship_IsDefaultLocationOf 
	get_relationship_IsDescribedBy get_relationship_IsDeterminedBy get_relationship_IsDisplayedOn 
	get_relationship_IsDividedInto get_relationship_IsDivisionOf get_relationship_IsEncompassedIn 
	get_relationship_IsExemplarOf get_relationship_IsFamilyFor get_relationship_IsFormedInto 
	get_relationship_IsFormedOf get_relationship_IsFunctionalIn get_relationship_IsGroupFor 
	get_relationship_IsImpactedBy get_relationship_IsImplementedBy get_relationship_IsInClass 
	get_relationship_IsInGroup get_relationship_IsInPair get_relationship_IsInTaxa 
	get_relationship_IsIncludedIn get_relationship_IsInstanceOf get_relationship_IsInstantiatedBy 
	get_relationship_IsInvolvedIn get_relationship_IsLocated get_relationship_IsLocatedIn 
	get_relationship_IsLocatedOn get_relationship_IsLocusFor get_relationship_IsManagedBy 
	get_relationship_IsMemberOf get_relationship_IsModeledBy get_relationship_IsNamedBy 
	get_relationship_IsOwnedBy get_relationship_IsOwnerOf get_relationship_IsPairOf 
	get_relationship_IsPartOf get_relationship_IsParticipationOf get_relationship_IsPresentIn 
	get_relationship_IsProjectedOnto get_relationship_IsProposedLocationOf get_relationship_IsProteinFor 
	get_relationship_IsProteinMemberOf get_relationship_IsRealLocationOf get_relationship_IsReferencedBy 
	get_relationship_IsRegulatedIn get_relationship_IsRegulatedSetOf get_relationship_IsRelevantFor 
	get_relationship_IsRelevantTo get_relationship_IsRepresentedBy get_relationship_IsRepresentedIn 
	get_relationship_IsRequiredBy get_relationship_IsRoleFor get_relationship_IsRoleOf 
	get_relationship_IsRowOf get_relationship_IsSectionOf get_relationship_IsSequenceOf 
	get_relationship_IsShownOn get_relationship_IsStepOf get_relationship_IsSubInstanceOf 
	get_relationship_IsSubclassOf get_relationship_IsSuperclassOf get_relationship_IsTargetOf 
	get_relationship_IsTaxonomyOf get_relationship_IsTerminusFor get_relationship_IsTriggeredBy 
	get_relationship_IsUsageOf get_relationship_IsUseOf get_relationship_IsUsedAs 
	get_relationship_IsUsedBy get_relationship_IsUtilizedIn get_relationship_IsVariantOf 
	get_relationship_Manages get_relationship_Measures get_relationship_Models 
	get_relationship_Names get_relationship_OperatesIn get_relationship_Overlaps 
	get_relationship_ParticipatesAs get_relationship_ParticipatesIn get_relationship_ProducedResultsFor 
	get_relationship_Produces get_relationship_ProjectsOnto get_relationship_Provided 
	get_relationship_ReflectsStateOf get_relationship_Requires get_relationship_ResultsIn 
	get_relationship_RunsByDefaultIn get_relationship_Shows get_relationship_Submitted 
	get_relationship_SummarizedBy get_relationship_Summarizes get_relationship_Targets 
	get_relationship_Triggers get_relationship_Uses get_relationship_UsesAliasForCompound 
	get_relationship_UsesAliasForReaction get_relationship_UsesReference get_relationship_Validates 
	get_relationship_WasDetermiedBy get_relationship_WasFormulatedBy get_relationship_WasGeneratedFrom 
	get_relationship_WasImportedFrom get_relationship_WasProvidedBy get_relationship_WasSubmittedBy 
	query_entity_AlignmentTree query_entity_AlleleFrequency query_entity_Annotation 
	query_entity_Assay query_entity_AtomicRegulon query_entity_Attribute query_entity_Biomass 
	query_entity_BiomassCompound query_entity_Compartment query_entity_Complex 
	query_entity_Compound query_entity_Contig query_entity_ContigChunk query_entity_ContigSequence 
	query_entity_CoregulatedSet query_entity_Diagram query_entity_EcNumber query_entity_Experiment 
	query_entity_Family query_entity_Feature query_entity_Genome query_entity_Identifier 
	query_entity_Locality query_entity_Media query_entity_Model query_entity_ModelCompartment 
	query_entity_OTU query_entity_ObservationalUnit query_entity_PairSet query_entity_Pairing 
	query_entity_ProbeSet query_entity_ProteinSequence query_entity_Publication 
	query_entity_Reaction query_entity_ReactionRule query_entity_Reagent query_entity_Requirement 
	query_entity_Role query_entity_SSCell query_entity_SSRow query_entity_Scenario 
	query_entity_Source query_entity_StudyExperiment query_entity_Subsystem query_entity_SubsystemClass 
	query_entity_TaxonomicGrouping query_entity_Trait query_entity_Variant query_entity_Variation 
	
	annotate_genome fasta_to_genome genomeTO_to_feature_data genomeTO_to_reconstructionTO 
	reconstructionTO_to_roles reconstructionTO_to_subsystems
			genomeTO_to_html file_to_spreadsheet
);

my %valid_commands = map { $_ => 1 } @valid_commands;
my @command_path = ("/kb/deployment/bin", "/home/olson/FIGdisk/FIG/bin");

my @valid_shell_commands = qw(sort grep cut cat head tail date echo);
my %valid_shell_commands = map { $_ => 1 } @valid_shell_commands;

sub _valid_session_name
{
    my($self, $session) = @_;

    return $session =~ /^[a-zA-Z0-9._-]+$/;
}

sub _validate_session
{
    my($self, $session) = @_;
    my $d = $self->_session_dir($session);
    return -d $d;
}

sub _session_dir
{
    my($self, $session) = @_;
    return $self->{storage_dir} . "/$session";
}

sub _expand_filename
{
    my($self, $session, $file, $cwd) = @_;
    if ($file !~ /^([a-zA-Z][a-zA-Z0-9-_]*(?:\/[a-zA-Z][a-zA-Z0-9-_]*)*)/)
    {
	die "Invalid filename $file";
    }
    return $self->validate_path($session, $cwd."/".$file);

    #return $self->_session_dir($session) . "/$file";
}

sub _validate_command
{
    my($self, $cmd) = @_;

    my $path;
    if ($valid_commands{$cmd})
    {
	for my $cpath (@command_path)
	{
	    if (-x "$cpath/$cmd")
	    {
		$path = "$cpath/$cmd";
		last;
	    }
	    else
	    {
		print STDERR "Not found: $cpath/$cmd\n";
	    }
	}
    }
    elsif ($valid_shell_commands{$cmd})
    {
	for my $dir ('/bin', '/usr/bin')
	{
	    if (-x "$dir/$cmd")
	    {
		$path = "$dir/$cmd";
		last;
	    }
	}
    }
    else
    {
	return undef;
    }

    if (! -x $path)
    {
	return undef;
    }
    return $path;
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my($storage_dir) = @args;

    if (! -d $storage_dir)
    {
	die "Storage directory $storage_dir does not exist";
    }

    $self->{storage_dir} = $storage_dir;
    $self->{count} = 0;
    
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 start_session

  $actual_session_id = $obj->start_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$actual_session_id is a string

</pre>

=end html

=begin text

$session_id is a string
$actual_session_id is a string


=end text



=item Description



=back

=cut

sub start_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'start_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($actual_session_id);
    #BEGIN start_session

    print STDERR "start_session '$session_id'\n";
    if (!$session_id)
    {
	my $dig = Digest::MD5->new();
	if (open(my $rand, "<", "/dev/urandom"))
	{
	    my $dat;
	    my $n = read($rand, $dat, 1024);
	    print STDERR "Read $n bytes of random data\n";
	    $dig->add($dat);
	    close($rand);
	}
	$dig->add($$);
	$dig->add($self->{counter}++);
	$dig->add($self->{storage_dir});
	
	$session_id = $dig->hexdigest;
    }
    elsif (!$self->_valid_session_name($session_id))
    {
	die "Invalid session id";
    }
    my $dir = $self->_session_dir($session_id);
    if (!-d $dir)
    {
	mkdir($dir) or die "Cannot create session directory";
    }
    $actual_session_id = $session_id;
    
    #END start_session
    my @_bad_returns;
    (!ref($actual_session_id)) or push(@_bad_returns, "Invalid type for return variable \"actual_session_id\" (value was \"$actual_session_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'start_session');
    }
    return($actual_session_id);
}




=head2 valid_session

  $return = $obj->valid_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$return is an int

</pre>

=end html

=begin text

$session_id is a string
$return is an int


=end text



=item Description



=back

=cut

sub valid_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return);
    #BEGIN valid_session
    return $self->_validate_session($session_id);
    #END valid_session
    my @_bad_returns;
    (!ref($return)) or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_session');
    }
    return($return);
}




=head2 list_files

  $return_1, $return_2 = $obj->list_files($session_id, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$return_1 is a reference to a list where each element is a directory
$return_2 is a reference to a list where each element is a file
directory is a reference to a hash where the following keys are defined:
	name has a value which is a string
	mod_date has a value which is a string
file is a reference to a hash where the following keys are defined:
	name has a value which is a string
	mod_date has a value which is a string
	size has a value which is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$return_1 is a reference to a list where each element is a directory
$return_2 is a reference to a list where each element is a file
directory is a reference to a hash where the following keys are defined:
	name has a value which is a string
	mod_date has a value which is a string
file is a reference to a hash where the following keys are defined:
	name has a value which is a string
	mod_date has a value which is a string
	size has a value which is a string


=end text



=item Description



=back

=cut

sub list_files
{
    my $self = shift;
    my($session_id, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_files');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return_1, $return_2);
    #BEGIN list_files

   
    my $dir  = $self->validate_path($session_id, $cwd);

    my @dirs;
    my @files;
    my $dh;
    opendir($dh, $dir) or die "Cannot open directory: $!";
    while (my $file = readdir($dh)) {
	next if ($file =~ m/^\./);
	my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$dir/$file");
	my $date= strftime("%b %d %G %H:%M:%S", localtime($mtime));
        #my $date= strftime("%+", localtime($mtime));
        if (-f "$dir/$file") {
		push @files, [$file, $date, $size];
        } else {
                if (-d "$dir/$file") {
			push @dirs, [$file, $date];
                }
        }
    }



    $return_1  = \@dirs;
    $return_2 =  \@files;
    #$return = [ sort { $a <=> $b } readdir($dh) ];
    #$return = [ sort { $a <=> $b } grep { -f "$dir/$_" } readdir($dh) ];
    closedir($dh);

    #END list_files
    my @_bad_returns;
    (ref($return_1) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (ref($return_2) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_2\" (value was \"$return_2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_files');
    }
    return($return_1, $return_2);
}




=head2 remove_files

  $obj->remove_files($session_id, $cwd, $filename)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$filename is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$filename is a string


=end text



=item Description



=back

=cut

sub remove_files
{
    my $self = shift;
    my($session_id, $cwd, $filename) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to remove_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'remove_files');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN remove_files
    my $ap;

    if ($filename =~ /^\//) {
        $ap = $self->validate_path($session_id, $filename);
    } else {
        $ap = $self->validate_path($session_id, $cwd."/".$filename);
   }

    unlink("$ap");
    #END remove_files
    return();
}




=head2 rename_file

  $obj->rename_file($session_id, $cwd, $from, $to)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$from is a string
$to is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$from is a string
$to is a string


=end text



=item Description



=back

=cut

sub rename_file
{
    my $self = shift;
    my($session_id, $cwd, $from, $to) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($from)) or push(@_bad_arguments, "Invalid type for argument \"from\" (value was \"$from\")");
    (!ref($to)) or push(@_bad_arguments, "Invalid type for argument \"to\" (value was \"$to\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to rename_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'rename_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN rename_file

    my $apf;
    my $apt;


    if ($from =~ /^\//) {
        $apf = $self->validate_path($session_id, $from);
    } else {
        $apf = $self->validate_path($session_id, $cwd."/".$from);
   }
    if ($to =~ /^\//) {
        $apt = $self->validate_path($session_id, $to);
    } else {
        $apt = $self->validate_path($session_id, $cwd."/".$to);
   }
   if (-d "$apt") {
           my $f = basename $from;
	    if ($to =~ /^\//) {
		$apt = $self->validate_path($session_id, $to."/".$f);
	    } else {
		$apt = $self->validate_path($session_id, $cwd."/".$to."/".$f);
	   }
   }

    rename("$apf", "$apt") || die ( "Error in renaming" );
    #END rename_file
    return();
}




=head2 make_directory

  $obj->make_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description



=back

=cut

sub make_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to make_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'make_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN make_directory

    my $ap;

    if ($directory =~ /^\//) {
        $ap = $self->validate_path($session_id, $directory);
    } else {
        $ap = $self->validate_path($session_id, $cwd."/".$directory);
   }


    mkdir("$ap") || die ( "Error in mkdir" );
    #END make_directory
    return();
}




=head2 remove_directory

  $obj->remove_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description



=back

=cut

sub remove_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to remove_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'remove_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN remove_directory

    my $ap;

    if ($directory =~ /^\//) {
        $ap = $self->validate_path($session_id, $directory);
    } else {
        $ap = $self->validate_path($session_id, $cwd."/".$directory);
   }

    rmtree("$ap") || die ( "Error in rmdir" );
    #END remove_directory
    return();
}




=head2 change_directory

  $obj->change_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description



=back

=cut

sub change_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to change_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'change_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN change_directory

    my $base = $self->_session_dir($session_id);

    my $ap;

    if ($directory =~ /^\//) {
        $ap = $self->validate_path($session_id, $directory);
    } else {
        $ap = $self->validate_path($session_id, $cwd."/".$directory);
   }

   if ($ap =~ /^$base(.*)/) {
	if (!$1) {
		return "/";
	} else {
		return $1;
	}
   } else {
	die "invalid path";
   }
		 


    #END change_directory
    return();
}




=head2 put_file

  $obj->put_file($session_id, $filename, $contents, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$filename is a string
$contents is a string
$cwd is a string

</pre>

=end html

=begin text

$session_id is a string
$filename is a string
$contents is a string
$cwd is a string


=end text



=item Description



=back

=cut

sub put_file
{
    my $self = shift;
    my($session_id, $filename, $contents, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($contents)) or push(@_bad_arguments, "Invalid type for argument \"contents\" (value was \"$contents\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to put_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'put_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN put_file

    #
    # Filenames can't have any special characters or start with a /.
    #
    if ($filename !~ /^([a-zA-Z][a-zA-Z0-9-_]*(?:\/[a-zA-Z][a-zA-Z0-9-_]*)*)/)
    {
	die "Invalid filename";
    }
    my $ap;

    if ($filename =~ /^\//) {
        $ap = $self->validate_path($session_id, $filename);
    } else {
        $ap = $self->validate_path($session_id, $cwd."/".$filename);
   }
    open(my $fh, ">", $ap) or die "Cannot open $ap: $!";
    print $fh $contents;
    close($fh);

    #END put_file
    return();
}




=head2 get_file

  $contents = $obj->get_file($session_id, $filename, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$filename is a string
$cwd is a string
$contents is a string

</pre>

=end html

=begin text

$session_id is a string
$filename is a string
$cwd is a string
$contents is a string


=end text



=item Description



=back

=cut

sub get_file
{
    my $self = shift;
    my($session_id, $filename, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($contents);
    #BEGIN get_file


    #
    # Filenames can't have any special characters or start with a /.
    #
    if ($filename !~ /^([a-zA-Z][a-zA-Z0-9-_]*(?:\/[a-zA-Z][a-zA-Z0-9-_]*)*)/)
    {
	die "Invalid filename";
    }
    my $ap;

    if ($filename =~ /^\//) {
        $ap = $self->validate_path($session_id, $filename);
    } else {
        $ap = $self->validate_path($session_id, $cwd."/".$filename);
   }
    open(my $fh, "<", $ap) or die "Cannot open $ap: $!";
    local $/;
    undef $/;
    $contents = <$fh>;
    close($fh);
    #END get_file
    my @_bad_returns;
    (!ref($contents)) or push(@_bad_returns, "Invalid type for return variable \"contents\" (value was \"$contents\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_file');
    }
    return($contents);
}




=head2 run_pipeline

  $output, $errors = $obj->run_pipeline($session_id, $pipeline, $input, $max_output_size, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string

</pre>

=end html

=begin text

$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub run_pipeline
{
    my $self = shift;
    my($session_id, $pipeline, $input, $max_output_size, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument \"pipeline\" (value was \"$pipeline\")");
    (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument \"max_output_size\" (value was \"$max_output_size\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($output, $errors);
    #BEGIN run_pipeline

    print STDERR "Parse: '$pipeline'\n";
    $pipeline =~ s/\xA0/ /g;
    print STDERR "Parse: '$pipeline'\n";
    my $parser = Bio::KBase::InvocationService::PipelineGrammar->new;
    $parser->input($pipeline);
    my $tree = $parser->Run();

    if (!$tree)
    {
	die "Error parsing command line";
    }

    #
    # construct pipeline for IPC::Run
    #

    my @cmds;

    print STDERR Dumper($tree);

    $output = [];
    $errors = [];

    my $harness;

    my $dir = $self->validate_path($session_id, $cwd);
    my @cmd_list;
    my @saved_stderr;
 PIPELINE:
    for my $idx (0..$#$tree)
    {
	my $ent = $tree->[$idx];
	
	my $cmd = $ent->{cmd};
	my $redirect = $ent->{redir};
	my $args = $ent->{args};

	my $cmd_path = $self->_validate_command($cmd);
	if (!$cmd_path)
	{
	    push(@$errors, "$cmd: invalid command");
	    next;
	}

	
	if (@cmds)
	{
	    push(@cmds, '|');
	}
	$saved_stderr[$idx] = [];
	push(@cmd_list, $cmd);
	push(@cmds, [$cmd_path, @$args]);
	push @cmds, init => sub {
	    chdir $dir or die $!;
	};
	my $have_output_redirect;
	my $have_stderr_redirect;
	for my $r (@$redirect)
	{
	    my($what, $file) = @$r;
	    if ($what eq '<')
	    {
		my $path = $self->_expand_filename($session_id, $file, $cwd);
		if (! -f $path)
		{
		    push(@$errors, "$file: input not found");
		    next PIPELINE;
		}
		push(@cmds, '<', $path);
	    }
	    elsif ($what eq '>' || $what eq '>>')
	    {
		my $path = $self->_expand_filename($session_id, $file, $cwd);
		push(@cmds, $what, $path);
		$have_output_redirect = 1;
	    }
	    
	}
	if ($idx == $#$tree)
	{
	    if (!$have_output_redirect)
	    {
		push(@cmds, '>', IPC::Run::new_chunker, sub {
		    my($l) = @_;
		    push(@$output, $l);
		    if ($max_output_size > 0 && @$output >= $max_output_size)
		    {
			push(@$errors, "Output truncated to $max_output_size lines");
			$harness->kill_kill;
		    }
		});
	    }
	}
	if (!$have_stderr_redirect)
	{
	    push(@cmds, '2>', IPC::Run::new_chunker, sub {
		my($l) = @_;
		push(@{$saved_stderr[$idx]}, $l);
	    });
	}
    }

    print STDERR Dumper(\@cmds);
    $output = [];

    if (@$errors == 0)
    {
	my $h = IPC::Run::start(@cmds);
	$harness = $h;
	eval {
	    $h->finish();
	};

	my $err = $@;
	if ($err)
	{
	    push(@$errors, "Error invoking pipeline");
	    warn "error invooking pipeline: $err";
	}
	
	my @res = $h->results();
	for (my $i = 0; $i <= $#res; $i++)
	{
	    push(@$errors, "Return code from $cmd_list[$i]: $res[$i]");
	    push(@$errors, @{$saved_stderr[$i]});
	}
    }

    if ($max_output_size > 0 && @$output > $max_output_size)
    {
	my $removed = @$output - $max_output_size;
	$#$output = $max_output_size - 1;
	push(@$errors, "Elided $removed lines of output");
    }
	
    
    #END run_pipeline
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    (ref($errors) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"errors\" (value was \"$errors\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline');
    }
    return($output, $errors);
}




=head2 exit_session

  $obj->exit_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string

</pre>

=end html

=begin text

$session_id is a string


=end text



=item Description



=back

=cut

sub exit_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to exit_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'exit_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN exit_session
    #END exit_session
    return();
}


sub validate_path
{
    my($self, $session_id, $cwd) = @_;
    my $base = $self->_session_dir($session_id);
    my $dir = $base.$cwd;
    my $ap = abs_path($dir);
    if ($ap =~ /^$base/) {
	return $ap;
    } else {
	die "Invalid path $ap";
    }


}

=head1 TYPES



=head2 directory

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
mod_date has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
mod_date has a value which is a string


=end text

=back



=head2 file

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
mod_date has a value which is a string
size has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
mod_date has a value which is a string
size has a value which is a string


=end text

=back



=cut

1;
