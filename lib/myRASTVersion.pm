# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.053",
	package_date => 1360274741,
	package_date_str => "Feb 07, 2013 16:05:41",
    };
    return bless $self, $class;
}
1;
