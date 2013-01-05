use strict;
use warnings;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

use Archer;
use FindBin;


my $ERR;
my $OUT;
sub init {
    $FindBin::Bin .= "/.." if $FindBin::Bin !~ m!/\.\.!;
    $ERR = undef;
    $OUT = undef;
    $t::Plugin::Dummy::RUN_COUNTER = 0;
}

sub capture(&) {
    my $code = shift;

    tie *STDERR, 'IO::Scalar', \$ERR;
    tie *STDOUT, 'IO::Scalar', \$OUT;

        $code->();

    untie *STDERR;
    untie *STDOUT;
}

subtest 'normal' => sub {
    init();
    capture {
        Archer->new(
            {
                project      => 'YourProj',
                dry_run_fg   => 0,
                parallel_num => 0,
                skips        => {},
                config_yaml  => 't/05_ready.yaml',
                argv_str     => '',
                shell        => 0,
                write_config => 0,
            }
        )->run;
    };
    is $t::Plugin::Dummy::RUN_COUNTER, 4;
};

subtest 'only' => sub {
    init();
    capture {
        Archer->new(
            {
                project      => 'YourProj',
                dry_run_fg   => 0,
                parallel_num => 0,
                skips        => {},
                only         => 'dummy',
                config_yaml  => 't/05_ready.yaml',
                argv_str     => '',
                shell        => 0,
                write_config => 0,
            }
        )->run;
    };
    is $t::Plugin::Dummy::RUN_COUNTER, 2;
};

done_testing;
