# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.063",
	package_date => 1381170245,
	package_date_str => "Oct 07, 2013 13:24:05",
    };
    return bless $self, $class;
}
1;
