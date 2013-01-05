use strict;
use warnings;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

use Archer;
use t::Util;

subtest '01_simple' => sub {
    init;

    capture {
        Archer->new({
            project      => 'YourProj',
            dry_run_fg   => 0,
            parallel_num => 0,
            skips        => {},
            config_yaml  => 't/01_simple.yaml',
            argv_str     => '',
            shell        => 0,
            write_config => 0,
        })->run;
    };

    is $t::Plugin::Dummy::RUN_COUNTER, 1;
};

done_testing;
