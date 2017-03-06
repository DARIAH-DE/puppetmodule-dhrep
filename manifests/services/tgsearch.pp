# == Class: dhrep::services::tgsearch
#
# Class to install and configure tgsearch nonpublic service.
#
class dhrep::services::tgsearch (
  $scope   = undef,
  $version = 'latest',
)  inherits dhrep::params {

  include dhrep::services::tomcat_tgsearch

  $_confdir   = $::dhrep::params::confdir
  $_catname   = $::dhrep::services::tomcat_tgsearch::catname
  $_http_port = $::dhrep::services::tomcat_tgsearch::http_port

  # FIXME remove if textgrid services finally are deployed to /var/dhrep/webapps!
  if $scope == 'textgrid' {
    $_aptdir = '/var/textgrid/webapps'
  }
  else {
    $_aptdir = $::dhrep::params::aptdir
  }

  ###
  # update apt repo and install package
  ###
  package { 'tgsearch-nonpublic-webapp':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/tgsearch":
    ensure  => 'link',
    target  => "${_aptdir}/tgsearch-nonpublic",
    require => Usertomcat::Instance[$_catname],
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
  # nrpe
  ###
  nrpe::plugin { 'check_http_tgsearch':
    plugin => 'check_http',
    args   => "-H localhost -p ${_http_port} -u /tgsearch",
  }

}
