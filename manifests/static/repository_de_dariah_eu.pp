# == Class: dhrep::static::repository_de_dariah_eu
#
# Class to install and configure the dariahr epository static sites.
#
class dhrep::static::repository_de_dariah_eu(
) {

  include dhrep::nginx

  Exec {
    path => ['/usr/bin','/bin','/usr/sbin'],
  }

  #
  # DARIAH-DE Repository Documentation (common index file and folder)
  #
  file { '/var/www/nginx-root/doc':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
#
# TODO Make index file for repository later.
#
#  file { '/var/www/nginx-root/doc/index.html':
#    source  => 'puppet:///modules/dhrep/var/www/nginx-root/doc/index.html',
#    mode    => '0644',
#    require => File['/var/www/nginx-root/doc'],
# }

  #
  # TextGridRep API Documentation DEB package (Sphinx-based)
  #
  package { 'dariah-de-doc':
    ensure  => latest,
    require => Exec['update_dariah_apt_repository'],
  }
  -> file { '/var/www/nginx-root/doc/services':
    ensure => link,
    target => '/var/www/doc/services',
  }
}
