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
is_valid_output($OUT, [map{"$_:date"}@all], 'command');

capture { $shell->catch_run("on 127.0.0.0 127.0.0.2 127.0.0.2 do date"); };
is_valid_output($OUT, [map{"$_:date"}qw(127.0.0.2)], "on host do command");

capture { $shell->catch_run("with app do uname"); };
is_valid_output($OUT, [map{"$_:uname"}@app], "with role do command");

capture { $shell->catch_run("with app db do w"); };
is_valid_output($OUT, [map{"$_:w"}@app,@db], "with role role do command");

capture { $shell->catch_run("!test"); };
is_valid_output($OUT, [map{"$_:hostname"}@all], "task");

capture { $shell->catch_run("!test on 127.0.0.0 127.0.0.2 127.0.0.2"); };
is_valid_output($OUT, [map{"$_:hostname"}qw(127.0.0.2)], "task on host");

capture { $shell->catch_run("!test with app"); };
is_valid_output($OUT, [map{"$_:hostname"}@app], "task with role");

capture { $shell->catch_run("!test with app db"); };
is_valid_output($OUT, [map{"$_:hostname"}@app,@db], "task with role role");

done_testing;
