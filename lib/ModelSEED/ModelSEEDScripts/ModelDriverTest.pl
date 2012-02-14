#!/usr/bin/perl -w

########################################################################
# Driver script for the model database interaction module
# Author: Christopher Henry
# Author email: chrisshenry@gmail.com
# Author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 8/26/2008
########################################################################

use strict;
use FIGMODEL;
use LWP::Simple;
$|=1;

#Setting system to ignore chilren so we don't create any zombie processes
$SIG{CHLD}='IGNORE';

#First checking to see if at least one argument has been provided
if (!defined($ARGV[0]) || $ARGV[0] eq "help") {
    print "This is the driver for the model database interaction module. Based on the information you require, you submit arguments to this script. The following arguments are currently recognized:\n";
    print "ARGUMENT: transporters?(CompoundListInputFile)\n";
    print "DESCRIPTION: The transporters in the database for the compounds listed in the (CompoundListFile) are printed to the stdout.\n\n";
    print "ARGUMENT: query?(Query input file)?(Object to query)?(exact)\n";
    print "DESCRIPTION: Searches the current biochemistry database for the queries indicated in (QueryListFile). Query results are printed to the stdout. (Object to query) indicates which object type should be queried: 'reactions' or 'compounds'. If (exact) is '1', then only exact matches are accepted; otherwise substring matches are accepted as well.\n\n";
    print "ARGUMENT: translatemodel?(Organism ID)\n";
    print "DESCRIPTION: \n\n";
    print "ARGUMENT: createmodelfile?(Organism ID)\n";
    print "DESCRIPTION: Creates the reaction list for the model, determines the directionality using the MFAToolkit, then interprets the correction file to fix an problematic directionalities. Models are printed in the 'Organisms/(Organism ID)/Model/Core(Organism ID).txt' and 'Organisms/(Organism ID)/Model/Fit(Organism ID).txt' files. If 'All' is used instead of a specific organism ID, this script is run for every genome in the SEED.\n\n";
    print "ARGUMENT: optimizemodel?(Organism ID)\n";
    print "DESCRIPTION: Identifies reactions from the reaction database that can be added to the 'Core' model specified in 'Organisms/(Organism ID)/Model/Core(Organism ID).txt' to fix false negative prediction conditions listed in the 'Organisms/(Organism ID)/Model/ExperimentalData/' directory. If 'All' is input for the (Organism ID), this command is run for every genome in the SEED.\n\n";
    print "ARGUMENT: simulateexperiment?(Model name)?(experiment specification)\n";
    print "DESCRIPTION: Simulates all of the conditions for the experiment type specified in (experiment specification) using the model specified in (Model name). Output is printed to the stdout.\nRecognized values for experiment specificaiton are:\n(i) 'biolog': model will be tested for growth on biolog media\n(ii) 'LBKO': each gene in the model will be knocked out and tested for growth on LB media\n(iii) 'MMKO': each gene in the model will be knocked out and tested for growth on glucose minimal media\n(iv) 'interval_filename': intervals specified in filename will be knockedout and tested for growth on LB media\n\n";
    print "ARGUMENT: comparemodels?(Model name one)?(Model name two)\n";
    print "DESCRIPTION: This command compares the reactions, genes, complexes, and annotation in (Model name one) and (Model name two). Results are printed to the stdout.\n\n";
    print "ARGUMENT: makehistogram?(Input filename)\n";
    print "DESCRIPTION: This command read in a list of strings from (Input filename) and prints the frequency of each unique string to the stdout.\n\n";
    print "ARGUMENT: classifyreactions?(Model name)?(Media)\n";
    print "DESCRIPTION: This command uses the MFAToolkit to classify the reactions in (Model name) and prints the results in the model directory: ReactionClasses(Model name).txt.'";
    print "ARGUMENT: printmodeldata?(Model name)\n";
    print "DESCRIPTION: This command uses the MFAToolkit to print the model data to a file in the model directory: 'Printed(Model name).txt.\n\n";
    print "ARGUMENT: processdatabase\n";
    print "DESCRIPTION: This command orders the MFAToolkit to process the reaction database estimating thermodynamic parameters, setting species charge, and balancing reactions.\n\n";
    print "ARGUMENT: updatedatabase?(Add new objects?)?(Process compounds)?(Process reactions)\n";
    print "DESCRIPTION: This command orders the database to be synced: meaning the mapping of compound and reaction IDs between Argonne,KEGG, and Model content will be repeated. If 'yes' is input for (Add new compounds?), than any unrecognized compounds and reactions will be added to the database. This should be run whenever a new KEGG has been downloaded, a new model has been added, or new compounds have been mapped.\n\n";
    print "ARGUMENT: printmodellist\n";
    print "DESCRIPTION: This command prints the list of models currently in the SEED model database to the stdout.\n\n";
    print "ARGUMENT: printmedialist\n";
    print "DESCRIPTION: This command prints the list of media formulations currently in the SEED model database to the stdout.\n\n";
    print "ARGUMENT: addnewcompoundcombination?(Compound ID one)?(Compound ID two)\n";
    print "DESCRIPTION: Adds a new pair of compounds to the pending list of compounds that should be combined. This list is processed whenever the updatedatabase command is used.\n\n";
    print "ARGUMENT: backupdatabase\n";
    print "DESCRIPTION: Creates a backup copy of the compound and reaction database incase the existing database becomes corrupted.\n\n";
    print "ARGUMENT: syncwithkegg\n";
    print "DESCRIPTION: Once a new KEGG version has been downloaded, this script syncs the database up with the KEGG.\n\n";
    print "ARGUMENT: syncmolfiles\n";
    print "DESCRIPTION: Occassionally the molfiles in the database are altered as databases evolve and manual curation continues. This script syncs up all of the various molfile sources: KEGG, genome-scale models, and manual corrections.\n\n";
    print "ARGUMENT: updatesubsystemclass\n";
    print "DESCRIPTION: \n\n";
    print "ARGUMENT: updatesubsystemscenarios\n";
    print "DESCRIPTION: \n\n";
    print "ARGUMENT: gapfillmodel\n";
    print "DESCRIPTION: \n\n";
    print "ARGUMENT: rungapgeneration\n";
    print "DESCRIPTION: \n\n";
}

#Creating model object which is almost certain to be necessary
my $model = new FIGMODEL->new();

#This variable will hold the name of a file that will be printed when a job finishes
my $FinishedFile = "NONE";
my $Status = "SUCCESS";

#Searching for recognized arguments
for (my $i=0; $i < @ARGV; $i++) {
    print "\nProcessing argument: ".$ARGV[$i]."\n";
    if ($ARGV[$i] =~ m/^transporters/) {
    	$Status = &transporters($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^query/) {
    	$Status = &query($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^adddirection/) {
    	$Status = &adddirection($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^createmodelfile/) {
    	$Status = &createmodelfile($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^optimizemodel/) {
    	$Status = &optimizemodel($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^simulateexperiment/) {
    	$Status = &simulateexperiment($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^comparemodels/) {
    	$Status = &comparemodels($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^makehistogram/) {
    	$Status = &makehistogram($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^classifyreactions/) {
    	$Status = &classifyreactions($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^printmodeldata/) {
    	$Status = &printmodeldata($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^processdatabase/) {
    	$Status = &processdatabase($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^updatedatabase/) {
    	$Status = &updatedatabase($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^printmodellist/) {
    	$Status = &printmodellist($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^printmedialist/) {
        $Status = &printmedialist($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^addnewcompoundcombination/) {
        $Status = &addnewcompoundcombination($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^backupdatabase/) {
        $Status = &backupdatabase($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^syncwithkegg/) {
        $Status = &syncwithkegg($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^syncmolfiles/) {
        $Status = &syncmolfiles($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^updatesubsystemclass/) {
        $Status = &updatesubsystemclass();
    } elsif ($ARGV[$i] =~ m/^updatesubsystemscenarios/) {
        $Status = &updatesubsystemscenarios();
    } elsif ($ARGV[$i] =~ m/^gapfillmodel/) {
        $Status = &gapfillmodel($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^optimizedeletions/) {
        $Status = &optimizedeletions($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^combinemappingsources/) {
        $Status = &combinemappingsources($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^rungapgeneration/) {
        $Status = &rungapgeneration($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^gathermodelstats/) {
        $Status = &gathermodelstats($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^rundeletions/) {
        $Status = &rundeletions($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^installdb/) {
        $Status = &installdb($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^getessentialitydata/) {
        $Status = &getessentialitydata($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^getgapfillingdependancy/) {
        $Status = &getgapfillingdependancy($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^editdb/) {
        $Status = &editdb($ARGV[$i]);
	} elsif ($ARGV[$i] =~ m/^printsbmlfiles/) {
        $Status = &printsbmlfiles($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^reconciliation/) {
        $Status = &reconciliation($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^integrategrowmatchsolution/) {
        $Status = &integrategrowmatchsolution($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^repairmodelfiles/) {
        $Status = &repairmodelfiles($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^addcompoundstomedia/) {
        $Status = &addcompoundstomedia($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^addbiologtransporters/) {
        $Status = &addbiologtransporters($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^printgenomefeatures/) {
        $Status = &printgenomefeatures($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^parsebiolog/) {
        $Status = &parsebiolog($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^openwebpage/) {
        $Status = &openwebpage($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^testdatabasebiomass/) {
        $Status = &testdatabasebiomass($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^rollbackmodel/) {
        $Status = &rollbackmodel($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^getgapfillingstats/) {
        $Status = &getgapfillingstats($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^collectmolfiles/) {
        $Status = &collectmolfiles($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^testmodelgrowth/) {
        $Status = &testmodelgrowth($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^buildmetagenomemodel/) {
        $Status = &buildmetagenomemodel($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^gapfillmetagenome/) {
        $Status = &gapfillmetagenome($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^buildbiomassreaction/) {
        $Status = &buildbiomassreaction($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^optimizeannotations/) {
        $Status = &optimizeannotations($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^datagapfill/) {
        $Status = &datagapfill($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^testsolutions/) {
        $Status = &testsolutions($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^schedule/) {
        $Status = &schedule($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^implementannoopt/) {
        $Status = &implementannoopt($ARGV[$i]);
    } elsif ($ARGV[$i] =~ m/^finish\?(.+)/) {
        $FinishedFile = $1;
    } else {
		print "ARGUMENT: ".$ARGV[$i]." NOT RECOGNIZED.\n";
    }
}

#Printing the finish file if specified
if ($FinishedFile ne "NONE") {
    if ($FinishedFile =~ m/^\//) {
        FIGMODEL::PrintArrayToFile($FinishedFile,[$Status]);
    } else {
        FIGMODEL::PrintArrayToFile($model->{"database message file directory"}->[0].$FinishedFile,[$Status]);
    }
}

exit();

#Individual subroutines are all listed here
sub transporters {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: transporters?(CompoundListInputFile).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Getting the list of compound IDs from the input file
    my $Query = FIGMODEL::LoadSingleColumnFile($Data[1],";");
    my $CompoundNum = @{$Query};
    my $TransportDataHash = $model->GetTransportReactionsForCompoundIDList($Query);
    my @CompoundsWithTransporters = keys(%{$TransportDataHash});
    my $NumCompoundsWithTransporters = @CompoundsWithTransporters;

    #Printing the results
    print "Transporters found for ".$NumCompoundsWithTransporters." out of ".$CompoundNum." input compound IDs.\n\n";
    print "Compound;Transporter ID;Equation\n";
    for (my $i=0; $i < @{$Query}; $i++) {
	print $Query->[$i].";";
	if (defined($TransportDataHash->{$Query->[$i]})) {
	    my @TransportList = keys(%{$TransportDataHash->{$Query->[$i]}});
	    for (my $j=0; $j < @TransportList; $j++) {
		print $TransportList[$j].";".$TransportDataHash->{$Query->[$i]}->{$TransportList[$j]}->{"EQUATION"}->[0].";";
	    }
	}
	print "\n";
    }

    return;
}

sub query {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 4) {
        print "Syntax for this command: query?(Query input file)?(Object to query)?(exact).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Loading the query list from file
    my $QueryList = FIGMODEL::LoadSingleColumnFile($Data[1],"\t");
    my $QueryNum = @{$QueryList};

    #Calling the query function
    my $Results = $model->QueryCompoundDatabase($QueryList,$Data[3],$Data[2]);

    #Printing the results
    my $MatchNum = 0;
    print "Matching ".$Data[2]." found for ".$MatchNum." out of ".$QueryNum." queries.\n\n";
    print "INDEX;QUERY;MATCHING IDs;MATCHING NAMES;MATCHING HIT VALUE\n";
    my $Count = 0;
    foreach my $Item (@{$Results}) {
	if ($Item != 0) {
	    $MatchNum++;
	    foreach my $Match (@{$Item}) {
		if (defined($Match->{"HIT VALUE"})) {
		    print $Count.";".$QueryList->[$Count].";".$Match->{"MINORGID"}->[0].";".join("|",@{$Match->{"NAME"}}).";".$Match->{"HIT VALUE"}->[0]."\n";
		} else {
		    print $Count.";".$QueryList->[$Count].";".$Match->{"MINORGID"}->[0].";".join("|",@{$Match->{"NAME"}}).";FULL WORD MATCH\n";
		}
	    }
	} else {
	    print $Count.";".$QueryList->[$Count].";NO HITS\n";
	}
	$Count++;
    }
}

sub createmodelfile {
    my($Argument) = @_;
    #/vol/rast-prod/jobs/(job number)/rp/(genome id)/
    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: createmodelfile?(Organism ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    $model->CombineRoleReactionMappingSources();

    if ($Data[1] =~ m/LIST-(.+)$/) {
        my $List = FIGMODEL::LoadSingleColumnFile($1,"");
        for (my $i=0; $i < @{$List}; $i++) {
            $model->CreateModelReactionList($List->[$i],"NONE");
        }
        print "Model file successfully generated.\n\n";
        return;
    }

    #Checking if the organism ID has a job number in it
    my $OrganismID = $Data[1];
    my $JobNumber = "NONE";
    if ($Data[1] =~ m/^(\S+)-(\S+)$/) {
        $OrganismID = $2;
        $JobNumber = $1;
    }

    #Creating the reaction list
    my $Result = $model->CreateModelReactionList($OrganismID,$JobNumber);
    if ($Result == 0) {
        print "Model file not generated.\n\n";
        return 0;
    } elsif ($Result == 1) {
        print "Model file successfully generated.\n\n";
        return 1;
    } elsif ($Result == 2) {
        print "Rebuild resulted in no model changes.\n\n";
        return 2;
    }
}

sub updatesubsystemclass {
    my($Argument) = @_;

    $model->UpdateSubsystemClassFile();

    print "Subsystem class file printed.\n\n";
}

sub translatemodel {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: translatemodel?(Organism ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    $model->TranslateModelGeneIDs($Data[1]);

    print "Model file successfully translated.\n\n";
}

sub datagapfill {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: datagapfill?(Model ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Running the gap filling algorithm
    print "Running gapfilling on ".$Data[1]."\n";
    if ($model->GapFillingAlgorithm($Data[1]) == 1) {
        #Scheduling the solution testing to run
        #system($model->{"Model driver executable"}->[0]." \"schedule:ADD:testsolutions?".$Data[1]."?-1?GF:BACK:test:NOHUP\"");
        print "Data gap filling successfully completed!\n";
        return "SUCCESS";
    }

    print "Error encountered during data gap filling!\n";
    return "FAIL";
}

sub optimizeannotations {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: optimizeannotations?(Organism ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Optimizing the annotations
    if ($Data[1] =~ m/LIST-(.+)$/) {
        my $List = FIGMODEL::LoadSingleColumnFile($1,"");
        $model->OptimizeAnnotation($List);
    }
}

sub implementannoopt {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: implementannoopt?(Commands)?(Filename).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->AdjustAnnotation($Data[1);
}

sub simulateexperiment {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 3) {
        print "Syntax for this command: simulateexperiment?(Model name)?(experiment specification).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Getting the list of models to be analyzed
    my @ModelList;
    if ($Data[1] =~ m/LIST-(.+)/) {
        my $List = FIGMODEL::LoadSingleColumnFile($1,"");
        if (defined($List)) {
            push(@ModelList,@{$List});
        }
    } else {
        push(@ModelList,$Data[1]);
    }

    #Checking if the user asked to classify the reactions as well
    if (defined($Data[3] && $Data[3] eq "Classify")) {
        $model->{"RUN PARAMETERS"}->{"Classify reactions during simulation"} = 1;
    }

    #Creating a table to store the results of the analysis
    my $ResultsTable = new FIGMODELTable(["Model","Total data","Total biolog","Total gene KO","False positives","False negatives","Correct positives","Correct negatives","Biolog False positives","Biolog False negatives","Biolog Correct positives","Biolog Correct negatives","KO False positives","KO False negatives","KO Correct positives","KO Correct negatives"],$model->{"database message file directory"}->[0]."SimulationResults-".$Data[2].".txt",[],";","|",undef);

    #Calling the model function that runs the experiment
    for (my $i=0; $i < @ModelList; $i++) {
        print "Processing ".$ModelList[$i]."\n";
        #Creating a table to store the results of the analysis
        my $ClassificationResultsTable = new FIGMODELTable(["Database ID","Positive","Negative","Postive variable","Negative variable","Variable","Blocked"],$model->{"database message file directory"}->[0]."ClassificationResults-".$ModelList[$i]."-".$Data[2].".txt",[],";","|",undef);
        my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$ErrorVector,$HeadingVector) = $model->RunAllStudiesWithData($ModelList[$i],$Data[2]);
        my @ErrorArray = split(/;/,$ErrorVector);
        my @HeadingArray = split(/;/,$HeadingVector);
        my $NewRow = {"Model" => [$ModelList[$i]],"Total data" => [$FalsePostives+$FalseNegatives+$CorrectNegatives+$CorrectPositives],"Total biolog" => [0],"Total gene KO" => [0],"False positives" => [$FalsePostives],"False negatives", => [$FalseNegatives],"Correct positives" => [$CorrectPositives],"Correct negatives" => [$CorrectNegatives],"Biolog False positives" => [0],"Biolog False negatives" => [0],"Biolog Correct positives" => [0],"Biolog Correct negatives" => [0],"KO False positives" => [0],"KO False negatives" => [0],"KO Correct positives" => [0],"KO Correct negatives" => [0]};
        for (my $j=0; $j < @HeadingArray; $j++) {
            if ($HeadingArray[$j] =~ m/^Media/) {
                $NewRow->{"Total biolog"}->[0]++;
                if ($ErrorArray[$j] == 0) {
                    $NewRow->{"Biolog Correct positives"}->[0]++;
                } elsif ($ErrorArray[$j] == 1) {
                    $NewRow->{"Biolog Correct negatives"}->[0]++;
                } elsif ($ErrorArray[$j] == 2) {
                    $NewRow->{"Biolog False positives"}->[0]++;
                } elsif ($ErrorArray[$j] == 3) {
                    $NewRow->{"Biolog False negatives"}->[0]++;
                }
            } elsif ($HeadingArray[$j] =~ m/^Gene\sKO/) {
                $NewRow->{"Total gene KO"}->[0]++;
                if ($ErrorArray[$j] == 0) {
                    $NewRow->{"KO Correct positives"}->[0]++;
                } elsif ($ErrorArray[$j] == 1) {
                    $NewRow->{"KO Correct negatives"}->[0]++;
                } elsif ($ErrorArray[$j] == 2) {
                    $NewRow->{"KO False positives"}->[0]++;
                } elsif ($ErrorArray[$j] == 3) {
                    $NewRow->{"KO False negatives"}->[0]++;
                }
            }
        }
        $ResultsTable->add_row($NewRow);
        if (defined($Data[3] && $Data[3] eq "Classify")) {
            my @ReactionIDList = keys(%{$model->{"Simulation classification results"}});
            for (my $i=0; $i < @ReactionIDList; $i++) {
                $ClassificationResultsTable->add_row({"Database ID" => [$ReactionIDList[$i]],"Positive" => [$model->{"Simulation classification results"}->{$ReactionIDList[$i]}->{"P"}],"Negative" => [$model->{"Simulation classification results"}->{$ReactionIDList[$i]}->{"N"}],"Postive variable" => [$model->{"Simulation classification results"}->{$ReactionIDList[$i]}->{"PV"}],"Negative variable" => [$model->{"Simulation classification results"}->{$ReactionIDList[$i]}->{"NV"}],"Variable" => [$model->{"Simulation classification results"}->{$ReactionIDList[$i]}->{"V"}],"BLOCKED" => [$model->{"Simulation classification results"}->{$ReactionIDList[$i]}->{"B"}]});
            }
            $ClassificationResultsTable->save();
        }
        undef $ClassificationResultsTable;
    }

    #Printing the results
    $ResultsTable->save();

    return 0;
}

sub comparemodels {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
	if (@Data >= 2 && $Data[1] =~ m/LIST-(.+)/) {
		my $List = FIGMODEL::LoadSingleColumnFile($1,"");
		my $CombinedResults;
        foreach my $Pair (@{$List}) {
            push(@{$CombinedResults->{"COMPARISON"}},$Pair);
            my ($ModelOne,$ModelTwo) = split(/-/,$Pair);
            my $ComparisonResults = $model->CompareModels($ModelOne,$ModelTwo);
            my @KeyList = keys(%{$ComparisonResults});
            foreach my $Key (@KeyList) {
                my $Number = shift(@{$ComparisonResults->{$Key}});
                my $Items = join(",",@{$ComparisonResults->{$Key}});
                $Key =~ s/$ModelOne/A/g;
                $Key =~ s/$ModelTwo/B/g;
                push(@{$CombinedResults->{$Key}},$Number);
                push(@{$CombinedResults->{"Items ".$Key}},$Items);
            }
		}
		FIGMODEL::SaveHashToHorizontalDataFile($model->{"database message file directory"}->[0]."ModelComparison.txt",";",$CombinedResults);
        my $EquivalentReactionArray;
        my @ReactionArray = keys(%{$model->{"EquivalentReactions"}});
        my $ReactionTable = $model->GetDBTable("REACTIONS");
        foreach my $Reaction (@ReactionArray) {
            my @EquivalentReactions = keys(%{$model->{"EquivalentReactions"}->{$Reaction}});
            foreach my $EquivReaction (@EquivalentReactions) {
                my $LoadedReaction = $model->LoadObject($Reaction);
                my $LoadedEquivReaction = $model->LoadObject($EquivReaction);
                if (!defined($model->{"ModelReactions"}->{$Reaction}) && !defined($model->{"ForeignReactions"}->{$EquivReaction})) {
                    push(@{$EquivalentReactionArray},$Reaction.";".$EquivReaction.";".$LoadedReaction->{"DEFINITION"}->[0].";".$LoadedEquivReaction->{"DEFINITION"}->[0].";".$model->{"EquivalentReactions"}->{$Reaction}->{$EquivReaction}->{"Count"}.";".$model->{"EquivalentReactions"}->{$Reaction}->{$EquivReaction}->{"Source"});
                }
            }
        }
        FIGMODEL::PrintArrayToFile($model->{"database message file directory"}->[0]."EquivalentReactions.txt",$EquivalentReactionArray);
    } elsif (@Data >= 3) {
		my $ComparisonResults = $model->CompareModels($Data[1],$Data[2]);
		FIGMODEL::SaveHashToHorizontalDataFile($model->{"database message file directory"}->[0].$Data[1]."-".$Data[2].".txt",";",$ComparisonResults);
	} else {
		print "Syntax for this command: comparemodels?(Model one)?(Model two) or comparemodels?LIST-(name of file with ; delimited pairs).\n\n";
        exit(1);
	}

    #Printing run success line
    print "Model comparison successful.\n\n";
}

sub makehistogram {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: makehistogram?(Input filename)\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    if ($Data[1]) {
        my $DataArrayRef = FIGMODEL::LoadSingleColumnFile($Data[1],"");
        my $HistoHashRef = FIGMODEL::CreateHistogramHash($DataArrayRef);
        FIGMODEL::SaveHashToHorizontalDataFile($model->{"database message file directory"}->[0]."HistogramOutput.txt","\t",$HistoHashRef);
    }

    #Printing run success line
    print "Histogram generation successful.\n\n";
}

sub classifyreactions {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: classifyreactions?(Model name)?(Media)?(Filename)?(Version).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    if (!defined($Data[2])) {
        $Data[2] = "Complete";
    }

    my $ReactionClassTable = $model->ClassifyModelReactions($Data[1],$Data[2],$Data[4]);
    $ReactionClassTable->save($Data[3]);
}

sub printmodeldata {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: printmodeldata?(Model name).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    $model->PrintModelGenomeData($Data[1]);
    $model->PrintModelDataToFile($Data[1]);

    print "Model data successfully printed.\n\n";
}

#Inspected: working as intended
sub processdatabase {
    my($Argument) = @_;

    $model->ProcessDatabaseWithMFAToolkit();
}

#Inspected: working as intended
sub updatedatabase {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 4) {
        print "Syntax for this command: updatedatabase?(Add new objects?)?(Process compounds)?(Process reactions).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    if ($Data[2] eq "yes") {
        #Next, updating the compound mapping
        $model->UpdateCompoundDatabase();
        #Adding new compounds to the database if requested
        if ($Data[1] eq "yes") {
            if ($model->AddUnmappedCompoundsToArgonneDatabase() > 0) {
                $model->UpdateCompoundDatabase();
            }
        }
    }
    if ($Data[3] eq "yes") {
        #Next, updating the reaction mapping
        $model->UpdateReactionDatabase();
        #Adding new reactions to the database if requested
        if ($Data[1] eq "yes") {
            if ($model->AddUnmappedReactionsToArgonneDatabase() > 0) {
                $model->UpdateReactionDatabase();
            }
        }
    }
}

#Inspected: appears to be working
sub printmodellist {
    my $ModelList = $model->GetListOfCurrentModels();
    print "Current model list for SEED:\n";
    for (my $i=0; $i < @{$ModelList}; $i++) {
        print $ModelList->[$i]."\n";
    }
}

#Inspected: appears to be working
sub printmedialist {
    my $MediaList = $model->GetListOfMedia();
    print "Current media list for SEED:\n";
    for (my $i=0; $i < @{$MediaList}; $i++) {
        print $MediaList->[$i]."\n";
    }
}

#Inspected: working as intended
sub addnewcompoundcombination {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 3) {
        print "Syntax for this command: addnewcompoundcombination?(Compound ID one)?(Compound ID two).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    $model->AddNewPendingCompoundCombination($Data[1].";".$Data[2]);
}

sub backupdatabase {
    $model->BackupDatabase();
}

#Partially inspected: will complete inspection upon next KEGG update
sub syncwithkegg {
    $model->SyncWithTheKEGG();
}

#Inspected: working as intended
sub syncmolfiles {
    $model->SyncDatabaseMolfiles();
}

sub updatesubsystemscenarios {
    $model->ParseHopeSEEDReactionFiles();
}

sub combinemappingsources {
    $model->CombineRoleReactionMappingSources();
}

sub gapfillmodel {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: gapfillmodel?(Organism ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Gap filling the model
    $model->GapFillModel("Core".$Data[1]);
    $model->AddBiologTransporters("Core".$Data[1]);

    return "SUCCESS";
}

sub testsolutions {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 4) {
        print "Syntax for this command: testsolutions?(Model ID)?(Index)?(GapFill)?(Number of processors).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #Setting the processor index
    my $ProcessorIndex = -1;
    if (defined($Data[2])) {
        $ProcessorIndex = $Data[2];
    }

    #Setting the number of processors
    my $NumProcessors = $model->{"Solution testing processors"}->[0];
    if (defined($Data[4])) {
        $NumProcessors = $Data[4];
    }

    #Running the test algorithm
    print "Testing solutions for ".$Data[1]." with ".$NumProcessors." processors.\n";
    $model->TestSolutions($Data[1],$NumProcessors,$ProcessorIndex,$Data[3]);

    #Checking that the error matrices have really been generated
    (my $Directory,$Data[1]) = $model->GetDirectoryForModel($Data[1]);
    if (!-e $Directory.$Data[1]."-".$Data[3]."EM.txt") {
        return "ERROR MATRIX FILE NOT GENERATED!";
    } elsif (!-e $Directory.$Data[1]."-OPEM.txt") {
        return "ORIGINAL PERFORMANCE FILE NOT FOUND!"
    }

    return "SUCCESS";
}

sub optimizedeletions {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 5) {
        print "Syntax for this command: optimizedeletions?(Model ID)?(Media)?(Min deletions)?(Max deletions).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    (my $Directory,my $ModelName) = $model->GetDirectoryForModel($Data[1]);

    my $UniqueFilename = $model->filename();

    system($model->{"MFAToolkit executable"}->[0].' parameterfile Parameters/DeletionOptimization.txt resetparameter "Minimum number of deletions" '.$Data[3].' resetparameter "Maximum number of deletions" '.$Data[4].' resetparameter "user bounds filename" "Media/'.$Data[2].'.txt" resetparameter output_folder "'.$UniqueFilename.'/" LoadCentralSystem "'.$Directory.$ModelName.'.txt" > '.$model->{"Reaction database directory"}->[0]."log/".$UniqueFilename.'.log');
}

sub rungapgeneration {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: rungapgeneration?(Model ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    my $Filename = "";
    my $NumberOfProcessors = 1;
    my $ProcessorIndex = -1;
    if (defined($Data[2])) {
        $NumberOfProcessors = $Data[2];
    }
    if (defined($Data[3])) {
        $ProcessorIndex = $Data[3];
    }
    if (defined($Data[4])) {
        $Filename = $Data[4];
    }

    $model->GapGenerationAlgorithm($Data[1],$NumberOfProcessors,$ProcessorIndex,$Filename);
}

sub gathermodelstats {
    my($Argument) = @_;

    #$model->GatherModelStatistics();

    my $ModelTable = $model->GetDBTable("MODEL LIST");
    for (my $i=0; $i < $ModelTable->size(); $i++) {
        $model->UpdateModelStats($ModelTable->get_row($i)->{"MODEL ID"}->[0]);
    }
}

sub rundeletions {
    my($Argument) = @_;
    #/vol/rast-prod/jobs/(job number)/rp/(genome id)/
    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: rundeletions?model.\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    #The first argument should always be the model (or model list), all subsequent arguments are optional
    my $List;
    if ($Data[1] =~ m/LIST-(.+)$/) {
        $List = FIGMODEL::LoadSingleColumnFile($1,"");
    } elsif ($Data[1] eq "ALL") {
        my $ModelData = $model->GetListOfCurrentModels();
        for (my $i=0; $i < @{$ModelData}; $i++) {
            push(@{$List},$ModelData->[$i]->{"MODEL ID"}->[0]);
        }
    } else {
        push(@{$List},$Data[1]);
    }

    #Setting the media
    my $Media = "Complete";
    if (defined($Data[2])) {
        $Media = $Data[2];
    }

    #Running MFA on the model list
    my $Results;
    for (my $i=0; $i < @{$List}; $i++) {
        my $DeletionResultsTable = $model->PredictEssentialGenes($List->[$i],$Media);
        my $OrganismID = $model->genomeid_of_model($List->[$i]);
        if (defined($DeletionResultsTable)) {
            #Printing essentiality data in the model directory
            (my $Directory,$List->[$i]) = $model->GetDirectoryForModel($List->[$i]);
            my $Filename = $Directory.$Media."-EssentialGenes.txt";
            if (open (OUTPUT, ">$Filename")) {
                for (my $j=0; $j < $DeletionResultsTable->size(); $j++) {
                    if ($DeletionResultsTable->get_row($j)->{"Insilico growth"}->[0] < 0.0000001) {
                        print OUTPUT "fig|".$OrganismID.".".$DeletionResultsTable->get_row($j)->{"Experiment"}->[0]."\n";
                        push(@{$Results->{$List->[$i]}},$DeletionResultsTable->get_row($j)->{"Experiment"}->[0]);
                    }
                }
                close(OUTPUT);
            }
            system("cp ".$Directory.$Media."-EssentialGenes.txt"." /home/chenry/EssentialGeneLists/".$OrganismID."-".$Media."-Essentials.txt");
        }
    }

    #Printing combined results of the entire run in the log directory
    my $Filename = $model->{"database message file directory"}->[0]."GeneEssentialityAnalysisResults.txt";
    if (open (OUTPUT, ">$Filename")) {
        my @ModelList = keys(%{$Results});
        print OUTPUT "Model;Number of essential genes;Essential genes\n";
        foreach my $Item (@ModelList) {
            my $NumberOfEssentialGenes = @{$Results->{$Item}};
            print OUTPUT $Item.";".$NumberOfEssentialGenes.";".join(",",@{$Results->{$Item}})."\n";
        }
        close(OUTPUT);
    }
    print "Model deletions successfully completed.\n\n";
}

sub installdb {
    my($Argument) = @_;

    $model->InstallDatabase();
}

sub editdb {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: editdb?edit commands filename.\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    $model->EditDatabase($Data[1]);
}

sub getessentialitydata {
    my($Argument) = @_;

    $model->GetSEEDEssentialityData();
}

sub getgapfillingdependancy {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: getgapfillingdependancy?(Model ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    if ($Data[1] =~ m/LIST-(.+)$/) {
        my $List = FIGMODEL::LoadSingleColumnFile($1,"");
        for (my $i=0; $i < @{$List}; $i++) {
            getgapfillingdependancy("getgapfillingdependancy?".$List->[$i]);
        }
        return;
    }

    $model->IdentifyDependancyOfGapFillingReactions($Data[1]);
}

sub runmfa {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
        print "Syntax for this command: getgapfillingdependancy?(Model ID).\n\n";
        return "ARGUMENT SYNTAX FAIL";
    }

    if ($Data[1] =~ m/LIST-(.+)$/) {
        my $List = FIGMODEL::LoadSingleColumnFile($1,"");
        for (my $i=0; $i < @{$List}; $i++) {
            getgapfillingdependancy("getgapfillingdependancy?".$List->[$i]);
        }
        return;
    }

    $model->IdentifyDependancyOfGapFillingReactions($Data[1]);
}

sub printsbmlfiles {
	my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: printsbmlfiles?(Model ID).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    if ($Data[1] =~ m/LIST-(.+)$/) {
        my $List = FIGMODEL::LoadSingleColumnFile($1,"");
        for (my $i=0; $i < @{$List}; $i++) {
			print "Processing ".$List->[$i]."\n";
            $model->PrintSBMLFile($List->[$i]);
		}
    } elsif ($Data[1] eq "ALL") {
		my $ModelList = $model->GetListOfCurrentModels();
        for (my $i=0; $i < @{$ModelList}; $i++) {
			print "Processing ".$ModelList->[$i]->{"MODEL ID"}->[0]."\n";
            $model->PrintSBMLFile($ModelList->[$i]->{"MODEL ID"}->[0]);
		}
	} else {
		$model->PrintSBMLFile($Data[1]);
	}

	print "SBML file successfully generated.\n\n";
    return;
}

sub reconciliation {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: reconciliation?(Model ID).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->SolutionReconciliation($Data[1]);
}

sub integrategrowmatchsolution{
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 4) {
		print "Syntax for this command: integrategrowmatchsolution?(Model ID)?(GrowMatch solution file)?(NewModelFilename).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    #Loading GrowMatch solution file
    (my $Directory,my $ModelName) = $model->GetDirectoryForModel($Data[1]);
    if (!(-e $Directory.$Data[2])) {
        print "Could not find grow match solution file!\n";
        return;
    }
    my $ReactionArray;
    my $DirectionArray;
    my $SolutionData = FIGMODEL::LoadMultipleColumnFile($Directory.$Data[2],";");
    for (my $i=0; $i < @{$SolutionData}; $i++) {
        push(@{$ReactionArray},$SolutionData->[$i]->[0]);
        push(@{$DirectionArray},$SolutionData->[$i]->[1]);
    }

    #Creating the new model file
    my $Changes = $model->IntegrateGrowMatchSolution($Data[1],$Directory.$Data[3],$ReactionArray,$DirectionArray,"GROWMATCH",1,1);
    if (defined($Changes)) {
        my @ChangeKeyList = keys(%{$Changes});
        for (my $i=0; $i < @ChangeKeyList; $i++) {
            print $ChangeKeyList[$i].";".$Changes->{$ChangeKeyList[$i]}."\n";
        }
    }
}

sub repairmodelfiles {
    my($Argument) = @_;

    my $Models = $model->GetListOfCurrentModels();

    for (my $i=0; $i < @{$Models}; $i++) {
        my $Model = $model->GetDBModel($Models->[$i]->{"MODEL ID"}->[0]);
        FIGMODEL::SaveTable($Model);
    }
}

sub addcompoundstomedia {
    my($Argument) = @_;

    my @Filenames = glob($model->{"Media directory"}->[0]."*");
	for (my $i=0; $i < @Filenames; $i++) {
		if ($Filenames[$i] =~ m/\.txt/) {
			my $MediaTable = FIGMODELTable::load_table($Filenames[$i],";","",0,["VarName"]);
            if (!defined($MediaTable->get_row_by_key("cpd00099","VarName"))) {
                $MediaTable->add_row({"VarName" => ["cpd00099"],"VarType" => ["DRAIN_FLUX"],"VarCompartment" => ["e"],"Min" => [-100],"Max" => [100]});
            }
            if (!defined($MediaTable->get_row_by_key("cpd00058","VarName"))) {
                $MediaTable->add_row({"VarName" => ["cpd00058"],"VarType" => ["DRAIN_FLUX"],"VarCompartment" => ["e"],"Min" => [-100],"Max" => [100]});
            }
            if (!defined($MediaTable->get_row_by_key("cpd00149","VarName"))) {
                $MediaTable->add_row({"VarName" => ["cpd00149"],"VarType" => ["DRAIN_FLUX"],"VarCompartment" => ["e"],"Min" => [-100],"Max" => [100]});
            }
            if (!defined($MediaTable->get_row_by_key("cpd00030","VarName"))) {
                $MediaTable->add_row({"VarName" => ["cpd00030"],"VarType" => ["DRAIN_FLUX"],"VarCompartment" => ["e"],"Min" => [-100],"Max" => [100]});
            }
            if (!defined($MediaTable->get_row_by_key("cpd00034","VarName"))) {
                $MediaTable->add_row({"VarName" => ["cpd00034"],"VarType" => ["DRAIN_FLUX"],"VarCompartment" => ["e"],"Min" => [-100],"Max" => [100]});
            }
            $MediaTable->save();
		}
	}
}

sub addbiologtransporters {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: addbiologtransporters?(Model ID).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->AddBiologTransporters($Data[1]);
}

sub printgenomefeatures {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: printgenomefeatures?(genome ID)-(job ID)?(filename).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    #Setting the filename
    my $Filename = $model->{"database message file directory"}->[0]."Features-".$Data[1].".txt";
    if (defined($Data[2])) {
        $Filename = $Data[2];
    }

    #Setting the job ID
    my $JobID = undef;
    my $OrganismID = $Data[1];
    if ($Data[1] =~ m/(\d+\.\d+)-(\d+)/) {
        $OrganismID = $1;
        $JobID = $2;
    }

    #Getting the feature table
    my $FeaturesTable = $model->GetGenomeFeatureTable($OrganismID,$JobID);
    #Printing the table
    $FeaturesTable->save($Filename);
}

sub parsebiolog {
    my($Argument) = @_;

    $model->ParseBiolog();
}

sub openwebpage {
    my($Argument) = @_;

    for (my $i=1; $i < 311; $i++) {
        my $url = "http://tubic.tju.edu.cn/deg/information.php?ac=DEG10140";
        if ($i < 10) {
            $url .= "00".$i;
        } elsif ($i < 100) {
            $url .= "0".$i;
        } else {
            $url .= $i;
        }
        my $pid = fork();
        if ($pid == 0) {
            my $Page = get $url;
            if (defined($Page) && $Page =~ m/(GI:\d\d\d\d\d\d\d\d)/) {
               print $1."\n";
            }
            exit 0;
        } else {
            sleep(5);
            if (kill(9,$pid) == 1) {
                $i--;
            }
        }

    }
}

sub testdatabasebiomass {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: testdatabasebiomass?(Biomass reaction)?(Media)?(Balanced reactions only).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    my $Biomass = $Data[1];
    my $Media = "Complete";
    if (defined($Data[2])) {
        $Media = $Data[2];
    }
    my $BalancedReactionsOnly = 1;
    if (defined($Data[3])) {
        $BalancedReactionsOnly = $Data[3];
    }
    my $ProblemReportTable = $model->TestDatabaseBiomassProduction($Biomass,$Media,$BalancedReactionsOnly);

    if (!defined($ProblemReportTable)) {
        print "No problem report returned. An error occurred!\n";
        return;
    }

    if (defined($ProblemReportTable->get_row(0)) && defined($ProblemReportTable->get_row(0)->{"Objective"}->[0])) {
        if ($ProblemReportTable->get_row(0)->{"Objective"}->[0] == 10000000 || $ProblemReportTable->get_row(0)->{"Objective"}->[0] < 0.0000001) {
            print "No biomass was generated. Could not produce the following biomass precursors:\n";
            if (defined($ProblemReportTable->get_row(0)->{"Individual metabolites with zero production"})) {
                print join("\n",split(/\|/,$ProblemReportTable->get_row(0)->{"Individual metabolites with zero production"}->[0]))."\n";
			}
        } else {
            print "Biomass successfully generated with objective value of: ".$ProblemReportTable->get_row(0)->{"Objective"}->[0]."\n";
        }
    }
}

sub rollbackmodel {
    my($Argument) = @_;

    #Checking the argument to ensure all required parameters are present
    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: rollbackmodel?(Model).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->RollBackModel($Data[1]);
}

sub getgapfillingstats {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: getgapfillingstats?(List filename).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }
    my $List = FIGMODEL::LoadSingleColumnFile($Data[1],"");

    $model->GatherGapfillingStatistics(@{$List});
}

sub collectmolfiles {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 3) {
		print "Syntax for this command: collectmolfiles?(List filename)?(Output directory).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }
    my $List = FIGMODEL::LoadSingleColumnFile($Data[1],"");

    for (my $i=0; $i < @{$List}; $i++) {
        if (-e $model->{"Argonne molfile directory"}->[0]."pH7/".$List->[$i].".mol") {
            system("cp ".$model->{"Argonne molfile directory"}->[0]."pH7/".$List->[$i].".mol ".$Data[2].$List->[$i].".mol");
        } elsif (-e $model->{"Argonne molfile directory"}->[0].$List->[$i].".mol") {
            system("cp ".$model->{"Argonne molfile directory"}->[0].$List->[$i].".mol ".$Data[2].$List->[$i].".mol");
        }
    }
}

sub testmodelgrowth {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 3) {
		print "Syntax for this command: testmodelgrowth?(Model ID)?(Media)?(Version).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    my $UniqueFilename = $model->filename();
    my $Version = undef;
    my @DataArray = split(/\|/,$Data[3]);
    my $Parameters = {"optimize metabolite production if objective is zero" => 1};
    foreach my $Item (@DataArray) {
        if ($Item =~ m/^V/) {
            $Version = $Item;
        } elsif ($Item =~ m/RKO:(.+)/) {
            $Parameters->{"Reactions to knockout"} = $1;
        } elsif ($Item =~ m/GKO:(.+)/) {
            $Parameters->{"Genes to knockout"} = $1;
        }
    }
    system($model->GenerateMFAToolkitCommandLineCall($UniqueFilename,$Data[1],$Data[2],["ProductionMFA"],$Parameters,$Data[1]."-".$Data[2]."-GrowthTest.txt",undef,$Version));
    my $ProblemReport = $model->LoadProblemReport($UniqueFilename);

    my $Row = $ProblemReport->get_row(0);
    if (defined($Row) && defined($Row->{"Objective"}->[0])) {
        if ($Row->{"Objective"}->[0] < 0.00000001) {
            print "Model did not grow in specified media. The following biomass precursors could not be produced:\n";
            print join("\n",split(/\|/,$Row->{"Individual metabolites with zero production"}->[0]))."\n";
        } else {
            print "Model grew with biomass flux of: ".$Row->{"Objective"}->[0]."\n";
        }
    }

    if ($model->{"preserve all log files"}->[0] ne "yes") {
        $model->cleardirectory($UniqueFilename);
        unlink($model->{"database message file directory"}->[0].$Data[1]."-".$Data[2]."-GrowthTest.txt");
    }
}

sub buildmetagenomemodel {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: buildmetagenomemodel?(Metagenome name)?(E-value).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->CreateMetaGenomeReactionList($Data[1],$Data[2]);
}

sub gapfillmetagenome {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: gapfillmetagenome?(Metagenome model ID).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->GapFillModel($Data[1]);
}

sub buildbiomassreaction {
    my($Argument) = @_;

    my @Data = split(/\?/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: buildbiomassreaction?(genome ID).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    $model->BuildSpecificBiomassReaction($Data[1],undef);
}

sub schedule {
    my($Argument) = @_;

    my @Data = split(/:/,$Argument);
    if (@Data < 2) {
		print "Syntax for this command: schedule:(Commands).\n\n";
		return "ARGUMENT SYNTAX FAIL";
    }

    if ($Data[1] eq "MONITOR") {
        #Checking the command syntax
        if (!defined($Data[2]) || !defined($Data[3]) || !defined($Data[4])) {
            print STDERR "Syntax for monitor command: schedule:MONITOR:(Name):(Default type):(Number of processors)";
            return "ARGUMENT SYNTAX FAIL";
        }
        my $Time = time();
        my $Filename = substr($Time,length($Time)-6);
        my $Index = 0;
        my $Name = $Data[2];
        my $Type = $Data[3];
        my $NumProcesses = $Data[4];
        my $Continue = 1;
        while ($Continue == 1) {
            #Loading and locking the queue
            my $Queue = $model->LockDBTable("QUEUE");
            if (!defined($Queue)) {
                $Queue = FIGMODELTable->new(["COMMAND","TYPE","OWNER"],$model->{"Queue filename"}->[0],undef,";","",undef);
            }
            #Loading the list of running processes
            my $RunningProcess = $model->GetDBTable("RUNNING PROCESSES");
            if (!defined($RunningProcess)) {
                $RunningProcess = FIGMODELTable->new(["COMMAND","FILE","OWNER","START","DURATION"],$model->{"Running job filename"}->[0],["FILE","OWNER"],";","",undef);
            }
            #Loading the finished job table
            my $FinishedJobs = $model->GetDBTable("FINISHED JOBS");
            if (!defined($FinishedJobs)) {
                $FinishedJobs = FIGMODELTable->new(["COMMAND","FILE","OWNER","STATUS","FINISHED","START","DURATION"],$model->{"Finished job filename"}->[0],["FILE","OWNER"],";","",undef);
            }
            #Looking for any jobs owned by this monitor
            my @Rows = $RunningProcess->get_rows_by_key($Name,"OWNER");
            my $RunningCount = 0;
            #Checking if any of this processor's jobs are done
            my $JobFinished = 0;
            foreach my $Row (@Rows) {
                if (defined($Row) && defined($Row->{"FILE"}->[0])) {
                    $RunningCount++;
                    if (-e $Row->{"FILE"}->[0]) {
                        #This job is done
                        $JobFinished = 1;
                        $RunningProcess->delete_row($RunningProcess->row_index($Row));
                        #Getting the status of the job from the file
                        my $List = FIGMODEL::LoadSingleColumnFile($Row->{"FILE"}->[0],"");
                        $Row->{"STATUS"}->[0] = $List->[0];
                        $Row->{"FINISHED"}->[0] = FIGMODEL::Date();
                        $FinishedJobs->add_row($Row);
                        #Clearing the file
                        unlink($Row->{"FILE"}->[0]);
                        $RunningCount--;
                    } else {
                        $Row->{"DURATION"}->[0] += 3;
                    }
                }
            }
            #If there are open slots, we start new processes
            my $JobAdded = 0;
            while ($RunningCount < $NumProcesses) {
                #Looking for an available job in the queue
                if (defined($Queue) || $Queue->size() > 0) {
                    for (my $i=0; $i < $Queue->size(); $i++) {
                        my $Row = $Queue->get_row($i);
                        if ($Row->{"OWNER"}->[0] eq "ANY" || $Row->{"OWNER"}->[0] eq $Name) {
                            $JobAdded = 1;
                            #Starting the job
                            $Row->{"DURATION"}->[0] = 0;
                            $Row->{"START"}->[0] = FIGMODEL::Date();
                            $Row->{"OWNER"}->[0] = $Name;
                            $Row->{"FILE"}->[0] = $model->{"temp file directory"}->[0].$Name."-".$Index."-".$Filename.".txt";
                            $Index++;
                            my $CurrentType = $Type;
                            if (defined($Row->{"TYPE"}->[0]) && length($Row->{"TYPE"}->[0]) > 0) {
                                $CurrentType = $Row->{"TYPE"}->[0];
                            }
                            if ($Row->{"COMMAND"}->[0] =~ m/MONITOR/) {
                                #This is a specific command directored at the monitor
                                if ($Row->{"COMMAND"}->[0] =~ m/KILL/) {
                                    $Continue = 0;
                                    $NumProcesses = 0;
                                } elsif ($Row->{"COMMAND"}->[0] =~ m/(\d+)/) {
                                    $NumProcesses = $1;
                                }
                                $RunningCount--;
                            } elsif ($CurrentType eq "NOHUP") {
                                system($model->{"Nohup model driver executable"}->[0]." finish?".$Row->{"FILE"}->[0]." ".$Row->{"COMMAND"}->[0]." > ".$model->{"database message file directory"}->[0]."Output-".$Row->{"FILE"}->[0]." &");
                                #Adding the job to the running job table
                                $RunningProcess->add_row($Row);
                            } else {
                                system($model->{"Recursive model driver executable"}->[0]." finish?".$Row->{"FILE"}->[0]." ".$Row->{"COMMAND"}->[0]);
                                #Adding the job to the running job table
                                $RunningProcess->add_row($Row);
                            }
                            #Deleting the row from the Queue
                            $Queue->delete_row($Queue->row_index($Row));
                            last;
                        }
                    }
                }
                $RunningCount++;
            }
            #Saving all queue tables
            if ($JobFinished == 1) {
                $FinishedJobs->save();
            }
            $RunningProcess->save();
            if ($JobAdded == 1) {
                $Queue->save();
            }
            $model->UnlockDBTable("QUEUE");
            #Clearing all tables from memmory
            $model->ClearDBTable("RUNNING PROCESSES","DELETE");
            $model->ClearDBTable("QUEUE","DELETE");
            $model->ClearDBTable("FINISHED JOBS","DELETE");
            undef $RunningProcess;
            undef $FinishedJobs;
            undef $Queue;
            print "Sleeping...\n";
            sleep(180);
        }
    } elsif ($Data[1] eq "ADD") {
        #Checking the command syntax
        if (!defined($Data[2])) {
            print STDERR "Syntax for add command: schedule:ADD:(Filename/Command):(FRONT/BACK):(Owner):(Type)";
            return "ARGUMENT SYNTAX FAIL";
        }
        #Setting the owner of the process being added
        my $Owner = "ANY";
        if (defined($Data[4])) {
            $Owner = $Data[4];
        }
        #Reading in the lines to be added to the queue
        my $List;
        if (-e $Data[2]) {
            $List = FIGMODEL::LoadSingleColumnFile($Data[2],"");
        } else {
            $List = [$Data[2]];
        }
        #Adding the data to the queue
        my $Queue = $model->LockDBTable("QUEUE");
        if (!defined($Queue)) {
            $Queue = FIGMODEL->new(["COMMAND","TYPE","OWNER"],$model->{"Queue filename"}->[0],undef,";","",undef);
        }
        if (!defined($Data[3]) || $Data[3] eq "BACK") {
            foreach my $Item (@{$List}) {
                if (defined($Data[5])) {
                    $Queue->add_row({"COMMAND" => [$Item],"OWNER" => [$Owner],"TYPE" => [$Data[5]]});
                } else {
                    $Queue->add_row({"COMMAND" => [$Item],"OWNER" => [$Owner]});
                }
            }
        } else {
            foreach my $Item (@{$List}) {
                if (defined($Data[5])) {
                    $Queue->add_row({"COMMAND" => [$Item],"OWNER" => [$Owner],"TYPE" => [$Data[5]]},0);
                } else {
                    $Queue->add_row({"COMMAND" => [$Item],"OWNER" => [$Owner]},0);
                }
            }
        }
        #Saving and unlocking the queue
        $Queue->save();
        $model->UnlockDBTable("QUEUE");
    } elsif ($Data[1] eq "DELETE") {
        #Checking the command syntax
        if (!defined($Data[2])) {
            print STDERR "Syntax for delete command: schedule:DELETE:(Job filename)";
            return "ARGUMENT SYNTAX FAIL";
        }
        #Loading and locking the queue
        my $Queue = $model->LockDBTable("QUEUE");
        if (!defined($Queue)) {
            $Queue = FIGMODEL->new(["COMMAND","TYPE","OWNER"],$model->{"Queue filename"}->[0],undef,";","",undef);
        }
        #Loading the list of running processes
        my $RunningProcess = $model->GetDBTable("RUNNING PROCESSES");
        if (!defined($RunningProcess)) {
            print STDERR "No job found with filename ".$Data[2]."\n";
            $model->UnlockDBTable("QUEUE");
            return "JOB NOT FOUND";
        }
        #Looking for specified job ID
        my $Row = $RunningProcess->get_row_by_key($Data[2],"FILE");
        if (!defined($Row)) {
            print STDERR "No job found with filename ".$Data[2]."\n";
            $model->UnlockDBTable("QUEUE");
            return "JOB NOT FOUND";
        }
        #Deleting the job
        $RunningProcess->delete_row($RunningProcess->row_index($Row));
        $RunningProcess->save();
        #Adding the deleted job to the finished job list
        $Row->{"STATUS"}->[0] = "KILLED BY USER";
        $Row->{"FINISHED"}->[0] = FIGMODEL::Date();
        #Loading the finished job table
        my $FinishedJobs = $model->GetDBTable("FINISHED JOBS");
        if (!defined($FinishedJobs)) {
            $FinishedJobs = FIGMODEL->new(["JOB","COMMAND","FILE","OWNER","STATUS"],$model->{"Finished job filename"}->[0],["JOB","OWNER"],";","",undef);
        }
        $FinishedJobs->add_row($Row);
        $FinishedJobs->save();
        $model->UnlockDBTable("QUEUE");
    } elsif ($Data[1] eq "FREEZE") {
        my $Queue = $model->LockDBTable("QUEUE");
        print "Hit enter when queue adjuments have been completed: ";
        my $Answer = <STDIN>;
        $model->UnlockDBTable("QUEUE");
    }
}