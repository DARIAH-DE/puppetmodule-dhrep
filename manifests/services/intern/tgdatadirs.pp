# == Class: dhrep::services::intern::tgdatadirs
#
# === Description
#
# Class to install and configure TextGrid data folders, public and non-public. Local folders are used for local VMs (such as vagrant and VirtualBox installations), NFS mounts are used for productice machines in most cases.
#
# === Notes
#
#
# === Parameters
#
# [*scope*]
#   textgrid or dariah (textgrid only at the moment, no local or mounted storage is necesarry for DARIAH-DE Repository).
#
# [*create_local_datadirs*]
#   true if local datadirs shall be created at system creation
#
# [*data_public_location*]
#   location of the public data folder
#
# [*data_nonpublic_location*]
#   location of the non-public data folder
#
# [*tg_delete_empty_dirs*]
#   delete empty dirs in data folders via cron job
#
class dhrep::services::intern::tgdatadirs (
  $scope                   = undef,
  $create_local_datadirs   = undef,
  $data_public_location    = undef,
  $data_nonpublic_location = undef,
  $tg_delete_empty_dirs    = false,
){

  $_data_public_location = $data_public_location
  $_data_nonpublic_location = $data_nonpublic_location

  ###
  # the data dir: must be present
  ###
  file { '/data':
    ensure => directory,
    owner  => 'storage',
    group  => 'ULSB',
    mode   => '0755',
  }

  ###
  # create local data dirs if configured so
  ###
  if ($create_local_datadirs) {

    $_data_public_location    = '/data/public/productive'
    $_data_nonpublic_location = '/data/nonpublic/productive'

    file { '/data/public':
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }
    file { '/data/nonpublic':
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }
    file { $_data_public_location:
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }
    file { $_data_nonpublic_location:
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }
  }

  ###
  # create nfs mounts otherwise
  ###
  else {

    package { 'nfs-common':
      ensure => present,
    }

    #
    # FIXME Change into netapp folders and pathes if moving from StorNext to NetApp!!
    #

    file { '/media/stornext':
      ensure => directory,
      # owner  => 'storage',
      # group  => 'ULSB',
      # mode   => '0755',
    }
    mount { '/media/stornext':
      ensure  => 'mounted',
      device  => 'gwdu157.fs.gwdg.de:/home/textgrid01/',
      fstype  => 'nfs',
      options => 'defaults',
      atboot  => true,
      require => [File['/media/stornext'],Package['nfs-common']],
    }
    file { '/data/public':
      ensure => 'link',
      target => $data_public_location,
    }
    file { '/data/nonpublic':
      ensure => 'link',
      target => $data_nonpublic_location,
    }

    ###
    # nrpe
    ###
    nrpe::plugin { 'check_disk_stornext':
      plugin => 'check_disk',
      args   => '--units GB -w 1024 -c 256 -p /media/stornext',
    }
  }

  ###
  # cron for deleting empty folders in data dirs
  ###
  if ($tg_delete_empty_dirs) {
    cron { 'delete-empty-folders-public':
      command  => "find ${_data_public_location} -type d -empty -delete > /dev/null",
      user     => 'storage',
      hour     => 5,
      minute   => 24,
      monthday => 20,
      require  => File['/data/public'],
    }
    cron { 'delete-empty-folders-nonpublic':
      command  => "find ${_data_nonpublic_location} -type d -empty -delete > /dev/null",
      user     => 'storage',
      hour     => 3,
      minute   => 18,
      monthday => 22,
      require  => File['/data/public'],
    }
  }
}
