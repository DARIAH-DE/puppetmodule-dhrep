# == Class: textgrid::services::digilib
#
# Class to install and configure digilib
#
class textgrid::services::digilib {

  package {
    'libvips':       ensure => present; # this is needed by the prescaler, see textgrid::services::intern::messaging
    'libvips-tools': ensure => present;
  }

  file { '/var/textgrid/digilib':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  # the prescale images will be written by wildfly
  file { '/var/textgrid/digilib/prescale':
    ensure => directory,
    owner  => 'wildfly',
    group  => 'wildfly',
    mode   => '0755',
  }

}
