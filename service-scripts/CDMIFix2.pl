### Emergency fixup script for CDMI.

use strict;
use Bio::KBase::CDMI::CDMI;
use Bio::KBase::CDMI::CDMILoader;
use Stats;
use SeedUtils;
use Bio::KBase::CDMI::TaxonomyUtils;

    $| = 1; # Prevent buffering on STDOUT.
    my %names;
    my $counter = 0;
    my $stats = Stats->new();
    my %classes = ('scientific name' => 1); #, 'synonym' => 1, 'equivalent name' => 1, 'common name' => 1, 'misspelling' => 1);
	open(my $ih, "</Users/Bruce/FIG/taxdump/names.dmp") || die "Could not open names file: $!";
	while (! eof $ih) {
		my ($id, $name, $unique, $class) = Bio::KBase::CDMI::TaxonomyUtils::GetTaxData($ih, $stats);
		if ($classes{$class} && $name ne 'environmental samples') {
			$names{$name}++;
			$counter++;
			if ($names{$name} > 1) {
				print "Non-unique name $name for $id, unique variant $unique, class $class.\n";
			}
		}
	}
	print $counter;
