# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.105",
	package_date => 1408393980,
	package_date_str => "Aug 18, 2014 15:33:00",
    };
    return bless $self, $class;
}
1;
