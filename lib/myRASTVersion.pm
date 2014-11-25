# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.112",
	package_date => 1416941336,
	package_date_str => "Nov 25, 2014 12:48:56",
    };
    return bless $self, $class;
}
1;
