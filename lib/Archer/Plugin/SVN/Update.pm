package Archer::Plugin::SVN::Update;

use strict;
use warnings;
use base qw( Archer::Plugin::SVN );

use SVN::Agent;

sub run {
    my ($self, $context, $args) = @_;

    my $path = $self->{config}->{path}
        || File::Spec->catfile($context->{config}->{global}->{work_dir}, $context->{project});
    $path = $self->templatize($path);

    my $svn = SVN::Agent->load({ path => $path });
    $svn->update;
}

1;

__END__

=head1 NAME

Archer::Plugin::SVN::Update - svn update

=head1 SYNOPSIS

  - module: SVN::Update
    config:
      path: "[% work_dir %]/[% project %]"

=head1 DESCRIPTION

Execute svn update.

=head1 CONFIG

=head2 path

Svn working directory path.Default is [% work_dir %]/[% project %].

=head1 AUTHORS

Gosuke Miyashita

=head1 SEE ALSO

L<SVN::Agent>

=cut
