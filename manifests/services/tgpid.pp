# == Class: textgrid::services::tgpid
#
# Class to install and configure tgpid.
#
class textgrid::services::tgpid (
  $tgpid_name     = 'tgppid-service',
  $tgpid_version  = '3.2.0',
){

  $tgname = 'tomcat-tgpublish'

  ###
  # stage war
  ###
  staging::file { "tgpid-${tgpid_version}.war":
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=${tgpid_name}&v=${tgpid_version}&e=war",
    target  => "/var/cache/textgrid/${tgpid_name}-${tgpid_version}.war",
  }
  ~>

  ###
  # deploy war
  ###
  tomcat::war { 'tgpid.war':
    war_ensure    => present,
    catalina_base => "/home/textgrid/${tgname}",
    war_source    => "/var/cache/textgrid/${tgpid_name}-${tgpid_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }


  ###
  # config
  ###
  file { '/etc/textgrid/tgpid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { '/etc/textgrid/tgpid/tgpid.properties':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpid/tgpid.properties.erb'),
    require => File['/etc/textgrid/tgpid'],
  }

  ###
  # logging
  ###
  file { '/var/log/textgrid/tgpid':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
    require => File['/var/log/textgrid'],
  }

}
