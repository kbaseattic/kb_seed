# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.027",
	package_date => 1344977259,
	package_date_str => "Aug 14, 2012 15:47:39",
    };
    return bless $self, $class;
}
1;
