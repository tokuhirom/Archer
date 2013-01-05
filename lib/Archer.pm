package Archer;
use strict;
use warnings;
use 5.008001;
use Carp;
use List::MoreUtils qw/uniq/;
use Archer::ConfigLoader;
use UNIVERSAL::require;

our $VERSION = '0.12';

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
        $self->{ config } = $config_loader->load( $opts->{ config_yaml }, $self );
    }

    if ( $self->{ log_level } ) {
        $self->{ config }->{ global }->{ log } = { level => $self->{ log_level } };
    } else {
        $self->{ config }->{ global }->{ log } ||= { level => 'debug' };
    }

    Archer->set_context( $self );

    return $self;
}

sub run {
    my ( $self, ) = @_;

    if ( $self->{ shell } ) {

        require Archer::Shell;

        my $server_tree = $self->{config}->{projects}->{$self->{project}};
        my @servers;
        while ( my ( $role, $servers ) = each %$server_tree ) {
            next if $self->{role} && $self->{role} ne $role;
            for my $server ( @$servers ) {
                push @servers, $server;
            }
        }
        @servers = uniq @servers;

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
    TASK:
    for my $plugin ( @{ $self->{ config }->{ tasks }->{ $hook } } ) {
        if ( $self->{ skips }->{ $plugin->{ name } } ) {
            $self->log( info => "skipped: $plugin->{name}" );
            next;
        }

        if ( $hook eq 'process' && $self->{ only } ) {
            if ( $self->{only} ne $plugin->{ name } ) {
                $self->log( debug => "skipped: $plugin->{name}" );
                next;
            }
        } else {
            if ( $plugin->{skip_default} && ! $self->{ withs }->{ $plugin->{ name } } ) {
                next;
            }
        }

        for my $filter ( qw/ role project / ) {
          if ( my $data = $plugin->{ $filter } ) {
            my @datas = ref $data eq 'ARRAY' ? @$data : ($data);
            unless ( grep {$_ eq $args->{ $filter }} @datas ) {
              $self->log( info =>
                qq(skip $args->{server}. because "@{[join ' ', @datas]}" doesn't match $args->{$filter})
              );
              next TASK;
            }
          }
        }

        my $class = ($plugin->{module} =~ /^\+(.+)$/) ? $1 : "Archer::Plugin::$plugin->{module}";
        $self->log( 'debug' => "load $class" );
        $class->use or die $@;

        if ( $args->{server} ) {
            $self->log( 'info' => "run @{[ $plugin->{name} ]} ( $class ) to @{[ $args->{server} ]}" );
        } else {
            $self->log( 'info' => "run @{[ $plugin->{name} ]} ( $class )" );
        }
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

    my $server_tree = $self->{config}->{projects}->{$self->{project}};

    my @elems;
    while ( my ( $role, $servers ) = each %$server_tree ) {
        next if $self->{role} && $self->{role} ne $role;
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

    my $setting_level = $self->{config}->{global}->{log}->{level} || 'debug';
    $levels{ $level } >= $levels{ $setting_level };
}

1;

__END__

=head1 NAME

Archer - yet another deployment tool

=head1 DESCRIPTION

This is yet another deployment tool :)

=head1 AUTHORS

Tokuhiro Matsuno and Archer comitters.

=head1 TODO

=head1 SEE ALSO

L<capistrano>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

