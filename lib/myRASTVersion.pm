# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.032",
	package_date => 1345663000,
	package_date_str => "Aug 22, 2012 14:16:40",
    };
    return bless $self, $class;
}
1;
