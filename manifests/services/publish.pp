# == Class: dhrep::services::publish
#
# Class to install and configure publish service.
#
class dhrep::services::publish (
  $scope        = undef,
  $log_level    = 'INFO',
  $fake_pids    = false,
  $pid_secret   = '',
  $storage_host = 'https://de.dariah.eu/storage/'
) inherits dhrep::params {

  include dhrep::services::tomcat_publish

  $_name    = $::dhrep::params::publish_name[$scope]
  $_short   = $::dhrep::params::publish_short[$scope]
  $_version = $::dhrep::params::publish_version[$scope]
  $_confdir = $::dhrep::params::confdir
  $_logdir  = $::dhrep::params::logdir
  $_catname = $::dhrep::services::tomcat_publish::catname
  $_user    = $::dhrep::services::tomcat_publish::user
  $_group   = $::dhrep::services::tomcat_publish::group

  # FIXME remove if textgrid services finally are deployed to /var/dhrep/webapps!
  if $scope == 'textgrid' {
    $_aptdir = '/var/textgrid/webapps'
  }
  else {
    $_aptdir = $::dhrep::params::aptdir
  }

  $templates = "dhrep/etc/dhrep/publish"

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
  file { "/home/${_user}/${_catname}/webapps/${_short}":
    ensure  => 'link',
    target  => "${_aptdir}/${_short}",
    require => [File["${_confdir}/${_short}/beans.properties"],Usertomcat::Create[$_catname]],
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
  file { "${_confdir}/${_short}/config.xml":
    ensure  => present,
    owner   => $_user,
    group   => $_group,
    mode    => '0640',
    content => template("${templates}/${scope}/config.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/beans.properties":
    ensure  => present,
    owner   => $_user,
    group   => $group,
    mode    => '0640',
    content => template("${templates}/${scope}/beans.properties.erb"),
    require => File["${_confdir}/${_short}"],
  }
  file { "${_confdir}/${_short}/policies.xml":
    ensure  => present,
    owner   => $_user,
    group   => $group,
    mode    => '0640',
    content => template("${templates}/${scope}/policies.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/mets_template.xml":
    ensure  => present,
    owner   => $_user,
    group   => $group,
    mode    => '0640',
    content => template("${templates}/mets_template.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/map_dias2jhove.xml":
    ensure  => present,
    owner   => $_user,
    group   => $group,
    mode    => '0640',
    content => template("${templates}/map_dias2jhove.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/${_short}/dias_formatregistry.xml":
    ensure  => present,
    owner   => $_user,
    group   => $group,
    mode    => '0640',
    content => template("${templates}/dias_formatregistry.xml.erb"),
    require => File["${_confdir}/${_short}"],
    notify  => Service[$_catname],
  }

  ###
  # temp, dest, and work dir
  ###
  file { "${_confdir}/${_short}/temp":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/${_short}"],
  }
  file { "${_confdir}/${_short}/dest":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/${_short}"],
  }
  file { "${_confdir}/${_short}/work":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/${_short}"],
  }

  ###
  # logging
  ###
  file { "${_logdir}/${_short}":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_logdir],
  }

  logrotate::rule { $_short:
    path         => "${_logdir}/${_short}/publish.log",
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
    # add elasticsearch script for removing nearly publish flag from elasticsearch
    ###
    file { '/etc/elasticsearch/masternode/scripts/removeNearlyPublishFlag.groovy':
      ensure  => present,
      owner   => 'elasticsearch',
      group   => 'elasticsearch',
      mode    => '0640',
      source  => 'puppet:///modules/dhrep/etc/elasticsearch/masternode/scripts/removeNearlyPublishFlag.groovy',
      require => File['/etc/elasticsearch/masternode/scripts/'],
      notify  => Service[$_catname],
    }
  }
}
