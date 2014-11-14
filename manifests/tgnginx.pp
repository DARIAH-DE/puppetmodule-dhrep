# == Class: textgrid::tgnginx
#
# install and configure nginx.
#
# set proxyconfig for forwarding local services via port 80 
#
class textgrid::tgnginx (
  $proxy_conf_file = '/etc/nginx/proxyconf/1.0.conf',
  $proxy_conf_template = 'textgrid/etc/nginx/proxyconf/1.0.conf.erb',
  $nginx_conf_template = 'textgrid/etc/nginx/nginx.erb',
  $default_site_template = 'textgrid/etc/nginx/sites-available/default.erb',
) {

  package {
    'nginx-extras': ensure => present;
    'ssl-cert'   : ensure => present; # snakeoil cert for nginx
  }

  # Use with module jfryman/nginx (maybe later)
  #    class { 'nginx':
  #        http_cfg_append => {
  #            client_body_buffer_size => '512k',
  #            chunkin                 => 'on',
  #        }
  #    }

  file { '/var/www':
    ensure => directory,
  }

  file { '/var/www/nginx-root':
    ensure => directory,
  } 

  file { '/etc/nginx/proxyconf':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => Package['nginx-extras'],
  }
  ->
  file { $proxy_conf_file:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($proxy_conf_template),
  }
  ->
  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($nginx_conf_template),
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
    require => [Package['nginx-extras'],Package['ssl-cert']],
  }

}
