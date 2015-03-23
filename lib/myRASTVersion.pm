# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.115",
	package_date => 1427147120,
	package_date_str => "Mar 23, 2015 16:45:20",
    };
    return bless $self, $class;
}
1;
