# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.108",
	package_date => 1411056930,
	package_date_str => "Sep 18, 2014 11:15:30",
    };
    return bless $self, $class;
}
1;
