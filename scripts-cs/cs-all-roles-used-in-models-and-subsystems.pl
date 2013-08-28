use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

cs-all-roles-used-in-models-and-subsystems

=head1 SYNOPSIS

cs-all-roles-used-in-models-and-subsystems > output

=head1 DESCRIPTION

The cs-all-roles-used-in-models-and-subsystems allows a user to access
the set of roles that are included in current models and subsystems.  This is
important.  There are far fewer roles used in models than overall.
Hence, the returned set represents the minimal set we need to clean up
in order to properly support modeling.

Example:

    cs-all-roles-used-in-models-and-subsystems > output

This is a pipe command. The is no input, and the
output is to the standard output.

=head2 Output Format

The output is a file in which each line contains just a role
used in the construction of models or occurring in a subsystem.

=head1 COMMAND-LINE OPTIONS

Usage: cs-all-roles-used-in-models-and-subsystems > output

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut


our $usage = "usage: cs-all-roles-used-in-models-and-subsystems > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script();
if (! $kbO) { print STDERR $usage; exit }

my %roles;
my $h = $kbO->all_roles_used_in_models();
foreach my $role (@$h) {
    $roles{$role} = 1;
}

open(SSPIPE, "er-all-entities-Subsystem | cs-subsystems-to-roles |");
while (<SSPIPE>) {
    chomp;
    my($ss, $role) = split(/\t/);
    $roles{$role} = 1;
}
close(SSPIPE);

for my $role (sort keys %roles) {
    print "$role\n";
}

__DATA__
