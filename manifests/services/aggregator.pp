# == Class: textgrid::services::aggregator
#
# Class to install and configure aggregator
#
class textgrid::services::aggregator (
  $scope              = 'textgrid',
  $short              = 'aggregator',
  $aggregator_name    = 'aggregator',
  $aggregator_version = '1.4.7-SNAPSHOT',
  $aggregator_group   = 'info.textgrid.services',
# $maven_repository   = 'http://dev.dariah.eu/nexus/content/repositories/snapshots/',
  $maven_repository   = 'http://dev.digital-humanities.de/nexus/content/repositories/snapshots/',
){

  include textgrid::services::tomcat_aggregator

  $catname = $textgrid::services::tomcat_aggregator::catname
  $user    = $textgrid::services::tomcat_aggregator::user
  $group   = $textgrid::services::tomcat_aggregator::group

  ###
  # config
  ###

  file { '/etc/textgrid/aggregator':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${scope}/${short}/aggregator.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${scope}/etc/${scope}/${short}/aggregator.properties.erb"),
    require =>  File["/etc/${scope}/${short}"],
  }

  ###
  # use maven to fetch latest aggregator service from nexus, copy war, set permissions,
  # and restart tomcat
  ###

  maven { "/var/cache/${scope}/${aggregator_name}-${aggregator_version}.war":
    ensure     => latest,
    groupid    => $aggregator_group,
    artifactid => $aggregator_name,
    version    => $aggregator_version,
    packaging  => 'war',
    repos      => $maven_repository,
    require    => Package['maven'],
    notify     => Exec['replace_aggregator_service'],
  }

  exec { 'replace_aggregator_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${catname}/${catname}/webapps/${short} && sleep 2 && cp /var/cache/${scope}/${aggregator_name}-${aggregator_version}.war /home/${catname}/${catname}/webapps/${short}.war",
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
    require => File["/etc/${scope}/${short}/aggregator.properties"],
  }

}
