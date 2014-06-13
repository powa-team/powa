package Helpers::Database;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Plugin';

use Carp;
use DBI;

has conninfo => sub { [] };

sub register {
    my ( $self, $app, $config ) = @_;

    # data source name
    my $dsn = $config->{dsn};

    # Check if we have a split dsn with fallback on defaults
    unless ($dsn) {
        my $database = $config->{database} || lc $ENV{MOJO_APP};
        my $dsn = "dbi:Pg:database=" . $database;
        $dsn .= ';host=' . $config->{host} if $config->{host};
        $dsn .= ';port=' . $config->{port} if $config->{port};
    }

    # Save connection parameters
    $self->conninfo($dsn);

    # Register a helper that give the database handle
    $app->helper(
        database => sub {
            my ( $ctrl, $username, $password ) = @_;
            if ( ( !defined($username) ) or ( !defined($password) ) ) {
                $username = $ctrl->session('user_username');
                $password = $ctrl->session('user_password');
            }

            # Return a new database connection handle
            my $dbh =
                DBI->connect( $self->conninfo, $username, $password,
                $config->{options} || {} );
            return $dbh;
        } );

    return;
}

1;
