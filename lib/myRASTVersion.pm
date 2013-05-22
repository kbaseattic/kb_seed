# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.056",
	package_date => 1369251041,
	package_date_str => "May 22, 2013 14:30:41",
    };
    return bless $self, $class;
}
1;
