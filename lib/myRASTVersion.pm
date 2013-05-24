# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.057",
	package_date => 1369428942,
	package_date_str => "May 24, 2013 15:55:42",
    };
    return bless $self, $class;
}
1;
