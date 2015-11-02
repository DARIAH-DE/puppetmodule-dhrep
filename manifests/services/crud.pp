# == Class: dhrep::services::crud
#
# Class to install and configure tgcrud/dhcrud
#
class dhrep::services::crud (
  $scope            = undef,
  $short            = 'tgcrud',
  $crud_name        = 'tgcrud-webapp',
  $crud_version     = '5.9.205-SNAPSHOT',
  $crud_group       = 'info.textgrid.middleware',
  $use_messaging    = true,
  $publish_secret   = undef,
  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/snapshots/',
) inherits dhrep::params {

  include dhrep::services::intern::javagat
  include dhrep::services::tomcat_crud

  $catname = $dhrep::services::tomcat_crud::catname
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

  file { "/etc/${scope}/${short}/${short}.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/${short}.properties.erb"),
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

  file { "/etc/${scope}/${short}/${short}.log4j":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/${short}.log4j.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${scope}"],
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
    notify     => Exec['replace_crud_service'],
  }

  exec { 'replace_crud_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${scope}/${catname}/webapps/${short} && sleep 2 && cp /var/cache/${scope}/${crud_name}-${crud_version}.war /home/${scope}/${catname}/webapps/${short}.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file {"/home/${scope}/${catname}/webapps/${short}.war":
    group   => $group,
    mode    => '0640',
    notify  => Service[$catname],
    require => File["/etc/${scope}/${short}/beans.properties"],
  }

}
