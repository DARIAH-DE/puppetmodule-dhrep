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
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/nginx-root'],
  }

  #
  # index.html file for repository
  #
  file { '/var/www/nginx-root/index.html':
#    source  => 'puppet:///modules/dhrep/var/www/nginx-root/dariah/index.html',
    ensure  => file,
    mode    => '0644',
    require => File['/var/www/nginx-root'],
    content => template('dhrep/var/www/nginx-root/dariah/index.html'),
  }

  #
  # DARIAH-DE API Documentation DEB package (Sphinx-based)
  #
  package { 'dariah-de-doc':
    ensure  => latest,
    require => Exec['update_dariah_apt_repository'],
  }
  -> file { '/var/www/nginx-root/doc/services':
    ensure  => link,
    target  => '/var/www/doc/services',
    require => File['/var/www/nginx-root/doc'],
  }

  #
  # BagIt Profile folders and profile itself
  #
  file { '/var/www/nginx-root/schemas':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/nginx-root'],
  }
  file { '/var/www/nginx-root/schemas/bagit':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/nginx-root/schemas'],
  }
  file { '/var/www/nginx-root/schemas/bagit/profiles':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/nginx-root/schemas/bagit'],
  }
  file { '/var/www/nginx-root/schemas/bagit/profiles/dhrep_0.1.json':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dhrep/var/www/nginx-root/dariah/schemas/bagit/profiles/dhrep_0.1.json.erb'),
  }
}
