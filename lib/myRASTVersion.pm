# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.006",
	package_date => 1332174997,
	package_date_str => "Mar 19, 2012 11:36:37",
    };
    return bless $self, $class;
}
1;
