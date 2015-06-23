# == Class: textgrid::services::tgsearch_public
#
# Class to install and configure tgsearch public.
#
class textgrid::services::tgsearch_public (
  $short                = 'tgsearch',
  $tgsearch_name        = 'tgsearch-public-webapp',
  $tgsearch_version     = '3.4.0-SNAPSHOT',
  $tgsearch_group       = 'info.textgrid.middleware',
) {

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::tomcat_tgsearch

  $catname = $textgrid::services::tomcat_tgsearch::catname
  $user    = $textgrid::services::tomcat_tgsearch::user
  $group   = $textgrid::services::tomcat_tgsearch::group

  ###
  # config
  ###

  file { "/etc/textgrid/${short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/textgrid/${short}/${short}-public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("textgrid/etc/textgrid/${short}/${short}-public.properties.erb"),
  }

  file { "/etc/textgrid/${short}/log4j.public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("textgrid/etc/textgrid/${short}/log4j.public.properties.erb"),
  }

  ###
  # use maven to fetch latest tgsearch service from nexus, copy war, set permissions,
  # and restart tomcat (tgsearch-public and tgsearch-nonpublic)
  ###

  maven { "/var/cache/textgrid/${tgsearch_name_public}-${tgsearch_version}.war":
    ensure     => latest,
    groupid    => $tgsearch_group,
    artifactid => $tgsearch_name,
    version    => $tgsearch_version,
    packaging  => 'war',
    repos      => ['http://dev.dariah.eu/nexus/content/repositories/snapshots/'],
    require    => Package['maven'],
    notify     => Exec['replace_tgsearch_service_public'],
  }

  exec { 'replace_tgsearch_service_public':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${catname}/${catname}/webapps/${short}-public && sleep 2 && cp /var/cache/textgrid/${tgsearch_name_public}-${tgsearch_version}.war /home/${catname}/${catname}/webapps/${short}-public.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file { "/home/${catname}/${catname}/webapps/${short}-public.war":
    group  => $group,
    mode   => '0640',
  }

}
