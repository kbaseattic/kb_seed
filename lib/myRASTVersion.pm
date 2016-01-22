# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.134",
	package_date => 1453490263,
	package_date_str => "Jan 22, 2016 13:17:43",
    };
    return bless $self, $class;
}
1;
