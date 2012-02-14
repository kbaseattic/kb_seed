#!/Users/olson/wx/bin/perl


=head1 NAME

dtr_helper_psiblast - run psiblast lookup in background for Desktop RAST

=head1 SYNOPSIS

  dtr_helper_psiblast [handle status-port] < sequence > ids

=head1 DESCRIPTION

Reads protein data from stdin, and does the appropriate lookups to NCBI to perform
the psiblast analysis. When complete, writes the blast computation id and the 
CDD computation ID to stdout.

If status port is defined, connects to the status port to write 
updates of the progress of the computation. Each update is a 
list of status tuples of one of these forms:

     [ status_msg => "some string" ]
     [ progress_value => N ]
     [ progress_range => N ]

=cut

use strict;
use IO::Socket::INET;
use LWP::UserAgent;
use Time::HiRes 'gettimeofday';
use YAML::Any;

my $port;
my $sock;
my $handle;
my $input_file;
if (@ARGV)
{
    @ARGV == 2 or @ARGV == 3 or die "Usage: $0 [handle status-port [input]] < inp > out\n";
    $handle = shift;
    $port = shift;
    $input_file = shift;
    if ($port !~ /^\d+$/)
    {
	die "Invalid status port $port\n";
    }

    $sock = IO::Socket::INET->new(PeerHost => 'localhost',
				  PeerPort => $port,
				  Proto => 'tcp');
}

my $ua = LWP::UserAgent->new();
my $url = "http://blast.ncbi.nlm.nih.gov/Blast.cgi";

undef $/;
my $seq;
my $fh;
if (defined($input_file))
{
    print STDERR "Starting, reading $input_file\n";
    open($fh, "<", $input_file) or die "cannot open $input_file: $!";
}
else
{
    $fh = \*STDIN;
    print STDERR "Starting, reading stdin\n";
}

my $seq = <$fh>;
print STDERR "read $seq\n";

my $req = {
    QUERY => $seq,
    DATABASE => 'nr',
    CDD_SEARCH => 'on',
    COMPOSITION_BASED_STATISTICS => 'on,',
    FILTER => 0,
    EXPECT => 10,
    WORD_SIZE => 3,
    MATRIX_NAME => 'BLOSUM62',
    NCBI_GI => 'on',
    GRAPHIC_OVERVIEW => 'is_set',
    FORMAT_OBJECT => 'Alignment',
    FORMAT_TYPE => 'XML',
    DESCRIPTIONS => 500,
    ALIGNMENTS => 250,
    ALIGNMENT_VIEW => 'Pairwise',
    SHOW_OVERVIEW => 'on',
    RUN_PSIBLAST => 'on',
    I_THRESH => 0.002,
    AUTO_FORMAT => 'on',
    PROGRAM => 'blastp',
    CLIENT => 'web',
    PAGE => 'Proteins',
    SERVICE => 'psi',
    CMD => 'Put',
};

&send([ status => "Query NCBI" ],
      [ progress_range => -1 ]);

my $res = $ua->post($url, $req);

my $done = 0;
my($rid, $cdd_rid);
while (!$done)
{
    if ($res->is_success)
    {
	my $dat = $res->content;

	open(O, ">", "out." . time);
	print O $dat;
	close(O);
exit;	
	my($timeout) = $dat =~ /var\s*tm\s*=\s*"(\d+)"/;
	($rid) = $dat =~ /input name="RID".*?value="([A-Z0-9]+)"/;

	if (!defined($rid))
	{
	    #
	    # Something went badly wrong.
	    #
	    &send([status => "Query failed"]);
	    exit 1;
	}

	($cdd_rid) = $dat =~ /input name="CDD_RID".*?value="data_cache_seq:([A-Z0-9]+)"/;
	my $waiting = $dat =~ /This page will be automatically updated/;
#	print "FOUND cdd_rid=$cdd_rid waiting=$waiting\n";
	if ($waiting)
	{
	    if (defined($timeout))
	    {
		$timeout /= 1000;
	    }
	    else
	    {
		($timeout) = $dat =~ /updated in.*?(\d+).*?seconds/;
		if (!defined($timeout))
		{
		    $timeout = 1;
		}
	    }
	}

#	open(O, ">", gettimeofday . ".html");
#	print O $dat;
#	close(O);
#	print STDERR "timeout=$timeout cdd_rid=$cdd_rid rid=$rid waiting=$waiting\n";

	if (!(length($cdd_rid) > 2 && defined($rid)))
	{
	    if (defined($timeout))
	    {
		&send([ status => "Waiting $timeout sends for results..." ],
		      [ progress_range => $timeout * 10 ],
		      [ progress => 0 ]);
		
		my $finish = gettimeofday + $timeout;

		while ((my $left = $finish - gettimeofday) > 0)
		{
		    sleep(0.5);
		    &send([ progress => int((($timeout - $left) * 10)) ]);
		}
		&send([ status => "Query NCBI" ],
		      [ progress_range => -1 ]);
		$res = $ua->get("http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Get&VIEW_RESULTS=FromRes&RID=$rid&QUERY_INDEX=0");
	    }
	}
	else
	{
	    print STDERR "done rid=$rid \n";
	    $done = 1;
	}
    }
    else
    {
	&send([status => "Query failed"]);
	exit 1;
    }
}
print STDERR "finishing\n";
print "$rid\n$cdd_rid\n";
$sock->close() if defined($sock);
exit 0;

sub send
{
    my(@list) = @_;

    return unless defined($sock);

    my $txt = Dump([ $handle => \@list]);
    my $len = length($txt);
    print $sock pack("N", $len) . $txt;
}
