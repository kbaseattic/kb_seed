# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.125",
	package_date => 1439477392,
	package_date_str => "Aug 13, 2015 09:49:52",
    };
    return bless $self, $class;
}
1;
