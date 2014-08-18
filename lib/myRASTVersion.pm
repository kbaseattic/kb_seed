# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.106",
	package_date => 1408394229,
	package_date_str => "Aug 18, 2014 15:37:09",
    };
    return bless $self, $class;
}
1;
