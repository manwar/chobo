package PomBase::Chobo::Role::ChadoStore;

=head1 NAME

PomBase::Chobo::Role::ChadoStore - Code for storing terms in Chado

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::Role::ChadoStore

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Mouse::Role;

requires 'dbh';
requires 'chado_data';
requires 'ontology_data';

use PomBase::Chobo::ChadoData;
use PomBase::Chobo::OntologyConf;

our @relationship_cv_names;

BEGIN {
  @relationship_cv_names = @PomBase::Chobo::OntologyConf::relationship_cv_names;
}

sub _copy_to_table
{
  my $self = shift;
  my $table_name = shift;
  my $column_names_ref = shift;
  my @column_names = @$column_names_ref;
  my $data_ref = shift;
  my @data = @$data_ref;

  my $dbh = $self->dbh();

  my $column_names = join ',', @column_names;

  $dbh->do("COPY $table_name($column_names) FROM STDIN")
    or die "failed to COPY into $table_name: ", $dbh->errstr, "\n";

  for my $row (@data) {
    if (!$dbh->pg_putcopydata((join "\t", @$row) . "\n")) {
      die $dbh->errstr();
    }
  }

  if (!$dbh->pg_putcopyend()) {
    die $dbh->errstr();
  }

  warn "COPY $table_name FROM STDIN finished\n";
}

sub _get_relationship_term
{
  my $self = shift;
  my $chado_data = shift;
  my $rel_name = shift;
  my $rel_cv_names_ref = shift;

  my @rel_cv_names = @$rel_cv_names_ref;

  for my $rel_cv_name (@rel_cv_names) {
    my $cv_id = $chado_data->get_cv_by_name($rel_cv_name)->{cv_id};

    my $get_cvterm_by_cv_i
  }
}


my %row_makers = (
  db => sub {
    my $ontology_data = shift;

    return map {
      [$_];
    } $ontology_data->get_db_names();
  },
  dbxref => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    map {
      my $db_name = $_;
      my $db_id = $chado_data->get_db_by_name($db_name)->{db_id};

      my %current_db_terms = %{$ontology_data->terms_by_db_name()->{$db_name}};

      map {
        my $accession = $_;
        [$db_id, $accession];
     } keys %current_db_terms;
    } $ontology_data->get_db_names();
  },
  cv => sub {
    my $ontology_data = shift;

    return map {
      [$_];
    } $ontology_data->get_cv_names();
  },
  cvterm => sub {
    my $ontology_data = shift;
    my $chado_data = shift;

    map {
      my $cv_name = $_;
      my $cv_id = $chado_data->get_cv_by_name($cv_name)->{cv_id};

      my @cvterms = $ontology_data->get_terms_by_cv_name($cv_name);

      map {
        my $term = $_;

        my $dbxref_id = $chado_data->get_dbxref_by_termid($term->{id})->{dbxref_id};
        my $is_relationshiptype = $term->{is_relationshiptype};

        if ($term->{is_obsolete}) {
          ();
        } else {
          [$term->name(), $cv_id, $dbxref_id, $is_relationshiptype];
        }
      } @cvterms;
    } $ontology_data->get_cv_names();
  },
#   cvterm_relationship = sub {
#     my $ontology_data = shift;
#     my $chado_data = shift;
#
#     my $is_a_cvterm = $self->_get_relationship_term($chado_data, 'is_a',
#                                                     [@relationship_cv_names]);
#
#     map {
#       my $cv_name = $_;
#       my $cv_id = $chado_data->get_cv_by_name($cv_name)->{cv_id};
#
#       my @cvterms = $ontology_data->get_terms_by_cv_name($cv_name);
#
#       map {
#         my $term = $_;
#
# #        if (
#
#         my $subject_id = $chado_data->get_cvterm_by_termid($term->{id});
#         my $rel_name = $
#
#         [$term->name(), $cv_id, $dbxref_id, $is_relationshiptype];
#       } @cvterms;
#     } $ontology_data->get_cv_names();
#   },
);

my %table_column_names = (
  db => [qw(name)],
  dbxref => [qw(db_id accession)],
  cv => [qw(name)],
  cvterm => [qw(name cv_id dbxref_id is_relationshiptype)],
  cvterm_relationship => [qw(subject_id type_id object_id)],
);

sub chado_store
{
  my $self = shift;

  my @cvterm_column_names =
    @PomBase::Chobo::ChadoData::cvterm_column_names;

  my $chado_data = $self->chado_data();

  my @tables_to_store = qw(db dbxref cv cvterm);

  for my $table_to_store (@tables_to_store) {
    my @rows = $row_makers{$table_to_store}->($self->ontology_data(),
                                              $self->chado_data());

    $self->_copy_to_table($table_to_store, $table_column_names{$table_to_store},
                          \@rows);
  }

}

1;
