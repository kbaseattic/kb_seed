use Bio::KBase::KmerEval::KmerEvalImpl;

use Bio::KBase::KmerEval::Service;



my @dispatch;

{
    my $obj = Bio::KBase::KmerEval::KmerEvalImpl->new;
    push(@dispatch, 'KmerEval' => $obj);
}


my $server = Bio::KBase::KmerEval::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub {
    my($env) = @_;
    
    my $resp = $server->handle_input($env);

    if ($env->{HTTP_ORIGIN})
    {
	my($code, $hdrs, $body) = @$resp;
	push(@$hdrs, 'Access-Control-Allow-Origin', $env->{HTTP_ORIGIN});
    }
    return $resp;
};

$handler;
