# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.110",
	package_date => 1411925693,
	package_date_str => "Sep 28, 2014 12:34:53",
    };
    return bless $self, $class;
}
1;
