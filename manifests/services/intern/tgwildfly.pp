# == Class: dhrep::services::intern::tgwildfly
#
# Class to install and configure wildfly, 
# adds also tgcrud user for jms
# 
class dhrep::services::intern::tgwildfly (
  $scope       = undef,
  $xmx         = $dhrep::params::wildfly_xmx,
  $xms         = $dhrep::params::wildfly_xms,
  $maxpermsize = $dhrep::params::wildfly_maxpermsize,
) inherits dhrep::params {

  $message_beans_version = '1.0.1-SNAPSHOT'
  $java_home = '/usr/lib/jvm/default-java'

  # install wildfly
  class { 'wildfly::install':
    version           => '8.2.0',
    install_source    => 'http://download.jboss.org/wildfly/8.2.0.Final/wildfly-8.2.0.Final.tar.gz',
    install_file      => 'wildfly-8.2.0.Final.tar.gz',
    java_home         => $java_home,
    dirname           => '/home/wildfly/wildfly',
    mode              => 'standalone',
    config            => 'standalone-full.xml',
    java_xmx          => $xmx,
    java_xms          => $xms,
    java_maxpermsize  => $maxpermsize,
    mgmt_http_port    => '19990',
    mgmt_https_port   => '19993',
    public_http_port  => '18080',
    public_https_port => '18443',
    ajp_port          => '18009',
#    notify            => [Exec['wildfly_add_tgrud_user'],Exec['wildfly_add_tgcrud_topic']],
    require           => Package['default-jre-headless'],
  }
  ~>
  # add user for tgcrud to connect
  # TODO: use wildfly:config module, as commented out below, requires server restart
  exec { 'wildfly_add_tgrud_user':
    path        => ['/usr/bin','/bin','/usr/sbin', '/sbin', '/home/wildfly/wildfly/bin'],
    environment => ['JBOSS_HOME=/home/wildfly/wildfly', "JAVA_HOME=${java_home}"],
#    require     => Class['wildfly'],
    refreshonly => true,
    command     => '/home/wildfly/wildfly/bin/add-user.sh -a -s --user tgcrud --password secret --group guest',
  }
  ~>
  # add tgcrud topic to jms
  exec { 'wildfly_add_tgcrud_topic':
    path        => ['/usr/bin','/bin','/usr/sbin', '/sbin', '/home/wildfly/wildfly/bin'],
    environment => ['JBOSS_HOME=/home/wildfly/wildfly', "JAVA_HOME=${java_home}"],
#    require     => Class['wildfly'],
    refreshonly => true,
    command     => '/home/wildfly/wildfly/bin/jboss-cli.sh --controller=localhost:19990 --connect --command="jms-topic add --topic-address=tgcrudTopic --entries=topic/tgcrud,java:jboss/exported/jms/topic/tgcrud"',
  }

  ###
  # stage war
  ###
  staging::file { 'message-beans.war':
    source  => "http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=snapshots&g=info.textgrid.middleware&a=message-beans&v=${message_beans_version}&e=war",
    target  => "/var/cache/textgrid/message-beans-${message_beans_version}.war",
    require => Class['wildfly::install'],
  }
  ~>
  file { '/home/wildfly/wildfly/standalone/deployments/message-beans.war':
    source => "/var/cache/textgrid/message-beans-${message_beans_version}.war",
  }

  # service:jmx:http-remoting-jmx://vm1:19990
  # service:jmx:http-remoting-jmx://localhost:19990
  #collectd::plugin::genericjmx { "add_wildfy_jar_to_jmx":
  #  jvmarg => "-Djava.class.path=/home/wildfly/wildfly/bin/client/jboss-cli-client.jar"
  #}
#  class { 'collectd::plugin::genericjmx':
#    jvmarg => "-Djava.class.path=/home/wildfly/wildfly/bin/client/jboss-cli-client.jar",
#  }

#  collectd::plugin::genericjmx::connection { $name:
#      host            => $fqdn,
#      service_url     => "service:jmx:http-remoting-jmx://localhost:19990",
#      collect         => [ 'memory-heap', 'memory-nonheap' ],
#      instance_prefix => "wildfly-",
#  }

}
