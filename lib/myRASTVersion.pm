# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.062",
	package_date => 1380750205,
	package_date_str => "Oct 02, 2013 16:43:25",
    };
    return bless $self, $class;
}
1;
