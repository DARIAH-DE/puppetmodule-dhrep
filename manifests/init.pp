# == Class: dhrep
#
# Setup and manage a dhrep server with scope "textgrid" or "dariah".
#
class dhrep (
  # generic refs
  $scope = undef,
  $crud_log_level = undef,
  $crud_public_log_level = undef,
  $publish_log_level = undef,
  $elasticsearch_cluster_name = undef,
  $pid_user = undef,
  $pid_passwd = undef,
  $pid_prefix = undef,
  $pid_secret = undef,
  $public_hostname = $::fqdn,
  $publish_pid_secret = undef,
  # textgrid specific refs
  $tgcrud_location = undef,
  $tgcrud_public_location = undef,
  $tgauth_binddn_pass = undef,
  $tgauth_user_binddn_pass = undef,
  $tgauth_crud_secret = undef,
  $tgauth_slapd_rootpw = undef,
  $tgauth_authz_shib_pw = undef,
  $tgauth_authz_instance = undef,
  $tgauth_webauth_secret = undef,
  $tgauth_no_shib_login = undef,
  $tgconfserv_service_base_url = undef,
  $tgcrud_publish_secret = undef,
  $tgdatadirs_create_local_datadirs = undef,
  $tgnoid_crud_secret = undef,
  # dariah specific refs
  $dhcrud_location = undef,
  $dhcrud_storage_host = undef,
  $dhcrud_storage_host_public = undef,
  $dhcrud_pid_secret = undef,
  $dhcrud_public_location = undef,
  $dhcrud_public_storage_host = undef,
  $dhcrud_public_storage_host_public = undef,
  $dhcrud_public_pid_secret = undef,
  $dhpublish_cr_import_key = undef,
  #publikator
  $publikator_lock_to_group = undef,
) inherits dhrep::params {

  require dhrep::tools

  ###
  # folder creation
  ###
  file { $::dhrep::params::aptdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$::dhrep::params::vardir],
  }
  file { $::dhrep::params::backupdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$::dhrep::params::vardir],
  }
  file { $::dhrep::params::cachedir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }
  file { $::dhrep::params::confdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { $::dhrep::params::logdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { $::dhrep::params::optdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }
  file { $::dhrep::params::statdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0701',
    require => File[$::dhrep::params::vardir],
  }
  file { $::dhrep::params::vardir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  ###
  # tomcat
  ###
  if ($::lsbdistcodename == 'trusty') {
    service { 'tomcat7':
      ensure  => stopped,
      enable  => false,
      require => Package['tomcat7'],
    }
  } else {
    service { 'tomcat8':
      ensure  => stopped,
      enable  => false,
      require => Package['tomcat8'],
    }
  }

  ###
  # generic internal services used for both scopes
  ###
  class { 'dhrep::nginx':
    scope => $scope,
  }
  class { 'dhrep::resources::apache':
    scope => $scope,
  }
  class { 'dhrep::services::intern::elasticsearch':
    scope        => $scope,
    cluster_name => $elasticsearch_cluster_name,
  }
  class { 'dhrep::tools::scripts':
    scope => $scope,
  }
  class { 'dhrep::tools::cli':
    scope => $scope,
  }
  class { 'dhrep::services::tomcat_crud':
    scope => $scope,
  }
  class { 'dhrep::services::fits':
    scope => $scope,
  }
  class { 'dhrep::services::digilib':
    scope => $scope,
  }
  class { 'dhrep::services::intern::messaging':
    scope => $scope,
  }
  class { 'dhrep::services::intern::wildfly':
    scope => $scope,
  }
  class { 'dhrep::services::iiifmd':
    scope => $scope,
  }

  ###
  # services for scope textgrid configured here
  ###
  if $scope == 'textgrid' {
    class { 'dhrep::services::intern::sesame':
      scope => $scope,
    }
    class { 'dhrep::services::intern::tgnoid':
      scope       => $scope,
      before      => Class['dhrep::services::crud'],
      crud_secret => $tgnoid_crud_secret,
    }
    class { 'dhrep::services::intern::tgdatadirs':
      scope                 => $scope,
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
      no_shib_login    => $tgauth_no_shib_login,
    }
    class { 'dhrep::services::crud':
      scope          => $scope,
      location       => $tgcrud_location,
      publish_secret => $tgcrud_publish_secret,
      log_level      => $crud_log_level,
      require        => [Class['dhrep::services::intern::elasticsearch'], Class['dhrep::services::intern::sesame'],
      Class['dhrep::services::intern::wildfly']],
    }
    class { 'dhrep::services::crud_public':
      scope     => $scope,
      location  => $tgcrud_public_location,
      log_level => $crud_public_log_level,
      require   => [Class['dhrep::services::intern::elasticsearch'], Class['dhrep::services::intern::sesame'],
      Class['dhrep::services::intern::wildfly'], Class['dhrep::services::fits']],
    }
    class { 'dhrep::services::publish':
      scope        => $scope,
      pid_secret   => $publish_pid_secret,
      log_level    => $publish_log_level,
      storage_host => $dhcrud_storage_host,
    }
    class { 'dhrep::services::tgconfserv':
      service_base_url => $tgconfserv_service_base_url,
    }
    class { 'dhrep::services::aggregator':
      scope => $scope,
    }
    class { 'dhrep::static::textgridrep_website': }
    class { 'dhrep::static::textgridlab_org': }
    class { 'dhrep::services::tgsearch':
      scope   => $scope,
      require => [Class['dhrep::services::intern::elasticsearch'],
      Class['dhrep::services::intern::sesame'], Class['dhrep::services::tgauth']],
    }
    class { 'dhrep::services::tgsearch_public':
      scope   => $scope,
      require => [Class['dhrep::services::intern::elasticsearch'], Class['dhrep::services::intern::sesame']],
    }
    #class { 'dhrep::services::tgmarketplace': }
    class { 'dhrep::services::bughandler': }
  }

  ###
  # services for scope dariah following now (mainly due to different dependencies)
  ###
  if $scope == 'dariah' {
    class { 'dhrep::services::crud':
      scope               => $scope,
      location            => $dhcrud_location,
      storage_host        => $dhcrud_storage_host,
      storage_host_public => $dhcrud_storage_host_public,
      pid_secret          => $dhcrud_pid_secret,
      log_level           => $crud_log_level,
      require             => [Class['dhrep::services::intern::elasticsearch'], Class['dhrep::services::intern::wildfly'],  Class['dhrep::services::fits']],
    }
    class { 'dhrep::services::crud_public':
      scope               => $scope,
      location            => $dhcrud_public_location,
      storage_host        => $dhcrud_public_storage_host,
      storage_host_public => $dhcrud_public_storage_host_public,
      pid_secret          => $dhcrud_pid_secret,
      log_level           => $crud_public_log_level,
      require             => [Class['dhrep::services::intern::elasticsearch'], Class['dhrep::services::intern::wildfly']],
    }
    class { 'dhrep::services::publish':
      scope         => $scope,
      pid_secret    => $publish_pid_secret,
      log_level     => $publish_log_level,
      storage_host  => $dhcrud_storage_host,
      cr_import_key => $dhpublish_cr_import_key,
    }
    class { 'dhrep::services::publikator':
      scope   => $scope,
      require => Class['dhrep::services::publish'],
    }
    class { 'dhrep::static::repository_de_dariah_eu': }
  }

  ###
  # general external services declared now
  ###
  class { 'dhrep::services::pid':
    scope  => $scope,
    user   => $pid_user,
    passwd => $pid_passwd,
    prefix => $pid_prefix,
    secret => $pid_secret,
  }
  class { 'dhrep::services::oaipmh':
    scope   => $scope,
    require => Class['dhrep::services::intern::elasticsearch'],
  }

  # TODO: conditional just for migration from trusty to bionic, cleanup afterwards
  if ($::lsbdistcodename == 'trusty') {
    ###
    # java8
    ###
    package {
      'openjdk-6-jdk':          ensure => absent;
      'openjdk-6-jre':          ensure => absent;
      'openjdk-6-jre-headless': ensure => absent;
      'openjdk-6-jre-lib':      ensure => absent;
      'openjdk-7-jdk':          ensure => present;
      # Creates symlink /usr/lib/jvm/default-java.
      'default-jre-headless':   ensure => present;
      'maven':                  ensure => present;
      'make':                   ensure => present;
      'apache2-utils':          ensure => present;
    }
  } else {
    package {
      'openjdk-8-jdk-headless': ensure => present;
      'default-jre-headless':   ensure => present;  # wildfly?
    }
  }

  ###
  # open http and https ports (other ports are closed via dariah-common
  # firewall rules)
  ###
  firewall { '100 allow http and https access':
    dport  => [80, 443],
    proto  => tcp,
    action => accept,
  }

  ###
  # vagrant cachier changes this to symlink
  ###
  # FIXME UBBO: MUSS INS PROFILE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  unless $::vagrant {
#    file { $::dhrep::params::cachedir:
#      ensure => directory,
#    }
#  }
}
