# == Class: dhrep::services::intern::tgmarketplace
#
# Class to install and configure the TextGrid Marketplace.
# 
class dhrep::services::intern::tgmarketplace (
  $time = ['23', '02'],
){

  $owner = www-data
  $group = www-data

  package {
    'libapache2-mod-python': ensure => present;
    'python3': ensure               => present;
    'python3-lxml': ensure          => present;
  }

  require dhrep::resources::apache

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin','/usr/local/bin'],
  }

  #
  # Clone marketplace from GIT and copy to var/www/
  #
  # TODO Use release-tag in any way?
  # TODO Cloning does not yield automatic updates via pull!!
  #
  exec { 'git_clone_textgrid_marketplace':
    command => 'git clone git://git.projects.gwdg.de/textgridlab-marketplace.git /usr/local/src/textgrid-marketplace-git',
    creates => '/usr/local/src/textgrid-marketplace-git',
    require => Package['git'],
  }
  ->
  file { '/var/www/marketplace':
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '0755',
  }
  file { '/var/www/marketplace/cgi':
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File['/var/www/marketplace'],
  }
  # .htaccess and config file from template.
  file { '/var/www/marketplace/.htaccess':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    content => template('dhrep/var/www/marketplace/.htaccess.erb'),
    require => File['/var/www/marketplace'],
  }
  # Logging and logrotate
  file { '/var/log/textgrid/marketplace':
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File['/var/log/textgrid'],
  }
  logrotate::rule { marketplace:
    path         => '/var/log/textgrid/marketplace/msInterface.log',
    require      => File['/var/log/textgrid/marketplace'],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }
  # Configuration
  file { '/var/www/marketplace/cgi/ms.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    content => template('dhrep/var/www/marketplace/cgi/ms.conf.erb'),
    require => File['/var/www/marketplace/cgi'],
  }
  # Symlink to /etc/textgrid/marketplace, create folder before.
  file { '/etc/textgrid/marketplace':
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '0755',
    require => File['/etc/textgrid'],
  }
  file { '/etc/textgrid/marketplace/ms.conf':
    ensure  => 'link',
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    target  => '/var/www/marketplace/cgi/ms.conf',
    require => [File['/etc/textgrid/marketplace'],File['/var/www/marketplace/cgi/ms.conf']],
  }
  # Other files from cloned GIT repo.
  file { '/var/www/marketplace/tg32.png':
    source  => 'file:///usr/local/src/textgrid-marketplace-git/tg32.png',
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    require => File['/var/www/marketplace'],
  }
  file { '/var/www/marketplace/cgi/msInterface.cgi':
    source  => 'file:///usr/local/src/textgrid-marketplace-git/msInterface.cgi',
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File['/var/www/marketplace/cgi'],
  }
  # Cron for automatical cache reloading
  cron { 'marketplace-cach-reload':
    ensure  => present,
    command => 'curl http://vm1/marketplace/cgi/msInterface.cgi?action=cache_reload',
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    weekday => 0,
  }

}
