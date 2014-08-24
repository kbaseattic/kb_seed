# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.107",
	package_date => 1408917195,
	package_date_str => "Aug 24, 2014 16:53:15",
    };
    return bless $self, $class;
}
1;
