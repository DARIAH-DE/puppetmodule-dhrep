# == Class: textgrid::services::aggregator
#
# Class to install and configure aggregator
#
class textgrid::services::aggregator {

  $tgname = 'tomcat-aggregator'
  $http_port = '9095'
  $control_port = '9010'
  $jmx_port = '9995'
  $aggregator_version = '1.4.3' 


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
    source  => "http://dev.digital-humanities.de/nexus/content/repositories/releases/info/textgrid/services/aggregator/1.4.3/aggregator-${aggregator_version}.war",
    target  => "/var/cache/textgrid/aggregator-${aggregator_version}.war",
  }
  ->
  tomcat::war { 'aggregator.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/var/cache/textgrid/aggregator-${aggregator_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
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
