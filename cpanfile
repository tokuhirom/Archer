requires 'File::HomeDir';
requires 'File::ShareDir';
requires 'File::Util';
requires 'IO::Prompt::Simple';
requires 'Kwalify';
requires 'List::MoreUtils';
requires 'Net::SSH';
requires 'Parallel::ForkManager';
requires 'Path::Class';
requires 'String::CamelCase';
requires 'Template';
requires 'Term::ANSIColor';
requires 'UNIVERSAL::require';
requires 'YAML';
requires 'perl', '5.008001';

recommends 'File::Rsync';
recommends 'SVN::Agent';
recommends 'MySQL::Diff';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More';
};
