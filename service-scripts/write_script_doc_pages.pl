use strict;
use Pod::Simple::HTML;

@ARGV == 3 or die "Usage: $0 script-dir index.html text.html\n";

my $script_dir = shift;
my $index = shift;
my $text = shift;

open(OUT, ">", $text) or die "Cannot write $text: $!";
open(IDX, ">", $index) or die "Cannot write $index: $!";

for my $script (<$script_dir/*.pl>)
{
    my $pod = Pod::Simple::HTML->new;

    $pod->force_title('');
    $pod->html_h_level(2);
    $pod->index(0);
    $pod->html_css('');
    $pod->html_javascript('');
    $pod->title_prefix('<title>');
    $pod->title_postfix('</title>');
    $pod->html_header_before_title('');
    $pod->html_header_after_title('');
    $pod->html_footer('');
    
     $pod->output_fh(\*OUT);
    
    $pod->parse_file($script);
    print OUT "<hr>\n";
    
    print IDX $pod->index_as_html;
}

close(OUT);
close(IDX);
