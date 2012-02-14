package GenomeBrowserFrame;

#
# Browse the genome sets that are installed on this system.
#
# Via the "All Genomes" set one can browse every genome.
#


use SeedUtils;
use myRAST;
use Data::Dumper;
use File::HomeDir;
use File::Basename;
use File::Path;
use FeatureBrowserFrame;
use BrowserSap;
use ProteinPanel;
use DesktopRast;
use DesktopRastFrame;
use GenomeInfoPanel;
use GenomeSetDB;


use Moose;
use MooseX::NonMoose;

use wxPerl::Constructors;
use Wx qw(:sizer :everything);
use Wx::Event qw(EVT_BUTTON EVT_RADIOBOX EVT_COMBOBOX EVT_TIMER
		 EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED
		 EVT_TREE_SEL_CHANGED EVT_TREE_ITEM_ACTIVATED
		 EVT_SIZE);

extends 'Wx::Frame';

has 'genome_set_db' => (isa => 'GenomeSetDB', is => 'ro', required => 1);

has 'menubar' => (is => 'rw',
		  isa => 'Wx::MenuBar');

has 'panel' => (is => 'rw',
		isa => 'Object');

has 'set_list' => (isa => 'Wx::ListCtrl',
		   is  => 'rw');
has 'set_data' => (isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] });

has 'set_tree' => (isa => 'Wx::TreeCtrl',
		   is  => 'rw');

has 'genome_list' => (isa => 'Wx::ListCtrl',
		      is  => 'rw');
has 'genome_data' => (isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] });

has 'genome_info' => (isa => 'GenomeInfoPanel', is => 'rw');

has 'selected_set' => (isa => 'Maybe[GenomeSet]', is => 'rw');
has 'selected_genome' => (isa => 'Maybe[SapGenome]', is => 'rw',
			  trigger => \&_trigger_selected_genome);

has 'open_genome_button' => (isa => 'Wx::Button', is => 'rw');
has 'delete_genome_button' => (isa => 'Wx::Button', is => 'rw');
has 'delete_pangenome_button' => (isa => 'Wx::Button', is => 'rw');

sub FOREIGNBUILDARGS
{
    my($self, %args) = @_;

    my $title = $args{title};

    return (undef, -1, $title, wxDefaultPosition,
	    (exists($args{size}) ? $args{size} : Wx::Size->new(800,300)));
}

sub BUILDxx
{
    my($self) = @_;

    if ($self->menubar)
    {
	$self->SetMenuBar($self->menubar);
    }

    my $panel = wxPerl::Panel->new($self);
    $self->panel($panel);

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    $panel->SetSizer($top_sz);
    # $top_sz->SetSizeHints($self);

    #
    # Lists and detail panel fit in a horizontal sizer.
    #

    my $split1 = Wx::SplitterWindow->new($panel);

    $top_sz->Add($split1, 1, wxEXPAND | wxALL, 5);

    my $set_list = wxPerl::ListCtrl->new($split1,
					 style => wxLC_REPORT | wxLC_SINGLE_SEL);
    $self->set_list($set_list);
    $self->init_set_list($set_list);

    my $split2 = Wx::SplitterWindow->new($split1);

    my $genome_list = wxPerl::ListCtrl->new($split2,
					    style => wxLC_REPORT | wxLC_SINGLE_SEL);
    $self->genome_list($genome_list);
    $self->init_genome_list($genome_list);
    EVT_LIST_ITEM_ACTIVATED($self, $genome_list, sub { $self->open_genome(); });

    my $info = GenomeInfoPanel->new(parent => $split2);
    $self->genome_info($info);

    $split1->SplitVertically($set_list, $split2);
    $split2->SplitVertically($genome_list, $info);

    #
    # Buttons
    #

    my $bsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $top_sz->Add($bsizer, 0, wxEXPAND | wxALL, 5);

    my $b = wxPerl::Button->new($panel, "Process new genome");
    # does not yet work in myRAST2
    $b->Enable(0);
    $bsizer->Add($b, 0, wxALIGN_LEFT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->process_new_genome(); });

    $b = wxPerl::Button->new($panel, "Open genome");
    $b->Enable(0);
    $self->open_genome_button($b);
    $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->open_genome(); });

    $b = wxPerl::Button->new($panel, "Delete genome");
    $b->Enable(0);
    $self->delete_genome_button($b);
    $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->delete_genome(); });


    #$b = wxPerl::Button->new($panel, "Cancel");
    #$bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    #EVT_BUTTON($self, $b, sub { $self->cancel(); });

    $self->load_sets();

}

sub BUILD
{
    my($self) = @_;

    if ($self->menubar)
    {
	$self->SetMenuBar($self->menubar);
    }

    my $panel = wxPerl::Panel->new($self);
    $self->panel($panel);

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    $panel->SetSizer($top_sz);

    my $split1 = Wx::SplitterWindow->new($panel);

    $top_sz->Add($split1, 1, wxEXPAND | wxALL, 5);

    #
    # TODO: on windows, if we use wxTR_HIDE_ROOT, we don't get
    # +/- buttons on the top level items so they can't be
    # expanded/collapsed.
    #
    my $data_tree = wxPerl::TreeCtrl->new($split1,
					  style => wxTR_HAS_BUTTONS | wxSUNKEN_BORDER);

    EVT_TREE_SEL_CHANGED($self, $data_tree, sub {
	my($me, $evt) = @_;
	$self->tree_selection_changed($data_tree, $evt);
    });
    
    EVT_TREE_ITEM_ACTIVATED($self, $data_tree, sub {
	my($me, $evt) = @_;
	$self->tree_item_activated($data_tree, $evt);
    });
    
    $self->set_tree($data_tree);

    $self->init_tree($data_tree);

    my $info = GenomeInfoPanel->new(parent => $split1);
    $self->genome_info($info);

    $split1->SplitVertically($data_tree, $info, -200);

    #
    # Buttons
    #

    my $bsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $top_sz->Add($bsizer, 0, wxEXPAND | wxALL, 5);

    my $b = wxPerl::Button->new($panel, "Process new genome");
    $b->Enable(0);
    $bsizer->Add($b, 0, wxALIGN_LEFT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->process_new_genome(); });

    $b = wxPerl::Button->new($panel, "Open genome");
    $b->Enable(0);
    $self->open_genome_button($b);
    $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->open_genome(); });

    $b = wxPerl::Button->new($panel, "Load Pangenome Data Bundle");
    $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->load_pangenome_data_bundle(); });
    
    $b = wxPerl::Button->new($panel, "Delete Pangenome");
    $b->Enable(0);
    $self->delete_pangenome_button($b);
    $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->delete_pangenome(); });
    
#     $b = wxPerl::Button->new($panel, "Delete genome");
#     $b->Enable(0);
#     $self->delete_genome_button($b);
#     $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
#     EVT_BUTTON($self, $b, sub { $self->delete_genome(); });

#     $b = wxPerl::Button->new($panel, "Cancel");
#     $bsizer->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
#     EVT_BUTTON($self, $b, sub { $self->cancel(); });
}

sub reload_tree
{
    my($self) = @_;

    my $data_tree = $self->set_tree;

    $data_tree->DeleteAllItems();
    $self->init_tree($data_tree);

    $self->selected_genome(undef);
    $self->selected_set(undef);
}

sub init_tree
{
    my($self, $tree) = @_;

    my $root = $tree->AddRoot("All sets", -1, -1, Wx::TreeItemData->new("all_sets"));
    
    my $all_genomes = $tree->AppendItem($root, "All genomes", -1, -1, Wx::TreeItemData->new("all_genomes"));
    my $pangenomes = $tree->AppendItem($root, "Pangenome sets", -1, -1, Wx::TreeItemData->new("pangenome_sets"));

    $self->load_all_genomes_into_tree($tree, $all_genomes);
    $self->load_pangenome_sets_into_tree($tree, $pangenomes);

    $tree->Expand($root);
    $tree->Expand($pangenomes);
}

sub load_all_genomes_into_tree
{
    my($self, $tree, $item) = @_;
    my $sap = myRAST->instance->sap;

    my $glist = $sap->all_genomes();

    my $row = 0;
    for my $g (sort keys %$glist)
    {
	my $name = $glist->{$g};
	my $txt = $name ? "$name ($g)" : $g;

	my $gobj = SapGenomeFactory->instance->get_genome($g);

	$tree->AppendItem($item, $txt, -1, -1,
			  Wx::TreeItemData->new($gobj));
    }
    
}

sub load_pangenome_sets_into_tree
{
    my($self, $tree, $item) = @_;

    for my $ent ($self->genome_set_db->enumerate)
    {
	my $ename = $ent->name;
	$ename =~ s/^pangenome from\s+//;
	my $sitem = $tree->AppendItem($item, $ename, -1, -1,
				      Wx::TreeItemData->new($ent));

	my $glist = $ent->genomes;
	if (ref($glist))
	{
	    for my $g (@$glist)
	    {
		my $name = $g->name;
		my $id = $g->id;
		my $txt = $name ? "$name ($id)" : $id;
		$tree->AppendItem($sitem, $txt, -1, -1,
				  Wx::TreeItemData->new($g));
	    }
	}
    }
}
	
sub tree_selection_changed {
    my( $self, $tree, $event ) = @_;
    
    my $item = $event->GetItem;
    my $data = $tree->GetItemData( $item );
    if ($data)
    {
	$data = $data->GetData();
    }

    if ($data->isa('SapGenome'))
    {
	$self->selected_genome($data);
	my $par = $tree->GetItemParent($item);
	my $par_data = $tree->GetItemData($par);
	$par_data = $par_data->GetData if $par_data;

	$self->delete_pangenome_button->Enable(0);

	if ($par_data eq 'all_genomes')
	{
	    $self->selected_set(undef);
	}
	elsif ($par_data->isa('GenomeSet'))
	{
	    $self->selected_set($par_data);
	}
    }
    elsif ($data->isa('GenomeSet'))
    {
	$self->selected_set($data);
	$self->delete_pangenome_button->Enable(1);

	my $refs = $data->reference_genomes;
	print "refs=@$refs\n";
	$self->selected_genome($refs->[0]);
    }
    else
    {
	$self->selected_genome(undef);
	$self->selected_set(undef);
	$self->delete_pangenome_button->Enable(0);
    }
}
    
sub tree_item_activated {
    my( $self, $tree, $event ) = @_;
    
    my $item = $event->GetItem;
    my $data = $tree->GetItemData( $item );
    if ($data)
    {
	$data = $data->GetData();
    }

    if ($data->isa('SapGenome'))
    {
	$self->selected_genome($data);
	$self->open_genome();
    }
    elsif ($data->isa('GenomeSet'))
    {
	$self->open_pangenome();
    }
    else
    {
	print "Data isn't " . ref($data) . Dumper($data);
    }
}
    
sub delete_pangenome
{
    my($self) = @_;
    my $set = $self->selected_set;
    return unless $set;

    $self->genome_set_db->delete_set($set->id);
    $self->reload_tree();
    
}

sub open_pangenome
{
    my($self) = @_;

    my $set = $self->selected_set;
    return unless $set;
	
    my @genomes = $self->genomes;
    return unless @genomes;
    $self->selected_genome($genomes[0]);
    $self->open_genome();
}

sub open_genome
{
    my($self) = @_;

    my $g = $self->selected_genome;
    if (!$g)
    {
	warn "No genome selected\n";
	return;
    }

    if (!$g->exists)
    {
	my $name = $g->name_text;
	Wx::MessageBox("Cannot open genome $name: genome is not loaded",
		       "Cannot open genome");
	return;
    }

    my $sap = myRAST->instance->sap;
    my $lc = myRAST->instance->local_correspondences;
    
    my $browser = Browser->new(sap => $sap,
			       local_correspondences => $lc,
			       genome_set => $self->selected_set);

    my $peg = "fig|" . $g->id . ".peg.1";

    my $frame = FeatureBrowserFrame->new(size => Wx::Size->new(800,500),
					 browser => $browser);

    #my $frame = wxPerl::Frame->new(undef, "Genome Browser -- " . $g->name,
#				  size => Wx::Size->new(800,500));
#    my $panel = ProteinPanel->new(parent => $frame, browser => $browser);
    
    $frame->Show();

    $browser->set_peg($peg);
}

sub init_set_list
{
    my($self, $list) = @_;
    EVT_LIST_ITEM_SELECTED($self, $list, \&set_selected );
    EVT_SIZE($list, \&set_list_size);

    $list->InsertColumn(0, "Genome set");
}

sub init_genome_list
{
    my($self, $list) = @_;
    EVT_LIST_ITEM_SELECTED($self, $list, \&genome_selected);
    EVT_SIZE($list, \&set_list_size);

    $list->InsertColumn(0, "Genome");
}

sub set_list_size
{
    my($list, $evt) = @_;
    my $s = $evt->GetSize;
    my $w = $s->width;
    my $h = $s->height;
    $list->SetColumnWidth(0, $w-3);
}

sub load_sets
{
    my($self) = @_;

    my $list = $self->set_list();

    $list->DeleteAllItems();
    my $data = $self->set_data;
    @$data = ();

    my @sets = (['All Genomes', undef]);

    for my $ent ($self->genome_set_db->enumerate)
    {
	push(@sets, [$ent->name, $ent]);
    }

    my $row = 0;
    for my $ent (@sets)
    {
	my $item = Wx::ListItem->new();
	$item->SetText($ent->[0]);
	$item->SetData($row);
	$item->SetId($row);
	$list->InsertItem($item);
	$data->[$row] = $ent;
	$row++;
    }

    $list->SetColumnWidth(0, wxLIST_AUTOSIZE_USEHEADER);

}

sub set_selected
{
    my($self, $evt) = @_;
    my $item = $evt->GetText;
    my $set = $self->set_data->[$evt->GetData];
#    print "Selected $item $set\n";

    if ($item eq 'All Genomes')
    {
	$self->load_all_genomes();
	$self->selected_set(undef);
    }
    else
    {
	$self->load_set($set->[1]);
	$self->selected_set($set->[1]);
    }
    $self->selected_genome(undef);
}

sub load_all_genomes
{
    my($self) = @_;
    my $sap = myRAST->instance->sap;

    my $glist = $sap->all_genomes();

    my $list = $self->genome_list();
    $list->DeleteAllItems();
    my $data = $self->genome_data;
    @$data = ();
    
    my $row = 0;
    for my $g (sort keys %$glist)
    {
	my $name = $glist->{$g};
	my $txt = $name ? "$name ($g)" : $g;

	$data->[$row] = SapGenomeFactory->instance->get_genome($g);

	my $item = Wx::ListItem->new();
	$item->SetId($row);
	$item->SetText($txt);
	$item->SetData($row);
	$list->InsertItem($item);

	$row++;
    }
    
}

sub load_set
{
    my($self, $set) = @_;
    my $sap = myRAST->instance->sap();

    my $glist = $set->genomes;

    my $list = $self->genome_list();
    $list->DeleteAllItems();
    my $data = $self->genome_data;
    @$data = ();
    
    my $row = 0;
    for my $gobj (@$glist)
    {
	my $g = $gobj->id;
#	print "gobj=$gobj g=$g\n";
	my $name = $gobj->name;
	my $txt = $name ? "$name ($g)" : $g;

	$data->[$row] = $gobj;

	my $item = Wx::ListItem->new();
	$item->SetId($row);
	$item->SetText($txt);
	$item->SetData($row);
	$list->InsertItem($item);

	$row++;
    }
    
}

sub genome_selected
{
    my($self, $evt) = @_;
    my $item = $evt->GetText;

    my $genome = $self->genome_data->[$evt->GetData];
#    print "Selected $item => $genome\n";
    $self->selected_genome($genome);
}

sub _trigger_selected_genome
{
    my($self, $genome) = @_;
    $self->genome_info->genome($genome);
    $self->open_genome_button->Enable(defined($genome));
    # $self->delete_genome_button->Enable(defined($genome));
}

sub load_pangenome_data_bundle
{
    my($self) = @_;
    my $dlg = Wx::FileDialog->new($self, "Open Pangenome Data Bundle",
				  File::HomeDir->my_home,
				  "ZIP files (*.zip)|*.zip|Compress Tarfiles (*.tgz)|*.tgz");
    if ($dlg->ShowModal == wxID_OK)
    {
	my $file = $dlg->GetPath();
	print "load $file\n";
	$dlg->Destroy();
	my $app = Wx::App::GetInstance();
	$app->load_pangenome_bundle($file);
	$self->reload_tree();
    }
}

1;
