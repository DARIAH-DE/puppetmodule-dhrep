# == Class: dhrep::services::publish
#
# Class to install and configure dhpublish and/or tgpublish.
#
class dhrep::services::publish (
  $publish_scope    = undef,
  $publish_short    = 'tgpublish',
  $publish_name     = 'kolibri-tgpublish-service',
  $publish_version  = '3.7.13-SNAPSHOT',
  $publish_group    = 'de.langzeitarchivierung.kolibri',
  $fake_pids        = false,
  $maven_repository = 'http://dev.dariah.eu/nexus/content/repositories/snapshots/',
){

  $catname = $dhrep::services::tomcat_publish::catname
  $user    = $dhrep::services::tomcat_publish::user
  $group   = $dhrep::services::tomcat_publish::group

  ###
  # config
  ###

  file { "/etc/${publish_scope}/${publish_short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  
  file { "/etc/${publish_scope}/${publish_short}/conf":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${publish_scope}/${publish_short}"],
  }

  file { "/etc/${publish_scope}/${publish_short}/conf/config.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${publish_scope}/etc/${publish_scope}/${publish_short}/conf/config.xml.erb"),
    require => File["/etc/${publish_scope}/${publish_short}/conf"],
  }

  file { "/etc/${publish_scope}/${publish_short}/conf/beans.properties.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${publish_scope}/etc/${publish_scope}/${publish_short}/conf/beans.properties.erb"),
    require => File["/etc/${publish_scope}/${publish_short}/conf"],
  }
  
  file { "/etc/${publish_scope}/${publish_short}/conf/policies.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${publish_scope}/etc/${publish_scope}/${publish_short}/conf/policies.xml.erb"),
    require => File["/etc/${publish_scope}/${publish_short}/conf"],
  }

  file { "/etc/${publish_scope}/${publish_short}/conf/mets_template.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${publish_scope}/etc/${publish_scope}/${publish_short}/conf/mets_template.xml.erb"),
    require => File["/etc/${publish_scope}/${publish_short}/conf"],
  }

  file { "/etc/${publish_scope}/${publish_short}/conf/map_dias2jhove.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${publish_scope}/etc/${publish_scope}/${publish_short}/conf/map_dias2jhove.xml.erb"),
    require => File["/etc/${publish_scope}/${publish_short}/conf"],
  }

  file { "/etc/${publish_scope}/${publish_short}/conf/dias_formatregistry.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("${publish_scope}/etc/${publish_scope}/${publish_short}/conf/dias_formatregistry.xml.erb"),
    require => File["/etc/${publish_scope}/${publish_short}/conf"],
  }

  ###
  # temp dir
  ###

  file { "/etc/${publish_scope}/${publish_short}/temp":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${publish_scope}/${publish_short}"],
  }

  ###
  # dest dir
  ###

  file { "/etc/${publish_scope}/${publish_short}/dest":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${publish_scope}/${publish_short}"],
  }

  ###
  # work dir
  ###

  file { "/etc/${publish_scope}/${publish_short}/work":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${publish_scope}/${publish_short}"],
  }

  ###
  # logging
  ###

  file { "/var/log/${publish_scope}/${publish_short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${publish_scope}"],
  }

  ###
  # use maven to fetch latest publish service from nexus, copy war, set permissions,
  # and restart tomcat
  ###

  maven { "/var/cache/${publish_scope}/${publish_name}-${publish_version}.war":
    ensure     => latest,
    groupid    => $publish_group,
    artifactid => $publish_name,
    version    => $publish_version,
    packaging  => 'war',
    repos      => $maven_repository,
    require    => Package['maven'],
    notify     => Exec['replace_publish_service'],
  }

  exec { 'replace_publish_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${publish_scope}/${catname}/webapps/${publish_short} && sleep 2 && cp /var/cache/${publish_scope}/${publish_name}-${publish_version}.war /home/${publish_scope}/${catname}/webapps/${publish_short}.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file {"/home/${publish_scope}/${catname}/webapps/${publish_short}.war":
    group   => $group,
    mode    => '0640',
    notify  => Service[$catname],
    require => File["/etc/${publish_scope}/${publish_short}/conf/beans.properties.xml"],
  }

}
