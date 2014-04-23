# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.087",
	package_date => 1398277679,
	package_date_str => "Apr 23, 2014 13:27:59",
    };
    return bless $self, $class;
}
1;
