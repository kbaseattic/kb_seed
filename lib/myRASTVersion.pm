# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.065",
	package_date => 1389890609,
	package_date_str => "Jan 16, 2014 10:43:29",
    };
    return bless $self, $class;
}
1;
