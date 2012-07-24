# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.022",
	package_date => 1343160314,
	package_date_str => "Jul 24, 2012 15:05:14",
    };
    return bless $self, $class;
}
1;
