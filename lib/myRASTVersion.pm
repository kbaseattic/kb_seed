# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.049",
	package_date => 1359755965,
	package_date_str => "Feb 01, 2013 15:59:25",
    };
    return bless $self, $class;
}
1;
