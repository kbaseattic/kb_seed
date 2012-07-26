# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.023",
	package_date => 1343316601,
	package_date_str => "Jul 26, 2012 10:30:01",
    };
    return bless $self, $class;
}
1;
