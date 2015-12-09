# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.132",
	package_date => 1449693317,
	package_date_str => "Dec 09, 2015 14:35:17",
    };
    return bless $self, $class;
}
1;
