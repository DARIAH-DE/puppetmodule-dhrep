# == Class: textgrid
#
# setup and manage a textgrid server
#
# TODO  read https://dev2.dariah.eu/wiki/display/TGINT/textgrid-esx1.gwdg.de
#       and write the manifests ;-)
#
class dhrep (
  $scope              = 'textgrid',
  $tgauth_binddn_pass = undef,
  $tgauth_crud_secret = undef,
  $tgelasticsearch_cluster_name = undef,

  $tgauth_slapd_rootpw = undef,
  $tgauth_authz_shib_pw = undef,
  $tgauth_webauth_secret = undef,
  $tgnoid_tgcrud_secret = undef,

){


  class { 'dhrep::services::tgauth':
    scope       => $scope,
    binddn_pass => $tgauth_binddn_pass,
    crud_secret => $tgauth_crud_secret,
  }

  class { 'dhrep::services::aggregator':
    scope => $scope,
  }

  if $scope == 'textgrid' {
    class { 'dhrep::services::confserv': }
  }

  class { 'dhrep::services::crud':
    scope   => $scope,
    require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame'],Class['dhrep::services::tgauth']]
  }

  class { 'dhrep::services::crud_public':
    scope   => $scope,
    require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame']]
  }

  class { 'dhrep::services::digilib':
    scope => $scope,
  }

  class { 'dhrep::services::oaipmh':
    scope   => $scope,
    require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame']]
  }

  class { 'dhrep::services::pid':
    scope => $scope,
  }

  class { 'dhrep::services::publish':
    scope => $scope,
  }

  class { 'dhrep::services::intern::tgelasticsearch':
    scope        => $scope,
    cluster_name => $tgelasticsearch_cluster_name,
  }

  class { 'dhrep::services::intern::sesame':
    scope => $scope,
  }
  class { 'dhrep::services::intern::tgwildfly':
    scope => $scope,
  }
  class { 'dhrep::services::intern::messaging':
    scope => $scope,
  }

  if $scope == 'textgrid' {

    class { 'dhrep::services::textgridrep_website': }
    
    class { 'dhrep::services::tgsearch':
      require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame'],Class['dhrep::services::tgauth']],
    }
    class { 'dhrep::services::tgsearch_public':
      require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame']],
    }

    class { 'dhrep::services::intern::tgnoid':
      before        => Class['dhrep::services::crud'],
      tgcrud_secret => $tgnoid_tgcrud_secret,
    }

  }

  #  include textgrid::tgnginx

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
    'apache2-utils':            ensure => present;
  }

  # open http and https ports (other ports are closed via dariah-common firewall rules)
  firewall { '100 allow http and https access':
    port   => [80, 443],
    proto  => tcp,
    action => accept,
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

  $tgcache = '/var/cache/textgrid/'
  # vagrant cachier changes this to symlink
  unless $::vagrant {
    file { $tgcache :
      ensure => directory,
    }
  }

}
