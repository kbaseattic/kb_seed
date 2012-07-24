# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.020",
	package_date => 1343159448,
	package_date_str => "Jul 24, 2012 14:50:48",
    };
    return bless $self, $class;
}
1;
