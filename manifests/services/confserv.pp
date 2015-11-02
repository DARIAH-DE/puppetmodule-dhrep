# == Class: dhrep::services::tgsearch
#
# Class to create confserv entries
# 
# === Parameters
#
# [*service_base_url*]
#   the url where the services are accessible from tglab
#
class dhrep::services::confserv (
  $service_base_url = '',
){

  file { '/var/www/confserv':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/etc/textgrid'],
  }

  file { '/var/www/confserv/1.0':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/confserv'],
  }

  file { '/var/www/confserv/1.0/getAll':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/confserv/1.0/getAll.erb'),
  }

  file { '/var/www/confserv/1.0/getAllJ':
    ensure => link,
    target => '/var/www/confserv/1.0/getAll',
  }

}
