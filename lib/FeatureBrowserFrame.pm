package FeatureBrowserFrame;

use SeedUtils;
use myRAST;
use Data::Dumper;
use File::HomeDir;
use File::Basename;
use File::Path;
use BrowserSap;
use ProteinPanel;

use Moose;
use MooseX::NonMoose;

use wxPerl::Constructors;
use Wx qw(:sizer :everything :bitmap :toolbar wxNullBitmap);
use Wx::Event qw(EVT_BUTTON EVT_RADIOBOX EVT_COMBOBOX EVT_TIMER EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED
		 EVT_SIZE EVT_TOOL EVT_TEXT EVT_TEXT_ENTER EVT_MENU);

extends 'Wx::Frame';

has 'menubar' => (is => 'rw',
		  isa => 'Wx::MenuBar');

has 'toolbar' => (is => 'rw', isa => 'Wx::ToolBar');

has 'browser' => (isa => 'Browser', is => 'ro', required => 1);

has 'panel' => (is => 'rw',
		isa => 'Object');

has 'peg_text' => (is => 'rw', isa => 'Wx::TextCtrl');
has 'forward_button' => (is => 'rw', isa => 'Int');
has 'back_button' => (is => 'rw', isa => 'Int');

sub FOREIGNBUILDARGS
{
    my($self, %args) = @_;

    my $title = $args{title};

    return (undef, -1, $title, wxDefaultPosition,
	    (exists($args{size}) ? $args{size} : Wx::Size->new(600,300)));
};

sub BUILD
{
    my($self) = @_;

    if ($self->menubar)
    {
	$self->SetMenuBar($self->menubar);
    }

    my $app = Wx::App::GetInstance();

    my $show_text = 0; # wxTB_TEXT
    my $toolbar = $self->CreateToolBar(wxNO_BORDER | wxTB_HORIZONTAL | $show_text);
    $self->toolbar($toolbar);

    #
    # Back button
    #

    my $lb = $app->get_icon("left_arrow");
    my $a = $toolbar->AddTool(-1, "Back", $lb, wxNullBitmap, 0, undef, 'Show the previous feature');
    $self->back_button($a->GetId);
    $toolbar->EnableTool($a->GetId, 0);

    EVT_TOOL($self, $a->GetId, sub { $self->browser->history_back() });

    #
    # Forward button
    #

    my $rb = $app->get_icon("right_arrow");
    $a = $toolbar->AddTool(-1, "Forward", $rb, wxNullBitmap, 0, undef, 'Show the next feature');
    $self->forward_button($a->GetId);
    $toolbar->EnableTool($a->GetId, 0);

    EVT_TOOL($self, $a->GetId, sub { $self->browser->history_forward() });

    #
    # Feature location text
    #

    my $txt = wxPerl::TextCtrl->new($toolbar, "",
				    style => wxTE_PROCESS_ENTER);
    $txt->SetSize(400, -1);
    $toolbar->AddControl($txt);
    $self->peg_text($txt);

    EVT_TEXT_ENTER($self, $txt, \&go_to_location);

    my $b = $self->browser;

    #
    # these don't work yet
    #
    my @rest = (["export", "Export", "Export this genome", $app->get_menu_id('export'), undef],
		["import", "Import", "Import a genome", $app->get_menu_id('import'), undef]);
    @rest = ();
    
    #
    # Don't put this stuff on the menubar.
    #
    if (0)
    {
	push(@rest, 
		["prev_contig", "Prev contig", "Move to previous contig", -1, sub { $b->set_peg($b->prev_contig()) }],
		["prev_page", "Prev page", "Move to previous page", -1, sub { $b->set_peg($b->prev_page()) }],
		["prev_halfpage", "Prev halfpage", "Move to previous halfpage", -1, sub { $b->set_peg($b->prev_halfpage()) }],
		["prev_peg", "Prev feature", "Move to previous feature", -1, sub { $b->set_peg($b->prev_peg()) }],
		["next_peg", "Next feature", "Move to next feature", -1, sub { $b->set_peg($b->next_peg()) }],
		["next_halfpage", "Next halfpage", "Move to next halfpage", -1, sub { $b->set_peg($b->next_halfpage()) }],
		["next_page", "Next page", "Move to next page", -1, sub { $b->set_peg($b->next_page()) }],
		["next_contig", "Next contig", "Move to next contig", -1, sub { $b->set_peg($b->next_contig()) }],
		);
    }

    for my $ent (@rest)
    {
	my($icon_name, $label, $help, $id, $sub) = @$ent;

	my $icon = $app->get_icon($icon_name);
	$a = $toolbar->AddTool($id, $label, $icon, wxNullBitmap, wxITEM_NORMAL, $help);
	EVT_TOOL($self, $a->GetId, $sub) if $sub;
    }

    $toolbar->Realize();
    my $panel = ProteinPanel->new(parent => $self, browser => $self->browser);

    $self->browser->add_observer(sub { $self->browser_change(@_); });

    my $id = $app->get_menu_id('export');
    print "Binding menu to $id app=$app\n";
    print Dumper($app->menu_id_hash);
    EVT_MENU($self, $id, sub { $panel->perform_export(); });
}

sub go_to_location
{
    my($self, $evt) = @_;
    my $loc = $self->peg_text->GetValue();
    my $ok = $self->browser->find_location($loc);
    if (!$ok)
    {
	Wx::MessageBox("Could not find $loc",
		       "Not found");
    }
}

sub browser_change
{
    my($self, $browser, $peg, $have_back, $have_fwd) = @_;
    $self->toolbar->EnableTool($self->back_button, $have_back);
    $self->toolbar->EnableTool($self->forward_button, $have_fwd);
#    print "Change: browser=$browser peg=$peg\n";
    $self->peg_text->SetValue($peg);
}

1;
