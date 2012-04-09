# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.008",
	package_date => 1333995412,
	package_date_str => "Apr 09, 2012 13:16:52",
    };
    return bless $self, $class;
}
1;
