# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.067",
	package_date => 1390255331,
	package_date_str => "Jan 20, 2014 16:02:11",
    };
    return bless $self, $class;
}
1;
