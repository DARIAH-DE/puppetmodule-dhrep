# == Class: textgrid::services::oaipmh
#
# Class to install and configure oaipmh
#
class textgrid::services::oaipmh (
  $scope          = 'textgrid',
  $short          = 'tgoaipmh',
  $oaipmh_name    = 'oaipmh-webapp',
  $oaipmh_version = '1.3.20-SNAPSHOT',
  $oaipmh_group   = 'info.textgrid.middleware',
){

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::tomcat_oaipmh

  $catname = $textgrid::services::tomcat_oaipmh::catname
  $user    = $textgrid::services::tomcat_oaipmh::user
  $group   = $textgrid::services::tomcat_oaipmh::group

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
    content => template("${scope}/etc/${scope}/${short}/oaipmh.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }
  ->

  ###
  # use maven to fetch latest oaipmh service from nexus, copy war, set permissions,
  # and restart tomcat
  ###
  maven { "/var/cache/${scope}/${oaipmh_name}-${oaipmh_version}.war":
    ensure     => latest,
    groupid    => $oaipmh_group,
    artifactid => $oaipmh_name,
    version    => $oaipmh_version,
    packaging  => 'war',
    repos      => ['http://dev.dariah.eu/nexus/content/repositories/snapshots/'],
    require    => Package['maven'],
    notify     => Exec['replace_oaipmh_service'],
  }
  ->
  exec { 'replace_oaipmh_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${catname}/${catname}/webapps/oaipmh && sleep 2 && cp /var/cache/${scope}/${oaipmh_name}-${oaipmh_version}.war /home/${catname}/${catname}/webapps/${short}.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file { "/home/${catname}/${catname}/webapps/${short}.war":
    group  => $group,
    mode   => '0640',
    notify => Service[$catname],
  }

  ###
  # logging
  ###

  file { "/etc/${scope}/${short}/log4j.oaipmh.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${scope}/etc/${scope}/${short}/log4j.oaipmh.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => root,
    group   => $group,
    mode    => '0775',
    require => File["/var/log/${scope}"],
  }

}
