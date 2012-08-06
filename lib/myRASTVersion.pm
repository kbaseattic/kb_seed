# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.026",
	package_date => 1344282555,
	package_date_str => "Aug 06, 2012 14:49:15",
    };
    return bless $self, $class;
}
1;
