# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.081",
	package_date => 1394657398,
	package_date_str => "Mar 12, 2014 15:49:58",
    };
    return bless $self, $class;
}
1;
