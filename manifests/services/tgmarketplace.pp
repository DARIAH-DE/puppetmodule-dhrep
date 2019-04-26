# == Class: dhrep::services::tgmarketplace
#
# Class to install and configure the TextGrid Marketplace.
#
class dhrep::services::tgmarketplace (
  $scope = undef,
  $time  = ['23', '02'],
) inherits dhrep::params {

  $_confdir = $::dhrep::params::confdir
  $_logdir  = $::dhrep::params::logdir

  $owner = 'www-data'
  $group = 'www-data'

  package {
    'libapache2-mod-python': ensure => present;
    'python3': ensure               => present;
    'python3-lxml': ensure          => present;
  }

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin','/usr/local/bin'],
  }

  ###
  # clone marketplace from git and copy to var/www/
  #
  # TODO use release-tag in any way?
  # TODO cloning does not yield automatic updates via pull!!
  ###
  exec { 'git_clone_textgrid_marketplace':
    command => 'git clone git://projects.gwdg.de/dariah-de/tg/textgridlab-marketplace.git /usr/local/src/textgrid-marketplace-git',
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

  ###
  # .htaccess and config file from template.
  ###
  file { '/var/www/marketplace/.htaccess':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    content => template('dhrep/var/www/marketplace/.htaccess.erb'),
    require => File['/var/www/marketplace'],
    notify  => Service['apache2'],
  }

  ###
  # logging and logrotate
  ###
  file { "${_logdir}/marketplace":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File[$_logdir],
  }
  logrotate::rule { marketplace:
    path         => "${_logdir}/marketplace/msInterface.log",
    require      => File["${_logdir}/marketplace"],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }

  ###
  # Configuration
  ###
  file { '/var/www/marketplace/cgi/ms.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    content => template('dhrep/var/www/marketplace/cgi/ms.conf.erb'),
    require => File['/var/www/marketplace/cgi'],
  }

  ###
  # symlink to /etc/textgrid/marketplace, create folder before.
  ###
  file { "${_confdir}/marketplace":
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '0755',
    require => File[$_confdir],
  }
  file { "${_confdir}/marketplace/ms.conf":
    ensure  => 'link',
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    target  => '/var/www/marketplace/cgi/ms.conf',
    require => [File["${_confdir}/marketplace"],File['/var/www/marketplace/cgi/ms.conf']],
  }
  ###
  # other files from cloned GIT repo.
  ###
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
  file { '/var/www/marketplace/cgi/data.yaml':
    source  => 'file:///usr/local/src/textgrid-marketplace-git/data.yaml',
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File['/var/www/marketplace/cgi'],
  }

  ###
  # apache config, apache should be setup by dhrep::init
  ###
  file { "/etc/apache2/textgrid/default_vhost_includes/tgmarketplace.conf":
    content => "
    # --------------------------------------------------------------------------
    # TextGrid Marketplace configuration
    # --------------------------------------------------------------------------

    <Directory /var/www/marketplace/>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride All
      Order allow,deny
      allow from all
    </Directory>
    <Directory \"/var/www/marketplace/cgi/\">
      SetHandler cgi-script
      AllowOverride All
      Options +ExecCGI
    </Directory>
    ",
    notify => Service['apache2'],
  }
}
