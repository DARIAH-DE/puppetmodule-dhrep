# == Class: dhrep::services::tgsearch_public
#
# Class to install and configure tgsearch public service.
#
class dhrep::services::tgsearch_public (
  $scope   = undef,
  $version = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_tgsearch

  $_confdir = $::dhrep::params::confdir
  $_catname = $::dhrep::services::tomcat_tgsearch::catname

  # FIXME remove if tgsearch services finally are deployed to /var/dhrep/webapps!
  if $scope == 'textgrid' {
    $_aptdir = '/var/textgrid/webapps'
  }
  else {
    $_aptdir = $::dhrep::params::aptdir
  }

  ###
  # update apt repo and install package
  ###
  package { 'tgsearch-public-webapp':
    ensure  => $version,
    require => Exec['update_dariah_apt_repository'],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/tgsearch-public":
    ensure => 'link',
    target => "${_aptdir}/tgsearch-public",
  }

  ###
  # config
  ###
  file { "${_confdir}/tgsearch/tgsearch-public.properties":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/etc/dhrep/tgsearch-public/tgsearch.properties.erb'),
    require => File["${_confdir}/tgsearch"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/tgsearch/log4.public.properties":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/etc/dhrep/tgsearch-public/log4j.properties.erb'),
    require => File["${_confdir}/tgsearch"],
  }
}
