package Varations;

=head1 Notes on Variations and Observational Units

I<Observational units> are organisms (genomes) for which the DNA is
reconstructed from how it varies from that of a reference genome.
This is a common way of storing information on large, closely-related
genomes in a way that makes it easier to deduce the differences.

Consider by way of example a very small reference genome of only 6 base 
pairs. In the diagram below the position is shown above each DNA letter.

    123456
    AGCTAT

We will look at two observational units in addition to this genome, O1
and O2.

    O1: ACCTAAT
    O2: AAACTTT

For purposes of creating a good example, we align these three genomes to 
get something like the following.

        1  2345 6
     R: A--GCTA-T
    O1: A--CCTAAT
    O2: AAA-CTT-T

This arrangement gives us four variations. In each one, we show the DNA
for the reference genome followed by the DNA for observational unit 1 and
the DNA for observational unit 2. Essentially, each variation contains the
DNA for all the organisms in question in a specific, predetermined order.

=over 4

=item variation 1

Located before position 2: C<-->, C<-->, C<AA>.

=item variation 2

Located at position 2: C<G>, C<C>, C<->.

=item variation 3

Located at position 5: C<A>, C<A>, C<T>.

=item variation 4

Located before position 6: C<->, C<A>, C<->.

=back

Note that in a real example, the reference genome usually contains upwards of
tens of millions of base pairs, and the number of variations may be less than 
five percent of that, so there is a more reasonable expectation of space savings.

=cut

1;