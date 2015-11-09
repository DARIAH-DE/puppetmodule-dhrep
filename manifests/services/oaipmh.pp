# == Class: dhrep::services::oaipmh
#
# Class to install and configure oaipmh
#
class dhrep::services::oaipmh (
  $scope            = undef,
  $short            = 'tgoaipmh',
  $oaipmh_name      = 'oaipmh-webapp',
  $oaipmh_version   = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_oaipmh

  $catname = $dhrep::services::tomcat_oaipmh::catname
  $user    = $dhrep::services::tomcat_oaipmh::user
  $group   = $dhrep::services::tomcat_oaipmh::group

  package { $oaipmh_name:
    ensure  => $oaipmh_version,
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

  file { "/etc/${scope}/${short}/oaipmh.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/oaipmh.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  ###
  # logging
  ###

  file { "/etc/${scope}/${short}/log4j.oaipmh.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/log4j.oaipmh.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => root,
    group   => $group,
    mode    => '0775',
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

  # symlink war from deb package to tomcat webapps dir
  file { "/home/${user}/${catname}/webapps/${short}.war": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/${short}.war",
#    notify  => Service[$catname],
    require => [File["/etc/${scope}/${short}/oaipmh.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

}
