# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.035",
	package_date => 1345829961,
	package_date_str => "Aug 24, 2012 12:39:21",
    };
    return bless $self, $class;
}
1;
