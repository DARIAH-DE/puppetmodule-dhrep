# == Class: dhrep::services::crud_public
#
# Class to install and configure dhcrud-public or tgcrud-public
#
class dhrep::services::crud_public (
  $scope            = undef,
  $short            = 'tgcrud-public',
  $crud_name        = 'tgcrud-webapp-public',
  $crud_version     = 'latest',
  $use_messaging    = true,
  $publish_secret   = undef,
) inherits dhrep::params {

  include dhrep::services::intern::javagat
  include dhrep::services::tomcat_crud
  include dhrep::services::tomcat_publish

  $catname = $dhrep::services::tomcat_publish::catname
  $user    = $dhrep::services::tomcat_publish::user
  $group   = $dhrep::services::tomcat_publish::group

  package { $crud_name:
    ensure  => $crud_version,
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

  file { "/etc/${scope}/${short}/tgcrud.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/tgcrud.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/etc/${scope}/${short}/beans.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/beans.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  ###
  # logging
  ###

  file { "/etc/${scope}/${short}/tgcrud.log4j":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/tgcrud.log4j.erb"),
    require => File["/etc/${scope}/${short}"],
  }

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

  # symlink war from deb package to tomcat webapps dir
  file { "/home/${user}/${catname}/webapps/${short}.war": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/${short}.war",
#    notify  => Service[$catname],
    require => [File[ "/etc/${scope}/${short}/beans.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

}
