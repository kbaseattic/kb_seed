# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.074",
	package_date => 1391712101,
	package_date_str => "Feb 06, 2014 12:41:41",
    };
    return bless $self, $class;
}
1;
