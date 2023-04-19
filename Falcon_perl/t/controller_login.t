use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Falcon_perl';
use Falcon_perl::Controller::login;

ok( request('/login')->is_success, 'Request should succeed' );
done_testing();
