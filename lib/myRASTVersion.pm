# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.004",
	package_date => 1330467643,
	package_date_str => "Feb 28, 2012 16:20:43",
    };
    return bless $self, $class;
}
1;
