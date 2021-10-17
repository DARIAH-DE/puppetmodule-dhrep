# == Class: dhrep::services::bugreport
#
# Class to install the bugreport script for tglab
# if no gitlab_token is given, script will not be installed 
# - that's no problem, because its only needed on on server
#
class dhrep::services::bughandler (
  $scope = undef,
  $time  = ['23', '02'],
  $gitlab_token = '',
) inherits dhrep::params {

  $_confdir = $::dhrep::params::confdir
  $_logdir  = $::dhrep::params::logdir

  $owner = 'www-data'
  $group = 'www-data'

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin','/usr/local/bin'],
  }

  # install script only if token is set, else skip
  if($gitlab_token != '') {

    vcsrepo { '/usr/local/src/bughandler-git':
      ensure   => latest,
      owner    => 'root',
      group    => 'root',
      provider => git,
      source   => "https://puppet-pull:${gitlab_token}@gitlab.gwdg.de/dariah-de/textgridlab/bughandler.git",
      revision => 'main',
    }
    -> file { '/var/www/bugreport':
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => '0755',
    }

    ###
    # logging and logrotate
    ###
    file { "${_logdir}/bughandler":
      ensure  => directory,
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      require => File[$_logdir],
    }
    logrotate::rule { 'bughandler':
      path         => "${_logdir}/bughandler/bughandler.log",
      require      => File["${_logdir}/bughandler"],
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
    # script from cloned GIT repo.
    ###
    file { '/var/www/bugreport/bughandler.py':
      source  => 'file:///usr/local/src/bughandler-git/bughandler.py',
      owner   => $owner,
      group   => $group,
      mode    => '0755',
      require => File['/var/www/bugreport'],
    }


    ###
    # apache config, apache should be setup by dhrep::init
    ###
    file { '/etc/apache2/textgrid/default_vhost_includes/bughandler.conf':
      content => "
      # --------------------------------------------------------------------------
      # TextGrid Bughandler configuration
      # --------------------------------------------------------------------------

      <Directory \"/var/www/bugreport/\">
        SetHandler cgi-script
        AllowOverride All
        Options +ExecCGI
      </Directory>
      ",
      notify  => Service['apache2'],
    }
  }
}
