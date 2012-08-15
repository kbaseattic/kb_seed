# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.029",
	package_date => 1345056165,
	package_date_str => "Aug 15, 2012 13:42:45",
    };
    return bless $self, $class;
}
1;
