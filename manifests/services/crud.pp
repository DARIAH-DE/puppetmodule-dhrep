# == Class: dhrep::services::crud
#
# Class to install and configure non-public crud service.
#
class dhrep::services::crud (
  $scope               = undef,
  $publish_secret      = undef,
  $log_level           = 'INFO',
  $use_messaging       = true,
  $location            = '',
  $storage_host        = '',
  $storage_host_public = '',
  $pid_resolver        = 'https://hdl.handle.net/',
  $extract_techmd      = false,
  $pid_secret          = '',
) inherits dhrep::params {

  if $scope == 'textgrid' {
    include dhrep::services::intern::javagat
  }

  $_name    = $::dhrep::params::crud_name[$scope]
  $_short   = $::dhrep::params::crud_short[$scope]
  $_version = $::dhrep::params::crud_version[$scope]
  $_confdir = $::dhrep::params::confdir
  $_logdir  = $::dhrep::params::logdir
  $_optdir  = $::dhrep::params::optdir
  $_catname = $::dhrep::params::config['tomcat_crud']['catname']
  $_user    = $::dhrep::params::config['tomcat_crud']['user']
  $_group   = $::dhrep::params::config['tomcat_crud']['group']
  $_aptdir  = $::dhrep::params::aptdir
 
  # FIXME remove if textgrid services finally are deployed to /var/dhrep/webapps!
#  if $scope == 'textgrid' {
#    $_aptdir = '/var/textgrid/webapps'
#  }
#  else {
#    $_aptdir = $::dhrep::params::aptdir
#  }

  $templates = "dhrep/etc/dhrep/crud/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'], Usertomcat::Create[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/${_short}":
    ensure  => 'link',
    target  => "${_aptdir}/${_short}",
    require => [File["${_confdir}/${_short}/beans.properties"], Usertomcat::Create[$_catname]],
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
    dateformat   => '.%Y-%m-%d',
  }

  ###
  # scope: textgrid
  ###
  if $scope == 'textgrid' {

    ###
    # tgcrud comment and analyse scrpits
    ###
    file { "${_optdir}/crud-analyse.pl":
      source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/crud-analyse.pl",
      owner   => $_user,
      group   => $_group,
      mode    => '0755',
      require => File[$_optdir],
    }
    file { "${_optdir}/crud-comment.pl":
      source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/crud-comment.pl",
      owner   => $_user,
      group   => $_group,
      mode    => '0700',
      require => [File[$_optdir],File["${_optdir}/crud-analyse.pl"]],
    }

    ###
    # cron for tgcrud comment and analyse
    ###
    cron { 'crud-comment':
      command => "${_optdir}/crud-comment.pl > /dev/null",
      user    => $_user,
      hour    => 4,
      minute  => 3,
      require => File["${_optdir}/crud-comment.pl"],
    }
    cron { 'crud-analyse':
      command => "${_optdir}/crud-analyse.pl -l ${_logdir}/${_short}/rollback.log -c ${_logdir}/${_short}/logcomments.log &> /dev/null",
      user    => $_user,
      minute  => '*/5',
      require => File["${_optdir}/crud-analyse.pl"],
    }

    ###
    # nrpe for tgcrud
    ###
    nrpe::plugin { 'check_rollback_tgcrud':
      plugin => 'crud-analyse.pl',
      args   => "-n -l ${_logdir}/${_short}/rollback.log",
      libexecdir => $_optdir,
    }
  }
}
