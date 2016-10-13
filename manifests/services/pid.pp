# == Class: dhrep::services::pid
#
# Class to install and configure pid service.
#
class dhrep::services::pid (
  $scope       = undef,
  $name        = 'pid-webapp',
  $version     = 'latest',
  $endpoint    = 'http://pid.gwdg.de',
  $path        = '/handles/',
  $user        = undef,
  $passwd      = undef,
  $prefix      = undef,
  $responsible = 'TextGrid',
) inherits dhrep::params {

  $_confdir  = $::dhrep::params::confdir
  $_vardir   = $::dhrep::params::vardir
  $_logdir   = $::dhrep::params::logdir
  $_catname  = $::dhrep::services::tomcat_publish::catname
  $_user     = $::dhrep::services::tomcat_publish::user
  $_group    = $::dhrep::services::tomcat_publish::group

  $templates = "dhrep/etc/dhrep/pid/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $name:
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/pid":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { "${_confdir}/pid/pid.properties":
    ensure  => present,
    owner   => root,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/pid/pid.properties.erb"),
    require => File["${_confdir}/pid"],
    notify  => Service[$_catname],
  }

  ###
  # logging
  ###
  file { "${_logdir}/pid":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_logdir],
  }
  logrotate::rule { 'pid':
    path         => "${_logdir}/pid/pid.log",
    require      => File["${_logdir}/pid"],
    rotate       => 30,
    rotate_every => 'day',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/pid":
    ensure => 'link',
    target => "/var/dhrep/webapps/pid",
    require => [File["${_confdir}/pid/pid.properties"],Dhrep::Resources::Servicetomcat[$_catname]],
  }
}
