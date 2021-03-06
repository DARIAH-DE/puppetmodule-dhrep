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

    $_local_data_public_location = '/data/public/productive'
    $_local_data_nonpublic_location = '/data/nonpublic/productive'

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
    file { $_local_data_public_location:
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }
    file { $_local_data_nonpublic_location:
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }

    ###
    # cron for deleting empty folders in data dirs
    ###
    if ($tg_delete_empty_dirs) {
      cron { 'delete-empty-local-folders-public':
        command  => "find ${_local_data_public_location} -type d -empty -delete > /dev/null",
        user     => 'storage',
        hour     => 5,
        minute   => 24,
        monthday => 20,
        require  => File['/data/public'],
      }
      cron { 'delete-empty-local-folders-nonpublic':
        command  => "find ${_local_data_nonpublic_location} -type d -empty -delete > /dev/null",
        user     => 'storage',
        hour     => 3,
        minute   => 18,
        monthday => 22,
        require  => File['/data/public'],
      }
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
    # FIXME: Change into netapp folders and pathes if moving from StorNext to NetApp!!
    #

#    file { '/media/stornext':
#      ensure => directory,
#      # owner  => 'storage',
#      # group  => 'ULSB',
#      # mode   => '0755',
#    }

    file { '/media/netapp':
      ensure => directory,
      # owner  => 'storage',
      # group  => 'ULSB',
      # mode   => '0755',
    }

# TODO: mount target should move to hiera? or remove completely from puppet?
#    mount { '/media/stornext':
#      ensure  => 'mounted',
#      device  => 'gwdu157.fs.gwdg.de:/home/textgrid01/',
#      fstype  => 'nfs',
#      options => 'defaults',
#      atboot  => true,
#      require => [File['/media/stornext'],Package['nfs-common']],
#    }

    file { '/data/public':
      ensure => 'link',
      target => $data_public_location,
    }
    file { '/data/nonpublic':
      ensure => 'link',
      target => $data_nonpublic_location,
    }

    # FIXME: Remove NRPE check for stornext if all digilib caches have been moved to netapp!

    ###
    # nrpe
    ###
    nrpe::plugin { 'check_disk_stornext':
      plugin => 'check_disk',
      args   => '--units GB -w 1024 -c 256 -p /media/stornext',
    }

    ###
    # netapp
    ###
    nrpe::plugin { 'check_disk_netapp':
      plugin => 'check_disk',
      args   => '--units GB -w 1024 -c 256 -p /media/netapp',
    }

    ###
    # cron for deleting empty folders in data dirs
    ###
    if ($tg_delete_empty_dirs) {
      cron { 'delete-empty-nfs-folders-public':
        command  => "find ${data_public_location} -type d -empty -delete > /dev/null",
        user     => 'storage',
        hour     => 5,
        minute   => 24,
        monthday => 20,
        require  => File['/data/public'],
      }
      cron { 'delete-empty-nfs-folders-nonpublic':
        command  => "find ${data_nonpublic_location} -type d -empty -delete > /dev/null",
        user     => 'storage',
        hour     => 3,
        minute   => 18,
        monthday => 22,
        require  => File['/data/public'],
      }
    }
  }
}
