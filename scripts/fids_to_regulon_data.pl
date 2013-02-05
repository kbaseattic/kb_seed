use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#

=head1 NAME

fids_to_regulon_data

=head1 SYNOPSIS

fids_to_regulon_data [arguments] < input > output

=head1 DESCRIPTION





Example:

    fids_to_regulon_data [arguments] < input > output

The standard input should be a tab-separated table (i.e., each line
is a tab-separated set of fields).  Normally, the last field in each
line would contain the identifer. If another column contains the identifier
use

    -c N

where N is the column (from 1) that contains the subsystem.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head1 COMMAND-LINE OPTIONS

Usage: fids_to_regulon_data [arguments] < input > output


    -c num        Select the identifier from column num
    --fields string
    -i filename   Use filename rather than stdin for input

=head1 AUTHORS

L<The SEED Project|http://www.theseed.org>

=cut

my @all_fields = ( 'regulon_id', 'regulon_set', 'tfs' );
my %all_fields = map { $_ => 1 } @all_fields;


our $usage = "usage: fids_to_regulon_data [-h] [-c column] [-a | -f field list] < input > output";

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;

my $column;
my @fields;
my $a;
my $f;
my $show_fields;

my $input_file;

my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script('c=i' => \$column,
						"a"   => \$a,
						"h"   => \$show_fields,
						"show-fields" => \$show_fields,
						"fields=s"    => \$f,
					        'i=s' => \$input_file);
if (! $kbO) { print STDERR $usage; exit }

if ($show_fields)
{
    print STDERR "Available fields: @all_fields\n";
    exit 0;
}
if ($a && $f) { print STDERR $usage; exit 1 }

if ($a)
{   
    @fields = @all_fields;
}
elsif ($f) {
    my @err;
    for my $field (split(",", $f))
    {   
        if (!$all_fields{$field})
        {   
            push(@err, $field);
        }
        else
        {   
            push(@fields, $field);
        }
    }
    if (@err)
    {   
        print STDERR "fids_to_regulon_data: unknown fields @err. Valid fields are: @all_fields\n";
        exit 1;
    }
} else {
    print STDERR $usage;
    exit 1;
}

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}

while (my @tuples = Bio::KBase::Utilities::ScriptThing::GetBatch($ih, undef, $column)) {
    my @h = map { $_->[0] } @tuples;

    my $h = $kbO->fids_to_regulon_data(\@h);
    for my $tuple (@tuples) {
        #
        # Process output here and print.
        #
        my ($id, $line) = @$tuple;
        my $v = $h->{$id};

        if (! defined($v))
        {
            print STDERR $line,"\n";
        }
        elsif (ref($v) eq 'ARRAY')
        {
            foreach my $row (@$v)
            {
		my @ret;
		foreach my $field (@fields) {
		    if (ref($row->{$field}) eq 'ARRAY') {
			    push (@ret, join (",", @{$row->{$field}}));
		     } else {
			    push(@ret, $row->{$field}); 
		     }
		}
	 	    my $out = join("\t", @ret);
		    print "$line\t$out\n";
            }
        }
        else
        {
            print "$line\n";
        }
    }
}

__DATA__
