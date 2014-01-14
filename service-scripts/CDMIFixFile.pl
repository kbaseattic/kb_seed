### Emergency fixup script for CDMI.

use strict;
use Stats;

    $| = 1; # Prevent buffering on STDOUT.
    my $file = $ARGV[0];
    open my $ih, "<$file";
    open my $oh, ">$file.tbl";
    my $stats = Stats->new();
    my $line = "";
    my $mode = 0;
    while (! eof $ih) {
        my $input = <$ih>;
        chomp $input;
        $stats->Add(linesIn => 1);
        my @fields = split /\t/, $input;
        for my $field (@fields) {
            $stats->Add(fieldsIn => 1);
            if ($mode) {
                if ($field =~ /(.*)"\s*$/) {
                    $line .= " " . $1 . "\t";
                    $mode = 0;
                    $stats->Add(closeQuotes => 1);
                } else {
                    $line .= " " . $field;
                    $stats->Add(subFields => 1);
                }
            } else {
                if ($field =~ /^\s*"\s*(.+)"\s*$/) {
                    $line .= $1 . "\t";
                    $stats->Add(quotedFields => 1);
                } elsif ($field =~ /^\s*"\s*(.*)/) {
                    $line .= $1;
                    $mode = 1;
                    $stats->Add(openQuotes => 1);
                } else {
                    $line .= $field . "\t";
                    $stats->Add(wholeFields => 1);
                }
            }
        }
        if (! $mode) {
            print $oh "$line\n";
            $line = "";
            $stats->Add(linesOut => 1);
        }
    }
    # All done.
    print "All done:\n" . $stats->Show();

