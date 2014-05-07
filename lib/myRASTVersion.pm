# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.090",
	package_date => 1399490128,
	package_date_str => "May 07, 2014 14:15:28",
    };
    return bless $self, $class;
}
1;
