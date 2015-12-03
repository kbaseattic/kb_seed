# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.131",
	package_date => 1449157565,
	package_date_str => "Dec 03, 2015 09:46:05",
    };
    return bless $self, $class;
}
1;
