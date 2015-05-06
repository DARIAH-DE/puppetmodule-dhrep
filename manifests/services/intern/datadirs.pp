# == Class: textgrid::services::intern::datadirs
#
# Class to install and configure TG-cruds data folders.
#
class textgrid::services::intern::datadirs (
  $create_local_datadirs = true,
  $data_public_location = '',
  $data_nonpublic_location = '',
){

  ###
  # the data dir
  ###
  file { '/data':
    ensure => directory,
    owner  => 'textgrid',
    group  => 'ULSB',
    mode   => '0755',
  }


  if($create_local_datadirs) {
    ###
    # local
    ###
    file { '/data/public':
      ensure => directory,
      owner  => 'textgrid',
      group  => 'ULSB',
      mode   => '0755',
    }

    file { '/data/nonpublic':
      ensure  => directory,
      owner   => 'textgrid',
      group   => 'ULSB',
      mode    => '0755',
    }

    file { '/data/public/productive':
      ensure  => directory,
      owner   => 'textgrid',
      group   => 'ULSB',
      mode    => '0755',
    }

    file { '/data/nonpublic/productive':
      ensure  => directory,
      owner   => 'textgrid',
      group   => 'ULSB',
      mode    => '0755',
    }

  } else {
    ###
    # nfs
    ###
    package { 'nfs-common':
      ensure => present,
    }
    file { '/media/stornext':
      ensure  => directory,
      owner   => 'textgrid',
      group   => 'ULSB',
      mode    => '0755',
    }    
    mount { '/media/stornext':
      device  => 'fs-base3.gwdg.de:/home/textgrid/',
      fstype  => 'nfs',
      ensure  => 'mounted',
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
 
  }

}
