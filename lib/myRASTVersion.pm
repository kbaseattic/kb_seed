# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.117",
	package_date => 1427221202,
	package_date_str => "Mar 24, 2015 13:20:02",
    };
    return bless $self, $class;
}
1;
