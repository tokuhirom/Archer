package Archer::Parallel::ForkManager;
use strict;
use warnings;
use Parallel::ForkManager;

sub new { bless {}, shift }

sub run {
    my ($self, $args) = @_;

    my $pm = Parallel::ForkManager->new( $args->{num} );
    for my $elem ( @{ $args->{elems} } ) {
        $pm->start and next;

        $args->{callback}->( $elem );

        $pm->finish;
    }

    $pm->wait_all_children;
}

1;
__END__

=head1 SYNOPSIS

    my $manager = Archer::Parallel::ForkManager->new;
    $manager->run(
        {
            num => 30,
            callback => sub {
                my $elem = shift;
                $self->run_hook('process', {elem => $elem});
            }
        }
    );

