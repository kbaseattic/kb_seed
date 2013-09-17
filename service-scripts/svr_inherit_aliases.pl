use strict;
use Data::Dumper;
use Carp;
use gjoseqlib;

#
# This is a SAS Component
#


=head1 svr_inherit_aliases

Cause a new genome to inherit aliases from an existing
genome for protein-encoding genes that are unique within each
genome and that have identical translations.

------

Example:

    svr_inherit_aliases OldSEEDdir NewSEEDdir

would alter the contents of the NewSEEDdir.  

It would carry over any known aliases from the old version to the new version for
genes that unambiguously correspond.

------

=head2 Command-Line Options

=over 4

=item oldSEEDdir

This is a path to the old SEED directory from which aliases
are inherited

=item newSEEDdir

This is a path to the new SEED directory which inherits aliases

=back

=cut

my $usage = "usage: svr_inherit_aliases oldSEEDdir newSEEDdir";

my($oldD,$newD);

(($oldD = shift @ARGV) && (-d $oldD)) || die "$usage";
(($newD = shift @ARGV) && (-d $newD)) || die "$usage";

&verify_exists("$oldD/Features/peg/fasta");
&verify_exists("$newD/Features/peg/fasta");
&verify_exists("$oldD/Features/peg/tbl");
&verify_exists("$newD/Features/peg/tbl");

my $corrH = &get_correspondence("$oldD/Features/peg/fasta", "$newD/Features/peg/fasta");
# die Dumper($corrH);

&update_aliases($oldD,$newD);

exit(0);



sub update_aliases {
    my($oldD,$newD) = @_;

    my $aliases = {};
    my $oldA = &load_aliases($oldD);
    rename("$newD/Features/peg/tbl","$newD/Features/peg/tbl~") || die "could not backup";
    open(BEFORE,"<$newD/Features/peg/tbl~") || die "could not open backup";
    open(AFTER,">$newD/Features/peg/tbl") || die "could not open tbl";
    while (defined(my $entry = <BEFORE>))
    {
	chomp $entry;
	my ($peg, $loc, @aliases) = split(/\t/, $entry);
	
	my @merged = @aliases;
	if (defined(my $old_peg = $corrH->{$peg})) {
#	    print STDOUT "$peg ==> $old_peg\n";
	    if (defined($oldA->{$old_peg})) {
		my %a = map { $_ => 1 } (@aliases, (@ { $oldA->{$old_peg} }));
		@merged = sort keys %a;
#		print STDOUT (join(qq($_, ), @aliases), qq(\n\n));
#		print STDOUT (join(qq($_, ), @merged), qq(\n\n));
	    }
	}
	print AFTER (join("\t", ($peg, $loc, @merged)), "\n");
    }
    close(BEFORE);
    close(AFTER);
}

sub load_aliases {
    my($dir) = @_;

    my $aliases = {};
    
    if (open(TBL,"<$dir/Features/peg/tbl"))
    {
	while (defined($_ = <TBL>))
	{
	    if ($_ =~ /^(\S+)\t\S+\t(\S.*\S)$/)
	    {
		my $peg = $1;
		$aliases->{$peg} = [split(/\t/,$2)];
	    }
	}
    }
    return $aliases;
}

sub get_correspondence {
    my($oldF,$newF) = @_;

    my %old;
    my @old = &gjoseqlib::read_fasta($oldF);
    foreach $_ (@old)
    {
	push @ { $old{$_->[2]} }, $_->[0];
    }
    
    my %new;
    my @new = &gjoseqlib::read_fasta($newF);
    foreach $_ (@new)
    {
	push @ { $new{$_->[2]} }, $_->[0];
    }
    
    my $corrH = {};
    foreach my $seqN (keys(%new))
    {
	my $old_fids_for_seq = $old{$seqN};
	my $new_fids_for_seq = $new{$seqN};
	if (defined($old_fids_for_seq) && defined($new_fids_for_seq) && 
	    (@$old_fids_for_seq == 1)  &&  (@$new_fids_for_seq == 1)
	    ) {
	    $corrH->{$new_fids_for_seq->[0]} = $old_fids_for_seq->[0];
	}
    }
    return $corrH;
}

sub verify_exists {
    my($file) = @_;

    if (! -s $file)
    {
	die "$file either does not exist or is empty";
    }
}

sub run {
    my($cmd) = @_;

    my $rc = system($cmd);
    if ($rc)
    {
	die "$rc: $cmd failed";
    }
}
