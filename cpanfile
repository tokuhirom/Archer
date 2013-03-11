requires 'Carp'                  => 0;
requires 'File::Spec'            => 0;
requires 'FindBin'               => 0;
requires 'Getopt::Long'          => 0;
requires 'List::MoreUtils'       => 0;
requires 'Module::Build'         => 0;
requires 'Parallel::ForkManager' => 0;
requires 'Path::Class'           => 0;
requires 'Pod::Usage'            => 0;
requires 'Storable'              => 0;
requires 'String::CamelCase'     => 0;
requires 'Template'              => 0;
requires 'Term::ANSIColor'       => 0;
requires 'Test::More'            => 0.98;
requires 'UNIVERSAL::require'    => 0;
requires 'YAML'                  => 0;
requires 'Net::SSH'              => 0;
requires 'Term::ReadLine'        => 0;
requires 'File::Util';
requires 'IO::Prompt::Simple';
requires 'Kwalify';
requires 'File::HomeDir';
requires 'File::ShareDir';

on 'develop' => sub {
    requires 'Module::Install::CPANfile';
};
