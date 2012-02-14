package LogWindow;

use SeedUtils;
use Data::Dumper;

use Moose;
use MooseX::NonMoose;

use List::Util qw(first);
    
use wxPerl::Constructors;
use Wx qw(:sizer :everything);
use Wx::Event qw(EVT_BUTTON EVT_RADIOBOX EVT_COMBOBOX EVT_TIMER EVT_SIZE EVT_CLOSE EVT_TEXT);

extends 'Wx::Frame';

has 'panel' => (isa => 'Wx::Panel', is => 'rw');
has 'text' => (isa => 'Wx::TextCtrl', is => 'rw');
has 'closed' => (isa => 'Bool', is => 'rw', default => 0);

has 'is_canceled' => (isa => 'Bool', is => 'rw',
		      traits => ['Bool'],
		      handles => {
			  cancel_operation => 'set',
		      },
		      );
has 'cancel_button' => (isa => 'Wx::Button', is => 'rw');
has 'close_button' => (isa => 'Wx::Button', is => 'rw');

sub FOREIGNBUILDARGS
{
    my($self, %args) = @_;

    my $title = $args{title};

    return (undef, -1, $title, wxDefaultPosition,
	    (exists($args{size}) ? $args{size} : wxDefaultSize,
	     wxMINIMIZE_BOX | wxMAXIMIZE_BOX | wxRESIZE_BORDER | wxCAPTION | wxCLIP_CHILDREN));
};

sub BUILD
{
    my($self) = @_;

    my $panel = wxPerl::Panel->new($self);
    $self->panel($panel);

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    $panel->SetSizer($top_sz);

    my $txt = wxPerl::TextCtrl->new($panel, "",
				style => wxTE_MULTILINE | wxTE_READONLY);
    $top_sz->Add($txt, 1, wxEXPAND);

    my $attr = $txt->GetDefaultStyle();
    my $font = $attr->GetFont;
    my $nfont = Wx::Font->new($font);
    $nfont->SetFamily(wxFONTFAMILY_TELETYPE);
    $nfont->SetPointSize($nfont->GetPointSize + 2);
    $attr->SetFont($nfont);
    $txt->SetDefaultStyle($attr);

    $self->text($txt);

    my $bbar = Wx::BoxSizer->new(wxHORIZONTAL);
    $top_sz->Add($bbar, 0, wxEXPAND);

    my $b = wxPerl::Button->new($panel, "Close");
    $bbar->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->Close(); });
    $self->close_button($b);

    $b = wxPerl::Button->new($panel, "Cancel");
    $bbar->Add($b, 0, wxALIGN_RIGHT | wxALL, 5);
    EVT_BUTTON($self, $b, sub { $self->cancel_operation(); });
    $self->cancel_button($b);

    $top_sz->Layout();
    $self->Show();
    
}

sub add_text
{
    my($self, $text) = @_;

    print "Adding text $text\n";

    $self->text->AppendText($text);
    $self->text->Refresh();
    $self->Refresh();
    $self->Update();
}

1;
