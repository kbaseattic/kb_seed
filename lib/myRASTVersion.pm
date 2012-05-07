# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.015",
	package_date => 1336419886,
	package_date_str => "May 07, 2012 14:44:46",
    };
    return bless $self, $class;
}
1;
