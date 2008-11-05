package MT::Auth::CAS;

use strict;
use warnings;
use base qw( MT::Auth::MT );
use AuthCAS;

sub can_recover_password { 0 }
sub is_profile_needed { 1 }
sub password_exists { 0 }
sub delegate_auth { 0 }
sub can_logout { 1 }

sub sanity_check {
    my $class = shift;
    my ($app) = @_;
    $class->SUPER::sanity_check(@_);
}

sub fetch_credentials { 
    my $class = shift; 
    my ( $ctx ) = @_; 
    $ctx = $class->session_credentials(@_); 
    if (!defined $ctx) { 
        my $app = $ctx->{app} || MT->instance(); 
        if ( my $st = $app->param('ticket') ) {
            $ctx = { app => $app, session_ticket => $st };
        }
        else {
            my $cas = new AuthCAS(
                casUrl => $app->config->AuthLoginURL,
            );
            my $login_url = $cas->getServerLoginURL($app->base . $app->mt_uri);
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
    unless ( $st || $session_id ) {
        my $q = $app->param;
        $st = $q->param('ticket');
        return MT::Auth::REDIRECT_NEEDED() unless $st;
    }
    if ( $st ) {
        my $cas = new AuthCAS(
            casUrl => $app->config->AuthLoginURL,
        );
        my $user = $cas->validateST($app->base . $app->mt_uri, $st);
        unless ( $user ) {
            my $login_url = $cas->getServerLoginURL($app->base . $app->mt_uri);
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
    my $auth = shift; 
    my ( $ctx ) = @_; 
    $auth->SUPER::invalidate_credentials(@_); 
    my $app = $ctx->{app}; 
    my $cas = new AuthCAS(
        casUrl => $app->config->AuthLoginURL,
    );
    my $login_url = $cas->getServerLoginURL($app->base . $app->mt_uri);
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

1;
__END__
