# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.030",
	package_date => 1345655194,
	package_date_str => "Aug 22, 2012 12:06:34",
    };
    return bless $self, $class;
}
1;
