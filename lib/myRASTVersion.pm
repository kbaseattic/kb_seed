# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.040",
	package_date => 1348611166,
	package_date_str => "Sep 25, 2012 17:12:46",
    };
    return bless $self, $class;
}
1;
