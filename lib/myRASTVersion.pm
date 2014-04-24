# This is a SAS component.
package myRASTVersion;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(release));
sub new
{
    my($class) = @_;
    my $self = {
	release => "1.088",
	package_date => 1398373930,
	package_date_str => "Apr 24, 2014 16:12:10",
    };
    return bless $self, $class;
}
1;
