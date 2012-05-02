# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.014",
	package_date => 1335989382,
	package_date_str => "May 02, 2012 15:09:42",
    };
    return bless $self, $class;
}
1;
