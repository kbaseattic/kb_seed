# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.079",
	package_date => 1394082605,
	package_date_str => "Mar 05, 2014 23:10:05",
    };
    return bless $self, $class;
}
1;
