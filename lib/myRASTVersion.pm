# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.041",
	package_date => 1348677873,
	package_date_str => "Sep 26, 2012 11:44:33",
    };
    return bless $self, $class;
}
1;
