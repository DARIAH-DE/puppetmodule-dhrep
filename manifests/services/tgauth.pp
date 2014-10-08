# == Class: textgrid::services::tgsearch
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
class textgrid::services::tgauth (
  $ldap_host = '',
  $binddn_pass = '',
  $crud_secret = '',
  $webauth_secret = '',
  $sidcheck_secret = '',
  $rbac_base = '',
  $rbac_local_base = 'http://localhost:8080/tgauth/',
  $webauth_dariah_secret = '',
  $authz_shib_pw = '',
  $authz_name_secret = '',
  $authz_instance = '',
  $slapd_pass = '',
){

  package {
    'slapd':                ensure => present;
    'ldap-utils':           ensure => present;
    'php5-ldap':            ensure => present;
  }

  # TODO: possibly we want a require here
  # http://localhost:9292/puppet/latest/reference/lang_relationships.html#the-require-function
  include textgrid::resources::apache

  Exec {
    path    => ['/usr/bin','/bin','/usr/sbin'],
  }

  ###
  # conf to etc
  ###

  file { '/etc/textgrid/tgauth':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/etc/textgrid'],
  }

  file { '/etc/textgrid/tgauth/conf':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/etc/textgrid/tgauth'],
  }

  file { '/etc/textgrid/tgauth/conf/rbac.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgauth/conf/rbac.conf.erb'),
  }

  file { '/etc/textgrid/tgauth/conf/rbacSoap.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgauth/conf/rbacSoap.conf.erb'),
  }

  file { '/etc/textgrid/tgauth/conf/system.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgauth/conf/system.conf.erb'),
  }

  file { '/etc/textgrid/tgauth/conf/config_tgwebauth.xml':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/etc/textgrid/tgauth/conf/config_tgwebauth.xml.erb'),
  }

  file { '/var/www/tgauth/conf':
    ensure => link,
    target => '/etc/textgrid/tgauth/conf',
  }

  ###
  # /var/www/tgauth
  ###

  # anonymous git is broken at gwdg right now
  exec { 'git_clone_tgauth':
    #command => 'git clone git:/git.projects.gwdg.de/tg-auth.git /usr/local/src/tgauth-git',
    #command => 'git clone git@git.projects.gwdg.de:tg-auth.git /usr/local/src/tgauth-git',
    command => 'git clone http://git.projects.gwdg.de/tg-auth.git /usr/local/src/tgauth-git',
    creates => '/usr/local/src/tgauth-git',
    require => Package['git'],
  }

  file { '/var/www/tgauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac',
    recurse => true,
  }

  file {
    '/var/www/tgauth/rbacSoap/wsdl':
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
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgadministration.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgextra-crud.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgextra.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgreview.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgsystem.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra.local.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgextra.local.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgreview.local.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgreview.local.wsdl.erb'),
  }

  file { '/var/www/tgauth/rbacSoap/wsdl/tgsystem.local.wsdl':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgsystem.local.wsdl.erb'),
  }

  ###
  # /var/www/info.textgrid.middleware.tgauth.webauth
  ###
  file { '/var/www/info.textgrid.middleware.tgauth.webauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.webauth',
    recurse => true,
  }

  ###
  # ldap config
  ###
  file { '/etc/ldap/ldap.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('textgrid//etc/ldap/ldap.conf.erb'),
  }

  # todo: changes group of /etc/ldap/schemas from root to staff, ok?
  file { '/etc/ldap/schema/':
    source  => '/usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac/ldap-schemas/',
    recurse => true,
    require => Exec['git_clone_tgauth'],
  }

# this does not work, as generate functions are executed first, so the slappasswd from ldap-utils 
# is not yet installed
#  $slapd_pass_sha = generate('/usr/sbin/slappasswd', '-s', $slapd_pass)
  # /usr/sbin/slappasswd -s secret
  $slapd_pass_sha = '{SSHA}27SkyYHMenDPBiWZJsPkx1YlQeAnl+kU' 

  file { '/etc/ldap/slapd.conf':
    ensure  => present,
    owner   => 'openldap',
    group   => 'openldap',
    mode    => '0750',
    content => template('textgrid/etc/ldap/slapd.conf.erb'),
    require => Package['slapd'],
  }
  ~>
  exec { 'slapdconf_to_cn_p1':
    command => 'mv /etc/ldap/slapd.d /etc/ldap/slapd.d.orig',
    refreshonly => true,
  } 
  ~>
  file { '/etc/ldap/slapd.d':
    ensure => directory,
    owner  => 'openldap',
    group  => 'openldap',
  }
  ~>
  exec { 'slapdconf_to_cn_p2':
    command     => 'slaptest -f /etc/ldap/slapd.conf -F /etc/ldap/slapd.d/',
    refreshonly => true,
    user        => 'openldap',
    notify      => [Exec['ldapadd_ldap_template'],Service['slapd']],
  }

  file { '/tmp/ldap-template.ldif':
    ensure => present,
    source => 'puppet:///modules/textgrid/ldap/rbac-data.ldif',
  }

  # should only run once, if ldap template is added (with help of notify and refreshonly)
  exec { 'ldapadd_ldap_template':
    command     => "ldapadd -x -f /tmp/ldap-template.ldif -D \"cn=Manager,dc=textgrid,dc=de\" -w ${slapd_pass}",
    refreshonly => true,
    require     => [Package['ldap-utils'], File['/tmp/ldap-template.ldif'], Service['slapd']],    
    logoutput   => true,
  }

  service{ 'slapd':
    ensure  => running,
    enable  => true,
#    require => [Package['slapd'], File['/etc/ldap/slapd.conf']],
    require => Package['slapd'],
  }

}
