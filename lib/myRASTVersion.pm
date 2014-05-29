# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.092",
	package_date => 1401400608,
	package_date_str => "May 29, 2014 16:56:48",
    };
    return bless $self, $class;
}
1;
