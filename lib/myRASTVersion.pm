# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.133",
	package_date => 1449867991,
	package_date_str => "Dec 11, 2015 15:06:31",
    };
    return bless $self, $class;
}
1;
