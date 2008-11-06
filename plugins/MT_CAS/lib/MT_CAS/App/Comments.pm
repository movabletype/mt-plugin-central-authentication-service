package MT_CAS::App::Comments;

use strict;
use warnings;

use MT::Util qw( encode_url );
use AuthCAS;

sub cas_login {
    my $app = shift;
    my $q   = $app->param;

    my $cas = new AuthCAS(
        casUrl => $app->config->AuthLoginURL,
    );
    my $login_url = $cas->getServerLoginURL( encode_url( _service_url($app) ) );
    return $app->redirect($login_url); 
}

sub cas_do_login {
    my $app = shift;
    my $q   = $app->param;

    require MT::Auth;
    my $ctx = MT::Auth->fetch_credentials( { app => $app, service_url => _service_url($app) } );
    my $blog_id = $q->param('blog_id');
    my $result = MT::Auth->validate_credentials($ctx);

    my ( $message, $error );
    my $username = $ctx->{username};
    if (   ( MT::Auth::NEW_LOGIN() == $result )
        || ( MT::Auth::NEW_USER() == $result )
        || ( MT::Auth::SUCCESS() == $result ) )
    {
        my $commenter = $app->user;
        if ( $q->param('external_auth') && !$commenter ) {
            $app->param( 'name', $username );
            if ( MT::Auth::NEW_USER() == $result ) {
                $commenter = $app->_create_commenter_assign_role( $blog_id );
                return _redirect_to_target( $app ) unless $commenter;
            }
        }
        MT::Auth->new_login( $app, $commenter );
        if ( $app->_check_commenter_author( $commenter, $blog_id ) ) {
            $app->make_commenter_session($commenter);
            return _redirect_to_target( $app );
        }
        $error   = $app->translate("Permission denied.");
        $message = $app->translate(
            "Login failed: permission denied for user '[_1]'", $username );
    }
    elsif ( MT::Auth::INVALID_PASSWORD() == $result ) {
        $message = $app->translate(
            "Login failed: password was wrong for user '[_1]'", $username );
    }
    elsif ( MT::Auth::INACTIVE() == $result ) {
        $message
            = $app->translate( "Failed login attempt by disabled user '[_1]'",
            $username );
    }
    else {
        $message
            = $app->translate( "Failed login attempt by unknown user '[_1]'",
            $username );
    }
    $app->log(
        {   message  => $message,
            level    => MT::Log::WARNING(),
            category => 'login',
        }
    );
    $ctx->{app} ||= $app;
    MT::Auth->invalidate_credentials($ctx);
    return _redirect_to_target( $app );
}

sub _service_url {
    my ( $app ) = @_;
    my $q = $app->param;
    return $app->base . $app->app_uri(
        mode => 'cas_do_login',
        args => {
            key => 'CAS',
            blog_id => $q->param('blog_id'),
            static => $q->param('static') || $q->param('return_url'),
            $q->param('entry_id') ? ( entry_id => $q->param('entry_id') ) : ()
        }
    );
}

sub _redirect_to_target {
    my ( $app ) = @_;
    require MT::App::Comments;
    return MT::App::Comments::redirect_to_target( $app );
}

1;
__END__
