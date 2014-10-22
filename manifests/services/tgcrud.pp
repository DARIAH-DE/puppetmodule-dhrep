# == Class: textgrid::services::tgcrud
#
# Class to install and configure tgcrud
#
class textgrid::services::tgcrud (
  $use_messaging = 'false',
  $tgcrud_version = '5.5.0-SNAPSHOT',
){

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::intern::tgnoid
  include textgrid::services::tgauth

  $tgname = 'tomcat-tgcrud'
  $http_port = '9093'
  $control_port = '9008'
  $xmx = '1024'
  $xms = '128'
  $jmx_port = '9993'

  ###
  # user, home-dir and user-tomcat
  ###
  textgrid::resources::servicetomcat { $tgname:
    user         => 'textgrid',
    group        => 'ULSB',
    gid          => '29900',
    uid          => '49628',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
    defaults_template => 'textgrid/etc/default/tomcat.tgcrud.erb',
  }

  staging::file { "tgcrud-${tgcrud_version}.war":
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=tgcrud-base&v=${tgcrud_version}&e=war",
    target  => "/var/cache/textgrid/tgcrud-${tgcrud_version}.war",
  }

#  textgrid::tools::tgstaging { "tgcrud-${tgcrud_version}.war":
#    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=tgcrud-base&v=${tgcrud_version}&e=war",
#    target  => "/home/textgrid/${tgname}/webapps/tgcrud",
#    creates => "/home/textgrid/${tgname}/webapps/tgcrud",
#    require => Textgrid::Resources::Servicetomcat[$tgname],
#  }
  ~>
  ###
  # deploy war
  ###
  tomcat::war { 'tgcrud.war':
    war_ensure    => present,
    catalina_base => "/home/textgrid/${tgname}",
    war_source    => "/var/cache/textgrid/tgcrud-${tgcrud_version}.war",
#    war_source    => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=tgcrud-base&v=5.1.2-SNAPSHOT&e=war',
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }

  ###
  # javagat
  ###
  textgrid::tools::tgstaging {"JavaGAT-2.1.1-binary.zip":
    source  => 'http://gforge.cs.vu.nl/gf/download/frsrelease/154/1196/JavaGAT-2.1.1-binary.zip',
    target  => '/usr/local',
    creates => '/usr/local/JavaGAT-2.1.1',
  }

  file { '/usr/local/javagat':
    ensure => link,
    target => '/usr/local/JavaGAT-2.1.1',
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

  file { '/etc/textgrid/tgcrud/tgcrud.properties':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgcrud/tgcrud.properties.erb'),
  }

  file { '/etc/textgrid/tgcrud/tgcrud.log4j':
    ensure  => present,
    owner   => root,
    group   => 'ULSB',
    mode    => '0640',
    content => template('textgrid/etc/textgrid/tgcrud/tgcrud.log4j.erb'),
  }

  file { '/var/log/textgrid/tgcrud':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
    require => File['/var/log/textgrid'],
  }

  ###
  # the data dir
  ###
  file { '/data':
    ensure => directory,
    owner  => 'textgrid',
    group  => 'ULSB',
    mode   => '0755',
  }

  # TODO: decide wether to mount stornext or create local data dir

  #mount { '/media/stornext':
  #  device  => 'fs-base3.gwdg.de:/home/textgrid/',
  #  fstype  => 'nfs',
  #  ensure  => 'mounted',
  #  options => 'defaults',
  #  atboot  => true,
  #  require => [File['/mnt/storage'],Package['nfs-common']],
  #}

  file { '/data/public':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
  }

  file { '/data/nonpublic':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
  }

  file { '/data/public/productive':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
  }

  file { '/data/nonpublic/productive':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
  }
}
