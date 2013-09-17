#!/usr/bin/perl -w
use Getopt::Std;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_spreadsheet_to_file -f filename -x coordinates 

Writes the contents of the spreadsheet given in filename to a tab separated file on STDOUT.

If given, the coordinates delimit the cells to be written.

The output is a file of tab separated cells, one row per line. 

Example: svr_spreadsheet_to_file -f test.xls  > test.txt 

=head2 Command-Line Options

=over 4

=item -f 

The file name of an xls or xlsx format spreadsheet.

=item -x

Coordinates to be displayed. These are given in the form (minx, miny, maxx, maxy)
That is, 1,1,20,20 will choose cells starting in the leftmost corner of the 
spreadsheet to cell 20,20.

1,2,5,3 will start at row 1, column 2, and go to row 5, column 3. 

=back

=head2 Output Format

The standard output is a file to STDOUT where each line contains the contents of all the selected cells, separated by tabs.

=cut

our ($opt_x, $opt_f);
getopt("x:f");

if (!$opt_f) {
	die "Usage: No File Specified (-f missing)\n";
} 
	
my ($cell, $row, $col);
my ($minx, $miny, $maxx, $maxy);
if ($opt_x) {
($minx, $miny, $maxx, $maxy) = split(",",$opt_x);
if ($minx < 1 || $miny < 1 || $maxx < 1 || $maxy < 1) {
	die "Usage coordinates must be > 0\n";
}
$minx--;
$miny--;
$maxx--;
$maxy--;
}

if ($opt_f =~ /xlsx/) {
	process_xlsx();
} else {
	process_xls();
}

sub process_xls {
	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($opt_f);

	if ( !defined $workbook ) {
	die $parser->error(), ".\n";
	}

	for my $worksheet ( $workbook->worksheets() ) {
		my ( $row_min, $row_max ) = $worksheet->row_range();
		my ( $col_min, $col_max ) = $worksheet->col_range();
		$row_min = defined($miny) && $miny > $row_min? $miny:$row_min;
		$row_max = defined($maxy) && $maxy < $row_max? $maxy:$row_max;
		$col_min = defined($minx) && $minx > $col_min? $minx:$col_min;
		$col_max = defined($maxx) && $maxx < $col_max? $maxx:$col_max;

		for $row ( $row_min .. $row_max ) {
			$col = $col_min;	
			$cell = $worksheet->get_cell( $row, $col );
			if ($cell) {
				print $cell->value();
			}
			for $col ( $col_min+1 .. $col_max ) {
				$cell = $worksheet->get_cell( $row, $col );
				print "\t";
				if ($cell) {
					print $cell->value();
				}
				#print "Value       = ", $cell->value(),       "\n";
				#print "Unformatted = ", $cell->unformatted(), "\n";
			}
			print "\n";
		}
	}
}

sub process_xlsx {
	my $excel = Spreadsheet::XLSX -> new ($opt_f);
	foreach my $sheet (@{$excel -> {Worksheet}}) {
		my $row_min = $sheet->{MinRow};
		my $row_max = $sheet->{MaxRow};
		my $col_min = $sheet->{MinCol};
		my $col_max = $sheet->{MaxCol};

		$row_min = defined($miny) && $miny > $row_min? $miny:$row_min;
		$row_max = defined($maxy) && $maxy < $row_max? $maxy:$row_max;
		$col_min = defined($minx) && $minx > $col_min? $minx:$col_min;
		$col_max = defined($maxx) && $maxx < $col_max? $maxx:$col_max;

		for $row ( $row_min .. $row_max ) {
			$col = $col_min;	
 			$cell = $sheet -> {Cells} [$row] [$col];
			if ($cell) {
				print $cell->value();
			}
			for $col ( $col_min+1 .. $col_max ) {
				$cell = $sheet -> {Cells} [$row] [$col];
				print "\t";
				if ($cell) {
					print $cell->value();
				}
				#print "Value       = ", $cell->value(),       "\n";
				#print "Unformatted = ", $cell->unformatted(), "\n";
			}
			print "\n";
		}
 	}
}
