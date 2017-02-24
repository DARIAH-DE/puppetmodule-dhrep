# == Class: dhrep::services::oaipmh
#
# Class to install and configure oaipmh service
#
class dhrep::services::oaipmh (
  $scope   = undef,
) inherits dhrep::params {

  include dhrep::services::tomcat_oaipmh

  $_name    = $::dhrep::params::oaipmh_name[$scope]
  $_version = $::dhrep::params::oaipmh_version[$scope]
  $_confdir = $::dhrep::params::confdir
  $_vardir  = $::dhrep::params::vardir
  $_logdir  = $::dhrep::params::logdir
  $_aptdir  = $::dhrep::params::aptdir
  $_catname = $::dhrep::services::tomcat_oaipmh::catname
  $_user    = $::dhrep::services::tomcat_oaipmh::user
  $_group   = $::dhrep::services::tomcat_oaipmh::group

  $templates = "dhrep/etc/dhrep/oaipmh/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'],Usertomcat::Create[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/oaipmh":
    ensure  => 'link',
    target  => "${_aptdir}/oaipmh",
    require => [File["${_confdir}/oaipmh/oaipmh.properties"],Usertomcat::Create[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/oaipmh":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/oaipmh/oaipmh.properties":
    ensure  => present,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/oaipmh.properties.erb"),
    require => File["${_confdir}/oaipmh"],
    notify  => Service[$_catname],
  }

  ###
  # logging
  ###
  file { "${_confdir}/oaipmh/log4j.oaipmh.properties":
    ensure  => present,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/log4j.properties.erb"),
    require => File["${_confdir}/oaipmh"],
  }
  file { "${_logdir}/oaipmh":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_logdir],
  }
  logrotate::rule { 'oaipmh':
    path         => "${_vardir}/oaipmh/oaipmh.log",
    require      => File["${_logdir}/oaipmh"],
    rotate       => 30,
    rotate_every => 'day',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }
}
