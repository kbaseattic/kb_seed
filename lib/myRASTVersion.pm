# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.084",
	package_date => 1395694350,
	package_date_str => "Mar 24, 2014 15:52:30",
    };
    return bless $self, $class;
}
1;
