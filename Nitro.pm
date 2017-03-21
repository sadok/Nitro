package Nitro;

use strict;
use warnings;
use LWP;
use Carp;
use JSON;
use URI::Escape;
our $VERSION = '1.04';

my $scheme = undef;

sub login {

	my ( $ipaddress, $username, $password, $is_ssl ) = @_;

	if ( !$ipaddress || $ipaddress eq q{} ) {
		Carp::confess 'Error : IP Address should not be null';
	}
	if ( !$username || $username eq q{} ) {
		Carp::confess 'Error : Username should not be null';
	}
	if ( !$password || $password eq q{} ) {
		Carp::confess 'Error : Password should not be null';
	}

	if ( $is_ssl == 1 ) {
		$scheme = 'https';
	}
	else {
		$scheme = 'http';
	}

	my $obj = undef;
	$obj->{username} = $username;
	$obj->{password} = $password;
	my $payload = JSON->new->allow_blessed->convert_blessed->encode($obj);
	$payload = '{"login" :' . $payload . '}';

	my $url         = "$scheme://$ipaddress/nitro/v1/config/login";
	my $contenttype = 'application/vnd.com.citrix.netscaler.login+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( POST => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->content($payload);
	$nitro_useragent->ssl_opts( verify_hostname => 0 );
	$nitro_useragent->timeout(5);

	my $response = $nitro_useragent->request($request);
	my $session  = undef;
	if ( HTTP::Status::is_error( $response->code ) ) {

		#$session = JSON->new->allow_blessed->convert_blessed->decode($response->content);
		$session->{errorcode} = $response->{_rc};
		$session->{message}   = $response->{_msg};
	}
	else {
		my $cookie = $response->header('Set-Cookie');
		if ( $cookie && $cookie =~ /NITRO_AUTH_TOKEN=(.*);/sm ) {
			$session->{sessionid} = uri_unescape($1);
		}
		$session->{errorcode} = 0;
		$session->{message}   = 'Done';
	}
	$session->{ns}       = $ipaddress;
	$session->{username} = $username;
	$session->{password} = $password;
	return $session;
} ## end sub login

# POST method : Used to clear, enable, add, unset, bind, import, export and save the configuration
# Arguments : session, objecttype, object, operation
sub post {

	my ( $session, $objecttype, $object, $operation ) = @_;

	if ( !$session || $session eq q{} ) {
		Carp::confess 'Error : Session should not be null';
	}
	if ( !( $session->{sessionid} ) ) {
		Carp::confess 'Error : Not logged in';
	}
	if ( !$objecttype || $objecttype eq q{} ) {
		Carp::confess 'Error : Object type should not be null';
	}
	if ( !$object || $object eq q{} ) {
		Carp::confess 'Error : Object should not be null';
	}

	my $payload = JSON->new->allow_blessed->convert_blessed->encode($object);
	$payload = '{"' . $objecttype . '" :' . $payload . '}';

	my $url = "$scheme://$session->{ns}/nitro/v1/config/" . $objecttype;
	if ( $operation && $operation ne 'add' ) {
		$url = $url . '?action=' . $operation;
	}
	my $contenttype = 'application/vnd.com.citrix.netscaler.' . $objecttype . '+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( POST => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->header( 'Set-Cookie',   'NITRO_AUTH_TOKEN=' . $session->{sessionid} );
	$request->content($payload);
	$nitro_useragent->ssl_opts( verify_hostname => 0 );

	my $response = $nitro_useragent->request($request);
	if ( HTTP::Status::is_error( $response->code ) ) {
		$response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
	}
	else {
		$response->{errorcode} = 0;
		$response->{message}   = 'Done';
	}
	return $response;
} ## end sub post

# GET method : Used to get the details of configuration
# Arguments : session, objecttype, objectname, options
sub get {

	my ( $session, $objecttype, $objectname, $options ) = @_;

	if ( !$session || $session eq q{} ) {
		Carp::confess 'Error : Session should not be null';
	}
	if ( !( $session->{sessionid} ) ) {
		Carp::confess 'Error : Not logged in';
	}
	if ( !$objecttype || $objecttype eq q{} ) {
		Carp::confess 'Error : Object type should not be null';
	}

	my $url = "$scheme://$session->{ns}/nitro/v1/config/" . $objecttype;
	if ( $objectname && $objectname ne q{} ) {
		$url = $url . q{/} . uri_escape( uri_escape($objectname) );
	}
	if ( $options && $options ne q{} ) {
		$url = $url . q{?} . $options;
	}
	my $contenttype = 'application/vnd.com.citrix.netscaler.' . $objecttype . '+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( GET => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->header( 'Set-Cookie',   'NITRO_AUTH_TOKEN=' . $session->{sessionid} );
	$nitro_useragent->ssl_opts( verify_hostname => 0 );

	my $response = $nitro_useragent->request($request);
	$response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
	return $response;
} ## end sub get

# Get stats method : Used to get the stats of the configuration
# Arguments : session, objecttype, objectname
sub get_stats {

	my ( $session, $objecttype, $objectname ) = @_;

	if ( !$session || $session eq q{} ) {
		Carp::confess 'Error : Session should not be null';
	}
	if ( !( $session->{sessionid} ) ) {
		Carp::confess 'Error : Not logged in';
	}
	if ( !$objecttype || $objecttype eq q{} ) {
		Carp::confess 'Error : Object type should not be null';
	}

	my $url = "$scheme://$session->{ns}/nitro/v1/stat/" . $objecttype;
	if ( $objectname && $objectname ne q{} ) {
		$url = $url . q{/} . uri_escape( uri_escape($objectname) );
	}
	my $contenttype = 'application/vnd.com.citrix.netscaler.' . $objecttype . '+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( GET => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->header( 'Set-Cookie',   'NITRO_AUTH_TOKEN=' . $session->{sessionid} );
	$nitro_useragent->ssl_opts( verify_hostname => 0 );

	my $response = $nitro_useragent->request($request);
	$response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
	return $response;
} ## end sub get_stats

# PUT method : Used to update the already existing configuration
# Arguments : session, objecttype, object, objectname
sub put {
	my ( $session, $objecttype, $object, $objectname ) = @_;

	if ( !$session || $session eq q{} ) {
		Carp::confess 'Error : Session should not be null';
	}
	if ( !( $session->{sessionid} ) ) {
		Carp::confess 'Error : Not logged in';
	}
	if ( !$objecttype || $objecttype eq q{} ) {
		Carp::confess 'Error : Object type should not be null';
	}
	if ( !$object || $object eq q{} ) {
		Carp::confess 'Error : Object should not be null';
	}

	my $payload = JSON->new->allow_blessed->convert_blessed->encode($object);
	$payload = '{"' . $objecttype . '" :' . $payload . '}';

	my $url = "$scheme://$session->{ns}/nitro/v1/config/" . $objecttype . q{/} . uri_escape( uri_escape($objectname) );
	my $contenttype = 'application/vnd.com.citrix.netscaler.' . $objecttype . '+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( PUT => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->header( 'Set-Cookie',   'NITRO_AUTH_TOKEN=' . $session->{sessionid} );
	$request->content($payload);
	$nitro_useragent->ssl_opts( verify_hostname => 0 );

	my $response = $nitro_useragent->request($request);
	if ( HTTP::Status::is_error( $response->code ) ) {
		$response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
	}
	else {
		$response->{errorcode} = 0;
		$response->{message}   = 'Done';
	}
	return $response;
} ## end sub put

# DELETE method : Used to delete, unbind the existing configuration
# Arguments : session, objecttype, object
sub del {

	my ( $session, $objecttype, $object ) = @_;

	if ( !$session || $session eq q{} ) {
		Carp::confess 'Error : Session should not be null';
	}
	if ( !( $session->{sessionid} ) ) {
		Carp::confess 'Error : Not logged in';
	}
	if ( !$objecttype || $objecttype eq q{} ) {
		Carp::confess 'Error : Object type should not be null';
	}
	if ( !$object || $object eq q{} ) {
		Carp::confess 'Error : Object should not be null';
	}

	my $url = "$scheme://$session->{ns}/nitro/v1/config/$objecttype";
	if ( ref($object) eq 'HASH' ) {
		$url = $url . '?args=';
		while ( ( my $key, my $value ) = each %{$object} ) {
			$url = $url . $key . q{:} . uri_escape( uri_escape($value) ) . q{,};
		}
		$url =~ s/,$//sm;
	}
	else {
		$url = $url . q{/} . uri_escape( uri_escape($object) );
	}
	my $contenttype = 'application/vnd.com.citrix.netscaler.' . $objecttype . '+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( DELETE => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->header( 'Set-Cookie',   'NITRO_AUTH_TOKEN=' . $session->{sessionid} );
	$nitro_useragent->ssl_opts( verify_hostname => 0 );

	my $response = $nitro_useragent->request($request);
	if ( HTTP::Status::is_error( $response->code ) ) {
		$response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
	}
	else {
		$response->{errorcode} = 0;
		$response->{message}   = 'Done';
	}
	return $response;
} ## end sub del

# Logout method : Used to logout the netscaler
# Arguments : session
sub logout {

	my ($session) = @_;

	if ( !$session || $session eq q{} ) {
		Carp::confess 'Error : Session should not be null';
	}
	if ( !( $session->{sessionid} ) ) {
		Carp::confess 'Error : Not logged in';
	}

	my $payload = '{"logout" :{}}';

	my $url         = "$scheme://$session->{ns}/nitro/v1/config/logout";
	my $contenttype = 'application/vnd.com.citrix.netscaler.logout+json';

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( POST => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->header( 'Set-Cookie',   'NITRO_AUTH_TOKEN=' . $session->{sessionid} );
	$request->content($payload);
	$nitro_useragent->ssl_opts( verify_hostname => 0 );

	my $response = $nitro_useragent->request($request);
	if ( HTTP::Status::is_error( $response->code ) ) {
		$response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
	}
	else {
		$response->{errorcode} = 0;
		$response->{message}   = 'Done';
	}
	return $response;
} ## end sub logout

1;
