# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.050",
	package_date => 1359756479,
	package_date_str => "Feb 01, 2013 16:07:59",
    };
    return bless $self, $class;
}
1;
