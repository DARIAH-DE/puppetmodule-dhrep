# == Define: users_addadmin
#
# helper for adding admin user
# copied from cendari::defaults::defaults::users_addadmin
# maybe useful as a dariah common define
#
define dhrep::users_addadmin (
  $username    = $title,
  $uid         = undef,
  $groups      = [],
  $fullname    = undef,
  $affiliation = undef,
  $mail        = undef,
  $sshkey_type = undef,
  $sshkey      = undef,
  $shell       = '/bin/bash'
) {

  user { $username:
    ensure     => present,
    uid        => $uid,
    comment    => "${fullname} (${affiliation})",
    gid        => 'users',
    groups     => $groups,
    shell      => $shell,
    home       => "/home/${username}",
    managehome => true,
    require    => [Package['zsh'],Package['bash']],
  }

  if ($sshkey != '') {
    ssh_authorized_key {"sshkey_${username}":
      ensure => present,
      name   => $username,
      user   => $username,
      type   => $sshkey_type,
      key    => $sshkey,
    }
  }

#  file { "/home/${username}/.bashrc_cendari":
#    ensure  => present,
#    owner   => $username,
#    group   => 'users',
#    mode    => '0644',
#    source  => 'puppet:///modules/defaults/home/bashrc_cendari',
#    require => User[$username],
#  }

#  exec { "install_${username}_bashrc_cendari":
#    path    => ['/usr/bin','/bin','/usr/sbin'],
#    command => "echo \"
## THE FOLLOWING IS ADDED BY PUPPET !!!
## uncomment to disable (deleting is futile)
#if [ -f ~/.bashrc_cendari ]; then
#    . ~/.bashrc_cendari
#fi
#   \" >> /home/${username}/.bashrc",
#    unless  => "grep 'bashrc_cendari' /home/${username}/.bashrc",
#    require => User[$username],
#  }

  if $mail != '' {
    file_line { "${username}_mailalias":
      line    => "${username}: ${mail}",
      path    => '/etc/aliases',
      require => File['/etc/aliases'],
    }
  }
}
