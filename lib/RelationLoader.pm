package RelationLoader;

use Carp;
use File::Spec;
use File::Temp;
use strict;

sub new
{
    my($class, $rel_name, $fields) = @_;


    my $fh = File::Temp->new(TEMPLATE => "rel_${rel_name}_XXXXX", UNLINK => 1, DIR => File::Spec->tmpdir());
    my $self = {
	rel_name => $rel_name,
	fields => $fields,
	n_fields => scalar @$fields,
	fh => $fh,
	file => $fh->filename,
    };
    return bless $self, $class;
}

sub add
{
    my($self, @fields) = @_;
    if (@fields != $self->{n_fields})
    {
	confess "Invalid call to RelationLoader::add for relation $self->{rel_name}";
    }
    my $fh = $self->{fh};
    print $fh join("\t", @fields), "\n";
}

sub load
{
    my($self, $dbh) = @_;
    $self->{fh}->close();
#     print "Load $self->{file}\n";
    chmod(0644, $self->{file});
    $dbh->load_table(file => $self->{file}, tbl => $self->{rel_name});
}

1;
