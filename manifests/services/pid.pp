# == Class: dhrep::services::pid
#
# Class to install and configure dhpid or tgpid.
#
class dhrep::services::pid (
  $scope            = undef,
  $short            = 'pid',
  $pid_name         = 'pid-webapp',
  $pid_version      = 'latest',
  $pid_user         = '',
  $pid_passwd       = '',
  $pid_endpoint     = 'http://pid.gwdg.de',
  $pid_path         = '/handles/',
  $pid_prefix       = '',
  $pid_responsible  = 'TextGrid',
){

  $catname = $dhrep::services::tomcat_publish::catname
  $user    = $dhrep::services::tomcat_publish::user
  $group   = $dhrep::services::tomcat_publish::group

  package { $pid_name:
    ensure  => $pid_version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { "/etc/${scope}/${short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${scope}/${short}/${short}.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/${short}.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  ###
  # logging
  ###

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${scope}"],
  }

  logrotate::rule { $short:
    path         => "/var/log/${scope}/${short}/${short}.log",
    require      => File["/var/log/${scope}/${short}"],
    rotate       => 365,
    rotate_every => 'week',
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

  file { "/home/${user}/${catname}/webapps/${short}": 
    ensure => 'link',
    target => "/var/dhrep/webapps/${short}",
    require => [File["/etc/${scope}/${short}/${short}.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

}
