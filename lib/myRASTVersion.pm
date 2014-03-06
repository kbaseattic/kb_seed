# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.080",
	package_date => 1394083370,
	package_date_str => "Mar 05, 2014 23:22:50",
    };
    return bless $self, $class;
}
1;
