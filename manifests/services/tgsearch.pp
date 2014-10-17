# == Class: textgrid::services::tgsearch
#
# Class to install and configure tgsearch.
# 
class textgrid::services::tgsearch {

  include textgrid::services::intern::tgelasticsearch

  $tgname = 'tomcat-tgsearch'
  $http_port = '9090'
  $control_port = '9005'
  $jmx_port = '9990'

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $tgname:
    gid          => '1007',
    uid          => '1007',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  ###
  # the war files
  ###
  tomcat::war { 'tgsearch-public.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=tgsearch-public-webapp&v=3.3.1-SNAPSHOT&e=war',
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }
  ->
  tomcat::war { 'tgsearch.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=tgsearch-nonpublic-webapp&v=3.3.1-SNAPSHOT&e=war',
    require       => Textgrid::Resources::Servicetomcat[$tgname],
#    notify        => Service['tomcat-tgsearch'],
  }

  ###
  # the config in /etc
  ###
  file { '/etc/textgrid/tgsearch':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/etc/textgrid/tgsearch/tgsearch-nonpublic.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgsearch/tgsearch-nonpublic.properties.erb'),
  }

  file { '/etc/textgrid/tgsearch/tgsearch-public.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgsearch/tgsearch-public.properties.erb'),
  }

  file { '/etc/textgrid/tgsearch/log4j.public.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgsearch/log4j.public.properties.erb'),
  }

  file { '/etc/textgrid/tgsearch/log4j.nonpublic.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgsearch/log4j.nonpublic.properties.erb'),
  }

}
