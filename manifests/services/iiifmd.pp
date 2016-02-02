# == Class: dhrep::services::iiifmd
#
# Class to install and configure iiifmd
#
class dhrep::services::iiifmd (
  $scope            = undef,
  $version          = 'latest',
){

  include dhrep::services::tomcat_digilib

  $catname   = $dhrep::services::tomcat_digilib::catname
  $user      = $dhrep::services::tomcat_digilib::user
  $group     = $dhrep::services::tomcat_digilib::group

  package { 'tg-iiif-metadata':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { '/etc/textgrid/iiifmd':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/etc/textgrid/iiifmd/iiifmd.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/iiifmd/iiifmd.properties.erb'),
    require => File['/etc/textgrid/iiifmd'],
    notify  => Service[$catname]
  }

  ###
  # data
  ###

  file { '/var/textgrid/iiifmd':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  file { '/var/textgrid/iiifmd/cache':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###

  file { "/home/${user}/${catname}/webapps/iiifmd": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/iiifmd",
    require => [File['/etc/textgrid/iiifmd/iiifmd.properties'],Dhrep::Resources::Servicetomcat[$catname]],
  }

}
