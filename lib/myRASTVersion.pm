# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.033",
	package_date => 1345742756,
	package_date_str => "Aug 23, 2012 12:25:56",
    };
    return bless $self, $class;
}
1;
