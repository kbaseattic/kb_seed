# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.054",
	package_date => 1368722574,
	package_date_str => "May 16, 2013 11:42:54",
    };
    return bless $self, $class;
}
1;
