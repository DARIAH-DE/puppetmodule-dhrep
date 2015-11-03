# == Class: dhrep::static::textgridlab_org
#
# Class to install and configure the textgridlab.org static sites
#
class dhrep::static::textgridlab_org(
) {

  include dhrep::tgnginx

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin'],
  }

  #
  # Create folder
  #
  file { '/var/www/nginx-root/textgridlab.org':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  ->

  #
  # Clone metadata schemas
  #
  exec { 'git_clone_textgridlab_metadata':
    command => 'git clone git://git.projects.gwdg.de/textgrid-metadata.git /var/www/nginx-root/textgridlab.org/schema',
    creates => '/var/www/nginx-root/textgridlab.org/schema',
    require => Package['git'],
  }

}
