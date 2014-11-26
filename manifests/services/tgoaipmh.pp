# == Class: textgrid::services::tgoaipmh
#
# Class to install and configure tgoaipmh
#
class textgrid::services::tgoaipmh (
  $tgoaipmh_name    = 'oaipmh-webapp',
  $tgoaipmh_version = '1.0-SNAPSHOT',
){

  include textgrid::services::intern::tgelasticsearch

  $tgname       = 'tomcat-tgoaipmh'
  $http_port    = '9097'
  $control_port = '9012'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9996'

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $tgname:
    user         => 'tg-oaipmh',
    group        => 'tg-oaipmh',
    gid          => '1011',
    uid          => '1011',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
    defaults_template => 'textgrid/etc/default/tomcat.erb',
  }
  ~>

  ###
  # stage war
  ###
  staging::file { "tgoaipmh-${tgoaipmh_version}.war":
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=${tgoaipmh_name}&v=${tgoaipmh_version}&e=war",
    target  => "/var/cache/textgrid/tgoaipmh-${tgoaipmh_version}.war",
  }
  ~>

  ###
  # deploy war
  ###
  tomcat::war { 'tgoaipmh.war':
    war_ensure    => present,
    catalina_base => "/home/tg-oaipmh/${tgname}",
    war_source    => "/var/cache/textgrid/tgoaipmh-${tgoaipmh_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }

  ###
  # config
  ###
  file { '/etc/textgrid/tgoaipmh':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { '/etc/textgrid/tgoaipmh/oaipmh.properties':
    ensure  => present,
    owner   => root,
    group   => 'tg-oaipmh',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgoaipmh/oaipmh.properties.erb'),
    require => File['/etc/textgrid/tgoaipmh'],
  }

  ###
  # logging
  ###
  file { '/etc/textgrid/tgoaipmh/log4j.oaipmh.properties':
    ensure  => present,
    owner   => root,
    group   => 'tg-oaipmh',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgoaipmh/log4j.oaipmh.properties.erb'),
    require => File['/etc/textgrid/tgoaipmh'],
  }
  file { '/var/log/textgrid/tgoaipmh':
    ensure  => directory,
    owner   => root,
    group   => 'tg-oaipmh',
    mode    => '0755',
    require => File['/var/log/textgrid'],
  }

}
