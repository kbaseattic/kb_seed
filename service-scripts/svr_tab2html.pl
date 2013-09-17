#!/usr/bin/perl

#
# This is a SAS Component
#

my $usage = "usage: svr_tab2html [LINK-TEMPLATE] < tab-separated > html
The LINK-TEMPATE is a URL in which the 3-character string PEG is mapped
to the FIG-ID for any column containing a PEG";

my $border = q();
if (@ARGV && ($ARGV[0] =~ m/^-{1,2}border/)) {
    $border = q( border=1);
    shift;
}

my $url = (@ARGV > 0) ? $ARGV[0] : "";

print "<table$border>\n";
while (defined($_ = <STDIN>))
{
    chomp;
    if ($_ =~ m{^//}) {
	print STDOUT "</table>\n\n";
	next;
    }
    
    my $heading_line = ($_ =~ s/^\#//) ? 1 : 0;
    
    my @flds = split(/\t/,$_);
    print "<tr>\n";
    foreach $fld (@flds)
    {
	if (($fld =~ /(fig\|\d+\.\d+\.peg\.\d+)/) && $url)
	{
	    my $peg = $1;
	    my $tmp = $url;
	    $tmp =~ s/PEG/$peg/g;
	    $fld = "<a href=$tmp>$fld</a>";
	}
	
	if ($heading_line) {
	    print STDOUT "  <th>$fld</th>\n";
	}
	else {
	    print STDOUT "  <td>$fld</td>\n";
	}
    }
    print STDOUT "</tr>\n";
}
print STDOUT "</table>\n";
