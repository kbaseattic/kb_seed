use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

all_roles_used_in_models

=head1 SYNOPSIS

all_roles_used_in_models > output

=head1 DESCRIPTION

The all_roles_used_in_models allows a user to access the set of roles that are included in current models.
Note that there are far fewer roles used in models than in the complete set of functional roles.
Hence, the returned set represents the minimal set we need to clean up in order to properly support modeling.

Example:

    all_roles_used_in_models > output

This is a pipe command. The is no input, and the output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: all_roles_used_in_models > output

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: all_roles_used_in_models > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;


my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script();
if (! $kbO) { print STDERR $usage; exit }

my $h = $kbO->all_roles_used_in_models();
foreach my $role (@$h) {
    print $role, "\n";
}

__DATA__
