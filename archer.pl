#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use FindBin ();
use Path::Class;
use File::Util;
use Cwd;

use lib dir( $FindBin::RealBin, 'lib' )->stringify;

use Archer;

my $argv_str = "@ARGV";
my $fork_num = 1;
my $config   = file( $FindBin::RealBin, 'config.yaml' )->stringify;
Getopt::Long::GetOptions(
    '--para=i'       => \$fork_num,
    '--dry-run'      => \my $dry_run_fg,
    '--skip=s'       => \my $skips,
    '--with=s'       => \my $withs,
    '--only=s'       => \my $only,
    '--shell',       => \my $shell,
    '--man'          => \my $man,
    '+--log_level=s'  => \my $log_level,
    '--config=s'     => \$config,
    '--write-config' => \my $wc,
) or pod2usage( 2 );
Getopt::Long::Configure( "bundling" );    # allows -p
pod2usage( -verbose => 2 ) if $man;

if ( !@ARGV ) {

    # name of the current dir, will be the project name
    my $dir     = getcwd;
    my $f       = File::Util->new;
    my $project = $f->strip_path( $dir );
    $config = '.archer.yaml';
    if ( $f->existent( $config ) ) {
        Archer->new(
            {   project      => $project,
                dry_run_fg   => $dry_run_fg,
                parallel_num => $fork_num,
                skips => +{ map { $_ => 1 } split /,/, ( $skips || '' ) },
                withs => +{ map { $_ => 1 } split /,/, ( $withs || '' ) },
                only        => $only,
                log_level   => $log_level,
                config_yaml => $config,
                argv_str    => $argv_str,
                shell       => $shell,
            }
        )->run;
        exit;
    }
    else {
        Archer->new(
            {   project      => $project,
                dry_run_fg   => $dry_run_fg,
                config_yaml  => $config,
                write_config => $wc,
            }
        )->run;
        exit;
    }
    pod2usage( 2 ) unless @ARGV;
}

for my $proj ( @ARGV ) {
    Archer->new(
        {   project      => $proj,
            dry_run_fg   => $dry_run_fg,
            parallel_num => $fork_num,
            skips        => +{ map { $_ => 1 } split /,/, ( $skips || '' ) },
            withs        => +{ map { $_ => 1 } split /,/, ( $withs || '' ) },
            only         => $only,
            log_level    => $log_level,
            config_yaml  => $config,
            argv_str     => $argv_str,
            shell        => $shell,
            write_config => $wc,
        }
    )->run;
}

__END__

=head1 SYNOPSIS

    $ archer.pl Caspeee
    
    Options:
        --para=5                parallel run for process phase.
        --dry-run               dry-run.
        --skip=restart          skip the task(csv).
        --with=somejob          do deploy with skip_defalt tasks.
        --only=rsync            do only specify task (only affect on process phase).
        --man                   show manual
        [--log_level=debug]     change log level from option. If you specify this, 
        --config                config.yaml path
        --shell                 shell mode

=head1 DESCRIPTION

Automating Application Deployment.

=head1 TODO

    logging.
    para=half.

=head1 TIPS

add to .zshrc.

    compctl -k '(--skip-restart --skip-mysqldiff --para --skip-svn-up)' deploy.pl

=head1 AUTHORS

Tokuhiro Matsuno <tokuhiro at mobilefactory.jp>.
