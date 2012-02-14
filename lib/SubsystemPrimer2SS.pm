
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
package SubsystemPrimer2SS;
use FIG_Config;
use Data::Dumper;
use strict;

sub page {
    my($cgi,$user) = @_;

    my $html = [];
    push(@$html,"<TITLE>Convert Request to a Subsystem</TITLE>\n");

    if ($cgi->param('Build'))
    {
	&create_ss($cgi,$html,$user);
    }
    else
    {
	&disp_state($cgi,$html);
    }
    return $html;
}

sub disp_state {
    my($cgi,$html) = @_;

    push(@$html,$cgi->start_form(-action => "ssp2ss.cgi"));
    push(@$html,&display_requests($cgi));
    push(@$html,$cgi->submit('Build'));
    push(@$html,$cgi->end_form);
}

sub display_requests {
    my($cgi) = @_;

    my @html;
    my $sspD = $FIG_Config::ssp_dir;
    if ($sspD eq '')
    {
	$sspD = "$FIG_Config::temp/ssp";
    }
    opendir(SSP,$sspD) || die "could not open $sspD";
    my @reqs = sort { $a <=> $b } grep { $_ =~ /^\d+$/ } readdir(SSP);
    if (@reqs == 0)
    {
	push(@html,$cgi->h1("We have no requests queued in $sspD"));
    }
    else
    {
	my @req_radio_group = $cgi->radio_group( -name      => 'which', 
						 -default   => $reqs[0],
						 -override  => 1,
						 -values    => \@reqs
					       );
	my $tab      = [];
	my $col_hdrs = ['','User','Title','Roles'];
        my $i;
	for ($i=0; ($i < @reqs); $i++)
	{
	    my $req = $reqs[$i];
	    my $radio = $req_radio_group[$i];

	    $/ = "\n//\n";
	    my $roles = [];
	    my $proteins = [];
	    my $title = '';
	    my $user  = '';
	    foreach $_ (`cat $sspD/$req`)
	    {
		chomp;
		if ($_ =~ /^(\S+)\n(.*)/s)
		{
		    if    ($1 eq 'title')    { $title = $2 }
		    elsif ($1 eq 'user')     { $user  = $2 }
		    elsif ($1 eq 'role')     { push(@$roles,$2) }
		    elsif ($1 eq 'protein')  { push(@$proteins,$2) }
		}
	    }
	    $/ = "\n";
	    if ($title && $user && (@$roles > 0) && (@$proteins > 0))
	    {
		push(@$tab,[$radio,$user,$title,join("<br>",@$roles)]);
	    }
	    else
	    {
#		print &Dumper($req,$title,$user,$roles,$proteins);
	    }
	}
	push(@html,&HTML::make_table($col_hdrs,$tab,'Requests'));
    }
    return @html;
}

sub create_ss {
    my($cgi,$html,$user) = @_;

    my $req = $cgi->param('which');
    my $sspD = $FIG_Config::ssp_dir;
    if ($sspD eq '')
    {
	$sspD = "$FIG_Config::temp/ssp";
    }
    if ($req && (-s "$sspD/$req"))
    {
	if (my $title = &build_ss("$sspD/$req",$user))
	{
	    push(@$html,$cgi->h1("Successfully built subsystem $title"));
	}
	else
	{
	    push(@$html,$cgi->h1("Failed to build subsystem"));
	}
    }
    else
    {
	push(@$html,$cgi->h1("Failed to build subsystem"));
    }
}

use Subsystem;
use FIG;

sub build_ss {
    my($file,$user) = @_;

    my $reqH = {};
    my @roles;
    my @proteins;
    open(REQ,"<",$file) || die "could not open $file";
    $/ = "\n//\n";
    while (defined($_ = <REQ>))
    {
	chomp;
	if ($_ =~ /^(\S+)\n(.*)/s)
	{
	    my($k,$v) = ($1,$2);
	    if ($k eq 'role')
	    {
		my($abbrev,$role) = split(/::/,$v);
		push(@roles,[$role,$abbrev]);
	    }
	    elsif ($k eq 'protein')
	    {
		my($id,$func) = split(/::/,$v);
		push(@proteins,[$id,$func]);
	    }
	    else
	    {
		$reqH->{$k} = $v;
	    }
	}
    }
    close(REQ);
    $/ = "\n";
    @roles = sort { $a->[0] cmp $b->[0] } @roles;
    my $fig = new FIG;
    my $subsys = new Subsystem($reqH->{title},$fig,1);
    $subsys->set_curator($user);
    $subsys->set_notes($reqH->{notes});
    $subsys->set_description($reqH->{desc});
    $subsys->set_roles(\@roles);
    my $spreadsheet = &generate_spreadsheet($fig,\@proteins,\@roles);
    foreach my $genome (keys(%$spreadsheet))
    {
	my $gindex = $subsys->add_genome($genome);
	my $roles_for_genome = $spreadsheet->{$genome};
	foreach my $role (keys(%$roles_for_genome))
	{
	    my $pegs = $spreadsheet->{$genome}->{$role};
	    $subsys->set_pegs_in_cell($genome,$role,$pegs);
	}
	
	my $variant_code = (@roles == keys(%$roles_for_genome)) ? 1 : 0;
	$subsys->set_variant_code($gindex,$variant_code);
    }
			    
    $subsys->write_subsystem;
    system "$FIG_Config::bin/index_subsystems $reqH->{title}";
    return $reqH->{title};

}
sub generate_spreadsheet {
    my($fig,$proteins,$roles) = @_;

    my %roleH = map { $_->[0] => $_->[1] } @$roles;  # Role => Abbrev
    my @extended_set_of_proteins = &get_all_with_same_md5($fig,$proteins);
    my $spreadsheet = {};
    foreach my $tuple (@extended_set_of_proteins)
    {
	my($peg,$func) = @$tuple;
	my $g = &SeedUtils::genome_of($peg);
	foreach my $r (&SeedUtils::roles_of_function($func))
	{
	    if ($roleH{$r})
	    {
		push(@{$spreadsheet->{$g}->{$r}},$peg);
	    }
	}
    }
    return $spreadsheet;
}
	
sub get_all_with_same_md5 {
    my($fig,$proteins) = @_;

    my %func_of;
    foreach my $tuple (@$proteins)
    {
	my($id,$func) = @$tuple;
	my @pegs = &id_to_pegs($fig,$id);
	foreach my $peg (@pegs)
	{
	    $func_of{$peg} = $func;
	}
    }
    return sort { &SeedUtils::by_fig_id($a->[0],$b->[0]) } 
           map { [$_,$func_of{$_}] } keys(%func_of);
}

sub id_to_pegs {
    my($fig,$id) = @_;
    my @tmp = $fig->by_all_aliases($id);
    my @pegs = ();
    if (@tmp > 0)
    {
	my $md5 = $fig->md5_of_peg($tmp[0]);
	@pegs = $fig->pegs_with_md5($md5);
    }
#    print &Dumper($id,\@pegs);
    return @pegs;
}

1;
