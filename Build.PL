use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Archer',
    license             => 'perl',
    dist_author         => 'Tokuhiro Matsuno <tokuhiro __at__ mobilefactory.jp>',
    dist_version_from   => 'lib/Archer.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Archer-*' ],
);

$builder->create_build_script();
