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
    return $cas_url . '/logout' . '?service=' . encode_url( $service_url );
    # Swap above line with below based on your specific CAS params
    # return $cas_url . '/logout' . '?url=' . encode_url( $service_url );
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
    die $plugin->translate(
      'HTTP(S) request to the validation service failed: [_1]',
      $resp->status_line )
        unless $resp->is_success();

    require XML::Simple;
    my $xs = XML::Simple->new();
    my $xml = $xs->XMLin( $resp->content, ForceArray => 1 );

    # response keys $resp->{_protocol}. " :: ".$resp->{_content} ." :: ".$resp->{_headers} ." :: ".$resp->{_msg};
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
