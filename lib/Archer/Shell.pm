package Archer::Shell;
use strict;
use warnings;
use Net::SSH;
use Term::ReadLine;
use POSIX;
use File::HomeDir;
use Path::Class;
use List::MoreUtils qw/uniq/;

sub new {
    my ( $class, $args ) = @_;

    return bless {%$args}, $class;
}

sub run_loop {
    my ( $self, ) = @_;

    # initialize parallel manager.
    $self->{parallel} = $self->{context}->{config}->{global}->{parallel}
        || 'Archer::Parallel::ForkManager';
    $self->{parallel}->use or die $@;

    # initialize readline library.
    my $term = Term::ReadLine->new('Archer');

    my $HISTFILE = file( File::HomeDir->my_home, "/.archer_shell_history" );
    my $HISTSIZE = 256;

   # this won't work with Term::ReadLine::Perl
   # If there is Term::ReadLine::Gnu, be sure to do : export "PERL_RL=Gnu o=0"
    eval { $term->stifle_history($HISTSIZE); };

    if ($@) {
        $self->{context}
            ->log( 'debug' => "You will need Term::ReadLine::Gnu" );
    }
    else {
        if ( -f $HISTFILE ) {
            $term->ReadHistory($HISTFILE)
                or $self->{context}
                ->log( 'warn' => "cannot read history file: $!" );
        }
    }

    while ( defined( my $line = $term->readline('archer> ') ) ) {
        next if $line =~ /^\s*$/;
        $self->catch_run($line);
    }

    print "\n";

    eval { $term->WriteHistory($HISTFILE); };
    if ($@) {
        $self->{context}
            ->log( 'debug' => "perlsh: cannot write history file: $!" );
    }

}

sub catch_run {
    my ( $self, $cmd ) = @_;

    if ( $cmd =~ /^on\s+/ ) {
        if ( $cmd =~ /^on\s(.*)\sdo\s(.*)$/ ) {
            $self->process_host( $1, $2 );
        }
        else {
            print "[WARNING] error in your syntax, see help\n";
        }
    }
    elsif ( $cmd =~ /^with\s+/ ) {
        if ( $cmd =~ /^with\s(.*)\sdo\s(.*)$/ ) {
            $self->process_role( $1, $2 );
        }
        else {
            print "[WARNING] error in your syntax, see help\n";
        }
    }
    elsif ( $cmd =~ /^help/ ) {
        $self->help();
    }
    elsif ( $cmd =~ /^(quit|exit)/ ) {
        print "bye bye\n";
        exit;
    }
    elsif ( $cmd =~ /^!/ ) {
        if ( $cmd =~ /^!(\w+)\s?(on|with)?\s?(.*)?$/ ) {
            my $task     = $1;
            my $action   = $2;
            my $machines = $3;
            if (   defined $action
                && defined $machines
                && length($machines) < 1 )
            {
                return print "[WARNING] error in your syntax, see help\n";
            }
            my $executed = 0;
            my %valid_host = map {$_=>1} @{$self->{servers}};
            for my $plugin ( @{ $self->{config}->{tasks}->{process} } ) {
                next if $plugin->{name} ne $task;
                $executed = 1;
                if ( defined $action ) {
                    if ( $action eq "on" ) {
                        my @hosts = split " ", $machines;
                        for my $host (uniq @hosts) {
                            $self->process_task( $plugin, $host ) if $valid_host{$host};
                        }
                    }
                    else {
                        my @roles = split " ", $machines;
                        my $server_tree = $self->{config}->{projects}->{$self->{context}->{project}};
                        for my $role (@roles) {
                            for my $host ( @{ $server_tree->{$role} } ) {
                                $self->process_task( $plugin, $host ) if $valid_host{$host};
                            }
                        }
                    }
                }
                else {
                    for my $host (@{$self->{servers}}) {
                        $self->process_task( $plugin, $host );
                    }
                }
            }
            if ( $executed == 0 ) {
                print "[WARNING] unable to find the requested task: $task\n";
            }
        }
        else {
            print "[WARNING] error in your syntax\n";
        }
    }
    else {
        $self->process_command($cmd);
    }
}

sub process_host {
    my ( $self, $hosts, $cmd ) = @_;

    my @hosts = split /\s/, $hosts;

    # check if hosts are in our config.
    my %valid_host = map {$_=>1} @{$self->{servers}};
    @hosts = grep { $valid_host{$_} } @hosts;

    if (@hosts) {
        $self->process_command( $cmd, \@hosts );
    }
}

sub process_role {
    my ( $self, $roles, $cmd ) = @_;

    my @roles      = split /\s/, $roles;
    my @hosts      = ();
    my @inexistant = ();
    my $server_tree = $self->{config}->{projects}->{$self->{context}->{project}};

    for my $role (@roles) {
        if ( !defined $server_tree->{$role} ) {
            push( @inexistant, $role );
            next;
        }
        for my $host ( @{ $server_tree->{$role} } ) {
            push @hosts, $host;
        }
    }
    if (@inexistant) {
        print "[WARNING] inexisting role(s) for "
            . join( ' ', @inexistant ) . "\n";
    }
    $self->process_command( $cmd, \@hosts );
}

sub process_command {
    my ( $self, $cmd, $hosts ) = @_;
    my $manager = $self->{parallel}->new;

    $hosts ||= $self->{servers};
    $hosts = [ sort( uniq(@{$hosts}) ) ];

    $manager->run(
        {   elems    => $hosts,
            callback => sub {
                my $server = shift;
                $self->callback( $server, $cmd );
            },
            num => $self->{context}->{parallel_num},
        }
    );
}

sub process_task {
    my ( $self, $plugin, $host ) = @_;
    my $class = ($plugin->{module} =~ /^\+(.+)$/) ? $1 : "Archer::Plugin::$plugin->{module}";
    $class->use or die $@;
    $class->new(
        {   config  => $plugin->{config},
            project => $self->{context}->{project},
            server  => $host
        }
    )->run( $self->{context} );
}

sub callback {
    my ( $self, $server, $cmd ) = @_;

    Net::SSH::sshopen2( $server, *READER, *WRITER, $cmd );
    while (<READER>) {
        chomp;
        print "[$server] $_\n";
    }
    close READER;
    close WRITER;
}

sub help {
    my ($self) = @_;
    my $help = <<HELP;
 To quit, just type quit, exit, or press ctrl-D. 
 This shell is still experimental.

 execute a command on all servers, just type it directly, like:

archer> ping

 To execute a command on a specific set of servers, specify an 'on' clause.
 Note that if you specify more than one host name, they must be 
 space-delimited.

archer> on app1.foo.com app2.foo.com do ping

 To execute a command on all servers matching a set of roles:

archer> with web db do ping

 To execute an Archer task, prefix the name with a bang, by default it
 will be executed only on the role applyed to this task.

archer> !restart

 To execute an Archer task on a specific set of servers:

archer> !restart on app1.foo.com app2.foo.com

 To execute an Archer task on all servers matching a set of roles:

archer> !restart with web db

HELP
    print $help;
}

1;
__END__

=head1 NAME

Archer::Shell - display shell prompt for remote servers.

=head1 DESCRIPTION

Shell prompt for remote servers.

=head1 FILES

    ~/.archer_shell_history

=head1 AUTHORS

    Gosuke Miyashita
    Tokuhiro Matsuno

=head1 SEE ALSO

L<Term::ReadLine>

=cut
