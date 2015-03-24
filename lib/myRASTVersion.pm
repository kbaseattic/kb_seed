# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.116",
	package_date => 1427215823,
	package_date_str => "Mar 24, 2015 11:50:23",
    };
    return bless $self, $class;
}
1;
