########################################################################
use strict;
use Data::Dumper;
use Carp;
use ERDB;

#
# This is a SAS Component
#

=head1 NAME

get_all

=head1 SYNOPSIS

get_all -p Path [-c Constraint] [-f Fields] > outut

=head1 DESCRIPTION

This command is a general operator used to extract data from an ERDB.

Example:
    
    get_all -p 'Feature Produces ProteinSequence' -c 'Feature(id)=?' -v 'kb|g.0.peg.4' -f 'ProteinSequence(sequence)'


    returns the translation of peg kb|g.0.peg.4

=head1 COMMAND-LINE OPTIONS

get_all -p Path [-c Constraint] [-f Fields] > output

    -p Path
        This gives the explicit path of nodes in the ERDB, comma-separated

    -c Constraint
        This specifies the explicit constraint imposed on an instance of the path

    -f Fields
        This specifies a set of fields to be returned, comma-separated

=head1 OUTPUT FORMAT

The standard output is a tab-delimited file. It consists of one line
per instance of the instantiated path.  Each line contains the 
fields requested

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

use SeedUtils;

our $usage = "usage: get_all -p Path [-c Constraint] [-f Fields] > output\n";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $path;
my $constraint;
my $fields;
my $parameters;
my $count = 0;

my $csO = Bio::KBase::CDMI::CDMI->new_for_script('p=s'   => \$path,
						 'c=s'   => \$constraint,
						 'v=s'   => \$parameters,
						 'n=i'   => \$count,
						 'f=s'   => \$fields);
						       
if ((! $csO) || (! $path) || (! $fields) ) { print STDERR $usage; exit }
$parameters = $parameters ? [split(/,/,$parameters)] : [];
my @rows = $csO->GetAll($path,$constraint,$parameters,$fields,$count);
foreach my $row (@rows)
{
    print join("\t",@$row),"\n";
}
