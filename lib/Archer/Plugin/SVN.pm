package Archer::Plugin::SVN;

use strict;
use warnings;
use base qw( Archer::Plugin );


package # hide from pause
    SVN::Agent;

sub log {
    my ( $self, @args ) = @_;
    return eval { $self->_svn_command('log', @args) };
}

1;
