#
# This is a SAS component.
#


#
# Wrapper for user-authored perl scripts
#

use strict;

#
# Look in current directory too.
#

push(@INC, ".");

if (@ARGV == 0)
{
    die "Usage: svr script-name [arguments]\n";
}

my $script = shift;

my $x = do $script;
if (!$x)
{
    if ($@)
    {
	die "Error executing script: $@\n";
    }
    else
    {
	die "Error loading $script: $!\n";
    }
}


