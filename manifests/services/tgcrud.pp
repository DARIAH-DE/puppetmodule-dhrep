# == Class: textgrid::services::tgcrud
#
# Class to install and configure tgcrud
#
class textgrid::services::tgcrud (
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
    user        => 'textgrid',
    group       => 'ULSB',
    gid          => '29900',
    uid          => '49628',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  ###
  # deploy war
  ###
  tomcat::war { 'tgcrud.war':
    war_ensure    => present,
    catalina_base => "/home/textgrid/${tgname}",
    war_source    => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=tgcrud-base&v=5.1.2-SNAPSHOT&e=war',
     require      => Textgrid::Resources::Servicetomcat[$tgname],
#    require       => Exec["create_${tgname}"],
  }

  ###
  # config
  ###
  file { '/etc/textgrid/tgcrud':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
  }

#  file { '/etc/textgrid/tgcrud/conf':
#    ensure  => directory,
#    owner   => root,
#    group   => root,
#    mode    => '0755',
#  }

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
    require => File['/data'],
  }

  file { '/data/nonpublic':
    ensure  => directory,
    owner   => 'textgrid',
    group   => 'ULSB',
    mode    => '0755',
    require => File['/data'],
  }
}
