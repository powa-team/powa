package Helpers::Permissions;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper;

has target => sub { };

sub register {
    my ( $self, $app ) = @_;

    $app->helper(
        perm => sub {
            my $ctrl = shift;
            $self->target($ctrl);
            return $self;
        } );
}

sub update_info {
    my $self = shift;
    my $data = ref $_[0] ? $_[0] : {@_};

    # Does the cookie expires ?
    if ( defined $data->{'stay_connected'} ){
        $self->target->session(expiration => 0);
    } else {
        # Default expiration : 1 hour
        $self->target->session(expiration => 3600);
    }

    foreach my $info (qw/username password/) {
        if ( exists $data->{$info} ) {
            $self->target->session( 'user_' . $info => $data->{$info} );
        }
    }

    return;
}

sub remove_info {
    my $self = shift;

    map { delete $self->target->session->{$_} }
        qw(user_username user_password);
}

sub is_authd {
    my $self = shift;

    if ( $self->target->session('user_username') ) {
        return 1;
    }

    return 0;
}

1;
