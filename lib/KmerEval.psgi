use Bio::KBase::KmerEval::KmerEvalImpl;

use Bio::KBase::KmerEval::Service;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = Bio::KBase::KmerEval::KmerEvalImpl->new;
    push(@dispatch, 'KmerEval' => $obj);
}


my $server = Bio::KBase::KmerEval::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
