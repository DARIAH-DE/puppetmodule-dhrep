# == Class: textgrid::services::digilib
#
# Class to install and configure digilib
#
class textgrid::services::digilib {

  $tgname = 'tomcat-iiif'
  $http_port = '9092'
  $control_port = '9007'
  $jmx_port = '9992'
  $digilib_version = '1.7-SNAPSHOT'

  package {
    'libvips15':       ensure => present; # this is needed by the prescaler, see textgrid::services::intern::messaging
    'libvips-tools': ensure => present;
  }

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $tgname:
    gid          => '1009',
    uid          => '1009',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

# http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.services&a=digilib-service&v=1.7-SNAPSHOT&e=war

  staging::file { "digilib-service-${digilib_version}.war":
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.services&a=digilib-service&v=${digilib_version}&e=war",
    target  => "/var/cache/textgrid/digilib-service-${digilib_version}.war",
  }

  tomcat::war { 'digilibservice.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/var/cache/textgrid/digilib-service-${digilib_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }
  ->
  # TODO: next step needs to need to wait until tomcat unzipped war file
  file { "/home/${tgname}/${tgname}/webapps/digilibservice/WEB-INF/classes/digilib.properties":
    ensure => link,
    target => '/etc/textgrid/digilib/digilib.properties',
  }
  ->
  file { "/home/${tgname}/${tgname}/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
    ensure => link,
    target => '/etc/textgrid/digilib/digilib-service.properties',
  }  

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
  }

  file { '/etc/textgrid/digilib/digilib-service.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/digilib/digilib-service.properties.erb'),
  }
}
