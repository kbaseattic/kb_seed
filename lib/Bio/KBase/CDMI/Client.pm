package Bio::KBase::CDMI::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::KBase::CDMI::Client

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => Bio::KBase::CDMI::Client::RpcClient->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 $result = fids_to_annotations(fids)

This routine takes as input a list of fids.  It retrieves the existing
annotations for each fid, including the text of the annotation, who
made the annotation and when (as seconds from the epoch).

=cut

sub fids_to_annotations
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_annotations (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_annotations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_annotations');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_annotations",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_annotations',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_annotations",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_annotations',
				       );
    }
}



=head2 $result = fids_to_functions(fids)

This routine takes as input a list of fids and returns a mapping
from the fids to their assigned functions.

=cut

sub fids_to_functions
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_functions (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_functions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_functions');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_functions",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_functions',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_functions",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_functions',
				       );
    }
}



=head2 $result = fids_to_literature(fids)

We try to associate features and publications, when the publications constitute
supporting evidence of the function.  We connect a paper to a feature when
we believe that an "expert" has asserted that the function of the feature
is basically what we have associated with the feature.  Thus, we might
attach a paper reporting the crystal structure of a protein, even though
the paper is clearly not the paper responsible for the original characterization.
Our position in this matter is somewhat controversial, but we are seeking to
characterize some assertions as relatively solid, and this strategy seems to
support that goal.  Please note that we certainly wish we could also
capture original publications, and when experts can provide those
connections, we hope that they will help record the associations.

=cut

sub fids_to_literature
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_literature (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_literature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_literature');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_literature",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_literature',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_literature",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_literature',
				       );
    }
}



=head2 $result = fids_to_protein_families(fids)

Kbase supports the creation and maintence of protein families.  Each family is intended to contain a set
of isofunctional homologs.  Currently, the families are collections of translations
of features, rather than of just protein sequences (represented by md5s, for example).
fids_to_protein_families supports access to the features that have been grouped into a family.
Ideally, each feature in a family would have the same assigned function.  This is not
always true, but probably should be.

=cut

sub fids_to_protein_families
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_protein_families (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_protein_families');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_protein_families",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_protein_families',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_protein_families",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_protein_families',
				       );
    }
}



=head2 $result = fids_to_roles(fids)

Given a feature, one can get the set of roles it implements using fid_to_roles.
Remember, a protein can be multifunctional -- implementing several roles.
This can occur due to fusions or to broad specificity of substrate.

=cut

sub fids_to_roles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_roles (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_roles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_roles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_roles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_roles",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_roles',
				       );
    }
}



=head2 $result = fids_to_subsystems(fids)

fids in subsystems normally have somewhat more reliable assigned functions than
those not in subsystems.  Hence, it is common to ask "Is this protein-encoding gene
included in any subsystems?"   fids_to_subsystems can be used to see which subsystems
contain a fid (or, you can submit as input a set of fids and get the subsystems for each).

=cut

sub fids_to_subsystems
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_subsystems (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_subsystems');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_subsystems",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_subsystems',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_subsystems",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_subsystems',
				       );
    }
}



=head2 $result = fids_to_co_occurring_fids(fids)

One of the most powerful clues to function relates to conserved clusters of genes on
the chromosome (in prokaryotic genomes).  We have attempted to record pairs of genes
that tend to occur close to one another on the chromosome.  To meaningfully do this,
we need to construct similarity-based mappings between genes in distinct genomes.
We have constructed such mappings for many (but not all) genomes maintained in the
Kbase CS.  The prokaryotic geneomes in the CS are grouped into OTUs by ribosomal
RNA (genomes within a single OTU have SSU rRNA that is greater than 97% identical).
If two genes occur close to one another (i.e., corresponding genes occur close
to one another), then we assign a score, which is the number of distinct OTUs
in which such clustering is detected.  This allows one to normalize for situations
in which hundreds of corresponding genes are detected, but they all come from
very closely related genomes.

The significance of the score relates to the number of genomes in the database.
We recommend that you take the time to look at a set of scored pairs and determine
approximately what percentage appear to be actually related for a few cutoff values.

=cut

sub fids_to_co_occurring_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_co_occurring_fids (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_co_occurring_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_co_occurring_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_co_occurring_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_co_occurring_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_co_occurring_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_co_occurring_fids',
				       );
    }
}



=head2 $result = fids_to_locations(fids)

A "location" is a sequence of "regions".  A region is a contiguous set of bases
in a contig.  We work with locations in both the string form and as structures.
fids_to_locations takes as input a list of fids.  For each fid, a structured location
is returned.  The location is a list of regions; a region is given as a pointer to
a list containing

             the contig,
             the beginning base in the contig (from 1).
             the strand (+ or -), and
             the length

Note that specifying a region using these 4 values allows you to represent a single
base-pair region on either strand unambiguously (which giving begin/end pairs does
not achieve).

=cut

sub fids_to_locations
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_locations (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_locations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_locations');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_locations",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_locations',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_locations",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_locations',
				       );
    }
}



=head2 $result = locations_to_fids(region_of_dna_strings)

It is frequently the case that one wishes to look up the genes that
occur in a given region of a contig.  Location_to_fids can be used to extract
such sets of genes for each region in the input set of regions.  We define a gene
as "occuring" in a region if the location of the gene overlaps the designated region.

=cut

sub locations_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function locations_to_fids (received $n, expecting 1)");
    }
    {
	my($region_of_dna_strings) = @args;

	my @_bad_arguments;
        (ref($region_of_dna_strings) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"region_of_dna_strings\" (value was \"$region_of_dna_strings\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to locations_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'locations_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.locations_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'locations_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method locations_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'locations_to_fids',
				       );
    }
}



=head2 $result = alleles_to_bp_locs(alleles)



=cut

sub alleles_to_bp_locs
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function alleles_to_bp_locs (received $n, expecting 1)");
    }
    {
	my($alleles) = @args;

	my @_bad_arguments;
        (ref($alleles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"alleles\" (value was \"$alleles\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to alleles_to_bp_locs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'alleles_to_bp_locs');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.alleles_to_bp_locs",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'alleles_to_bp_locs',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method alleles_to_bp_locs",
					    status_line => $self->{client}->status_line,
					    method_name => 'alleles_to_bp_locs',
				       );
    }
}



=head2 $result = region_to_fids(region_of_dna)



=cut

sub region_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function region_to_fids (received $n, expecting 1)");
    }
    {
	my($region_of_dna) = @args;

	my @_bad_arguments;
        (ref($region_of_dna) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"region_of_dna\" (value was \"$region_of_dna\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to region_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'region_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.region_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'region_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method region_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'region_to_fids',
				       );
    }
}



=head2 $result = region_to_alleles(region_of_dna)



=cut

sub region_to_alleles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function region_to_alleles (received $n, expecting 1)");
    }
    {
	my($region_of_dna) = @args;

	my @_bad_arguments;
        (ref($region_of_dna) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"region_of_dna\" (value was \"$region_of_dna\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to region_to_alleles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'region_to_alleles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.region_to_alleles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'region_to_alleles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method region_to_alleles",
					    status_line => $self->{client}->status_line,
					    method_name => 'region_to_alleles',
				       );
    }
}



=head2 $result = alleles_to_traits(alleles)



=cut

sub alleles_to_traits
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function alleles_to_traits (received $n, expecting 1)");
    }
    {
	my($alleles) = @args;

	my @_bad_arguments;
        (ref($alleles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"alleles\" (value was \"$alleles\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to alleles_to_traits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'alleles_to_traits');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.alleles_to_traits",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'alleles_to_traits',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method alleles_to_traits",
					    status_line => $self->{client}->status_line,
					    method_name => 'alleles_to_traits',
				       );
    }
}



=head2 $result = traits_to_alleles(traits)



=cut

sub traits_to_alleles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function traits_to_alleles (received $n, expecting 1)");
    }
    {
	my($traits) = @args;

	my @_bad_arguments;
        (ref($traits) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"traits\" (value was \"$traits\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to traits_to_alleles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'traits_to_alleles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.traits_to_alleles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'traits_to_alleles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method traits_to_alleles",
					    status_line => $self->{client}->status_line,
					    method_name => 'traits_to_alleles',
				       );
    }
}



=head2 $result = ous_with_trait(genome, trait, measurement_type, min_value, max_value)



=cut

sub ous_with_trait
{
    my($self, @args) = @_;

    if ((my $n = @args) != 5)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function ous_with_trait (received $n, expecting 5)");
    }
    {
	my($genome, $trait, $measurement_type, $min_value, $max_value) = @args;

	my @_bad_arguments;
        (!ref($genome)) or push(@_bad_arguments, "Invalid type for argument 1 \"genome\" (value was \"$genome\")");
        (!ref($trait)) or push(@_bad_arguments, "Invalid type for argument 2 \"trait\" (value was \"$trait\")");
        (!ref($measurement_type)) or push(@_bad_arguments, "Invalid type for argument 3 \"measurement_type\" (value was \"$measurement_type\")");
        (!ref($min_value)) or push(@_bad_arguments, "Invalid type for argument 4 \"min_value\" (value was \"$min_value\")");
        (!ref($max_value)) or push(@_bad_arguments, "Invalid type for argument 5 \"max_value\" (value was \"$max_value\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to ous_with_trait:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'ous_with_trait');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.ous_with_trait",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'ous_with_trait',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method ous_with_trait",
					    status_line => $self->{client}->status_line,
					    method_name => 'ous_with_trait',
				       );
    }
}



=head2 $result = locations_to_dna_sequences(locations)

locations_to_dna_sequences takes as input a list of locations (each in the form of
a list of regions).  The routine constructs 2-tuples composed of

     [the input location,the dna string]

The returned DNA string is formed by concatenating the DNA for each of the
regions that make up the location.

=cut

sub locations_to_dna_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function locations_to_dna_sequences (received $n, expecting 1)");
    }
    {
	my($locations) = @args;

	my @_bad_arguments;
        (ref($locations) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"locations\" (value was \"$locations\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to locations_to_dna_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'locations_to_dna_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.locations_to_dna_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'locations_to_dna_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method locations_to_dna_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'locations_to_dna_sequences',
				       );
    }
}



=head2 $result = proteins_to_fids(proteins)

proteins_to_fids takes as input a list of proteins (i.e., a list of md5s) and
returns for each a set of protein-encoding fids that have the designated
sequence as their translation.  That is, for each sequence, the returned fids will
be the entire set (within Kbase) that have the sequence as a translation.

=cut

sub proteins_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function proteins_to_fids (received $n, expecting 1)");
    }
    {
	my($proteins) = @args;

	my @_bad_arguments;
        (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"proteins\" (value was \"$proteins\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to proteins_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'proteins_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.proteins_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'proteins_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method proteins_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'proteins_to_fids',
				       );
    }
}



=head2 $result = proteins_to_protein_families(proteins)

Protein families contain a set of isofunctional homologs.  proteins_to_protein_families
can be used to look up is used to get the set of protein_families containing a specified protein.
For performance reasons, you can submit a batch of proteins (i.e., a list of proteins),
and for each input protein, you get back a set (possibly empty) of protein_families.
Specific collections of families (e.g., FIGfams) usually require that a protein be in
at most one family.  However, we will be integrating protein families from a number of
sources, and so a protein can be in multiple families.

=cut

sub proteins_to_protein_families
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function proteins_to_protein_families (received $n, expecting 1)");
    }
    {
	my($proteins) = @args;

	my @_bad_arguments;
        (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"proteins\" (value was \"$proteins\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to proteins_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'proteins_to_protein_families');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.proteins_to_protein_families",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'proteins_to_protein_families',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method proteins_to_protein_families",
					    status_line => $self->{client}->status_line,
					    method_name => 'proteins_to_protein_families',
				       );
    }
}



=head2 $result = proteins_to_literature(proteins)

The routine proteins_to_literature can be used to extract the list of papers
we have associated with specific protein sequences.  The user should note that
in many cases the association of a paper with a protein sequence is not precise.
That is, the paper may actually describe a closely-related protein (that may
not yet even be in a sequenced genome).  Annotators attempt to use best
judgement when associating literature and proteins.  Publication references
include [pubmed ID,URL for the paper, title of the paper].  In some cases,
the URL and title are omitted.  In theory, we can extract them from PubMed
and we will attempt to do so.

=cut

sub proteins_to_literature
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function proteins_to_literature (received $n, expecting 1)");
    }
    {
	my($proteins) = @args;

	my @_bad_arguments;
        (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"proteins\" (value was \"$proteins\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to proteins_to_literature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'proteins_to_literature');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.proteins_to_literature",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'proteins_to_literature',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method proteins_to_literature",
					    status_line => $self->{client}->status_line,
					    method_name => 'proteins_to_literature',
				       );
    }
}



=head2 $result = proteins_to_functions(proteins)

The routine proteins_to_functions allows users to access functions associated with
specific protein sequences.  The input proteins are given as a list of MD5 values
(these MD5 values each correspond to a specific protein sequence).  For each input
MD5 value, a list of [feature-id,function] pairs is constructed and returned.
Note that there are many cases in which a single protein sequence corresponds
to the translation associated with multiple protein-encoding genes, and each may
have distinct functions (an undesirable situation, we grant).

This function allows you to access all of the functions assigned (by all annotation
groups represented in Kbase) to each of a set of sequences.

=cut

sub proteins_to_functions
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function proteins_to_functions (received $n, expecting 1)");
    }
    {
	my($proteins) = @args;

	my @_bad_arguments;
        (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"proteins\" (value was \"$proteins\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to proteins_to_functions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'proteins_to_functions');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.proteins_to_functions",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'proteins_to_functions',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method proteins_to_functions",
					    status_line => $self->{client}->status_line,
					    method_name => 'proteins_to_functions',
				       );
    }
}



=head2 $result = proteins_to_roles(proteins)

The routine proteins_to_roles allows a user to gather the set of functional
roles that are associated with specifc protein sequences.  A single protein
sequence (designated by an MD5 value) may have numerous associated functions,
since functions are treated as an attribute of the feature, and multiple
features may have precisely the same translation.  In our experience,
it is not uncommon, even for the best annotation teams, to assign
distinct functions (and, hence, functional roles) to identical
protein sequences.

For each input MD5 value, this routine gathers the set of features (fids)
that share the same sequence, collects the associated functions, expands
these into functional roles (for multi-functional proteins), and returns
the set of roles that results.

Note that, if the user wishes to see the specific features that have the
assigned fiunctional roles, they should use proteins_to_functions instead (it
returns the fids associated with each assigned function).

=cut

sub proteins_to_roles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function proteins_to_roles (received $n, expecting 1)");
    }
    {
	my($proteins) = @args;

	my @_bad_arguments;
        (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"proteins\" (value was \"$proteins\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to proteins_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'proteins_to_roles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.proteins_to_roles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'proteins_to_roles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method proteins_to_roles",
					    status_line => $self->{client}->status_line,
					    method_name => 'proteins_to_roles',
				       );
    }
}



=head2 $result = roles_to_proteins(roles)

roles_to_proteins can be used to extract the set of proteins (designated by MD5 values)
that currently are believed to implement a given role.  Note that the proteins
may be multifunctional, meaning that they may be implementing other roles, as well.

=cut

sub roles_to_proteins
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function roles_to_proteins (received $n, expecting 1)");
    }
    {
	my($roles) = @args;

	my @_bad_arguments;
        (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"roles\" (value was \"$roles\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to roles_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'roles_to_proteins');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.roles_to_proteins",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'roles_to_proteins',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method roles_to_proteins",
					    status_line => $self->{client}->status_line,
					    method_name => 'roles_to_proteins',
				       );
    }
}



=head2 $result = roles_to_subsystems(roles)

roles_to_subsystems can be used to access the set of subsystems that include
specific roles. The input is a list of roles (i.e., role descriptions), and a mapping
is returned as a hash with key role description and values composed of sets of susbsystem names.

=cut

sub roles_to_subsystems
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function roles_to_subsystems (received $n, expecting 1)");
    }
    {
	my($roles) = @args;

	my @_bad_arguments;
        (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"roles\" (value was \"$roles\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to roles_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'roles_to_subsystems');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.roles_to_subsystems",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'roles_to_subsystems',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method roles_to_subsystems",
					    status_line => $self->{client}->status_line,
					    method_name => 'roles_to_subsystems',
				       );
    }
}



=head2 $result = roles_to_protein_families(roles)

roles_to_protein_families can be used to locate the protein families containing
features that have assigned functions implying that they implement designated roles.
Note that for any input role (given as a role description), you may have a set
of distinct protein_families returned.

=cut

sub roles_to_protein_families
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function roles_to_protein_families (received $n, expecting 1)");
    }
    {
	my($roles) = @args;

	my @_bad_arguments;
        (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"roles\" (value was \"$roles\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to roles_to_protein_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'roles_to_protein_families');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.roles_to_protein_families",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'roles_to_protein_families',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method roles_to_protein_families",
					    status_line => $self->{client}->status_line,
					    method_name => 'roles_to_protein_families',
				       );
    }
}



=head2 $result = fids_to_coexpressed_fids(fids)

The routine fids_to_coexpressed_fids returns (for each input fid) a
list of features that appear to be coexpressed.  That is,
for an input fid, we determine the set of fids from the same genome that
have Pearson Correlation Coefficients (based on normalized expression data)
greater than 0.5 or less than -0.5.

=cut

sub fids_to_coexpressed_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_coexpressed_fids (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_coexpressed_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_coexpressed_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_coexpressed_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_coexpressed_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_coexpressed_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_coexpressed_fids',
				       );
    }
}



=head2 $result = protein_families_to_fids(protein_families)

protein_families_to_fids can be used to access the set of fids represented by each of
a set of protein_families.  We define protein_families as sets of fids (rather than sets
of MD5s.  This may, or may not, be a mistake.

=cut

sub protein_families_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function protein_families_to_fids (received $n, expecting 1)");
    }
    {
	my($protein_families) = @args;

	my @_bad_arguments;
        (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"protein_families\" (value was \"$protein_families\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to protein_families_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'protein_families_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.protein_families_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'protein_families_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method protein_families_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'protein_families_to_fids',
				       );
    }
}



=head2 $result = protein_families_to_proteins(protein_families)

protein_families_to_proteins can be used to access the set of proteins (i.e., the set of MD5 values)
represented by each of a set of protein_families.  We define protein_families as sets of fids (rather than sets
           of MD5s.  This may, or may not, be a mistake.

=cut

sub protein_families_to_proteins
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function protein_families_to_proteins (received $n, expecting 1)");
    }
    {
	my($protein_families) = @args;

	my @_bad_arguments;
        (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"protein_families\" (value was \"$protein_families\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to protein_families_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'protein_families_to_proteins');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.protein_families_to_proteins",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'protein_families_to_proteins',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method protein_families_to_proteins",
					    status_line => $self->{client}->status_line,
					    method_name => 'protein_families_to_proteins',
				       );
    }
}



=head2 $result = protein_families_to_functions(protein_families)

protein_families_to_functions can be used to extract the set of functions assigned to the fids
that make up the family.  Each input protein_family is mapped to a family function.

=cut

sub protein_families_to_functions
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function protein_families_to_functions (received $n, expecting 1)");
    }
    {
	my($protein_families) = @args;

	my @_bad_arguments;
        (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"protein_families\" (value was \"$protein_families\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to protein_families_to_functions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'protein_families_to_functions');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.protein_families_to_functions",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'protein_families_to_functions',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method protein_families_to_functions",
					    status_line => $self->{client}->status_line,
					    method_name => 'protein_families_to_functions',
				       );
    }
}



=head2 $result = protein_families_to_co_occurring_families(protein_families)

Since we accumulate data relating to the co-occurrence (i.e., chromosomal
clustering) of genes in prokaryotic genomes,  we can note which pairs of genes tend to co-occur.
From this data, one can compute the protein families that tend to co-occur (i.e., tend to
cluster on the chromosome).  This allows one to formulate conjectures for unclustered pairs, based
on clustered pairs from the same protein_families.

=cut

sub protein_families_to_co_occurring_families
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function protein_families_to_co_occurring_families (received $n, expecting 1)");
    }
    {
	my($protein_families) = @args;

	my @_bad_arguments;
        (ref($protein_families) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"protein_families\" (value was \"$protein_families\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to protein_families_to_co_occurring_families:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'protein_families_to_co_occurring_families');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.protein_families_to_co_occurring_families",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'protein_families_to_co_occurring_families',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method protein_families_to_co_occurring_families",
					    status_line => $self->{client}->status_line,
					    method_name => 'protein_families_to_co_occurring_families',
				       );
    }
}



=head2 $result = co_occurrence_evidence(pairs_of_fids)

co-occurence_evidence is used to retrieve the detailed pairs of genes that go into the
computation of co-occurence scores.  The scores reflect an estimate of the number of distinct OTUs that
contain an instance of a co-occuring pair.  This routine returns as evidence a list of all the pairs that
went into the computation.

The input to the computation is a list of pairs for which evidence is desired.

The returned output is a list of elements. one for each input pair.  Each output element
is a 2-tuple: the input pair and the evidence for the pair.  The evidence is a list of pairs of
fids that are believed to correspond to the input pair.

=cut

sub co_occurrence_evidence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function co_occurrence_evidence (received $n, expecting 1)");
    }
    {
	my($pairs_of_fids) = @args;

	my @_bad_arguments;
        (ref($pairs_of_fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"pairs_of_fids\" (value was \"$pairs_of_fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to co_occurrence_evidence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'co_occurrence_evidence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.co_occurrence_evidence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'co_occurrence_evidence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method co_occurrence_evidence",
					    status_line => $self->{client}->status_line,
					    method_name => 'co_occurrence_evidence',
				       );
    }
}



=head2 $result = contigs_to_sequences(contigs)

contigs_to_sequences is used to access the DNA sequence associated with each of a set
of input contigs.  It takes as input a set of contig IDs (from which the genome can be determined) and
produces a mapping from the input IDs to the returned DNA sequence in each case.

=cut

sub contigs_to_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function contigs_to_sequences (received $n, expecting 1)");
    }
    {
	my($contigs) = @args;

	my @_bad_arguments;
        (ref($contigs) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"contigs\" (value was \"$contigs\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to contigs_to_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'contigs_to_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.contigs_to_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'contigs_to_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method contigs_to_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'contigs_to_sequences',
				       );
    }
}



=head2 $result = contigs_to_lengths(contigs)

In some cases, one wishes to know just the lengths of the contigs, rather than their
actual DNA sequence (e.g., suppose that you wished to know if a gene boundary occured within
100 bp of the end of the contig).  To avoid requiring a user to access the entire DNA sequence,
we offer the ability to retrieve just the contig lengths.  Input to the routine is a list of contig IDs.
The routine returns a mapping from contig IDs to lengths

=cut

sub contigs_to_lengths
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function contigs_to_lengths (received $n, expecting 1)");
    }
    {
	my($contigs) = @args;

	my @_bad_arguments;
        (ref($contigs) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"contigs\" (value was \"$contigs\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to contigs_to_lengths:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'contigs_to_lengths');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.contigs_to_lengths",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'contigs_to_lengths',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method contigs_to_lengths",
					    status_line => $self->{client}->status_line,
					    method_name => 'contigs_to_lengths',
				       );
    }
}



=head2 $result = contigs_to_md5s(contigs)

contigs_to_md5s can be used to acquire MD5 values for each of a list of contigs.
The quickest way to determine whether two contigs are identical is to compare their
associated MD5 values, eliminating the need to retrieve the sequence of each and compare them.

The routine takes as input a list of contig IDs.  The output is a mapping
from contig ID to MD5 value.

=cut

sub contigs_to_md5s
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function contigs_to_md5s (received $n, expecting 1)");
    }
    {
	my($contigs) = @args;

	my @_bad_arguments;
        (ref($contigs) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"contigs\" (value was \"$contigs\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to contigs_to_md5s:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'contigs_to_md5s');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.contigs_to_md5s",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'contigs_to_md5s',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method contigs_to_md5s",
					    status_line => $self->{client}->status_line,
					    method_name => 'contigs_to_md5s',
				       );
    }
}



=head2 $result = md5s_to_genomes(md5s)

md5s to genomes is used to get the genomes associated with each of a list of input md5 values.

           The routine takes as input a list of MD5 values.  It constructs a mapping from each input
           MD5 value to a list of genomes that share the same MD5 value.

           The MD5 value for a genome is independent of the names of contigs and the case of the DNA sequence
           data.

=cut

sub md5s_to_genomes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function md5s_to_genomes (received $n, expecting 1)");
    }
    {
	my($md5s) = @args;

	my @_bad_arguments;
        (ref($md5s) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"md5s\" (value was \"$md5s\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to md5s_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'md5s_to_genomes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.md5s_to_genomes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'md5s_to_genomes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method md5s_to_genomes",
					    status_line => $self->{client}->status_line,
					    method_name => 'md5s_to_genomes',
				       );
    }
}



=head2 $result = genomes_to_md5s(genomes)

The routine genomes_to_md5s can be used to look up the MD5 value associated with each of
a set of genomes.  The MD5 values are computed when the genome is loaded, so this routine
just retrieves the precomputed values.

Note that the MD5 value of a genome is independent of the contig names and case of the
DNA sequences that make up the genome.

=cut

sub genomes_to_md5s
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomes_to_md5s (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomes_to_md5s:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomes_to_md5s');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.genomes_to_md5s",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomes_to_md5s',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomes_to_md5s",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomes_to_md5s',
				       );
    }
}



=head2 $result = genomes_to_contigs(genomes)

The routine genomes_to_contigs can be used to retrieve the IDs of the contigs
associated with each of a list of input genomes.  The routine constructs a mapping
from genome ID to the list of contigs included in the genome.

=cut

sub genomes_to_contigs
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomes_to_contigs (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomes_to_contigs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomes_to_contigs');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.genomes_to_contigs",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomes_to_contigs',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomes_to_contigs",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomes_to_contigs',
				       );
    }
}



=head2 $result = genomes_to_fids(genomes, types_of_fids)

genomes_to_fids bis used to get the fids included in specific genomes.  It
is often the case that you want just one or two types of fids -- hence, the
types_of_fids argument.

=cut

sub genomes_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomes_to_fids (received $n, expecting 2)");
    }
    {
	my($genomes, $types_of_fids) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        (ref($types_of_fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"types_of_fids\" (value was \"$types_of_fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomes_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomes_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.genomes_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomes_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomes_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomes_to_fids',
				       );
    }
}



=head2 $result = genomes_to_taxonomies(genomes)

The routine genomes_to_taxonomies can be used to retrieve taxonomic information for
each of a list of input genomes.  For each genome in the input list of genomes, a list of
taxonomic groups is returned.  Kbase will use the groups maintained by NCBI.  For an NCBI
taxonomic string like

     cellular organisms;
     Bacteria;
     Proteobacteria;
     Gammaproteobacteria;
     Enterobacteriales;
     Enterobacteriaceae;
     Escherichia;
     Escherichia coli

associated with the strain 'Escherichia coli 1412', this routine would return a list of these
taxonomic groups:


     ['Bacteria',
      'Proteobacteria',
      'Gammaproteobacteria',
      'Enterobacteriales',
      'Enterobacteriaceae',
      'Escherichia',
      'Escherichia coli',
      'Escherichia coli 1412'
     ]

That is, the initial "cellular organisms" has been deleted, and the strain ID has
been added as the last "grouping".

The output is a mapping from genome IDs to lists of the form shown above.

=cut

sub genomes_to_taxonomies
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomes_to_taxonomies (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomes_to_taxonomies:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomes_to_taxonomies');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.genomes_to_taxonomies",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomes_to_taxonomies',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomes_to_taxonomies",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomes_to_taxonomies',
				       );
    }
}



=head2 $result = genomes_to_subsystems(genomes)

A user can invoke genomes_to_subsystems to rerieve the names of the subsystems
relevant to each genome.  The input is a list of genomes.  The output is a mapping
from genome to a list of 2-tuples, where each 2-tuple give a variant code and a
subsystem name.  Variant codes of -1 (or *-1) amount to assertions that the
genome contains no active variant.  A variant code of 0 means "work in progress",
and presence or absence of the subsystem in the genome should be undetermined.

=cut

sub genomes_to_subsystems
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomes_to_subsystems (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomes_to_subsystems:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomes_to_subsystems');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.genomes_to_subsystems",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomes_to_subsystems',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomes_to_subsystems",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomes_to_subsystems',
				       );
    }
}



=head2 $result = subsystems_to_genomes(subsystems)

The routine subsystems_to_genomes is used to determine which genomes are in
specified subsystems.  The input is the list of subsystem names of interest.
The output is a map from the subsystem names to lists of 2-tuples, where each 2-tuple is
a [variant-code,genome ID] pair.

=cut

sub subsystems_to_genomes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function subsystems_to_genomes (received $n, expecting 1)");
    }
    {
	my($subsystems) = @args;

	my @_bad_arguments;
        (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"subsystems\" (value was \"$subsystems\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to subsystems_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'subsystems_to_genomes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.subsystems_to_genomes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'subsystems_to_genomes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method subsystems_to_genomes",
					    status_line => $self->{client}->status_line,
					    method_name => 'subsystems_to_genomes',
				       );
    }
}



=head2 $result = subsystems_to_fids(subsystems, genomes)

The routine subsystems_to_fids allows the user to map subsystem names into the fids that
occur in genomes in the subsystems.  Specifically, the input is a list of subsystem names.
What is returned is a mapping from subsystem names to a "genome-mapping".  The genome-mapping
takes genome IDs to 2-tuples that capture the variant code of the genome and the fids from
the genome that are included in the subsystem.

=cut

sub subsystems_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function subsystems_to_fids (received $n, expecting 2)");
    }
    {
	my($subsystems, $genomes) = @args;

	my @_bad_arguments;
        (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"subsystems\" (value was \"$subsystems\")");
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to subsystems_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'subsystems_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.subsystems_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'subsystems_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method subsystems_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'subsystems_to_fids',
				       );
    }
}



=head2 $result = subsystems_to_roles(subsystems, aux)

The routine subsystem_to_roles is used to determine the role descriptions that
occur in a subsystem.  The input is a list of subsystem names.  A map is returned connecting
subsystem names to lists of roles.  'aux' is a boolean variable.  If it is 0, auxiliary roles
are not returned.  If it is 1, they are returned.

=cut

sub subsystems_to_roles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function subsystems_to_roles (received $n, expecting 2)");
    }
    {
	my($subsystems, $aux) = @args;

	my @_bad_arguments;
        (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"subsystems\" (value was \"$subsystems\")");
        (!ref($aux)) or push(@_bad_arguments, "Invalid type for argument 2 \"aux\" (value was \"$aux\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to subsystems_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'subsystems_to_roles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.subsystems_to_roles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'subsystems_to_roles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method subsystems_to_roles",
					    status_line => $self->{client}->status_line,
					    method_name => 'subsystems_to_roles',
				       );
    }
}



=head2 $result = subsystems_to_spreadsheets(subsystems, genomes)

The subsystem_to_spreadsheet routine allows a user to extract the subsystem spreadsheets for
a specified set of subsystem names.  In the returned output, each subsystem is mapped
to a hash that takes as input a genome ID and maps it to the "row" for the genome in the subsystem.
The "row" is itself a 2-tuple composed of the variant code, and a mapping from role descriptions to
lists of fids.  We suggest writing a simple test script to get, say, the subsystem named
'Histidine Degradation', extracting the spreadsheet, and then using something like Dumper to make
sure that it all makes sense.

=cut

sub subsystems_to_spreadsheets
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function subsystems_to_spreadsheets (received $n, expecting 2)");
    }
    {
	my($subsystems, $genomes) = @args;

	my @_bad_arguments;
        (ref($subsystems) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"subsystems\" (value was \"$subsystems\")");
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to subsystems_to_spreadsheets:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'subsystems_to_spreadsheets');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.subsystems_to_spreadsheets",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'subsystems_to_spreadsheets',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method subsystems_to_spreadsheets",
					    status_line => $self->{client}->status_line,
					    method_name => 'subsystems_to_spreadsheets',
				       );
    }
}



=head2 $result = all_roles_used_in_models()

The all_roles_used_in_models allows a user to access the set of roles that are included in current models.  This is
important.  There are far fewer roles used in models than overall.  Hence, the returned set represents
the minimal set we need to clean up in order to properly support modeling.

=cut

sub all_roles_used_in_models
{
    my($self, @args) = @_;

    if ((my $n = @args) != 0)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_roles_used_in_models (received $n, expecting 0)");
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.all_roles_used_in_models",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_roles_used_in_models',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_roles_used_in_models",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_roles_used_in_models',
				       );
    }
}



=head2 $result = complexes_to_complex_data(complexes)



=cut

sub complexes_to_complex_data
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function complexes_to_complex_data (received $n, expecting 1)");
    }
    {
	my($complexes) = @args;

	my @_bad_arguments;
        (ref($complexes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"complexes\" (value was \"$complexes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to complexes_to_complex_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'complexes_to_complex_data');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.complexes_to_complex_data",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'complexes_to_complex_data',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method complexes_to_complex_data",
					    status_line => $self->{client}->status_line,
					    method_name => 'complexes_to_complex_data',
				       );
    }
}



=head2 $result = genomes_to_genome_data(genomes)



=cut

sub genomes_to_genome_data
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function genomes_to_genome_data (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to genomes_to_genome_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'genomes_to_genome_data');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.genomes_to_genome_data",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'genomes_to_genome_data',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method genomes_to_genome_data",
					    status_line => $self->{client}->status_line,
					    method_name => 'genomes_to_genome_data',
				       );
    }
}



=head2 $result = fids_to_regulon_data(fids)



=cut

sub fids_to_regulon_data
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_regulon_data (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_regulon_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_regulon_data');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_regulon_data",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_regulon_data',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_regulon_data",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_regulon_data',
				       );
    }
}



=head2 $result = regulons_to_fids(regulons)



=cut

sub regulons_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function regulons_to_fids (received $n, expecting 1)");
    }
    {
	my($regulons) = @args;

	my @_bad_arguments;
        (ref($regulons) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"regulons\" (value was \"$regulons\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to regulons_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'regulons_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.regulons_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'regulons_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method regulons_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'regulons_to_fids',
				       );
    }
}



=head2 $result = fids_to_feature_data(fids)



=cut

sub fids_to_feature_data
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_feature_data (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_feature_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_feature_data');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_feature_data",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_feature_data',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_feature_data",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_feature_data',
				       );
    }
}



=head2 $result = equiv_sequence_assertions(proteins)

Different groups have made assertions of function for numerous protein sequences.
The equiv_sequence_assertions allows the user to gather function assertions from
all of the sources.  Each assertion includes a field indicating whether the person making
the assertion viewed themself as an "expert".  The routine gathers assertions for all
proteins having identical protein sequence.

=cut

sub equiv_sequence_assertions
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function equiv_sequence_assertions (received $n, expecting 1)");
    }
    {
	my($proteins) = @args;

	my @_bad_arguments;
        (ref($proteins) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"proteins\" (value was \"$proteins\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to equiv_sequence_assertions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'equiv_sequence_assertions');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.equiv_sequence_assertions",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'equiv_sequence_assertions',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method equiv_sequence_assertions",
					    status_line => $self->{client}->status_line,
					    method_name => 'equiv_sequence_assertions',
				       );
    }
}



=head2 $result = fids_to_atomic_regulons(fids)

The fids_to_atomic_regulons allows one to map fids into regulons that contain the fids.
Normally a fid will be in at most one regulon, but we support multiple regulons.

=cut

sub fids_to_atomic_regulons
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_atomic_regulons (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_atomic_regulons:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_atomic_regulons');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_atomic_regulons",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_atomic_regulons',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_atomic_regulons",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_atomic_regulons',
				       );
    }
}



=head2 $result = atomic_regulons_to_fids(atomic_regulons)

The atomic_regulons_to_fids routine allows the user to access the set of fids that make up a regulon.
Regulons may arise from several sources; hence, fids can be in multiple regulons.

=cut

sub atomic_regulons_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function atomic_regulons_to_fids (received $n, expecting 1)");
    }
    {
	my($atomic_regulons) = @args;

	my @_bad_arguments;
        (ref($atomic_regulons) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"atomic_regulons\" (value was \"$atomic_regulons\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to atomic_regulons_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'atomic_regulons_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.atomic_regulons_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'atomic_regulons_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method atomic_regulons_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'atomic_regulons_to_fids',
				       );
    }
}



=head2 $result = fids_to_protein_sequences(fids)

fids_to_protein_sequences allows the user to look up the amino acid sequences
corresponding to each of a set of fids.  You can also get the sequence from proteins (i.e., md5 values).
This routine saves you having to look up the md5 sequence and then accessing
the protein string in a separate call.

=cut

sub fids_to_protein_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_protein_sequences (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_protein_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_protein_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_protein_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_protein_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_protein_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_protein_sequences',
				       );
    }
}



=head2 $result = fids_to_proteins(fids)



=cut

sub fids_to_proteins
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_proteins (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_proteins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_proteins');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_proteins",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_proteins',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_proteins",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_proteins',
				       );
    }
}



=head2 $result = fids_to_dna_sequences(fids)

fids_to_dna_sequences allows the user to look up the DNA sequences
corresponding to each of a set of fids.

=cut

sub fids_to_dna_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_dna_sequences (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_dna_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_dna_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_dna_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_dna_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_dna_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_dna_sequences',
				       );
    }
}



=head2 $result = roles_to_fids(roles, genomes)

A "function" is a set of "roles" (often called "functional roles");

                F1 / F2  (where F1 and F2 are roles)  is a function that implements
                          two functional roles in different domains of the protein.
                F1 @ F2 implements multiple roles through broad specificity
                F1; F2  is thought to implement F1 or f2 (uncertainty)

            You often wish to find the fids in one or more genomes that
            implement specific functional roles.  To do this, you can use
            roles_to_fids.

=cut

sub roles_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function roles_to_fids (received $n, expecting 2)");
    }
    {
	my($roles, $genomes) = @args;

	my @_bad_arguments;
        (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"roles\" (value was \"$roles\")");
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to roles_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'roles_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.roles_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'roles_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method roles_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'roles_to_fids',
				       );
    }
}



=head2 $result = reactions_to_complexes(reactions)

Reactions are thought of as being either spontaneous or implemented by
one or more Complexes.  Complexes connect to Roles.  Hence, the connection of fids
or roles to reactions goes through Complexes.

=cut

sub reactions_to_complexes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function reactions_to_complexes (received $n, expecting 1)");
    }
    {
	my($reactions) = @args;

	my @_bad_arguments;
        (ref($reactions) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"reactions\" (value was \"$reactions\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to reactions_to_complexes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'reactions_to_complexes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.reactions_to_complexes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'reactions_to_complexes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method reactions_to_complexes",
					    status_line => $self->{client}->status_line,
					    method_name => 'reactions_to_complexes',
				       );
    }
}



=head2 $result = aliases_to_fids(aliases)



=cut

sub aliases_to_fids
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function aliases_to_fids (received $n, expecting 1)");
    }
    {
	my($aliases) = @args;

	my @_bad_arguments;
        (ref($aliases) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"aliases\" (value was \"$aliases\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to aliases_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'aliases_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.aliases_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'aliases_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method aliases_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'aliases_to_fids',
				       );
    }
}



=head2 $result = reaction_strings(reactions, name_parameter)

Reaction_strings are text strings that represent (albeit crudely)
the details of Reactions.

=cut

sub reaction_strings
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function reaction_strings (received $n, expecting 2)");
    }
    {
	my($reactions, $name_parameter) = @args;

	my @_bad_arguments;
        (ref($reactions) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"reactions\" (value was \"$reactions\")");
        (!ref($name_parameter)) or push(@_bad_arguments, "Invalid type for argument 2 \"name_parameter\" (value was \"$name_parameter\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to reaction_strings:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'reaction_strings');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.reaction_strings",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'reaction_strings',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method reaction_strings",
					    status_line => $self->{client}->status_line,
					    method_name => 'reaction_strings',
				       );
    }
}



=head2 $result = roles_to_complexes(roles)

roles_to_complexes allows a user to connect Roles to Complexes,
from there, the connection exists to Reactions (although in the
actual ER-model model, the connection from Complex to Reaction goes through
ReactionComplex).  Since Roles also connect to fids, the connection between
fids and Reactions is induced.

The "name_parameter" can be 0, 1 or 'only'. If 1, then the compound name will 
be included with the ID in the output. If only, the compound name will be included 
instead of the ID. If 0, only the ID will be included. The default is 0.

=cut

sub roles_to_complexes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function roles_to_complexes (received $n, expecting 1)");
    }
    {
	my($roles) = @args;

	my @_bad_arguments;
        (ref($roles) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"roles\" (value was \"$roles\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to roles_to_complexes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'roles_to_complexes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.roles_to_complexes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'roles_to_complexes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method roles_to_complexes",
					    status_line => $self->{client}->status_line,
					    method_name => 'roles_to_complexes',
				       );
    }
}



=head2 $result = complexes_to_roles(complexes)



=cut

sub complexes_to_roles
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function complexes_to_roles (received $n, expecting 1)");
    }
    {
	my($complexes) = @args;

	my @_bad_arguments;
        (ref($complexes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"complexes\" (value was \"$complexes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to complexes_to_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'complexes_to_roles');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.complexes_to_roles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'complexes_to_roles',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method complexes_to_roles",
					    status_line => $self->{client}->status_line,
					    method_name => 'complexes_to_roles',
				       );
    }
}



=head2 $result = fids_to_subsystem_data(fids)



=cut

sub fids_to_subsystem_data
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_subsystem_data (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_subsystem_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_subsystem_data');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_subsystem_data",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_subsystem_data',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_subsystem_data",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_subsystem_data',
				       );
    }
}



=head2 $result = representative(genomes)



=cut

sub representative
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function representative (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to representative:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'representative');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.representative",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'representative',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method representative",
					    status_line => $self->{client}->status_line,
					    method_name => 'representative',
				       );
    }
}



=head2 $result = otu_members(genomes)



=cut

sub otu_members
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function otu_members (received $n, expecting 1)");
    }
    {
	my($genomes) = @args;

	my @_bad_arguments;
        (ref($genomes) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"genomes\" (value was \"$genomes\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to otu_members:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'otu_members');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.otu_members",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'otu_members',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method otu_members",
					    status_line => $self->{client}->status_line,
					    method_name => 'otu_members',
				       );
    }
}



=head2 $result = otus_to_representatives(otus)



=cut

sub otus_to_representatives
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function otus_to_representatives (received $n, expecting 1)");
    }
    {
	my($otus) = @args;

	my @_bad_arguments;
        (ref($otus) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"otus\" (value was \"$otus\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to otus_to_representatives:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'otus_to_representatives');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.otus_to_representatives",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'otus_to_representatives',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method otus_to_representatives",
					    status_line => $self->{client}->status_line,
					    method_name => 'otus_to_representatives',
				       );
    }
}



=head2 $result = fids_to_genomes(fids)



=cut

sub fids_to_genomes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_genomes (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_genomes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.fids_to_genomes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_genomes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_genomes",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_genomes',
				       );
    }
}



=head2 $result = text_search(input, start, count, entities)

text_search performs a search against a full-text index maintained 
for the CDMI. The parameter "input" is the text string to be searched for.
The parameter "entities" defines the entities to be searched. If the list
is empty, all indexed entities will be searched. The "start" and "count"
parameters limit the results to "count" hits starting at "start".

=cut

sub text_search
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function text_search (received $n, expecting 4)");
    }
    {
	my($input, $start, $count, $entities) = @args;

	my @_bad_arguments;
        (!ref($input)) or push(@_bad_arguments, "Invalid type for argument 1 \"input\" (value was \"$input\")");
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 2 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 3 \"count\" (value was \"$count\")");
        (ref($entities) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"entities\" (value was \"$entities\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to text_search:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'text_search');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.text_search",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'text_search',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method text_search",
					    status_line => $self->{client}->status_line,
					    method_name => 'text_search',
				       );
    }
}



=head2 $result = corresponds(fids, genome)



=cut

sub corresponds
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function corresponds (received $n, expecting 2)");
    }
    {
	my($fids, $genome) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        (!ref($genome)) or push(@_bad_arguments, "Invalid type for argument 2 \"genome\" (value was \"$genome\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to corresponds:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'corresponds');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.corresponds",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'corresponds',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method corresponds",
					    status_line => $self->{client}->status_line,
					    method_name => 'corresponds',
				       );
    }
}



=head2 $result = corresponds_from_sequences(g1_sequences, g1_locations, g2_sequences, g2_locations)



=cut

sub corresponds_from_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function corresponds_from_sequences (received $n, expecting 4)");
    }
    {
	my($g1_sequences, $g1_locations, $g2_sequences, $g2_locations) = @args;

	my @_bad_arguments;
        (ref($g1_sequences) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"g1_sequences\" (value was \"$g1_sequences\")");
        (ref($g1_locations) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"g1_locations\" (value was \"$g1_locations\")");
        (ref($g2_sequences) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"g2_sequences\" (value was \"$g2_sequences\")");
        (ref($g2_locations) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"g2_locations\" (value was \"$g2_locations\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to corresponds_from_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'corresponds_from_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.corresponds_from_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'corresponds_from_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method corresponds_from_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'corresponds_from_sequences',
				       );
    }
}



=head2 $result = close_genomes(seq_set, n)



=cut

sub close_genomes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function close_genomes (received $n, expecting 2)");
    }
    {
	my($seq_set, $n) = @args;

	my @_bad_arguments;
        (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"seq_set\" (value was \"$seq_set\")");
        (!ref($n)) or push(@_bad_arguments, "Invalid type for argument 2 \"n\" (value was \"$n\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to close_genomes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'close_genomes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.close_genomes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'close_genomes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method close_genomes",
					    status_line => $self->{client}->status_line,
					    method_name => 'close_genomes',
				       );
    }
}



=head2 $result = representative_sequences(seq_set, rep_seq_parms)

we return two arguments.  The first is the list of representative triples,
and the second is the list of sets (the first entry always being the
representative sequence)

=cut

sub representative_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function representative_sequences (received $n, expecting 2)");
    }
    {
	my($seq_set, $rep_seq_parms) = @args;

	my @_bad_arguments;
        (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"seq_set\" (value was \"$seq_set\")");
        (ref($rep_seq_parms) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 2 \"rep_seq_parms\" (value was \"$rep_seq_parms\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to representative_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'representative_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.representative_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'representative_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method representative_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'representative_sequences',
				       );
    }
}



=head2 $result = align_sequences(seq_set, align_seq_parms)



=cut

sub align_sequences
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function align_sequences (received $n, expecting 2)");
    }
    {
	my($seq_set, $align_seq_parms) = @args;

	my @_bad_arguments;
        (ref($seq_set) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"seq_set\" (value was \"$seq_set\")");
        (ref($align_seq_parms) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 2 \"align_seq_parms\" (value was \"$align_seq_parms\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to align_sequences:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'align_sequences');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.align_sequences",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'align_sequences',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method align_sequences",
					    status_line => $self->{client}->status_line,
					    method_name => 'align_sequences',
				       );
    }
}



=head2 $result = build_tree(alignment, build_tree_parms)



=cut

sub build_tree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function build_tree (received $n, expecting 2)");
    }
    {
	my($alignment, $build_tree_parms) = @args;

	my @_bad_arguments;
        (ref($alignment) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"alignment\" (value was \"$alignment\")");
        (ref($build_tree_parms) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 2 \"build_tree_parms\" (value was \"$build_tree_parms\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to build_tree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'build_tree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.build_tree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'build_tree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method build_tree",
					    status_line => $self->{client}->status_line,
					    method_name => 'build_tree',
				       );
    }
}



=head2 $result = alignment_by_id(aln_id)



=cut

sub alignment_by_id
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function alignment_by_id (received $n, expecting 1)");
    }
    {
	my($aln_id) = @args;

	my @_bad_arguments;
        (!ref($aln_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"aln_id\" (value was \"$aln_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to alignment_by_id:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'alignment_by_id');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.alignment_by_id",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'alignment_by_id',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method alignment_by_id",
					    status_line => $self->{client}->status_line,
					    method_name => 'alignment_by_id',
				       );
    }
}



=head2 $result = tree_by_id(tree_id)



=cut

sub tree_by_id
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function tree_by_id (received $n, expecting 1)");
    }
    {
	my($tree_id) = @args;

	my @_bad_arguments;
        (!ref($tree_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"tree_id\" (value was \"$tree_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to tree_by_id:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'tree_by_id');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_API.tree_by_id",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'tree_by_id',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method tree_by_id",
					    status_line => $self->{client}->status_line,
					    method_name => 'tree_by_id',
				       );
    }
}





=head2 $result = get_entity_Alignment(ids, fields)

An alignment arranges a group of sequences so that they
match. Each alignment is associated with a phylogenetic tree that
describes how the sequences developed and their evolutionary
distance.
It has the following fields:

=over 4


=item n_rows

number of rows in the alignment


=item n_cols

number of columns in the alignment


=item status

status of the alignment, currently either [i]active[/i],
[i]superseded[/i], or [i]bad[/i]


=item is_concatenation

TRUE if the rows of the alignment map to multiple
sequences, FALSE if they map to single sequences


=item sequence_type

type of sequence being aligned, currently either
[i]Protein[/i], [i]DNA[/i], [i]RNA[/i], or [i]Mixed[/i]


=item timestamp

date and time the alignment was loaded


=item method

name of the primary software package or script used
to construct the alignment


=item parameters

non-default parameters used as input to the software
package or script indicated in the method attribute


=item protocol

description of the steps taken to construct the alignment,
or a reference to an external pipeline


=item source_id

ID of this alignment in the source database



=back

=cut

sub get_entity_Alignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Alignment (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Alignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Alignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Alignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Alignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Alignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Alignment',
				       );
    }
}



=head2 $result = query_entity_Alignment(qry, fields)



=cut

sub query_entity_Alignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Alignment (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Alignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Alignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Alignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Alignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Alignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Alignment',
				       );
    }
}



=head2 $result = all_entities_Alignment(start, count, fields)



=cut

sub all_entities_Alignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Alignment (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Alignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Alignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Alignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Alignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Alignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Alignment',
				       );
    }
}



=head2 $result = get_entity_AlignmentAttribute(ids, fields)

This entity represents an attribute type that can
be assigned to an alignment. The attribute
values are stored in the relationships to the target. The
key is the attribute name.
It has the following fields:

=over 4



=back

=cut

sub get_entity_AlignmentAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_AlignmentAttribute (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_AlignmentAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_AlignmentAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_AlignmentAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_AlignmentAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_AlignmentAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_AlignmentAttribute',
				       );
    }
}



=head2 $result = query_entity_AlignmentAttribute(qry, fields)



=cut

sub query_entity_AlignmentAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_AlignmentAttribute (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_AlignmentAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_AlignmentAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_AlignmentAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_AlignmentAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_AlignmentAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_AlignmentAttribute',
				       );
    }
}



=head2 $result = all_entities_AlignmentAttribute(start, count, fields)



=cut

sub all_entities_AlignmentAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_AlignmentAttribute (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_AlignmentAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_AlignmentAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_AlignmentAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_AlignmentAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_AlignmentAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_AlignmentAttribute',
				       );
    }
}



=head2 $result = get_entity_AlignmentRow(ids, fields)

This entity represents a single row of an alignment.
In general, this corresponds to a sequence, but in a
concatenated alignment multiple sequences may be represented
here.
It has the following fields:

=over 4


=item row_number

1-based ordinal number of this row in the alignment


=item row_id

identifier for this row in the FASTA file for the alignment


=item row_description

description of this row in the FASTA file for the alignment


=item n_components

number of components that make up this alignment
row; for a single-sequence alignment this is always "1"


=item beg_pos_aln

the 1-based column index in the alignment where this
sequence row begins


=item end_pos_aln

the 1-based column index in the alignment where this
sequence row ends


=item md5_of_ungapped_sequence

the MD5 of this row's sequence after gaps have been
removed; for DNA and RNA sequences, the [b]U[/b] codes are also
normalized to [b]T[/b] before the MD5 is computed


=item sequence

sequence for this alignment row (with indels)



=back

=cut

sub get_entity_AlignmentRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_AlignmentRow (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_AlignmentRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_AlignmentRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_AlignmentRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_AlignmentRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_AlignmentRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_AlignmentRow',
				       );
    }
}



=head2 $result = query_entity_AlignmentRow(qry, fields)



=cut

sub query_entity_AlignmentRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_AlignmentRow (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_AlignmentRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_AlignmentRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_AlignmentRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_AlignmentRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_AlignmentRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_AlignmentRow',
				       );
    }
}



=head2 $result = all_entities_AlignmentRow(start, count, fields)



=cut

sub all_entities_AlignmentRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_AlignmentRow (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_AlignmentRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_AlignmentRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_AlignmentRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_AlignmentRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_AlignmentRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_AlignmentRow',
				       );
    }
}



=head2 $result = get_entity_AlleleFrequency(ids, fields)

An allele frequency represents a summary of the major and minor allele frequencies for a position on a chromosome.
It has the following fields:

=over 4


=item source_id

identifier for this allele in the original (source) database


=item position

Specific position on the contig where the allele occurs


=item minor_AF

Minor allele frequency.  Floating point number from 0.0 to 0.5.


=item minor_allele

Text letter representation of the minor allele. Valid values are A, C, G, and T.


=item major_AF

Major allele frequency.  Floating point number less than or equal to 1.0.


=item major_allele

Text letter representation of the major allele. Valid values are A, C, G, and T.


=item obs_unit_count

Number of observational units used to compute the allele frequencies. Indicates
the quality of the analysis.



=back

=cut

sub get_entity_AlleleFrequency
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_AlleleFrequency (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_AlleleFrequency:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_AlleleFrequency');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_AlleleFrequency",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_AlleleFrequency',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_AlleleFrequency",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_AlleleFrequency',
				       );
    }
}



=head2 $result = query_entity_AlleleFrequency(qry, fields)



=cut

sub query_entity_AlleleFrequency
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_AlleleFrequency (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_AlleleFrequency:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_AlleleFrequency');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_AlleleFrequency",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_AlleleFrequency',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_AlleleFrequency",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_AlleleFrequency',
				       );
    }
}



=head2 $result = all_entities_AlleleFrequency(start, count, fields)



=cut

sub all_entities_AlleleFrequency
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_AlleleFrequency (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_AlleleFrequency:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_AlleleFrequency');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_AlleleFrequency",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_AlleleFrequency',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_AlleleFrequency",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_AlleleFrequency',
				       );
    }
}



=head2 $result = get_entity_Annotation(ids, fields)

An annotation is a comment attached to a feature.
Annotations are used to track the history of a feature's
functional assignments and any related issues. The key is
the feature ID followed by a colon and a complemented ten-digit
sequence number.
It has the following fields:

=over 4


=item annotator

name of the annotator who made the comment


=item comment

text of the annotation


=item annotation_time

date and time at which the annotation was made



=back

=cut

sub get_entity_Annotation
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Annotation (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Annotation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Annotation');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Annotation",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Annotation',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Annotation",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Annotation',
				       );
    }
}



=head2 $result = query_entity_Annotation(qry, fields)



=cut

sub query_entity_Annotation
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Annotation (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Annotation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Annotation');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Annotation",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Annotation',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Annotation",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Annotation',
				       );
    }
}



=head2 $result = all_entities_Annotation(start, count, fields)



=cut

sub all_entities_Annotation
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Annotation (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Annotation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Annotation');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Annotation",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Annotation',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Annotation",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Annotation',
				       );
    }
}



=head2 $result = get_entity_Assay(ids, fields)

An assay is an experimental design for determining alleles at specific chromosome positions.
It has the following fields:

=over 4


=item source_id

identifier for this assay in the original (source) database


=item assay_type

Text description of the type of assay (e.g., SNP, length, sequence, categorical, array, short read, SSR marker, AFLP marker)


=item assay_type_id

source ID associated with the assay type (informational)



=back

=cut

sub get_entity_Assay
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Assay (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Assay:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Assay');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Assay",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Assay',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Assay",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Assay',
				       );
    }
}



=head2 $result = query_entity_Assay(qry, fields)



=cut

sub query_entity_Assay
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Assay (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Assay:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Assay');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Assay",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Assay',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Assay",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Assay',
				       );
    }
}



=head2 $result = all_entities_Assay(start, count, fields)



=cut

sub all_entities_Assay
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Assay (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Assay:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Assay');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Assay",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Assay',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Assay",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Assay',
				       );
    }
}



=head2 $result = get_entity_AtomicRegulon(ids, fields)

An atomic regulon is an indivisible group of coregulated
features on a single genome. Atomic regulons are constructed so
that a given feature can only belong to one. Because of this, the
expression levels for atomic regulons represent in some sense the
state of a cell.
It has the following fields:

=over 4



=back

=cut

sub get_entity_AtomicRegulon
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_AtomicRegulon (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_AtomicRegulon:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_AtomicRegulon');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_AtomicRegulon",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_AtomicRegulon',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_AtomicRegulon",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_AtomicRegulon',
				       );
    }
}



=head2 $result = query_entity_AtomicRegulon(qry, fields)



=cut

sub query_entity_AtomicRegulon
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_AtomicRegulon (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_AtomicRegulon:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_AtomicRegulon');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_AtomicRegulon",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_AtomicRegulon',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_AtomicRegulon",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_AtomicRegulon',
				       );
    }
}



=head2 $result = all_entities_AtomicRegulon(start, count, fields)



=cut

sub all_entities_AtomicRegulon
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_AtomicRegulon (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_AtomicRegulon:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_AtomicRegulon');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_AtomicRegulon",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_AtomicRegulon',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_AtomicRegulon",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_AtomicRegulon',
				       );
    }
}



=head2 $result = get_entity_Attribute(ids, fields)

An attribute describes a category of condition or characteristic for
an experiment. The goals of the experiment can be inferred from its values
for all the attributes of interest.
It has the following fields:

=over 4


=item description

Descriptive text indicating the nature and use of this attribute.



=back

=cut

sub get_entity_Attribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Attribute (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Attribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Attribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Attribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Attribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Attribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Attribute',
				       );
    }
}



=head2 $result = query_entity_Attribute(qry, fields)



=cut

sub query_entity_Attribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Attribute (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Attribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Attribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Attribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Attribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Attribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Attribute',
				       );
    }
}



=head2 $result = all_entities_Attribute(start, count, fields)



=cut

sub all_entities_Attribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Attribute (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Attribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Attribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Attribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Attribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Attribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Attribute',
				       );
    }
}



=head2 $result = get_entity_Biomass(ids, fields)

A biomass is a collection of compounds in a specific
ratio and in specific compartments that are necessary for a
cell to function properly. The prediction of biomasses is key
to the functioning of the model. Each biomass belongs to
a specific model.
It has the following fields:

=over 4


=item mod_date

last modification date of the biomass data


=item name

descriptive name for this biomass


=item dna

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is DNA


=item protein

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is protein


=item cell_wall

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is cell wall


=item lipid

portion of a gram of this biomass (expressed as a
fraction of 1.0) that is lipid but is not part of the cell
wall


=item cofactor

portion of a gram of this biomass (expressed as a
fraction of 1.0) that function as cofactors


=item energy

number of ATP molecules hydrolized per gram of
this biomass



=back

=cut

sub get_entity_Biomass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Biomass (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Biomass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Biomass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Biomass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Biomass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Biomass",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Biomass',
				       );
    }
}



=head2 $result = query_entity_Biomass(qry, fields)



=cut

sub query_entity_Biomass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Biomass (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Biomass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Biomass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Biomass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Biomass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Biomass",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Biomass',
				       );
    }
}



=head2 $result = all_entities_Biomass(start, count, fields)



=cut

sub all_entities_Biomass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Biomass (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Biomass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Biomass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Biomass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Biomass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Biomass",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Biomass',
				       );
    }
}



=head2 $result = get_entity_CodonUsage(ids, fields)

This entity contains information about the codon usage
frequency in a particular genome with respect to a particular
type of analysis (e.g. high-expression genes, modal, mean,
etc.).
It has the following fields:

=over 4


=item frequencies

A packed-string representation of the codon usage
frequencies. These are not global frequencies, but rather
frequenicy of use relative to other codons that produce
the same amino acid.


=item genetic_code

Genetic code used for these codons.


=item type

Type of frequency analysis: average, modal,
high-expression, or non-native.


=item subtype

Specific nature of the codon usage with respect
to the given type, generally indicative of how the
frequencies were computed.



=back

=cut

sub get_entity_CodonUsage
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_CodonUsage (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_CodonUsage:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_CodonUsage');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_CodonUsage",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_CodonUsage',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_CodonUsage",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_CodonUsage',
				       );
    }
}



=head2 $result = query_entity_CodonUsage(qry, fields)



=cut

sub query_entity_CodonUsage
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_CodonUsage (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_CodonUsage:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_CodonUsage');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_CodonUsage",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_CodonUsage',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_CodonUsage",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_CodonUsage',
				       );
    }
}



=head2 $result = all_entities_CodonUsage(start, count, fields)



=cut

sub all_entities_CodonUsage
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_CodonUsage (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_CodonUsage:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_CodonUsage');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_CodonUsage",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_CodonUsage',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_CodonUsage",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_CodonUsage',
				       );
    }
}



=head2 $result = get_entity_Complex(ids, fields)

A complex is a set of chemical reactions that act in concert to
effect a role.
It has the following fields:

=over 4


=item name

name of this complex. Not all complexes have names.


=item source_id

ID of this complex in the source from which it was added.


=item mod_date

date and time of the last change to this complex's definition



=back

=cut

sub get_entity_Complex
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Complex (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Complex:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Complex');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Complex",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Complex',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Complex",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Complex',
				       );
    }
}



=head2 $result = query_entity_Complex(qry, fields)



=cut

sub query_entity_Complex
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Complex (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Complex:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Complex');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Complex",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Complex',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Complex",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Complex',
				       );
    }
}



=head2 $result = all_entities_Complex(start, count, fields)



=cut

sub all_entities_Complex
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Complex (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Complex:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Complex');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Complex",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Complex',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Complex",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Complex',
				       );
    }
}



=head2 $result = get_entity_Compound(ids, fields)

A compound is a chemical that participates in a reaction. Both
ligands and reaction components are treated as compounds.
It has the following fields:

=over 4


=item label

primary name of the compound, for use in displaying
reactions


=item abbr

shortened abbreviation for the compound name


=item source_id

common modeling ID of this compound


=item ubiquitous

TRUE if this compound is found in most reactions, else FALSE


=item mod_date

date and time of the last modification to the
compound definition


=item mass

pH-neutral atomic mass of the compound


=item formula

a pH-neutral formula for the compound


=item charge

computed charge of the compound in a pH-neutral
solution


=item deltaG

the pH 7 reference Gibbs free-energy of formation for this
compound as calculated by the group contribution method (units are
kcal/mol)


=item deltaG_error

the uncertainty in the [b]deltaG[/b] value (units are
kcal/mol)



=back

=cut

sub get_entity_Compound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Compound (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Compound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Compound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Compound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Compound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Compound",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Compound',
				       );
    }
}



=head2 $result = query_entity_Compound(qry, fields)



=cut

sub query_entity_Compound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Compound (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Compound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Compound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Compound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Compound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Compound",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Compound',
				       );
    }
}



=head2 $result = all_entities_Compound(start, count, fields)



=cut

sub all_entities_Compound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Compound (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Compound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Compound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Compound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Compound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Compound",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Compound',
				       );
    }
}



=head2 $result = get_entity_CompoundInstance(ids, fields)

A Compound Instance represents the occurrence of a particular
compound in a location in a model.
It has the following fields:

=over 4


=item charge

computed charge based on the location instance pH
and similar constraints


=item formula

computed chemical formula for this compound based
on the location instance pH and similar constraints



=back

=cut

sub get_entity_CompoundInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_CompoundInstance (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_CompoundInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_CompoundInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_CompoundInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_CompoundInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_CompoundInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_CompoundInstance',
				       );
    }
}



=head2 $result = query_entity_CompoundInstance(qry, fields)



=cut

sub query_entity_CompoundInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_CompoundInstance (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_CompoundInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_CompoundInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_CompoundInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_CompoundInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_CompoundInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_CompoundInstance',
				       );
    }
}



=head2 $result = all_entities_CompoundInstance(start, count, fields)



=cut

sub all_entities_CompoundInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_CompoundInstance (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_CompoundInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_CompoundInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_CompoundInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_CompoundInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_CompoundInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_CompoundInstance',
				       );
    }
}



=head2 $result = get_entity_Contig(ids, fields)

A contig is thought of as composing a part of the DNA
associated with a specific genome.  It is represented as an ID
(including the genome ID) and a ContigSequence. We do not think
of strings of DNA from, say, a metgenomic sample as "contigs",
since there is no associated genome (these would be considered
ContigSequences). This use of the term "ContigSequence", rather
than just "DNA sequence", may turn out to be a bad idea.  For now,
you should just realize that a Contig has an associated
genome, but a ContigSequence does not.
It has the following fields:

=over 4


=item source_id

ID of this contig from the core (source) database



=back

=cut

sub get_entity_Contig
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Contig (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Contig:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Contig');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Contig",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Contig',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Contig",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Contig',
				       );
    }
}



=head2 $result = query_entity_Contig(qry, fields)



=cut

sub query_entity_Contig
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Contig (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Contig:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Contig');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Contig",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Contig',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Contig",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Contig',
				       );
    }
}



=head2 $result = all_entities_Contig(start, count, fields)



=cut

sub all_entities_Contig
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Contig (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Contig:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Contig');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Contig",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Contig',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Contig",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Contig',
				       );
    }
}



=head2 $result = get_entity_ContigChunk(ids, fields)

ContigChunks are strings of DNA thought of as being a
string in a 4-character alphabet with an associated ID.  We
allow a broader alphabet that includes U (for RNA) and
the standard ambiguity characters.
It has the following fields:

=over 4


=item sequence

base pairs that make up this sequence



=back

=cut

sub get_entity_ContigChunk
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ContigChunk (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ContigChunk:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ContigChunk');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ContigChunk",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ContigChunk',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ContigChunk",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ContigChunk',
				       );
    }
}



=head2 $result = query_entity_ContigChunk(qry, fields)



=cut

sub query_entity_ContigChunk
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ContigChunk (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ContigChunk:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ContigChunk');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ContigChunk",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ContigChunk',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ContigChunk",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ContigChunk',
				       );
    }
}



=head2 $result = all_entities_ContigChunk(start, count, fields)



=cut

sub all_entities_ContigChunk
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ContigChunk (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ContigChunk:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ContigChunk');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ContigChunk",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ContigChunk',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ContigChunk",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ContigChunk',
				       );
    }
}



=head2 $result = get_entity_ContigSequence(ids, fields)

ContigSequences are strings of DNA.  Contigs have an
associated genome, but ContigSequences do not.  We can think
of random samples of DNA as a set of ContigSequences. There
are no length constraints imposed on ContigSequences -- they
can be either very short or very long.  The basic unit of data
that is moved to/from the database is the ContigChunk, from
which ContigSequences are formed. The key of a ContigSequence
is the sequence's MD5 identifier.
It has the following fields:

=over 4


=item length

number of base pairs in the contig



=back

=cut

sub get_entity_ContigSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ContigSequence (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ContigSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ContigSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ContigSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ContigSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ContigSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ContigSequence',
				       );
    }
}



=head2 $result = query_entity_ContigSequence(qry, fields)



=cut

sub query_entity_ContigSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ContigSequence (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ContigSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ContigSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ContigSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ContigSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ContigSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ContigSequence',
				       );
    }
}



=head2 $result = all_entities_ContigSequence(start, count, fields)



=cut

sub all_entities_ContigSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ContigSequence (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ContigSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ContigSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ContigSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ContigSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ContigSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ContigSequence',
				       );
    }
}



=head2 $result = get_entity_CoregulatedSet(ids, fields)

We need to represent sets of genes that are coregulated via
some regulatory mechanism.  In particular, we wish to represent
genes that are coregulated using transcription binding sites and
corresponding transcription regulatory proteins. We represent a
coregulated set (which may, or may not, be considered a regulon)
using CoregulatedSet.
It has the following fields:

=over 4


=item source_id

original ID of this coregulated set in the source (core)
database


=item binding_location

binding location for this set's transcription factor;
there may be none of these or there may be more than one



=back

=cut

sub get_entity_CoregulatedSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_CoregulatedSet (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_CoregulatedSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_CoregulatedSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_CoregulatedSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_CoregulatedSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_CoregulatedSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_CoregulatedSet',
				       );
    }
}



=head2 $result = query_entity_CoregulatedSet(qry, fields)



=cut

sub query_entity_CoregulatedSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_CoregulatedSet (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_CoregulatedSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_CoregulatedSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_CoregulatedSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_CoregulatedSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_CoregulatedSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_CoregulatedSet',
				       );
    }
}



=head2 $result = all_entities_CoregulatedSet(start, count, fields)



=cut

sub all_entities_CoregulatedSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_CoregulatedSet (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_CoregulatedSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_CoregulatedSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_CoregulatedSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_CoregulatedSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_CoregulatedSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_CoregulatedSet',
				       );
    }
}



=head2 $result = get_entity_Diagram(ids, fields)

A functional diagram describes a network of chemical
reactions, often comprising a single subsystem.
It has the following fields:

=over 4


=item name

descriptive name of this diagram


=item content

content of the diagram, in PNG format



=back

=cut

sub get_entity_Diagram
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Diagram (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Diagram:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Diagram');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Diagram",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Diagram',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Diagram",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Diagram',
				       );
    }
}



=head2 $result = query_entity_Diagram(qry, fields)



=cut

sub query_entity_Diagram
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Diagram (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Diagram:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Diagram');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Diagram",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Diagram',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Diagram",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Diagram',
				       );
    }
}



=head2 $result = all_entities_Diagram(start, count, fields)



=cut

sub all_entities_Diagram
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Diagram (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Diagram:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Diagram');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Diagram",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Diagram',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Diagram",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Diagram',
				       );
    }
}



=head2 $result = get_entity_EcNumber(ids, fields)

EC numbers are assigned by the Enzyme Commission, and consist
of four numbers separated by periods, each indicating a successively
smaller cateogry of enzymes.
It has the following fields:

=over 4


=item obsolete

This boolean indicates when an EC number is obsolete.


=item replacedby

When an obsolete EC number is replaced with another EC number, this string will
hold the name of the replacement EC number.



=back

=cut

sub get_entity_EcNumber
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_EcNumber (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_EcNumber:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_EcNumber');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_EcNumber",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_EcNumber',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_EcNumber",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_EcNumber',
				       );
    }
}



=head2 $result = query_entity_EcNumber(qry, fields)



=cut

sub query_entity_EcNumber
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_EcNumber (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_EcNumber:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_EcNumber');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_EcNumber",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_EcNumber',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_EcNumber",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_EcNumber',
				       );
    }
}



=head2 $result = all_entities_EcNumber(start, count, fields)



=cut

sub all_entities_EcNumber
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_EcNumber (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_EcNumber:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_EcNumber');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_EcNumber",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_EcNumber',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_EcNumber",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_EcNumber',
				       );
    }
}



=head2 $result = get_entity_Environment(ids, fields)

An Environment is a set of conditions for microbial growth,
including temperature, aerobicity, media, and supplementary
conditions.
It has the following fields:

=over 4


=item temperature

The temperature in Kelvin.


=item description

A description of the environment.


=item anaerobic

Whether the environment is anaerobic (True) or aerobic
(False).


=item pH

The pH of the media used in the environment.


=item source_id

The ID of the environment used by the data source.



=back

=cut

sub get_entity_Environment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Environment (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Environment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Environment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Environment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Environment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Environment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Environment',
				       );
    }
}



=head2 $result = query_entity_Environment(qry, fields)



=cut

sub query_entity_Environment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Environment (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Environment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Environment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Environment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Environment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Environment",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Environment',
				       );
    }
}



=head2 $result = all_entities_Environment(start, count, fields)



=cut

sub all_entities_Environment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Environment (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Environment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Environment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Environment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Environment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Environment",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Environment',
				       );
    }
}



=head2 $result = get_entity_Experiment(ids, fields)

An experiment is a combination of conditions for which gene expression
information is desired. The result of the experiment is a set of expression
levels for features under the given conditions.
It has the following fields:

=over 4


=item source

Publication or lab relevant to this experiment.



=back

=cut

sub get_entity_Experiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Experiment (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Experiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Experiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Experiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Experiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Experiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Experiment',
				       );
    }
}



=head2 $result = query_entity_Experiment(qry, fields)



=cut

sub query_entity_Experiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Experiment (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Experiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Experiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Experiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Experiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Experiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Experiment',
				       );
    }
}



=head2 $result = all_entities_Experiment(start, count, fields)



=cut

sub all_entities_Experiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Experiment (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Experiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Experiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Experiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Experiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Experiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Experiment',
				       );
    }
}



=head2 $result = get_entity_ExperimentalUnit(ids, fields)

An ExperimentalUnit is a subset of an experiment consisting of
a Strain, an Environment, and one or more Measurements on that
strain in the specified environment. ExperimentalUnits belong to a
single experiment.
It has the following fields:

=over 4


=item source_id

The ID of the experimental unit used by the data source.



=back

=cut

sub get_entity_ExperimentalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ExperimentalUnit (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ExperimentalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ExperimentalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ExperimentalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ExperimentalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ExperimentalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ExperimentalUnit',
				       );
    }
}



=head2 $result = query_entity_ExperimentalUnit(qry, fields)



=cut

sub query_entity_ExperimentalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ExperimentalUnit (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ExperimentalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ExperimentalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ExperimentalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ExperimentalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ExperimentalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ExperimentalUnit',
				       );
    }
}



=head2 $result = all_entities_ExperimentalUnit(start, count, fields)



=cut

sub all_entities_ExperimentalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ExperimentalUnit (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ExperimentalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ExperimentalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ExperimentalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ExperimentalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ExperimentalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ExperimentalUnit',
				       );
    }
}



=head2 $result = get_entity_Family(ids, fields)

The Kbase will support the maintenance of protein families
(as sets of Features with associated translations).  We are
initially only supporting the notion of a family as composed of
a set of isofunctional homologs.  That is, the families we
initially support should be thought of as containing
protein-encoding genes whose associated sequences all implement
the same function (we do understand that the notion of "function"
is somewhat ambiguous, so let us sweep this under the rug by
calling a functional role a "primitive concept").
We currently support families in which the members are
protein sequences as well. Identical protein sequences
as products of translating distinct genes may or may not
have identical functions.  This may be justified, since
in a very, very, very few cases identical proteins do, in
fact, have distinct functions.
It has the following fields:

=over 4


=item type

type of protein family (e.g. FIGfam, equivalog)


=item release

release number / subtype of protein family


=item family_function

optional free-form description of the family. For function-based
families, this would be the functional role for the family
members.


=item alignment

FASTA-formatted alignment of the family's protein
sequences



=back

=cut

sub get_entity_Family
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Family (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Family:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Family');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Family",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Family',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Family",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Family',
				       );
    }
}



=head2 $result = query_entity_Family(qry, fields)



=cut

sub query_entity_Family
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Family (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Family:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Family');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Family",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Family',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Family",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Family',
				       );
    }
}



=head2 $result = all_entities_Family(start, count, fields)



=cut

sub all_entities_Family
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Family (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Family:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Family');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Family",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Family',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Family",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Family',
				       );
    }
}



=head2 $result = get_entity_Feature(ids, fields)

A feature (sometimes also called a gene) is a part of a
genome that is of special interest. Features may be spread across
multiple DNA sequences (contigs) of a genome, but never across more
than one genome. Each feature in the database has a unique
ID that functions as its ID in this table. Normally a Feature is
just a single contigous region on a contig. Features have types,
and an appropriate choice of available types allows the support
of protein-encoding genes, exons, RNA genes, binding sites,
pathogenicity islands, or whatever.
It has the following fields:

=over 4


=item feature_type

Code indicating the type of this feature. Among the
codes currently supported are "peg" for a protein encoding
gene, "bs" for a binding site, "opr" for an operon, and so
forth.


=item source_id

ID for this feature in its original source (core)
database


=item sequence_length

Number of base pairs in this feature.


=item function

Functional assignment for this feature. This will
often indicate the feature's functional role or roles, and
may also have comments.


=item alias

alternative identifier for the feature. These are
highly unstructured, and frequently non-unique.



=back

=cut

sub get_entity_Feature
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Feature (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Feature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Feature');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Feature",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Feature',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Feature",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Feature',
				       );
    }
}



=head2 $result = query_entity_Feature(qry, fields)



=cut

sub query_entity_Feature
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Feature (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Feature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Feature');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Feature",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Feature',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Feature",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Feature',
				       );
    }
}



=head2 $result = all_entities_Feature(start, count, fields)



=cut

sub all_entities_Feature
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Feature (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Feature:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Feature');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Feature",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Feature',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Feature",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Feature',
				       );
    }
}



=head2 $result = get_entity_Genome(ids, fields)

The Kbase houses a large and growing set of genomes.  We
often have multiple genomes that have identical DNA.  These usually
have distinct gene calls and annotations, but not always.  We
consider the Kbase to be a framework for managing hundreds of
thousands of genomes and offering the tools needed to
support compartive analysis on large sets of genomes,
some of which are virtually identical.
It has the following fields:

=over 4


=item pegs

Number of protein encoding genes for this genome.


=item rnas

Number of RNA features found for this organism.


=item scientific_name

Full genus/species/strain name of the genome sequence.


=item complete

TRUE if the genome sequence is complete, else FALSE


=item prokaryotic

TRUE if this is a prokaryotic genome sequence, else FALSE


=item dna_size

Number of base pairs in the genome sequence.


=item contigs

Number of contigs for this genome sequence.


=item domain

Domain for this organism (Archaea, Bacteria, Eukaryota,
Virus, Plasmid, or Environmental Sample).


=item genetic_code

Genetic code number used for protein translation on most
of this genome sequence's contigs.


=item gc_content

Percent GC content present in the genome sequence's
DNA.


=item phenotype

zero or more strings describing phenotypic information
about this genome sequence


=item md5

MD5 identifier describing the genome's DNA sequence


=item source_id

identifier assigned to this genome by the original
source



=back

=cut

sub get_entity_Genome
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Genome (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Genome');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Genome",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Genome',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Genome",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Genome',
				       );
    }
}



=head2 $result = query_entity_Genome(qry, fields)



=cut

sub query_entity_Genome
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Genome (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Genome');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Genome",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Genome',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Genome",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Genome',
				       );
    }
}



=head2 $result = all_entities_Genome(start, count, fields)



=cut

sub all_entities_Genome
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Genome (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Genome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Genome');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Genome",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Genome',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Genome",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Genome',
				       );
    }
}



=head2 $result = get_entity_Locality(ids, fields)

A locality is a geographic location.
It has the following fields:

=over 4


=item source_name

Name or description of the location used as a collection site.


=item city

City of the collecting site.


=item state

State or province of the collecting site.


=item country

Country of the collecting site.


=item origcty

3-letter ISO 3166-1 extended country code for the country of origin.


=item elevation

Elevation of the collecting site, expressed in meters above sea level.  Negative values are allowed.


=item latitude

Latitude of the collecting site, recorded as a decimal number.  North latitudes are positive values and south latitudes are negative numbers.


=item longitude

Longitude of the collecting site, recorded as a decimal number.  West longitudes are positive values and east longitudes are negative numbers.


=item lo_accession

gazeteer ontology term ID



=back

=cut

sub get_entity_Locality
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Locality (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Locality:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Locality');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Locality",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Locality',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Locality",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Locality',
				       );
    }
}



=head2 $result = query_entity_Locality(qry, fields)



=cut

sub query_entity_Locality
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Locality (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Locality:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Locality');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Locality",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Locality',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Locality",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Locality',
				       );
    }
}



=head2 $result = all_entities_Locality(start, count, fields)



=cut

sub all_entities_Locality
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Locality (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Locality:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Locality');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Locality",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Locality',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Locality",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Locality',
				       );
    }
}



=head2 $result = get_entity_LocalizedCompound(ids, fields)

This entity represents a compound occurring in a
specific location. A reaction always involves localized
compounds. If a reaction occurs entirely in a single
location, it will frequently only be represented by the
cytoplasmic versions of the compounds; however, a transport
always uses specifically located compounds.
It has the following fields:

=over 4



=back

=cut

sub get_entity_LocalizedCompound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_LocalizedCompound (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_LocalizedCompound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_LocalizedCompound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_LocalizedCompound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_LocalizedCompound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_LocalizedCompound",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_LocalizedCompound',
				       );
    }
}



=head2 $result = query_entity_LocalizedCompound(qry, fields)



=cut

sub query_entity_LocalizedCompound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_LocalizedCompound (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_LocalizedCompound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_LocalizedCompound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_LocalizedCompound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_LocalizedCompound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_LocalizedCompound",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_LocalizedCompound',
				       );
    }
}



=head2 $result = all_entities_LocalizedCompound(start, count, fields)



=cut

sub all_entities_LocalizedCompound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_LocalizedCompound (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_LocalizedCompound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_LocalizedCompound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_LocalizedCompound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_LocalizedCompound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_LocalizedCompound",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_LocalizedCompound',
				       );
    }
}



=head2 $result = get_entity_Location(ids, fields)

A location is a region of the cell where reaction compounds
originate from or are transported to (e.g. cell wall, extracellular,
cytoplasm).
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to the
compartment's definition


=item name

common name for the location


=item source_id

ID from the source of this location


=item abbr

an abbreviation (usually a single letter) for the
location.



=back

=cut

sub get_entity_Location
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Location (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Location:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Location');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Location",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Location',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Location",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Location',
				       );
    }
}



=head2 $result = query_entity_Location(qry, fields)



=cut

sub query_entity_Location
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Location (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Location:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Location');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Location",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Location',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Location",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Location',
				       );
    }
}



=head2 $result = all_entities_Location(start, count, fields)



=cut

sub all_entities_Location
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Location (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Location:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Location');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Location",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Location',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Location",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Location',
				       );
    }
}



=head2 $result = get_entity_LocationInstance(ids, fields)

The Location Instance represents a region of a cell
(e.g. cell wall, cytoplasm) as it appears in a specific
model.
It has the following fields:

=over 4


=item index

number used to distinguish between different
instances of the same type of location in a single
model. Within a model, any two instances of the same
location must have difference compartment index
values.


=item label

description used to differentiate between instances
of the same location in a single model


=item pH

pH of the cell region, which is used to determine compound
charge and pH gradient across cell membranes


=item potential

electrochemical potential of the cell region, which is used to
determine the electrochemical gradient across cell membranes



=back

=cut

sub get_entity_LocationInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_LocationInstance (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_LocationInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_LocationInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_LocationInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_LocationInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_LocationInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_LocationInstance',
				       );
    }
}



=head2 $result = query_entity_LocationInstance(qry, fields)



=cut

sub query_entity_LocationInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_LocationInstance (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_LocationInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_LocationInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_LocationInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_LocationInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_LocationInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_LocationInstance',
				       );
    }
}



=head2 $result = all_entities_LocationInstance(start, count, fields)



=cut

sub all_entities_LocationInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_LocationInstance (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_LocationInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_LocationInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_LocationInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_LocationInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_LocationInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_LocationInstance',
				       );
    }
}



=head2 $result = get_entity_Measurement(ids, fields)

A Measurement is a value generated by performing a protocol to
evaluate a phenotype on an ExperimentalUnit - e.g. a strain in an
environment.
It has the following fields:

=over 4


=item timeSeries

A string containing time series data in the following
format: time1,value1;time2,value2;...timeN,valueN.


=item source_id

The ID of the measurement used by the data source.


=item value

The value of the measurement.


=item mean

The mean of multiple replicates if they are included in the
measurement.


=item median

The median of multiple replicates if they are included in
the measurement.


=item stddev

The standard deviation of multiple replicates if they are
included in the measurement.


=item N

The number of replicates if they are included in the
measurement.


=item p_value

The p-value of multiple replicates if they are included in
the measurement. The exact meaning of the p-value is specified in
the Phenotype object for this measurement.


=item Z_score

The Z-score of multiple replicates if they are included in
the measurement. The exact meaning of the p-value is specified in
the Phenotype object for this measurement.



=back

=cut

sub get_entity_Measurement
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Measurement (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Measurement:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Measurement');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Measurement",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Measurement',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Measurement",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Measurement',
				       );
    }
}



=head2 $result = query_entity_Measurement(qry, fields)



=cut

sub query_entity_Measurement
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Measurement (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Measurement:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Measurement');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Measurement",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Measurement',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Measurement",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Measurement',
				       );
    }
}



=head2 $result = all_entities_Measurement(start, count, fields)



=cut

sub all_entities_Measurement
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Measurement (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Measurement:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Measurement');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Measurement",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Measurement',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Measurement",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Measurement',
				       );
    }
}



=head2 $result = get_entity_Media(ids, fields)

A media describes the chemical content of the solution in which cells
are grown in an experiment or for the purposes of a model. The key is the
common media name. The nature of the media is described by its relationship
to its constituent compounds.
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to the media's
definition


=item name

descriptive name of the media


=item is_minimal

TRUE if this is a minimal media, else FALSE


=item source_id

The ID of the media used by the data source.


=item type

The general category of the media.



=back

=cut

sub get_entity_Media
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Media (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Media');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Media",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Media',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Media",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Media',
				       );
    }
}



=head2 $result = query_entity_Media(qry, fields)



=cut

sub query_entity_Media
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Media (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Media');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Media",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Media',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Media",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Media',
				       );
    }
}



=head2 $result = all_entities_Media(start, count, fields)



=cut

sub all_entities_Media
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Media (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Media');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Media",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Media',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Media",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Media',
				       );
    }
}



=head2 $result = get_entity_Model(ids, fields)

A model specifies a relationship between sets of features and
reactions in a cell. It is used to simulate cell growth and gene
knockouts to validate annotations.
It has the following fields:

=over 4


=item mod_date

date and time of the last change to the model data


=item name

descriptive name of the model


=item version

revision number of the model


=item type

string indicating where the model came from
(e.g. single genome, multiple genome, or community model)


=item status

indicator of whether the model is stable, under
construction, or under reconstruction


=item reaction_count

number of reactions in the model


=item compound_count

number of compounds in the model


=item annotation_count

number of features associated with one or more reactions in
the model



=back

=cut

sub get_entity_Model
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Model (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Model');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Model",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Model',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Model",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Model',
				       );
    }
}



=head2 $result = query_entity_Model(qry, fields)



=cut

sub query_entity_Model
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Model (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Model');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Model",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Model',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Model",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Model',
				       );
    }
}



=head2 $result = all_entities_Model(start, count, fields)



=cut

sub all_entities_Model
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Model (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Model');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Model",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Model',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Model",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Model',
				       );
    }
}



=head2 $result = get_entity_OTU(ids, fields)

An OTU (Organism Taxonomic Unit) is a named group of related
genomes.
It has the following fields:

=over 4



=back

=cut

sub get_entity_OTU
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_OTU (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_OTU:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_OTU');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_OTU",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_OTU',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_OTU",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_OTU',
				       );
    }
}



=head2 $result = query_entity_OTU(qry, fields)



=cut

sub query_entity_OTU
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_OTU (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_OTU:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_OTU');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_OTU",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_OTU',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_OTU",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_OTU',
				       );
    }
}



=head2 $result = all_entities_OTU(start, count, fields)



=cut

sub all_entities_OTU
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_OTU (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_OTU:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_OTU');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_OTU",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_OTU',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_OTU",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_OTU',
				       );
    }
}



=head2 $result = get_entity_ObservationalUnit(ids, fields)

An ObservationalUnit is an individual plant that 1) is part of an experiment or study, 2) has measured traits, and 3) is assayed for the purpose of determining alleles.  
It has the following fields:

=over 4


=item source_name

Name/ID by which the observational unit may be known by the originator and is used in queries.


=item source_name2

Secondary name/ID by which the observational unit may be known and is queried.


=item plant_id

ID of the plant that was tested to produce this
observational unit. Observational units with the same plant
ID are different assays of a single physical organism.



=back

=cut

sub get_entity_ObservationalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ObservationalUnit (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ObservationalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ObservationalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ObservationalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ObservationalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ObservationalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ObservationalUnit',
				       );
    }
}



=head2 $result = query_entity_ObservationalUnit(qry, fields)



=cut

sub query_entity_ObservationalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ObservationalUnit (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ObservationalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ObservationalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ObservationalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ObservationalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ObservationalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ObservationalUnit',
				       );
    }
}



=head2 $result = all_entities_ObservationalUnit(start, count, fields)



=cut

sub all_entities_ObservationalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ObservationalUnit (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ObservationalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ObservationalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ObservationalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ObservationalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ObservationalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ObservationalUnit',
				       );
    }
}



=head2 $result = get_entity_PairSet(ids, fields)

A PairSet is a precompute set of pairs or genes.  Each
pair occurs close to one another of the chromosome.  We believe
that all of the first members of the pairs correspond to one another
(are quite similar), as do all of the second members of the pairs.
These pairs (from prokaryotic genomes) offer one of the most
powerful clues relating to uncharacterized genes/peroteins.
It has the following fields:

=over 4


=item score

Score for this evidence set. The score indicates the
number of significantly different genomes represented by the
pairings.



=back

=cut

sub get_entity_PairSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_PairSet (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_PairSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_PairSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_PairSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_PairSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_PairSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_PairSet',
				       );
    }
}



=head2 $result = query_entity_PairSet(qry, fields)



=cut

sub query_entity_PairSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_PairSet (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_PairSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_PairSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_PairSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_PairSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_PairSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_PairSet',
				       );
    }
}



=head2 $result = all_entities_PairSet(start, count, fields)



=cut

sub all_entities_PairSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_PairSet (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_PairSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_PairSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_PairSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_PairSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_PairSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_PairSet',
				       );
    }
}



=head2 $result = get_entity_Pairing(ids, fields)

A pairing indicates that two features are found
close together in a genome. Not all possible pairings are stored in
the database; only those that are considered for some reason to be
significant for annotation purposes.The key of the pairing is the
concatenation of the feature IDs in alphabetical order with an
intervening colon.
It has the following fields:

=over 4



=back

=cut

sub get_entity_Pairing
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Pairing (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Pairing:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Pairing');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Pairing",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Pairing',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Pairing",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Pairing',
				       );
    }
}



=head2 $result = query_entity_Pairing(qry, fields)



=cut

sub query_entity_Pairing
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Pairing (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Pairing:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Pairing');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Pairing",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Pairing',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Pairing",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Pairing',
				       );
    }
}



=head2 $result = all_entities_Pairing(start, count, fields)



=cut

sub all_entities_Pairing
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Pairing (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Pairing:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Pairing');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Pairing",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Pairing',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Pairing",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Pairing',
				       );
    }
}



=head2 $result = get_entity_Person(ids, fields)

A person represents a human affiliated in some way with Kbase.
It has the following fields:

=over 4


=item firstName

The given name of the person.


=item lastName

The surname of the person.


=item contactEmail

Email address of the person.


=item institution

The institution where the person works.


=item source_id

The ID of the person used by the data source.



=back

=cut

sub get_entity_Person
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Person (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Person:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Person');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Person",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Person',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Person",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Person',
				       );
    }
}



=head2 $result = query_entity_Person(qry, fields)



=cut

sub query_entity_Person
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Person (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Person:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Person');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Person",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Person',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Person",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Person',
				       );
    }
}



=head2 $result = all_entities_Person(start, count, fields)



=cut

sub all_entities_Person
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Person (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Person:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Person');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Person",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Person',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Person",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Person',
				       );
    }
}



=head2 $result = get_entity_PhenotypeDescription(ids, fields)

A Phenotype is a measurable characteristic of an organism.
It has the following fields:

=over 4


=item name

The name of the phenotype.


=item description

The description of the physical phenotype, how it is
measured, and what the measurement statistics mean.


=item unitOfMeasure

The units of the measurement of the phenotype.


=item source_id

The ID of the phenotype description used by the data source.



=back

=cut

sub get_entity_PhenotypeDescription
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_PhenotypeDescription (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_PhenotypeDescription:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_PhenotypeDescription');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_PhenotypeDescription",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_PhenotypeDescription',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_PhenotypeDescription",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_PhenotypeDescription',
				       );
    }
}



=head2 $result = query_entity_PhenotypeDescription(qry, fields)



=cut

sub query_entity_PhenotypeDescription
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_PhenotypeDescription (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_PhenotypeDescription:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_PhenotypeDescription');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_PhenotypeDescription",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_PhenotypeDescription',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_PhenotypeDescription",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_PhenotypeDescription',
				       );
    }
}



=head2 $result = all_entities_PhenotypeDescription(start, count, fields)



=cut

sub all_entities_PhenotypeDescription
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_PhenotypeDescription (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_PhenotypeDescription:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_PhenotypeDescription');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_PhenotypeDescription",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_PhenotypeDescription',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_PhenotypeDescription",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_PhenotypeDescription',
				       );
    }
}



=head2 $result = get_entity_PhenotypeExperiment(ids, fields)

A PhenotypeExperiment, consisting of (potentially) multiple
strains, enviroments, and measurements of phenotypic information on
those strains and environments.
It has the following fields:

=over 4


=item description

Design of the experiment including the numbers and types of
experimental units, phenotypes, replicates, sampling plan, and
analyses that are planned.


=item source_id

The ID of the phenotype experiment used by the data source.


=item dateUploaded

The date this experiment was loaded into the database


=item metadata

Any data describing the experiment that is not covered by
the description field.



=back

=cut

sub get_entity_PhenotypeExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_PhenotypeExperiment (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_PhenotypeExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_PhenotypeExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_PhenotypeExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_PhenotypeExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_PhenotypeExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_PhenotypeExperiment',
				       );
    }
}



=head2 $result = query_entity_PhenotypeExperiment(qry, fields)



=cut

sub query_entity_PhenotypeExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_PhenotypeExperiment (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_PhenotypeExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_PhenotypeExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_PhenotypeExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_PhenotypeExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_PhenotypeExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_PhenotypeExperiment',
				       );
    }
}



=head2 $result = all_entities_PhenotypeExperiment(start, count, fields)



=cut

sub all_entities_PhenotypeExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_PhenotypeExperiment (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_PhenotypeExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_PhenotypeExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_PhenotypeExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_PhenotypeExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_PhenotypeExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_PhenotypeExperiment',
				       );
    }
}



=head2 $result = get_entity_ProbeSet(ids, fields)

A probe set is a device containing multiple probe sequences for use
in gene expression experiments.
It has the following fields:

=over 4



=back

=cut

sub get_entity_ProbeSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ProbeSet (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ProbeSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ProbeSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ProbeSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ProbeSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ProbeSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ProbeSet',
				       );
    }
}



=head2 $result = query_entity_ProbeSet(qry, fields)



=cut

sub query_entity_ProbeSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ProbeSet (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ProbeSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ProbeSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ProbeSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ProbeSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ProbeSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ProbeSet',
				       );
    }
}



=head2 $result = all_entities_ProbeSet(start, count, fields)



=cut

sub all_entities_ProbeSet
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ProbeSet (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ProbeSet:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ProbeSet');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ProbeSet",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ProbeSet',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ProbeSet",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ProbeSet',
				       );
    }
}



=head2 $result = get_entity_ProteinSequence(ids, fields)

We use the concept of ProteinSequence as an amino acid
string with an associated MD5 value.  It is easy to access the
set of Features that relate to a ProteinSequence.  While function
is still associated with Features (and may be for some time),
publications are associated with ProteinSequences (and the inferred
impact on Features is through the relationship connecting
ProteinSequences to Features).
It has the following fields:

=over 4


=item sequence

The sequence contains the letters corresponding to
the protein's amino acids.



=back

=cut

sub get_entity_ProteinSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ProteinSequence (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ProteinSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ProteinSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ProteinSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ProteinSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ProteinSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ProteinSequence',
				       );
    }
}



=head2 $result = query_entity_ProteinSequence(qry, fields)



=cut

sub query_entity_ProteinSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ProteinSequence (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ProteinSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ProteinSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ProteinSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ProteinSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ProteinSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ProteinSequence',
				       );
    }
}



=head2 $result = all_entities_ProteinSequence(start, count, fields)



=cut

sub all_entities_ProteinSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ProteinSequence (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ProteinSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ProteinSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ProteinSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ProteinSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ProteinSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ProteinSequence',
				       );
    }
}



=head2 $result = get_entity_Protocol(ids, fields)

A Protocol is a step by step set of instructions for
performing a part of an experiment.
It has the following fields:

=over 4


=item name

The name of the protocol.


=item description

The step by step instructions for performing the experiment,
including measurement details, materials, and equipment. A
researcher should be able to reproduce the experimental results
with this information.


=item source_id

The ID of the protocol used by the data source.



=back

=cut

sub get_entity_Protocol
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Protocol (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Protocol:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Protocol');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Protocol",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Protocol',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Protocol",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Protocol',
				       );
    }
}



=head2 $result = query_entity_Protocol(qry, fields)



=cut

sub query_entity_Protocol
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Protocol (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Protocol:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Protocol');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Protocol",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Protocol',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Protocol",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Protocol',
				       );
    }
}



=head2 $result = all_entities_Protocol(start, count, fields)



=cut

sub all_entities_Protocol
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Protocol (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Protocol:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Protocol');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Protocol",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Protocol',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Protocol",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Protocol',
				       );
    }
}



=head2 $result = get_entity_Publication(ids, fields)

Experimenters attach publications to experiments and
protocols. Annotators attach publications to ProteinSequences.
The attached publications give an ID (usually a
DOI or Pubmed ID),  a URL to the paper (when we have it), and a title
(when we have it). Pubmed IDs are given unmodified. DOI IDs
are prefixed with [b]doi:[/b], e.g. [i]doi:1002385[/i].
It has the following fields:

=over 4


=item title

title of the article, or (unknown) if the title is not known


=item link

URL of the article, DOI preferred


=item pubdate

publication date of the article



=back

=cut

sub get_entity_Publication
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Publication (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Publication:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Publication');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Publication",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Publication',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Publication",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Publication',
				       );
    }
}



=head2 $result = query_entity_Publication(qry, fields)



=cut

sub query_entity_Publication
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Publication (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Publication:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Publication');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Publication",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Publication',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Publication",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Publication',
				       );
    }
}



=head2 $result = all_entities_Publication(start, count, fields)



=cut

sub all_entities_Publication
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Publication (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Publication:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Publication');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Publication",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Publication',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Publication",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Publication',
				       );
    }
}



=head2 $result = get_entity_Reaction(ids, fields)

A reaction is a chemical process that converts one set of
compounds (substrate) to another set (products).
It has the following fields:

=over 4


=item mod_date

date and time of the last modification to this reaction's
definition


=item name

descriptive name of this reaction


=item source_id

ID of this reaction in the resource from which it was added


=item abbr

abbreviated name of this reaction


=item direction

direction of this reaction (> for forward-only,
< for backward-only, = for bidirectional)


=item deltaG

Gibbs free-energy change for the reaction calculated using
the group contribution method (units are kcal/mol)


=item deltaG_error

uncertainty in the [b]deltaG[/b] value (units are kcal/mol)


=item thermodynamic_reversibility

computed reversibility of this reaction in a
pH-neutral environment


=item default_protons

number of protons absorbed by this reaction in a
pH-neutral environment


=item status

string indicating additional information about
this reaction, generally indicating whether the reaction
is balanced and/or lumped



=back

=cut

sub get_entity_Reaction
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Reaction (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Reaction:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Reaction');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Reaction",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Reaction',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Reaction",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Reaction',
				       );
    }
}



=head2 $result = query_entity_Reaction(qry, fields)



=cut

sub query_entity_Reaction
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Reaction (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Reaction:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Reaction');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Reaction",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Reaction',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Reaction",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Reaction',
				       );
    }
}



=head2 $result = all_entities_Reaction(start, count, fields)



=cut

sub all_entities_Reaction
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Reaction (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Reaction:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Reaction');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Reaction",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Reaction',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Reaction",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Reaction',
				       );
    }
}



=head2 $result = get_entity_ReactionInstance(ids, fields)

A reaction instance describes the specific implementation of
a reaction in a model.
It has the following fields:

=over 4


=item direction

reaction directionality (> for forward, < for
backward, = for bidirectional) with respect to this model


=item protons

number of protons produced by this reaction when
proceeding in the forward direction. If this is a transport
reaction, these protons end up in the reaction instance's
main location. If the number is negative, then the protons
are consumed by the reaction rather than being produced.



=back

=cut

sub get_entity_ReactionInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_ReactionInstance (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_ReactionInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_ReactionInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_ReactionInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_ReactionInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_ReactionInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_ReactionInstance',
				       );
    }
}



=head2 $result = query_entity_ReactionInstance(qry, fields)



=cut

sub query_entity_ReactionInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_ReactionInstance (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_ReactionInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_ReactionInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_ReactionInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_ReactionInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_ReactionInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_ReactionInstance',
				       );
    }
}



=head2 $result = all_entities_ReactionInstance(start, count, fields)



=cut

sub all_entities_ReactionInstance
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_ReactionInstance (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_ReactionInstance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_ReactionInstance');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_ReactionInstance",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_ReactionInstance',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_ReactionInstance",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_ReactionInstance',
				       );
    }
}



=head2 $result = get_entity_Role(ids, fields)

A role describes a biological function that may be fulfilled
by a feature. One of the main goals of the database is to assign
features to roles. Most roles are effected by the construction of
proteins. Some, however, deal with functional regulation and message
transmission.
It has the following fields:

=over 4


=item hypothetical

TRUE if a role is hypothetical, else FALSE



=back

=cut

sub get_entity_Role
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Role (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Role:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Role');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Role",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Role',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Role",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Role',
				       );
    }
}



=head2 $result = query_entity_Role(qry, fields)



=cut

sub query_entity_Role
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Role (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Role:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Role');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Role",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Role',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Role",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Role',
				       );
    }
}



=head2 $result = all_entities_Role(start, count, fields)



=cut

sub all_entities_Role
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Role (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Role:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Role');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Role",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Role',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Role",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Role',
				       );
    }
}



=head2 $result = get_entity_SSCell(ids, fields)

An SSCell (SpreadSheet Cell) represents a role as it occurs
in a subsystem spreadsheet row. The key is a colon-delimited triple
containing an MD5 hash of the subsystem ID followed by a genome ID
(with optional region string) and a role abbreviation.
It has the following fields:

=over 4



=back

=cut

sub get_entity_SSCell
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_SSCell (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_SSCell:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_SSCell');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_SSCell",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_SSCell',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_SSCell",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_SSCell',
				       );
    }
}



=head2 $result = query_entity_SSCell(qry, fields)



=cut

sub query_entity_SSCell
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_SSCell (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_SSCell:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_SSCell');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_SSCell",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_SSCell',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_SSCell",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_SSCell',
				       );
    }
}



=head2 $result = all_entities_SSCell(start, count, fields)



=cut

sub all_entities_SSCell
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_SSCell (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_SSCell:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_SSCell');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_SSCell",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_SSCell',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_SSCell",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_SSCell',
				       );
    }
}



=head2 $result = get_entity_SSRow(ids, fields)

An SSRow (that is, a row in a subsystem spreadsheet)
represents a collection of functional roles present in the
Features of a single Genome.  The roles are part of a designated
subsystem, and the features associated with each role are included
in the row. That is, a row amounts to an instance of a subsystem as
it exists in a specific, designated genome.
It has the following fields:

=over 4


=item curated

This flag is TRUE if the assignment of the molecular
machine has been curated, and FALSE if it was made by an
automated program.


=item region

Region in the genome for which the row is relevant.
Normally, this is an empty string, indicating that the machine
covers the whole genome. If a subsystem has multiple rows
for a genome, this contains a location string describing the
region occupied by this particular row.



=back

=cut

sub get_entity_SSRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_SSRow (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_SSRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_SSRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_SSRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_SSRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_SSRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_SSRow',
				       );
    }
}



=head2 $result = query_entity_SSRow(qry, fields)



=cut

sub query_entity_SSRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_SSRow (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_SSRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_SSRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_SSRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_SSRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_SSRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_SSRow',
				       );
    }
}



=head2 $result = all_entities_SSRow(start, count, fields)



=cut

sub all_entities_SSRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_SSRow (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_SSRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_SSRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_SSRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_SSRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_SSRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_SSRow',
				       );
    }
}



=head2 $result = get_entity_Scenario(ids, fields)

A scenario is a partial instance of a subsystem with a
defined set of reactions. Each scenario converts input compounds to
output compounds using reactions. The scenario may use all of the
reactions controlled by a subsystem or only some, and may also
incorporate additional reactions. Because scenario names are not
unique, the actual scenario ID is a number.
It has the following fields:

=over 4


=item common_name

Common name of the scenario. The name, rather than the ID
number, is usually displayed everywhere.



=back

=cut

sub get_entity_Scenario
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Scenario (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Scenario:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Scenario');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Scenario",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Scenario',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Scenario",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Scenario',
				       );
    }
}



=head2 $result = query_entity_Scenario(qry, fields)



=cut

sub query_entity_Scenario
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Scenario (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Scenario:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Scenario');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Scenario",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Scenario',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Scenario",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Scenario',
				       );
    }
}



=head2 $result = all_entities_Scenario(start, count, fields)



=cut

sub all_entities_Scenario
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Scenario (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Scenario:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Scenario');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Scenario",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Scenario',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Scenario",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Scenario',
				       );
    }
}



=head2 $result = get_entity_Source(ids, fields)

A source is a user or organization that is permitted to
assign its own identifiers or to submit bioinformatic objects
to the database.
It has the following fields:

=over 4



=back

=cut

sub get_entity_Source
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Source (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Source:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Source');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Source",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Source',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Source",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Source',
				       );
    }
}



=head2 $result = query_entity_Source(qry, fields)



=cut

sub query_entity_Source
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Source (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Source:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Source');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Source",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Source',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Source",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Source',
				       );
    }
}



=head2 $result = all_entities_Source(start, count, fields)



=cut

sub all_entities_Source
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Source (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Source:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Source');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Source",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Source',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Source",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Source',
				       );
    }
}



=head2 $result = get_entity_Strain(ids, fields)

This entity represents an organism derived from a genome or
another organism with one or more modifications to the organism's
genome.
It has the following fields:

=over 4


=item description

A description of the strain, e.g. knockout/modification
methods, resulting phenotypes, etc.


=item source_id

The ID of the strain used by the data source.


=item aggregateData

Denotes whether this entity represents a physical strain
(False) or aggregate data calculated from one or more strains
(True).



=back

=cut

sub get_entity_Strain
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Strain (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Strain:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Strain');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Strain",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Strain',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Strain",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Strain',
				       );
    }
}



=head2 $result = query_entity_Strain(qry, fields)



=cut

sub query_entity_Strain
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Strain (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Strain:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Strain');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Strain",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Strain',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Strain",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Strain',
				       );
    }
}



=head2 $result = all_entities_Strain(start, count, fields)



=cut

sub all_entities_Strain
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Strain (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Strain:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Strain');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Strain",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Strain',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Strain",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Strain',
				       );
    }
}



=head2 $result = get_entity_StudyExperiment(ids, fields)

An Experiment is a collection of observational units with one originator that are part of a specific study.  An experiment may be conducted at more than one location and in more than one season or year.
It has the following fields:

=over 4


=item source_name

Name/ID by which the experiment is known at the source.  


=item design

Design of the experiment including the numbers and types of observational units, traits, replicates, sampling plan, and analysis that are planned.


=item originator

Name of the individual or program that are the originators of the experiment.



=back

=cut

sub get_entity_StudyExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_StudyExperiment (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_StudyExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_StudyExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_StudyExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_StudyExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_StudyExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_StudyExperiment',
				       );
    }
}



=head2 $result = query_entity_StudyExperiment(qry, fields)



=cut

sub query_entity_StudyExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_StudyExperiment (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_StudyExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_StudyExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_StudyExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_StudyExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_StudyExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_StudyExperiment',
				       );
    }
}



=head2 $result = all_entities_StudyExperiment(start, count, fields)



=cut

sub all_entities_StudyExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_StudyExperiment (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_StudyExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_StudyExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_StudyExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_StudyExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_StudyExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_StudyExperiment',
				       );
    }
}



=head2 $result = get_entity_Subsystem(ids, fields)

A subsystem is a set of functional roles that have been annotated simultaneously (e.g.,
the roles present in a specific pathway), with an associated subsystem spreadsheet
which encodes the fids in each genome that implement the functional roles in the
subsystem.
It has the following fields:

=over 4


=item version

version number for the subsystem. This value is
incremented each time the subsystem is backed up.


=item curator

name of the person currently in charge of the
subsystem


=item notes

descriptive notes about the subsystem


=item description

description of the subsystem's function in the
cell


=item usable

TRUE if this is a usable subsystem, else FALSE. An
unusable subsystem is one that is experimental or is of
such low quality that it can negatively affect analysis.


=item private

TRUE if this is a private subsystem, else FALSE. A
private subsystem has valid data, but is not considered ready
for general distribution.


=item cluster_based

TRUE if this is a clustering-based subsystem, else
FALSE. A clustering-based subsystem is one in which there is
functional-coupling evidence that genes belong together, but
we do not yet know what they do.


=item experimental

TRUE if this is an experimental subsystem, else FALSE.
An experimental subsystem is designed for investigation and
is not yet ready to be used in comparative analysis and
annotation.



=back

=cut

sub get_entity_Subsystem
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Subsystem (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Subsystem:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Subsystem');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Subsystem",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Subsystem',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Subsystem",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Subsystem',
				       );
    }
}



=head2 $result = query_entity_Subsystem(qry, fields)



=cut

sub query_entity_Subsystem
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Subsystem (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Subsystem:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Subsystem');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Subsystem",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Subsystem',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Subsystem",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Subsystem',
				       );
    }
}



=head2 $result = all_entities_Subsystem(start, count, fields)



=cut

sub all_entities_Subsystem
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Subsystem (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Subsystem:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Subsystem');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Subsystem",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Subsystem',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Subsystem",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Subsystem',
				       );
    }
}



=head2 $result = get_entity_SubsystemClass(ids, fields)

Subsystem classes impose a hierarchical organization on the
subsystems.
It has the following fields:

=over 4



=back

=cut

sub get_entity_SubsystemClass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_SubsystemClass (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_SubsystemClass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_SubsystemClass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_SubsystemClass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_SubsystemClass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_SubsystemClass",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_SubsystemClass',
				       );
    }
}



=head2 $result = query_entity_SubsystemClass(qry, fields)



=cut

sub query_entity_SubsystemClass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_SubsystemClass (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_SubsystemClass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_SubsystemClass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_SubsystemClass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_SubsystemClass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_SubsystemClass",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_SubsystemClass',
				       );
    }
}



=head2 $result = all_entities_SubsystemClass(start, count, fields)



=cut

sub all_entities_SubsystemClass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_SubsystemClass (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_SubsystemClass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_SubsystemClass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_SubsystemClass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_SubsystemClass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_SubsystemClass",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_SubsystemClass',
				       );
    }
}



=head2 $result = get_entity_TaxonomicGrouping(ids, fields)

We associate with most genomes a "taxonomy" based on
the NCBI taxonomy. This includes, for each genome, a list of
ever larger taxonomic groups. The groups are stored as
instances of this entity, and chained together by the
IsGroupFor relationship.
It has the following fields:

=over 4


=item domain

TRUE if this is a domain grouping, else FALSE.


=item hidden

TRUE if this is a hidden grouping, else FALSE. Hidden groupings
are not typically shown in a lineage list.


=item scientific_name

Primary scientific name for this grouping. This is the name used
when displaying a taxonomy.


=item alias

Alternate name for this grouping. A grouping
may have many alternate names. The scientific name should also
be in this list.



=back

=cut

sub get_entity_TaxonomicGrouping
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_TaxonomicGrouping (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_TaxonomicGrouping:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_TaxonomicGrouping');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_TaxonomicGrouping",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_TaxonomicGrouping',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_TaxonomicGrouping",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_TaxonomicGrouping',
				       );
    }
}



=head2 $result = query_entity_TaxonomicGrouping(qry, fields)



=cut

sub query_entity_TaxonomicGrouping
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_TaxonomicGrouping (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_TaxonomicGrouping:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_TaxonomicGrouping');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_TaxonomicGrouping",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_TaxonomicGrouping',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_TaxonomicGrouping",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_TaxonomicGrouping',
				       );
    }
}



=head2 $result = all_entities_TaxonomicGrouping(start, count, fields)



=cut

sub all_entities_TaxonomicGrouping
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_TaxonomicGrouping (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_TaxonomicGrouping:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_TaxonomicGrouping');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_TaxonomicGrouping",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_TaxonomicGrouping',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_TaxonomicGrouping",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_TaxonomicGrouping',
				       );
    }
}



=head2 $result = get_entity_Trait(ids, fields)

A Trait is a phenotypic quality that can be measured or observed for an observational unit.  Examples include height, sugar content, color, or cold tolerance.
It has the following fields:

=over 4


=item trait_name

Text name or description of the trait


=item unit_of_measure

The units of measure used when determining this trait.  If multiple units of measure are applicable, each has its own row in the database.  


=item TO_ID

Trait Ontology term ID (http://www.gramene.org/plant-ontology/)


=item protocol

A thorough description of how the trait was collected, and if a rating, the minimum and maximum values



=back

=cut

sub get_entity_Trait
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Trait (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Trait:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Trait');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Trait",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Trait',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Trait",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Trait',
				       );
    }
}



=head2 $result = query_entity_Trait(qry, fields)



=cut

sub query_entity_Trait
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Trait (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Trait:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Trait');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Trait",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Trait',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Trait",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Trait',
				       );
    }
}



=head2 $result = all_entities_Trait(start, count, fields)



=cut

sub all_entities_Trait
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Trait (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Trait:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Trait');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Trait",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Trait',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Trait",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Trait',
				       );
    }
}



=head2 $result = get_entity_Tree(ids, fields)

A tree describes how the sequences in an alignment relate
to each other. Most trees are phylogenetic, but some may be based on
taxonomy or gene content.
It has the following fields:

=over 4


=item status

status of the tree, currently either [i]active[/i],
[i]superseded[/i], or [i]bad[/i]


=item data_type

type of data the tree was built from, usually
[i]sequence_alignment[/i]


=item timestamp

date and time the tree was loaded


=item method

name of the primary software package or script used
to construct the tree


=item parameters

non-default parameters used as input to the software
package or script indicated in the method attribute


=item protocol

description of the steps taken to construct the tree,
or a reference to an external pipeline


=item source_id

ID of this tree in the source database


=item newick

NEWICK format string containing the structure
of the tree



=back

=cut

sub get_entity_Tree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Tree (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Tree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Tree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Tree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Tree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Tree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Tree',
				       );
    }
}



=head2 $result = query_entity_Tree(qry, fields)



=cut

sub query_entity_Tree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Tree (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Tree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Tree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Tree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Tree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Tree",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Tree',
				       );
    }
}



=head2 $result = all_entities_Tree(start, count, fields)



=cut

sub all_entities_Tree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Tree (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Tree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Tree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Tree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Tree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Tree",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Tree',
				       );
    }
}



=head2 $result = get_entity_TreeAttribute(ids, fields)

This entity represents an attribute type that can
be assigned to a tree. The attribute
values are stored in the relationships to the target. The
key is the attribute name.
It has the following fields:

=over 4



=back

=cut

sub get_entity_TreeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_TreeAttribute (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_TreeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_TreeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_TreeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_TreeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_TreeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_TreeAttribute',
				       );
    }
}



=head2 $result = query_entity_TreeAttribute(qry, fields)



=cut

sub query_entity_TreeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_TreeAttribute (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_TreeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_TreeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_TreeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_TreeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_TreeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_TreeAttribute',
				       );
    }
}



=head2 $result = all_entities_TreeAttribute(start, count, fields)



=cut

sub all_entities_TreeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_TreeAttribute (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_TreeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_TreeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_TreeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_TreeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_TreeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_TreeAttribute',
				       );
    }
}



=head2 $result = get_entity_TreeNodeAttribute(ids, fields)

This entity represents an attribute type that can
be assigned to a node. The attribute
values are stored in the relationships to the target. The
key is the attribute name.
It has the following fields:

=over 4



=back

=cut

sub get_entity_TreeNodeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_TreeNodeAttribute (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_TreeNodeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_TreeNodeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_TreeNodeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_TreeNodeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_TreeNodeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_TreeNodeAttribute',
				       );
    }
}



=head2 $result = query_entity_TreeNodeAttribute(qry, fields)



=cut

sub query_entity_TreeNodeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_TreeNodeAttribute (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_TreeNodeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_TreeNodeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_TreeNodeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_TreeNodeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_TreeNodeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_TreeNodeAttribute',
				       );
    }
}



=head2 $result = all_entities_TreeNodeAttribute(start, count, fields)



=cut

sub all_entities_TreeNodeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_TreeNodeAttribute (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_TreeNodeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_TreeNodeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_TreeNodeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_TreeNodeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_TreeNodeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_TreeNodeAttribute',
				       );
    }
}



=head2 $result = get_entity_Variant(ids, fields)

Each subsystem may include the designation of distinct
variants.  Thus, there may be three closely-related, but
distinguishable forms of histidine degradation.  Each form
would be called a "variant", with an associated code, and all
genomes implementing a specific variant can easily be accessed.
It has the following fields:

=over 4


=item role_rule

a space-delimited list of role IDs, in alphabetical order,
that represents a possible list of non-auxiliary roles applicable to
this variant. The roles are identified by their abbreviations. A
variant may have multiple role rules.


=item code

the variant code all by itself


=item type

variant type indicating the quality of the subsystem
support. A type of "vacant" means that the subsystem
does not appear to be implemented by the variant. A
type of "incomplete" means that the subsystem appears to be
missing many reactions. In all other cases, the type is
"normal".


=item comment

commentary text about the variant



=back

=cut

sub get_entity_Variant
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_entity_Variant (received $n, expecting 2)");
    }
    {
	my($ids, $fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_entity_Variant:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_entity_Variant');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_entity_Variant",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_entity_Variant',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_entity_Variant",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_entity_Variant',
				       );
    }
}



=head2 $result = query_entity_Variant(qry, fields)



=cut

sub query_entity_Variant
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function query_entity_Variant (received $n, expecting 2)");
    }
    {
	my($qry, $fields) = @args;

	my @_bad_arguments;
        (ref($qry) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"qry\" (value was \"$qry\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to query_entity_Variant:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'query_entity_Variant');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.query_entity_Variant",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'query_entity_Variant',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method query_entity_Variant",
					    status_line => $self->{client}->status_line,
					    method_name => 'query_entity_Variant',
				       );
    }
}



=head2 $result = all_entities_Variant(start, count, fields)



=cut

sub all_entities_Variant
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function all_entities_Variant (received $n, expecting 3)");
    }
    {
	my($start, $count, $fields) = @args;

	my @_bad_arguments;
        (!ref($start)) or push(@_bad_arguments, "Invalid type for argument 1 \"start\" (value was \"$start\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 2 \"count\" (value was \"$count\")");
        (ref($fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"fields\" (value was \"$fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to all_entities_Variant:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'all_entities_Variant');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.all_entities_Variant",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'all_entities_Variant',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method all_entities_Variant",
					    status_line => $self->{client}->status_line,
					    method_name => 'all_entities_Variant',
				       );
    }
}



=head2 $result = get_relationship_AffectsLevelOf(ids, from_fields, rel_fields, to_fields)

This relationship indicates the expression level of an atomic regulon
for a given experiment.
It has the following fields:

=over 4


=item level

Indication of whether the feature is expressed (1), not expressed (-1),
or unknown (0).



=back

=cut

sub get_relationship_AffectsLevelOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_AffectsLevelOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_AffectsLevelOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_AffectsLevelOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_AffectsLevelOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_AffectsLevelOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_AffectsLevelOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_AffectsLevelOf',
				       );
    }
}



=head2 $result = get_relationship_IsAffectedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsAffectedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAffectedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAffectedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAffectedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAffectedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAffectedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAffectedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAffectedIn',
				       );
    }
}



=head2 $result = get_relationship_Aligned(ids, from_fields, rel_fields, to_fields)

This relationship connects an alignment to the database
from which it was generated.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Aligned
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Aligned (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Aligned:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Aligned');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Aligned",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Aligned',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Aligned",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Aligned',
				       );
    }
}



=head2 $result = get_relationship_WasAlignedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_WasAlignedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_WasAlignedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_WasAlignedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_WasAlignedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_WasAlignedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_WasAlignedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_WasAlignedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_WasAlignedBy',
				       );
    }
}



=head2 $result = get_relationship_AssertsFunctionFor(ids, from_fields, rel_fields, to_fields)

Sources (users) can make assertions about protein sequence function.
The assertion is associated with an external identifier.
It has the following fields:

=over 4


=item function

text of the assertion made about the identifier.
It may be an empty string, indicating the function is unknown.


=item external_id

external identifier used in making the assertion


=item organism

organism name associated with this assertion. If the
assertion is not associated with a specific organism, this
will be an empty string.


=item gi_number

NCBI GI number associated with the asserted identifier


=item release_date

date and time the assertion was downloaded



=back

=cut

sub get_relationship_AssertsFunctionFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_AssertsFunctionFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_AssertsFunctionFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_AssertsFunctionFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_AssertsFunctionFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_AssertsFunctionFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_AssertsFunctionFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_AssertsFunctionFor',
				       );
    }
}



=head2 $result = get_relationship_HasAssertedFunctionFrom(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasAssertedFunctionFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasAssertedFunctionFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasAssertedFunctionFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasAssertedFunctionFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasAssertedFunctionFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasAssertedFunctionFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasAssertedFunctionFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasAssertedFunctionFrom',
				       );
    }
}



=head2 $result = get_relationship_BelongsTo(ids, from_fields, rel_fields, to_fields)

The BelongsTo relationship specifies the experimental
units performed on a particular strain.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_BelongsTo
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_BelongsTo (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_BelongsTo:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_BelongsTo');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_BelongsTo",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_BelongsTo',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_BelongsTo",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_BelongsTo',
				       );
    }
}



=head2 $result = get_relationship_IncludesStrain(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IncludesStrain
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IncludesStrain (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IncludesStrain:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IncludesStrain');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IncludesStrain",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IncludesStrain',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IncludesStrain",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IncludesStrain',
				       );
    }
}



=head2 $result = get_relationship_Concerns(ids, from_fields, rel_fields, to_fields)

This relationship connects a publication to the protein
sequences it describes.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Concerns
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Concerns (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Concerns:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Concerns');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Concerns",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Concerns',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Concerns",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Concerns',
				       );
    }
}



=head2 $result = get_relationship_IsATopicOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsATopicOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsATopicOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsATopicOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsATopicOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsATopicOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsATopicOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsATopicOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsATopicOf',
				       );
    }
}



=head2 $result = get_relationship_ConsistsOfCompounds(ids, from_fields, rel_fields, to_fields)

This relationship defines the subcompounds that make up a
compound. For example, CoCl2-6H2O is made up of 1 Co2+, 2 Cl-, and
6 H2O.
It has the following fields:

=over 4


=item molar_ratio

Number of molecules of the subcompound that make up
the compound. A -1 in this field signifies that although
the subcompound is present in the compound, the molar
ratio is unknown.



=back

=cut

sub get_relationship_ConsistsOfCompounds
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ConsistsOfCompounds (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ConsistsOfCompounds:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ConsistsOfCompounds');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ConsistsOfCompounds",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ConsistsOfCompounds',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ConsistsOfCompounds",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ConsistsOfCompounds',
				       );
    }
}



=head2 $result = get_relationship_ComponentOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_ComponentOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ComponentOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ComponentOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ComponentOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ComponentOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ComponentOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ComponentOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ComponentOf',
				       );
    }
}



=head2 $result = get_relationship_Contains(ids, from_fields, rel_fields, to_fields)

This relationship connects a subsystem spreadsheet cell to the features
that occur in it. A feature may occur in many machine roles and a
machine role may contain many features. The subsystem annotation
process is essentially the maintenance of this relationship.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Contains
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Contains (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Contains:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Contains');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Contains",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Contains',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Contains",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Contains',
				       );
    }
}



=head2 $result = get_relationship_IsContainedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsContainedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsContainedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsContainedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsContainedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsContainedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsContainedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsContainedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsContainedIn',
				       );
    }
}



=head2 $result = get_relationship_ContainsAlignedDNA(ids, from_fields, rel_fields, to_fields)

This relationship connects a nucleotide alignment row to the
contig sequences from which its components are formed.
It has the following fields:

=over 4


=item index_in_concatenation

1-based ordinal position in the alignment row of this
nucleotide sequence


=item beg_pos_in_parent

1-based position in the contig sequence of the first
nucleotide that appears in the alignment


=item end_pos_in_parent

1-based position in the contig sequence of the last
nucleotide that appears in the alignment


=item parent_seq_len

length of original sequence


=item beg_pos_aln

the 1-based column index in the alignment where this
nucleotide sequence begins


=item end_pos_aln

the 1-based column index in the alignment where this
nucleotide sequence ends


=item kb_feature_id

ID of the feature relevant to this sequence, or an
empty string if the sequence is not specific to a genome



=back

=cut

sub get_relationship_ContainsAlignedDNA
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ContainsAlignedDNA (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ContainsAlignedDNA:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ContainsAlignedDNA');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ContainsAlignedDNA",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ContainsAlignedDNA',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ContainsAlignedDNA",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ContainsAlignedDNA',
				       );
    }
}



=head2 $result = get_relationship_IsAlignedDNAComponentOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsAlignedDNAComponentOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAlignedDNAComponentOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAlignedDNAComponentOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAlignedDNAComponentOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAlignedDNAComponentOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAlignedDNAComponentOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAlignedDNAComponentOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAlignedDNAComponentOf',
				       );
    }
}



=head2 $result = get_relationship_ContainsAlignedProtein(ids, from_fields, rel_fields, to_fields)

This relationship connects a protein alignment row to the
protein sequences from which its components are formed.
It has the following fields:

=over 4


=item index_in_concatenation

1-based ordinal position in the alignment row of this
protein sequence


=item beg_pos_in_parent

1-based position in the protein sequence of the first
amino acid that appears in the alignment


=item end_pos_in_parent

1-based position in the protein sequence of the last
amino acid that appears in the alignment


=item parent_seq_len

length of original sequence


=item beg_pos_aln

the 1-based column index in the alignment where this
protein sequence begins


=item end_pos_aln

the 1-based column index in the alignment where this
protein sequence ends


=item kb_feature_id

ID of the feature relevant to this protein, or an
empty string if the protein is not specific to a genome



=back

=cut

sub get_relationship_ContainsAlignedProtein
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ContainsAlignedProtein (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ContainsAlignedProtein:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ContainsAlignedProtein');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ContainsAlignedProtein",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ContainsAlignedProtein',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ContainsAlignedProtein",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ContainsAlignedProtein',
				       );
    }
}



=head2 $result = get_relationship_IsAlignedProteinComponentOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsAlignedProteinComponentOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAlignedProteinComponentOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAlignedProteinComponentOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAlignedProteinComponentOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAlignedProteinComponentOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAlignedProteinComponentOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAlignedProteinComponentOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAlignedProteinComponentOf',
				       );
    }
}



=head2 $result = get_relationship_Controls(ids, from_fields, rel_fields, to_fields)

This relationship connects a coregulated set to the
features that are used as its transcription factors.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Controls
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Controls (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Controls:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Controls');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Controls",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Controls',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Controls",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Controls',
				       );
    }
}



=head2 $result = get_relationship_IsControlledUsing(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsControlledUsing
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsControlledUsing (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsControlledUsing:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsControlledUsing');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsControlledUsing",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsControlledUsing',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsControlledUsing",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsControlledUsing',
				       );
    }
}



=head2 $result = get_relationship_DerivedFromStrain(ids, from_fields, rel_fields, to_fields)

The recursive DerivedFromStrain relationship organizes derived
organisms into a tree based on parent/child relationships.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_DerivedFromStrain
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DerivedFromStrain (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DerivedFromStrain:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DerivedFromStrain');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DerivedFromStrain",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DerivedFromStrain',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DerivedFromStrain",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DerivedFromStrain',
				       );
    }
}



=head2 $result = get_relationship_StrainParentOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_StrainParentOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_StrainParentOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_StrainParentOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_StrainParentOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_StrainParentOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_StrainParentOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_StrainParentOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_StrainParentOf',
				       );
    }
}



=head2 $result = get_relationship_Describes(ids, from_fields, rel_fields, to_fields)

This relationship connects a subsystem to the individual
variants used to implement it. Each variant contains a slightly
different subset of the roles in the parent subsystem.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Describes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Describes (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Describes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Describes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Describes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Describes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Describes",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Describes',
				       );
    }
}



=head2 $result = get_relationship_IsDescribedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsDescribedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsDescribedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsDescribedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsDescribedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsDescribedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsDescribedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsDescribedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsDescribedBy',
				       );
    }
}



=head2 $result = get_relationship_DescribesAlignment(ids, from_fields, rel_fields, to_fields)

This relationship connects an alignment to its free-form
attributes.
It has the following fields:

=over 4


=item value

value of this attribute



=back

=cut

sub get_relationship_DescribesAlignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DescribesAlignment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DescribesAlignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DescribesAlignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DescribesAlignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DescribesAlignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DescribesAlignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DescribesAlignment',
				       );
    }
}



=head2 $result = get_relationship_HasAlignmentAttribute(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasAlignmentAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasAlignmentAttribute (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasAlignmentAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasAlignmentAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasAlignmentAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasAlignmentAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasAlignmentAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasAlignmentAttribute',
				       );
    }
}



=head2 $result = get_relationship_DescribesTree(ids, from_fields, rel_fields, to_fields)

This relationship connects a tree to its free-form
attributes.
It has the following fields:

=over 4


=item value

value of this attribute



=back

=cut

sub get_relationship_DescribesTree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DescribesTree (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DescribesTree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DescribesTree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DescribesTree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DescribesTree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DescribesTree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DescribesTree',
				       );
    }
}



=head2 $result = get_relationship_HasTreeAttribute(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasTreeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasTreeAttribute (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasTreeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasTreeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasTreeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasTreeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasTreeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasTreeAttribute',
				       );
    }
}



=head2 $result = get_relationship_DescribesTreeNode(ids, from_fields, rel_fields, to_fields)

This relationship connects an tree to the free-form
attributes of its nodes.
It has the following fields:

=over 4


=item value

value of this attribute


=item node_id

ID of the node described by the attribute



=back

=cut

sub get_relationship_DescribesTreeNode
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DescribesTreeNode (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DescribesTreeNode:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DescribesTreeNode');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DescribesTreeNode",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DescribesTreeNode',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DescribesTreeNode",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DescribesTreeNode',
				       );
    }
}



=head2 $result = get_relationship_HasNodeAttribute(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasNodeAttribute
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasNodeAttribute (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasNodeAttribute:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasNodeAttribute');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasNodeAttribute",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasNodeAttribute',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasNodeAttribute",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasNodeAttribute',
				       );
    }
}



=head2 $result = get_relationship_Displays(ids, from_fields, rel_fields, to_fields)

This relationship connects a diagram to its reactions. A
diagram shows multiple reactions, and a reaction can be on many
diagrams.
It has the following fields:

=over 4


=item location

Location of the reaction's node on the diagram.



=back

=cut

sub get_relationship_Displays
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Displays (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Displays:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Displays');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Displays",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Displays',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Displays",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Displays',
				       );
    }
}



=head2 $result = get_relationship_IsDisplayedOn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsDisplayedOn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsDisplayedOn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsDisplayedOn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsDisplayedOn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsDisplayedOn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsDisplayedOn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsDisplayedOn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsDisplayedOn',
				       );
    }
}



=head2 $result = get_relationship_Encompasses(ids, from_fields, rel_fields, to_fields)

This relationship connects a feature to a related
feature; for example, it would connect a gene to its
constituent splice variants, and the splice variants to their
exons.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Encompasses
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Encompasses (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Encompasses:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Encompasses');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Encompasses",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Encompasses',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Encompasses",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Encompasses',
				       );
    }
}



=head2 $result = get_relationship_IsEncompassedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsEncompassedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsEncompassedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsEncompassedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsEncompassedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsEncompassedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsEncompassedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsEncompassedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsEncompassedIn',
				       );
    }
}



=head2 $result = get_relationship_Formulated(ids, from_fields, rel_fields, to_fields)

This relationship connects a coregulated set to the
source organization that originally computed it.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Formulated
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Formulated (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Formulated:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Formulated');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Formulated",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Formulated',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Formulated",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Formulated',
				       );
    }
}



=head2 $result = get_relationship_WasFormulatedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_WasFormulatedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_WasFormulatedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_WasFormulatedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_WasFormulatedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_WasFormulatedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_WasFormulatedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_WasFormulatedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_WasFormulatedBy',
				       );
    }
}



=head2 $result = get_relationship_GeneratedLevelsFor(ids, from_fields, rel_fields, to_fields)

This relationship connects an atomic regulon to a probe set from which experimental
data was produced for its features. It contains a vector of the expression levels.
It has the following fields:

=over 4


=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in
sequence order.



=back

=cut

sub get_relationship_GeneratedLevelsFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_GeneratedLevelsFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_GeneratedLevelsFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_GeneratedLevelsFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_GeneratedLevelsFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_GeneratedLevelsFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_GeneratedLevelsFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_GeneratedLevelsFor',
				       );
    }
}



=head2 $result = get_relationship_WasGeneratedFrom(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_WasGeneratedFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_WasGeneratedFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_WasGeneratedFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_WasGeneratedFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_WasGeneratedFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_WasGeneratedFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_WasGeneratedFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_WasGeneratedFrom',
				       );
    }
}



=head2 $result = get_relationship_GenomeParentOf(ids, from_fields, rel_fields, to_fields)

The DerivedFromGenome relationship specifies the direct child
strains of a specific genome.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_GenomeParentOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_GenomeParentOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_GenomeParentOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_GenomeParentOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_GenomeParentOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_GenomeParentOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_GenomeParentOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_GenomeParentOf',
				       );
    }
}



=head2 $result = get_relationship_DerivedFromGenome(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_DerivedFromGenome
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DerivedFromGenome (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DerivedFromGenome:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DerivedFromGenome');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DerivedFromGenome",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DerivedFromGenome',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DerivedFromGenome",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DerivedFromGenome',
				       );
    }
}



=head2 $result = get_relationship_HasAssociatedMeasurement(ids, from_fields, rel_fields, to_fields)

The HasAssociatedMeasurement relationship specifies a measurement that
measures a phenotype.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasAssociatedMeasurement
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasAssociatedMeasurement (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasAssociatedMeasurement:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasAssociatedMeasurement');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasAssociatedMeasurement",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasAssociatedMeasurement',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasAssociatedMeasurement",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasAssociatedMeasurement',
				       );
    }
}



=head2 $result = get_relationship_MeasuresPhenotype(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_MeasuresPhenotype
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_MeasuresPhenotype (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_MeasuresPhenotype:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_MeasuresPhenotype');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_MeasuresPhenotype",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_MeasuresPhenotype',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_MeasuresPhenotype",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_MeasuresPhenotype',
				       );
    }
}



=head2 $result = get_relationship_HasCompoundAliasFrom(ids, from_fields, rel_fields, to_fields)

This relationship connects a source (database or organization)
with the compounds for which it has assigned names (aliases).
The alias itself is stored as intersection data.
It has the following fields:

=over 4


=item alias

alias for the compound assigned by the source



=back

=cut

sub get_relationship_HasCompoundAliasFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasCompoundAliasFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasCompoundAliasFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasCompoundAliasFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasCompoundAliasFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasCompoundAliasFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasCompoundAliasFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasCompoundAliasFrom',
				       );
    }
}



=head2 $result = get_relationship_UsesAliasForCompound(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_UsesAliasForCompound
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsesAliasForCompound (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsesAliasForCompound:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsesAliasForCompound');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsesAliasForCompound",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsesAliasForCompound',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsesAliasForCompound",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsesAliasForCompound',
				       );
    }
}



=head2 $result = get_relationship_HasExperimentalUnit(ids, from_fields, rel_fields, to_fields)

The HasExperimentalUnit relationship describes which
ExperimentalUnits are part of a PhenotypeExperiment.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasExperimentalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasExperimentalUnit (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasExperimentalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasExperimentalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasExperimentalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasExperimentalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasExperimentalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasExperimentalUnit',
				       );
    }
}



=head2 $result = get_relationship_IsExperimentalUnitOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsExperimentalUnitOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsExperimentalUnitOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsExperimentalUnitOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsExperimentalUnitOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsExperimentalUnitOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsExperimentalUnitOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsExperimentalUnitOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsExperimentalUnitOf',
				       );
    }
}



=head2 $result = get_relationship_HasIndicatedSignalFrom(ids, from_fields, rel_fields, to_fields)

This relationship connects an experiment to a feature. The feature
expression levels inferred from the experimental results are stored here.
It has the following fields:

=over 4


=item rma_value

Normalized expression value for this feature under the experiment's
conditions.


=item level

Indication of whether the feature is expressed (1), not expressed (-1),
or unknown (0).



=back

=cut

sub get_relationship_HasIndicatedSignalFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasIndicatedSignalFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasIndicatedSignalFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasIndicatedSignalFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasIndicatedSignalFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasIndicatedSignalFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasIndicatedSignalFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasIndicatedSignalFrom',
				       );
    }
}



=head2 $result = get_relationship_IndicatesSignalFor(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IndicatesSignalFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IndicatesSignalFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IndicatesSignalFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IndicatesSignalFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IndicatesSignalFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IndicatesSignalFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IndicatesSignalFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IndicatesSignalFor',
				       );
    }
}



=head2 $result = get_relationship_HasKnockoutIn(ids, from_fields, rel_fields, to_fields)

The HasKnockoutIn relationship specifies the gene knockouts in
a particular strain.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasKnockoutIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasKnockoutIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasKnockoutIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasKnockoutIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasKnockoutIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasKnockoutIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasKnockoutIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasKnockoutIn',
				       );
    }
}



=head2 $result = get_relationship_KnockedOutIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_KnockedOutIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_KnockedOutIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_KnockedOutIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_KnockedOutIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_KnockedOutIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_KnockedOutIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_KnockedOutIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_KnockedOutIn',
				       );
    }
}



=head2 $result = get_relationship_HasMeasurement(ids, from_fields, rel_fields, to_fields)

The HasMeasurement relationship specifies a measurement
performed on a particular experimental unit.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasMeasurement
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasMeasurement (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasMeasurement:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasMeasurement');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasMeasurement",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasMeasurement',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasMeasurement",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasMeasurement',
				       );
    }
}



=head2 $result = get_relationship_IsMeasureOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsMeasureOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsMeasureOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsMeasureOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsMeasureOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsMeasureOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsMeasureOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsMeasureOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsMeasureOf',
				       );
    }
}



=head2 $result = get_relationship_HasMember(ids, from_fields, rel_fields, to_fields)

This relationship connects each feature family to its
constituent features. A family always has many features, and a
single feature can be found in many families.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasMember
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasMember (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasMember:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasMember');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasMember",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasMember',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasMember",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasMember',
				       );
    }
}



=head2 $result = get_relationship_IsMemberOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsMemberOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsMemberOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsMemberOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsMemberOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsMemberOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsMemberOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsMemberOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsMemberOf',
				       );
    }
}



=head2 $result = get_relationship_HasParticipant(ids, from_fields, rel_fields, to_fields)

A scenario consists of many participant reactions that
convert the input compounds to output compounds. A single reaction
may participate in many scenarios.
It has the following fields:

=over 4


=item type

Indicates the type of participaton. If 0, the
reaction is in the main pathway of the scenario. If 1, the
reaction is necessary to make the model work but is not in
the subsystem. If 2, the reaction is part of the subsystem
but should not be included in the modelling process.



=back

=cut

sub get_relationship_HasParticipant
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasParticipant (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasParticipant:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasParticipant');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasParticipant",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasParticipant',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasParticipant",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasParticipant',
				       );
    }
}



=head2 $result = get_relationship_ParticipatesIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_ParticipatesIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ParticipatesIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ParticipatesIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ParticipatesIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ParticipatesIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ParticipatesIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ParticipatesIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ParticipatesIn',
				       );
    }
}



=head2 $result = get_relationship_HasPresenceOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a media to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.
It has the following fields:

=over 4


=item concentration

concentration of the compound in the media


=item maximum_flux

maximum allowed increase in this compound


=item minimum_flux

maximum allowed decrease in this compound



=back

=cut

sub get_relationship_HasPresenceOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasPresenceOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasPresenceOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasPresenceOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasPresenceOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasPresenceOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasPresenceOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasPresenceOf',
				       );
    }
}



=head2 $result = get_relationship_IsPresentIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsPresentIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsPresentIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsPresentIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsPresentIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsPresentIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsPresentIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsPresentIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsPresentIn',
				       );
    }
}



=head2 $result = get_relationship_HasProteinMember(ids, from_fields, rel_fields, to_fields)

This relationship connects each feature family to its
constituent protein sequences. A family always has many protein sequences,
and a single sequence can be found in many families.
It has the following fields:

=over 4


=item source_id

Native identifier used for the protein in the definition
of the family. This will be its ID in the alignment, if one
exists.



=back

=cut

sub get_relationship_HasProteinMember
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasProteinMember (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasProteinMember:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasProteinMember');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasProteinMember",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasProteinMember',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasProteinMember",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasProteinMember',
				       );
    }
}



=head2 $result = get_relationship_IsProteinMemberOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsProteinMemberOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsProteinMemberOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsProteinMemberOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsProteinMemberOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsProteinMemberOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsProteinMemberOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsProteinMemberOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsProteinMemberOf',
				       );
    }
}



=head2 $result = get_relationship_HasReactionAliasFrom(ids, from_fields, rel_fields, to_fields)

This relationship connects a source (database or organization)
with the reactions for which it has assigned names (aliases).
The alias itself is stored as intersection data.
It has the following fields:

=over 4


=item alias

alias for the reaction assigned by the source



=back

=cut

sub get_relationship_HasReactionAliasFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasReactionAliasFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasReactionAliasFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasReactionAliasFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasReactionAliasFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasReactionAliasFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasReactionAliasFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasReactionAliasFrom',
				       );
    }
}



=head2 $result = get_relationship_UsesAliasForReaction(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_UsesAliasForReaction
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsesAliasForReaction (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsesAliasForReaction:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsesAliasForReaction');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsesAliasForReaction",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsesAliasForReaction',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsesAliasForReaction",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsesAliasForReaction',
				       );
    }
}



=head2 $result = get_relationship_HasRepresentativeOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to the FIGfam protein families
for which it has representative proteins. This information can be computed
from other relationships, but it is provided explicitly to allow fast access
to a genome's FIGfam profile.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasRepresentativeOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasRepresentativeOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasRepresentativeOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasRepresentativeOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasRepresentativeOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasRepresentativeOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasRepresentativeOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasRepresentativeOf',
				       );
    }
}



=head2 $result = get_relationship_IsRepresentedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsRepresentedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRepresentedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRepresentedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRepresentedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRepresentedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRepresentedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRepresentedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRepresentedIn',
				       );
    }
}



=head2 $result = get_relationship_HasRequirementOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a model to the instances of
reactions that represent how the reactions occur in the model.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasRequirementOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasRequirementOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasRequirementOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasRequirementOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasRequirementOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasRequirementOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasRequirementOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasRequirementOf',
				       );
    }
}



=head2 $result = get_relationship_IsARequirementOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsARequirementOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsARequirementOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsARequirementOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsARequirementOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsARequirementOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsARequirementOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsARequirementOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsARequirementOf',
				       );
    }
}



=head2 $result = get_relationship_HasResultsIn(ids, from_fields, rel_fields, to_fields)

This relationship connects a probe set to the experiments that were
applied to it.
It has the following fields:

=over 4


=item sequence

Sequence number of this experiment in the various result vectors.



=back

=cut

sub get_relationship_HasResultsIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasResultsIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasResultsIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasResultsIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasResultsIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasResultsIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasResultsIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasResultsIn',
				       );
    }
}



=head2 $result = get_relationship_HasResultsFor(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasResultsFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasResultsFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasResultsFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasResultsFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasResultsFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasResultsFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasResultsFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasResultsFor',
				       );
    }
}



=head2 $result = get_relationship_HasSection(ids, from_fields, rel_fields, to_fields)

This relationship connects a contig's sequence to its DNA
sequences.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasSection
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasSection (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasSection:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasSection');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasSection",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasSection',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasSection",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasSection',
				       );
    }
}



=head2 $result = get_relationship_IsSectionOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsSectionOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSectionOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSectionOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSectionOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSectionOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSectionOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSectionOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSectionOf',
				       );
    }
}



=head2 $result = get_relationship_HasStep(ids, from_fields, rel_fields, to_fields)

This relationship connects a complex to the reactions it
catalyzes.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasStep
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasStep (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasStep:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasStep');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasStep",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasStep',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasStep",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasStep',
				       );
    }
}



=head2 $result = get_relationship_IsStepOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsStepOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsStepOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsStepOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsStepOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsStepOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsStepOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsStepOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsStepOf',
				       );
    }
}



=head2 $result = get_relationship_HasTrait(ids, from_fields, rel_fields, to_fields)

This relationship contains the measurement values of a trait on a specific observational Unit
It has the following fields:

=over 4


=item value

value of the trait measurement


=item statistic_type

text description of the statistic type (e.g. mean, median)


=item measure_id

internal ID given to this measurement



=back

=cut

sub get_relationship_HasTrait
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasTrait (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasTrait:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasTrait');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasTrait",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasTrait',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasTrait",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasTrait',
				       );
    }
}



=head2 $result = get_relationship_Measures(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Measures
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Measures (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Measures:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Measures');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Measures",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Measures',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Measures",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Measures',
				       );
    }
}



=head2 $result = get_relationship_HasUnits(ids, from_fields, rel_fields, to_fields)

This relationship associates observational units with the
geographic location where the unit is planted.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasUnits
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasUnits (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasUnits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasUnits');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasUnits",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasUnits',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasUnits",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasUnits',
				       );
    }
}



=head2 $result = get_relationship_IsLocated(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsLocated
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsLocated (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsLocated:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsLocated');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsLocated",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsLocated',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsLocated",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsLocated',
				       );
    }
}



=head2 $result = get_relationship_HasUsage(ids, from_fields, rel_fields, to_fields)

This relationship connects a specific compound in a model to the localized
compound to which it corresponds.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_HasUsage
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasUsage (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasUsage:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasUsage');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasUsage",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasUsage',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasUsage",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasUsage',
				       );
    }
}



=head2 $result = get_relationship_IsUsageOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsUsageOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsUsageOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsUsageOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsUsageOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsUsageOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsUsageOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsUsageOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsUsageOf',
				       );
    }
}



=head2 $result = get_relationship_HasValueFor(ids, from_fields, rel_fields, to_fields)

This relationship connects an experiment to its attributes. The attribute
values are stored here.
It has the following fields:

=over 4


=item value

Value of this attribute in the given experiment. This is always encoded
as a string, but may in fact be a number.



=back

=cut

sub get_relationship_HasValueFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasValueFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasValueFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasValueFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasValueFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasValueFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasValueFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasValueFor',
				       );
    }
}



=head2 $result = get_relationship_HasValueIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasValueIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasValueIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasValueIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasValueIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasValueIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasValueIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasValueIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasValueIn',
				       );
    }
}



=head2 $result = get_relationship_HasVariationIn(ids, from_fields, rel_fields, to_fields)

This relationship defines an observational unit's DNA variation
from a contig in the reference genome.
It has the following fields:

=over 4


=item position

Position of this variation in the reference contig.


=item len

Length of the variation in the reference contig. A length
of zero indicates an insertion.


=item data

Replacement DNA for the variation on the primary chromosome. An
empty string indicates a deletion. The primary chromosome is chosen
arbitrarily among the two chromosomes of a plant's chromosome pair
(one coming from the mother and one from the father).


=item data2

Replacement DNA for the variation on the secondary chromosome.
This will frequently be the same as the primary chromosome string.


=item quality

Quality score assigned to this variation.



=back

=cut

sub get_relationship_HasVariationIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasVariationIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasVariationIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasVariationIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasVariationIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasVariationIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasVariationIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasVariationIn',
				       );
    }
}



=head2 $result = get_relationship_IsVariedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsVariedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsVariedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsVariedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsVariedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsVariedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsVariedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsVariedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsVariedIn',
				       );
    }
}



=head2 $result = get_relationship_Impacts(ids, from_fields, rel_fields, to_fields)

This relationship contains the best scoring statistical correlations between measured traits and the responsible alleles.
It has the following fields:

=over 4


=item source_name

Name of the study which analyzed the data and determined that a variation has impact on a trait


=item rank

Rank of the position among all positions correlated with this trait.


=item pvalue

P-value of the correlation between the variation and the trait


=item position

Position in the reference contig where the trait
has an impact.



=back

=cut

sub get_relationship_Impacts
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Impacts (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Impacts:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Impacts');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Impacts",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Impacts',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Impacts",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Impacts',
				       );
    }
}



=head2 $result = get_relationship_IsImpactedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsImpactedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsImpactedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsImpactedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsImpactedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsImpactedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsImpactedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsImpactedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsImpactedBy',
				       );
    }
}



=head2 $result = get_relationship_Includes(ids, from_fields, rel_fields, to_fields)

A subsystem is defined by its roles. The subsystem's variants
contain slightly different sets of roles, but all of the roles in a
variant must be connected to the parent subsystem by this
relationship. A subsystem always has at least one role, and a role
always belongs to at least one subsystem.
It has the following fields:

=over 4


=item sequence

Sequence number of the role within the subsystem.
When the roles are formed into a variant, they will
generally appear in sequence order.


=item abbreviation

Abbreviation for this role in this subsystem. The
abbreviations are used in columnar displays, and they also
appear on diagrams.


=item auxiliary

TRUE if this is an auxiliary role, or FALSE if this role
is a functioning part of the subsystem.



=back

=cut

sub get_relationship_Includes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Includes (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Includes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Includes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Includes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Includes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Includes",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Includes',
				       );
    }
}



=head2 $result = get_relationship_IsIncludedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsIncludedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsIncludedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsIncludedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsIncludedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsIncludedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsIncludedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsIncludedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsIncludedIn',
				       );
    }
}



=head2 $result = get_relationship_IncludesAdditionalCompounds(ids, from_fields, rel_fields, to_fields)

This relationship connects a environment to the compounds that
occur in it. The intersection data describes how much of each
compound can be found.
It has the following fields:

=over 4


=item concentration

concentration of the compound in the environment


=item units

vol%, g/L, or molar (mol/L).



=back

=cut

sub get_relationship_IncludesAdditionalCompounds
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IncludesAdditionalCompounds (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IncludesAdditionalCompounds:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IncludesAdditionalCompounds');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IncludesAdditionalCompounds",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IncludesAdditionalCompounds',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IncludesAdditionalCompounds",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IncludesAdditionalCompounds',
				       );
    }
}



=head2 $result = get_relationship_IncludedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IncludedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IncludedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IncludedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IncludedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IncludedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IncludedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IncludedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IncludedIn',
				       );
    }
}



=head2 $result = get_relationship_IncludesAlignmentRow(ids, from_fields, rel_fields, to_fields)

This relationship connects an alignment to its component
rows.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IncludesAlignmentRow
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IncludesAlignmentRow (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IncludesAlignmentRow:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IncludesAlignmentRow');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IncludesAlignmentRow",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IncludesAlignmentRow',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IncludesAlignmentRow",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IncludesAlignmentRow',
				       );
    }
}



=head2 $result = get_relationship_IsAlignmentRowIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsAlignmentRowIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAlignmentRowIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAlignmentRowIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAlignmentRowIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAlignmentRowIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAlignmentRowIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAlignmentRowIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAlignmentRowIn',
				       );
    }
}



=head2 $result = get_relationship_IncludesPart(ids, from_fields, rel_fields, to_fields)

This relationship associates observational units with the
experiments that generated the data on them.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IncludesPart
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IncludesPart (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IncludesPart:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IncludesPart');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IncludesPart",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IncludesPart',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IncludesPart",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IncludesPart',
				       );
    }
}



=head2 $result = get_relationship_IsPartOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsPartOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsPartOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsPartOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsPartOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsPartOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsPartOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsPartOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsPartOf',
				       );
    }
}



=head2 $result = get_relationship_IndicatedLevelsFor(ids, from_fields, rel_fields, to_fields)

This relationship connects a feature to a probe set from which experimental
data was produced for the feature. It contains a vector of the expression levels.
It has the following fields:

=over 4


=item level_vector

Vector of expression levels (-1, 0, 1) for the experiments, in
sequence order.



=back

=cut

sub get_relationship_IndicatedLevelsFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IndicatedLevelsFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IndicatedLevelsFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IndicatedLevelsFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IndicatedLevelsFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IndicatedLevelsFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IndicatedLevelsFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IndicatedLevelsFor',
				       );
    }
}



=head2 $result = get_relationship_HasLevelsFrom(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasLevelsFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasLevelsFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasLevelsFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasLevelsFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasLevelsFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasLevelsFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasLevelsFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasLevelsFrom',
				       );
    }
}



=head2 $result = get_relationship_Involves(ids, from_fields, rel_fields, to_fields)

This relationship connects a reaction to the
specific localized compounds that participate in it.
It has the following fields:

=over 4


=item coefficient

Number of molecules of the compound that participate
in a single instance of the reaction. For example, if a
reaction produces two water molecules, the stoichiometry of
water for the reaction would be two. When a reaction is
written on paper in chemical notation, the stoichiometry is
the number next to the chemical formula of the
compound. The value is negative for substrates and positive
for products.


=item cofactor

TRUE if the compound is a cofactor; FALSE if it is a major
component of the reaction.



=back

=cut

sub get_relationship_Involves
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Involves (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Involves:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Involves');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Involves",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Involves',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Involves",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Involves',
				       );
    }
}



=head2 $result = get_relationship_IsInvolvedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsInvolvedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInvolvedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInvolvedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInvolvedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInvolvedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInvolvedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInvolvedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInvolvedIn',
				       );
    }
}



=head2 $result = get_relationship_IsAnnotatedBy(ids, from_fields, rel_fields, to_fields)

This relationship connects a feature to its annotations. A
feature may have multiple annotations, but an annotation belongs to
only one feature.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsAnnotatedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAnnotatedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAnnotatedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAnnotatedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAnnotatedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAnnotatedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAnnotatedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAnnotatedBy',
				       );
    }
}



=head2 $result = get_relationship_Annotates(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Annotates
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Annotates (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Annotates:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Annotates');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Annotates",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Annotates',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Annotates",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Annotates',
				       );
    }
}



=head2 $result = get_relationship_IsAssayOf(ids, from_fields, rel_fields, to_fields)

This relationship associates each assay with the relevant
experiments.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsAssayOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAssayOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAssayOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAssayOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAssayOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAssayOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAssayOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAssayOf',
				       );
    }
}



=head2 $result = get_relationship_IsAssayedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsAssayedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsAssayedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsAssayedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsAssayedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsAssayedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsAssayedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsAssayedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsAssayedBy',
				       );
    }
}



=head2 $result = get_relationship_IsClassFor(ids, from_fields, rel_fields, to_fields)

This relationship connects each subsystem class with the
subsystems that belong to it. A class can contain many subsystems,
but a subsystem is only in one class. Some subsystems are not in any
class, but this is usually a temporary condition.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsClassFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsClassFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsClassFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsClassFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsClassFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsClassFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsClassFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsClassFor',
				       );
    }
}



=head2 $result = get_relationship_IsInClass(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsInClass
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInClass (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInClass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInClass');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInClass",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInClass',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInClass",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInClass',
				       );
    }
}



=head2 $result = get_relationship_IsCollectionOf(ids, from_fields, rel_fields, to_fields)

A genome belongs to only one genome set. For each set, this relationship marks the genome to be used as its representative.
It has the following fields:

=over 4


=item representative

TRUE for the representative genome of the set, else FALSE.



=back

=cut

sub get_relationship_IsCollectionOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsCollectionOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsCollectionOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsCollectionOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsCollectionOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsCollectionOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsCollectionOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsCollectionOf',
				       );
    }
}



=head2 $result = get_relationship_IsCollectedInto(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsCollectedInto
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsCollectedInto (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsCollectedInto:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsCollectedInto');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsCollectedInto",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsCollectedInto',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsCollectedInto",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsCollectedInto',
				       );
    }
}



=head2 $result = get_relationship_IsComposedOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to its
constituent contigs. Unlike contig sequences, a
contig belongs to only one genome.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsComposedOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsComposedOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsComposedOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsComposedOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsComposedOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsComposedOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsComposedOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsComposedOf',
				       );
    }
}



=head2 $result = get_relationship_IsComponentOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsComponentOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsComponentOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsComponentOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsComponentOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsComponentOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsComponentOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsComponentOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsComponentOf',
				       );
    }
}



=head2 $result = get_relationship_IsComprisedOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a biomass composition reaction to the
compounds specified as contained in the biomass.
It has the following fields:

=over 4


=item coefficient

number of millimoles of the compound instance that exists in one
gram cell dry weight of biomass



=back

=cut

sub get_relationship_IsComprisedOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsComprisedOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsComprisedOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsComprisedOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsComprisedOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsComprisedOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsComprisedOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsComprisedOf',
				       );
    }
}



=head2 $result = get_relationship_Comprises(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Comprises
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Comprises (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Comprises:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Comprises');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Comprises",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Comprises',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Comprises",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Comprises',
				       );
    }
}



=head2 $result = get_relationship_IsConfiguredBy(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to the atomic regulons that
describe its state.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsConfiguredBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsConfiguredBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsConfiguredBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsConfiguredBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsConfiguredBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsConfiguredBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsConfiguredBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsConfiguredBy',
				       );
    }
}



=head2 $result = get_relationship_ReflectsStateOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_ReflectsStateOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ReflectsStateOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ReflectsStateOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ReflectsStateOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ReflectsStateOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ReflectsStateOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ReflectsStateOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ReflectsStateOf',
				       );
    }
}



=head2 $result = get_relationship_IsConsistentWith(ids, from_fields, rel_fields, to_fields)

This relationship connects a functional role to the EC numbers consistent
with the chemistry described in the role.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsConsistentWith
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsConsistentWith (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsConsistentWith:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsConsistentWith');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsConsistentWith",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsConsistentWith',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsConsistentWith",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsConsistentWith',
				       );
    }
}



=head2 $result = get_relationship_IsConsistentTo(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsConsistentTo
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsConsistentTo (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsConsistentTo:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsConsistentTo');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsConsistentTo",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsConsistentTo',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsConsistentTo",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsConsistentTo',
				       );
    }
}



=head2 $result = get_relationship_IsCoregulatedWith(ids, from_fields, rel_fields, to_fields)

This relationship connects a feature with another feature in the
same genome with which it appears to be coregulated as a result of
expression data analysis.
It has the following fields:

=over 4


=item coefficient

Pearson correlation coefficient for this coregulation.



=back

=cut

sub get_relationship_IsCoregulatedWith
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsCoregulatedWith (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsCoregulatedWith:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsCoregulatedWith');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsCoregulatedWith",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsCoregulatedWith',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsCoregulatedWith",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsCoregulatedWith',
				       );
    }
}



=head2 $result = get_relationship_HasCoregulationWith(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasCoregulationWith
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasCoregulationWith (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasCoregulationWith:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasCoregulationWith');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasCoregulationWith",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasCoregulationWith',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasCoregulationWith",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasCoregulationWith',
				       );
    }
}



=head2 $result = get_relationship_IsCoupledTo(ids, from_fields, rel_fields, to_fields)

This relationship connects two FIGfams that we believe to be related
either because their members occur in proximity on chromosomes or because
the members are expressed together. Such a relationship is evidence the
functions of the FIGfams are themselves related. This relationship is
commutative; only the instance in which the first FIGfam has a lower ID
than the second is stored.
It has the following fields:

=over 4


=item co_occurrence_evidence

number of times members of the two FIGfams occur close to each
other on chromosomes


=item co_expression_evidence

number of times members of the two FIGfams are co-expressed in
expression data experiments



=back

=cut

sub get_relationship_IsCoupledTo
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsCoupledTo (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsCoupledTo:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsCoupledTo');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsCoupledTo",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsCoupledTo',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsCoupledTo",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsCoupledTo',
				       );
    }
}



=head2 $result = get_relationship_IsCoupledWith(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsCoupledWith
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsCoupledWith (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsCoupledWith:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsCoupledWith');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsCoupledWith",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsCoupledWith',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsCoupledWith",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsCoupledWith',
				       );
    }
}



=head2 $result = get_relationship_IsDeterminedBy(ids, from_fields, rel_fields, to_fields)

A functional coupling evidence set exists because it has
pairings in it, and this relationship connects the evidence set to
its constituent pairings. A pairing cam belong to multiple evidence
sets.
It has the following fields:

=over 4


=item inverted

A pairing is an unordered pair of protein sequences,
but its similarity to other pairings in a pair set is
ordered. Let (A,B) be a pairing and (X,Y) be another pairing
in the same set. If this flag is FALSE, then (A =~ X) and (B
=~ Y). If this flag is TRUE, then (A =~ Y) and (B =~
X).



=back

=cut

sub get_relationship_IsDeterminedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsDeterminedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsDeterminedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsDeterminedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsDeterminedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsDeterminedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsDeterminedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsDeterminedBy',
				       );
    }
}



=head2 $result = get_relationship_Determines(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Determines
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Determines (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Determines:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Determines');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Determines",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Determines',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Determines",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Determines',
				       );
    }
}



=head2 $result = get_relationship_IsDividedInto(ids, from_fields, rel_fields, to_fields)

This relationship connects a model to its instances of
subcellular locations that participate in the model.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsDividedInto
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsDividedInto (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsDividedInto:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsDividedInto');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsDividedInto",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsDividedInto',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsDividedInto",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsDividedInto',
				       );
    }
}



=head2 $result = get_relationship_IsDivisionOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsDivisionOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsDivisionOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsDivisionOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsDivisionOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsDivisionOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsDivisionOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsDivisionOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsDivisionOf',
				       );
    }
}



=head2 $result = get_relationship_IsExecutedAs(ids, from_fields, rel_fields, to_fields)

This relationship links a reaction to the way it is used in a model.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsExecutedAs
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsExecutedAs (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsExecutedAs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsExecutedAs');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsExecutedAs",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsExecutedAs',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsExecutedAs",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsExecutedAs',
				       );
    }
}



=head2 $result = get_relationship_IsExecutionOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsExecutionOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsExecutionOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsExecutionOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsExecutionOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsExecutionOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsExecutionOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsExecutionOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsExecutionOf',
				       );
    }
}



=head2 $result = get_relationship_IsExemplarOf(ids, from_fields, rel_fields, to_fields)

This relationship links a role to a feature that provides a typical
example of how the role is implemented.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsExemplarOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsExemplarOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsExemplarOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsExemplarOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsExemplarOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsExemplarOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsExemplarOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsExemplarOf',
				       );
    }
}



=head2 $result = get_relationship_HasAsExemplar(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasAsExemplar
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasAsExemplar (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasAsExemplar:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasAsExemplar');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasAsExemplar",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasAsExemplar',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasAsExemplar",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasAsExemplar',
				       );
    }
}



=head2 $result = get_relationship_IsFamilyFor(ids, from_fields, rel_fields, to_fields)

This relationship connects an isofunctional family to the roles that
make up its assigned function.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsFamilyFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsFamilyFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsFamilyFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsFamilyFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsFamilyFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsFamilyFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsFamilyFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsFamilyFor',
				       );
    }
}



=head2 $result = get_relationship_DeterminesFunctionOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_DeterminesFunctionOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DeterminesFunctionOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DeterminesFunctionOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DeterminesFunctionOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DeterminesFunctionOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DeterminesFunctionOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DeterminesFunctionOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DeterminesFunctionOf',
				       );
    }
}



=head2 $result = get_relationship_IsFormedOf(ids, from_fields, rel_fields, to_fields)

This relationship connects each feature to the atomic regulon to
which it belongs.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsFormedOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsFormedOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsFormedOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsFormedOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsFormedOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsFormedOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsFormedOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsFormedOf',
				       );
    }
}



=head2 $result = get_relationship_IsFormedInto(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsFormedInto
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsFormedInto (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsFormedInto:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsFormedInto');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsFormedInto",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsFormedInto',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsFormedInto",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsFormedInto',
				       );
    }
}



=head2 $result = get_relationship_IsFunctionalIn(ids, from_fields, rel_fields, to_fields)

This relationship connects a role with the features in which
it plays a functional part.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsFunctionalIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsFunctionalIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsFunctionalIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsFunctionalIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsFunctionalIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsFunctionalIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsFunctionalIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsFunctionalIn',
				       );
    }
}



=head2 $result = get_relationship_HasFunctional(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasFunctional
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasFunctional (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasFunctional:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasFunctional');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasFunctional",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasFunctional',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasFunctional",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasFunctional',
				       );
    }
}



=head2 $result = get_relationship_IsGroupFor(ids, from_fields, rel_fields, to_fields)

The recursive IsGroupFor relationship organizes
taxonomic groupings into a hierarchy based on the standard organism
taxonomy.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsGroupFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsGroupFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsGroupFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsGroupFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsGroupFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsGroupFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsGroupFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsGroupFor',
				       );
    }
}



=head2 $result = get_relationship_IsInGroup(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsInGroup
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInGroup (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInGroup:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInGroup');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInGroup",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInGroup',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInGroup",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInGroup',
				       );
    }
}



=head2 $result = get_relationship_IsImplementedBy(ids, from_fields, rel_fields, to_fields)

This relationship connects a variant to the physical machines
that implement it in the genomes. A variant is implemented by many
machines, but a machine belongs to only one variant.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsImplementedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsImplementedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsImplementedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsImplementedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsImplementedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsImplementedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsImplementedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsImplementedBy',
				       );
    }
}



=head2 $result = get_relationship_Implements(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Implements
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Implements (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Implements:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Implements');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Implements",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Implements',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Implements",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Implements',
				       );
    }
}



=head2 $result = get_relationship_IsInPair(ids, from_fields, rel_fields, to_fields)

A pairing contains exactly two protein sequences. A protein
sequence can belong to multiple pairings. When going from a protein
sequence to its pairings, they are presented in alphabetical order
by sequence key.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsInPair
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInPair (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInPair:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInPair');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInPair",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInPair',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInPair",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInPair',
				       );
    }
}



=head2 $result = get_relationship_IsPairOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsPairOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsPairOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsPairOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsPairOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsPairOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsPairOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsPairOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsPairOf',
				       );
    }
}



=head2 $result = get_relationship_IsInstantiatedBy(ids, from_fields, rel_fields, to_fields)

This relationship connects a subcellular location to the instances
of that location that occur in models.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsInstantiatedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInstantiatedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInstantiatedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInstantiatedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInstantiatedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInstantiatedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInstantiatedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInstantiatedBy',
				       );
    }
}



=head2 $result = get_relationship_IsInstanceOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsInstanceOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInstanceOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInstanceOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInstanceOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInstanceOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInstanceOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInstanceOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInstanceOf',
				       );
    }
}



=head2 $result = get_relationship_IsLocatedIn(ids, from_fields, rel_fields, to_fields)

A feature is a set of DNA sequence fragments. Most features
are a single contiquous fragment, so they are located in only one
DNA sequence; however, fragments have a maximum length, so even a
single contiguous feature may participate in this relationship
multiple times. A few features belong to multiple DNA sequences. In
that case, however, all the DNA sequences belong to the same genome.
A DNA sequence itself will frequently have thousands of features
connected to it.
It has the following fields:

=over 4


=item ordinal

Sequence number of this segment, starting from 1
and proceeding sequentially forward from there.


=item begin

Index (1-based) of the first residue in the contig
that belongs to the segment.


=item len

Length of this segment.


=item dir

Direction (strand) of the segment: "+" if it is
forward and "-" if it is backward.



=back

=cut

sub get_relationship_IsLocatedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsLocatedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsLocatedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsLocatedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsLocatedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsLocatedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsLocatedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsLocatedIn',
				       );
    }
}



=head2 $result = get_relationship_IsLocusFor(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsLocusFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsLocusFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsLocusFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsLocusFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsLocusFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsLocusFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsLocusFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsLocusFor',
				       );
    }
}



=head2 $result = get_relationship_IsMeasurementMethodOf(ids, from_fields, rel_fields, to_fields)

The IsMeasurementMethodOf relationship describes which protocol
was used to make a measurement.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsMeasurementMethodOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsMeasurementMethodOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsMeasurementMethodOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsMeasurementMethodOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsMeasurementMethodOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsMeasurementMethodOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsMeasurementMethodOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsMeasurementMethodOf',
				       );
    }
}



=head2 $result = get_relationship_WasMeasuredBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_WasMeasuredBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_WasMeasuredBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_WasMeasuredBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_WasMeasuredBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_WasMeasuredBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_WasMeasuredBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_WasMeasuredBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_WasMeasuredBy',
				       );
    }
}



=head2 $result = get_relationship_IsModeledBy(ids, from_fields, rel_fields, to_fields)

A genome can be modeled by many different models, but a model belongs
to only one genome.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsModeledBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsModeledBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsModeledBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsModeledBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsModeledBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsModeledBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsModeledBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsModeledBy',
				       );
    }
}



=head2 $result = get_relationship_Models(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Models
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Models (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Models:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Models');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Models",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Models',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Models",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Models',
				       );
    }
}



=head2 $result = get_relationship_IsModifiedToBuildAlignment(ids, from_fields, rel_fields, to_fields)

Relates an alignment to other alignments built from it.
It has the following fields:

=over 4


=item modification_type

description of how the alignment was modified


=item modification_value

description of any parameters used to derive the
modification



=back

=cut

sub get_relationship_IsModifiedToBuildAlignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsModifiedToBuildAlignment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsModifiedToBuildAlignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsModifiedToBuildAlignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsModifiedToBuildAlignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsModifiedToBuildAlignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsModifiedToBuildAlignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsModifiedToBuildAlignment',
				       );
    }
}



=head2 $result = get_relationship_IsModificationOfAlignment(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsModificationOfAlignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsModificationOfAlignment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsModificationOfAlignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsModificationOfAlignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsModificationOfAlignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsModificationOfAlignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsModificationOfAlignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsModificationOfAlignment',
				       );
    }
}



=head2 $result = get_relationship_IsModifiedToBuildTree(ids, from_fields, rel_fields, to_fields)

Relates a tree to other trees built from it.
It has the following fields:

=over 4


=item modification_type

description of how the tree was modified (rerooted,
annotated, etc.)


=item modification_value

description of any parameters used to derive the
modification



=back

=cut

sub get_relationship_IsModifiedToBuildTree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsModifiedToBuildTree (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsModifiedToBuildTree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsModifiedToBuildTree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsModifiedToBuildTree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsModifiedToBuildTree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsModifiedToBuildTree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsModifiedToBuildTree',
				       );
    }
}



=head2 $result = get_relationship_IsModificationOfTree(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsModificationOfTree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsModificationOfTree (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsModificationOfTree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsModificationOfTree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsModificationOfTree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsModificationOfTree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsModificationOfTree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsModificationOfTree',
				       );
    }
}



=head2 $result = get_relationship_IsOwnerOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to the features it
contains. Though technically redundant (the information is
available from the feature's contigs), it simplifies the
extremely common process of finding all features for a
genome.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsOwnerOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsOwnerOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsOwnerOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsOwnerOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsOwnerOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsOwnerOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsOwnerOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsOwnerOf',
				       );
    }
}



=head2 $result = get_relationship_IsOwnedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsOwnedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsOwnedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsOwnedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsOwnedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsOwnedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsOwnedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsOwnedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsOwnedBy',
				       );
    }
}



=head2 $result = get_relationship_IsParticipatingAt(ids, from_fields, rel_fields, to_fields)

This relationship connects a localized compound to the
location in which it occurs during one or more reactions.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsParticipatingAt
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsParticipatingAt (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsParticipatingAt:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsParticipatingAt');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsParticipatingAt",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsParticipatingAt',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsParticipatingAt",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsParticipatingAt',
				       );
    }
}



=head2 $result = get_relationship_ParticipatesAt(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_ParticipatesAt
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ParticipatesAt (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ParticipatesAt:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ParticipatesAt');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ParticipatesAt",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ParticipatesAt',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ParticipatesAt",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ParticipatesAt',
				       );
    }
}



=head2 $result = get_relationship_IsProteinFor(ids, from_fields, rel_fields, to_fields)

This relationship connects a peg feature to the protein
sequence it produces (if any). Only peg features participate in this
relationship. A single protein sequence will frequently be produced
by many features.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsProteinFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsProteinFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsProteinFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsProteinFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsProteinFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsProteinFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsProteinFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsProteinFor',
				       );
    }
}



=head2 $result = get_relationship_Produces(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Produces
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Produces (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Produces:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Produces');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Produces",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Produces',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Produces",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Produces',
				       );
    }
}



=head2 $result = get_relationship_IsReagentIn(ids, from_fields, rel_fields, to_fields)

This relationship connects a compound instance to the reaction instance
in which it is transformed.
It has the following fields:

=over 4


=item coefficient

Number of molecules of the compound that participate
in a single instance of the reaction. For example, if a
reaction produces two water molecules, the stoichiometry of
water for the reaction would be two. When a reaction is
written on paper in chemical notation, the stoichiometry is
the number next to the chemical formula of the
compound. The value is negative for substrates and positive
for products.



=back

=cut

sub get_relationship_IsReagentIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsReagentIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsReagentIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsReagentIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsReagentIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsReagentIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsReagentIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsReagentIn',
				       );
    }
}



=head2 $result = get_relationship_Targets(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Targets
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Targets (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Targets:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Targets');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Targets",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Targets',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Targets",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Targets',
				       );
    }
}



=head2 $result = get_relationship_IsRealLocationOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a specific instance of a compound in a model
to the specific instance of the model subcellular location where the compound exists.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsRealLocationOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRealLocationOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRealLocationOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRealLocationOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRealLocationOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRealLocationOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRealLocationOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRealLocationOf',
				       );
    }
}



=head2 $result = get_relationship_HasRealLocationIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasRealLocationIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasRealLocationIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasRealLocationIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasRealLocationIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasRealLocationIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasRealLocationIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasRealLocationIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasRealLocationIn',
				       );
    }
}



=head2 $result = get_relationship_IsReferencedBy(ids, from_fields, rel_fields, to_fields)

This relationship associates each observational unit with the reference
genome that it will be compared to.  All variations will be differences
between the observational unit and the reference.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsReferencedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsReferencedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsReferencedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsReferencedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsReferencedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsReferencedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsReferencedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsReferencedBy',
				       );
    }
}



=head2 $result = get_relationship_UsesReference(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_UsesReference
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsesReference (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsesReference:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsesReference');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsesReference",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsesReference',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsesReference",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsesReference',
				       );
    }
}



=head2 $result = get_relationship_IsRegulatedIn(ids, from_fields, rel_fields, to_fields)

This relationship connects a feature to the set of coregulated features.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsRegulatedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRegulatedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRegulatedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRegulatedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRegulatedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRegulatedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRegulatedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRegulatedIn',
				       );
    }
}



=head2 $result = get_relationship_IsRegulatedSetOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsRegulatedSetOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRegulatedSetOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRegulatedSetOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRegulatedSetOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRegulatedSetOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRegulatedSetOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRegulatedSetOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRegulatedSetOf',
				       );
    }
}



=head2 $result = get_relationship_IsRelevantFor(ids, from_fields, rel_fields, to_fields)

This relationship connects a diagram to the subsystems that are depicted on
it. Only diagrams which are useful in curating or annotation the subsystem are
specified in this relationship.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsRelevantFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRelevantFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRelevantFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRelevantFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRelevantFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRelevantFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRelevantFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRelevantFor',
				       );
    }
}



=head2 $result = get_relationship_IsRelevantTo(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsRelevantTo
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRelevantTo (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRelevantTo:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRelevantTo');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRelevantTo",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRelevantTo',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRelevantTo",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRelevantTo',
				       );
    }
}



=head2 $result = get_relationship_IsRepresentedBy(ids, from_fields, rel_fields, to_fields)

This relationship associates observational units with a genus,
species, strain, and/or variety that was the source material.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsRepresentedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRepresentedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRepresentedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRepresentedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRepresentedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRepresentedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRepresentedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRepresentedBy',
				       );
    }
}



=head2 $result = get_relationship_DefinedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_DefinedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_DefinedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_DefinedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_DefinedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_DefinedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_DefinedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_DefinedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_DefinedBy',
				       );
    }
}



=head2 $result = get_relationship_IsRoleOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a role to the machine roles that
represent its appearance in a molecular machine. A machine role has
exactly one associated role, but a role may be represented by many
machine roles.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsRoleOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRoleOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRoleOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRoleOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRoleOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRoleOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRoleOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRoleOf',
				       );
    }
}



=head2 $result = get_relationship_HasRole(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasRole
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasRole (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasRole:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasRole');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasRole",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasRole',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasRole",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasRole',
				       );
    }
}



=head2 $result = get_relationship_IsRowOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a subsystem spreadsheet row to its
constituent spreadsheet cells.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsRowOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRowOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRowOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRowOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRowOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRowOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRowOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRowOf',
				       );
    }
}



=head2 $result = get_relationship_IsRoleFor(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsRoleFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsRoleFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsRoleFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsRoleFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsRoleFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsRoleFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsRoleFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsRoleFor',
				       );
    }
}



=head2 $result = get_relationship_IsSequenceOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a Contig as it occurs in a
genome to the Contig Sequence that represents the physical
DNA base pairs. A contig sequence may represent many contigs,
but each contig has only one sequence.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsSequenceOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSequenceOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSequenceOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSequenceOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSequenceOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSequenceOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSequenceOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSequenceOf',
				       );
    }
}



=head2 $result = get_relationship_HasAsSequence(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasAsSequence
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasAsSequence (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasAsSequence:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasAsSequence');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasAsSequence",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasAsSequence',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasAsSequence",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasAsSequence',
				       );
    }
}



=head2 $result = get_relationship_IsSubInstanceOf(ids, from_fields, rel_fields, to_fields)

This relationship connects a scenario to its subsystem it
validates. A scenario belongs to exactly one subsystem, but a
subsystem may have multiple scenarios.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsSubInstanceOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSubInstanceOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSubInstanceOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSubInstanceOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSubInstanceOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSubInstanceOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSubInstanceOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSubInstanceOf',
				       );
    }
}



=head2 $result = get_relationship_Validates(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Validates
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Validates (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Validates:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Validates');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Validates",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Validates',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Validates",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Validates',
				       );
    }
}



=head2 $result = get_relationship_IsSummarizedBy(ids, from_fields, rel_fields, to_fields)

This relationship describes the statistical frequencies of the
most common alleles in various positions on the reference contig.
It has the following fields:

=over 4


=item position

Position in the reference contig where the trait
has an impact.



=back

=cut

sub get_relationship_IsSummarizedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSummarizedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSummarizedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSummarizedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSummarizedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSummarizedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSummarizedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSummarizedBy',
				       );
    }
}



=head2 $result = get_relationship_Summarizes(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Summarizes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Summarizes (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Summarizes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Summarizes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Summarizes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Summarizes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Summarizes",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Summarizes',
				       );
    }
}



=head2 $result = get_relationship_IsSuperclassOf(ids, from_fields, rel_fields, to_fields)

This is a recursive relationship that imposes a hierarchy on
the subsystem classes.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsSuperclassOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSuperclassOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSuperclassOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSuperclassOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSuperclassOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSuperclassOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSuperclassOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSuperclassOf',
				       );
    }
}



=head2 $result = get_relationship_IsSubclassOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsSubclassOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSubclassOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSubclassOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSubclassOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSubclassOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSubclassOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSubclassOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSubclassOf',
				       );
    }
}



=head2 $result = get_relationship_IsTaxonomyOf(ids, from_fields, rel_fields, to_fields)

A genome is assigned to a particular point in the taxonomy tree, but not
necessarily to a leaf node. In some cases, the exact species and strain is
not available when inserting the genome, so it is placed at the lowest node
that probably contains the actual genome.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsTaxonomyOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsTaxonomyOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsTaxonomyOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsTaxonomyOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsTaxonomyOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsTaxonomyOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsTaxonomyOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsTaxonomyOf',
				       );
    }
}



=head2 $result = get_relationship_IsInTaxa(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsInTaxa
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsInTaxa (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsInTaxa:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsInTaxa');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsInTaxa",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsInTaxa',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsInTaxa",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsInTaxa',
				       );
    }
}



=head2 $result = get_relationship_IsTerminusFor(ids, from_fields, rel_fields, to_fields)

A terminus for a scenario is a compound that acts as its
input or output. A compound can be the terminus for many scenarios,
and a scenario will have many termini. The relationship attributes
indicate whether the compound is an input to the scenario or an
output. In some cases, there may be multiple alternative output
groups. This is also indicated by the attributes.
It has the following fields:

=over 4


=item group_number

If zero, then the compound is an input. If one, the compound is
an output. If two, the compound is an auxiliary output.



=back

=cut

sub get_relationship_IsTerminusFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsTerminusFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsTerminusFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsTerminusFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsTerminusFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsTerminusFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsTerminusFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsTerminusFor',
				       );
    }
}



=head2 $result = get_relationship_HasAsTerminus(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasAsTerminus
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasAsTerminus (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasAsTerminus:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasAsTerminus');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasAsTerminus",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasAsTerminus',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasAsTerminus",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasAsTerminus',
				       );
    }
}



=head2 $result = get_relationship_IsTriggeredBy(ids, from_fields, rel_fields, to_fields)

This connects a complex to the roles that work together to form the complex.
It has the following fields:

=over 4


=item optional

TRUE if the role is not necessarily required to trigger the
complex, else FALSE


=item type

a string code that is used to determine whether a complex
should be added to a model


=item triggering

TRUE if the presence of the role requires including the
complex in the model, else FALSE



=back

=cut

sub get_relationship_IsTriggeredBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsTriggeredBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsTriggeredBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsTriggeredBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsTriggeredBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsTriggeredBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsTriggeredBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsTriggeredBy',
				       );
    }
}



=head2 $result = get_relationship_Triggers(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_Triggers
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Triggers (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Triggers:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Triggers');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Triggers",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Triggers',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Triggers",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Triggers',
				       );
    }
}



=head2 $result = get_relationship_IsUsedToBuildTree(ids, from_fields, rel_fields, to_fields)

This relationship connects each tree to the alignment from
which it is built. There is at most one.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_IsUsedToBuildTree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsUsedToBuildTree (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsUsedToBuildTree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsUsedToBuildTree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsUsedToBuildTree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsUsedToBuildTree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsUsedToBuildTree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsUsedToBuildTree',
				       );
    }
}



=head2 $result = get_relationship_IsBuiltFromAlignment(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsBuiltFromAlignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsBuiltFromAlignment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsBuiltFromAlignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsBuiltFromAlignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsBuiltFromAlignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsBuiltFromAlignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsBuiltFromAlignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsBuiltFromAlignment',
				       );
    }
}



=head2 $result = get_relationship_Manages(ids, from_fields, rel_fields, to_fields)

This relationship connects a model to its associated biomass
composition reactions.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Manages
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Manages (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Manages:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Manages');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Manages",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Manages',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Manages",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Manages',
				       );
    }
}



=head2 $result = get_relationship_IsManagedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsManagedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsManagedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsManagedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsManagedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsManagedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsManagedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsManagedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsManagedBy',
				       );
    }
}



=head2 $result = get_relationship_OperatesIn(ids, from_fields, rel_fields, to_fields)

This relationship connects an experiment to the media in which the
experiment took place.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_OperatesIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_OperatesIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_OperatesIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_OperatesIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_OperatesIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_OperatesIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_OperatesIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_OperatesIn',
				       );
    }
}



=head2 $result = get_relationship_IsUtilizedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsUtilizedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsUtilizedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsUtilizedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsUtilizedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsUtilizedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsUtilizedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsUtilizedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsUtilizedIn',
				       );
    }
}



=head2 $result = get_relationship_Overlaps(ids, from_fields, rel_fields, to_fields)

A Scenario overlaps a diagram when the diagram displays a
portion of the reactions that make up the scenario. A scenario may
overlap many diagrams, and a diagram may be include portions of many
scenarios.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Overlaps
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Overlaps (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Overlaps:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Overlaps');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Overlaps",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Overlaps',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Overlaps",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Overlaps',
				       );
    }
}



=head2 $result = get_relationship_IncludesPartOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IncludesPartOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IncludesPartOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IncludesPartOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IncludesPartOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IncludesPartOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IncludesPartOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IncludesPartOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IncludesPartOf',
				       );
    }
}



=head2 $result = get_relationship_ParticipatesAs(ids, from_fields, rel_fields, to_fields)

This relationship connects a generic compound to a specific compound
where subceullar location has been specified.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_ParticipatesAs
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ParticipatesAs (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ParticipatesAs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ParticipatesAs');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ParticipatesAs",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ParticipatesAs',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ParticipatesAs",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ParticipatesAs',
				       );
    }
}



=head2 $result = get_relationship_IsParticipationOf(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsParticipationOf
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsParticipationOf (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsParticipationOf:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsParticipationOf');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsParticipationOf",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsParticipationOf',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsParticipationOf",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsParticipationOf',
				       );
    }
}



=head2 $result = get_relationship_PerformedExperiment(ids, from_fields, rel_fields, to_fields)

Denotes that a Person was associated with a
PhenotypeExperiment in some role.
It has the following fields:

=over 4


=item role

Describes the role the person played in the experiment.
Examples are Primary Investigator, Designer, Experimentalist, etc.



=back

=cut

sub get_relationship_PerformedExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_PerformedExperiment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_PerformedExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_PerformedExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_PerformedExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_PerformedExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_PerformedExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_PerformedExperiment',
				       );
    }
}



=head2 $result = get_relationship_PerformedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_PerformedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_PerformedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_PerformedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_PerformedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_PerformedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_PerformedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_PerformedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_PerformedBy',
				       );
    }
}



=head2 $result = get_relationship_ProducedResultsFor(ids, from_fields, rel_fields, to_fields)

This relationship connects a probe set to a genome for which it was
used to produce experimental results. In general, a probe set is used for
only one genome and vice versa, but this is not a requirement.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_ProducedResultsFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ProducedResultsFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ProducedResultsFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ProducedResultsFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ProducedResultsFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ProducedResultsFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ProducedResultsFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ProducedResultsFor',
				       );
    }
}



=head2 $result = get_relationship_HadResultsProducedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HadResultsProducedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HadResultsProducedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HadResultsProducedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HadResultsProducedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HadResultsProducedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HadResultsProducedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HadResultsProducedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HadResultsProducedBy',
				       );
    }
}



=head2 $result = get_relationship_Provided(ids, from_fields, rel_fields, to_fields)

This relationship connects a source (core) database
to the subsystems it submitted to the knowledge base.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Provided
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Provided (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Provided:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Provided');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Provided",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Provided',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Provided",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Provided',
				       );
    }
}



=head2 $result = get_relationship_WasProvidedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_WasProvidedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_WasProvidedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_WasProvidedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_WasProvidedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_WasProvidedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_WasProvidedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_WasProvidedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_WasProvidedBy',
				       );
    }
}



=head2 $result = get_relationship_PublishedExperiment(ids, from_fields, rel_fields, to_fields)

The ExperimentPublishedIn relationship describes where a
particular experiment was published.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_PublishedExperiment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_PublishedExperiment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_PublishedExperiment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_PublishedExperiment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_PublishedExperiment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_PublishedExperiment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_PublishedExperiment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_PublishedExperiment',
				       );
    }
}



=head2 $result = get_relationship_ExperimentPublishedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_ExperimentPublishedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ExperimentPublishedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ExperimentPublishedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ExperimentPublishedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ExperimentPublishedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ExperimentPublishedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ExperimentPublishedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ExperimentPublishedIn',
				       );
    }
}



=head2 $result = get_relationship_PublishedProtocol(ids, from_fields, rel_fields, to_fields)

The ProtocolPublishedIn relationship describes where a
particular protocol was published.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_PublishedProtocol
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_PublishedProtocol (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_PublishedProtocol:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_PublishedProtocol');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_PublishedProtocol",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_PublishedProtocol',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_PublishedProtocol",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_PublishedProtocol',
				       );
    }
}



=head2 $result = get_relationship_ProtocolPublishedIn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_ProtocolPublishedIn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_ProtocolPublishedIn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_ProtocolPublishedIn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_ProtocolPublishedIn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_ProtocolPublishedIn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_ProtocolPublishedIn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_ProtocolPublishedIn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_ProtocolPublishedIn',
				       );
    }
}



=head2 $result = get_relationship_Shows(ids, from_fields, rel_fields, to_fields)

This relationship indicates that a compound appears on a
particular diagram. The same compound can appear on many diagrams,
and a diagram always contains many compounds.
It has the following fields:

=over 4


=item location

Location of the compound's node on the diagram.



=back

=cut

sub get_relationship_Shows
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Shows (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Shows:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Shows');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Shows",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Shows',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Shows",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Shows',
				       );
    }
}



=head2 $result = get_relationship_IsShownOn(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsShownOn
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsShownOn (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsShownOn:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsShownOn');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsShownOn",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsShownOn',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsShownOn",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsShownOn',
				       );
    }
}



=head2 $result = get_relationship_Submitted(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to the
core database from which it was loaded.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Submitted
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Submitted (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Submitted:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Submitted');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Submitted",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Submitted',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Submitted",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Submitted',
				       );
    }
}



=head2 $result = get_relationship_WasSubmittedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_WasSubmittedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_WasSubmittedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_WasSubmittedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_WasSubmittedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_WasSubmittedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_WasSubmittedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_WasSubmittedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_WasSubmittedBy',
				       );
    }
}



=head2 $result = get_relationship_SupersedesAlignment(ids, from_fields, rel_fields, to_fields)

This relationship connects an alignment to the alignments
it replaces.
It has the following fields:

=over 4


=item successor_type

Indicates whether sequences were removed or added
to create the new alignment.



=back

=cut

sub get_relationship_SupersedesAlignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_SupersedesAlignment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_SupersedesAlignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_SupersedesAlignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_SupersedesAlignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_SupersedesAlignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_SupersedesAlignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_SupersedesAlignment',
				       );
    }
}



=head2 $result = get_relationship_IsSupersededByAlignment(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsSupersededByAlignment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSupersededByAlignment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSupersededByAlignment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSupersededByAlignment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSupersededByAlignment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSupersededByAlignment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSupersededByAlignment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSupersededByAlignment',
				       );
    }
}



=head2 $result = get_relationship_SupersedesTree(ids, from_fields, rel_fields, to_fields)

This relationship connects a tree to the trees
it replaces.
It has the following fields:

=over 4


=item successor_type

Indicates whether sequences were removed or added
to create the new tree.



=back

=cut

sub get_relationship_SupersedesTree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_SupersedesTree (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_SupersedesTree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_SupersedesTree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_SupersedesTree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_SupersedesTree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_SupersedesTree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_SupersedesTree',
				       );
    }
}



=head2 $result = get_relationship_IsSupersededByTree(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsSupersededByTree
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsSupersededByTree (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsSupersededByTree:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsSupersededByTree');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsSupersededByTree",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsSupersededByTree',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsSupersededByTree",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsSupersededByTree',
				       );
    }
}



=head2 $result = get_relationship_Treed(ids, from_fields, rel_fields, to_fields)

This relationship connects a tree to the source database from
which it was generated.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Treed
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Treed (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Treed:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Treed');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Treed",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Treed',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Treed",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Treed',
				       );
    }
}



=head2 $result = get_relationship_IsTreeFrom(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsTreeFrom
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsTreeFrom (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsTreeFrom:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsTreeFrom');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsTreeFrom",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsTreeFrom',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsTreeFrom",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsTreeFrom',
				       );
    }
}



=head2 $result = get_relationship_UsedBy(ids, from_fields, rel_fields, to_fields)

The UsesMedia relationship defines which media is used by an
Environment.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_UsedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsedBy',
				       );
    }
}



=head2 $result = get_relationship_UsesMedia(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_UsesMedia
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsesMedia (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsesMedia:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsesMedia');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsesMedia",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsesMedia',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsesMedia",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsesMedia',
				       );
    }
}



=head2 $result = get_relationship_UsedInExperimentalUnit(ids, from_fields, rel_fields, to_fields)

The HasEnvironment relationship describes the enviroment a
subexperiment defined by Experimental unit was performed in.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_UsedInExperimentalUnit
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsedInExperimentalUnit (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsedInExperimentalUnit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsedInExperimentalUnit');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsedInExperimentalUnit",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsedInExperimentalUnit',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsedInExperimentalUnit",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsedInExperimentalUnit',
				       );
    }
}



=head2 $result = get_relationship_HasEnvironment(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_HasEnvironment
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_HasEnvironment (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_HasEnvironment:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_HasEnvironment');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_HasEnvironment",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_HasEnvironment',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_HasEnvironment",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_HasEnvironment',
				       );
    }
}



=head2 $result = get_relationship_Uses(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to the machines that form
its metabolic pathways. A genome can use many machines, but a
machine is used by exactly one genome.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_Uses
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_Uses (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_Uses:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_Uses');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_Uses",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_Uses',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_Uses",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_Uses',
				       );
    }
}



=head2 $result = get_relationship_IsUsedBy(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_IsUsedBy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_IsUsedBy (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_IsUsedBy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_IsUsedBy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_IsUsedBy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_IsUsedBy',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_IsUsedBy",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_IsUsedBy',
				       );
    }
}



=head2 $result = get_relationship_UsesCodons(ids, from_fields, rel_fields, to_fields)

This relationship connects a genome to the various codon usage
records for it.
It has the following fields:

=over 4



=back

=cut

sub get_relationship_UsesCodons
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_UsesCodons (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_UsesCodons:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_UsesCodons');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_UsesCodons",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_UsesCodons',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_UsesCodons",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_UsesCodons',
				       );
    }
}



=head2 $result = get_relationship_AreCodonsFor(ids, from_fields, rel_fields, to_fields)



=cut

sub get_relationship_AreCodonsFor
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_relationship_AreCodonsFor (received $n, expecting 4)");
    }
    {
	my($ids, $from_fields, $rel_fields, $to_fields) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        (ref($from_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 2 \"from_fields\" (value was \"$from_fields\")");
        (ref($rel_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"rel_fields\" (value was \"$rel_fields\")");
        (ref($to_fields) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 4 \"to_fields\" (value was \"$to_fields\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_relationship_AreCodonsFor:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_relationship_AreCodonsFor');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "CDMI_EntityAPI.get_relationship_AreCodonsFor",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_relationship_AreCodonsFor',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_relationship_AreCodonsFor",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_relationship_AreCodonsFor',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "CDMI_EntityAPI.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'get_relationship_AreCodonsFor',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method get_relationship_AreCodonsFor",
            status_line => $self->{client}->status_line,
            method_name => 'get_relationship_AreCodonsFor',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::KBase::CDMI::Client\n";
    }
    if ($sMajor == 0) {
        warn "Bio::KBase::CDMI::Client version is $svr_version. API subject to change.\n";
    }
}

package Bio::KBase::CDMI::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}

1;
