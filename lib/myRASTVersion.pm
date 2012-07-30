# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.024",
	package_date => 1343667743,
	package_date_str => "Jul 30, 2012 12:02:23",
    };
    return bless $self, $class;
}
1;
