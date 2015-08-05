# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.123",
	package_date => 1438788583,
	package_date_str => "Aug 05, 2015 10:29:43",
    };
    return bless $self, $class;
}
1;
