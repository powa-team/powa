package Powa::User;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Digest::SHA qw(sha256_hex);


sub login {
    my $self = shift;
    my $username;
    my $password;
    my $server;

    # Do not go through the login process if the user is already in
    if ( $self->perm->is_authd ) {
        return $self->redirect_to('site_home');
    }

    my $method = $self->req->method;
    if ( $method =~ m/^POST$/i ) {

        # process the input data
        my $form_data = $self->req->params->to_hash;

        # Check input values
        my $e = 0;

        $server = $form_data->{server};
        $username = $form_data->{username};
        $password = $form_data->{password};

        if ( $server =~ m/^\s*$/ ) {
            $self->msg->error("Empty server.");
            $e = 1;
        }

        my $need_auth = $self->server_needs_auth($server);

        if ( $need_auth ) {
            if ( $username =~ m/^\s*$/ ) {
                $self->msg->error("Empty username.");
                $e = 1;
            }

            if ( $password =~ m/^\s*$/ ) {
                $self->msg->error("Empty password.");
                $e = 1;
            }
        } else {
            $username = $self->get_server_username($server);
            $password = $self->get_server_password($server);
        }

        $self->stash( 'subtitle' => 'login' );
        return $self->render() if ($e);

        my $dbh =
            $self->database( $username, $password, $server );

        if ($dbh) {
            $self->perm->update_info(
                username => $username,
                password => $password,
                server => $server,
                stay_connected => $form_data->{stay_connected}
            );
            $dbh->disconnect();

            if ( (defined $self->flash('saved_route')) && (defined $self->flash('stack')) ){
                return $self->redirect_to($self->flash('saved_route'), $self->flash('stack'));
            } else {
                return $self->redirect_to('site_home');
            }
        }
        else {
            $self->msg->error("Wrong username or password.");
            return $self->render();
        }
    }

    $self->flash('saved_route'=> $self->flash('saved_route'));
    $self->flash('stack'=> $self->flash('stack'));
    $self->stash( 'subtitle' => 'login' );
    $self->render();
}

sub logout {
    my $self = shift;

    if ( $self->perm->is_authd ) {
        $self->msg->info("You have logged out.");
    }
    $self->perm->remove_info;
    $self->redirect_to('site_home');
}

sub check_auth {
    my $self = shift;

    # Make the dispatch continue when the user id is found in the session
    if ( $self->perm->is_authd ) {
        return 1;
    }
    $self->flash('saved_route' => $self->current_route);
    $self->flash('stack' => $self->match->stack->[1]);
    $self->redirect_to('user_login');
    return 0;
}

1;
