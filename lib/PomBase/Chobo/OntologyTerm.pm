package PomBase::Chobo::OntologyTerm;

=head1 NAME

PomBase::Chobo::OntologyTerm - Simple class for accessing term data

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chobo::OntologyTerm

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use Mouse;

use PomBase::Chobo::OntologyConf;

has id => (is => 'ro', isa => 'Str');
has name => (is => 'ro', isa => 'Str');
has namespace => (is => 'ro', isa => 'Str');
has is_relationshiptype => (is => 'ro', isa => 'Bool');

our @field_names;
our %field_conf;

BEGIN {
  %field_conf = %PomBase::Chobo::OntologyConf::field_conf;
  @field_names = qw(id name);

  for my $field_name (sort grep { $_ ne 'id' && $_ ne 'name' } keys %field_conf) {
    push @field_names, $field_name;
  }
}

sub bless_object
{
  my $object = shift;

  bless $object, __PACKAGE__;
}

sub to_string
{
  my $self = shift;

  my @lines = ();

  if ($self->is_relationshiptype()) {
    push @lines, "[Typedef]";
  } else {
    push @lines, "[Term]";
  }

  my $line_maker = sub {
    my $name = shift;
    my $value = shift;

    my @ret_lines = ();

    if (ref $value) {
      for my $single_value (@$value) {
        my $to_string_proc = $field_conf{$name}->{to_string};
        my $value_as_string;
        if (defined $to_string_proc) {
          $value_as_string = $to_string_proc->($single_value);
        } else {
          $value_as_string = $single_value;
        }
        push @ret_lines, "$name: $value_as_string";
      }
    } else {
      push @ret_lines, "$name: $value";
    }

    return @ret_lines;
  };

  for my $field_name (@field_names) {
  my $field_value = $self->{$field_name};

    if (defined $field_value) {
      push @lines, $line_maker->($field_name, $field_value);
    }
  }

  return join "\n", @lines;
}

1;
