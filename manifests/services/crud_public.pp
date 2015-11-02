# == Class: dhrep::services::crud_public
#
# Class to install and configure dhcrud-public or tgcrud-public
#
class dhrep::services::crud_public (
  $scope            = undef,
  $short            = 'tgcrud-public',
  $crud_name        = 'tgcrud-webapp-public',
  $crud_version     = '5.9.152-SNAPSHOT',
  $crud_group       = 'info.textgrid.middleware',
  $use_messaging    = false,
  $publish_secret   = '',
  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/snapshots/',
){

  include dhrep::services::intern::tgelasticsearch
  include dhrep::services::intern::sesame
  include dhrep::services::intern::tgnoid
  include dhrep::services::intern::javagat
  include dhrep::services::tgauth
  include dhrep::services::tomcat_crud
  include dhrep::services::tomcat_publish

  $catname = $dhrep::services::tomcat_publish::catname
  $user    = $dhrep::services::tomcat_publish::user
  $group   = $dhrep::services::tomcat_publish::group

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
    content => template("${scope}/etc/${scope}/${short}/tgcrud.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/etc/${scope}/${short}/beans.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${scope}/etc/${scope}/${short}/beans.properties.erb"),
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
    content => template("${scope}/etc/${scope}/${short}/tgcrud.log4j.erb"),
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
