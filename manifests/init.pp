# == Class: dhrep
#
# Setup and manage a dhrep server with scope "textgrid" or "dariah".
#
class dhrep (
  $scope = undef,
  $public_hostname = $::fqdn,
  $elasticsearch_cluster_name = undef,
  $crud_publish_secret = undef,
  $oracle_jdk8 = false,

  ###
  # textgrid specific refs defined here
  ###
  $tgauth_binddn_pass = undef,
  $tgauth_user_binddn_pass = undef,
  $tgauth_crud_secret = undef,
  $tgauth_slapd_rootpw = undef,
  $tgauth_authz_shib_pw = undef,
  $tgauth_authz_instance = undef,
  $tgauth_webauth_secret = undef,
  $tgnoid_tgcrud_secret = undef,
  $tgdatadirs_create_local_datadirs = undef,
  $tgconfserv_service_base_url = undef,
) inherits dhrep::params {

  ###
  # generic internal services used for both scopes
  ###
  class { 'dhrep::services::intern::elasticsearch':
    scope        => $scope,
    cluster_name => $elasticsearch_cluster_name,
  }
  class { 'dhrep::tools::check_services':
    scope => $scope,
  }
  class { 'dhrep::nginx':
    scope => $scope,
  }

  ###
  # services for scope textgrid configured here
  ###
  if $scope == 'textgrid' {
    class { 'dhrep::services::intern::tgwildfly':
      scope => $scope,
    }
    class { 'dhrep::resources::apache':
      scope => $scope,
    }
    class { 'dhrep::services::intern::sesame':
      scope => $scope,
    }
    class { 'dhrep::services::intern::tgnoid':
      before        => Class['dhrep::services::crud'],
      tgcrud_secret => $tgcrud_secret,
    }
    class { 'dhrep::services::intern::tgdatadirs':
      create_local_datadirs => $tgdatadirs_create_local_datadirs,
    }
    class { 'dhrep::services::tgauth':
      scope            => $scope,
      binddn_pass      => $tgauth_binddn_pass,
      user_binddn_pass => $tgauth_user_binddn_pass,
      crud_secret      => $tgauth_crud_secret,
      slapd_rootpw     => $tgauth_slapd_rootpw,
      authz_instance   => $tgauth_authz_instance,
      authz_shib_pw    => $tgauth_authz_shib_pw,
      webauth_secret   => $tgauth_webauth_secret,
    }
    class { 'dhrep::services::intern::messaging':
      scope => $scope,
    }
    class { 'dhrep::services::crud':
      scope          => $scope,
      publish_secret => $crud_publish_secret,
      require        => [Class['dhrep::services::intern::elasticsearch'],Class['dhrep::services::intern::sesame'],Class['dhrep::services::intern::tgwildfly']],
    }
    class { 'dhrep::services::crud_public':
      scope   => $scope,
      require => [Class['dhrep::services::intern::elasticsearch'],Class['dhrep::services::intern::sesame'],Class['dhrep::services::intern::tgwildfly']],
    }
    class { 'dhrep::services::tgconfserv':
      service_base_url => $tgconfserv_service_base_url,
    }
    class { 'dhrep::services::digilib':
      scope => $scope,
    }
    class { 'dhrep::services::iiifmd':
      scope => $scope,
    }
    class { 'dhrep::services::aggregator':
      scope => $scope,
    }
    class { 'dhrep::static::textgridrep_website': }
    class { 'dhrep::static::textgridlab_org': }
    class { 'dhrep::services::tgsearch':
      require => [Class['dhrep::services::intern::elasticsearch'],Class['dhrep::services::intern::sesame'],Class['dhrep::services::tgauth']],
    }
    class { 'dhrep::services::tgsearch_public':
      require => [Class['dhrep::services::intern::elasticsearch'],Class['dhrep::services::intern::sesame']],
    }
    class { 'dhrep::services::tgmarketplace': }
  }

  ###
  # services for scope dariah following now (mainly due to different dependencies)
  ###
  if $scope == 'dariah' {
    class { 'dhrep::services::fits':
      scope  => $scope,
    }
    class { 'dhrep::services::crud':
      scope          => $scope,
      publish_secret => $crud_publish_secret,
      require        => Class['dhrep::services::intern::elasticsearch'],
    }
    class { 'dhrep::services::crud_public':
      scope   => $scope,
      require => Class['dhrep::services::intern::elasticsearch'],
    }
  }

  ###
  # general external services declared now
  ###
  class { 'dhrep::services::pid':
    scope => $scope,
  }
  class { 'dhrep::services::oaipmh':
    scope   => $scope,
    require => Class['dhrep::services::intern::elasticsearch'],
  }
  class { 'dhrep::services::publish':
    scope => $scope,
  }

  ###
  # java8 we want! openjdk-r does not seem to be up to date, so oracle for now
  ###
  if $oracle_jdk8 {
    # copied from
    # https://github.com/Spantree/puppet-java8/blob/master/manifests/init.pp
    # Ubuntu specific, for debian look at above link
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
    'openjdk-6-jdk':          ensure => absent;
    'openjdk-6-jre':          ensure => absent;
    'openjdk-6-jre-headless': ensure => absent;
    'openjdk-6-jre-lib':      ensure => absent;
    'openjdk-7-jdk':          ensure => present;
    # Creates symlink /usr/lib/jvm/default-java.
    'default-jre-headless':   ensure => present;
    'tomcat7':                ensure => present;
    'tomcat7-user':           ensure => present;
    'libtcnative-1':          ensure => present;
    'mc':                     ensure => present;
    'maven':                  ensure => present;
    'make':                   ensure => present;
    'apache2-utils':          ensure => present;
  }

  ###
  # open http and https ports (other ports are closed via dariah-common
  # firewall rules)
  ###
  firewall { '100 allow http and https access':
    port   => [80, 443],
    proto  => tcp,
    action => accept,
  }

  ###
  # folder creation
  ###
  file { $::dhrep::params::confdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { $::dhrep::params::logdir:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { $::dhrep::params::vardir:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { $::dhrep::params::backupdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$::dhrep::params::vardir],
  }
  file { $::dhrep::params::statdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0701',
    require => File[$::dhrep::params::vardir],
  }
  file { $::dhrep::params::optdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }

  ###
  # tomcat
  ###
  service { 'tomcat7':
    ensure  => stopped,
    enable  => false,
    require => Package['tomcat7'],
  }

  ###
  # facter
  ###
  # we want to use custom facts (TODO: is there an existing puppet plugin?)
  file { '/etc/facter/':
    ensure => directory,
  }
  file { '/etc/facter/facts.d':
    ensure  => directory,
  }

  ###
  # vagrant cachier changes this to symlink
  ###
  unless $::vagrant {
    file { $::dhrep::params::cachedir:
      ensure => directory,
    }
  }
}
