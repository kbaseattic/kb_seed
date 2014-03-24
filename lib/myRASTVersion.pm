# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.083",
	package_date => 1395674900,
	package_date_str => "Mar 24, 2014 10:28:20",
    };
    return bless $self, $class;
}
1;
