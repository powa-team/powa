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

            if ( $self->session('user_username') ) {
                $self->stash(
                    menu_username => $self->session('user_username') );

                $html = $self->render(
                    template => 'helpers/user_menu',
                    partial  => 1 );
            }

            return b($html);
        } );

    $app->helper(
        main_menu => sub {
            my $self = shift;
            my $html;
            my $dbh;
            my $sql;
            my @dbs;

            my $level = "guest";
            $level = "user"  if ( $self->session('user_username') );
            $level = "admin" if ( $self->session('user_admin') );

            if ( $level ne "guest" ) {
                $dbh = $self->database();
                $sql = $dbh->prepare("SELECT DISTINCT dbname FROM public.powa_statements ORDER BY dbname");
                $sql->execute();

                while ( my $dbname = $sql->fetchrow() ) {
                    push @dbs, $dbname;
                }
                $sql->finish();
                $dbh->disconnect();
            }

            $self->stash(
                user_level => $level,
                dbs        => \@dbs
            );
            $html =
                $self->render( template => 'helpers/main_menu', partial => 1 );

            return b($html);
        } );
}

1;
