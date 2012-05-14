package Archer::Plugin::Confirm;
use strict;
use warnings;
use base qw/Archer::Plugin/;
use IO::Prompt::Simple qw/prompt/;

sub run {
    my ($self,) = @_;

    local $SIG{ALRM} = sub {
        $self->detach("\n\nConfirm timeout\n");
    };

    my $msg = $self->{config}->{msg} || 'do ? [y/n]';
    my $timeout = $self->{config}->{timeout} || 0;
    my $latest_alarm = alarm $timeout;

    if ( lc(prompt( $msg )) =~ /\Ay(?:es)?\z/ms ) {
        alarm $latest_alarm;
        $self->log(debug => "yes");
    }
    else {
        $self->log(debug => "no");
        $self->detach("cancel'd by user");
    }
}

1;
__END__

=head1 NAME

Archer::Plugin::Confirm -

=head1 SYNOPSIS

  - module: Confirm
    config:
      msg: really deploy? [Y/N]

=head1 DESCRIPTION

really deploy?

=head1 AUTHORS

Tokuhiro Matsuno.

=cut

