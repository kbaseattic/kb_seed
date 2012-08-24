# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.034",
	package_date => 1345829681,
	package_date_str => "Aug 24, 2012 12:34:41",
    };
    return bless $self, $class;
}
1;
