# == Class: dhrep::tgnginx
#
# install and configure nginx.
#
# set proxyconfig for forwarding local services via port 80 
#
class dhrep::tgnginx (
  $proxy_conf_file = '/etc/nginx/proxyconf/1.0.conf',
  $proxy_conf_template = 'dhrep/etc/nginx/proxyconf/1.0.conf.erb',
  $nginx_conf_template = 'dhrep/etc/nginx/nginx.erb',
  $default_site_template = 'dhrep/etc/nginx/sites-available/default.erb',
  $tgsearch_toplevel_cache_expiration = '24h',
) {

  package {
    'nginx'    : ensure => present;
    'ssl-cert' : ensure => present; # snakeoil cert for nginx
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
  file { $proxy_conf_file:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($proxy_conf_template),
    notify  => Service['nginx'],
  }
  ->
  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($nginx_conf_template),
    notify  => Service['nginx'],
  }
  ->
  file { '/etc/nginx/sites-available/default':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($default_site_template),
  }
  ~>
  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => [Package['nginx'],Package['ssl-cert']],
  }

}
