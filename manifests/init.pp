# == Class: textgrid
#
# setup and manage a textgrid server
#
# TODO  read https://dev2.dariah.eu/wiki/display/TGINT/textgrid-esx1.gwdg.de
#       and write the manifests ;-)
#
class dhrep (
  $scope = 'textgrid',
  $tgauth_binddn_pass = undef,
  $tgauth_crud_secret = undef,
  $tgauth_slapd_rootpw = undef,
  $tgauth_authz_shib_pw = undef,
  $tgauth_authz_instance = undef,
  $tgauth_webauth_secret = undef,
  $tgelasticsearch_cluster_name = 'testing',
  $tgnoid_tgcrud_secret = undef,
  $crud_publish_secret = undef,
  $datadirs_create_local_datadirs = undef,
  $confserv_service_base_url = undef,
  $oracle_jdk8 = false,
) inherits dhrep::params {

  # internal services containing variables used by other modules need to be evaluated in order
  class { 'dhrep::services::tgauth':
    scope          => $scope,
    binddn_pass    => $tgauth_binddn_pass,
    crud_secret    => $tgauth_crud_secret,
    slapd_rootpw   => $tgauth_slapd_rootpw,
    authz_instance => $tgauth_authz_instance,
    authz_shib_pw  => $tgauth_authz_shib_pw,
    webauth_secret => $tgauth_webauth_secret,
  }

  class { 'dhrep::services::intern::tgelasticsearch':
    scope        => $scope,
    cluster_name => $tgelasticsearch_cluster_name,
  }

  class { 'dhrep::resources::apache': 
    scope => $scope,
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

  class { 'dhrep::services::aggregator':
    scope => $scope,
  }

  if $scope == 'textgrid' {
    class { 'dhrep::services::intern::tgnoid':
      before        => Class['dhrep::services::crud'],
      tgcrud_secret => $tgnoid_tgcrud_secret,
    }
  }

  class { 'dhrep::services::crud':
    scope          => $scope,
    publish_secret => $crud_publish_secret,
    require        => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame']]
  }

  class { 'dhrep::services::crud_public':
    scope   => $scope,
    require => [Class['dhrep::services::intern::tgelasticsearch'],
                Class['dhrep::services::intern::sesame']]
  }

  class { 'dhrep::services::digilib':
    scope => $scope,
  }

  class { 'dhrep::services::iiifmd':
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
    scope     => $scope,
  }

  if $scope == 'textgrid' {

    class { 'dhrep::services::confserv':
      service_base_url => $confserv_service_base_url,
    }

    class { 'dhrep::services::intern::datadirs':
      create_local_datadirs => $datadirs_create_local_datadirs,
    }

    class { 'dhrep::static::textgridrep_website': }

    class { 'dhrep::static::textgridlab_org': }

    class { 'dhrep::services::tgsearch':
      require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame'],Class['dhrep::services::tgauth']],
    }
    class { 'dhrep::services::tgsearch_public':
      require => [Class['dhrep::services::intern::tgelasticsearch'],Class['dhrep::services::intern::sesame']],
    }

    class { 'dhrep::services::tgmarketplace': }

    class { 'dhrep::tools::check_services': }

  }

  #  include textgrid::tgnginx

  ###
  # java8 we want,
  # openjdk-r does not seem to be up to date, so oracle for now
  ###

  #  apt::ppa { 'ppa:openjdk-r/ppa': }
  #  package {
  #    'openjdk-8-jdk':            ensure => present;
  #  }
  #  ->

  if $oracle_jdk8 {
    # copied from https://github.com/Spantree/puppet-java8/blob/master/manifests/init.pp
    # ubuntu specific, for debian look at above link
    # accept license
    file { '/tmp/java.preseed':
      source => 'puppet:///modules/liferay/oracle-java.preseed',
      mode   => '0600',
      backup => false,
    }

    apt::ppa { 'ppa:webupd8team/java': }
    ->
    package {
      'oracle-java8-installer':
        ensure       => present,
        responsefile => '/tmp/java.preseed',
        require      => [Apt::Ppa['ppa:webupd8team/java'],File['/tmp/java.preseed']],
    }
    ->
    package { 'oracle-java8-set-default': ensure => present }

  } else {
    apt::ppa { 'ppa:webupd8team/java': ensure => absent }
    package { 
      'oracle-java8-set-default': ensure => absent;
      'oracle-java8-installer':   ensure => absent;
    }
  }

  ###
  # /java8
  ###

  package {
    'openjdk-6-jdk':            ensure => absent;
    'openjdk-6-jre':            ensure => absent;
    'openjdk-6-jre-headless':   ensure => absent;
    'openjdk-6-jre-lib':        ensure => absent;
    'openjdk-7-jdk':            ensure => present;
    'default-jre-headless':     ensure => present; # creates symlink /usr/lib/jvm/default-java
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

  file { "/etc/${scope}":
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
