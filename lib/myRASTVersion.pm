# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.099",
	package_date => 1405369857,
	package_date_str => "Jul 14, 2014 15:30:57",
    };
    return bless $self, $class;
}
1;
