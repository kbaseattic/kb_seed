# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.046",
	package_date => 1354829863,
	package_date_str => "Dec 06, 2012 15:37:43",
    };
    return bless $self, $class;
}
1;
