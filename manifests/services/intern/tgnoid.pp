# == Class: dhrep::services::intern::tgnoid
#
# === Description
#
# Class to install and configure the NOID for TextGrid usage. The NOID is minting TextGrid URIs for internal and external TextGrid use. TG-crud is using the key/value store of the NOID identifiers for internal locking of TextGrid objects on revision URI level (such as textgrid:1234.3).
#
# In case of a rebuild of the TextGrid machines from backup files (LDAP, Sesame, and/or more) the NOID IDs must be minted again, until the next minted TextGrid URI will be a new one that is NOT yet used by any restored data! The internal key/value store must NOT be rebuild, it is only used at TG-crud runtime.
#
# Patches some warning out of the code and creates initial textgrid minter.
#
# === Notes
#
# TODO: add checks to bash script
#
# === Parameters
#
# [*scope*]
#   textgrid or dariah (textgrid only at the moment, no NOIDs are used for the DARIAH-DE Repository, Handle PIDs are used there for internal identifier usage).
#
# [*crud_secret*]
#   the secret crud uses to access the noid via HTTP
#
class dhrep::services::intern::tgnoid (
  $scope       = undef,
  $crud_secret = undef,
) {

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
  -> file { "/home/${noiduser}":
    mode => '0755',
  }

  ###
  # create apache user for tgnoid
  ###
  exec { 'create_noid_apache_credentials':
    command => "htpasswd -bc /etc/apache2/tgnoid.htpasswd tgcrud ${crud_secret}",
    creates => '/etc/apache2/tgnoid.htpasswd',
    require => Service['apache2'],
  }
  ~> exec { 'change_noid_apache_credential_permissions':
    command     => 'chmod 600 /etc/apache2/tgnoid.htpasswd',
    refreshonly => true,
  }
  ~> exec { 'change_noid_apache_credential_owner':
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
  ~> file { '/home/tgnoid/tgnoid.patch':
    source => 'puppet:///modules/dhrep/tgnoid/tgnoid.patch',
  }
  ~> exec { 'install_tgnoid':
    command   => '/home/tgnoid/install_tgnoid.sh',
    creates   => '/home/tgnoid/htdocs/nd/textgrid/NOID',
    logoutput => true,
  }

  ###
  # apache config, apache should be setup by dhrep::init
  ###
  file { '/etc/apache2/textgrid/default_vhost_includes/tgnoid.conf':
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
    notify  => Service['apache2'],
  }

  ###
  # nrpe
  ###
  nrpe::plugin { 'check_tgnoid':
    plugin => 'check_http',
    args   => "-H localhost -a 'tgcrud:${crud_secret}' -p 8080 -u /nd/noidu_textgrid?get+textgrid:h4kg.0 -s \"note: no elements bound under textgrid:h4kg.0\"",
  }
}
