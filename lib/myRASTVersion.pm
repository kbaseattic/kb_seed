# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.017",
	package_date => 1339788124,
	package_date_str => "Jun 15, 2012 14:22:04",
    };
    return bless $self, $class;
}
1;
