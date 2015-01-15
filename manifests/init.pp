# == Class: textgrid
#
# setup and manage a textgrid server
#
# TODO  read https://dev2.dariah.eu/wiki/display/TGINT/textgrid-esx1.gwdg.de
#       and write the manifests ;-)
#
class textgrid {

  include '::dariahcommon'

  include textgrid::services::tgsearch
  include textgrid::services::tgcrud
  include textgrid::services::tgcrud_public
  include textgrid::services::tgpublish
  include textgrid::services::tgpid
  include textgrid::services::tgauth
  include textgrid::services::confserv
  include textgrid::services::digilib
  include textgrid::services::textgridrep_website
  include textgrid::services::tgoaipmh
  include textgrid::services::aggregator

  include textgrid::services::intern::tgelasticsearch
  include textgrid::services::intern::sesame
  include textgrid::services::intern::tgwildfly
  include textgrid::services::intern::messaging
  include textgrid::services::intern::tgnoid

  include textgrid::tgnginx

  package {
    'openjdk-6-jdk':            ensure => absent;
    'openjdk-6-jre':            ensure => absent;
    'openjdk-6-jre-headless':   ensure => absent;
    'openjdk-6-jre-lib':        ensure => absent;
    'openjdk-7-jdk':            ensure => present;
    'tomcat7':                  ensure => present;
    'tomcat7-user':             ensure => present;
    'libtcnative-1':            ensure => present;               
    'emacs':                    ensure => present;
    'mc':                       ensure => present;
    'maven':                    ensure => present;
    'make':                     ensure => present;
  }

  # open http and https ports (other ports are closed via dariah-common firewall rules)
  firewall { '100 allow http and https access':
    port   => [80, 443],
    proto  => tcp,
    action => accept,
  }

  file { '/etc/textgrid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/var/log/textgrid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/var/textgrid':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  service { 'tomcat7':
    ensure  => stopped,
    enable  => false,
    require => Package['tomcat7'],
  }

  ###
  # create admin users on system and set mail aliases
  ###
  file { '/etc/aliases':
    ensure => present,
  }

  $textgridadmins = hiera_hash('textgridadmins')
  $admin_defaults = {
    'groups' => ['sudo', 'textgridadmins'],
  }

  create_resources(textgrid::users_addadmin, $textgridadmins, $admin_defaults)

  # add passwordless sudoers (cmp. with cendari server puppet)
  group { 'textgridadmins':
    ensure => present,
    gid    => 900,
  }

  augeas { 'textgridsudonopass':
    context => '/files/etc/sudoers',
    changes => [
        # allow group cendariadmins to use sudo without password
        'set spec[user = "%textgridadmins"]/user %textgridadmins',
        'set spec[user = "%textgridadmins"]/host_group/host ALL',
        'set spec[user = "%textgridadmins"]/host_group/command ALL',
        'set spec[user = "%textgridadmins"]/host_group/command/runas_user ALL',
        'set spec[user = "%textgridadmins"]/host_group/command/tag NOPASSWD',
    ]
  }



  # we want to use custom facts (TODO: is there an existing puppet plugin?)
  file { '/etc/facter/':
    ensure => directory,
  }
  file { '/etc/facter/facts.d':
    ensure  => directory,
  }

  # cache for tgstaging
  # vagrant cachier changes this to symlink TODO: workaround
#  unless $textgrid_staging_dir_created {
  unless $vagrant {
    file { '/var/cache/textgrid/' :
      ensure => directory,
    }
#    file {'/etc/facter/facts.d/textgrid_staging_dir_created.txt':
#      content => "textgrid_staging_dir_created=true",
#    }
  }

}
