# == Class: textgrid::services::crud_public
#
# Class to install and configure dhcrud-public or tgcrud-public
#
class textgrid::services::crud_public (
  $crud_scope     = 'textgrid',
  $crud_short     = 'tgcrud-public',
  $crud_name      = 'tgcrud-webapp-public',
  $crud_version   = '5.9.152-SNAPSHOT',
  $crud_group     = 'info.textgrid.middleware',
  $use_messaging  = 'false',
  $publish_secret = '',
){

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::intern::sesame
  include textgrid::services::intern::tgnoid
  include textgrid::services::intern::javagat
  include textgrid::services::tgauth
  include textgrid::services::tomcat_crud
  include textgrid::services::tomcat_publish

  $catname = $textgrid::services::tomcat_publish::catname
  $user    = $textgrid::services::tomcat_publish::user
  $group   = $textgrid::services::tomcat_publish::group

  ###
  # config
  ###

  file { "/etc/${crud_scope}/${crud_short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${crud_scope}/${crud_short}/tgcrud.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${crud_scope}/etc/${crud_scope}/${crud_short}/tgcrud.properties.erb"),
    require => File["/etc/${crud_scope}/${crud_short}"],
  }

  file { "/etc/${crud_scope}/${crud_short}/beans.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${crud_scope}/etc/${crud_scope}/${crud_short}/beans.properties.erb"),
    require => File["/etc/${crud_scope}/${crud_short}"],
  }
  ->

  ###
  # use maven to fetch latest crud service from nexus, copy war, set permissions,
  # and restart tomcat
  ###

  maven { "/var/cache/${crud_scope}/${crud_name}-${crud_version}.war":
    ensure     => latest,
    groupid    => $crud_group,
    artifactid => $crud_name,
    version    => $crud_version,
    packaging  => 'war',
    repos      => ["http://dev.dariah.eu/nexus/content/repositories/snapshots/"],
    require    => Package['maven'],
    notify     => Exec['replace_crud_public_service'],
  }
  ->
  exec { 'replace_crud_public_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${crud_scope}/${catname}/webapps/${crud_short} && sleep 2 && cp /var/cache/${crud_scope}/${crud_name}-${crud_version}.war /home/${crud_scope}/${catname}/webapps/${crud_short}.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file { "/home/${crud_scope}/${catname}/webapps/${crud_short}.war":
    group  => $group,
    mode   => '0640',
    notify => Service[$catname],
  }

  ###
  # logging
  ###

  file { "/etc/${crud_scope}/${crud_short}/tgcrud.log4j":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${crud_scope}/etc/${crud_scope}/${crud_short}/tgcrud.log4j.erb"),
    require => File["/etc/${crud_scope}/${crud_short}"],
  }

  file { "/var/log/${crud_scope}/${crud_short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${crud_scope}"],
  }

}
