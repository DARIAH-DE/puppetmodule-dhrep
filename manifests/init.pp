class textgrid {

  include textgrid::tgsearch
  include textgrid::tgcrud
  include textgrid::tgelasticsearch
  include textgrid::sesame
  include textgrid::tgauth
  include textgrid::tgnginx

  package {
    'openjdk-6-jdk':            ensure => absent;
    'openjdk-6-jre':            ensure => absent;
    'openjdk-6-jre-headless':   ensure => absent;
    'openjdk-6-jre-lib':        ensure => absent;
    'openjdk-7-jdk':            ensure => present;
    'tomcat7':                  ensure => present;
    'tomcat7-user':             ensure => present;
    'git':                      ensure => present;
  }

  file { '/etc/textgrid':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
  }

  file { '/var/log/textgrid':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
  }

  service { 'tomcat7':
    	ensure  => stopped,
    	enable  => false,
    	require => Package["tomcat7"],
  }

}
