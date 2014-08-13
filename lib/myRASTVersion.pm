# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.104",
	package_date => 1407962126,
	package_date_str => "Aug 13, 2014 15:35:26",
    };
    return bless $self, $class;
}
1;
