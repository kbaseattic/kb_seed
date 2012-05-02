# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.013",
	package_date => 1335986879,
	package_date_str => "May 02, 2012 14:27:59",
    };
    return bless $self, $class;
}
1;
