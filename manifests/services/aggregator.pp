# == Class: dhrep::services::aggregator
#
# Class to install and configure aggregator
#
class dhrep::services::aggregator (
  $scope              = undef,
  $short              = 'aggregator',
  $aggregator_name    = 'aggregator',
  $aggregator_version = 'latest',
){

  include dhrep::services::tomcat_aggregator

  $catname = $dhrep::services::tomcat_aggregator::catname
  $user    = $dhrep::services::tomcat_aggregator::user
  $group   = $dhrep::services::tomcat_aggregator::group

  package { $aggregator_name:
    ensure  => $aggregator_version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { "/etc/${scope}/aggregator":
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
    content => template("dhrep/etc/textgrid/${short}/aggregator.properties.erb"),
    require =>  File["/etc/${scope}/${short}"],
  }

  # symlink war from deb package to tomcat webapps dir
  file { "/home/${user}/${catname}/webapps/${short}.war": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/${short}.war",
#    notify  => Service[$catname],
    require => [File["/etc/${scope}/${short}/aggregator.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

}
