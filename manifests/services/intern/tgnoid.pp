# == Class: dhrep::services::intern::tgnoid
#
# Class to install and configure the NOID.
# Creates initial minter textgrid.
# 
# TODO:
#   add checks to bash script
#
class dhrep::services::intern::tgnoid (
  $scope         = 'textgrid',
  $tgcrud_secret
){

  $tgname    = 'tgnoid'
  $noiduser  = 'tgnoid'
  $noidgroup = 'tgnoid'

  package {
    'libberkeleydb-perl': ensure => present;
  }

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
  ->
  file { "/home/${noiduser}":
    mode => '0755',
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
    command     => 'chmod 600 /etc/apache2/tgnoid.htpasswd',
    refreshonly => true,
  }
  ~>
  exec { 'change_noid_apache_credential_owner':
    command     => 'chown www-data:root /etc/apache2/tgnoid.htpasswd',
    refreshonly => true,
  }

  ###
  # do everything else via bash scripting
  ###
  file { '/home/tgnoid/install_tgnoid.sh':
    source  => 'puppet:///modules/dhrep/tgnoid/install_tgnoid.sh',
    mode    => '0744',
    require => User[$noiduser],
  }
  ~>
  file { '/home/tgnoid/tgnoid.patch':
    source => 'puppet:///modules/dhrep/tgnoid/tgnoid.patch',
  }
  ~>
  exec { 'install_tgnoid':
    command   => '/home/tgnoid/install_tgnoid.sh',
    creates   => '/home/tgnoid/htdocs/nd/textgrid/NOID',
    logoutput => true,
  }

  ###
  # apache config, apache should be setup by dhrep::init
  ###  
  file { "/etc/apache2/${scope}/default_vhost_includes/tgnoid.conf":
    content => "
    # --------------------------------------------------------------------------
    # All the NOID configuration things following here for minting TextGrid URIs
    # --------------------------------------------------------------------------

    # ScriptAlias /cgi-bin/ /home/tgnoid/htdocs/nd/
    <Directory \"/home/tgnoid/htdocs/nd/\">
      AuthType Basic
      AuthName \"The TextGrid URI NOID Service\"
      AuthUserFile /etc/apache2/tgnoid.htpasswd
      Require valid-user
      AllowOverride None
      Options +ExecCGI -Includes
      Require all granted
    </Directory>

    # Make the server recognize links to htdocs/nd
    ScriptAliasMatch ^/nd/noidr(.*) \"/home/tgnoid/htdocs/nd/noidr\$1\"
    ScriptAliasMatch ^/nd/noidu(.*) \"/home/tgnoid/htdocs/nd/noidu\$1\"

    # Define all the rewrite maps, start every program once on server start
    # RewriteMap rslv_textgrid prg:/home/tgnoid/htdocs/nd/noidr_textgrid

    # --------------------------------------------------------------------------
    # End of NOID configuration
    # --------------------------------------------------------------------------
    ",
    notify => Service['apache2']
  }

  ###
  # nrpe
  ###
  dariahcommon::nagios_service { 'check_tgnoid':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -a 'tgcrud:${dhrep::services::intern::tgnoid::tgcrud_secret}' -p 8080 -u /nd/noidu_textgrid?get+textgrid:h4kg.0 -s \"note: no elements bound under textgrid:h4kg.0\"",
  }

}
