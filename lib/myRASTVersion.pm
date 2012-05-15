# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.016",
	package_date => 1337116953,
	package_date_str => "May 15, 2012 16:22:33",
    };
    return bless $self, $class;
}
1;
