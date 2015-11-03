# == Class: dhrep::services::crud_public
#
# Class to install and configure dhcrud-public or tgcrud-public
#
class dhrep::services::crud_public (
  $scope            = undef,
  $short            = 'tgcrud-public',
  $crud_name        = 'tgcrud-webapp-public',
  $crud_version     = '5.9.205-SNAPSHOT',
  $crud_group       = 'info.textgrid.middleware',
  $use_messaging    = true,
  $publish_secret   = undef,
  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/snapshots/',
) inherits dhrep::params {

  include dhrep::services::intern::javagat
  include dhrep::services::tomcat_crud
  include dhrep::services::tomcat_publish

  $catname = $dhrep::services::tomcat_publish::catname
  $user    = 'storage'
  $group   = 'storage'

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

  ###
  # use maven to fetch latest crud service from nexus, copy war, set permissions,
  # and restart tomcat
  ###

  maven { "/var/cache/${scope}/${crud_name}-${crud_version}.war":
    ensure     => latest,
    groupid    => $crud_group,
    artifactid => $crud_name,
    version    => $crud_version,
    packaging  => 'war',
    repos      => $maven_repository,
    require    => Package['maven'],
    notify     => Exec['replace_crud_public_service'],
  }

  exec { 'replace_crud_public_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${scope}/${catname}/webapps/${short} && sleep 2 && cp /var/cache/${scope}/${crud_name}-${crud_version}.war /home/${scope}/${catname}/webapps/${short}.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file { "/home/${scope}/${catname}/webapps/${short}.war":
    group   => $group,
    mode    => '0640',
    notify  => Service[$catname],
    require => File[ "/etc/${scope}/${short}/beans.properties"],
  }

}
