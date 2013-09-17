use strict;
use Data::Dumper;
use Carp;
use Getopt::Long;

use SeedEnv;
use SAPserver;

#
# This is a SAS Component
#

my $sapO = SAPserver->new();
my $modO = FBAMODELserver->new;

my ($user, $password, $man, $help, $model, $column) = undef;
$user = $ENV{'SAS_USER'} if(defined($ENV{'SAS_USER'}));
$password = $ENV{'SAS_PASSWORD'} if(defined($ENV{'SAS_PASSWORD'}));

my $opted    = GetOptions('help|h|?' => \$help,
                          'man|m' => \$man,
                          'u|username|user=s' => \$user,
                          'p|password=s' => \$password,
                          'c|column=i' => \$column,
                          'm|model=s' => \$model,
                         ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $args = {};
if(defined($user) && defined($password)) {
    $args->{user} = $user;
    $args->{password} = $password;
}

my @lines;
if ($model) {
    @lines = ([$model]);
    $column = 1;
} else {
    @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
    if (! $column)  { $column = @{$lines[0]} }
}
my @models = map { $_->[$column-1] } @lines;
$args->{ids} = \@models;

my $gapfilled = $modO->gapfilled_roles($args);
foreach my $line (@lines) {
    my $model1 = $line->[$column-1];
    my $predicted = $gapfilled->{$model1};
    if(defined($predicted) && defined($predicted->{error})) {
        warn "Error for model $model1 : " . $predicted->{error} ."\n";
        next;
    }
    if (defined($predicted)) {
        my @output;
        foreach my $role (keys(%$predicted)) {
            my $reactions = $predicted->{$role};
            if ($reactions) {
                push(@output,map { [$_,$role] } @$reactions);
            }
        }

        foreach $_ (sort { $a->[1] cmp $b->[1] } @output) {
            print join("\t",(@$line,@$_)),"\n";
        }
    }
}

__DATA__
=head1 svr_gap_filled_reactions_and _roles [-m model]

Get the reactions and functional roles that were predicted by gap-filling

------

Example:

    svr_gap_filled_reactions_and_roles -m Seed83333.1 > predicted.reactions.and.roles

would write a 2-column table containing [reaction,role]
giving the reactions and roles predicted by gap-filling.

    svr_gap_filled_reactions_and_roles < file.of.models

could be used to read the model IDs from the last column of the lines in
file.of.models.

------
=head2 Command-Line Options

=over 4

=item -m Model [optional]

This parameter can be used to specify a specific model ID.  If it is omitted,
the model IDs will be read from input lines.

=item -c Column

This is used only if the column containing model IDs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file.  Each line will contain
2 extra tab-separated fields:

    reaction-id
    role

=cut
