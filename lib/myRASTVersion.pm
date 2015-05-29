# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.121",
	package_date => 1432933825,
	package_date_str => "May 29, 2015 16:10:25",
    };
    return bless $self, $class;
}
1;
