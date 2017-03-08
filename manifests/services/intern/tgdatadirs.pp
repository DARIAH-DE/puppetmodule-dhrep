# == Class: dhrep::services::intern::tgdatadirs
#
# Class to install and configure TG-crud data folders.
#
class dhrep::services::intern::tgdatadirs (
  $scope                   = undef,
  $create_local_datadirs   = undef,
  $data_public_location    = '',
  $data_nonpublic_location = '',
){

  ###
  # the data dir
  ###

  file { '/data':
    ensure => directory,
    owner  => 'storage',
    group  => 'ULSB',
    mode   => '0755',
  }

  if($create_local_datadirs) {
    ###
    # local
    ###
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

    file { '/data/public/productive':
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }

    file { '/data/nonpublic/productive':
      ensure => directory,
      owner  => 'storage',
      group  => 'ULSB',
      mode   => '0755',
    }

  } else {

    ###
    # nfs
    ###

    package { 'nfs-common':
      ensure => present,
    }

    file { '/media/stornext':
      ensure => directory,
#      owner  => 'storage',
#      group  => 'ULSB',
#      mode   => '0755',
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
      target => $data_public_location
    }

    file { '/data/nonpublic':
      ensure => 'link',
      target => $data_nonpublic_location
    }

    ###
    # nrpe
    ###
    nrpe::plugin { 'check_disk_stornext':
      plugin => 'check_disk',
      args   => '--units GB -w 1024 -c 256 -p /media/stornext',
    }

  }

}
