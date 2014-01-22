# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.069",
	package_date => 1390413540,
	package_date_str => "Jan 22, 2014 11:59:00",
    };
    return bless $self, $class;
}
1;
