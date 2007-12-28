package Archer::Plugin;
use strict;
use warnings;
use Archer;
use Template;
use String::CamelCase qw//;
use Path::Class;
use Carp;

sub new {
    my ( $class, $args ) = @_;
    bless { %$args }, $class;
}

sub log {
    my $self = shift;
    Archer->context->log( @_ );
}

sub templatize {
    my ( $self, $cmd ) = @_;

    my $vars = {
        config    => $self->{ config },
        project   => $self->{ project },
        l_project => $self->l_project,
        work_dir  => Archer->context->{ config }->{ global }->{ work_dir },
        dest_dir  => Archer->context->{ config }->{ global }->{ dest_dir },
        server    => $self->{ server },
        user      => $ENV{ USER },
    };

    my $tt = Template->new;
    $tt->process( \$cmd, $vars, \my $out )
        or $self->log( 'error' => 'Template Error: ' . $tt->error );

    $out;
}

sub detach {
    my ( $self, $msg ) = @_;

    croak "$msg\n";
}

# FIXME: so bad...following method...
sub l_project {
    my ( $self, ) = @_;

    my $work_dir = Archer->context->{ config }->{ global }->{ work_dir };

    my $lc = String::CamelCase::decamelize( $self->{ project } );
    if ( -e file( $work_dir, $self->{ project }, $lc )->stringify ) {
        return $lc;
    }
    else {
        return lc Archer->context->{ project };
    }
}

sub check_recipe {
    my ( $self, $recipe_name, $altern_path ) = @_;
    my ( $f, $path );

    $f = File::Util->new;
    $path = File::Spec->catfile( $FindBin::Bin, 'assets', 'recipe',
        $recipe_name );

    # check first in assets
    if ( $f->existent( $path ) ) {
        return $f->load_file( $path );
    }

    # if there is another path for recipe in the config, check this one
    $path = File::Spec->catfile( $altern_path, $recipe_name );
    if ( $f->existent( $path ) ) {
        return $f->load_file( $path );
    }

    # fail
    return;
}

1;
