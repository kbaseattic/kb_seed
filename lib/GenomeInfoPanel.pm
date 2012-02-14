package GenomeInfoPanel;

use SeedUtils;
use Data::Dumper;

use Moose;
use MooseX::NonMoose;

use wxPerl::Constructors;
use Wx::Grid;
use Wx qw(:sizer :everything);
use Wx::Event qw(EVT_BUTTON EVT_RADIOBOX EVT_COMBOBOX EVT_TIMER EVT_GRID_COL_SIZE EVT_GRID_ROW_SIZE
		 EVT_IDLE EVT_SIZE EVT_GRID_CELL_LEFT_DCLICK EVT_SIZE);

extends 'Wx::Panel';

=head1 NAME

GenomeInfoPanel - general info about a genome

=cut

use constant ATTRIBS =>
    ([ txt_genome_id => undef ],
     [ txt_genome_name => undef ],
     [ txt_feature_counts => "Feature counts" ],
     [ txt_contig_size => "Contig size" ],
     [ txt_subsystem_count => "Subsystem count" ],
     );

foreach my $a (ATTRIBS)
{
    has "$a->[0]" => (isa => 'Wx::StaticText', is => 'rw');
}

has 'genome' => (isa => 'Maybe[SapGenome]', is => 'rw',
		 trigger => \&_set_genome);

has 'top_sizer' => (isa => 'Wx::Sizer', is => 'rw');

has 'labels' => (isa => 'ArrayRef', is => 'rw');

sub FOREIGNBUILDARGS
{
    my($self, %args) = @_;

    return ($args{parent}, -1);
};

sub BUILD
{
    my($self) = @_;

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    $self->SetSizer($top_sz);
    $top_sz->SetSizeHints($self);
    $self->top_sizer($top_sz);

    my $bold_font = Wx::Font->new(24, wxFONTFAMILY_DEFAULT, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_BOLD);

    #
    # The attribs with undef names go at the top in big text.
    #
    for my $a (ATTRIBS)
    {
	my($key, $name) = @$a;
	next if $name;

	my $txt = wxPerl::StaticText->new($self, '');
	$txt->SetFont($bold_font);
	$top_sz->Add($txt, 0, wxEXPAND | wxALL);
	$self->$key($txt);
    }

    my $flex = Wx::FlexGridSizer->new(0, 2, 5, 5);
    $top_sz->Add($flex, 1, wxEXPAND);

    #
    # The rest are labeled pairs in the flex sizer.
    #
    my @labels;
    for my $a (ATTRIBS)
    {
	my($key, $name) = @$a;
	next unless $name;

	my $label = wxPerl::StaticText->new($self, $name);
	$label->Show(0);
	$flex->Add($label, 0, wxEXPAND);
	my $t = wxPerl::StaticText->new($self, '');
	$flex->Add($t);
	$self->$key($t);
	push(@labels, $label);
    }
    $self->labels(\@labels);

    EVT_SIZE($self, \&on_resize);
}
		   
sub _set_genome
{
    my($self, $new, $old) = @_;

#    print "me " . $self->GetSize->width . "\n";
    $self->txt_genome_id->Wrap($self->GetSize->width);
    $self->txt_genome_name->Wrap($self->GetSize->width);

    $_->Show($new ? 1 : 0) foreach @{$self->labels};

    if ($new)
    {
	$self->txt_genome_id->SetLabel($new->id);
	$self->txt_genome_name->SetLabel($new->name? $new->name : "(no name)");
    }
    else
    {
	$self->txt_genome_id->SetLabel("");
	$self->txt_genome_name->SetLabel("");
    }

    $self->on_resize();
    
#     my $s = $self->txt_genome_name->GetSize;
#     $self->top_sizer->SetItemMinSize($self->txt_genome_name, $s->width, $s->height);
#     print $s->width . " " . $s->height . "\n";
#     my $s = $self->txt_genome_id->GetSize;
#     $self->top_sizer->SetItemMinSize($self->txt_genome_id, $s->width, $s->height);

}

sub on_resize
{
    my($self) = @_;

#    print "me " . $self->GetSize->width . "\n";
    $self->txt_genome_id->Wrap($self->GetSize->width);
    $self->txt_genome_name->Wrap($self->GetSize->width);

#    print $self->txt_genome_id->GetSize->width . " " . $self->txt_genome_id->GetSize->height . "\n";
#    print $self->txt_genome_name->GetSize->width . " " . $self->txt_genome_name->GetSize->height . "\n";
    $self->top_sizer->Layout();
    $self->Layout();
}

1;

