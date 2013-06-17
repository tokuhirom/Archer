package Archer::Plugin::Exec;
use strict;
use warnings;
use base qw/Archer::Plugin/;
use Carp;
use Term::ANSIColor;

sub run {
    my ( $self, $context, $args ) = @_;
    my $cmd;

    if ( $self->{ config }->{ command } ) {
        $cmd = $self->{ config }->{ command };
        $self->log( debug => "template: $cmd" );

        $cmd = $self->templatize( $cmd );
        $self->log( info => "* execute " . colored( $cmd, 'red' ) );
    }
    elsif ( $self->{ config }->{ recipe } ) {
        #require Archer::Util;
        $cmd = $self->check_recipe( $self->{ config }->{ recipe },
            $context->{ config }->{ global }->{ recipe } );

        if ( !defined $cmd ) {
            $self->log(
                'warn' => 'The recipe ' . $self->{ config }->{ recipe } . ' can\'t be found'
            );
            return;
        }
        $cmd = $self->templatize( $cmd );
    }

    if ( $context->{ dry_run_fg } ) {
        $self->log( debug => "dry-run" );
    }
    else {
        $self->log( debug => "run!" );
        if ( $cmd ) {
            $self->_execute( $_ ) for grep !/^\s*$/, split /\n/, $cmd;
        }
    }
}

sub _execute {
    croak "this method is abstract";
}

1;
__END__

=head1 NAME

Archer::Plugin::Exec - run the command in ...

=head1 SYNOPSIS

  This class is not intended to be used directly

=head1 DESCRIPTION

Base class for executing commands.

=head1 AUTHORS

Tokuhiro Matsuno.

=cut

