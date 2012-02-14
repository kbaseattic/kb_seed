#
# Module to render a page that looks like an NMPDR page.
#
#

#### WARNING! THIS IS NOT A PACKAGE. IT'S A SET OF INCLUDED
#### SUBROUTINES! THIS IS NOT A PACKAGE.

use FIG_Config;
use LWP::UserAgent;

sub get_php_include
{
    my($path) = @_;
    my $base = "$FIG_Config::fig_disk/../html";
    $path = "$base/$path";
    local $/ = undef;
    if (!open(F, "<$path"))
    {
	warn "get_php_include(): Cannot open $path: $!\n";
	return;
    }
    my $out = <F>;
    close(F);
    return $out;
}

sub expand_nmpdr_page
{
    my($title, $content) = @_;

    my $header = get_php_include("includes/header-fig.inc");
    my $left_nav = get_php_include("includes/left_nav-fig.inc");
    my $footer = get_php_include("includes/footer.inc");

    my $out = <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
END
    $out .= "<title>$title</title>\n";

    $out .= <<'END';
<link href="../content/NMPDR.css" rel="stylesheet" type="text/css" />
</head>

<body>
<div id="header">
END
    $out .= $header;
    $out .= <<'END';
</div>
<div id="container">

<div id="sidebar">
END
    $out .= $left_nav;
    $out .= <<'END';
</div>
<div id="content">
END
    $out .= $content;

    $out .= <<'END';

</div>
<div id="footer">
END
    $out .= $footer;
    $out .= <<'END';
</div>
</div>
</body>
</html>
END
    return $out;
}

sub print_template_header
{
    my($title) = @_;

    my $header = get_php_include("includes/header-fig.inc");
    my $left_nav = get_php_include("includes/left_nav-fig.inc");

    print <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
END
    print "<title>$title</title>\n";
    print <<'END';
<link href="../content/NMPDR.css" rel="stylesheet" type="text/css" />
</head>

<body>
<div id="header">
END
    print $header;
    print <<'END';
</div>
<div id="container-cal">

<div id="sidebar">
END
    print $left_nav;
    print <<'END';
</div>
<div id="content">
END
}

sub print_template_footer
{
    my $footer = get_php_include("includes/footer.inc");
    print <<'END';

</div>
<div id="footer">
END
    print $footer;
    print <<'END';
</div>
</div>
</body>
</html>
END
}

# Look for relative URLs in the body of a template string and
# replace them with absolute URLs. On entry, the first parameter
# ($template) should be a giant HTML string representing the
# template, and the second parameter ($base) should be the
# proposed new base URL. The modified template will be returned.
sub fix_template_urls {
    my ($template, $base) = @_;
    # Strip any trailing slash off the base.
    if ($base =~ m!/$!) {
        substr $base, -1, 1, "";
    }
    # Create an output string.
    my $retVal = "";
    # Denote we're at the beginning of the template string.
    my $pos = 0;
    # Loop through the input template, looking for possible
    # URLs.
    while ($template =~ m/(href|src|action)="([^"]+)"/gi) {
        # At this point, $1 should be a keyword that has a
        # URL as its value and $2 will be the URL. We use the
        # pos() function to find where we are in the template
        # string. In particular, we want to know where the
        # keyword starts. We begin by computing the length of
        # the entire matched string.
        my $matchLen = length($1) + 3 + length($2);
        # Get the keyword and URL values.
        my $keyword = $1;
        my $url = $2;
        # Compute the start position and copy the stuff we
        # passed over on the way to finding this match.
        my $startPos = pos($template) - $matchLen;
        $retVal .= substr($template,$pos, $startPos - $pos);
        # Append the keyword and the =".
        $retVal .= "$keyword=\"";
        # Find out if this is an absolute or relative URL.
        if ($url =~ /^http:/i) {
            # Absolute URL. Move it unmodified.
            $retVal .= $url;
        } elsif ($url =~ m!^/!i) {
            # Here it's relative to the site root. We
            # stuff the caller-specified bnase URL in
            # front.
            $retVal .= "$base$url";
        } else {
            # Here it's relative to the current location. Since
            # it's a Typo3 web page, the curent location is
            # the site root. We have to insert a slash between
            # the base and the URL.
            $retVal .= "$base/$url";
        }
        # Add the closing quote.
        $retVal .= '"';
        # Denote we've processed up through the end of the
        # matched section.
        $pos = $startPos + $matchLen;
    }
    # Check for a residual.
    if ($pos < length($template)) {
        # Here there's unmatched residual that needs to be
        # added at the end of the return string.
        $retVal .= substr($template, $pos);
    }
    # Return the result.
    return $retVal;
}

1;
