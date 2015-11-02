# == Class: dhrep::services::intern::messaging
#
# Class to build up messaging.
#
class dhrep::services::intern::messaging (
  $scope                     = undef,
  $enzmeta_textgrid_user     = '',
  $enzmeta_textgrid_password = '',
  $bolrdf_textgrid_user      = '',
  $bolrdf_textgrid_user      = '',

){

  exec { 'git_clone_messagebeans':
    command => 'git clone git://git.projects.gwdg.de/textgrid-messagebeans.git /usr/local/src/messagebeans-git',
    path    => ['/usr/bin','/bin','/usr/sbin'],
    creates => '/usr/local/src/messagebeans-git',
    require => Package['git'],
  }

#  $nexus = {
#    id       => "dariah-nexus",
#    url      => "http://dev.dariah.eu/nexus/content/groups/public",
#    mirrorof => "*",      # if you want to use the repo as a mirror, see maven::settings below
#  }

#  maven::settings { 'maven-user-settings' :
#    mirrors => [$nexus], # mirrors entry in settings.xml, uses id, url, mirrorof from the hash passed
#    servers => [$central], # servers entry in settings.xml, uses id, username, password from the hash passed
#    proxies => [$proxy], # proxies entry in settings.xml, active, protocol, host, username, password, nonProxyHosts
#    user    => 'root',
#  }
  # mvn package wildfly:deploy -Dwildfly.port=19990
  
  file { '/root/.m2':
    ensure => directory,
  }

  file { '/root/.m2/settings.xml':
    ensure => present,
    source => 'puppet:///modules/textgrid/root/m2-settings.xml',
  }

  file { '/etc/textgrid/messagebeans':
    ensure => directory,
  }

  file { '/etc/textgrid/messagebeans/enzmeta.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/messagebeans/enzmeta.properties.erb'),
  }

  file { '/etc/textgrid/messagebeans/bolrfd.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/messagebeans/bolrdf.properties.erb'),
  }

}
