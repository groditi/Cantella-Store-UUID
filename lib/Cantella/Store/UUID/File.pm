package Cantella::Store::UUID::File;

use Moose;
use JSON ();

use MooseX::Types::Data::GUID qw/GUID/;
use MooseX::Types::Path::Class qw/Dir File/;

use namespace::autoclean;

our $VERSION = '0.001000';

has uuid => (is => 'ro', isa => GUID, coerce => 1, required => 1);
has dir => (is => 'ro', isa => Dir,  coerce => 1);

has path => (is => 'ro', isa => File, coerce => 1, lazy_build => 1);
has _meta_file => (is => 'ro', isa => File, coerce => 1, lazy_build => 1);

has metadata => (
  isa => 'HashRef',
  reader => 'metadata',
  writer => 'set_metadata',
  lazy_build => 1,
  trigger => sub { shift->write_metadata },
);

sub _build_path {
  my $self = shift;
  $self->dir->file( $self->uuid->as_string );
}

sub _build__meta_file {
  my $self = shift;
  $self->dir->file((join '.', $self->uuid->as_string, 'meta' ));
}

sub _build_metadata {
  my $self = shift;
  my $file = $self->_meta_file;
  if( my $json = $file->slurp ){
    if( my $perl = eval { JSON::from_json( $json ) }){
      return $perl;
    }
    die("Failed to parse contents of meta file $file: ${@}");
  }
  die("Failed to read file $file: ${!}");
}

sub write_metadata {
  my $self = shift;
  my $file = $self->_meta_file;
  if (my $json = JSON::to_json( $self->metadata || {} ) ){
    if( my $fh = $file->openw ){
      print $fh $json;
      return 1;
    }
    die("Failed to write meta file '${file}' Contents: '${json}': ${!}");
  }
  die("Failed to serialize metadata");
}

sub remove {
  my $self = shift;
  my $uuid = $self->uuid;
  my $file_path = $self->path;
  my $meta_path = $self->_meta_file;

  if( -e $meta_path && !$meta_path->remove ){
    die("Can't remove '${uuid}': Failed to delete '${meta_path}': ${!}");
  }
  if (-e $file_path && !$file_path->remove){
    die("Can't remove '${uuid}': Failed to delete '${file_path}': ${!}");
  }

  return ! (-e $self->path || -e $self->_meta_file);
}

sub exists {
  my $self = shift;
  return -e $self->path and -e $self->_meta_file;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME Cantella::Store::UUID::File

=head1 A NOTE ABOUT EXTENSIONS

To make file location deterministic, files are stored under only their UUID,
along with their respective meta file which is named C<$UUID.meta> eg
(C<DD5EB40A-164B-11DE-9893-5FA9AE3835A0.meta>). The meta files may contain any
number of attributes relevant to the file such as original name, extension,
MIME typ, etc. Meta files are stored in JSON format.

=head1 ATTRIBUTES

C<Cantella::Store::UUID> is a subclass of L<Moose::Object>. It inherits the
C<new> object provided by L<Moose>. All attributes can be set using the C<new>
constructor method, or their respecitive writer method, if applicable.

=head2 uuid

Required, read-only L<Data::GUID> object, will automatically coerce.

=head2 dir

Required, read-only L<Path::Class::File> object representing the directory
where this file is stored. Automatically coercing.

=head2 path

Lazy-building, read-only L<Path::Class::File> object representing the file being stored
under this UUID.

=head2 metadata

Lazy_building, read-write hashref which contains the file's metadata. Setting it with the
set_metadata method will write the data to disk.

=head2 _meta_file

Lazy-building, read-only L<Path::Class::File> object pointing at the meta file.

=head1 METHODS

=head2 write_metadata

Write the contents of C<metadata> to the metadata file.

=head2 remove

Removes the file and metadata file from the store. Returns true if both are
removed successfully.

=head2 exists

Checks for existence of both the file and the metadata file. Returns true only
if both exist.

=head1 SEE ALSO

L<Cantella::Store::UUID>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
