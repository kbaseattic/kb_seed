# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.009",
	package_date => 1334166817,
	package_date_str => "Apr 11, 2012 12:53:37",
    };
    return bless $self, $class;
}
1;
