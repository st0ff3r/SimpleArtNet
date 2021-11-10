package LedController::Progress;

use IPC::ShareLite;
use POSIX qw( ceil );
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Const;
use CGI;
use CGI::Cookie ();
use Data::Dumper;

use constant REDIS_HOST => '127.0.0.1';
use constant REDIS_PORT => '6379';

$SIG{PIPE} = sub {
	warn "connection aborted\n";
};

sub handler {
	my $r = shift;
	
	my $redis_host = REDIS_HOST;
	my $redis_port = REDIS_PORT;
	my $redis = Redis->new(
		server => "$redis_host:$redis_port",
	) || warn $!;
		
	my %cookies = ();
	my $session_id = '';
	if (%cookies = CGI::Cookie->fetch) {
		# cookie received
		$session_id = $cookies{'session_id'}->value;
	
		# send it again
		my $cookie = CGI::Cookie->new(-name  => 'session_id', -value => $session_id);
		$r->err_headers_out->add('Set-Cookie' => $cookie);
	}
	
	$r->err_headers_out->add('Content-type' => 'text/event-stream');
	$r->err_headers_out->add('Cache-Control' => 'no-cache');
	$r->err_headers_out->add('Connection' => 'keep-alive');
	
	while (1) {
		my $progress = $redis->get('progress:' . $session_id);
		if ($progress == -1) {
			print("data: ERROR\n\n");
			$redis->del('progress:' . $session_id);
			exit;
		}
		elsif ($progress == 100) {
			print("data: 100\n\n");			
			print("data: DONE\n\n");
			$redis->del('progress:' . $session_id);
			exit;
		}
		else {
			print("data: " . ceil($progress) . "\n\n");
		}
		$r->rflush;
	}
}

1;

__END__
