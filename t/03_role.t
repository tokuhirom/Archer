use strict;
use warnings;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

use Archer;
use t::Util;

my @app = qw(127.0.0.1 127.0.0.2);
my @db  = qw(127.0.0.3 127.0.0.4);
my @all = (@app, @db);

subtest 'no role' => sub {
    init();
    capture {
        Archer->new({
            project      => 'YourProj',
            dry_run_fg   => 0,
            parallel_num => 0,
            skips        => {},
            config_yaml  => 't/03_role.yaml',
            argv_str     => '',
            shell        => 0,
            write_config => 0,
        })->run;
    };

    $OUT =~ s/\n$//msg;
    $OUT =~ s/^\n//msg;
    is_valid_output($OUT, [map{"$_:hostname"}@all]);
    is $t::Plugin::Dummy::RUN_COUNTER, 4;
};

subtest 'role app' => sub {
    init();
    capture {
        Archer->new({
            project      => 'YourProj',
            dry_run_fg   => 0,
            parallel_num => 0,
            skips        => {},
            config_yaml  => 't/03_role.yaml',
            argv_str     => '',
            shell        => 0,
            write_config => 0,
            role         => 'app',
        })->run;
    };

    $OUT =~ s/\n$//msg;
    $OUT =~ s/^\n//msg;
    is_valid_output($OUT, [map{"$_:hostname"}@app]);
    is $t::Plugin::Dummy::RUN_COUNTER, 2;
};

done_testing;
