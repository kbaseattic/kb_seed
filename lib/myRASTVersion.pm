# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.138",
	package_date => 1456767504,
	package_date_str => "Feb 29, 2016 11:38:24",
    };
    return bless $self, $class;
}
1;
