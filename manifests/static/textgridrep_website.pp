# == Class: dhrep::static::textgridrep_website
#
# Class to install and configure the (old) textgridrep website
#
class dhrep::static::textgridrep_website (
  $tgrep_server_name  = 'vm1rep vm1rep.textgrid.local',
  $tgrep_service_url  = 'http://vm1.textgrid.local/1.0',
  $install_site       = false,
) {

  include dhrep::nginx

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin'],
  }

  # the old textgridrep website is hidden (and not installed) by default!
  if ($install_site) {

    # install everything
    file { '/var/www/nginx-root/textgridrep.de':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    -> exec { 'git_clone_textgridrep':
      command => 'git clone git://projects.gwdg.de/dariah-de/tg/textgrid-repository/textgridrep-webseite.git /var/www/nginx-root/textgridrep.de/textgridrep-webseite',
      creates => '/var/www/nginx-root/textgridrep.de/textgridrep-webseite',
      require => Package['git'],
    }
    -> file { '/var/www/nginx-root/textgridrep.de/textgridrep-webseite-sandbox':
      source  => 'file:///var/www/nginx-root/textgridrep.de/textgridrep-webseite',
      recurse => true,
    }
    -> file { '/var/www/nginx-root/textgridrep.de/textgridrep-webseite/sandbox':
      ensure => 'link',
      target => '/var/www/nginx-root/textgridrep.de/textgridrep-webseite-sandbox',
    }
    -> file { '/var/www/nginx-root/textgridrep.de/textgridrep-webseite/js/config.js':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dhrep/var/www/nginx-root/textgridrep-webseite/config.js.erb'),
    }
    -> file { '/var/www/nginx-root/textgridrep.de/textgridrep-webseite-sandbox/js/config.js':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dhrep/var/www/nginx-root/textgridrep-webseite-sandbox/config.js.erb'),
    }

    file { '/etc/nginx/sites-available/textgridrep':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dhrep/etc/dhrep/nginx/sites-available/textgridrep.erb'),
    }
    -> file { '/etc/nginx/proxyconf/textgridrep.common.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('dhrep/etc/dhrep/nginx/proxyconf/textgridrep.common.conf.erb'),
    }
    -> file { '/etc/nginx/sites-enabled/textgridrep':
      ensure => 'link',
      source => '/etc/nginx/sites-available/textgridrep',
      notify => Service['nginx'],
    }
  }
}
