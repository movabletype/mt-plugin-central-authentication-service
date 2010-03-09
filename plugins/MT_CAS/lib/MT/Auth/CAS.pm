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
package MT::Auth::CAS;

use strict;
use warnings;
use base qw( MT::Auth::MT );
use MT_CAS::Util;

sub SURL_COOKIE_NAME { 'SourceURL' }
sub can_recover_password { 0 }
sub is_profile_needed { 1 }
sub password_exists { 0 }
sub can_logout { 1 }

sub delegate_auth {
    my $class = shift;
    my $app = MT->instance;
    return 1 if 'logout' eq $app->mode;
    return 0;
}

sub sanity_check {
    my $class = shift;
    my ($app) = @_;
    # $class->SUPER::sanity_check(@_);
    return 0;
}

sub fetch_credentials {
    my $class = shift;
    my ( $ctx ) = @_;
    my $app = $ctx->{app} || MT->instance();
    my $service_url = $ctx->{service_url} || _service_url( $app );

    $ctx = $class->session_credentials(@_);
    if (!defined $ctx) {
        # FIXME: session_js should not be the only mode
        return undef if 'session_js' eq $app->mode;
        if ( my $st = $app->param('ticket') ) {
            $ctx = { app => $app, session_ticket => $st, service_url => $service_url };
        }
        else {
            my $login_url = MT_CAS::Util->get_server_login_url(
                $app->config->AuthLoginURL,
                $service_url
            );
            $app->bake_cookie(
                -name  => SURL_COOKIE_NAME(),
                -value => $service_url,
                -path  => '/',
            );
            $app->redirect($login_url);
            return undef;
        }
    }
    $ctx;
}

sub validate_credentials {
    my $class = shift;
    my ( $ctx, %opt ) = @_;

    my $app = $ctx->{app};
    my $st  = delete $ctx->{session_ticket};
    my $session_id = $ctx->{session_id};
    my $service_url = $ctx->{service_url} || _service_url( $app );
    unless ( $st || $session_id ) {
        my $q = $app->param;
        $st = $q->param('ticket');
        return MT::Auth::REDIRECT_NEEDED() unless $st;
    }

    if ( $st ) {
        my $service_url = _service_url( $app );
        my $validation_url = $app->config->MT_CAS_ValidationURL;
        $validation_url ||= $app->config->AuthLoginURL;
        my $user = MT_CAS::Util->validate_st(
            $validation_url,
            $service_url,
            $st
        );
        unless ( $user ) {
            my $login_url = MT_CAS::Util->get_server_login_url(
                $app->config->AuthLoginURL,
                $service_url
            );
            $app->bake_cookie(
                -name  => SURL_COOKIE_NAME(),
                -value => $service_url,
                -path  => '/',
            );
            $app->redirect($login_url);
            return MT::Auth::REDIRECT_NEEDED();
        }
        $ctx->{username} = $user;
    }

    my $result = MT::Auth::UNKNOWN();

    # load author from db
    my $author_class = $app->model('author');
    my $author = $author_class->load({ name => $ctx->{username}, type => $author_class->AUTHOR(), auth_type => [ 'MT', $app->config->AuthenticationModule ] });

    if ($author) {
        # author status validation
        if ($author->is_active) {
            $result = MT::Auth::SUCCESS();
            $app->user($author);

            $result = MT::Auth::NEW_LOGIN()
                unless $app->session_user($author, $ctx->{session_id}, %opt);
        } else {
            $result = MT::Auth::INACTIVE();
        }
    } else {
        if ($app->config->ExternalUserManagement) {
            $result = MT::Auth::NEW_USER();
        }
    }

    return $result;
}

sub invalidate_credentials {
    my $class = shift;
    my ( $ctx ) = @_;
    my $app = $ctx->{app} || MT->instance();
    my $result = $class->SUPER::invalidate_credentials(@_);

    # FIXME: handle_sign_in should not be the only mode
    return $result if ( 'handle_sign_in' eq $app->mode ) && $app->param('logout');

    # my $service_url = $ctx->{service_url} || _service_url( $app );
    # my $logout_url = MT_CAS::Util->get_server_logout_url(
    #     $app->config->AuthLoginURL,
    #     $service_url
    # );
    # $app->bake_cookie(
    #     -name  => SURL_COOKIE_NAME(),
    #     -value => $service_url,
    #     -path  => '/',
    # );
    #
    #     my $ua = MT->new_ua( { timeout => 10 } );
    #     return $app->redirect($logout_url) unless $ua;
    #
    #     my $req = new HTTP::Request( GET => $logout_url );
    #     my $resp = $ua->request($req);
    #     my $result = $resp->is_success ? $resp->content : $resp->status_line;
    #
    # use MT::Log;
    # my $log = MT::Log->new;
    # $log->message("Logout $logout_url (".$resp->is_success." ? ".$resp->content." : ".$resp->status_line.")");
    # $log->save;

    return undef;
}

sub new_user {
    my $class = shift;
    my ( $app, $user ) = @_;
    $user->password('(none)');
    my $tag_delim = $app->config->DefaultUserTagDelimiter;
    $user->entry_prefs('tag_delim' => $tag_delim);
    my $result = $user->save;
    if ($result) {
        $user->add_default_roles;
    }
    $result;
}

sub login_form {
    my $class = shift;
    my ( $app ) = @_;
    return q();
}

sub _service_url {
    my ( $app ) = @_;
    my %args = $app->param_hash;
    delete $args{__mode};
    delete $args{ticket};
    my %params = 'logout' eq $app->mode
      ? ()
      : ( mode => $app->mode, %args ? ( args => \%args ) : () );
    return $app->base . $app->uri( %params );
}

1;
__END__
