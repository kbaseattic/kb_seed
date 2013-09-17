#!/usr/bin/perl -w

    use strict;
    use Tracer;

    my $ih = Open(undef, "<C:\\Users\\Bruce\\FIG\\Kbase\\Plants\\Ptrichocarpa.JGI2.0\\contigs.fa");
    my @contigs;
    while (! eof $ih) {
        my $line = <$ih>;
        if ($line =~ /^>scaffold_(\d+)/) {
            push @contigs, $1;
        }
    }
    print join("\n", map { "scaffold_$_" } sort { $a <=> $b } @contigs, "");
