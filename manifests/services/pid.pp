# == Class: dhrep::services::pid
#
# Class to install and configure pid service.
#
class dhrep::services::pid (
  $scope          = undef,
  $endpoint       = 'http://pid.gwdg.de',
  $path           = '/handles/',
  $prefix         = undef,
  $user           = undef,
  $passwd         = undef,
  $responsible    = '',
  $creator        = '',
  $secret         = undef,
  $doi_prefix     = '',
  $doi_endpoint   = '',
  $doi_user       = '',
  $doi_passwd     = '',
  $doi_target_url = '',
  $doi_publisher  = '',
) inherits dhrep::params {

  include dhrep::services::tomcat_pid

  $_name    = $::dhrep::params::pid_name[$scope]
  $_short   = $::dhrep::params::pid_short[$scope]
  $_version = $::dhrep::params::pid_version[$scope]
  $_confdir = $::dhrep::params::confdir
  $_vardir  = $::dhrep::params::vardir
  $_logdir  = $::dhrep::params::logdir
  $_aptdir  = $::dhrep::params::aptdir
  $_catname = $::dhrep::services::tomcat_pid::catname

  $templates = "dhrep/etc/dhrep/pid/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'],Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/${_short}":
    ensure  => link,
    target  => "${_aptdir}/pid",
    require => [File["${_confdir}/${_short}/pid.properties"],Usertomcat::Instance[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/${_short}":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/${_short}/pid.properties":
    ensure  => file,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0640',
    content => template("${templates}/pid.properties.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }

  ###
  # logging
  ###
  file { "${_logdir}/${_short}":
    ensure  => directory,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0755',
    require => File[$_logdir],
  }
  logrotate::rule { 'pid':
    path         => "${_logdir}/${_short}/pid.log",
    require      => File["${_logdir}/${_short}"],
    rotate       => 30,
    rotate_every => 'day',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d',
  }
}
