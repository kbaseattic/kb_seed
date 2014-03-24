# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.086",
	package_date => 1395695327,
	package_date_str => "Mar 24, 2014 16:08:47",
    };
    return bless $self, $class;
}
1;
