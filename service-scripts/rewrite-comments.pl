use strict;
use File::Temp;
use Data::Dumper;
use File::Copy;
use File::Basename;
use List::MoreUtils qw(first_index);

for my $file (@ARGV)
{
    process_file($file);
}

sub process_file
{
    my($file) = @_;

    my $base = basename($file, ".pl");

    my $tmp = File::Temp->new(UNLINK => 0);
    open(F, "<", $file) or die "Cannot open $file: $!";

    #
    # Read up to the opening =head1; write those lines to the temp file.
    # Read the comment block until the =cut and save.
    #
    # Then spin through to the CDMIClient->new saving lines.
    #
    # Determine the command line options there, and pass to the comment processor.
    # Write the generated data from the comment processor, the saved intervening lines, the CDMIClient->new,
    # then copy the rest of the file.
    #

    my @doc;
    while (<F>)
    {
	if (/^=head/)
	{
	    push(@doc, $_);
	    last;
	}
	print $tmp $_;
    }

    while (<F>)
    {
	push(@doc, $_);
	last if (/^=cut/);
    }

    my @saved;

    my @maybe_args;
    while (<F>)
    {
	push(@saved, $_);
	if (/new_for_script(.*)/)
	{
	    push(@maybe_args, $1);
	    last;
	}
    }
    if (@maybe_args)
    {
	while (<F>)
	{
	    push(@saved, $_);
	    push(@maybe_args, $_);
	    last if (/\)\s*;/)
	}
    }

    #
    # Find arguments.
    #
    my @args;
    for my $m (@maybe_args)
    {
	my $q = q(['"]); # "' ]);
		   
	if ($m =~ /$q(\S+?)=(\S+?)$q/) 
	{
	    push(@args, [$1, $2]);
	}
    }

    my $repl = process_comments($base, \@doc, \@args);

    if (!$repl)
    {
	print STDERR "Not processing $file\n";
	next;
    }
    print "Processed $file\n";
    print $tmp $repl;
    print $tmp @saved;

    while (<F>)
    {
	print $tmp $_;
    }
    close(F);
    close($tmp);

    rename($file, "$file.bak") or die "error renaming $file to $file.bak: $!";
    copy($tmp->filename, $file) or die "error copying " . $tmp->filename . " to $file: $!";
}

#
# Walk the comments. Replace the headings as follows:
#
# =head1 <scriptname> => NAME header
#
# Find the example that starts with the script name.
#
# Remove the chunk about documentation for underlying call and the command
# line options section. In their place write the new command line options section,
# using the example collected above and the parameters passed in.
#
# Replace the output format heading with a head1.
#
# Add the authors at the end.
# 
sub process_comments
{
    my($script, $comments, $params) = @_;

    my $i;
    my @new;

    #
    # Find the synopsis.
    #
    my $syn;
    if (($i = first_index { /^\s+$script.*arguments/ } @$comments) > -1)
    {
	$syn = $comments->[$i];
	$syn =~ s/^\s*//;
    }
    else
    {
	return undef;
    }
    
    if (($i = first_index { /=head1.*$script/ } @$comments) >= 0)
    {
	splice(@$comments, $i, 1,
	       "=head1 NAME\n",
	       "\n",
	       "$script\n",
	       "\n",
	       "=head1 SYNOPSIS\n",
	       "\n",
	       $syn,
	       "\n",
	       "=head1 DESCRIPTION\n",
	       );
    }
    else
    {
	return undef;
    }

    my $chunk_start = first_index { /^=head.*Documentation.*underlying/ } @$comments;
    if ($chunk_start > -1)
    {
	splice(@$comments, $chunk_start);
	push(@$comments,
	     "=head1 COMMAND-LINE OPTIONS\n",
	     "\n",
	     "Usage: $syn\n",
	     "\n");

	my %typemap = ( i => "integer",
			s => "string" );

	for my $param (@$params)
	{
	    my($name, $val) = @$param;
	    if ($name eq 'c')
	    {
		push(@$comments, "    -c num        Select the identifier from column num\n");
	    }
	    elsif ($name eq 'i')
	    {
		push(@$comments, "    -i filename   Use filename rather than stdin for input\n");
	    }
	    elsif ($val)
	    {
		my $type = $typemap{$val} || "value";
		push(@$comments, "    --$name $type\n");
	    }
	    else
	    {
		push(@$comments, "    --$name\n");
	    }
	}

	push(@$comments,
	     "\n",
	     "=head1 AUTHORS\n",
	     "\n",
	     "L<The SEED Project|http://www.theseed.org>\n",
	     "\n",
	     "=cut\n",
	     );
    }


    return join("", @$comments);
}
