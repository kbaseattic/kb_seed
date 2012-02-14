#
# Build the SEED Access Scripts distribution from the code in the current checkout
# of the SEED code.
#
#
#
#
#
# We walk the FigKernelScripts and FigKernelPackages directories looking for
# scripts that have a comment
#
#  SAS Component
#
# in the first 10 lines. These are copied to the destination directory.
#
# We create a shell-script wrapper for each .pl script from FigKernelScripts that is installed.
# This wrapper determines the installation directory and sets up the perl runtime environment
# appropriately, then executes the script.
#

use File::Copy;
use File::Path qw(make_path);
use File::Basename;
use strict;
use FIG_Config;
use Getopt::Long;

my $source_dir = "$FIG_Config::fig_disk/dist/releases/current";

my $usage = "Usage: $0 [--source source-dir] destination-dir [module-dir]\n";

if (!GetOptions("source=s" => \$source_dir))
{
    die $usage;
}

@ARGV == 1 or @ARGV == 2  or die $usage;

my $dest_dir = shift;

-d $dest_dir or die "Destination directory $dest_dir does not exist\n";

my $module_dir = shift;

#
# Find the CPAN modules we need, from the cache in $module_dir.
#
#my @required_module_names = qw(YAML);
my @required_module_names = qw(YAML URI HTML-Tagset HTML-Parser libwww-perl Task-Weaken SOAP-Lite
			       File-HomeDir);


my @required_modules;
my $err = 0;
if ($module_dir)
{
    my @avail = <$module_dir/*>;
    for my $n (@required_module_names)
    {
	my @have = grep { m,/$n-\d+, } @avail;
	if (@have == 0)
	{
	    warn "Missing required module $n\n";
	    $err++;
	    next;
	}
	elsif (@have > 1)
	{
	    warn "multiple modules available for $n: @have\n";
	    $err++;
	    next;
	}
	push(@required_modules, $have[0]);
    }
}
print "Modules:\n";
print "  $_\n" for @required_modules;

my $bin_dir = "$dest_dir/bin";
my $plbin_dir = "$dest_dir/plbin";
my $lib_dir = "$dest_dir/lib";
my $mod_dir = "$dest_dir/modules";
my $modsrc_dir = "$dest_dir/modules/sources";

-d $bin_dir or mkdir $bin_dir or die "Cannot mkdir $bin_dir: $!";
-d $plbin_dir or mkdir $plbin_dir or die "Cannot mkdir $plbin_dir: $!";
-d $lib_dir or mkdir $lib_dir or die "Cannot mkdir $lib_dir: $!";
-d $mod_dir or mkdir $mod_dir or die "Cannot mkdir $mod_dir: $!";
if (-d $modsrc_dir)
{
    system("rm", "-rf", $modsrc_dir);
}
mkdir $modsrc_dir or die "Cannot mkdir $modsrc_dir: $!";

my @libs_preserve_dir_structure;
my @libs = find_sas_files("$source_dir/FigKernelPackages", ".pm");
push(@libs, find_sas_files("$source_dir/DesktopRast", ".pm", 1));
push(@libs_preserve_dir_structure, find_sas_files({dir => "$source_dir/ModelSEED", regex => qr/\.pm/, recursive => 1}));
print "Libs:\n";
print "  $_\n" for @libs;

my @bins = find_sas_files("$source_dir/FigKernelScripts", ".pl");
push(@bins, find_sas_files("$source_dir/DesktopRast", ".pl", 1));
push(@bins, find_sas_files("$source_dir/ModelSEED", ".pl", 1));

#
# We also include the sgv.cgi from FigWebServices as a special case.
#
push(@bins, "$source_dir/FigWebServices/sgv.cgi");

print "Bins:\n";
print "  $_\n" for @bins;


for my $lib (@libs_preserve_dir_structure) {
    my $path = dirname($lib);
    my $base = basename($lib);
    $path =~ s/$source_dir//;
    make_path("$lib_dir/$path");
    copy($lib, "$lib_dir/$path/$base");
}

for my $lib (@libs)
{
    my $base = basename($lib);
    my $dest = "$lib_dir/$base";
    copy($lib, $dest) or die "Error copying $base to $dest: $!";
}

for my $bin (@bins)
{
    my $base = basename($bin);
    my $dest = "$plbin_dir/$base";
    copy($bin, $dest) or die "Error copying $base to $dest: $!";

    create_wrapper($base);
}

my @mod_dirs;
for my $mod (@required_modules)
{
    opendir(D,  $modsrc_dir);
    my %dirs = map { $_ => 1 } readdir(D);
    closedir(D);
    my $rc = system("tar", "-C", $modsrc_dir, "-x", "-z", "-f", $mod);
    $rc == 0 or die "Error untarring $mod\n";

    opendir(D, $modsrc_dir);
    my @new = grep { !$dirs{$_} } readdir(D);
    closedir(D);
    push(@mod_dirs, @new);
}
#
# Create a script for building the modules.
#
if (@mod_dirs)
{
    my $script = "$mod_dir/BUILD_MODULES";
    open(F, ">", $script) or die "Cannot write $script: $!";
    print F <<END;
#!/bin/sh
dir=\`dirname \$0\`
dir=\`cd \$dir; pwd\`
END
    for my $mod (@mod_dirs)
    {
	my $pre;
	if ($mod =~ /^HTML-Parser/)
	{
	    $pre = "echo no |";
	}
	print F <<END;
	echo "Build $mod"
	(cd \$dir/sources/$mod; $pre perl Makefile.PL PREFIX=\$dir LIB=\$dir/lib; make; make install)
END
    }
    chmod 0755, $script;
}

#
# Create the shell-script wrapper for this perl script.
#
sub create_wrapper
{
    my($name) = @_;

    my $base = basename($name, ".pl");

    my $fh;
    my $out = "$bin_dir/$base";
    print "name=$name base=$base out=$out\n";

    open($fh, ">", $out) or die "Cannot open $out for writing: $!";

    print $fh <<END;
#!/bin/sh
dir=\`dirname \$0\`
dir=\`cd \$dir/..; pwd\`
export SAS_HOME=\$dir
export DYLD_FALLBACK_LIBRARY_PATH=\$dir/lib
export PATH=\${PATH}:\$dir/bin
export PERL5LIB=\$dir/lib:\$dir/modules/lib
perl \$dir/plbin/$name "\$@"
END
    close($fh);
    chmod 0755, $out;
}

sub find_sas_files
{
    my($dir_stack, $dir, $regex, $recursive, $all_are_sas);
    my ($args) = shift @_;
    # old call method is find_sas_files(dir, suffix, all_are_sas)
    if(ref($args) ne 'HASH') {
        $dir = $args;
        my $suffix  = shift @_;
        $regex = qr/$suffix$/;
        $all_are_sas = shift @_;
        $recursive = 0;
        $dir_stack = [$dir];
    } else {
        $dir_stack = [$args->{dir}];
        $regex = $args->{regex};
        $recursive = $args->{recursive} || 0;
        $all_are_sas = $args->{all_are_sas} || 0;
    }
    my @out;
    while(@$dir_stack > 0) {
        $dir = shift @$dir_stack;
        opendir(D, $dir) or warn "Cannot opendir $dir: $!";
        # prevent . and .. from getting in files list
        my @files = grep { !/^\.\.?$/ } readdir(D); 
        while (my $f = shift @files) {
            my $path = "$dir/$f";
            if($recursive && -d $path) {
                push(@$dir_stack, $path);
                next;
            }
            next unless $f =~ $regex and -f $path;

            if ($all_are_sas) {
                push(@out, $path);
                next;
            }
            #
            # svr*.pl files are always SAS components.
            #
            if ($f =~ /^svr.*\.pl$/)
            {
                push(@out, $path);
                next;
            }

            if (!open(F, "<", $path))
            {
                warn "Cannot open $path: $!";
                next;
            }

            while (<F>)
            {
                last if $. > 10;
                if (/SAS\s+Component/i)
                {
                push(@out, $path);
                last;
                }
            }
            close(F);
        }
        closedir(D);
    }
    return @out;
}
