# == Class: dhrep::services::digilib
#
# Class to install and configure digilib
#
class dhrep::services::digilib (
  $scope            = undef,
  $short            = 'digilibservice',
  $digilib_name     = 'digilib-service',
  $digilib_version  = 'latest',
){

  package {
    'libvips37':     ensure  => present; # this is needed by the prescaler, see dhrep::services::intern::messaging
    'libvips-tools': ensure  => present;
    $digilib_name:   ensure  => $digilib_version, 
                     require => Exec['update_dariah_ubunturepository'],
  }

  include dhrep::services::tomcat_digilib

  $catname   = $dhrep::services::tomcat_digilib::catname
  $user      = $dhrep::services::tomcat_digilib::user
  $group     = $dhrep::services::tomcat_digilib::group
  $http_port = $dhrep::services::tomcat_digilib::http_port

  ###
  # config
  ###

  file { '/etc/textgrid/digilib':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/etc/textgrid/digilib/digilib.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/digilib/digilib.properties.erb'),
    require => File['/etc/textgrid/digilib'],
  }

  file { '/etc/textgrid/digilib/digilib-service.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/digilib/digilib-service.properties.erb'),
    require => File['/etc/textgrid/digilib'],
  }

  ###
  # data
  ###

  file { '/var/textgrid/digilib':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  # the prescale images will be written by wildfly
  file { '/var/textgrid/digilib/prescale':
    ensure => directory,
    owner  => 'wildfly',
    group  => 'wildfly',
    mode   => '0755',
  }

  # symlink war from deb package to tomcat webapps dir
  file { "/home/${user}/${catname}/webapps/${short}.war": 
    ensure => 'link',
    target => "/var/${scope}/webapps/${short}.war",
    notify  => Service[$catname],
    require => File['/etc/textgrid/digilib/digilib.properties'],
  }

#  dhrep::tools::wait_for_url_ready { 'wait_4_digilib_war_deployed':
#    url         => "http://localhost:${http_port}/digilibservice/",
#    require     => dhrep::Resources::Servicetomcat[$catname],
#    refreshonly => true,
 # }
  #->
#  file { "/home/${catname}/${catname}/webapps/digilibservice/WEB-INF/classes/digilib.properties":
#    ensure  => link,
#    target  => '/etc/textgrid/digilib/digilib.properties',
#  }
#  ->
#  file { "/home/${catname}/${catname}/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
#    ensure  => link,
#    target  => '/etc/textgrid/digilib/digilib-service.properties',
#  }

}
