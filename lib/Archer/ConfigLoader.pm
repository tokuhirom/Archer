package Archer::ConfigLoader;
use strict;
use warnings;
use YAML;
use Storable;
use Carp;
use Kwalify qw(validate); 
use Path::Class;
use FindBin;

sub new { bless {}, shift }

sub load {
    my ( $self, $stuff, $context ) = @_;

    # load
    my $config;
    if (   ( !ref($stuff) && $stuff eq '-' )
        || ( -e $stuff && -r _ ) )
    {
        $config = YAML::LoadFile($stuff);
        $context->{config_path} = $stuff if $context;
    }
    elsif ( ref($stuff) && ref($stuff) eq 'SCALAR' ) {
        $config = YAML::Load( ${$stuff} );
    }
    elsif ( ref($stuff) && ref($stuff) eq 'HASH' ) {
        $config = Storable::dclone($stuff);
    }
    else {
        croak "Archer::ConfigLoader->load: $stuff: $!";
    }

    # setup default value
    $config->{global}->{assets_path} ||= file( $FindBin::Bin, 'assets')->stringify;
    $context->log('debug' => "assets path: $config->{global}->{assets_path}");

    # verify
    my $schema_file = file( $config->{global}->{assets_path}, 'kwalify', 'schema.yaml' );
    my $res = validate( YAML::LoadFile($schema_file), $config );
    $context->log( error => $res ) unless $res == 1;

    return $config;
}

1;
