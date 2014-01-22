# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.068",
	package_date => 1390413139,
	package_date_str => "Jan 22, 2014 11:52:19",
    };
    return bless $self, $class;
}
1;
