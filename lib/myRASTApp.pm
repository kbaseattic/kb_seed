package myRASTApp;

use Data::Dumper;
use Moose;
use MooseX::NonMoose;
use GenomeInfoPanel;
use RegionPanel;
use File::Temp 'tempfile';
use SeedAware;
use LWP::UserAgent;
use LogWindow;
use Archive::Extract;
use GenomeLoader;
use Try::Tiny;
use POSIX;

use myRAST;

use wxPerl::Constructors;

use Wx qw(:everything);
use Wx::RichText qw(:richtextctrl);
use Wx::Event qw(EVT_BUTTON EVT_RADIOBOX EVT_COMBOBOX EVT_TIMER EVT_SIZE EVT_CLOSE EVT_MENU);

use GenomeBrowserFrame;
use GenomeSetDB;

extends 'Wx::App';

use JobBrowserFrame;
use SampleJobBrowserFrame;

has 'icon_cache' => (isa => 'HashRef[Wx::Bitmap]', is => 'ro',
		     default => sub { {} });

our %icon_map = (left_arrow => 'arrow_left_32.png',
		 right_arrow => 'arrow_right_32.png',
		 export => 'document-export.png',
		 import => 'document-import.png',
		 prev_contig => 'go-first-view.png',
		 prev_page => 'go-first.png',
		 prev_halfpage => 'go-previous.png',
		 prev_peg => 'go-previous-view.png',
		 next_contig => 'go-last-view.png',
		 next_page => 'go-last.png',
		 next_halfpage => 'go-next.png',
		 next_peg => 'go-next-view.png',
		 zoom_in => "zoom-in.png",
		 zoom_original => "zoom-original.png",
		 zoom_out => "zoom-out.png",
		 );

our @menu_names = qw(export open_genome open_sample import
		     genbank_compute_comparison genbank_show_comparison
		     );

has 'menu_id_hash' => (isa => 'HashRef[Num]',
		       lazy => 1,
		       is => 'ro',
		       default => sub { print "Creating default menu_id_hash\n"; print Dumper(\@_); return {} },
		       traits => ['Hash'],
		       handles => {
			   get_menu_id => 'get',
			   set_menu_id => 'set',
		       });

my $version;
eval
{
    require myRASTVersion;
    $version = myRASTVersion->new;
};

sub BUILD
{
    my($self) = @_;
    print "BUILD app $self\n";
}

sub OnInit
{
    my($self) = @_;
    print "Init app self=$self\n";

    Wx::InitAllImageHandlers();

    #
    # Initialize menu ids we need.
    #
    for my $name (@menu_names)
    {
	$self->set_menu_id($name, Wx::NewId());
    }
    print Dumper($self->menu_id_hash);

    $self->show_browser();

    return 1;
}

sub get_icon
{
    my($self, $name) = @_;

    my $file = $icon_map{$name};

    if (defined($file))
    {
	return $self->get_icon_by_file($file);
    }

    return wxNullBitmap;
}

sub get_icon_by_file
{
    my($self, $file_base) = @_;

    my $bm = $self->icon_cache->{$file_base};
    return $bm if defined($bm);

    my @search_path = (".",
#		       "/Users/olson/Downloads/oxygen-icons-4.6.0/64x64/actions",
		       "/Users/olson/Downloads/oxygen-icons-4.6.0/32x32/actions");
    push(@search_path, "$ENV{SAS_HOME}/lib") if exists $ENV{SAS_HOME};

    for my $path (@search_path)
    {
	my $file = "$path/$file_base";
	if (-f $file)
	{
	    $bm = Wx::Bitmap->new($file, wxBITMAP_TYPE_ANY);
	    if ($bm)
	    {
		print "Found icon at $file\n";
		$self->icon_cache->{$file_base} = $bm;
		return $bm;
	    }
	}
    }
    print "No icon found for $file_base in @search_path\n";
    return wxNullBitmap;
}

sub default_menubar
{
    my($self) = @_;

    my $bar = Wx::MenuBar->new();
    my $file = Wx::Menu->new();

    my $i_open_g = $file->Append($self->get_menu_id('open_genome'),, "&Open genome\tCtrl+O");
    my $i_open_s = $file->Append($self->get_menu_id('open_sample'), "Open s&ample\tShift+Ctrl+O");
#    my $i_all_to_all = $file->Append(-1, "Export all-to-all analysis");
#    my $i_tree_all_to_all = $file->Append(-1, "Compute tree for all-to-all analysis");

    my $exp = $file->Append($self->get_menu_id('export'), "Export data");
    $file->Append($self->get_menu_id('genbank_compute_comparison'), "Compute genbank comparison");
    $file->Append($self->get_menu_id('genbank_show_comparison'), "Show genbank comparison");
    

    EVT_MENU($self, $i_open_g, \&open_genome);
    EVT_MENU($self, $i_open_s, \&open_sample);
#    EVT_MENU($self, $i_all_to_all, \&export_all_to_all);
#    EVT_MENU($self, $i_tree_all_to_all, \&all_to_all_to_tree);

    my $help = Wx::Menu->new();
    my $i_about = $help->Append(wxID_ABOUT, "About myRAST");
    EVT_MENU($self, $i_about, \&OnAbout);
    
#    my $i_docs = $help->Append(-1, "Docs");

    $bar->Append($file,"File");
    $bar->Append($help, "&Help");

    return $bar;
}

sub export_all_to_all
{
    my($self, $samples_to_compare) = @_;

    my $dlg = Wx::FileDialog->new(undef, "Export all-to-all analysis to file", "",
				  "", "*.*", wxFD_SAVE);
    my $rc = $dlg->ShowModal();

    if ($rc != wxID_OK)
    {
	return;
    }
    my $file = $dlg->GetPath();

    my $fh;
    if (!open($fh, ">", $file))
    {
	my $dlg = Wx::MessageDialog->new(undef, "Cannot open file $file: $!",
					 "Error opening file",
					 wxOK);
	$dlg->Show();
	return;
    }

    my $busy = Wx::BusyCursor->new();

    my($samples, $scores, $prog_dlg, $max) = $self->interactive_compute_all_to_all($samples_to_compare);

    if ($prog_dlg)
    {
	$prog_dlg->Destroy();
    }

    #
    # Was it canceled?
    #
    if (!$samples)
    {
	return;
    }

    $self->write_all2all_to_file($fh, $samples, $scores);
    close($fh);
}

sub write_all2all_to_file
{
    my($self, $fh, $samples, $scores) = @_;
    my $close = 0;
    if (!ref($fh))
    {
	$fh = open($fh, ">", $fh);
	if (!$fh)
	{
	    return undef;
	}
	$close = 1;
    }
    my $n = @$samples;
    
    for my $i (0..$n-1)
    {
	my $s = $samples->[$i];
	print $fh join("\t", $i, @$s{qw(name kmer max_gap min_hits dataset dataset_index)}), "\n";
    }
    print $fh "//\n";
    for my $i (0..$n-1)
    {
	my $rref = $scores->[$i];
	
	my @row = ref($rref) ? @{$scores->[$i]} : ();
	$#row = $n-1;
	print $fh join("\t", @row), "\n";

    }

    close($fh) if $close;
}

sub all_to_all_to_tree
{
    my($self, $samples_to_compare) = @_;

#    print "tree: ",Dumper($samples_to_compare);
    my $busy = Wx::BusyCursor->new();

    my $file = SeedAware::location_of_tmp() . "/tree.$$";

    my $fh;
    if (!open($fh, ">", $file))
    {
	my $dlg = Wx::MessageDialog->new(undef, "Cannot open temp file $file: $!",
					 "Error opening file",
					 wxOK);
	$dlg->ShowModal();
	return;
    }

    binmode($fh);

    my($samples, $scores, $prog_dlg, $max) = $self->interactive_compute_all_to_all($samples_to_compare);

    #
    # Was it canceled?
    #
    if (!$samples)
    {
	$prog_dlg->Destroy();
	return;
    }

    $prog_dlg->Update($max - 1, "Computing tree...");
    Wx::App::GetInstance()->Yield();

    $self->write_all2all_to_file($fh, $samples, $scores);
    close($fh);

    print "posting\n";
    my $ua = LWP::UserAgent->new();
    my $res = $ua->post("http://bioseed.mcs.anl.gov/~redwards/FIG/neighbor_tree.cgi",
			Content_Type => ['form-data'],
			Content => [request => 1,
				    uploadedfile => [$file],
				    ]);
    print "done\n";
    undef $busy;
    $prog_dlg->Destroy();
    if ($res->is_success)
    {
	$self->process_and_display_tree($res->content);
    }
    else
    {
	my $dlg = Wx::MessageDialog->new(undef,
					 "We encountered an error computing the tree:\n" . $res->content,
					 "Error computing tree",
					 wxOK);
	$dlg->ShowModal();
	return;
    }
}

sub process_and_display_tree
{
    my($self, $txt) = @_;
    
    my($tree) = $txt =~ m,<pre>(.*?)</pre>,s;
    
    my $dlg = wxPerl::Dialog->new(undef, "All to all tree",
				  size => Wx::Size->new(900, 600),
				  style => wxRESIZE_BORDER | wxDEFAULT_DIALOG_STYLE);

    my $sz = Wx::BoxSizer->new(wxVERTICAL);
    $dlg->SetSizer($sz);
    
    my $txtctrl = Wx::RichTextCtrl->new($dlg, -1, "", [-1, -1], [-1, -1], wxRE_READONLY);

    $sz->Add($txtctrl, 1, wxEXPAND | wxALL, 5);
    my $a = $txtctrl->GetDefaultStyle();

    my $font = Wx::Font->new(10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL);
    $txtctrl->SetFont($font);
    print "font is " . $font->GetFaceName() . "\n";
    #$a->SetFont($font);
    #$txtctrl->SetDefaultStyle($a);
    #print "using ", $txtctrl->GetDefaultStyle()->GetFont()->GetFaceName(), "\n";
    
    $txtctrl->AppendText($tree);

    $sz->Add($dlg->CreateStdDialogButtonSizer(wxOK), 0, wxALL, 5);

    $dlg->Show(1);
}


sub interactive_compute_all_to_all
{
    my($self, $samples_to_compare) = @_;

    my $prog_dlg;
    my $max;
    my $count_cb = sub {
	my($c) = @_;
	$max = $c + 2;
	$prog_dlg = Wx::ProgressDialog->new("All to all progress",
					    "Computing distances...",
					    $max, undef,
					    wxPD_APP_MODAL | wxPD_CAN_ABORT);
	$prog_dlg->Show(1);
    };
    my $update_cb = sub {
	my($i) = @_;
	my $exit = $prog_dlg->Update($i);
	Wx::App::GetInstance()->Yield();
	return $exit;
    };
    
    my($samples,$scores) = myRAST->instance->compute_all_to_all_distances($samples_to_compare, $count_cb, $update_cb);

    return($samples, $scores, $prog_dlg, $max);
}

sub show_browser
{
    my($self) = @_;

    my $gset = myRAST->instance->genome_set_db;
    my $jb = GenomeBrowserFrame->new(title=> "myRAST Genome Browser",
				     menubar => $self->default_menubar(),
				     genome_set_db => $gset);

    $jb->Show();
}

sub open_genome
{
    my($self) = @_;

    my $jb = JobBrowserFrame->new(title=> "myRAST Job Browser",
				  menubar => $self->default_menubar());

    $jb->Show();
}

sub open_sample
{
    my($self) = @_;

    my $jb = SampleJobBrowserFrame->new(title=> "myRAST Job Browser",
					menubar => $self->default_menubar());

    $jb->Show();
}

sub OnAbout
{
    my($self) = @_;

    my $ver_str;
    if (defined($version))
    {
	$ver_str = "Version " . $version->release;
	if (my $d = $version->{package_date_str})
	{
	    $ver_str .= "\nPackaged on $d";
	}
    }
    else
    {
	$ver_str = "Development build";
    }
    my $dlg = Wx::MessageDialog->new(undef, "myRAST\n$ver_str", "About myRAST");
    $dlg->ShowModal();
}

=head3 load_pangenome_bundle(bundle-file)

Load a pangenome data bundle.

This is a zip file that has one toplevel directory per data set. That directory
will contain a subdirectory PG that holds the pangenome.

The bundle loader will force-load the genomes that appear in each of the PEG directories,
then load the pangenome itself.

=cut

sub load_pangenome_bundle
{
    my($self, $bundle) = @_;

    my $now = strftime("%Y-%m-%d-%H-%M-%S", localtime time);

    my $dir = myRAST->instance->doc_dir . "/extracted_bundles";

    -d $dir || mkdir($dir);

    my $bdir = "$dir/$now";
    
    -d $bdir || mkdir($bdir);

    my $lw = LogWindow->new(title => "Install pangenome from $bundle");
    $lw->close_button->Enable(0);
    $lw->cancel_button->Enable(1);
    $self->Yield();

    my $loader = GenomeLoader->new();
    my $update_cb = sub { $self->cancel_check($lw);
			  my $txt = join(" ", @_);
			  print $txt;
			  $lw->add_text($txt);
		      };
    try {
    
	$lw->add_text("Installing pangenome from $bundle\n");
	$lw->add_text("Extracting data into $bdir...");
	
	$self->cancel_check($lw);
	my $ae = Archive::Extract->new(archive => $bundle);
	my $ok = $ae->extract(to => $bdir);
	
	if (!$ok)
	{
	    Wx::MessageBox("Could not open bundle file $bundle",
			   "Error opening pangenome bundle.");
	    return;
	}
	
	$self->cancel_check($lw);
	$lw->add_text(" done\n");
	$self->cancel_check($lw);
	
	my $files = $ae->files;
	my @toplevel = grep { tr /\/// == 1  && /\/$/ } @$files;
	
	for my $top (@toplevel)
	{
	    $top =~ s,/$,,;

	    my $pg_dir = "$bdir/$top/PG";
	    if (-d $pg_dir)
	    {
		$lw->add_text("Processing pangenome $top\n");
		$self->cancel_check($lw);

		$loader->load_pangenome($pg_dir, 1, $update_cb);
	    }
	    else
	    {
		$lw->add_text("Pangenome directory $pg_dir does not exist\n");
	    }
	       
	}
    } catch {
	if ($_ =~ /Canceled/)
	{
	    print "Canceled";
	}
	else
	{
	    $lw->add_text("Error caught: $_");
	}
    }

    $lw->close_button->Enable(1);
    $lw->cancel_button->Enable(0);
    
}

sub cancel_check
{
    my($self, $obj) = @_;
    $self->Yield();
    if ($obj->is_canceled)
    {
	die "Canceled";
    }
}

1;
