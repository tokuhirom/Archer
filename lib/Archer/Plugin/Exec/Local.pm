package Archer::Plugin::Exec::Local;
use strict;
use warnings;
use base qw/Archer::Plugin::Exec/;

sub _execute {
    my ($self, $cmd, $args) = @_;

    my $user = $self->{config}->{user};
    my $real_command = $user ? "sudo -u $user $cmd " : $cmd;
    $self->log(debug => "real execute: $real_command");

    system $real_command; # XXX security!!!
}

1;
__END__

=head1 NAME

Archer::Plugin::Exec::Local - run the command in local machine.

=head1 SYNOPSIS

  - module: Exec::Local
    config:
      user: root
      command: ls [% work_dir %]/[% project %]/

=head1 DESCRIPTION

run the command in local machine.

=head1 AUTHORS

Tokuhiro Matsuno.

=cut

