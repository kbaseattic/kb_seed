# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.061",
	package_date => 1379446374,
	package_date_str => "Sep 17, 2013 14:32:54",
    };
    return bless $self, $class;
}
1;
