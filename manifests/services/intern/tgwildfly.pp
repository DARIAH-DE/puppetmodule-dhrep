# == Class: textgrid::services::intern::tgwildfly
#
# Class to install and configure wildfly, 
# adds also tgcrud user for jms
# 
# TODO: default pw for wildfly system user
#       compare https://github.com/biemond/biemond-wildfly/blob/v0.1.7/manifests/install.pp#L37
class textgrid::services::intern::tgwildfly {

  # install wildfly
  class { 'wildfly::install':
    version           => '8.1.0',
    install_source    => 'http://download.jboss.org/wildfly/8.1.0.Final/wildfly-8.1.0.Final.tar.gz',
    install_file      => 'wildfly-8.1.0.Final.tar.gz',
    java_home         => '/usr/lib/jvm/java-7-openjdk-amd64',
    dirname           => '/home/wildfly/wildfly',
    mode              => 'standalone',
    config            => 'standalone-full.xml',
    java_xmx          => '512m',
    java_xms          => '256m',
    java_maxpermsize  => '256m',
    mgmt_http_port    => '19990',
    mgmt_https_port   => '19993',
    public_http_port  => '18080',
    public_https_port => '18443',
    ajp_port          => '18009',
    notify            => [Exec['wildfly_add_tgrud_user'],Exec['wildfly_add_tgcrud_topic']]
  }

#  Exec {
#    logoutput => true,
#  }

  # add user for tgcrud to connect
  exec { 'wildfly_add_tgrud_user':
    path => ['/usr/bin','/bin','/usr/sbin', '/sbin', '/home/wildfly/wildfly/bin'],
    environment => ["JBOSS_HOME=/home/wildfly/wildfly", "JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64"],
    require     => Class['wildfly::install'],
    refreshonly => true,
    command     => '/home/wildfly/wildfly/bin/add-user.sh -a -s --user tgcrud --password secret --group guest',
  }

  # add tgcrud topic to jms
  exec { 'wildfly_add_tgcrud_topic':
    path => ['/usr/bin','/bin','/usr/sbin', '/sbin', '/home/wildfly/wildfly/bin'],
    environment => ["JBOSS_HOME=/home/wildfly/wildfly", "JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64"],
    require     => Class['wildfly::install'],
    refreshonly => true,
    command => '/home/wildfly/wildfly/bin/jboss-cli.sh --controller=localhost:19990 --connect --command="jms-topic add --topic-address=tgcrudTopic --entries=topic/tgcrud,java:jboss/exported/jms/topic/tgcrud"',
  }

}