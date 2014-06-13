package Powa::Modules;

use Mojo::Base 'Mojolicious::Plugin';
use File::Spec::Functions qw(splitdir catdir);

sub register {
    my ( $self, $app, $list ) = @_;

    #
    foreach my $m ( @{$list} ) {

        # Add the lib sub dir to @INC
        my @mod_home = ( splitdir( $app->home ), 'modules' );
        push( @INC, catdir( @mod_home, $m, 'lib' ) );

        # Register the module as plugin, the register method holds routes
        $app->plugin( $m, home => catdir( @mod_home, $m ) );

        # Add the template path
        push @{ $app->renderer->paths }, catdir( @mod_home, $m, 'templates' );

        # Add the public path
        push @{ $app->static->paths }, catdir( @mod_home, $m, 'public' );
    }

    return;
}

1;

