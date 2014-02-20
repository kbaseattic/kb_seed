# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.076",
	package_date => 1392937534,
	package_date_str => "Feb 20, 2014 17:05:34",
    };
    return bless $self, $class;
}
1;
