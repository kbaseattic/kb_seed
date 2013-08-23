# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.059",
	package_date => 1377292814,
	package_date_str => "Aug 23, 2013 16:20:14",
    };
    return bless $self, $class;
}
1;
