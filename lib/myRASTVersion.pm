# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.058",
	package_date => 1377291735,
	package_date_str => "Aug 23, 2013 16:02:15",
    };
    return bless $self, $class;
}
1;
