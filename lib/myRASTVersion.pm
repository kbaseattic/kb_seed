# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.102",
	package_date => 1407252464,
	package_date_str => "Aug 05, 2014 10:27:44",
    };
    return bless $self, $class;
}
1;
