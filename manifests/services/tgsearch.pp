# == Class: dhrep::services::tgsearch
#
# Class to install and configure tgsearch nonpublic service.
#
class dhrep::services::tgsearch (
  $scope   = undef,
  $version = 'latest',
)  inherits dhrep::params {

  include dhrep::services::tomcat_tgsearch

  $_confdir = $::dhrep::params::confdir
  $_catname = $::dhrep::services::tomcat_tgsearch::catname
  $_user    = $::dhrep::services::tomcat_tgsearch::user
  $_group   = $::dhrep::services::tomcat_tgsearch::group

  ###
  # update apt repo and install package
  ###
  package { 'tgsearch-nonpublic-webapp':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/tgsearch":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/tgsearch/tgsearch-nonpublic.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/etc/dhrep/tgsearch/tgsearch.properties.erb"),
    require => File["${_confdir}/tgsearch"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/tgsearch/log4j.nonpublic.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/etc/dhrep/tgsearch/log4j.properties.erb"),
    require => File["${_confdir}/tgsearch"],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/tgsearch-nonpublic-webapp":
    ensure  => 'link',
    target  => "/var/dhrep/webapps/tgsearch-nonpublic",
    require => Dhrep::Resources::Servicetomcat[$_catname],
  }

  ###
  # nrpe
  ###
  dariahcommon::nagios_service { 'check_http_tgsearch':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -p 9090 -u /tgsearch",
  }
}
