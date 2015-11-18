# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.127",
	package_date => 1447870939,
	package_date_str => "Nov 18, 2015 12:22:19",
    };
    return bless $self, $class;
}
1;
