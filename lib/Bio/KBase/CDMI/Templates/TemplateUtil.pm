#
# This directory contains templates used to automatically generate the Entity-Relationship
# API and scripts using compile-dbd-to-typespec.  These templates previously existed in
# the typecomp repository.  This simple module simply allows you to fetch the installed
# location of this directory so that 
#
# The functionality of this script was copied from typecomp Bio::KBase::KIDL::KBT
#
package Bio::KBase::CDMI::Templates::TemplateUtil;

use strict;
use File::Spec;

sub install_path
{
    return File::Spec->catpath((File::Spec->splitpath(__FILE__))[0,1], '');
}

1;