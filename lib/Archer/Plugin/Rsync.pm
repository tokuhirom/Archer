package Archer::Plugin::Rsync;
use strict;
use warnings;
use base qw( Archer::Plugin );
use File::Spec;
use File::Rsync;

sub run {
    my ($self, $context, $args) = @_;

    my $global = $context->{config}->{global};
    my $source = $self->{config}->{source}
        || File::Spec->catfile($global->{work_dir}, $context->{project});
    my $dest   = $self->{config}->{dest} || "$args->{server}:$global->{dest_dir}";
    my $user   = $self->{config}->{user};
    if ( $user ) {
        $dest = join '@', $user, $dest;
        delete $self->{config}->{user};
    }

    $source = $self->templatize($source);
    $dest   = $self->templatize($dest);

    delete $self->{config}->{source};
    delete $self->{config}->{dest};

    my %defaults = (
        archive  => 1,
        update   => 1,
        compress => 1,
        delete   => 1,
        exclude  => [ '.svn/' ],
        rsh      => 'ssh',
        source => $source,
        dest   => $dest,
        'dry-run' => ($context->{dry_run_fg} ? 1 : 0),
    );

    my $option = $self->{config} || {};
    my $rsync = File::Rsync->new({
        %defaults,
        %$option,
    });

    $rsync->exec;

    $self->log( debug => join('', $rsync->out) ) if () = $rsync->out;
    $self->log( debug => join('', $rsync->err) ) if () = $rsync->err;
}

1;
__END__

=head1 NAME

Archer::Plugin::Rsync - execute Rsync.

=head1 SYNOPSIS

  - module: Rsync
    config:
      user: mizzy
      source: "[% work_dir %]/[% project %]"
      dest: "[% server %]:[% dest_dir %]"
      archive:  1
      compress: 1
      rsh:      ssh
      update:   1
      delete:   1
      exclude:
        - .svn/

=head1 DESCRIPTION

Execute Rsync.

=head1 CONFIG

See L<File::Rsync>.

=head1 AUTHORS

Gosuke Miyashita

=head1 SEE ALSO

L<File::Rsync>

=cut
