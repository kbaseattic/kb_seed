# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.135",
	package_date => 1453829273,
	package_date_str => "Jan 26, 2016 11:27:53",
    };
    return bless $self, $class;
}
1;
