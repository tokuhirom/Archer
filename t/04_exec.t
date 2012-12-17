use strict;
use warnings;
use utf8;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

use Archer;
use FindBin;

main();
done_testing;
exit;

my $OUT;
my $ERR;
sub init {
    $FindBin::Bin .= "/.." if $FindBin::Bin !~ m!/\.\.!;
    $OUT = undef;
    $ERR = undef;
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

sub main {
    my @app = qw(127.0.0.1 127.0.0.2);
    my @all = (@app);

    {
        init();
        local $@;
        eval {
            capture {
                Archer->new(
                    {
                        project      => 'YourProj',
                        dry_run_fg   => 0,
                        parallel_num => 0,
                        skips        => {},
                        config_yaml  => 't/04_exec.yaml',
                        argv_str     => '',
                        shell        => 0,
                        write_config => 0,
                    }
                )->run;
            };
        };
        like $@, qr/Deployment is cancelled/;
        like $ERR, qr/continue!!!/ms;
        like $ERR, qr/stop!!!/ms;
        is $t::Plugin::Dummy::RUN_COUNTER, 1;
    }

}

