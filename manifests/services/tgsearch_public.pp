# == Class: dhrep::services::tgsearch_public
#
# Class to install and configure tgsearch public service.
#
class dhrep::services::tgsearch_public (
  $scope   = undef,
  $name    = 'tgsearch-public-webapp',
  $version = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_tgsearch

  $_confdir   = $::dhrep::params::confdir
  $_catname   = $::dhrep::services::tomcat_tgsearch::catname
  $_user      = $::dhrep::services::tomcat_tgsearch::user
  $_group     = $::dhrep::services::tomcat_tgsearch::group

  ###
  # update apt repo and install package
  ###
  package { $name:
    ensure  => $version,
    require => Exec['update_dariah_apt_repository'],
  }

  ###
  # config
  ###
#  file { "${_confdir}/tgsearch":
#    ensure => directory,
#    owner  => root,
#    group  => root,
#    mode   => '0755',
#  }
  file { "${_confdir}/tgsearch/tgsearch-public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/dhrep/tgsearch-public/tgsearch.properties.erb"),
    require => File["${_confdir}/tgsearch"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/tgsearch/log4.public.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/dhrep/tfsearch-public/log4j.properties.erb"),
    require => File["${_confdir}/tgsearch"],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/tgsearch-public":
    ensure => 'link',
    target => "/var/dhrep/webapps/tgsearch-public",
  }
}
