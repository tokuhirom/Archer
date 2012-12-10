package Archer::ConfigLoader;
use strict;
use warnings;
use Storable;
use Carp;
use Kwalify qw(validate);
use Path::Class;
use FindBin;
use File::ShareDir qw/dist_dir/;

my $yaml_class;
if (eval "require YAML::Syck; 1;") { ## no critic.
    $yaml_class = "YAML::Syck";
} else {
    require YAML;
    $yaml_class = "YAML";
}

sub new { bless {}, shift }

sub load {
    my ( $self, $stuff, $context ) = @_;

    $context->log('debug' => "yaml class: $yaml_class");

    # load
    my $config;
    if (   ( !ref($stuff) && $stuff eq '-' )
        || ( -e $stuff && -r _ ) )
    {
        $config = $yaml_class->can('LoadFile')->($stuff);
        $context->{config_path} = $stuff if $context;
    }
    elsif ( ref($stuff) && ref($stuff) eq 'SCALAR' ) {
        $config = $yaml_class->can('Load')->( ${$stuff} );
    }
    elsif ( ref($stuff) && ref($stuff) eq 'HASH' ) {
        $config = Storable::dclone($stuff);
    }
    else {
        croak "Archer::ConfigLoader->load: $stuff: $!";
    }

    # setup default value
    $config->{global}->{assets_path} ||= sub {
        my $dir = file( $FindBin::Bin, 'assets');
        return $dir->stringify if -d $dir;

        dist_dir('Archer');
    }->();
    $context->log('debug' => "assets path: $config->{global}->{assets_path}");

    # verify
    my $schema_file = file( $config->{global}->{assets_path}, 'kwalify', 'schema.yaml' );
    my $res = validate( $yaml_class->can('LoadFile')->($schema_file), $config );
    $context->log( error => $res ) unless $res == 1;

    return $config;
}

1;
