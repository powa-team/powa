package Helpers::Database;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Plugin';

use Carp;
use DBI;

sub register {
    my ( $self, $app, $config ) = @_;

    # Register a helper that give the database handle
    # username, password and dbname are optionnal.
    # both username and password must be provided to be used.
    # if a dbname is provided, it'll overload the value configured
    # in powa.conf
    $app->helper(
        database => sub {
            my ( $ctrl, $username, $password, $server, $dbname ) = @_;
            my $dbh;
            my $sql;
            my $ok;
            if ( ( !defined($username) ) or ( !defined($password) ) or ( !defined($server) ) ) {
                $username = $ctrl->session('user_username');
                $password = $ctrl->session('user_password');
                $server = $ctrl->session('user_server');
            }

            # Return a new database connection handle
            $config->{database}->{options}->{AutoCommit} = 1;
            $config->{database}->{options}->{pg_enable_utf8} = 1;
            $dbh = DBI->connect(
                $self->conninfo($config->{servers}->{$server},$dbname),
                $username,
                $password,
                $config->{database}->{options} || {}
            );

            return 0 if (!$dbh);

            # Check if we are a super-user, only when connecting
            if ( ( not defined $config->{base_timestamp} ) and ( not defined $ctrl->session('user_username') ) ) {
                $sql = $dbh->prepare(qq{
                    SELECT (COUNT(*) = 1)::int
                    FROM pg_roles
                    WHERE rolname = ? AND rolsuper
                });

                $sql->execute( $username );
                $ok = $sql->fetchrow();
                $sql->finish();

                return 0 if not $ok;
            }
            return $dbh;
        } );

    return;
}

# Return a PG connection string. dbname can be overloaded.
sub conninfo {
    my ( $self, $dbconf, $dbname ) = @_;

    my $db = $dbconf->{dbname} || lc $ENV{MOJO_APP};
    $db = $dbname if defined $dbname;

    my $dsn = "dbi:Pg:";
    $dsn .= "database=" . $db;
    $dsn .= ";host="    . $dbconf->{host} if $dbconf->{host};
    $dsn .= ";port="    . $dbconf->{port} if $dbconf->{port};

    return $dsn;
}

1;
