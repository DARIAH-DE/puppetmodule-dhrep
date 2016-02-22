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

  # install the collectd plugin for elasticsearch
  file { '/var/www/nginx-root/textgridrep.de/iiif':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  vcsrepo { '/var/www/nginx-root/textgridrep.de/iiif/mirador':
    ensure   => present,
    owner  => $user,
    group  => $group,
    provider => git,
    source   => 'https://github.com/IIIF/m1.git',
  }
  ->
  file { '/var/www/nginx-root/textgridrep.de/iiif/mirador/view.html':
    source => 'puppet:///modules/dhrep/var/www/nginx-root/textgridrep.de/iiif/mirador/view.html',
    mode   => '0644',
  }

  # TODO: npm nodejs build and dhsummit.html
  vcsrepo { '/var/www/nginx-root/textgridrep.de/iiif/m2':
    ensure   => present,
    owner  => $user,
    group  => $group,
    provider => git,
    source   => 'https://github.com/IIIF/mirador.git',
    revision => 'v2.0.0',
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
