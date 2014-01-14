# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.064",
	package_date => 1389740076,
	package_date_str => "Jan 14, 2014 16:54:36",
    };
    return bless $self, $class;
}
1;
