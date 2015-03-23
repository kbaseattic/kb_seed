#!/usr/bin/perl -w

#
# This is a SAS component.
#

use strict;
BEGIN {
    eval { require FIG_Config; };
}
no warnings qw(once);

package ERDBExtras;

=head1 ERDB Extras

=head2 Introduction

This module contains parameter declarations used by the ERDB system.

A package called B<FIG_Config> must be somewhere in the PERL path. Parameters
that vary from server to server should go in there. Parameters common to the
entire installation should go in here. Note that if B<FIG_Config> is empty,
everything will still work.

=cut

=head2 Configuration Values

=head3 customERDBtypes

C<$ERDBExtras::customERDBtypes> contains a list of the custom ERDB types associated
with the current code base. This replaces the old B<FIG_Config> variable of the
same name. When a new custom type is created, it should be put in this list.

=cut

our $customERDBtypes        = [qw(ERDBTypeDNA ERDBTypeLink ERDBTypeImage
                               ERDBTypeLongString ERDBTypeSemiBoolean
                               ERDBTypeRectangle ERDBTypeCountVector
                               ERDBTypeProteinData ERDBTypeShortString)];

=head3 sort_options

C<$ERDBExtras::sort_options> specifies the options to be used when performing a
sort during a database load. So, for example, if the host machine has a lot of
memory, you can specify a value for the C<-S> option to increase the size of the
sort buffer.

=cut

our $sort_options           = $FIG_Config::sort_options || "";

=head3 temp

C<$ERDBExtras::temp> specifies the name of the directory to be used for
temporary files. It should be a location that is writable and accessible
from the web, because it is used to store images (see L</temp_url>).

=cut

our $temp                   = $FIG_Config::temp || "/tmp";

=head3 temp_url

C<$ERDBExtras::temp_url> must be the URL that can be used to find the temporary
directory from the web (see L</temp>).

=cut

our $temp_url               = $FIG_Config::temp_url || "/tmp";

=head3 delete_limit

C<$ERDBExtras::delete_limit> specifies the maximum number of database rows that should
be deleted at a time. If a non-zero value is specified, SQL deletes will be
limited to the specified size. Use this parameter if large deletes are locking
the database server for unacceptable periods.

=cut

our $delete_limit           = 0;

=head3 cgi_url

C<$ERDBExtras::cgi_url> specifies the URL of the CGI directory containing the
ERDB web scripts.

=cut

our $cgi_url                = $FIG_Config::cgi_url || "/cgi-bin";

=head3 diagram_url

C<$ERDBExtras::diagramURL> specifies the URL of the ERDB diagramming engine.
This is a compiled flash movie file (SWF) used for the documentation widget.

=cut

our $diagramURL             = $FIG_Config::diagramURL || "$cgi_url/Html/Diagrammer.swf";

=head3 query_limit

C<$ERDBExtras::query_limit> specifies the maximum number of rows that can be
returned by the query script if the user is not authorized. This is used
to prevent denial-of-service attackes against the query engine.

=cut

our $query_limit            = 1000;

=head3 css_dir

C<$ERDBExtras::css_dir> specifies the directory containing the C<ERDB.css>
file.

=cut

our $css_dir                = "$cgi_url/Html/css";

=head3 js_dir

C<$ERDBExtras::js_dir> specifies the directory containing the C<ERDB.js>
file.

=cut

our $js_dir                 = "$cgi_url/Html";

=head3 query_retries

C<$ERDBExtras::query_retries> specifies the number of times a lost connection
should be retried when querying the database.

=cut

our $query_retries          = 1;

=head3 sleep_time

C<$ERDBExtras::sleep_time> specifies how many seconds to wait between database
reconnection attempts.

=cut

our $sleep_time             = 10;

1;
