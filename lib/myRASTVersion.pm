# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.126",
	package_date => 1440693776,
	package_date_str => "Aug 27, 2015 11:42:56",
    };
    return bless $self, $class;
}
1;
