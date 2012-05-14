use strict;
use warnings;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

plan tests => 4;

use Archer;
use FindBin;

main();
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
    my @db  = qw(127.0.0.3 127.0.0.4);
    my @all = (@app, @db);

    {
        init();
        capture {
            Archer->new(
                {
                    project      => 'YourProj',
                    dry_run_fg   => 0,
                    parallel_num => 0,
                    skips        => {},
                    config_yaml  => 't/03_role.yaml',
                    argv_str     => '',
                    shell        => 0,
                    write_config => 0,
                }
            )->run;
        };

        $OUT =~ s/\n$//msg;
        $OUT =~ s/^\n//msg;
        is($OUT, join("\n",map{"$_:hostname"}@all));
        is $t::Plugin::Dummy::RUN_COUNTER, 4;
    }

    {
        init();
        capture {
            Archer->new(
                {
                    project      => 'YourProj',
                    dry_run_fg   => 0,
                    parallel_num => 0,
                    skips        => {},
                    config_yaml  => 't/03_role.yaml',
                    argv_str     => '',
                    shell        => 0,
                    write_config => 0,
                    role         => 'app',
                }
            )->run;
        };

        $OUT =~ s/\n$//msg;
        $OUT =~ s/^\n//msg;
        is($OUT, join("\n",map{"$_:hostname"}@app));
        is $t::Plugin::Dummy::RUN_COUNTER, 2;
    }

}



