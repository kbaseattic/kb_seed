#!/usr/bin/perl -w

package ListServerScripts;

    use strict;
    use Tracer;
    use CGI;
    no warnings qw(once);

=head1 List Server Scripts

The main method of this package will generate a web page that lists the
current server scripts. The scripts will be determined by searching the
B<$FIG_Config::bin> directory for files with an C<svr_> prefix in the name
and a C<SAS Component> identifier at the beginning of the file. If there is
also evidence of POD documentation, a link to the script will be generated
in the output.

=head2 Constants

=head3 MAX_LINES

Maximum number of lines to read when searching script files.

=cut

use constant MAX_LINES => 50;

=head2 Methods

=head3 main

    ListServerScripts::main();

Run through the server scripts and generate a web page displaying links to their
documentation.

=cut

sub main {
    # Start with the CGI and HTML headers.
    print CGI::header();
    print CGI::start_html(-title => "Server Scripts List",
                          -style => { src => "http://servers.nmpdr.org/sapling/Html/css/ERDB.css" });
    # We'll accumulate HTML output in here.
    my @retVal;
    # Put in the introductory text.
    push @retVal, CGI::h1("Server Scripts");
    push @retVal, CGI::p("All scripts read from the standard input and write to the " .
                         "standard output. File names are never specified on the command " .
                         "line. In general, they accept as input a tab-delimited file and " .
                         "operate on the last column of the input. This allows multiple " .
                         "commands to be strung together using a pipe.");
    # Begin the list of scripts.
    push @retVal, CGI::start_ul();
    # Get the server script names.
    my @scripts = sort grep { $_ =~ /^svr_/ } Tracer::OpenDir($FIG_Config::bin);
    # Loop through them.
    for my $script (@scripts) {
        # Open the script for input.
        my $ih = Open(undef, "<$FIG_Config::bin/$script");
        # We'll keep the current input line in here.
        my $line;
        # Look for a SAS component indicator.
        my $sasFound = 0;
        while (! eof $ih && $ih->input_line_number() < MAX_LINES && ! $sasFound) {
            $line = <$ih>;
            if ($line =~ /\s+SAS\s+component/i) {
                $sasFound = 1;
            }
        }
        if ($sasFound) {
            # This is one of our files. Look for a head1 line.
            $line = <$ih> until (eof $ih || $line =~ /^=head1/);
            if (! eof $ih) {
                # We found the head1 line. We now want to find the first
                # line that could be a summary.
                $line = <$ih> while (! eof $ih && $line =~ /^(?:\s|=)/);
                # Build the lines in this region into a summary.
                my $summary = "";
                until (eof $ih || $line =~ /^\s/) {
                    $summary .= $line;
                    $line = <$ih>;
                }
                # Create a description of this script.
                push @retVal, CGI::li(CGI::a({ href => "http://pubseed.theseed.org/sapling/server.cgi?pod=$script.pl"},
                                             $script) . ": $summary");
            }
        }
    }
    # Close the list of scripts.
    push @retVal, CGI::end_ul();
    # Output the whole thing.
    print join("\n", @retVal);
    # Close the page.
    print CGI::end_html();
}

1;
