#
# This is a SAS Component
#

use strict;
use Data::Dumper;
use Carp;
use Getopt::Long;
use LWP::UserAgent;
use Digest::MD5;

=head1 svr_cdd_scan

    svr_cdd_scan [options] < seqs.fa > cdd.table

Scans protein sequences for conserved domain hits in NCBI CD-Database.

=head2 Command-Line options

=over 4

=item -d

With the -d option, the program uses sequences instead of GI numbers as queries. This can be much slower.

=item -i ID_list

Comma separated input sequences/IDs .

=item -s 

With the -s option, the short form of output will contain one line for each sequence with 7 columns:

  [ seq_id, specific_hits, superfamiy_hits, multi-domain_hits, 
            names_for_specific_hits, names_for_superfamiy_hits, names_for_multi-domain_hits ]

If there are more than one hits in a column, they will be comma delimited.

=head2 Input

The FASTA file containing input sequences is read from STDIN.

=head2 Output

The table containing CDD hits is written to STDOUT. 

Without the -s option, the output table is -column table that may contain multiple lines for each input sequence:

  [ seq_id query_no query_id hit_type pssm_id
    from to e_value bit_score accession domain
    short_name incomplete_flag superfamily ] 

=cut

use gjoseqlib;
use SAPserver;

my $usage = <<"End_of_Usage";

usage: svr_cdd_scan [options] < seqs.fa > cdd.table

       -h   print this help screen
       -d   use sequences instead of GI numbers as queries (slow)
       -i   comma separated input sequences/IDs 
       -s   print short output table (one line for each sequence):

  Short output:

  [ seq_id, specific_hits, superfamiy_hits, multi-domain_hits, 
            names_for_specific_hits, names_for_superfamiy_hits, names_for_multi-domain_hits ]

  Long output (default):

  [ seq_id query_no query_id hit_type pssm_id from to e_value bit_score
           accession domain short_name incomplete_flag superfamily ] 

End_of_Usage

my ($help, $direct, $short, $idlist);

GetOptions("h|help"  => \$help,
           "d"       => \$direct,
           "i=s"     => \$idlist,
           "s|short" => \$short);

$help and die $usage;

my $opts;

my $seqs = $idlist ? [ map { [$_, undef, $_] } split(/,/, $idlist) ] : gjoseqlib::read_fasta();
my $cdH  = $idlist || $direct ? seqs_to_cds_direct($seqs, $opts) : seqs_to_cds($seqs, $opts);

if ($short) {
    for my $seq (@$seqs) {
        my $hits = $cdH->{$seq->[2]};
        my (@dom1, @dom2, @dom3);
        my (@name1, @name2, @name3);
        my %seen;
        for (@$hits) {
            next if $seen{$_->[8]}++;
            if ($_->[2] =~ /specific/) {
                push @dom1,  $_->[8]; 
                push @name1, $_->[9];
            } elsif ($_->[2] =~ /superfamily/) {
                push @dom2,  $_->[8];
                push @name2, $_->[9];
            } elsif ($_->[2] =~ /multi-dom/) {
                push @dom3,  $_->[8];
                push @name3, $_->[9];
            }
        }
        print join("\t", $seq->[0], join(",", @dom1),  join(",", @dom2),  join(",", @dom3),
                                    join(",", @name1), join(",", @name2), join(",", @name3)) . "\n";
    }    
} else {
    for my $seq (@$seqs) {
        my $hits = $cdH->{$seq->[2]};
        print join('', map { join("\t", $seq->[0], @$_)."\n" } @$hits );
    }
}

sub seqs_to_cds {
    my ($seqs, $opts) = @_;
    
    my $hash;
    my @prots = map { $_->[2] } @$seqs;
    my @md5s  = map { Digest::MD5::md5_hex($_->[2]) } @$seqs;
    my $sap   = new SAPserver;
    my $idH   = $sap->equiv_sequence_ids({ -ids => \@md5s });
    my %giH   = map { my ($gi) = map { /gi\|(\w+)/ ? $1 :() } @{$idH->{$_}}; $gi ? ($_ => $gi) : () } @md5s;
    my $cdH1  = ids_to_cds([values %giH]);
    
    my @ids2;
    for (my $i = 0; $i < @prots; $i++) {
        next if $giH{$md5s[$i]} && $cdH1->{$giH{$md5s[$i]}};
        push @ids2, $prots[$i];
    }
    my $cdH2  = ids_to_cds(\@ids2) if @ids2;
    for (my $i = 0; $i < @prots; $i++) {
        $hash->{$prots[$i]} = $cdH2->{$prots[$i]} || $cdH1->{$giH{$md5s[$i]}};
    }

    wantarray ? map { $hash->{$_} } @prots : $hash;
}

sub seqs_to_cds_direct {
    my ($seqs, $opts) = @_;
    my @ids = map { $_->[2] } @$seqs;
    my $hash = ids_to_cds(\@ids, $opts);
    return $hash;
}

sub ids_to_cds {
    my ($ids, $opts) = @_;

    my $info  = batch_cd_search($ids, $opts);
    my @lines = split(/\n/, $info);

    my $hash;
    for (@lines) {
        next unless s/^Q#//;
        my ($qno, undef, $qid, $type, $pssm, $from, $to, $exp, $scr, $acc, $name, $incmp, $super) = split /\s+/;
        push @{$hash->{$ids->[$qno-1]}}, [$qno, $qid, $type, $pssm, $from, $to, $exp, $scr, $acc, $name, $incmp, $super];
    }
    
    return $hash;
}

sub batch_cd_search {
    my ($queries, $opts) = @_;

    # URL to the Batch CD-Search server
    my $bwrpsb = "http://www.ncbi.nlm.nih.gov/Structure/bwrpsb/bwrpsb.cgi";

    my $cdsid  = "";
    my $cddefl = "false";
    my $qdefl  = "false";
    my $smode  = "auto";
    my $useid1 = "true";
    my $maxhit = 250;
    my $filter = "true";
    my $db     = "cdd";
    my $evalue = 0.01;
    # my $dmode  = "rep";
    my $dmode  = "all";
    my $clonly = "false";
    my $tdata  = "hits";

    my $rid;
    my $browser = LWP::UserAgent->new;
    my $response = $browser->post(
                                  $bwrpsb,
                                  [
                                   'useid1' => $useid1,
                                   'maxhit' => $maxhit,
                                   'filter' => $filter,
                                   'db'     => $db,
                                   'evalue' => $evalue,
                                   'cddefl' => $cddefl,
                                   'qdefl'  => $qdefl,
                                   'dmode'  => $dmode,
                                   'clonly' => $clonly,
                                   'tdata'  => "hits",
                                   ( map {; queries => $_ } @$queries )
                                  ],
                                 );
    die "Error: ", $response->status_line
        unless $response->is_success;

    if ($response->content =~ /^#cdsid\s+([a-zA-Z0-9-]+)/m) {
        $rid =$1;
        # print "Search with Request-ID $rid started.\n";
    } else {
        die "Submitting the search failed,\n can't make sense of response: $response->content\n";
    }

    $|++;
    my $done = 0;
    my $status = -1;
    while ($done == 0) {
        sleep(5);
        my $browser = LWP::UserAgent->new;
        my $response = $browser->post(
                                      $bwrpsb,
                                      [
                                       'tdata' => "hits",
                                       'cdsid' => $rid
                                      ],
                                     );
        die "Error: ", $response->status_line
            unless $response->is_success;

        if ($response->content =~ /^#status\s+([\d])/m) {
            $status = $1;
            if ($status == 0) {
                $done = 1;
                # print "Search has been completed, retrieving results ..\n";
            } elsif ($status == 3) {
                print STDERR ".";
            } elsif ($status == 1) {
                die "Invalid request ID\n";
            } elsif ($status == 2) {
                die "Invalid input - missing query information or search ID\n";
            } elsif ($status == 4) {
                die "Queue Manager Service error\n";
            } elsif ($status == 5) {
                die "Data corrupted or no longer available\n";
            }
        } else {
            die "Checking search status failed,\ncan't make sense of response: $response->content\n";
        }

    }

    ###############################################################################
    # retrieve and display results
    ###############################################################################
    {
        my $browser = LWP::UserAgent->new;
        my $response = $browser->post(
                                      $bwrpsb,
                                      [
                                       'tdata'  => $tdata,
                                       'cddefl' => $cddefl,
                                       'qdefl'  => $qdefl,
                                       'dmode'  => $dmode,
                                       'clonly' => $clonly,
                                       'cdsid'  => $rid
                                      ],
                                     );
        die "Error: ", $response->status_line
            unless $response->is_success;

        # print $response->content,"\n";
        return $response->content;
    }

}

