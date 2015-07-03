# == Class: textgrid::services::aggregator
#
# Class to install and configure aggregator
#
class textgrid::services::aggregator (
  $aggregator_version = '1.4.5',
){

  $tgname = 'tomcat-aggregator'
  $http_port = '9095'
  $control_port = '9010'
  $jmx_port = '9995'

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $tgname:
    gid          => '1014',
    uid          => '1014',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  staging::file { "aggregator-${aggregator_version}.war":
    source  => "http://dev.digital-humanities.de/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.services&a=aggregator&v=${aggregator_version}&e=war",
    target  => "/var/cache/textgrid/aggregator-${aggregator_version}.war",
  }
  ->
  tomcat::war { 'aggregator.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/var/cache/textgrid/aggregator-${aggregator_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }
  ~>
  # strange thing this is necessary... TODO: why?
  file { "/var/cache/textgrid/aggregator-${aggregator_version}.war":
    mode    => '0644',
  }
  
  file { '/etc/textgrid/aggregator':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  
  file { '/etc/textgrid/aggregator/aggregator.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/aggregator/aggregator.properties.erb'),
  }

}
