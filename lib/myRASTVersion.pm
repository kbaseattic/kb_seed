# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.055",
	package_date => 1369074273,
	package_date_str => "May 20, 2013 13:24:33",
    };
    return bless $self, $class;
}
1;
