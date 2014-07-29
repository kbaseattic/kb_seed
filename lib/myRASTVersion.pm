# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.100",
	package_date => 1406580514,
	package_date_str => "Jul 28, 2014 15:48:34",
    };
    return bless $self, $class;
}
1;
