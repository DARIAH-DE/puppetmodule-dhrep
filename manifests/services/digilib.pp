# == Class: textgrid::services::digilib
#
# Class to install and configure digilib
#
class textgrid::services::digilib (
  $digilib_name    = 'digilib-service',
  $digilib_version = '1.7-SNAPSHOT',
  $digilib_group   = 'info.textgrid.services',
){

  package {
    'libvips37':     ensure => present; # this is needed by the prescaler, see textgrid::services::intern::messaging
    'libvips-tools': ensure => present;
  }

  include textgrid::services::tomcat_digilib

  $catname   = $textgrid::services::tomcat_digilib::catname
  $user      = $textgrid::services::tomcat_digilib::user
  $group     = $textgrid::services::tomcat_digilib::group
  $http_port = $textgrid::services::tomcat_digilib::http_port

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
    content => template('textgrid/etc/textgrid/digilib/digilib.properties.erb'),
    require => File['/etc/textgrid/digilib'],
  }

  file { '/etc/textgrid/digilib/digilib-service.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/digilib/digilib-service.properties.erb'),
    require => File['/etc/textgrid/digilib'],
  }

  ###
  # use maven to fetch latest digilib service from nexus, copy war, set permissions,
  # and restart tomcat
  ###

  maven { "/var/cache/textgrid/${digilib_name}-${digilib_version}.war":
    ensure     => latest,
    groupid    => $digilib_group,
    artifactid => $digilib_name,
    version    => $digilib_version,
    packaging  => 'war',
    repos      => ['http://dev.dariah.eu/nexus/content/repositories/snapshots/'],
    require    => Package['maven'],
    notify     => Exec['replace_digilib_service'],
  }

  exec { 'replace_digilib_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${catname}/${catname}/webapps/digilibservice && sleep 2 && cp /var/cache/textgrid/${digilib_name}-${digilib_version}.war /home/${catname}/${catname}/webapps/digilibservice.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file { "/home/${catname}/${catname}/webapps/digilibservice.war":
    group   => $group,
    mode    => '0640',
    notify  => Service[$catname],
    require => File['/etc/textgrid/digilib/digilib.properties'],
  }
  ~>
  textgrid::tools::wait_for_url_ready { 'wait_4_digilib_war_deployed':
    url         => "http://localhost:${http_port}/digilibservice/",
    require     => Textgrid::Resources::Servicetomcat[$catname],
    refreshonly => true,
  }
  ->
  file { "/home/${catname}/${catname}/webapps/digilibservice/WEB-INF/classes/digilib.properties":
    ensure  => link,
    target  => '/etc/textgrid/digilib/digilib.properties',
  }
  ->
  file { "/home/${catname}/${catname}/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
    ensure  => link,
    target  => '/etc/textgrid/digilib/digilib-service.properties',
  }

  ###
  # digilib
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

}
