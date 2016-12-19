# == Class: dhrep::services::intern::messaging
#
# Class to build up messaging.
#
class dhrep::services::intern::messaging (
  $scope                     = undef,
  $enzmeta_textgrid_user     = '',
  $enzmeta_textgrid_password = '',
  $bolrdf_textgrid_user      = '',
) inherits dhrep::params {

  $_confdir = $::dhrep::params::confdir

  exec { 'git_clone_messagebeans':
    command => 'git clone git://git.projects.gwdg.de/textgrid-messagebeans.git /usr/local/src/messagebeans-git',
    path    => ['/usr/bin','/bin','/usr/sbin'],
    creates => '/usr/local/src/messagebeans-git',
    require => Package['git'],
  }
  file { '/root/.m2':
    ensure => directory,
  }
  file { '/root/.m2/settings.xml':
    ensure => present,
    source => 'puppet:///modules/dhrep/root/m2-settings.xml',
  }
  file { "${_confdir}/messagebeans":
    ensure => directory,
  }
  file { "${_confdir}/messagebeans/enzmeta.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/dhrep/messagebeans/enzmeta.properties.erb'),
  }
  file { "${_confdir}/messagebeans/bolrfd.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/dhrep/messagebeans/bolrdf.properties.erb'),
  }
  # symlink to old config path
  file { '/etc/textgrid/messagebeans':
    ensure => link,
    target => "${_confdir}/messagebeans/",
  }   
}
