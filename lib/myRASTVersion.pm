# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.129",
	package_date => 1448315042,
	package_date_str => "Nov 23, 2015 15:44:02",
    };
    return bless $self, $class;
}
1;
