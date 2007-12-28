package Archer;
use strict;
use warnings;
use Carp;
use List::MoreUtils qw/uniq/;
use Archer::ConfigLoader;
use UNIVERSAL::require;

our $VERSION = 0.01;

my $context;
sub context { $context }

sub set_context {
    my ( $class, $c ) = @_;
    $context = $c;
}

sub new {
    my ( $class, $opts ) = @_;
    my $self = bless { %$opts }, $class;

    if ( !$$opts{ write_config } ) {
        my $config_loader = Archer::ConfigLoader->new;
        $self->{ config } = $config_loader->load( $opts->{ config_yaml } );
    }
    $self->{ config }->{ global }->{ log } ||= { level => 'debug' };

    Archer->set_context( $self );

    return $self;
}

sub run {
    my ( $self, ) = @_;

    if ( $self->{ shell } ) {

        # TODO: role support
        require Archer::Shell;
        my @servers
            = map { @{ $_ } }
            values
            %{ $context->{ config }->{ projects }->{ $self->{ project } } };
        my $shell = Archer::Shell->new(
            {   context => $self,
                config  => $self->{ config },
                servers => \@servers,
            }
        );

        $shell->run_loop;
    }
    elsif ( $self->{ write_config } ) {
        require Archer::Util;
        my $util = Archer::Util->new;
        $util->templatize( $self );
    }
    else {
        $self->run_hook( 'init' );

        $self->run_process;

        $self->run_hook( 'finalize' );
    }
}

sub run_hook {
    my ( $self, $hook, $args ) = @_;
    $args ||= {};

    $self->log( 'info' => "run hook $hook" );
    for my $plugin ( @{ $self->{ config }->{ tasks }->{ $hook } } ) {
        if ( $self->{ skips }->{ $plugin->{ name } } ) {
            $self->log( info => "skipped: $plugin->{name}" );
            next;
        }

        if ( $plugin->{ role } && $plugin->{ role } ne $args->{ role } ) {
            $self->log( debug =>
                    "skip $args->{server}. because $plugin->{role} ne $args->{role}"
            );
            next;
        }

        my $class = "Archer::Plugin::$plugin->{module}";
        $self->log( 'debug' => "load $class" );
        $class->use or die $@;

        $self->log( 'info' => "run $class" );
        $class->new(
            {   config  => $plugin->{ config },
                project => $self->{ project },
                %$args
            }
        )->run( $self, $args );

        print "\n\n";    # for debug.
    }
}

sub run_process {
    my ( $self ) = @_;

    my $parallel = $self->{ config }->{ global }->{ parallel }
        || 'Archer::Parallel::ForkManager';
    $parallel->use or die $@;

    # construct elements
    # this one doesn't work for me
    # my $server_tree = $self->{config}->{projects}->{$self->{project}};
    # but this one do
    my $server_tree = $self->{ config }->{ projects };

    my @elems;
    while ( my ( $role, $servers ) = each %$server_tree ) {
        for my $server ( @$servers ) {
            push @elems, { server => $server, role => $role };
        }
    }
    $self->log( debug => "run parallel : $self->{parallel_num}" );
    my $manager = $parallel->new;
    $manager->run(
        {   elems    => \@elems,
            callback => sub {
                my $args = shift;
                $self->run_hook( 'process', $args );
            },
            num => $self->{ parallel_num },
        }
    );
}

sub bootstrap {
    my ( $class, $opts ) = @_;

    my $self = $class->new( $opts );
    $self->run;
    return $self;
}

# TODO: use the log4perl?
sub log {
    my ( $self, $level, $msg, %opt ) = @_;

    return unless $self->should_log( $level );

    # hack to get the original caller as Plugin or Rule
    # from plagger.
    my $caller = $opt{ caller };
    unless ( $caller ) {
        my $i = 0;
        while ( my $c = caller( $i++ ) ) {
            last if $c !~ /Plugin|Rule/;
            $caller = $c;
        }
        $caller ||= caller( 0 );
    }

    warn "$caller [$level] $msg\n";
}

my %levels = (
    debug => 0,
    warn  => 1,
    info  => 2,
    error => 3,
);

sub should_log {
    my ( $self, $level ) = @_;

    $levels{ $level }
        >= $levels{ $self->{ config }->{ global }->{ log }->{ level } };
}

1;

__END__

=head1 NAME

Archer - 

=head1 SYNOPSIS



=head1 DESCRIPTION

=head1 AUTHORS

Tokuhiro Matsuno

=head1 TODO

=cut

