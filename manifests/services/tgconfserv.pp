# == Class: dhrep::services::tgconfserv
#
# Class to create TextGrid confserv entries
#
# === Parameters
#
# [*service_base_url*]
#   the url where the services are accessible from tglab
#
class dhrep::services::tgconfserv (
  $service_base_url = "https:\\/\\/${::fqdn}\\/1.0",
){

  ###
  # configuration
  ###
  file { '/var/www/confserv':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/etc/dhrep'],
  }
  file { '/var/www/confserv/1.0':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/confserv'],
  }
  file { '/var/www/confserv/1.0/getAll':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/confserv/1.0/getAll.erb'),
  }
  file { '/var/www/confserv/1.0/getAllJ':
    ensure => link,
    target => '/var/www/confserv/1.0/getAll',
  }
}
