# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.130",
	package_date => 1448920085,
	package_date_str => "Nov 30, 2015 15:48:05",
    };
    return bless $self, $class;
}
1;
