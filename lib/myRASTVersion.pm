# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.118",
	package_date => 1432760303,
	package_date_str => "May 27, 2015 15:58:23",
    };
    return bless $self, $class;
}
1;
