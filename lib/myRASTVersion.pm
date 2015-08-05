# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.124",
	package_date => 1438788820,
	package_date_str => "Aug 05, 2015 10:33:40",
    };
    return bless $self, $class;
}
1;
