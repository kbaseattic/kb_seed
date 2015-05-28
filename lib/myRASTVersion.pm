# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.119",
	package_date => 1432824915,
	package_date_str => "May 28, 2015 09:55:15",
    };
    return bless $self, $class;
}
1;
