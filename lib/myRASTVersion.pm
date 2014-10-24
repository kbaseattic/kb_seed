# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.111",
	package_date => 1414191601,
	package_date_str => "Oct 24, 2014 18:00:01",
    };
    return bless $self, $class;
}
1;
