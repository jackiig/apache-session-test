package MasonX::MyApp;

use strict;
use HTML::Mason::ApacheHandler ( args_method => 'mod_perl' );
use DBI;
use Apache::DBI;

# $DBH = DBI->connect($SCHEMA, $CONF->{database}->{user}, $CONF->{database}->{pass});
my $DBH = DBI->connect('DBI:mysql:database=polmaker;host=mysql;port=3306',
  'root', 'abc123') or die("Unable to connect to database.");

my $ah = HTML::Mason::ApacheHandler->new (
	comp_root					=>	'/usr/src/app/htdocs/',
	data_dir					=>	'/tmp/mason_data_dir/',
	args_method					=>	"mod_perl",
	request_class				=>	'MasonX::Request::WithApacheSession',
	session_args_param   		=>	'session_id',
	# session_class        		=>	'Apache::Session::File',
	# session_directory => '/tmp',
	# session_lock_directory => '/tmp',
	# session_lock				=>	'File',
	session_class        		=>	'Apache::Session::MySQL',
	session_lock				=>	'MySQL',
	session_handle				=>	$DBH,
	session_lock_handle			=>	$DBH,
	session_use_cookie   		=>	0,
	session_cookie_domain		=>	'localhost',
	session_cookie_expires		=>	"session",
	session_allow_invalid_id	=>	0,
	error_mode					=>	'fatal',
	);



sub handler {
   my $r = shift;  # Apache request object;
   return $ah->handle_request($r);
}
