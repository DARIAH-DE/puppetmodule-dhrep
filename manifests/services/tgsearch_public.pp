# == Class: dhrep::services::tgsearch_public
#
# Class to install and configure tgsearch public.
#
class dhrep::services::tgsearch_public (
  $short            = 'tgsearch-public',
  $tgsearch_name    = 'tgsearch-public-webapp',
  $tgsearch_version = '3.4.0-SNAPSHOT',
  $tgsearch_group   = 'info.textgrid.middleware',
  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/snapshots/',
) {

  include dhrep::services::tomcat_tgsearch

  $catname = $dhrep::services::tomcat_tgsearch::catname
  $user    = $dhrep::services::tomcat_tgsearch::user
  $group   = $dhrep::services::tomcat_tgsearch::group

  ###
  # config
  ###

  file { "/etc/textgrid/${short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/textgrid/${short}/tgsearch-public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/tgsearch.properties.erb"),
    require => File["/etc/textgrid/${short}"],
  }

  file { "/etc/textgrid/${short}/log4..public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/log4j.properties.erb"),
    require => File["/etc/textgrid/${short}"],
  }

  ###
  # use maven to fetch latest tgsearch service from nexus, copy war, set permissions,
  # and restart tomcat tgsearch.
  ###

  maven { "/var/cache/textgrid/${tgsearch_name}-${tgsearch_version}.war":
    ensure     => latest,
    groupid    => $tgsearch_group,
    artifactid => $tgsearch_name,
    version    => $tgsearch_version,
    packaging  => 'war',
    repos      => $maven_repository,
    require    => Package['maven'],
    notify     => Exec['replace_tgsearch_service_public'],
  }

  exec { 'replace_tgsearch_service_public':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${catname}/${catname}/webapps/${short} && sleep 2 && cp /var/cache/textgrid/${tgsearch_name}-${tgsearch_version}.war /home/${catname}/${catname}/webapps/${short}.war",
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

}
