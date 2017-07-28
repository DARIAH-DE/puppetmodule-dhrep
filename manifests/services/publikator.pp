# == Class: dhrep::services::publikator
#
# Class to install and configure THE PUBLIKATOR service.
#
class dhrep::services::publikator (
  $scope = undef,
) inherits dhrep::params {

  include dhrep::services::tomcat_publikator

  $_name     = $::dhrep::params::publikator_name[$scope]
  $_version  = $::dhrep::params::publikator_version[$scope]
  $_confdir  = $::dhrep::params::confdir
  $_logdir   = $::dhrep::params::logdir
  $_optdir   = $::dhrep::params::optdir
  $_catname  = $::dhrep::params::config['tomcat_publikator']['catname']
  $_aptdir   = $::dhrep::params::aptdir

  $templates = "dhrep/etc/dhrep/publikator/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'], Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/publikator":
    ensure  => 'link',
    target  => "${_aptdir}/publikator",
    require => [File["${_confdir}/publikator/web.xml"], Usertomcat::Instance[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/publikator":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/publikator/web.xml":
    ensure  => file,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0640',
    content => template("${templates}/web.xml.erb"),
    require => File["${_confdir}/publikator"],
    notify  => Service[$_catname],
  }

  ###
  # logging
  ###
#  file { "${_confdir}/${_short}/crud.log4j":
#    ensure  => file,
#    owner   => $_user,
#    group   => $_group,
#    mode    => '0640',
#    content => template("${templates}/crud.log4j.erb"),
#    require => File["${_confdir}/${_short}"],
#  }
#  file { "${_logdir}/${_short}":
#    ensure  => directory,
#    owner   => $_user,
#    group   => $_group,
#    mode    => '0755',
#    require => File[$_logdir],
#  }
#  logrotate::rule { $_short:
#    path         => "${_logdir}/${_short}/crud.log",
#    require      => File["${_logdir}/${_short}"],
#    rotate       => 30,
#    rotate_every => 'day',
#    compress     => true,
#    copytruncate => true,
#    missingok    => true,
#    ifempty      => true,
#    dateext      => true,
#    dateformat   => '.%Y-%m-%d',
#  }
}
