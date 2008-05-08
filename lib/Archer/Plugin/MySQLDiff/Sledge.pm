package Archer::Plugin::MySQLDiff::Sledge;
use strict;
use warnings;
use base qw/Archer::Plugin/;
use SQL::Translator;
use SQL::Translator::Diff;
use SQL::Translator::Parser::MySQL;
use Path::Class;

sub run {
    my $self = shift;

    my $config = "$self->{project}::Config";
    $config->use or die $@;
    return unless $config->can('_new_instance');

    my $src = $self->_src_schema;

    local $ENV{SLEDGE_CONFIG_NAME} = '_product';
    my $production = $self->_production_db($config->_new_instance->{datasource});

    my $diff = SQL::Translator::Diff->new(
        {
            output_db       => 'MySQL',
            source_schema   => $src,
            target_schema   => $production,
            target_db       => 'MySQL',
            no_batch_alters => 1,
        }
    )->compute_differences->produce_diff_sql;

    print STDERR $diff;
}

sub _src_schema {
    my $self = shift;
    my $work_dir = Archer->context->{ config }->{ global }->{ work_dir };

    my $src = file( $work_dir, $self->{project}, $self->l_project, 'db', 'schema.sql' )->slurp;
    $src =~ s/\s+COMMENT\s+['"][^'"]+['"]\s*//gi;    # SQL::Translator cannot parse comments.

    my $t = SQL::Translator->new();
    $t->parser('SQL::Translator::Parser::MySQL');
    $t->translate( \$src );

    my $schema = $t->schema;
    $schema->name('schema.sql');
    $schema;
}

sub _production_db {
    my ($self, $dsn) = @_;

    if ( scalar @$dsn == 4 ) {
        pop @$dsn; # dbic stuff
    }

    my $dbh = DBI->connect(
        @$dsn,
        {
            RaiseError       => 1,
            FetchHashKeyName => 'NAME_lc',
        }
    );

    my $t = SQL::Translator->new(
        parser => 'DBI',
        no_comments => 1,
        parser_args => {
            dbh    => $dbh,
        }
    );
    $t->translate;

    my $schema = $t->schema or die $t->error;
    $schema->name($dsn->[0]);
    $schema;
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

