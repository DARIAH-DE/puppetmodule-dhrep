# == Class: dhrep::services::tgsearch
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
  $scope,
  $ldap_host             = 'localhost',
  $binddn_pass           = '',
  $crud_secret           = '',
  $webauth_secret        = '',
  $sidcheck_secret       = '',
  $rbac_base             = "http://${::fqdn}/1.0/tgauth/",
  $authz_shib_pw         = '',
  $authz_instance        = '',
  $slapd_rootpw          = undef,
  $ldap_replication      = false,
  $ldap_clusternodes     = [],
  $no_shib_login         = false,
  $malloc                = '', # tcmalloc or jemalloc, default to glibc
){

  package {
    'slapd':                ensure => present;
    'ldap-utils':           ensure => present;
    'php5-ldap':            ensure => present;
    'db5.3-util':           ensure => present;
    'mailutils':            ensure => present;
  }

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin'],
  }

  ###
  # conf to etc
  ###

  file { "/etc/${scope}/tgauth":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${scope}"],
  }

  file { "/etc/${scope}/tgauth/conf":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File["/etc/${scope}/tgauth"],
  }

  file { "/etc/${scope}/tgauth/conf/rbac.conf":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/tgauth/conf/rbac.conf.erb'),
  }

  file { "/etc/${scope}/tgauth/conf/rbacSoap.conf":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/tgauth/conf/rbacSoap.conf.erb'),
  }

  file { "/etc/${scope}/tgauth/conf/system.conf":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/tgauth/conf/system.conf.erb'),
  }

  file { "/etc/${scope}/tgauth/conf/config_tgwebauth.xml":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/tgauth/conf/config_tgwebauth.xml.erb'),
  }

  file { '/var/www/tgauth/conf':
    ensure => link,
    target => "/etc/${scope}/tgauth/conf",
  }

  ###
  # /var/www/tgauth
  #
  # TODO Use GIT module for always getting a certain branch/tag, not clone via Exec!!
  ###

  exec { 'git_clone_tgauth':
    command => 'git clone git://git.projects.gwdg.de/tg-auth.git /usr/local/src/tgauth-git',
    #command => 'git clone git@git.projects.gwdg.de:tg-auth.git /usr/local/src/tgauth-git',
    #command => 'git clone http://git.projects.gwdg.de/tg-auth.git /usr/local/src/tgauth-git',
    creates => '/usr/local/src/tgauth-git',
    require => Package['git'],
  }

  file { '/var/www/tgauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac',
    recurse => true,
    mode    => '0644',
  }

  file { '/var/www/tgauth/rbacSoap/wsdl':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0644',
    #this dir needs to be there from above copy operation
    #require => File['/var/www/tgauth/rbacSoap'],
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl.erb'),
  }

  ###
  # /var/www/info.textgrid.middleware.tgauth.webauth
  ###
  file { '/var/www/info.textgrid.middleware.tgauth.webauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.webauth',
    recurse => true,
    mode    => '0644',
  }
  ->
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
    ensure  => link,
    target  => '/var/www/secure/',
    mode    => '0755',
    require => File['/var/www/1.0'],
  }

  ###
  # Nutzungsordnung
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

  # ldap needs to know its own id for mulit-master replikation
  augeas { 'slapd_default':
    changes => [
      "set /files/etc/default/slapd/SLAPD_SERVICES '\"ldap://localhost:389 ldap://${::fqdn}:389 ldapi:///\"'",
    ],
    notify  => Service['slapd'],
  }

  ###
  # use tcmalloc http://highlandsun.com/hyc/malloc/
  # http://directory.fedoraproject.org/docs/389ds/FAQ/memory-usage-research.html
  # or jmalloc  http://directory.fedoraproject.org/docs/389ds/FAQ/jemalloc-testing.html 
  # or keep default: glibc
  ###

  $archlibdir = $::architecture ? {
    'i386'  => 'i386-linux-gnu',
    'amd64' => 'x86_64-linux-gnu',
  }

  $preload_jemalloc_line = "export LD_PRELOAD=\"/usr/lib/${archlibdir}/libjemalloc.so.1\""
  $preload_tcmalloc_line = 'export LD_PRELOAD="/usr/lib/libtcmalloc_minimal.so.4"'

  case $malloc {
    'tcmalloc': {
        package { 'libtcmalloc-minimal4': ensure => present; }
        ->
        file_line { 'slapd_absent_jemalloc':
          ensure => absent,
          path   => '/etc/default/slapd',
          line   => $preload_jemalloc_line,
        }
        ->
        file_line { 'slapd_tcmalloc':
          path   => '/etc/default/slapd',
          line   => $preload_tcmalloc_line,
          notify => Service['slapd'],
        }
     }
     'jemalloc': {
        package { 'libjemalloc1': ensure => present; }
        ->
        file_line { 'slapd_absent_tcmalloc':
          ensure => absent,
          path   => '/etc/default/slapd',
          line   => $preload_tcmalloc_line,
        }
        ->
        file_line { 'slapd_jemalloc':
          path   => '/etc/default/slapd',
          line   => $preload_jemalloc_line,
          notify => Service['slapd'],
        }
     }
     default: {
        file_line { 'slapd_absent_jemalloc':
          ensure => absent,
          path   => '/etc/default/slapd',
          line   => $preload_tcmalloc_line,
          notify => Service['slapd'],
        }
        file_line { 'slapd_absent_tcmalloc':
          ensure => absent,
          path   => '/etc/default/slapd',
          line   => $preload_jemalloc_line,
          notify => Service['slapd'],
        }
     }
  }

  # todo: changes group of /etc/ldap/schemas from root to staff, ok?
#  file { '/etc/ldap/schema/':
#    source  => '/usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac/ldap-schemas/',
#    recurse => true,
#    require => Exec['git_clone_tgauth'],
#  }

  # test
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

  # apache config, apache should be there (e.g. by dhrep::init.pp or dariah profile::apache)
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
    <Directory \"/var/www/tgauth/rbacSoap\">
      Options +FollowSymLinks -Indexes
      Require all granted
    </Directory>
    ",
    notify => Service['apache2']
  }

  # Configure LDAP backup and unused logfile removing.
  file { '/var/textgrid/backups/' :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => File['/var/textgrid'],
  }
  file { '/var/textgrid/backups/ldap' :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => File['/var/textgrid/backups'],
  }
  file { '/opt/dhrep' :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }
  file { '/opt/dhrep/ldap-backup.sh' :
    source  => 'puppet:///modules/dhrep/opt/dhrep/ldap-backup.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => [File['/opt/dhrep'],File['/var/textgrid/backups/ldap']]
  }
  cron { 'ldap-backup' :
    command => '/opt/dhrep/ldap-backup.sh > /dev/null',
    user    => 'root',
    hour    => 22,
    minute  => 03,
  }

  # Configure LDAP statistics.
  file { '/var/textgrid/statistics' :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => File['/var/textgrid'],
  }
  file { '/var/textgrid/statistics/ldap' :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => File['/var/textgrid'],
  }
  file { '/opt/dhrep/ldap-statistic.pl' :
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('dhrep/opt/dhrep/ldap-statistic.pl.erb'),
    require => [File['/opt/dhrep'],File['/var/textgrid/statistics']],
  }
  cron { 'ldap-statistic' :
    command  => '/opt/dhrep/ldap-statistic.pl -a -c /var/textgrid/statistics/ldap/rbacusers-`date --iso`.csv -u /var/textgrid/statistics/ldap/rbacusers-`date --iso`.txt > /dev/null',
    user     => 'root',
    hour     => 23,
    minute   => 53,
    monthday => 01,
  }

}
