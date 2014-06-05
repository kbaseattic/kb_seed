# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.094",
	package_date => 1401984865,
	package_date_str => "Jun 05, 2014 11:14:25",
    };
    return bless $self, $class;
}
1;
