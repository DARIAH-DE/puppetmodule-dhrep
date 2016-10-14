# == Class: dhrep::services::intern::tgwildfly
#
# Class to install and configure wildfly, adds also tgcrud user for jms
#
class dhrep::services::intern::tgwildfly (
  $scope       = undef,
  $xmx         = $dhrep::params::wildfly_xmx,
  $xms         = $dhrep::params::wildfly_xms,
  $maxpermsize = $dhrep::params::wildfly_maxpermsize,
  $tgcrud_pw   = 'secret',
) inherits dhrep::params {

  $message_beans_version = '1.0.1-SNAPSHOT'

  if($::dhrep::oracle_jdk8) {
    $java_home = '/usr/lib/jvm/java-8-oracle'
  } else {
    $java_home = '/usr/lib/jvm/default-java'
  }

  # install wildfly
  class { 'wildfly':
    version           => '9.0.2',
    install_source    => 'http://download.jboss.org/wildfly/9.0.2.Final/wildfly-9.0.2.Final.tar.gz',
    java_home         => $java_home,
    dirname           => '/home/wildfly/wildfly',
    mode              => 'standalone',
    config            => 'standalone-full.xml',
    java_xmx          => $xmx,
    java_xms          => $xms,
    java_maxpermsize  => $maxpermsize,
    java_opts         => "-Djava.net.preferIPv4Stack=true",
    mgmt_http_port    => '19990',
    mgmt_https_port   => '19993',
    public_http_port  => '18080',
    public_https_port => '18443',
    ajp_port          => '18009',
    # only required if not oracle jdk8...?
    require           => Package['default-jre-headless'],
  }
  ->
  wildfly::config::app_user { 'tgcrud':
    password => $tgcrud_pw,
  }
  ->
  wildfly::config::user_roles { 'tgcrud':
    roles    => 'guest',
  }
  ->
  wildfly::messaging::topic { 'tgcrudTopic':
    entries => ['topic/tgcrud','java:jboss/exported/jms/topic/tgcrud'],
    notify => [Service['tomcat-crud'], Service['tomcat-publish']],
  }

  ###
  # stage war
  ###
  staging::file { 'message-beans.war':
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=message-beans&v=${message_beans_version}&e=war",
    target  => "/var/cache/textgrid/message-beans-${message_beans_version}.war",
    require => Class['wildfly'],
  }
  ~>
  file { '/home/wildfly/wildfly/standalone/deployments/message-beans.war':
    source => "/var/cache/textgrid/message-beans-${message_beans_version}.war",
  }

  #  wildfly::deployment { 'message-beans.war':
  #    source   => "/var/cache/textgrid/message-beans-${message_beans_version}.war",
  #  }



  ###
  # collectd for wildfly
  ###

  #  wildfly::deployment { 'jolokia.war':
  #    source   => 'http://central.maven.org/maven2/org/jolokia/jolokia-war/1.3.2/jolokia-war-1.3.2.war
  #  ',
  #  }

  staging::file { 'jolokia.war':
    source  => "http://central.maven.org/maven2/org/jolokia/jolokia-war/1.3.2/jolokia-war-1.3.2.war",
    target  => "/var/cache/textgrid/jolokia.war",
    require => Class['wildfly'],
  }
  ~>
  file { '/home/wildfly/wildfly/standalone/deployments/jolokia.war':
    source => "/var/cache/textgrid/jolokia.war",
  }

  collectd::plugin::curl_json { 'wildfly':
    url      => "http://localhost:18080/jolokia/read/java.lang:type=Memory",
    instance => 'wildfly',
    keys => {
      'value/NonHeapMemoryUsage/*' => {'type' => 'bytes'},
      'value/HeapMemoryUsage/*'    => {'type' => 'bytes'},
    },
  }

  logrotate::rule { 'wildfly_logrotate':
    path         => "/var/log/wildfly/console.log",
    require      => Class['wildfly'],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }
}
