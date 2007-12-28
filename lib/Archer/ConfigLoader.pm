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

    my $schema_file = file( $FindBin::Bin, 'assets', 'kwalify', 'schema.yaml' );

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

    my $res = validate( YAML::LoadFile($schema_file), $config );
    $context->log( error => $res ) unless $res == 1;

    return $config;
}

1;
