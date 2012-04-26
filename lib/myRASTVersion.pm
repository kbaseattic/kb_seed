# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.012",
	package_date => 1335472791,
	package_date_str => "Apr 26, 2012 15:39:51",
    };
    return bless $self, $class;
}
1;
