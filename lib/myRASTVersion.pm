# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.095",
	package_date => 1402431472,
	package_date_str => "Jun 10, 2014 15:17:52",
    };
    return bless $self, $class;
}
1;
