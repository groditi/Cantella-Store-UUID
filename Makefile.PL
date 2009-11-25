use inc::Module::Install;

name 'Cantella-Store-UUID';
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
requires 'FindBin';
requires 'Test::More';
requires 'Test::Exception';

WriteAll;
