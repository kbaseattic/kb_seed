use strict;
use ModelSEED::FIGMODEL;

package ModelSEED::FIGMODEL::FIGMODELreaction;

=head1 FIGMODELreaction object
=head2 Introduction
Module for holding reaction related access functions
=head2 Core Object Methods

=head3 new
Definition:
	FIGMODELreaction = FIGMODELreaction->new({figmodel => FIGMODEL:parent figmodel object,id => string:reaction id});
Description:
	This is the constructor for the FIGMODELreaction object.
=cut
sub new {
	my ($class,$args) = @_;
	#Must manualy check for figmodel argument since figmodel is needed for automated checking
	if (!defined($args->{figmodel})) {
		print STDERR "FIGMODELreaction->new():figmodel must be defined to create an genome object!\n";
		return undef;
	}
	my $self = {_figmodel => $args->{figmodel}};
	bless $self;
	#Processing remaining arguments
	$args = $self->figmodel()->process_arguments($args,["figmodel","id"],{});
	if (defined($args->{error})) {
		$self->error_message({function=>"new",args=>$args});
		return undef;
	}
	$self->{_id} = $args->{id};
	$self->figmodel()->set_cache("FIGMODELreaction|".$self->id(),$self);
	return $self;
}

=head3 error_message
Definition:
	string:message text = FIGMODELreaction->error_message(string::message);
Description:
=cut
sub error_message {
	my ($self,$args) = @_;
	$args->{"package"} = "FIGMODELreaction";
    return $self->figmodel()->new_error_message($args);
}

=head3 figmodel
Definition:
	FIGMODEL = FIGMODELreaction->figmodel();
Description:
	Returns the figmodel object
=cut
sub figmodel {
	my ($self) = @_;
	return $self->{_figmodel};
}

=head3 id
Definition:
	string:reaction ID = FIGMODELreaction->id();
Description:
	Returns the reaction ID
=cut
sub id {
	my ($self) = @_;
	return $self->{_id};
}

=head3 ppo
Definition:
	PPOreaction:reaction object = FIGMODELreaction->ppo();
Description:
	Returns the reaction ppo object
=cut
sub ppo {
	my ($self,$inppo) = @_;
	if (defined($inppo)) {
		$self->{_ppo} = $inppo;
	}
	if (!defined($self->{_ppo})) {
		if ($self->id() =~ m/^bio\d+$/) {
			$self->{_ppo} = $self->figmodel()->database()->get_object("bof",{id => $self->id()});
		} else {
			$self->{_ppo} = $self->figmodel()->database()->get_object("reaction",{id => $self->id()});
		}
	}
	return $self->{_ppo};
}

=head3 copyReaction
Definition:
	FIGMODELreaction = FIGMODELreaction->copyReaction({
		newid => string:new ID
	});
Description:
	Creates a replica of the reaction
=cut
sub copyReaction {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{newid=>undef,owner=>$self->ppo()->owner()});
	if (defined($args->{error})) {return $self->error_message({function => "copyReaction",args => $args});}
	#Issuing new ID
	if (!defined($args->{newid})) {
		if ($self->id() =~ m/rxn/) {
			$args->{newid} = $self->figmodel()->database()->check_out_new_id("reaction");
		} elsif ($self->id() =~ m/bio/) {
			$args->{newid} = $self->figmodel()->database()->check_out_new_id("bof");
		}
	}
	#Replicating PPO
	if ($self->id() =~ m/rxn/) {
			
	} elsif ($self->id() =~ m/bio/) {
		$self->figmodel()->database()->create_object("bof",{
			owner => $self->ppo()->owner(),
			name => $self->ppo()->name(),
			public => $self->ppo()->public(),
			equation => $self->ppo()->equation(),
			modificationDate => time(),
			creationDate => time(),
			id => $args->{newid},
			cofactorPackage => $self->ppo()->cofactorPackage(),
			lipidPackage => $self->ppo()->lipidPackage(),
			cellWallPackage => $self->ppo()->cellWallPackage(),
			protein => $self->ppo()->protein(),
			DNA => $self->ppo()->DNA(),
			RNA => $self->ppo()->RNA(),
			lipid => $self->ppo()->lipid(),
			cofactor => $self->ppo()->cofactor(),
			cellWall => $self->ppo()->cellWall(),
			proteinCoef => $self->ppo()->proteinCoef(),
			DNACoef => $self->ppo()->DNACoef(),
			RNACoef => $self->ppo()->RNACoef(),
			lipidCoef => $self->ppo()->lipidCoef(),
			cofactorCoef => $self->ppo()->cofactorCoef(),
			cellWallCoef => $self->ppo()->cellWallCoef(),
			essentialRxn => $self->ppo()->essentialRxn(),
			energy => $self->ppo()->energy(),
			unknownPackage => $self->ppo()->unknownPackage(),
			unknownCoef => $self->ppo()->unknownCoef()
		});
	}
	my $newRxn = $self->figmodel()->get_reaction($args->{newid});
	if (-e $self->file()) {
		$self->file()->save($newRxn->filename());
	}
	return $newRxn;
}
=head3 filename
Definition:
	string = FIGMODELreaction->filename();
=cut
sub filename {
	my ($self) = @_;
	return $self->figmodel()->config("reaction directory")->[0].$self->id();
}
=head3 file
Definition:
	{string:key => [string]:values} = FIGMODELreaction->file({clear => 0/1});
Description:
	Loads the reaction data from file
=cut
sub file {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		clear => 0,
		filename=>$self->filename()
	});
	if ($args->{clear} == 1) {
		delete $self->{_file};
	}
	if (!defined($self->{_file})) {
		$self->{_file} = ModelSEED::FIGMODEL::FIGMODELObject->new({filename=>$args->{filename},delimiter=>"\t",-load => 1});
		if (!defined($self->{_file})) {return $self->error_message({function=>"file",message=>"could not load file",args=>$args});}
	} 
	return $self->{_file};
}
=head3 substrates_from_equation
Definition:
	([{}:reactant data],[{}:Product data]) = FIGMODELreaction->substrates_from_equation({});
	{}:Reactant/Product data = {
		DATABASE => [string],
		COMPARTMENT => [string],
		COEFFICIENT => [string]}]
	}
Description:
	This function parses the input reaction equation and returns the data on reactants and products.
=cut
sub substrates_from_equation {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{equation => undef});
	if (defined($args->{error})) {return $self->error_message({function => "substrates_from_equation",args => $args});}
	my $Equation = $args->{equation};
	if (!defined($Equation)) {
		if (!defined($self->ppo())) {return $self->error_message({message => "Could not find reaction in database",function => "substrates_from_equation",args => $args});}
		$Equation = $self->ppo()->equation();
	}
	my $Reactants;
	my $Products;
	if (defined($Equation)) {
		my @TempArray = split(/\s/,$Equation);
		my $Coefficient = 1;
		my $CurrentlyOnReactants = 1;
		for (my $i=0; $i < @TempArray; $i++) {
			if ($TempArray[$i] =~ m/^\(([\.\d]+)\)$/ || $TempArray[$i] =~ m/^([\.\d]+)$/) {
				$Coefficient = $1;
			} elsif ($TempArray[$i] =~ m/(cpd\d\d\d\d\d)/) {
				my $NewRow;
				$NewRow->{"DATABASE"}->[0] = $1;
				$NewRow->{"COMPARTMENT"}->[0] = "c";
				$NewRow->{"COEFFICIENT"}->[0] = $Coefficient;
				if ($TempArray[$i] =~ m/cpd\d\d\d\d\d\[(\D)\]/) {
					$NewRow->{"COMPARTMENT"}->[0] = lc($1);
				}
				if ($CurrentlyOnReactants == 1) {
					push(@{$Reactants},$NewRow);
				} else {
					push(@{$Products},$NewRow);
				}
				$Coefficient = 1;
			} elsif ($TempArray[$i] =~ m/=/) {
				$CurrentlyOnReactants = 0;
			}
		}
	}
	return ($Reactants,$Products);
}

=head2 Functions involving interactions with MFAToolkit

=head3 updateReactionData
Definition:
	string:error = FIGMODELreaction->updateReactionData();
Description:
	This function uses the MFAToolkit to process the reaction and reaction data is updated accordingly
=cut
sub updateReactionData {
	my ($self) = @_;
	if (!defined($self->ppo())) {return $self->error_message({function=>"updateReactionData",message=>"could not find ppo object",args=>{}});}
	my $data = $self->file({clear=>1});#Reloading the file data for the compound, which now has the updated data
	my $translations = {EQUATION => "equation",DELTAG => "deltaG",DELTAGERR => "deltaGErr","THERMODYNAMIC REVERSIBILITY" => "thermoReversibility",STATUS => "status",TRANSATOMS => "transportedAtoms"};#Translating MFAToolkit file headings into PPO headings
	foreach my $key (keys(%{$translations})) {#Loading file data into the PPO
		if (defined($data->{$key}->[0])) {
			my $function = $translations->{$key};
			$self->ppo()->$function($data->{$key}->[0]);
		}
	}
	if (defined($data->{"STRUCTURAL_CUES"}->[0])) {
		$self->ppo()->structuralCues(join("|",@{$data->{"STRUCTURAL_CUES"}}));	
	}
	my $codeOutput = $self->createReactionCode();
	if (defined($codeOutput->{code})) {
		$self->ppo()->code($codeOutput->{code});
	}
	if (defined($self->figmodel()->config("acceptable unbalanced reactions"))) {
		if ($self->ppo()->status() =~ m/OK/) {
			for (my $i=0; $i < @{$self->figmodel()->config("acceptable unbalanced reactions")}; $i++) {
				if ($self->figmodel()->config("acceptable unbalanced reactions")->[$i] eq $self->id()) {
					$self->ppo()->status("OK|".$self->ppo()->status());
					last;
				}	
			}
		}
		for (my $i=0; $i < @{$self->figmodel()->config("permanently knocked out reactions")}; $i++) {
			if ($self->figmodel()->config("permanently knocked out reactions")->[$i] eq $self->id() ) {
				if ($self->ppo()->status() =~ m/OK/) {
					$self->ppo()->status("BL");
				} else {
					$self->ppo()->status("BL|".$self->ppo()->status());
				}
				last;
			}	
		}
		for (my $i=0; $i < @{$self->figmodel()->config("spontaneous reactions")}; $i++) {
			if ($self->figmodel()->config("spontaneous reactions")->[$i] eq $self->id() ) {
				$self->ppo()->status("SP|".$self->ppo()->status());
				last;
			}
		}
		for (my $i=0; $i < @{$self->figmodel()->config("universal reactions")}; $i++) {
			if ($self->figmodel()->config("universal reactions")->[$i] eq $self->id() ) {
				$self->ppo()->status("UN|".$self->ppo()->status());
				last;
			}
		}
		if (defined($self->figmodel()->config("reversibility corrections")->{$self->id()})) {
			$self->ppo()->status("RC|".$self->ppo()->status());
		}
		if (defined($self->figmodel()->config("forward only reactions")->{$self->id()})) {
			$self->ppo()->status("FO|".$self->ppo()->status());
		}
		if (defined($self->figmodel()->config("reverse only reactions")->{$self->id()})) {
			$self->ppo()->status("RO|".$self->ppo()->status());
		}
	}
	return undef;
}

=head3 processReactionWithMFAToolkit
Definition:
	string:error message = FIGMODELreaction->processReactionWithMFAToolkit();
Description:
	This function uses the MFAToolkit to process the entire reaction database. This involves balancing reactions, calculating thermodynamic data, and parsing compound structure files for charge and formula.
	This function should be run when reactions are added or changed, or when structures are added or changed.
	The database should probably be backed up before running the function just in case something goes wrong.
=cut
sub processReactionWithMFAToolkit {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		overwriteReactionFile => 0,
		loadToPPO => 0,
		loadEquationFromPPO => 0,
		comparisonFile => undef
	});
	if (defined($args->{error})) {return $self->error_message({function => "processReactionWithMFAToolkit",args => $args});}
	#Backing up the old file
	system("cp ".$self->figmodel()->config("reaction directory")->[0].$self->id()." ".$self->figmodel()->config("database root directory")->[0]."ReactionDB/oldreactions/".$self->id());
	#Getting unique directory for output
	my $filename = $self->figmodel()->filename();
	#Eliminating the mfatoolkit errors from the compound and reaction files
	my $data = $self->file();
	if (defined($self->ppo()) && $args->{loadEquationFromPPO} == 1) {
		$data->{EQUATION}->[0] = $self->ppo()->equation();
	}
	$data->remove_heading("MFATOOLKIT ERRORS");
	$data->remove_heading("STATUS");
	$data->remove_heading("TRANSATOMS");
	$data->remove_heading("DBLINKS");
	$data->save();
	#Running the mfatoolkit
	print $self->figmodel()->GenerateMFAToolkitCommandLineCall($filename,"processdatabase","NONE",["ArgonneProcessing"],{"load compound structure" => 0,"Calculations:reactions:process list" => "LIST:".$self->id()},"DBProcessing-".$self->id()."-".$filename.".log")."\n";
	system($self->figmodel()->GenerateMFAToolkitCommandLineCall($filename,"processdatabase","NONE",["ArgonneProcessing"],{"load compound structure" => 0,"Calculations:reactions:process list" => "LIST:".$self->id()},"DBProcessing-".$self->id()."-".$filename.".log"));
	#Copying in the new file
	print $self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()."\n";
	if (-e $self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()) {
		my $newData = $self->file({filename=>$self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()});
		if ($args->{overwriteReactionFile} == 1) {
			system("cp ".$self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()." ".$self->figmodel()->config("reaction directory")->[0].$self->id());
		}
		if ($args->{loadToPPO} == 1) {
			$self->updateReactionData();
		}
		if (defined($args->{comparisonFile}) && $newData->{EQUATION}->[0] ne $data->{EQUATION}->[0]) {
			if (-e $args->{comparisonFile}) {
				$self->figmodel()->database()->print_array_to_file($args->{comparisonFile},["ID\tPPO equation\tOriginal equation\tNew equation\tStatus",$self->id()."\t".$data->ppo()->equation()."\t".$data->{EQUATION}->[0]."\t".$newData->{EQUATION}->[0]."\t".$newData->{STATUS}->[0]],1);
			} else {
				$self->figmodel()->database()->print_array_to_file($args->{comparisonFile},[$self->id()."\t".$data->ppo()->equation()."\t".$data->{EQUATION}->[0]."\t".$newData->{EQUATION}->[0]."\t".$newData->{STATUS}->[0]]);
			}
		}
	} else {return $self->error_message({function=>"processReactionWithMFAToolkit",message=>"could not find output reaction file",args=>{}});}
	$self->figmodel()->clearing_output($filename,"DBProcessing-".$self->id()."-".$filename.".log");
	return {};
}

=head3 get_neighboring_reactions
Definition:
	{string:metabolite ID => [string]:neighboring reaction IDs}:Output = FIGMODELreaction->get_neighboring_reactions({});
Description:
	This function identifies the other reactions that share the same metabolites as this reaction
=cut
sub get_neighboring_reactions {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{});
    if (defined($args->{error})) {return $self->error_message({function=>"get_neighboring_reactions",args=>$args});}
	#Getting the list of reactants for this reaction
	my $cpds = $self->figmodel()->database()->get_objects("cpdrxn",{REACTION=>$self->id(),cofactor=>0});
	my $neighbors;
	for (my $i=0; $i < @{$cpds}; $i++) {
		my $hash;
		my $rxns = $self->figmodel()->database()->get_objects("cpdrxn",{COMPOUND=>$cpds->[$i]->COMPOUND(),cofactor=>0});
		for (my $j=0; $j < @{$rxns}; $j++) {
			if ($rxns->[$j]->REACTION() ne $self->id()) {
				$hash->{$rxns->[$j]->REACTION()} = 1;
			}
		}
		push(@{$neighbors->{$cpds->[$i]->COMPOUND()}},keys(%{$hash}));
	}
	return $neighbors;
}

=head3 identify_dependant_reactions
Definition:
	FIGMODELreaction->identify_dependant_reactions({});
Description:
=cut
sub identify_dependant_reactions {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{biomass => undef,model => undef,media => "Complete"});
	if (defined($args->{error})) {return $self->error_message({function=>"identify_dependant_reactions",args=>$args});}
	my $fba = $self->figmodel()->fba($args);
	if (!defined($args->{model})) {
		if (!defined($args->{biomass})) {
			$args->{biomass} = "bio00001";	
		}
		$fba->model("Complete");
		$fba->set_parameters({"Complete model biomass reaction" => $args->{biomass}});
	}
	$fba->add_parameter_files(["ProductionCompleteClassification"]);
	$fba->set_parameters({"find tight bounds" => 1});
	$fba->add_constraint({objects => [$self->id()],coefficients => [1],rhs => 0.00001,sign => ">"});
	$fba->runFBA();
	my $essentials;
	my $results = $fba->parseTightBounds({});
	if (defined($results->{tb})) {
		foreach my $key (keys(%{$results->{tb}})) {
			if ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{max} < -0.000001) {
				$essentials->{"for_rev"}->{$key} = 1;
			} elsif ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{min} > 0.000001) {
				 $essentials->{"for_for"}->{$key} = 1;
			}
		}	
	}
	$fba->clear_constraints();
	$fba->add_constraint({objects => [$self->id()],coefficients => [1],compartments => ["c"],rhs => -0.000001,sign => "<"});
	$fba->runFBA();
	$results = $fba->parseTightBounds({});
	if (defined($results->{tb})) {
		foreach my $key (keys(%{$results->{tb}})) {
			if ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{max} < 0 || $results->{tb}->{$key}->{min} > 0) {
				if ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{max} < -0.000001) {
					$essentials->{"rev_rev"}->{$key} = 1;
				} elsif ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{min} > 0.000001) {
					$essentials->{"rev_for"}->{$key} = 1;
				}
			}
		}
	}
	my $obj = $self->figmodel()->database()->get_object("rxndep",{REACTION=>$self->id(),MODEL=>$args->{model},BIOMASS=>$args->{biomass},MEDIA=>$args->{media}});
	if (!defined($obj)) {
		$obj = $self->figmodel()->database()->create_object("rxndep",{REACTION=>$self->id(),MODEL=>$args->{model},BIOMASS=>$args->{biomass},MEDIA=>$args->{media}});	
	}
	$obj->forrev(join("|",sort(keys(%{$essentials->{"for_rev"}}))));
	$obj->forfor(join("|",sort(keys(%{$essentials->{"for_for"}}))));
	$obj->revrev(join("|",sort(keys(%{$essentials->{"rev_rev"}}))));
	$obj->revfor(join("|",sort(keys(%{$essentials->{"rev_for"}}))));
}

=head3 build_complete_biomass_reaction
Definition:
	{}:Output = FIGMODELreaction->build_complete_biomass_reaction({});
Description:
	This function identifies the other reactions that share the same metabolites as this reaction
=cut
sub build_complete_biomass_reaction {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{});
    my $bioObj = $self->figmodel()->database()->get_object("bof",{id => "bio00001"});
    #Filling in miscellaneous data for biomass
    $bioObj->name("Biomass");
	$bioObj->owner("master");
	$bioObj->modificationDate(time());
	$bioObj->creationDate(time());
	$bioObj->unknownCoef("NONE");
	$bioObj->unknownPackage("NONE");
	my $oldEquation = $bioObj->equation();
    #Filling in fraction of main components of biomass
    foreach my $key (keys(%{$self->figmodel()->config("universalBiomass_fractions")})) {
    	$bioObj->$key($self->figmodel()->config("universalBiomass_fractions")->{$key}->[0]);
    }
    #Filing compound hash
    my $compoundHash;
    $compoundHash = {cpd00001 => -1*$self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00002 => -1*$self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00008 => $self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00009 => $self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00067 => $self->figmodel()->config("universalBiomass_fractions")->{energy}->[0]};    
    my $categories = ["RNA","DNA","protein","cofactor","lipid","cellWall"];
    my $categoryTranslation = {"cofactor" => "Cofactor","lipid" => "Lipid","cellWall" => "CellWall"};
    foreach my $category (@{$categories}) {
    	my $tempHash;
    	my @array = sort(keys(%{$self->figmodel()->config("universalBiomass_".$category)}));
    	my $fractionCount = 0;
    	foreach my $item (@array) {
    		if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] !~ m/cpd\d+/) {
    			if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/FRACTION/) {
	    			$fractionCount++;
	    		} else {
	    			my $MW = 1;
	    			my $obj = $self->figmodel()->database()->get_object("compound",{"id"=>$item});
	    			if (defined($obj)) {
	    				$MW = $obj->mass();
	    			}
	    			if ($MW == 0) {
	    				$MW = 1;	
	    			}
	    			$tempHash->{$item} = $self->figmodel()->config("universalBiomass_fractions")->{$category}->[0]*$self->figmodel()->config("universalBiomass_".$category)->{$item}->[0]/$MW;
	    		}
    		}
    	}
    	foreach my $item (@array) {
    		if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/FRACTION/) {
    			my $MW = 1;
    			my $obj = $self->figmodel()->database()->get_object("compound",{"id"=>$item});
    			if (defined($obj)) {
    				$MW = $obj->mass();
    			}
    			my $sign = 1;
    			if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/^-/) {
    				$sign = -1;
    			}
    			if ($MW == 0) {
    				$MW = 1;	
    			}
    			$tempHash->{$item} = $sign*$self->figmodel()->config("universalBiomass_fractions")->{$category}->[0]/$fractionCount/$MW;
    		}
    	}
    	my $coefficients;
    	foreach my $item (@array) {
    		if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/cpd\d+/) {
    			my $sign = 1;
    			if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/^-(.+)/) {
    				$self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] = $1;
    				$sign = -1;
    			}
    			my @array = split(/,/,$self->figmodel()->config("universalBiomass_".$category)->{$item}->[0]);
    			$tempHash->{$item} = 0;
    			foreach my $cpd (@array) {
    				if (!defined($tempHash->{$cpd})) {
    					print "Compound not found:".$item."=>".$cpd."\n";
    				}
    				$tempHash->{$item} += $tempHash->{$cpd};
    			}
    			$tempHash->{$item} = $sign*$tempHash->{$item};
    		}
    		if (!defined($compoundHash->{$item})) {
    			$compoundHash->{$item} = 0;	
    		}
    		$compoundHash->{$item} += $tempHash->{$item};
    		push(@{$coefficients},$tempHash->{$item});
    	}
    	if (defined($categoryTranslation->{$category})) {
    		my $arrayRef;
    		push(@{$arrayRef},@array);
    		my $group = $self->figmodel()->get_compound("cpd00001")->get_general_grouping({ids => $arrayRef,type => $categoryTranslation->{$category}."Package",create=>1});
    		my $function = $category."Package";
    		$bioObj->$function($group);
    	}
    	my $function = $category."Coef";
    	$bioObj->$function(join("|",@{$coefficients}));
    }
    #Filling out equation
    $compoundHash->{"cpd11416"} = 1;
    my $reactants;
    my $products;
    foreach my $cpd (sort(keys(%{$compoundHash}))) {
    	if ($compoundHash->{$cpd} > 0) {
    		$products .= " + (".$compoundHash->{$cpd}.") ".$cpd;
    	} elsif ($compoundHash->{$cpd} < 0) {
    		$reactants .= "(".-1*$compoundHash->{$cpd}.") ".$cpd." + ";
    	}
    }
    $reactants = substr($reactants,0,length($reactants)-2);
    $products = substr($products,2);
    $bioObj->equation($reactants."=>".$products);
	$self->figmodel()->print_biomass_reaction_file("bio00001");
	if ($bioObj->equation() ne $oldEquation) {
		$bioObj->essentialRxn("NONE");
		$self->figmodel()->add_job_to_queue({command => "runfigmodelfunction?determine_biomass_essential_reactions?bio00001",user => $self->figmodel()->user(),queue => "fast"});
	}
}
=head3 createReactionCode
Definition:
	{} = FIGMODELreaction->createReactionCode({
		equation => 
		translations => 
	});
	
	Output = {
		direction => <=/<=>/=>,
		code => string:canonical reaction equation with H+ removed,
		reverseCode => string:reverse canonical equation with H+ removed,
		fullEquation => string:full equation with H+ included,
		compartment => string:compartment of reaction,
		error => string:error message
	}
Description:
	This function is used to convert reaction equations to a standardized form that allows for reaction comparison.
	This function accepts a string containing a reaction equation and a referece to a hash translating compound IDs in the reaction equation to Argonne compound IDs.
	This function uses the hash to translate the IDs in the equation to Argonne IDs, and orders the reactants alphabetically.
	This function returns four strings. The first string is the directionality of the input reaction: <= for reverse, => for forward, <=> for reversible.
	The second string is the query equation for the reaction, which is the translated and sorted equation minus any cytosolic H+ terms.
	The third strings is the reverse reaction for the second string, for matching this reaction to an exact reverse version of this reaction.
	The final string is the full translated and sorted reaction equation with the cytosolic H+.
=cut
sub createReactionCode {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{equation => $self->ppo()->equation(),translations => {}});
	if (defined($args->{error})) {return $self->error_message({function => "createReactionCode",args => $args});}
	my $OriginalEquation = $args->{equation};
	my $CompoundHashRef = $args->{translations};
	#Dealing with the compartment at the front of the equation
	my $EquationCompartment = "c";
	if ($OriginalEquation =~ m/^\[[(a-z)]\]\s/i) {
		$EquationCompartment = lc($1);
		$OriginalEquation =~ s/^\[[(a-z)]\]\s//i;
	}
	$OriginalEquation =~ s/^:\s//;
	$OriginalEquation =~ s/^\s:\s//;
	#Dealing with obvious errors in equation
	while ($OriginalEquation =~ m/\s\s/) {
		$OriginalEquation =~ s/\s\s/ /g;
	}
	$OriginalEquation =~ s/([^\+]\s)\+([^\s])/$1+ $2/g;
	$OriginalEquation =~ s/([^\s])\+(\s[^\+])/$1 +$2/g;
	$OriginalEquation =~ s/-->/=>/;
	$OriginalEquation =~ s/<--/<=/;
	$OriginalEquation =~ s/<==>/<=>/;
	$OriginalEquation =~ s/([^\s^<])(=>)/$1 $2/;
	$OriginalEquation =~ s/(<=)([^\s^>])/$1 $2/;
	$OriginalEquation =~ s/(=>)([^\s])/$1 $2/;
	$OriginalEquation =~ s/([^\s])(<=)/$1 $2/;
	$OriginalEquation =~ s/\s(\[[a-z]\])\s/$1 /ig;
	$OriginalEquation =~ s/\s(\[[a-z]\])$/$1/ig;
	#Checking for reactions that have no products, no reactants, or neither products nor reactants
	my $Error = 0;
	if ($OriginalEquation =~ m/^\s[<=]/ || $OriginalEquation =~ m/^[<=]/ || $OriginalEquation =~ m/[=>]\s$/ || $OriginalEquation =~ m/[=>]$/) {
		my $output = {
			code => $OriginalEquation,
			compartment => $EquationCompartment,
			error => $Error
		};
		return $output;
	}
	#Ready to start parsing equation
	my $Direction = "<=>";
	my @Data = split(/\s/,$OriginalEquation);
	my %ReactantHash;
	my %ProductHash;
	my $WorkingOnProducts = 0;
	my $CurrentReactant = "";
	my $CurrentString = "";
	my %RepresentedCompartments;
	for (my $i =0; $i < @Data; $i++) {
		if ($Data[$i] eq "" || $Data[$i] eq ":") {
			#Do nothing
		} elsif ($Data[$i] eq "+") {
			if ($CurrentString eq "") {
				$Error = 1;
			} elsif ($WorkingOnProducts == 0) {
				$ReactantHash{$CurrentReactant} = $CurrentString;
			} else {
				$ProductHash{$CurrentReactant} = $CurrentString;
			}
			$CurrentString = "";
			$CurrentReactant = "";
		} elsif ($Data[$i] eq "<=>" || $Data[$i] eq "=>" || $Data[$i] eq "<=") {
			$Direction = $Data[$i];
			$WorkingOnProducts = 1;
			if ($CurrentString eq "") {
				$Error = 1;
			} else {
				$ReactantHash{$CurrentReactant} = $CurrentString;
			}
			$CurrentString = "";
			$CurrentReactant = "";
		} elsif ($Data[$i] !~ m/[ABCDFGHIJKLMNOPQRSTUVWXYZ\]\[]/i) {
			#Stripping off perenthesis if present
			if ($Data[$i] =~ m/^\((.+)\)$/) {
				$Data[$i] = $1;
			}
			#Converting scientific notation to normal notation
			if ($Data[$i] =~ m/[eE]/) {
				my $Coefficient = "";
				my @Temp = split(/[eE]/,$Data[$i]);
				my @TempTwo = split(/\./,$Temp[0]);
				if ($Temp[1] > 0) {
					my $Index = $Temp[1];
					if (defined($TempTwo[1]) && $TempTwo[1] != 0) {
						$Index = $Index - length($TempTwo[1]);
						if ($Index < 0) {
							$TempTwo[1] = substr($TempTwo[1],0,(-$Index)).".".substr($TempTwo[1],(-$Index))
						}
					}
					for (my $j=0; $j < $Index; $j++) {
						$Coefficient .= "0";
					}
					if ($TempTwo[0] == 0) {
						$TempTwo[0] = "";
					}
					if (defined($TempTwo[1])) {
						$Coefficient = $TempTwo[0].$TempTwo[1].$Coefficient;
					} else {
						$Coefficient = $TempTwo[0].$Coefficient;
					}
				} elsif ($Temp[1] < 0) {
					my $Index = -$Temp[1];
					$Index = $Index - length($TempTwo[0]);
					if ($Index < 0) {
						$TempTwo[0] = substr($TempTwo[0],0,(-$Index)).".".substr($TempTwo[0],(-$Index))
					}
					if ($Index > 0) {
						$Coefficient = "0.";
					}
					for (my $j=0; $j < $Index; $j++) {
						$Coefficient .= "0";
					}
					$Coefficient .= $TempTwo[0];
					if (defined($TempTwo[1])) {
						$Coefficient .= $TempTwo[1];
					}
				}
				$Data[$i] = $Coefficient;
			}
			#Removing trailing zeros
			if ($Data[$i] =~ m/(.+\..*?)0+$/) {
				$Data[$i] = $1;
			}
			$Data[$i] =~ s/\.$//;
			#Adding the coefficient to the current string
			if ($Data[$i] != 1) {
				$CurrentString = "(".$Data[$i].") ";
			}
		} else {
			my $CurrentCompartment = "c";
			if ($Data[$i] =~ m/(.+)\[(\D)\]$/) {
				$Data[$i] = $1;
				$CurrentCompartment = lc($2);
			} elsif ($Data[$i] =~ m/(.+)_(\D)$/) {
				$Data[$i] = $1;
				$CurrentCompartment = lc($2);
			}
			$RepresentedCompartments{$CurrentCompartment} = 1;
			if (defined($CompoundHashRef->{$Data[$i]})) {
				$CurrentReactant = $CompoundHashRef->{$Data[$i]};
			} else {
				if ($Data[$i] !~ m/cpd\d\d\d\d\d/) {
					$Error = 1;
				}
				$CurrentReactant = $Data[$i];
			}
			$CurrentString .= $CurrentReactant;
			if ($CurrentCompartment ne "c") {
				$CurrentString .= "[".$CurrentCompartment."]";
			}
		}
	}
	if (length($CurrentReactant) > 0) {
		$ProductHash{$CurrentReactant} = $CurrentString;
	}
	#Checking if every reactant has the same compartment
	my @Compartments = keys(%RepresentedCompartments);
	if (@Compartments == 1) {
		$EquationCompartment = $Compartments[0];
	}
	#Checking if some reactants cancel out, since reactants will be canceled out by the MFAToolkit
	my @Reactants = keys(%ReactantHash);
	for (my $i=0; $i < @Reactants; $i++) {
		my @ReactantData = split(/\s/,$ReactantHash{$Reactants[$i]});
		my $ReactantCoeff = 1;
		if ($ReactantData[0] =~ m/^\(([\d\.]+)\)$/) {
		   $ReactantCoeff = $1;
		}
		my $ReactantCompartment = pop(@ReactantData);
		if ($ReactantCompartment =~ m/(\[\D\])$/) {
			$ReactantCompartment = $1;
		} else {
			$ReactantCompartment = "[c]";
		}
		if (defined($ProductHash{$Reactants[$i]})) {
			my @ProductData = split(/\s/,$ProductHash{$Reactants[$i]});
			my $ProductCoeff = 1;
			if ($ProductData[0] =~ m/^\(([\d\.]+)\)$/) {
			   $ProductCoeff = $1;
			}
			my $ProductCompartment = pop(@ProductData);
			if ($ProductCompartment =~ m/(\[\D\])$/) {
				$ProductCompartment = $1;
			} else {
				$ProductCompartment = "[c]";
			}
			if ($ReactantCompartment eq $ProductCompartment) {
				#print "Exactly matching product and reactant pair found: ".$OriginalEquation."\n";
				if ($ReactantCompartment eq "[c]") {
					$ReactantCompartment = "";
				}
				if ($ReactantCoeff == $ProductCoeff) {
					delete $ReactantHash{$Reactants[$i]};
					delete $ProductHash{$Reactants[$i]};
				} elsif ($ReactantCoeff > $ProductCoeff) {
					delete $ProductHash{$Reactants[$i]};
					$ReactantHash{$Reactants[$i]} = "(".($ReactantCoeff - $ProductCoeff).") ".$Reactants[$i].$ReactantCompartment;
					if (($ReactantCoeff - $ProductCoeff) == 1) {
						$ReactantHash{$Reactants[$i]} = $Reactants[$i].$ReactantCompartment;
					}
				} elsif ($ReactantCoeff < $ProductCoeff) {
					delete $ReactantHash{$Reactants[$i]};
					$ProductHash{$Reactants[$i]} = "(".($ProductCoeff - $ReactantCoeff).") ".$Reactants[$i].$ReactantCompartment;
					if (($ProductCoeff - $ReactantCoeff) == 1) {
						$ProductHash{$Reactants[$i]} = $Reactants[$i].$ReactantCompartment;
					}
				}
			}
		}
	}
	#Sorting the reactants and products by the cpd ID
	@Reactants = sort(keys(%ReactantHash));
	my $ReactantString = "";
	for (my $i=0; $i < @Reactants; $i++) {
		if ($ReactantHash{$Reactants[$i]} eq "") {
			$Error = 1;
		} else {
			if ($i > 0) {
			$ReactantString .= " + ";
			}
			$ReactantString .= $ReactantHash{$Reactants[$i]};
		}
	}
	my @Products = sort(keys(%ProductHash));
	my $ProductString = "";
	for (my $i=0; $i < @Products; $i++) {
		if ($ProductHash{$Products[$i]} eq "") {
			$Error = 1;
		} else {
			if ($i > 0) {
			$ProductString .= " + ";
			}
			$ProductString .= $ProductHash{$Products[$i]};
		}
	}
	if (length($ReactantString) == 0 || length($ProductString) == 0) {
		$Error = 1;
	}
	#Creating the forward, reverse, and full equations
	my $Equation = $ReactantString." <=> ".$ProductString;
	my $ReverseEquation = $ProductString." <=> ".$ReactantString;
	my $FullEquation = $Equation;
	#Removing protons from the equations used for matching
	$Equation =~ s/cpd00067\[e\]/TEMPH/gi;
	$Equation =~ s/\([^\)]+\)\scpd00067\s\+\s//g;
	$Equation =~ s/\s\+\s\([^\)]+\)\scpd00067//g;
	$Equation =~ s/cpd00067\s\+\s//g;
	$Equation =~ s/\s\+\scpd00067//g;
	$Equation =~ s/TEMPH/cpd00067\[e\]/g;
	$ReverseEquation =~ s/cpd00067\[e\]/TEMPH/gi;
	$ReverseEquation =~ s/\([^\)]+\)\scpd00067\s\+\s//g;
	$ReverseEquation =~ s/\s\+\s\([^\)]+\)\scpd00067//g;
	$ReverseEquation =~ s/cpd00067\s\+\s//g;
	$ReverseEquation =~ s/\s\+\scpd00067//g;
	$ReverseEquation =~ s/TEMPH/cpd00067\[e\]/g;
	#Clearing noncytosol compartment notation... compartment data is stored separately to improve reaction comparison
	if ($EquationCompartment eq "") {
		$EquationCompartment = "c";
	} elsif ($EquationCompartment ne "c") {
		$Equation =~ s/\[$EquationCompartment\]//g;
		$ReverseEquation =~ s/\[$EquationCompartment\]//g;
		$FullEquation =~ s/\[$EquationCompartment\]//g;
	}
	if ($EquationCompartment ne "c") {
		#print "\nCompartment:".$EquationCompartment."\n";
	}
	my $output = {
		direction => $Direction,
		code => $Equation,
		reverseCode => $ReverseEquation,
		fullEquation => $FullEquation,
		compartment => $EquationCompartment,
		error => $Error
	};
	return $output;
}

1;