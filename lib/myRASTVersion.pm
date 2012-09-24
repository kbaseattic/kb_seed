# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.038",
	package_date => 1348522404,
	package_date_str => "Sep 24, 2012 16:33:24",
    };
    return bless $self, $class;
}
1;
