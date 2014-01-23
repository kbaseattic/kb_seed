# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.070",
	package_date => 1390515498,
	package_date_str => "Jan 23, 2014 16:18:18",
    };
    return bless $self, $class;
}
1;
