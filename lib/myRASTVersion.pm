# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.139",
	package_date => 1464717294,
	package_date_str => "May 31, 2016 12:54:54",
    };
    return bless $self, $class;
}
1;
