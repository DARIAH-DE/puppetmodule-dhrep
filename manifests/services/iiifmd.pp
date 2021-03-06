# == Class: dhrep::services::iiifmd
#
# Class to install and configure iiifmd service.
#
class dhrep::services::iiifmd (
  $scope = undef,
  $version = 'latest',
  $iiif_enabled_projects = [],
  $iiif_blacklist_uris = [],
  $repository_host = 'textgridrep.org',
  $mirador_host = 'textgridlab.org',
) inherits dhrep::params {

  include dhrep::services::tomcat_oaipmh

  $_confdir = $::dhrep::params::confdir
  $_vardir  = $::dhrep::params::vardir
  $_aptdir  = $::dhrep::params::aptdir
  $_catname = $dhrep::services::tomcat_oaipmh::catname

  ###
  # update apt repo and install package
  ###
  package { 'tg-iiif-metadata':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/iiifmd":
    ensure  => 'link',
    target  => "${_aptdir}/iiifmd",
    require => [File["${_confdir}/iiifmd/iiifmd.properties"],Usertomcat::Instance[$_catname]],
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
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/etc/dhrep/iiifmd/${scope}/iiifmd.properties.erb"),
    require => File["${_confdir}/iiifmd"],
    notify  => Service[$_catname],
  }

  ###
  # data
  ###
  file { "${_vardir}/iiifmd":
    ensure => directory,
    owner  => $_catname,
    group  => $_catname,
    mode   => '0755',
  }
  file { "${_vardir}/iiifmd/cache":
    ensure  => directory,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0755',
    require => File["${_vardir}/iiifmd"],
  }

  ###
  # install mirador
  ###
  if $scope == 'textgrid' {
    file { '/var/www/nginx-root/textgridrep.de/iiif':
      ensure => directory,
      owner  => $_catname,
      group  => $_catname,
      mode   => '0755',
    }
    package { 'textgrid-mirador':
      ensure  => present,
      require => Exec['update_dariah_apt_repository'],
    }
  }
  else {
    # TODO create dhrep scope "dariah" mirador?
  }
}
