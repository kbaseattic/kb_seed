# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.091",
	package_date => 1399584620,
	package_date_str => "May 08, 2014 16:30:20",
    };
    return bless $self, $class;
}
1;
