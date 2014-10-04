# == Class: textgrid::services::intern::tgwildfly
#
# Class to install and configure wildfly, 
# adds also tgcrud user for jms
# 
# TODO: default pw for wildfly system user
#       compare https://github.com/biemond/biemond-wildfly/blob/v0.1.7/manifests/install.pp#L37
class textgrid::services::intern::tgwildfly {

  class { 'wildfly::install':
    version           => '8.1.0',
    install_source    => 'http://download.jboss.org/wildfly/8.1.0.Final/wildfly-8.1.0.Final.tar.gz',
    install_file      => 'wildfly-8.1.0.Final.tar.gz',
    java_home         => '/usr/lib/jvm/java-7-openjdk-amd64',
    mgmt_http_port    => '19990',
    mgmt_https_port   => '19993',
    public_http_port  => '18080',
    public_https_port => '18443',
    ajp_port          => '18009',
  }

}
