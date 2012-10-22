# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.045",
	package_date => 1350938516,
	package_date_str => "Oct 22, 2012 15:41:56",
    };
    return bless $self, $class;
}
1;
