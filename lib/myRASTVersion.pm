# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.101",
	package_date => 1406760308,
	package_date_str => "Jul 30, 2014 17:45:08",
    };
    return bless $self, $class;
}
1;
