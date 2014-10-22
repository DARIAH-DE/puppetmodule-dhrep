# == Class: textgrid::services::intern::tgnoid
#
# Class to install and configure the NOID.
# Creates initial minter textgrid.
# 
# TODO:
#   add checks to bash script
#

class textgrid::services::intern::tgnoid ( $tgcrud_secret ) {

  $tgname    = 'tgnoid'
  $noiduser  = 'tgnoid'
  $noidgroup = 'tgnoid'

  package {
    'libberkeleydb-perl': ensure => present;
  }

  require textgrid::resources::apache

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin','/usr/local/bin'],
  }

  ###
  # create user, group and home dir
  ###
  group { $noidgroup:
    ensure => present,
  }
  user { $noiduser:
    ensure     => present,
    gid        => $noidgroup,
    home       => "/home/${noiduser}",
    shell      => '/bin/bash',
    managehome => true,
  }

  ###
  # create apache user for tgnoid
  ###
  exec { 'create_noid_apache_credentials':
    command => "htpasswd -bc /etc/apache2/tgnoid.htpasswd tgcrud ${tgcrud_secret}",
    creates => '/etc/apache2/tgnoid.htpasswd',
  }
  ~>
  exec { 'change_noid_apache_credential_permissions':
    command => 'chmod 600 /etc/apache2/tgnoid.htpasswd',
    refreshonly => true,
  }
  ~>
  exec { 'change_noid_apache_credential_owner':
    command => 'chown www-data:root /etc/apache2/tgnoid.htpasswd',
    refreshonly => true,
  }

  ###
  # do everything else via bash scripting
  ###
  file { '/home/tgnoid/install_tgnoid.sh':
    source => 'puppet:///modules/textgrid/tgnoid/install_tgnoid.sh',
    mode   => '0744',
  } 
  ~>
  file { '/home/tgnoid/tgnoid.patch':
    source => 'puppet:///modules/textgrid/tgnoid/tgnoid.patch',
  }
  ~>
  exec { 'install_tgnoid':
    command => '/home/tgnoid/install_tgnoid.sh',
    creates => '/home/tgnoid/htdocs/nd/textgrid/NOID',
    logoutput => true,
  }

}
