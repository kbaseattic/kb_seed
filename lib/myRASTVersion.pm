# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.051",
	package_date => 1360092350,
	package_date_str => "Feb 05, 2013 13:25:50",
    };
    return bless $self, $class;
}
1;
