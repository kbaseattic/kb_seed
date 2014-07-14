# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.098",
	package_date => 1405357968,
	package_date_str => "Jul 14, 2014 12:12:48",
    };
    return bless $self, $class;
}
1;
