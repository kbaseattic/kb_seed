# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.109",
	package_date => 1411860773,
	package_date_str => "Sep 27, 2014 18:32:53",
    };
    return bless $self, $class;
}
1;
