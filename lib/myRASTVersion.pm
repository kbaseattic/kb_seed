# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.075",
	package_date => 1392923000,
	package_date_str => "Feb 20, 2014 13:03:20",
    };
    return bless $self, $class;
}
1;
