package Archer::Plugin::Exec::Remote;
use strict;
use warnings;
use base qw/Archer::Plugin::Exec/;

sub _execute {
    my ($self, $cmd, $args) = @_;

    my $real_command = "ssh -t $self->{server} $cmd";
    $real_command = "sudo -u $self->{config}->{user} $real_command" if $self->{config}->{user};
    $self->log(debug => "real execute: $real_command");

    system $real_command; # XXX security!!!
}

1;
__END__

=head1 NAME

Archer::Plugin::Exec::Remote - 

=head1 SYNOPSIS

    - module: Exec::Remote
      config:
        name: restart
        user: root
        command: "if [ -e /etc/init.d/apache ] ; then  /etc/init.d/apache stop; sleep 6; /etc/init.d/apache start; fi"
        type: app

=head1 DESCRIPTION

should be use in 'process' phase?

=head1 TODO

  use Net::SSH::Perl

=cut

