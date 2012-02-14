#
# Build the SEED Access Scripts distribution from the code in the current checkout
# of the SEED code.
# 
# This is a cusotmized version that builds the particular scripts for the
# MacOS desktop application.
#
# In particular, we don't try to include modules because the D-RAST
# perl package includes all of them.
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
use File::Copy::Recursive 'dircopy';
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

my $bin_dir = "$dest_dir/bin";
my $plbin_dir = "$dest_dir/plbin";
my $lib_dir = "$dest_dir/lib";

-d $bin_dir or mkdir $bin_dir or die "Cannot mkdir $bin_dir: $!";
-d $plbin_dir or mkdir $plbin_dir or die "Cannot mkdir $plbin_dir: $!";
-d $lib_dir or mkdir $lib_dir or die "Cannot mkdir $lib_dir: $!";

my @copy_lib_dirs;

my @libs = find_sas_files("$source_dir/FigKernelPackages", ".pm");
push(@libs, find_sas_files("$source_dir/DesktopRast", ".pm", 1));

my @libs_preserve_dir_structure = find_sas_files(
    {dir => "$source_dir/ModelSEED", regex => qr/\.pm/, recursive => 1 });
print "Libs:\n";
print "  $_\n" for @libs;

my @bins = find_sas_files("$source_dir/FigKernelScripts", ".pl");
push(@bins, find_sas_files("$source_dir/ModelSEED", ".pl", 1));
push(@bins, find_sas_files("$source_dir/DesktopRast", ".pl", 1));

print "Bins:\n";
print "  $_\n" for @bins;

#if (-d "$source_dir/DesktopRast/debian")
#{
#    dircopy("$source_dir/DesktopRast/debian", "$dest_dir/debian");
#}
copy("$source_dir/DesktopRast/install_debian_binaries.pl", $dest_dir);

for my $dir (@copy_lib_dirs)
{
    my $name = basename($dir);
    dircopy($dir, "$lib_dir/$name");
}

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

create_wrapper("parse_genbank.pl", "svr_parse_genbank");

#
# Create the shell-script wrapper for this perl script.
#
sub create_wrapper
{
    my($name, $base) = @_;

    if (!defined($base))
    {
	$base = basename($name, ".pl");
    }

    my $fh;
    my $out = "$bin_dir/$base";
    print "name=$name base=$base out=$out\n";

    open($fh, ">", $out) or die "Cannot open $out for writing: $!";

    print $fh <<END;
#!/bin/bash
dir=\`dirname \$0\`
dir=\`cd \$dir/..; pwd\`
export SAS_HOME=\$dir
export DYLD_FALLBACK_LIBRARY_PATH=\$dir/lib
export PATH=\$dir/bin:\${PATH}
export PERL5LIB=\$dir/lib:\$dir/modules/lib:\$PERL5LIB

killgroup () {
    kill 0
}


if [[ -z "\$DTR_SUBPROCESS" ]] ; then

    exec \"\$dir/bin/perl\" \"\$dir/plbin/$name\" "\$@"

else
     trap killgroup INT TERM HUP

     unset DTR_SUBPROCESS
     \"\$dir/bin/perl\" \"\$dir/plbin/$name\" "\$@" < /dev/stdin &

     wait

fi


END
    close($fh);
    chmod 0755, $out;
}

sub find_sas_files
{
    my($dir_stack, $dir, $regex, $recursive, $all_are_sas);
    my ($args) = shift @_;
    # old version is find_sas_files($dir, $suffix, $all_are_sas)
    if(ref($args) ne "HASH") {
        $dir = $args;
        $dir_stack = [$dir];
        my $suffix = shift @_;
        $regex = qr/$suffix$/;
        $all_are_sas = shift @_;
        $recursive = 0;
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
