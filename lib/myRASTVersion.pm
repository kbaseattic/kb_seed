# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.048",
	package_date => 1355162505,
	package_date_str => "Dec 10, 2012 12:01:45",
    };
    return bless $self, $class;
}
1;
