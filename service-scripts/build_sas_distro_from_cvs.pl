#
# Check out a clean copy of the code in CVS, then run build_sas_distro against it to generate
# clean distribution.
#

use strict;
use FIG;
use FIG_Config;
use Cwd;

use Getopt::Long;

my $version;
my $build_dtr;

my $rc = GetOptions(dtr => \$build_dtr,
		    'version=s' => \$version,
		   );

$rc && @ARGV == 1 or die "usage: $0 [--version version-string] [--dtr] output-tarfile\n";

my $output_tarfile = shift;

my $modules = "/home/olson/Build/perl-packages";
my $temp = "$FIG_Config::temp/sas_build.$$";
my $distro_dir = "$temp/sas";

&FIG::verify_dir($temp);
&FIG::verify_dir($distro_dir);

my $here = getcwd();

chdir($temp);

my @cvs_modules = qw(FigKernelScripts FigKernelPackages ModelSEED ModelSEEDScripts);
my $tarfile_dir;
my $cmd;
if ($build_dtr)
{
    push(@cvs_modules, 'DesktopRast');
    $cmd = "build_dtr_distro";
    $tarfile_dir = "myrast-$version";
    my $new = "$distro_dir/$tarfile_dir";
    &FIG::verify_dir($new);
    $distro_dir = $new;
}
else
{
    push(@cvs_modules, 'FigWebServices');
    $cmd = "build_sas_distro";
}

my $rc = system('cvs -d :pserver:anonymous@biocvs.mcs.anl.gov:/disks/cvs/bio export -D now ' .
		join(" ", @cvs_modules) . " > cvs_checkout.stdout");
if ($rc != 0)
{
    die "cvs failed with rc=$rc\n";
}

chdir($here);

if (defined($version))
{
    my $vfile = "$temp/FigKernelPackages/myRASTVersion.pm";
    if (open(VF, ">", $vfile))
    {
	print VF <<END;
# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my(\$class) = \@_;
    my \$self = {
	release => \"$version\",
    };
    return bless \$self, \$class;
}
1;
END
    }
    else
    {
	warn "Cannot open $vfile: $!";
    }

    #
    # Also look for ClientThing and update AGENT_NAME.
    #
    my $ct = "$temp/FigKernelPackages/ClientThing.pm";
    if (open(my $ctfh, "<", $ct))
    {
	local $/;
	undef $/;
	my $txt = <$ctfh>;
	close($ctfh);
	my $new_name;
	if ($build_dtr)
	{
	    $new_name = "myRAST version $version";
	}
	else
	{
	    $new_name = "SAS version $version";
	}
	$txt =~ s/AGENT_NAME\s+=>\s+"[^"]*"/AGENT_NAME => "$new_name"/;
	open($ctfh, ">", $ct);
	print $ctfh $txt;
	close($ctfh);
    }
}

$rc = system("$FIG_Config::bin/$cmd", "--source", $temp, $distro_dir, $modules);

if ($rc != 0)
{
    die "build_sas_distro failed with rc=$rc\n";
}

if ($tarfile_dir)
{
    $rc = system("tar", "-c", "-C", "$distro_dir/..", "-z", "-f", $output_tarfile, $tarfile_dir);
}
else
{
    $rc = system("tar", "-c", "-C", $distro_dir, "-z", "-f", $output_tarfile, ".");
}
if ($rc != 0)
{
    die "tar failed with rc=$rc\n";
}
