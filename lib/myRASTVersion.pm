# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.002",
	package_date => 1330123386,
	package_date_str => "Feb 24, 2012 16:43:06",
    };
    return bless $self, $class;
}
1;
