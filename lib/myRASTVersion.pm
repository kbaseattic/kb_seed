# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.071",
	package_date => 1390584009,
	package_date_str => "Jan 24, 2014 11:20:09",
    };
    return bless $self, $class;
}
1;
