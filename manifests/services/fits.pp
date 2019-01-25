# == Class: dhrep::services::fits
#
# Class to install and configure the DARIAH fits.
#
class dhrep::services::fits (
  $scope                = undef,
  $fits_version         = '1.2.0',
  $fits_servlet_version = '1.1.3',
) inherits dhrep::params {

  include dhrep::services::tomcat_fits

  $_aptdir             = $::dhrep::params::aptdir
  $_vardir             = $::dhrep::params::vardir
  $_catname            = $::dhrep::services::tomcat_fits::catname
  $_user               = $::dhrep::services::tomcat_fits::user
  $_group              = $::dhrep::services::tomcat_fits::group

  $fits_folder         = "fits-${fits_version}"
  $fits_file           = "${fits_folder}.zip"
  $fits_source         = "http://projects.iq.harvard.edu/files/fits/files/${fits_file}"
  $fits_service_file   = "fits-${fits_servlet_version}.war"
  $fits_service_source = "http://projects.iq.harvard.edu/files/fits/files/fits-${fits_servlet_version}.war"
  $fits_home           = "/home/${_catname}/${fits_folder}"

  ###
  # do install the fits itself: download fits service zip file and extract
  ###
  staging::file { $fits_file:
    source  => $fits_source,
    target  => "${_vardir}/${fits_file}",
    timeout => 300000,
    # PLEASE NOTE staging is needing java for de-jarring things, so we require java here, then! (needed fix for xenial?)
    # require => Package['oracle-java8-installer'],
  }
  -> staging::extract { $fits_file:
    source  => "${_vardir}/${fits_file}",
    target  => "/home/${_catname}/",
    creates => "/home/${_catname}/${fits_folder}",
    require => Usertomcat::Instance[$_catname],
  }

  ###
  # do install the fits web service: download web service war file and extract
  ###
  file { "${_aptdir}/fits":
    ensure  => directory,
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => [File[$_aptdir],Usertomcat::Instance[$_catname]],
  }
  -> staging::file { $fits_service_file:
    source => $fits_service_source,
    target => "${_vardir}/${fits_service_file}",
  }
  -> staging::extract { $fits_service_file:
    source  => "${_vardir}/${fits_service_file}",
    target  => "${_aptdir}/fits/",
    creates => "${_aptdir}/fits/WEB-INF",
    require => File["${_aptdir}/fits"],
  }

  ###
  # symlink war from extracted war file to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/fits":
    ensure  => 'link',
    target  => "${_aptdir}/fits",
    require => [File["${_aptdir}/fits"],Usertomcat::Instance[$_catname]],
  }

  ###
  # add things to fits tomcat configuration
  ###
  file { "/home/${_catname}/${_catname}/conf/catalina.properties":
    ensure  => file,
    require => Exec["create_${_catname}"],
  }
  ~> file_line { 'configure_fits_libs_line_1':
    ensure => present,
    path   => "/home/${_catname}/${_catname}/conf/catalina.properties",
    line   => "fits.home=${fits_home}",
  }
  ~> file_line { 'configure_fits_libs_line_2':
    ensure => present,
    path   => "/home/${_catname}/${_catname}/conf/catalina.properties",
    line   => "shared.loader=${fits_home}/lib/*.jar",
  }
  ~> file_line { 'configure_fits_libs_line_3':
    ensure => present,
    path   => "/home/${_catname}/${_catname}/conf/catalina.properties",
    line   => "log4j.configuration=${fits_home}/log4j.properties",
    notify => Service[$_catname],
  }
}
