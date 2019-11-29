# == Class: dhrep::services::intern::messaging
#
# === Description
#
# Configuration of the enzmeta, bolrdf, and DARIAH-DE Repository messaging using Wildfly (please see wildfly.pp).
#
# FIXME: Are the user and password settings still in use?
#
# FIXME: Can we put these into the wildfly.pp class?
#
# === Parameters
#
# [*scope*]
#   textgrid or dariah
#
# [*enzmeta_textgrid_user*]
#   the enzmeta_textgrid_user (?)
#
# [*enzmeta_textgrid_password*]
#   the enzmeta_textgrid_password (?)
#
# [*bolrdf_textgrid_user*]
#   the bolrdf_textgrid_user (?)
#
class dhrep::services::intern::messaging (
  $scope                     = undef,
  $enzmeta_textgrid_user     = 'enzmeta-tguser',
  $enzmeta_textgrid_password = 'enzmeta-tgpass',
  $bolrdf_textgrid_user      = 'bolrdf-tguser',
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
  file { "${_confdir}/messagebeans/dhmb.properties":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/dhrep/messagebeans/dhmb.properties.erb'),
  }
}
