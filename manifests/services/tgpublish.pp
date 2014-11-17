# == Class: textgrid::services::tgpublish
#
# Class to install and configure tgpublish.
#
class textgrid::services::tgpublish (
  $tgpublish_name    = 'kolibri-tgpublish-service',
  $tgpublish_version = '3.5.4-SNAPSHOT',
  $fake_pids         = 'false',
){

  $tgname = 'tomcat-tgpublish'

  ###
  # stage war
  ###
  staging::file { "tgpublish-${tgpublish_version}.war":
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=de.langzeitarchivierung.kolibri&a=${tgpublish_name}&v=${tgpublish_version}&e=war",
    target  => "/var/cache/textgrid/${tgpublish_name}-${tgpublish_version}.war",
  }
  ~>

  ###
  # deploy war
  ###
  tomcat::war { 'tgpublish.war':
    war_ensure    => present,
    catalina_base => "/home/textgrid/${tgname}",
    war_source    => "/var/cache/textgrid/${tgpublish_name}-${tgpublish_version}.war",
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }

  ###
  # config
  ###
  file { '/etc/textgrid/tgpublish':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { '/etc/textgrid/tgpublish/conf':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/etc/textgrid/tgpublish'],
  }
  file { '/etc/textgrid/tgpublish/conf/config.xml':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpublish/conf/config.xml.erb'),
    require => File['/etc/textgrid/tgpublish/conf'],
  }
  file { '/etc/textgrid/tgpublish/conf/beans.properties.xml':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpublish/conf/beans.properties.erb'),
    require => File['/etc/textgrid/tgpublish/conf'],
  }
  file { '/etc/textgrid/tgpublish/conf/policies.xml':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpublish/conf/policies.xml.erb'),
    require => File['/etc/textgrid/tgpublish/conf'],
  }
  file { '/etc/textgrid/tgpublish/conf/mets_template.xml':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpublish/conf/mets_template.xml.erb'),
    require => File['/etc/textgrid/tgpublish/conf'],
  }
  file { '/etc/textgrid/tgpublish/conf/map_dias2jhove.xml':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpublish/conf/map_dias2jhove.xml.erb'),
    require => File['/etc/textgrid/tgpublish/conf'],
  }
  file { '/etc/textgrid/tgpublish/conf/dias_formatregistry.xml':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgpublish/conf/dias_formatregistry.xml.erb'),
    require => File['/etc/textgrid/tgpublish/conf'],
  }

  ###
  # temp dir
  ###
  file { '/etc/textgrid/tgpublish/temp':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
    require => File['/etc/textgrid/tgpublish'],
  }

  ###
  # dest dir
  ###
  file { '/etc/textgrid/tgpublish/dest':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
    require => File['/etc/textgrid/tgpublish'],
  }

  ###
  # work dir
  ###
  file { '/etc/textgrid/tgpublish/work':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
    require => File['/etc/textgrid/tgpublish'],
  }

  ###
  # logging
  ###
  file { '/var/log/textgrid/tgpublish':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
    require => File['/var/log/textgrid'],
  }

}
