package Archer::Plugin::MySQLDiff::Sledge;
use strict;
use warnings;
use base qw/Archer::Plugin/;
use MySQL::Diff;

sub run {
    my $self = shift;

    my $config = "$self->{project}::Config";
    $config->use or die;

    return unless $config->can('_new_instance');

    my $dev = $self->_db($config->_new_instance->datasource);
    local $ENV{SLEDGE_CONFIG_NAME} = '_product';
    my $product = $self->_db($config->_new_instance->datasource);

    print MySQL::Diff::diff_dbs({}, $product, $dev);
}

sub _db {
    my ($self, $drv, $user, $pass) = @_;

    my $db = ($drv =~ /^dbi:[^:]+:([^:;=]+)/) ? $1 : '';
    my $host = ($drv =~ /hostname=([a-zA-Z_0-9.]+)/) ? $1 : '';

    return MySQL::Database->new(
        auth =>
          { user => $user, password => $pass, host => $host },
        db => $db,
    );
}

1;
__END__

=head1 NAME

Archer::Plugin::MySQLDiff::Sledge - show the mysqldiff, with sledge's configuration class.

=head1 SYNOPSIS

  - module: MySQLDiff::Sledge

=head1 DESCRIPTION

=head1 AUTHORS

Tokuhiro Matsuno.

=cut

