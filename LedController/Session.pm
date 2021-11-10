package LedController::Session;

use strict;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Data::UUID;
use Data::Dumper;

sub handler {
	my $r = shift;

	my $ug = Data::UUID->new;

	my ($received_session_id, $file) = $r->uri =~ m|^(.*)(/.*)$|;
	warn Dumper ($received_session_id, $file);
	
	if ($received_session_id) {
		warn "id: $received_session_id file: $file\n";
		$r->uri($file);
		return Apache2::Const::DECLINED;
	}
	else {
		warn "redirecting\n";
		$r->headers_out->set('Location' => $ug->create_hex . '/index.epl');
		return Apache2::Const::REDIRECT;
	}
}

1;

__END__
