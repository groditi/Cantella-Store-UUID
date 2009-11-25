package Cantella::Store::UUID;

use Moose;
use Data::GUID;
use File::Copy qw();
use Path::Class qw();
use Cantella::Store::UUID::Util '_mkdirs';
use MooseX::Types::Path::Class qw/Dir/;

use namespace::autoclean;

our $VERSION = '0.001000';

has nest_levels => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has root_dir => (
  is => 'ro',
  isa => Dir,
  coerce => 1,
  required => 1
);

has file_class => (
  is => 'ro',
  isa => 'ClassName',
  required => 1,
  default => sub {
    Class::MOP::load_class('Cantella::Store::UUID::File');
    return 'Cantella::Store::UUID::File';
  }
);

sub from_uuid {
  my ($self, $uuid) = @_;
  return $self->file_class->new(
    uuid => $uuid,
    dir => $self->_get_dir_for_uuid($uuid),
    _document_store => $self,
  );
}

sub new_uuid {
  Data::GUID->new;
}

sub create_file {
  my( $self, $source_file, $uuid, $metadata) = @_;
  $source_file = Path::Class::file($source_file) unless blessed $source_file;
  my %meta = %{ $metadata || {} };
  $meta{original_name} = $source_file->basename;

  my $new_file = $self->from_uuid( $uuid );
  $new_file->set_metadata( \%meta );
  return $new_file if File::Copy::copy($source_file, $new_file->path);

  my $new_path = $new_file->path;
  die("File copy from ${source_file} to ${new_path} failed: $!");
}

sub deploy {
  my $self = shift;

  my $root = $self->root_dir;
  unless( -d $root || $root->mkpath ){
    die("Failed to create ${root}");
  }
  _mkdirs($root, $self->nest_levels);
  return 1;
}

sub _get_dir_for_uuid {
  my ($self, $uuid) = @_;
  $uuid = Data::GUID->from_any_string($uuid) unless blessed $uuid;
  my $target = $self->root_dir;
  my @dirs = split('', uc(substr($uuid->as_hex, 2, $self->nest_levels)));

  return $target->subdir( @dirs );
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME Cantella::Store::UUID - UUID based file storage

=head1 DESCRIPTION

L<Cantella::Store::UUID> stores documents in a deterministic location based on
a UUID. Depending on the number of files to be stored, a store may use 1
or more levels. A level is composed of 16 directories (0-9 and A-F) nested to
C<n> depth. For Example, if a store has 3 levels, the path to file represented
by UUID C<A5D45AF2-73D1-11DD-AA18-4B321EADD46B> would be
C<A/5/D/A5D45AF2-73D1-11DD-AA18-4B321EADD46B>.

The goal is to provide a simple way to spread the storage  of a large number of
files over many directories to prevent any single directory from storing too-many
files. Optionally, lower level tools can then be utilized to spread the
underlying storage points accross different physical devices if necessary.

The number of final storage points available can be calculated by raising 16 to
the nth power, where n is the number of C<nest levels>.

B<Caution:> The number of directories generated is actually larger than the
number of final storage points because all directories in the hierarchy must
be counted, thus the number of directories a store contains is
C<(16^n) + (16^(n-1)) .. (16^1) + (16^0)> and a 5 level deep hierarchy for
all three storage points would create 3,355,443 directories. For this reason,
any number larger than 4 is cautioned against.

=head1 SYNOPSYS

=head1 ATTRIBUTES

C<Cantella::Store::UUID> is a subclass of L<Moose::Object>. It inherits the
C<new> object provided by L<Moose>. All attributes can be set using the C<new>
constructor method, or their respecitive writer method, if applicable.

=head2 nest_levels

Required, read-only integer representing how many levels of depth to use in
the directory structure.

=head2 root_dir

Required, read-only directory location for the root of the hierarchy.

=head2 file_class

Required, read-only class name. The class to use for stored file objects.
Defaults to L<Cantella::Store::UUID::File>.

=head1 METHODS

=head2 from_uuid $uuid

Return the apropriate file object for $uuid.
Please note that this particular file does not neccesarily exist and its
presence is not checked for.

=head2 new_uuid

Returns a new UUID object suitable for use with this module. By default, it
currently uses L<Data::GUID>.

=head2 create_file $original, $uuid, $metadata

Will copy the C<$original> file into the the UUID storage and return the
file object representing it. The key C<original_name> will be automatically
set on the metadata with the base name of the original file.

=head2 deploy

Create directory hierarchy, starting with C<root_dir>. A call to deploy may
take a couple of minutes or even hours depending on the value of C<nest_levels>
and the speed of the storage being utilized.

=head2 _get_dir_for_uuid $uuid

Given a UUID, it returns the apropriate directory as a L<Path::Class::Dir>
object.

=head1 SEE ALSO

L<Cantella::Store::UUID::File>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
