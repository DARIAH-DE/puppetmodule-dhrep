# == Class: dhrep::nginx
#
# Install and configure nginx.
#
# Set proxyconfig for forwarding local services via port 80.
#
class dhrep::nginx (
  $scope                              = undef,
  $tgsearch_toplevel_cache_expiration = '24h',
  $sslcert                            = undef,
  $sslkey                             = undef,
  $dhparam                            = undef,
) inherits dhrep::params {

  include dhrep::services::tomcat_aggregator
  include dhrep::services::tomcat_crud
  include dhrep::services::tomcat_digilib
  include dhrep::services::tomcat_oaipmh
  include dhrep::services::tomcat_publish
  include dhrep::services::tomcat_sesame
  include dhrep::services::tomcat_tgsearch

  $_confdir  = $::dhrep::params::confdir
  $templates = "dhrep/etc/dhrep/nginx/"

  package {
    'nginx'    : ensure => present;
    'ssl-cert' : ensure => present; # snakeoil cert for nginx
  }

  ###
  # ssl certs and keys
  ###
  case $sslcert {
    undef:      {
      $vhost_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
      $vhost_ssl_key  = '/etc/ssl/private/ssl-cert-snakeoil.key'
    }
    default: {
      $vhost_ssl_cert = "/etc/ssl/${::fqdn}.chain.cert.pem"
      $vhost_ssl_key  = "/etc/ssl/${::fqdn}.key.pem"
    }
  }
  # TODO: for nginx we use chained cert, possibly merge to chain by puppet magic?
  # for now the "kette" is not used, but a chained cert below
  file { '/etc/ssl/Uni_Goettingen_Kette.pem':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/dariahcommon/etc/ssl/Uni_Goettingen_Kette.pem',
#    notify => Service['nginx'],
  }
  if $sslkey != undef {
    file { "/etc/ssl/${::fqdn}.key.pem":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => '0600',
      source => $sslkey,
      notify => Service['nginx'],
    }
  }
  if $sslcert != undef {
    file { "/etc/ssl/${::fqdn}.chain.cert.pem":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => $sslcert,
      notify => Service['nginx'],
    }
  }
  # todo: else create dhparam:
  # openssl dhparam -out /etc/nginx/dhparam2048.pem 2048
  if $dhparam != undef {
    file { "/etc/nginx/dhparam2048.pem":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => $dhparam,
      notify => Service['nginx'],
    }
    $dhparam_file = true
  }

  # Use with module jfryman/nginx (maybe later)
  #    class { 'nginx':
  #        http_cfg_append => {
  #            client_body_buffer_size => '512k',
  #        }
  #    }

  file { '/var/www':
    ensure => directory,
  }
  file { '/var/www/nginx-root':
    ensure => directory,
  }
  file { '/var/www/nginx-cache':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }
  file { '/var/www/nginx-cache/tgsearch':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }
  file { '/var/www/nginx-cache/aggregator':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }
  file { '/etc/nginx/proxyconf':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => Package['nginx'],
  }
  ->
  file { '/etc/nginx/proxyconf/1.0.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${templates}/proxyconf/${scope}/1.0.conf.erb"),
    notify  => Service['nginx'],
  }
  ->
  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${templates}/nginx.erb"),
    notify  => Service['nginx'],
  }
  ->
  file { '/etc/nginx/sites-available/default':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${templates}/sites-available/default.erb"),
  }
  ~>
  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => [Package['nginx'],Package['ssl-cert']],
  }
}
