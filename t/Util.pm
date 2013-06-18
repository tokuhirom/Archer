package t::Util;
use strict;
use warnings;
use utf8;
use FindBin;
use Test::More ();

use base 'Exporter';
our @EXPORT = qw/capture init $OUT $ERR is_valid_output/;

our $OUT;
our $ERR;

sub init {
    $FindBin::Bin .= "/.." if $FindBin::Bin !~ m!/\.\.!;
    $t::Plugin::Dummy::RUN_COUNTER = 0;
}

sub capture(&) {
    my $code = shift;

    $ERR = undef;
    $OUT = undef;

    tie *STDERR, 'IO::Scalar', \$ERR;
    tie *STDOUT, 'IO::Scalar', \$OUT;

        $code->();

    untie *STDERR;
    untie *STDOUT;
}

sub is_valid_output {
    my ($out, $out_expects, $test_name) = @_;

    Test::More::is_deeply([sort split /\n/, $out], [sort @$out_expects], $test_name);
}

1;
