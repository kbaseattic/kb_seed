# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.082",
	package_date => 1394659488,
	package_date_str => "Mar 12, 2014 16:24:48",
    };
    return bless $self, $class;
}
1;
