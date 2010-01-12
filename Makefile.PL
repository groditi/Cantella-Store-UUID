use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Cantella-Store-UUID';
license 'perl';
all_from 'lib/Cantella/Store/UUID.pm';

requires 'JSON';
requires 'Moose';
requires 'Class::MOP';
requires 'File::Copy';
requires 'Data::GUID';
requires 'Path::Class' => '0.18';
requires 'Sub::Exporter';
requires 'namespace::autoclean';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types::Data::GUID';

#tests
test_requires 'FindBin';
test_requires 'Test::More';
test_requires 'Test::Exception';

resources(
  'license', => 'http://dev.perl.org/licenses/',
  'repository', => 'http://github.com/groditi/Cantella-Store-UUID',
);

WriteAll;
