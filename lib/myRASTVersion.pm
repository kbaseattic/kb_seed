# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.077",
	package_date => 1393444125,
	package_date_str => "Feb 26, 2014 13:48:45",
    };
    return bless $self, $class;
}
1;
