# == Class: dhrep::services::publish
#
# Class to install and configure dhpublish and/or tgpublish.
#
class dhrep::services::publish (
  $scope            = undef,
  $publish_short    = 'tgpublish',
  $publish_name     = 'kolibri-tgpublish-service',
  $publish_version  = 'latest',
  $fake_pids        = false,
) inherits dhrep::params {

  $catname = $dhrep::services::tomcat_publish::catname
  $user    = $dhrep::services::tomcat_publish::user
  $group   = $dhrep::services::tomcat_publish::group

  package { $publish_name:
    ensure  => $publish_version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { "/etc/${scope}/${publish_short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${scope}/${publish_short}/conf":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${scope}/${publish_short}"],
  }

  file { "/etc/${scope}/${publish_short}/conf/config.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${publish_short}/conf/config.xml.erb"),
    require => File["/etc/${scope}/${publish_short}/conf"],
    notify  => Service['tomcat-tgpublish'],
  }

  file { "/etc/${scope}/${publish_short}/conf/beans.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${publish_short}/conf/beans.properties.erb"),
    require => File["/etc/${scope}/${publish_short}/conf"],
  }

  file { "/etc/${scope}/${publish_short}/conf/policies.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${publish_short}/conf/policies.xml.erb"),
    require => File["/etc/${scope}/${publish_short}/conf"],
    notify  => Service['tomcat-tgpublish'],
  }

  file { "/etc/${scope}/${publish_short}/conf/mets_template.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${publish_short}/conf/mets_template.xml.erb"),
    require => File["/etc/${scope}/${publish_short}/conf"],
    notify  => Service['tomcat-tgpublish'],
  }

  file { "/etc/${scope}/${publish_short}/conf/map_dias2jhove.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${publish_short}/conf/map_dias2jhove.xml.erb"),
    require => File["/etc/${scope}/${publish_short}/conf"],
    notify  => Service['tomcat-tgpublish'],
  }

  file { "/etc/${scope}/${publish_short}/conf/dias_formatregistry.xml":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${publish_short}/conf/dias_formatregistry.xml.erb"),
    require => File["/etc/${scope}/${publish_short}/conf"],
    notify  => Service['tomcat-tgpublish'],
  }

  ###
  # temp dir
  ###

  file { "/etc/${scope}/${publish_short}/temp":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${scope}/${publish_short}"],
  }

  ###
  # dest dir
  ###

  file { "/etc/${scope}/${publish_short}/dest":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${scope}/${publish_short}"],
  }

  ###
  # work dir
  ###

  file { "/etc/${scope}/${publish_short}/work":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${scope}/${publish_short}"],
  }

  ###
  # logging
  ###

  file { "/var/log/${scope}/${publish_short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${scope}"],
  }

  logrotate::rule { $publish_short:
    path         => "/var/log/${scope}/${publish_short}/${publish_short}.log",
    require      => File["/var/log/${scope}/${publish_short}"],
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
  # symlink war from deb package to tomcat webapps dir
  ###
  
  file { "/home/${user}/${catname}/webapps/${publish_short}": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/${publish_short}",
    require => [File["/etc/${scope}/${publish_short}/conf/beans.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

}
