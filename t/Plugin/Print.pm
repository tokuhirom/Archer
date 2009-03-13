package t::Plugin::Print;
use strict;
use warnings;
use base qw/Archer::Plugin/;
use FindBin ();

sub run {
    my ( $self, $context, $args ) = @_;
    printf "%s:%s\n", $self->{server}, $self->{config}->{command};
}

1;

