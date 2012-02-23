# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.001",
	package_date => 1330028198,
	package_date_str => "Feb 23, 2012 14:16:38",
    };
    return bless $self, $class;
}
1;
