# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.007",
	package_date => 1333559316,
	package_date_str => "Apr 04, 2012 12:08:36",
    };
    return bless $self, $class;
}
1;
