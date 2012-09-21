# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.037",
	package_date => 1348263562,
	package_date_str => "Sep 21, 2012 16:39:22",
    };
    return bless $self, $class;
}
1;
