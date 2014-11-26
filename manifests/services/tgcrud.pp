# == Class: textgrid::services::tgcrud
#
# Class to install and configure tgcrud
#
class textgrid::services::tgcrud (
  $tgcrud_name    = 'tgcrud-base',
  $tgcrud_version = '5.0.1',
  $use_messaging  = 'false',
  $publish_secret = '',
){

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::intern::tgnoid
  include textgrid::services::intern::javagat
  include textgrid::services::tgauth

  $tgname       = 'tomcat-tgcrud'
  $http_port    = '9093'
  $control_port = '9008'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9993'

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $tgname:
    user              => 'textgrid',
    group             => 'ULSB',
    gid               => '29900',
    uid               => '49628',
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => 'textgrid/etc/default/tomcat.tgcrud.erb',
    init_dependencies => 'wildfly',
    require           => Service['wildfly'],
  }

  ###
  # config
  ###
  file { '/etc/textgrid/tgcrud':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  } 
  ->
  file { '/etc/textgrid/tgcrud/tgcrud.properties':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgcrud/tgcrud.properties.erb'),
    require => File['/etc/textgrid/tgcrud'],
  }
  ->
  file { '/etc/textgrid/tgcrud/beans.properties':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgcrud/beans.properties.erb'),
    require => File['/etc/textgrid/tgcrud'],
  }
  ->
  ###
  # stage war
  ###
  staging::file { "tgcrud-${tgcrud_version}.war":
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=${tgcrud_name}&v=${tgcrud_version}&e=war",
    target  => "/var/cache/textgrid/tgcrud-${tgcrud_version}.war",
  }
  ~>
  ###
  # deploy war
  ###
  tomcat::war { 'tgcrud.war':
    war_ensure    => present,
    catalina_base => "/home/textgrid/${tgname}",
    war_source    => "/var/cache/textgrid/tgcrud-${tgcrud_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }

  ###
  # logging
  ###
  file { '/etc/textgrid/tgcrud/tgcrud.log4j':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgcrud/tgcrud.log4j.erb'),
    require => File['/etc/textgrid/tgcrud'],
  }
  file { '/var/log/textgrid/tgcrud':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
    require => File['/var/log/textgrid'],
  }

}
