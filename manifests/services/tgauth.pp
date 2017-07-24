# == Class: dhrep::services::tgauth
#
# Class to install and configure tgauth.
#
# === Parameters
#
# TODO
#   - param doku from someone who understands tgauth
#   - read https://dev2.dariah.eu/wiki/display/TGINT/TG-auth+Installation+und+Konfiguration
#     for completing this module
#
# possibly useful modules
#   https://github.com/gtmtechltd/puppet_ldapdn
#   https://forge.puppetlabs.com/datacentred/ldap
#   https://forge.puppetlabs.com/torian/ldap
#   https://forge.puppetlabs.com/camptocamp/openldap
#
class dhrep::services::tgauth (
  $scope             = undef,
  $ldap_host         = 'localhost',
  $ldap_port         = '389',
  $binddn_pass       = undef,
  $user_ldap_host    = 'auth.dariah.eu',
  $user_ldap_port    = '389',
  $user_binddn_pass  = undef,
  $crud_secret       = undef,
  $webauth_secret    = undef,
  $sidcheck_secret   = undef,
  $rbac_base         = "http://${::fqdn}/1.0/tgauth/",
  $authz_shib_pw     = undef,
  $authz_instance    = '',
  $slapd_rootpw      = undef,
  $ldap_replication  = false,
  $ldap_clusternodes = [],
  $no_shib_login     = false,
  $ldap_dbmaxsize    = 10485760, # default value 10485760 bytes = 10mb
) inherits dhrep::params {

  $_backupdir = $::dhrep::params::backupdir
  $_confdir   = $::dhrep::params::confdir
  $_logdir    = $::dhrep::params::logdir
  $_optdir    = $::dhrep::params::optdir
  $_statdir   = $::dhrep::params::statdir
  $_vardir    = $::dhrep::params::vardir

  apt::ppa { 'ppa:rtandy/openldap-backports': }
  ->
  package {
    'slapd':      ensure => present;
    'ldap-utils': ensure => present;
    'db5.3-util': ensure => present;
    'mailutils':  ensure => present;
    'php5-ldap':  ensure => present;
  }

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin'],
  }

  ###
  # conf to etc
  ###
  file { "${_confdir}/tgauth":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File[$_confdir],
  }
  file { "${_confdir}/tgauth/conf":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["${_confdir}/tgauth"],
  }
  file { "${_confdir}/tgauth/conf/rbac.conf":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/rbac.conf.erb"),
  }
  file { "${_confdir}/tgauth/conf/rbacSoap.conf":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/rbacSoap.conf.erb"),
  }
  file { "${_confdir}/tgauth/conf/system.conf":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/system.conf.erb"),
  }
  file { "${_confdir}/tgauth/conf/config_tgwebauth.xml":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/config_tgwebauth.xml.erb"),
  }
  file { '/var/www/tgauth/conf':
    ensure => link,
    target => "${_confdir}/tgauth/conf",
  }

  ### FIXME remove link is tgauth git master has been changed!
#  file { '/etc/textgrid/':
#    ensure  => directory,
#    owner   => root,
#    group   => root,
#    mode    => '0644',
#  }
#  file { '/etc/textgrid/tgauth':
#    ensure => link,
#    target => "${_confdir}/tgauth",
#    require => File['/etc/textgrid'],
#  }

  ###
  # /var/www/tgauth
  #
  # TODO Use GIT module for always getting a certain branch/tag, not clone via Exec!!
  ###
  exec { 'git_clone_tgauth':
    command => 'git clone git://git.projects.gwdg.de/tg-auth.git /usr/local/src/tgauth-git',
    creates => '/usr/local/src/tgauth-git',
    require => Package['git'],
  }
  ->
  file { '/var/www/tgauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac',
    recurse => true,
    mode    => '0644',
    require => File['/var/www'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0644',
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }

  ###
  # /var/www/info.textgrid.middleware.tgauth.webauth
  ###
  file { '/var/www/info.textgrid.middleware.tgauth.webauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.webauth',
    recurse => true,
    mode    => '0644',
    require => File[$_vardir],
  }
  file { '/var/www/info.textgrid.middleware.tgauth.webauth/i18n_cache':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => File['/var/www/info.textgrid.middleware.tgauth.webauth'],
  }
  file { '/var/www/WebAuthN':
    ensure  => link,
    target  => '/var/www/info.textgrid.middleware.tgauth.webauth/WebAuthN/',
    mode    => '0755',
    require => File['/var/www/info.textgrid.middleware.tgauth.webauth'],
  }
  file { '/var/www/secure':
    ensure  => link,
    target  => '/var/www/info.textgrid.middleware.tgauth.webauth/secure/',
    mode    => '0755',
    require => File['/var/www/info.textgrid.middleware.tgauth.webauth'],
  }
  file { '/var/www/1.0':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => File['/var/www/info.textgrid.middleware.tgauth.webauth'],
  }
  file { '/var/www/1.0/secure':
    ensure  => 'link',
    target  => '/var/www/secure/',
    mode    => '0755',
    require => File['/var/www/1.0'],
  }

  ###
  # shibboleth config (set IdP's entityID)
  ###
  file { '/var/www/WebAuthN/js/dariah.js':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/WebAuthN/js/dariah.js.erb'),
    require => File['/var/www/WebAuthN'],
  }

  ###
  # nutzungsordnung
  ###
  file { '/var/Nutzungsordnung_en_200611.txt.html':
    source => 'puppet:///modules/dhrep/var/Nutzungsordnung_en_200611.txt.html',
    mode   => '0644',
  }

  ###
  # ldap config
  ###
  file { '/etc/ldap/ldap.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/ldap/ldap.conf.erb'),
  }
  # ldap needs to know its own id for multi-master replikation
#  augeas { 'slapd_default':
#    changes => [
#      "set /files/etc/default/slapd/SLAPD_SERVICES '\"ldap://localhost:389 ldap://${::fqdn}:389 ldapi:///\"'",
#    ],
#    notify  => Service['slapd'],
#  }

  # todo: changes group of /etc/ldap/schemas from root to staff, ok?
  #  file { '/etc/ldap/schema/':
  #    source  => '/usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac/ldap-schemas/',
  #    recurse => true,
  #    require => Exec['git_clone_tgauth'],
  #  }

  ###
  # test
  ###
  file { '/tmp/ldap-cn-config-test.ldif':
    ensure  => present,
    content => template('dhrep/ldap/ldap-cn-config.ldif.erb'),
    require => Service['slapd'],
  }
  unless $tgauth_ldap_initialized {
      $slapd_rootpw_sha = sha1digest($slapd_rootpw)

      file { '/tmp/ldap-cn-config.ldif':
        ensure  => present,
        content => template('dhrep/ldap/ldap-cn-config.ldif.erb'),
        require => Service['slapd'],
      }
      ~>
      file { '/tmp/tgldapconf.sh':
        source => 'puppet:///modules/dhrep/ldap/tgldapconf.sh',
        mode   => '0744',
      }
      ~>
      exec { 'tgldapconf.sh':
        command => '/tmp/tgldapconf.sh',
        require => [Package['slapd'],File['/tmp/ldap-cn-config.ldif']],
      }
      ~>
      file { '/tmp/ldap-rbac-template.ldif':
        ensure  => present,
        content => template('dhrep/ldap/rbac-data.ldif.erb'),
      }
      ~>
      # should only run once, if ldap template is added (with help of notify and refreshonly)
      exec { 'ldapadd_ldap_template':
        command     => "ldapadd -x -f /tmp/ldap-rbac-template.ldif -D \"cn=Manager,dc=textgrid,dc=de\" -w ${slapd_rootpw}",
        refreshonly => true,
        require     => [Package['ldap-utils'], Service['slapd']],
        logoutput   => true,
      }
      ->
      file {'/etc/facter/facts.d/tgauth_ldap_initialized.txt':
        content => 'tgauth_ldap_initialized=true',
      }
  }
  service{ 'slapd':
    ensure  => running,
    enable  => true,
    require => Package['slapd'],
  }

  ###
  # apache config, apache should be there (e.g. by dhrep::init.pp or dariah
  # profile::apache)
  ###
  file { "/etc/apache2/${scope}/default_vhost_includes/tgauth.conf":
    content => "
    # --------------------------------------------------------------------------
    # All the TG-auth and RBAC configuration
    # --------------------------------------------------------------------------

    <Location /secure>
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>

    <Location /1.0/secure>
      AuthType shibboleth
      ShibRequestSetting requireSession 1
      require valid-user
    </Location>

    Alias /tgauth /var/www/tgauth/rbacSoap
    <Directory /var/www/tgauth/rbacSoap>
      Options +FollowSymLinks -Indexes
      Require all granted
    </Directory>
    ",
    notify => Service['apache2'],
  }

  ###
  # configure ldap backup
  ###
  file { "${_backupdir}/ldap" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0701',
    require => File[$_backupdir],
  }
  file { "${_optdir}/ldap-backup.sh" :
    source  => "puppet:///modules/dhrep/${_optdir}/${scope}/ldap-backup.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => [File[$_optdir],File["${_backupdir}/ldap"]]
  }
  cron { 'ldap-backup' :
    command => "${_optdir}/ldap-backup.sh > /dev/null",
    user    => 'root',
    hour    => 22,
    minute  => 03,
  }

  ###
  # Configure ldap statistics
  ###
  file { "${_statdir}/ldap" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_vardir],
  }
  file { "${_optdir}/ldap-statistic.pl" :
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template("dhrep/opt/dhrep/${scope}/ldap-statistic.pl.erb"),
    require => [File[$_optdir],File["${_statdir}/ldap"]],
  }
  cron { 'ldap-statistic' :
    command  => "${_optdir}/ldap-statistic.pl -a -c ${_statdir}/ldap/rbacusers-`date --iso`.csv -u ${_statdir}/ldap/rbacusers-`date --iso`.txt > /dev/null",
    user     => 'root',
    hour     => 23,
    minute   => 53,
    monthday => 01,
  }

  ###
  # nrpe for ldap, ldap-backup, and ldap-statistics
  ###
  nrpe::plugin { 'check_ldap':
    plugin => 'check_ldap',
    args   => '-H localhost -b dc=textgrid,dc=de -3',
  }
  file { "${_optdir}/check_ldap_statistics.sh" :
    source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/check_ldap_statistics.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_optdir}/ldap-statistic.pl"],
  }
  nrpe::plugin { 'check_ldap_statistics':
    plugin     => 'check_ldap_statistics.sh',
    libexecdir => $_optdir,
  }
  file { "${_optdir}/check_ldap_backups.sh" :
    source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/check_ldap_backups.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_optdir}/ldap-backup.sh"],
  }
  nrpe::plugin { 'check_ldap_backups':
    plugin     => 'check_ldap_backups.sh',
    libexecdir => $_optdir,
  }

  ###
  # monitor slapd with telegraf
  ###
  telegraf::input { 'slapd_procstat':
    plugin_type => 'procstat',
    options     => {
      'pid_file' => '/var/run/slapd/slapd.pid',
    }
  }

}
