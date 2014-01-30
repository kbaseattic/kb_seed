# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.073",
	package_date => 1391114582,
	package_date_str => "Jan 30, 2014 14:43:02",
    };
    return bless $self, $class;
}
1;
