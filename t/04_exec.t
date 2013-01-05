use strict;
use warnings;
use utf8;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

use Archer;
use t::Util;

my @app = qw(127.0.0.1 127.0.0.2);
my @all = (@app);

subtest 'exec validation' => sub {
    init;
    local $@;
    eval {
        capture {
            Archer->new({
                project      => 'YourProj',
                dry_run_fg   => 0,
                parallel_num => 0,
                skips        => {},
                config_yaml  => 't/04_exec.yaml',
                argv_str     => '',
                shell        => 0,
                write_config => 0,
            })->run;
        };
    };
    like $@, qr/Deployment is cancelled/;
    like $ERR, qr/continue!!!/ms;
    like $ERR, qr/stop!!!/ms;
    is $t::Plugin::Dummy::RUN_COUNTER, 1;
};

done_testing;
