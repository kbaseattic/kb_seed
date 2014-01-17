# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.066",
	package_date => 1389995929,
	package_date_str => "Jan 17, 2014 15:58:49",
    };
    return bless $self, $class;
}
1;
