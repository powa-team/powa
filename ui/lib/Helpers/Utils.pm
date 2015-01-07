package Helpers::Utils;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';

sub register {
    my ( $self, $app ) = @_;

    $app->helper(
        server_needs_auth => sub {
            my $self = shift;
            my $server = shift;

            return 0 if ( defined($self->config->{'servers'}->{$server}->{'username'})
              and defined($self->config->{'servers'}->{$server}->{'password'})
            );

            return 1;
        } );

    $app->helper(
        get_server_username => sub {
            my $self = shift;
            my $server = shift;
            return $self->config->{'servers'}->{$server}->{'username'};
        } );

    $app->helper(
        get_server_password => sub {
            my $self = shift;
            my $server = shift;
            return $self->config->{'servers'}->{$server}->{'password'};
        } );
}

1;
