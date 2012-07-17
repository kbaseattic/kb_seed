# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.018",
	package_date => 1342542680,
	package_date_str => "Jul 17, 2012 11:31:20",
    };
    return bless $self, $class;
}
1;
