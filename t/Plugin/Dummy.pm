package t::Plugin::Dummy;
use strict;
use warnings;
use base qw/Archer::Plugin/;

our $RUN_COUNTER = 0;

sub run {
    # this is just a dummy. nop.
    $RUN_COUNTER++;
}

1;

