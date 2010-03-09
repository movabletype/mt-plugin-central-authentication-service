#!/usr/bin/perl
############################################################################
# Copyright © 2008-2010 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# version 2 for more details. You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.
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
