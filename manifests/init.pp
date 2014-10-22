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
  include textgrid::services::tgauth
  include textgrid::services::confserv

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
    'git':                      ensure => present;
    'curl':                     ensure => present;
    'emacs':                    ensure => present;
    'mc':                       ensure => present;
    'maven':                    ensure => present;
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

  # cache for tgstaging
  # vagrant cachier changes this to symlink TODO: workaround
#  unless $textgrid_staging_dir_created {
  unless $vagrant {
    file { '/var/cache/textgrid/' :
      ensure => directory,
    }
#    file {'/etc/facter/facts.d/textgrid_staging_dir_created.txt':
#      content => "textgrid_staging_dir_created=true",
#    }
  }

}
