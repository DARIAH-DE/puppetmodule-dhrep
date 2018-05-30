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

  file { "${_confdir}/messagebeans":
    ensure => directory,
  }
  file { "${_confdir}/messagebeans/enzmeta.properties":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/dhrep/messagebeans/enzmeta.properties.erb'),
  }
  file { "${_confdir}/messagebeans/bolrfd.properties":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/dhrep/messagebeans/bolrdf.properties.erb'),
  }
  # symlink to old config path
<<<<<<< HEAD
#  file { '/etc/textgrid/messagebeans':
#    ensure => link,
#    target => "${_confdir}/messagebeans/",
#  }
=======
  file { '/etc/textgrid/messagebeans':
    ensure => link,
    target => "${_confdir}/messagebeans/",
  }
>>>>>>> master
}
