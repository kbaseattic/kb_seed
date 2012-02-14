
# This is a SAS component.

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
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
#
package SubsystemPrimer;
use FIG_Config;
use Data::Dumper;
use strict;

sub page {
    my($cgi,$user,$fig,$my_url,$hidden_vars) = @_;

    my $html = [];
    push(@$html,"<TITLE>Build Request for a Subsystem</TITLE>\n");
    if ($cgi->param('help'))
    {
	push(@$html,&help_request);
    }
    else
    {
	push(@$html,$cgi->br,$cgi->br,&help_link($cgi, $my_url),$cgi->br);
	if ($cgi->param('Save Request'))
	{
	    &save_request($cgi,$html,$user,$fig,$my_url,$hidden_vars);
	}
	else
	{
	    &disp_state($cgi,$html,$user,$fig,$my_url,$hidden_vars);
	}
    }
    return $html;
}

sub disp_state {
    my($cgi,$html,$user,$fig,$my_url,$hidden_vars) = @_;

    push(@$html,$cgi->start_form(-action => $my_url));
    push(@$html, $hidden_vars);
    push(@$html,&display_title($cgi));
    push(@$html,&display_desc($cgi));
    push(@$html,&display_pubmed($cgi));
    push(@$html,&display_notes($cgi,$fig));
    push(@$html,&display_categories($cgi));
    push(@$html,&display_roles($cgi));
    push(@$html,&display_proteins($cgi));
    push(@$html,$cgi->br,$cgi->br);
    push(@$html,&hide_pubmed($cgi));
    push(@$html,$cgi->submit('Update Display'));
    push(@$html,$cgi->submit('Save Request'));
    push(@$html,$cgi->end_form);
}

sub display_title {
    my($cgi) = @_;

    my @html;
    my $name = $cgi->param('name') || '';
    
    push(@html,$cgi->h2("Name of Subsystem"),
	        $cgi->textfield(-name => "name", -size => 60, -value => $name),
	        $cgi->br,$cgi->br);
    return @html;
}

sub display_desc {
    my($cgi) = @_;

    my @html;
    my $desc = $cgi->param('desc') || '';
    push(@html,$cgi->h2("Description"),
	        $cgi->textarea(-name => "desc", 
			       -rows => 5,
			       -cols => 150,
			       -value => $desc),
	        $cgi->br,$cgi->br);

    return @html;
}

sub pubmed_ids {
    my($cgi) = @_;
    my @pubmed;
    my $pubmed = $cgi->param('pubmed');
    if ($pubmed)
    {
	@pubmed = ($pubmed =~ /(\d+)/g);
    }
    return @pubmed;
}

sub display_pubmed {
    my($cgi) = @_;

    my @html;
    my @pubmed = &pubmed_ids($cgi);
    my $pubmed = join(",",@pubmed);
    push(@html,$cgi->h2("Pubmed IDs"),
               $cgi->textfield(-name => "pubmed", 
			       -size => 60,
			       -value => $pubmed,
			       -override => 1),
	        $cgi->br,$cgi->br);

    return @html;
}

sub hide_pubmed {
    my($cgi) = @_;

    my @pubmed = &pubmed_ids($cgi);
    my @html;
    foreach my $id (@pubmed)
    {
	push(@html,$cgi->hidden(-name => 'seen', -value => $id));
    }
    return @html;
}

sub display_notes {
    my($cgi,$fig) = @_;

    my @html;
    my $notes = $cgi->param('notes') || '';
    my @pubmed = &pubmed_ids($cgi);
    my $enhanced_notes = &enhance_notes($cgi,$fig,$notes,\@pubmed);

    push(@html,$cgi->h2("Notes"),
	        $cgi->textarea(-name => "notes", 
			       -rows => 20,
			       -cols => 150,
			       -override => 1,
			       -value => $enhanced_notes),
	        $cgi->br,$cgi->br);

    return @html;
}

sub enhance_notes {
    my($cgi,$fig,$notes,$pubmed) = @_;

    use Dlits;

    my %seen = map { $_ => 1 } $cgi->param('seen');
    foreach my $id (@$pubmed)
    {
	if (! $seen{$id})
	{
	    my $pmH = &Dlits::get_pubmed_document_details($fig,$id);
	    if ($pmH->{title})
	    {
		my $pm_add = "See \"$pmH->{title}\"\n\n    by $pmH->{authors}\n\n    in $pmH->{source}\n\n";
		$notes = $notes . "\n\n$pm_add\n";
	    }
	}
    }
    return $notes;
}

sub display_categories {
    my($cgi) = @_;

    my $html = [];
    my @cat1 = grep { $_ } $cgi->param('cat1');
    my $cat1 = $cat1[0] || '';
    my @cat2 = grep { $_ } $cgi->param('cat2');
    my $cat2 = $cat2[0] || '';
    push(@$html,$cgi->hr);
    &display_cat($cgi,$html,'Major Category',$cat1,'cat1',&cat1);
    &display_cat($cgi,$html,'Category',      $cat2,'cat2',&cat2);
    push(@$html,$cgi->hr);
    return @$html;
}

sub display_cat {
    my($cgi,$html,$label,$value,$name,$choices) = @_;

    if ((! $value) && (my $catL = $cgi->param(($name . 'L')))) { $value = $catL }
    unshift(@$choices,'');
    push(@$html,$cgi->h2($label),
	        $cgi->textfield(-name => $name, -value => $value, -override => 1, -size => 60),
	        $cgi->br,
	        $cgi->scrolling_list( -name => ($name . 'L'), -values => $choices, -size => 10, -default => ''),
	        $cgi->br,$cgi->br);

}

sub display_roles {
    my($cgi) = @_;

    my @html;
    push(@html,$cgi->br,$cgi->br,$cgi->h2('Roles'));
    my @params = sort { $a=>[0] =~ /^role(\d+)/; my $x = $1; $b->[0] =~ /^role(\d+)/; 
			($x <=> $1) or ($a->[0] cmp $b->[0]) }
	         grep { $_->[1] } 
                 map { [$_,$cgi->param($_),$cgi->param($_ . "AB")] } # [parm,role,abbrev]
                 grep { $_ =~ /^role\d+$/ } 
                 $cgi->param;
    
    my $sofar = 0;
    foreach $_ (@params)
    {
	$_->[0] =~ /^role(\d+)$/;
	$sofar = &SeedUtils::max($1,$sofar);
    }
    my $nxt = $sofar + 1;
    foreach $_ (@params)
    {
	my($param,$role,$abbrev) = @$_;
	push(@html,&display_one_role($cgi,$param,$role,$abbrev));
    }

    my $i;
    for ($i=$nxt; ($i < ($nxt + 5)); $i++)
    {
	my $param = "role$i";
	my $role = '';
	my $abbrev = '';
	push(@html,&display_one_role($cgi,$param,$role,$abbrev));
    }
    push(@html,$cgi->hr);
    return @html;
}

sub display_one_role {
    my($cgi,$param,$role,$abbrev) = @_;

    my @html;
    push(@html,$cgi->textfield(-name => ($param . 'AB'), -size => 6, -value => $abbrev));
    push(@html,$cgi->textfield(-name => $param, -size => 60, -value => $role));
    push(@html,$cgi->br,$cgi->br);
    return @html;
}

sub display_proteins {
    my($cgi) = @_;

    my @html;
    push(@html,$cgi->br,$cgi->br,$cgi->h2('Proteins'));
    my @params = sort { $a=>[0] =~ /^protein(\d+)/; my $x = $1; $b->[0] =~ /^protein(\d+)/; 
			($x <=> $1) or ($a->[0] cmp $b->[0]) }
	         grep { $_->[1] } 
                 map { [$_,$cgi->param($_),$cgi->param($_ . "FN")] } # [parm,protein,function]
                 grep { $_ =~ /^protein\d+$/ } 
                 $cgi->param;
    
    my $sofar = 0;
    foreach $_ (@params)
    {
	$_->[0] =~ /^protein(\d+)$/;
	$sofar = &SeedUtils::max($1,$sofar);
    }
    my $nxt = $sofar + 1;
    foreach $_ (@params)
    {
	my($param,$protein,$function) = @$_;
	push(@html,&display_one_protein($cgi,$param,$protein,$function));
    }

    my $i;
    for ($i=$nxt; ($i < ($nxt + 5)); $i++)
    {
	my $param = "protein$i";
	my $protein = '';
	my $function = '';
	push(@html,&display_one_protein($cgi,$param,$protein,$function));
    }
    push(@html,$cgi->hr);
    return @html;
}

sub display_one_protein {
    my($cgi,$param,$protein,$function) = @_;

    my @html;
    push(@html,$cgi->textfield(-name => $param, -size => 20, -value => $protein));
    push(@html,$cgi->textfield(-name => ($param . 'FN'), -size => 80, -value => $function));
    push(@html,$cgi->br,$cgi->br);
    return @html;
}

sub save_request {
    my($cgi,$html,$user,$fig, $my_url, $hidden_vars) = @_;

    my $title = $cgi->param('name');
    if (! $title)
    {
	push(@$html,$cgi->h1("You need to specify at least a title"));
	&disp_state($cgi,$html,$user, $fig, $my_url, $hidden_vars);
	return;
    }

    my $desc  = $cgi->param('desc');
    if (! $desc)
    {
	push(@$html,$cgi->h1("You need to specify a description"));
	&disp_state($cgi,$html,$user, $fig, $my_url, $hidden_vars);
	return;
    }

    my $notes  = $cgi->param('notes');
    if (! $notes)
    {
	push(@$html,$cgi->h1("You need to specify notes"));
	&disp_state($cgi,$html,$user, $fig, $my_url, $hidden_vars);
	return;
    }

    my $pubmed  = $cgi->param('pubmed');

    my $cat1    = $cgi->param('cat1');
    my @cat1L   = $cgi->param('cat1L');
    if ((! $cat1) && (@cat1L > 0)) { $cat1 = $cat1L[0] }

    my $cat2    = $cgi->param('cat2');
    my @cat2L   = $cgi->param('cat2L');
    if ((! $cat2) && (@cat2L > 0)) { $cat2 = $cat2L[0] }

    if ((! $cat1) || (! $cat2))
    {
	push(@$html,$cgi->h1("You need to specify both a major category and the lower-level category"));
	&disp_state($cgi,$html,$user, $fig, $my_url, $hidden_vars);
	return;
    }

    my @roles     = grep { $_ =~ /^role\d+$/ } $cgi->param;
    @roles        = grep { $cgi->param(($_ . 'AB'))} @roles;
    if (@roles < 1)
    {
	push(@$html,$cgi->h1("You need to specify one or more roles"));
	&disp_state($cgi,$html,$user, $fig, $my_url, $hidden_vars);
	return;
    }
    my @proteins  = grep { $_ =~ /^protein\d+$/ } $cgi->param;
    @proteins     = grep { $cgi->param(($_ . 'FN'))} @proteins;
    if (@proteins < 1)
    {
	push(@$html,$cgi->h1("You need to specify one or more proteins"));
	&disp_state($cgi,$html,$user, $fig, $my_url, $hidden_vars);
	return;
    }

    my $file = &really_save($cgi,$html,$user,$title,$desc,$pubmed,$notes,$cat1,$cat2,\@roles,\@proteins);
    push(@$html,$cgi->h2("Successfully saved the request for \"$title\" to $file"));
}

sub really_save {
    my($cgi,$html,$user,$title,$desc,$pubmed,$notes,$cat1,$cat2,$roles,$proteins) = @_;

    my $sspD = $FIG_Config::ssp_dir;
    if ($sspD eq '')
    {
	$sspD = "$FIG_Config::temp/ssp";
    }
    &SeedUtils::verify_dir($sspD);
    opendir(SSPD,$sspD) || die "could not open $sspD";
    my @existing = sort { $b <=> $a } grep { $_ =~ /^\d+$/ } readdir(SSPD);
    closedir(SSPD);
    my $nxt = (@existing > 0) ? ($existing[0]+1) : 1;
    my $file = "$sspD/$nxt";
    open(SSP,">", $file) || die "could not open $file: $!";
    &print_kv(\*SSP,'title',$title);
    &print_kv(\*SSP,'user',$user);
    &print_kv(\*SSP,'desc',$desc);
    &print_kv(\*SSP,'notes',$notes);
    &print_kv(\*SSP,'cat1',$cat1);
    &print_kv(\*SSP,'cat2',$cat2);
    my @pubmed = ($pubmed =~ /(\d+)/g);
    foreach $_ (@pubmed)
    {
	&print_kv(\*SSP,'pubmed',$_);
    }
    foreach my $role (@$roles)
    {
	my $v = $cgi->param($role);
	my $abbrev = $cgi->param($role . 'AB');
	&print_kv(\*SSP,'role',($abbrev . '::' . $v));
    }

    foreach my $protein (@$proteins)
    {
	my $v = $cgi->param($protein);
	my $function = $cgi->param($protein . 'FN');
	&print_kv(\*SSP,'protein',($v . '::' . $function));
    }
    close(SSPD);
    return $file;
}

sub print_kv {
    my($fh,$key,$v) = @_;

    print $fh "$key\n$v\n//\n";
}

sub help_link {
    my($cgi,$my_url) = @_;

#    my $link = $FIG_Config::cgi_url . "seedviewer.cgi?page=SSE&request=help";
    my $link = $my_url;
    if ($my_url =~ /\?/)
    {
	$link .= "&";
    }
    else
    {
	$link .= "?";
    }
    $link .= "help=1";
    my $window = "sse_help";
    return "<a target=$window href='$link'>Help</a>";
}    

sub help_request {

    my $help = <<"End_Help";

<br><br>
The Subsystem Request System allows you to create a request that a subsystem be built.
The request can be used by annotators as inital data from which a complete subsystem
can constructed.  The data that we ask you to fill in includes
<ul>
<li> <b>Name of Subsystem</b> (please do not use apostrophes or slashes in the name -- special
	                characters tend to cause problems),
<li> <b>a Short Description</b> of the subsystem (explain why you think the functional roles that make
     up the proposed subsystem should be curated as a group),
<li> s set of relevant PubMed IDs,
<li> <b>Detailed Notes</b>,
<li> <b>Categories</b> used to group the subsystems,
<li> <b>Functional Roles</b> that make up the subsystem, and
<li><b>the functions of a set of proteins (that, hopefully, cover the roles)</b>.
</ul>
<br>
The way the tool works is intended to be quite simple.  You can incrementally fill in the
data you wish to provide to the annotator, updating the display if you find that you need to add
more functional roles, add protein functions, or expand your notes.
You would not have to refresh the screen at all, except for three considerations:
<ol>
<li>We provide a small fixed number of places for you to fill in
functional roles and their abbreviations.  If you use them all, you
can click on <b>Update Display</b> and you should see more empty spots
to be filled in (while preserving everything that you had already
entered).
<li>A similar comment applies to running out of spots to add
characterized proteins/genes.  It is important that you give a
representative set of proteins corresponding to each role in the
requested subsystem.  This will help the annotators select genomes for
the subsystem, to locate other genes encoding proteins that play the
role, and so forth.

<li>The third reason relates to your specifying a set of PubMed IDs.
If you do, and then you update the display, you should see titles and
authors for the articles in the <b>Notes</b> field.  It would be a
good idea for you to summarize what is important about the paper.
Sometimes people paste in the abstract (which you would access via
NCBI in another browser window).
</ol>
<p>
You spend some time filling in the fields, and once you have them the
way you want, you click on <b>Save Request</b> and you are done.
<br>
Now we give some minimal guidelines on how to fill in the individual fields.

<h2> The Name of the Requested Subsystem </h2>
We will queue your request and build the named subsystem as quickly as we can.  If your name
conflicts with existing subsystems, it will either be changed or (more likely), the annotator
will enhance the existing subsystem.
<h2> A short description </h2>
This should be just a few sentences or a paragraph giving the motivation for building the subsystem.
Save the detailed comments for the <b>Notes</b> section.
<h2>PubMed IDs</h2>

The set of relevant journal articles is clearly one of the most valuable pieces of information 
you can provide.  Please put some thought into this.  The program will extract strings of digits as the
IDs, so you can just give the pubmed numbers separated by spaces or commas.

<h2> Notes</h2>
This section is where you can (and should) expand upon your motivation for requesting the subsystem.
Attach abstracts, insights, and any other information that might be helpful to the annotator who will
build the subsystem.

<h2> "Major Category" and "Category"</h2>

We organize subsystems into a 2-level hierarchy of labels that have "evolved".  
You can select entries from the provided scrolling lists, or you can paste in new categories as you see fit.

<h2> Roles</h2>

You specify a set of <b>roles</b> to be included in the subsystem.  Along with each role you need to
give an <b>abbreviation</b> that will be used as a column header in the subsystem spreadsheet.
You are given room for a relatively small set of functional roles.  If you need more, fill out the initial set
and hit <b>Update Display</b>.  This should preserve everything you have already entered and extend the list
of roles with some extra blasn entries.

<h2>Proteins</h2>

The key to constructing the initial spreadsheet for trhe subsystem will be to fill in
rows for at least a few genomes for which you are confident of the gene functions.  By
specifying the precise functions of a representative set of proteins, you will allow the annotator
to infer the relevant genomes and fill in the initial rows of the spreadsheet for you.
It is critical that the functions you assert for the proteins correspond to the values you
give for the "roles" character-for-character.  If a protein performs two functions <b>F1</b> and <b>F2</b>,
then you need to use one of the following functions:
<ol>
<li>
<b>F1 / F2</b> is used to mean "the protein implements F1 and F2 using distinct domains (i.e., you have
two functions fused in the protein)".
<li>
<b>F1 @ F2</b> is used to mean "the protein implements F1 and F2 due to broad specificity of the relevant domains".
</ol>

These comments can be generalized to three or more functions (e.g., <b>F1 / F2 / F3</b>).  Make
sure that you leave  single space on each side of the separator (i.e., the "/" or the "@").
<br><br>
It is critical that you give protein IDs in a format we recognize.  We strongly suggest that you
use
<ul>
<li> FIG ids (e.g., <b>fig|83333.1.peg.4</b>).  To see these IDs, you need to visit the PubSEED
(http://pubseed.theseed.org/seedviewer.cgi).
<li> GI numbers (e.g., <b>gi|135813</b>). Note that "GI:135813" probably won't work.
<lt>UniProt IDs (e.g., <b>sp|P00934</b> or <b>tr|B1XBC9</b>)
</ul>
<br>
To get a sense of what works, look at the aliases displayed on the "protein page" in the
PubSEED (you need to be reasonably familiar with the PubSEED to put together these subsystem
requests).


<h2> Refreshing the Display or Requesting that Your Request be Queued</h2>

At the bottom of the form, you can click either <b>Update Display</b> or <b>Save Request</b>. 
Clicking on the first choice will refresh the screen, adding room for more roles and proteins, if needed.
Clicking the <b>Save Request</b> actually queues your request.

<br><br>
End_Help

    return $help;
}


sub cat2 {
    return [ sort { (lc $a cmp lc $b) } (

'ABC transporters',
'ATP synthases',
'Acid stress',
'Adhesion',
'Alanine, serine, and glycine',
'Aminosugars',
'Anaerobic degradation of aromatic compounds',
'Arabinose',
'Arginine; urea cycle, polyamines',
'Aromatic amino acids and derivatives',
'Bacterial cytostatics, differentiation factors and antibiotics',
'Bacteriocins, ribosomally synthesized antibacterial peptides',
'Bacteriophage integration/excision/lysogeny',
'Bacteriophage structural proteins',
'Biologically active compounds in metazoan cell defence and differentiation',
'Biosynthesis of phenylpropanoids',
'Biotin',
'Branched-chain amino acids',
'CO2 fixation',
'CRISPs',
'Capsular and extracellular polysacchrides',
'Cell wall of Mycobacteria',
'Central carbohydrate metabolism',
'Coenzyme A',
'Coenzyme B',
'Coenzyme F420',
'Coenzyme M',
'Cold shock',
'DNA recombination',
'DNA repair',
'DNA replication',
'DNA uptake, competence',
'Dessication stress',
'Detection',
'Detoxification',
'Di- and oligosaccharides',
'Electron accepting reactions',
'Electron donating reactions',
'Electron transport and photophosphorylation',
'Experimental',
'Fatty acids',
'Fe-S clusters',
'Fermentation',
'Fimbriae of the Chaperone/Usher Assembly Pathway',
'Flagellar motility in Prokaryota',
'Folate and pterines',
'Glutamine, glutamate, aspartate, asparagine; ammonia assimilation',
'Glycoside hydrolases',
'Gram-Negative cell wall components',
'Gram-Positive cell wall components',
'Heat shock',
'Histidine Metabolism',
'Inorganic sulfur assimilation',
'Invasion and intracellular resistance',
'Isoprenoids',
'Light-harvesting complexes',
'Lipid-derived mediators',
'Lipoic acid',
'Lysine, threonine, methionine, and cysteine',
'Metabolism of central aromatic intermediates',
'Monosaccharides',
'NAD and NADP',
'One-carbon Metabolism',
'Organic acids',
'Organic sulfur assimilation',
'Osmotic stress',
'Oxidative stress',
'Pathogenicity islands',
'Peripheral pathways for catabolism of aromatic compounds',
'Periplasmic Stress',
'Phage Host Interactions',
'Phage family-specific subsystems',
'Phages, Prophages',
'Phospholipids',
'Plant Alkaloids',
'Plant Hormones',
'Plant Octadecanoids',
'Plant-Prokaryote DOE project',
'Plasmid related functions',
'Plasmid replication',
'Polysaccharides',
'Programmed Cell Death and Toxin-antitoxin Systems',
'Proline and 4-hydroxyproline',
'Protein and nucleoprotein secretion system, Type IV',
'Protein biosynthesis',
'Protein degradation',
'Protein folding',
'Protein processing and modification',
'Protein secretion system, Type II',
'Protein secretion system, Type III',
'Protein secretion system, Type VI',
'Protein secretion system, Type VII (Chaperone/Usher pathway, CU)',
'Protein secretion system, Type VIII (Extracellular nucleation/precipitation pathway, ENP)',
'Protein translocation across cytoplasmic membrane',
'Proteolytic pathway',
'Purines',
'Pyridoxine',
'Pyrimidines',
'Quinone cofactors',
'Quorum sensing and biofilm formation',
'RNA processing and modification',
'Regulation of virulence',
'Resistance to antibiotics and toxic compounds',
'Reverse electron transport',
'Riboflavin, FMN, FAD',
'Secretion',
'Selenoproteins',
'Siderophores',
'Signal transduction in Eukaryotes',
'Social motility and nonflagellar swimming in bacteria',
'Sodium Ion-Coupled Energetics',
'Spore DNA protection',
'Sugar Phosphotransferase Systems, PTS',
'Sugar alcohols',
'Superinfection Exclusion',
'TRAP transporters',
'Tetrapyrroles',
'Toxins and superantigens',
'Transcription',
'Transposable elements',
'Triacylglycerols',
'Type III, Type IV, Type VI, ESAT secretion systems',
'Uni- Sym- and Antiporters'
	   ) ];
}

sub cat1 {
    return [sort { (lc $a cmp lc $b) } (

'Tartronate-semialdehyde related area (links to pyridoxine and aldorate metabolism)',
'Amino Acids and Derivatives',
'Biosynthesis of galactoglycans and related lipopolysacharides',
'CRISPRs and associated hypotheticals',
'Carbohydrates',
'Carotenoid biosynthesis',
'Catabolism of an unknown compound',
'Cell Division',
'Cell Division and Cell Cycle',
'Cell Wall and Capsule',
'Chemotaxis, response regulators',
'Choline bitartrate degradation, putative',
'Chromosome Replication',
'Clustering-based subsystems',
'Cofactors, Vitamins, Prosthetic Groups, Pigments',
'Cytochrome biogenesis',
'DNA Metabolism',
'DNA metabolism',
'Degradation of Polyphenols',
'Dormancy and Sporulation',
'Drug resistance or antibiotic biosynthesis related cluster',
'Fatty Acids, Lipids, and Isoprenoids',
'Fatty acid metabolic cluster',
'Iron acquisition and metabolism',
'Isoprenoid/cell wall biosynthesis',
'Lysine Biosynthesis',
'M14 metallocarboxypeptidases',
'Membrane Transport',
'Membrane-bound hydrogenase',
'Metabolism of Aromatic Compounds',
'Methanol oxidation',
'Methylamine utilization',
'Miscellaneous',
'Molybdopterin oxidoreductase',
'Motility and Chemotaxis',
'Mycocerosic acid and related Polyketides biosynthesis clusters',
'Nitrogen Metabolism',
'Nucleosides and Nucleotides',
'Phages, Prophages, Transposable elements',
'Phages, Prophages, Transposable elements, Plasmids',
'Phage-related, replication',
'Phosphate metabolism',
'Phosphorus Metabolism',
'Photosynthesis',
'Pigment biosynthesis',
'Plasmids',
'Potassium metabolism',
'Prophage',
'Proteasome related clusters',
'Protein Metabolism',
'Protein export',
'RNA Metabolism',
'Regulation and Cell signaling',
'Related to Menaquinone-cytochrome C reductase ',
'Related to ribose or hydroxymethylpyrimidine metabolism',
'Respiration',
'Ribosome-related cluster',
'Sarcosine oxidase',
'Secondary Metabolism',
'Shiga toxin cluster',
'Stress Response',
'Sulfatases and sulfatase modifying factors',
'Sulfur Metabolism',
'Translation',
'Tricarboxilate (malonate, propionate) transport',
'Tricarboxylate transporter',
'Type III secretion system related',
'Urate degradation',
'Virulence, Disease and Defense',
'metabolism of linear and branched-chain alkanes, nitroalkanes and may be cyclic ketones, alkenoic acids',
'pH adaptation potassium efflux',
'proteosome related',
'tRNA sulfuration'
	   ) ];
}

1;

