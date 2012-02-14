
use myRASTApp;

our $have_env_path;
BEGIN {
    eval {
	require Env::Path;
	$have_env_path = 1;
    };
}

our $have_win32_gui;
BEGIN {
    eval {
	require Win32::GUI;
	$have_win32_gui = 1;
    };
}

use strict;

use Wx;
use wxPerl::Constructors;

if (@ARGV)
{
    my $path = shift;
    if (-d $path)
    {
	print STDERR "Adding $path to search path\n";
	if ($have_env_path)
	{
	    my $pathobj = Env::Path->PATH;
	    $pathobj->Prepend($path);
	    print STDERR "Path is now: ";
	    print STDERR "  $_\n" for $pathobj->List;
	}
	else
	{
	    # unix case

	    $ENV{PATH} = "${path}:$ENV{PATH}";
	    print STDERR "(no Env::Path) Path is now $ENV{PATH}\n";
	}
    }
    else
    {
	print STDERR "Request path $path does not exist\n";
    }

    if ($have_win32_gui)
    {
	my ($DOS) = Win32::GUI::GetPerlWindow();
	Win32::GUI::Hide($DOS);
    }
}

my $app = myRASTApp->new;

$app->MainLoop();


1;
