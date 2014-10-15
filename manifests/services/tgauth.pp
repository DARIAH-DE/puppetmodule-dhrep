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
  $slapd_rootpw = '',
  $slapd_rootpw_sha1 = '',
  $slapd_rootpw_base64 = '',
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

# i guess the local wsdls are not needed anymore
#  file { '/var/www/tgauth/rbacSoap/wsdl/tgextra.local.wsdl':
#    ensure  => present,
#    owner   => root,
#    group   => root,
#    mode    => '0644',
#    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgextra.local.wsdl.erb'),
#  }

#  file { '/var/www/tgauth/rbacSoap/wsdl/tgreview.local.wsdl':
#    ensure  => present,
#    owner   => root,
#    group   => root,
#    mode    => '0644',
#    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgreview.local.wsdl.erb'),
#  }

#  file { '/var/www/tgauth/rbacSoap/wsdl/tgsystem.local.wsdl':
#    ensure  => present,
#    owner   => root,
#    group   => root,
#    mode    => '0644',
#    content => template('textgrid/var/www/tgauth/rbacSoap/wsdl/tgsystem.local.wsdl.erb'),
#  }

  ###
  # /var/www/info.textgrid.middleware.tgauth.webauth
  ###
  file { '/var/www/info.textgrid.middleware.tgauth.webauth':
    source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.webauth',
    recurse => true,
  } 
  ->
  file { '/var/www/info.textgrid.middleware.tgauth.webauth/i18n_cache':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }

  file { '/var/www/WebAuthN':
    ensure => link,
    target => '/var/www/info.textgrid.middleware.tgauth.webauth/WebAuthN/',
  }

  file { '/var/www/secure':
    ensure => link,
    target => '/var/www/info.textgrid.middleware.tgauth.webauth/secure/',
  }

  ###
  # Nutzungsordnung
  ###
  file { '/var/Nutzungsordnung_en_200611.txt.html':
    source => 'puppet:///modules/textgrid/var/Nutzungsordnung_en_200611.txt.html',
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
    content => template('textgrid//etc/ldap/ldap.conf.erb'),
  }

  # todo: changes group of /etc/ldap/schemas from root to staff, ok?
#  file { '/etc/ldap/schema/':
#    source  => '/usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac/ldap-schemas/',
#    recurse => true,
#    require => Exec['git_clone_tgauth'],
#  }

  unless $tgauth_ldap_initialized {
      $slapd_rootpw_sha = sha1digest($slapd_rootpw)

      file { '/tmp/ldap-cn-config.ldif':
        ensure  => present,
        content => template('textgrid//tmp/ldap-cn-config.ldif.erb'),
        require => Service['slapd'],
      } 
      ~>
      file { '/tmp/tgldapconf.sh':
        source => 'puppet:///modules/textgrid/ldap/tgldapconf.sh',
        mode   => '0744',   
      } 
      ~>
      exec { 'tgldapconf.sh':
        command => '/tmp/tgldapconf.sh',
        require => [Package['slapd'],File['/tmp/ldap-cn-config.ldif']],
      }
      ~>
      file { '/tmp/ldap-rbac-template.ldif':
        ensure => present,
        source => 'puppet:///modules/textgrid/ldap/rbac-data.ldif',
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
        content => "tgauth_ldap_initialized=true",
      }
  }

  service{ 'slapd':
    ensure  => running,
    enable  => true,
    require => Package['slapd'],
  }

}
