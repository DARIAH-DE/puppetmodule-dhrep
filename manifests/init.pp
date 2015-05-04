# == Class: textgrid
#
# setup and manage a textgrid server
#
# TODO  read https://dev2.dariah.eu/wiki/display/TGINT/textgrid-esx1.gwdg.de
#       and write the manifests ;-)
#
class textgrid {

  include textgrid::services::tgsearch
  include textgrid::services::tgcrud
  include textgrid::services::tgcrud_public
  include textgrid::services::tgpublish
  include textgrid::services::tgpid
  include textgrid::services::tgauth
  include textgrid::services::confserv
  include textgrid::services::digilib
  include textgrid::services::textgridrep_website
  include textgrid::services::tgoaipmh
  include textgrid::services::aggregator

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::intern::sesame
  include textgrid::services::intern::tgwildfly
  include textgrid::services::intern::messaging
  include textgrid::services::intern::tgnoid

  include textgrid::tgnginx

  package {
    'openjdk-6-jdk':            ensure => absent;
    'openjdk-6-jre':            ensure => absent;
    'openjdk-6-jre-headless':   ensure => absent;
    'openjdk-6-jre-lib':        ensure => absent;
    'openjdk-7-jdk':            ensure => present;
    'tomcat7':                  ensure => present;
    'tomcat7-user':             ensure => present;
    'libtcnative-1':            ensure => present;               
    'mc':                       ensure => present;
    'maven':                    ensure => present;
    'make':                     ensure => present;
  }

  file { '/etc/textgrid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/var/log/textgrid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/var/textgrid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  service { 'tomcat7':
    ensure  => stopped,
    enable  => false,
    require => Package['tomcat7'],
  }

  # we want to use custom facts (TODO: is there an existing puppet plugin?)
  file { '/etc/facter/':
    ensure => directory,
  }
  file { '/etc/facter/facts.d':
    ensure  => directory,
  }

}
