# == Class: dhrep::services::crud_public
#
# Class to install and configure public crud service.
#
class dhrep::services::crud_public (
  $scope          = undef,
  $publish_secret = undef,
  $log_level      = 'INFO',
  $use_messaging  = true,
  $location       = '',
  $storage_host   = 'https://de.dariah.eu/storage/',
  $storage_user   = '',
  $storage_pw     = '',
  $pid_resolver   = 'https://hdl.handle.net',
  $extract_techmd = false,
  $pid_secret     = '',
) inherits dhrep::params {

  if $scope == 'textgrid' {
    include dhrep::services::intern::javagat
  }
  include dhrep::services::tomcat_crud

  $_name    = $::dhrep::params::crud_public_name[$scope]
  $_short   = $::dhrep::params::crud_public_short[$scope]
  $_version = $::dhrep::params::crud_public_version[$scope]
  $_aptdir  = $::dhrep::params::aptdir
  $_confdir = $::dhrep::params::confdir
  $_logdir  = $::dhrep::params::logdir
  $_optdir  = $::dhrep::params::optdir
  $_catname = $::dhrep::services::tomcat_crud::catname
  $_user    = $::dhrep::services::tomcat_crud::user
  $_group   = $::dhrep::services::tomcat_crud::group

  $templates = "dhrep/etc/dhrep/crud-public/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  # symlink war from deb package to tomcat webapps dir
  file { "/home/${_user}/${_catname}/webapps/${_short}":
    ensure  => 'link',
    target  => "${_aptdir}/${_short}",
    require => [File[ "${_confdir}/${_short}/beans.properties"],Dhrep::Resources::Servicetomcat[$_catname]],
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
  file { "${_confdir}/${_short}/crud.properties":
    ensure  => present,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/crud.properties.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/beans.properties":
    ensure  => present,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/beans.properties.erb"),
    require => File["${_confdir}/${_short}"],
  }

  ###
  # logging
  ###
  file { "${_confdir}/${_short}/crud.log4j":
    ensure  => present,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/crud.log4j.erb"),
    require => File["${_confdir}/${_short}"],
  }
  file { "${_logdir}/${_short}":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_logdir],
  }
  logrotate::rule { $_short:
    path         => "${_logdir}/${_short}/crud.log",
    require      => File["${_logdir}/${_short}"],
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
  # scope: textgrid
  ###
  if $scope == 'textgrid' {

    ###
    # cron for crud comment (scripts creation see crud.pp!) and analyse
    ###
    cron { 'crud-public-analyse':
      command => "${_optdir}/crud-analyse.pl -l ${_logdir}/${_short}/rollback.log -c ${_logdir}/${_short}/logcomments.log > /dev/null",
      user    => $_user,
      minute  => '2-59/5',
    }

    ###
    # nrpe for tgcrud_public
    ###
    dariahcommon::nagios_service { 'check_rollback_tgcrud_public':
      command => "${_optdir}/crud-analyse.pl -n -l ${_logdir}/${_short}/rollback.log",
    }
  }
}
