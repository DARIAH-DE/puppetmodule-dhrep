# == Class: dhrep::services::intern::wildfly
#
# Class to install and configure wildfly, adds also tgcrud user for jms
#
class dhrep::services::intern::wildfly (
  $scope       = undef,
  $xmx         = $dhrep::params::wildfly_xmx,
  $xms         = $dhrep::params::wildfly_xms,
  $maxpermsize = $dhrep::params::wildfly_maxpermsize,
  $crud_pw     = 'secret',
  $message_beans_version = '1.1.0-SNAPSHOT',
) inherits dhrep::params {

  if($::dhrep::oracle_jdk8) {
    $java_home = '/usr/lib/jvm/java-8-oracle'
  } else {
    $java_home = '/usr/lib/jvm/default-java'
  }

  if ($scope == 'textgrid') {
    $crud_name  = 'tgcrud'
    $crud_topic = 'tgcrudTopic'
  } else {
    $crud_name  = 'dhcrud'
    $crud_topic = 'dhcrudTopic'
  }

  ###
  # install wildfly
  ###
  class { 'wildfly':
    version          => '9.0.2',
    install_source   => 'http://download.jboss.org/wildfly/9.0.2.Final/wildfly-9.0.2.Final.tar.gz',
    java_home        => $java_home,
    dirname          => '/home/wildfly/wildfly',
    mode             => 'standalone',
    config           => 'standalone-full.xml',
    java_xmx         => $xmx,
    java_xms         => $xms,
    java_maxpermsize => $maxpermsize,
    java_opts        => '-Djava.net.preferIPv4Stack=true',
    properties       => {
      'jboss.management.http.port'  => '19990',
      'jboss.management.https.port' => '19993',
      'jboss.http.port'             => '18080',
      'jboss.https.port'            => '18443',
      'jboss.ajp.port'              => '18009',
    },
    # only required if not oracle jdk8...?
    require          => Package['default-jre-headless'],
    # should be initialised before tomcat_crud...
    before           => Service['tomcat-crud'],
  }
  -> wildfly::config::app_user { $crud_name:
    password => $crud_pw,
  }
  -> wildfly::config::user_roles { $crud_name:
    roles => 'guest',
  }
  -> wildfly::messaging::topic { $crud_topic:
    entries => ["topic/${crud_name}","java:jboss/exported/jms/topic/${crud_name}"],
    notify  => [Service['tomcat-crud'], Service['tomcat-publish']],
  }

  ###
  # stage war
  ###
  staging::file { 'message-beans.war':
    source  => "https://ci.de.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=message-beans&v=${message_beans_version}&e=war",
    target  => "/var/cache/dhrep/message-beans-${message_beans_version}.war",
    require => Class['wildfly'],
  }
  ~> file { '/home/wildfly/wildfly/standalone/deployments/message-beans.war':
    source => "/var/cache/dhrep/message-beans-${message_beans_version}.war",
  }

  ###
  # telegraf for wildfly
  ###
  require 'usertomcat::jolokia'
  file { '/home/wildfly/wildfly/standalone/deployments/jolokia.war':
    source => '/var/cache/jolokia.war',
  }

  telegraf::input { 'jolokia_wildfly_mem':
    plugin_type => 'jolokia',
    options     => {
      'context' => '/jolokia/',
    },
    sections    => {
      'jolokia.servers' => {
        'name' => 'wildfly',
        'host' => '127.0.0.1',
        'port' => '18080',
      },
      'jolokia.metrics' => {
        'name'      => 'heap_memory_usage',
        'mbean'     => 'java.lang:type=Memory',
        'attribute' => 'HeapMemoryUsage',
      },
    },
  }

  telegraf::input { 'jolokia_wildfly_cpu':
    plugin_type => 'jolokia',
    options     => {
      'context' => '/jolokia/',
    },
    sections    => {
      'jolokia.servers' => {
        'name' => 'wildfly',
        'host' => '127.0.0.1',
        'port' => '18080',
      },
      'jolokia.metrics' => {
        'name'      => 'process_cpu_load',
        'mbean'     => 'java.lang:type=OperatingSystem',
        'attribute' => 'ProcessCpuLoad',
      },
    },
  }

  ###
  # logrotate
  ###
  logrotate::rule { 'wildfly_logrotate':
    path         => '/var/log/wildfly/console.log',
    require      => Class['wildfly'],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d',
  }

  ###
  # nrpe
  ###
  nrpe::plugin { 'check_wildfly_memory':
    plugin => 'check_http',
    args   => '-H localhost -p 18080 -u /jolokia/read/java.lang:type=Memory -s HeapMemoryUsage -s NonHeapMemoryUsage',
  }
  nrpe::plugin { 'check_wildfly_uptime':
    plugin => 'check_http',
    args   => '-H localhost -p 18080 -u /jolokia/read/java.lang:type=Runtime/Uptime -s Uptime',
  }
}
