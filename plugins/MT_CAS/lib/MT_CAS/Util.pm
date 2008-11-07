package MT_CAS::Util;

use strict;
use warnings;
use base qw( MT::ErrorHandler );
use MT::Util qw( encode_url encode_html );

sub get_server_login_url {
    my $class = shift;
    my ( $cas_url, $service_url ) = @_;
    return $cas_url . '/login' . '?service=' . encode_url( $service_url );
}

sub get_server_logout_url {
    my $class = shift;
    my ( $cas_url, $service_url ) = @_;
    return $cas_url . '/logout' . '?url=' . encode_url( $service_url );
}

sub validate_st {
    my $class = shift;
    my ( $cas_url, $service_url, $service_ticket ) = @_;
    my $plugin = MT->component('mt_cas');
    my $validate_url = $cas_url
        . '/serviceValidate'
        . '?service=' . encode_url( $service_url )
        . '&ticket=' . $service_ticket;

    my $ua = MT->new_ua;
    my $resp = $ua->get($validate_url);
    return $class->error( $resp->status_line ) unless $resp->is_success();

    require XML::Simple;
    my $xs = XML::Simple->new();
    my $xml = $xs->XMLin( $resp->content, ForceArray => 1 );

    if ( defined $xml->{'cas:authenticationFailure'} ) {
        return $class->error( $plugin->translate(
            "Failed to validate Service Ticket [_1]: [_2]",
            encode_html( $service_ticket ),
            encode_html( $xml->{'cas:authenticationFailure'}[0] )
        ) );
    }

    if ( my $user = 
      $xml->{'cas:authenticationSuccess'}[0]{'cas:user'}[0] )
    {
        return $user;
    }

    return $class->error( $plugin->translate(
        "Failed to validate Service Ticket [_1]: [_2]",
        encode_html( $service_ticket ),
        'Unknown error'
    ) );
}

1;
__END__
