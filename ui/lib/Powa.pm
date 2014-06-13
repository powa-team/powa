package Powa;
use Mojo::Base 'Mojolicious';

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

# This method will run once at server start
sub startup {
    my $self = shift;

    # register Helpers plugins namespace
    $self->plugins->namespaces(
        [ "Helpers", "Powa", @{ $self->plugins->namespaces } ] );

    # setup charset
    $self->plugin( charset => { charset => 'utf8' } );

    # load configuration
    my $config_file = $self->home . '/powa.conf';
    my $config = $self->plugin( 'JSONConfig' => { file => $config_file } );

    # setup secret passphrase
    if ( $config->{secrets} ) {
        $self->secrets($config->{'secrets'});
    }

    # startup database connection
    $self->plugin( 'database', $config->{database} || {} );

    # Load HTML Messaging plugin
    $self->plugin('messages');

    # Load others plugins
    $self->plugin('menu');
    $self->plugin('permissions');

    # CGI pretty URLs
    if ( $config->{rewrite} ) {
        $self->hook(
            before_dispatch => sub {
                my $self = shift;
                $self->req->url->base(
                    Mojo::URL->new( $config->{base_url} ) );
            } );
    }

    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    $self->plugin( 'modules', $config->{modules} || [] );

    # Routes
    my $r      = $self->routes;
    my $r_auth = $r->bridge->to('user#check_auth');

    # User stuff
    $r->route('/login')->to('user#login')->name('user_login');
    $r_auth->route('/logout')->to('user#logout')->name('user_logout');

    # Powa stuff
    $r_auth->route('/')->to('statement#listdb')->name('site_home');
    $r_auth->route('/statement/:dbname')->to('statement#showdb')->name('statement_showdb');
    $r_auth->route('/statement/:dbname/:md5query')->to('statement#showdbquery')->name('statement_showdbquery');
    # Graph data
    $r_auth->post('/data/statement/dbdata')->to('statement#dbdata')->name('statement_dbdata');
    $r_auth->post('/data/statement/dbdata_agg')->to('statement#dbdata_agg')->name('statement_dbdata_agg');
    $r_auth->post('/data/statement/querydata')->to('statement#querydata')->name('statement_querydata');
}

1;
