# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.085",
	package_date => 1395695015,
	package_date_str => "Mar 24, 2014 16:03:35",
    };
    return bless $self, $class;
}
1;
