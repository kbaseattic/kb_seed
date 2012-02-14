# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.001",
	package_date => 1329154822,
	package_date_str => "Feb 13, 2012 11:40:22",
    };
    return bless $self, $class;
}
1;
