package MT::Auth::CAS;

use strict;
use warnings;
use base qw( MT::Auth::MT );
use MT::Util qw( encode_url );
use AuthCAS;

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
    $class->SUPER::sanity_check(@_);
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
            my $cas = new AuthCAS(
                casUrl => $app->config->AuthLoginURL,
            );
            my $login_url = $cas->getServerLoginURL( encode_url( $service_url ) );
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
        my $cas = new AuthCAS(
            casUrl => $app->config->AuthLoginURL,
        );
        my $service_url = _service_url( $app );
        my $user = $cas->validateST( encode_url($service_url), $st);
        unless ( $user ) {
            my $login_url = $cas->getServerLoginURL( encode_url( $service_url ) );
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
    my $service_url = $ctx->{service_url} || _service_url( $app );
    my $result = $class->SUPER::invalidate_credentials(@_); 
    # FIXME: handle_sign_in should not be the only mode
    return $result if ( 'handle_sign_in' eq $app->mode ) && $app->param('logout');
    my $cas = new AuthCAS(
        casUrl => $app->config->AuthLoginURL,
    );
    my $login_url = $cas->getServerLogoutURL( encode_url( $service_url ) );
    $app->redirect($login_url);
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
