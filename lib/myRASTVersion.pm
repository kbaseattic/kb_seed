# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.039",
	package_date => 1348607709,
	package_date_str => "Sep 25, 2012 16:15:09",
    };
    return bless $self, $class;
}
1;
