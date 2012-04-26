package Bio::KBase::GenomeAnnotation::GenomeAnnotationImpl;
use strict;
use Bio::KBase::Exceptions;

=head1 NAME

GenomeAnnotation

=head1 DESCRIPTION



=cut

#BEGIN_HEADER

use ANNOserver;
use Bio::KBase::IDServer::Client;
use Data::Dumper;
use gjoseqlib;

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 annotate_genome

  $return = $obj->annotate_genome($genome)

=over 4

=item Parameter and return types

=begin html

<pre>
$genome is a genome
$return is a genome
genome is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genome is a genome
$return is a genome
genome is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description

Given a genome object populated with contig data, perform gene calling
and functional annotation and return the annotated genome.

=back

=cut

sub annotate_genome
{
    my $self = shift;
    my($genome) = @_;

    my @_bad_arguments;
    (ref($genome) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genome\" (value was \"$genome\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to annotate_genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_genome');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN annotate_genome

    my $anno = ANNOserver->new();

    #
    # Reformat the contigs for use with the ANNOserver.
    #
    my @contigs;
    foreach my $gctg (@{$genome->{contigs}})
    {
	push(@contigs, [$gctg->{id}, undef, $gctg->{dna}]);
    }

    #
    # Call genes.
    #
    print STDERR "Call genes...\n";
    my $peg_calls = $anno->call_genes(-input => \@contigs, -geneticCode => $genome->{genetic_code});
    print STDERR "Call genes...done\n";


    #
    # Call RNAs
    #
    my($genus, $species, $strain) = split(/\s+/, $genome->{scientific_name}, 3);
    print STDERR "Call rnas '$genus' '$species' '$strain' '$genome->{domain}'...\n";
    my $rna_calls = $anno->find_rnas(-input => \@contigs, -genus => $genus, -species => $species,
				     -domain => $genome->{domain});
    print STDERR "Call rnas...done\n";

    my($fasta_rna, $rna_locations) = @$rna_calls;

    my %feature_loc;
    my %feature_func;
    my %feature_anno;
    
    for my $ent (@$rna_locations)
    {
	my($loc_id, $contig, $start, $stop, $func) = @$ent;
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	$feature_loc{$loc_id} = [$contig, $start, $strand, $len];
	$feature_func{$loc_id} = $func if $func;
    }

    my($fasta_proteins, $protein_locations) = @$peg_calls;

    my $features = $genome->{features};
    if (!$features)
    {
	$features = [];
	$genome->{features} = $features;
    }

    #
    # Assign functions for proteins.
    #

    my $prot_fh;
    open($prot_fh, "<", \$fasta_proteins) or die "Cannot open the fasta string as a filehandle: $!";
    my $handle = $anno->assign_function_to_prot(-input => $prot_fh,
						-kmer => 8,
						-scoreThreshold => 3,
						-seqHitThreshold => 3);
    while (my $res = $handle->get_next())
    {
	my($id, $function, $otu, $score, $nonoverlap_hits, $overlap_hits, $details, $fam) = @$res;
	$feature_func{$id} = $function;
	$feature_anno{$id} = "Assigned by assign_function_to_prot with otu=$otu score=$score nonoverlap=$nonoverlap_hits hits=$overlap_hits figfam=$fam";
    }
    close($prot_fh);
    
    for my $ent (@$protein_locations)
    {
	my($loc_id, $contig, $start, $stop) = @$ent;
	my $len = abs($stop - $start) + 1;
	my $strand = ($stop > $start) ? '+' : '-';
	$feature_loc{$loc_id} = [$contig, $start, $strand, $len];
    }

    my $id_server = Bio::KBase::IDServer::Client->new('http://bio-data-1.mcs.anl.gov/services/idserver');

    #
    # Create features for PEGs
    #
    my $n_pegs = @$protein_locations;
    my $protein_prefix = "$genome->{id}.peg";
    my $peg_id_start = $id_server->allocate_id_range($protein_prefix, $n_pegs);

    open($prot_fh, "<", \$fasta_proteins) or die "Cannot open the fasta string as a filehandle: $!";
    my $next_id = $peg_id_start;
    while (my($id, $def, $seq) = read_next_fasta_seq($prot_fh))
    {
	my $loc = $feature_loc{$id};
	my $kb_id = "$protein_prefix.$next_id";
	$next_id++;
	my $annos = [];
	push(@$annos, ['Initial gene call performed by call_genes', 'genome annotation service', time]);
	if ($feature_anno{$id})
	{
	    push(@$annos, [$feature_anno{$id}, 'genome annotation service', time]);
	}
	my $feature = {
	    id => $kb_id,
	    location => [$loc],
	    type => 'peg',
	    protein_translation => $seq,
	    aliases => [],
	    $feature_func{$id} ? (function => $feature_func{$id}) : (),
	    annotations => $annos,
	};
	push(@$features, $feature);
    }
    close($prot_fh);

    #
    # Create features for RNAs
    #
    my $n_rnas = @$rna_locations;
    my $rna_prefix = "$genome->{id}.rna";
    my $rna_id_start = $id_server->allocate_id_range($rna_prefix, $n_rnas);
    print STDERR "allocated id start $rna_id_start for $n_rnas nras\n";

    my $rna_fh;
    open($rna_fh, "<", \$fasta_rna) or die "Cannot open the fasta string as a filehandle: $!";
    $next_id = $rna_id_start;
    while (my($id, $def, $seq) = read_next_fasta_seq($rna_fh))
    {
	my $loc = $feature_loc{$id};
	my $kb_id = "$rna_prefix.$next_id";
	$next_id++;
	my $feature = {
	    id => $kb_id,
	    location => [$loc],
	    feature_type => 'rna',
	    $feature_func{$id} ? (function => $feature_func{$id}) : (),
	    aliases => [],
	    annotations => [ ['Initial RNA call performed by find_rnas', 'genome annotation service', time] ],
	};
	push(@$features, $feature);
    }

    $return = $genome;
    
    #END annotate_genome
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to annotate_genome:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_genome');
    }
    return($return);
}




=head2 annotate_proteins

  $return = $obj->annotate_proteins($genome)

=over 4

=item Parameter and return types

=begin html

<pre>
$genome is a genome
$return is a genome
genome is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int

</pre>

=end html

=begin text

$genome is a genome
$return is a genome
genome is a reference to a hash where the following keys are defined:
	id has a value which is a genome_id
	scientific_name has a value which is a string
	domain has a value which is a string
	genetic_code has a value which is an int
	source has a value which is a string
	source_id has a value which is a string
	contigs has a value which is a reference to a list where each element is a contig
	features has a value which is a reference to a list where each element is a feature
genome_id is a string
contig is a reference to a hash where the following keys are defined:
	id has a value which is a contig_id
	dna has a value which is a string
contig_id is a string
feature is a reference to a hash where the following keys are defined:
	id has a value which is a feature_id
	location has a value which is a location
	type has a value which is a feature_type
	function has a value which is a string
	protein_translation has a value which is a string
	aliases has a value which is a reference to a list where each element is a string
	annotations has a value which is a reference to a list where each element is an annotation
feature_id is a string
location is a reference to a list where each element is a region_of_dna
region_of_dna is a reference to a list containing 4 items:
	0: a contig_id
	1: an int
	2: a string
	3: an int
feature_type is a string
annotation is a reference to a list containing 3 items:
	0: a string
	1: a string
	2: an int


=end text



=item Description

Given a genome object populated with feature data, reannotate
the features that have protein translations. Return the updated
genome object.

=back

=cut

sub annotate_proteins
{
    my $self = shift;
    my($genome) = @_;

    my @_bad_arguments;
    (ref($genome) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"genome\" (value was \"$genome\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to annotate_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_proteins');
    }

    my $ctx = $Bio::KBase::GenomeAnnotation::Service::CallContext;
    my($return);
    #BEGIN annotate_proteins
    #END annotate_proteins
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to annotate_proteins:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'annotate_proteins');
    }
    return($return);
}




=head1 TYPES



=head2 genome_id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 feature_id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 contig_id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 feature_type

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 region_of_dna

=over 4



=item Description

A region of DNA is maintained as a tuple of four components:

                the contig
                the beginning position (from 1)
                the strand
                the length

           We often speak of "a region".  By "location", we mean a sequence
           of regions from the same genome (perhaps from distinct contigs).


=item Definition

=begin html

<pre>
a reference to a list containing 4 items:
0: a contig_id
1: an int
2: a string
3: an int

</pre>

=end html

=begin text

a reference to a list containing 4 items:
0: a contig_id
1: an int
2: a string
3: an int


=end text

=back



=head2 location

=over 4



=item Description

a "location" refers to a sequence of regions


=item Definition

=begin html

<pre>
a reference to a list where each element is a region_of_dna
</pre>

=end html

=begin text

a reference to a list where each element is a region_of_dna

=end text

=back



=head2 annotation

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: a string
1: a string
2: an int

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: a string
1: a string
2: an int


=end text

=back



=head2 feature

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a feature_id
location has a value which is a location
type has a value which is a feature_type
function has a value which is a string
protein_translation has a value which is a string
aliases has a value which is a reference to a list where each element is a string
annotations has a value which is a reference to a list where each element is an annotation

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a feature_id
location has a value which is a location
type has a value which is a feature_type
function has a value which is a string
protein_translation has a value which is a string
aliases has a value which is a reference to a list where each element is a string
annotations has a value which is a reference to a list where each element is an annotation


=end text

=back



=head2 contig

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a contig_id
dna has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a contig_id
dna has a value which is a string


=end text

=back



=head2 genome

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a genome_id
scientific_name has a value which is a string
domain has a value which is a string
genetic_code has a value which is an int
source has a value which is a string
source_id has a value which is a string
contigs has a value which is a reference to a list where each element is a contig
features has a value which is a reference to a list where each element is a feature

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a genome_id
scientific_name has a value which is a string
domain has a value which is a string
genetic_code has a value which is an int
source has a value which is a string
source_id has a value which is a string
contigs has a value which is a reference to a list where each element is a contig
features has a value which is a reference to a list where each element is a feature


=end text

=back



=cut

1;
