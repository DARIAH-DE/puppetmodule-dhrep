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
  $scope = undef,
  $ldap_host = 'localhost',
  $ldap_port = '389',
  $binddn_pass = undef,
  $user_ldap_host = 'auth.de.dariah.eu',
  $user_ldap_port = '389',
  $user_binddn_pass = undef,
  $crud_secret = undef,
  $webauth_secret = undef,
  $sidcheck_secret = undef,
  $rbac_base = "http://${::fqdn}/1.0/tgauth/",
  $authz_shib_pw = undef,
  $authz_instance = undef,
  $slapd_rootpw = undef,
  $ldap_replication = false,
  $ldap_clusternodes = [],
  $no_shib_login = false,
  $ldap_dbmaxsize = 10485760, # default value 10485760 bytes = 10mb
  $ldapcleaner_older_than = 'OLDER_THAN8D',
  $sid_redirect_domains_allowed = [],
) inherits dhrep::params {

  $_backupdir = $::dhrep::params::backupdir
  $_confdir   = $::dhrep::params::confdir
  $_logdir    = $::dhrep::params::logdir
  $_optdir    = $::dhrep::params::optdir
  $_statdir   = $::dhrep::params::statdir
  $_vardir    = $::dhrep::params::vardir

  $_daasidir  = '/opt/daasi'

  ###
  # package definition for bionic
  ###
  package {
    'slapd':        ensure => present;
    'ldap-utils':   ensure => present;
    'db5.3-util':   ensure => present;
    'mailutils':    ensure => present;
    'php-ldap':     ensure => present;
    'php-mbstring': ensure => present;
    'php-xml':      ensure => present;
    'php-soap':     ensure => present;
  }

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin'],
  }

  ###
  # conf to etc
  ###
  file { "${_confdir}/tgauth":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_confdir],
  }
  file { "${_confdir}/tgauth/conf":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_confdir}/tgauth"],
  }
  file { "${_confdir}/tgauth/conf/rbac.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/rbac.conf.erb"),
  }
  file { "${_confdir}/tgauth/conf/rbacSoap.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/rbacSoap.conf.erb"),
  }
  file { "${_confdir}/tgauth/conf/system.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/system.conf.erb"),
  }
  file { "${_confdir}/tgauth/conf/config_tgwebauth.xml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/${_confdir}/tgauth/conf/config_tgwebauth.xml.erb"),
  }
  file { "${_confdir}/tgauth/redirectSidConfig.php":
    ensure  => file,
    content => epp("dhrep/${_confdir}/tgauth/redirectSidConfig.php.epp", {
      domains  => $sid_redirect_domains_allowed,
      other => ['abc', 'def'],
    }),
  }

  ###
  # installing tgauth deb package
  # -- installs
  #      info.textgrid.middleware.tgauth.rbac
  #    and
  #      info.textgrid.middleware.tgauth.webauth
  #    to /var/www/
  # -- create symlinks to
  #      ~WebAuthN --> info.textgrid.middleware.tgauth.webauth/WebAuthN
  #      ~secure   --> info.textgrid.middleware.tgauth.webauth/secure
  #      ~tgauth   --> info.textgrid.middleware.tgauth.rbac
  ###
  package { 'tgauth':
    ensure  => latest,
    require => [Exec['update_dariah_apt_repository'], File['/var/www']],
  }
  file { '/var/www/tgauth':
    ensure  => link,
    target  => '/var/www/info.textgrid.middleware.tgauth.rbac',
    mode    => '0755',
    require => Package['tgauth'],
  }
  file { '/var/www/tgauth/conf':
    ensure  => link,
    target  => "${_confdir}/tgauth/conf",
    require => File['/var/www/tgauth'],
  }

  ###
  # installing config files
  ###
  file { '/var/www/tgauth/rbacSoap/wsdl':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }
  file { '/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl.erb'),
    require => File['/var/www/tgauth'],
  }

  ###
  # /var/www/info.textgrid.middleware.tgauth.webauth
  ###
  file { '/var/www/info.textgrid.middleware.tgauth.webauth/i18n_cache':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => Package['tgauth'],
  }
  file { '/var/www/WebAuthN':
    ensure  => link,
    target  => '/var/www/info.textgrid.middleware.tgauth.webauth/WebAuthN/',
    mode    => '0755',
    require => Package['tgauth'],
  }
  file { '/var/www/secure':
    ensure  => link,
    target  => '/var/www/info.textgrid.middleware.tgauth.webauth/secure/',
    mode    => '0755',
    require => Package['tgauth'],
  }
  file { '/var/www/1.0':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => Package['tgauth'],
  }
  file { '/var/www/1.0/secure':
    ensure  => link,
    target  => '/var/www/secure/',
    mode    => '0755',
    require => File['/var/www/1.0'],
  }

  ###
  # shibboleth config (set IdP's entityID)
  ###
  file { '/var/www/WebAuthN/js/dariah.js':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
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
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/etc/ldap/ldap.conf.erb'),
  }

  # TODO ldap needs to know its own id for multi-master replikation
  #  augeas { 'slapd_default':
  #    changes => [
  #      "set /files/etc/default/slapd/SLAPD_SERVICES '\"ldap://localhost:389 ldap://${::fqdn}:389 ldapi:///\"'",
  #    ],
  #    notify  => Service['slapd'],
  #  }

  # TODO changes group of /etc/ldap/schemas from root to staff, ok?
  #  file { '/etc/ldap/schema/':
  #    source  => '/usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac/ldap-schemas/',
  #    recurse => true,
  #    require => Exec['git_clone_tgauth'],
  #  }

  ###
  # create init ldap files for ldap creation
  ###
  file { "${_optdir}/ldap-init":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0701',
    require => Service['slapd'],
  }

  # set root ldap password and create init ldap ldfis and init script.
  $slapd_rootpw_sha = sha1digest($slapd_rootpw)

  file { "${_optdir}/ldap-init/ldap-cn-config.ldif":
    ensure  => file,
    content => template('dhrep/ldap/ldap-cn-config.ldif.erb'),
    require => File["${_optdir}/ldap-init"],
  }
  file { "${_optdir}/ldap-init/tgldapconf.sh":
    source  => 'puppet:///modules/dhrep/ldap/tgldapconf.sh',
    mode    => '0744',
    require => File["${_optdir}/ldap-init"],
  }
  file { "${_optdir}/ldap-init/ldap-rbac-template.ldif":
    ensure  => file,
    content => template('dhrep/ldap/rbac-data.ldif.erb'),
    require => File["${_optdir}/ldap-init"],
  }

  # NOTE database creation is now done by /opt/dhrep/init_databases.sh
  service{ 'slapd':
    ensure  => running,
    enable  => true,
    require => Package['slapd'],
  }

  ###
  # apache config, apache should be set up already (e.g. by dhrep::init.pp or
  # dariah profile::apache)
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
    notify  => Service['apache2'],
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
    require => [File[$_optdir],File["${_backupdir}/ldap"]],
  }
  cron { 'ldap-backup' :
    command => "${_optdir}/ldap-backup.sh > /dev/null 2>&1",
    user    => 'root',
    hour    => 21,
    minute  => '53',
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
    monthday => '01',
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
  # ldapcleaner
  ###
  # install perl-DAASIlib from ci.de.dariah.eu/packages/
  package {
    'libapache-dbi-perl': ensure => present;
    'libfile-flock-perl': ensure => present;
    'perl-daasilib':      ensure => present;
  }
  # install needed dirs
  file { $_daasidir :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_daasidir}/ldapcleaner" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_daasidir],
  }
  file { "${_daasidir}/ldapcleaner/etc" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_daasidir}/ldapcleaner"],
  }
  file { "${_daasidir}/ldapcleaner/man" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_daasidir}/ldapcleaner"],
  }
  file { "${_daasidir}/ldapcleaner/lib" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_daasidir}/ldapcleaner"],
  }
  # create needed files
  file { "${_daasidir}/ldapcleaner/ldapcleaner.pl" :
    source  => "puppet:///modules/dhrep/opt/daasi/${scope}/ldapcleaner/ldapcleaner.pl",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_daasidir}/ldapcleaner"],
  }
  file { "${_daasidir}/ldapcleaner/etc/ldapcleaner.sys" :
    source  => "puppet:///modules/dhrep/opt/daasi/${scope}/ldapcleaner/ldapcleaner.sys",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File["${_daasidir}/ldapcleaner/etc"],
  }
  file { "${_daasidir}/ldapcleaner/man/ldapcleaner.man" :
    source  => "puppet:///modules/dhrep/opt/daasi/${scope}/ldapcleaner/ldapcleaner.man",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File["${_daasidir}/ldapcleaner/man"],
  }
  file { "${_daasidir}/ldapcleaner/lib/DARIAHlib.pm" :
    source  => "puppet:///modules/dhrep/opt/daasi/${scope}/ldapcleaner/DARIAHlib.pm",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File["${_daasidir}/ldapcleaner/lib"],
  }
  # create more needed folders and files: cleanRbacSIDs.conf, and localldap.secret
  file { "${_daasidir}/cleanRbacSIDs" :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$_daasidir],
  }
  file { "${_daasidir}/cleanRbacSIDs/cleanRbacSIDs.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("dhrep/opt/daasi/${scope}/ldapcleaner/cleanRbacSIDs.conf.erb"),
    require => File["${_daasidir}/cleanRbacSIDs"],
  }
  file { "${_daasidir}/cleanRbacSIDs/localldap.secret":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("dhrep/opt/daasi/${scope}/ldapcleaner/localldap.secret.erb"),
    require => File["${_daasidir}/cleanRbacSIDs"],
  }
  # add cron for ldapcleaner
  cron { 'ldap-cleaner' :
    command => "${_daasidir}/ldapcleaner/ldapcleaner.pl -c ${_daasidir}/cleanRbacSIDs/cleanRbacSIDs.conf > /dev/null 2>&1",
    user    => 'root',
    hour    => 2,
    minute  => 31,
  }

  ###
  # monitor slapd with telegraf
  ###
  telegraf::input { 'slapd_procstat':
    plugin_type => 'procstat',
    options     => [{
        'pid_file' => '/var/run/slapd/slapd.pid',
    }],
  }
}
