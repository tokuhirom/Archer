package Archer::Plugin::Flock;
use strict;
use warnings;
use base qw/Archer::Plugin/;
use Fcntl ":flock";

sub run {
    my ($self, $context) = @_;

    my $filename = $self->{config}->{file} or die "missing filename";
    open my $fh , '>' , $filename or die $!;
    flock( $fh, LOCK_EX|LOCK_NB ) or die "cannot get the lock\n";

    $context->{__PACKAGE__} = $fh; # do not close the lock file :)
}

1;
__END__

=head1 NAME

Archer::Plugin::Flock - do not run two process in the same time.

=head1 SYNOPSIS

  - module: Flock
    config:
      file: /tmp/archer.lock

=head1 AUTHORS

Tokuhiro Matsuno.

=cut

