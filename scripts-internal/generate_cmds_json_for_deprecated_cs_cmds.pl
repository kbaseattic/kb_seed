use strict;
use Data::Dumper;

=head1 NAME

generate_cmds_json_for

=head1 DESCRIPTION

simple helper script that takes a two column, tab-delimited file with deprecated names followed
by replacement names, and prints the portion of the COMMANDS.json required to mark these methods
as deprecated.  run this script from root kb_seed directory.

=head1 AUTHORS

Michael Sneddon

=cut


my $deprecated_file_location = "scripts-cs/deprecated_script_list.txt";


open(my $file_handle, $deprecated_file_location) or die "Could not open $deprecated_file_location: $!";

my $cmd_names = {};

while( my $line = <$file_handle>) {
    chomp($line);
    my @toks = split("\t",$line);
    if (scalar @toks != 2) {
        warn "skipping '$line', incorrect number of tokens.\n";
        next;
    }
    $cmd_names->{$toks[0]}=$toks[1];
}

my @sorted_cmds = sort keys %{$cmd_names};
foreach my $cmd (@sorted_cmds) {
    print "             ,\n";
    print "                {\n";
    print "                    \"deprecated-name\": \"".$cmd."\",\n";
    print "                    \"file-name\": \"scripts-cs/".$cmd_names->{$cmd}.".pl\",\n";
    print "                    \"lang\":\"perl\",\n";
    print "                    \"deploy-to-iris\":true,\n";
    print "                    \"new-command-name\": \"".$cmd_names->{$cmd}."\"\n";
    print "                }\n";
}

close $file_handle;
