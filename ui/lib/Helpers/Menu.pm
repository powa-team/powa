package Helpers::Menu;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Data::Dumper;

sub register {
    my ( $self, $app ) = @_;

    $app->helper(
        user_menu => sub {
            my $self = shift;
            my $html = '';
            my $dbh;
            my $sql;
            my @dbs;

            if ( $self->perm->is_authd() ) {
                $self->stash(
                    menu_username => $self->session('user_username') );

                $dbh = $self->database();
                $sql = $dbh->prepare("SELECT DISTINCT dbname FROM public.powa_statements ORDER BY dbname");
                $sql->execute();

                while ( my $dbname = $sql->fetchrow() ) {
                    push @dbs, $dbname;
                }
                $sql->finish();
                $dbh->disconnect();

                $self->stash(
                    dbs        => \@dbs
                );

                if ( $Mojolicious::VERSION >= 5.00 ) {
                    $html = $self->render_to_string( template => 'helpers/user_menu' );
                } else {
                    $html = $self->render(
                        template => 'helpers/user_menu',
                        partial  => 1 );
                }
            }

            return b($html);
        } );

    $app->helper(
        get_servers => sub {
            my $self = shift;
            my $servers;
            foreach my $name (sort keys %{$self->config->{'servers'}} ) {
                push @{$servers}, $name;
            }

            return $servers;
        } );
}

1;
