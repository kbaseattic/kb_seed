# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.011",
	package_date => 1334691603,
	package_date_str => "Apr 17, 2012 14:40:03",
    };
    return bless $self, $class;
}
1;
