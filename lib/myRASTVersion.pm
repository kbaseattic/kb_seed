# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.042",
	package_date => 1348681938,
	package_date_str => "Sep 26, 2012 12:52:18",
    };
    return bless $self, $class;
}
1;
