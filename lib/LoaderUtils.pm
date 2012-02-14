#!/usr/bin/perl -w

package LoaderUtils;

    use strict;
    use Tracer;
    use SeedUtils;

=head1 Common DB Load Utilities

=head2 Introduction

This package contains static methods used by both the Sprout and Sapling loaders.

=head2 Public Methods

=head3 ReadAliasFile

    my $aliasHash = LoaderUtils::ReadAliasFile($dir, $genomeID);

This method reads the content of the alias file for the specified genome,
and returns a hash. For each feature, the hash contains a list of its
aliases. Each alias is represented by a 3-tuple consisting of the actual
alias, the alias type (e.g. C<CMR>, C<NCBI>), and the confidence code--
C<A> for a curated alias, C<B> for a non-curated feature alias, and C<C>
for a protein alias. If the alias file is not found, an error will occur.

=over 4

=item dir

Name of the directory containing the alias files.

=item genomeID

ID of the genome whose alias file is to be read.

=item RETURN

Returns a reference to a hash of feature IDs to alias lists. For each feature,
the alias list will be a reference to a list of 3-tuples. Each 3-tuple will
contain an alias ID, an alias type, and a confidence level from C<A> (highest)
to C<C> (lowest). If the alias file is not found, it will return an undefined
value.

=back

=cut

sub ReadAliasFile {
    # Get the parameters.
    my ($dir, $genomeID) = @_;
    # Declare the return variable.
    my $retVal = {};
    # Find the alias file. The alias files are created by "AliasCrunch.pl".
    my $aliasFile = "$dir/alias.$genomeID.tbl";
    if (! -f $aliasFile) {
        undef $retVal;
    } else {
        # The file exists, so open it for input.
        my $aliasH = Open(undef, "<$aliasFile");
        # Loop through the file.
        while (! eof $aliasH) {
            # Get this alias record.
            my ($aliasFid, $aliasID, $aliasType, $aliasConf) = Tracer::GetLine($aliasH);
            # Put it in the return hash.
            push @{$retVal->{$aliasFid}}, [$aliasID, $aliasType, $aliasConf];
        }
        # Close the file: we're done with it.
        close $aliasH;
        # Do a memory trace. Alias files can be pretty big.
        MemTrace("Aliases adjusted.") if T(ERDBLoadGroup => 3);
    }
    # Return the result.
    return $retVal;
}


1;