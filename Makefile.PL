use strict;
use warnings;
use inc::Module::Install;

name     'Archer';
all_from 'lib/Archer.pm';

features(
    'Plugin::Rsync' => [
        -default => 0,
        recommends('File::Rsync' => 0),
    ],
    'Plugin::MySQLDiff' => [
        -default => 0,
        recommends('MySQL::Diff' => 0),
    ],
    'Plugin::SVN::*' => [
        -default => 0,
        recommends('SVN::Agent' => 0),
    ],
);

author_tests 'xt';
install_script('archer.pl');
install_script('archer');
install_share 'assets';

cpanfile;

WriteAll;
