# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.089",
	package_date => 1398970864,
	package_date_str => "May 01, 2014 14:01:04",
    };
    return bless $self, $class;
}
1;
