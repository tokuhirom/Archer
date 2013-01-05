# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;

eval "use IO::Scalar;";
plan skip_all => 'this test requires IO::Scalar' if $@;

use Archer;
use Archer::Shell;
use Archer::Parallel::ForkManager;
use t::Util;
use List::MoreUtils qw/uniq/;

no warnings 'redefine';
local *Archer::Shell::callback = sub {
    my ( $self, $server, $cmd ) = @_;
    print "$server:$cmd\n";
};
use warnings 'redefine';

init;

my $archer = Archer->new({
    project      => 'YourProj',
    dry_run_fg   => 0,
    parallel_num => 0,
    skips        => {},
    config_yaml  => 't/02_shell.yaml',
    argv_str     => '',
    shell        => 1,
    write_config => 0,
    log_level    => 'error',
});

my $context = $archer->context;

my @servers
    = uniq map { @{ $_ } }
    sort
    values
    %{ $context->{ config }->{ projects }->{ $archer->{ project } } };

my $shell = Archer::Shell->new({
    context => $archer,
    config  => $archer->{ config },
    servers => \@servers,
    parallel => "Archer::Parallel::ForkManager",
});


my @app = qw(127.0.0.1 127.0.0.2);
my @db  = qw(127.0.0.3 127.0.0.4);
my @all = (@app, @db);

capture { $shell->catch_run("date"); };
is($OUT, join("\n",map{"$_:date"}@all)."\n","command");

capture { $shell->catch_run("on 127.0.0.0 127.0.0.2 127.0.0.2 do date"); };
is($OUT, join("\n",map{"$_:date"}qw(127.0.0.2))."\n", "on host do command");

capture { $shell->catch_run("with app do uname"); };
is($OUT, join("\n",map{"$_:uname"}@app)."\n", "with role do command");

capture { $shell->catch_run("with app db do w"); };
is($OUT, join("\n",map{"$_:w"}@app,@db)."\n", "with role role do command");


capture { $shell->catch_run("!test"); };
is($OUT, join("\n",map{"$_:hostname"}@all)."\n", "task");

capture { $shell->catch_run("!test on 127.0.0.0 127.0.0.2 127.0.0.2"); };
is($OUT, join("\n",map{"$_:hostname"}qw(127.0.0.2))."\n", "task on host");

capture { $shell->catch_run("!test with app"); };
is($OUT, join("\n",map{"$_:hostname"}@app)."\n", "task with role");

capture { $shell->catch_run("!test with app db"); };
is($OUT, join("\n",map{"$_:hostname"}@app,@db)."\n", "task with role role");

done_testing;
