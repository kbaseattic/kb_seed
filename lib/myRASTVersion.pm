# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.019",
	package_date => 1342755781,
	package_date_str => "Jul 19, 2012 22:43:01",
    };
    return bless $self, $class;
}
1;
