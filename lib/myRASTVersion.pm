# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.137",
	package_date => 1454436778,
	package_date_str => "Feb 02, 2016 12:12:58",
    };
    return bless $self, $class;
}
1;
