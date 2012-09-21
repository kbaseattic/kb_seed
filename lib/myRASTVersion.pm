# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.036",
	package_date => 1348262949,
	package_date_str => "Sep 21, 2012 16:29:09",
    };
    return bless $self, $class;
}
1;
