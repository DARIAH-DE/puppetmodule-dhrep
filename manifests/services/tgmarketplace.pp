# == Class: dhrep::services::tgmarketplace
#
# Class to install and configure the TextGrid Marketplace.
#
class dhrep::services::tgmarketplace (
  $scope                 = undef,
  $time                  = ['23', '02'],
  $docker_image_registry = 'docker.gitlab.gwdg.de',
  $docker_image_name     = 'dariah-de/textgridlab-marketplace/develop',
  $docker_image_tag      = 'latest',
  $docker                = false,
) inherits dhrep::params {

  if !$docker {
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
    # clone marketplace from git and copy some parts to var/www/
    # symlink data.yaml and keep updated with vcsrepo
    #
    # TODO use release-tag in any way?
    ###
    vcsrepo { '/usr/local/src/textgrid-marketplace-git':
      ensure   => latest,
      owner    => 'root',
      group    => 'root',
      provider => git,
      source   => 'https://github.com/DARIAH-DE/textgridlab-marketplace.git',
      revision => 'master',
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
      ensure  => 'link',
      target  => '/usr/local/src/textgrid-marketplace-git/data.yaml',
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
  } else {

    #
    # tgmarketplace docker
    #
    class { '::docker' :
      version => 'latest',
    }
    class {'docker::compose':
      version => '1.25.4',
    }
    docker::registry { $docker_image_registry: }

    file { '/opt/docker-marketplace':
      ensure  => directory,
    }

    file { '/opt/docker-marketplace/marketplace.env':
      ensure  => file,
      content => epp('dhrep/opt/docker-marketplace/marketplace.env.epp', {
        hostname => $profiles::textgridrepository::public_hostname,
      }),
    }

    file { '/opt/docker-marketplace/docker-compose.yaml':
      ensure  => file,
      content => epp('dhrep/opt/docker-marketplace/docker-compose.yaml.epp', {
        image => "${docker_image_registry}/${docker_image_name}:${docker_image_tag}",
      }),
    }

    docker::image { "${docker_image_registry}/${docker_image_name}":
      ensure    => latest,
      image_tag => $docker_image_tag,
    } ->
    docker_compose { 'marketplace':
      ensure        => present,
      compose_files => ['/opt/docker-marketplace/docker-compose.yaml'],
      require       => [
                         File['/opt/docker-marketplace/docker-compose.yaml'],
                         File['/opt/docker-marketplace/marketplace.env'],
                       ],
    }
    
  }
}

