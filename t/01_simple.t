use strict;
use warnings;
use Test::More tests => 1;
use Archer;
use IO::Scalar;
use FindBin;

main();
exit;

sub init {
    $FindBin::Bin .= "/..";
    $t::Plugin::Dummy::RUN_COUNTER = 0;
}

sub capture(&) {
    my $code = shift;

    tie *STDERR, 'IO::Scalar', \my $err;
    tie *STDOUT, 'IO::Scalar', \my $out;

        $code->();

    untie *STDERR;
    untie *STDOUT;
}

sub main {
    init();

    capture {
        Archer->new(
            {
                project      => 'YourProj',
                dry_run_fg   => 0,
                parallel_num => 0,
                skips        => {},
                config_yaml  => 't/01_simple.yaml',
                argv_str     => '',
                shell        => 0,
                write_config => 0,
            }
        )->run;
    };

    is $t::Plugin::Dummy::RUN_COUNTER, 1;
}

