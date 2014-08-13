# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.103",
	package_date => 1407949642,
	package_date_str => "Aug 13, 2014 12:07:22",
    };
    return bless $self, $class;
}
1;
