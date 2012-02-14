use strict;
use warnings;
no warnings 'once';
use CGI;
use ModelSEED::FIGMODEL;
use Archive::Tar;
use File::Path qw(rmtree);
use File::Temp qw(tempdir tempfile);


my $figmodel = ModelSEED::FIGMODEL->new();

sub make_xls {
    my ($name, $headings, $sheets) = @_;
    my ($fh, $workbook) = tempfile($name . "-xls-XXXXXX", 'DIR' => '/vol/model-dev/MODEL_DEV_DB/tmp/');
    close($fh);
    my $workbookFilename = $workbook;
    for(my $i=0; $i<@$sheets; $i++) {
        $workbook = $sheets->[$i]->add_as_sheet($headings->[$i], $workbook);
    }
    $workbook->close();
    my $data = do {
        local $/ = undef;   
        open(my $fh, "<:raw", $workbookFilename);
        <$fh>;
    };
    close($fh);
    unlink($workbookFilename);
    return ($data, "$name.xls");
}
    

sub getModelData {
    my ($type, $modelId) = @_;
    my $model = $figmodel->get_model($modelId);
    unless(defined($model)) {
        return ("User does not have access to the model.\n", $modelId . '.' . typeToSuffix(''));
    }
    if($type eq 'XLS') {
        my $tables = [$model->publicTable({type => "R"}),
                      $model->publicTable({type => "C"}),
                      $model->publicTable({type => "F"})
                    ];
        my $tableNames = ['Reactions', 'Compounds', 'Features'];
        return make_xls($modelId, $tableNames, $tables);
    } elsif ($type eq 'SBML') {
    	my $data = $model->PrintSBMLFile({print=>0});
    	return (join("\n",@{$data}),$model->id().".xml");
    } else {
        my $retString = "";
        my $filename = $model->id() . "." . typeToSuffix($type);
        if (-e $model->directory().$filename) {
            my $data = $figmodel->database()->load_single_column_file($model->directory().$filename);
            $retString = join("\n",@{$data});
        } else {
            $retString = $filename . " not found for " . $modelId . "\n";
        }
        return ($retString, $filename);
    }
}

sub getMIME {
    my ($type, $filename) = @_;
    my $ret = "";
    my $downloadable = "Content-Disposition: attachment; filename=$filename;\n";
    if($type eq "LP") {
        $ret = "Content-Type: text/plain\n" . $downloadable;
    } elsif($type eq "DB") {
        $ret = "Content-Type: text/plain\n" . $downloadable;
    } elsif($type eq "SBML") {
        $ret = "Content-Type: application/sbml+xml\n" . $downloadable;
    } elsif($type eq "TAR") {
        $ret = "Content-Type: application/x-tar\n" . $downloadable;
    } elsif($type eq "XLS") {
        $ret = "Content-Type: application/vnd.ms-excel\n" . $downloadable;
    } else {
        $ret = "Content-Type: text/plain\n";
    }
    return $ret . "\n";
}

sub typeToSuffix {
    my ($type) = @_;
    if($type eq 'LP') {
        return 'lp';
    } elsif ($type eq 'DB') {
        return 'tbl';
    } elsif ($type eq 'SBML') {
        return 'xml';
    } elsif ($type eq 'XLS') {
        return 'xls';
    } else {
        return 'txt';
    }
}

sub printTarball {
    my ($type, $listOfModelIds) = @_;
    my $dir = tempdir('model-download-XXXXXX');
    my @filenames;
    foreach my $modelId (@$listOfModelIds) {
        my ($data, $filename) = getModelData($type, $modelId);
        push(@filenames, $filename);
        open(my $fh, ">", $dir . "/" . $filenames[scalar(@filenames)-1]);
        print $fh $data;
        close($fh);
    }
    @filenames = map { $_ = $dir ."/". $_} @filenames;
    my ($fh, $tmpName) = tempfile('XXXXXX');
    close($fh);
    Archive::Tar->create_archive( $tmpName, $Archive::Tar::COMPRESS_GZIP, @filenames);
    File::Path::rmtree($dir);
    open($fh, "<", $tmpName);
    binmode $fh;
    my $string = "";
    while(<$fh>) {
        $string .= $_;
    }
    close($fh);
    unlink($tmpName);
    return getMIME('TAR', $tmpName . ".tar.gz") . $string;
}

# initialize cgi
my $cgi = new CGI();
my $username = "NONE";
my $password = "NONE";
$figmodel->authenticate({cgi => $cgi});
if(defined($cgi->param('biochemistry'))) {
    my $names = ['Reactions'];
    my $sheets = [$figmodel->public_reaction_table()];
    my ($data, $filename) = make_xls("ModelSEED-reactions-db", $names, $sheets);
    print getMIME('XLS', $filename) . $data;
    
} elsif(defined($cgi->param('biochemCompounds'))) {
    my $names = ['Compounds'];
    my $sheets = [$figmodel->public_compound_table()];
    my ($data, $filename) = make_xls("ModelSEED-compounds-db", $names, $sheets);
    print getMIME('XLS', $filename) . $data;
    
}
my $modelid = $cgi->param('model');
my $type = $cgi->param('file');
if(!defined($type)) {
    print CGI::header();
    print CGI::start_html();
    print '<pre>No file type selected for download</pre>';
    print CGI::end_html();
    return;
}
my @models = split(/,/, $modelid);
if (!defined($modelid)) {
    print CGI::header();
    print CGI::start_html();
    print '<pre>No model selected for download</pre>';
    print CGI::end_html();
	return;
} elsif (@models > 1) {
    print printTarball($type, \@models);
} else {
    my ($data, $filename) = getModelData($type, $modelid);
    print getMIME($type, $filename) . $data; 
}
