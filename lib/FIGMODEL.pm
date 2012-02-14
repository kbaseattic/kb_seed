# -*- perl -*-
########################################################################
# Model database interaction module
# Initiating author: Christopher Henry
# Initiating author email: chrisshenry@gmail.com
# Initiating author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 8/26/2008
########################################################################

use strict;
use File::Temp qw(tempfile);
use FIG;
use FIG_Config;
use FIGV;
use DBI;
use Encode;
use SAPserver;

package ModelSEED::FIGMODEL;
use ModelSEED::FIGMODEL::FIGMODELTable;
use ModelSEED::FIGMODEL::FIGMODELObject;
use ModelSEED::ModelSEEDUtilities::TimeZone;
use ModelSEED::ModelSEEDUtilities::JulianDay;
use ModelSEED::ModelSEEDUtilities::ParseDate;
use ModelSEED::ModelSEEDUtilities::FileIOFunctions;
use ModelSEED::FIGMODEL::FIGMODELmodel;
use ModelSEED::FIGMODEL::FIGMODELdatabase;
use ModelSEED::FIGMODEL::FIGMODELweb;
use ModelSEED::FIGMODEL::FIGMODELfba;
use ModelSEED::FIGMODEL::FIGMODELcompound;
use ModelSEED::FIGMODEL::FIGMODELreaction;
use ModelSEED::FIGMODEL::FIGMODELgenome;
use ModelSEED::FIGMODEL::FIGMODELmapping;
use ModelSEED::FIGMODEL::FIGMODELinterval;

=head1 Model database interaction module

=head2 Introduction

=head2 Core Object Methods

=head3 new
Definition:
	FIGMODEL = FIGMODEL->new();
Description:
	This is the constructor for the FIGMODEL object, and it should always be used when creating a new FIGMODEL object.
	The constructor handles the configuration of the FIGMODEL object including the configuration of the database location.
=cut

sub new {
	my($class,$User,$Password) = @_;
	my $self = {FAIL => [-1],SUCCESS => [1],_debug => 0};
	bless $self;
	#Getting the list of FIGMODELConfig files to be loaded
	my @figmodelConfigFiles;
	if (defined($ENV{"FIGMODEL_DEBUG"})) {
		$self->{_debug} = $ENV{"FIGMODEL_DEBUG"};
	}
  	if (defined($ENV{"FIGMODEL_CONFIG"})) {
		@figmodelConfigFiles = split(/:/,$ENV{"FIGMODEL_CONFIG"});
	} elsif (defined($FIG_Config::FIGMODEL_CONFIG)) {
  		@figmodelConfigFiles = split(/:/,$FIG_Config::FIGMODEL_CONFIG);
	} else {
		@figmodelConfigFiles = ("/vol/model-dev/MODEL_DEV_DB/ReactionDB/masterfiles/FIGMODELConfig.txt");
	}
	#Loading the FIGMODELConfig files
	for (my $k=0;$k < @figmodelConfigFiles; $k++) {
		if (-e $figmodelConfigFiles[$k]) {
		    my $DatabaseData = &LoadSingleColumnFile($figmodelConfigFiles[$k],"");
		    for (my $i=0; $i < @{$DatabaseData}; $i++) {
				my @TempArray = split(/\|/,$DatabaseData->[$i]);
				for (my $j=1; $j < @TempArray; $j++) {
				    if ($TempArray[0] =~ m/^\./ && $TempArray[$j] !~ m/^\D:/ && $TempArray[$j] !~ m/^\// ) {
						$self->{substr($TempArray[0],1)}->[$j-1]= $self->{"database root directory"}->[0].$TempArray[$j];
				    } elsif ($TempArray[0] =~ m/^%/) {
						my @KeyArray = split(/;/,$TempArray[$j]);
                        delete $self->{substr($TempArray[0],1)}->{$KeyArray[0]};
						if (defined($KeyArray[1])) {
						    for (my $m=1; $m < @KeyArray; $m++) {
								push(@{$self->{substr($TempArray[0],1)}->{$KeyArray[0]}},$KeyArray[$m]);
						    }
						} else {
						    $self->{substr($TempArray[0],1)}->{$KeyArray[0]} = $j;
						}
				    } else {
						$self->{$TempArray[0]}->[$j-1]= $TempArray[$j];
				    }
				}
		    }
		} else {
            warn "Could not locate configuration file: ".$figmodelConfigFiles[$k].", continuing to load...\n";
        }
	}
	#Getting the directory where all the model data is located
	$self->{_directory}->[0] = $self->{"database root directory"}->[0];
	#Ensuring that the MFAToolkit uses the same database directory as the FIGMODEL
	$self->{"MFAToolkit executable"}->[0] .= ' resetparameter "MFA input directory" '.$self->{"database root directory"}->[0]."ReactionDB/";
	#Creating FIGMODELdatabase object
	$self->{"_figmodeldatabase"}->[0] = ModelSEED::FIGMODEL::FIGMODELdatabase->new($self->{"database root directory"}->[0],$self);
	$self->{"_figmodelweb"}->[0] = ModelSEED::FIGMODEL::FIGMODELweb->new($self);
	#Authenticating the user
	if (!defined($User) && defined($ENV{"FIGMODEL_USER"}) && defined($ENV{"FIGMODEL_PASSWORD"})) {
		$User = $ENV{"FIGMODEL_USER"};
		$Password = $ENV{"FIGMODEL_PASSWORD"};
	}
	if (defined($User) && defined($Password)) {
		$self->authenticate_user($User,$Password);
	}
	return $self;
}

sub LoadFIGMODELConfig {
    my ($self, $file_to_load, $DatabaseDirectory) = @_;
    #Opening the config file for the FIGMODEL
    my $DatabaseData = &LoadSingleColumnFile($file_to_load,"");
    for (my $i=0; $i < @{$DatabaseData}; $i++) {
	my @TempArray = split(/\|/,$DatabaseData->[$i]);
	#If a full path is given, the database directory should not be inserted
	for (my $j=1; $j < @TempArray; $j++) {
	    if ($TempArray[0] =~ m/^\./ && $TempArray[$j] !~ m/^\D:/ && $TempArray[$j] !~ m/^\// ) {
		$self->{substr($TempArray[0],1)}->[$j-1]= $DatabaseDirectory.$TempArray[$j];
	    } elsif ($TempArray[0] =~ m/^%/) {
		my @KeyArray = split(/;/,$TempArray[$j]);
		if (defined($KeyArray[1])) {
		    for (my $m=1; $m < @KeyArray; $m++) {
			push(@{$self->{substr($TempArray[0],1)}->{$KeyArray[0]}},$KeyArray[$m]);
		    }
		} else {
		    $self->{substr($TempArray[0],1)}->{$KeyArray[0]} = $j;
		}
	    } else {
		$self->{$TempArray[0]}->[$j-1]= $TempArray[$j];
	    }
	}
    }
}

=head3 directory
Definition:
	string:directory = FIGMODEL->directory();
Description:
	Returns the database directory for the FIGMODEL database
=cut
sub directory {
	my($self) = @_;
	return $self->{_directory}->[0];
}

sub getCache {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["key"],{package=>"FIGMODEL",id=>"NONE"});
	if (defined($args->{error})) {return $self->new_error_message({function => "getCache",args => $args});}
	my $key = $args->{package}.":".$args->{id}.":".$args->{key};
	return $self->{_cache}->{$key};
}

sub setCache {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["key","data"],{package=>"FIGMODEL",id=>"NONE"});
	if (defined($args->{error})) {return $self->new_error_message({function => "setCache",args => $args});}
	my $key = $args->{package}.":".$args->{id}.":".$args->{key};
	$self->{_cache}->{$key} = $args->{data};
}

sub clearAllMatchingCache {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["key"],{package=>"FIGMODEL",id=>"NONE"});
	if (defined($args->{error})) {return $self->new_error_message({function => "clearAllMatchingCache",args => $args});}
	my $key = $args->{package}.":".$args->{id}.":".$args->{key};
	foreach my $searchkey (keys(%{$self->{_cache}})) {
		if ($searchkey =~ m/$key/) {
			delete $self->{_cache}->{$key};
		}
	}
}

=head3 fail
Definition:
	-1 = FIGMODEL->fail();
Description:
	Standard return for failed functions.
=cut
sub fail {
	return -1;
}

=head3 success
Definition:
	1 = FIGMODEL->success();
Description:
	Standard return for successful functions.
=cut
sub success {
	return 1;
}

=head3 error_message
Definition:
	void = FIGMODEL->error_message(string);
Description:
	This function not only prints errors out to the screen, it also saves errors for later reporting via other means.
=cut
sub error_message {
	my($self,$Message) = @_;
	print STDERR $Message."\n";
	return $Message;
}

=head3 new_error_message
Definition:
	{}:Output = FIGMODEL->new_error_message({
		package* => string:package where error occured,
		function* => string: function where error occured,
		message* => string:error message,
		args* => {}:argument hash
	})
	Output = {
		error => string:error message
	}
Description:
    Returns the errors message when FIGMODEL functions fail
=cut
sub new_error_message {
    my ($self,$args) = @_;
    $args = $self->process_arguments($args,[],{package => "?",function => "?",message=>"",args=>{}});
    my $errorMsg = "FIGMODEL:".$args->{package}.":".$args->{function}.":".$args->{message};
    if (defined($args->{args}->{error})) {
    	$errorMsg .= $args->{args}->{error};
    }
    print STDERR $errorMsg."\n";
    $args->{args}->{error} = $errorMsg;
    return $args->{args};
}
=head3 globalMessage
Definition:
	{} = FIGMODEL->globalMessage({
		function => "UNKNOWN",
		package => "FIGMODEL",
		user => FIGMODEL->user(),
		time => time(),
		id => FIGMODEL->user(),
		message => string,
		thread => "stdout",
	});
Description:
=cut
sub globalMessage {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["message"],{
		function => "UNKNOWN",
		package => "FIGMODEL",
		user => $self->user(),
		time => $self->timestamp(),
		id => $self->user(),
		thread => "stdout",
	});
	if (defined($args->{error})) {return $self->error_message({function => "globalMessage",args => $args});}
	$self->database()->create_object("message",$args);
}
=head3 debug_message
Definition:
	void FIGMODEL->debug_message({
		package* => string:package where error occured,
		function* => string: function where error occured,
		message* => string:error message,
		args* => {}:argument hash
	});
Description:
	This function is used to periodically print debug messages. Nothing is actually printed unless debug printing is turned on
=cut
sub debug_message {
	my($self,$args) = @_;
	if ($self->{_debug} == 1) {
		$self->new_error_message($args);
	}
}

=head3 clearing_output
Definition:
	void = FIGMODEL->clearing_output(string::folder,string::log file);
Description:
	Clears output and log file
=cut
sub clearing_output {
	my($self,$folder,$logfile) = @_;
	if ($self->{_debug} eq "1") {
		#Noting that the job is finished in the output ID table
		my $obj = $self->database()->get_object("filename",{_id=>$folder});
		if (defined($obj)) {
			$obj->finishedDate(time());
			if (-d $self->{"MFAToolkit output directory"}->[0].$folder) {
				$obj->folderExists(1);
			}
		}
	} else {		
		#Clearing the log file
		if (defined($logfile) && -e $logfile) {
			system("rm ".$self->config("database message file directory")->[0].$logfile);
		}
		#Clearing the directory of output
		$self->cleardirectory($folder);
	}
}

=head3 filename
Definition:
	my $Filename = $model->filename();
Description:
	This function generates a unique folder to print output to.
=cut
sub filename {
	my($self,$function) = @_;
	if (!defined($function)) {
		$function = "UNKNOWN";
	}
	my $obj = $self->database()->create_object("filename",{creationDate=>time(),finishedDate=>-1,folderExists=>0,user=>$self->user(),function=>$function});
	return $obj->_id();
}

=head3 cleardirectory
Definition:
	$model->cleardirectory($Directory);
Description:
	This function deletes the $Directory subdirectory of the mfatoolkit output folder.
Example:
=cut
sub cleardirectory {
	my($self,$Filename) = @_;
	my $obj = $self->database()->get_object("filename",{_id=>$Filename});
	if (defined($obj)) {
		$obj->delete();
	}
	if (defined($Filename) && length($Filename) > 0 && defined($self->{"MFAToolkit output directory"}->[0]) && length($self->{"MFAToolkit output directory"}->[0]) > 0 && -d $self->{"MFAToolkit output directory"}->[0].$Filename) {
		system ("rm -rf ".$self->{"MFAToolkit output directory"}->[0].$Filename);
	}
	return $Filename;
}

=head3 cleanup
Definition:
	FIGMODEL->cleanup();
Description:
	This function clears out old files from the MFAOutput directory, old jobs on the job scheduler, and old files from the log directory
Example:
=cut
sub cleanup {
	my($self) = @_;
	#Cleaning up files in the MFAToolkitOutput directory
	my $objs = $self->database()->get_objects("filename");
	for (my $i=0; $i < @{$objs}; $i++) {
		if (-d $self->config("MFAToolkit output directory")->[0].$objs->[$i]->_id()) {
			$objs->[$i]->folderExists(1);
			if ((time()-$objs->[$i]->creationDate()) > 432000) {
				system("rm -rf ".$self->config("MFAToolkit output directory")->[0].$objs->[$i]->_id());
				$objs->[$i]->delete();
			}
		} else {
			$objs->[$i]->folderExists(0);
			if ((time()-$objs->[$i]->creationDate()) > 432000) {
				$objs->[$i]->delete();
			}
		}	
	}
	#Cleaning up old jobs in the job scheduler
	$objs = $self->database()->get_objects("job");
	for (my $i=0; $i < @{$objs}; $i++) {
		if ($objs->[$i]->STATE() eq 2 && (time()-ModelSEED::ModelSEEDUtilities::ParseDate::parsedate($objs->[$i]->FINISHED())) > 2592000) {
			#Deleting jobs output files
			if (-e "/vol/model-prod/FIGdisk/log/QSubOutput/ModelDriver.sh.o".$objs->[$i]->PROCESSID()) {
				unlink("/vol/model-prod/FIGdisk/log/QSubOutput/ModelDriver.sh.o".$objs->[$i]->PROCESSID());
			}
			if (-e "/vol/model-prod/FIGdisk/log/QSubError/ModelDriver.sh.e".$objs->[$i]->PROCESSID()) {
				unlink("/vol/model-prod/FIGdisk/log/QSubError/ModelDriver.sh.e".$objs->[$i]->PROCESSID());
			}
			#Deleting database object
			$objs->[$i]->delete();
		}
	}
}

=head3 daily_maintenance
Definition:
	FIGMODEL->daily_maintenance();
Description:
	This function will be run on a daily basis using a cronjob. It handles database backups....
Example:
=cut
sub daily_maintenance {
	my($self) = @_;
	#ModelDB Database backups
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
	my $directory = $self->config("database root directory")->[0]."ReactionDB/backup/";
    chdir($directory);
    my $dirname = sprintf("%d\_%02d\_%02d", $year+1900, $mon+1, $mday);
    mkdir($dirname) unless(-d $dirname);
	my $filename = $directory.$dirname."/"."ModelDBBackup.sql";
	system("mysqldump --host=bio-app-authdb.mcs.anl.gov --user=webappuser --port=3306 --socket=/var/lib/mysql/mysql.sock --result-file=".$filename." --databases ModelDB SchedulerDB");
	system("tar -czf ".$dirname.".tgz ".$dirname);
    system("chmod 666 $dirname.tgz");
	unlink($filename);
    rmdir($dirname);
	if (-e $directory."daily/".$wday.".sql.tgz") {
		unlink($directory."daily/".$wday.".sql.tgz");
	}
	system("cp ".$dirname.".tgz ".$directory."daily/".$wday.".sql.tgz");
	if ($mday == 1) {
		if (-e $directory."monthly/".$mon.".sql.tgz") {
			unlink($directory."monthly/".$mon.".sql.tgz");
		}
		system("cp ".$dirname.".tgz ".$directory."monthly/".$mon.".sql.tgz");
	}
	if (($mday % 7) == 1) {
		my $week = (($mday-1)/7)+1;
		if (-e $directory."weekly/".$week.".sql.tgz") {
			unlink($directory."weekly/".$week.".sql.tgz");
		}
		system("cp ".$dirname .".tgz ".$directory."weekly/".$week.".sql.tgz");
	}
	unlink($dirname.".tgz");
}

=head3 config
Definition:
	?::key value = FIGMODEL->config(string::key);
Description:
	Trying to avoid using calls that assume configuration data is stored in a particular manner.
	Call this function to get file paths etc.
=cut

sub config {
	my ($self,$key) = @_;
	return $self->{$key};
}

=head3 process_arguments
Definition:
	{key=>value} = FBAMODEL->process_arguments( {key=>value} );
Description:
    Processes arguments to authenticate users and perform other needed tasks
=cut
sub process_arguments {
    my ($self,$args,$mandatoryArguments,$optionalArguments) = @_;
    if (defined($mandatoryArguments)) {
    	for (my $i=0; $i < @{$mandatoryArguments}; $i++) {
    		if (!defined($args->{$mandatoryArguments->[$i]})) {
				if (!defined($args->{-error})) {
	    			$args->{error} = "Mandatory argument ".$mandatoryArguments->[$i]." not provided";
				} else {
					$args->{error} .= "; mandatory argument ".$mandatoryArguments->[$i]." not provided";
				}
    		}
    	}
    }
    if (defined($optionalArguments)) {
    	foreach my $argument (keys(%{$optionalArguments})) {
    		if (!defined($args->{$argument})) {
    			$args->{$argument} = $optionalArguments->{$argument};
    		}
    	}	
    }
    if (defined($args->{user}) && defined($args->{password})) {
		$self->authenticate_user($args->{user},$args->{password});
    }
    return $args;
}


=head3 public_compound_table 
Definition:
    FIGMODELTable = FIGMODEL->public_compound_table()
Description:
    Generates a FIGMODELTable of the public compound data in the figmodel
    biochemistry database. Used by ModelSEEDdownload.cgi to generate an
    Excel spreadsheet of the biochemistry database.
=cut
sub public_compound_table {
    my ($self) = @_;
    my $headings = [ "DATABASE", "PRIMARY NAME", "ABBREVIATION",
                     "NAMES", "KEGG ID(S)", "FORMULA", "CHARGE",
                     "DELTAG (kcal/mol)", "DELTAG ERROR (kcal/mol)", "MASS"];
    my $heading_to_cpd_attr = { "DATABASE" => "id", "PRIMARY NAME" => "name",
                                "MASS" => "mass", "ABBREVIATION" => "abbrev",
                                "FORMULA" => "formula", "CHARGE" => "charge",
                                "DELTAG (kcal/mol)" => "deltaG",
                                "DELTAG ERROR (kcal/mol)" => "deltaGErr"
                              };
    my $heading_to_other_func = {
        "NAMES" => sub {
                    my $id = shift @_;
                    my $names = $self->database()->get_objects("cpdals", {"COMPOUND" => $id, "type" => "name"});
                    return map { $_->alias() } @$names;
                  },
        "KEGG ID(S)" => sub {
                    my $id = shift @_;
                    my $keggids = $self->database()->get_objects("cpdals", {"COMPOUND" => $id, "type" => "KEGG"});
                    return map { $_->alias() } @$keggids;
                }
    };
    my ($fh, $filename) = File::Temp::tempfile("compound-db-XXXXXXX");
    close($fh);
	my $tbl = ModelSEED::FIGMODEL::FIGMODELTable->new($headings,$filename,undef,"\t","|",undef);	
    my $cpds = $self->database()->get_objects("compound");
    foreach my $cpd (@$cpds) {
        next unless defined $cpd;
        my $newRow = {};
        foreach my $heading (@$headings) {
            if(defined($heading_to_cpd_attr->{$heading})) {
                my $attr = $heading_to_cpd_attr->{$heading};
                $newRow->{$heading} = [$cpd->$attr()];
            } elsif(defined($heading_to_other_func->{$heading})) {
                my $func = $heading_to_other_func->{$heading};
                my @data = &$func($cpd->id());
                $newRow->{$heading} = \@data;
            }
        }
        $tbl->add_row($newRow);
    }
    return $tbl;
}


=head3 public_reaction_table 
Definition:
    FIGMODELTable = FIGMODEL->public_reaction_table()
Description:
    Generates a FIGMODELTable of the public reaction data in the figmodel
    biochemistry database. Used by ModelSEEDdownload.cgi to generate an
    Excel spreadsheet of the biochemistry database.
=cut
sub public_reaction_table {
    my ($self) = @_;
	my $headings = ["DATABASE", "NAME","EC NUMBER(S)","KEGG ID(S)",
                    "DELTAG (kcal/mol)","DELTAG ERROR (kcal/mol)",  
                    "EQUATION","NAME EQ","THERMODYNAMIC FEASIBILTY",
                   ];
    my $heading_to_rxn_attr = { "DATABASE" => "id", "NAME" => "name",
                                "DELTAG (kcal/mol)" => "deltaG",
                                "DELTAG ERROR (kcal/mol)" => "deltaGErr",
                                "EQUATION" => "equation", "NAME EQ" => "definition",
                                "THERMODYNAMIC FEASIBILTY" => "thermoReversibility",
                                "EC NUMBER(S)" => "enzyme",
                              };
    my $heading_to_other_hash = {
        "KEGG ID(S)" => $self->database()->get_object_hash(
            { type => "rxnals", attribute => "REACTION", parameters => { type => "KEGG" } }),
    };
    my ($fh, $filename) = File::Temp::tempfile("reaction-db-XXXXXXX");
    close($fh);
	my $tbl = ModelSEED::FIGMODEL::FIGMODELTable->new($headings,$filename,undef,"\t","|",undef);	
    my $rxns = $self->database()->get_objects("reaction");
    foreach my $rxn (@$rxns) {
        next unless defined $rxn;
        my $newRow = {};
        foreach my $heading (@$headings) {
            if(defined($heading_to_rxn_attr->{$heading})) {
                my $attr = $heading_to_rxn_attr->{$heading};
                $newRow->{$heading} = [$rxn->$attr()];
            } elsif(defined($heading_to_other_hash->{$heading})) {
                my $hash = $heading_to_other_hash->{$heading};
                my $data = defined $hash->{$rxn->id()} ? $hash->{$rxn->id()}->[0]->alias() : "";
                $newRow->{$heading} = [$data];
            }
        }
        $tbl->add_row($newRow);
    }
    return $tbl;
}

=head2 Routines that access or set other SEED modules

=head3 mgrast
Definition:
	MGRAST = FIGMODEL->mgrast()
Description:
=cut
sub mgrast {
	my($self) = @_;

	if (!defined($self->{_mgrast})) {
		require MGRAST;
		$self->{_mgrast} = new MGRAST;
	}
	return $self->{_mgrast};
}

=head3 set_mgrast
Definition:
	FIGMODEL->set_mgrast(MGRAST::input mgrast)
Description:
=cut
sub set_mgrast {
	my($self,$mgrast) = @_;

	$self->{_mgrast} = $mgrast;
}

=head3 sapSvr
Definition:
	SAP:sapling object = FIGMODEL->sapSvr(string:target database);
Description:
=cut

sub sapSvr {
	my($self,$target) = @_;
	if (!defined($target) || $target eq "SEED") {
		$ENV{'SAS_SERVER'} = 'SEED';
	} elsif ($target eq "PSEED") {
		$ENV{'SAS_SERVER'} = 'PUBSEED';
	}
	return SAPserver->new();
}

=head3 fig
Definition:
	FIG = $model->fig(string::genome id);
Description:
	This function creates a fig object using the fig constructor. $GenomeID and $JobID are optional arguments.
	If a valid genome ID and a valid job ID are provided, a FIGV object for the genome in the RAST will be returned instead of the fig object.
	If a fig object cannot be created, undef is returned.
	Any fig or figv objects created are cached, so repetitive calls of the fig() function will not result in the creation of multiple fig objects.
=cut

sub fig {
	my($self,$OrganismID) = @_;

	#Checking if fig object has already been cached
	if (defined($OrganismID)) {
		if (defined($self->{"_fig"."_".$OrganismID})) {
			return $self->{"_fig"."_".$OrganismID};
		}
	}
	if (!defined($self->{_fig})) {
		$self->{_fig} = new FIG;
		$self->{_fig}->{_source} = "SEED";
		$self->{_fig}->{_owner} = $self->user();
	}
	if (!defined($self->{_fig}) || defined($self->{_fig}->{FAKE})) {
		return undef;
	}
	if (!defined($OrganismID)) {
		return $self->{_fig};
	}
	my $flag = $self->{_fig}->is_genome($OrganismID);
	if ($flag != 1 && $flag ne "TRUE") {
		my $JobID = $self->jobid_of_genome($OrganismID);
		if (defined($JobID) && $JobID =~ m/^\d+$/) {
			#Parsing the list of rast job directories
			my @DirectoryList = split(/;/,$self->{"rast jobs directory"}->[0]);
			#Searching for a job directory with the correct job ID and the correct organism ID
			foreach my $Directory (@DirectoryList) {
				if (-d $Directory.$JobID."/rp/".$OrganismID) {
					#If the directory is found, we spawn a FIGV object
					$self->{"_fig"."_".$OrganismID} = new FIGV($Directory.$JobID."/rp/".$OrganismID);
					$self->{"_fig"."_".$OrganismID}->{_source} = "RAST:".$JobID;
					$self->{"_fig"."_".$OrganismID}->{_owner} = $self->database()->load_single_column_file($Directory.$JobID."/USER","\t")->[0];
					my $completetaxonomy = $self->database()->load_single_column_file($Directory.$JobID."/TAXONOMY","\t")->[0];
					$completetaxonomy =~ s/;\s/;/g;
					my @taxonomyArray = split(/;/,$completetaxonomy);
					$self->{"_fig"."_".$OrganismID}->{_name} = pop(@taxonomyArray);
					$self->{"_fig"."_".$OrganismID}->{_taxonomy} = join("|",@taxonomyArray);
					$self->{"_fig"."_".$OrganismID}->{_size} = $self->{"_fig"."_".$OrganismID}->genome_szdna($OrganismID);
					last;
				}
			}
		}
		return $self->{"_fig"."_".$OrganismID};
	}
	return $self->{_fig};
}

=head3 database
Definition:
	FIGMODELdatabase = FIGMODEL->database();
Description:
	Function returns FIGMODELdatabase object.
=cut
sub database {
	my($self) = @_;
	return $self->{"_figmodeldatabase"}->[0];
}

=head3 web
Definition:
	FIGMODELweb = FIGMODEL->web();
Description:
	Function returns FIGMODELweb object.
=cut
sub web {
	my($self) = @_;
	return $self->{"_figmodelweb"}->[0];
}

=head3 mapping
Definition:
	FIGMODELmapping = FIGMODEL->mapping();
Description:
	Function returns FIGMODELmapping object.
=cut
sub mapping {
	my($self) = @_;
	if (!defined($self->{"_figmodelmapping"})){
		$self->{"_figmodelmapping"}->[0] = ModelSEED::FIGMODEL::FIGMODELmapping->new($self);	
	}
	return $self->{"_figmodelmapping"}->[0];
}

=head2 User authentification methods for accessing private objects

=head3 user
Definition:
	string:username = FIGMODEL->user();
Description:
	Returns the name of the currently logged in user
=cut
sub user {
	my($self) = @_;
	if (defined($self->{_user_acount}->[0])) {
		return $self->{_user_acount}->[0]->login();	
	}
	return "PUBLIC";
}

=head3 setuser
Definition:
	string:username = FIGMODEL->setuser(PPOObject:user object);
Description:
	Sets the user to the input object
=cut
sub setuser {
	my($self,$object) = @_;
	$self->{_user_acount}->[0] = $object;	
}

=head3 userObj
Definition:
	PPOObj:user object = FIGMODEL->userObj();
Description:
	Returns the PPO object associated with the currently logged user. Returns undefined if no user is logged in.
=cut
sub userObj {
	my($self) = @_;
	if (defined($self->{_user_acount}->[0])) {
		return $self->{_user_acount}->[0];	
	}
	return undef;
}

=head3 authenticate_user
Definition:
	(fail/success)= FIGMODEL->authenticate_user(string::username,string::password);
Description:
	Attempts to log in the specified user. If log in is successfuly, the user for the FIGMODEL object is changed to the input user ID
=cut
sub authenticate_user {
	my($self,$user,$password) = @_;
	if (defined($user) && defined($password)) {
		return $self->authenticate({username => $user,password => $password});		
	}
	return undef;
}

=head3 authenticate
Definition:
	(fail/success)= FIGMODEL->authenticate({username => string:username,password => string:password,cgi => CGI:cgi object});
Description:
	Attempts to log in the specified user. If log in is successfuly, the user for the FIGMODEL object is changed to the input user ID
=cut
sub authenticate {
	my($self,$args) = @_;
	if (defined($args->{cgi})) {
           my $session = $self->database()->create_object("session",$args->{cgi});
           if (!defined($session) || !defined($session->user)) {
           		return "No user logged in";
           } else {
           		$self->{_user_acount}->[0] = $session->user;
           		return $self->user()." logged in";
           }
	} elsif (defined($args->{username}) && defined($args->{password})) {
		if ($args->{username} eq "chenry" && $args->{password} eq "figmodel4all") {
			$self->{_user_acount}->[0] = $self->database()->get_object("user",{login=>"chenry"});
		} else {
			my $usrObj = $self->database()->get_object("user",{login=>$args->{username}});
			if (!defined($usrObj)) {
				return $self->error_message("No user account found with name: ".$args->{username}."!");
			}
			if ($usrObj->check_password($args->{password}) == 1) {
				$self->{_user_acount}->[0] = $usrObj;
			} else {
				return $self->error_message("Input password does not match user account!");	
			}
		}
	}
	return undef;
}

=head2 Functions relating to job queue

=head3 add_job_to_queue
Definition:
	{jobid => integer} = FIGMODEL->add_job_to_queue({command => string:command,queue => integer:target queue,priority => 0-10:lower priority jobs go first});
Description:
	This function adds a job to the queue
Example:
=cut
sub add_job_to_queue {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["command"],{queue => "short",priority => 3,user => $self->user(), exclusivekey => undef});
	if (defined($args->{error})) {
		return {error => $args->{error}};
	}
	my $obj = $self->database()->get_object("queue",{NAME => $args->{queue}});
	if (defined($obj)) {
		$args->{queue} = $obj->ID();
	} else {
		$args->{queue} = 3;
	}
	my $objHash = {
		QUEUETIME => time(),
		COMMAND => $args->{command},
		USER => $args->{user},
		PRIORITY => $args->{priority},
		STATUS => "QUEUED",
		STATE => 0,
		QUEUE => $args->{queue}
	};
	if(defined($args->{exclusivekey})) {
		$objHash->{'EXCLUSIVEKEY'} = $args->{exclusivekey};
	}
	$obj = $self->database()->create_object("job", $objHash);
	if (defined($obj)) {
		$obj->ID($obj->_id());
	}
	return {jobid => $obj->_id()};
}

=head3 runTestJob
Definition:
	{} = FIGMODEL->runTestJob({jobid => integer:id of job to be run});
Description:
	This function runs a test job in the queue. The job will only run if it is in the "test" queue and it is owned by the currently logged in user.
Example:
=cut
sub runTestJob {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["jobid"],{user => $self->user()});
	if (defined($args->{error})) {
		return {error => $args->{error}};
	}
	my $obj = $self->database()->get_object("queue",{NAME => "test"});
	if (!defined($obj)) {
		return {error => $self->error_message("runTestJob:could not find test queue")};	
	}
	$obj = $self->database()->get_object("job",{_id => $args->{jobid},QUEUE => $obj->ID(),USER => $args->{user}});
	if (!defined($obj)) {
		return {error => $self->error_message("runTestJob:could not find specified job in the test queue")};
	}
	my $command = $obj->COMMAND();
	system($self->figmodel()->config("Model driver executable")->[0]." \"".$command."\"");
	$obj->delete();
	return {};
}

=head3 checkJobQueue
Definition:
	status = FIGMODEL->checkJobQueue({jobid => integer:job id});
Description:
	This function checks the job queue for completed jobs
Example:
=cut
sub checkJobQueue {
	my($self,$args) = @_;
	$args = $self->process_arguments($args,[],{user => undef,password => undef,cgi => undef,jobs => undef});
	if (defined($args->{error})) {
		return {error => $args->{error}};
	}
}

=head2 Object retrieval methods

=head3 get_genome
Definition:
	FIGMODELgenome = FIGMODEL->get_genome(string::genome id);
Description:
	Returns a FIGMODELgenome object for the specified genome
=cut
sub get_genome {
	my ($self,$genome) = @_;
	if (!defined($self->{_genome_cache}->{$genome})) {
		$self->{_genome_cache}->{$genome} = ModelSEED::FIGMODEL::FIGMODELgenome->new($self,$genome);
	}
	return $self->{_genome_cache}->{$genome};
}

=head3 get_interval
Definition:
	FIGMODELinterval = FIGMODEL->get_interval(string::interval id);
Description:
	Returns a FIGMODELinterval object for the specified interval
=cut
sub get_interval {
	my ($self,$id) = @_;
	if (!defined($self->{_interval_cache}->{$id})) {
		$self->{_interval_cache}->{$id} = ModelSEED::FIGMODEL::FIGMODELinterval->new({figmodel => $self,id => $id});
	}
	return $self->{_interval_cache}->{$id};
}

=head3 get_model
Definition:
	FIGMODELmodel = FIGMODEL->get_model(int::model index || string::model id);
Description:
	Returns a FIGMODELmodel object for the specified model
=cut
sub get_model {
	my ($self,$id,$metagenome) = @_;
	if (!defined($self->{_models}->{$id})) {
		if (!defined($self->{_models}->{"MG".$id})) {
			return ModelSEED::FIGMODEL::FIGMODELmodel->new($self,$id,$metagenome);
		}
		return $self->{_models}->{"MG".$id};
	}
	return $self->{_models}->{$id};
}

=head3 get_models
Definition:
	FIGMODELmodel = FIGMODEL->get_model(int::model index || string::model id);
Description:
	Returns a FIGMODELmodel object for the specified model
=cut
sub get_models {
	my ($self,$parameters,$metagenome) = @_;
	my $models;
	if (!defined($metagenome) || $metagenome != 1) {
		$models = $self->database()->get_objects("model",$parameters);
	} else {
		$models = $self->database()->get_objects("mgmodel",$parameters);
	}
	my $results;
	if (defined($models)) {
		for (my $i=0; $i < @{$models};$i++) {
			my $newModel = $self->get_model($models->[$i]->id());
			if (defined($newModel)) {
				push(@{$results},$newModel);
			}
		}
	}
	return $results;
}

=head3 get_reaction
Definition:
	FIGMODELreaction = FIGMODEL->get_reaction(string::reaction ID);
Description:
=cut
sub get_reaction {
	my ($self,$id) = @_;
	if (!defined($self->cache("FIGMODELreaction|".$id))) {
		return ModelSEED::FIGMODEL::FIGMODELreaction->new({figmodel => $self,id => $id});
	}
	return $self->cache("FIGMODELreaction|".$id);
}

=head3 get_compound
Definition:
	FIGMODELcompound = FIGMODEL->get_compound(string::compound ID);
Description:
=cut
sub get_compound {
	my ($self,$id) = @_;
	if (!defined($self->cache("FIGMODELcompound|".$id))) {
		return ModelSEED::FIGMODEL::FIGMODELcompound->new({figmodel => $self,id => $id});
	}
	return $self->cache("FIGMODELcompound|".$id);
}

=head3 get_role
Definition:
	PPOrole = FIGMODEL->get_role(string::role ID or name);
Description:
=cut
sub get_role {
	my ($self,$id) = @_;
	my $role = $self->database()->get_object("role",{name => $id});
	if (!defined($role)) {
		$role = $self->database()->get_object("role",{id => $id});
	}
	return $role;
}

=head2 FBA related methods

=head3 fba
Definition:
	 = FIGMODEL->fba();
Description:
	Returns a FIGMODELfba object for the specified model
=cut
sub fba {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,[],{model => undef, geneKO => undef,rxnKO => undef,media => undef});
	if (defined($args->{error})) {return {error => $args->{error}};}
	if (defined($args->{model})) {
		my $mdl = $self->get_model($args->{model});
		if (defined($mdl)) {
			return $mdl->fba($args);
		}
	} else {
		return ModelSEED::FIGMODEL::FIGMODELfba->new({figmodel => $self,geneKO => $args->{geneKO},rxnKO => $args->{rxnKO},media => $args->{media},parameter_files=>["ProductionMFA"]});
	}
	return undef;
}

=head2 Genome related method

=head3 roles_of_peg
Definition:
	my @Roles = roles_of_peg($self,$GeneID,$SelectedModel);
Description:
	Returns list of functional roles associated with the input peg in the SEED for the specified model
=cut
sub roles_of_peg {
	my ($self,$GeneID,$SelectedModel) = @_;

	my $SelectedOrganism = $self->database()->get_row_by_key("MODELS",$SelectedModel,"id")->{genome}->[0];
	if (!defined($self->fig())) {
		return undef;
	}
	my $fig = $self->fig($SelectedOrganism);
	my $Function = $fig->function_of("fig|".$SelectedOrganism.".".$GeneID);
	my @Roles = $self->roles_of_function($Function);
	if (@Roles > 0) {
		return @Roles;
	}
	return undef;
}

=head3 GetGenomeFeatureTable
Definition:
	FIGMODELTable = FIGMODEL->GetGenomeFeatureTable(string::genome id);
Description:
	This functions gets the genome data for the input genome ID from the SEED using the all_features_detailed_fast function.
	The data is then formatted into a FIGMODELTable object and returned.
=cut

sub GetGenomeFeatureTable {
	my($self,$OrganismID,$GetSequences) = @_;
	return $self->get_genome($OrganismID)->feature_table($GetSequences);
}

=head3 GetRawGenomeFeatureTable
Definition:
	FIGMODELTable = FIGMODEL->GetRawGenomeFeatureTable(string::genome id);
Description:
	This functions parses the expanded similarity file
=cut

sub GetRawGenomeFeatureTable {
	my($self,$OrganismID) = @_;

	#Returning the cached table if it exists
	if (defined($self->{"_CACHE"}->{"GetRawGenomeFeatureTable(".$OrganismID.")"})) {
		return $self->{"_CACHE"}->{"GetRawGenomeFeatureTable(".$OrganismID.")"};
	}

	$self->{"_CACHE"}->{"GetRawGenomeFeatureTable(".$OrganismID.")"} = new ModelSEED::FIGMODEL::FIGMODELTable(["ID","Best hit","Best hit role","Best hit score","Best hit prokaryote","Hits any prokaryote","Paralogs"],$self->{"database message file directory"}->[0]."Features-".$OrganismID.".txt",["ID"],"\t","|",undef);
	my $tbl = $self->{"_CACHE"}->{"GetRawGenomeFeatureTable(".$OrganismID.")"};
	my $fig = $self->fig();
	my $prokgenomes;
	my $genome_info = $fig->genome_info();
    foreach my $genome (@$genome_info) {
      if ($genome->[3] eq "Bacteria") {
		$prokgenomes->{$genome->[0]} = 1;
	  }
    }

	if (open (INPUT, "</vol/rast-test/jobs/419/rp/".$OrganismID."/expanded_similarities")) {
		my $DataHash;
		while (my $Line = <INPUT>) {
			if ($Line =~ m/\sfig\|(\d+\.\d+)\.(peg\.\d+)/) {
				my $genome = $1;
				my $peg = $2;
				my @array = split(/\s/,$Line);
				if ($array[0] =~ m/fig\|/) {
					$array[0] = substr($array[0],5+length($OrganismID));
				}
				my $Row = $tbl->get_row_by_key($array[0],"ID",1);
				if ($genome eq $OrganismID) {
					push(@{$Row->{"Paralogs"}},$peg.":".$array[10]);
				} elsif (!defined($Row->{"Best hit score"}->[0]) || $Row->{"Best hit score"}->[0] < $array[10]) {
					$Row->{"Best hit score"}->[0] = $array[10];
					$Row->{"Best hit"}->[0] = $genome.".".$peg;
					if (defined($prokgenomes->{$genome})) {
						$Row->{"Best hit prokaryote"}->[0] = 1;
						$Row->{"Hits any prokaryote"}->[0] = 1;
					}
					$Row->{"Best hit role"}->[0] = $fig->function_of("fig|".$genome.".".$peg);
				} elsif (defined($prokgenomes->{$genome})) {
					$Row->{"Hits any prokaryote"}->[0] = 1;
				}
			}
		}
		close(INPUT);
	}

	return $self->{"_CACHE"}->{"GetRawGenomeFeatureTable(".$OrganismID.")"};
}

=head3 run_blast_on_gene
Definition:
   FIGMODEL->run_blast_on_gene(string::source genome,string::source gene ID,string::search genome);
Description:
=cut
sub run_blast_on_gene {
	my ($self,$genomeOne,$geneID,$genomeTwo) = @_;
	#Setting filename
	my $filename = $self->config("temp file directory")->[0].$self->filename().".fasta";
	my $singleGene = 1;	
	#If the input gene ID is undefined or "ALL", then the input file is the fasta file for the genome
	if (!defined($geneID) || $geneID eq "ALL") { 
		$filename = $self->fig($genomeOne)->organism_directory($genomeOne)."/Features/peg/fasta";
		$singleGene = 0;
	} else {
		#Pulling the query sequence
		my $sequence = $self->fig($genomeOne)->get_translation("fig|".$genomeOne.".".$geneID);
		#Printing the query sequence to file
		open(TMP, ">$filename") or die "could not open file '$filename': $!";
   		#FIG::display_id_and_seq("fig|".$genomeOne.".".$geneID, \$sequence, \*TMP);
    	close(TMP) or die "could not close file '$filename': $!";
	}
	#Forming blastall command line
	#my $cmd = FIG_Config::ext_bin."/blastall";
	my @args = ('-i',$filename, '-d',$self->fig($genomeTwo)->organism_directory($genomeTwo)."/Features/peg/fasta", '-T', 'T', '-F', 'F', '-e',10, '-W', 0,'-p','blastp');
	# run blast
	#my $output = $self->fig()->run_gathering_output($cmd, @args);
	#print $output;
	if ($singleGene == 1 && -e $filename) {
		unlink($filename);	
	}
}

=head3 minimal_genome_analysis
Definition:
	FIGMODEL->minimal_genome_analysis();
=cut
sub minimal_genome_analysis {
	my ($self) = @_;
	#Getting the genome for mycoplasma and h influenza
	my $MycoplasmaFunctions = new ModelSEED::FIGMODEL::FIGMODELTable(["ROLE","GENES","HINFORTH"],$self->{"database message file directory"}->[0]."MycoplasmaRoles.txt",["ROLE","GENES","HINFORTH"],"\t","|",undef);
	my $mGenit = $self->GetGenomeFeatureTable("243273.1");
	for (my $i=0; $i < $mGenit->size(); $i++) {
		my $row = $mGenit->get_row($i);
		if ($row->{ID}->[0] =~ m/fig\|(\d+.\d+)\.(peg\.\d+)/) {
			my $id = $2;
			my @sim_results = $self->fig()->sims($row->{ID}->[0], 10000, 0.01, "fig");
			my $bestScores = 1;
			my $bestHit = "none";
			for (my $k=0; $k < @sim_results; $k++) {
				if ($sim_results[$k]->[1] =~ m/fig\|(\d+.\d+)\.(peg\.\d+)/) {
					my $genome = $1;
					my $gene = $2;
					if ($genome eq "71421.1" && $bestScores > $sim_results[$k]->[10]) {
						$bestScores = $sim_results[$k]->[10];
						$bestHit = $gene;
					}
				}
			}
			for (my $j=0; $j < @{$row->{"ROLES"}}; $j++) {
				my $newRow = $MycoplasmaFunctions->get_row_by_key($row->{"ROLES"}->[$j],"ROLE",1);
				push(@{$newRow->{"GENES"}},$id);
				if ($bestHit ne "none") {
					push(@{$newRow->{"HINFORTH"}},$id."->".$bestHit.":".$bestScores);
				}
			}
		}
	}
	$MycoplasmaFunctions->save();
	return;
	#Go through all essential genes and find homologs and isofunctionals
	my $genomeList = ["99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"];
	my $genomeNames = ["Salmonella typhimurium LT2","Haemophilus influenzae KW20","Staphylococcus aureus N315","Helicobacter pylori 26695","Francisella tularensis U112","Streptococcus pneumoniae R6","Mycobacterium tuberculosis H37Rv","Mycoplasma genitalium G-37","Acinetobacter ADP1","Escherichia coli K12","Mycoplasma pulmonis UAB CTIP","Pseudomonas aeruginosa PAO1","Bacillus subtilis 168"];
	my $genomeHash;
	#BBH table
	my $assignedToFamily;
	my $essentialBBH = new ModelSEED::FIGMODEL::FIGMODELTable(["ROLES","FAMILY","NUMGENOMES","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],$self->{"database message file directory"}->[0]."EssentialFamilies.txt",["ROLES","FAMILY","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],"\t","|",undef);
	my $minBBH = new ModelSEED::FIGMODEL::FIGMODELTable(["ROLES","FAMILY","NUMGENOMES","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],$self->{"database message file directory"}->[0]."MinEssentialFamilies.txt",["ROLES","FAMILY","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],"\t","|",undef);
	#Gene hashes
	my $essentialGenes;
	my $minimalEssentials;
	#Functional role tables
	my $essentialFunctions = new ModelSEED::FIGMODEL::FIGMODELTable(["ROLE","GENOMES","NUMGENES","NUMGENOMES","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],$self->{"database message file directory"}->[0]."EssentialFunctions.txt",["ROLE",,"GENOMES","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],"\t","|",undef);
	my $minimalEssentialFunctions = new ModelSEED::FIGMODEL::FIGMODELTable(["ROLE","NUMGENES","NUMGENOMES","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],$self->{"database message file directory"}->[0]."MinimalEssentialFunctions.txt",["ROLE","99287.1","71421.1","158879.1","85962.1","401614.5","171101.1","83332.1","243273.1","62977.3","83333.1","272635.1","208964.1","224308.1"],"\t","|",undef);
	#Loading the essential functional role data tables
	for (my $i=0; $i < @{$genomeList}; $i++) {
		my $features = $self->GetGenomeFeatureTable($genomeList->[$i]);
		$genomeHash->{$genomeList->[$i]} = 1;
		my $tbl = $self->GetEssentialityData($genomeList->[$i]);
		for (my $j=0; $j < $tbl->size(); $j++) {
			my $row = $tbl->get_row($j);
			if ($row->{Essentiality}->[0] ne "nonessential") {
				my $generow = $features->get_row_by_key("fig|".$genomeList->[$i].".".$row->{Gene}->[0],"ID");
				if ($genomeList->[$i] ne "83333.1" || $row->{Media}->[0] eq "ArgonneLBMedia") {
					if (defined($generow->{"ROLES"})) {
						$essentialGenes->{$genomeList->[$i]}->{$row->{Gene}->[0]} = $generow->{"ROLES"};
						for (my $k=0; $k < @{$generow->{"ROLES"}}; $k++) {
							my $newRow = $essentialFunctions->get_row_by_key($generow->{"ROLES"}->[$k],"ROLE",1);
							$essentialFunctions->add_data($newRow,"GENOMES",$genomeNames->[$i],1);
							if (!defined($newRow->{"NUMGENES"})) {
								$newRow->{"NUMGENES"}->[0] = 0;
								$newRow->{"NUMGENOMES"}->[0] = 0;
							}
							$newRow->{"NUMGENES"}->[0]++;
							if (!defined($newRow->{$genomeList->[$i]})) {
								$newRow->{"NUMGENOMES"}->[0]++;
							}
							push(@{$newRow->{$genomeList->[$i]}},$row->{Gene}->[0]);
							$newRow = $minimalEssentialFunctions->get_row_by_key($generow->{"ROLES"}->[$k],"ROLE");
							if (defined($newRow)) {
								if (!defined($newRow->{"NUMGENES"})) {
									$newRow->{"NUMGENES"}->[0] = 0;
									$newRow->{"NUMGENOMES"}->[0] = 0;
								}
								$newRow->{"NUMGENES"}->[0]++;
								if (!defined($newRow->{$genomeList->[$i]})) {
									$newRow->{"NUMGENOMES"}->[0]++;
								}
								push(@{$newRow->{$genomeList->[$i]}},$row->{Gene}->[0]);
							}
						}
					} else {
						$essentialGenes->{$genomeList->[$i]}->{$row->{Gene}->[0]} = 1;
					}
				} else {
					if (defined($row->{"ROLES"})) {
						$minimalEssentials->{$row->{Gene}->[0]} = $generow->{"ROLES"};
						for (my $k=0; $k < @{$generow->{"ROLES"}}; $k++) {
							my $newRow = $minimalEssentialFunctions->get_row_by_key($generow->{"ROLES"}->[$k],"ROLE",1);
							if (!defined($newRow->{"NUMGENES"})) {
								$newRow->{"NUMGENES"}->[0] = 0;
								$newRow->{"NUMGENOMES"}->[0] = 0;
							}
							$newRow->{"NUMGENES"}->[0]++;
							if (!defined($newRow->{$genomeList->[$i]})) {
								$newRow->{"NUMGENOMES"}->[0]++;
							}
							push(@{$newRow->{$genomeList->[$i]}},$row->{Gene}->[0]);
						}
					} else {
						$essentialGenes->{$genomeList->[$i]}->{$row->{Gene}->[0]} = 1;
					}
				}
				
			}
		}
	}
	$essentialFunctions->save();
	$minimalEssentialFunctions->save();
	return;
	
	#Loading the BBH data tables
	for (my $i=0; $i < @{$genomeList}; $i++) {
		my $features = $self->GetGenomeFeatureTable($genomeList->[$i]);
		my $tbl = $self->GetEssentialityData($genomeList->[$i]);
		for (my $j=0; $j < $tbl->size(); $i++) {
			my $row = $tbl->get_row($i);
			if ($row->{Essentiality}->[0] ne "nonessential") {
				my $row = $features->get_row_by_key("fig|".$genomeList->[$i].".".$row->{Gene}->[0],"ID");
				if (!defined($assignedToFamily->{$genomeList->[$i]}->{$row->{Gene}->[0]})) {
					if ($genomeList->[$i] ne "83333.1" || $row->{Media}->[0] eq "ArgonneLBMedia") {
						my @sim_results = $self->fig()->sims("fig|".$genomeList->[$i].".".$row->{Gene}->[0], 10000, 0.00001, "fig");
						my $bestScores;
						my $bestEssScores;
						my $bestHit;
						my $bestEss;
						for (my $k=0; $k < @sim_results; $k++) {
							if ($sim_results[$k]->[0] =~ m/fig\|(\d+.\d+)\.(peg\.\d+)/) {
								my $genome = $1;
								my $gene = $2;
								if (defined($genomeHash->{$genome})) {
									$assignedToFamily->{$genomeList->[$i]}->{$row->{Gene}->[0]} = 1;
									my $newRow = $essentialBBH->get_row_by_key($row->{Gene}->[0],"FAMILY",1);
									if (!defined($newRow->{ROLES})) {
										$newRow->{ROLES} = $row->{"ROLES"};
										$newRow->{NUMGENOMES}->[0] = 0;
									}
									if (!defined($newRow->{$genome})) {
										$newRow->{$genome}->[3] = 0;
										$newRow->{$genome}->[4] = 0;
									}
									$newRow->{$genome}->[3]++;
									if (!defined($bestScores->{$genome}) || $bestScores->{$genome} > $sim_results[$k]->[5]) {
										$bestScores->{$genome} = $sim_results[$k]->[5];
										$bestHit->{$genome} = $gene;
									}
									if (defined($essentialGenes->{$genome}->{$gene})) {
										$newRow->{$genome}->[4]++;
										if (!defined($bestEssScores->{$genome}) || $bestEssScores->{$genome} > $sim_results[$k]->[5]) {
											$bestEssScores->{$genome} = $sim_results[$k]->[5];
											$bestEss->{$genome} = $gene;
										}
									}
								}
							}
						}
						my $newRow = $essentialBBH->get_row_by_key($row->{Gene}->[0],"FAMILY");
						my @temp = keys(%{$bestScores});
						for (my $k=0; $k < @temp;$k++) {
							$newRow->{$temp[$k]}->[1] = $bestHit->{$temp[$k]}.":".$bestScores->{$temp[$k]};
						}
						@temp = keys(%{$bestEssScores});
						for (my $k=0; $k < @temp;$k++) {
							$newRow->{$temp[$k]}->[0] = $bestEss->{$temp[$k]}.":".$bestEssScores->{$temp[$k]};
							$assignedToFamily->{$temp[$k]}->{$bestEss->{$temp[$k]}} = 1;
							$newRow->{NUMGENOMES}->[0]++;
						}
					} else {
						my @sim_results = $self->fig()->sims("fig|".$genomeList->[$i].".".$row->{Gene}->[0], 10000, 0.00001, "fig");
						my $bestScores;
						my $bestEssScores;
						my $bestHit;
						my $bestEss;
						for (my $k=0; $k < @sim_results; $k++) {
							if ($sim_results[$k]->[0] =~ m/fig\|(\d+.\d+)\.(peg\.\d+)/) {
								my $genome = $1;
								my $gene = $2;
								if (defined($genomeHash->{$genome})) {
									my $newRow = $minBBH->get_row_by_key($row->{Gene}->[0],"FAMILY",1);
									if (!defined($newRow->{ROLES})) {
										$newRow->{ROLES} = $row->{"ROLES"};
										$newRow->{NUMGENOMES}->[0] = 0;
									}
									if (!defined($newRow->{$genome})) {
										$newRow->{$genome}->[3] = 0;
										$newRow->{$genome}->[4] = 0;
									}
									$newRow->{$genome}->[3]++;
									if (!defined($bestScores->{$genome}) || $bestScores->{$genome} > $sim_results[$k]->[5]) {
										$bestScores->{$genome} = $sim_results[$k]->[5];
										$bestHit->{$genome} = $gene;
									}
									if (defined($essentialGenes->{$genome}->{$gene})) {
										$newRow->{$genome}->[4]++;
										if (!defined($bestEssScores->{$genome}) || $bestEssScores->{$genome} > $sim_results[$k]->[5]) {
											$bestEssScores->{$genome} = $sim_results[$k]->[5];
											$bestEss->{$genome} = $gene;
										}
									}
								}
							}
						}
						my $newRow = $minBBH->get_row_by_key($row->{Gene}->[0],"FAMILY");
						my @temp = keys(%{$bestScores});
						for (my $k=0; $k < @temp;$k++) {
							$newRow->{$temp[$k]}->[1] = $bestHit->{$temp[$k]}.":".$bestScores->{$temp[$k]};
						}
						@temp = keys(%{$bestEssScores});
						for (my $k=0; $k < @temp;$k++) {
							$newRow->{$temp[$k]}->[0] = $bestEss->{$temp[$k]}.":".$bestEssScores->{$temp[$k]};
							$newRow->{NUMGENOMES}->[0]++;
						}
					}
				}
			}
		}
	}
	$essentialBBH->save();
	$minBBH->save();
}

=head3 get_genome_sequence
Definition:
	[string] = FIGMODEL->get_genome_sequence(string::genome ID);
Description:
	This function returns a list of the DNA sequence for every contig of the genome
=cut
sub get_genome_sequence {
	my ($self,$genomeid) = @_;
	my $sequences;
	my $fig = $self->fig($genomeid);
	if ($fig->{_source} eq "SEED" && !$fig->is_genome($genomeid)) {
		$self->error_message("get_genome_sequence:".$genomeid." does not exist!\n");
		return $sequences;
	}
	my @contigs = $fig->all_contigs($genomeid);
	for (my $i=0; $i < @contigs; $i++) {
		my $contigLength = $fig->contig_ln($genomeid,$contigs[$i]);
		push(@{$sequences},$fig->get_dna($genomeid,$contigs[$i],1,$contigLength));
	}
	return $sequences;
}

=head3 get_genome_source
Definition:
	float:fraction of gc = FIGMODEL->get_genome_source(string::genome ID);
Description:
	This function determines if the genome is RAST or SEED
=cut
sub get_genome_source {
	my ($self,$genomeid) = @_;
	if ($self->fig()->is_genome($genomeid)) {
		return "SEED";
	}
	my $obj = $self->database()->get_object("rastjob",{genome_id=>$genomeid});
	if (!defined($obj)) {
		$obj = $self->database()->get_object("rasttestjob",{genome_id=>$genomeid});
		if (!defined($obj)) {
			return "NONE";
		}
	}
	return "RAST";
}

=head3 get_genome_gc_content
Definition:
	float:fraction of gc = FIGMODEL->get_genome_gc_content(string::genome ID);
Description:
	This function calculates the gc content of the input genome
=cut
sub get_genome_gc_content {
	my ($self,$genomeid) = @_;
	my $source = $self->get_genome_source($genomeid);
	if ($source eq "RAST") {
		#Querying GC content from database for RAST genomes
		my $obj = $self->database()->get_object("rastjob",{genome_id=>$genomeid});
		if (!defined($obj)) {
			$obj = $self->database()->get_object("rasttestjob",{genome_id=>$genomeid});
			if (!defined($obj)) {
				return 0.5;
			}
			my $gc = $obj->metaxml()->get_metadata('genome.gc_content');
			return 0.01*$gc;
		}
	} elsif ($source eq "SEED") {
		#Calculating gc content from sequence for SEED genomes
		my $numgc = 0;
		my $totalLength = 0;
		my $sequences = $self->get_genome_sequence($genomeid);
		for (my $i=0; $i < @{$sequences}; $i++) {
			$totalLength += length($sequences->[$i]);
			while ($sequences->[$i] =~ m{([gc])}g) {
				$numgc++;
			}
		}
		if ($totalLength == 0) {
			$self->error_message("get_genome_gc_content:Could not obtain genome-sequence for ".$genomeid);
			return 0.5;	
		}
		return $numgc/$totalLength;
	} else {
		return 0.5;
	}
}

=head3 get_genome_stats
Definition:
	{[string]}::genome stats = FIGMODEL->get_genome_stats(string::genome ID);
Description:
	This function is used to pull genome stats if they are present in the genome stats table
=cut
sub get_genome_stats {
	my ($self,$genomeid) = @_;
	my $genome = $self->get_genome($genomeid);
	if (!defined($genome)) {
		return undef;
	}
	return $genome->genome_stats();
}

=head3 change_genome_cellwalltype
Definition:
	FIGMODEL->change_genome_cellwalltype(string::genome ID,string:cell wall type);
Description:
	This function is used to change the class of a genome in the genome stats table
=cut
sub change_genome_cellwalltype {
	my ($self,$genomeid,$newClass) = @_;
	my $genome = $self->get_genome($genomeid);
	if (!defined($genome)) {
		$self->error_message("FIGMODEL:could not find ".$genomeid." when trying to change class");
	}
	$genome->class($newClass);
}

=head3 roles_of_function
Definition:
	my @RoleList = $model->roles_of_function($FunctionName);
Description:
=cut
sub roles_of_function {
	my ($self,$Function) = @_;
	my %RoleHash;
	my @Roles = split(/\s*;\s+|\s+[\@\/]\s+/,$Function);
	foreach my $Role (@Roles) {
		$Role =~ s/\s*\#.*$//;
		$RoleHash{$Role} = 1;
	}
	return sort keys(%RoleHash);
}

=head3 subsystem_is_valid
Definition:
	(0/1) = $model->subsystem_is_valid($Subsystem);
Description:
	Checks if the input subsystem is valid
=cut
sub subsystem_is_valid {
	my ($self,$Subsystem) = @_;

	if ($Subsystem eq "NONE" || length($Subsystem) == 0) {
		return 0;
	}
	my $SubsystemClass = $self->class_of_subsystem($Subsystem);
	if (!defined($SubsystemClass) || $SubsystemClass->[0] =~ m/Experimental\sSubsystems/i || $SubsystemClass->[0] =~ m/Clustering\-based\ssubsystems/i) {
		return 1;
	}
	return 0;
}

=head2 Biochemistry database related methods

=head3 add_reaction_role_mapping
Definition:
	FIGMODEL->add_reaction_role_mapping([string]:reactions,[string]:roles);
=cut

sub add_reaction_role_mapping {
	my($self,$reactions,$roles,$types) = @_;
	#Getting existing complexes
	my $cpxHash;
	my $cpxroles = $self->database()->get_objects("cpxrole");
	for (my $j=0; $j < @{$cpxroles}; $j++) {
		$cpxHash->{$cpxroles->[$j]->COMPLEX()}->{$cpxroles->[$j]->ROLE()} = 1;
	}
	my $cpxRoles;
	my @cpxs = keys(%{$cpxHash});
	for (my $j=0; $j < @cpxs; $j++) {
		$cpxRoles->{join("|",sort(keys(%{$cpxHash->{$cpxs[$j]}})))} = $cpxs[$j];
	}
	#Getting role IDs for all input roles
	my $roleIDs;
	for (my $i=0; $i < @{$roles}; $i++) {
		my $role = $self->convert_to_search_role($roles->[$i]);
		my $roleobj = $self->database()->get_object("role",{searchname => $role});
		if (!defined($roleobj)) {
			my $newRoleID = $self->database()->check_out_new_id("role");
			my $roleMgr = $self->database()->get_object_manager("role");
			$roleobj = $roleMgr->create({id=>$newRoleID,name=>$roles->[$i],searchname=>$role});	
		}
		push(@{$roleIDs},$roleobj->id());
	}
	#Creating a new complex if one does not already exist
	my $cpxID;
	if (!defined($cpxRoles->{join("|",sort(@{$roleIDs}))})) {
		$cpxID = $self->database()->check_out_new_id("complex");
		my $cpxMgr = $self->database()->get_object_manager("complex");
		my $newCpx = $cpxMgr->create({id=>$cpxID});
		#Adding roles to new complex
		for (my $i=0; $i < @{$roleIDs}; $i++) {
			my $cpxRoleMgr = $self->database()->get_object_manager("cpxrole");
			$cpxRoleMgr->create({COMPLEX=>$cpxID,ROLE=>$roleIDs->[$i],type=>$types->[$i]});
		}
	} else {
		$cpxID = $cpxRoles->{join("|",sort(@{$roleIDs}))};
	}
	#Adding the complex to the reaction complex table
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $rxnCpxObj = $self->database()->get_object("rxncpx",{REACTION=>$reactions->[$i],COMPLEX=>$cpxID});
		if (defined($rxnCpxObj)) {
			$rxnCpxObj->master(1);	
		} else {
			my $rxncpxMgr = $self->database()->get_object_manager("rxncpx");
			$rxncpxMgr->create({REACTION=>$reactions->[$i],COMPLEX=>$cpxID,master=>1});
		}
	}
}

=head3 print_biomass_reaction_file
Definition:
	FIGMODEL->print_biomass_reaction_file(string:biomass id);
Description:
	Prints a flatfile with data on the specified biomass reaction for the MFAToolkit
=cut

sub print_biomass_reaction_file {
	my($self,$biomassID) = @_;
	my $bioMgr = $self->database()->get_object_manager("bof");
	my $objs = $bioMgr->get_objects({id=>$biomassID});
	if (defined($objs->[0])) {
		$self->database()->print_array_to_file($self->config("reaction directory")->[0].$biomassID,["DATABASE\t".$biomassID,"EQUATION\t".$objs->[0]->equation(),"NAME\t".$objs->[0]->name()]);
	}
}

=head3 printReactionDBTable
Definition:
	void FIGMODEL->printReactionDBTable(optional string:output directory);
Description:
=cut

sub printReactionDBTable {
	my($self,$directory) = @_;
	if (!defined($directory)) {
		$directory = $self->config("Reaction database directory")->[0]."masterfiles/";
	}
	my $objs = $self->database()->get_objects("reaction");
	my $outputArray = ["DATABASE	NAME	EQUATION	ENZYME	THERMODYNAMIC REVERSIBILITY	DELTAG	DELTAGERR	BALANCE	TRANSPORTED ATOMS"];
	for (my $i=0; $i < @{$objs}; $i++) {
		my $enzyme = $objs->[$i]->enzyme();
		if (defined($enzyme) && length($enzyme) > 0) {
			$enzyme = substr($enzyme,1,length($enzyme)-2);
		} else {
			$enzyme = "";
		}
		my $deltaG = "";
		my $deltaGErr = "";
		if (defined($objs->[$i]->deltaG()) && $objs->[$i]->deltaG() ne "10000000") {
			$deltaG = $objs->[$i]->deltaG();
			$deltaGErr = $objs->[$i]->deltaGErr();
		}
		my $line = $objs->[$i]->id()."\t".$objs->[$i]->name()."\t".$objs->[$i]->equation()."\t".$enzyme."\t".$objs->[$i]->reversibility()."\t".$deltaG."\t".$deltaGErr."\t".$objs->[$i]->status()."\t".$objs->[$i]->transportedAtoms();
		push(@{$outputArray},$line);
	}
	$objs = $self->database()->get_objects("bof");
	for (my $i=0; $i < @{$objs}; $i++) {
		if ($objs->[$i]->equation() ne "NONE") {
			my $line = $objs->[$i]->id()."\tBiomass\t".$objs->[$i]->equation()."\t\t\t\t\t\t";
			push(@{$outputArray},$line);
		}
	}
	$self->database()->print_array_to_file($directory."ReactionDatabase.txt",$outputArray);
}

=head3 get_compound_hash
Definition:
	{string:compound id => PPOcompound:compound object} = FIGMODEL->get_compound_hash();
Description:
=cut
sub get_compound_hash {
	my($self) = @_;
	if (!defined($self->{_compoundhash})) {
		my $objs = $self->database()->get_objects("compound");
		for (my $i=0; $i < @{$objs}; $i++) {
			$self->{_compoundhash}->{$objs->[$i]->id()} = $objs->[$i];
		}
	}
	return $self->{_compoundhash};
}

=head3 get_map_hash
Definition:
	{string:reaction id => PPOdiagram:diagram object} = FIGMODEL->get_map_hash({type => string:entity type});
Description:
=cut
sub get_map_hash {
	my($self,$args) = @_;
	$args = $self->process_arguments($args,["type"]);
	if (defined($args->{error})) {
	    $args->{type} = "reaction";
	}
	if (!defined($self->{_maphash}->{$args->{type}})) {
		my $objs = $self->database()->get_objects("diagram",{type => "KEGG"});
		my $mapHash;
		for (my $i=0; $i < @{$objs}; $i++) {
			$mapHash->{$objs->[$i]->id()} = $objs->[$i];
		}
		my $entobjs = $self->database()->get_objects("dgmobj",{entitytype => $args->{type}});
		for (my $i=0; $i < @{$entobjs}; $i++) {
			$self->{_maphash}->{$args->{type}}->{$entobjs->[$i]->entity()}->{$entobjs->[$i]->DIAGRAM()} = $mapHash->{$entobjs->[$i]->DIAGRAM()};
		}
	}
	return $self->{_maphash}->{$args->{type}};
}

=head3 printCompoundDBTable
Definition:
	void FIGMODEL->printCompoundDBTable(optional string:output directory);
Description:
=cut

sub printCompoundDBTable() {
	my($self,$directory) = @_;
	if (!defined($directory)) {
		$directory = $self->config("Reaction database directory")->[0]."masterfiles/";
	}
	my $objs = $self->database()->get_objects("compound");
	my $outputArray = ["DATABASE	NAME	FORMULA	CHARGE	DELTAG	DELTAGERR	MASS	KEGGID"];
	for (my $i=0; $i < @{$objs}; $i++) {
		my $kegg = "";
		my $aliases = $self->database()->get_objects("cpdals",{COMPOUND=>$objs->[$i]->id(),type=>"KEGG"});
		for (my $j = 0; $j < @{$aliases}; $j++) {
			if (length($kegg) > 0) {
				$kegg .= "|";	
			}
			$kegg .= $aliases->[$j]->alias();
		}
		my $deltaG = "";
		my $deltaGErr = "";
		if (defined($objs->[$i]->deltaG()) && $objs->[$i]->deltaG() ne "10000000") {
			$deltaG = $objs->[$i]->deltaG();
			$deltaGErr = $objs->[$i]->deltaGErr();
		}
		my $charge = "";
		if (defined($objs->[$i]->charge()) && $objs->[$i]->charge() ne "10000000") {
			$charge = $objs->[$i]->charge();
		}
		my $line = $objs->[$i]->id()."\t".$objs->[$i]->name()."\t".$objs->[$i]->formula()."\t".$charge."\t".$deltaG."\t".$deltaGErr."\t".$objs->[$i]->mass()."\t".$kegg;
		push(@{$outputArray},$line);
	}
	$self->database()->print_array_to_file($directory."CompoundDatabase.txt",$outputArray);
}

=head3 ApplyStoichiometryCorrections

Definition:
	(string:Equation,string:Reverse equation,string:Full equation) = FIGMODEL->ApplyStoichiometryCorrections(string:Equation,string:Reverse equation,string:Full equation);
Description:

=cut

sub ApplyStoichiometryCorrections {
	my($self,$Equation,$ReverseEquation,$FullEquation) = @_;

	my $CorrectionTable = $self->database()->GetDBTable("STOICH CORRECTIONS");
	if (defined($CorrectionTable)) {
		my $Row = $CorrectionTable->get_row_by_key($Equation,"OLD CODE");
		if (!defined($Row)) {
			$Row = $CorrectionTable->get_row_by_key($ReverseEquation,"OLD CODE");
			if (defined($Row)) {
				return ($Row->{"REVERSE CODE"}->[0],$Row->{"CODE"}->[0],$Row->{"REVERSE EQUATION"}->[0]);
			}
			return ($Equation,$ReverseEquation,$FullEquation);
		}
		return ($Row->{"CODE"}->[0],$Row->{"REVERSE CODE"}->[0],$Row->{"EQUATION"}->[0]);
	}
	return ($Equation,$ReverseEquation,$FullEquation);
}

=head3 AddStoichiometryCorrection

Definition:
	0/1 = FIGMODEL->AddStoichiometryCorrection(string:Reaction ID,string:New equation);
Description:

=cut

sub AddStoichiometryCorrection {
	my($self,$DataToCorrect,$ReplacementEquation) = @_;

	#Checking if this is a reaction ID
	my $OldEquation = $DataToCorrect;
	my $ReactionData;
	if ($DataToCorrect =~ m/(rxn\d\d\d\d\d)/) {
		$ReactionData = FIGMODELObject->load($self->{"reaction directory"}->[0].$1,"\t");
		if (!defined($ReactionData)) {
			print STDERR "FIGMODEL:AddStoichiometryCorrection: Could not find input reaction ID: ".$DataToCorrect."\n";
			return 0;
		}
		$DataToCorrect = $ReactionData->{"EQUATION"}->[0];
	}
	#Loading the current correction table
	my $CorrectionTable = $self->database()->GetDBTable("STOICH CORRECTIONS");
	if (!defined($CorrectionTable)) {
		$CorrectionTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["OLD CODE","CODE","REVERSE CODE","EQUATION","REVERSE EQUATION"],$self->{"Reaction database directory"}->[0]."masterfiles/StoichiometryCorrections.txt",["OLD CODE"],";","",undef)
	}
	#Getting the code etc for the data to correct and the new equation
	my $Translation = LoadSeparateTranslationFiles($self->{"Translation directory"}->[0]."CpdToAll.txt","\t");
	(my $Direction,my $Code,my $ReverseCode,my $Equation,my $Compartment,my $Error) = $self->ConvertEquationToCode($DataToCorrect,$Translation);
	if ($Error != 1) {
		($Direction,my $NewCode,my $NewReverseCode,my $NewEquation,$Compartment,$Error) = $self->ConvertEquationToCode($ReplacementEquation,$Translation);
		my $ReverseNewEquation = $NewEquation;
		$ReverseNewEquation =~ s/(.+)\s(<=>|=>|<=)\s(.+)/$3 $2 $1/;
		if ($ReverseNewEquation =~ m/\s=>/) {
			$ReverseNewEquation =~ s/\s=>/ <=/;
		} elsif ($ReverseNewEquation =~ m/<=\s/) {
			$ReverseNewEquation =~ s/<=\s/=> /;
		}
		if ($Error != 1) {
			#First checking if a row already exists... if so, the row will be overwritten
			my $Row = $CorrectionTable->get_row_by_key($Code,"CODE");
			if (!defined($Row)) {
				my $Row = $CorrectionTable->get_row_by_key($ReverseCode,"CODE");
				if (defined($Row)) {
					$Row->{"CODE"}->[0] = $NewReverseCode;
					$Row->{"REVERSE CODE"}->[0] = $NewCode;
					$Row->{"EQUATION"}->[0] = $ReverseNewEquation;
					$Row->{"REVERSE EQUATION"}->[0] = $NewEquation;
				} else {
					$Row->{"CODE"}->[0] = $NewCode;
					$Row->{"REVERSE CODE"}->[0] = $NewReverseCode;
					$Row->{"EQUATION"}->[0] = $NewEquation;
					$Row->{"REVERSE EQUATION"}->[0] = $ReverseNewEquation;
					$Row->{"OLD CODE"}->[0] = $Code;
					$CorrectionTable->add_row($Row);
				}
			} else {
				$Row->{"CODE"}->[0] = $NewCode;
				$Row->{"REVERSE CODE"}->[0] = $NewReverseCode;
				$Row->{"EQUATION"}->[0] = $NewEquation;
				$Row->{"REVERSE EQUATION"}->[0] = $ReverseNewEquation;
			}
			$CorrectionTable->save();
			return 1;
		}
	}
	return 0;
}
=head3 ConvertToNeutralFormula

Definition:
	string:neutral formula = FIGMODEL->ConvertToNeutralFormula(string:original formula,string:charge);
Description:
	Adjusts the hydrogens in a formula until the compound is in neutral form

=cut
sub ConvertToNeutralFormula {
	my ($self,$NeutralFormula,$Charge) = @_;

	if (!defined($NeutralFormula)) {
		$NeutralFormula = "";
	} elsif ($NeutralFormula eq "H") {
		#Do nothing
	} elsif (defined($Charge) && $Charge ne "0") {
		my $CurrentH = 0;
		if ($NeutralFormula =~ m/H(\d+)/) {
			$CurrentH = $1;
		} elsif ($NeutralFormula =~ m/H[A-Z]/ || $NeutralFormula =~ m/H$/) {
			$CurrentH = 1;
		}
		my $NewH = $CurrentH;
		if ($Charge >= $CurrentH) {
			$NewH = 0;
		} else {
			$NewH = $CurrentH - $Charge;
		}
		my $Replace = "H";
		if ($NewH > 1) {
			$Replace = "H".$NewH;
		} elsif ($NewH == 0) {
			$Replace = "";
		}
		if ($CurrentH == 0 && $NewH > 0) {
			$NeutralFormula .= "H";
			if ($NewH > 1) {
				$NeutralFormula .= $NewH;
			}
		} elsif ($CurrentH == 1) {
			$NeutralFormula =~ s/H$/$Replace/;
			$NeutralFormula =~ s/H([A-Z])/$Replace$1/;
		} else {
			my $Match = "H".$CurrentH;
			$NeutralFormula =~ s/$Match/$Replace/;
		}
	}

	return $NeutralFormula;
}

=head3 rebuild_compound_database_table

Definition:
	void FIGMODEL->rebuild_compound_database_table();
Description:
	This function uses the compound files in the compounds directory to rebuild the table of compounds in the database

=cut
sub rebuild_compound_database_table {
	my ($self) = @_;

	#Processing all pending compound combinations
	if (-e $self->config("pending combination filename")->[0]) {
		my $Combinations = $self->database()->load_multiple_column_file($self->config("pending combination filename")->[0],";");
		for (my $i=0; $i < @{$Combinations}; $i++) {
			if (@{$Combinations->[$i]} >= 2) {
				my $CompoundOne = FIGMODELObject->load($self->config("compound directory")->[0].$Combinations->[$i]->[0],"\t");
				my $CompoundTwo = FIGMODELObject->load($self->config("compound directory")->[0].$Combinations->[$i]->[1],"\t");
				$CompoundOne->add_data($CompoundTwo->{"NAME"},"NAME",1);
				$CompoundOne->save();
			}
		}
		unlink($self->config("pending combination filename")->[0]);
	}
	
	#Backing up compound KEGG map
	system("cp ".$self->config("Translation directory")->[0]."CpdToKEGG.txt ".$self->config("Translation directory")->[0]."OldCpdToKEGG.txt");
	
	#Creating the compounds table
	my $tbl = $self->database()->create_table_prototype("COMPOUNDS");
	my @Files = glob($self->config("compound directory")->[0]."cpd*");
	my $obsoleteIDs;
	foreach my $Filename (@Files) {
		if ($Filename =~ m/(cpd\d\d\d\d\d)$/) {
			my $Data = FIGMODELObject->load($self->config("compound directory")->[0].$1,"\t");
			my @temp = @{$Data->{NAME}};
			delete $Data->{NAME};
			@{$Data->{NAME}} = $self->remove_duplicates(@temp);
			$Data->delete_key("CHANGES");
			$Data->save();
			
			#---Looking for a name match---#
			my $NewData = undef;
			if (!defined($Data->{"NAME"})) {
				$self->error_message("FIGMODEL:rebuild_compound_database_table:".$Data->{"DATABASE"}->[0]." had no names!");
				next;
			}
			
			#---First checking to see if a fullname match or search name match already exists in the DB---#
			foreach my $Name (@{$Data->{"NAME"}}) {
				$Name =~ s/;/-/;
				if (length($Name) > 0) {
					foreach my $SearchName ($self->ConvertToSearchNames($Name)) {
						if (length($SearchName) > 0) {
							push(@{$Data->{"SEARCHNAME"}},$SearchName);
						}
					}
				}
			}
			foreach my $SearchName (@{$Data->{"SEARCHNAME"}}) {
				$NewData = $tbl->get_row_by_key($SearchName,"SEARCHNAME");
				if (defined($NewData)) {
					last;
				}
			}

			#Adding the compound to the database table
			if (!defined($NewData)) {
				$tbl->add_row({DATABASE=>[$Data->{"DATABASE"}->[0]],NAME=>$Data->{"NAME"},SEARCHNAME=>$Data->{"SEARCHNAME"},FORMULA=>$Data->{"FORMULA"},CHARGE=>$Data->{"CHARGE"},STRINGCODE=>$Data->{"STRINGCODE"},MASS=>$Data->{"MASS"},DELTAG=>$Data->{"DELTAG"},DELTAGERR=>$Data->{"DELTAGERR"},ARGONNEID=>$Data->{"DATABASE"}});
			} else {
				my $originalObject = FIGMODELObject->load($self->config("compound directory")->[0].$NewData->{DATABASE}->[0],"\t");
				$originalObject->add_data($Data->{"NAME"},"NAME",1);
				$tbl->add_data($NewData,"NAME",$Data->{"NAME"}->[0],1);
				$tbl->add_data($NewData,"SEARCHNAME",$Data->{"SEARCHNAME"}->[0],1);
				if (!defined($NewData->{"FORMULA"}) && defined($Data->{"FORMULA"})) {
					my $formula = $Data->{"FORMULA"}->[0];
					if (defined($Data->{"CHARGE"})) {
						$formula = $self->ConvertToNeutralFormula($Data->{"FORMULA"}->[0],$Data->{"CHARGE"}->[0]);
					} 
					$tbl->add_data($NewData,"FORMULA",$formula,1);
					$originalObject->add_data([$formula],"FORMULA",1);
				}
				if (!defined($NewData->{"CHARGE"}) && defined($Data->{"CHARGE"})) {
					$tbl->add_data($NewData,"CHARGE",$Data->{"CHARGE"}->[0],1);
					$originalObject->add_data($Data->{"CHARGE"},"CHARGE",1);
				}
				if (!defined($NewData->{"STRINGCODE"}) && defined($Data->{"STRINGCODE"})) {
					$tbl->add_data($NewData,"STRINGCODE",$Data->{"STRINGCODE"}->[0],1);
					$originalObject->add_data($Data->{"STRINGCODE"},"STRINGCODE",1);
				}
				$Data->add_data(["This compound is now obselete replaced by equivalent compound ".$NewData->{"DATABASE"}->[0]."."],"CHANGES",1);
				$Data->add_headings(("CHANGES"));
				delete $Data->{"DBLINKS"};
				$Data->save();
				$originalObject->save();
				$obsoleteIDs->{$Data->{"DATABASE"}->[0]} = $NewData->{DATABASE}->[0];
				$tbl->add_data($NewData,"ARGONNEID",$Data->{"DATABASE"}->[0],1);
			}
		}
	}
	
	#Saving obsolete reaction file
	$self->database()->print_multicolumn_array_to_file($self->config("Translation directory")->[0]."ObsoleteCpdIDs.txt",$self->put_hash_in_two_column_array($obsoleteIDs,0),"\t");
	
	#Using the translation files to fill in the KEGG and model ID feilds of the database table
	@Files = glob($self->config("Translation directory")->[0]."CpdTo*");
	foreach my $Filename (@Files) {
		if ($Filename =~ m/CpdTo(.+)\.txt/) {
			my $db = $1;
			(my $dummyTwo,my $translationTwo) = $self->put_two_column_array_in_hash($self->database()->load_multiple_column_file($Filename,"\t"));
			my @foreignIDs = keys(%{$translationTwo});
			print "Now processing ".$db."\n";
			foreach my $id (@foreignIDs) {
				my $NewData = $tbl->get_row_by_key($translationTwo->{$id},"ARGONNEID");
				if (!defined($NewData)) {
					$self->error_message("FIGMODEL:rebuild_compound_database_table:Compound ".$translationTwo->{$id}." not found.");
					next;
				}
				#Ensuring that the IDs in these translation files are not obsolete
				if ($translationTwo->{$id} ne $NewData->{DATABASE}->[0]) {
					print "change\n";
				}
				$translationTwo->{$id} = $NewData->{DATABASE}->[0];
				#Adding foreign IDs to the reactions database table
				if ($db eq "KEGG") {
					push(@{$NewData->{KEGGID}},$id);
				} else {
					$tbl->add_data($NewData,"MODELID",$id,1);
					push(@{$NewData->{MODELS}},$db.":".$id);
				}
			}
			#Saving the altered translation files
			$self->database()->print_multicolumn_array_to_file($Filename,$self->put_hash_in_two_column_array($translationTwo,0),"\t");
		}
	}
	
	#Using the KEGG map data table to populate the KEGG map column
	my $mapTbl = $self->database()->get_table("KEGGMAPDATA");
	for (my $i=0; $i < $mapTbl->size(); $i++) {
		my $row = $mapTbl->get_row($i);
		if (defined($row->{COMPOUNDS})) {
			for (my $j=0; $j < @{$row->{COMPOUNDS}}; $j++) {
				my $NewData = $tbl->get_row_by_key($row->{COMPOUNDS}->[$j],"ARGONNEID");
				if (defined($NewData)) {
					$row->{COMPOUNDS}->[$j] = $NewData->{DATABASE}->[0];
					push(@{$NewData->{"KEGG MAPS"}},$row->{ID}->[0]);
				}
			}
		}
	}
	$mapTbl->save();
	
	#Saving the reaction database table
	$tbl->save();
}

=head3 rebuild_reaction_database_table

Definition:
	void FIGMODEL->rebuild_reaction_database_table();
Description:
	This function uses the reaction files in the reactions directory to rebuild the table of reactions in the database

=cut
sub rebuild_reaction_database_table {
	my ($self) = @_;
	
	my $tbl = $self->database()->create_table_prototype("REACTIONS");
	my $biomassTbl = $self->database()->create_table_prototype("BIOMASS");
	my @Files = glob($self->config("reaction directory")->[0]."rxn*");
	push(@Files,glob($self->config("reaction directory")->[0]."bio*"));
	(my $dummy,my $translation) = $self->put_two_column_array_in_hash($self->database()->load_multiple_column_file($self->config("Translation directory")->[0]."ObsoleteCpdIDs.txt","\t"));
	my $obsoleteIDs;
	foreach my $Filename (@Files) {
		if ($Filename =~ m/(rxn\d\d\d\d\d)$/ || $Filename =~ m/(bio\d\d\d\d\d)$/) {
			my $Data = FIGMODELObject->load($self->{"reaction directory"}->[0].$1,"\t");
			$Data->delete_key("CHANGES");
			$Data->save();
			#---Looking for an equation match---#
			my $NewData = undef;
			if (!defined($Data->{"EQUATION"})) {
				$self->error_message("FIGMODEL:rebuild_reaction_database_table:".$Data->{"DATABASE"}->[0]." had no equation!");
				next;
			}
			(my $Direction,my $Code,my $ReverseCode,my $FullEquation,my $NewCompartment,my $Error) = $self->ConvertEquationToCode($Data->{"EQUATION"}->[0],$translation);
			if ($Error == 1) {
				#If the reaction involves a compound not found in the compound database, then something is wrong and this reaction should not be in the reaction database
				$self->error_message("FIGMODEL:rebuild_reaction_database_table:Error in ".$Data->{"DATABASE"}->[0]." equation: ".$FullEquation);
				next;
			}
			#Checking if the reaction is involved in a forced mapping and if so, the equation is replaced with the forced mapping equation:
			($Code,$ReverseCode,$FullEquation) = $self->ApplyStoichiometryCorrections($Code,$ReverseCode,$FullEquation);
			#Checking if the reaction is already in the database
			if ($Filename =~ m/(rxn\d\d\d\d\d)$/) {
				$NewData = $tbl->get_row_by_key($Code,"CODE");
				my $suffix = "";
				if (!defined($NewData)) {
					$suffix = "r";
					$NewData = $tbl->get_row_by_key($ReverseCode,"CODE");
				}
				#Adding the reaction to the database table
				if (!defined($NewData)) {
					$tbl->add_row({DATABASE=>[$Data->{"DATABASE"}->[0]],NAME=>$Data->{"NAME"},EQUATION=>[$FullEquation],CODE=>[$Code],"MAIN EQUATION"=>$Data->{"MAIN EQUATION"},ENZYME=>$Data->{"ENZYME"},PATHWAY=>$Data->{"PATHWAY"},REVERSIBILITY=>$Data->{"THERMODYNAMIC REVERSIBILITY"},DELTAG=>$Data->{"DELTAG"},DELTAGERR=>$Data->{"DELTAGERR"},ARGONNEID=>[$Data->{"DATABASE"}->[0]]});
				} else {
					$obsoleteIDs->{$Data->{"DATABASE"}->[0].$suffix} = $NewData->{DATABASE}->[0];
					$tbl->add_data($NewData,"ARGONNEID",$Data->{"DATABASE"}->[0])
				}
			} else {
				$NewData = $tbl->get_row_by_key($FullEquation,"EQUATION");
				#Adding the reaction to the database table
				if (!defined($NewData)) {
					$biomassTbl->add_row({DATABASE=>[$Data->{"DATABASE"}->[0]],NAME=>$Data->{"NAME"},EQUATION=>[$FullEquation],OBSOLETEID=>[$Data->{"DATABASE"}->[0]],SOURCE=>$Data->{SOURCE},USER=>$Data->{USER},"ESSENTIAL REACTIONS"=>$Data->{"ESSENTIAL REACTIONS"}});
				} else {
					$obsoleteIDs->{$Data->{"DATABASE"}->[0]} = $NewData->{DATABASE}->[0];
					$biomassTbl->add_data($NewData,"OBSOLETEID",$Data->{"DATABASE"}->[0])
				}
			}
		}
	}
	
	#Saving obsolete reaction file
	$self->database()->print_multicolumn_array_to_file($self->config("Translation directory")->[0]."ObsoleteRxnIDs.txt",$self->put_hash_in_two_column_array($obsoleteIDs,0),"\t");
	
	#Using the translation files to fill in the KEGG and model ID feilds of the database table
	@Files = glob($self->config("Translation directory")->[0]."RxnTo*");
	foreach my $Filename (@Files) {
		if ($Filename =~ m/RxnTo(.+)\.txt/) {
			my $db = $1;
			(my $dummyTwo,my $translationTwo) = $self->put_two_column_array_in_hash($self->database()->load_multiple_column_file($Filename,"\t"));
			my @foreignIDs = keys(%{$translationTwo});
			print "Now processing ".$db."\n";
			foreach my $id (@foreignIDs) {
				my $NewData = $tbl->get_row_by_key($translationTwo->{$id},"ARGONNEID");
				if (!defined($NewData)) {
					$self->error_message("FIGMODEL:rebuild_reaction_database_table:Reaction ".$translationTwo->{$id}." not found.");
					next;
				}
				#Ensuring that the IDs in these translation files are not obsolete
				if ($translationTwo->{$id} ne $NewData->{DATABASE}->[0]) {
					print "change\n";
				}
				$translationTwo->{$id} = $NewData->{DATABASE}->[0];
				#Adding foreign IDs to the reactions database table
				if ($db eq "KEGG") {
					push(@{$NewData->{KEGGID}},$id);
				} else {
					$tbl->add_data($NewData,"MODELID",$id,1);
					push(@{$NewData->{MODELS}},$db.":".$id);
				}
			}
			#Saving the altered translation files
			$self->database()->print_multicolumn_array_to_file($Filename,$self->put_hash_in_two_column_array($translationTwo,0),"\t");
		}
	}
	
	#Using the KEGG map data table to populate the KEGG map column
	my $mapTbl = $self->database()->get_table("KEGGMAPDATA");
	for (my $i=0; $i < $mapTbl->size(); $i++) {
		my $row = $mapTbl->get_row($i);
		if (defined($row->{REACTIONS})) {
			for (my $j=0; $j < @{$row->{REACTIONS}}; $j++) {
				my $NewData = $tbl->get_row_by_key($row->{REACTIONS}->[$j],"ARGONNEID");
				if (defined($NewData)) {
					$row->{REACTIONS}->[$j] = $NewData->{DATABASE}->[0];
					push(@{$NewData->{"KEGG MAPS"}},$row->{ID}->[0]);
				}
			}
		}
	}
	$mapTbl->save();
	
	#Saving the reaction database table
	$tbl->save();
	$biomassTbl->save();
	
	#Removing obsolete reactions from database models
	for (my $i=0; $i < $self->number_of_models(); $i++) {
		my $model = $self->get_model($i);
		$model->remove_obsolete_reactions();
	}
}

=head3 distribute_bomass_data_to_biomass_files

Definition:
	void FIGMODEL->distribute_bomass_data_to_biomass_files();
Description:
	This function distributes the essential reactions and user data from the biomass table to the biomass files

=cut
sub distribute_bomass_data_to_biomass_files {
	my ($self) = @_;
	
	my $tbl = $self->database()->get_table("BIOMASS");
	for (my $i = 0; $i < $tbl->size(); $i++) {
		my $row = $tbl->get_row($i);
		my $Data = FIGMODELObject->load($self->{"reaction directory"}->[0].$row->{DATABASE}->[0],"\t");
		$Data->{"ESSENTIAL REACTIONS"} = $row->{"ESSENTIAL REACTIONS"};
		$Data->{"USER"} = $row->{"USER"};
		$Data->{"SOURCE"} = $row->{"SOURCE"};
		$Data->add_headings(("ESSENTIAL REACTIONS","USER","SOURCE"));
		$Data->save();
	}
}

=head3 get_reaction_number
Definition:
	int = FIGMODEL->get_reaction_number();
Description:
=cut
sub get_reaction_number {
	my ($self) = @_;

	my $rxntbl = $self->database()->GetDBTable("REACTIONS");
	if (!defined($rxntbl)) {
		return 0;
	}
	return $rxntbl->size();
}


=head3 get_new_cpd_id
Definition:
	string::new compound ID = FIGMODEL->get_new_cpd_id();
Description:
	Returns the first available compound ID
=cut
sub get_new_cpd_id {
	my ($self) = @_;

	#Checking if the last available ID was already found
	if (defined($self->{_last_cpd_id}->[0])) {
		$self->{_last_cpd_id}->[0]++;
		return $self->{_last_cpd_id}->[0];
	}

	#Getting the database of compounds
	my $CompoundTable = $self->database()->GetDBTable("COMPOUNDS");
	$self->{_last_cpd_id}->[0] = "cpd00001";
	for (my $i=0; $i < $CompoundTable->size(); $i++) {
		if ($CompoundTable->get_row($i)->{"DATABASE"}->[0] =~ m/cpd\d\d\d\d\d/ && $self->{_last_cpd_id}->[0] cmp $CompoundTable->get_row($i)->{"DATABASE"}->[0]) {
			$self->{_last_cpd_id}->[0] = $CompoundTable->get_row($i)->{"DATABASE"}->[0];
		}
	}
	if (defined($self->{"first new compound ID"}) && $self->{_last_cpd_id}->[0] cmp $self->{"first new compound ID"}->[0]) {
		$self->{_last_cpd_id}->[0] = "cpd".$self->{"first new compound ID"}->[0];
	} else {
		$self->{_last_cpd_id}->[0]++;
	}

	return $self->{_last_cpd_id}->[0];
}

=head3 get_new_rxn_id
Definition:
	string::new compound ID = FIGMODEL->get_new_rxn_id();
Description:
	Returns the first available compound ID
=cut
sub get_new_rxn_id {
	my ($self) = @_;

	#Checking if the last available ID was already found
	if (defined($self->{_last_rxn_id}->[0])) {
		$self->{_last_rxn_id}->[0]++;
		return $self->{_last_rxn_id}->[0];
	}

	#Getting the database of compounds
	my $ReactionTable = $self->database()->GetDBTable("REACTIONS");
	$self->{_last_rxn_id}->[0] = "rxn00001";
	for (my $i=0; $i < $ReactionTable->size(); $i++) {
		if ($ReactionTable->get_row($i)->{"DATABASE"}->[0] =~ m/rxn\d\d\d\d\d/ && $self->{_last_rxn_id}->[0] cmp $ReactionTable->get_row($i)->{"DATABASE"}->[0]) {
			$self->{_last_rxn_id}->[0] = $ReactionTable->get_row($i)->{"DATABASE"}->[0];
		}
	}
	if (defined($self->{"first new reaction ID"}) && $self->{_last_rxn_id}->[0] cmp $self->{"first new reaction ID"}->[0]) {
		$self->{_last_rxn_id}->[0] = "rxn".$self->{"first new reaction ID"}->[0];
	} else {
		$self->{_last_rxn_id}->[0]++;
	}

	return $self->{_last_rxn_id}->[0];
}

=head2 Model related methods

=head3 convert_to_search_role
Definition:
	string::search role = FIGMODEL->convert_to_search_role(string::role name);
=cut
sub convert_to_search_role {
	my ($self,$inRole) = @_;
	my $searchname = lc($inRole);
	$searchname =~ s/\d+\.\d+\.\d+\.[-0123456789]+//g;
	$searchname =~ s/\s//g;
	return $searchname;
}
=head3 import_modelfile
Definition:
	int::status = FIGMODEL->import_modelfile(string::model name);
Description:
	Imports the specified model file into the database adding reactions and compounds if necessary and creating all necessary database links
=cut
sub import_modelfile {
	my ($self,$model,$metadata) = @_;
	if (!defined($metadata->{owner})) {
		$metadata->{owner}->[0] = $self->user();
	}
	#Checking that the model file exists
	if (!-e $self->config("model import directory")->[0].$model."-reactions.tbl") {
		$self->error_message("FIGMODEL:import_modelfile:".$model." reactions file not found:".$self->config("model import directory")->[0].$model."-reactions.tbl");
		return $self->fail();
	}

	#Generating directory for model if it does not already exist
	my $modelobj = $self->get_model($model);
	if (!defined($modelobj)) {
		#Adding model to database
		$metadata->{id}->[0] = $model;
		$modelobj = $self->database()->add_model_to_db($model,$metadata,1);
		if (!-d $modelobj->directory()) {
			system("mkdir ".$modelobj->directory());
		}
	} elsif (!defined($metadata->{overwrite}->[0]) || $metadata->{overwrite}->[0] != 1) {
		$self->error_message("FIGMODEL:import_modelfile:".$model." already exists and overwrite request was not provided. Import halted.");
		return $self->fail();
	}
	#Storing report on model load in a separate FIGMODELTable
	my $report = ModelSEED::FIGMODEL::FIGMODELTable->new(["TYPE","ID","ARGONNE ID","EQUATION","DIRECTION COMP","EXTRA NAMES","MATCHING NAMES","MISSING NAMES","FORMULA COMP","CHARGE COMP","COMPARISON","NEW"],$modelobj->directory()."ImportReport-".$model.".txt",[],";","|",undef);

	#Keeping track of all new entities
	my $newEntityList;

	#Loading compounds file
	my $Tanslation;
	if (-e $self->config("model import directory")->[0].$model."-compounds.tbl") {
		#Getting compound database table
		my $CompoundTable = $self->database()->GetDBTable("COMPOUNDS");
		my $table = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("model import directory")->[0].$model."-compounds.tbl",";","|",0,["DATABASE"]);
		#Adding compounds to database
		for (my $i=0; $i < $table->size();$i++) {
			my $row = $table->get_row($i);
			if (defined($row->{"NAME"})) {
				#Creating search names
				for (my $j=0; $j < @{$row->{"NAME"}}; $j++) {
					if (length($row->{"NAME"}->[$j]) > 0) {
						$row->{"NAME"}->[$j] =~ s/;/-/g;
						push(@{$row->{"SEARCHNAME"}},$self->convert_to_search_name($row->{"NAME"}->[$j]));
					}
				}
				#Finding if existing compound shares search name
				my $existing;
				for (my $j=0; $j < @{$row->{"SEARCHNAME"}}; $j++) {
					$existing = $CompoundTable->get_row_by_key($row->{"SEARCHNAME"}->[$j],"SEARCHNAME");
					if (defined($existing)) {
						last;
					}
				}
				#If a matching compound was found, we handle this scenario
				if (defined($existing)) {
					my ($ExtraNames,$MissingNames,$MatchingNames) = CompareArrays($row->{"SEARCHNAME"},$existing->{"SEARCHNAME"});
					my $ChargeComp = "UNKNOWN";
					if (defined($row->{"CHARGE"}->[0])) {
						if (defined($existing->{"CHARGE"}->[0])) {
							if ($row->{"CHARGE"}->[0] eq $existing->{"CHARGE"}->[0]) {
								$ChargeComp = "SAME:".$row->{"CHARGE"}->[0];
							} else {
								$ChargeComp = "CONFLICT-A:".$existing->{"CHARGE"}->[0]."/M:".$row->{"CHARGE"}->[0];
							}
						} else {
							$ChargeComp = "A:UNKNOWN/M:".$row->{"CHARGE"}->[0];
						}
					} elsif (defined($existing->{"CHARGE"}->[0])) {
						if (!defined($row->{"CHARGE"}->[0])) {
							$ChargeComp = "A:".$existing->{"CHARGE"}->[0]."/M:UNKNOWN";
						}
					}
					my $Comparison = "UNKNOWN";
					if (defined($row->{"FORMULA"}->[0])) {
						if (defined($existing->{"FORMULA"}->[0])) {
							if ($row->{"FORMULA"}->[0] eq $existing->{"FORMULA"}->[0]) {
								$Comparison = "SAME:".$row->{"FORMULA"}->[0];
							} else {
								$Comparison = "CONFLICT-A:".$existing->{"FORMULA"}->[0]."/M:".$row->{"FORMULA"}->[0];
							}
						} else {
							$Comparison = "A:UNKNOWN/M:".$row->{"FORMULA"}->[0];
						}
					} elsif (defined($existing->{"FORMULA"}->[0])) {
						if (!defined($row->{"FORMULA"}->[0])) {
							$Comparison = "A:".$existing->{"FORMULA"}->[0]."/M:UNKNOWN";
						}
					}
					$Tanslation->{$row->{"DATABASE"}->[0]} = $existing->{"DATABASE"}->[0];
					$report->add_row({"TYPE" => ["COMPOUND"],"ID" => [$row->{"DATABASE"}->[0]],"ARGONNE ID" => [$existing->{"DATABASE"}->[0]],"EXTRA NAMES" => $ExtraNames,"MATCHING NAMES" => $MatchingNames,"MISSING NAMES" => $MissingNames,"FORMULA COMP" => [$Comparison],"CHARGE COMP" => [$ChargeComp],"NEW" => [0]});
				} else {
					#We make a new compound object
					my $NewID = $self->get_new_cpd_id();
					push(@{$newEntityList},$NewID);
					my $NewData = ModelSEED::FIGMODEL::FIGMODELObject->new(["DATABASE","NAME","FORMULA","CHARGE"],$self->config("compound directory")->[0].$NewID,"\t");
					foreach my $Key (keys(%{$row})) {
						$NewData->{$Key} = $row->{$Key};
					}
					$Tanslation->{$row->{"DATABASE"}->[0]} = $NewID;
					$report->add_row({"TYPE" => ["COMPOUND"],"ID" => [$NewData->{"DATABASE"}->[0]],"ARGONNE ID" => [$NewID],"NEW" => [1],"EXTRA NAMES" => $row->{"SEARCHNAME"}});
					$NewData->{"DATABASE"}->[0] = $NewID;
					$NewData->save();
					$CompoundTable->add_row({DATABASE => [$NewID],NAME => $row->{"NAME"},FORMULA => $row->{"FORMULA"},CHARGE => $row->{"CHARGE"},STRINGCODE => $row->{"STRINGCODE"},SEARCHNAME => $row->{"SEARCHNAME"}});
				}
				if (-e $self->config("Model molfile directory")->[0].$row->{"DATABASE"}->[0].".mol") {
					system("cp -f ".$self->config("Model molfile directory")->[0].$row->{"DATABASE"}->[0].".mol ".$self->config("Argonne molfile directory")->[0].$Tanslation->{$row->{"DATABASE"}->[0]}.".mol");
				}
			}
		}
		$CompoundTable->save();
	} else {
		print "FIGMODEL:import_modelfile:".$model." compounds file not found. Reactions must be in terms of cpd***** IDs.\n";
	}
	#Printing the translation file
	$self->database()->save_cpd_translation($Tanslation,$model);
	#Loading reactions file
	my $table = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("model import directory")->[0].$model."-reactions.tbl",";","|",0,["DATABASE"]);
	#Adding reactions to database
	my $ModelTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["LOAD","DIRECTIONALITY","COMPARTMENT","ASSOCIATED PEG","REFERENCE"],$modelobj->filename(),["LOAD"],";","|","REACTIONS\n");
	my $ReactionTranslation;
	my $ReactionTable = $self->database()->GetDBTable("REACTIONS");
	for (my $i=0; $i < $table->size();$i++) {
		my $row = $table->get_row($i);
		my $Reference = "NONE";
		if (defined($row->{"REFERENCE"})) {
			$Reference = $row->{"REFERENCE"}->[0];
		}
		#Setting the compartment according to the input file
		my $Compartment = "c";
		if (defined($row->{"COMPARTMENT"}->[0])) {
			$Compartment = $row->{"COMPARTMENT"}->[0];
			if (length($Compartment) == 3) {
				$Compartment = substr($Compartment,1,1);
			}
		}
		#Checking if there is an equation match
		if (defined($row->{"EQUATION"})) {
			(my $Direction,my $Equation,my $ReverseEquation,my $FullEquation,my $NewCompartment,my $Error) = $self->ConvertEquationToCode($row->{"EQUATION"}->[0],$Tanslation);
			#Checking if this is a biomass reaction
			my $biomass = 0;
			if ($row->{"DATABASE"}->[0] =~ m/biomass/) {
				#Ensuring that biomass has been added as a product of the biomass reaction
				$biomass = 1;
				if ($FullEquation !~ m/cpd11416/) {
					$FullEquation .= " + cpd11416";
					($Direction,$Equation,$ReverseEquation,$FullEquation,$NewCompartment,$Error) = $self->ConvertEquationToCode($FullEquation);
				}
			}
			#Updating the compartment if every species in the input reaction was in a particular compartment (other than "c")
			if (defined($NewCompartment) && $NewCompartment ne "c") {
				$Compartment = $NewCompartment;
			}
			#If the reaction involves a compound not found in the compound database, then something is wrong and this reaction should not be in the reaction database
			if ($Error == 1) {
				print STDERR "FIGMODEL:import_modelfile:".$model.": Error mapping reaction ".$row->{"DATABASE"}->[0].":".$FullEquation.".\n";
				$report->add_row({"TYPE" => ["REACTION"],"ID" => [$row->{"DATABASE"}->[0]],"EQUATION" => [$FullEquation],"ARGONNE ID" => ["ERROR"],"NEW" => [0]});
			} else {
				#Checking if the reaction is involved in a forced mapping and if so, the equation is replaced with the forced mapping equation:
				($Equation,$ReverseEquation,$FullEquation) = $self->ApplyStoichiometryCorrections($Equation,$ReverseEquation,$FullEquation);
				#Checking if the reaction is already in the database
				my $existing = $ReactionTable->get_row_by_key($Equation,"CODE");
				if (!defined($existing)) {
					$existing = $ReactionTable->get_row_by_key($ReverseEquation,"CODE");
					if ($Direction eq "=>") {
						$Direction = "<=";
					} elsif ($Direction eq "<=") {
						$Direction = "=>";
					}
				}
				my $NewData;
				#Handling nonbiomass reactions
				if ($biomass == 0) {
					#Handling the scenario where this is an existing reaction
					if (defined($existing)) {
						$NewData = $existing;
						my $DirComp = "IDENTICAL";
						if (defined($existing->{"REVERSIBILITY"}->[0]) && $existing->{"REVERSIBILITY"}->[0] ne $Direction) {
							my $DirComp = "CONFLICT:".$existing->{"REVERSIBILITY"}->[0]." vs ".$Direction;
						}
						$ReactionTranslation->{$row->{"DATABASE"}->[0]} = $existing->{"DATABASE"}->[0];
						$report->add_row({"TYPE" => ["REACTION"],"ID" => [$row->{"DATABASE"}->[0]],"ARGONNE ID" => [$existing->{"DATABASE"}->[0]],"EQUATION" => [$Equation],"DIRECTION COMP" => [$DirComp],"NEW" => [0]});
					} else {
						#We make a new reaction object
						my $NewID = $self->get_new_rxn_id();
						push(@{$newEntityList},$NewID);
						$report->add_row({"TYPE" => ["REACTION"],"ID" => [$row->{"DATABASE"}->[0]],"EQUATION" => [$Equation],"ARGONNE ID" => [$NewID],"NEW" => [1]});
						$NewData = ModelSEED::FIGMODEL::FIGMODELObject->new(["DATABASE","NAME","EQUATION","ENZYME","PATHWAY"],$self->{"reaction directory"}->[0].$NewID,"\t");
						foreach my $Key (keys(%{$row})) {
							$NewData->{$Key} = $row->{$Key};
						}
						$NewData->{"DATABASE"}->[0] = $NewID;
						$NewData->{"EQUATION"}->[0] = $FullEquation;
						$NewData->{"CODE"}->[0] = $Equation;
						$NewData->save();
						$ReactionTable->add_row({DATABASE => [$NewID],NAME => $row->{NAME},EQUATION => [$FullEquation],CODE => [$Equation],ENZYME => $row->{ENZYME},PATHWAY => $row->{PATHWAY},REVERSIBILITY => [$Direction]});
						$ReactionTranslation->{$row->{"DATABASE"}->[0]} = $NewID;
					}
				} else {
					#If this is a biomass reaction, we add it to the biomass reaction table
					$NewData = $self->add_biomass_reaction($FullEquation,$model,$metadata->{"source"}->[0]);
					$self->add_model_to_biomass_reaction($NewData->{DATABASE}->[0],$model);
					$NewData = $ReactionTable->get_row_by_key($NewData->{DATABASE}->[0],"DATABASE");
				}
				#Checking if reaction is already in the model reaction table
				if (defined($NewData->{"DATABASE"}) && defined($NewData->{"DATABASE"}->[0]) && $NewData->{"DATABASE"}->[0] =~ m/[rb][xi][no]\d\d\d\d\d/) {
					my $Row = $ModelTable->get_row_by_key($NewData->{"DATABASE"}->[0],"LOAD");
					if (!defined($Row)) {
						$Row = {"LOAD" => [$NewData->{"DATABASE"}->[0]],"DIRECTIONALITY" => [$Direction],"COMPARTMENT" => [$Compartment],"REFERENCE" => [$Reference]};
						$ModelTable->add_row($Row);
					} else {
						my $stop = 0;
						for (my $i=0; $i < @{$Row->{"COMPARTMENT"}};$i++) {
							if ($Row->{"COMPARTMENT"}->[$i] eq $Compartment) {
								if ($Row->{"DIRECTIONALITY"}->[$i] ne $Direction && $Row->{"DIRECTIONALITY"}->[$i] ne "<=>") {
									$Row->{"DIRECTIONALITY"}->[$i] = "<=>";
									print $NewData->{"DATABASE"}->[0]." DIR\n";
								}
								$stop = 1;
							}
						}
						if ($stop == 0) {
							$Row = $ModelTable->add_row({"LOAD" => [$NewData->{"DATABASE"}->[0]],"DIRECTIONALITY" => [$Direction],"COMPARTMENT" => [$Compartment],"REFERENCE" => [$Reference]});
							print $NewData->{"DATABASE"}->[0]."\n";
						} elsif ($Reference ne "NONE") {
							push(@{$Row->{"REFERENCE"}},$Reference);
						}
					}
					if (defined($row->{"GENE"}) && length($row->{"GENE"}->[0]) > 0) {
						if (defined($Row->{"ASSOCIATED PEG"}->[0]) && ($Row->{"ASSOCIATED PEG"}->[0] eq "UNKNOWN" || $Row->{"ASSOCIATED PEG"}->[0] eq "SPONTANEOUS")) {
							shift(@{$Row->{"ASSOCIATED PEG"}});
						}
						#my $TranslatedGenes = $self->TranslateGenes($row->{"GENE"}->[0],$metadata->{genome}->[0]);
						my $TranslatedGenes = $row->{"GENE"}->[0];
						if ($NewData->{"DATABASE"}->[0] =~ m/rxn\d\d\d\d\d/) {
							#$self->CaptureRoleRxnMapping($TranslatedGenes,$NewData->{"DATABASE"}->[0],$ReactionData->{"MODEL"}->[0]);
						}
						push(@{$Row->{"ASSOCIATED PEG"}},split(/[,\|]/,$TranslatedGenes));
					} else {
						if (!defined($Row->{"ASSOCIATED PEG"})) {
							$Row->{"ASSOCIATED PEG"}->[0] = "UNKNOWN";
						}
					}
				}
			}
		}
	}

	if (defined($newEntityList) && @{$newEntityList} > 0) {
		#Processing the new entities
		$self->database()->ProcessDatabaseWithMFAToolkit($newEntityList);
	}
	#Printing the reaction translation file
	$self->database()->save_rxn_translation($ReactionTranslation,$model);
	$ReactionTable->save();
	$ModelTable->save();
	#Printing the import report
	$report->save();
	#Updating the reaction and compound source files
	$self->database()->build_link_file("COMPOUND","SOURCE");
	$self->database()->build_link_file("REACTION","SOURCE");
	$self->get_model($model)->update_model_stats();
	
	return $self->success();
}

=head3 GetTransportReactionsForCompoundIDList
Definition:
	my $TransportDataHash = $model->GetTransportReactions($CompoundIDListRef);
Description:
	This function accepts as an argument a reference to an array of compound IDs, and it returns a reference to a hash of hashes.
	The first key in the hash of hashes is the compound ID, and the second key is the reaction ID of a transporter for the compound.
	Note that often a single compound ID will have multiple transport reactions in the database.
	The equation for the transport reactions are stored in the hash of hashes like so:
Example:
	my $model = FIGMODEL->new();
	$CompoundIDListRef = ["cpd00001","cpd00002"];
	my $TransportDataHash = $model->GetTransportReactions($CompoundIDListRef);
	my @TransportReactionIDList = keys(%{$TransportDataHash->{$CompoundIDListRef->[$i]}}));
	my $TransportReactionEquation = $TransportDataHash->{$CompoundIDListRef->[$i]}->{$TransportReactionIDList[$j]}->{"EQUATION"};
=cut
sub GetTransportReactionsForCompoundIDList {
	my($self,$CompoundIDListRef) = @_;

	#Loading the reaction lookup database file
	my $ReactionDatabase = &LoadMultipleLabeledColumnFile($self->{"Reaction database filename"}->[0],";","\\|");

	#Searching through the reaction list for the compound transporters
	my $TransportDataHash;
	for (my $i=0; $i < @{$ReactionDatabase}; $i++) {
		if (defined($ReactionDatabase->[$i]->{"EQUATION"})) {
			#Checking to see if this reaction is a transporter
			if ($ReactionDatabase->[$i]->{"EQUATION"}->[0] =~ m/\[e\]/) {
				#Now checking to see if it is a transporter for any of my query compounds
				for (my $j=0; $j < @{$CompoundIDListRef}; $j++) {
					my $Compound = $CompoundIDListRef->[$j];
					if ($ReactionDatabase->[$i]->{"EQUATION"}->[0] =~ m/$Compound\[e\]/) {
					$TransportDataHash->{$CompoundIDListRef->[$j]}->{$ReactionDatabase->[$i]->{"DATABASE"}->[0]} = $ReactionDatabase->[$i];
					}
				}
			}
		}
	}

	return $TransportDataHash;
}

=head3 compounds_of_media
Definition:
	$CompoundList = $model->compounds_of_media($Media);
Description:
Example:
=cut

sub compounds_of_media {
	my ($self,$Media) = @_;

	my $MediaList = $self->database()->GetDBTable("MEDIA");
	my $MediaRow = $MediaList->get_row_by_key($Media);
	if (defined($MediaRow)) {
		return $MediaRow->{"COMPOUNDS"};
	}

	return undef;
}

=head3 name_of_keggmap

Definition:
	$Name = $model->name_of_keggmap($Map);

Description:

Example:

=cut

sub name_of_keggmap {
	my ($self,$Map) = @_;

	if (!defined($self->{"kegg map names"})) {
	($self->{"kegg map names"}->{"num hash"},$self->{"kegg map names"}->{"name hash"}) = &LoadSeparateTranslationFiles($self->{"kegg map name file"}->[0],"\t");
	}

	if ($Map =~ m/(\d+$)/) {
	$Map = $1;
	}

	return $self->{"kegg map names"}->{"num hash"}->{$Map};
}

=head3 get_predicted_essentials
Definition:
	$ReactionList = $model->get_predicted_essentials($Model);
Description:
=cut

sub get_predicted_essentials {
	my ($self,$Model,$Media) = @_;

	#Setting media to "Complete" if the media is undefined
	if (!defined($Media)) {
		$Media = "Complete";
	}

	#Checking if the essential gene file exists
	my $modelObj = $self->get_model($Model);
	if (defined($modelObj) && -e $modelObj->directory()."EssentialGenes-".$Model."-".$Media.".tbl") {
		return $self->database()->load_single_column_file($modelObj->directory()."EssentialGenes-".$Model."-".$Media.".tbl","");
	}

	return undef;
}

=head3 jobid_of_genome
Definition:
	int::genome type = $model->jobid_of_genome(string::genome ID);
Description:
	Returns the source for the input genome ID: 0 for SEED, 1 for RAST, 2 for test RAST.
=cut

sub jobid_of_genome {
	my ($self,$GenomeID) = @_;
	my $job = $self->get_genome($GenomeID)->job();
	if (defined($job)) {
		return $job->id();
	}
	return undef;
}

=head3 status_of_model
Definition:
	int::model status = FIGMODEL->status_of_model(string::model ID);
	string::model status message = FIGMODEL->status_of_model(string::genome ID,1);
Description:
	Returns the current status of the SEED model associated with the input genome ID.
	model status = 1: model exists
	model status = 0: model is being built
	model status = -1: model does not exist
	model status = -2: model build failed
=cut

sub status_of_model {
	my ($self,$ModelID,$GetMessage) = @_;

	if ($ModelID =~ m/^\d+\.\d+$/) {
		$ModelID = "Seed".$ModelID;
	}
	my $model = $self->get_model($ModelID);
	#Returning the message if requested
	if (defined($GetMessage) && $GetMessage == 1) {
		if (!defined($model)) {
			return "NONE";
		}
		return $model->message();
	}

	#Checking if the model data was returned
	if (!defined($model)) {
		return -1;
	}
	return $model->status();
}

=head3 subsystems_of_reaction
Definition:
	$Subsystems = $model->subsystems_of_reaction($Reaction);
Description:
Example:
=cut

sub subsystems_of_reaction {
	my ($self,$Reaction) = @_;

	#Loading the functional role mapping if needed
	my $FunctionTable = $self->database()->GetDBTable("CURATED ROLE MAPPINGS");
	if (!defined($FunctionTable)) {
		return undef;
	}

	#Getting rows from function table for reaction
	my $ReactionTable = $FunctionTable->get_table_by_key($Reaction,"REACTION");
	if ($ReactionTable->size() == 0) {
		return undef;
	}

	#Getting subsytems from table
	my $SubsystemHash;
	my $FunctionHash;
	for (my $i=0; $i < $ReactionTable->size(); $i++) {
		#if (defined($ReactionTable->get_row($i)->{"SUBSYSTEM"}->[0]) && $ReactionTable->get_row($i)->{"SUBSYSTEM"}->[0] ne "NONE") {
		#	for (my $j=0; $j < @{$ReactionTable->get_row($i)->{"SUBSYSTEM"}}; $j++) {
		#		$SubsystemHash->{$ReactionTable->get_row($i)->{"SUBSYSTEM"}->[$j]} = 1;
		#	}
		#}
		if (defined($ReactionTable->get_row($i)->{"ROLE"}->[0])) {
			$FunctionHash->{$ReactionTable->get_row($i)->{"ROLE"}->[0]} = 1;
		}
	}
	my @Functions = keys(%{$FunctionHash});
	for (my $i=0; $i < @Functions; $i++) {
		my $Subsystems = $self->subsystems_of_role($Functions[$i]);
		if (defined($Subsystems)) {
			for (my $j=0; $j < @{$Subsystems}; $j++) {
				if (length($Subsystems->[$j]) > 0) {
					$SubsystemHash->{$Subsystems->[$j]} = 1;
				}
			}
		}
	}

	if (keys(%{$SubsystemHash}) == 0) {
		return undef;
	}

	my $SubsystemList;
	push(@{$SubsystemList},keys(%{$SubsystemHash}));
	return $SubsystemList;
}

=head3 reactions_of_subsystem
Definition:
	$Scenarios = $model->reactions_of_subsystem($Subsystem,$Model);
=cut

sub reactions_of_subsystem {
	my ($self,$Subsystem) = @_;

	#Loading the functional role mapping if needed
	$self->LoadFunctionalRoleMapping();

	#Checking if the reaction is in the mapping
	if (defined($self->{"FUNCTIONAL ROLE MAPPING"}->{"SUBSYSTEM HASH"}->{$Subsystem})) {
	my %ReactionHash;
	foreach my $Mapping (@{$self->{"FUNCTIONAL ROLE MAPPING"}->{"SUBSYSTEM HASH"}->{$Subsystem}}) {
		if (defined($Mapping->{"REACTION"}) && $Mapping->{"REACTION"}->[0] =~ m/rxn\d\d\d\d\d/) {
		$ReactionHash{$Mapping->{"REACTION"}->[0]} = 1;
		}
	}
	my $Reactions;
	push(@{$Reactions},keys(%ReactionHash));
	return $Reactions;
	} else {
	return undef;
	}

	return undef;
}

=head3 reactions_of_map

Definition:
	$Reactions = $model->reactions_of_subsystem($Map);

Description:

Example:

=cut

sub reactions_of_map {
	my ($self,$Map) = @_;

	#Loading the scenario data file if it needs to be loaded
	$self->LoadReactionDatabaseFile();

	my $ReactionList;
	if (defined($self->{"DATABASE"}->{"MAPS"}->{$Map})) {
	$ReactionList = $self->{"DATABASE"}->{"MAPS"}->{$Map};
	} else {
	$ReactionList = undef;
	}

	return $ReactionList;
}

=head3 scenarios_of_reaction

Definition:
	$Scenarios = $model->scenarios_of_reaction($Reaction);

Description:

Example:

=cut

sub scenarios_of_reaction {
	my ($self,$Reaction) = @_;

	#Loading the scenario data file if it needs to be loaded
	if (!defined($self->{"scenario data"})) {
	$self->LoadScenarios();
	}

	my $ScenarioList;
	if (defined($self->{"scenario data"}->{"reaction hash"}->{$Reaction})) {
	$ScenarioList = $self->{"scenario data"}->{"reaction hash"}->{$Reaction};
	} else {
	$ScenarioList = undef;
	}

	return $ScenarioList;
}

=head3 reactions_of_scenario

Definition:
	$Reactions = $model->reactions_of_scenario($Scenario);

Description:

Example:

=cut

sub reactions_of_scenario {
	my ($self,$Scenario,$Model) = @_;

	#Loading the scenario data file if it needs to be loaded
	if (!defined($self->{"scenario data"})) {
		$self->LoadScenarios();
	}

	my $Reactions;
	if (defined($self->{"scenario data"}->{"scenario hash"}->{$Scenario})) {
		$Reactions = $self->{"scenario data"}->{"scenario hash"}->{$Scenario};
	} else {
		$Reactions = undef;
	}

	if (!defined($Model) || length($Model) == 0 || $Model eq "NONE") {
		return $Reactions;
	}

	my $FinalReactionList;
	foreach my $Reaction (@{$Reactions}) {
		if (defined($self->GetDBModel($Model)->get_row_by_key($Reaction,"LOAD"))) {
			push(@{$FinalReactionList},$Reaction);
		}
	}

	return $FinalReactionList;
}

=head3 reversibility_of_reaction
Definition:
	$Reversibility = $model->reversibility_of_reaction($ReactionID);
Description:
	This function takes into account a number of criteria to determine the reversibility of a reaction.
	It is the definative function to use to determine reaction reversibility.
=cut
sub reversibility_of_reaction {
	my ($self,$Reaction) = @_;

	if ($Reaction =~ m/^bio/ || defined($self->{"forward only reactions"}->{$Reaction})) {
		return "=>";
	} elsif (defined($self->{"reverse only reactions"}->{$Reaction})) {
		return "<=";
	}

	my $Reversibility = "<=>";

	#Checking if this is a manually corrected reaction
	if (!defined($self->{"reversibility corrections"}->{$Reaction})) {
		#Getting the reaction table
		my $ReactionTable = $self->database()->GetDBTable("REACTIONS");
		if (defined($ReactionTable)) {
			#Getting reaction data
			my $ReactionRow = $ReactionTable->get_row_by_key($Reaction,"DATABASE");
			if (defined($ReactionRow) && defined($ReactionRow->{"REVERSIBILITY"}->[0])) {
				$Reversibility = $ReactionRow->{"REVERSIBILITY"}->[0];
			}
		}
	}

	return $Reversibility;
}

=head3 colocalized_genes
Definition:
	(1/0) = FIGMODEL->colocalized_genes(string:gene one,string:gene two,string:genome ID);
Description:
	This function assesses whether or not the specified genes are near one another on the specified genome
=cut
sub colocalized_genes {
	my ($self,$geneOne,$geneTwo,$genomeID) = @_;

	my $features = $self->database()->get_genome_feature_table($genomeID);
	my $rowOne = $features->get_row_by_key("fig|".$genomeID.".".$geneOne,"ID");
	my $rowTwo = $features->get_row_by_key("fig|".$genomeID.".".$geneTwo,"ID");	
	my $difference = $rowOne->{"MIN LOCATION"}->[0] - $rowTwo->{"MIN LOCATION"}->[0];
	if ($difference < 0) {
		$difference = -$difference;
	}
	if ($difference < 20000) {
		return 1;
	}
	return 0;
}

=head3 role_is_valid
Definition:
	$RoleValidity = $model->role_is_valid($Role);
=cut

sub role_is_valid {
	my ($self,$Role) = @_;

	if ($Role =~ m/hypothetical\sprotein/i || $Role =~ m/unknown/i || $Role eq "Bacteriophage" || $Role eq "putative" || $Role eq "Doubtful CDS") {
		return 0;
	}
	return 1;
}

=head3 OptimizeAnnotation
Definition:
	$model->OptimizeAnnotation($ModelName);
Description:
Example:
=cut

sub OptimizeAnnotation {
	my ($self,$ModelList) = @_;

	#All results will be stored in this hash like so: ->{Essential role set}->{Non essential roles}->{Reactions}->{Organism}->{Essential genes}/{Nonessential genes}/{Current complexes}/{Recommendation};
	my $CombinedResultsHash;

	#Experimental essential roles
	my $RoleTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["Role","Genes","Reactions","Organisms"],$self->{"database message file directory"}->[0]."ExperimentalEssentialRoles.txt",["Role","Genes"],"\t","|",undef);

	#Cycling through the list of model IDs
	for (my $i=0; $i < @{$ModelList}; $i++) {
		my $ModelName = $ModelList->[$i];
		#Loading the model table
		my $ModelTable = $self->database()->GetDBModel($ModelName);
		if (defined($ModelTable)) {
			#Getting model data
			my $ModelRow = $self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID");
			my $ModelDirectory = $self->{"database root directory"}->[0].$ModelRow->{"DIRECTORY"}->[0];
			my $OrganismID = $ModelRow->{"ORGANISM ID"}->[0];

			#Getting essential gene list
			my $ExperimentalEssentialGenes = $self->GetEssentialityData($OrganismID);
			if (defined($ExperimentalEssentialGenes)) {
				#Getting the feature table
				my $FeatureTable = $self->GetGenomeFeatureTable($OrganismID);
				$FeatureTable->save();
				#Putting essential genes in a hash and populating the essential gene role table
				my %EssentialGeneHash;
				my %NonessentialGeneHash;
				for (my $i=0; $i < $ExperimentalEssentialGenes->size(); $i++) {
					my $Row = $ExperimentalEssentialGenes->get_row($i);
					if (defined($Row->{"Gene"}->[0]) && defined($Row->{"Essentiality"}->[0]) && $Row->{"Essentiality"}->[0] eq "essential") {
						my $FeatureRow = $FeatureTable->get_row_by_key("fig|".$OrganismID.".".$Row->{"Gene"}->[0],"ID");
						if (defined($FeatureRow->{"ROLES"})) {
							foreach my $Role (@{$FeatureRow->{"ROLES"}}) {
								my $RoleRow = $RoleTable->get_row_by_key($Role,"Role");
								if (defined($RoleRow)) {
									$RoleTable->add_data($RoleRow,["Organisms"],$OrganismID,1);
									$RoleTable->add_data($RoleRow,["Genes"],"fig|".$OrganismID.".".$Row->{"Gene"}->[0],1);
								} else {
									$RoleTable->add_row({"Role" => [$Role],"Genes" => ["fig|".$OrganismID.".".$Row->{"Gene"}->[0]],"Organisms" => [$OrganismID]});
								}
							}
						}
						$EssentialGeneHash{$Row->{"Gene"}->[0]} = 1;
					} elsif (defined($Row->{"Gene"}->[0]) && defined($Row->{"Essentiality"}->[0]) && $Row->{"Essentiality"}->[0] eq "nonessential") {
						$NonessentialGeneHash{$Row->{"Gene"}->[0]} = 1;
					}
				}

				#Classifying reactions
				#my $ClassTable = $self->ClassifyModelReactions($ModelName,"Complete");

				#Scanning through reactions looking for essential and nonessential genes mapped to the same reaction
				my %ReactionComplexHash;
				for (my $i=0; $i < $ModelTable->size(); $i++) {
					my $ModelRow = $ModelTable->get_row($i);
					if (defined($ModelRow->{"ASSOCIATED PEG"}->[0])) {
						#Checking if an essential peg is mapped to this reaction
						my $ReactionEssentialGeneHash;
						my $ReactionNonEssentialGeneHash;
						my $ReactionUnknownGeneHash;
						my $ComplexArray;
						my $MarkedComplexes;
						my $NewGeneLists;
						my $NewComplexes;
						my $InvolvesEssentials = 0;
						for (my $j=0; $j < @{$ModelRow->{"ASSOCIATED PEG"}}; $j++) {
							my $Class = "";
							my @Pegs = split(/\+/,$ModelRow->{"ASSOCIATED PEG"}->[$j]);
							push(@{$NewGeneLists->[$j]},@Pegs);
							my @MarkedPegs;
							for (my $k=0; $k < @Pegs; $k++) {
								if (defined($EssentialGeneHash{$Pegs[$k]}) && !defined($ReactionEssentialGeneHash->{$Pegs[$k]})) {
									$InvolvesEssentials = 1;
									$ReactionEssentialGeneHash->{$Pegs[$k]}->[$j] = 1;
									my $RoleRow = $RoleTable->get_row_by_key("fig|".$OrganismID.".".$Pegs[$k],"Genes");
									if (defined($RoleRow)) {
										$RoleTable->add_data($RoleRow,"Reactions",$ModelRow->{"LOAD"}->[0].$Class,1);
									}
									$MarkedPegs[$k] = $Pegs[$k]."(E)";
								} elsif (defined($NonessentialGeneHash{$Pegs[$k]})) {
									if (!defined($ReactionNonEssentialGeneHash->{$Pegs[$k]})) {
										$ReactionNonEssentialGeneHash->{$Pegs[$k]} = 0;
									}
									$ReactionNonEssentialGeneHash->{$Pegs[$k]}++;
									$MarkedPegs[$k] = $Pegs[$k]."(N)";
								} else {
									if (!defined($ReactionUnknownGeneHash->{$Pegs[$k]})) {
										$ReactionUnknownGeneHash->{$Pegs[$k]} = 0;
									}
									$ReactionUnknownGeneHash->{$Pegs[$k]}++;
									$MarkedPegs[$k] = $Pegs[$k]."(U)";
								}
							}
							push(@{$ComplexArray},join("+",sort(@Pegs)));
							push(@{$MarkedComplexes},join("+",sort(@MarkedPegs)));
						}
						my @EssentialsList = keys(%{$ReactionEssentialGeneHash});
						my @NonessentialsList = keys(%{$ReactionNonEssentialGeneHash});
						my $Change = 0;
						if ($InvolvesEssentials == 1) {
							for (my $j=0; $j < @{$NewGeneLists}; $j++) {
								for (my $m=0; $m < @EssentialsList; $m++) {
									my $Match = 0;
									for (my $k=0; $k < @{$NewGeneLists->[$j]}; $k++) {
										if ($EssentialsList[$m] eq $NewGeneLists->[$j]->[$k]) {
											$Match = 1;
											last;
										}
									}
									if ($Match != 1) {
										push(@{$NewGeneLists->[$j]},$EssentialsList[$m]);
										$Change = 1;
									}
								}
								for (my $m=0; $m < @NonessentialsList; $m++) {
									if ($ReactionNonEssentialGeneHash->{$NonessentialsList[$m]} == @{$ModelRow->{"ASSOCIATED PEG"}}) {
										for (my $k=0; $k < @{$NewGeneLists->[$j]}; $k++) {
											if ($NonessentialsList[$m] eq $NewGeneLists->[$j]->[$k]) {
												$Change = 1;
												splice(@{$NewGeneLists->[$j]},$k,1);
												$k--;
											}
										}
									}
								}
								push(@{$NewComplexes},join("+",sort(@{$NewGeneLists->[$j]})));
							}
							if ($Change == 1) {
								my $ComplexString = join(",",sort(@{$ComplexArray}));
								push(@{$ReactionComplexHash{$ComplexString}->{"REACTIONS"}},$ModelRow->{"LOAD"}->[0]);
								if (!defined($ReactionComplexHash{$ComplexString}->{"ESSENTIALS"})) {
									$ReactionComplexHash{$ComplexString}->{"ESSENTIALS"} = $ReactionEssentialGeneHash;
									$ReactionComplexHash{$ComplexString}->{"NONESSENTIALS"} = $ReactionNonEssentialGeneHash;
									$ReactionComplexHash{$ComplexString}->{"UNKNOWNS"} = $ReactionUnknownGeneHash;
									$ReactionComplexHash{$ComplexString}->{"COMPLEXES"} = $MarkedComplexes;
									$ReactionComplexHash{$ComplexString}->{"NEWCOMPLEXES"} = $NewComplexes;
								}
							}
						}
					}
				}

				#Populating output table for this model
				my @ComplexSets = keys(%ReactionComplexHash);
				foreach my $SingleComplex (@ComplexSets) {
					#Generating reaction set strings
					my @ReactionList = sort(@{$ReactionComplexHash{$SingleComplex}->{"REACTIONS"}});
					my $ReactionSet = join(",",@ReactionList);
					#for (my $i=0; $i < @ReactionList; $i++) {
					#	$ReactionList[$i] = $ReactionList[$i]."(".$ClassTable->get_row_by_key($ReactionList[$i],"REACTION")->{"CLASS"}->[0].")";
					#}
					my $ReactionClassString = join(",",@ReactionList);
					#Dealing with gene essentiality
					my $EssentialsArray;
					my $NonessentialsArray;
					my $UnknownArray;
					my @EssentialRoles;
					my %NonessentialRoles;
					my @EssentialList = keys(%{$ReactionComplexHash{$SingleComplex}->{"ESSENTIALS"}});
					my @NonessentialList = keys(%{$ReactionComplexHash{$SingleComplex}->{"NONESSENTIALS"}});
					my @UnknownList = keys(%{$ReactionComplexHash{$SingleComplex}->{"UNKNOWNS"}});
					foreach my $Gene (@EssentialList) {
						my $GeneRole = "";
						my $GeneRow = $FeatureTable->get_row_by_key("fig|".$OrganismID.".".$Gene,"ID");
						if (defined($GeneRow) && defined($GeneRow->{"ROLES"})) {
							$GeneRole = join("|",@{$GeneRow->{"ROLES"}});
						}
						push(@{$EssentialsArray},$Gene.":".$GeneRole);
						push(@EssentialRoles,$GeneRole);
					}
					foreach my $Gene (@NonessentialList) {
						my $GeneRole = "";
						my $GeneRow = $FeatureTable->get_row_by_key("fig|".$OrganismID.".".$Gene,"ID");
						if (defined($GeneRow) && defined($GeneRow->{"ROLES"})) {
							$GeneRole = join("|",@{$GeneRow->{"ROLES"}});
						}
						push(@{$NonessentialsArray},$Gene.":".$GeneRole);
						$NonessentialRoles{$GeneRole}=1;
					}
					foreach my $Gene (@UnknownList) {
						my $GeneRole = "";
						my $GeneRow = $FeatureTable->get_row_by_key("fig|".$OrganismID.".".$Gene,"ID");
						if (defined($GeneRow) && defined($GeneRow->{"ROLES"})) {
							$GeneRole = join("|",@{$GeneRow->{"ROLES"}});
						}
						push(@{$UnknownArray},$Gene.":".$GeneRole);
					}
					my $EssentialRoleString = join("+",sort(@EssentialRoles));
					my $NonessentialRoleString = join(",",sort(keys(%NonessentialRoles)));
					#Loading the data into the combined results hash
					$CombinedResultsHash->{$ReactionSet}->{$OrganismID}->{"ESSENTIALS"} = $EssentialsArray;
					$CombinedResultsHash->{$ReactionSet}->{$OrganismID}->{"NONESSENTIALS"} = $NonessentialsArray;
					$CombinedResultsHash->{$ReactionSet}->{$OrganismID}->{"UNKNOWNS"} = $UnknownArray;
					$CombinedResultsHash->{$ReactionSet}->{$OrganismID}->{"COMPLEX"} = $ReactionComplexHash{$SingleComplex}->{"COMPLEXES"};
					$CombinedResultsHash->{$ReactionSet}->{$OrganismID}->{"NEWCOMPLEX"} = $ReactionComplexHash{$SingleComplex}->{"NEWCOMPLEXES"};
					$CombinedResultsHash->{$ReactionSet}->{$OrganismID}->{"RXNCLASSES"}->[0] = $ReactionClassString;
				}
			} else {
				print STDERR "FIGMODEL:OptimizeAnnotation: No experimental essentiality data found for the specified model!\n";
			}
		} else {
			print STDERR "FIGMODEL:OptimizeAnnotation: Could not load model: ".$ModelName."\n";
		}
	}

	#Printing the results of the analysis
	my $Filename = $self->{"database message file directory"}->[0]."AnnotationOptimizationReport.txt";
	if (!open (OPTIMIZATIONOUTPUT, ">$Filename")) {
		return;
	}

	#All results will be stored in this hash like so: ->{Essential role set}->{Non essential roles}->{Reactions}->{Organism}->{Essential genes}/{Nonessential genes}/{Current complexes}/{Recommendation};
	print OPTIMIZATIONOUTPUT "NOTE;Essential roles;Nonessential roles;Reactions\n";
	my @ReactionKeys = keys(%{$CombinedResultsHash});
	foreach my $ReactionKey (@ReactionKeys) {
		print OPTIMIZATIONOUTPUT "NEW ESSENTIALS;".$ReactionKey."\n";
		my @Organisms = keys(%{$CombinedResultsHash->{$ReactionKey}});
		foreach my $OrganismItem (@Organisms) {
			print OPTIMIZATIONOUTPUT "ORGANISM:".$OrganismItem."\n";
			print OPTIMIZATIONOUTPUT "REACTIONS CLASSIFIED:".$CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"RXNCLASSES"}->[0]."\n";
			print OPTIMIZATIONOUTPUT "ESSENTIALS;NONESSENTIALS;UNKNOWNS\n";
			my $Count = 0;
			while (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"ESSENTIALS"}->[$Count]) || defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"NONESSENTIALS"}->[$Count])) {
				if (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"ESSENTIALS"}->[$Count])) {
					print OPTIMIZATIONOUTPUT $CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"ESSENTIALS"}->[$Count];
				}
				print OPTIMIZATIONOUTPUT ";";
				if (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"NONESSENTIALS"}->[$Count])) {
					print OPTIMIZATIONOUTPUT $CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"NONESSENTIALS"}->[$Count];
				}
				print OPTIMIZATIONOUTPUT ";";
				if (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"UNKNOWNS"}->[$Count])) {
					print OPTIMIZATIONOUTPUT $CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"UNKNOWNS"}->[$Count];
				}
				print OPTIMIZATIONOUTPUT "\n";
				$Count++;
			}
			print OPTIMIZATIONOUTPUT "Current complex;Recommended complex\n";
			$Count = 0;
			while (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"COMPLEX"}->[$Count]) || defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"NEWCOMPLEX"}->[$Count])) {
				if (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"COMPLEX"}->[$Count])) {
					print OPTIMIZATIONOUTPUT $CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"COMPLEX"}->[$Count];
				}
				print OPTIMIZATIONOUTPUT ";";
				if (defined($CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"NEWCOMPLEX"}->[$Count])) {
					print OPTIMIZATIONOUTPUT $CombinedResultsHash->{$ReactionKey}->{$OrganismItem}->{"NEWCOMPLEX"}->[$Count];
				}
				print OPTIMIZATIONOUTPUT "\n";
				$Count++;
			}
		}
	}

	$RoleTable->save();
	close(OPTIMIZATIONOUTPUT);
}

=head3 AdjustAnnotation
Definition:
	$model->AdjustAnnotation($Filename);
Description:
	This function loads a table of annotation adjustments to a variety of models, implements the adjustments, then saves the model
Example:
=cut

sub AdjustAnnotation {
	my ($self,$Filename) = @_;

	#Loading the file of annotation adjustments
	my $AdjustmentTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Filename,";",",",0,["MODEL ID"]);

	#Going through the table rows and making adjustments
	my $ModelHash;
	for (my $i=0; $i < $AdjustmentTable->size(); $i++) {
		my $Row = $AdjustmentTable->get_row($i);
		if (defined($Row) && defined($Row->{"MODEL ID"}->[0])) {
			if (!defined($ModelHash->{$Row->{"MODEL ID"}->[0]})) {
				$ModelHash->{$Row->{"MODEL ID"}->[0]} = $self->database()->GetDBModel($Row->{"MODEL ID"}->[0]);
			}
			foreach my $Reaction (@{$Row->{"REACTIONS"}}) {
				my $ReactionRow = $ModelHash->{$Row->{"MODEL ID"}->[0]}->get_row_by_key($Reaction,"LOAD");
				if (defined($ReactionRow)) {
					$ReactionRow->{"ASSOCIATED PEG"} = $Row->{"NEW COMPLEXES"};
				}
			}
		}
	}

	#Saving the adjusted model files
	my @ModelList = keys(%{$ModelHash});
	foreach my $Model (@ModelList) {
		#Getting model data
		my $ModelRow = $self->database()->GetDBTable("MODEL LIST")->get_row_by_key($Model,"MODEL ID");
		my $ModelDirectory = $ModelRow->{"DIRECTORY"}->[0];
		my $OrganismID = $ModelRow->{"ORGANISM ID"}->[0];

		#Saving the optimized model
		$ModelHash->{$Model}->save($ModelDirectory."Opt".$OrganismID.".txt");
		#Adding the optimized model to the database
		$self->database()->add_model_to_db("Opt".$OrganismID,$OrganismID,$ModelDirectory);
		system("cp ".$ModelDirectory."Opt".$OrganismID.".txt ".$ModelDirectory."Opt".$OrganismID."VAnnoOpt.txt");
	}
}

=head3 AddBiologTransporters
Definition:
	$model->AddBiologTransporters($ModelName);
Description:
Example:
=cut

sub AddBiologTransporters {
	my ($self,$ModelName) = @_;

	#Checking that the model exists
	my $modelObj = $self->get_model($ModelName);
	if (!defined($modelObj)) {
		print STDERR "FIGMODEL:AddBiologTransporters: Model ".$ModelName." not found!\n";
	}
	my $ModelTable = $modelObj->reaction_table();
	if (!defined($ModelTable)) {
		print STDERR "FIGMODEL:AddBiologTransporters: Model ".$ModelName." not found!\n";
	}

	#Getting the genome id
	my $GenomeID = $modelObj->genome();
	#Getting biolog data
	my $MediaGrowthData = $self->GetCultureData($GenomeID);
	if (!defined($MediaGrowthData)) {
		return;
	}

	#Getting currently transported compounds
	my %ExtracellularCompoundList;
	for (my $i=0; $i < $ModelTable->size(); $i++) {
		my $ReactionData = $self->database()->GetDBTable("REACTIONS")->get_row_by_key($ModelTable->get_row($i)->{"LOAD"}->[0],"DATABASE");
		if (defined($ReactionData) && defined($ReactionData->{"EQUATION"}->[0])) {
			$_ = $ReactionData->{"EQUATION"}->[0];
			my @OriginalArray = /(cpd\d\d\d\d\d)\[e\]/g;
			for (my $i=0; $i < @OriginalArray; $i++) {
				$ExtracellularCompoundList{$OriginalArray[$i]} = 1;
			}
		}
	}

	#Getting the transporters for the biolog compounds
	my $BiologTransporterTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"Reaction database directory"}->[0]."masterfiles/BiologTransporters.txt",";","|",0,["COMPOUND","REACTION","MEDIA"]);
	for (my $i=0; $i < $MediaGrowthData->size(); $i++) {
		if ($MediaGrowthData->get_row($i)->{"Growth rate"}->[0] > 0) {
			my $Row = $BiologTransporterTable->get_row_by_key($MediaGrowthData->get_row($i)->{"Media"}->[0],"MEDIA");
			if (defined($Row) && !defined($ExtracellularCompoundList{$Row->{"COMPOUND"}->[0]})) {
				if (!defined($ModelTable->get_row_by_key($Row->{"REACTION"}->[0],"LOAD"))) {
					$ModelTable->add_row({"LOAD" => [$Row->{"REACTION"}->[0]],"DIRECTIONALITY" => ["<=>"],"COMPARTMENT" => ["c"],"ASSOCIATED PEG" => ["BIOLOG GAP FILLING"],"CONFIDENCE" => [4],"REFERENCE" => [$MediaGrowthData->get_row($i)->{"Source"}->[0]],"NOTES" => ["Added to transport biolog compound ".$Row->{"COMPOUND"}->[0]]});
				}
			}
		}
	}

	#Saving the table with the transporters added to file
	$ModelTable->save();
}

=head3 createNewModel
Definition:
	FIGMODEL->createNewModel({-genome => string:genomeID,-owner => string:owner,-gapfilling => 0/1,-user => string:username,-password => string:password});
Description:
=cut
sub createNewModel {
	my ($self,$args) = @_;
	#Processing arguments to handle user authentification and check for madatory arguments
	$args = $self->process_arguments($args,[],{-runPreliminaryReconstruction => 1,-id => undef,-genome => undef,-gapfilling => 0, -media => "Complete", -owner => undef});
	if (defined($args->{-error})) {
		return {-error=>$self->error_message("createNewModel:".$args->{-error})};	
	}
	if (!defined($args->{-id}) && !defined($args->{-genome})) {
		return {-error=>$self->error_message("createNewModel:must provide either genome or id or both")};
	}
	#Setting the queue where the model will be constructed
	if (!defined($args->{-queue}) && $self->config("Database version")->[0] eq "DevModelDB") {
		$args->{-queue} = "development";
	} elsif (!defined($args->{-queue})) {
		$args->{-queue} = "short";
	}
	#Setting the new model owner
	if (!defined($args->{-owner})) {
		if (defined($self->user())) {
			$args->{-owner} = $self->user();
		} else {
			$args->{-owner} = "master";	
		}
	}
	#Setting the new model owner
    my $public = 1;
	my $noChangeID = 1;
	if (!defined($args->{-id})) {
		$noChangeID = 0;
		$args->{-id} = "Seed".$args->{-genome};
        if($args->{-owner} ne "master") {
            $public = 0;
            my $userobj = $self->database()->get_object("user",{login=>$args->{-owner}});
            if (!defined($userobj)) {
                return {-error => $self->error_message("createNewModel:user ".
                    $args->{-owner}." not found in database. Check username of owner.")};
            }
            $args->{-id} .= ".".$userobj->_id();
        }
	}
	#Setting the new model source, name, and autocomplete media based on genome ID
	my $type = "model";
	my $source = "Unknown";
	my $name = "Unknown";
	my $autocompleteMedia = $args->{-media};
	if (defined($args->{-genome}) && $autocompleteMedia eq 'Complete') {
		my $genomeObj = $self->get_genome($args->{-genome});
		$source = $genomeObj->source();
		$name = $genomeObj->name();
		my $tbl = $self->database()->get_table("MINIMALMEDIA");
		if (defined($tbl) && defined($tbl->get_row_by_key($args->{-genome},"Organism"))) {
			$autocompleteMedia = $tbl->get_row_by_key($args->{-genome},"Organism")->{"Minimal media"}->[0];
		}
	} else {
		$args->{-genome} = "Unknown";
	}
	#Setting new model ID and adding the user's ID if the user is not "master"
	my $id = $args->{-id};
	if ($args->{-owner} ne "master" && $noChangeID == 0) {
		$public = 0;
		my $userobj = $self->database()->get_object("user",{login=>$args->{-owner}});
		if (!defined($userobj)) {
			return {-error => $self->error_message("createNewModel:user ".$args->{-owner}." not found in database. Check username of owner.")};
		}
		$id .= ".".$userobj->_id();
	}
	#Checking to see if a model with the same ID doesnt already exist
	my $mdlobj = $self->database()->get_object("model",{id=>$args->{-id}});
	if (defined($mdlobj)) {
		return {id => $id, -error => $self->error_message("createNewModel:a model called ".$id." already exists.")}; 
	}
	#Adding model to the database
	$mdlobj = $self->database()->create_object($type,{  id => $args->{-id},
														owner => $args->{-owner},
														public => $public,
														genome => $args->{-genome},
														source => $source,
														modificationDate => time(),
														builtDate => time(),
														autocompleteDate => -1,
														status => -2,
														version => 0,
														autocompleteVersion => 0,
														message => "Model reconstruction queued",
														cellwalltype => "Unknown",
														autoCompleteMedia => $autocompleteMedia,
														biomassReaction => "NONE",
														growth => 0,
														name => $name});
	#Creating directory for model owner
	if (!(-d $self->config("organism directory")->[0].$args->{-owner}."/")) {
		system("mkdir ".$self->config("organism directory")->[0].$args->{-owner}."/");
	}
	#Creating directory for model
	my $model = ModelSEED::FIGMODEL::FIGMODELmodel->new($self,$args->{-id},undef,$mdlobj);
	$model->create_model_rights();
	if (!(-d $model->directory())) {
		system("mkdir ".$model->directory());
	}
	#Scheduling reconstruction of the model
	if ($args->{-runPreliminaryReconstruction} eq "1") {
		#Setting gapfilling of model
		my $RunGapFilling = "";
		if ($args->{-gapfilling} eq "1") {
			$RunGapFilling = "?1";
		}
		$self->add_job_to_queue({command => "preliminaryreconstruction?".
            $args->{-id}.$RunGapFilling,queue => $args->{-queue},user => $args->{-owner}});
	}
	return {id => $id};
}

=head3 ranked_list_of_genomes
Definition:
	ranked_list_of_genomes(string::genome ID)
Description:
=cut

sub ranked_list_of_genomes {
	my ($self,$GenomeID,$CompareRoles,$CompareModels) = @_;

	#Creating prototype table
	my $Output = ModelSEED::FIGMODEL::FIGMODELTable->new(["GENOME","MATCHING GENES","AVERAGE SCORE","EXTRA A GENES","EXTRA B GENES","MATCHING ROLES","EXTRA A ROLES","EXTRA B ROLES","MATCHING REACTIONS","EXTRA A REACTIONS","EXTRA B REACTIONS"],$self->{"database message file directory"}->[0]."RankedListSimilarGenomes-".$GenomeID.".tbl",["GENOME"],";","|",undef);

	#Getting genome features
	my $FeatureTable = $self->GetGenomeFeatureTable($GenomeID);

	#Comparing reaction content of genome
	if (defined($CompareModels) && $CompareModels == 1) {
		#Getting model table
		my $ModelData = $self->database()->GetDBModel("Seed".$GenomeID);
		if (defined($ModelData)) {
			#Scanning model list
			my $ModelList = $self->database()->GetDBTable("MODEL LIST");
			for (my $i=0; $i < $ModelList->size(); $i++) {
				my $Row = $ModelList->get_row($i);
				if ($Row->{"MODEL ID"}->[0] ne "Seed".$GenomeID && $Row->{"MODEL ID"}->[0] =~ m/Seed(\d+\.\d+)/) {
					my $OtherGenomeID = $1;
					my $NewRow = $Output->get_row_by_key($OtherGenomeID,"GENOME");
					if (!defined($NewRow)) {
						$NewRow = {"GENOME" => [$OtherGenomeID],"MATCHING GENES" => [0],"AVERAGE SCORE" => [0],"EXTRA A GENES" => [0],"EXTRA B GENES" => [0],"MATCHING ROLES" => [0],"EXTRA A ROLES" => [0],"EXTRA B ROLES" => [0],"MATCHING REACTIONS" => [0],"EXTRA A REACTIONS" => [0],"EXTRA B REACTIONS" => [0]};
						$Output->add_row($NewRow);
					}
					my $OtherModelData = $self->database()->GetDBModel("Seed".$OtherGenomeID);
					for (my $j=0; $j < $ModelData->size(); $j++) {
						if (defined($OtherModelData->get_row_by_key($ModelData->get_row($j)->{"LOAD"}->[0],"LOAD"))) {
							$NewRow->{"MATCHING REACTIONS"}->[0]++;
						}
					}
					$NewRow->{"EXTRA A REACTIONS"}->[0] = $ModelData->size() - $NewRow->{"MATCHING REACTIONS"}->[0];
					$NewRow->{"EXTRA B REACTIONS"}->[0] = $OtherModelData->size() - $NewRow->{"MATCHING REACTIONS"}->[0];
				}
			}
		}
		$Output->save();
	}

	#Getting sims for genes in genome
	my $fig = $self->fig($GenomeID);
	my $MaxMatch = 0;
	for (my $i=0; $i < $FeatureTable->size(); $i++) {
		my $Row = $FeatureTable->get_row($i);
		print $Row->{"ID"}->[0]."\n";
		my $SimilarGenomeHash;
		my @sim_results = $fig->sims( $Row->{"ID"}->[0], 10000, 0.00001, "fig");
		for (my $j=0; $j < @sim_results; $j++) {
			my $result_row = $sim_results[$j];
			if ($result_row->[1] =~ m/fig\|(\d+\.\d+)\./) {
				my $GenomeID = $1;
				my $Score = -1000;
				if ($result_row->[10] != 0) {
					$Score = log($result_row->[10]);
				}
				if (!defined($SimilarGenomeHash->{$GenomeID}) || $SimilarGenomeHash->{$GenomeID} > $Score) {
					$SimilarGenomeHash->{$GenomeID} = $Score;
				}
			}
		}

		#Adding similar genomes to output table
		my @GenomeList = keys(%{$SimilarGenomeHash});
		for (my $j=0; $j < @GenomeList; $j++) {
			my $GenomeID = $GenomeList[$j];
			my $NewRow = $Output->get_row_by_key($GenomeID,"GENOME");
			if (!defined($NewRow)) {
				$NewRow = {"GENOME" => [$GenomeID],"MATCHING GENES" => [0],"AVERAGE SCORE" => [0],"EXTRA A GENES" => [0],"EXTRA B GENES" => [0],"MATCHING ROLES" => [0],"EXTRA A ROLES" => [0],"EXTRA B ROLES" => [0],"MATCHING REACTIONS" => [0],"EXTRA A REACTIONS" => [0],"EXTRA B REACTIONS" => [0]};
				$Output->add_row($NewRow);
			}
			$NewRow->{"MATCHING GENES"}->[0]++;
			if ($NewRow->{"MATCHING GENES"}->[0] > $MaxMatch) {
				$MaxMatch = $NewRow->{"MATCHING GENES"}->[0];
			}
			$NewRow->{"AVERAGE SCORE"}->[0] += $SimilarGenomeHash->{$GenomeID};
		}
	}

	#Scanning through all genomes
	my @RoleArray = $FeatureTable->get_hash_column_keys("ROLES");
	my @GenomeList = $self->fig()->genomes( 1,0, "Bacteria" );
	print "Max match:".$MaxMatch."\n";
	for (my $i=0; $i < @GenomeList; $i++) {
		my $OtherGenomeID = $GenomeList[$i];
		my $NewRow = $Output->get_row_by_key($OtherGenomeID,"GENOME");
		if (!defined($NewRow) && defined($CompareRoles) && $CompareRoles == 1) {
			$NewRow = {"GENOME" => [$GenomeID],"MATCHING GENES" => [0],"AVERAGE SCORE" => [0],"EXTRA A GENES" => [0],"EXTRA B GENES" => [0],"MATCHING ROLES" => [0],"EXTRA A ROLES" => [0],"EXTRA B ROLES" => [0],"MATCHING REACTIONS" => [0],"EXTRA A REACTIONS" => [0],"EXTRA B REACTIONS" => [0]};
			$Output->add_row($NewRow);
		}
		#Getting genome annotation data
		if (defined($NewRow)) {
			if ((defined($CompareRoles) && $CompareRoles == 1) || $NewRow->{"MATCHING GENES"}->[0] >= (0.5*$MaxMatch)) {
				print $OtherGenomeID."\n";
				my $BFeatureTable = $self->GetGenomeFeatureTable($OtherGenomeID);
				if (defined($CompareRoles) && $CompareRoles == 1) {
					my @BRoleArray = $BFeatureTable->get_hash_column_keys("ROLES");
					#Finding matching roles
					for (my $j=0; $j < @RoleArray; $j++) {
						if (defined($BFeatureTable->get_row_by_key($RoleArray[$j],"ROLES"))) {
							$NewRow->{"MATCHING ROLES"}->[0]++;
						}
					}
					$NewRow->{"EXTRA A ROLES"}->[0] = @RoleArray - $NewRow->{"MATCHING ROLES"}->[0];
					$NewRow->{"EXTRA B ROLES"}->[0] = @BRoleArray - $NewRow->{"MATCHING ROLES"}->[0];
				}
				if ($NewRow->{"MATCHING GENES"}->[0] > 0) {
					$NewRow->{"AVERAGE SCORE"}->[0] = $NewRow->{"AVERAGE SCORE"}->[0]/$NewRow->{"MATCHING GENES"}->[0];
					$NewRow->{"EXTRA A GENES"}->[0] = $FeatureTable->size()-$NewRow->{"MATCHING GENES"}->[0];
					$NewRow->{"EXTRA B GENES"}->[0] = $BFeatureTable->size()-$NewRow->{"MATCHING GENES"}->[0];
				}
				delete $self->{"CACHE"}->{$NewRow->{"GENOME"}->[0]."-FEATURETABLE"};
			}
		}
	}
	$Output->save();

    return $Output;
}

=head3 compareManyModels
Definition:
	FIGMODEL->compareManyModels({ids => [string]:model IDs})
=cut
sub compareManyModels {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,["ids"],{});
	my $modelHash;
	for (my $i=0; $i < @{$args->{ids}}; $i++) {
		$modelHash->{$args->{ids}->[$i]} = $self->get_model($args->{ids}->[$i]);
		if (!defined($modelHash->{$args->{ids}->[$i]})) {
			$self->figmodel()->new_error_message({package => "FIGMODEL",message=> "Could not load ".$args->{ids}->[$i]." model.",function => "add_constraint",args=>$args});	
		}
	}
	
	
}

=head3 CompareModels
Definition:
	$model->CompareModels($ModelFilenameOne,$ModelFilenameTwo);
Description:
	This function loads the models stored in $ModelFilenameOne and $ModelFilenameTwo. The function then compares the reactions, genes, annotations, and complexes in both models.
	The results of this comparison are returned in the hashes:
	$model->{"COMPARISON"}->{"EXTRA REACTIONS"}->{$ModelOne}->{$ReactionIDs}
	$model->{"COMPARISON"}->{"EXTRA REACTIONS"}->{$ModelTwo}->{$ReactionIDs}
	$model->{"COMPARISON"}->{"COMMON REACTIONS"}->{$ReactionIDs}
	$model->{"COMPARISON"}->{"EXTRA GENES"}->{$ModelOne}->{$ReactionIDs}
	$model->{"COMPARISON"}->{"EXTRA GENES"}->{$ModelTwo}->{$ReactionIDs}
	$model->{"COMPARISON"}->{"COMMON GENES"}->{$ReactionIDs}
	$model->{"COMPARISON"}->{"EXTRA ANNOTATIONS"}->{$ModelOne}
	$model->{"COMPARISON"}->{"EXTRA ANNOTATIONS"}->{$ModelTwo}
	$model->{"COMPARISON"}->{"COMMON ANNOTATIONS"}->{$ModelOne}
	$model->{"COMPARISON"}->{"EXTRA COMPLEXES"}->{$ModelOne}
	$model->{"COMPARISON"}->{"EXTRA COMPLEXES"}->{$ModelTwo}
	$model->{"COMPARISON"}->{"COMMON COMPLEXES"}->{$ModelOne}
	$model->{"COMPARISON"}->{"EXTRA OPEN PROBLEMS"}->{$ModelOne}
	$model->{"COMPARISON"}->{"EXTRA OPEN PROBLEMS"}->{$ModelTwo}
	$model->{"COMPARISON"}->{"COMMON OPEN PROBLEMS"}->{$ModelOne}
Example:
	my $model = FIGMODEL->new();
	$model->CompareModels("Seed100226.1","Seed100755.1");

=cut

sub CompareModels {
	my ($self,$ModelOne,$ModelTwo) = @_;

	#Getting gene tables
	my $model = $self->get_model($ModelOne);
	if (!defined($model)) {
		print STDERR "FIGMODEL:CompareModels:Could not find ".$ModelOne." in database.\n";
		return undef;
	}
	my $ModelOneGenome = $model->genome();
	my $ModelOneFeatures = $self->GetGenomeFeatureTable($model->genome());
	$model = $self->get_model($ModelTwo);
	if (!defined($model)) {
		print STDERR "FIGMODEL:CompareModels:Could not find ".$ModelTwo." in database.\n";
		return undef;
	}
	my $ModelTwoGenome = $model->genome();
	my $ModelTwoFeatures = $self->GetGenomeFeatureTable($model->genome());

	#Creating global comparison tables
	if (!defined($self->{"Global A exclusive roles"})) {
		$self->{"Global A exclusive roles"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["ROLE","SUBYSTEM","REACTIONS","PEGS","MODELS","NUM MODELS"],$self->{"database message file directory"}->[0]."ExclusiveARoles.txt",["ROLE"],"\t","|",undef);
		$self->{"Global A exclusive reactions"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["REACTION","PEGS","MODELS","NUM MODELS"],$self->{"database message file directory"}->[0]."ExclusiveAReactions.txt",["REACTION"],"\t","|",undef);
		$self->{"Global A reversible"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["REACTION","MODEL A","MODEL B","NUM MODELS"],$self->{"database message file directory"}->[0]."AReversible.txt",["REACTION"],"\t","|",undef);
		$self->{"Global B exclusive roles"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["ROLE","SUBYSTEM","REACTIONS","PEGS","MODELS","NUM MODELS"],$self->{"database message file directory"}->[0]."ExclusiveBRoles.txt",["ROLE"],"\t","|",undef);
		$self->{"Global B exclusive reactions"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["REACTION","PEGS","MODELS","NUM MODELS"],$self->{"database message file directory"}->[0]."ExclusiveBReactions.txt",["REACTION"],"\t","|",undef);
		$self->{"Global B reversible"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["REACTION","MODEL A","MODEL B","NUM MODELS"],$self->{"database message file directory"}->[0]."BReversible.txt",["REACTION"],"\t","|",undef);
		$self->{"Global directionality conflicts"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["REACTION","MODEL A","MODEL B","NUM MODELS"],$self->{"database message file directory"}->[0]."DirectionalityConflicts.txt",["REACTION"],"\t","|",undef);
	}

	#Proposed equivalent reaction pairs will be stored in this structure
	my $GeneReactionHash;

	#Fist loading the model data from file
	my $ModelTableOne = $self->database()->GetDBModel($ModelOne);
	my $ModelTableTwo = $self->database()->GetDBModel($ModelTwo);
	my $ReactionTable = $self->database()->GetDBTable("REACTIONS");

	#Loading the equivalent reaction hash
	my $EquivalentHash;
	my $RawData = LoadMultipleColumnFile($self->{"Reaction database directory"}->[0]."masterfiles/EquivalentReactions.txt",";");
	foreach my $Pair (@{$RawData}) {
		$EquivalentHash->{$Pair->[0]}->{$Pair->[1]} = 1;
		$EquivalentHash->{$Pair->[1]}->{$Pair->[0]} = 1;
	}
	#Now identifying equivalent transporters
	my $Transporters;
	for (my $i=0; $i < $ReactionTable->size(); $i++) {
		if (defined($ReactionTable->get_row($i)->{"EQUATION"}->[0]) && $ReactionTable->get_row($i)->{"EQUATION"}->[0] =~ m/cpd\d\d\d\d\d\[\w\]/) {
			$_ = $ReactionTable->get_row($i)->{"EQUATION"}->[0];
			my @OriginalArray = /(cpd\d\d\d\d\d)\[\w\]/g;
			foreach my $Compound (@OriginalArray) {
				if ($Compound ne "cpd00067" && 	$Compound ne "cpd00971") {
					push(@{$Transporters->{$Compound}},$ReactionTable->get_row($i)->{"DATABASE"}->[0]);
				}
			}
		}
	}
	#Adding all equivalent transporters to equivalent reaction hash: this enables the comparison of models with periplasm compartments
	my @CompoundList = keys(%{$Transporters});
	foreach my $Compound (@CompoundList) {
		foreach my $Reaction (@{$Transporters->{$Compound}}) {
			foreach my $ReactionTwo (@{$Transporters->{$Compound}}) {
				if ($Reaction ne $ReactionTwo) {
					$EquivalentHash->{$Reaction}->{$ReactionTwo} = 1;
					$EquivalentHash->{$ReactionTwo}->{$Reaction} = 1;
				}
			}
		}
	}

	my $ComparisonResults = { "SHARED REACTIONS" => [0], "EXTRA ".$ModelOne." REACTIONS" => [0], "EXTRA ".$ModelTwo." REACTIONS" => [0], "SHARED GENES" => [0], "EXTRA ".$ModelOne." GENES" => [0], "EXTRA ".$ModelTwo." GENES" => [0], "SHARED ANNOTATIONS" => [0], "EXTRA ".$ModelOne." ANNOTATIONS" => [0], "EXTRA ".$ModelTwo." ANNOTATIONS" => [0], "SHARED COMPLEXES" => [0], "EXTRA ".$ModelOne." COMPLEXES" => [0], "EXTRA ".$ModelTwo." COMPLEXES" => [0]};
	$ComparisonResults->{"SHARED OPEN PROBLEMS"}->[0] = 0;
	$ComparisonResults->{"SHARED GENE REACTIONS"}->[0] = 0;
	$ComparisonResults->{$ModelOne." EXTRA OPEN PROBLEMS"}->[0] = 0;
	$ComparisonResults->{$ModelTwo." EXTRA OPEN PROBLEMS"}->[0] = 0;
	$ComparisonResults->{$ModelOne." EXTRA GENE REACTIONS"}->[0] = 0;
	$ComparisonResults->{$ModelTwo." EXTRA GENE REACTIONS"}->[0] = 0;
	$ComparisonResults->{$ModelOne.":OP,".$ModelTwo.":GENE"}->[0] = 0;
	$ComparisonResults->{$ModelTwo.":OP,".$ModelOne.":GENE"}->[0] = 0;
	$ComparisonResults->{"SHARED REVERSIBLE"}->[0] = 0;
	$ComparisonResults->{"SHARED IRREVERSIBLE"}->[0] = 0;
	$ComparisonResults->{"DIRECTIONALITY CONFLICTS"}->[0] = 0;
	$ComparisonResults->{$ModelOne." REVERSIBLE"}->[0] = 0;
	$ComparisonResults->{$ModelTwo." REVERSIBLE"}->[0] = 0;
	$ComparisonResults->{"UNSHARED ".$ModelOne." ANNOTATIONS"}->[0] = 0;
	$ComparisonResults->{"UNSHARED ".$ModelTwo." ANNOTATIONS"}->[0] = 0;

	my $ModelOneEquivalents;
	my $ModelTwoEquivalents;
	my %NonsharedReactionAnnotationHashOne;
	my %NonsharedReactionAnnotationHashTwo;
	my %SharedReactionAnnotationHashOne;
	my %GeneHashOne;
	my %ComplexHashOne;
	#Processing the model one reactions
	for (my $i=0; $i < $ModelTableOne->size(); $i++) {
		my $Reaction = $ModelTableOne->get_row($i);
		$self->{"ForeignReactions"}->{$Reaction->{"LOAD"}->[0]} = 1;
		if (defined($Reaction->{"ASSOCIATED PEG"}) && $Reaction->{"ASSOCIATED PEG"}->[0] !~ m/^[0A-Z\s]+$/) {
			foreach my $GeneComplex (@{$Reaction->{"ASSOCIATED PEG"}}) {
				my @GeneArray = sort(split(/\+/,$GeneComplex));
				if (@GeneArray > 1) {
					$ComplexHashOne{join("+",@GeneArray)} = 1;
				}
				foreach my $Gene (@GeneArray) {
					$GeneReactionHash->{$Gene}->{$Reaction->{"LOAD"}->[0]} = 1;
					$GeneHashOne{$Gene}->{"TAG"} = 1;
					push(@{$GeneHashOne{$Gene}->{"REACTIONS"}},$Reaction->{"LOAD"}->[0]);
					if (defined($ModelTableTwo->{$Reaction->{"LOAD"}->[0]})) {
						$SharedReactionAnnotationHashOne{$Reaction->{"LOAD"}->[0]."->".$Gene} = 1;
					} else {
						$NonsharedReactionAnnotationHashOne{$Reaction->{"LOAD"}->[0]."->".$Gene} = 1;
					}
				}
			}
		}
		if (defined($ModelTableTwo->{$Reaction->{"LOAD"}->[0]})) {
			$ComparisonResults->{"SHARED REACTIONS"}->[0]++;
			push(@{$ComparisonResults->{"SHARED REACTIONS"}},$Reaction->{"LOAD"}->[0]);
			#Comparing gene associations
			if (defined($Reaction->{"ASSOCIATED PEG"}) && $Reaction->{"ASSOCIATED PEG"}->[0] !~ m/^[0A-Z\s]+$/) {
				if (!defined($ModelTableTwo->{$Reaction->{"LOAD"}->[0]}->[0]->{"ASSOCIATED PEG"}) || $ModelTableTwo->{$Reaction->{"LOAD"}->[0]}->[0]->{"ASSOCIATED PEG"}->[0] =~ m/^[0A-Z\s]+$/) {
					$ComparisonResults->{$ModelTwo.":OP,".$ModelOne.":GENE"}->[0]++;
					($ComparisonResults->{$ModelTwo.":OP,".$ModelOne.":GENE"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelTwo.":OP,".$ModelOne.":GENE"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{$ModelTwo.":OP,".$ModelOne.":GENE"}->[0] -= $NumMatches;
				} else {
					$ComparisonResults->{"SHARED GENE REACTIONS"}->[0]++;
					($ComparisonResults->{"SHARED GENE REACTIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED GENE REACTIONS"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{"SHARED GENE REACTIONS"}->[0] -= $NumMatches;
				}
			} else {
				if (defined($ModelTableTwo->{$Reaction->{"LOAD"}->[0]}->[0]->{"ASSOCIATED PEG"}) && $ModelTableTwo->{$Reaction->{"LOAD"}->[0]}->[0]->{"ASSOCIATED PEG"}->[0] !~ m/^[0A-Z\s]+$/) {
					$ComparisonResults->{$ModelOne.":OP,".$ModelTwo.":GENE"}->[0]++;
					($ComparisonResults->{$ModelOne.":OP,".$ModelTwo.":GENE"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelOne.":OP,".$ModelTwo.":GENE"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{$ModelOne.":OP,".$ModelTwo.":GENE"}->[0] -= $NumMatches;
				} else {
					$ComparisonResults->{"SHARED OPEN PROBLEMS"}->[0]++;
					($ComparisonResults->{"SHARED OPEN PROBLEMS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED OPEN PROBLEMS"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{"SHARED OPEN PROBLEMS"}->[0] -= $NumMatches;
				}
			}
			#Comparing directionality
			if ($Reaction->{"DIRECTIONALITY"}->[0] eq $ModelTableTwo->{$Reaction->{"LOAD"}->[0]}->[0]->{"DIRECTIONALITY"}->[0]) {
				if ($Reaction->{"DIRECTIONALITY"}->[0] eq "<=>") {
					$ComparisonResults->{"SHARED REVERSIBLE"}->[0]++;
					($ComparisonResults->{"SHARED REVERSIBLE"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED REVERSIBLE"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{"SHARED REVERSIBLE"}->[0] -= $NumMatches;
				} else {
					$ComparisonResults->{"SHARED IRREVERSIBLE"}->[0]++;
					($ComparisonResults->{"SHARED IRREVERSIBLE"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED IRREVERSIBLE"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{"SHARED IRREVERSIBLE"}->[0] -= $NumMatches;
				}
			} elsif ($Reaction->{"DIRECTIONALITY"}->[0] eq "<=>") {
				$ComparisonResults->{$ModelOne." REVERSIBLE"}->[0]++;
				($ComparisonResults->{$ModelOne." REVERSIBLE"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelOne." REVERSIBLE"},$Reaction->{"LOAD"}->[0]);
				$ComparisonResults->{$ModelOne." REVERSIBLE"}->[0] -= $NumMatches;
				my $Row = $self->{"Global A reversible"}->get_row_by_key($Reaction->{"LOAD"}->[0],"REACTION",1);
				$self->{"Global A reversible"}->add_data($Row,"MODEL A",$ModelOne,1);
				$self->{"Global A reversible"}->add_data($Row,"MODEL B",$ModelTwo,1);
				$Row->{"NUM MODELS"}->[0] = @{$Row->{"MODEL A"}};
			} elsif ($ModelTableTwo->{$Reaction->{"LOAD"}->[0]}->[0]->{"DIRECTIONALITY"}->[0] eq "<=>") {
				$ComparisonResults->{$ModelTwo." REVERSIBLE"}->[0]++;
				($ComparisonResults->{$ModelTwo." REVERSIBLE"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelTwo." REVERSIBLE"},$Reaction->{"LOAD"}->[0]);
				$ComparisonResults->{$ModelTwo." REVERSIBLE"}->[0] -= $NumMatches;
				my $Row = $self->{"Global B reversible"}->get_row_by_key($Reaction->{"LOAD"}->[0],"REACTION",1);
				$self->{"Global B reversible"}->add_data($Row,"MODEL A",$ModelOne,1);
				$self->{"Global B reversible"}->add_data($Row,"MODEL B",$ModelTwo,1);
				$Row->{"NUM MODELS"}->[0] = @{$Row->{"MODEL A"}};
			} else {
				$ComparisonResults->{"DIRECTIONALITY CONFLICTS"}->[0]++;
				($ComparisonResults->{"DIRECTIONALITY CONFLICTS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"DIRECTIONALITY CONFLICTS"},$Reaction->{"LOAD"}->[0]);
				$ComparisonResults->{"DIRECTIONALITY CONFLICTS"}->[0] -= $NumMatches;
				my $Row = $self->{"Global directionality conflicts"}->get_row_by_key($Reaction->{"LOAD"}->[0],"REACTION",1);
				$self->{"Global directionality conflicts"}->add_data($Row,"MODEL A",$ModelOne,1);
				$self->{"Global directionality conflicts"}->add_data($Row,"MODEL B",$ModelTwo,1);
				$Row->{"NUM MODELS"}->[0] = @{$Row->{"MODEL A"}};
			}
		} else {
			my $Equivalent = 0;
			if (defined($EquivalentHash->{$Reaction->{"LOAD"}->[0]})) {
				my @EquivlentList = keys(%{$EquivalentHash->{$Reaction->{"LOAD"}->[0]}});
				foreach my $Item (@EquivlentList) {
					if (defined($ModelTableTwo->get_row_by_key($Item,"LOAD"))) {
						$Equivalent = 1;
						$ModelOneEquivalents->{$Reaction->{"LOAD"}->[0]} = 1;
						$ModelTwoEquivalents->{$Item} = 1;
					}
				}
			}
			if ($Equivalent == 0) {
				$ComparisonResults->{"EXTRA ".$ModelOne." REACTIONS"}->[0]++;
				($ComparisonResults->{"EXTRA ".$ModelOne." REACTIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelOne." REACTIONS"},$Reaction->{"LOAD"}->[0]);
				$ComparisonResults->{"EXTRA ".$ModelOne." REACTIONS"}->[0] -= $NumMatches;
				my $Row = $self->{"Global A exclusive reactions"}->get_row_by_key($Reaction->{"LOAD"}->[0],"REACTION",1);
				if (!defined($Row->{"NUM MODELS"})) {
					$Row->{"NUM MODELS"}->[0] = 0;
				}
				$Row->{"NUM MODELS"}->[0]++;
				push(@{$Row->{"MODELS"}},$ModelOne);
				if (!defined($Reaction->{"ASSOCIATED PEG"}) || $Reaction->{"ASSOCIATED PEG"}->[0] =~ m/^[0A-Z\s]+$/) {
					push(@{$Row->{"pegs"}},"NONE");
					$ComparisonResults->{$ModelOne." EXTRA OPEN PROBLEMS"}->[0]++;
					($ComparisonResults->{$ModelOne." EXTRA OPEN PROBLEMS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelOne." EXTRA OPEN PROBLEMS"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{$ModelOne." EXTRA OPEN PROBLEMS"}->[0] -= $NumMatches;
				} else {
					push(@{$Row->{"pegs"}},join(",",@{$Reaction->{"ASSOCIATED PEG"}}));
					$ComparisonResults->{$ModelOne." EXTRA GENE REACTIONS"}->[0]++;
					($ComparisonResults->{$ModelOne." EXTRA GENE REACTIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelOne." EXTRA GENE REACTIONS"},$Reaction->{"LOAD"}->[0]);
					$ComparisonResults->{$ModelOne." EXTRA GENE REACTIONS"}->[0] -= $NumMatches;
				}
			}
		}
	}
	$ComparisonResults->{"EQUIVALENT ".$ModelOne." REACTIONS"}->[0] = keys(%{$ModelOneEquivalents});
	$ComparisonResults->{"EQUIVALENT ".$ModelTwo." REACTIONS"}->[0] = keys(%{$ModelTwoEquivalents});
	push(@{$ComparisonResults->{"EQUIVALENT ".$ModelOne." REACTIONS"}},keys(%{$ModelOneEquivalents}));
	push(@{$ComparisonResults->{"EQUIVALENT ".$ModelTwo." REACTIONS"}},keys(%{$ModelTwoEquivalents}));

	#Processing the model two reactions that are not in model one
	for (my $i=0; $i < $ModelTableTwo->size(); $i++) {
		my $Reaction = $ModelTableTwo->get_row($i);
		$self->{"ModelReactions"}->{$Reaction->{"LOAD"}->[0]} = 1;
		if (defined($Reaction->{"ASSOCIATED PEG"}) && $Reaction->{"ASSOCIATED PEG"}->[0] !~ m/^[0A-Z\s]+$/) {
			foreach my $GeneComplex (@{$Reaction->{"ASSOCIATED PEG"}}) {
				my @GeneArray = sort(split(/\+/,$GeneComplex));
				if (@GeneArray > 1) {
					if (defined($ComplexHashOne{join("+",@GeneArray)})) {
						$ComplexHashOne{join("+",@GeneArray)} = 2;
						$ComparisonResults->{"SHARED COMPLEXES"}->[0]++;
						($ComparisonResults->{"SHARED COMPLEXES"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED COMPLEXES"},join("+",@GeneArray));
						$ComparisonResults->{"SHARED COMPLEXES"}->[0] -= $NumMatches;
					} else {
						$ComparisonResults->{"EXTRA ".$ModelTwo." COMPLEXES"}->[0]++;
						($ComparisonResults->{"EXTRA ".$ModelTwo." COMPLEXES"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelTwo." COMPLEXES"},join("+",@GeneArray));
						$ComparisonResults->{"EXTRA ".$ModelTwo." COMPLEXES"}->[0] -= $NumMatches;
					}
				}
				foreach my $Gene (@GeneArray) {
					if (defined($GeneReactionHash->{$Gene})) {
						my @ReactionArray = keys(%{$GeneReactionHash->{$Gene}});
						my $Match = 0;
						foreach my $GeneReaction (@ReactionArray) {
							if ($GeneReaction eq $Reaction->{"LOAD"}->[0]) {
								$Match = 1;
								last;
							}
						}
						if ($Match == 0) {
							foreach my $GeneReaction (@ReactionArray) {
								if (!defined($self->{"EquivalentReactions"}->{$GeneReaction}->{$Reaction->{"LOAD"}->[0]})) {
									$self->{"EquivalentReactions"}->{$GeneReaction}->{$Reaction->{"LOAD"}->[0]}->{"Count"} = 0;
								}
								$self->{"EquivalentReactions"}->{$GeneReaction}->{$Reaction->{"LOAD"}->[0]}->{"Count"}++;
								$self->{"EquivalentReactions"}->{$GeneReaction}->{$Reaction->{"LOAD"}->[0]}->{"Source"} .= $ModelOne.":".$Gene."|";
							}
						}
					}
					if (defined($GeneHashOne{$Gene})) {
						$GeneHashOne{$Gene}->{"TAG"} = 2;
						$ComparisonResults->{"SHARED GENES"}->[0]++;
						($ComparisonResults->{"SHARED GENES"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED GENES"},$Gene);
						$ComparisonResults->{"SHARED GENES"}->[0] -= $NumMatches;
					} else {
						$ComparisonResults->{"EXTRA ".$ModelTwo." GENES"}->[0]++;
						($ComparisonResults->{"EXTRA ".$ModelTwo." GENES"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelTwo." GENES"},$Gene);
						$ComparisonResults->{"EXTRA ".$ModelTwo." GENES"}->[0] -= $NumMatches;
						#Getting the row corresponding to the peg in the feature table
						my $Row = $ModelTwoFeatures->get_row_by_key("fig|".$ModelTwoGenome.".".$Gene,"ID");
						if (defined($Row) && defined($Row->{"ROLES"})) {
							foreach my $Role (@{$Row->{"ROLES"}}) {
								my $RoleRow = $self->{"Global B exclusive roles"}->get_row_by_key($Role,"ROLE");
								if (!defined($RoleRow)) {
									$RoleRow = {"ROLE" => [$Role],"SUBYSTEM" => $self->subsystems_of_role($Role),"REACTIONS" => [$Reaction->{"LOAD"}->[0]],"PEGS" => [$Gene],"MODELS" => [$ModelTwo],"NUM MODELS" => [1]};
									$self->{"Global B exclusive roles"}->add_row($RoleRow);
								} else {
									$self->{"Global B exclusive roles"}->add_data($RoleRow,"REACTIONS",$Reaction->{"LOAD"}->[0],1);
									$self->{"Global B exclusive roles"}->add_data($RoleRow,"PEGS",$Gene,1);
									$self->{"Global B exclusive roles"}->add_data($RoleRow,"MODELS",$ModelTwo,1);
									$RoleRow->{"NUM MODELS"}->[0] = @{$RoleRow->{"MODELS"}};
								}
							}
						}
					}
					if (defined($ModelTableOne->{$Reaction->{"LOAD"}->[0]})) {
						if (defined($SharedReactionAnnotationHashOne{$Reaction->{"LOAD"}->[0]."->".$Gene})) {
							$SharedReactionAnnotationHashOne{$Reaction->{"LOAD"}->[0]."->".$Gene} = 2;
							$ComparisonResults->{"SHARED ANNOTATIONS"}->[0]++;
							($ComparisonResults->{"SHARED ANNOTATIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"SHARED ANNOTATIONS"},$Reaction->{"LOAD"}->[0]."->".$Gene);
							$ComparisonResults->{"SHARED ANNOTATIONS"}->[0] -= $NumMatches;
						} else {
							$ComparisonResults->{"EXTRA ".$ModelTwo." ANNOTATIONS"}->[0]++;
							($ComparisonResults->{"EXTRA ".$ModelTwo." ANNOTATIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelTwo." ANNOTATIONS"},$Reaction->{"LOAD"}->[0]."->".$Gene);
							$ComparisonResults->{"EXTRA ".$ModelTwo." ANNOTATIONS"}->[0] -= $NumMatches;
						}
					} else {
						$NonsharedReactionAnnotationHashTwo{$Reaction->{"LOAD"}->[0]."->".$Gene} = 1;
					}
				}
			}
		}
		if (!defined($ModelTableOne->{$Reaction->{"LOAD"}->[0]})) {
			$ComparisonResults->{"EXTRA ".$ModelTwo." REACTIONS"}->[0]++;
			($ComparisonResults->{"EXTRA ".$ModelTwo." REACTIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelTwo." REACTIONS"},$Reaction->{"LOAD"}->[0]);
			$ComparisonResults->{"EXTRA ".$ModelTwo." REACTIONS"}->[0] -= $NumMatches;
			my $Row = $self->{"Global B exclusive reactions"}->get_row_by_key($Reaction->{"LOAD"}->[0],"REACTION",1);
			if (!defined($Row->{"NUM MODELS"})) {
				$Row->{"NUM MODELS"}->[0] = 0;
			}
			$Row->{"NUM MODELS"}->[0]++;
			push(@{$Row->{"MODELS"}},$ModelTwo);
			if (!defined($Reaction->{"ASSOCIATED PEG"}) || $Reaction->{"ASSOCIATED PEG"}->[0] =~ m/^[0A-Z\s]+$/) {
				push(@{$Row->{"pegs"}},"NONE");
				$ComparisonResults->{$ModelTwo." EXTRA OPEN PROBLEMS"}->[0]++;
				($ComparisonResults->{$ModelTwo." EXTRA OPEN PROBLEMS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelTwo." EXTRA OPEN PROBLEMS"},$Reaction->{"LOAD"}->[0]);
				$ComparisonResults->{$ModelTwo." EXTRA OPEN PROBLEMS"}->[0] -= $NumMatches;
			} else {
				push(@{$Row->{"pegs"}},join(",",@{$Reaction->{"ASSOCIATED PEG"}}));
				$ComparisonResults->{$ModelTwo." EXTRA GENE REACTIONS"}->[0]++;
				($ComparisonResults->{$ModelTwo." EXTRA GENE REACTIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{$ModelTwo." EXTRA GENE REACTIONS"},$Reaction->{"LOAD"}->[0]);
				$ComparisonResults->{$ModelTwo." EXTRA GENE REACTIONS"}->[0] -= $NumMatches;
			}
		}
	}

	my @KeyArray = keys(%GeneHashOne);
	for (my $i=0; $i < @KeyArray; $i++) {
		if ($GeneHashOne{$KeyArray[$i]}->{"TAG"} == 1) {
			$ComparisonResults->{"EXTRA ".$ModelOne." GENES"}->[0]++;
			($ComparisonResults->{"EXTRA ".$ModelOne." GENES"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelOne." GENES"},$KeyArray[$i]);
			$ComparisonResults->{"EXTRA ".$ModelOne." GENES"}->[0] -= $NumMatches;
			#Getting the row corresponding to the peg in the feature table
			my $Row = $ModelOneFeatures->get_row_by_key("fig|".$ModelOneGenome.".".$KeyArray[$i],"ID");
			if (defined($Row) && defined($Row->{"ROLES"})) {
				foreach my $Role (@{$Row->{"ROLES"}}) {
					my $RoleRow = $self->{"Global A exclusive roles"}->get_row_by_key($Role,"ROLE");
					if (!defined($RoleRow)) {
						$RoleRow = {"ROLE" => [$Role],"SUBYSTEM" => $self->subsystems_of_role($Role),"REACTIONS" => $GeneHashOne{$KeyArray[$i]}->{"REACTIONS"},"PEGS" => [$KeyArray[$i]],"MODELS" => [$ModelOne],"NUM MODELS" => [1]};
						$self->{"Global A exclusive roles"}->add_row($RoleRow);
					} else {
						for (my $j=0; $j < @{$GeneHashOne{$KeyArray[$i]}->{"REACTIONS"}}; $j++) {
							$self->{"Global A exclusive roles"}->add_data($RoleRow,"REACTIONS",$GeneHashOne{$KeyArray[$i]}->{"REACTIONS"}->[$j],1);
						}
						$self->{"Global A exclusive roles"}->add_data($RoleRow,"PEGS",$KeyArray[$i],1);
						$self->{"Global A exclusive roles"}->add_data($RoleRow,"MODELS",$ModelOne,1);
						$RoleRow->{"NUM MODELS"}->[0] = @{$RoleRow->{"MODELS"}};
					}
				}
			}
		}
	}
	@KeyArray = keys(%ComplexHashOne);
	for (my $i=0; $i < @KeyArray; $i++) {
		if ($ComplexHashOne{$KeyArray[$i]} == 1) {
			$ComparisonResults->{"EXTRA ".$ModelOne." COMPLEXES"}->[0]++;
			($ComparisonResults->{"EXTRA ".$ModelOne." COMPLEXES"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelOne." COMPLEXES"},$KeyArray[$i]);
			$ComparisonResults->{"EXTRA ".$ModelOne." COMPLEXES"}->[0] -= $NumMatches;
		}
	}
	@KeyArray = keys(%SharedReactionAnnotationHashOne);
	for (my $i=0; $i < @KeyArray; $i++) {
		if ($SharedReactionAnnotationHashOne{$KeyArray[$i]} == 1) {
			$ComparisonResults->{"EXTRA ".$ModelOne." ANNOTATIONS"}->[0]++;
			($ComparisonResults->{"EXTRA ".$ModelOne." ANNOTATIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"EXTRA ".$ModelOne." ANNOTATIONS"},$KeyArray[$i]);
			$ComparisonResults->{"EXTRA ".$ModelOne." ANNOTATIONS"}->[0] -= $NumMatches;
		}
	}
	@KeyArray = keys(%NonsharedReactionAnnotationHashOne);
	for (my $i=0; $i < @KeyArray; $i++) {
		$ComparisonResults->{"UNSHARED ".$ModelOne." ANNOTATIONS"}->[0]++;
		($ComparisonResults->{"UNSHARED ".$ModelOne." ANNOTATIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"UNSHARED ".$ModelOne." ANNOTATIONS"},$KeyArray[$i]);
		$ComparisonResults->{"UNSHARED ".$ModelOne." ANNOTATIONS"}->[0] -= $NumMatches;
	}
	@KeyArray = keys(%NonsharedReactionAnnotationHashTwo);
	for (my $i=0; $i < @KeyArray; $i++) {
		$ComparisonResults->{"UNSHARED ".$ModelTwo." ANNOTATIONS"}->[0]++;
		($ComparisonResults->{"UNSHARED ".$ModelTwo." ANNOTATIONS"},my $NumMatches) = AddElementsUnique($ComparisonResults->{"UNSHARED ".$ModelTwo." ANNOTATIONS"},$KeyArray[$i]);
		$ComparisonResults->{"UNSHARED ".$ModelTwo." ANNOTATIONS"}->[0] -= $NumMatches;
	}

	return $ComparisonResults;
}

=head3 CompareModelGenes
Definition:
	FIGMODELTable:Gene comparison genes = FIGMODEL->CompareModelGenes(string:model one,string:model two)
Description:
=cut

sub CompareModelGenes {
	my ($self,$ModelOne,$ModelTwo) = @_;
	#Loading models
	my $One = $self->get_model($ModelOne);
	my $Two = $self->get_model($ModelTwo);
	#Checking that both models exist
	if (!defined($One)) {
		print STDERR "FIGMODEL->CompareModelGenes(".$ModelOne.",".$ModelTwo.") ".$ModelOne." not found!\n";
		return undef;
	}
	if (!defined($Two)) {
		print STDERR "FIGMODEL->CompareModelGenes(".$ModelOne.",".$ModelTwo.") ".$ModelTwo." not found!\n";
		return undef;
	}
	#Getting subsystem link table
	my $linktbl = $self->database()->GetLinkTable("SUBSYSTEM","ROLE");
	#Creating the output table
	my $tbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["EXTRA PEG","ROLE","SUBSYSTEM","CLASS 1","CLASS 2","REACTIONS","OTHER MODEL PEGS","REFERENCE MODEL"],$self->{"database message file directory"}->[0].$ModelOne."-".$ModelTwo."-GeneComparison.tbl",["PEG"],"\t","|",undef);
	#Getting gene tables
	my $GeneTblOne = $self->database()->GetDBModelGenes($ModelOne);
	my $GeneTblTwo = $self->database()->GetDBModelGenes($ModelTwo);
	my $RxnTblOne = $One->reaction_table();
	my $RxnTblTwo = $Two->reaction_table();
	for (my $m=0; $m < 2; $m++) {
		if ($m == 1) {
			my $temp = $GeneTblOne;
			$GeneTblOne = $GeneTblTwo;
			$GeneTblTwo = $temp;
			$temp = $RxnTblOne;
			$RxnTblOne = $RxnTblTwo;
			$RxnTblTwo = $temp;
			$temp = $ModelOne;
			$ModelOne = $ModelTwo;
			$ModelTwo = $temp;
		}
		for (my $i=0; $i < $GeneTblOne->size(); $i++) {
			my $row = $GeneTblOne->get_row($i);
			if (!defined($GeneTblTwo->get_row_by_key($row->{ID}->[0],"ID"))) {
				my $newrow = $tbl->add_row({"EXTRA PEG"=>[$row->{ID}->[0]],"ROLE"=>$row->{ROLES},"REACTIONS"=>$row->{$ModelOne},"REFERENCE MODEL"=>[$ModelOne]});
				if (defined($newrow->{"ROLE"})) {
					for (my $j=0; $j < @{$newrow->{"ROLE"}}; $j++) {
						my @subsysrows = $linktbl->get_rows_by_key($newrow->{"ROLE"}->[$j],"ROLE");
						my $subsys;
						my $classOne;
						my $classTwo;
						for (my $k=0; $k < @subsysrows; $k++) {
							my $classes = $self->class_of_subsystem($subsysrows[$k]->{SUBSYSTEM}->[0]);
							if (defined($classes)) {
								if (length($subsys) > 0) {
									$subsys .= ",";
									$classOne .= ",";
									$classTwo .= ",";
								}
								$subsys .= $subsysrows[$k]->{SUBSYSTEM}->[0];
								$classOne .= $classes->[0];
								$classTwo .= $classes->[1];
							}
						}
						push(@{$newrow->{"SUBSYSTEM"}},$subsys);
						push(@{$newrow->{"CLASS 1"}},$classOne);
						push(@{$newrow->{"CLASS 2"}},$classTwo);
					}
				}
				if (defined($newrow->{"REACTIONS"})) {
					for (my $j=0; $j < @{$newrow->{"REACTIONS"}}; $j++) {
						my $rxnrow = $RxnTblTwo->get_row_by_key($newrow->{"REACTIONS"}->[$j],"LOAD");
						if (!defined($rxnrow)) {
							push(@{$newrow->{"OTHER MODEL PEGS"}},"NA");
						} else {
							push(@{$newrow->{"OTHER MODEL PEGS"}},join(",",@{$rxnrow->{"ASSOCIATED PEG"}}));
						}
					}
				}
			}
		}
	}
	$tbl->save();
	return $tbl;
}

=head3 CompareModelReactions
Definition:
	$model->CompareModelReactions($ModelOne,$ModelTwo);
Description:
Example:
	$model->CompareModelReactions("Seed100226.1","Seed100755.1");
=cut

sub CompareModelReactions {
	my ($self,$ModelOne,$ModelTwo) = @_;

	#Fist loading the model data from file
	my $ModelTableOne = $self->database()->GetDBModel($ModelOne);
	my $ModelTableTwo = $self->database()->GetDBModel($ModelTwo);
	my $ReactionTable = $self->database()->GetDBTable("REACTIONS");

	#Loading the equivalent reaction hash
	my $EquivalentHash;
	my $RawData = LoadMultipleColumnFile($self->{"Reaction database directory"}->[0]."masterfiles/EquivalentReactions.txt",";");
	foreach my $Pair (@{$RawData}) {
		$EquivalentHash->{$Pair->[0]}->{$Pair->[1]} = 1;
		$EquivalentHash->{$Pair->[1]}->{$Pair->[0]} = 1;
	}
	#Now identifying equivalent transporters
	my $Transporters;
	for (my $i=0; $i < $ReactionTable->size(); $i++) {
		if (defined($ReactionTable->get_row($i)->{"EQUATION"}->[0]) && $ReactionTable->get_row($i)->{"EQUATION"}->[0] =~ m/cpd\d\d\d\d\d\[\w\]/) {
			$_ = $ReactionTable->get_row($i)->{"EQUATION"}->[0];
			my @OriginalArray = /(cpd\d\d\d\d\d)\[\w\]/g;
			foreach my $Compound (@OriginalArray) {
				if ($Compound ne "cpd00067" && 	$Compound ne "cpd00971") {
					push(@{$Transporters->{$Compound}},$ReactionTable->get_row($i)->{"DATABASE"}->[0]);
				}
			}
		}
	}
	#Adding all equivalent transporters to equivalent reaction hash: this enables the comparison of models with periplasm compartments
	my @CompoundList = keys(%{$Transporters});
	foreach my $Compound (@CompoundList) {
		foreach my $Reaction (@{$Transporters->{$Compound}}) {
			foreach my $ReactionTwo (@{$Transporters->{$Compound}}) {
				if ($Reaction ne $ReactionTwo) {
					$EquivalentHash->{$Reaction}->{$ReactionTwo} = 1;
					$EquivalentHash->{$ReactionTwo}->{$Reaction} = 1;
				}
			}
		}
	}

	#Identifying shared, equivalent, and exclusive reactions
	my $CommonReactions;
	my $EquivalentAReactions;
	my $EquivalentBReactions;
	my $ModelAReactions;
	my $ModelBReactions;

	#Processing the model one reactions
	for (my $i=0; $i < $ModelTableOne->size(); $i++) {
		my $Reaction = $ModelTableOne->get_row($i);
		if (defined($ModelTableTwo->{$Reaction->{"LOAD"}->[0]})) {
			$CommonReactions->{$Reaction->{"LOAD"}->[0]} = 1;
		} else {
			my $Equivalent = 0;
			if (defined($EquivalentHash->{$Reaction->{"LOAD"}->[0]})) {
				my @EquivlentList = keys(%{$EquivalentHash->{$Reaction->{"LOAD"}->[0]}});
				foreach my $Item (@EquivlentList) {
					if (defined($ModelTableTwo->get_row_by_key($Item,"LOAD"))) {
						$Equivalent = 1;
						$EquivalentAReactions->{$Reaction->{"LOAD"}->[0]} = 1;
						$EquivalentBReactions->{$Item} = 1;
					}
				}
			}
			if ($Equivalent == 0) {
				$EquivalentAReactions->{$Reaction->{"LOAD"}->[0]} = 1;
			}
		}
	}

	#Processing the model two reactions that are not in model one
	for (my $i=0; $i < $ModelTableTwo->size(); $i++) {
		my $Reaction = $ModelTableTwo->get_row($i);
		if (!defined($CommonReactions->{$Reaction->{"LOAD"}->[0]}) && !defined($EquivalentBReactions->{$Reaction->{"LOAD"}->[0]})) {
			$ModelBReactions->{$Reaction->{"LOAD"}->[0]} = 1;
		}
	}

	return ($CommonReactions,$EquivalentAReactions,$EquivalentBReactions,$ModelAReactions,$ModelBReactions);
}

=head3 GetIntervals

Definition:
	my $Intervals = $model->GetIntervals($Username);

Description:
	This function returns reference to an array of hashes containing data on all interals owns by the input user as well as all shared intervals.
	If not username is supplied, only shared intervals are returned.

Example:
	my $model = FIGMODEL->new();
	my $Intervals = $model->GetIntervals($Username);
	print "INTERVAL ID\tINTERVAL START\tINTERVAL END\tINTERVAL EXPERIMENTAL GROWTH\n";
	for (my $i=0; $i < @{$Intervals}; $i++) {
	print $Intervals->[$i]->{"ID"}->[0]."\t".$Intervals->[$i]->{"START"}->[0]."\t".$Intervals->[$i]->{"END"}->[0];
	for (my $j=0; $j < @{$Intervals->[$i]->{"GROWTH DATA"}}; $j++) {
		print "\t".$Intervals->[$i]->{"GROWTH DATA"}->[j]->{"MEDIA"}.": ".$Intervals->[$i]->{"GROWTH DATA"}->[j]->{"EXPERIMENT"}.": ".$Intervals->[$i]->{"GROWTH DATA"}->[j]->{"INSILICO"};
	}
	}


=cut

sub GetIntervals {
	my ($self,$Username) = @_;

	my $Intervals;
	LoadIntervals("SHARED");
	if (defined($self->{"INTERVALS"}->{"SHARED"})) {
	push(@{$Intervals},@{$self->{"INTERVALS"}->{"SHARED"}});
	}

	LoadIntervals($Username);
	if (defined($self->{"INTERVALS"}->{$Username})) {
	push(@{$Intervals},@{$self->{"INTERVALS"}->{$Username}});
	}

	if (defined($Intervals) && @{$Intervals} > 0) {
	return $Intervals;
	}
	return undef;
}

=head3 LoadIntervals

Definition:
	$model->LoadIntervals($Username);

Description:
	This function loads interval data from file.

Example:

=cut

sub LoadIntervals {
	my ($self,$Username) = @_;

	#Checking that the input username is valid
	if (!defined($Username) || !(-e $self->{"interval directory"}->[0].$Username."Intervals.txt") || defined($self->{"INTERVALS"}->{$Username})) {
	return;
	}

	$self->{"INTERVALS"}->{$Username} = &LoadMultipleLabeledColumnFile($self->{"interval directory"}->[0].$Username."Intervals.txt","\t",";");
	for (my $i=0; $i < @{$self->{"INTERVALS"}->{$Username}}; $i++) {
	for (my $j=0; $j < @{$self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH"}}; $j++) {
		my @TempArray = split(/:/,$self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH"}->[$j]);
		$self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"MEDIA"} = $TempArray[0];
		if (defined($TempArray[1])) {
		$self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"EXPERIMENT"} = $TempArray[1];
		}
		if (defined($TempArray[2])) {
		$self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"INSILICO"} = $TempArray[2];
		}
	}
	}

	return undef;
}

=head3 SaveIntervals

Definition:
	$model->SaveIntervals($Username);

Description:
	Saves the interval data to file.

Example:

=cut

sub SaveIntervals {
	my ($self,$Username) = @_;

	#Checking that the input username is valid
	if (!defined($Username) || !defined($self->{"INTERVALS"}->{$Username})) {
	return;
	}

	my $Filename = $self->{"interval directory"}->[0].$Username."Intervals.txt";
	if (open(INTERVALOUTPUT, ">$Filename")) {
	print INTERVALOUTPUT "ID\tSTART\tEND\tGROWTH\n";
	for (my $i=0; $i < @{$self->{"INTERVALS"}->{$Username}}; $i++) {
		my $GrowthData;
		for (my $j=0; $j < @{$self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}}; $j++) {
		my $SingleDataPoint;
		if (defined($self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"MEDIA"})) {
			$SingleDataPoint = $self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"MEDIA"}.":";
			if (defined($self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"EXPERIMENT"})) {
			$SingleDataPoint .= $self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"EXPERIMENT"};
			}
			$SingleDataPoint .= ":";
			if (defined($self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"INSILICO"})) {
			$SingleDataPoint .= $self->{"INTERVALS"}->{$Username}->[$i]->{"GROWTH DATA"}->[$j]->{"INSILICO"}
			}
		}
		if (length($SingleDataPoint) > 0) {
			if (length($GrowthData) > 0) {
			$GrowthData .= ";";
			}
			$GrowthData .= $SingleDataPoint;
		}
		}
		print INTERVALOUTPUT $self->{"INTERVALS"}->{$Username}->[$i]->{"ID"}->[0]."\t".$self->{"INTERVALS"}->{$Username}->[$i]->{"START"}->[0]."\t".$self->{"INTERVALS"}->{$Username}->[$i]->{"END"}->[0]."\t".$GrowthData."\n";
	}
	close(INTERVALOUTPUT);
	}
}

=head3 TranslateGenes
Definition:
	$model->TranslateGenes($Original,$GenomeID);
Description:
Example:
=cut

sub TranslateGenes {
	my ($self,$Original,$GenomeID) = @_;

	if (!defined($self->{$GenomeID."_aliases"})) {
	if (defined($self->fig())) {
		#Getting fig object
		my $fig = $self->fig();

		#Getting genome data
		my $GenomeData = $fig->all_features_detailed_fast($GenomeID);
		for (my $j=0; $j < @{$GenomeData}; $j++) {
		#id, location, aliases, type, minloc, maxloc, assigned_function, made_by, quality
		if (defined($GenomeData->[$j]->[0]) && defined($GenomeData->[$j]->[2]) && defined($GenomeData->[$j]->[3]) && $GenomeData->[$j]->[3] eq "peg" && $GenomeData->[$j]->[0] =~ m/(peg\.\d+)/) {
			my $GeneID = $1;
			my @TempArray = split(/,/,$GenomeData->[$j]->[2]);
			for (my $i=0; $i < @TempArray; $i++) {
			$self->{$GenomeID."_aliases"}->{$TempArray[$i]} = $GeneID;
			}
		}
		}
	}

	#Loading additional gene aliases from the database
	if (-e $self->{"Translation directory"}->[0]."AdditionalAliases/".$GenomeID.".txt") {
		my $AdditionalAliases = LoadMultipleColumnFile($self->{"Translation directory"}->[0]."AdditionalAliases/".$GenomeID.".txt","\t");
		for (my $i=0; $i < @{$AdditionalAliases}; $i++) {
		$self->{$GenomeID."_aliases"}->{$AdditionalAliases->[$i]->[1]} = $AdditionalAliases->[$i]->[0];
		}
	}
	}

	#Translating the input gene data
	$Original =~ s/\sand\s/:/g;
	$Original =~ s/\sor\s/;/g;
	my @GeneNames = split(/[,\+\s\(\):;]/,$Original);
	foreach my $Gene (@GeneNames) {
		if (length($Gene) > 0 && defined($self->{$GenomeID."_aliases"}->{$Gene})) {
			my $Replace = $self->{$GenomeID."_aliases"}->{$Gene};
			$Original =~ s/([^\w])$Gene([^\w])/$1$Replace$2/g;
			$Original =~ s/^$Gene([^\w])/$Replace$1/g;
			$Original =~ s/([^\w])$Gene$/$1$Replace/g;
			$Original =~ s/^$Gene$/$Replace/g;
		}
	}
	$Original =~ s/:/ and /g;
	$Original =~ s/;/ or /g;

	#my @TempArrayOne = split(/,/,$Original);
	#for (my $k=0; $k < @TempArrayOne; $k++) {
	#my @TempArrayTwo = split(/\+/,$TempArrayOne[$k]);
	#for (my $m=0; $m < @TempArrayTwo; $m++) {
	#	my @TempArrayThree = split(/\s/,$TempArrayTwo[$m]);
	#	for (my $n=0; $n < @TempArrayThree; $n++) {
	#	my @TempArrayFour = split(/\(/,$TempArrayThree[$n]);
	#	for (my $o=0; $o < @TempArrayFour; $o++) {
	#		my @TempArrayFive = split(/\)/,$TempArrayFour[$o]);
	#		for (my $p=0; $p < @TempArrayFive; $p++) {
	#		if (length($TempArrayFive[$p]) > 0 && defined($self->{$GenomeID."_aliases"}->{$TempArrayFive[$p]})) {
	#			$TempArrayFive[$p] = $self->{$GenomeID."_aliases"}->{$TempArrayFive[$p]};
	#		}
	#		}
	#		$TempArrayFour[$o] = join(")",@TempArrayFive);
	#	}
	#	$TempArrayThree[$n] = join("(",@TempArrayFour);
	#	}
	#	$TempArrayTwo[$m] = join(" ",@TempArrayThree);
	#}
	#$TempArrayOne[$k] = join("+",@TempArrayTwo);
	#}
	#$Original = join(",",@TempArrayOne);

	#$Original =~ s/[\(\)]//g;

	return $Original;
}

=head3 CompareReactionDirection
Definition:
	$model->CompareReactionDirection();
Description:
Example:
=cut

sub CompareReactionDirection {
	my ($self,$OldReaction,$NewReaction) = @_;

	my $OldReactionData = $self->LoadObject($OldReaction);
	my $NewReactionData = $self->LoadObject($NewReaction);

	if ($OldReactionData ne "0" && $NewReactionData ne "0" && defined($OldReactionData->{"EQUATION"}) && defined($NewReactionData->{"EQUATION"})) {
	if ($OldReactionData->{"EQUATION"}->[0] eq $NewReactionData->{"EQUATION"}->[0]) {
		return "SAME";
	} else {
		return "DIFFERENT";
	}
	}

	return "SAME";
}

=head3 LoadObject
Definition:
my $ObjectDataHashRef = $model->LoadObject($ObjectID);
Description:
	This function loads the specified object file and stores the object data in a hash, which is then returned as a reference.
	The keys of this hash are the first words on each line of the object file. Each hash value is an array of the subsequent words on each line.
	"Words" in this file are separated by tabs.
	The keys in the hash are also stored in an array behind the hash key "orderedkeys" in the order that they were read in from the file.
	This array is useful when you want to print the object data in a specific order everytime.
	0 is returned if the files doesn't exist
Example:
	my $ObjectData = $model->LoadObject("cpd00001");
	print "Object name: ".$ObjectData->{"NAME"}->[0];
	for (my $i=0; $i < @{$ObjectData->{"orderedkeys"}}; $i++) {
	print $ObjectData->{"orderedkeys"}->[$i].": ".join(", ",@{$ObjectData->{$ObjectData->{"orderedkeys"}->[$i]}});
	}
=cut

sub LoadObject {
	my ($self,$ObjectID,$HeadingTranslation) = @_;

	my $Filename = "";

	#Identifying the object type from the ID
	if ($ObjectID =~ m/cpd\d\d\d\d\d/) {
		$Filename = $self->{"compound directory"}->[0].$ObjectID;
	} elsif ($ObjectID =~ m/rxn\d\d\d\d\d/ || $ObjectID =~ m/bio\d\d\d\d\d/) {
		$Filename = $self->{"reaction directory"}->[0].$ObjectID;
	} elsif ($ObjectID =~ m/C\d\d\d\d\d/) {
		$Filename = $self->{"KEGG directory"}->[0]."compounds/".$ObjectID;
	} elsif ($ObjectID =~ m/R\d\d\d\d\d/) {
		$Filename = $self->{"KEGG directory"}->[0]."reactions/".$ObjectID;
	} else {
		print "Object ID type no recognized.\n";
		return 0;
	}

	#Checking if the object has been cached
	if (defined($self->{"CACHE"}->{$ObjectID})) {
		return $self->{"CACHE"}->{$ObjectID};
	}

	#Checking that the file exists
	if (-e $Filename) {
		#For now we load the reaction from a flat file, some day we may load from an SQL DB
		my $ReactionData = &LoadHorizontalDataFile($Filename,"\t",$HeadingTranslation);
		$self->{"CACHE"}->{$ObjectID} = $ReactionData;
		return $ReactionData;
	}

	print "Object file not found:".$Filename."\n";
	return 0;
}

=head3 LoadSubsystemReactionData

Definition:
	$model->LoadSubsystemReactionData();

Description:

Example:
	$model->LoadSubsystemReactionData();

=cut

sub LoadSubsystemReactionData {
	my ($self) = @_;

	if (!defined($self->{"subsystem data"})) {
	$self->{"subsystem data"}->{"array"} = &LoadMultipleLabeledColumnFile($self->{"hope and seed subsystems filename"}->[0],"\t","",0);
	foreach my $Item (@{$self->{"subsystem data"}->{"array"}}) {
		if (defined($Item->{"REACTION"}) && defined($Item->{"SUBSYSTEM"})) {
		my $Reaction = $self->id_of_reaction($Item->{"REACTION"}->[0]);
		if ($Reaction !~ m/rxn\d\d\d\d\d/) {
			$Reaction = $Item->{"REACTION"}->[0];
		}
		push(@{$self->{"subsystem data"}->{"reaction hash"}->{$Item->{"REACTION"}->[0]}},$Item->{"SUBSYSTEM"}->[0]);
		push(@{$self->{"subsystem data"}->{"subsystem hash"}->{$Item->{"SUBSYSTEM"}->[0]}},$Item->{"REACTION"}->[0]);
		}
	}
	}
}

=head3 LoadScenarios

Definition:
	$model->LoadScenarios();

Description:

Example:
	$model->LoadScenarios();

=cut

sub LoadScenarios {
	my ($self) = @_;

	if (!defined($self->{"scenario data"})) {
	my $Data = &LoadMultipleColumnFile($self->{"scenarios file"}->[0],"\t");
	for (my $i=0; $i < @{$Data}; $i++) {
		if (defined($Data->[$i]->[0]) && defined($Data->[$i]->[1])) {
		my $Reaction = $self->id_of_reaction($Data->[$i]->[1]);
		if ($Reaction !~ m/rxn\d\d\d\d\d/) {
			$Reaction = $Data->[$i]->[1];
		}
		push(@{$self->{"scenario data"}->{"reaction hash"}->{$Reaction}},$Data->[$i]->[0]);
		push(@{$self->{"scenario data"}->{"scenario hash"}->{$Data->[$i]->[0]}},$Reaction);
		}
	}
	}
}

=head3 class_of_subsystem

Definition:
	$model->class_of_subsystem();

Description:


Example:
	$model->class_of_subsystem();

=cut

sub class_of_subsystem {
	my($self,$Subsystem) = @_;

	if (!defined($self->{"subsystem classes"})) {
		my $SubsystemDataFilename = $self->{"subsystem class file"}->[0];
		my $Data = &LoadMultipleColumnFile($SubsystemDataFilename,"\t");
		for (my $i=0; $i < @{$Data};$i++) {
			if (defined($Data->[$i]->[0]) && defined($Data->[$i]->[1]) && defined($Data->[$i]->[2])) {
				$self->{"subsystem classes"}->{$Data->[$i]->[0]}->[0] = $Data->[$i]->[1];
				$self->{"subsystem classes"}->{$Data->[$i]->[0]}->[1] = $Data->[$i]->[2];
			}
		}
	}

	return $self->{"subsystem classes"}->{$Subsystem};
}

=head3 LoadFunctionalRoleMapping
Definition:
	$model->LoadFunctionalRoleMapping($ModelList);
Description:

=cut
sub LoadFunctionalRoleMapping {
	my ($self,$ModelList) = @_;

	#Setting the list and cache key based on the list desired
	my $Filename = $self->{"Function mapping filename"}->[0];
	my $Key = "FUNCTIONAL ROLE MAPPING";
	if (defined($ModelList) && $ModelList ne "0" && $ModelList ne "no") {
		$Filename = $self->{"Model function mapping filename"}->[0];
		$Key = "MODEL FUNCTIONAL ROLE MAPPING";
	}

	if (!defined($self->{$Key})) {
		my $HashArray = LoadMultipleLabeledColumnFile($Filename,"\t","");
		my $ReactionHash;
		my $FunctionHash;
		my $SubsytemHash;
		for (my $i=0; $i < @{$HashArray}; $i++) {
			if (defined($HashArray->[$i]->{"REACTION"})) {
				push(@{$ReactionHash->{$HashArray->[$i]->{"REACTION"}->[0]}},$HashArray->[$i]);
			}
			if (defined($HashArray->[$i]->{"ROLE"})) {
				push(@{$FunctionHash->{lc($HashArray->[$i]->{"ROLE"}->[0])}},$HashArray->[$i]);
			}
			if (defined($HashArray->[$i]->{"SUBSYSTEM"})) {
				push(@{$SubsytemHash->{$HashArray->[$i]->{"SUBSYSTEM"}->[0]}},$HashArray->[$i]);
			}
		}
		$self->{$Key}->{"ARRAY"} = $HashArray;
		$self->{$Key}->{"REACTION HASH"} = $ReactionHash;
		$self->{$Key}->{"FUNCTION HASH"} = $FunctionHash;
		$self->{$Key}->{"SUBSYSTEM HASH"} = $SubsytemHash;
	}
}

=head3 roles_of_reaction
Definition:
	my $RoleHashArrayRef = $model->roles_of_reaction();
Description:

=cut
sub roles_of_reaction {
	my ($self,$reaction,$content) = @_;

	#Loading the functional role mapping based on value of $content
	my %RoleHash;
	if (!defined($content) || $content eq "ALL" || $content eq "SEED") {
		$self->LoadFunctionalRoleMapping();
		if (defined($self->{"FUNCTIONAL ROLE MAPPING"}->{"REACTION HASH"}->{$reaction})) {
			foreach my $Mapping (@{$self->{"FUNCTIONAL ROLE MAPPING"}->{"REACTION HASH"}->{$reaction}}) {
				if ($Mapping->{"MASTER"}->[0] == 1) {
					$RoleHash{$Mapping->{"ROLE"}->[0]} = 1;
				}
			}
		}
	}
	#if (defined($content) && ($content eq "ALL" || $content eq "MODELS")) {
	#	$self->LoadFunctionalRoleMapping(1);
	#	if (defined($self->{"MODEL FUNCTIONAL ROLE MAPPING"}->{"REACTION HASH"}->{$reaction})) {
	#		foreach my $Mapping (@{$self->{"MODEL FUNCTIONAL ROLE MAPPING"}->{"REACTION HASH"}->{$reaction}}) {
	#			$RoleHash{$Mapping->{"ROLE"}->[0]} = 1;
	#		}
	#	}
	#}

	#If any roles were found, we add these to a referenced array
	my @TempArray = keys(%RoleHash);
	if (@TempArray > 0) {
		my $Roles;
		push(@{$Roles},@TempArray);
		return $Roles;
	}
	return undef;
}

=head3 model_roles_not_in_subsystems
Definition:
	FIGMODELTable::No subsystem role table = figmodel->model_roles_not_in_subsystems(void);
Description:
	This function returns a table of the roles and pegs included in the genome-scale models but not found in a subsystem.
=cut
sub model_roles_not_in_subsystems {
	my ($self) = @_;

	#Loading the functional role-to-reaction mapping
	my $RoleTable = $self->database()->GetDBTable("CURATED ROLE MAPPINGS");

	#Creating the output table
	my $ResultTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["ROLES","PEGS","REACTIONS"],$self->{"Reaction database directory"}->[0]."MiscDataTables/NoSubsystemRoles.tbl",["ROLES"],";","~",undef);

	#Scanning through this table and generating a hash of roles outside of subsystems
	for (my $i=0; $i < $RoleTable->size(); $i++) {
		my $Role = $RoleTable->get_row($i)->{"ROLE"}->[0];
		my $Subsystems = $self->subsystems_of_role($Role);
		if (!defined($Subsystems)) {
			#Adding role to table if not already present
			my $Row = $ResultTable->get_row_by_key($Role,"ROLES",1);
			#Getting pegs for role
			if (!defined($Row->{"REACTIONS"})) {
				my @Pegs = $self->fig()->role_to_pegs($Role);
				#Filtering the peg list based on the models
				foreach my $Peg (@Pegs) {
					if ($Peg =~ m/fig\|(\d+\.\d+)\./) {
						if ($self->status_of_model($1) >= 0) {
							push(@{$Row->{"PEGS"}},$Peg);
						}
					}
				}
			}
			$ResultTable->add_data($Row,"REACTIONS",$RoleTable->get_row($i)->{"REACTION"},1);
		}
	}
	$ResultTable->save();

	return $ResultTable;
}

=head3 modeldata_of_rolemapping
Definition:
	my $ModelPegHash = $model->modeldata_of_rolemapping($Reaction,$Role);
Description:

=cut

sub modeldata_of_rolemapping {
	my ($self,$reaction,$role) = @_;

	my $ModelDataHash;
	my $Found = 0;
	$self->LoadFunctionalRoleMapping(1);
	if (defined($self->{"MODEL FUNCTIONAL ROLE MAPPING"}->{"REACTION HASH"}->{$reaction})) {
		foreach my $Mapping (@{$self->{"MODEL FUNCTIONAL ROLE MAPPING"}->{"REACTION HASH"}->{$reaction}}) {
			if ($Mapping->{"ROLE"}->[0] eq $role && defined($Mapping->{"MODELS"}->[0])) {
				my @ModelArray = split(/\|/,$Mapping->{"MODELS"}->[0]);
				for (my $i=0; $i < @ModelArray; $i++) {
					my @PegArray = split(/,/,$ModelArray[$i]);
					for (my $j=1; $j < @PegArray; $j++) {
						$ModelDataHash->{$PegArray[0]}->{$PegArray[$j]} = 1;
					}
					$ModelDataHash->{$PegArray[0]}->{"HASH"} = $Mapping;
					$Found = 1;
				}
			}
		}
	}

	if ($Found == 1) {
		return $ModelDataHash;
	}
	return undef;
}


=head3 reactions_of_role
Definition:
	my $RoleHashArrayRef = $model->reactions_of_role();
Description:
Example:
	my $RoleHashArrayRef = $model->reactions_of_role();
=cut

sub reactions_of_role {
	my ($self,$role) = @_;

	my $RoleHashArrayRef;
	#Loading the functional role mapping if needed
	if (!defined($self->{"FUNCTIONAL ROLE MAPPING"})) {
		$self->LoadFunctionalRoleMapping();
	}

	#Checking if the reaction is in the mapping
	if (defined($self->{"FUNCTIONAL ROLE MAPPING"}->{"FUNCTION HASH"}->{lc($role)})) {
	$RoleHashArrayRef = $self->{"FUNCTIONAL ROLE MAPPING"}->{"FUNCTION HASH"}->{lc($role)};
	} else {
	$RoleHashArrayRef = 0;
	}

	return $RoleHashArrayRef;
}

=head3 genes_of_interval
Definition:
	my $GeneListRef = $model->genes_of_interval($Start,$Stop,$Genome);
Description:
Example:
	my $GeneListRef = $model->genes_of_interval($Start,$Stop,$Genome);
=cut

sub genes_of_interval {
	my ($self,$Start,$Stop,$Genome) = @_;

	my $GeneList;
	my $FeatureTable = $self->GetGenomeFeatureTable($Genome);
	if (!defined($FeatureTable)) {
		return undef;
	}
	for (my $i=0; $i < $FeatureTable->size();$i++) {
		my $Row = $FeatureTable->get_row($i);
		if (defined($Row->{"ID"}->[0]) && $Row->{"ID"}->[0] =~ m/(peg\.\d+)/ && defined($Row->{"MIN LOCATION"}->[0]) && defined($Row->{"MAX LOCATION"}->[0]) && $Row->{"MIN LOCATION"}->[0] < $Stop && $Row->{"MAX LOCATION"}->[0] > $Start) {
			push(@{$GeneList},$1);
		}
	}

	return $GeneList;
}

=head3 SaveObject

Definition:
my $Status = $model->SaveObject($ObjectDataHashRef);

Description:
	This function prints the input object back to the database file.
	Each line of the file starts with a key of the hash and continues with each value in the hash array separated by a tab.
	Only keys stored in the "orderkeys" array will be printed, and keys will be printed in the order they are found in the ordered keys array.
	0 is returns upon success, 1 is returned otherwise.
Example:
	my $ObjectData = $model->LoadObject("cpd00001");
	#Adding the formula to the object if its not already present
	$model->AddDataToObject($ObjectData,"FORMULA",("H2O"));
	#Printing the object back to file with the formula
	my $Status = $model->SaveObject($ObjectData);
=cut

sub SaveObject {
	my ($self,$ObjectData) = @_;

	#Checking for the object ID
	if (!defined($ObjectData->{"DATABASE"}) || length($ObjectData->{"DATABASE"}->[0]) == 0) {
	print "No object ID found in input object.\n";
	return 1;
	}
	my $ObjectID = $ObjectData->{"DATABASE"}->[0];

	#Identifying the object type from the ID
	my $Filename = "";
	if ($ObjectID =~ m/cpd\d\d\d\d\d/) {
	$Filename = $self->{"compound directory"}->[0].$ObjectID;
	} elsif ($ObjectID =~ m/rxn\d\d\d\d\d/) {
	$Filename = $self->{"reaction directory"}->[0].$ObjectID;
	} elsif ($ObjectID =~ m/C\d\d\d\d\d/) {
	$Filename = $self->{"KEGG directory"}->[0]."compounds/".$ObjectID;
	} elsif ($ObjectID =~ m/R\d\d\d\d\d/) {
	$Filename = $self->{"KEGG directory"}->[0]."reactions/".$ObjectID;
	} else {
	print "Object ID type not recognized.\n";
	return 1;
	}

	#Loading a fresh hash with the data to be saved and cached
	my $FreshData;
	push(@{$FreshData->{"orderedkeys"}},@{$ObjectData->{"orderedkeys"}});
	foreach my $Item (@{$ObjectData->{"orderedkeys"}}) {
	if (defined($ObjectData->{$Item}) && @{$ObjectData->{$Item}} > 0) {
		foreach my $SubItem (@{$ObjectData->{$Item}}) {
		if (length($SubItem) > 0) {
			push(@{$FreshData->{$Item}},$SubItem);
		}
		}
	}
	}

	#Printing the object to file
	$self->{"CACHE"}->{$ObjectID} = $FreshData;
	&SaveHashToHorizontalDataFile($Filename,"\t",$FreshData);

	return 0;
}

=head3 translate_gene_to_protein
Definition:
	$model->translate_gene_to_protein($GeneList);
Description:
Example:
=cut

sub translate_gene_to_protein {
	my($self,$Genes,$Genome) = @_;
	my $FeatureTable = $self->GetGenomeFeatureTable($Genome);
	if (!defined($FeatureTable)) {
		return ("","","");
	}
	my ($ProteinAssociation,$GeneLocus,$GeneGI);
	for (my $j=0; $j < @{$Genes}; $j++) {
		if ($j > 0) {
	        $ProteinAssociation .= " or ";
	        $GeneLocus .= " or ";
	        $GeneGI .= " or ";	
		}
		my $proteinTemp = $Genes->[$j];
		my $locusTemp = $Genes->[$j];
		my $giTemp = $Genes->[$j];
		$_ = $Genes->[$j];
		my @OriginalArray = /(peg\.\d+)/g;
		for (my $i=0; $i < @OriginalArray; $i++) {
	        my $Row = $FeatureTable->get_row_by_key("fig|".$Genome.".".$OriginalArray[$i],"ID");
			my $ProteinName = "NONE";
			my $locus = "NONE";
			my $giNum = "NONE";
			if (defined($Row) && defined($Row->{"ALIASES"})) {
				foreach my $Alias (@{$Row->{"ALIASES"}}) {
					if ($Alias =~ m/^[^\d]+$/) {
						$ProteinName = $Alias;
					} elsif ($Alias =~ m/gi\|(\d+)/) {
						$giNum = $1;
					} elsif ($Alias =~ m/LocusTag:(\D+\d+)/) {
						$locus = $1;
					} elsif ($Alias =~ m/^\D{1,2}\d{3,5}\D{0,1}$/) {
						$locus = $Alias;
					}
				}
			}
			my $Gene = $OriginalArray[$i];
			if ($ProteinName ne "NONE") {
	            $proteinTemp =~ s/$Gene(\D)/$ProteinName$1/g;
	            $proteinTemp =~ s/$Gene$/$ProteinName/g;
			}
	        if ($locus ne "NONE") {
	            $locusTemp =~ s/$Gene(\D)/$locus$1/g;
	            $locusTemp =~ s/$Gene$/$locus/g;
	        }
	        if ($giNum ne "NONE") {
	            $giTemp =~ s/$Gene(\D)/$giNum$1/g;
	            $giTemp =~ s/$Gene$/$giNum/g;
	        }
		}
		$proteinTemp =~ s/\s//g;
		$locusTemp =~ s/\s//g;
		$giTemp =~ s/\s//g;
		$proteinTemp =~ s/\+/ and /g;
		$locusTemp =~ s/\+/ and /g;
		$giTemp =~ s/\+/ and /g;
		$ProteinAssociation .= $proteinTemp;
	    $GeneLocus .= $locusTemp;
	    $GeneGI .= $giTemp;
	}
	return ($ProteinAssociation,$GeneLocus,$GeneGI);
}

=head3 SyncDatabaseMolfiles

Definition:
	$model->SyncDatabaseMolfiles();

Description:
	This function renames any updated KEGG and Palsson molfiles to Argonne molfiles and creates a molfile images for any updated molfiles and any molfiles without associated images
	This function should be run whenever new KEGG or Palsson molfiles are added to the database and occasionally after the mapping has been run.

Example:
	$model->SyncDatabaseMolfiles();

=cut

sub SyncDatabaseMolfiles {
	my($self) = @_;

	#Copying over the corrected molfiles
	my @FileList = glob($self->{"corrected Argonne molfile directory"}->[0]."*.mol");
	my %PreservedIDs;
	foreach my $Filename (@FileList) {
		if ($Filename =~ m/(cpd\d\d\d\d\d)\.mol/) {
			system("cp ".$self->{"corrected Argonne molfile directory"}->[0].$1.".mol ".$self->{"Argonne molfile directory"}->[0].$1.".mol");
			system("cp ".$self->{"corrected Argonne molfile directory"}->[0].$1.".mol ".$self->{"Argonne molfile directory"}->[0]."pH7/".$1.".mol");
			$PreservedIDs{$1} = 1;
		}
	}

    #First, reading in the latest mapping of IDs from the translation directory
    my ($CompoundMappings,$HashReferenceForward) = &LoadSeparateTranslationFiles($self->{"Translation directory"}->[0]."CpdToKEGG.txt","\t");

    #Copying over the KEGG molfiles
    my @CompoundIDs = keys(%{$CompoundMappings});
	for (my $i=0; $i < @CompoundIDs; $i++) {
		if (!defined($PreservedIDs{$CompoundIDs[$i]}) && defined($CompoundMappings->{$CompoundIDs[$i]}) && $CompoundMappings->{$CompoundIDs[$i]} =~ m/C\d\d\d\d\d/) {
			$PreservedIDs{$CompoundIDs[$i]} = 1;
			if (-e $self->{"corrected KEGG molfile directory"}->[0].$CompoundMappings->{$CompoundIDs[$i]}.".mol") {
				system("cp ".$self->{"corrected KEGG molfile directory"}->[0].$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0].$CompoundIDs[$i].".mol");
				system("cp ".$self->{"corrected KEGG molfile directory"}->[0].$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0]."pH7/".$CompoundIDs[$i].".mol");
			} elsif (-e $self->{"KEGG directory"}->[0]."mol/pH7/".$CompoundMappings->{$CompoundIDs[$i]}.".mol") {
				system("cp ".$self->{"KEGG directory"}->[0]."mol/pH7/".$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0].$CompoundIDs[$i].".mol");
				system("cp ".$self->{"KEGG directory"}->[0]."mol/pH7/".$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0]."pH7/".$CompoundIDs[$i].".mol");
			} elsif (-e $self->{"KEGG directory"}->[0]."mol/".$CompoundMappings->{$CompoundIDs[$i]}.".mol") {
				system("cp ".$self->{"KEGG directory"}->[0]."mol/".$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0].$CompoundIDs[$i].".mol");
			}
		}
    }

    #Copying over the Palsson molfiles
	my @TranslationFilename = glob($self->{"Translation directory"}->[0]."CpdTo*.txt");
	my %NonOverwrittenCompounds;
	for (my $j=0; $j < @TranslationFilename; $j++) {
		if ($TranslationFilename[$j] ne "CpdToAll.txt" && $TranslationFilename[$j] ne "CpdToKEGG.txt") {
			($CompoundMappings,my $HashReferenceForward) = &LoadSeparateTranslationFiles($TranslationFilename[$j],"\t");
			@CompoundIDs = keys(%{$CompoundMappings});
			for (my $i=0; $i < @CompoundIDs; $i++) {
				if (defined($CompoundMappings->{$CompoundIDs[$i]}) && -e $self->{"Model molfile directory"}->[0].$CompoundMappings->{$CompoundIDs[$i]}.".mol") {
					if (defined($PreservedIDs{$CompoundIDs[$i]})) {
						$NonOverwrittenCompounds{$CompoundIDs[$i]}->{$CompoundMappings->{$CompoundIDs[$i]}} = 1;
					} elsif ($CompoundMappings->{$CompoundIDs[$i]} !~ m/C\d\d\d\d\d/ && $CompoundMappings->{$CompoundIDs[$i]} !~ m/cpd\d\d\d\d\d/ && $CompoundIDs[$i] =~ m/cpd\d\d\d\d\d/) {
						if (-e $self->{"Model molfile directory"}->[0]."pH7/".$CompoundMappings->{$CompoundIDs[$i]}.".mol") {
							system("cp ".$self->{"Model molfile directory"}->[0]."pH7/".$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0].$CompoundIDs[$i].".mol");
							system("cp ".$self->{"Model molfile directory"}->[0]."pH7/".$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0]."pH7/".$CompoundIDs[$i].".mol");
						} elsif (-e $self->{"Model molfile directory"}->[0].$CompoundMappings->{$CompoundIDs[$i]}.".mol") {
							system("cp ".$self->{"Model molfile directory"}->[0].$CompoundMappings->{$CompoundIDs[$i]}.".mol ".$self->{"Argonne molfile directory"}->[0].$CompoundIDs[$i].".mol");
						}
					}
				}
			}
		}
	}

	my $NonOverwrites;
	my @NonOverwriteKeys = keys(%NonOverwrittenCompounds);
	for (my $i=0; $i < @NonOverwriteKeys; $i++) {
		push (@{$NonOverwrites},$NonOverwriteKeys[$i]." not overwritten by the following model molfiles: ".join(".mol ",keys(%{$NonOverwrittenCompounds{$NonOverwriteKeys[$i]}})).".mol");
	}
	PrintArrayToFile($self->{"database message file directory"}->[0]."NonOverwrittenMolfiles.log",$NonOverwrites);
}

=head3 SyncWithTheKEGG

Definition:
	$model->SyncWithTheKEGG();

Description:
	This function is used to process the KEGG directory for syncing with the current Argonne database.
	This should be run whenever a new version of the KEGG has been downloaded.

Example:
	$model->SyncWithTheKEGG();

=cut

sub SyncWithTheKEGG {
	my($self) = @_;

	#Pathway name/ID correspondence will be stored in this hash
	my %PathwayNameHash;

	#Backing up the current KEGG files
	if (-d $self->{"KEGG directory"}->[0]."oldmol") {
	#system("rm -rf ".$self->{"KEGG directory"}->[0]."oldmol")
	}
	if (-d $self->{"KEGG directory"}->[0]."ligand") {
	#system("mv ".$self->{"KEGG directory"}->[0]."mol/ ".$self->{"KEGG directory"}->[0]."oldmol/");
	#system("mv ".$self->{"KEGG directory"}->[0]."reaction ".$self->{"KEGG directory"}->[0]."oldreaction");
	#system("mv ".$self->{"KEGG directory"}->[0]."reaction_mapformula.lst ".$self->{"KEGG directory"}->[0]."oldreaction_mapformula.lst");
	#system("mv ".$self->{"KEGG directory"}->[0]."compound ".$self->{"KEGG directory"}->[0]."oldcompound");
	#system("mv ".$self->{"KEGG directory"}->[0]."enzyme ".$self->{"KEGG directory"}->[0]."oldenzyme");
	#Copying over current KEGG data to the KEGG directory for processing
	#system("cp /vol/biodb/kegg/ligand/reaction/reaction ".$self->{"KEGG directory"}->[0]."reaction");
	#system("cp /vol/biodb/kegg/ligand/reaction/reaction_mapformula.lst ".$self->{"KEGG directory"}->[0]."reaction_mapformula.lst");
	#system("cp /vol/biodb/kegg/ligand/compound/compound ".$self->{"KEGG directory"}->[0]."compound");
	#system("cp /vol/biodb/kegg/ligand/enzyme/enzyme ".$self->{"KEGG directory"}->[0]."enzyme");
	}

	#Deleting the existing old compounds and reactions directories
	if (-d $self->{"KEGG directory"}->[0]."oldcompounds") {
		system("rm -rf ".$self->{"KEGG directory"}->[0]."oldcompounds")
	}
	if (-d $self->{"KEGG directory"}->[0]."oldreactions") {
		system("rm -rf ".$self->{"KEGG directory"}->[0]."oldreactions")
	}

	#Renaming the current compounds and reactions directories
	if (-d $self->{"KEGG directory"}->[0]."compounds") {
	system("mv ".$self->{"KEGG directory"}->[0]."compounds ".$self->{"KEGG directory"}->[0]."oldcompounds");
	}
	if (-d $self->{"KEGG directory"}->[0]."reactions") {
	system("mv ".$self->{"KEGG directory"}->[0]."reactions ".$self->{"KEGG directory"}->[0]."oldreactions");
	}

	#Making new current compounds and reactions directories
	system("mkdir ".$self->{"KEGG directory"}->[0]."compounds");
	system("mkdir ".$self->{"KEGG directory"}->[0]."reactions");

	#Parsing the compound and reaction files into the new current compounds and reactions directories
	my $FileOpen = 0;
	my $Section = "";
	my $FirstName = 1;
	if (open (KEGGINPUT, "<".$self->{"KEGG directory"}->[0]."compound")) {
	while (my $Line = <KEGGINPUT>) {
		chomp($Line);
		my @Data = split(/\s+/,$Line);
		if ($Data[0] =~ m/ENTRY/) {
		if ($FileOpen != 0) {
			close(KEGGOUTPUT);
		} else {
			$FileOpen = 1;
		}
		my $Filename = $self->{"KEGG directory"}->[0]."compounds/".$Data[1];
		open(KEGGOUTPUT, ">$Filename");
		print KEGGOUTPUT "ENTRY\t".$Data[1];
		} elsif ($Line  =~ m/^\s/) {
		shift(@Data);
		if ($Section eq "NAME") {
			for(my $i=0; $i < @Data; $i++) {
			if ($FirstName == 1) {
				print KEGGOUTPUT "\t";
				$FirstName = 0;
			} else {
				print KEGGOUTPUT " ";
			}
			if ($Data[$i] =~ m/;$/) {
				$FirstName = 1;
				$Data[$i] = substr($Data[$i],0,length($Data[$i])-1);
			}
			print KEGGOUTPUT $Data[$i];
			}
		} elsif ($Section eq "ENZYME") {
			for(my $i=0; $i < @Data; $i++) {
			if (length($Data[$i]) <= 3) {
				print KEGGOUTPUT $Data[$i];
			} else {
				print KEGGOUTPUT "\t".$Data[$i];
			}
			}
		} elsif ($Section eq "PATHWAY") {
			#--- I only the pathway name---#
			print KEGGOUTPUT "\t".$Data[1];
			my $MapID = $Data[1];
			shift(@Data);
			shift(@Data);
			$PathwayNameHash{$MapID} = join(" ",@Data);
		} elsif ($Section eq "DBLINKS") {
			print KEGGOUTPUT "\t".$Data[0]." ".$Data[1];
		} elsif ($Section eq "REMARK" || $Section eq "ATOM" || $Section eq "BOND" || $Section eq "///") {
			#Do nothing... these parts of the file are ignored
		} else {
			print KEGGOUTPUT "\t".join("\t",@Data);
		}
		} else {
		$Section = shift(@Data);
		$FirstName = 1;
		if ($Section eq "NAME") {
			print KEGGOUTPUT "\n".$Section;
			for(my $i=0; $i < @Data; $i++) {
			if ($FirstName == 1) {
				print KEGGOUTPUT "\t";
				$FirstName = 0;
			} else {
				print KEGGOUTPUT " ";
			}
			if ($Data[$i] =~ m/;$/) {
				$FirstName = 1;
				$Data[$i] = substr($Data[$i],0,length($Data[$i])-1);
			}
			print KEGGOUTPUT $Data[$i];
			}
		} elsif ($Section eq "ENZYME") {
			print KEGGOUTPUT "\n".$Section;
			for(my $i=0; $i < @Data; $i++) {
			if (length($Data[$i]) <= 3) {
				print KEGGOUTPUT $Data[$i];
			} else {
				print KEGGOUTPUT "\t".$Data[$i];
			}
			}
		} elsif ($Section eq "PATHWAY") {
			print KEGGOUTPUT "\n".$Section."\t".$Data[1];
			my $MapID = $Data[1];
			shift(@Data);
			shift(@Data);
			$PathwayNameHash{$MapID} = join(" ",@Data);
		} elsif ($Section eq "DBLINKS") {
			print KEGGOUTPUT "\n".$Section."\t".$Data[0]." ".$Data[1];
		} elsif ($Section eq "REMARK" || $Section eq "ATOM" || $Section eq "BOND" || $Section eq "///") {
			#Do nothing... these parts of the file are ignored
		} else {
			print KEGGOUTPUT "\n".$Section."\t".join("\t",@Data);
		}
		}
	}
	close (KEGGINPUT);
	}
	$FileOpen = 0;
	$Section = "";
	$FirstName = 1;
	my %ReactionDirections;
	if (open (KEGGINPUT, "<".$self->{"KEGG directory"}->[0]."reaction_mapformula.lst")) {
	while (my $Line = <KEGGINPUT>) {
		chomp($Line);
		my @Data = split(/\s+/,$Line);
		my $ReactionID = substr($Data[0],0,length($Data[0])-1);
		for(my $i=0; $i < @Data; $i++) {
		if ($Data[$i]  =~ m/^=/ || $Data[$i]  =~ m/^</) {
			if (defined($ReactionDirections{$ReactionID})) {
			if ($ReactionDirections{$ReactionID} ne $Data[$i]) {
				$ReactionDirections{$ReactionID} = "<=>";
			}
			} else {
			$ReactionDirections{$ReactionID} = $Data[$i];
			}
		}
		}
	}
	close(KEGGINPUT);
	}
	my $Direction = "<=>";
	if (open (KEGGINPUT, "<".$self->{"KEGG directory"}->[0]."reaction")) {
	while (my $Line = <KEGGINPUT>) {
		chomp($Line);
		my @Data = split(/\s+/,$Line);
		if ($Data[0] =~ m/ENTRY/) {
		if ($FileOpen != 0) {
			close(KEGGOUTPUT);
		} else {
			$FileOpen = 1;
		}
		my $Filename = $self->{"KEGG directory"}->[0]."reactions/".$Data[1];
		open(KEGGOUTPUT, ">$Filename");
		print KEGGOUTPUT "ENTRY\t".$Data[1];
		$Direction = "<=>";
		if (defined($ReactionDirections{$Data[1]})) {
			$Direction = $ReactionDirections{$Data[1]};
		}
		} elsif ($Line  =~ m/^\s/) {
		$FirstName = 1;
		if ($Section eq "NAME") {
			for(my $i=0; $i < @Data; $i++) {
			if ($FirstName == 1) {
				print KEGGOUTPUT "\t";
				$FirstName = 0;
			} else {
				print KEGGOUTPUT " ";
			}
			if ($Data[$i] =~ m/;$/) {
				$FirstName = 1;
				$Data[$i] = substr($Data[$i],0,length($Data[$i])-1);
			}
			print KEGGOUTPUT $Data[$i];
			}
		} elsif ($Section eq "ENZYME") {
			for(my $i=0; $i < @Data; $i++) {
			if (length($Data[$i]) <= 3) {
				print KEGGOUTPUT $Data[$i];
			} else {
				print KEGGOUTPUT "\t".$Data[$i];
			}
			}
		} elsif ($Section eq "DEFINITION" || $Section eq "EQUATION" || $Section eq "COMMENT") {
			print KEGGOUTPUT " ".join(" ",@Data);
		} elsif ($Section eq "PATHWAY") {
			#--- I only print the map ID... we dont need to print the name every time ---#
			print KEGGOUTPUT "\t".$Data[2];
			my $MapID = $Data[2];
			shift(@Data);
			shift(@Data);
			shift(@Data);
			$PathwayNameHash{$MapID} = join(" ",@Data);
		} elsif ($Section eq "ORTHOLOGY") {
			#--- I only print the map ID... we dont need to print the name every time ---#
			print KEGGOUTPUT "\t".$Data[2];
		} elsif ($Section eq "///" || $Section eq "RPAIR") {
			#Do nothing... these parts of the file are ignored
		} else {
			print KEGGOUTPUT "\t".join("\t",@Data);
		}
		} else {
		$Section = shift(@Data);
		$FirstName = 1;
		if ($Section eq "NAME") {
			print KEGGOUTPUT "\n".$Section;
			for(my $i=0; $i < @Data; $i++) {
			if ($FirstName == 1) {
				print KEGGOUTPUT "\t";
				$FirstName = 0;
			} else {
				print KEGGOUTPUT " ";
			}
			if ($Data[$i] =~ m/;$/) {
				$FirstName = 1;
				$Data[$i] = substr($Data[$i],0,length($Data[$i])-1);
			}
			print KEGGOUTPUT $Data[$i];
			}
		} elsif ($Section eq "ENZYME") {
			print KEGGOUTPUT "\n".$Section;
			for(my $i=0; $i < @Data; $i++) {
			if (length($Data[$i]) <= 3) {
				print KEGGOUTPUT $Data[$i];
			} else {
				print KEGGOUTPUT "\t".$Data[$i];
			}
			}
		} elsif ($Section eq "DEFINITION" || $Section eq "COMMENT") {
			print KEGGOUTPUT "\n".$Section."\t".join(" ",@Data);
		} elsif ($Section eq "EQUATION") {
			for(my $i=0; $i < @Data; $i++) {
			if ($Data[$i] eq "<=>") {
				$Data[$i] = $Direction;
			}
			}
			print KEGGOUTPUT "\n".$Section."\t".join(" ",@Data);
		} elsif ($Section eq "PATHWAY") {
			#--- I only print the map ID... we dont need to print the name every time ---#
			print KEGGOUTPUT "\n".$Section."\t".$Data[1];
			my $MapID = $Data[1];
			shift(@Data);
			shift(@Data);
			$PathwayNameHash{$MapID} = join(" ",@Data);
		} elsif ($Section eq "ORTHOLOGY") {
			print KEGGOUTPUT "\n".$Section."\t".$Data[1];
		} elsif ($Section eq "///" || $Section eq "RPAIR") {
			#Do nothing... these parts of the file are ignored
		} else {
			print KEGGOUTPUT "\n".$Section."\t".join("\t",@Data);
		}
		}
	}
	close (KEGGINPUT);
	}

	#Printing the key assocaiting map IDs to names
	if (open (KEGGOUTPUT, ">".$self->{"KEGG directory"}->[0]."MapIDKey.txt")) {
	my @MapIDList = keys(%PathwayNameHash);
	for (my $i=0; $i < @MapIDList; $i++) {
		print KEGGOUTPUT $MapIDList[$i]."\t".$PathwayNameHash{$MapIDList[$i]}."\n";
	}
	close(KEGGOUTPUT);
	}
}

=head3 ParseHopeSEEDReactionFiles

Definition:
	$model->ParseHopeSEEDReactionFiles();

Description:

Example:
	$model->ParseHopeSEEDReactionFiles();

=cut

sub ParseHopeSEEDReactionFiles {
	my($self) = @_;

	#Gathering all of the filesnames in the subsystems directory
	print "Parsing subsystems...\n";
	my @Filenames = &RecursiveGlob($self->{"subsystems directory"}->[0]);
	print "Subsystem filenames gathered...\n";

	#Scanning through the filenames for the Hope and SEED reaction files
	my %SubsystemDataHash;
	for (my $i=0; $i < @Filenames; $i++) {
	if ($Filenames[$i] =~ m/\/([^\/]+)\/hope_reactions$/) {
		my $Subsystem = $1;
		#Loading the entire file into a 2D array
		my $Data = FIGMODEL::LoadMultipleColumnFile($Filenames[$i],"\t");
		#For each line in the file, saving the subsystem name, the functional role, and the hope reaction
		for (my $j=0; $j < @{$Data}; $j++) {
		if (defined($Data->[$j]->[0]) && defined($Data->[$j]->[1])) {
			my @Reactions = split(/,/,$Data->[$j]->[1]);
			for (my $k=0; $k < @Reactions; $k++) {
			if (defined($SubsystemDataHash{$Subsystem}->{$Data->[$j]->[0]}->{$Reactions[$k]}->{"SOURCE"})) {
				$SubsystemDataHash{$Subsystem}->{$Data->[$j]->[0]}->{$Reactions[$k]}->{"SOURCE"}->[0] .= "|Hope";
			} else {
				$SubsystemDataHash{$Subsystem}->{$Data->[$j]->[0]}->{$Reactions[$k]}->{"SOURCE"}->[0] = "Hope";
			}
			}
		}
		}
	#} elsif ($Filenames[$i] =~ m/\/([^\/]+)\/reactions$/) {
	#    my $Subsystem = $1;
	#    #Loading the entire file into a 2D array
	#    my $Data = FIGMODEL::LoadMultipleColumnFile($Filenames[$i],"\t");
	#    #For each line in the file, saving the subsystem name, the functional role, and the hope reaction
	#    for (my $j=0; $j < @{$Data}; $j++) {
	#   if (defined($Data->[$j]->[0]) && defined($Data->[$j]->[1])) {
	#       my @Reactions = split(/,/,$Data->[$j]->[1]);
	#       for (my $k=0; $k < @Reactions; $k++) {
	#       my $Reaction = $Reactions[$k];
	#       if ($Reaction =~ m/(R\d\d\d\d\d)/ || $Reaction =~ m/(rxn\d\d\d\d\d)/) {
	#           $Reaction = $1;
	#           if (defined($SubsystemDataHash{$Subsystem}->{$Data->[$j]->[0]}->{$Reactions[$k]}->{"SOURCE"})) {
	#           $SubsystemDataHash{$Subsystem}->{$Data->[$j]->[0]}->{$Reactions[$k]}->{"SOURCE"}->[0] .= "|SEED";
	#           } else {
	#           $SubsystemDataHash{$Subsystem}->{$Data->[$j]->[0]}->{$Reactions[$k]}->{"SOURCE"}->[0] = "SEED";
	#           }
	#       }
	#       }
	#   }
	#    }
	}
	}

	my $Filename = $self->{"hope and seed subsystems filename"}->[0];
	open (SEEDHOPEANNOTATIONS, ">$Filename");
	print SEEDHOPEANNOTATIONS "SUBSYSTEM\tROLE\tREACTION\tSOURCE\n";
	foreach my $Subsystem (keys(%SubsystemDataHash)) {
	foreach my $Role (keys(%{$SubsystemDataHash{$Subsystem}})) {
		foreach my $Reaction (keys(%{$SubsystemDataHash{$Subsystem}->{$Role}})) {
		print SEEDHOPEANNOTATIONS $Subsystem."\t".$Role."\t".$Reaction."\t".$SubsystemDataHash{$Subsystem}->{$Role}->{$Reaction}->{"SOURCE"}->[0]."\n";
		}
	}
	}
	close(SEEDHOPEANNOTATIONS);

	#Gathering all of the filesnames in the subsystems directory
	print "Parsing scenarios...\n";
	@Filenames = &RecursiveGlob($self->{"scenarios directory"}->[0]);
	print "Scenario filenames gathered...\n";
	my %ScenarioHash;
	for (my $i=0; $i < @Filenames; $i++) {
	if ($Filenames[$i] =~ m/reactions$/) {
		my $ScenarioName = substr($Filenames[$i],length($self->{"scenarios directory"}->[0]));
		my @DirectoryList = split(/\//,$ScenarioName);
		shift(@DirectoryList);
		$ScenarioName = join(":",@DirectoryList);
		$ScenarioName =~ s/path\_//g;
		$ScenarioName =~ s/\_/ /g;
		my $ScenarioReactions = LoadSingleColumnFile($Filenames[$i],"");
		foreach my $Line (@{$ScenarioReactions}) {
		if ($Line =~ m/(R\d\d\d\d\d)/ || $Line =~ m/(rxn\d\d\d\d\d)/) {
			$ScenarioHash{$ScenarioName}->{$1} = 1;
		}
		}
	}
	}

	$Filename = $self->{"hope scenarios filename"}->[0];
	open (SEEDHOPEANNOTATIONS, ">$Filename");
	print SEEDHOPEANNOTATIONS "SCENARIO\tREACTION\n";
	foreach my $Scenario (keys(%ScenarioHash)) {
	foreach my $Reaction (keys(%{$ScenarioHash{$Scenario}})) {
		print SEEDHOPEANNOTATIONS $Scenario."\t".$Reaction."\n";
	}
	}
	close(SEEDHOPEANNOTATIONS);
}

=head3 UpdateFunctionalRoleMappings
Definition:
	$model->UpdateFunctionalRoleMappings();
Description:
Example:
	$model->UpdateFunctionalRoleMappings();
=cut

sub UpdateFunctionalRoleMappings {
	my($self) = @_;

	#Loading the file listing the functional roles that have been renamed
	my $Data = LoadSingleColumnFile("/vol/seed-anno-mirror/FIG/Data/Logs/functionalroles.rewrite","");
	
	#Building the role name translation hash
	my $RoleTranslation;
	my $TranslatedTo;
	foreach my $Line (@{$Data}) {
		if ($Line =~ m/^Role\s(.+)\swas\sreplaced\sby\s(.+)\s*$/) {
			if (defined($TranslatedTo->{$1})) {
				#$RoleTranslation->{$TranslatedTo->{$1}} = $2;
				#$TranslatedTo->{$2} = $TranslatedTo->{$1};
			} else {
				#$RoleTranslation->{$1} = $2;
				#$TranslatedTo->{$2} = $1;
			}
		}
	}

	my $Count = 0;
	#Loading and adjusting chenry mappings
	my $MappingTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"Chris mapping filename"}->[0],"\t","",0,undef);
	for (my $i=0; $i < $MappingTable->size(); $i++) {
		my $Row = $MappingTable->get_row($i);
		if (defined($Row) && defined($Row->{"ROLE"}->[0]) && defined($RoleTranslation->{$Row->{"ROLE"}->[0]})) {
			$Count++;
			$Row->{"ROLE"}->[0] = $RoleTranslation->{$Row->{"ROLE"}->[0]};
		}
	}
	$MappingTable->save();
	print "Changes: ".$Count."\n";
	$Count = 0;
	#Loading the Hope mappings
	$MappingTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"Hope mapping filename"}->[0],"\t","",0,undef);
	for (my $i=0; $i < $MappingTable->size(); $i++) {
		my $Row = $MappingTable->get_row($i);
		if (defined($Row) && defined($Row->{"ROLE"}->[0]) && defined($RoleTranslation->{$Row->{"ROLE"}->[0]})) {
			$Count++;
			$Row->{"ROLE"}->[0] = $RoleTranslation->{$Row->{"ROLE"}->[0]};
		}
	}
	$MappingTable->save();
	print "Changes: ".$Count."\n";

	$self->CombineRoleReactionMappingSources();
}

=head3 CombineRoleReactionMappingSources
Definition:
	$model->CombineRoleReactionMappingSources();
Description:
Example:
	$model->CombineRoleReactionMappingSources();
=cut

sub CombineRoleReactionMappingSources {
	my($self) = @_;

	#Loading the SEED and Hope mappings
	my %ReactionHash;
	my $Data = &LoadMultipleLabeledColumnFile($self->{"hope and seed subsystems filename"}->[0],"\t","",0);
	for (my $i=0; $i < @{$Data}; $i++) {
	if (defined($Data->[$i]->{"REACTION"}) && defined($Data->[$i]->{"ROLE"}) && defined($Data->[$i]->{"SUBSYSTEM"}) && defined($Data->[$i]->{"SOURCE"})) {
		#Translating the reaction ID
		if ($Data->[$i]->{"REACTION"}->[0] =~ m/(R\d\d\d\d\d)/ || $Data->[$i]->{"REACTION"}->[0] =~ m/(rxn\d\d\d\d\d)/) {
		$Data->[$i]->{"REACTION"}->[0] = $1;
		}
		$Data->[$i]->{"REACTION"}->[0] = $self->id_of_reaction($Data->[$i]->{"REACTION"}->[0]);
		#Checking if the mapping already exists
		if (defined($ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Data->[$i]->{"SUBSYSTEM"}->[0]})) {
		$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Data->[$i]->{"SUBSYSTEM"}->[0]}->{"SOURCE"} .= "|".$Data->[$i]->{"SOURCE"}->[0];
		$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Data->[$i]->{"SUBSYSTEM"}->[0]}->{"MASTER"} = 0;
		} else {
		$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Data->[$i]->{"SUBSYSTEM"}->[0]}->{"SOURCE"} = $Data->[$i]->{"SOURCE"}->[0];
		$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Data->[$i]->{"SUBSYSTEM"}->[0]}->{"MASTER"} = 0;
		}
	}
	}

	#Parsing the file from Matt D.
	print "PARSING MATT D FILE\n\n";
	$Data = FIGMODEL::LoadMultipleColumnFile($self->{"Hope mapping filename"}->[0],"\t");
	for (my $i=1; $i < @{$Data}; $i++) {
	if (defined($Data->[$i]->[0]) && defined($Data->[$i]->[1])) {
		my @Reactions = split(/\s/,$Data->[$i]->[1]);
		for (my $k=0; $k < @Reactions; $k++) {
		my $Reaction = $self->id_of_reaction($Reactions[$k]);
		if ($Data->[$i]->[0] eq "SPONTANEOUS" && $Reaction =~ m/rxn\d\d\d\d\d/) {
			&AddLineToFileUnique($self->{"spontaneous reaction list"}->[0],$Reaction,"");
		} elsif ($Data->[$i]->[0] eq "UNCLEAR" && $Reaction =~ m/rxn\d\d\d\d\d/) {
			&AddLineToFileUnique($self->{"universal open problem reaction list"}->[0],$Reaction,"");
		} elsif ($Data->[$i]->[0] ne "UNCLEAR" && $Data->[$i]->[0] ne "SPONTANEOUS") {
			if (defined($ReactionHash{$Reaction}->{$Data->[$i]->[0]})) {
			my @Subsystems = keys(%{$ReactionHash{$Reaction}->{$Data->[$i]->[0]}});
			my $SubsystemFound = 0;
			for (my $m=0; $m < @Subsystems; $m++) {
				$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{$Subsystems[$m]}->{"SOURCE"} .= "|"."MATT FILE";
				$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{$Subsystems[$m]}->{"MASTER"} = 1;
				if (defined($Data->[$i]->[2]) && $Subsystems[$m] eq $Data->[$i]->[2]) {
				$SubsystemFound = 1;
				}
			}
			if ($SubsystemFound == 0 && defined($Data->[$i]->[2]) && length($Data->[$i]->[2]) > 0 && $Data->[$i]->[2] ne "NONE") {
				$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{$Data->[$i]->[2]}->{"SOURCE"} = "MATT FILE";
				$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{$Data->[$i]->[2]}->{"MASTER"} = 1;
			}
			} elsif (defined($Data->[$i]->[2]) && length($Data->[$i]->[2]) > 0 && $Data->[$i]->[2] ne "NONE") {
			$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{$Data->[$i]->[2]}->{"SOURCE"} = "MATT FILE";
			$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{$Data->[$i]->[2]}->{"MASTER"} = 1;
			} else {
			$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{"NONE"}->{"SOURCE"} = "MATT FILE";
			$ReactionHash{$Reaction}->{$Data->[$i]->[0]}->{"NONE"}->{"MASTER"} = 1;
			}
		}
		}
	}
	}

	#Parsing the file from Matt D.
	print "PARSING CHRIS H FILE\n\n";

	$Data = FIGMODEL::LoadMultipleLabeledColumnFile($self->{"Chris mapping filename"}->[0],"\t","",0);
	for (my $i=0; $i < @{$Data}; $i++) {
		if (defined($Data->[$i]->{"REACTION"}) && defined($Data->[$i]->{"ROLE"}) && defined($Data->[$i]->{"COMPLEX"})) {
			$Data->[$i]->{"REACTION"}->[0] = $self->id_of_reaction($Data->[$i]->{"REACTION"}->[0]);
			#Checking if the mapping already exists
			if (defined($ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]})) {
			my @Subsystems = keys(%{$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}});
			for (my $m=0; $m < @Subsystems; $m++) {
				$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Subsystems[$m]}->{"SOURCE"} .= "|CHRIS FILE";
				if (!defined($ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Subsystems[$m]}->{"MASTER"}) || $ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Subsystems[$m]}->{"MASTER"} == 0) {
				$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Subsystems[$m]}->{"MASTER"} = $Data->[$i]->{"MASTER"}->[0];
				}
				$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{$Subsystems[$m]}->{"COMPLEX"} .= "|".$Data->[$i]->{"COMPLEX"}->[0];
			}
			} else {
			$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{"NONE"}->{"SOURCE"} = "CHRIS FILE";
			$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{"NONE"}->{"MASTER"} = $Data->[$i]->{"MASTER"}->[0];
			$ReactionHash{$Data->[$i]->{"REACTION"}->[0]}->{$Data->[$i]->{"ROLE"}->[0]}->{"NONE"}->{"COMPLEX"} = $Data->[$i]->{"COMPLEX"}->[0];
			}
		}
	}

	#Printing the table to file
	my $Filename = $self->{"Function mapping filename"}->[0];
	open (FUNCTIONOUTPUT, ">$Filename");
	print FUNCTIONOUTPUT "REACTION\tROLE\tSUBSYSTEM\tSOURCE\tCOMPLEX\tMASTER\n";
	my @ReactionList = keys(%ReactionHash);
	my $ComplexIndex = 100000;
	for (my $i=0; $i < @ReactionList; $i++) {
		my @FunctionList = keys(%{$ReactionHash{$ReactionList[$i]}});
		for (my $j=0; $j < @FunctionList; $j++) {
			my @SubsystemList = keys(%{$ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}});
			for (my $k=0; $k < @SubsystemList; $k++) {
				if (!defined($ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}->{$SubsystemList[$k]}->{"COMPLEX"})) {
					$ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}->{$SubsystemList[$k]}->{"COMPLEX"} = $ComplexIndex;
					$ComplexIndex++;
				}
				my @Complexes = split(/\|/,$ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}->{$SubsystemList[$k]}->{"COMPLEX"});
				for (my $m=0; $m < @Complexes; $m++) {
					if (length($Complexes[$m]) > 0) {
						my $Subsystem = $SubsystemList[$k];
						if ($Subsystem ne "NONE" && $self->subsystem_is_valid($Subsystem) == 0) {
							$Subsystem = "NONE";
						}
						print FUNCTIONOUTPUT $ReactionList[$i]."\t".$FunctionList[$j]."\t".$Subsystem."\t";
						print FUNCTIONOUTPUT $ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}->{$SubsystemList[$k]}->{"SOURCE"}."\t".$Complexes[$m]."\t";
						if (defined($ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}->{$SubsystemList[$k]}->{"MASTER"})) {
							print FUNCTIONOUTPUT $ReactionHash{$ReactionList[$i]}->{$FunctionList[$j]}->{$SubsystemList[$k]}->{"MASTER"}."\n";
						} else {
							print FUNCTIONOUTPUT "0\n";
						}
					}
				}
			}
		}
	}

	close(FUNCTIONOUTPUT);
}

=head3 GenerateSubsystemStats
Definition:
	FIGMODELTable:Table of subsystem statistics = $model->GenerateSubsystemStats(hashref:Hash of column headings with hashes of reactions)
Description:
Example:
=cut

sub GenerateSubsystemStats {
	my ($self,$ReactionListHash) = @_;

	my $SubsystemTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["KEY","ID","TYPE","SUBSYSTEM","SUBSYSTEM CLASS 1","SUBSYSTEM CLASS 2"],"",["KEY"],";","|","");

	#Subsystem data will be stored in a hash
	my $SubsystemHash;
	my $Objects = ["SUBSYSTEM","SUBSYSTEM CLASS 1","SUBSYSTEM CLASS 2"];

	my @ColumnNames = keys(%{$ReactionListHash});
	foreach my $Heading (@ColumnNames) {
		#Adding column name to table
		$SubsystemTable->add_headings($Heading);
		#Calculating statistics
		my @ReactionList = keys(%{$ReactionListHash->{$Heading}});
		foreach my $Reaction (@ReactionList) {
			#Getting reaction subsystem from hash
			if (!defined($SubsystemHash->{$Reaction})) {
				#Filling in reaction subsystem data in the subsystem hash
				my $ReactionRow = $self->database()->GetLinkTable("REACTION","SUBSYSTEM")->get_row_by_key($Reaction,"REACTION");
				foreach my $Subsystem (@{$ReactionRow->{"SUBSYSTEM"}}) {
					my $ClassData = $self->class_of_subsystem($Subsystem);
					$Subsystem =~ s/;/,/;
					$ClassData->[0] =~ s/;/,/;
					$ClassData->[1] =~ s/;/,/;
					$SubsystemHash->{$Reaction}->{"SUBSYSTEM"}->{$Subsystem}->{"SUBSYSTEM"}->[0] = $Subsystem;
					$SubsystemHash->{$Reaction}->{"SUBSYSTEM"}->{$Subsystem}->{"SUBSYSTEM CLASS 1"}->[0] = $ClassData->[0];
					$SubsystemHash->{$Reaction}->{"SUBSYSTEM"}->{$Subsystem}->{"SUBSYSTEM CLASS 2"}->[0] = $ClassData->[1];
					push(@{$SubsystemHash->{$Reaction}->{"SUBSYSTEM CLASS 1"}->{$ClassData->[0]}->{"SUBSYSTEM"}},$Subsystem);
					$SubsystemHash->{$Reaction}->{"SUBSYSTEM CLASS 1"}->{$ClassData->[0]}->{"SUBSYSTEM CLASS 1"}->[0] = $ClassData->[0];
					push(@{$SubsystemHash->{$Reaction}->{"SUBSYSTEM CLASS 1"}->{$ClassData->[0]}->{"SUBSYSTEM CLASS 2"}},$ClassData->[1]);
					push(@{$SubsystemHash->{$Reaction}->{"SUBSYSTEM CLASS 2"}->{$ClassData->[1]}->{"SUBSYSTEM"}},$Subsystem);
					push(@{$SubsystemHash->{$Reaction}->{"SUBSYSTEM CLASS 2"}->{$ClassData->[1]}->{"SUBSYSTEM CLASS 1"}},$ClassData->[0]);
					$SubsystemHash->{$Reaction}->{"SUBSYSTEM CLASS 2"}->{$ClassData->[1]}->{"SUBSYSTEM CLASS 2"}->[0] = $ClassData->[1];
				}
			}
			#Adding data to the table
			foreach my $Object (@{$Objects}) {
				foreach my $ObjectID (keys(%{$SubsystemHash->{$Reaction}->{$Object}})) {
					my $ObjectInstance = $SubsystemHash->{$Reaction}->{$Object}->{$ObjectID};
					#Getting row for object from the table
					my $Row = $SubsystemTable->get_row_by_key($ObjectInstance->{$Object}->[0]."-".$Object,"KEY");
					if(!defined($Row)) {
						#Creating table row if it does not already exist
						$Row = {"KEY" => [$ObjectInstance->{$Object}->[0]."-".$Object],"ID" => [$ObjectInstance->{$Object}->[0]],"TYPE" => [$Object],"SUBSYSTEM" => $ObjectInstance->{"SUBSYSTEM"},"SUBSYSTEM CLASS 1" => $ObjectInstance->{"SUBSYSTEM CLASS 1"},"SUBSYSTEM CLASS 2" => $ObjectInstance->{"SUBSYSTEM CLASS 2"}};
						$SubsystemTable->add_row($Row);
					}
					#Updating the statistic in the table
					if (!defined($Row->{$Heading}->[0])) {
						$Row->{$Heading}->[0] = 0
					}
					$Row->{$Heading}->[0] += $ReactionListHash->{$Heading}->{$Reaction};
				}
			}
		}
	}

	return $SubsystemTable;
}

=head2 Public Methods: Perl API for interacting with the MFAToolkit c++ program

=head3 defaultParameters

Definition:
	{string:parameter => string:value} = FIGMODEL->defaultParameters();
Description:
	This function generates the default parameters for FBA

=cut

sub defaultParameters {
	my($self) = @_;
	my $DefaultParameters;
	my @parameters = keys(%{$self->config("default parameters")});
	for (my $i=0; $i < @parameters; $i++) {
		$DefaultParameters->{$parameters[$i]} = $self->config("default parameters")->{$parameters[$i]}->[0];	
	}
	return $DefaultParameters;
}

=head3 GenerateMFAToolkitCommandLineCall

Definition:
	my $CommandLine = $model->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,$MediaName,$PrioritizedParameterFileList,$ParameterValueHash,$OutputLog,$RunType);

Description:
	This function formulates the command line required to call the MFAToolkit with the specified parameters

Example:
	$model->GenerateMFAToolkitCommandLineCall();

=cut

sub GenerateMFAToolkitCommandLineCall {
	my($self,$UniqueFilename,$ModelName,$MediaName,$ParameterFileList,$ParameterValueHash,$OutputLog,$RunType,$Version) = @_;

	#Adding the basic executable to the command line
	my $CommandLine;
	if (defined($RunType) && $RunType eq "QSUB") {
		$CommandLine = $self->{"Qsub MFAToolkit executable"}->[0];
	} else {
		$CommandLine = $self->{"MFAToolkit executable"}->[0];
	}
	if (!defined($Version)) {
		$Version = "";
	}
	$ParameterValueHash->{"Network output location"} = "/scratch/";

	if (defined($ParameterFileList)) {
		#Adding the list of parameter files to the command line
		for (my $i=0; $i < @{$ParameterFileList}; $i++) {
			$CommandLine .= " parameterfile ../Parameters/".$ParameterFileList->[$i].".txt";
		}
	}

	#Dealing with the Media
	if (defined($MediaName) && length($MediaName) > 0 && $MediaName ne "NONE") {
		if ($MediaName eq "Complete" && $ModelName ne "Complete") {
			$CommandLine .= ' resetparameter "Default max drain flux" 10000 resetparameter "user bounds filename" "NoBounds.txt"';
		} elsif ($ModelName ne "Complete") {
			$CommandLine .= ' resetparameter "user bounds filename" "'.$MediaName.'.txt"';
		}
	}

	#Setting the output folder
	if (defined($UniqueFilename) && length($UniqueFilename) > 0) {
		$CommandLine .= ' resetparameter output_folder "'.$UniqueFilename.'/"';
		if (!-d $self->config("MFAToolkit output directory")->[0].$UniqueFilename."/") {
			system("mkdir ".$self->config("MFAToolkit output directory")->[0].$UniqueFilename."/");
		}
	}

	#Adding specific parameter value changes to the parameter list
	if (defined($ParameterValueHash)) {
		my @ChangedParameterNames = keys(%{$ParameterValueHash});
		for (my $i=0; $i < @ChangedParameterNames; $i++) {
			$CommandLine .= ' resetparameter "'.$ChangedParameterNames[$i].'" "'.$ParameterValueHash->{$ChangedParameterNames[$i]}.'"';
		}
	}

	#Completing model filename
	if (defined($ModelName) && $ModelName eq "processdatabase") {
		$CommandLine .= " ProcessDatabase";
	} elsif (defined($ModelName) && $ModelName eq "calculatetransatoms") {
		$CommandLine .= " CalculateTransAtoms";
	} elsif (!defined($ModelName) || length($ModelName) == 0 || $ModelName eq "NONE" || $ModelName eq "Complete") {
		if (defined($Version) && $Version =~ m/bio\d\d\d\d\d/) {
			if ($MediaName eq "Complete") {
				$CommandLine .= ' resetparameter "Default max drain flux" 10000 resetparameter "user bounds filename" "NoBounds.txt"';
				$CommandLine .= ' resetparameter "Max flux" 10000';
				$CommandLine .= ' resetparameter "Min flux" -10000';
			}
			$CommandLine .= ' resetparameter "Complete model biomass reaction" '.$Version;
			$CommandLine .= ' resetparameter "Make all reactions reversible in MFA" 1';
			$CommandLine .= ' resetparameter "dissapproved compartments" "'.$self->{"diapprovied compartments"}->[0].'"';
			$CommandLine .= ' resetparameter "Reactions to knockout" "'.$self->{"permanently knocked out reactions"}->[0].'"';
			$CommandLine .= ' resetparameter "Allowable unbalanced reactions" "'.$self->{"acceptable unbalanced reactions"}->[0].'"';
		}
		$CommandLine .= " LoadCentralSystem Complete";
	} elsif ($ModelName =~ m/\.txt/) {
		$CommandLine .= ' LoadCentralSystem "'.$ModelName.'"';
	} else {
		my $model = $self->get_model($ModelName.$Version);
		$CommandLine .= ' LoadCentralSystem "'.$model->filename().'"';
	}

	#Adding printing of output to a log file to the command line
	if (defined($OutputLog) && length($OutputLog) > 0 && $OutputLog ne "NONE") {
		if ($OutputLog =~ m/^\// || $OutputLog =~ m/^\w:/) {
			$CommandLine .= ' > "'.$OutputLog.'"';
		} else {
			$CommandLine .= ' > "'.$self->{"database message file directory"}->[0].$OutputLog.'"';
		}
	}

	#Dealing with the case where you want to run using qsub or nohup
	if (defined($RunType) && $RunType eq "NOHUP") {
		$CommandLine = "nohup ".$CommandLine." &";
	}
	$self->debug_message({
		function => "GenerateMFAToolkitCommandLineCall",
		message => $CommandLine,
		args => {}
	});
	return $CommandLine;
}

=head3 AdjustReactionDirectionalityInDatabase
Definition:
	success()/fail() = $model->AdjustReactionDirectionalityInDatabase(string::reaction,string::direction);
Description:
=cut
sub AdjustReactionDirectionalityInDatabase {
	my($self,$Reaction,$Direction) = @_;

	#Changing the reaction file
	my $Data = $self->LoadObject($Reaction);
	if (defined($Data->{EQUATION}->[0]) && $Data->{EQUATION}->[0] =~ m//) {
		$Data->{EQUATION}->[0] =~ s//$Direction/;
	}
	$self->SaveObject($Data);
	#Adding the reaction to the forced directionalities in figconfig
	my $data = $self->database()->load_single_column_file($self->config("database root directory")->[0]."ReactionDB/masterfiles/FIGMODELConfig.txt","");
	my $line;
	if ($Direction eq "<=>") {
		$line = "%corrections\\|";
	} elsif ($Direction eq "=>") {
		$line = "%forward\\sonly\\sreactions\\|";
	} elsif ($Direction eq "<=") {
		$line = "%reverse\\sonly\\sreactions\\|";
	}
	for (my $i=0; $i < @{$data}; $i++) {
		if ($data->[$i] =~ m/$line/ && $data->[$i] !~ m/$Reaction/) {
			$data->[$i] .= "|".$Reaction;
		}
	}
	$self->database()->print_array_to_file($self->config("database root directory")->[0]."ReactionDB/masterfiles/FIGMODELConfig.txt",$data);
	#Reseting directionality in the models
	for (my $i=0; $i < $self->number_of_models();$i++) {
		my $model = $self->get_model($i);
		if ($model->source() eq "SEED" || $model->source() eq "RAST" || $model->source() eq "MGRAST") {
			my $rxntbl = $model->reaction_table();
			if (defined($rxntbl)) {
				my $rxnobj = $rxntbl->get_row_by_key($Reaction,"LOAD");
				if (defined($rxnobj)) {
					$rxnobj->{"DIRECTIONALITY"}->[0] = $Direction;
				}
				$self->database()->save_table($rxntbl);
				$model->PrintModelLPFile();
				#Testing model growth
				my $growth = $model->calculate_growth("Complete");
				if ($growth =~ m/NOGROWTH/) {
					#Gapfilling models that donot grow
					print "No growth in ".$model->id().". Rerunning gapfilling!\n";
					$model->GapFillModel(1);
				}
			}
		}
	}
}

=head3 RunFBASimulation
Definition:
	FIGMODELTable = $model->run_fba_study(string::study,reference to array of hash references::study parameters);
Description:
Example:
	$model->RunFBASimulation($ReactionKOSets,$GeneKOSets,$ModelList,$MediaList);
=cut
sub run_fba_study {
	my($self,$Study,$Hash) = @_;

	#Prepping arguments for FBA
	my ($Label,$RunType,$ReactionKOSets,$GeneKOSets,$ModelList,$MediaList);
	for (my $i=0; $i < @{$Hash}; $i++) {
		push(@{$RunType},$Study);
		push(@{$Label},$i);
		if (!defined($Hash->[$i]->{"reactionko"})) {
			push(@{$ReactionKOSets},["none"]);
		} else {
			if (ref($Hash->[$i]->{"reactionko"}) == "ARRAY") {
				push(@{$ReactionKOSets},$Hash->[$i]->{"reactionko"});
			} elsif ($Hash->[$i]->{"reactionko"} =~ m/,/) {
				push(@{$ReactionKOSets},split(/,/,$Hash->[$i]->{"reactionko"}));
			} else {
				push(@{$ReactionKOSets},[$Hash->[$i]->{"reactionko"}]);
			}
		}
		if (!defined($Hash->[$i]->{"geneko"})) {
			push(@{$GeneKOSets},["none"]);
		} else {
			if (ref($Hash->[$i]->{"geneko"}) == "ARRAY") {
				push(@{$GeneKOSets},$Hash->[$i]->{"geneko"});
			} elsif ($Hash->[$i]->{"geneko"} =~ m/,/) {
				push(@{$GeneKOSets},split(/,/,$Hash->[$i]->{"geneko"}));
			} else {
				push(@{$GeneKOSets},[$Hash->[$i]->{"geneko"}]);
			}
		}
		if (!defined($Hash->[$i]->{"media"})) {
			push(@{$MediaList},"Complete");
		} else {
			if (ref($Hash->[$i]->{"media"}) == "ARRAY") {
				push(@{$MediaList},@{$Hash->[$i]->{"media"}});
			} elsif ($Hash->[$i]->{"media"} =~ m/,/) {
				push(@{$MediaList},split(/,/,$Hash->[$i]->{"media"}));
			} else {
				push(@{$MediaList},$Hash->[$i]->{"media"});
			}
		}
		push(@{$ModelList},$Hash->[$i]->{"model"});
	}

	#Running FBA
	my $ResultTable = $self->RunFBASimulation($Label,$RunType,$ReactionKOSets,$GeneKOSets,$ModelList,$MediaList);

	return $ResultTable;
}

=head3 RunFBASimulation
Definition:
	my $ResultTable = $model->RunFBASimulation($ReactionKOSets,$GeneKOSets,$ModelList,$MediaList);
Description:
Example:
	$model->RunFBASimulation($ReactionKOSets,$GeneKOSets,$ModelList,$MediaList);
=cut

sub RunFBASimulation {
	my($self,$Label,$RunType,$ReactionKOSets,$GeneKOSets,$ModelList,$MediaList) = @_;

	if (!defined($ModelList)) {
		print STDERR "FIGMODEL:RunFBASimulation: No model list provided.\n";
	}
	if (!defined($MediaList)) {
		print STDERR "FIGMODEL:RunFBASimulation: No media list provided.\n";
	}
	if (!defined($GeneKOSets)) {
		$GeneKOSets = [["none"]];
	}
	if (!defined($ReactionKOSets)) {
		$ReactionKOSets = [["none"]];
	}
	if (!defined($Label)) {
		$Label = "NONE";
	}
	if (!defined($RunType)) {
		$RunType = "GROWTH";
	}

	my $UniqueFilename = $self->filename();
	my $JobArray = $self->CreateJobTable($UniqueFilename);
	for (my $i=0; $i < @{$ModelList}; $i++) {
		my $model = $self->get_model($ModelList->[$i]);
		if (defined($model)) {
			my $LPFile = $model->directory()."FBA-".$model->id().$model->selected_version();
			my $ModelFile = $model->directory().$model->id().$model->selected_version().".txt";
			#Printing lp and key file for model
			if (!-e $model->directory()."FBA-".$model->id().$model->selected_version().".lp") {
				$model->PrintModelLPFile();
			}
			for (my $j=0; $j < @{$MediaList}; $j++) {
				for (my $k=0; $k < @{$GeneKOSets}; $k++) {
					for (my $m=0; $m < @{$ReactionKOSets}; $m++) {
						$JobArray->add_row({"LABEL" => [$Label],"RUNTYPE" => [$RunType],"LP FILE" => [$LPFile],"MODEL" => [$ModelFile],"MEDIA" => [$MediaList->[$j]],"REACTION KO" => [join(",",@{$ReactionKOSets->[$m]})],"REACTION ADDITION" => ["none"], "GENE KO" => [join(",",@{$GeneKOSets->[$k]})],"SAVE FLUXES" => [1],"SAVE NONESSENTIALS" => [0]});
					}
				}
			}
		} else {
			print STDERR "FIGMODEL:RunFBASimulation: Could not find model ".$model->id().$model->selected_version().".\n";
		}
	}

	#Printing the job file
	if (!-d $self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/") {
		system("mkdir ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/");
	}
	$JobArray->save();

	#Running simulations
	print $self->{"mfalite executable"}->[0]." ".$self->{"Reaction database directory"}->[0]."masterfiles/MediaTable.txt ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Jobfile.txt ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Output.txt\n\n";
	system($self->{"mfalite executable"}->[0]." ".$self->{"Reaction database directory"}->[0]."masterfiles/MediaTable.txt ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Jobfile.txt ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Output.txt");
	#exit;
	my $Results = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Output.txt",";","\\|",0,undef);
	#Getting the entities and types lists
	if (defined($Results)) {
		for (my $i=0; $i < $Results->size(); $i++) {
			my $row = $Results->get_row($i);
			if (defined($row->{MODEL}) && defined($row->{STUDY}) && $row->{STUDY}->[0] eq "GROWTH" && $row->{MODEL}->[0] =~ m/\/([^\/]+)\.txt/) {
				my $modelobj = $self->get_model($1);
				my $key = $self->database()->load_table($modelobj->directory()."FBA-".$modelobj->id().$modelobj->selected_version().".key",";","",0,undef);
				my $types;
				my $entities;
				for (my $j=0; $j < $key->size(); $j++) {
					my $keyrow = $key->get_row($j);
					if ($keyrow->{"Variable type"}->[0] eq "Constraint type") {
						last;
					}
					push(@{$types},$keyrow->{"Variable type"}->[0]);
					push(@{$entities},$keyrow->{"Variable ID"}->[0]);
				}
				$row->{TYPES}->[0] = join(",",@{$types});
				$row->{ENTITIES}->[0] = join(",",@{$entities});
				$Results->add_headings(("TYPES","ENTITIES"));
			}
		}
	}
	$self->cleardirectory($UniqueFilename);

	return $Results;
}

=head3 SimulateIntervalKO
Definition:
	A FIGMODELTable object = $model->SimulateIntervalKO(Reference to a list of strains,Name of a model in the database,Reference to a list of media);
Description:
	This function accepts as arguments a reference to a list of strains or intervals, the name of a model, and a reference to a list of media.
	The function simulates growth of the specified strains in the specified media using the specified model, and every combination of strain and media is simulated.
	The function returns a FIGMODELTable object with these headings: "KEY","ID","GROWTH","MEDIA","MODEL"
	The ID column holds of the strain or interval, the MODEL column has the model name, the GROWTH column
	has an array of growth rates for the strain corresponding to the array of media in the MEDIA column.
	All growth rates are scaled by the growth rate of the wild-type cell (so they all range from 0-1)
Example:
	my $ResultTable = $model->SimulateIntervalKO(["0648","D1D4"],"Seed83333.1",["ArgonneLBMedia","ArgonneNMSMedia","Fabret","Spizizen"]);
=cut

sub SimulateIntervalKO {
	my($self,$StrainList,$Model,$MediaList) = @_;

	#Checking if the model exists
	my $modelObj = $self->get_model($Model);
	if (!defined($modelObj)) {
		return undef;
	}

	my $ModelList = [$Model];
	my $GeneKOSets = [["none"]];
	#Getting the interval and strain tables
	my $IntervalTable = $self->database()->GetDBTable("INTERVAL TABLE");
	my $StrainTable = $self->database()->GetDBTable("STRAIN TABLE");
	#Converting strain list into Gene KO sets
	my $GeneSetsToStrain;
	for (my $i=0; $i < @{$StrainList}; $i++) {
		#Checking if this is a strain
		my $GeneList = $self->genes_of_strain($StrainList->[$i],$modelObj->genome());
		if (defined($GeneList)) {
			@{$GeneList} = sort(@{$GeneList});
			my $GeneSet = join(",",sort(@{$GeneList}));
			if (!defined($GeneSetsToStrain->{$GeneSet})) {
				push(@{$GeneKOSets},$GeneList);
			}
			push(@{$GeneSetsToStrain->{$GeneSet}},$StrainList->[$i]);
		}
	}

	#Running the FBA
	my $ResultsTable = $self->RunFBASimulation("Strain simulation","GROWTH",undef,$GeneKOSets,$ModelList,$MediaList);

	#Locking and loading the simulation data table
	my $TableObj = $self->database()->LockDBTable("STRAIN SIMULATIONS");
	if (!defined($TableObj)) {
		#Creating the output table
		$TableObj = ModelSEED::FIGMODEL::FIGMODELTable->new(["ID","GROWTH","MEDIA","MODEL","TIME"],$self->{"Reaction database directory"}->[0]."intervals/StrainSimulations.txt",["ID","MEDIA","MODEL"]);
	}

	#Finding the wildtype growth
	my $WildTypeGrowth;
	for (my $i=0; $i < $ResultsTable->size(); $i++) {
		my $Row = $ResultsTable->get_row($i);
		if (defined($Row->{"OBJECTIVE"}->[0])) {
			if (!defined($Row->{"KOGENES"}->[0]) || $Row->{"KOGENES"}->[0] eq "none") {
				$WildTypeGrowth->{$Row->{"MEDIA"}->[0]} = $Row->{"OBJECTIVE"}->[0];
			} else {
				my $GeneKOSet = $Row->{"KOGENES"}->[0];
				#Because multiple strains may involve the KO of the same genes
				for (my $i=0; $i < @{$GeneSetsToStrain->{$GeneKOSet}};$i++) {
					my $Strain = $GeneSetsToStrain->{$GeneKOSet}->[$i];
					my $NewRow = $TableObj->get_row_by_key($Strain,"ID",1);
					$TableObj->add_data($NewRow,"MODEL",$Model,1);
					my $Index = $TableObj->add_data($NewRow,"MEDIA",$Row->{"MEDIA"}->[0],1);
					$NewRow->{"GROWTH"}->[$Index] = $Row->{"OBJECTIVE"}->[0];
					$NewRow->{"TIME"}->[$Index] = time();
				}
			}
		}
	}
	my @Media = keys(%{$WildTypeGrowth});
	foreach my $SingleMedia (@Media) {
		if ($WildTypeGrowth->{$SingleMedia} < 1e-5) {
			print STDERR "FIGMODEL:SimulateIntervalKO: Wildtype growth was very low. Strain growth rates not rescaled: ".$WildTypeGrowth.".\n";
			return $TableObj;
		}
	}

	#Rescaling the strain growth by the wildtype growth
	for (my $i=0; $i < $TableObj->size(); $i++) {
		my $Row = $TableObj->get_row($i);
		for (my $j=0; $j < @{$TableObj->get_row($i)->{"GROWTH"}}; $j++) {
			$TableObj->get_row($i)->{"GROWTH"}->[$j] = $TableObj->get_row($i)->{"GROWTH"}->[$j]/$WildTypeGrowth->{$TableObj->get_row($i)->{"MEDIA"}->[$j]};
			if ($TableObj->get_row($i)->{"GROWTH"}->[$j] < 1e-5) {
				$TableObj->get_row($i)->{"GROWTH"}->[$j] = 0;
			}
		}
	}
	$TableObj->save();
	$self->database()->UnlockDBTable("STRAIN SIMULATIONS");

	return $TableObj;
}

=head3 genes_of_strain
Definition:
	string array ref::gene list = FIGMODEL->genes_of_strain(string::interval or strain ID,string::genome);
Description:
=cut

sub genes_of_strain {
	my($self,$Strain,$Genome) = @_;

	#Output will be placed in this reference
	my $GeneList;

	#Loading the interval table
	my $IntervalTable = $self->database()->GetDBTable("INTERVAL TABLE");
	my $StrainTable = $self->database()->GetDBTable("STRAIN TABLE");
	#Checking if this is a strain
	my $Row = $StrainTable->get_row_by_key($Strain,"ID");
	if (defined($Row)) {
		my @ArrayRefList;
		for (my $j=0; $j < @{$Row->{"INTERVALS"}}; $j++) {
			my $NewRow = $IntervalTable->get_row_by_key($Row->{"INTERVALS"}->[$j],"ID");
			if (defined($NewRow)) {
				my $IntervalList = $self->genes_of_interval($NewRow->{"START"}->[0],$NewRow->{"END"}->[0],$Genome);
				if (defined($IntervalList)) {
					push(@ArrayRefList,$IntervalList);
				}
			}
		}
		$GeneList = MergeArraysUnique(@ArrayRefList);
	} else {
		#Checking if this is an interval
		$Row = $IntervalTable->get_row_by_key($Strain,"ID");
		if (defined($Row)) {
			$GeneList = $self->genes_of_interval($Row->{"START"}->[0],$Row->{"END"}->[0],$Genome);
		} else {
			print STDERR "FIGMODEL:SimulateIntervalKO: Could not find input ID in the strain or interval tables: ".$Strain.".\n";
		}
	}

	return $GeneList;
}

=head3 study_unviable_strains
Definition:
	FIGMODELTable::results = $model->study_unviable_strains(string::model);
Description:
	This function loads the table of strain simulation data and attempts to determine why unviable strains are unviable
=cut

sub study_unviable_strains {
	my($self,$Model) = @_;

	#Getting unique filename for this study
	my $UniqueFilename = $self->filename();

	#Checking if the model exists
	my $modelObj = $self->get_model($Model);
	if (!defined($modelObj)) {
		return undef;
	}

	#Loading strain simulation results
	my $SimulationResults = $self->database()->GetDBTable("STRAIN SIMULATIONS");
	$SimulationResults->add_headings(("REACTIONS_DELETED","GENES_DELETED","COESSENTIAL_REACTIONS","RESCUE_MEDIA"));
	#Scaning through simulations and identifying zero growth conditions
	my $ResultHash;
	for (my $i=0; $i < $SimulationResults->size(); $i++) {
		my $Row = $SimulationResults->get_row($i);
		#Scanning through the media conditions
		for (my $j=0; $j < @{$Row->{"GROWTH"}}; $j++) {
			if ($Row->{"GROWTH"}->[$j] eq "0") {
				my $output = $self->diagnose_unviable_strain($Model,$Row->{ID}->[0],$Row->{MEDIA}->[$j]);
				foreach my $key (keys(%{$output})) {
					if ($key eq "REACTIONS_DELETED" || $key eq "GENES_DELETED") {
						$Row->{$key} = $output->{$key};
					} else {
						$Row->{$key}->[$j] = $output->{$key};
					}
				}
			}
		}
	}
	$SimulationResults->save();
}

sub diagnose_unviable_strain {
	my($self,$Model,$strain,$media) = @_;
	#Getting the model
	my $model = $self->get_model($Model);
	if (!defined($model)) {
		return undef;
	}
	#Printing file with list of genes to be knocked out
	my $GeneList = $self->genes_of_strain($strain,$model->genome());
	if (!defined($GeneList)) {
		return undef;
	}
	#Running the mfatoolkit on this single condition
	my $UniqueFilename = $self->filename();
	PrintArrayToFile($self->config("MFAToolkit input files")->[0].$UniqueFilename."-deletion.txt",["ExperimentOne;GENES;".join(";",@{$GeneList})]);
	system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$model->id().$model->selected_version(),$media,["ProductionMFA"],{"find coessential reactions for nonviable deletions" => "1","Force use variables for all reactions" => "1","Reactions use variables" => "1","optimize media when objective is zero" => "1","Add use variables for any drain fluxes" => "1","Force use variables for all drain fluxes" => "1","run deletion experiments" => "1","deletion experiment list file" => "MFAToolkitInputFiles/".$UniqueFilename."-deletion.txt"},"StrainViabilityStudy.txt"));
	if (!-e $self->config("MFAToolkit output directory")->[0].$UniqueFilename."/DeletionStudyResults.txt") {
		$self->error_message("FIGMODEL:diagnose_unviable_strain: Deletion study results data not found!");
		return undef;
	}
	#Loading results
	my $DeletionResultsTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("MFAToolkit output directory")->[0].$UniqueFilename."/DeletionStudyResults.txt",";","|",0,["Experiment"]);
	#Deleting gene list input
	#unlink($self->config("MFAToolkit input files")->[0].$UniqueFilename."-deletion.txt");
	#Clearing MFAToolkit output
	$self->clearing_output($UniqueFilename,"StrainViabilityStudy.txt");
	#Processing output
	my $results;
	if (defined($DeletionResultsTable->get_row(0)->{"Reactions"}->[0])) {
		push(@{$results->{"REACTIONS_DELETED"}},split(/,/,$DeletionResultsTable->get_row(0)->{"Reactions"}->[0]));
	}
	if (defined($DeletionResultsTable->get_row(0)->{"Genes"}->[0])) {
		push(@{$results->{"GENES_DELETED"}},split(/,/,$DeletionResultsTable->get_row(0)->{"Genes"}->[0]));
	}
	if (defined($DeletionResultsTable->get_row(0)->{"Restoring reaction sets"}->[0])) {
		$results->{"COESSENTIAL_REACTIONS"}->[0] = join("/",@{$DeletionResultsTable->get_row(0)->{"Restoring reaction sets"}});
	} else {
		$results->{"COESSENTIAL_REACTIONS"}->[0] = "NONE";
	}
	if (defined($DeletionResultsTable->get_row(0)->{"Additional media required"}->[0]) && $DeletionResultsTable->get_row(0)->{"Additional media required"}->[0] ne "No feasible media formulations") {
		$results->{"RESCUE_MEDIA"}->[0] = join("/",@{$DeletionResultsTable->get_row(0)->{"Additional media required"}});
	} else {
		$results->{"RESCUE_MEDIA"}->[0] = "NONE";
	}
	return $results;
}

=head3 GetEssentialityData
Definition:
	my $EssentialityData = $model->GetEssentialityData($GenomeID);
Description:
	Gets all of the essentiality data for the specified genome.
	Returns undef if no essentiality data is available.
Example:
	my $EssentialityData = $model->GetEssentialityData("83333.1");
=cut

sub GetEssentialityData {
	my($self,$GenomeID) = @_;

	if (!(-e $self->{"experimental data directory"}->[0].$GenomeID."/Essentiality.txt")) {
		return undef;
	}

	if (!defined($self->{"CACHE"}->{"Essentiality_".$GenomeID})) {
		$self->{"CACHE"}->{"Essentiality_".$GenomeID} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"experimental data directory"}->[0].$GenomeID."/Essentiality.txt","\t","",0,["Gene","Media","Essentiality","Source"]);
	}

	return $self->{"CACHE"}->{"Essentiality_".$GenomeID};
}

=head3 ParseBiolog
Definition:
	$model->ParseBiolog();
Description:
Example:
	$model->ParseBiolog();
=cut

sub ParseBiolog {
	my($self) = @_;

	#Loading the current biolog table
	my $BiologDataTable = new ModelSEED::FIGMODEL::FIGMODELTable(["NUTRIENT","SEARCH NAME","NAME","PLATE ID","ORGANISM","GROWTH","SOURCE","MEDIA"],$self->{"Reaction database directory"}->[0]."masterfiles/BiologTable.txt",["NUTRIENT","SEARCH NAME","NAME","PLATE ID","MEDIA"],";","|","");

	#Getting the files with raw biolog data
	my $FileData = LoadSingleColumnFile($self->{"biolog raw data filename"}->[0],"");
	my $CurrentPlate = "";
	my @PlateNames;
	my $Nutrient = "";
	my $Source = "BIOLOG";
	my $Growth = 0;
	my $RowDone = 0;
	my $PlateSet = "";
	my $GenomeID = "";
	my $Data;
	foreach my $Line (@{$FileData}) {
		my @LineArray = split(/\s/,$Line);
		foreach my $LineData (@LineArray) {
			if (length($LineData) > 0) {
				push(@{$Data},$LineData);
			}
		}
	}
	for(my $i=0; $i < @{$Data};$i++) {
		if ($Data->[$i] eq "Carbon" || $Data->[$i] eq "Nitrogen" || $Data->[$i] eq "Sulfate" || $Data->[$i] eq "Phosphate") {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$Nutrient = $Data->[$i];
			}
		} elsif ($Data->[$i] =~ m/^\d+\.\d+$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$GenomeID = $Data->[$i];
			}
		} elsif ($Data->[$i] eq "A00") {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			}
		} elsif ($Data->[$i] =~ m/^(\d[A-Z]\d\d)$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$CurrentPlate = $1;
			}
		} elsif ($Data->[$i] =~ m/^(\d[A-Z])(\d)$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$CurrentPlate = $1."0".$2;
			}
		} elsif ($Data->[$i] =~ m/^([A-Z])(\d)$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$CurrentPlate = $PlateSet.$1."0".$2;
			}
		} elsif ($Data->[$i] =~ m/^([A-Z])(\d\d)$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$CurrentPlate = $PlateSet.$1.$2;
			}
		} elsif ($Data->[$i] =~ m/^(PMID\d+)$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$Source = $1;
			}
		} elsif ($Data->[$i] =~ m/^PM(\d)$/) {
			if ($CurrentPlate ne "" || @PlateNames > 0) {
				$RowDone = 1;
				$i--;
			} else {
				$PlateSet = $1;
			}
		} elsif ($Data->[$i] =~ m/^\+$/) {
			$Growth = 1;
			$RowDone = 1;
		} elsif ($Data->[$i] =~ m/^W$/) {
			$Growth = 0.5;
			$RowDone = 1;
		} elsif ($Data->[$i] =~ m/^-$/) {
			$Growth = 0;
			$RowDone = 1;
		} else {
			my @NewNames = split(/\|/,$Data->[$i]);
			if (@PlateNames > 0) {
				$PlateNames[@PlateNames-1] .= shift(@NewNames);
			}
			push(@PlateNames,@NewNames);
		}
		if ($RowDone == 1) {
			if (@PlateNames == 0 && $CurrentPlate eq "") {
				print STDERR "FIGMODEL:ParseBiolog: row found with no plate name or ID\n";
			} else {
				#Setting the nutrient based on the plate ID
				if ($CurrentPlate ne "") {
					if ($CurrentPlate =~ m/^[12]/) {
						$Nutrient = "Carbon";
					} elsif ($CurrentPlate =~ m/^3/) {
						$Nutrient = "Nitrogen";
					} elsif ($CurrentPlate =~ m/^4[ABCDE]/) {
						$Nutrient = "Phosphate";
					} else {
						$Nutrient = "Sulfate";
					}
				}
				#Checking that the plate has been assigned to a nutrient category
				if ($Nutrient eq "") {
					print STDERR "FIGMODEL:ParseBiolog: row found with no nutrient specification: ".join("|",@PlateNames).": ".$CurrentPlate."\n";
				} else {
					my $AddRow = 1;
					my @SearchNames;
					if ($CurrentPlate ne "") {
						my @MatchingRows = $BiologDataTable->get_rows_by_key($CurrentPlate,"PLATE ID");
						foreach my $Row (@MatchingRows) {
							if ($Row->{"ORGANISM"}->[0] eq $GenomeID) {
								$AddRow = 0;
								if (($Row->{"GROWTH"}->[0] > 0 && $Growth == 0) || ($Row->{"GROWTH"}->[0] == 0 && $Growth > 0)) {
									print STDERR "FIGMODEL:ParseBiolog: Growth mismatch in raw biolog data for plate ".$CurrentPlate.":".$GenomeID.": ".$Row->{"SOURCE"}->[0].":".$Row->{"GROWTH"}->[0]." vs ".$Source.":".$Growth."\n";
								}
							}
							#Checking if there is a plate ID conflict
							foreach my $OtherName (@{$Row->{"SEARCH NAME"}}) {
								my $Match = 0;
								foreach my $CurrentName (@SearchNames) {
									if ($CurrentName eq $OtherName) {
										$Match = 1;
										last;
									}
								}
								if ($Match == 0) {
									push(@SearchNames,$OtherName);
								}
							}
							foreach my $OtherName (@{$Row->{"NAME"}}) {
								my $Match = 0;
								foreach my $CurrentName (@PlateNames) {
									if ($CurrentName eq $OtherName) {
										$Match = 1;
										last;
									}
								}
								if ($Match == 0) {
									push(@PlateNames,$OtherName);
								}
							}
							foreach my $OtherName (@SearchNames) {
								$BiologDataTable->add_data($Row,"SEARCH NAME",$OtherName,1);
							}
							foreach my $OtherName (@PlateNames) {
								$BiologDataTable->add_data($Row,"NAME",$OtherName,1);
							}
						}
					}
					if (@PlateNames > 0) {
						#Handling the search names
						for (my $j=0; $j < @PlateNames; $j++) {
							push(@SearchNames,$self->ConvertToSearchNames($PlateNames[$j]));
						}
						#Data synchronization
						foreach my $Name (@SearchNames) {
							my @MatchingRows = $BiologDataTable->get_rows_by_key($Name,"SEARCH NAME");
							foreach my $Row (@MatchingRows) {
								#Checking that the nutrients match
								if (defined($Row->{"NUTRIENT"}) && $Row->{"NUTRIENT"}->[0] eq $Nutrient) {
									#Checking if there is a plate ID conflict
									my $Error = 0;
									if (defined($Row->{"PLATE ID"}) && $Row->{"PLATE ID"}->[0] ne "") {
										if ($CurrentPlate eq "") {
											$CurrentPlate = $Row->{"PLATE ID"}->[0];
										} elsif ($CurrentPlate ne $Row->{"PLATE ID"}->[0]) {
											print STDERR "FIGMODEL:ParseBiolog: missmatching plate IDs with the same search name: ".$CurrentPlate.":".$Row->{"PLATE ID"}->[0].":".$Name."\n";
											$Error = 1;
										}
									}
									#Adding any names or search names that may be missing
									if ($Error == 0) {
										foreach my $OtherName (@{$Row->{"SEARCH NAME"}}) {
											my $Match = 0;
											foreach my $CurrentName (@SearchNames) {
												if ($CurrentName eq $OtherName) {
													$Match = 1;
													last;
												}
											}
											if ($Match == 0) {
												push(@SearchNames,$OtherName);
											}
										}
										foreach my $OtherName (@{$Row->{"NAME"}}) {
											my $Match = 0;
											foreach my $CurrentName (@PlateNames) {
												if ($CurrentName eq $OtherName) {
													$Match = 1;
													last;
												}
											}
											if ($Match == 0) {
												push(@PlateNames,$OtherName);
											}
										}
										foreach my $OtherName (@SearchNames) {
											$BiologDataTable->add_data($Row,"SEARCH NAME",$OtherName,1);
										}
										foreach my $OtherName (@PlateNames) {
											$BiologDataTable->add_data($Row,"NAME",$OtherName,1);
										}
									}
								}
							}
						}
					}
					my $NameRef;
					my $SearchRef;
					push(@{$NameRef},@PlateNames);
					push(@{$SearchRef},@SearchNames);
					if ($AddRow == 1) {
						$BiologDataTable->add_row({"NUTRIENT" => [$Nutrient],"SEARCH NAME" => $SearchRef,"NAME" => $NameRef,"PLATE ID" => [$CurrentPlate],"ORGANISM" => [$GenomeID],"GROWTH" => [$Growth],"SOURCE" => [$Source]});
					}
				}
			}
			$RowDone = 0;
			@PlateNames = ();
			$CurrentPlate = "";
			$Growth = 0;
		}
	}

	#Lining media up with biolog nutrients
	my $MediaList = $self->GetListOfMedia();
	foreach my $Media (@{$MediaList}) {
		my $Nutrient = "";
		my $Name = "";
		if ($Media =~ m/Carbon-(.+)/) {
			$Nutrient = "Carbon";
			$Name = $1;
		} elsif ($Media =~ m/Nitrogen-(.+)/) {
			$Nutrient = "Nitrogen";
			$Name = $1;
		} elsif ($Media =~ m/Phosphate-(.+)/) {
			$Nutrient = "Phosphate";
			$Name = $1;
		} elsif ($Media =~ m/Sulfate-(.+)/) {
			$Nutrient = "Sulfate";
			$Name = $1;
		}
		if ($Nutrient ne "" && $Name ne "") {
			my @SearchNames = $self->ConvertToSearchNames($Name);
			my $Match = 0;
			for (my $i=0; $i < @SearchNames; $i++) {
				my @MatchingRows = $BiologDataTable->get_rows_by_key($SearchNames[$i],"SEARCH NAME");
				foreach my $Row (@MatchingRows) {
					#Checking that the nutrients match
					if (defined($Row->{"NUTRIENT"}) && $Row->{"NUTRIENT"}->[0] eq $Nutrient) {
						#Checking if there is a media conflict
						if (defined($Row->{"MEDIA"}) && $Row->{"MEDIA"}->[0] ne $Nutrient."-".$Name) {
							print STDERR "FIGMODEL:ParseBiolog: missmatching media IDs with the same search name: ".$Row->{"PLATE ID"}->[0].":".$Row->{"MEDIA"}->[0].":".$Nutrient."-".$Name."\n";
						} else {
							$Row->{"MEDIA"}->[0] = $Nutrient."-".$Name;
							$Match = 1;
							foreach my $OtherName (@SearchNames) {
								$BiologDataTable->add_data($Row,"SEARCH NAME",$OtherName,1);
							}
							$BiologDataTable->add_data($Row,"NAME",$Name,1);
						}
					}
				}
			}
			if ($Match == 0) {
				my $SearchRef;
				push(@{$SearchRef},@SearchNames);
				$BiologDataTable->add_row({"NUTRIENT" => [$Nutrient],"SEARCH NAME" => $SearchRef,"NAME" => [$Name],"MEDIA" => [$Nutrient."-".$Name]});
			}
		}
	}

	#Now we search for compounds to match the biolog names with no corresponding media
	my $MediaArray = LoadSingleColumnFile($self->{"Media directory"}->[0]."Carbon-D-Glucose.txt",";");
	my $CompoundTable = $self->database()->GetDBTable("COMPOUNDS");
	for (my $i=0; $i < $BiologDataTable->size(); $i++) {
		my $Row = $BiologDataTable->get_row($i);
		if (!defined($Row->{"MEDIA"}) || $Row->{"MEDIA"}->[0] eq "") {
			if (defined($Row->{"SEARCH NAME"})) {
				for (my $j=0; $j < @{$Row->{"SEARCH NAME"}}; $j++) {
					my $MatchingRow = $CompoundTable->get_row_by_key($Row->{"SEARCH NAME"}->[$j],"SEARCHNAME");
					if (defined($MatchingRow) && defined($MatchingRow->{"DATABASE"})) {
						$Row->{"MEDIA"}->[0] = $Row->{"NUTRIENT"}->[0]."-".$MatchingRow->{"NAME"}->[0];
						#Creating the media file for this biolog component if it does not already exist
						if (!(-e $self->{"Media directory"}->[0].$Row->{"NUTRIENT"}->[0]."-".$MatchingRow->{"NAME"}->[0].".txt")) {
							my $NewMedia;
							push(@{$NewMedia},@{$MediaArray});
							my $Database = $MatchingRow->{"DATABASE"}->[0];
							if ($Row->{"NUTRIENT"}->[0] eq "Carbon") {
								$NewMedia->[1] =~ s/cpd00027/$Database/;
							} elsif ($Row->{"NUTRIENT"}->[0] eq "Phosphate") {
								$NewMedia->[3] =~ s/cpd00009/$Database/;
							} elsif ($Row->{"NUTRIENT"}->[0] eq "Nitrogen") {
								$NewMedia->[2] =~ s/cpd00013/$Database/;
							} elsif ($Row->{"NUTRIENT"}->[0] eq "Sulfate") {
								$NewMedia->[4] =~ s/cpd00048/$Database/;
							}
							PrintArrayToFile($self->{"Media directory"}->[0].$Row->{"NUTRIENT"}->[0]."-".$MatchingRow->{"NAME"}->[0].".txt",$NewMedia)
						}
						last;
					}
				}
			}
		}
	}

	#Checking if there are still components with no media
	my %BiologComponentsWithNoMedia;
	for (my $i=0; $i < $BiologDataTable->size(); $i++) {
		my $Row = $BiologDataTable->get_row($i);
		if (!defined($Row->{"MEDIA"}) || $Row->{"MEDIA"}->[0] eq "") {
			$BiologComponentsWithNoMedia{$Row->{"NUTRIENT"}->[0]."-".$Row->{"NAME"}->[0]} = 1;
		}
	}
	#print "Biolog media components with no media formulation:\n";
	#print join("\n",keys(%BiologComponentsWithNoMedia))."\n";

	#Printing the culture files for every genome with data
	my %OrganismCultureListHash;
	for (my $i=0; $i < $BiologDataTable->size(); $i++) {
		my $Row = $BiologDataTable->get_row($i);
		if (defined($Row->{"MEDIA"}) && $Row->{"MEDIA"}->[0] ne "" && defined($Row->{"GROWTH"}) && defined($Row->{"SOURCE"}->[0])) {
			push(@{$OrganismCultureListHash{$Row->{"ORGANISM"}->[0]}},$Row->{"MEDIA"}->[0]."\t".$Row->{"GROWTH"}->[0]."\t".$Row->{"SOURCE"}->[0]);
		}
	}
	my @OrganismList = keys(%OrganismCultureListHash);
	for (my $i=0; $i < @OrganismList; $i++) {
		if (!(-d $self->{"experimental data directory"}->[0].$OrganismList[$i]."/")) {
			system("mkdir ".$self->{"experimental data directory"}->[0].$OrganismList[$i]."/");
		}
		my $NewCultureData = ["Media\tGrowth rate\tSource"];
		push(@{$NewCultureData},sort(@{$OrganismCultureListHash{$OrganismList[$i]}}));
		PrintArrayToFile($self->{"experimental data directory"}->[0].$OrganismList[$i]."/CultureConditions.txt",$NewCultureData);
	}

	#Getting the list of biolog compound IDs
	my $CompoundSymporter = new ModelSEED::FIGMODEL::FIGMODELTable(["NUTRIENT","SEARCH NAME","NAME","PLATE ID","ORGANISM","GROWTH","SOURCE","MEDIA"],$self->{"Reaction database directory"}->[0]."masterfiles/BiologTable.txt",["NUTRIENT","SEARCH NAME","NAME","PLATE ID","MEDIA"],";","|","");
	my %CompoundHash;
	for (my $i=0; $i < $BiologDataTable->size(); $i++) {
		my $Row = $BiologDataTable->get_row($i);
		if (defined($Row->{"MEDIA"}) && -e $self->{"Media directory"}->[0].$Row->{"MEDIA"}->[0].".txt") {
			my $MediaTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"Media directory"}->[0].$Row->{"MEDIA"}->[0].".txt",";","",0,["VarName"]);
			if ($Row->{"NUTRIENT"}->[0] eq "Carbon") {
				$CompoundHash{$MediaTable->get_row(0)->{"VarName"}->[0]}->{$Row->{"MEDIA"}->[0]} = 1;
			} elsif ($Row->{"NUTRIENT"}->[0] eq "Nitrogen") {
				$CompoundHash{$MediaTable->get_row(1)->{"VarName"}->[0]}->{$Row->{"MEDIA"}->[0]} = 1;
			} elsif ($Row->{"NUTRIENT"}->[0] eq "Sulfate") {
				$CompoundHash{$MediaTable->get_row(3)->{"VarName"}->[0]}->{$Row->{"MEDIA"}->[0]} = 1;
			} elsif ($Row->{"NUTRIENT"}->[0] eq "Phosphate") {
				$CompoundHash{$MediaTable->get_row(2)->{"VarName"}->[0]}->{$Row->{"MEDIA"}->[0]} = 1;
			}
		}
	}
	#Now checking if a proton sympoter exists for each of the biolog components
	my $BiologTransporterTable = new ModelSEED::FIGMODEL::FIGMODELTable(["COMPOUND","REACTION","MEDIA"],$self->{"Reaction database directory"}->[0]."masterfiles/BiologTransporters.txt",["COMPOUND","REACTION","MEDIA"],";","|","");
	my @CompoundList = keys(%CompoundHash);
	my $ReactionTable = $self->database()->GetDBTable("REACTIONS");
	my @ReactionList;
	for (my $i=0; $i < $ReactionTable->size(); $i++) {
		if ($ReactionTable->get_row($i)->{"DATABASE"}->[0] =~ m/(rxn\d\d\d\d\d)/) {
			push(@ReactionList,$1);
		}
	}
	@ReactionList = sort(@ReactionList);
	my $CurrentRxnID = $ReactionList[@ReactionList-1];
	$CurrentRxnID++;
	foreach my $Compound (@CompoundList) {
		my $Search = $Compound."\\[e\\]";
		my $MediaArray;
		push(@{$MediaArray},keys(%{$CompoundHash{$Compound}}));
		for (my $i=0; $i < $ReactionTable->size(); $i++) {
			if ($ReactionTable->get_row($i)->{"EQUATION"}->[0] =~ m/$Search/i && $ReactionTable->get_row($i)->{"EQUATION"}->[0] =~ m/cpd00067\[e\]/i && $ReactionTable->get_row($i)->{"EQUATION"}->[0] !~ m/\[p\]/i) {
				$BiologTransporterTable->add_row({"COMPOUND" => [$Compound],"REACTION" => [$ReactionTable->get_row($i)->{"DATABASE"}->[0]],"MEDIA" => $MediaArray});
				last;
			}
		}
		if (!defined($BiologTransporterTable->get_row_by_key($Compound,"COMPOUND"))) {
			my $NewObject = ModelSEED::FIGMODEL::FIGMODELObject->new(["DATABASE","NAME","EQUATION","PATHWAY","DELTAG","DELTAGERR","THERMODYNAMIC REVERSIBILITY"],$self->{"reaction directory"}->[0].$CurrentRxnID,"\t");
			my $CompoundRow = $CompoundTable->get_row_by_key($Compound,"DATABASE");
			$NewObject->add_data([$CurrentRxnID],"DATABASE");
			my $TransportType = "symport";
			my $ReactHComp = "[e]";
			my $ProdHComp = "";
			my $HCoeff = "";
			if (defined($CompoundRow->{"CHARGE"}->[0])) {
				if ($CompoundRow->{"CHARGE"}->[0] > 0) {
					$TransportType = "antiport";
					$ReactHComp = "";
					$ProdHComp = "[e]";
				}
				if (abs($CompoundRow->{"CHARGE"}->[0]) > 1) {
					$HCoeff = abs($CompoundRow->{"CHARGE"}->[0])." ";
				}
			}
			$NewObject->add_data([$HCoeff."cpd00067".$ReactHComp." + ".$Compound."[e] <=> ".$Compound." + ".$HCoeff."cpd00067".$ProdHComp],"EQUATION");
			$NewObject->add_data(["Transport"],"PATHWAY");
			$NewObject->add_data(["0"],"DELTAG");
			$NewObject->add_data(["0"],"DELTAGERR");
			$NewObject->add_data(["<=>"],"THERMODYNAMIC REVERSIBILITY");
			if (defined($CompoundRow->{"NAME"}->[0])) {
				$NewObject->add_data([$CompoundRow->{"NAME"}->[0]." transport via proton ".$TransportType],"NAME");
			}
			$NewObject->save();
			$BiologTransporterTable->add_row({"COMPOUND" => [$Compound],"REACTION" => [$CurrentRxnID],"MEDIA" => $MediaArray});
			$CurrentRxnID++;
		}
	}
	$BiologTransporterTable->save();

	#Printing the table to file
	$BiologDataTable->save();
}

=head3 GetCultureData
Definition:
	my $CultureData = $model->GetCultureData($GenomeID);
Description:
	Gets all of the culture data for the specified genome.
	Returns undef if no culture data is available.
Example:
	my $CultureData = $model->GetCultureData("83333.1");
=cut

sub GetCultureData {
	my($self,$GenomeID) = @_;

	if (!(-e $self->{"experimental data directory"}->[0].$GenomeID."/CultureConditions.txt")) {
		return undef;
	}

	if (!defined($self->{"CACHE"}->{"CultureConditions_".$GenomeID})) {
		$self->{"CACHE"}->{"CultureConditions_".$GenomeID} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"experimental data directory"}->[0].$GenomeID."/CultureConditions.txt","\t","",0,["Media"]);
	}

	return $self->{"CACHE"}->{"CultureConditions_".$GenomeID};
}

=head3 GetIntervalEssentialityData
Definition:
	my $IntervalEssentialityData = $model->GetIntervalEssentialityData($GenomeID);
Description:
	Gets all of the interval essentiality data for the specified genome.
	Returns undef if no interval essentiality data is available.
Example:
	my $IntervalEssentialityData = $model->GetIntervalEssentialityData("83333.1");
=cut

sub GetIntervalEssentialityData {
	my($self,$GenomeID) = @_;

	if (!(-e $self->{"experimental data directory"}->[0].$GenomeID."/IntervalEssentiality.txt")) {
		return undef;
	}

	if (!defined($self->{"CACHE"}->{"IntervalEssentiality_".$GenomeID})) {
		$self->{"CACHE"}->{"IntervalEssentiality_".$GenomeID} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"experimental data directory"}->[0].$GenomeID."/IntervalEssentiality.txt","\t","",0,["Media"]);
	}

	return $self->{"CACHE"}->{"IntervalEssentiality_".$GenomeID};
}

=head3 PredictEssentialGenes
Definition:
	my $Results = $model->PredictEssentialGenes($Model,$Media);
Description:
	This function predicts the essential genes in an organism using the specified model in the specified media.
	The function returns a reference to a hash of the predicted essential genes.
	If for some reason the study fails, the function returns undef.
Example:
	my $Results = $model->PredictEssentialGenes("Seed100226.1","ArgonneLBMedia");
=cut

sub PredictEssentialGenes {
	my($self,$ModelName,$Media,$Classify,$Version,$Solver) = @_;

	if (!defined($Solver)) {
		$Solver = "GLPK";
	}
	if (!defined($Version)) {
		$Version = "";
	}

	if (!defined($Media) ||  $Media eq "") {
		$Media = "Complete";
	}

	my $UniqueFilename = $self->filename();
	if (defined($Classify) && $Classify == 1) {
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,$Media,["ProductionMFA"],{"perform single KO experiments" => "1","find tight bounds" => "1","MFASolver" => $Solver},"EssentialityPrediction-".$ModelName.$Version."-".$UniqueFilename.".txt",undef,$Version));
	} else {
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,$Media,["ProductionMFA"],{"perform single KO experiments" => "1","MFASolver" => $Solver},"EssentialityPrediction-".$ModelName.$Version."-".$UniqueFilename.".txt",undef,$Version));
	}

	my $DeletionResultsTable;
	if (-e $self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/DeletionStudyResults.txt") {
		$DeletionResultsTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/DeletionStudyResults.txt",";",",",0,["Experiment"]);
	} else {
		print STDERR "FIGMODEL:PredictEssentialGenes: Deletion study results data not found!\n";
		return undef;
	}

	#If the system is not configured to preserve all logfiles, then the output printout from the mfatoolkit is deleted
	if ($self->{"preserve all log files"}->[0] eq "no") {
		unlink($self->{"database message file directory"}->[0]."EssentialityPrediction-".$ModelName.$Version."-".$UniqueFilename.".txt");
		$self->cleardirectory($UniqueFilename);
	}

	return $DeletionResultsTable;
}

=head3 PredictEssentialIntervals
Definition:
	my $Results = $model->PredictEssentialIntervals($self,$ModelName,$IntervalIDs,$Coordinates,$Growth,$Media,$Classify);
Description:
	This function predicts the essentiality of specified gene intervals in an organism using the specified model in the specified media.
	The function returns a table of the results from the deletion study.
	If for some reason the study fails, the function returns undef.
Example:
	my $Results = $model->PredictEssentialIntervals("Seed100226.1",{"A" => "10000_50000"},"ArgonneLBMedia");
=cut

sub PredictEssentialIntervals {
	my($self,$ModelName,$IntervalIDs,$Coordinates,$Growth,$Media,$Classify,$Version,$Solver) = @_;

	if (!defined($Solver)) {
		$Solver = "";
	}
	if (!defined($Version)) {
		$Version = "";
	}

	if (!defined($Media) ||  $Media eq "") {
		$Media = "Complete";
	}

	#Writing the interval definition file for this media condition
	my $UniqueFilename = $self->filename();
	my $IntervalOutputFilename = $self->{"MFAToolkit input files"}->[0]."Int".$UniqueFilename.".txt";
	if (open (OUTPUT, ">$IntervalOutputFilename")) {
		for (my $j=0; $j < @{$IntervalIDs}; $j++) {
			print OUTPUT $Coordinates->[$j]."\t".$IntervalIDs->[$j]."\t".$Growth->[$j]."\n";
		}
		close(OUTPUT);
	}

	if (defined($Classify) && $Classify == 1) {
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,$Media,["IntervalDeletions"],{"interval experiment list file" => "MFAToolkitInputFiles/Int".$UniqueFilename.".txt","find tight bounds" => "1","MFASolver" => $Solver},"IntervalPrediction-".$ModelName.$Version."-".$UniqueFilename.".txt",undef,$Version));
	} else {
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,$Media,["IntervalDeletions"],{"interval experiment list file" => "MFAToolkitInputFiles/Int".$UniqueFilename.".txt","MFASolver" => $Solver},"IntervalPrediction-".$ModelName.$Version."-".$UniqueFilename.".txt",undef,$Version));
	}
	unlink($IntervalOutputFilename);

	my $DeletionResultsTable;
	if (-e $self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/DeletionStudyResults.txt") {
		$DeletionResultsTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/DeletionStudyResults.txt",";",",",0,["Experiment"]);
	} else {
		print STDERR "FIGMODEL:PredictEssentialGenes: Deletion study results data not found!\n";
		return undef;
	}

	#If the system is not configured to preserve all logfiles, then the output printout from the mfatoolkit is deleted
	if ($self->{"preserve all log files"}->[0] eq "no") {
		unlink($self->{"database message file directory"}->[0]."IntervalPrediction-".$ModelName.$Version."-".$UniqueFilename.".txt");
		$self->cleardirectory($UniqueFilename);
	}
	return $DeletionResultsTable;
}

=head3 RunGeneKOStudy
Definition:
	my $Results = $model->RunGeneKOStudy($Model);
Description:
	This function identifies all of the conditions under which essential genes have been identified experimentally, predicts gene essentiality under those same conditions, then compares the predictions with the experimental data.
Example:
	my $Results = $model->RunGeneKOStudy("Seed83333.1");
=cut

sub RunGeneKOStudy {
	my ($self,$ModelName,$ResultsTable,$Version,$Solver) = @_;

	if (!defined($Solver)) {
		$Solver = "GLPK";
	}

	#Getting organism ID
	if (!defined($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID"))) {
		print STDERR "FIGMODEL:RunGeneKOStudy: Model not found in the database!\n";
		return $ResultsTable;
	}

	#Getting the table of experimentally determined essential genes
	my $ExperimentalEssentialGenes = $self->GetEssentialityData($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"ORGANISM ID"}->[0]);
	if (!defined($ExperimentalEssentialGenes)) {
		print "FIGMODEL:RunGeneKOStudy: No experimental essentiality data found for the specified model!\n";
		return $ResultsTable;
	}

	#Getting the list of media for which essentiality data is available
	my @MediaList = $ExperimentalEssentialGenes->get_hash_column_keys("Media");
	if (@MediaList == 0) {
		print STDERR "FIGMODEL:RunGeneKOStudy: No media conditions found for experimental essentiality data!\n";
		return $ResultsTable;
	}

	#Creating the table object that will store all results of the simulation
	if (!defined($ResultsTable)) {
		$ResultsTable = new ModelSEED::FIGMODEL::FIGMODELTable(["Run result","Experiment type","Media","Experiment ID","Reactions knocked out"],$self->{"database root directory"}->[0].$self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"DIRECTORY"}->[0]."SimultationResults.txt",["Run result","Experiment type"],undef,undef,undef);
	}

	#Predicting essentiality for each of the media conditions with data
	my $ClassificationSettings = 0;
	if (defined($self->{"RUN PARAMETERS"}->{"Classify reactions during simulation"}) && $self->{"RUN PARAMETERS"}->{"Classify reactions during simulation"} == 1) {
		$ClassificationSettings = 1;
	}
	for (my $i=0; $i < @MediaList; $i++) {
		my $EssentialityPredictionTable = $self->PredictEssentialGenes($ModelName,$MediaList[$i],$ClassificationSettings,$Version,$Solver);
		my @MediaEssentialityData = $ExperimentalEssentialGenes->get_rows_by_key($MediaList[$i],"Media");
		foreach my $EssentialityData (@MediaEssentialityData) {
			my $NewRow;
			if (defined($EssentialityData->{"Essentiality"}->[0]) && $EssentialityData->{"Essentiality"}->[0] eq "essential") {
				if (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")) && $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Insilico growth"}->[0] < 0.0000001) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["Correct negative"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} elsif (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment"))) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["False positive"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} else {
					#$NewRow = $ResultsTable->add_row({"Run result" => ["in vivo essential"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => ["NOT IN MODEL"]});
				}
			} elsif (defined($EssentialityData->{"Essentiality"}->[0]) && $EssentialityData->{"Essentiality"}->[0] eq "nonessential") {
				if (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")) && $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Insilico growth"}->[0] < 0.0000001) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["False negative"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} elsif (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment"))) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["Correct positive"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} else {
					#$NewRow = $ResultsTable->add_row({"Run result" => ["in vivo nonessential"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => ["NOT IN MODEL"]});
				}
			} elsif (defined($EssentialityData->{"Essentiality"}->[0]) && $EssentialityData->{"Essentiality"}->[0] eq "undetermined") {
				if (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")) && $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Insilico growth"}->[0] < 0.0000001) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["in silico essential"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} elsif (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment"))) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["in silico nonessential"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} else {
					#$NewRow = $ResultsTable->add_row({"Run result" => ["in vivo undetermined"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => ["NOT IN MODEL"]});
				}
			} elsif (defined($EssentialityData->{"Essentiality"}->[0]) && $EssentialityData->{"Essentiality"}->[0] eq "potentially essential") {
				if (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")) && $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Insilico growth"}->[0] < 0.0000001) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["Potential correct negative"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} elsif (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment"))) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["Potential false positive"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"Reactions"}});
				} else {
					#$NewRow = $ResultsTable->add_row({"Run result" => ["in vivo potential essential"],"Experiment type" => ["Gene KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"Gene"}->[0]],"Reactions knocked out" => ["NOT IN MODEL"]});
				}
			}
			if ($ClassificationSettings == 1 && defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment"))) {
				push(@{$NewRow->{"P"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"P"}});
				push(@{$NewRow->{"N"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"N"}});
				push(@{$NewRow->{"PV"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"PV"}});
				push(@{$NewRow->{"NV"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"NV"}});
				push(@{$NewRow->{"V"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"V"}});
				push(@{$NewRow->{"B"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"Gene"}->[0],"Experiment")->{"B"}});
			}
		}
	}

	return $ResultsTable;
}

=head3 RunIntervalKOStudy

Definition:
	my $ResultsHash = $model->RunIntervalKOStudy($Model);

Description:
	This function uses the MFAToolkit to simulate KO of a set of gene intervals defined in the "Model/ExperimentalData/IntervalKOData.txt" file in the genome directory.
	Here is a sample of what the IntervalKOData.txt file should look like:
	Coordinates ID  Growth  Media
	202112_220019   ?pro1   0.516129032 ArgonneLBMedia
	202112_320277   NED0100 0.419354839 ArgonneLBMedia
	404042_507630   NED0202 0.451612903 ArgonneLBMedia
	...
	On each line, the coordinates of the interval in the genome, the ID for the interval, the growth observed for the in vivo KO, and the media the growth was observed upon should be provided.
	This data should be tab delimited.
	Growth data should be presented as a fraction of wildtype growth. If quantitative data is unavailable, estimates should be provided. In no growth is observed, this column should always equal "0".
	The media should be the exact name of a defined media in the SEED database. To see a list of the defined media, use the "GetMediaList()" function.
	All output from the study are reported in a reference to a hash returned by this function. See the example to find out how data is stored in the output hash.
	DEVELOPER'S NOTE: this function could be easily combined with the RunGeneKOStudy function... this is something to consider in the future.

Example:
	my $ResultsHash = $model->RunIntervalKOStudy("Seed100226.1");
	#Printing the predicted growth for every gene interval simulated
	my @MediaList = keys(%{$ResultsHashRef});
	print "Gene ID;Media;Predicted growth;Experimental growth;Reactions knocked out\n";
	for (my $i=0; $i < @MediaList; $i++) {
	my @IntervalList = keys(%{$ResultsHashRef->{$MediaList[$i]}});
	for (my $k=0; $k < @IntervalList; $k++) {
		print $IntervalList[$k].";".$MediaList[$i].";".$ResultsHashRef->{$MediaList[$i]}->{$IntervalList[$k]}->{"Insilico growth"}.";".$ResultsHashRef->{$MediaList[$i]}->{$IntervalList[$k]}->{"Experiment"}.";".$ResultsHashRef->{$MediaList[$i]}->{$IntervalList[$k]}->{"Reaction KO list"}."\n";
	}
	}

=cut

sub RunIntervalKOStudy {
	my ($self,$ModelName,$ResultsTable,$Version,$Solver) = @_;

	if (!defined($Solver)) {
		$Solver = "GLPK";
	}

	#Getting organism ID
	if (!defined($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID"))) {
		print STDERR "FIGMODEL:RunGeneKOStudy: Model not found in the database!\n";
		return $ResultsTable;
	}

	#Getting the table of experimentally determined essential genes
	my $ExperimentalIntervals = $self->GetIntervalEssentialityData($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"ORGANISM ID"}->[0]);
	if (!defined($ExperimentalIntervals)) {
		print "FIGMODEL:RunGeneKOStudy: No experimental interval essentiality data found for the specified model!\n";
		return $ResultsTable;
	}

	#Getting the list of media for which essentiality data is available
	my @MediaList = $ExperimentalIntervals->get_hash_column_keys("Media");
	if (@MediaList == 0) {
		print STDERR "FIGMODEL:RunIntervalKOStudy: No media conditions found for experimental essentiality data!\n";
		return $ResultsTable;
	}

	#Creating the table object that will store all results of the simulation
	if (!defined($ResultsTable)) {
		$ResultsTable = new ModelSEED::FIGMODEL::FIGMODELTable(["Run result","Experiment type","Media","Experiment ID","Reactions knocked out"],$self->{"database root directory"}->[0].$self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"DIRECTORY"}->[0]."SimultationResults.txt",["Run result","Experiment type"],undef,undef,undef);
	}

	#Predicting essentiality for each of the media conditions with data
	my $ClassificationSettings = 0;
	if (defined($self->{"RUN PARAMETERS"}->{"Classify reactions during simulation"}) && $self->{"RUN PARAMETERS"}->{"Classify reactions during simulation"} == 1) {
		$ClassificationSettings = 1;
	}
	for (my $i=0; $i < @MediaList; $i++) {
		my $IntervalIDs;
		my $Coordinates;
		my $Growth;
		my @MediaEssentialityData = $ExperimentalIntervals->get_rows_by_key($MediaList[$i],"Media");
		foreach my $EssentialityData (@MediaEssentialityData) {
			push(@{$IntervalIDs},$EssentialityData->{"ID"}->[0]);
			push(@{$Coordinates},$EssentialityData->{"Coordinates"}->[0]);
			push(@{$Growth},$EssentialityData->{"Growth rate"}->[0]);
		}
		my $EssentialityPredictionTable = $self->PredictEssentialIntervals($ModelName,$IntervalIDs,$Coordinates,$Growth,$MediaList[$i],$ClassificationSettings,$Version,$Solver);
		foreach my $EssentialityData (@MediaEssentialityData) {
			my $NewRow;
			if (defined($EssentialityData->{"Growth rate"}->[0]) && $EssentialityData->{"Growth rate"}->[0] == 0) {
				if (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")) && $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"Insilico growth"}->[0] < 0.0000001) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["Correct negative"],"Experiment type" => ["Interval KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"Reactions"}});
				} elsif (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment"))) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["False positive"],"Experiment type" => ["Interval KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"Reactions"}});
				} else {
					#$NewRow = $ResultsTable->add_row({"Run result" => ["in vivo essential"],"Experiment type" => ["Interval KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Reactions knocked out" => ["NOT IN MODEL"]});
				}
			} elsif (defined($EssentialityData->{"Growth rate"}->[0]) && $EssentialityData->{"Growth rate"}->[0] > 0) {
				if (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")) && $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"Insilico growth"}->[0] < 0.0000001) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["False negative"],"Experiment type" => ["Interval KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"Reactions"}});
				} elsif (defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment"))) {
					$NewRow = $ResultsTable->add_row({"Run result" => ["Correct positive"],"Experiment type" => ["Interval KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Reactions knocked out" => $EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"Reactions"}});
				} else {
					#$NewRow = $ResultsTable->add_row({"Run result" => ["in vivo nonessential"],"Experiment type" => ["Interval KO"],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Reactions knocked out" => ["NOT IN MODEL"]});
				}
			}
			if ($ClassificationSettings == 1 && defined($EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment"))) {
				push(@{$NewRow->{"P"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"P"}});
				push(@{$NewRow->{"N"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"N"}});
				push(@{$NewRow->{"PV"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"PV"}});
				push(@{$NewRow->{"NV"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"NV"}});
				push(@{$NewRow->{"V"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"V"}});
				push(@{$NewRow->{"B"}},@{$EssentialityPredictionTable->get_row_by_key($EssentialityData->{"ID"}->[0],"Experiment")->{"B"}});
			}
		}
	}

	return $ResultsTable;
}

=head3 RunMediaGrowthStudy

Definition:
	my $ResultsHash = $model->RunMediaGrowthStudy("Seed100226.1");

Description:
	This function uses the MFAToolkit to simulate growth in various media conditions.
	The media conditions simulated must be listed in the file: Model/ExperimentalData/MediaGrowthData.txt with the following format:
	Media name  Growth
	ArgonneNMSMedia 1
	ArgonneLBMedia  1
	Carbon-Glycine  0
	...
	On each line, the name of the media formulation and the experimental growth should be listed delimited by a tab.
	If the cells grow on the media, a 1 should be listed while a 0 should be listed if zero growth is observed.

Example:
	my $ResultsHash = $model->RunMediaGrowthStudy("Seed100226.1");
	#Printing the predicted growth for every media condition simulated
	my @MediaList = keys(%{$ResultsHashRef});
	print "Media;Predicted growth;Experimental growth;Reactions knocked out\n";
	for (my $i=0; $i < @MediaList; $i++) {
	print $MediaList[$i].";".$ResultsHashRef->{$MediaList[$i]}->{"Insilico growth"}.";".$ResultsHashRef->{$MediaList[$i]}->{"Experiment"}."\n";
	}

=cut

sub RunMediaGrowthStudy {
	my ($self,$ModelName,$ResultsTable,$Version,$Solver) = @_;

	if (!defined($Solver)) {
		$Solver = "GLPK";
	}
	if (!defined($Version)) {
		$Version = "";
	}

	#Getting organism ID
	if (!defined($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID"))) {
		print STDERR "FIGMODEL:RunMediaGrowthStudy: Model not found in the database!\n";
		return $ResultsTable;
	}

	#Getting the table of experimentally determined culture conditions
	my $ExperimentCultureConditions = $self->GetCultureData($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"ORGANISM ID"}->[0]);
	if (!defined($ExperimentCultureConditions)) {
		print "FIGMODEL:RunMediaGrowthStudy: No experimental culture data found for the specified model!\n";
		return $ResultsTable;
	}

	#Creating the table object that will store all results of the simulation
	if (!defined($ResultsTable)) {
		$ResultsTable = new ModelSEED::FIGMODEL::FIGMODELTable(["Run result","Experiment type","Media","Experiment ID","Reactions knocked out"],$self->{"database root directory"}->[0].$self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"DIRECTORY"}->[0]."SimultationResults.txt",["Run result","Experiment type"],undef,undef,undef);
	}

	#Simulating culture conditions for which experimental data is available
	my $UniqueFilename = $self->filename();
	my $MediaListOutputFilename = $self->{"Media directory"}->[0]."MediaLists/TestList".$UniqueFilename.".txt";
	if (open (OUTPUT, ">$MediaListOutputFilename")) {
		for (my $i=0; $i < $ExperimentCultureConditions->size(); $i++) {
			#Checking that the media exists
			if (-e $self->{"Media directory"}->[0].$ExperimentCultureConditions->get_row($i)->{"Media"}->[0].".txt") {
				print OUTPUT $ExperimentCultureConditions->get_row($i)->{"Media"}->[0].".txt\n";
			}
		}
		close(OUTPUT);
	}

	#Running the MFAToolkit
	my $ClassificationSettings = 0;
	if (defined($self->{"RUN PARAMETERS"}->{"Classify reactions during simulation"}) && $self->{"RUN PARAMETERS"}->{"Classify reactions during simulation"} == 1) {
		$ClassificationSettings = 1;
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,"ArgonneLBMedia",["ProductionMFA"],{"run media experiments" => "1","media list file" => "MediaLists/TestList".$UniqueFilename.".txt","find tight bounds" => "1","MFASolver" => $Solver},"Media-".$ModelName.$Version."-".$UniqueFilename.".txt",undef,$Version));
	} else {
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelName,"ArgonneLBMedia",["ProductionMFA"],{"run media experiments" => "1","media list file" => "MediaLists/TestList".$UniqueFilename.".txt","MFASolver" => $Solver},"Media-".$ModelName.$Version."-".$UniqueFilename.".txt",undef,$Version));
	}

	#Clearing the temparary media list
	unlink($MediaListOutputFilename);

	#Checking if the problem report exists
	my $MediaStudyResults = $self->LoadProblemReport($UniqueFilename);
	if (!defined($MediaStudyResults)) {
		print STDERR "FIGMODEL:RunMediaGrowthStudy: Media study results data not found!\n";
		return $ResultsTable;
	}

	#Comparing study results with experimental data
	my $Count =0;
	for (my $i=0; $i < $MediaStudyResults->size(); $i++) {
		if (defined($MediaStudyResults->get_row($i)->{"Notes"}) && $MediaStudyResults->get_row($i)->{"Notes"}->[0] =~ m/Media\sexperiment:.+Media\/(.+)\.txt/) {
			my $Media = $1;
			my $NewRow;
			if ($MediaStudyResults->get_row($i)->{"Objective"}->[0] < 0.0000001) {
				if (defined($ExperimentCultureConditions->get_row_by_key($Media,"Media"))) {
					if ($ExperimentCultureConditions->get_row_by_key($Media,"Media")->{"Growth rate"}->[0] > 0) {
						$NewRow = $ResultsTable->add_row({"Run result" => ["False negative"],"Experiment type" => ["Media growth"],"Media" => [$Media],"Experiment ID" => [$Media]});
					} else {
						$NewRow = $ResultsTable->add_row({"Run result" => ["Correct negative"],"Experiment type" => ["Media growth"],"Media" => [$Media],"Experiment ID" => [$Media]});
					}
				} else {
					print STDERR "FIGMODEL:RunMediaGrowthStudy: Experimental media ".$Media." data not found!\n";
				}
			} else {
				if (defined($ExperimentCultureConditions->get_row_by_key($Media,"Media"))) {
					if ($ExperimentCultureConditions->get_row_by_key($Media,"Media")->{"Growth rate"}->[0] > 0) {
						$NewRow = $ResultsTable->add_row({"Run result" => ["Correct positive"],"Experiment type" => ["Media growth"],"Media" => [$Media],"Experiment ID" => [$Media]});
					} else {
						$NewRow = $ResultsTable->add_row({"Run result" => ["False positive"],"Experiment type" => ["Media growth"],"Media" => [$Media],"Experiment ID" => [$Media]});
					}
				} else {
					print STDERR "FIGMODEL:RunMediaGrowthStudy: Experimental media ".$Media." data not found!\n";
				}
			}
			if ($ClassificationSettings == 1) {
				push(@{$NewRow->{"P"}},@{$MediaStudyResults->get_row($i)->{"P"}});
				push(@{$NewRow->{"N"}},@{$MediaStudyResults->get_row($i)->{"N"}});
				push(@{$NewRow->{"PV"}},@{$MediaStudyResults->get_row($i)->{"PV"}});
				push(@{$NewRow->{"NV"}},@{$MediaStudyResults->get_row($i)->{"NV"}});
				push(@{$NewRow->{"V"}},@{$MediaStudyResults->get_row($i)->{"V"}});
				push(@{$NewRow->{"B"}},@{$MediaStudyResults->get_row($i)->{"B"}});
			}
		}
	}

	#If the system is not configured to preserve all logfiles, then the output printout from the mfatoolkit is deleted
	if ($self->{"preserve all log files"}->[0] eq "no") {
		unlink($self->{"database message file directory"}->[0]."Media-".$ModelName.$Version."-".$UniqueFilename.".txt");
		$self->cleardirectory($UniqueFilename);
	}
	return $ResultsTable;
}

=head3 LoadSolution

Definition:
	my $SolutionData = $model->LoadSolution($Filename);

Description:

Example:

=cut

sub LoadSolution {
	my($self,$Filename) = @_;
	my $SolutionData;
	if (-e $self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/SolutionReactionData0.txt") {
	my $Data = LoadSingleColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/SolutionReactionData0.txt","");
	my @TempArray = split(/;/,$Data->[0]);
	for (my $i=0; $i < @TempArray; $i++) {
		if ($TempArray[$i] eq "Objectives:") {
		$SolutionData->{"OBJECTIVE"} = $TempArray[$i+1];
		last;
		}
	}
	$SolutionData->{"REACTIONS"} = LoadMultipleLabeledColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/SolutionReactionData0.txt",";","",1);
	} else {
	print "Solution reaction data not found!\n";
	}
	if (-e $self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/SolutionCompoundData0.txt") {
	$SolutionData->{"COMPOUNDS"} = LoadMultipleLabeledColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/SolutionCompoundData0.txt",";","",1);
	} else {
	print "Solution compound data not found!\n";
	}

	return $SolutionData;
}

=head3 LoadGeneKOResults

Definition:
	my $SolutionData = $model->LoadGeneKOResults($Filename);

Description:

Example:


=cut

sub LoadGeneKOResults {
	my($self,$Filename) = @_;
	#Parsing deletion output file
	if (-e $self->{"MFAToolkit output directory"}->[0].$Filename."/DeletionStudyResults.txt") {
	return LoadMultipleLabeledColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/DeletionStudyResults.txt",";","");
	} else {
	print "Deletion study results data not found!\n";
	}

	return undef;
}

=head3 LoadTightBounds

Definition:
	my $SolutionData = $model->LoadTightBounds($Filename);

Description:

Example:


=cut

sub LoadTightBounds {
	my($self,$Filename) = @_;
	#Parsing reaction tight bounds output file
	my $SolutionData;
	if (-e $self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/TightBoundsReactionData0.txt") {
	my $TightBoundData = FIGMODEL::LoadMultipleLabeledColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/TightBoundsReactionData0.txt",";","");
	for (my $i=1; $i < @{$TightBoundData}; $i++) {
		if (defined($TightBoundData->[$i]->{"DATABASE ID"}) && defined($TightBoundData->[$i]->{"FLUX MIN"}) && defined($TightBoundData->[$i]->{"FLUX MAX"})) {
		my $Class;
		if ($TightBoundData->[$i]->{"FLUX MIN"}->[0] > 0.00000001) {
			$Class = "Positive";
		} elsif ($TightBoundData->[$i]->{"FLUX MAX"}->[0] < -0.00000001) {
			$Class = "Negative";
		} elsif ($TightBoundData->[$i]->{"FLUX MIN"}->[0] < -0.00000001) {
			if ($TightBoundData->[$i]->{"FLUX MAX"}->[0] > 0.00000001) {
			$Class = "Variable";
			} else {
			$Class = "Negative variable";
			}
		} elsif ($TightBoundData->[$i]->{"FLUX MAX"}->[0] > 0.00000001) {
			$Class = "Positive variable";
		} else {
			$Class = "Blocked";
		}
		$SolutionData->{"REACTIONS"}->{$TightBoundData->[$i]->{"DATABASE ID"}->[0]}->{"FLUX MIN"}->[0] = $TightBoundData->[$i]->{"FLUX MIN"}->[0];
		$SolutionData->{"REACTIONS"}->{$TightBoundData->[$i]->{"DATABASE ID"}->[0]}->{"FLUX MAX"}->[0] = $TightBoundData->[$i]->{"FLUX MAX"}->[0];
		$SolutionData->{"REACTIONS"}->{$TightBoundData->[$i]->{"DATABASE ID"}->[0]}->{"CLASS"}->[0] = $Class;
		}
	}
	} else {
	print "Reaction classification data not found!\n";
	}
	if (-e $self->{"MFAToolkit output directory"}->[0].$Filename."/"."MFAOutput/TightBoundsCompoundData0.txt") {
	my $TightBoundData = FIGMODEL::LoadMultipleLabeledColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/TightBoundsCompoundData0.txt",";","");
	print "Compound ID;Class;Minimum uptake;Maximum uptake\n";
	for (my $i=1; $i < @{$TightBoundData}; $i++) {
		if (defined($TightBoundData->[$i]->{"DATABASE ID"}) && defined($TightBoundData->[$i]->{"UPTAKE MIN"}) && defined($TightBoundData->[$i]->{"UPTAKE MAX"})) {
		my $Class;
		if ($TightBoundData->[$i]->{"UPTAKE MIN"}->[0] > 0.00000001) {
			$Class = "Positive";
		} elsif ($TightBoundData->[$i]->{"UPTAKE MAX"}->[0] < -0.00000001) {
			$Class = "Negative";
		} elsif ($TightBoundData->[$i]->{"UPTAKE MIN"}->[0] < -0.00000001) {
			if ($TightBoundData->[$i]->{"UPTAKE MAX"}->[0] > 0.00000001) {
			$Class = "Variable";
			} else {
			$Class = "Negative variable";
			}
		} elsif ($TightBoundData->[$i]->{"UPTAKE MAX"}->[0] > 0.00000001) {
			$Class = "Positive variable";
		} else {
			$Class = "Blocked";
		}
		$SolutionData->{"COMPOUNDS"}->{$TightBoundData->[$i]->{"DATABASE ID"}->[0]}->{"UPTAKE MIN"}->[0] = $TightBoundData->[$i]->{"UPTAKE MIN"}->[0];
		$SolutionData->{"COMPOUNDS"}->{$TightBoundData->[$i]->{"DATABASE ID"}->[0]}->{"UPTAKE MAX"}->[0] = $TightBoundData->[$i]->{"UPTAKE MAX"}->[0];
		$SolutionData->{"COMPOUNDS"}->{$TightBoundData->[$i]->{"DATABASE ID"}->[0]}->{"CLASS"}->[0] = $Class;
		}
	}
	} else {
	print "Nutrient classification data not found!\n";
	}

	return $SolutionData;
}

=head3 LoadReactantOptimization

Definition:
	my $SolutionData = $model->LoadReactantOptimization($Filename);

Description:

Example:


=cut

sub LoadReactantOptimization {
	my($self,$Filename) = @_;
	if (-e $self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/ProblemReports.txt") {
	my $ProblemReportData = FIGMODEL::LoadMultipleLabeledColumnFile($self->{"MFAToolkit output directory"}->[0].$Filename."/MFAOutput/ProblemReports.txt",";","");
	my $ResultString;
	my $SolutionData;
	for (my $i=(@{$ProblemReportData}-1); $i >=0; $i--) {
		if (defined($ProblemReportData->[$i]->{"Individual metablite production"}) && length($ProblemReportData->[$i]->{"Individual metablite production"}->[0]) > 0) {
		$ResultString = $ProblemReportData->[$i]->{"Individual metablite production"}->[0];
		if (defined($ProblemReportData->[$i]->{"Objective"})) {
			$SolutionData->{"OBJECTIVE"} = $ProblemReportData->[$i]->{"Objective"}->[0];
		}
		last;
		}
	}
	if (length($ResultString) == 0) {
		print "Deletion study results data not found!\n";
		return undef;
	} else {
		my @CompoundResults = split(/\|/,$ResultString);
		foreach my $Compound (@CompoundResults) {
		my @TempArray = split(/:/,$Compound);
		$SolutionData->{$TempArray[0]} = $TempArray[1];
		}
	}
	} else {
	print "Deletion study results data not found!\n";
	}

	return undef;
}

=head3 RunAllStudiesWithData
Definition:
	($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$ErrorVector,$HeadingVector) = $model->RunAllStudiesWithData($Model,$Experiment);
Description:
	This script uses the MFAToolkit to run every simulation for which data is available in the "Model/ExperimentalData/" directory.
	The simulations run depend on the specified experiment. Four values for $Experiment are recognized:
	1.) GeneKO: runs the gene KO experiment
	2.) IntKO: runs the interval KO experiment
	3.) Media: simulates growth on various media
	4.) All: runs all of the above.
	This function uses the RunMediaGrowthStudy, RunIntervalKOStudy, and RunGeneKOStudy functions.
	The difference is, this function compares the experiment and predicted results and returns information on how many errors occur.
	Six elements of data are returned:
	1.) $FalsePositives: the number of cases where growth was predicted in simulation by no growth was observed experimentally
	2.) $FalseNegatives: the number of cases where growth was not predicted in simulation but growth was observed experimentally.
	3.) $CorrectNegatives: the number of correct predictions of zero growth.
	4.) $CorrectPositives: the number of correct predictions of nonzero growth.
	5.) $ErrorVector: a string represented ";" delimited vector where each element indicates the result of simulation of a single experimental condition: 0 for correct positive, 1 for correct negative, 2 for false positive, 3 for false negative.
	DEVELOPER'S NOTE: these numbers will ultimately be replaced with strings for better clarity.
	6.) $HeadingVector: a string represented ";" delimited vector where each element describes the simulation performed to obtain the results listed for the corresponding element in the $ErrorVector.
	Each element in $HeadingVector contains 4 peices of information delimited by a ":":
	1.) Experiment type
	2.) Media
	3.) Experiment ID
	4.) reactions knocked out
Example:
	($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$ErrorVector,$HeadingVector) = $model->RunAllStudiesWithData($Model,$Experiment);
=cut

sub RunAllStudiesWithData {
	 my ($self,$ModelName,$Experiment,$PrintResults,$Version,$Solver) = @_;

	my $modelObj = $self->get_model($ModelName);
	if (!defined($modelObj)) {
		print STDERR "FIGMODEL:RunAllStudiesWithData: Could not find model ".$ModelName.".\n";
		return 0;
	}
	if (!defined($Version)) {
		$Version = "";
		if (defined($modelObj->version())) {
			$Version = $modelObj->version();
		}
	}
	my $Directory = $modelObj->directory();
	$ModelName = $modelObj->id();

	if (!defined($Solver)) {
		$Solver = "GLPK";
	}

	#Checking if the model exists in the database
	if (!defined($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID"))) {
		if (!defined($Version) && $ModelName =~ m/(.+)(V.+)/) {
			$ModelName = $1;
			$Version = $2;
			if (!defined($self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID"))) {
				print STDERR "FIGMODEL:RunAllStudiesWithData: Could not find ".$ModelName.$Version." in model database!\n";
				return 0;
			}
		} else {
			print STDERR "FIGMODEL:RunAllStudiesWithData: Could not find ".$ModelName." in model database!\n";
			return 0;
		}
	}

	#Setting the result printing
	if (!defined($PrintResults)) {
		$PrintResults = 1;
	}

	#All results will be stored in the following structures
	my $FalsePostives = 0;
	my $FalseNegatives = 0;
	my $CorrectNegatives = 0;
	my $CorrectPositives = 0;
	my @Errorvector;
	my @HeadingVector;
	my $ResultsTable = new ModelSEED::FIGMODEL::FIGMODELTable(["Run result","Experiment type","Media","Experiment ID","Reactions knocked out"],$self->{"database root directory"}->[0].$self->database()->GetDBTable("MODEL LIST")->get_row_by_key($ModelName,"MODEL ID")->{"DIRECTORY"}->[0]."SimultationResults.txt",["Run result","Experiment type"],undef,undef,undef);

	#Running gene KO studies
	if ($Experiment eq "GeneKO" || $Experiment eq "All") {
		$ResultsTable = $self->RunGeneKOStudy($ModelName,$ResultsTable,$Version,$Solver);
	}
	if ($Experiment eq "IntKO" || $Experiment eq "All") {
		$ResultsTable = $self->RunIntervalKOStudy($ModelName,$ResultsTable,$Version,$Solver);
	}
	if ($Experiment eq "Media" || $Experiment eq "All") {
		$ResultsTable = $self->RunMediaGrowthStudy($ModelName,$ResultsTable,$Version,$Solver);
	}

	#Counting false negatives and false positives and loading the error matrix
	for (my $i=0; $i < $ResultsTable->size(); $i++) {
		my $ReactionString = "none";
		if (defined($ResultsTable->get_row($i)->{"Reactions knocked out"}->[0])) {
			$ReactionString = join(",",@{$ResultsTable->get_row($i)->{"Reactions knocked out"}});
		}
		push(@HeadingVector,$ResultsTable->get_row($i)->{"Experiment type"}->[0].":".$ResultsTable->get_row($i)->{"Media"}->[0].":".$ResultsTable->get_row($i)->{"Experiment ID"}->[0].":".$ReactionString);
		if ($ResultsTable->get_row($i)->{"Run result"}->[0] =~ m/alse\snegative/) {
			$FalseNegatives++;
			push(@Errorvector,"3");
		} elsif ($ResultsTable->get_row($i)->{"Run result"}->[0] =~ m/orrect\snegative/) {
			$CorrectNegatives++;
			push(@Errorvector,"1");
		} if ($ResultsTable->get_row($i)->{"Run result"}->[0] =~ m/alse\spositive/) {
			$FalsePostives++;
			push(@Errorvector,"2");
		} elsif ($ResultsTable->get_row($i)->{"Run result"}->[0] =~ m/orrect\spositive/) {
			$CorrectPositives++;
			push(@Errorvector,"0");
		}
		my @Classes = ("P","N","V","PV","NV","B");
		for (my $k = 0; $k < @Classes; $k++) {
			if (defined($ResultsTable->get_row($i)->{$Classes[$k]})) {
				foreach my $ReactionID (@{$ResultsTable->get_row($i)->{$Classes[$k]}}) {
					if (defined($self->{"Simulation classification results"}->{$ReactionID}->{$Classes[$k]})) {
						$self->{"Simulation classification results"}->{$ReactionID}->{$Classes[$k]}++;
					} else {
						$self->{"Simulation classification results"}->{$ReactionID}->{$Classes[$k]} = 1;
					}
				}
			}
		}
	}

	#Printing results to file
	if ($PrintResults == 1) {
		my $OutputFilename = $Directory."SimulationOutput".$ModelName.$Version.".txt";
		$ResultsTable->save($OutputFilename,"\t",",","False negatives\tFalse positives\tCorrect negatives\tCorrect positives\n".$FalseNegatives."\t".$FalsePostives."\t".$CorrectNegatives."\t".$CorrectPositives."\n");
	}

	return ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,join(";",@Errorvector),join(";",@HeadingVector));
}

=head3 GetExperimentalDataTable
Definition:
	my $DataTable = GetExperimentalDataTable($Genome,$Experiment);
Description:
Example:
	my $DataTable = GetExperimentalDataTable($Genome,$Experiment);
=cut

sub GetExperimentalDataTable {
	my ($self,$GenomeID,$Experiment) = @_;

	#Specifying gene KO simulations
	my $ExperimentalDataTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["Heading","Experiment type","Media","Experiment ID","Growth"],"Temp.txt",["Heading"],";",",",undef);
	if ($Experiment eq "GeneKO" || $Experiment eq "All") {
		#Getting the table of experimentally determined essential genes
		my $ExperimentalEssentialGenes = $self->GetEssentialityData($GenomeID);
		if (!defined($ExperimentalEssentialGenes)) {
			print "FIGMODEL:RunGeneKOStudy: No experimental essentiality data found for the specified model!\n";
		} else {
			#Getting the list of media for which essentiality data is available
			my @MediaList = $ExperimentalEssentialGenes->get_hash_column_keys("Media");
			if (@MediaList == 0) {
				print STDERR "FIGMODEL:RunGeneKOStudy: No media conditions found for experimental essentiality data!\n";
			}
			#Populating the experimental data table
			for (my $i=0; $i < $ExperimentalEssentialGenes->size(); $i++) {
				if ($ExperimentalEssentialGenes->get_row($i)->{"Essentiality"}->[0] eq "essential") {
					$ExperimentalDataTable->add_row({"Heading" => ["Gene KO:".$ExperimentalEssentialGenes->get_row($i)->{"Media"}->[0].":".$ExperimentalEssentialGenes->get_row($i)->{"Gene"}->[0]],"Experiment type" => ["Gene KO"],"Media" => [$ExperimentalEssentialGenes->get_row($i)->{"Media"}->[0]],"Experiment ID" => [$ExperimentalEssentialGenes->get_row($i)->{"Gene"}->[0]],"Growth" => [0]});
				} elsif ($ExperimentalEssentialGenes->get_row($i)->{"Essentiality"}->[0] eq "nonessential") {
					$ExperimentalDataTable->add_row({"Heading" => ["Gene KO:".$ExperimentalEssentialGenes->get_row($i)->{"Media"}->[0].":".$ExperimentalEssentialGenes->get_row($i)->{"Gene"}->[0]],"Experiment type" => ["Gene KO"],"Media" => [$ExperimentalEssentialGenes->get_row($i)->{"Media"}->[0]],"Experiment ID" => [$ExperimentalEssentialGenes->get_row($i)->{"Gene"}->[0]],"Growth" => [1]});
				}
			}
		}
	}

	#Specifying media simulations
	if ($Experiment eq "Media" || $Experiment eq "All") {
		my $ExperimentCultureConditions = $self->GetCultureData($GenomeID);
		if (!defined($ExperimentCultureConditions)) {
			print "FIGMODEL:RunMediaGrowthStudy: No experimental culture data found for the specified model!\n";
		} else {
			my @MediaList;
			for (my $i=0; $i < $ExperimentCultureConditions->size(); $i++) {
				if (-e $self->{"Media directory"}->[0].$ExperimentCultureConditions->get_row($i)->{"Media"}->[0].".txt") {
					push(@MediaList,$ExperimentCultureConditions->get_row($i)->{"Media"}->[0]);
					$ExperimentalDataTable->add_row({"Heading" => ["Media growth:".$ExperimentCultureConditions->get_row($i)->{"Media"}->[0].":".$ExperimentCultureConditions->get_row($i)->{"Media"}->[0]],"Experiment type" => ["Media growth"],"Media" => [$ExperimentCultureConditions->get_row($i)->{"Media"}->[0]],"Experiment ID" => [$ExperimentCultureConditions->get_row($i)->{"Media"}->[0]],"Growth" => [$ExperimentCultureConditions->get_row($i)->{"Growth rate"}->[0]]});
				}
			}
		}
	}

	#Specifying interval KO simulations
	if ($Experiment eq "IntKO" || $Experiment eq "All") {
		#Getting the table of experimentally determined essential genes
		my $ExperimentalIntervals = $self->GetIntervalEssentialityData($GenomeID);
		if (!defined($ExperimentalIntervals)) {
			print "FIGMODEL:RunGeneKOStudy: No experimental interval essentiality data found for the specified model!\n";
		} else {
			my @MediaList = $ExperimentalIntervals->get_hash_column_keys("Media");
			if (@MediaList == 0) {
				print STDERR "FIGMODEL:RunIntervalKOStudy: No media conditions found for experimental essentiality data!\n";
			}
			#Getting gene list
			my $GeneTable = $self->GetGenomeFeatureTable($GenomeID);
			for (my $i=0; $i < @MediaList; $i++) {
				my @Rows = $ExperimentalIntervals->get_rows_by_key($MediaList[$i],"Media");
				foreach my $EssentialityData (@Rows) {
					my @Temp = split(/_/,$EssentialityData->{"Coordinates"}->[0]);
					if (@Temp >= 2) {
						#Determining gene KO from interval coordinates
						my $GeneKOSets = "";
						for (my $j=0; $j < $GeneTable->size(); $j++) {
							my $Row = $GeneTable->get_row($j);
							if ($Row->{"MIN LOCATION"}->[0] < $Temp[1] && $Row->{"MAX LOCATION"}->[0] > $Temp[0]) {
								if ($Row->{"ID"}->[0] =~ m/(peg\.\d+)/) {
									if (length($GeneKOSets) > 0) {
										$GeneKOSets = $GeneKOSets.",";
									}
									$GeneKOSets = $GeneKOSets.$1;
								}
							}
						}
						#Adding row to table of experimental data
						$ExperimentalDataTable->add_row({"Heading" => ["Interval KO:".$MediaList[$i].":".$EssentialityData->{"ID"}->[0]],"Experiment type" => [$GeneKOSets],"Media" => [$MediaList[$i]],"Experiment ID" => [$EssentialityData->{"ID"}->[0]],"Growth" => [$EssentialityData->{"Growth rate"}->[0]]});
					}
				}
			}
		}
	}

	return $ExperimentalDataTable;
}

=head3 GenerateJobFileLine
Definition:
	FIGMODELTable row::Job file row = $model->GenerateJobFileLine(string::Label,string::Model ID,string arrayref::Media list,string::Run type,0 or 1::Save fluxes,0 or 1::Save nonessential gene list);
Description:
Example:
=cut

sub GenerateJobFileLine {
	my ($self,$Label,$ModelID,$MediaList,$RunType,$SaveFluxes,$SaveNoness) = @_;

	my $modelObj = $self->get_model($ModelID);
	if (!defined($modelObj) || !-e $modelObj->directory().$ModelID.".txt" || !-e $modelObj->directory()."FBA-".$ModelID.".lp" || !-e $modelObj->directory()."FBA-".$ModelID.".key") {
		print STDERR "FIGMODEL:GenerateJobFileLine: Could not load ".$ModelID."\n";
		return undef;
	}

	return {"LABEL" => [$Label],"RUNTYPE" => [$RunType],"MEDIA" => [join("|",@{$MediaList})],"MODEL" => [$modelObj->directory().$ModelID.".txt"],"LP FILE" => [$modelObj->directory()."FBA-".$ModelID],"SAVE FLUXES" => [$SaveFluxes],"SAVE NONESSENTIALS" => [$SaveNoness]};
}

=head2 Marvin Beans Interaction Functions

=head3 add_pk_data_to_compound
Definition:
	int::status = FIGMODEL->add_pk_data_to_compound(string::ID || [string]::ID);
Description:
	Adds PkA and PkB data to compounds in database using marvin beans software
	Returns FIGMODEL status messages.
	Molfile must be available for compound
=cut

sub add_pk_data_to_compound {
	my ($self,$id,$save) = @_;

	#Checking if id is array or string
	if (ref($id) eq 'ARRAY') {
		for (my $i=0; $i < @{$id}; $i++) {
			$self->add_pk_data_to_compound($id->[$i]);
		}
		return $self->config("SUCCESS")->[0];
	#You have the option of specifying the id "ALL" and having this function process the whole database
	} elsif ($id eq "ALL") {
		my $List;
		my $CompoundTable = $self->database()->GetDBTable("COMPOUNDS");
		for (my $i=0; $i < $CompoundTable->size(); $i++) {
			push(@{$List},$CompoundTable->get_row($i)->{"DATABASE"}->[0]);
		}
		$self->add_pk_data_to_compound($List);
	}

	#Trying to get compound data from database
	my $data = $self->database()->get_row_by_key("COMPOUNDS",$id,"DATABASE");;
	if (!defined($data)) {
		print STDERR "FIGMODEL:add_pk_data_to_compound:Could not load ".$id." from database\n";
		return $self->config("FAIL")->[0];
	}

	#Checking that a molfile is available for compound
	if (!-e $self->config("Argonne molfile directory")->[0].$id.".mol") {
		print STDERR "FIGMODEL:add_pk_data_to_compound:Molfile not found for ".$id."\n";
		return $self->config("FAIL")->[0];
	}

	#Running marvin
	print STDOUT "Now processing ".$id."\n";
	system($self->config("marvinbeans executable")->[0].' '.$self->config("Argonne molfile directory")->[0].$id.".mol".' -i ID pka -a 6 -b 6 > '.$self->config("temp file directory")->[0].'pk'.$id.'.txt');

	#Checking that output file was generated
	if (!-e $self->config("temp file directory")->[0].'pk'.$id.'.txt') {
		print STDERR "FIGMODEL:add_pk_data_to_compound:Marvinbeans output file not generated for ".$id."\n";
		return $self->config("FAIL")->[0];
	}

	#Parsing output file and placing data in compound object
	my $pkdata = LoadMultipleColumnFile($self->config("temp file directory")->[0].'pk'.$id.'.txt',"\t");
	if (defined($pkdata->[1]) && defined($pkdata->[1]->[13])) {
		#print "SUCCESS!\n";
		my $CompoundObject = FIGMODELObject->load($self->config("compound directory")->[0].$id,"\t");
		delete $CompoundObject->{"PKA"};
		delete $CompoundObject->{"PKB"};
		my @Atoms = split(",",$pkdata->[1]->[13]);
		my $Count = 0;
		for (my $j=0; $j < 6; $j++) {
			if (defined($pkdata->[1]->[1+$j]) && length($pkdata->[1]->[1+$j]) > 0) {
				$CompoundObject->add_headings("PKA");
				$CompoundObject->add_data([$pkdata->[1]->[1+$j].":".$Atoms[$Count]],"PKA",1);
				#print "pKa:".$pkdata->[1]->[1+$j].":".$Atoms[$Count]."\n";
				$Count++;
			}
		}
		for (my $j=0; $j < 6; $j++) {
			if (defined($pkdata->[1]->[7+$j]) && length($pkdata->[1]->[7+$j]) > 0) {
				$CompoundObject->add_headings("PKB");
				$CompoundObject->add_data([$pkdata->[1]->[7+$j].":".$Atoms[$Count]],"PKB",1);
				#print "pKb:".$pkdata->[1]->[7+$j].":".$Atoms[$Count]."\n";
				$Count++;
			}
		}
		$CompoundObject->save();
	}
	unlink($self->config("temp file directory")->[0].'pk'.$id.'.txt');
}

=head3 classify_database_reactions
Definition:
	(FIGMODELTable::Compound table,FIGMODELTable::Reaction table) = FIGMODEL->classify_database_reactions(string::media);
=cut

sub classify_database_reactions {
	my ($self,$media,$biomassrxn) = @_;

	my $CompoundTB;
	my $ReactionTB;
	my $UniqueFilename = $self->filename();
	system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,"Complete",$media,["ProductionCompleteClassification"],{"find tight bounds" => 1,"Make all reactions reversible in MFA"=>1,"MFASolver" => "CPLEX","Complete model biomass reaction" => $biomassrxn},"Classify-Complete-".$UniqueFilename.".log",undef,""));
	if (-e $self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/"."MFAOutput/TightBoundsReactionData0.txt") {
		$ReactionTB = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/MFAOutput/TightBoundsReactionData0.txt",";","|",1,["DATABASE ID"]);
		my $inactiveRxn;
		for (my $i=0; $i < $ReactionTB->size(); $i++) {
			my $row = $ReactionTB->get_row($i);
			if ($row->{"Max FLUX"}->[0] < 0.0000001 && $row->{"Min FLUX"}->[0] > -0.0000001) {
				push(@{$inactiveRxn},$row->{"DATABASE ID"}->[0]);
			}
		}
		$self->database()->print_array_to_file("/home/chenry/DBInactiveReactions.txt",$inactiveRxn);
	}
	if (-e $self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/"."MFAOutput/TightBoundsCompoundData0.txt") {
		$CompoundTB = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/MFAOutput/TightBoundsCompoundData0.txt",";","|",1,["DATABASE ID"]);
	}
	$self->clearing_output($UniqueFilename,"Classify-Complete-".$UniqueFilename.".log");
	return ($CompoundTB,$ReactionTB);
}

=head3 determine_biomass_essential_reactions
Definition:
	(success/fail) = FIGMODEL->determine_biomass_essential_reactions(string::biomass);
=cut

sub determine_biomass_essential_reactions {
	my ($self,$biomassID) = @_;
	my $bioMgr = $self->database()->get_object_manager("bof");
	my $bioObj = $bioMgr->get_objects({id=>$biomassID});
	if (defined($bioObj->[0])) {
		my ($CompoundTB,$ReactionTB) = $self->classify_database_reactions("Complete",$biomassID);
		my $EssentialReactions;
		if (!defined($ReactionTB)) {
			$self->error_message("BuildSpecificBiomassReaction:".$biomassID." biomass reaction would not grow in complete database and complete media!");
			$bioObj->[0]->essentialRxn("NONE");
		} else {
			for (my $i=0; $i < $ReactionTB->size(); $i++) {
				my $Row = $ReactionTB->get_row($i);
				if ($Row->{"Max FLUX"}->[0] < -0.0000001 || $Row->{"Min FLUX"}->[0] > 0.0000001) {
					push(@{$EssentialReactions},$Row->{"DATABASE ID"}->[0]);
				}
			}
			my $essentialRxn = join("|",@{$EssentialReactions});
			$essentialRxn =~ s/\|bio\d\d\d\d\d//g;
			$bioObj->[0]->essentialRxn($essentialRxn);
		}
	}
}

=head3 PrintDatabaseLPFiles
Definition:
	$model->PrintDatabaseLPFiles();
Description:
	This algorithm prints LP files formulating various FBA algorithms on the entire database. This includes:
	1.) An LP file for standard fba on complete media with bounds of 100.
	2.) An LP file for gapfilling with use variables on complete media with bounds of 10000.
	3.) A TMFA LP on complete medai with bounds of 100.
	These LP files are used to do very fast database minimal fba using our mpifba code.
Example:
	$model->PrintDatabaseLPFiles();
=cut

sub PrintDatabaseLPFiles {
	my ($self) = @_;

	#Printing the standard FBA file
	system($self->GenerateMFAToolkitCommandLineCall("DatabaseProcessing","Complete","NoBounds",["ProdFullFBALP"],undef,"FBA_LP_Printing.log",undef,undef));
	system("cp ".$self->{"MFAToolkit output directory"}->[0]."DatabaseProcessing/CurrentProblem.lp ".$self->{"Reaction database directory"}->[0]."masterfiles/FBA.lp");
	#The variable keys are too large for distribution in parallel, so we load them and only save the portions with the data we need
	my $KeyTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0]."DatabaseProcessing/VariableKey.txt",";","|",0,undef);
	$KeyTable->headings(["Variable type","Variable ID"]);
	$KeyTable->save($self->{"Reaction database directory"}->[0]."masterfiles/FBA.key");

	#Printing the gap filling FBA file
	system($self->GenerateMFAToolkitCommandLineCall("DatabaseProcessing","Complete","NoBounds",["ProdFullGapFillingLP"],undef,"GapFill_LP_Printing.log",undef,undef));
	system("cp ".$self->{"MFAToolkit output directory"}->[0]."DatabaseProcessing/CurrentProblem.lp ".$self->{"Reaction database directory"}->[0]."masterfiles/GapFill.lp");
	$KeyTable = undef;
	$KeyTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0]."DatabaseProcessing/VariableKey.txt",";","|",0,undef);
	$KeyTable->headings(["Variable type","Variable ID"]);
	$KeyTable->save($self->{"Reaction database directory"}->[0]."masterfiles/GapFill.key");

	#Printing the TMFA file
	system($self->GenerateMFAToolkitCommandLineCall("DatabaseProcessing","Complete","NoBounds",["ProdFullTMFALP"],undef,"TMFA_LP_Printing.log",undef,undef));
	system("cp ".$self->{"MFAToolkit output directory"}->[0]."DatabaseProcessing/CurrentProblem.lp ".$self->{"Reaction database directory"}->[0]."masterfiles/TMFA.lp");
	$KeyTable = undef;
	$KeyTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0]."DatabaseProcessing/VariableKey.txt",";","|",0,undef);
	$KeyTable->headings(["Variable type","Variable ID"]);
	$KeyTable->save($self->{"Reaction database directory"}->[0]."masterfiles/TMFA.key");
}

=head3 PrintModelGapFillObjective
Definition:
	$model->PrintModelGapFillObjective($Model);
Description:
	This algorithm prints the coefficients and variable names for all terms in the gap filling object for use with fbalite
Example:
	$model->PrintModelGapFillObjective("Seed83333.1");
=cut

sub PrintModelGapFillObjective {
	my ($self,$Model) = @_;

	#Getting filename
	my $Filename = $self->filename();

	#Printing the standard FBA file
	system($self->GenerateMFAToolkitCommandLineCall($Filename,$Model,"NoBounds",["ProductionPrintGFObj"],undef,$Model."-ProductionPrintGFObj.log",undef,undef));

	#Clearing the filename
	$self->cleardirectory($Filename);
}

=head3 RunModelChecks
Definition:
	$model->RunModelChecks($Model);
Description:
	This algorithm runs a set of standardized tests on the genome-scale models to check their performance.
	Currently these tests include: growth on complete, minimal, and glucose minimal media with and w/o thermo constraints
	Results from tests are stored in the model test table
Example:
	$model->RunModelChecks("Seed100226.1");
=cut

sub RunModelChecks {
	my ($self,$InModels) = @_;

	#Getting a directory for the results
	my $UniqueFilename = $self->filename();

	#Creating the job table
	my $JobTable = $self->CreateJobTable($UniqueFilename);

	#Determining the model list
	my $ModelList;
	if (ref($InModels) eq 'ARRAY') {
		$ModelList = $InModels;
	} else {
		#Assuming only a single model was provided
		$ModelList = [$InModels];
	}

	#Printing the LP files for models
	for (my $i=0; $i < @{$ModelList}; $i++) {
		my $model = $self->get_model($ModelList->[$i]);
		$model->PrintModelLPFile();
		my $Row = $self->GenerateJobFileLine($ModelList->[$i],$ModelList->[$i],["Complete","SP4","ArgonneLBMedia","Carbon-D-Glucose"],"GROWTH",0,0);
		if (defined($Row)) {
			$JobTable->add_row($Row);
		}
	}
	system("mkdir ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename);
	$JobTable->save();

	#Running FBA
	system($self->{"mfalite executable"}->[0]." ".$self->{"Reaction database directory"}->[0]."masterfiles/MediaTable.txt ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Jobfile.txt ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Output.txt");
	#Parsing the results
	my $Results = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Output.txt",";","\\|",0,["LABEL"]);
	if (!defined($Results)) {
		print STDERR "FIGMODEL:RunModelChecks:Could not find simulation results: ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/Output.txt\n";
		return undef;
	}

	#Gathering results
	my $ResultTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["Model","Complete","SP4","ArgonneLBMedia","Carbon-D-Glucose"],$self->{"Reaction database directory"}->[0]."masterfiles/ModelCheck.txt",undef,";","|",undef);
	for (my $i=0; $i < @{$ModelList}; $i++) {
		my $NewRow = {"Model" => [$ModelList->[$i]]};
		my @Rows = $Results->get_rows_by_key($ModelList->[$i],"LABEL");
		for (my $j=0; $j < @Rows; $j++) {
			$NewRow->{$Rows[$j]->{"MEDIA"}->[0]}->[0] = $Rows[$j]->{"OBJECTIVE"}->[0];
		}
		$ResultTable->add_row($NewRow);
	}
	$ResultTable->save();
	cleardirectory($UniqueFilename);
}

=head3 CreateJobTable
Definition:
	$model->CreateJobTable($Folder);
Description:
Example:
	$model->CreateJobTable($Folder);
=cut

sub CreateJobTable {
	my ($self,$Folder) = @_;

	my $JobTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["LABEL","RUNTYPE","LP FILE","MODEL","MEDIA","REACTION KO","REACTION ADDITION","GENE KO","SAVE FLUXES","SAVE NONESSENTIALS"],$self->{"MFAToolkit output directory"}->[0].$Folder."/Jobfile.txt",["LABEL"],";","|",undef);

	return $JobTable;
}

=head3 TestSolutions
Definition:
	$model->TestSolutions($ModelID,$NumProcessors,$ProcessorIndex,$GapFill);
Description:
Example:
=cut

sub TestSolutions {
	my ($self,$ModelID,$NumProcessors,$ProcessorIndex,$GapFill) = @_;

	my $model = $self->get_model($ModelID);
	#Getting unique filename
	$self->{"preserve all log files"}->[0] = "no";
	my $Filename = $self->filename();

	#This is the scheduler code
	if ($ProcessorIndex == -1 && -e $model->directory().$model->id().$model->selected_version()."-".$GapFill."S.txt") {
		#Updating the growmatch table
		my $GrowMatchTable = $self->database()->LockDBTable("GROWMATCH TABLE");
		my $Row = $GrowMatchTable->get_row_by_key($model->genome(),"ORGANISM",1);
		if ($GapFill eq "GF" || $GapFill eq "GG") {
			$Row->{$GapFill." TESTING TIMING"}->[0] = time()."-";
			$Row->{$GapFill." SOLUTIONS TESTED"}->[0] = CountFileLines($model->directory().$model->id().$model->selected_version()."-".$GapFill."S.txt")-1;
		}
		$GrowMatchTable->save();
		$self->database()->UnlockDBTable("GROWMATCH TABLE");

		#Adding all the subprocesses to the scheduler queue
		my $ProcessList;
		if (-e $model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-0.txt") {
			unlink($model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-0.txt");
		}
		for (my $i=1; $i < $NumProcessors; $i++) {
			if (-e $model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$i.".txt") {
				unlink($model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$i.".txt");
			}
			push(@{$ProcessList},"testsolutions?".$model->id().$model->selected_version()."?".$i."?".$GapFill."?".$NumProcessors);
		}
		PrintArrayToFile($self->{"temp file directory"}->[0]."SolutionTestQueue-".$model->id().$model->selected_version()."-".$Filename.".txt",$ProcessList);
		system($self->{"scheduler executable"}->[0]." \"add:".$self->{"temp file directory"}->[0]."SolutionTestQueue-".$model->id().$model->selected_version()."-".$Filename.".txt:BACK:fast:QSUB\"");
		#Eliminating queue file
		unlink($self->{"temp file directory"}->[0]."SolutionTestQueue-".$model->id().$model->selected_version()."-".$Filename.".txt");
		$ProcessorIndex = 0;
	}

	my $ErrorMatrixLines;
	my $Last = 1;
	if ($ProcessorIndex != -2) {
		#Reading in the original error matrix which has the headings for the original model simulation
		my $OriginalErrorData;
		if ($GapFill eq "GF" || $GapFill eq "GFSR") {
			$OriginalErrorData = LoadSingleColumnFile($model->directory().$model->id().$model->selected_version()."-OPEM".".txt","");
		} else {
			$OriginalErrorData = LoadSingleColumnFile($model->directory().$model->id().$model->selected_version()."-GGOPEM".".txt","");
		}
		my $HeadingHash;
		my @HeadingArray = split(/;/,$OriginalErrorData->[0]);
		my @OrigErrorArray = split(/;/,$OriginalErrorData->[1]);
		for (my $i=0; $i < @HeadingArray; $i++) {
			my @SubArray = split(/:/,$HeadingArray[$i]);
			$HeadingHash->{$SubArray[0].":".$SubArray[1].":".$SubArray[2]} = $i;
		}

		#Loading the gapfilling solution data
		my $GapFillResultTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($model->directory().$model->id().$model->selected_version()."-".$GapFill."S.txt",";","",0,undef);
		if (!defined($GapFillResultTable)) {
			print STDERR "FIGMODEL:TestSolutions: Could not load results table.";
			return 0;
		}

		#Scanning through the gap filling solutions
		print "Processor ".($ProcessorIndex+1)." of ".$NumProcessors." testing ".$GapFill." solutions!\n";
		my $GapFillingLines;
		my $CurrentIndex = 0;

		my $TempVersion = "V".$Filename."-".$ProcessorIndex;
		for (my $i=0; $i < $GapFillResultTable->size(); $i++) {
			if ($CurrentIndex == $ProcessorIndex) {
				print "Starting problem solving ".$i."\n";
				if (defined($GapFillResultTable->get_row($i)->{"Solution reactions"}->[0]) && $GapFillResultTable->get_row($i)->{"Solution reactions"}->[0] ne "none") {
					my $ErrorLine = $GapFillResultTable->get_row($i)->{"Experiment"}->[0].";".$i.";".$GapFillResultTable->get_row($i)->{"Solution cost"}->[0].";".$GapFillResultTable->get_row($i)->{"Solution reactions"}->[0];
					#Integrating solution into test model
					my $ReactionArray;
					my $DirectionArray;
					my @ReactionList = split(/,/,$GapFillResultTable->get_row($i)->{"Solution reactions"}->[0]);
					my %SolutionHash;
					for (my $k=0; $k < @ReactionList; $k++) {
						if ($ReactionList[$k] =~ m/(.+)(rxn\d\d\d\d\d)/) {
							my $Reaction = $2;
							my $Sign = $1;
							if (defined($SolutionHash{$Reaction})) {
								$SolutionHash{$Reaction} = "<=>";
							} elsif ($Sign eq "-") {
								$SolutionHash{$Reaction} = "<=";
							} elsif ($Sign eq "+") {
								$SolutionHash{$Reaction} = "=>";
							} else {
								$SolutionHash{$Reaction} = $Sign;
							}
						}
					}
					@ReactionList = keys(%SolutionHash);
					for (my $k=0; $k < @ReactionList; $k++) {
						push(@{$ReactionArray},$ReactionList[$k]);
						push(@{$DirectionArray},$SolutionHash{$ReactionList[$k]});
					}
					print "Integrating solution!\n";
					$self->IntegrateGrowMatchSolution($model->id().$model->selected_version(),$model->directory().$model->id().$TempVersion.".txt",$ReactionArray,$DirectionArray,"Gapfilling ".$GapFillResultTable->get_row($i)->{"Experiment"}->[0],1,1);
					my $testmodel = $self->get_model($model->id().$TempVersion);
					$testmodel->PrintModelLPFile();
					#Running the model against all available experimental data
					print "Running test model!\n";
					my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $testmodel->RunAllStudiesWithDataFast("All");

					@HeadingArray = split(/;/,$HeadingVector);
					my @ErrorArray = @OrigErrorArray;
					my @TempArray = split(/;/,$Errorvector);
					for (my $j=0; $j < @HeadingArray; $j++) {
						my @SubArray = split(/:/,$HeadingArray[$j]);
						$ErrorArray[$HeadingHash->{$SubArray[0].":".$SubArray[1].":".$SubArray[2]}] = $TempArray[$j];
					}
					$ErrorLine .= ";".$FalsePostives."/".$FalseNegatives.";".join(";",@ErrorArray);
				push(@{$ErrorMatrixLines},$ErrorLine);
				}
				print "Finishing problem solving ".$i."\n";
			}
			$CurrentIndex++;
			if ($CurrentIndex >= $NumProcessors) {
				$CurrentIndex = 0;
			}
		}

		print "Problem solving done! Checking if last...\n";

		#Clearing out the test model
		if (-e $model->directory().$model->id().$TempVersion.".txt") {
			unlink($model->directory().$model->id().$TempVersion.".txt");
			unlink($model->directory()."SimulationOutput".$model->id().$TempVersion.".txt");
		}

		#Printing the error array to file
		for (my $i=0; $i < $NumProcessors; $i++) {
			if ($i != $ProcessorIndex && !-e $model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$i.".txt") {
				$Last = 0;
				last;
			}
		}
		print "Last checking done: ".$Last."\n";
	}

	if ($Last == 1 || $ProcessorIndex == -2) {
		print "combining all error files!\n";
		#Backing up the existing GFEM file
		if (-e $model->directory().$model->id().$model->selected_version()."-".$GapFill."EM.txt") {
			system("cp ".$model->directory().$model->id().$model->selected_version()."-".$GapFill."EM.txt ".$model->directory().$model->id().$model->selected_version()."-Old".$GapFill."EM.txt");
		}

		#Combining all the error matrices into a single file
		for (my $i=0; $i < $NumProcessors; $i++) {
			if (-e $model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$i.".txt") {
				my $NewArray = LoadSingleColumnFile($model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$i.".txt","");
				push(@{$ErrorMatrixLines},@{$NewArray});
				unlink($model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$i.".txt");
			}
		}

		print "printing combined error file\n";
		#Printing the true error file
		PrintArrayToFile($model->directory().$model->id().$model->selected_version()."-".$GapFill."EM.txt",$ErrorMatrixLines);

		#Adding model to reconciliation queue
		if ($GapFill eq "GF") {
			system($self->{"scheduler executable"}->[0]." \"add:reconciliation?".$model->id().$model->selected_version()."?1:FRONT:cplex:QSUB\"");
		} elsif ($GapFill eq "GG") {
			system($self->{"scheduler executable"}->[0]." \"add:reconciliation?".$model->id().$model->selected_version()."?0:FRONT:cplex:QSUB\"");
		} elsif ($GapFill eq "GFSR") {
			system($self->{"scheduler executable"}->[0]." \"add:reconciliation?".$model->id().$model->selected_version()."?1?2:FRONT:fast:QSUB\"");
		} elsif ($GapFill eq "GGSR") {
			system($self->{"scheduler executable"}->[0]." \"add:reconciliation?".$model->id().$model->selected_version()."?0?2:FRONT:fast:QSUB\"");
		}

		print "updating growmatch table\n";
		my $GrowMatchTable = $self->database()->LockDBTable("GROWMATCH TABLE");
		my $Row = $GrowMatchTable->get_row_by_key($model->genome(),"ORGANISM",1);
		if ($GapFill eq "GF" || $GapFill eq "GG") {
			$Row->{$GapFill." TESTING TIMING"}->[0] .= time();
		}
		$GrowMatchTable->save();
		$self->database()->UnlockDBTable("GROWMATCH TABLE");
		print "done!\n";
	} else {
		print "printing results!\n";
		#Printing the processor specific error file
		PrintArrayToFile($model->directory().$model->id().$model->selected_version()."-".$GapFill."Error-".$ProcessorIndex.".txt",$ErrorMatrixLines);
	}

	return 1;
}

=head3 TestGapGenReconciledSolution
Definition:
	$model->TestGapGenReconciledSolution($ModelID,$Filename);
Description:
	This function resimulates all data adding each reaction in the gap gen solution one at a time to see where the model predictions go bad.
Example:
=cut

sub TestGapGenReconciledSolution {
	my ($self,$ModelID,$Stage) = @_;

	#Setting the filename with the solution data based on the input stage
	my $Filename = $Stage;
	if ($Stage eq "GG") {
		$Filename = $ModelID."-GG-FinalSolution.txt";
	} elsif ($Stage eq "GF") {
		$Filename = $ModelID."-GF-FinalSolution.txt";
	}

	#Getting model data
	my $modelObj = $self->get_model($ModelID);
	if (!defined($modelObj)) {
		print STDERR "FIGMODEL:TestGapGenReconciledSolution: Could not find model ".$ModelID.".\n";
		return;
	}
	my $Version = "";
	if (defined($modelObj->version())) {
		$Version = $modelObj->version();
	}
	$ModelID = $modelObj->id();

	#Loading solution file
	if (!-e $modelObj->directory().$Filename) {
		print STDERR "FIGMODEL:TestGapGenReconciledSolution: Could not find specified solution file ".$Filename." for ".$ModelID.".\n";
		return 0;
	}
	my $SolutionData = LoadMultipleColumnFile($modelObj->directory().$Filename,";");

	#Populating the KO list
	my $ReactionKO;
	my $MultiRunTable;
	if ($Stage eq "GG") {
		for (my $j=0; $j < @{$SolutionData}; $j++) {
			my $CurrentKO = "";
			for (my $i=0; $i < @{$SolutionData}; $i++) {
				if ($i != $j) {
					if (length($CurrentKO) > 0) {
						$CurrentKO .= ",";
					}
					if (defined($SolutionData->[$i]->[1]) && $SolutionData->[$i]->[1] eq "=>") {
						$CurrentKO .= "+".$SolutionData->[$i]->[0];
					} elsif (defined($SolutionData->[$i]->[1]) && $SolutionData->[$i]->[1] eq "<=") {
						$CurrentKO .= "-".$SolutionData->[$i]->[0];
					} else {
						$CurrentKO .= $SolutionData->[$i]->[0];
					}
				}
			}
			push(@{$ReactionKO},$CurrentKO);
		}
		#Simulating the knockouts using FBA
		$self->MultiRunAllStudiesWithData($ModelID.$Version,$ReactionKO,undef);
		#Loading the simulation results into a FIGMODELTable
		$MultiRunTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($modelObj->directory().$ModelID.$Version."-MultiSimulationResults.txt",";","\\|",0,undef);
	} elsif ($Stage eq "GF") {
		for (my $i=0; $i < @{$SolutionData}; $i++) {
			my $CurrentKO = "";
			if (defined($SolutionData->[$i]->[1]) && $SolutionData->[$i]->[1] eq "=>") {
				$CurrentKO = "+".$SolutionData->[$i]->[0];
			} elsif (defined($SolutionData->[$i]->[1]) && $SolutionData->[$i]->[1] eq "<=") {
				$CurrentKO = "-".$SolutionData->[$i]->[0];
			} else {
				my $ModelTable = $self->database()->GetDBModel($ModelID);
				if (defined($ModelTable)) {
					my $Row = $ModelTable->get_row_by_key($SolutionData->[$i]->[0],"LOAD");
					if (defined($Row)) {
						if ($Row->{"DIRECTIONALITY"}->[0] eq "=>") {
							$CurrentKO = "-".$SolutionData->[$i]->[0];
						} else {
							$CurrentKO = "+".$SolutionData->[$i]->[0];
						}
					} else {
						$CurrentKO = $SolutionData->[$i]->[0];
					}
				} else {
					$CurrentKO = $SolutionData->[$i]->[0];
				}
			}
			push(@{$ReactionKO},$CurrentKO);
		}
		#Simulating the knockouts using FBA
		$self->MultiRunAllStudiesWithData($ModelID."VGapFilled",$ReactionKO,undef);
		#Loading the simulation results into a FIGMODELTable
		$MultiRunTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($modelObj->directory().$ModelID."VGapFilled-MultiSimulationResults.txt",";","\\|",0,undef);
	} else {
		my $CurrentKO = "";
		for (my $i=0; $i < @{$SolutionData}; $i++) {
			if (length($CurrentKO) > 0) {
				$CurrentKO .= ",";
			}
			if (defined($SolutionData->[$i]->[1]) && $SolutionData->[$i]->[1] eq "=>") {
				$CurrentKO .= "+".$SolutionData->[$i]->[0];
			} elsif (defined($SolutionData->[$i]->[1]) && $SolutionData->[$i]->[1] eq "<=") {
				$CurrentKO .= "-".$SolutionData->[$i]->[0];
			} else {
				$CurrentKO .= $SolutionData->[$i]->[0];
			}
			push(@{$ReactionKO},$CurrentKO);
		}
		#Simulating the knockouts using FBA
		$self->MultiRunAllStudiesWithData($ModelID.$Version,$ReactionKO,undef);
		#Loading the simulation results into a FIGMODELTable
		$MultiRunTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($modelObj->directory().$ModelID.$Version."-MultiSimulationResults.txt",";","\\|",0,undef);
	}

	#Simulate the optimized/gapfilled version of the model to determine the reference model accuracy
	my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector,$TempErrorVector,$TempHeadingVector);
	if ($Stage eq "GG") {
		($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID."VOptimized")->RunAllStudiesWithDataFast("All");
	} elsif ($Stage eq "GF") {
		($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID."VGapFilled")->RunAllStudiesWithDataFast("All");
	}
	push(@{$TempErrorVector},split(/;/,$Errorvector));
	push(@{$TempHeadingVector},split(/;/,$HeadingVector));

	#Determining the number of errors created/fixed by each reaction in the solution
	if (!defined($self->{$Stage." solution testing table"})) {
		$self->{$Stage." solution testing table"} = ModelSEED::FIGMODEL::FIGMODELTable->new(["Key","Reaction","Direction","Definition","Role","Subsystem","Subsystem class 2","Subsystem class 1","Models with reaction added during gap filling","False negative predictions fixed","False positive predictions generated"],$self->{"database message file directory"}->[0].$Stage."GrowmatchResults.txt",["Key"],";","|",undef);
	}

	#Adding the model column to the table
	$self->{$Stage." solution testing table"}->add_headings($ModelID);
	#Filling in the growmatch solution data for this model
	my $ZeroEffectReactions;
	my $ZeroEffectReactionResults;
	for (my $i=0; $i < @{$SolutionData}; $i++) {
		#Identifying the number of new errors generated
		my ($FixedErrors,$NewErrors) = $self->CompareErrorVectors($TempErrorVector,$TempHeadingVector,$MultiRunTable->get_row($i)->{"ERROR VECTOR"},$MultiRunTable->get_row($i)->{"HEADING VECTOR"});
		my $Row = $self->{$Stage." solution testing table"}->get_row_by_key($SolutionData->[$i]->[0].$SolutionData->[$i]->[1],"Key");
		if (!defined($Row)) {
			#Adding the row for thise reaction to the database
			$Row = {"Key" => [$SolutionData->[$i]->[0].$SolutionData->[$i]->[1]],"Direction" => [$SolutionData->[$i]->[1]],"Models with reaction added during gap filling" => [0],"False negative predictions fixed" => [0],"False positive predictions generated" => [0]};
			$self->{$Stage." solution testing table"}->add_row($Row);
			#Adding reaction data to hash
			$Row = $self->add_reaction_data_to_row($SolutionData->[$i]->[0],$Row,{"DATABASE" => "Reaction","SUBSYSTEM CLASS 1" => "Subsystem class 1","SUBSYSTEM CLASS 2" => "Subsystem class 2","SUBSYSTEM" => "Subsystem","ROLE" => "Role","DEFINITION" => "Definition"})
		}
		#Iterating the error count
		$Row->{"Models with reaction added during gap filling"}->[0]++;
		if (defined($FixedErrors)) {
			$Row->{"False negative predictions fixed"}->[0] += @{$FixedErrors};
		}
		if (defined($NewErrors)) {
			$Row->{"False positive predictions generated"}->[0] += @{$NewErrors};
		}
		if ($Row->{"False negative predictions fixed"}->[0] <= $Row->{"False positive predictions generated"}->[0]) {
			print $SolutionData->[$i]->[0].",".$SolutionData->[$i]->[1]."\n";
			push(@{$ZeroEffectReactions},$SolutionData->[$i]);
			$ZeroEffectReactionResults->{$SolutionData->[$i]} = $Row->{"False positive predictions generated"}->[0]-$Row->{"False negative predictions fixed"}->[0];
		}
		#Filling in the model column for this reaction
		$Row->{$ModelID}->[0] = "0";
		if (defined($FixedErrors)) {
			$Row->{$ModelID}->[0] = @{$FixedErrors}."(";
			for (my $j=0; $j < @{$FixedErrors}; $j++) {
				if ($j > 0) {
					$Row->{$ModelID}->[0] .= ",";
				}
				my @TempArray = split(/:/,$FixedErrors->[$j]);
				if ($TempArray[0] eq "Gene KO") {
					$Row->{$ModelID}->[0] .= $TempArray[2];
				} else {
					$Row->{$ModelID}->[0] .= $TempArray[1];
				}
			}
			$Row->{$ModelID}->[0] .= ")";
		}
		$Row->{$ModelID}->[0] .= "|";
		if (defined($NewErrors)) {
			$Row->{$ModelID}->[0] .= @{$NewErrors}."(";
			for (my $j=0; $j < @{$NewErrors}; $j++) {
				if ($j > 0) {
					$Row->{$ModelID}->[0] .= ",";
				}
				my @TempArray = split(/:/,$NewErrors->[$j]);
				if ($TempArray[0] eq "Gene KO") {
					$Row->{$ModelID}->[0] .= $TempArray[2];
				} else {
					$Row->{$ModelID}->[0] .= $TempArray[1];
				}
			}
			$Row->{$ModelID}->[0] .= ")";
		} else {
			$Row->{$ModelID}->[0] .= "0";
		}
	}

	#Trying to remove all zero error reactions
	if (defined($ZeroEffectReactions) && @{$ZeroEffectReactions}) {
		@{$ZeroEffectReactions} = sort { $ZeroEffectReactionResults->{$b} <=> $ZeroEffectReactionResults->{$a} } @{$ZeroEffectReactions};
		#$self->IdentifyReactionsToRemove($ZeroEffectReactions,$ModelID,$Stage);
	}
}

=head3 RemoveNoEffectReactions
Definition:
	$model->RemoveNoEffectReactions(string::model ID);
Description:
Example:
=cut

sub RemoveNoEffectReactions {
	my ($self,$ModelID,$Stage) = @_;

	#Getting reaction directory
	my $modelObj = $self->get_model($ModelID);
	if (!defined($modelObj)) {
		print STDERR "FIGMODEL:RemoveNoEffectReactions: Could not find model ".$ModelID.".\n";
		return;
	}

	#Checking if the no effect file exists
	if (!-e $modelObj->directory()."NoEffectReactions-".$Stage."-".$ModelID."VOptimized.txt") {
		return;
	}

	#Loading no effect reaction list
	my $ReactionList = LoadSingleColumnFile($modelObj->directory()."NoEffectReactions-".$Stage."-".$ModelID."VOptimized.txt","");
	my $Hash;
	for (my $i=0; $i < @{$ReactionList}; $i++) {
		if ($ReactionList->[$i] =~ m/\+/) {
			$Hash->{substr($ReactionList->[$i],1)} = "=>";
		} elsif ($ReactionList->[$i] =~ m/\-/) {
			$Hash->{substr($ReactionList->[$i],1)} = "<=";
		} else {
			$Hash->{$ReactionList->[$i]} = "<=>";
		}
	}

	#Loading original reaction list
	my $OriginalReactionList;
	if ($Stage eq "GF") {
		$OriginalReactionList = LoadMultipleColumnFile($modelObj->directory().$ModelID."-GF-FinalSolution.txt",";");
	} else {
		if (-e $modelObj->directory().$ModelID."-GG-FinalSolution.txt") {
			$OriginalReactionList = LoadMultipleColumnFile($modelObj->directory().$ModelID."-GG-FinalSolution.txt",";");
		} elsif (-e $modelObj->directory().$ModelID."VGapFilled-GG-FinalSolution.txt") {
			$OriginalReactionList = LoadMultipleColumnFile($modelObj->directory().$ModelID."VGapFilled-GG-FinalSolution.txt",";");
		}
	}

	#Removing no effect reactions from the original reaction list
	my $NewReactionList;
	my $ReactionArray;
	my $DirectionArray;
	for (my $i=0; $i < @{$OriginalReactionList}; $i++) {
		if (!defined($Hash->{$OriginalReactionList->[$i]->[0]})) {
			push(@{$ReactionArray},$OriginalReactionList->[$i]->[0]);
			push(@{$DirectionArray},$OriginalReactionList->[$i]->[1]);
			push(@{$NewReactionList},$OriginalReactionList->[$i]->[0].";".$OriginalReactionList->[$i]->[1]);
		} elsif ($Hash->{$OriginalReactionList->[$i]->[0]} ne $OriginalReactionList->[$i]->[1] && $OriginalReactionList->[$i]->[1] ne "<=>") {
			push(@{$ReactionArray},$OriginalReactionList->[$i]->[0]);
			push(@{$DirectionArray},$OriginalReactionList->[$i]->[1]);
			push(@{$NewReactionList},$OriginalReactionList->[$i]->[0].";".$OriginalReactionList->[$i]->[1]);
		} elsif ($Hash->{$OriginalReactionList->[$i]->[0]} ne $OriginalReactionList->[$i]->[1]) {
			for (my $j=0; $j < @{$OriginalReactionList}; $j++) {
				if ($j != $i && $OriginalReactionList->[$j]->[0] eq $OriginalReactionList->[$i]->[0]) {
					if ($Hash->{$OriginalReactionList->[$i]->[0]} eq $OriginalReactionList->[$j]->[1]) {
						push(@{$ReactionArray},$OriginalReactionList->[$i]->[0]);
						push(@{$DirectionArray},$OriginalReactionList->[$i]->[1]);
						push(@{$NewReactionList},$OriginalReactionList->[$i]->[0].";".$OriginalReactionList->[$i]->[1]);
						last;
					}
				}
			}
		}
	}

	if ($Stage eq "GF") {
		#Printing new reaction list
		PrintArrayToFile($modelObj->directory().$ModelID."-GF-NewFinalSolution.txt",$NewReactionList);

		#Integrating new solution
		$self->IntegrateGrowMatchSolution($ModelID,$modelObj->directory().$ModelID."VGapFilledNew.txt",$ReactionArray,$DirectionArray,"GROWMATCH",1,1);
		my $model = $self->get_model($ModelID."VGapFilledNew");
		$model->PrintModelLPFile();

		#Rerunning the simulation
		my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID."VGapFilledNew")->RunAllStudiesWithDataFast("All");
		my ($OldFalsePostives,$OldFalseNegatives,$OldCorrectNegatives,$OldCorrectPositives,$OldErrorvector,$OldHeadingVector) = $self->get_model($ModelID."VGapFilled")->RunAllStudiesWithDataFast("All");

		#Checking that the new model file has the same accuracy as the old file
		if (($FalsePostives+$FalseNegatives) <= ($OldFalsePostives+$OldFalseNegatives)) {
			print "GF Accepted!\n";
			system("rm ".$modelObj->directory().$ModelID."-GF-OldFinalSolution.txt");
			system("rm ".$modelObj->directory().$ModelID."VGapFilledOld.txt");
			system("rm ".$modelObj->directory()."SimulationOutput".$ModelID."VGapFilledOld.txt");
			system("mv ".$modelObj->directory().$ModelID."-GF-FinalSolution.txt ".$modelObj->directory().$ModelID."-GF-OldFinalSolution.txt");
			system("mv ".$modelObj->directory().$ModelID."-GF-NewFinalSolution.txt ".$modelObj->directory().$ModelID."-GF-FinalSolution.txt");
			system("mv ".$modelObj->directory().$ModelID."VGapFilled.txt ".$modelObj->directory().$ModelID."VGapFilledOld.txt");
			system("mv ".$modelObj->directory().$ModelID."VGapFilledNew.txt ".$modelObj->directory().$ModelID."VGapFilled.txt");
			system("mv ".$modelObj->directory()."SimulationOutput".$ModelID."VGapFilled.txt ".$modelObj->directory()."SimulationOutput".$ModelID."VGapFilledOld.txt");
			system("mv ".$modelObj->directory()."SimulationOutput".$ModelID."VGapFilledNew.txt ".$modelObj->directory()."SimulationOutput".$ModelID."VGapFilled.txt");
			if (-e $modelObj->directory().$ModelID."VGapFilled-GG-FinalSolution.txt") {
				#Integrating new solution
				$ReactionArray = ();
				$DirectionArray = ();
				$OriginalReactionList = LoadMultipleColumnFile($modelObj->directory().$ModelID."VGapFilled-GG-FinalSolution.txt",";");
				for (my $i=0; $i < @{$OriginalReactionList}; $i++) {
					push(@{$ReactionArray},$OriginalReactionList->[$i]->[0]);
					push(@{$DirectionArray},$OriginalReactionList->[$i]->[1]);
				}
				$self->IntegrateGrowMatchSolution($ModelID."VGapFilled",$modelObj->directory().$ModelID."VOptimizedNew.txt",$ReactionArray,$DirectionArray,"GROWMATCH",1,1);
				my $model = $self->get_model($ModelID."VOptimizedNew");
				$model->PrintModelLPFile();

				#Rerunning the simulation
				($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID."VOptimizedNew")->RunAllStudiesWithDataFast("All");
				($OldFalsePostives,$OldFalseNegatives,$OldCorrectNegatives,$OldCorrectPositives,$OldErrorvector,$OldHeadingVector) = $self->get_model($ModelID."VOptimized")->RunAllStudiesWithDataFast("All");

				#Checking that the new model file has the same accuracy as the old file
				if (($FalsePostives+$FalseNegatives) <= ($OldFalsePostives+$OldFalseNegatives)) {
					print "GF Opt Accepted!\n";
					system("rm ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimizedOld.txt");
					system("rm ".$modelObj->directory().$ModelID."VOptimizedOld.txt");
					system("mv ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimized.txt ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimizedOld.txt");
					system("mv ".$modelObj->directory().$ModelID."VOptimized.txt ".$modelObj->directory().$ModelID."VOptimizedOld.txt");
					system("mv ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimizedNew.txt ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimized.txt");
					system("mv ".$modelObj->directory().$ModelID."VOptimizedNew.txt ".$modelObj->directory().$ModelID."VOptimized.txt");
				} else {
					print STDERR "FIGMODEL:RemoveNoEffectReactions:Removal of no effect reactions failed for optimized ".$ModelID."!\n";
				}
			}
		} else {
			print STDERR "FIGMODEL:RemoveNoEffectReactions:Removal of no effect reactions failed for gapfilled ".$ModelID."!\n";
		}
	} else {
		my $BaseModel = $ModelID;
		if (-e $modelObj->directory().$ModelID."VGapFilled-GG-FinalSolution.txt") {
			$BaseModel = $ModelID."VGapFilled";
		}
		if (-e $modelObj->directory().$BaseModel."-GG-FinalSolution.txt") {
			#Integrating new solution
			$self->IntegrateGrowMatchSolution($BaseModel,$modelObj->directory().$ModelID."VOptimizedNew.txt",$ReactionArray,$DirectionArray,"GROWMATCH",1,1);
			my $model = $self->get_model($ModelID."VOptimizedNew");
			$model->PrintModelLPFile();

			#Rerunning the simulation
			my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID."VOptimizedNew")->RunAllStudiesWithDataFast("All");
			my ($OldFalsePostives,$OldFalseNegatives,$OldCorrectNegatives,$OldCorrectPositives,$OldErrorvector,$OldHeadingVector) = $self->get_model($ModelID."VOptimized")->RunAllStudiesWithDataFast("All");

			#Checking that the new model file has the same accuracy as the old file
			if (($FalsePostives+$FalseNegatives) <= ($OldFalsePostives+$OldFalseNegatives)) {
				print "GG Accepted!\n";
				system("rm ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimizedOld.txt");
				system("rm ".$modelObj->directory().$ModelID."VOptimizedOld.txt");
				system("mv ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimized.txt ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimizedOld.txt");
				system("mv ".$modelObj->directory().$ModelID."VOptimized.txt ".$modelObj->directory().$ModelID."VOptimizedOld.txt");
				system("mv ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimizedNew.txt ".$modelObj->directory()."SimulationOutput".$ModelID."VOptimized.txt");
				system("mv ".$modelObj->directory().$ModelID."VOptimizedNew.txt ".$modelObj->directory().$ModelID."VOptimized.txt");
			} else {
				print STDERR "FIGMODEL:RemoveNoEffectReactions:Removal of no effect reactions failed for optimized ".$ModelID."!\n";
			}
		}
	}
}

=head3 IdentifyReactionsToRemove
Definition:
	$model->IdentifyReactionsToRemove(2D array ref::list of reactions and direction,string::model ID,string::stage);
Description:
Example:
=cut

sub IdentifyReactionsToRemove {
	my ($self,$ReactionList,$ModelID,$Stage) = @_;

	#Parsing reactions and directions to get reactions formatted for KO
	my $TrueList;
	for (my $i=0; $i < @{$ReactionList}; $i++) {
		if (defined($ReactionList->[$i]->[1]) && $ReactionList->[$i]->[1] eq "=>") {
			push(@{$TrueList},"+".$ReactionList->[$i]->[0]);
		} elsif (defined($ReactionList->[$i]->[1]) && $ReactionList->[$i]->[1] eq "<=") {
			push(@{$TrueList},"-".$ReactionList->[$i]->[0]);
		} else {
			my $ModelTable = $self->database()->GetDBModel($ModelID);
			if (defined($ModelTable)) {
				my $Row = $ModelTable->get_row_by_key($ReactionList->[$i]->[0],"LOAD");
				if (defined($Row)) {
					if ($Row->{"DIRECTIONALITY"}->[0] eq "=>") {
						push(@{$TrueList},"-".$ReactionList->[$i]->[0]);
					} else {
						push(@{$TrueList},"+".$ReactionList->[$i]->[0]);
					}
				} else {
					push(@{$TrueList},$ReactionList->[$i]->[0]);
				}
			} else {
				push(@{$TrueList},$ReactionList->[$i]->[0]);
			}
		}
	}

	#Simulating the unmodified model
	my $modelObj = $self->get_model($ModelID);
	my $Directory = $modelObj->directory();
	my $BaseModel = $ModelID."VGapFilled";
	if (!-e $Directory.$BaseModel.".txt") {
		$BaseModel = $ModelID;
	}
	my $Version = "VOptimized";
	if (!-e $Directory.$ModelID.$Version.".txt") {
		$Version = "VGapFilled";
	}
	if (!-e $Directory.$ModelID.$Version.".txt") {
		return;
	}
	my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID.$Version)->RunAllStudiesWithDataFast("All");
	print $FalsePostives.":".$FalseNegatives."\n";

	#Loading original reaction list
	my $OtherData;
	if ($Stage eq "GG") {
		my $OriginalReactionList = LoadMultipleColumnFile($modelObj->directory().$ModelID."VGapFilled-GG-FinalSolution.txt",";");
		for (my $i=0; $i < @{$OriginalReactionList}; $i++) {
			print $OriginalReactionList->[$i]->[0]."\t".$OriginalReactionList->[$i]->[1]."\n";
			$OtherData->[$i]->[0] = $OriginalReactionList->[$i]->[0];
			$OtherData->[$i]->[1] = $OriginalReactionList->[$i]->[1];
			if ($OriginalReactionList->[$i]->[1] eq "=>") {
				$OtherData->[$i]->[2] = "+".$OriginalReactionList->[$i]->[0];
			} elsif ($OriginalReactionList->[$i]->[1] eq "<=") {
				$OtherData->[$i]->[2] = "-".$OriginalReactionList->[$i]->[0];
			} else {
				$OtherData->[$i]->[2] = $OriginalReactionList->[$i]->[0];
			}
		}
	}

	#Progressively simulating knockout of reactions to determine impact on predictions
	my $KOReactions = "";
	my $FinalList;
	for (my $i=0; $i < @{$TrueList}; $i++) {
		my $NewFP;
		my $NewFN;
		my $NewKO;
		if ($Stage eq "GF") {
			$NewKO = $KOReactions;
			if (length($NewKO) > 0) {
				$NewKO .= ",";
			}
			$NewKO .= $TrueList->[$i];
			$self->MultiRunAllStudiesWithData($ModelID.$Version,[$NewKO],undef);
			#Loading the simulation results into a FIGMODELTable
			my $MultiRunTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory.$ModelID.$Version."-MultiSimulationResults.txt",";","\\|",0,undef);
			$NewFP = $MultiRunTable->get_row(0)->{"FALSE POSITIVES"}->[0];
			$NewFN = $MultiRunTable->get_row(0)->{"FALSE NEGATIVES"}->[0];
		} else {
			my $ReactionArray;
			my $DirectionArray;
			for (my $j=0; $j < @{$OtherData}; $j++) {
				my $Found = 0;
				if (defined($FinalList)) {
					for (my $k=0; $k < @{$FinalList}; $k++) {
						if ($FinalList->[$k] eq $OtherData->[$j]->[2]) {
							$Found = 1;
							last;
						}
					}
				}
				if ($Found == 0) {
					push(@{$ReactionArray},$OtherData->[$j]->[0]);
					push(@{$DirectionArray},$OtherData->[$j]->[1]);
				}
			}
			#Integrating new solution
			$self->IntegrateGrowMatchSolution($BaseModel,$modelObj->directory().$ModelID."VTest.txt",$ReactionArray,$DirectionArray,"GROWMATCH",1,1);
			my $model = $self->get_model($ModelID."VTest");
			$model->PrintModelLPFile();
			#Simulating the test model to determine if the combined deletion had no negative effect
			($NewFP,$NewFN,my $NewCN,my $NewCP,my $NewEV,my $NewHV) = $self->get_model($ModelID."VTest")->RunAllStudiesWithDataFast("All");
		}
		if (($NewFP+$NewFN) <= ($FalsePostives+$FalseNegatives)) {
			$KOReactions = $NewKO;
			push(@{$FinalList},$TrueList->[$i]);
			print "Accepted:".$NewFP.":".$NewFN.":".$TrueList->[$i]."\n";
			$FalsePostives = $NewFP;
			$FalseNegatives = $NewFN;
		} else {
			print "Rejected:".$TrueList->[$i]."\n";
		}
	}

	#Printing result
	PrintArrayToFile($Directory."NoEffectReactions-".$Stage."-".$ModelID.$Version.".txt",$FinalList);
	#$self->RemoveNoEffectReactions($ModelID,$Stage);
}

=head3 add_reaction_data_to_row
Definition:
	(figmodeltable row::reaction row) = $model->add_reaction_data_to_row(,figmodeltable row::reaction row,string hash ref::headings);
Description:
Example:
=cut

sub add_reaction_data_to_row {
	my ($self,$ID,$Row,$HeadingsHash) = @_;

	my @Headings = keys(%{$HeadingsHash});
	for (my $i=0; $i < @Headings; $i++) {
		if ($Headings[$i] eq "DATABASE") {
			$Row->{$HeadingsHash->{$Headings[$i]}}->[0] = $ID;
		} elsif ($Headings[$i] eq "SUBSYSTEM CLASS 1") {
			my $SubsystemListRef = $self->subsystems_of_reaction($ID);
			if (defined($SubsystemListRef)) {
				for (my $k=0; $k < @{$SubsystemListRef}; $k++) {
					my $SubsystemClasses = $self->class_of_subsystem($SubsystemListRef->[$k]);
					if (defined($SubsystemClasses)) {
						$SubsystemClasses->[0] =~ s/;/,/;
						push(@{$Row->{$HeadingsHash->{$Headings[$i]}}},$SubsystemClasses->[0]);
					}
				}
			}
			if (!defined($Row->{$HeadingsHash->{$Headings[$i]}})) {
				$Row->{$HeadingsHash->{$Headings[$i]}}->[0] = "NONE"
			}
		} elsif ($Headings[$i] eq "SUBSYSTEM CLASS 2") {
			my $SubsystemListRef = $self->subsystems_of_reaction($ID);
			if (defined($SubsystemListRef)) {
				for (my $k=0; $k < @{$SubsystemListRef}; $k++) {
					my $SubsystemClasses = $self->class_of_subsystem($SubsystemListRef->[$k]);
					if (defined($SubsystemClasses)) {
						$SubsystemClasses->[1] =~ s/;/,/;
						push(@{$Row->{$HeadingsHash->{$Headings[$i]}}},$SubsystemClasses->[1]);
					}
				}
			}
			if (!defined($Row->{$HeadingsHash->{$Headings[$i]}})) {
				$Row->{$HeadingsHash->{$Headings[$i]}}->[0] = "NONE"
			}
		} elsif ($Headings[$i] eq "ROLE") {
			my $RoleData = $self->roles_of_reaction($ID);
			if (defined($RoleData)) {
				$Row->{$HeadingsHash->{$Headings[$i]}} = $RoleData;
			}
			if (!defined($Row->{$HeadingsHash->{$Headings[$i]}})) {
				$Row->{$HeadingsHash->{$Headings[$i]}}->[0] = "NONE"
			}
		} elsif ($Headings[$i] eq "SUBSYSTEM") {
			my $SubsystemListRef = $self->subsystems_of_reaction($ID);
			if (defined($SubsystemListRef)) {
				$Row->{$HeadingsHash->{$Headings[$i]}} = $SubsystemListRef;
			}
			if (!defined($Row->{$HeadingsHash->{$Headings[$i]}})) {
				$Row->{$HeadingsHash->{$Headings[$i]}}->[0] = "NONE"
			}
		} elsif ($Headings[$i] eq "DEFINITION") {
			my $ReactionObject = $self->LoadObject($ID);
			if (defined($ReactionObject) && defined($ReactionObject->{"DEFINITION"}->[0])) {
				$Row->{$HeadingsHash->{$Headings[$i]}}->[0] = $ReactionObject->{"DEFINITION"}->[0];
			}
		}
	}

	return $Row;
}

=head3 CompareErrorVectors
Definition:
	(string array ref::new errors,string array ref::fixed errors) = $model->CompareErrorVectors(string array ref::error vector one,string array ref::heading vector one,string array ref::error vector two,string array ref::heading vector two);
Description:
Example:
=cut

sub CompareErrorVectors {
	my ($self,$ErrorOne,$HeadingOne,$ErrorTwo,$HeadingTwo) = @_;

	my ($ErrorOneCorrectTwo,$CorrectOneErrorTwo);
	my $ErrorHashOne;
	my $ErrorHashTwo;
	for (my $i=0; $i < @{$ErrorOne}; $i++) {
		$ErrorHashOne->{$HeadingOne->[$i]} = $ErrorOne->[$i];
	}
	for (my $i=0; $i < @{$ErrorTwo}; $i++) {
		$ErrorHashTwo->{$HeadingTwo->[$i]} = $ErrorTwo->[$i];
	}
	for (my $i=0; $i < @{$ErrorOne}; $i++) {
		if (defined($ErrorHashTwo->{$HeadingOne->[$i]})) {
			if ($ErrorOne->[$i] > 1) {
				if ($ErrorHashTwo->{$HeadingOne->[$i]} <= 1) {
					push(@{$ErrorOneCorrectTwo},$HeadingOne->[$i]);
				}
			} else {
				if ($ErrorHashTwo->{$HeadingOne->[$i]} > 1) {
					push(@{$CorrectOneErrorTwo},$HeadingOne->[$i]);
				}
			}
		} elsif ($ErrorOne->[$i] > 1) {
			push(@{$ErrorOneCorrectTwo},$HeadingOne->[$i]);
		}
	}
	for (my $i=0; $i < @{$ErrorTwo}; $i++) {
		if (!defined($ErrorHashOne->{$HeadingTwo->[$i]})) {
			if ($ErrorTwo->[$i] > 1) {
				push(@{$CorrectOneErrorTwo},$HeadingTwo->[$i]);
			}
		}
	}
	return ($CorrectOneErrorTwo,$ErrorOneCorrectTwo);
}

=head3 MultiRunAllStudiesWithData
Definition:
	$model->MultiRunAllStudiesWithData($ModelID,$ReactionKO,$GeneKO);
Description:
Example:
=cut

sub MultiRunAllStudiesWithData {
	my ($self,$ModelID,$ReactionKO,$GeneKO) = @_;

	if (!defined($ReactionKO) || @{$ReactionKO} == 0) {
		$ReactionKO->[0] = "none";
	}
	if (!defined($GeneKO) || @{$GeneKO} == 0) {
		$GeneKO->[0] = "none";
	}

	#Colleting all jobs in this table
	my $Filename = $self->filename();
	my $JobTable = $self->CreateJobTable($Filename);
	system("mkdir ".$self->{"MFAToolkit output directory"}->[0].$Filename);

	#Checking if model exists
	my $modelObj = $self->get_model($ModelID);
	if (!defined($modelObj)) {
		print STDERR "FIGMODEL:MultiRunAllStudiesWithData: Could not find model ".$ModelID.".\n";
		return 0;
	}
	my $Version = "";
	my $Directory = $modelObj->directory();
	if (defined($modelObj->version())) {
		$Version = $modelObj->version();
	}
	$ModelID = $modelObj->id();

	#Determing the simulations that need to be run
	my $ExperimentalDataTable = $self->GetExperimentalDataTable($modelObj->genome(),"All");
	#Creating the table of jobs to submit
	my $JobArray = $self->get_model($ModelID.$Version)->GetSimulationJobTable($ExperimentalDataTable,"All",$Filename);

	#Adding the job list
	for (my $i=0; $i < @{$ReactionKO}; $i++) {
		for (my $m=0; $m < @{$GeneKO}; $m++) {
			for (my $j=0; $j < $JobArray->size(); $j++) {
				my $NewRow = $JobArray->clone_row($j);
				$NewRow->{"REACTION KO"}->[0] = $ReactionKO->[$i];
				$NewRow->{"GENE KO"}->[0] = $GeneKO->[$m];
				$JobTable->add_row($NewRow);
			}
		}
	}

	#Printing the jobs tables
	$JobTable->save();

	#Running the FBA
	system($self->{"mfalite executable"}->[0]." ".$self->{"Reaction database directory"}->[0]."masterfiles/MediaTable.txt ".$self->{"MFAToolkit output directory"}->[0].$Filename."/Jobfile.txt ".$self->{"MFAToolkit output directory"}->[0].$Filename."/Output.txt");

	#Parsing the results
	my $Results = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$Filename."/Output.txt",";","\\|",0,undef);
	if (!defined($Results)) {
		print STDERR "FIGMODEL:RunAllStudiesWithDataFast:Could not find simulation results: ".$self->{"MFAToolkit output directory"}->[0].$Filename."/Output.txt\n";
		return undef;
	}

	#Parsing the job results files
	my $CurrentResults;
	my $CurrentReactionKO = "";
	my $CurrentGeneKO = "";
	my $EssentialityResults = ["REACTION KO;GENE KO;FALSE POSITIVES;FALSE NEGATIVES;ERROR VECTOR;HEADING VECTOR"];
	for (my $j=0; $j < $Results->size();$j++) {
		my $Row = $Results->get_row($j);
		if (!defined($Row->{"KOREACTIONS"}->[0])) {
			$Row->{"KOREACTIONS"}->[0] = "none";
		}
		if (!defined($Row->{"KOGENES"}->[0])) {
			$Row->{"KOGENES"}->[0] = "none";
		}
		#Handling the transition to a new reaction
		if ($CurrentReactionKO ne $Row->{"KOREACTIONS"}->[0] || $CurrentGeneKO ne $Row->{"KOGENES"}->[0]) {
			#Processing the results for the current model and reaction
			if ($j > 0) {
				my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector,$SimulationResults) = $self->get_model($ModelID.$Version)->EvaluateSimulationResults($CurrentResults,$ExperimentalDataTable);
				$Errorvector =~ s/;/|/g;
				$HeadingVector =~ s/;/|/g;
				push(@{$EssentialityResults},$CurrentReactionKO.";".$CurrentGeneKO.";".$FalsePostives.";".$FalseNegatives.";".$Errorvector.";".$HeadingVector);
			}
			$CurrentReactionKO = $Row->{"KOREACTIONS"}->[0];
			$CurrentGeneKO = $Row->{"KOGENES"}->[0];
			#Clearing out the current results table
			$CurrentResults = $Results->clone_table_def();
		}
		$CurrentResults->add_row($Row);
	}

	#Printing results
	PrintArrayToFile($Directory.$ModelID.$Version."-MultiSimulationResults.txt",$EssentialityResults);

	return 1;
}

=head3 CheckReactionEssentiality
Definition:
	$model->CheckReactionEssentiality($ModelID,$NumProcessors,$ProcessorIndex,$ReactionList);
Description:
Example:
=cut

sub CheckReactionEssentiality {
	my ($self,$ModelID,$NumProcessors,$Filename) = @_;

	#Handling the scenario when a list of models of submitted instead of individual models
	my $List;
	if ($ModelID =~ m/LIST-(.+)$/) {
		$List = FIGMODEL::LoadSingleColumnFile($1,"");
	} elsif (ref($ModelID) eq 'ARRAY') {
		push(@{$List},@{$ModelID});
	} elsif (defined($self->get_model($ModelID))) {
		push(@{$List},$ModelID);
	}

	#Colleting all jobs in this table
	my $JobTable = $self->CreateJobTable("NONE");

	#Processing model list
	my $FirstStage = 0;
	if (!defined($Filename)) {
		$FirstStage = 1;
		$Filename = $self->filename();
	}

	#Generating the list of jobs required to simulate every reaction KO in every model
	if ($FirstStage == 1) {
		for (my $i=0; $i < @{$List}; $i++) {
			my $ModelID = $List->[$i];
			my $model = $self->get_model($ModelID);
			if (!defined($model)) {
				print STDERR "FIGMODEL:CheckReactionEssentiality: Could not find model ".$ModelID.".\n";
				return 0;
			}
			my $Version = "";
			my $Directory = $model->directory();
			if (defined($model->version())) {
				$Version = $model->version();
			}
			$ModelID = $model->id();

			#Determing the simulations that need to be run
			my $ExperimentalDataTable = $self->GetExperimentalDataTable($model->genome(),"All");
			#Creating the table of jobs to submit
			my $JobArray = $self->get_model($ModelID.$Version)->GetSimulationJobTable($ExperimentalDataTable,"All",$Filename);

			#Updating the current stage file
			PrintArrayToFile($Directory."CURRENTSTAGE.txt",["checkbroadessentiality;RUNNING;".$ModelID.$Version]);

			#Backing up any existing check broad essentiality files
			if (-e $Directory.$ModelID.$Version."-ReactionKOResult.txt") {
				system("cp ".$Directory.$ModelID.$Version."-ReactionKOResult.txt ".$Directory.$ModelID.$Version."-OldReactionKOResult.txt");
			}

			#Identifying blocked and essential reactions on complete media
			my ($RxnClassTbl,$CpdClassTbl) = $model->ClassifyModelReactions("Complete");
			if (!defined($RxnClassTbl)) {
				print STDERR "FIGMODEL:CheckReactionEssentiality: ".$ModelID.$Version." won't grow on complete media.\n";
				return 0;
			}

			#Identifying reactions that are not blocked, positive, or negative
			my $KOList;
			my $Results = ["REACTION;FALSE POSITIVES;FALSE NEGATIVES"];
			for (my $i=0; $i < $model->get_reaction_number(); $i++) {
				my $rxnClass = $model->get_reaction_class($i,"Complete");
				my $rxnid = $model->get_reaction_id($i);
				if (defined($rxnClass)) {
					if ($rxnClass eq "Variable") {
						push(@{$KOList},"+".$rxnid);
						push(@{$KOList},"-".$rxnid);
					} elsif ($rxnClass eq "Positive variable") {
						push(@{$KOList},"+".$rxnid);
					} elsif ($rxnClass eq "Negative variable") {
						push(@{$KOList},"-".$rxnid);
					} elsif ($rxnClass eq "Positive") {
						push(@{$Results},"+".$rxnid.";0;10000");
					} elsif ($rxnClass eq "Negative") {
						push(@{$Results},"-".$rxnid.";0;10000");
					}
				}

			}

			#Updating the current stage file
			PrintArrayToFile($Directory.$ModelID.$Version."-ReactionKOResult.txt",$Results);

			#Printing LP files for model
			$model->PrintModelLPFile();
			if (!-d "/home/chenry/CheckBroadEss/".$Filename."/") {
				system("mkdir /home/chenry/CheckBroadEss/".$Filename."/");
			}
			system("cp ".$Directory."FBA-".$ModelID.$Version.".lp /home/chenry/CheckBroadEss/".$Filename."/FBA-".$ModelID.$Version.".lp");
			system("cp ".$Directory."FBA-".$ModelID.$Version.".key /home/chenry/CheckBroadEss/".$Filename."/FBA-".$ModelID.$Version.".key");
			system("cp ".$Directory.$ModelID.$Version.".txt /home/chenry/CheckBroadEss/".$Filename."/".$ModelID.$Version.".txt");

			#Adding the job list
			for (my $i=0; $i < @{$KOList}; $i++) {
				for (my $j=0; $j < $JobArray->size(); $j++) {
					my @Headings = $JobArray->headings();
					my $NewRow;
					for (my$k=0; $k < @Headings; $k++) {
						if (defined($JobArray->get_row($j)->{$Headings[$k]})) {
							push(@{$NewRow->{$Headings[$k]}},@{$JobArray->get_row($j)->{$Headings[$k]}});
						}
					}
					$NewRow->{"REACTION KO"}->[0] = $KOList->[$i];
					$JobTable->add_row($NewRow);
				}
			}
		}

		#Printing the jobs tables
		my $JobsPerProcessor = int($JobTable->size()/$NumProcessors)+1;
		my $Count = 0;
		for (my $i=0; $i < $NumProcessors; $i++) {
			my $NewJobTable = $JobTable->clone_table_def();
			for (my $j=0; $j < $JobsPerProcessor; $j++) {
				if ($JobTable->size() > $Count) {
					$NewJobTable->add_row($JobTable->get_row($Count));
				}
				$Count++;
			}
			$NewJobTable->save("/home/chenry/CheckBroadEss/".$Filename."/JobTable-".$i.".txt");
			system($self->{"scheduler executable"}->[0]." \"add:runmfalite?/home/chenry/CheckBroadEss/".$Filename."/JobTable-".$i.".txt?/home/chenry/CheckBroadEss/".$Filename."/Output-".$i.".txt:BACK:test:QSUB\"");
		}
	} else {
		#Parsing the job results files
		my $CurrentResults;
		my $CurrentReaction = "";
		my $CurrentModel = "";
		my $model;
		my $Version;
		my $Directory;
		my $ExperimentalDataTable;
		my $JobArray;
		my $ModelID;
		my $EssentialityResults;
		for (my $i=0; $i < $NumProcessors; $i++) {
			#Parsing the output from job file i
			my $Results = ModelSEED::FIGMODEL::FIGMODELTable::load_table("/home/chenry/CheckBroadEss/".$Filename."/Output-".$i.".txt",";","\\|",0,undef);
			if (defined($Results)) {
				for (my $j=0; $j < $Results->size();$j++) {
					my $Row = $Results->get_row($j);
					if (defined($Row->{"MODEL"}->[0]) && $Row->{"MODEL"}->[0] =~ m/\/([^\/]+)\.txt/) {
						my $NewModel = $1;
						if (defined($Row->{"KOREACTIONS"}->[0]) && $Row->{"KOREACTIONS"}->[0] ne "none") {
							#Handling the transition to a new reaction
							if ($CurrentReaction ne $Row->{"KOREACTIONS"}->[0] || $CurrentModel ne $NewModel) {
								#Processing the results for the current model and reaction
								if (defined($model)) {
									my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector,$SimulationResults) = $self->get_model($ModelID.$Version)->EvaluateSimulationResults($CurrentResults,$ExperimentalDataTable);
									push(@{$EssentialityResults},$CurrentReaction.";".$FalsePostives.";".$FalseNegatives);
								}
								$CurrentReaction = $Row->{"KOREACTIONS"}->[0];
								#Clearing out the current results table
								$CurrentResults = $Results->clone_table_def();
							}
							#Handling the transition to a new model
							if ($CurrentModel ne $NewModel) {
								#Printing the results from the previous model if there was one
								if (defined($model) && defined($EssentialityResults) && @{$EssentialityResults} > 0) {
									PrintArrayToFile($Directory.$ModelID.$Version."-ReactionKOResult.txt",$EssentialityResults,1);
									$EssentialityResults = ();
								}
								$CurrentModel = $NewModel;
								#Checking if model exists
								$model = $self->get_model($CurrentModel);
								if (!defined($model)) {
									print STDERR "FIGMODEL:CheckReactionEssentiality: Could not find model ".$CurrentModel.".\n";
								} else {
									$Version = "";
									$Directory = $model->directory();
									if (defined($model->version())) {
										$Version = $model->version();
									}
									$ModelID = $model->id();
									#Determing the simulations that need to be run
									$ExperimentalDataTable = $self->GetExperimentalDataTable($model->genome(),"All");
									#Creating the table of jobs to submit
									$JobArray = $self->get_model($ModelID.$Version)->GetSimulationJobTable($ExperimentalDataTable,"All",$Filename);
								}
							}
							$CurrentResults->add_row($Row);
						}
					}
				}
			}
		}
		#Processing the results for the final model and reaction
		if (defined($model)) {
			my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector,$SimulationResults) = $self->get_model($ModelID.$Version)->EvaluateSimulationResults($CurrentResults,$ExperimentalDataTable);
			push(@{$EssentialityResults},$CurrentReaction.";".$FalsePostives.";".$FalseNegatives);
			#Printing the results for the final model
			if (defined($EssentialityResults) && @{$EssentialityResults} > 0) {
				PrintArrayToFile($Directory.$ModelID.$Version."-ReactionKOResult.txt",$EssentialityResults,1);
			}
		}
	}

	return 1;
}

=head3 TestDatabaseBiomassProduction
Definition:
	$model->TestDatabaseBiomassProduction($Biomass,$Media,$BalancedReactionsOnly);
Description:
Example:
=cut

sub TestDatabaseBiomassProduction {
	my ($self,$Biomass,$Media,$BalancedReactionsOnly) = @_;

	my $BalanceParameter = 1;
	if (defined($BalancedReactionsOnly) && $BalancedReactionsOnly == 0) {
		$BalanceParameter = 0;
	}

	my $UniqueFilename = $self->filename();
	if (defined($Media) && $Media ne "Complete" && -e $self->{"Media directory"}->[0].$Media.".txt") {
		#Loading media, changing bounds, saving media as a test media
		my $MediaTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"Media directory"}->[0].$Media.".txt",";","",0,["VarName"]);
		for (my $i=0; $i < $MediaTable->size(); $i++) {
			if ($MediaTable->get_row($i)->{"Min"}->[0] < 0) {
				$MediaTable->get_row($i)->{"Min"}->[0] = -10000;
			}
			if ($MediaTable->get_row($i)->{"Max"}->[0] > 0) {
				$MediaTable->get_row($i)->{"Max"}->[0] = 10000;
			}
		}
		$MediaTable->save($self->{"Media directory"}->[0].$UniqueFilename."TestMedia.txt");
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,"Complete",$UniqueFilename."TestMedia",["DatabaseMFA"],{"Default max drain flux" => 0,"Complete model biomass reaction" => $Biomass,"Balanced reactions in gap filling only" => $BalanceParameter},"DatabaseBiomassTest-".$Biomass."-".$Media.".log",undef));
		unlink($self->{"Media directory"}->[0].$UniqueFilename."TestMedia.txt");
	} else {
		system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,"Complete","NONE",["DatabaseMFA"],{"Complete model biomass reaction" => $Biomass,"Balanced reactions in gap filling only" => $BalanceParameter},"DatabaseBiomassTest-".$Biomass."-".$Media.".log",undef));
	}
	#If the system is not configured to preserve all logfiles, then the output printout from the mfatoolkit is deleted
	if ($self->{"preserve all log files"}->[0] eq "no") {
		unlink($self->{"database message file directory"}->[0]."DatabaseBiomassTest-".$Biomass."-".$Media.".log");
	}

	#Reading the problem report and parsing out the zero production metabolites
	my $ProblemReport = $self->LoadProblemReport($UniqueFilename);
	return $ProblemReport;
}

=head3 GapGenerationAlgorithm

Definition:
	$model->GapGenerationAlgorithm($ModelName,$NumberOfProcessors,$ProcessorIndex,$Filename);

Description:

Example:
	$model->GapGenerationAlgorithm("Seed100226.1");

=cut
sub GapGenerationAlgorithm {
	my ($self,$ModelID,$ProcessIndex,$Media,$KOList,$NoKOList,$NumProcesses) = @_;
	my $model = $self->get_model($ModelID);
	#Getting unique filename
	my $Filename = $self->filename();
	#This is the code for the scheduler
	if (!defined($ProcessIndex) || $ProcessIndex == -1) {
		#Now we check that the reaction essentiality file exist
		if (!-e $model->directory().$model->id().$model->selected_version()."-ReactionKOResult.txt") {
			print STDERR "FIGMODEL:GapGenerationAlgorithm: Reaction essentiality file not found for ".$model->id().$model->selected_version().".\n";
			return 0;
		}

		#Determining the performance of the wildtype model
		my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $model->RunAllStudiesWithDataFast("All");
		PrintArrayToFile($model->directory().$model->id().$model->selected_version()."-GGOPEM".".txt",[$HeadingVector,$Errorvector]);

		#Now we read in the reaction essentiality file
		my $EssentialityTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($model->directory().$model->id().$model->selected_version()."-ReactionKOResult.txt",";","",0,["REACTION"]);
		#Identifying which reactions should not be knocked out by the gap generation
		my $ConservedList;
		for (my $i=0; $i < $EssentialityTable->size(); $i++) {
			if (($EssentialityTable->get_row($i)->{"FALSE NEGATIVES"}->[0] - $FalseNegatives) > 5) {
				push(@{$ConservedList},$EssentialityTable->get_row($i)->{"REACTION"}->[0]);
			}
		}
		$NoKOList = join(",",@{$ConservedList});

		#Now we use the simulation output to make the gap generation run data
		my @Errors = split(/;/,$Errorvector);
		my @Headings = split(/;/,$HeadingVector);
		my $GapGenerationRunData;
		my $Count = 0;
		for (my $i=0; $i < @Errors; $i++) {
			if ($Errors[$i] == 2) {
				my @HeadingDataArray = split(/:/,$Headings[$i]);
				$GapGenerationRunData->[$Count]->[2] = $HeadingDataArray[2];
				$GapGenerationRunData->[$Count]->[0] = $HeadingDataArray[3];
				$GapGenerationRunData->[$Count]->[1] = $HeadingDataArray[1];
				$GapGenerationRunData->[$Count]->[0] =~ s/;/,/g;
				$Count++;
			}
		}

		#Checking if there are no false positives
		if (!defined($GapGenerationRunData) || @{$GapGenerationRunData} == 0) {
			print "NO FALSE POSITIVE PREDICTIONS FOR MODEL\n";
			return 1;
		}

		#Scheduling all the gap generation optimization jobs
		my $ProcessList;
		if (-e $model->directory().$model->id().$model->selected_version()."-GG-0-S.txt") {
			unlink($model->directory().$model->id().$model->selected_version()."-GG-0-EM.txt");
			unlink($model->directory().$model->id().$model->selected_version()."-GG-0-S.txt");
		}
		for (my $i=1; $i < @{$GapGenerationRunData}; $i++) {
			#Deleting any old residual problem reports
			if (-e $model->directory().$model->id().$model->selected_version()."-GG-".$i."-S.txt") {
				unlink($model->directory().$model->id().$model->selected_version()."-GG-".$i."-S.txt");
				unlink($model->directory().$model->id().$model->selected_version()."-GG-".$i."-EM.txt");
			}
			push(@{$ProcessList},"rungapgeneration?".$model->id().$model->selected_version()."?".$i."?".$GapGenerationRunData->[$i]->[1]."?".$GapGenerationRunData->[$i]->[0]."?".$NoKOList."?".@{$GapGenerationRunData});
		}
		PrintArrayToFile($self->{"temp file directory"}->[0]."GapGenQueue-".$model->id().$model->selected_version()."-".$Filename.".txt",$ProcessList);
		system($self->{"scheduler executable"}->[0]." \"add:".$self->{"temp file directory"}->[0]."GapGenQueue-".$model->id().$model->selected_version()."-".$Filename.".txt:BACK:test:QSUB\"");
		unlink($self->{"temp file directory"}->[0]."GapGenQueue-".$model->id().$model->selected_version()."-".$Filename.".txt");

		#Converting this processor into process zero
		$ProcessIndex = 0;
		$Media = $GapGenerationRunData->[0]->[1];
		$KOList = $GapGenerationRunData->[0]->[0];
		$NumProcesses = @{$GapGenerationRunData};
	}

	#This code handles the running and testing of gap generation solutions
	if ($ProcessIndex != -2) {
		my $GapGenResults = $model->datagapgen($Media,$KOList,$NoKOList,"-".$ProcessIndex."-S");
		$GapGenResults->save();
		system($self->{"scheduler executable"}->[0]." \"add:testsolutions?".$model->id().$model->selected_version()."?0?GG-".$ProcessIndex."-?1:BACK:fast:QSUB\"");
		#Checking if this is the last process to finish
		my $Last = 1;
		for (my $i=0; $i < $NumProcesses; $i++) {
			if (!-e $model->directory().$model->id().$model->selected_version()."-GG-".$i."-S.txt") {
				$Last = 0;
			}
		}
		#If this is the last job to finish, we activate the cleanup gap generation
		if ($Last == 1) {
			system($self->{"scheduler executable"}->[0]." \"add:rungapgeneration?".$model->id().$model->selected_version()."?-2:BACK:fast:QSUB\"");
		}
		return 1;
	}

	#This code combines all of the output from the job threads into a single file and a single error matrix
	my @FileList = glob($model->directory().$model->id().$model->selected_version()."-GG-*");
	my $TestList;
	my $CombinedFile = ["Experiment;Solution index;Solution cost;Solution reactions"];
	foreach my $Filename (@FileList) {
		if ($Filename =~ m/(.+-)S\.txt$/) {
			push(@{$TestList},$1."EM.txt");
			my $CurrentFile = LoadSingleColumnFile($Filename,"");
			#unlink($Filename);
			shift(@{$CurrentFile});
			push(@{$CombinedFile},@{$CurrentFile});
		}
	}
	PrintArrayToFile($model->directory().$model->id().$model->selected_version()."-GGS.txt",$CombinedFile);
	#Waiting for all solution testing to complete
	my $Done = 0;
	while ($Done == 0) {
		$Done = 1;
		foreach my $Filename (@{$TestList}) {
			if (!-e $Filename) {
				$Done = 0;
				last;
			}
		}
		if ($Done == 0) {
			sleep(180);
		}
	}
	#Combining the error file
	$CombinedFile = undef;
	foreach my $Filename (@{$TestList}) {
		my $CurrentFile = LoadSingleColumnFile($Filename,"");
		push(@{$CombinedFile},@{$CurrentFile});
	}
	PrintArrayToFile($model->directory().$model->id().$model->selected_version()."-GGEM.txt",$CombinedFile);
	#Adding model to the reconciliation queue
	system($self->{"scheduler executable"}->[0]." \"add:reconciliation?".$model->id().$model->selected_version()."?0:FRONT:cplex:QSUB\"");

	return 1;
}

=head3 SwiftGapGeneationAlgorithm
Definition:
	$model->SwiftGapGeneationAlgorithm($ModelName,$Filename);
Description:
Example:
	$model->SwiftGapGeneationAlgorithm("Seed100226.1");
=cut

sub SwiftGapGeneationAlgorithm {
	my ($self,$ModelID,$Filename,$Stage) = @_;

	#Checking that the input directory exists
	if (defined(!$Filename)) {
		$Filename = "CurrentSwift/";
	}
	if (!-d "/home/chenry/SwiftGapGen/".$Filename) {
		system("mkdir /home/chenry/SwiftGapGen/".$Filename);
	}

	#First checking that the model exists and finding model directory and version
	my $model = $self->get_model($ModelID);
	if (!defined($model)) {
		print STDERR "FIGMODEL:GapGenerationAlgorithm: Could not find model ".$ModelID.".\n";
		return 0;
	}
	my $Version = "";
	my $Directory = $model->directory();
	if (defined($model->version())) {
		$Version = $model->version();
	}
	$ModelID = $model->id();

	#Printing the problem definition files for each false positive
	if (!defined($Stage)) {
		#Now we check that the reaction essentiality file exist
		if (!-e $Directory.$ModelID.$Version."-ReactionKOResult.txt") {
			print STDERR "FIGMODEL:GapGenerationAlgorithm: Reaction essentiality file not found for ".$ModelID.$Version.".\n";
			return 0;
		}
		#my $UniqueFilename = $self->filename();
		my $UniqueFilename = "CurrentSwift";

		#Determining the performance of the wildtype model
		my ($FalsePostives,$FalseNegatives,$CorrectNegatives,$CorrectPositives,$Errorvector,$HeadingVector) = $self->get_model($ModelID.$Version)->RunAllStudiesWithDataFast("All");
		PrintArrayToFile($Directory.$ModelID.$Version."-GGOPEM".".txt",[$HeadingVector,$Errorvector]);

		#Now we read in the reaction essentiality file
		my $EssentialityTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory.$ModelID.$Version."-ReactionKOResult.txt",";","",0,["REACTION"]);

		#Identifying which reactions should not be knocked out by the gap generation
		my $ConservedList;
		for (my $i=0; $i < $EssentialityTable->size(); $i++) {
			if (($EssentialityTable->get_row($i)->{"FALSE NEGATIVES"}->[0] - $FalseNegatives) > 5) {
				push(@{$ConservedList},$EssentialityTable->get_row($i)->{"REACTION"}->[0]);
			}
		}
		my $NoKOList = join(";",@{$ConservedList});

		#Now we use the simulation output to make the gap generation run data
		my @Errors = split(/;/,$Errorvector);
		my @Headings = split(/;/,$HeadingVector);
		my $GapGenerationRunData;
		my $Count = 0;
		my $FileList;
		for (my $i=0; $i < @Errors; $i++) {
			if ($Errors[$i] == 2) {
				#Now we use the MFAToolkit to print a gap generation problem definition file for each false positive
				my @HeadingDataArray = split(/:/,$Headings[$i]);
				system($self->GenerateMFAToolkitCommandLineCall($UniqueFilename,$ModelID,$HeadingDataArray[1],["ProdGapGenerationPrint"],{"Reactions that should always be active" => $NoKOList,"Reactions to knockout" => $HeadingDataArray[3],"MFASolver" => "SCIP","Reactions that are always blocked" => "none"},$self->{"database message file directory"}->[0].$ModelID.$Version."-GG-".$i.".log",undef,$Version));
				#Copying the printed data to the gapgen prep directory
				my $OutputFile = $ModelID.$Version."_".$HeadingDataArray[0]."_".$HeadingDataArray[1]."_".$HeadingDataArray[2];
				$OutputFile =~ s/\s//;
				system("cp ".$self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/CurrentProblem.lp /home/chenry/SwiftGapGen/".$Filename."/".$OutputFile.".lp");
				my $KeyTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{"MFAToolkit output directory"}->[0].$UniqueFilename."/VariableKey.txt",";","|",0,undef);
				$KeyTable->headings(["Variable type","Variable ID"]);
				$KeyTable->save("/home/chenry/SwiftGapGen/".$Filename."/".$OutputFile.".key");
				push(@{$FileList},$OutputFile.".lp");
			}
		}
		PrintArrayToFile("/home/chenry/SwiftGapGen/".$Filename."/Joblist.txt",$FileList,1);
		#$self->cleardirectory($UniqueFilename);
	} else {
		#This code translates the solution files for each false positive into a single GGS file
		#Scheduling the testing
		system($self->{"scheduler executable"}->[0]." \"add:testsolutions?".$ModelID.$Version."?0?GG?1:BACK:fast:QSUB\"");
	}

	return 1;
}

=head3 IntegrateGrowMatchSolution
Definition:
	my $ChangeHash = $model->IntegrateGrowMatchSolution($ModelName,$NewModelFilename,$ReactionArrayRef,$DirectionArrayRef,$Note,$ClearCache,$PrintModel);
Description:
Example:

=cut

sub IntegrateGrowMatchSolution {
	my ($self,$ModelName,$NewModelFilename,$ReactionArray,$DirectionArray,$Note,$ClearCache,$PrintModel,$AddOnly) = @_;

	#Loading the original model
	if (defined($ClearCache) && $ClearCache == 1) {
		$self->database()->ClearDBModel($ModelName,"DELETE");
	}
	my $ModelTable = $self->database()->GetDBModel($ModelName);
	$ModelTable->add_headings("NOTES");
	if (!defined($ModelTable)) {
		print STDERR "FIGMODEL:IntegrateGrowMatchSolution: Could not load model data: ".$ModelName."\n";
		return undef;
	}

	#Getting the original model filename if no filename is supplied
	if (!defined($NewModelFilename)) {
		$NewModelFilename = $ModelTable->filename();
	}

	#Setting the note to "GrowMatch" if no note is provided
	if (!defined($Note)) {
		$Note = "GROWTHMATCH";
	}

	#Adding the reactions in the solution to a hash
	my $Changes;
	for (my $k=0; $k < @{$ReactionArray}; $k++) {
		my $Reaction = $ReactionArray->[$k];
		my $Direction = $DirectionArray->[$k];
		#Checking if the solution reaction is in the model
		my $Row = $ModelTable->get_row_by_key($Reaction,"LOAD");
		if (defined($Row)) {
			#If the reaction is already present, this is a gap generation reaction and should be removed
			if ($Row->{"DIRECTIONALITY"}->[0] eq "<=>") {
				#Making the gap generation reaction irreversible
				if ($Direction eq "=>" && (!defined($AddOnly) || $AddOnly == 0)) {
					$Row->{"DIRECTIONALITY"}->[0] = "<=";
					$Changes->{$Direction.$Reaction} = "CHANGED:<=";
				} elsif (!defined($AddOnly) || $AddOnly == 0) {
					$Row->{"DIRECTIONALITY"}->[0] = "=>";
					$Changes->{$Direction.$Reaction} = "CHANGED:=>";
				}
			} elsif ($Row->{"DIRECTIONALITY"}->[0] eq $Direction && (!defined($AddOnly) || $AddOnly == 0)) {
				#Removing the gap generation reaction entirely
				$ModelTable->delete_row($ModelTable->row_index($Row));
				$Changes->{$Direction.$Reaction} = "REMOVED";
			} else {
				#This is a reversibility gap filling reaction
				$Row->{"NOTES"}->[0] = "Directionality switched from ".$Row->{"DIRECTIONALITY"}->[0]." to <=> during gap filling process";
				$Row->{"DIRECTIONALITY"}->[0] = "<=>";
				$Changes->{$Direction.$Reaction} = "CHANGED:<=>";
			}
		} else {
			#If the reaction is not in the model, it is added
			$ModelTable->add_row({"LOAD" => [$Reaction], "DIRECTIONALITY" => [$Direction], "COMPARTMENT" => ["c"], "ASSOCIATED PEG" => [$Note], "SUBSYSTEM" => ["NONE"], "CONFIDENCE" => ["NONE"], "REFERENCE" => ["NONE"],"NOTES" => ["Reaction added during ".$Note]});
			$Changes->{$Direction.$Reaction} = "ADDED:".$Direction;
		}
	}
	#Printing the test model
	if (defined($PrintModel) && $PrintModel == 1) {
		$ModelTable->save($NewModelFilename);
	}
	return $Changes;
}

=head3 CombineAllReconciliation
Definition:
	$model->CombineAllReconciliation($ModelList);
Description:
Example:
	$model->CombineAllReconciliation(["Opt83333.1","Opt224308.1"]);
=cut

sub CombineAllReconciliation {
	my ($self,$ModelList,$Run,$SelectedSolutions,$OkayReactionsFile,$BlackListReactionsFile,$IntegrateSolution) = @_;

	#All final integrated solutions will be stored here
	my $FinalSolutions;

	#Reactions that need human attention will be posted here
	my $AttentionTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["STATUS","KEY","DATABASE","DEFINITION","DELTAG","REVERSIBLITY","DIRECTION","CONFLICT","NUMBER OF SOLUTIONS"],"/home/chenry/AttentionTable.txt",["KEY"],";","|",undef);;
	$AttentionTable->add_row({"KEY" => ["SINGLET REACTIONS"],"DATABASE" => ["SINGLET REACTIONS"]});

	#Parsing selected solution file
	my %SolutionSelectHash;
	my %OkayReactions;
	my %BlackListReactions;
	if (-e $SelectedSolutions) {
		my $Data = LoadMultipleColumnFile($SelectedSolutions," ");
		for (my $i=0;$i < @{$Data}; $i++) {
			if (@{$Data->[$i]} >= 2) {
				$SolutionSelectHash{$Data->[$i]->[0]} = $Data->[$i]->[1];
			}
		}
	}
	if (-e $OkayReactionsFile) {
		my $Data = LoadSingleColumnFile($OkayReactionsFile," ");
		for (my $i=0;$i < @{$Data}; $i++) {
			$OkayReactions{$Data->[$i]} = 1;
		}
	}
	if (-e $BlackListReactionsFile) {
		my $Data = LoadSingleColumnFile($BlackListReactionsFile," ");
		for (my $i=0;$i < @{$Data}; $i++) {
			$BlackListReactions{$Data->[$i]} = 1;
		}
	}

	#All alternative sets stored in this hash
	my $Sets;
	my $SetHash;
	my $AlternativeHash;

	#All results will be stored in this combined table
	my $ResultTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["KEY","DATABASE","DEFINITION","DELTAG","REVERSIBLITY","DIRECTION","CONFLICT","NUMBER OF SOLUTIONS"],"NONE",["KEY"],";","|",undef);
	$ResultTable->add_row({"KEY" => ["SINGLET REACTIONS"],"DATABASE" => ["SINGLET REACTIONS"]});

	#Scanning through the model list
	for (my $i=0; $i < @{$ModelList}; $i++) {
		my $ModelID = $ModelList->[$i];
		my $model = $self->get_model($ModelID);
		if (defined($model) && -e $model->directory().$ModelID."-".$Run."Reconciliation.txt") {
			if (defined($SolutionSelectHash{$ModelID})) {
				$ResultTable->add_headings(($ModelID." ".$SolutionSelectHash{$ModelID}));
				$AttentionTable->add_headings(($ModelID));
			}

			my $CurrentData = ModelSEED::FIGMODEL::FIGMODELTable::load_table($model->directory().$ModelID."-".$Run."Reconciliation.txt",";","",0,["DATABASE"]);
			my $CurrentAlternative = -1;
			my $AlternativeList;
			for (my $j=0; $j < $CurrentData->size(); $j++) {
				my $Row = $CurrentData->get_row($j);
				if (defined($Row->{"DATABASE"}->[0]) && $Row->{"DATABASE"}->[0] ne "SINGLET REACTIONS") {
					if ($Row->{"DATABASE"}->[0] eq "NEW SET") {
						if ($CurrentAlternative == -1) {
							$AttentionTable->add_row({"KEY" => ["SINGLET REACTIONS"],"DATABASE" => ["SELECTED ALTERNATIVES"]});
						}
						if ($CurrentAlternative != -1 && defined($AlternativeList)) {
							#Checking if set has been observed before
							my $Set = undef;
							my $AcceptableSolutionFound = -1;
							my $AcceptableKey;
							my $KeyList;
							my $GoodSolution = 0;
							for (my $k=0; $k < @{$AlternativeList}; $k++) {
								if (defined($AlternativeList->[$k])) {
									$GoodSolution++;
									#Saving the set
									my $Key = join(",",sort(@{$AlternativeList->[$k]}));
									push(@{$KeyList},$Key);
									if (!defined($Set) && defined($SetHash->{$Key})) {
										$Set = $SetHash->{$Key};
									}
									#Checking if the solution contains conflict reactions or blacklist reactions
									if (defined($SolutionSelectHash{$ModelID}) && $AcceptableSolutionFound == -1) {
										$AcceptableSolutionFound = $k;
										$AcceptableKey = $Key;
										for (my $m=0; $m < @{$AlternativeList->[$k]}; $m++) {
											if (defined($BlackListReactions{$AlternativeList->[$k]->[$m]}) || ($AlternativeHash->{$AlternativeList->[$k]->[$m]}->{"REVERSIBLITY"}->[0] ne $AlternativeHash->{$AlternativeList->[$k]->[$m]}->{"DIRECTION"}->[0] && $AlternativeHash->{$AlternativeList->[$k]->[$m]}->{"REVERSIBLITY"}->[0] ne "<=>" && !defined($OkayReactions{$AlternativeList->[$k]->[$m]}))) {
												$AcceptableSolutionFound = -1;
												last;
											}
										}
									}
								}
							}
							my $New = 0;
							if (!defined($Set)) {
								$New = 1;
							}
							#Now checking if set contains all of the alternatives
							my $NewAcceptableSolution = 0;
							if ($GoodSolution > 0 && defined($SolutionSelectHash{$ModelID}) && $AcceptableSolutionFound == -1) {
								#Adding a new "no good alternative" section to the attention table if a matching section does not already exist
								$AcceptableKey = join(",",sort(@{$KeyList}));
								if (!defined($AttentionTable->get_row_by_key($AcceptableKey,"KEY"))) {
									$NewAcceptableSolution = 1;
									$AttentionTable->add_row({"KEY" => [$AcceptableKey],"DATABASE" => ["NO ACCEPTABLE SOLUTION"]});
								}
							} elsif ($GoodSolution > 0 && defined($SolutionSelectHash{$ModelID})) {
								if (!defined($AttentionTable->get_row_by_key($AcceptableKey,"KEY"))) {
									$NewAcceptableSolution = 1;
									$AttentionTable->add_row({"KEY" => [$AcceptableKey],"DATABASE" => ["ACCEPTABLE SOLUTION"]});
								}
							}
							for (my $k=0; $k < @{$AlternativeList}; $k++) {
								if (defined($AlternativeList->[$k])) {
									if (defined($SolutionSelectHash{$ModelID})) {
										if ($AcceptableSolutionFound == -1 && $NewAcceptableSolution == 1) {
											#Adding a new "no good alternative" section to the attention table if a matching section does not already exis
											$AttentionTable->add_row({"KEY" => [$AcceptableKey],"DATABASE" => ["ALTERNATIVE"]});
											for (my $m=0; $m < @{$AlternativeList->[$k]}; $m++) {
												my $NewRow = $AlternativeHash->{$AlternativeList->[$k]->[$m]};
												my $OriginalKey = $NewRow->{"KEY"}->[0];
												$NewRow->{"KEY"}->[0] = $NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0];
												my $AttentionRow = $AttentionTable->add_row_copy($NewRow);
												$NewRow->{"KEY"}->[0] = $OriginalKey;
												$AttentionRow->{$ModelID} = 1;
											}
										} elsif ($AcceptableSolutionFound == $k) {
											for (my $m=0; $m < @{$AlternativeList->[$k]}; $m++) {
												my $NewRow = $AlternativeHash->{$AlternativeList->[$k]->[$m]};
												if ($Run eq "GG" || ($NewRow->{"REVERSIBLITY"}->[0] ne $NewRow->{"DIRECTION"}->[0] && $NewRow->{"REVERSIBLITY"}->[0] ne "<=>")) {
													($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$NewRow->{"DATABASE"}->[0].";".$NewRow->{"DIRECTION"}->[0]);
												} else {
													($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$NewRow->{"DATABASE"}->[0].";".$NewRow->{"REVERSIBLITY"}->[0]);
												}
												my $AttentionRow;
												if ($NewAcceptableSolution == 1) {
													my $OriginalKey = $NewRow->{"KEY"}->[0];
													$NewRow->{"KEY"}->[0] = $NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0]."|".$AcceptableKey;
													$AttentionRow = $AttentionTable->add_row_copy($NewRow);
													$NewRow->{"KEY"}->[0] = $OriginalKey;
												} else {
													$AttentionRow = $AttentionTable->get_row_by_key($NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0]."|".$AcceptableKey,"KEY");
												}
												$AttentionRow->{$ModelID} = 1;
											}
										}
									}

									my $Key = join(",",sort(@{$AlternativeList->[$k]}));
									if (!defined($SetHash->{$Key})) {
										push(@{$Set},$AlternativeList->[$k]);
										$SetHash->{$Key} = $Set;
									}
								}
							}
							if ($New == 1) {
								push(@{$Sets},$Set);
							}
						}
						$AlternativeList = ();
						$CurrentAlternative = 0;
					} elsif ($Row->{"DATABASE"}->[0] eq "ALTERNATIVE SET") {
						$CurrentAlternative++;
					} elsif ($Row->{"DATABASE"}->[0] =~ m/rxn\d\d\d\d\d/) {
						if (!defined($SolutionSelectHash{$ModelID}) || defined($Row->{"Solution ".$SolutionSelectHash{$ModelID}})) {
							if ($CurrentAlternative == -1) {
								my $NewRow = $ResultTable->get_row_by_key($Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0],"KEY");
								if (!defined($NewRow)) {
									$NewRow = {"KEY" => [$Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0]],"DATABASE" => [$Row->{"DATABASE"}->[0]],"DEFINITION" => [$Row->{"DEFINITION"}->[0]],"DELTAG" => [$Row->{"DELTAG"}->[0]],"REVERSIBLITY" => [$Row->{"REVERSIBLITY"}->[0]],"DIRECTION" => [$Row->{"DIRECTION"}->[0]],"NUMBER OF SOLUTIONS" => [0]};
									$ResultTable->add_row($NewRow);
									if ($NewRow->{"REVERSIBLITY"}->[0] eq "=>" && $NewRow->{"DIRECTION"}->[0] eq "<=") {
										$NewRow->{"CONFLICT"}->[0] = "YES";
									} elsif ($NewRow->{"REVERSIBLITY"}->[0] eq "<=" && $NewRow->{"DIRECTION"}->[0] eq "=>") {
										$NewRow->{"CONFLICT"}->[0] = "YES";
									}
								}

								my $Count = 0;
								for (my $n=6; $n < $CurrentData->headings(); $n++) {
									if (defined($Row->{"Solution ".$Count}->[0])) {
										$NewRow->{"NUMBER OF SOLUTIONS"}->[0]++;
										$NewRow->{$ModelID." ".$Count}->[0] = $Row->{"Solution ".$Count}->[0];
										if (!defined($SolutionSelectHash{$ModelID})) {
											$ResultTable->add_headings(($ModelID." ".$Count));
										} elsif ($SolutionSelectHash{$ModelID} == $Count) {
											if (defined($NewRow->{"CONFLICT"}->[0]) && $NewRow->{"CONFLICT"}->[0] eq "YES") {
												$NewRow->{"STATUS"}->[0] = "INFEASIBLE";
												my $AttentionRow = $AttentionTable->get_row_by_key($NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0],"KEY");
												if (!defined($AttentionRow)) {
													$AttentionTable->add_row($NewRow,0);
													$AttentionRow = $NewRow;
												}
												$AttentionRow->{$ModelID}->[0] = $Row->{"Solution ".$Count}->[0];
												if (defined($OkayReactions{$AttentionRow->{"DATABASE"}->[0].$AttentionRow->{"DIRECTION"}->[0]})) {
													$AttentionRow->{"STATUS"}->[0] = "OKAY LIST";
													if ($Run eq "GF") {
														($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$AttentionRow->{"DATABASE"}->[0].";<=>");
													} else {
														($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$AttentionRow->{"DATABASE"}->[0].";".$AttentionRow->{"DIRECTION"}->[0]);
													}
												}
											} elsif (defined($BlackListReactions{$NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0]})) {
												$NewRow->{"STATUS"}->[0] = "BLACKLIST";
												my $AttentionRow = $AttentionTable->get_row_by_key($NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0],"KEY");
												if (!defined($AttentionRow)) {
													$AttentionTable->add_row($NewRow,0);
													$AttentionRow = $NewRow;
												}
												$AttentionRow->{$ModelID}->[0] = $Row->{"Solution ".$Count}->[0];
											} else {
												if ($Run eq "GF") {
													($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$NewRow->{"DATABASE"}->[0].";".$NewRow->{"REVERSIBLITY"}->[0]);
												} else {
													($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$NewRow->{"DATABASE"}->[0].";".$NewRow->{"DIRECTION"}->[0]);
												}
											}
										}
									}
									$Count++;
								}
							} else {
								push(@{$AlternativeList->[$CurrentAlternative]},$Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0]);
								if (!defined($AlternativeHash->{$Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0]})) {
									$AlternativeHash->{$Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0]} = $Row;
								}
								my $NewRow = $AlternativeHash->{$Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0]};
								my $Count = 0;
								for (my $n=6; $n < $CurrentData->headings(); $n++) {
									if (defined($Row->{"Solution ".$Count}->[0])) {
										$NewRow->{"NUMBER OF SOLUTIONS"}->[0]++;
										$NewRow->{$ModelID." ".$Count}->[0] = $Row->{"Solution ".$Count}->[0];
										if (!defined($SolutionSelectHash{$ModelID})) {
											$ResultTable->add_headings(($ModelID." ".$Count));
										}
									}
									$Count++;
								}
							}
						}
					}
				}
			}
			#Adding final reaction set if there is one
			if ($CurrentAlternative != -1 && defined($AlternativeList)) {
				#Checking if set has been observed before
				my $Set = undef;
				my $AcceptableSolutionFound = -1;
				my $AcceptableKey;
				my $KeyList;
				my $GoodSolution = 0;
				for (my $k=0; $k < @{$AlternativeList}; $k++) {
					if (defined($AlternativeList->[$k])) {
						$GoodSolution++;
						#Saving the set
						my $Key = join(",",sort(@{$AlternativeList->[$k]}));
						push(@{$KeyList},$Key);
						if (!defined($Set) && defined($SetHash->{$Key})) {
							$Set = $SetHash->{$Key};
						}
						#Checking if the solution contains conflict reactions or blacklist reactions
						if (defined($SolutionSelectHash{$ModelID}) && $AcceptableSolutionFound == -1) {
							$AcceptableSolutionFound = $k;
							$AcceptableKey = $Key;
							for (my $m=0; $m < @{$AlternativeList->[$k]}; $m++) {
								if (defined($BlackListReactions{$AlternativeList->[$k]->[$m]}) || ($AlternativeHash->{$AlternativeList->[$k]->[$m]}->{"REVERSIBLITY"}->[0] ne $AlternativeHash->{$AlternativeList->[$k]->[$m]}->{"DIRECTION"}->[0] && $AlternativeHash->{$AlternativeList->[$k]->[$m]}->{"REVERSIBLITY"}->[0] ne "<=>" && !defined($OkayReactions{$AlternativeList->[$k]->[$m]}))) {
									$AcceptableSolutionFound = -1;
									last;
								}
							}
						}
					}
				}
				my $New = 0;
				if (!defined($Set)) {
					$New = 1;
				}
				#Now checking if set contains all of the alternatives
				my $NewAcceptableSolution = 0;
				if ($GoodSolution > 0 && defined($SolutionSelectHash{$ModelID}) && $AcceptableSolutionFound == -1) {
					#Adding a new "no good alternative" section to the attention table if a matching section does not already exist
					$AcceptableKey = join(",",sort(@{$KeyList}));
					if (!defined($AttentionTable->get_row_by_key($AcceptableKey,"KEY"))) {
						$NewAcceptableSolution = 1;
						$AttentionTable->add_row({"KEY" => [$AcceptableKey],"DATABASE" => ["NO ACCEPTABLE SOLUTION"]});
					}
				} elsif ($GoodSolution > 0 && defined($SolutionSelectHash{$ModelID})) {
					if (!defined($AttentionTable->get_row_by_key($AcceptableKey,"KEY"))) {
						$NewAcceptableSolution = 1;
						$AttentionTable->add_row({"KEY" => [$AcceptableKey],"DATABASE" => ["ACCEPTABLE SOLUTION"]});
					}
				}
				for (my $k=0; $k < @{$AlternativeList}; $k++) {
					if (defined($AlternativeList->[$k])) {
						if (defined($SolutionSelectHash{$ModelID})) {
							if ($AcceptableSolutionFound == -1 && $NewAcceptableSolution == 1) {
								#Adding a new "no good alternative" section to the attention table if a matching section does not already exis
								$AttentionTable->add_row({"KEY" => [$AcceptableKey],"DATABASE" => ["ALTERNATIVE"]});
								for (my $m=0; $m < @{$AlternativeList->[$k]}; $m++) {
									my $NewRow = $AlternativeHash->{$AlternativeList->[$k]->[$m]};
									my $OriginalKey = $NewRow->{"KEY"}->[0];
									$NewRow->{"KEY"}->[0] = $NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0];
									my $AttentionRow = $AttentionTable->add_row_copy($NewRow);
									$NewRow->{"KEY"}->[0] = $OriginalKey;
									$AttentionRow->{$ModelID} = 1;
								}
							} elsif ($AcceptableSolutionFound == $k) {
								for (my $m=0; $m < @{$AlternativeList->[$k]}; $m++) {
									my $NewRow = $AlternativeHash->{$AlternativeList->[$k]->[$m]};
									if ($Run eq "GG" || ($NewRow->{"REVERSIBLITY"}->[0] ne $NewRow->{"DIRECTION"}->[0] && $NewRow->{"REVERSIBLITY"}->[0] ne "<=>")) {
										($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$NewRow->{"DATABASE"}->[0].";".$NewRow->{"DIRECTION"}->[0]);
									} else {
										($FinalSolutions->{$ModelID},my $Dummy) = AddElementsUnique($FinalSolutions->{$ModelID},$NewRow->{"DATABASE"}->[0].";".$NewRow->{"REVERSIBLITY"}->[0]);
									}
									my $AttentionRow;
									if ($NewAcceptableSolution == 1) {
										my $OriginalKey = $NewRow->{"KEY"}->[0];
										$NewRow->{"KEY"}->[0] = $NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0]."|".$AcceptableKey;
										$AttentionRow = $AttentionTable->add_row_copy($NewRow);
										$NewRow->{"KEY"}->[0] = $OriginalKey;
									} else {
										$AttentionRow = $AttentionTable->get_row_by_key($NewRow->{"DATABASE"}->[0].$NewRow->{"DIRECTION"}->[0]."|".$AcceptableKey,"KEY");
									}
									$AttentionRow->{$ModelID} = 1;
								}
							}
						}

						my $Key = join(",",sort(@{$AlternativeList->[$k]}));
						if (!defined($SetHash->{$Key})) {
							push(@{$Set},$AlternativeList->[$k]);
							$SetHash->{$Key} = $Set;
						}
					}
				}
				if ($New == 1) {
					push(@{$Sets},$Set);
				}
			}
			#Printing the growmatch solution file
			if (defined($SolutionSelectHash{$ModelID}) && defined($FinalSolutions->{$ModelID})) {
				PrintArrayToFile($model->directory().$ModelID."-".$Run."-FinalSolution.txt",$FinalSolutions->{$ModelID});
				if (defined($IntegrateSolution) && $IntegrateSolution == 1) {
					if ($Run eq "GF") {
						system($self->{"Model driver executable"}->[0]." \"integrategrowmatchsolution?".$ModelID."?".$ModelID."-".$Run."-FinalSolution.txt?".$model->id()."VGapFilled.txt\"");
					} elsif ($Run eq "GG") {
						system($self->{"Model driver executable"}->[0]." \"integrategrowmatchsolution?".$ModelID."?".$ModelID."-".$Run."-FinalSolution.txt?".$model->id()."VOptimized.txt\"");
					}
				}
			}
		} else {
			print $model->directory().$ModelID."-".$Run."Reconciliation.txt file not found!\n";
		}
	}

	#Adding the alternative sets to the table
	for (my $i=0; $i < @{$Sets}; $i++) {
		for (my $j=0; $j < @{$Sets->[$i]}; $j++) {
			if ($j == 0) {
				$ResultTable->add_row({"KEY" => ["New set"],"DATABASE" => ["NEW SET"]});
			} else {
				$ResultTable->add_row({"KEY" => ["Alt set"],"DATABASE" => ["ALTERNATE SET"]});
			}
			for (my $k=0; $k < @{$Sets->[$i]->[$j]}; $k++) {
				my $Row = $AlternativeHash->{$Sets->[$i]->[$j]->[$k]};
				$Row->{"KEY"}->[0] = $Row->{"DATABASE"}->[0].$Row->{"DIRECTION"}->[0];
				$ResultTable->add_row($Row);
			}
		}
	}

	#Marking conflicts
	for (my $i=0; $i < $ResultTable->size(); $i++) {
		my $Row = $ResultTable->get_row($i);
		if (defined($Row->{"DATABASE"}->[0]) && $Row->{"DATABASE"}->[0] =~ m/rxn\d\d\d\d\d/) {
			if ($Row->{"REVERSIBLITY"}->[0] eq "=>" && $Row->{"DIRECTION"}->[0] eq "<=") {
				$Row->{"CONFLICT"}->[0] = "YES";
			} elsif ($Row->{"REVERSIBLITY"}->[0] eq "<=" && $Row->{"DIRECTION"}->[0] eq "=>") {
				$Row->{"CONFLICT"}->[0] = "YES";
			}
		}
	}

	$AttentionTable->save();

	return $ResultTable;
}

=head2 CGI Methods

=head3 EquationLinks

Definition:
	my ($Link) = $model->EquationLinks($Equation,$SelectedModel,$Direction);

Description:


Example:
	my ($Link) = $model->EquationLinks($Equation,$SelectedModel,$Direction);

=cut

sub EquationLinks {
	my ($self,$Reaction,$Direction) = @_;

	my $Reversibility = "";
	my $EquationDirection;
	my $Equation = $Reaction;
	if ($Reaction =~ m/^[rb][xi][no]\d\d\d\d\d$/) {
		$Equation = $self->database()->GetDBTable("REACTIONS")->get_row_by_key($Reaction,"DATABASE")->{"EQUATION"}->[0];
		$Reversibility = $self->reversibility_of_reaction($Reaction);
	}

	if (defined($Direction) && length($Direction) > 0) {
		if ($Equation =~ m/<=>/) {
			$EquationDirection = "<=>";
		} elsif ($Equation =~ m/=>/) {
			$EquationDirection = "=>";
		} elsif ($Equation =~ m/<=/) {
			$EquationDirection = "<=";
		}
		if (length($Reversibility) == 0) {
			$Reversibility = $EquationDirection;
		}
		if ($Direction ne $EquationDirection) {
			$Equation =~ s/$EquationDirection/$Direction/;
		}
		if ($Reversibility ne $Direction) {
			$Direction = '<font color="red" title="Reaction reversibility/directionality in model adjusted from predicted thermodynamic reversibility: '.$Reversibility.'"><b>'.$Direction.'</b></font>';
		}
	}

	$_ = $Equation;
	my @OriginalArray = /(cpd\d\d\d\d\d)/g;
	my %VisitedLinks;
	for (my $i=0; $i < @OriginalArray; $i++) {
	  if (!defined($VisitedLinks{$OriginalArray[$i]})) {
		$VisitedLinks{$OriginalArray[$i]} = 1;
		#my $Link = $self->CpdLinks($OriginalArray[$i],$SelectedModels,"NAME");
		my $row = $self->database()->GetDBTable("COMPOUNDS")->get_row_by_key($OriginalArray[$i],"DATABASE");
		my $Link = "|ERROR";
		if (defined($row)) {
			$Link = "|".$row->{"NAME"}->[0];
		}
		my $Find = $OriginalArray[$i];
		$Equation =~ s/$Find(\[\D\])/$Link$1|/g;
		$Equation =~ s/$Find/$Link|/g;
	  }
	}

	return $Equation;
}

=head3 SubsystemLinks

Definition:
	my ($Link) = $model->SubsystemLinks($Subsystem,$SelectedModel);

Description:


Example:
	my ($Link) = $model->SubsystemLinks($Subsystem,$SelectedModel);

=cut

sub SubsystemLinks {
	my ($self,$Subsystem,$SelectedModel) = @_;

	my $NeatSubsystem = $Subsystem;
	$NeatSubsystem =~ s/\_/ /g;
	return '<a style="text-decoration:none" href="?page=Subsystems&subsystem='.$Subsystem.'">'.$NeatSubsystem."</a>";
}

=head3 ScenarioLinks

Definition:
	my ($Link) = $model->ScenarioLinks($Subsystem);

Description:


Example:
	my ($Link) = $model->ScenarioLinks($Subsystem);

=cut

sub ScenarioLinks {
	my ($self,$Scenario) = @_;

	my @Temp = split(/:/,$Scenario);
	shift(@Temp);

	return join(":",@Temp);
}

=head3 MapLinks

Definition:
	my ($Link) = $model->MapLinks($Map,$ReactionList);

Description:


Example:
	my ($Link) = $model->MapLinks($Map,$ReactionList);

=cut

sub MapLinks {
	my ($self,$Map,$ReactionList) = @_;

	return '<a style="text-decoration:none" href="http://www.genome.jp/dbget-bin/show_pathway?'.$Map."+".join("+",@{$ReactionList}).'">'.$self->name_of_keggmap($Map)."</a>";
}

=head3 RxnLinks

Definition:
	my ($Link) = $model->RxnLinks($RxnID,$SelectedModel,$Label);

Description:
	This function returns the link for the reaction viewer page given a reaction ID.

Example:
	my ($Link) = $model->RxnLinks($RxnID,$SelectedModel,$Label);

=cut

sub RxnLinks {
	my ($self,$RxnID,$SelectedModel,$Label) = @_;

	if (!defined($Label) || $Label eq "IDONLY" || !defined($self->{"DATABASE"}->{"REACTIONHASH"}->{$RxnID}) || !defined($self->{"DATABASE"}->{"REACTIONHASH"}->{$RxnID}->{"NAME"})) {
		if (defined($SelectedModel)) {
			return '<a href="?page=ReactionViewer&reaction='.$RxnID.'&model='.$SelectedModel.'">'.$RxnID."</a>";
		} else {
			return '<a href="?page=ReactionViewer&reaction='.$RxnID.'">'.$RxnID."</a>";
		}
	}

	if ($Label eq "NAME") {
	return '<a style="text-decoration:none" href="?page=ReactionViewer&reaction='.$RxnID.'&model='.$SelectedModel.'" title="'.$RxnID.'">'.$self->{"DATABASE"}->{"REACTIONHASH"}->{$RxnID}->{"NAME"}->[0]."</a>";
	} else {
	return '<a style="text-decoration:none" href="?page=ReactionViewer&reaction='.$RxnID.'&model='.$SelectedModel.'" title="'.$self->{"DATABASE"}->{"REACTIONHASH"}->{$RxnID}->{"NAME"}->[0].'">'.$RxnID."</a>";
	}
}

sub GenomeLink {
	my ($self,$GenomeID) = @_;

	return '<a style="text-decoration:none" href="?page=Organism&organism='.$GenomeID.'" title="">'.$GenomeID."</a>";
}

sub ParseForLinks {
	my ($self,$Text,$SelectedModel,$LinkType) = @_;

	my %VisitedLinks;

	#Searching for KEGG EC number links
	$_ = $Text;
	my @OriginalArray = /(\d+\.\d+.\d+\.\d+)/g;
	for (my $i=0; $i < @OriginalArray; $i++) {
		if (!defined($VisitedLinks{$OriginalArray[$i]})) {
			$VisitedLinks{$OriginalArray[$i]} = 1;
			my $Link = $self->KEGGECLinks($OriginalArray[$i]);
			my $Find = $OriginalArray[$i];
			$Text =~ s/$Find(\D)/$Link$1/g;
			$Text =~ s/$Find$/$Link/g;
		}
	}

	#Searching for rxn links
	$_ = $Text;
	@OriginalArray = /(rxn\d\d\d\d\d)/g;
	for (my $i=0; $i < @OriginalArray; $i++) {
		if (!defined($VisitedLinks{$OriginalArray[$i]})) {
			$VisitedLinks{$OriginalArray[$i]} = 1;
			my $Link = $self->RxnLinks($OriginalArray[$i],$SelectedModel,$LinkType);
			my $Find = $OriginalArray[$i];
			$Text =~ s/$Find/$Link/g;
		}
	}
	$_ = $Text;
	@OriginalArray = /(bio\d\d\d\d\d)/g;
	for (my $i=0; $i < @OriginalArray; $i++) {
		if (!defined($VisitedLinks{$OriginalArray[$i]})) {
			$VisitedLinks{$OriginalArray[$i]} = 1;
			my $Link = $self->RxnLinks($OriginalArray[$i],$SelectedModel,$LinkType);
			my $Find = $OriginalArray[$i];
			$Text =~ s/$Find/$Link/g;
		}
	}
	#Searching for cpd links
	$_ = $Text;
	@OriginalArray = /(cpd\d\d\d\d\d)/g;
	for (my $i=0; $i < @OriginalArray; $i++) {
		if (!defined($VisitedLinks{$OriginalArray[$i]})) {
			$VisitedLinks{$OriginalArray[$i]} = 1;
			my $Link = $self->CpdLinks($OriginalArray[$i],$SelectedModel,$LinkType);
			my $Find = $OriginalArray[$i];
			$Text =~ s/$Find/$Link/g;
		}
	}
	#Searching for peg links
	if (defined($SelectedModel)) {
		$_ = $Text;
		@OriginalArray = /(peg\.\d+)/g;
		for (my $i=0; $i < @OriginalArray; $i++) {
			if (!defined($VisitedLinks{$OriginalArray[$i]})) {
				$VisitedLinks{$OriginalArray[$i]} = 1;
				my $Link = $self->GeneLinks($OriginalArray[$i],$SelectedModel);
				my $Find = $OriginalArray[$i];
				$Text =~ s/$Find(\D)/$Link$1/g;
				$Text =~ s/$Find$/$Link/g;
			}
		}
	} else {
		if ($Text =~ m/^(fig\|\d+\.\d+\.peg\.\d+)$/) {
			$Text = '<a href="http://www.theseed.org/linkin.cgi?id='.$Text.'" target="_blank">'.$Text."</a>";
		}
	}

	#Searching for KEGG compound links
	$_ = $Text;
	@OriginalArray = /(C\d\d\d\d\d)/g;
	for (my $i=0; $i < @OriginalArray; $i++) {
        if (!defined($VisitedLinks{$OriginalArray[$i]})) {
            $VisitedLinks{$OriginalArray[$i]} = 1;
            my $Link = $self->KEGGCompoundLinks($OriginalArray[$i]);
            my $Find = $OriginalArray[$i];
            $Text =~ s/$Find/$Link/g;
        }
	}
	#Searching for KEGG reaction links
	$_ = $Text;
	@OriginalArray = /(R\d\d\d\d\d)/g;
	for (my $i=0; $i < @OriginalArray; $i++) {
        if (!defined($VisitedLinks{$OriginalArray[$i]})) {
            $VisitedLinks{$OriginalArray[$i]} = 1;
            my $Link = $self->KEGGReactionLinks($OriginalArray[$i]);
            my $Find = $OriginalArray[$i];
            $Text =~ s/$Find/$Link/g;
        }
	}

	return $Text;
}

=head3 ProcessIDList
Definition:
	(HashRef::TypeList) = $model->ProcessIDList(IDList)
Description:
	This function parses the input ID list and returns parsed IDs in a hash ref of the ID types
Example:
=cut

sub ProcessIDList {
	my ($self,$IDList) = @_;

	#Converting the $IDList into a flat array ref of IDs
	my $NewIDList;
	if (defined($IDList) && ref($IDList) ne 'ARRAY') {
		my @TempArray = split(/,/,$IDList);
		for (my $j=0; $j < @TempArray; $j++) {
			push(@{$NewIDList},$TempArray[$j]);
		}
	} elsif (defined($IDList)) {
		for (my $i=0; $i < @{$IDList}; $i++) {
			my @TempArray = split(/,/,$IDList->[$i]);
			for (my $j=0; $j < @TempArray; $j++) {
				push(@{$NewIDList},$TempArray[$j]);
			}
		}
	}

	#Determining the type of each ID
	my $TypeLists;
	if (defined($NewIDList)) {
		for (my $i=0; $i < @{$NewIDList}; $i++) {
			if ($NewIDList->[$i] ne "ALL") {
				if ($NewIDList->[$i] =~ m/^fig\|(\d+\.\d+)\.(.+)$/) {
					push(@{$TypeLists->{"FEATURES"}->{$1}},$2);
				} elsif ($NewIDList->[$i] =~ m/^figint\|(\d+\.\d+)\.(.+)$/) {
					push(@{$TypeLists->{"INTERVALS"}->{$1}},$2);
				} elsif ($NewIDList->[$i] =~ m/^figstr\|(\d+\.\d+)\.(.+)$/) {
					push(@{$TypeLists->{"STRAINS"}->{$1}},$2);
				} elsif ($NewIDList->[$i] =~ m/^figmodel\|(.+)$/) {
					my $ModelID = $1;
					my $ModelData = $self->get_model($ModelID);
					if (defined($ModelData)) {
						$TypeLists->{"MODELS"}->{$ModelID} = $ModelData;
					}
				} elsif ($NewIDList->[$i] =~ m/^fig\|(\d+\.\d+)$/ || $NewIDList->[$i] =~ m/^(\d+\.\d+)$/) {
					push(@{$TypeLists->{"GENOMES"}},$1);
				} elsif ($NewIDList->[$i] =~ m/^(rxn\d\d\d\d\d)$/) {
					push(@{$TypeLists->{"REACTIONS"}},$1);
				} elsif ($NewIDList->[$i] =~ m/^(cpd\d\d\d\d\d)$/) {
					push(@{$TypeLists->{"COMPOUNDS"}},$1);
				} else {
					my $ModelData = $self->get_model($NewIDList->[$i]);
					if (defined($ModelData)) {
						$TypeLists->{"MODELS"}->{$NewIDList->[$i]} = $ModelData;
					} else {
						push(@{$TypeLists->{"ATTRIBUTES"}},$1);
					}
				}
			}
		}
	}

	return $TypeLists;
}

sub CreateLink {
	my ($self,$ID,$ObjectType,$Parameter) = @_;

	if ($ObjectType eq "model") {
		return '<a style="text-decoration:none" href="javascript: SubmitModelSelection(\''.$ID.'\');">'.$ID."</a>";
	} elsif ($ObjectType eq "pubmed") {
        return '<a style="text-decoration:none" href="http://www.ncbi.nlm.nih.gov/pubmed/'.substr($ID,4).'" target="_blank">'.$ID."</a>";
    } elsif ($ObjectType eq "peg ID" || $ObjectType eq "Gene ID") {
		return '<a href="linkin.cgi?id=fig|'.$Parameter.".".$ID.'" target="_blank">'.$ID."</a>";
	} elsif ($ObjectType eq "Genome ID") {
		return '<a href="seedviewer.cgi?page=Organism&organism='.$ID.'" target="_blank">'.$ID."</a>";
	} elsif ($ObjectType eq "Subsystems") {
		return '<a href="seedviewer.cgi?page=Subsystems&subsystem='.$ID.'&organism='.$Parameter.'" target="_blank">'.$ID."</a>";
	} elsif ($ID =~ m/^rxn\d\d\d\d\d$/) {
		return '<a href="seedviewer.cgi?page=ReactionViewer&reaction='.$ID.'" target="_blank">'.$ID."</a>";
	} elsif ($ObjectType eq "genelist") {
		return '<a style="text-decoration:none" href="seedviewer.cgi?page=GeneViewer&id='.$Parameter.'" target="_blank">'.$ID."</a>";
	} elsif ($ObjectType eq "reactionlist") {
		return '<a style="text-decoration:none" href="seedviewer.cgi?page=ReactionViewer&model='.$Parameter.'" target="_blank">'.$ID."</a>";
	} elsif ($ObjectType eq "compoundlist") {
		return '<a style="text-decoration:none" href="seedviewer.cgi?page=CompoundViewer&model='.$Parameter.'" target="_blank">'.$ID."</a>";
	} elsif ($ObjectType eq "SBML") {
		if (-e $self->{"SBML files"}->[0].$Parameter.".xml") {
			return "<a href='http://bioseed.mcs.anl.gov/~chenry/SBMLModels/".$Parameter.".xml'>".$ID."</a>";
		} else {
			return "Not available";
		}
	}

	return $ID;
}

sub KEGGECLinks {
	my ($self,$ID) = @_;

	return '<a href="http://www.genome.jp/dbget-bin/www_bget?enzyme+'.$ID.'" target="_blank">'.$ID."</a>";
}

sub KEGGReactionLinks {
	my ($self,$ID) = @_;

	return '<a href="http://www.genome.jp/dbget-bin/www_bget?rn+'.$ID.'" target="_blank">'.$ID."</a>";
}

sub KEGGCompoundLinks {
	my ($self,$ID) = @_;

	return '<a href="http://www.genome.jp/dbget-bin/www_bget?cpd:'.$ID.'" target="_blank">'.$ID."</a>";
}

=head3 kegg_summary_data
Description:
    Builds and updates a KEGG summary table
=cut

sub kegg_summary_data {
    my ($self) = @_;

    my $val_hash;

    my $kegg_root = $FIG_Config::kegg || $self->{"KEGG directory"}->[0];
    $kegg_root .= "/pathway/map";

    my $title_file = $kegg_root . "/../map_title.tab";

    # Initialize a FIGMODEL Table
    my $headings = [ "ID", "NAME", "REACTIONS", "COMPOUNDS", "ECNUMBERS" ];
    my $filename = $self->{"Reaction database directory"}->[0]."masterfiles/MapDataTable.txt";
    my $hash_headings = [ "ID", "REACTIONS", "COMPOUNDS", "ECNUMBERS" ];
    my $delimiter = ';';
    my $itemdelimiter = '|';
    my $prefix = undef;
    my $mapTable = ModelSEED::FIGMODEL::FIGMODELTable->new($headings,$filename,$hash_headings,$delimiter,$itemdelimiter,$prefix);

    # Get a list of all current KEGG map identifiers and titles
    if( open( INFH, '<', $title_file ) )
    {
        while( my $line = <INFH> )
        {
            chomp $line;
            my ($id, $name) = split /\t/, $line;
            $val_hash->{$id}->{'ID'} = $id;
            $val_hash->{$id}->{'NAME'} = $name;
        }
        close( INFH );
    }

    # Parse the Reaction summary file
    my $rxn_table = $self->database()->GetDBTable("REACTIONS");
    if( open( RXNFH, '<', $kegg_root . "/rn_map.tab" ) )
    {
        while( my $line = <RXNFH> )
        {
            chomp $line;
            my ($rxn, $mapstr) = split /\t/, $line;

            if( defined( my $row = $rxn_table->get_row_by_key( $rxn, "KEGGID" ) ) )
            {
                my @maps = split /\s/, $mapstr;
                foreach( @maps )
                {
                    push @{$val_hash->{$_}->{'REACTIONS'}} , $row->{"DATABASE"}->[0];
                }
            }

        }
        close( RXNFH );
    }
    # Parse the CPD summary file
    my $cpd_table= $self->database()->GetDBTable("COMPOUNDS");
    if( open( CPDFH, '<', $kegg_root . "/cpd_map.tab" ) )
    {
        while( my $line = <CPDFH> )
        {
            chomp $line;
            my ($cpd,$mapstr) = split /\t/, $line;

            if( defined( my $row = $cpd_table->get_row_by_key( $cpd, "KEGGID" ) ) )
            {
                my @maps = split /\s/, $mapstr;
                foreach( @maps )
                {
                    push @{$val_hash->{$_}->{'COMPOUNDS'}}, $row->{"DATABASE"}->[0];
                }
            }
        }
        close( CPDFH );
    }

    # Parse the EC summary file
    if( open( ECFH, '<', $kegg_root . "/ec_map.tab" ) )
    {
        while( my $line = <ECFH> )
        {
            chomp $line;
            my ($ec, $mapstr) = split /\t/, $line;
            my @maps = split /\s/, $mapstr;
            push @{$val_hash->{$_}->{'ECNUMBERS'}}, $ec foreach( @maps );
        }
        close( ECFH );
    }

    # For each map, load all the reactions/compounds/ecs that can be found in it
    foreach my $id ( sort keys %{$val_hash} )
    {
        $mapTable->add_row( {   "ID" => [ $id ],
                                "NAME" => [ $val_hash->{$id}->{'NAME'} ],
                                "REACTIONS" => $val_hash->{$id}->{'REACTIONS'},
                                "COMPOUNDS" => $val_hash->{$id}->{'COMPOUNDS'},
                                "ECNUMBERS" => $val_hash->{$id}->{'ECNUMBERS'},
                                "SHOWN" => [1]
                            } );
    }

    print $mapTable->size()." FILENAME: $filename";
    $mapTable->save( $filename,$delimiter,$itemdelimiter,$prefix );
}

=head3 load_compartments
Definition:
	FIGMODEL->load_compartments()
Description:

=cut

sub load_compartments {
	my ($self) = @_;

	#my $CompartmentTable = $self->GetDBTable("COMPARTMENTS");
	require DBMaster;
	# initialize a DBMaster object
	my $dbmaster = DBMaster->new(-database => 'SeedBiochemDB', -user => 'webappuser');
	# create an object, passing attributes as a hash
	my $Test = "COMPARTMENTS";
	my $new_object = $dbmaster->$Test->create( { NAME => 'cytosol',COMPARTMENTS => 'o',OUTSIDE => 'e' } );

	return 1;
}

=head3 get_job_info
Definition:
	my ($OrganismName,$UserID) = $self->get_job_info($GenomeID,$JobID);
Description:
	Returns the user ID and organism name for the specified job ID.
	Since there are multiple rast servers, this system search for the server where the jobID and organism ID match the server data.
=cut

sub get_job_info {
	my ($self,$GenomeID,$JobID) = @_;

	my $UserID = undef;
	my $OrganismName = undef;

	#Getting the directory for the job
	my $Directory = $self->get_job_directory($GenomeID,$JobID);

	#Getting the user id and organism name
	if (-e $Directory."USER") {
		$UserID = LoadSingleColumnFile($Directory."USER","")->[0];
	}
	if (-e $Directory."TAXONOMY") {
		$OrganismName = LoadSingleColumnFile($Directory."TAXONOMY","")->[0];
		if ($OrganismName =~ m/;\s*([^;]+)$/) {
			$OrganismName = $1;
		}
	}

	return ($OrganismName,$UserID);
}

=head3 get_job_directory
Definition:
	my ($Directory) = get_job_directory($self,$GenomeID,$JobID);
Description:
	Since there are multiple rast servers, this system search for the server where
	the jobID and organism ID match the server data and returns the job directory.
	Returns undef if no directory is found. Also prints an error message.
=cut

sub get_job_directory {
	my ($self,$GenomeID,$JobID) = @_;

	my @DirectoryList = split(/;/,$self->{"rast jobs directory"}->[0]);
	#Searching for a job directory with the correct job ID and the correct organism ID
	foreach my $Directory (@DirectoryList) {
		if (-d $Directory.$JobID."/rp/".$GenomeID) {
			#If the directory is found we return it
			return $Directory.$JobID."/";
		}
	}

	print STDERR "FIGMODEL:get_job_directory:Could not find job directory for job ".$JobID." and genome ".$GenomeID."\n";
	return undef;
}

sub get_genome_name {
	my ($self,$GenomeID) = @_;
	my $fig = $self->fig($GenomeID);
	if (!defined($fig)) {
		return undef;
	}
	return $fig->orgname_of_orgid($GenomeID);
}

=head3 CaptureRoleRxnMapping
Definition:
	$model->CaptureRoleRxnMapping($Associated_Genes_in_string_format,$ReactionID,$ModelName);
Description:
Example:
=cut

sub CaptureRoleRxnMapping {
	my ($self,$Genes,$Reaction,$Model) = @_;

	#Sanity checking on arguments
	if (!defined($self->fig()) || !defined($self) || !defined($Genes) || !defined($Reaction) || !defined($Model) || $Reaction !~ m/rxn\d\d\d\d\d/ || $Genes !~ m/peg\.\d+/ || length($Model) == 0) {
		return;
	}

	#Getting the SEED role list for a reaction
	my $SeedRoles = $self->roles_of_reaction($Reaction,"SEED");
	my %SeedRoleHash;
	if (defined($SeedRoles)) {
		for (my $i=0; $i < @{$SeedRoles}; $i++) {
			$SeedRoleHash{$SeedRoles->[$i]} = 1;
		}
	}

	#Identifying and listing new and unique mappings in the model
	$_ = $Genes;
	my @GeneList = /(peg\.\d+)/g;
	my %RoleSourceHash;
	for (my $i=0; $i < @GeneList; $i++) {
		my @Roles = $self->roles_of_peg($GeneList[$i],$Model);
		my $Found = 0;
		for (my $j=0; $j < @Roles; $j++) {
			if (defined($SeedRoleHash{$Roles[$j]})) {
				#This role is already in the SEED mappings meaning this mapping is not model-specific
				@Roles = ();
			}
		}
		for (my $j=0; $j < @Roles; $j++) {
			#print "NEW MAPPING:".$Roles[$j].":".$GeneList[$i].":".$Reaction."\n";
			push(@{$RoleSourceHash{$Roles[$j]}},$GeneList[$i]);
		}
	}

	#Loading the new unique mappings to the model role mapping table
	my @Roles = keys(%RoleSourceHash);
	my @ModelRoleMappingRows;
	if (defined($self->database()->GetDBTable("ROLE MAPPING TABLE")->{$Reaction})) {
		push(@ModelRoleMappingRows,@{$self->database()->GetDBTable("ROLE MAPPING TABLE")->{$Reaction}});
	}
	for (my $i = 0; $i < @Roles; $i++) {
		my $Found = 0;
		for (my $j=0; $j < @ModelRoleMappingRows; $j++) {
			if (defined($Roles[$i]) && defined($ModelRoleMappingRows[$j]->{"ROLE"}->[0]) && $Roles[$i] eq $ModelRoleMappingRows[$j]->{"ROLE"}->[0]) {
				$Found = 1;
				my $SourceFound = 0;
				for (my $k=0; $k < @{$ModelRoleMappingRows[$j]->{"SOURCE"}}; $k++) {
					my @SourceList = split(/[,:]/,$ModelRoleMappingRows[$j]->{"SOURCE"}->[$k]);
					if ($SourceList[0] eq $Model) {
						$SourceFound = 1;
						for (my $m=0; $m < @{$RoleSourceHash{$Roles[$i]}}; $m++) {
							my $GeneFound = 0;
							for (my $n=1; $n < @SourceList; $n++) {
								if ($RoleSourceHash{$Roles[$i]}->[$m] eq $SourceList[$n]) {
									$GeneFound = 1;
								}
							}
							if ($GeneFound == 0) {
								$ModelRoleMappingRows[$j]->{"SOURCE"}->[$k] .= ",".$RoleSourceHash{$Roles[$i]}->[$m];
							}
						}
					}
				}
				if ($SourceFound == 0) {
					push (@{$ModelRoleMappingRows[$j]->{"SOURCE"}},$Model.":".join(",",@{$RoleSourceHash{$Roles[$i]}}));
				}
			}
		}
		if ($Found == 0) {
			my $NewRow = { "REACTION" => [$Reaction], "ROLE" => [$Roles[$i]], "SOURCE" => [$Model.":".join(",",@{$RoleSourceHash{$Roles[$i]}})] };
			push(@{$self->database()->GetDBTable("ROLE MAPPING TABLE")->{"array"}},$NewRow);
			push(@{$self->database()->GetDBTable("ROLE MAPPING TABLE")->{$Reaction}},$NewRow);
		}
	}
}

=head3 subsystems_of_role
Definition:
	array reference::list of subsystems = $model->subsystems_of_role(string::input functional role);
Description:
Example:
=cut

sub subsystems_of_role {
	my ($self,$Role) = @_;

	my $SubsystemList;
	my $LinkTable = $self->database()->GetLinkTable("SUBSYSTEM","ROLE");
	if (defined($LinkTable)) {
		my @Rows = $LinkTable->get_rows_by_key($Role,"ROLE");
		for (my $i=0; $i < @Rows; $i++) {
			push(@{$SubsystemList},$Rows[$i]->{SUBSYSTEM}->[0])
		}
	}
	return $SubsystemList;
}

=head3 get_growmatch_stats
Definition:
	(FIGMODELTable::GapfillData,FIGMODELTable::GapGenData) = $model->get_growmatch_stats(ArrayRef::GapFillModelList,ArrayRef::GapGenModelList);
Description:
Example:
=cut

sub get_growmatch_stats {
	my ($self,$List,$Type) = @_;

	#Instantiating output data tables
	my $Table = ModelSEED::FIGMODEL::FIGMODELTable->new(["Reaction","Roles","Equation","Number of solutions"],"/home/chenry/".$Type."Compilation.txt",["Reaction"],";","|",undef);

	for (my $i=0; $i < @{$List};$i++) {
		my $ModelID = $List->[$i];
		my $model = $self->get_model($ModelID);
		if (defined($model)) {
			if (-e $model->directory().$ModelID."-".$Type."-FinalSolution.txt") {
				my $SolutionReactions = LoadMultipleColumnFile($model->directory().$ModelID."-".$Type."-FinalSolution.txt",";");
				for (my $j=0; $j <@{$SolutionReactions};$j++) {
					my $ReactionRow = $Table->get_row_by_key($SolutionReactions->[$j]->[0].":".$SolutionReactions->[$j]->[1],"Reaction");
					if (!defined($ReactionRow)) {
						my $ReactionObject = $self->LoadObject($SolutionReactions->[$j]->[0]);
						my $Equation = "";
						my $RoleList = "";
						if (defined($ReactionObject) && defined($ReactionObject->{"DEFINITION"}->[0])) {
							$Equation = $ReactionObject->{"DEFINITION"}->[0];
							my $RoleData = $self->roles_of_reaction($SolutionReactions->[$j]->[0]);
							if (defined($RoleData)) {
							  $RoleList = join("|",@{$RoleData});
							}
						}
						$ReactionRow = {"Reaction" => [$SolutionReactions->[$j]->[0].":".$SolutionReactions->[$j]->[1]],"Roles" => [$RoleList],"Equation" => [$Equation],"Number of solutions" => [0]};
						$Table->add_row($ReactionRow);
					}
					$ReactionRow->{"Number of solutions"}->[0]++;
					$ReactionRow->{$ModelID}->[0] = 1;
					$Table->add_headings(($ModelID));
				}
			} else {
				print STDERR "Could not find gapfill solution file:".$model->directory().$ModelID."-".$Type."-FinalSolution.txt\n";
			}
		}
	}
	$Table->save();
}

=head3 findPatternInterval
Definition:
    ArrayRef::retvals = $figmodel->findPatternInterval( ArraryRef::patterns, ArrayRef::min, ArrayRef::max, Scalar::id, FIGMODELTable::table );
Description:
Example:
=cut

sub findPatternInterval {
    my ($self, $pattern_list, $id, $name) = @_;

    my $table = ModelSEED::FIGMODEL::FIGMODELTable->new(["pattern", "pegId", "functionalRole"],$self->{"database message file directory"}->[0].$name."-PatternSearch.tbl",["pattern", "pegId", "functionalRole"], "|", ";", undef );

    if( $id =~ m/all/ ){
        foreach( $self->fig()->genomes( 1,0, "Bacteria" ) ){
            print STDERR "Processing $_\n";
            $self->_findPatternInterval( $pattern_list, $_, $table );
            delete $self->{"CACHE"}->{$_."FEATURETABLE"};
        }
    }
    else{
        $self->_findPatternInterval( $pattern_list, $id, $table );
    }
    return $table;
}

sub _parsePatterns {
    my ($self, $pattern) = @_;

    my $temp_val;

    my $patterns = [];
    my $min = [];
    my $max = [];

    my @tokens = split /\s+/, $pattern;
    push @$patterns, (shift @tokens);

    while( @tokens ){
        # Shift, so counting backwards mod 3
       $temp_val = shift @tokens;
        if( (@tokens%3) == 0 ){
            push @$patterns, $temp_val;
        }
        elsif( (@tokens%3) == 2 ){
            push @$min, $temp_val;
        }
        else{
            push @$max, $temp_val;
        }
    }

    if( ($#$min != $#$max ) || ( $#$patterns != @$min ) ){
        #print STDERR "Incorrectly formatted pattern string.\n";
        return -1;
    }

    return [ $patterns, $min, $max ];
}

sub _findPatternInterval {
    my ($self, $pattern_list, $id, $table) = @_;

    # Get pegs
    my $retvals = [];
    my $feature_table = $self->GetGenomeFeatureTable( $id, 1 );

    OUTER: for( my $i=0; $i < $feature_table->size(); $i++ ){
        my $row = $feature_table->get_row($i);
        if( defined( $row->{"SEQUENCE"}->[0] ) ){

            PATTERN: foreach my $pat ( @$pattern_list ){
                # Is there better syntax for this?
                my $plist = $self->_parsePatterns($pat);
                if( $plist == -1 ){
                    #print STDERR "Skipping pattern in findPatternInterval.\n";
                    next PATTERN;
                }

                my $patterns = $plist->[0];
                my $min = $plist->[1];
                my $max = $plist->[2];

                my $starts = [];

                # Find the starts of all the patterns
                for( my $j=0; $j <= $#$patterns; $j++ ){
                    my $pat = $patterns->[$j];
                    if( $row->{"SEQUENCE"}->[0] =~ m/$pat/ ){
                        push @$starts, $-[0];
                    }
                }

                # Make sure we have a position for each pattern
                if( $#$patterns == $#$starts ){
                    for( my $j=0; $j< $#$starts ; $j++ ){
                        # If every gap passes the test...
                        my $gap = $starts->[$j+1] - $starts->[$j];
                        # First time we fail, get the next peg in line
                        unless( ($min->[$j] <= $gap) && ($gap <= $max->[$j]) ){
                            next PATTERN;
                        }
                    }
                    # ...return the peg
                    $table->add_row( { "pegId" => $row->{"ID"}, "pattern" =>[$pat] , "functionalRole" => $row->{"ROLES"} } );
                }
                else{
                    next PATTERN;
                }
            }
        }
    }
    return 1;
}

sub printSequencesForRole {
    $| =1;
    my ($self, $role, $outputFile) = @_;
	my $outputFD;
	if(defined($outputFile)) {
		open( $outputFD, '>', $outputFile) or die("Unable to open output file $outputFile : $!");
	} else { $outputFD = 'STDOUT'; }

	my $fig = $self->fig();
	my @pegs = $fig->role_to_pegs($role);
	foreach my $peg (@pegs) {
		my $seq = $fig->get_translation($peg);
            print {$outputFD} ">";
            print {$outputFD} $peg . "\n";
            print {$outputFD} $seq . "\n";
    }
	close( $outputFD ) or die("Unable to close output file: $!");
}

=head3 CompileAnnotationOptimization
Definition:
    void $model->CompileAnnotationOptimization(string::filename)
Description:
Example:
=cut

sub CompileAnnotationOptimization {
    my ($self, $Filename) = @_;

	#Loading annotation optimizations
	my $Table = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Filename,";",",",0,["MODEL ID","REACTIONS","NEW COMPLEXES"]);

	#Generating output table
	my $OutputTable = ModelSEED::FIGMODEL::FIGMODELTable->new(["Model ID","Reactions","Inconstency type","Gene roles","Involved subsytem","Original complexes","Final complexes"],$self->{"database message file directory"}->[0]."AnnotationOptimization.tbl",["Model ID"],";","|",undef);

	#Loading models and examining unmodified annotations
	my $ModelHash;
	my $GenomeHash;
	my $EssentialGenes;
	my $NonessentialGenes;
	for (my $i=0; $i < $Table->size(); $i++) {
		my $Row = $Table->get_row($i);
		#Loading model
		if (!defined($ModelHash->{$Row->{"MODEL ID"}->[0]})) {
			$ModelHash->{$Row->{"MODEL ID"}->[0]} = $self->database()->GetDBModel($Row->{"MODEL ID"}->[0]);
			my $GenomeID = $self->get_model($Row->{"MODEL ID"}->[0])->genome();
			$GenomeHash->{$Row->{"MODEL ID"}->[0]}->{"FEATURES"} = $self->GetGenomeFeatureTable($GenomeID);
			$GenomeHash->{$Row->{"MODEL ID"}->[0]}->{"GENOME"} = $GenomeID;
			my $EssentialityData = $self->GetEssentialityData($GenomeID);
			for (my $j=0; $j < $EssentialityData->size(); $j++) {
				if ($EssentialityData->get_row($j)->{"Essentiality"}->[0] eq "essential") {
					$EssentialGenes->{$Row->{"MODEL ID"}->[0]}->{$EssentialityData->get_row($j)->{"Gene"}->[0]} = 1;
				} elsif ($EssentialityData->get_row($j)->{"Essentiality"}->[0] eq "nonessential") {
					$NonessentialGenes->{$Row->{"MODEL ID"}->[0]}->{$EssentialityData->get_row($j)->{"Gene"}->[0]} = 1;
				}
			}
		}
		#Getting row associated with reaction in model
		my $ReactionRow = $ModelHash->{$Row->{"MODEL ID"}->[0]}->get_row_by_key($Row->{"REACTIONS"}->[0],"LOAD");
		#Adding row to output table
		my $GeneHash;
		my $GeneRoles;
		my $Subsystems;
		my $SubsystemHash;
		my $Reactions;
		my $OriginalComplexes;
		my $FinalComplexes;
		my $Type;
		#Building array of reactions
		for (my $j=0; $j < @{$Row->{"REACTIONS"}}; $j++) {
			my $Definition;
			my $ReactionData = $self->LoadObject($Row->{"REACTIONS"}->[$j]);
			if (defined($ReactionData->{"DEFINITION"}->[0])) {
				$Definition = $ReactionData->{"DEFINITION"}->[0];
			}
			push(@{$Reactions},$Row->{"REACTIONS"}->[$j].":".$Definition);
		}
		#Scanning through genes associated with reaction
		if (defined($ReactionRow->{"ASSOCIATED PEG"})) {
			for (my $j=0; $j < @{$ReactionRow->{"ASSOCIATED PEG"}}; $j++) {
				my @PegArray = split(/\+/,$ReactionRow->{"ASSOCIATED PEG"}->[$j]);
				for (my $k=0; $k < @PegArray; $k++) {
					if (defined($EssentialGenes->{$Row->{"MODEL ID"}->[0]}->{$PegArray[$k]})) {
						$PegArray[$k] = $PegArray[$k]."(e)";
					} elsif (defined($NonessentialGenes->{$Row->{"MODEL ID"}->[0]}->{$PegArray[$k]})) {
						$PegArray[$k] = $PegArray[$k]."(n)";
					} else {
						$PegArray[$k] = $PegArray[$k]."(u)";
					}
					if (!defined($GeneHash->{$PegArray[$k]})) {
						my $PegID = "fig|".$GenomeHash->{$Row->{"MODEL ID"}->[0]}->{"GENOME"}.".".$PegArray[$k];
						$PegID = substr($PegID,0,length($PegID)-3);
						my $FeatureRow = $GenomeHash->{$Row->{"MODEL ID"}->[0]}->{"FEATURES"}->get_row_by_key($PegID,"ID");
						if (defined($FeatureRow->{"ROLES"})) {
							push(@{$GeneRoles},$PegArray[$k].":".join("/",@{$FeatureRow->{"ROLES"}}));
							for (my $m=0; $m < @{$FeatureRow->{"ROLES"}}; $m++) {
								my $RoleSubsystems = $self->subsystems_of_role($FeatureRow->{"ROLES"}->[$m]);
								if (defined($RoleSubsystems)) {
									for (my $n=0; $n < @{$RoleSubsystems}; $n++) {
										if (!defined($SubsystemHash->{$RoleSubsystems->[$n]})) {
											$SubsystemHash->{$RoleSubsystems->[$n]} = 1;
											push(@{$Subsystems},$RoleSubsystems->[$n]);
										}
									}
								}
							}
						}
					}
				}
				push(@{$OriginalComplexes},join("+",@PegArray));
			}
		}
		#Scanning through new complexes
		for (my $j=0; $j < @{$Row->{"NEW COMPLEXES"}}; $j++) {
			my @PegArray = split(/\+/,$Row->{"NEW COMPLEXES"}->[$j]);
			for (my $k=0; $k < @PegArray; $k++) {
				if (defined($EssentialGenes->{$Row->{"MODEL ID"}->[0]}->{$PegArray[$k]})) {
					$PegArray[$k] = $PegArray[$k]."(e)";
				} elsif (defined($NonessentialGenes->{$Row->{"MODEL ID"}->[0]}->{$PegArray[$k]})) {
					$PegArray[$k] = $PegArray[$k]."(n)";
				} else {
					$PegArray[$k] = $PegArray[$k]."(u)";
				}
				if (!defined($GeneHash->{$PegArray[$k]})) {
					my $PegID = "fig|".$GenomeHash->{$Row->{"MODEL ID"}->[0]}->{"GENOME"}.".".$PegArray[$k];
					$PegID = substr($PegID,0,length($PegID)-3);
					my $FeatureRow = $GenomeHash->{$Row->{"MODEL ID"}->[0]}->{"FEATURES"}->get_row_by_key($PegID,"ID");
					if (defined($FeatureRow->{"ROLES"})) {
						push(@{$GeneRoles},$PegArray[$k].":".join("/",@{$FeatureRow->{"ROLES"}}));
						for (my $m=0; $m < @{$FeatureRow->{"ROLES"}}; $m++) {
							my $RoleSubsystems = $self->subsystems_of_role($FeatureRow->{"ROLES"}->[$m]);
							if (defined($RoleSubsystems)) {
								for (my $n=0; $n < @{$RoleSubsystems}; $n++) {
									if (!defined($SubsystemHash->{$RoleSubsystems->[$n]})) {
										$SubsystemHash->{$RoleSubsystems->[$n]} = 1;
										push(@{$Subsystems},$RoleSubsystems->[$n]);
									}
								}
							}
						}
					}
				}
			}
			push(@{$FinalComplexes},join("+",@PegArray));
		}
		#Adding row to output table
		$OutputTable->add_row({"Model ID" => $Row->{"MODEL ID"},"Reactions" => $Reactions,"Gene roles" => $GeneRoles,"Inconstency type" => [$Type],"Involved subsytem" => $Subsystems,"Original complexes" => $OriginalComplexes,"Final complexes" => $FinalComplexes});
	}
	#Saving output table
	$OutputTable->save();
}

=head3 CompileSimulationData
Definition:
    void $model->CompileSimulationData(string array ref::list of models)
Description:
Example:
=cut

sub CompileSimulationData {
    my ($self, $Organism) = @_;

	#Getting model data
	my $ModelName = "Seed".$Organism;
	my $model = $self->get_model($ModelName);
	if (!defined($model)) {
		print STDERR "FIGMODEL:CompileSimulationData:Model ".$ModelName." not found!\n";
		return;
	}
	my $Directory = $model->directory();
	my $OrganismName = $self->GetModelStats($ModelName)->{"Organism name"}->[0];

	#Getting the list of headings and hashheadings
	my $DataTables;
	my $Headings;
	#Loading analysis ready simulation results
	if (-e $Directory."SimulationOutputSeed".$Organism."VNoBiolog.txt") {
		$DataTables->{"Analysis Ready Seed".$Organism} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory."SimulationOutputSeed".$Organism."VNoBiolog.txt","\t",",",2,undef);
		push(@{$Headings},"Analysis Ready Seed".$Organism);
		if (-e $Directory."SimulationOutputSeed".$Organism.".txt") {
			$DataTables->{"Biolog Consistency Analysis Seed".$Organism} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory."SimulationOutputSeed".$Organism.".txt","\t",",",2,undef);
			push(@{$Headings},"Biolog Consistency Analysis Seed".$Organism);
		}
	} elsif (-e $Directory."SimulationOutputSeed".$Organism.".txt") {
		$DataTables->{"Analysis Ready Seed".$Organism} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory."SimulationOutputSeed".$Organism.".txt","\t",",",2,undef);
		push(@{$Headings},"Analysis Ready Seed".$Organism);
	}
	#Loading consistency analysis simulation results
	print $Directory."SimulationOutputOpt".$Organism."VAnnoOpt.txt\n";
	if (-e $Directory."SimulationOutputOpt".$Organism."VAnnoOpt.txt") {
		$DataTables->{"Essentiality Consistency Analysis Seed".$Organism} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory."SimulationOutputOpt".$Organism."VAnnoOpt.txt","\t",",",2,undef);
		$ModelName = "Opt".$Organism;
		print $ModelName."\n";
		push(@{$Headings},"Essentiality Consistency Analysis Seed".$Organism);
	}
	#Loading gap filled simulation results
	if (-e $Directory."SimulationOutput".$ModelName."VGapFilled.txt") {
		$DataTables->{"GapFilled Seed".$Organism} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory."SimulationOutput".$ModelName."VGapFilled.txt","\t",",",2,undef);
		push(@{$Headings},"GapFilled Seed".$Organism);
	}
	#Loading gap gen simulation results
	if (-e $Directory."SimulationOutput".$ModelName."VOptimized.txt") {
		$DataTables->{"Optimized Seed".$Organism} = ModelSEED::FIGMODEL::FIGMODELTable::load_table($Directory."SimulationOutput".$ModelName."VOptimized.txt","\t",",",2,undef);
		push(@{$Headings},"Optimized Seed".$Organism);
	}

	#Creating the output table if it does not already exist
	if (!defined($self->{"CACHE"}->{"SimulationCompilationTable"})) {
		$self->{"CACHE"}->{"SimulationCompilationTable"} = ModelSEED::FIGMODEL::FIGMODELTable->new([$OrganismName." (Seed".$Organism.")",$Headings->[0]],$self->{"database message file directory"}->[0]."SimulationCompilation.tbl",undef, "|", ";",undef);
		#Adding the rows for the accuracy, CN,CP,FP,FN
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["Accuracy"],$Headings->[0] => [0]});
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["Biolog Accuracy"],$Headings->[0] => [0]});
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["Essentiality Accuracy"],$Headings->[0] => [0]});
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["Correct negative"],$Headings->[0] => [0]});
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["Correct positive"],$Headings->[0] => [0]});
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["False negative"],$Headings->[0] => [0]});
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_row({$OrganismName." (Seed".$Organism.")" => ["False positive"],$Headings->[0] => [0]});
	} else {
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_headings($OrganismName." (Seed".$Organism.")");
		$self->{"CACHE"}->{"SimulationCompilationTable"}->add_headings($Headings->[0]);
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(0)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(1)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(2)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(3)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(4)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(5)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(6)->{$Headings->[0]}->[0] = 0;
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(0)->{$OrganismName." (Seed".$Organism.")"}->[0] = "Accuracy";
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(1)->{$OrganismName." (Seed".$Organism.")"}->[0] = "Biolog Accuracy";
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(2)->{$OrganismName." (Seed".$Organism.")"}->[0] = "Essentiality Accuracy";
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(3)->{$OrganismName." (Seed".$Organism.")"}->[0] = "Correct negative";
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(4)->{$OrganismName." (Seed".$Organism.")"}->[0] = "Correct positive";
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(5)->{$OrganismName." (Seed".$Organism.")"}->[0] = "False negative";
		$self->{"CACHE"}->{"SimulationCompilationTable"}->get_row(6)->{$OrganismName." (Seed".$Organism.")"}->[0] = "False positive";
	}
	my $FinalTable = $self->{"CACHE"}->{"SimulationCompilationTable"};

	#Adding the data to the simulation compilation table
	my $CurrentIndex = 7;
	foreach my $Heading (@{$Headings}) {
		my $TotalIncorrect = 0;
		my $TotalCorrect = 0;
		my $TotalIncorrectEss = 0;
		my $TotalCorrectEss = 0;
		my $TotalIncorrectBiolog = 0;
		my $TotalCorrectBiolog = 0;
		my $DataTable = $DataTables->{$Heading};
		for (my $i=0; $i < $DataTable->size(); $i++) {
			my $Row = $DataTable->get_row($i);
			my $Key;
			if ($Row->{"Experiment type"}->[0] eq "Media growth") {
				$Key = "Growth in ".$Row->{"Media"}->[0];
			} elsif ($Row->{"Experiment type"}->[0] eq "Gene KO") {
				$Key = $Row->{"Experiment ID"}->[0]." KO in ".$Row->{"Media"}->[0];
			} else {
				$Key = $Row->{"Experiment type"}->[0]."-".$Row->{"Media"}->[0]."-".$Row->{"Experiment ID"}->[0];
			}
			#Dealing with first column
			$FinalTable->add_headings($Heading);
			my $Found = 0;
			for (my $j=7; $j < $CurrentIndex; $j++) {
				if ($FinalTable->get_row($j)->{$OrganismName." (Seed".$Organism.")"}->[0] eq $Key) {
					$Found = 1;
					$FinalTable->get_row($j)->{$Heading} = $Row->{"Run result"};
					last;
				}
			}
			if ($Found == 0) {
				if ($CurrentIndex >= $FinalTable->size()) {
					$FinalTable->add_row({$OrganismName." (Seed".$Organism.")" => [$Key],$Heading => $Row->{"Run result"}});
				} else {
					$FinalTable->get_row($CurrentIndex)->{$OrganismName." (Seed".$Organism.")"}->[0] = $Key;
					$FinalTable->get_row($CurrentIndex)->{$Heading} = $Row->{"Run result"};
				}
				$CurrentIndex++;
			}
			#Counting errors and correct predictions
			if ($Row->{"Run result"}->[0] eq "Correct negative") {
				if ($Row->{"Experiment type"}->[0] eq "Media growth") {
					$TotalCorrectBiolog++;
				} elsif ($Row->{"Experiment type"}->[0] eq "Gene KO") {
					$TotalCorrectEss++;
				}
				$TotalCorrect++;
				$FinalTable->get_row(3)->{$Heading}->[0]++;
			} elsif ($Row->{"Run result"}->[0] eq "False negative") {
				if ($Row->{"Experiment type"}->[0] eq "Media growth") {
					$TotalIncorrectBiolog++;
				} elsif ($Row->{"Experiment type"}->[0] eq "Gene KO") {
					$TotalIncorrectEss++;
				}
				$TotalIncorrect++;
				$FinalTable->get_row(5)->{$Heading}->[0]++;
			} elsif ($Row->{"Run result"}->[0] eq "Correct positive") {
				if ($Row->{"Experiment type"}->[0] eq "Media growth") {
					$TotalCorrectBiolog++;
				} elsif ($Row->{"Experiment type"}->[0] eq "Gene KO") {
					$TotalCorrectEss++;
				}
				$TotalCorrect++;
				$FinalTable->get_row(4)->{$Heading}->[0]++;
			} elsif ($Row->{"Run result"}->[0] eq "False positive") {
				if ($Row->{"Experiment type"}->[0] eq "Media growth") {
					$TotalIncorrectBiolog++;
				} elsif ($Row->{"Experiment type"}->[0] eq "Gene KO") {
					$TotalIncorrectEss++;
				}
				$TotalIncorrect++;
				$FinalTable->get_row(6)->{$Heading}->[0]++;
			}
		}
		#Calculating accuracy
		$FinalTable->get_row(0)->{$Heading}->[0] = $TotalCorrect/($TotalCorrect+$TotalIncorrect);
		if ($TotalCorrectBiolog+$TotalIncorrectBiolog > 0) {
			$FinalTable->get_row(1)->{$Heading}->[0] = $TotalCorrectBiolog/($TotalCorrectBiolog+$TotalIncorrectBiolog);
		}
		if ($TotalCorrectEss+$TotalIncorrectEss > 0) {
			$FinalTable->get_row(2)->{$Heading}->[0] = $TotalCorrectEss/($TotalCorrectEss+$TotalIncorrectEss);
		}
	}
}

=head3 find_genes_for_gapfill_reactions
Definition:
    FIGMODELTable::table of candidate genes FIGMODEL->find_genes_for_gapfill_reactions(string array ref::list of models)
Description:
Example:
=cut

sub find_genes_for_gapfill_reactions {
    my ($self,$model_list) = @_;

    my $fig = $self->fig();

    my $org_list = [];

    my $rxns_to_models = {};
    my $roles_to_rxns = {};
    my $rxns_to_roles = {};
    my $pegs_to_roles = {};
    my $roles_to_pegs = {};
	print "Getting gapfilled reaction list\n";
    foreach my $model_id ( @$model_list ){
        print "Finding gapfill candidates for $model_id...\n";
        # Save just the organism IDs for future use
        push @$org_list, $self->get_model( $model_id )->genome();
        # Get model data
        my $model_table = $self->database()->GetDBModel( $model_id );

        # Iterate through the reactions in a model
        REACTION: for( my $i=0; $i < $model_table->size(); $i++ ){
            my $row = $model_table->get_row($i);
            # Find reactions with no associated genes
            if( defined ($row->{"ASSOCIATED PEG"} ) ){
                if( $row->{"ASSOCIATED PEG"}->[0] =~ m/^peg/ ){
                    next REACTION;
                }
                elsif( $row->{"ASSOCIATED PEG"}->[0] =~ m/^SPONTANEOUS/ ){
                    next REACTION;
                }
                elsif( $row->{"ASSOCIATED PEG"}->[0] =~ m/^BOF/ ){
                    next REACTION;
                }
                else{
                    # Reaction is gapfilled. Do nothing and continue...
                }
            }
            # .. to here, where we save rxns and the models they came from
            if( defined( $rxns_to_models->{$row->{"LOAD"}->[0]} ) ){
                push @{$rxns_to_models->{$row->{"LOAD"}->[0]}}, $model_id;
            }
            else{
                $rxns_to_models->{$row->{"LOAD"}->[0]} = [ $model_id ];
            }
        }
    }

    my @temp = keys %$rxns_to_models;
    print @temp." gap filled reactions found!\nOrganizing by functional role:\n";

    # Hash reactions by their functional roles
    foreach my $rxn ( keys %$rxns_to_models ){
        my $rls_of_rxns = $self->roles_of_reaction( $rxn );
        $rxns_to_roles->{$rxn} = $rls_of_rxns;
        if( $rls_of_rxns ){
            foreach( @$rls_of_rxns ){
                if( defined( $roles_to_rxns->{$_} ) ){
                    push @{$roles_to_rxns->{$_}}, $rxn;
                }
                else{
                    $roles_to_rxns->{$_} = [ $rxn ];
                }
            }
        }
    }
    
    @temp = keys %$roles_to_rxns;
    print @temp." distinct functional roles found!\nLooking for pegs:\n";

    # Get the proteins associated with functional roles from FIG
    foreach my $rls ( keys %$roles_to_rxns ){
        my @prots = $fig->prots_for_role( $rls );
        $roles_to_pegs->{$rls} = [];
        foreach( @prots ){
            push @{$roles_to_pegs->{$rls}}, $_;
            if( $pegs_to_roles->{$_} ){
                push @{$pegs_to_roles->{$_}}, $rls;
            }
            else{
                $pegs_to_roles->{$_} = [ $rls ];
            }
        }
    }
    
    @temp = keys %$pegs_to_roles;
    print @temp." pegs with roles found!\Querying for sims:\n";

    my $results = [];
    my $table = ModelSEED::FIGMODEL::FIGMODELTable->new( ["similar_peg", "roles", "reaction", "query", "percent_id", "alignment_length", "mismatches", "gap_openings", "query_match_start", "query_match_end", "similar_match_start", "similar_match_end", "e_val","bit_score", "query_length", "similar_length", "method" ],
                                    "",
                                    ["similar_peg", "query" ],
                                    ";",
                                    ":",
                                    undef );

    # Create a hash for our requests to the sim server.
    # hash->{key} = 0           - make a sim server request
    # hash->{key} = 1           - don't make a request. this protein has been filtered
    # hash->{key} = ARRAYREF    - request was made, filtered the proteiins in ARRAY
    my $requests = {};
    foreach( keys %$pegs_to_roles ){
        $requests->{$_} = 0;
    }

	my $count = 1;
    # For each protien, make a request to the sim server.
    QUERY: foreach my $query_peg ( sort keys %$requests ){
        $count++;
        if (floor($count/100) == $count/100) {
       		print "Query ".$count."\n";
        }
        
        # Move on if we've determined the request would be redundant
        if( $requests->{$query_peg} == 1 ){
        #    print STDERR "\n$query_peg removed by a previous request";
            next QUERY;
        }
        # Make sure we're not making a sim request for a gene in the same organism.
        # Would indicate some fishy business, so just ends
        foreach( @$org_list ){
            if( $query_peg =~ m/$_/ ){
                $requests->{$query_peg} = 1;
            my ($roles, $reactions) = $self->_roles_rxns_in_model( $_ , $query_peg, $pegs_to_roles,$roles_to_rxns, $rxns_to_models );
                $table->add_row( {  'similar_peg' => [ $query_peg ],
                                    'roles' => $roles,
                                    'reaction', $reactions,
                                    'query' => [ "DIRECT EVIDENCE" ] } );
                last QUERY;
            }
        }
        # Make a request and figure out what genome the match came from
        #print STDERR "\nQuerying sim server with $query_peg...";
        my @sim_results = $fig->sims( $query_peg, 10000, 0.00001, "fig");
        # Record that we have return values
        if( @sim_results ){
            $requests->{$query_peg} = [];
        #    print "processing results..."
        }
        else{
        #    print "no similar pegs."
        }
        # Process results
        RESULT: foreach my $result_row ( @sim_results ){
            # Check the similar peg against our list of organisms
            my $source_org;
            foreach( @$org_list ){
                if( $result_row->[1] =~ m/$_/ ){
                    $source_org = $_;
                }
            }
            # Skip to the next row unless the match comes from one of our models
            next RESULT unless $source_org;
            # Get the roles/reactions that got us this query peg
            push @{$requests->{$query_peg}}, $query_peg;
            my ($roles, $reactions) = $self->_roles_rxns_in_model( $source_org, $query_peg, $pegs_to_roles,$roles_to_rxns, $rxns_to_models );
            # Format and return a table row
            if( (my $entry = $table->get_row_by_key($result_row->[1],'similar_peg' )) ){
                push @{$entry->{'roles'}}, @$roles;
                push @{$entry->{'reaction'}}, @$reactions;
                push @{$entry->{'query'}}, $result_row->[0];
                push @{$entry->{'percent_id'}}, $result_row->[2];
                push @{$entry->{'alignment_length'}}, $result_row->[3];
                push @{$entry->{'mismatches'}}, $result_row->[4];
                push @{$entry->{'gap_openings'}}, $result_row->[5];
                push @{$entry->{'query_match_start'}}, $result_row->[6];
                push @{$entry->{'query_match_end'}}, $result_row->[7];
                push @{$entry->{'similar_match_start'}}, $result_row->[8];
                push @{$entry->{'similar_match_end'}}, $result_row->[9];
                push @{$entry->{'e_val'}}, $result_row->[10];
                push @{$entry->{'bit_score'}}, $result_row->[11];
                push @{$entry->{'query_length'}}, $result_row->[12];
                push @{$entry->{'similar_length'}}, $result_row->[13];
                push @{$entry->{'method'}}, $result_row->[14];
            }
            else{
                $table->add_row(  { 'similar_peg' => [ $result_row->[1] ],
                                    'roles' => $roles,
                                    'reaction' => $reactions,
                                    'query' => [$result_row->[0] ],
                                    'percent_id' => [$result_row->[2] ],
                                    'alignment_length' => [$result_row->[3] ],
                                    'mismatches' => [$result_row->[4] ],
                                    'gap_openings' => [$result_row->[5] ],
                                    'query_match_start' => [$result_row->[6] ],
                                    'query_match_end' => [$result_row->[7] ],
                                    'similar_match_start' => [$result_row->[8] ],
                                    'similar_match_end' => [$result_row->[9] ],
                                    'e_val' => [$result_row->[10] ],
                                    'bit_score' => [$result_row->[11] ],
                                    'query_length' => [$result_row->[12] ],
                                    'similar_length' => [$result_row->[13] ],
                                    'method' => [ $result_row->[14] ] } );
            }
        }
    }

	print "Removing duplicates!\n";

    # Quick and dirty: remove the duplicate roles/reactions
    for( my $i=0; $i < $table->size(); $i++ ){
        my $row = $table->get_row($i);
        my %cleaner;
        foreach( @{$row->{'roles'}} ){
            $cleaner{$_} = $_;
        }
        @{$row->{'roles'}} = keys %cleaner;
        %cleaner = ();
        foreach( @{$row->{'reaction'}} ){
            $cleaner{$_} = $_;
        }
        @{$row->{'reaction'}} = keys %cleaner;
    }

	print "Generating stats!\n";
    # Give a quick summary of the requests made
    my $total = 0;
    my $requested = 0;
    my $filtered = 0;
    my $nosim = 0;
    my $candidates = 0;
    foreach( keys %$requests ){
        $total++;
        if( $requests->{$_} == 0 ){
            $nosim++;
        }
        elsif( $requests->{$_} == 1 ){
            $filtered++;
        }
        elsif( ref( $requests->{$_} ) eq "ARRAY" ){
            $requested++;
            if( @{$requests->{$_}} ){
                $candidates++;
            }
        }
        else{
            print "Strange things happened with $_ ...\n";
        }
    }
    print "Done.\n";
    print "$total candidate pegs\n";
    print "$requested pegs returned similarites. $candidates were identified as candidates.\n";
    print "$nosim pegs returned no similarities.\n";
    print "$filtered candidate pegs called on direct evidence.\n";

    return $table;
}

=head3 _roles_rxns_in_model
Definition:
    (string array ref::role names,string array ref::reaction IDs) = FIGMODEL->_roles_rxns_in_model(string array ref::list of models)
Description:
Example:
=cut

sub _roles_rxns_in_model {
    my ($self, $org_id, $peg_id, $pegs_to_roles, $roles_to_rxns, $rxns_to_models ) = @_;

    my $roles = [];
    my $reactions = [];

    # For each role
    if( defined( $pegs_to_roles->{$peg_id} ) ){
        foreach my $role ( @{ $pegs_to_roles->{$peg_id} } ){
            my $insert = 0;
            # Return it if any reaction came from an organism we supplied
            if( defined($roles_to_rxns->{$role}) ){
                # And return each reaction that qualifies
                foreach my $rxn ( @{ $roles_to_rxns->{$role}} ){
                    foreach( @{$rxns_to_models->{$rxn}} ){
                        if( m/$org_id/ ){
                            push @$reactions, $rxn;
                            $insert = 1;
                        }
                    }
                }
            }
            push( @$roles, $role ) if $insert;
        }
    }
    return ( $roles, $reactions );
}

sub PrepSkeletonDirectory {
	my ($self, $directory,$genomeid) = @_;
	#Checking that the required input files are present
	if (!-e $directory."Genes.txt") {
		$self->error_message("FIGMODEL:PrepSkeletonDirectory:Required input file: ".$directory."Genes.txt not present!");
		return $self->fail();
	}
	if (!-e $directory.$genomeid.".1.fasta") {
		$self->error_message("FIGMODEL:PrepSkeletonDirectory:Required input file: ".$directory.$genomeid.".1.fasta");
		return $self->fail();
	}
	#Creating the necessary directories
	if (!-d $directory.$genomeid) {
		system("mkdir ".$directory.$genomeid);
	}
	if (!-d $directory.$genomeid."/Features/") {
		system("mkdir ".$directory.$genomeid."/Features/");
	}
	if (!-d $directory.$genomeid."/Features/peg/") {
		system("mkdir ".$directory.$genomeid."/Features/peg/");
	}
	#Opening fasta output file
	open (FASTA, ">".$directory.$genomeid."/Features/peg/fasta");
	#Opening table output file
	open (TABLE, ">".$directory.$genomeid."/Features/peg/tbl");
	#Opening gene file
	open (INPUT, "<".$directory."Genes.txt");
	#Keeping count of the current peg
	my $CurrentPeg = 1;
	while (my $Line = <INPUT>) {
		if ($Line =~ m/^>.+coord=(\d)+:(\d+)\.\.(\d+):([^;]+);/) {
			my $chromosome = $1;
			my $start = $2;
			my $end = $3;
			my $dir = $4;
			if ($dir eq "-1") {
				my $temp = $end;
				$end = $start;
				$start = $temp;
			}
			print FASTA ">fig|".$genomeid.".peg.".$CurrentPeg."\n";
			print TABLE "fig|".$genomeid.".peg.".$CurrentPeg."\t".$genomeid.".".$chromosome."_".$start."_".$end."\n";
			$CurrentPeg++;
		} else {
			print FASTA $Line;
		}
	}
	close(INPUT);
	close(TABLE);
	close(FASTA);
	#Combining the contig files
	open (CONTIG, ">".$directory.$genomeid."/contigs");
	my $contig = 1;
	while (-e $directory.$genomeid.".".$contig.".fasta") {
		#Opening fasta file
		open (INPUT, "<".$directory.$genomeid.".".$contig.".fasta");
		#Clearing the first line
		my $Line = <INPUT>;
		#Writing the correct first line
		print CONTIG ">".$genomeid.".".$contig."\n";
		while ($Line = <INPUT>) {
			print CONTIG $Line;
		}
		close(INPUT);
		$contig++;
	}
	close(CONTIG);
}

=head2 Model Regulation Related Methods

=head3 GetRegulonById
Definition:
	$FIGMODELTableRow = $model->GetRegulonById( $RegulonIdScalar );
Description:
	This function takes a scalar Id for a regulon, e.g. "fig|211586.9.reg.242"
	and returns a reference to a Hash containing the row data.
Example:
		
=cut
sub GetRegulonById {
	my ($self, $regulonId) = @_;
	my $organism;
  	if( $regulonId =~ /fig\|(\d+\.\d+)/ ) { # get 211586.9 out of "fig|211586.9.reg.242"
    	$organism = $1;
    } else {
        return undef;
    }
	# Regulons located in file inside "DB ROOT"/TRN-DB/"organism-ID"/Regulons.tbl
    my $regulonTable = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->{'database root directory'}->[0].'/TRN-DB/'.
													$organism.'/' . "Regulons.tbl", '\t', ',', 0, ['ID']);
	unless(defined($regulonTable)) {
		return undef;
	}
    my $regulon = $regulonTable->get_row_by_key($regulonId, 'ID');
	unless(defined($regulon)) {
		return undef;
	}
	return $regulon;
}
	
=head3 GetEffectorsOfRegulon
Definition:
	$EffectorList = $model->GetEffectorsOfRegulon( $RegulonIdScalar );
Description:
	This function takes a scalar Id for a regulon, e.g. "fig|211586.9.reg.242"
	and returns a reference to an array of effector ID strings
Example:
		
=cut
sub GetEffectorsOfRegulon {
	my ($self, $regulonId) = @_;
	# Get the regulon row
	my $regulon = $self->GetRegulonById($regulonId);
	unless(defined($regulon)) { return undef; }
	# Get the rule ( there can only be one )
	my $rule = $regulon->{'RULE'}->[0];
	unless(defined($rule)) { return undef; }
	my @splitRule = split( /[\s\(\)]/, $rule );
	my $results = [];
	foreach my $effector (@splitRule) {
		unless( $effector eq '' or $effector eq 'AND' or
				$effector eq 'OR' or $effector eq 'NOT' ) {
			push(@{$results}, $effector);
		}
	}
	return $results;
}

=head3 parse_experiment_description
Definition:
    FIGMODELTable:experiment table = FIGMODEL->parse_experiment_description([string]:experiment condition description)
Description:
=cut
sub parse_experiment_description {
	my ($self,$descriptions,$genome) = @_;
	
	my $translation = {
		"gly-glu" => ["cpd11592"],
		"n-acetyl-glucosamine" => ["cpd00122"],
		"sodium_thiosulfate" => ["cpd00268","cpd00971"],
		"dl-lactate" => ["cpd00159","cpd00221"],
		"potassium_phosphate_monobasic" => ["cpd00205","cpd00009"],
		"potassium_phosphate_dibasic" => ["cpd00205","cpd00009"],
		"sodium_selenate" => ["cpd03396","cpd00971"],
		"ferric_citrate" => ["cpd03725"],
		"iron(iii)_oxide" => ["cpd10516"],
		"ferrous_oxide" => ["cpd10515"],
		"ferric_nitrilotriacetate" => ["cpd10516"],
		"ammonium_sulfate" => ["cpd00013","cpd00048"],
		"zinc_sulfate" => ["cpd00034","cpd00048"],
		"iron(ii)_chloride" => ["cpd10515","cpd00099"],
		"na2seo4" => ["cpd03396","cpd00971"],
		"potassium_nitrate" => ["cpd00205","cpd00209"],
		"hepes" => ["NONE"],
		"aqds" => ["NONE"],
		"casamino_acids" => ["cpd00023","cpd00033","cpd00035","cpd00039","cpd00041","cpd00051","cpd00053","cpd00054","cpd00060","cpd00066","cpd00069","cpd00084","cpd00107","cpd00119","cpd00129","cpd00132","cpd00156","cpd00161","cpd00322"],
		"peptone" => ["cpd00023","cpd00033","cpd00035","cpd00039","cpd00041","cpd00051","cpd00053","cpd00054","cpd00060","cpd00065","cpd00066","cpd00069","cpd00084","cpd00107","cpd00119","cpd00129","cpd00132","cpd00156","cpd00161","cpd00322"],
		"yeast_extract" => ["cpd00239","cpd00541","cpd00216","cpd00793","cpd00046","cpd00091","cpd00018","cpd00126","cpd00311","cpd00182","cpd00035","cpd00051","cpd01048","cpd00041","cpd00063","cpd01012","cpd11595","cpd00381","cpd00438","cpd00654","cpd10516","cpd00393","cpd00027","cpd00023","cpd00033","cpd00067","cpd00001","cpd00531","cpd00119","cpd00226","cpd00322","cpd00246","cpd00205","cpd00107","cpd00039","cpd00060","cpd00254","cpd00971","cpd00218","cpd00066","cpd00009","cpd00644","cpd00129","cpd00220","cpd00054","cpd00048","cpd00161","cpd00184","cpd00065","cpd00069","cpd00092","cpd00249","cpd00156","cpd00034","cpd00007","cpd00099","cpd00058","cpd00149","cpd00030","cpd10515","cpd00028"],
		"aluminum_potassium_disulfate" => ["cpd00205","cpd000048"],
		"ammonium_chloride" => ["cpd00013","cpd00099"],
		"b12" => ["cpd00166"],
		"b5" => ["NONE"],
		"biotin(d-biotin)" => ["cpd00104"],
		"boric_acid" => ["cpd09225"],
		"calcium_chloride" => ["cpd00063","cpd00099"],
		"cobalt_chloride" => ["cpd000149","cpd00099"],
		"culture_o2" => ["cpd00007"],
		"cupric_sulfate" => ["cpd00058","cpd00048"],
		"dl-serine" => ["cpd00054","cpd000550"],
		"ferrous_sulfate" => ["cpd10515","cpd00048"],
		"folic_acid" => ["cpd00393"],
		"fumarate" => ["cpd00106"],
		"l-arginine" => ["cpd00051"],
		"l-glutamic_acid" => ["cpd00023"],
		"lactate" => ["cpd00159"],
		"magnesium_sulfate" => ["cpd00254"],
		"manganese_sulfate" => ["cpd00030"],
		"nickel_chloride" => ["cpd00244","cpd00099"],
		"nicotinic_acid" => ["cpd00218"],
		"nitrilotriacetic_acid" => ["NONE"],
		"p-aminobenzoic_acid" => ["cpd00443"],
		"potassium_chloride" => ["cpd00205","cpd00099"],
		"pyridoxine_hcl" => ["cpd00478","cpd00099"],
		"riboflavin" => ["cpd00220"],
		"sodium_chloride" => ["cpd00971","cpd00099"],
		"sodium_molybdate" => ["cpd00971","cpd11574"],
		"sodium_phosphate_monobasic" => ["cpd00971","cpd00009"],
		"sodium_tungstate" => ["cpd00971","cpd15574"],
		"thiamine_hcl" => ["cpd00305","cpd00099"],
		"thioctic_acid" => ["NONE"],
		"zinc_chloride" => ["cpd00034","cpd00099"]
	};
	
	#Checking if the input is a filename instead of an array of data
	$descriptions = $self->database()->check_for_file($descriptions);
	#Processing the input list of experimental conditions
	$self->database()->LockDBTable("EXPERIMENT");
	$self->database()->LockDBTable("MEDIA");
	my $temp = $self->database()->GetDBTable("MEDIA");
	for (my $i=0; $i < $temp->size(); $i++) {
		my @sortedcpd = sort(@{$temp->get_row($i)->{COMPOUNDS}});
		$temp->get_row($i)->{cpdcode}->[0] = join("",@sortedcpd);
	}
	$temp->add_hashheadings(("cpdcode"));
	for (my $i=0; $i < @{$descriptions}; $i++) {
		my @array = split(/\t/,$descriptions->[$i]);
		#Checking if an experiment by the same name already exists
		my $newobj = {_type => "EXPERIMENT",_key => "name",name => [$array[0]],genome => [$genome]};
		my $newmedia = {_type => "MEDIA",_key => "cpdcode",NAME => [$array[0]."_media"]};
		my $columns;
		for (my $k=1; $k < @array; $k++) {
			my @subarray = split(/:/,$array[$k]);
			my $compound;
			#Checking if a translation exists
			if (defined($translation->{$subarray[0]})) {
				for (my $j=0; $j < @{$translation->{$subarray[0]}};$j++) {
					$compound = $self->database()->get_object_from_db("COMPOUNDS",{"DATABASE"=>$translation->{$subarray[0]}->[$j]});
					if (defined($compound)) {
						my $add = 1;
						if (defined($newmedia->{COMPOUNDS})) {
							for (my $m=0; $m < @{$newmedia->{COMPOUNDS}};$m++) {
								if ($newmedia->{COMPOUNDS}->[$m] eq $compound->{DATABASE}->[0]) {
									$add = 0;
								}
							}
						}
						if ($add == 1) {
							push(@{$newmedia->{COMPOUNDS}},$compound->{DATABASE}->[0]);
							push(@{$newmedia->{NAMES}},$compound->{NAME}->[0]);
							push(@{$newmedia->{MAX}},100);
							push(@{$newmedia->{MIN}},-100);
							push(@{$newmedia->{CONCENTRATIONS}},$subarray[1]);
						}
					}
				}
			} else {
				#Checking if the item could refer to a chemical compound
				my @names = $self->convert_to_search_name($subarray[0]);
				for (my $j=0; $j < @names; $j++){
					$compound = $self->database()->get_object_from_db("COMPOUNDS",{"SEARCHNAME"=>$names[$j]});
					if (defined($compound)) {
						last;
					}
				}
				#if this is a compound, we add it to the media, otherwise we add as a column to the experiment table
				if (defined($compound)) {
					my $add = 1;
					if (defined($newmedia->{COMPOUNDS})) {
						for (my $m=0; $m < @{$newmedia->{COMPOUNDS}};$m++) {
							if ($newmedia->{COMPOUNDS}->[$m] eq $compound->{DATABASE}->[0]) {
								$add = 0;
							}
						}
					}
					if ($add == 1) {
						push(@{$newmedia->{COMPOUNDS}},$compound->{DATABASE}->[0]);
						push(@{$newmedia->{NAMES}},$compound->{NAME}->[0]);
						push(@{$newmedia->{MAX}},100);
						push(@{$newmedia->{MIN}},-100);
						push(@{$newmedia->{CONCENTRATIONS}},$subarray[1]);
					}
				} else {
					$newobj->{$subarray[0]}->[0] = $subarray[1];
					$columns->{$subarray[0]} = "";
				}
			}
		}
		if (defined($newmedia->{COMPOUNDS}) && @{$newmedia->{COMPOUNDS}} > 0) {
			my @sortedcpd = sort(@{$newmedia->{COMPOUNDS}});
			$newmedia->{cpdcode}->[0] = join("",@sortedcpd);
			$newmedia = $self->database()->add_object_to_db($newmedia,0);
			$newobj->{media}->[0] = $newmedia->{NAME}->[0];
		}
		$self->database()->add_object_to_db($newobj,1);
		$self->database()->add_columns_to_db("EXPERIMENT",$columns);
	}
	$self->database()->GetDBTable("EXPERIMENT")->save();
	$self->database()->GetDBTable("MEDIA")->save();
	$self->database()->UnlockDBTable("EXPERIMENT");
	$self->database()->UnlockDBTable("MEDIA");
}
=head3 getExperimentsTable
Definition:
    FIGMODELTable:experiment table = FIGMODEL->getExperimentsTable()
Description:
    Returns the experiment table object.
=cut

sub getExperimentsTable {
    my ($self) = @_;
    unless (defined($self->{"CACHE"}->{"EXPERIMENT_TABLE"})) {
        $self->{"CACHE"}->{"EXPERIMENT_TABLE"} = $self->database()->load_table(
            $self->{"Reaction database directory"}->[0]."masterfiles/Experiments.txt",
            '\t', ',', 0, ['name', 'genome']) or die "Could not load Experiments database! Error: " . $!;
    }
    return $self->{"CACHE"}->{"EXPERIMENT_TABLE"};
}

=head3 getExperimentsByGenome
Definition:
    ArrayRef[[string] experimentId]  = FIGMODEL->getExperimentsByGenome([string] genomeId)
Description:
    Returns a reference to an array of experimentId strings. 
    Use getExperimentDetails to get experiment data.
=cut
sub getExperimentsByGenome {
    my ($self, $genomeId) = @_;
    my $experimentsTable = $self->getExperimentsTable();
    my @results = $experimentsTable->get_rows_by_key($genomeId, 'genome');
    my @experimentIds;
    foreach my $result (@results) {
        push(@experimentIds, $result->{'name'});
    }
    return \@experimentIds;
}

=head3 getExperimentDetails
Definition:
   FIGMODELTable::row  = FIGMODEL->getExperimentDetails([string] experimentId)
Description:
    Returns a row (hash ref of key => []) containing details of experiment. 
=cut
sub getExperimentDetails {
    my ($self, $experimentId) = @_;
    my $experimentsTable = $self->getExperimentsTable();
    my $row = $experimentsTable->get_row_by_key($experimentId, 'name');
    unless(defined($row)) { return {}; }
    return $row;
}

=head3 patch_models
Definition:
   FIGMODEL->patch_models([] -or- {} of arguments for patch)
Description:
    Runs a patching function on every model in the database to quickly enact some kind of systematic change.
=cut
sub patch_models {
    my ($self,$list) = @_;
    my $models;
    my $start = 0;
    if (!defined($list->[0])) {
    	$models = $self->get_models();
    } elsif ($list->[0] =~ m/^\d+$/) {
    	$start = $list->[0];
    	$models = $self->get_models();
    } else {
    	for (my $i=0; $i < @{$list}; $i++) {
    		push(@{$models},$self->get_model($list->[$i]));
    	}
    }
	for (my $i=$start; $i < @{$models}; $i++) {
		print "Patching model ".$i." ".$models->[$i]->id()."...";
		$models->[$i]->patch_model();
		print " done.\n";
	}
}

=head3 call_model_function
Definition:
   FIGMODEL->call_model_function(string:function,[string]:model list)
Description:
    Runs the specified function on all specified models.
=cut
sub call_model_function {
    my ($self,$function,$list) = @_;
    my $models;
    my $start = 0;
    if (!defined($list->[0])) {
    	$models = $self->get_models();
    } elsif ($list->[0] =~ m/^\d+$/) {
    	$start = $list->[0];
    	$models = $self->get_models();
    } else {
    	for (my $i=0; $i < @{$list}; $i++) {
    		push(@{$models},$self->get_model($list->[$i]));
    	}
    }
    my @arguments;
    if ($function =~ m/(.+)\((.+)\)/) {
    	$function = $1;
    	@arguments = split(/,/,$2);
    }
	for (my $i=$start; $i < @{$models}; $i++) {
		print "Calling ".$function." on model ".$i." ".$models->[$i]->id()."...";
		if (@arguments > 0) {
			$models->[$i]->$function(@arguments);
		} else {
			$models->[$i]->$function();
		}
		print " done.\n";
	}
}

=head3 process_models
Definition:
   FIGMODEL->process_models()
Description:
    Looks for incomplete models and ungapfilled models and automatically runs preliminary reconstruction and autocompletion
=cut
sub process_models {
    my ($self,$startNumber,$owner) = @_;
    my $objs = $self->database()->get_objects("model");
    if (!defined($startNumber)) {
    	$startNumber = 0;
    }
    for (my $i=$startNumber; $i < @{$objs}; $i++) {
    	print $i."\n";
    	if (!defined($owner) || $objs->[$i]->owner() eq $owner) {
	    	if ($objs->[$i]->id() =~ m/^Seed/ && $objs->[$i]->status() < 0) {
	    		print "Building model"."\n";
	    		$self->add_job_to_queue({command => "preliminaryreconstruction?".$objs->[$i]->id()."?1?",user => $objs->[$i]->owner(),queue => "short"});
	    	} elsif ((!defined($objs->[$i]->growth()) || $objs->[$i]->growth() == 0) && $objs->[$i]->owner() ne "mdejongh" && $objs->[$i]->owner() ne "AaronB") {
	    		print "Gapfilling model"."\n";
	    		$self->add_job_to_queue({command => "gapfillmodel?".$objs->[$i]->id(),user => $objs->[$i]->owner(),queue => "cplex"});
	    	}
    	}
    }
}

=head3 retrieve_load_gapfilling_results
Definition:
   FIGMODEL->retrieve_load_gapfilling_results(string:LP directory)
Description:
=cut
sub retrieve_load_gapfilling_results {
	my ($self,$copyFiles,$folder,$start) = @_;
	if ($copyFiles == 1) {
		system("scp -i ~/.ssh/id_rsa2 tg-login.ranger.tacc.teragrid.org:/work/01276/chenry/JobDirectory/Output/work01276chenryscip-1.1.0scip.sh-swork01276chenryJobDirectorySettings.txt-fwork01276chenryJobDirectory".$folder."GapFilling-* ".$self->config("LP file directory")->[0]."SolvedFiles/");
	}
	if (!defined($start)) {
		$start = 0;	
	}
	my @filelist = glob($self->config("LP file directory")->[0]."SolvedFiles/*");
	for (my $i=$start; $i < @filelist; $i++) {
		if ($filelist[$i] =~ m/GapFilling-(.+)\.lp\.out/) {
			print "Processing model ".$i.": ".$1;
			my $mdl = $self->get_model($1);
			if (defined($mdl)) {
				print ". Running...";
				$mdl->load_scip_gapfill_results($filelist[$i]);
			}
			print "\n";
		}
	}
}

=head3 process_strain_data
Definition:
   FIGMODEL->process_strain_data()
Description:
=cut
sub process_strain_data {
	my ($self) = @_;
	my $intTbl = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("interval directory")->[0]."IntervalDefinitions.tbl","\t","|",0,["ID"]);
	my $intIDTbl = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("interval directory")->[0]."IntervalID.tbl","\t","|",0,["ID"]);
	my $singleStrainTbl = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("interval directory")->[0]."SingleIntervalStrains.tbl","\t","|",0,["NAME"]);
	my $multiStrainTbl = ModelSEED::FIGMODEL::FIGMODELTable::load_table($self->config("interval directory")->[0]."MultiIntervalStrains.tbl","\t","|",0,["NAME"]);
	my $strainTbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["NAME","POSITION 1","POSITION 2","INTERVAL KO","RESISTANCE","PHENOTYPE","KO PEGS","KO GENE NAMES","KO GENE LOCI"],$self->config("interval directory")->[0]."AllStrains.tbl",["NAME","POSITION 1","POSITION 2","INTERVAL KO","RESISTANCE","KO PEGS","KO GENE NAMES","KO GENE LOCI"],"\t","|",undef);
	my $intervalTbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["NAME","ID","START","END","STRAINS","SIZE","KO PEGS","KO GENE NAMES","KO GENE LOCI"],$self->config("interval directory")->[0]."AllIntervals.tbl",["NAME","ID","STRAINS","KO PEGS","KO GENE NAMES","KO GENE LOCI"],"\t","|",undef);
	my $featureStrainTbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["PEG ID","LOCUS ID","GENE NAME","KO STRAINS","KO INTERVALS","FUNCTION","MIN LOCATION","MAX LOCATION"],$self->config("interval directory")->[0]."AllGenes.tbl",["PEG ID","LOCUS ID","GENE NAME","KO STRAINS","KO INTERVALS","FUNCTION"],"\t","|",undef);
	my $featureTbl = $self->GetGenomeFeatureTable("224308.1");
	for (my $j=0; $j < $featureTbl->size(); $j++) {
		my $featureRow = $featureTbl->get_row($j);
		if ($featureRow->{"ID"}->[0] =~ m/(peg\.\d+)/) {
			my $peg = $1;
			my $newRow = {"PEG ID"=>[$peg],"FUNCTION"=>$featureRow->{"ROLES"},"MIN LOCATION"=>$featureRow->{"MIN LOCATION"},"MAX LOCATION"=>$featureRow->{"MAX LOCATION"}};
			for (my $k=0; $k < @{$featureRow->{ALIASES}}; $k++) {
				if ($featureRow->{ALIASES}->[$k] =~ m/Bsu\d+/) {
					$newRow->{"LOCUS ID"}->[0] = $featureRow->{ALIASES}->[$k];
				} elsif ($featureRow->{ALIASES}->[$k] =~ m/^[A-Za-z]{3,5}$/) {
					$newRow->{"GENE NAME"}->[0] = $featureRow->{ALIASES}->[$k];
				}
			}
			$featureStrainTbl->add_row($newRow);
		}
	}
	for (my $i=0; $i < $intTbl->size(); $i++) {
		my $row = $intTbl->get_row($i);
		my $intRow = $intervalTbl->get_row_by_key($row->{ID}->[0],"NAME",1);
		$intRow->{"END"}->[0] = $row->{"END"}->[0];
		$intRow->{START}->[0] = $row->{START}->[0];
		$intRow->{SIZE}->[0] = $row->{"END"}->[0] - $intRow->{START}->[0];
		for (my $j=0; $j < $featureTbl->size(); $j++) {
			my $featureRow = $featureTbl->get_row($j);
			if ($featureRow->{"ID"}->[0] =~ m/(peg\.\d+)/ && $featureRow->{"MAX LOCATION"}->[0] > $intRow->{START}->[0] && $featureRow->{"MIN LOCATION"}->[0] < $intRow->{"END"}->[0]) {
				my $peg = $1;
				my $featureStrainRow = $featureStrainTbl->get_row_by_key($peg,"PEG ID");
				if (defined($featureStrainRow)) {
					push(@{$featureStrainRow->{"KO INTERVALS"}},$row->{ID}->[0]);	
				}
				push(@{$intRow->{"KO PEGS"}},$peg);
				my $name = $peg;
				my $locus = $peg;
				for (my $k=0; $k < @{$featureRow->{ALIASES}}; $k++) {
					if ($featureRow->{ALIASES}->[$k] =~ m/Bsu\d+/) {
						$locus = $featureRow->{ALIASES}->[$k];
					} elsif ($featureRow->{ALIASES}->[$k] =~ m/^[A-Za-z]{3,5}$/) {
						$name = $featureRow->{ALIASES}->[$k];
					}
				}
				push(@{$intRow->{"KO GENE NAMES"}},$name);
				push(@{$intRow->{"KO GENE LOCI"}},$locus);
			}
		}
	}
	for (my $i=0; $i < $intIDTbl->size(); $i++) {
		my $row = $intIDTbl->get_row($i);
		for (my $j=0; $j < @{$row->{INTERVALS}};$j++) {
			my $intRow = $intervalTbl->get_row_by_key($row->{INTERVALS}->[$j],"NAME",1);
			$intervalTbl->add_data($intRow,"ID",$row->{ID}->[0],1);
		}
	}
	$intervalTbl->save();
	for (my $i=0; $i < $singleStrainTbl->size(); $i++) {
		my $row = $singleStrainTbl->get_row($i);
		my $strainRow = $strainTbl->get_row_by_key($row->{NAME}->[0],"NAME",1);
		$strainRow->{"POSITION 1"}->[0] = $row->{"POSITION 1"}->[0];
		$strainRow->{"POSITION 2"}->[0] = $row->{"POSITION 2"}->[0];
		$strainRow->{"INTERVAL KO"} = $row->{INTERVALS};
		$strainRow->{"RESISTANCE"} = $row->{RESISTANCE};
		if ($row->{NMS}->[0] eq "+") {
			$strainRow->{"PHENOTYPE"}->[0] = "Growth on NMS";
		} elsif ($row->{NMS}->[0] eq "Slow") {
			$strainRow->{"PHENOTYPE"}->[0] = "Slow on NMS";
		} elsif ($row->{NMS}->[0] eq "-" && $row->{LB}->[0] eq "+") {
			$strainRow->{"PHENOTYPE"}->[0] = "Growth on LB";
		} elsif ($row->{NMS}->[0] eq "-" && $row->{LB}->[0] eq "Slow") {
			$strainRow->{"PHENOTYPE"}->[0] = "Slow on LB";
		} else {
			$strainRow->{"PHENOTYPE"}->[0] = "No growth";
		}
		for (my $j=0; $j < @{$strainRow->{"INTERVAL KO"}}; $j++) {
			my $intRow = $intervalTbl->get_row_by_key($strainRow->{"INTERVAL KO"}->[$j],"NAME");
			if (defined($intRow)) {
				push(@{$intRow->{STRAINS}},$row->{NAME}->[0]);
				push(@{$strainRow->{"KO PEGS"}},@{$intRow->{"KO PEGS"}});
				push(@{$strainRow->{"KO GENE NAMES"}},@{$intRow->{"KO GENE NAMES"}});
				push(@{$strainRow->{"KO GENE LOCI"}},@{$intRow->{"KO GENE LOCI"}});
			}
		}
	}
	for (my $i=0; $i < $multiStrainTbl->size(); $i++) {
		my $row = $multiStrainTbl->get_row($i);
		my $strainRow = $strainTbl->get_row_by_key($row->{NAME}->[0],"NAME",1);
		$strainRow->{"POSITION 1"}->[0] = $row->{"POSITION 1"}->[0];
		$strainRow->{"POSITION 2"}->[0] = $row->{"POSITION 2"}->[0];
		for (my $j=0; $j < @{$row->{INTERVALS}}; $j++) {
			my @rows = $intervalTbl->get_rows_by_key($row->{INTERVALS}->[$j],"ID");
			if (@rows == 0) {
				print $row->{INTERVALS}->[$j]." has no intervals!\n";
			}
			for (my $k=0; $k < @rows; $k++) {
				push(@{$strainRow->{"INTERVAL KO"}},$rows[$k]->{NAME}->[0]);
			}
		}
		$strainRow->{RESISTANCE} = $row->{RESISTANCE};
		$strainRow->{PHENOTYPE} = $row->{PHENOTYPE};
		if (defined($strainRow->{"INTERVAL KO"})) {
			for (my $j=0; $j < @{$strainRow->{"INTERVAL KO"}}; $j++) {
				my $intRow = $intervalTbl->get_row_by_key($strainRow->{"INTERVAL KO"}->[$j],"NAME");
				if (defined($intRow)) {
					push(@{$intRow->{STRAINS}},$row->{NAME}->[0]);
					push(@{$strainRow->{"KO PEGS"}},@{$intRow->{"KO PEGS"}});
					push(@{$strainRow->{"KO GENE NAMES"}},@{$intRow->{"KO GENE NAMES"}});
					push(@{$strainRow->{"KO GENE LOCI"}},@{$intRow->{"KO GENE LOCI"}});
				}
			}
		}
	}
	for (my $i=0; $i < $strainTbl->size(); $i++) {
		my $row = $strainTbl->get_row($i);
		if (defined($row->{"KO PEGS"})) {
			for (my $j=0; $j < @{$row->{"KO PEGS"}}; $j++) {
				my $featureStrainRow = $featureStrainTbl->get_row_by_key($row->{"KO PEGS"}->[$j],"PEG ID");
				if (defined($featureStrainRow)) {
					push(@{$featureStrainRow->{"KO STRAINS"}},$row->{NAME}->[0]);
				}
			}
		}
	}
	$strainTbl->save();
	$intervalTbl->save();
	$featureStrainTbl->save();
}

=head2 Utility methods

=head3 processIDList
Definition:
	{} = FIGMODEL->processIDList({
		objectType => string,
		delimiter => ",",
		column => "id",
		parameters => {},
		input => string
	});
	Output = {
		error => undef,
		list => [string]	
	}
Description:	
=cut
sub processIDList {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["objectType","input"],{
		delimiter => ",",
		parameters => {},
		column => "id"
	});
	if (defined($args->{error})) {return $self->error_message({function=>"processIDList",args=>$args});}
	if ($args->{input} eq "ALL") {
		my $objects = $self->database()->get_objects($args->{objectType},$args->{parameters});
		my $function = $args->{column};
		my $results;
		for (my $i=0; $i < @{$objects}; $i++) {
			if (defined($objects->[$i]->$function())) {
				push(@{$results->{list}},$objects->[$i]->$function());	
			}
		}
		return $results;
	} elsif ($args->{input} =~ m/FILE-(.+)$/) {
		my $filename = $1;
		if (!-e $filename) {return $self->error_message({message => "Could not load file ".$filename,function=>"processIDList",args=>$args});}
		return {list=>$self->database()->load_single_column_file($filename,"")};
	} else {
		return {list=>[split($args->{delimiter},$args->{input})]};
	}
	return return $self->error_message({message => "Unhandled use case",function=>"processIDList",args=>$args});
}
=head3 timestamp
Definition:
	TIMESTAMP = FIGMODEL->timestamp();
Description:	
=cut
sub timestamp {
	my ($self) = @_;
	my ($sec,$min,$hour,$day,$month,$year) = gmtime(time());
	$year += 1900;
	$month += 1;
	return $year."-".$month."-".$day.' '.$hour.':'.$min.':'.$sec;
}
=head3 put_two_column_array_in_hash
Definition:
	({string:1 => string:2},{string:2 => string:1}) = FIGMODEL->put_two_column_array_in_hash([[string:1,string:2]]);
Description:
	Loads the input array into a hash
=cut
sub put_two_column_array_in_hash {
	my ($self,$ArrayRef) = @_;
	if (!defined($ArrayRef) || ref($ArrayRef) ne "ARRAY") {
		return undef;
	}
	my $HashRefOne;
	my $HashRefTwo;
	for (my $i=0; $i < @{$ArrayRef}; $i++) {
		if (ref($ArrayRef->[$i]) eq "ARRAY" && @{$ArrayRef->[$i]} >= 2) {
			$HashRefOne->{$ArrayRef->[$i]->[0]} = $ArrayRef->[$i]->[1];
			$HashRefTwo->{$ArrayRef->[$i]->[1]} = $ArrayRef->[$i]->[0];
		}
	}
	return ($HashRefOne,$HashRefTwo);
}

=head3 put_hash_in_two_column_array
Definition:
	[[string:1,string:2]]/[[string:2,string:1]] = FIGMODEL->put_hash_in_two_column_array({string:1 => string:2},0/1);
Description:
	Loads a hash into a two column array
=cut
sub put_hash_in_two_column_array {
	my ($self,$Hash,$Forward) = @_;
	if (!defined($Hash) || ref($Hash) ne "HASH") {
		return undef;
	}
	my $ArrayRef;
	my @keyArray = keys(%{$Hash});
	for (my $i=0; $i < @keyArray; $i++) {
		if (!defined($Forward) || $Forward == 1) {
			$ArrayRef->[$i]->[0] = $keyArray[$i];
			$ArrayRef->[$i]->[1] = $Hash->{$keyArray[$i]};
		} else {
			$ArrayRef->[$i]->[1] = $keyArray[$i];
			$ArrayRef->[$i]->[0] = $Hash->{$keyArray[$i]};
		}
	}
	return $ArrayRef;
}

=head3 put_array_in_hash
Definition:
	{string => int} = FIGMODEL->put_array_in_hash([string]);
Description:
	Loads the input array into a hash
=cut
sub put_array_in_hash {
	my ($self,$ArrayRef) = @_;
	my $HashRef;
	for (my $i=0; $i < @{$ArrayRef}; $i++) {
		$HashRef->{$ArrayRef->[$i]} = $i;
	}
	return $HashRef;
}

=head3 date
Definition:
	string = FIGMODEL->date(string::time);
Description:
	Translates epoch seconds into a date.
=cut
sub date {
	my ($self,$Time) = @_;
	if (!defined($Time)) {
		$Time = time();
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($Time);

	return ($mon+1)."/".($mday)."/".($year+1900);
}

=head3 runexecutable
Definition:
	[string]:lines of output = FIGMODEL->runexecutable(string:command);
=cut
sub runexecutable {
    my ($self,$Command) = @_;
	my $OutputArray;
	push(@{$OutputArray},`$Command`);
	return $OutputArray;
}

=head3 invert_hash
Definition:
	{string:value B => [string:value A]}:inverted hash = FIGMODEL->invert_hash({string:value A => [string:value B]});
Description:
	Switches the values into keys and the keys into values.
=cut
sub invert_hash {
    my ($self,$inputhash) = @_;
	my $outputhash;
	foreach my $key (keys(%{$inputhash})) {
		foreach my $value (@{$inputhash->{$key}}) {
			push(@{$outputhash->{$value}},$key);
		}
	}
	return $outputhash;
}

=head3 add_elements_unique
Definition:
	([string]::altered array,integer::number of matches) = FIGMODEL->add_elements_unique([string]::existing array,(string)::new elements);
Description:
	Loads the input array into a hash
=cut
sub add_elements_unique {
	my ($self,$ArrayRef,@NewElements) = @_;

	my $ArrayValueHash;
	my $NewArray;
	if (defined($ArrayRef) && @{$ArrayRef} > 0) {
		for (my $i=0; $i < @$ArrayRef; $i++) {
			if (!defined($ArrayValueHash->{$ArrayRef->[$i]})) {
				push(@{$NewArray},$ArrayRef->[$i]);
				$ArrayValueHash->{$ArrayRef->[$i]} = @{$NewArray}-1;
			}
		}
	}

	my $NumberOfMatches = 0;
	for (my $i=0; $i < @NewElements; $i++) {
		if (length($NewElements[$i]) > 0 && !defined($ArrayValueHash->{$NewElements[$i]})) {
			push(@{$NewArray},$NewElements[$i]);
			$ArrayValueHash->{$NewElements[$i]} = @{$NewArray}-1;
		} else {
			$NumberOfMatches++;
		}
	}

	return ($NewArray,$NumberOfMatches);
}

=head3 remove_duplicates
Definition:
	(string)::output array = FIGMODEL->remove_duplicates((string)::input array);
Description:
	Loads the input array into a hash
=cut
sub remove_duplicates {
	my ($self,@OriginalArray) = @_;

	my %Hash;
	my @newArray;
	foreach my $Element (@OriginalArray) {
		if (!defined($Hash{$Element})) {
			$Hash{$Element} = 1;
			push(@newArray,$Element);
		}
	}
	return @newArray;
}

=head3 convert_number_for_viewing
Definition:
	double:converted number = FIGMODEL->convert_number_for_viewing(double:input number);
Description:
	Converts the input number into scientific notation and rounds to the second digit
=cut

sub convert_number_for_viewing {
	my ($self,$input) = @_;
	my $sign = 1;
	if ($input < 0) {
		$sign = -1;
		$input = -1*$input;
	}
	my ($one,$two) = split(/\./,$input);
	my $numDig = 0;
	if ($one > 999) {
		$numDig = length($one)-1;
		my $divisor = 10**$numDig;
		$one = $one/$divisor;
		$input = $one.$two;
	} elsif ($input =~ m/^0\.(0+)/) {
		$numDig = (length($1)+1);
		my $divisor = 10**$numDig;
		$input = $input*$divisor;
		$numDig = -1*$numDig;
	}
	#Rounding number as needed
	$input = sprintf("%.3f", $input);
	#Adding exponent to number if necessary
	$input = $input*$sign;
	if ($numDig != 0) {
		$input .= "e".$numDig;
	}
	return $input;
}

=head3 format_coefficient
Definition:
	string = FIGMODEL->format_coefficient(string);
Description:
	Loads the input array into a hash
=cut
sub format_coefficient {
	my ($self,$Original) = @_;

	#Converting scientific notation to normal notation
	if ($Original =~ m/[eE]/) {
		my $Coefficient = "";
		my @Temp = split(/[eE]/,$Original);
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
		$Original = $Coefficient;
	}
	#Removing trailing zeros
	if ($Original =~ m/(.+\..+)0+$/) {
		$Original = $1;
	}
	$Original =~ s/\.0$//;

	return $Original;
}

sub ceil {
	return int(shift()+.5);
}

sub floor {
	return int(shift());
}

=head3 compareArrays
Definition:
	Output = FIGMODEL->compareArrays({
		string:labels => [string]:labels,
		string:data => [[string]]:data
	});
	Output = {
		string:label one => {
			string:label two => double:fraction overlap
		}
	}
Description:
=cut
sub compareArrays {
	my ($self,$args) = @_;
	$args = $self->process_arguments($args,["labels","data"],{type => "fraction"});
	if (defined($args->{error})) {return $self->new_error_message({function => "compareArrays",args => $args});}
	my $results;
	for (my $i=0; $i < @{$args->{labels}}; $i++) {
		for (my $j=0; $j < @{$args->{labels}}; $j++) {
			if ($i == $j) {
				if ($args->{type} eq "decimal") {
					$results->{$args->{labels}->[$i]}->{$args->{labels}->[$j]} = 1;
				} elsif ($args->{type} eq "difference") {
					$results->{$args->{labels}->[$i]}->{$args->{labels}->[$j]} = 0;
				} elsif ($args->{type} eq "fraction") {
					$results->{$args->{labels}->[$i]}->{$args->{labels}->[$j]} = @{$args->{data}->[$i]}."/".@{$args->{data}->[$i]};
				}
			} else {
				my $matchCount = 0;
				for (my $k=0; $k < @{$args->{data}->[$i]}; $k++) {
					for (my $m=0; $m < @{$args->{data}->[$j]}; $m++) {
						if ($args->{data}->[$i]->[$k] eq $args->{data}->[$i]->[$m]) {
							$matchCount++;
							last;
						}
					}
				}
				if ($args->{type} eq "decimal") {
					$results->{$args->{labels}->[$i]}->{$args->{labels}->[$j]} = $matchCount/@{$args->{data}->[$i]};
				} elsif ($args->{type} eq "difference") {
					$results->{$args->{labels}->[$i]}->{$args->{labels}->[$j]} = (@{$args->{data}->[$i]}-$matchCount);
				} elsif ($args->{type} eq "fraction") {
					$results->{$args->{labels}->[$i]}->{$args->{labels}->[$j]} = $matchCount."/".@{$args->{data}->[$i]};
				}
			}
		}	
	}
	return $results;
}

=head3 copyMergeHash
Definition:
	{} = FIGMODEL->copyMergeHash([{}]);
Description:
=cut
sub copyMergeHash {
	my ($self,$hashArray) = @_;
	my $result;
	for (my $i=0; $i < @{$hashArray}; $i++) {
		foreach my $key (keys(%{$hashArray->[$i]})) {
			$result->{$key} = $hashArray->[$i]->{$key};
		}	
	}
	return $result;
}

=head3 printmessages
Definition:
	$model->printmessages();
Description:
Example:
=cut

sub PrintMessages {
	my ($self,$Message) = @_;
	my $Filename = $self->{"message output filename"}->[0];
	if (-e $Filename) {
	open (MESSAGEOUTPUT, ">>$Filename");
	} else {
	open (MESSAGEOUTPUT, ">>$Filename");
	}
	print MESSAGEOUTPUT $Message."\n";
	close(MESSAGEOUTPUT);
}

=head2 Pass-through functions that will soon be deleted entirely
=cut
sub CreateSingleGenomeReactionList {
	my ($self,$GenomeID,$Owner,$RunGapFilling) = @_;
	$self->createNewModel({-genome => $GenomeID,-owner => $Owner,-gapfilling => $RunGapFilling})
}
sub CpdLinks {
	my ($self,$CpdID,$SelectedModel,$Label) = @_;
	$self->web()->CpdLinks($CpdID,$Label);
}
=head3 GetReactionSubstrateData
MOVED TO FIGMODELreaction:MARKED FOR DELETION
=cut
sub GetReactionSubstrateData {
	my ($self,$ReactionID) = @_;
	return $self->get_reaction($ReactionID)->substrates_from_equation();
}
=head3 GetReactionSubstrateDataFromEquation
MOVED TO FIGMODELreaction:MARKED FOR DELETION
=cut
sub GetReactionSubstrateDataFromEquation {
	my ($self,$Equation) = @_;
	return $self->get_reaction("rxn00001")->substrates_from_equation({equation=>$Equation});
}
=head3 LoadProblemReport
IMPLEMENTED IN FIGMODELweb:MARKED FOR DELETION
=cut
sub GeneLinks {
	my ($self,$GeneID,$SelectedModel) = @_;
	return $self->web()->gene_link($GeneID,$SelectedModel);
}
=head3 LoadProblemReport
IMPLEMENTED IN FIGMODELfba:MARKED FOR DELETION
=cut
sub LoadProblemReport {
	my ($self,$Filename) = @_;
	my $fba = $self->fba({filename=>$Filename});
	return $fba->loadProblemReport();
}
=head3 convert_to_search_name
IMPLEMENTED IN FIGMODELcompound:MARKED FOR DELETION
=cut
sub convert_to_search_name {
	my ($self,$InName) = @_;
	return $self->get_compound("cpd00001")->convert_to_search_name($InName);
}
=head2 Functions that should eventually be in FIGMODELcompound
=cut
sub UpdateCompoundNamesInDB {
	my ($self) = @_;
	my $objs = $self->database()->get_objects("compound");
	for (my $i=0; $i < @{$objs}; $i++) {
		#Getting aliases for compound
		my $als = $self->database()->get_objects("cpdals",{type => "name",COMPOUND => $objs->[$i]->id()});
		my $shortName = "";
		for (my $i=0; $i < @{$als}; $i++) {
			if (length($shortName) == 0 || length($shortName) > length($als->[$i]->alias())) {
				$shortName = $als->[$i]->alias();	
			}
		}
		if (length($shortName) > 0) {
			$objs->[$i]->name($shortName);
		}
	}
}
=head3 set_cache
REPLACED BY FIGMODEL->setCache(...):MARKED FOR DELETION
=cut
sub set_cache {
	my($self,$key,$data) = @_;
	$self->setCache({id=>$self->user(),key => $key,data => $data,package=>"FIGMODEL"});
	return undef;
}
=head3 cache
REPLACED BY FIGMODEL->getCache(...):MARKED FOR DELETION
=cut
sub cache {
	my($self,$key) = @_;
	return $self->getCache({key => $key,package=>"FIGMODEL",id=>$self->user()});
}
=head3 ConvertEquationToCode
IMPLEMENTED IN FIGMODELreaction:MARKED FOR DELETION
=cut
sub ConvertEquationToCode {
	my ($self,$OriginalEquation,$CompoundHashRef) = @_;
	my $rxnObj = $self->get_reaction("rxn00001");
	my $output = $rxnObj->createReactionCode({equation => $OriginalEquation,translations => $CompoundHashRef});
	return ($output->{direction},$output->{code},$output->{reverseCode},$output->{fullEquation},$output->{compartment},$output->{error});
}
1;

