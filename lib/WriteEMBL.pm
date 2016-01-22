# -*- perl -*-
# This is a SAS component.

package WriteEMBL;

#########################################################################
# Copyright (c) 2003-2008 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#########################################################################

use strict;
use warnings;


sub form_header {
    my ($acc_num, $contig_len, $topology, $sequencing_type,
	$date, $defline, $keywords,
	$genome, $strain, $taxonomy, $taxon_ID) = @_;
    
    $keywords ||= q(.);
    
    print STDOUT (q(ID   ),
		  join(q(; ), ($acc_num, q(SV 1), $topology, q(genomic DNA), q(STD), q(PRO), qq($contig_len BP))),
		  q(.), qq(\n),
		  q(XX), qq(\n),
		  q(AC   ), $acc_num, qq(\n),
		  q(XX), qq(\n),
		  q(PR   Project:Your_Project_ID;), qq(\n),
		  q(XX), qq(\n),
	);
    
    print STDOUT (q(DT   ), $date, qq(\n), q(XX), qq(\n));
    
    formline <<END, $defline;
DE   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END, $defline;
DE~~ ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END;
XX
END

    formline <<END, $keywords;
KW   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
XX
END

    formline <<END, $genome, $taxonomy;
OS   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
OC   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END, $taxonomy;
OC~~ ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END;
XX
END

    formline <<END, $contig_len;
FH   Key             Location/Qualifiers
FH
FT   source          1..@<<<<<<<
END

    &form_multiline('organism', $genome);
    &form_multiline('mol_type', 'genomic DNA');
    &form_multiline('strain', $strain) if $strain;
    &form_multiline('db_xref', "taxon:$taxon_ID");

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#...Print header and clear Format-Accumulator...
#===============================================================================
    print $^A;  $^A = ""; 
#-------------------------------------------------------------------------------
    
    return;
}



sub form_feature {
    my ($type, $locus, $field_pairs) = @_;
    
    my $old_split = $:;
    $: = ',';
    formline <<END, $type, $locus;
FT   @<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END, $locus;
FT~~                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    $: = $old_split;
    
    if ($field_pairs) {
	foreach my $pair (@$field_pairs) {
	    &form_multiline(@$pair);
	}
    }
    
    return;
}



sub form_multiline {
    my ($field, $text) = @_;
    
    my $tmp = $text ? qq(/$field="$text") : qq(/$field);
    
    formline <<END, $tmp;
FT                   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    formline <<END, $tmp;
FT~~                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
END
    
    return;
}



sub write_contig {
    my ($contig_sequence_reference) = @_;
    
    my $tmp = lc($$contig_sequence_reference);
    
    my $len   = length($tmp);
    
    my $num_A = ($tmp =~ tr/a//);
    my $num_C = ($tmp =~ tr/c//);
    my $num_G = ($tmp =~ tr/g//);
    my $num_T = ($tmp =~ tr/t//);
    my $num_other = $len - ($num_A + $num_C + $num_G + $num_T);
    
    print STDOUT qq(SQ   Sequence $len BP\; $num_A A\; $num_C C\; $num_G G\; $num_T T\; $num_other other\;\n); 
    
    my $charcount = 0;
    while ($tmp)
    {
        $charcount += 60;
	formline <<END, $tmp, $tmp, $tmp, $tmp, $tmp, $tmp, $charcount;
     ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< ^<<<<<<<<< @########
END
    }
    
    print $^A;   $^A = "";
    
    return;
}

1;
