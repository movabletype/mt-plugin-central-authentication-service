#!/usr/bin/perl
# $Id$
use strict;
use warnings;
use lib 'lib';
use lib 'extlib';
use lib 'plugins/MT_CAS/lib';
use Test::More tests => 3;
use_ok 'MT_CAS::Util';

use MT::Util qw( encode_url );
my $auth_login_url = 'https://localhost:8443/cas';
my $service_url = 'http://example.com/?__mode=view&_type=entry&blog_id=1';

my $login_url = MT_CAS::Util->get_server_login_url(
    $auth_login_url,
    $service_url,
);

is($login_url, "$auth_login_url/login?service=" . encode_url($service_url), 'get_server_login_url');

my $logout_url = MT_CAS::Util->get_server_logout_url(
    $auth_login_url,
    $service_url,
);

is($logout_url, "$auth_login_url/logout?url=" . encode_url($service_url), 'get_server_logout_url');

1;
