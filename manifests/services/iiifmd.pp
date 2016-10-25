# == Class: dhrep::services::iiifmd
#
# Class to install and configure iiifmd service.
#
class dhrep::services::iiifmd (
  $scope   = undef,
  $version = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_digilib

  $_confdir = $::dhrep::params::confdir
  $_vardir  = $::dhrep::params::vardir
  $_catname = $dhrep::services::tomcat_digilib::catname
  $_user    = $dhrep::services::tomcat_digilib::user
  $_group   = $dhrep::services::tomcat_digilib::group

  ###
  # update apt repo and install package
  ###
  package { 'tg-iiif-metadata':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/iiifmd":
    ensure  => 'link',
    target  => "${_vardir}/webapps/iiifmd",
    require => [File["${_confdir}/iiifmd/iiifmd.properties"],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/iiifmd":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/iiifmd/iiifmd.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/etc/dhrep/iiifmd/iiifmd.properties.erb'),
    require => File["${_confdir}/iiifmd"],
    notify  => Service[$_catname]
  }

  ###
  # data
  ###
  file { "${_vardir}/iiifmd":
    ensure => directory,
    owner  => $_user,
    group  => $_group,
    mode   => '0755',
  }
  file { "${_vardir}/iiifmd/cache":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File["${_vardir}/iiifmd"],
  }

  ###
  # install the collectd plugin for elasticsearch
  ###
  file { '/var/www/nginx-root/textgridrep.de/iiif':
    ensure => directory,
    owner  => $_user,
    group  => $_group,
    mode   => '0755',
  }
  vcsrepo { '/var/www/nginx-root/textgridrep.de/iiif/mirador':
    ensure   => present,
    owner    => $_user,
    group    => $_group,
    provider => git,
    source   => 'https://github.com/IIIF/m1.git',
    require  => File['/var/www/nginx-root/textgridrep.de/iiif'],
  }
  ->
  file { '/var/www/nginx-root/textgridrep.de/iiif/mirador/view.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridrep.de/iiif/mirador/view.html',
    mode    => '0644',
  }
  # TODO: npm nodejs build and dhsummit.html
  vcsrepo { '/var/www/nginx-root/textgridrep.de/iiif/m2':
    ensure   => present,
    owner    => $_user,
    group    => $_group,
    provider => git,
    source   => 'https://github.com/IIIF/mirador.git',
    revision => 'v2.0.0',
    require  => File['/var/www/nginx-root/textgridrep.de/iiif'],
  }
}
