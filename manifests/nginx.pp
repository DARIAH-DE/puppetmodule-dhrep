# == Class: dhrep::nginx
#
# Install and configure nginx.
#
# Set proxyconfig for forwarding local services via port 80.
#
# === Parameters
#
# [*scope*]
#   textgrid or dariah
# [*ignore_service_status*]
#   let puppet ignore the service status of nginx, useful if nginx is stopped manually for maintenance reasons
#
class dhrep::nginx (
  $scope                              = undef,
  $tgsearch_toplevel_cache_expiration = '24h',
  $sslcert                            = undef,
  $sslkey                             = undef,
  $dhparam                            = undef,
  $nginx_root                         = undef,
  $ignore_service_status              = false,
  $proxyconf_proxypath_dhrep_search   = 'https://dfa.de.dariah.eu/search-alt/',
  $proxyconf_proxypath_dhrep_colreg   = 'https://dfa.de.dariah.eu/colreg-ui-alt/',
  $proxyconf_proxy_set_host_header    = '    ',
) inherits dhrep::params {

  include dhrep::services::tomcat_oaipmh
  include dhrep::services::tomcat_publish
  include dhrep::services::tomcat_pid
  include dhrep::services::tomcat_digilib
  include dhrep::services::tomcat_digilib2
  include dhrep::services::tomcat_fits

  if $scope == 'textgrid' {
    include dhrep::services::tomcat_aggregator
    include dhrep::services::tomcat_sesame
    include dhrep::services::tomcat_tgsearch
    include dhrep::services::tgmarketplace
  }
  if $scope == 'dariah' {
    include dhrep::services::tomcat_publikator
    include roles::dariahrepository
    if ($::roles::dariahrepository::with_shib) {
      $tomcat_publikator_http_port = '8080'
    }
    else {
      $tomcat_publikator_http_port = $::dhrep::params::config['tomcat_publikator']['http_port']
    }
  }

  $_confdir  = $::dhrep::params::confdir
  $templates = 'dhrep/etc/dhrep/nginx/'

  $tomcat_crud_http_port = $::dhrep::params::config['tomcat_crud']['http_port']

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
  # TODO: please do a
  # $cat {hostname}-crt.pem dhrep_dariah_de_puppet/modules/profiles/files/etc/ssl/DFN_PKI_Generation_2.pem >> {hostname}-chain-crt.pem
  # to add DFN cert to server cert.
  file { '/etc/ssl/DFN_PKI_Generation_2.pem':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/profiles/etc/ssl/DFN_PKI_Generation_2.pem',
  }
  if $sslkey != undef {
    file { "/etc/ssl/${::fqdn}.key.pem":
      ensure => file,
      owner  => root,
      group  => root,
      mode   => '0600',
      source => $sslkey,
    }
  }
  if $sslcert != undef {
    file { "/etc/ssl/${::fqdn}.chain.cert.pem":
      ensure => file,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => $sslcert,
    }
  }
  # todo: else create dhparam:
  # openssl dhparam -out /etc/nginx/dhparam2048.pem 2048
  if $dhparam != undef {
    file { '/etc/nginx/dhparam2048.pem':
      ensure => file,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => $dhparam,
    }
    $dhparam_file = true
  }

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
  -> file { '/etc/nginx/proxyconf/1.0.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${templates}/proxyconf/${scope}/1.0.conf.erb"),
  }
  -> file { '/etc/nginx/nginx.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${templates}/nginx.erb"),
  }
  -> file { '/etc/nginx/sites-available/default':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("${templates}/sites-available/${scope}/default.erb"),
  }
  if ! $ignore_service_status {
    service { 'nginx':
      ensure    => running,
      enable    => true,
      require   => [Package['nginx'],Package['ssl-cert']],
      subscribe => [
        File['/etc/nginx/sites-available/default'],
        File['/etc/nginx/nginx.conf'],
        File['/etc/nginx/proxyconf/1.0.conf'],
        File['/etc/nginx/conf.d/digilib.conf'],
      ],
    }
  }

  logrotate::rule { 'nginx':
    path          => '/var/log/nginx/*.log',
    rotate        => 90,
    rotate_every  => 'day',
    compress      => true,
    copytruncate  => true,
    delaycompress => true,
    missingok     => true,
    ifempty       => true,
    dateext       => true,
    dateformat    => '.%Y-%m-%d',
    prerotate     => 'if [ -d /etc/logrotate.d/httpd-prerotate ]; then run-parts /etc/logrotate.d/httpd-prerotate; fi;',
    postrotate    => '[ -s /run/nginx.pid ] && kill -USR1 `cat /run/nginx.pid`',
  }

  file {'/opt/dhrep/anonymizer_nginx.sh':
    ensure => file,
    owner  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/dhrep/opt/dhrep/anonymizer_nginx.sh',
  }

  cron { 'anonymizer_nginx' :
    command => '/opt/dhrep/anonymizer_nginx.sh',
    user    => 'root',
    hour    => '22',
    minute  => '07',
  }

  host { 'ref.de.dariah.eu':
    ensure  => present,
    comment => 'prevent "host not found in upstream..." errors on first nginx startup when network not fully ready',
    ip      => '141.5.101.74',
  }

  telegraf::input { 'nginx':
    plugin_type => 'nginx',
    options     => [{
        'urls' => ['http://localhost/nginx_status'],
    }],
  }
}
