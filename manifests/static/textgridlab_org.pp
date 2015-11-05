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
  # Create textgridlab.org folder in /var/www
  #
  file { '/var/www/nginx-root/textgridlab.org':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  ->

  #
  # Clone metadata schemas from git (TODO get files from a certain 1.0 tag?)
  #
  exec { 'git_clone_textgridlab_metadata':
    command => 'git clone git://git.projects.gwdg.de/textgrid-metadata.git /var/www/nginx-root/textgridlab.org/schema',
    creates => '/var/www/nginx-root/textgridlab.org/schema',
    require => Package['git'],
  }
  ->
  file { '/var/www/nginx-root/textgridlab.org/schema':
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  #
  # TODO Automated middleware and puppet documentation!
  #
  file { '/var/www/nginx-root/textgridlab.org/doc':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
  }
  file { '/var/www/nginx-root/textgridlab.org/doc/index.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/doc/index.html',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/doc'],
  }

  #
  # TODO Marketplace
  #

  #
  # HTML files: index.html, favicon.ico, jira.html, error sites, and images
  #
  file { '/var/www/nginx-root/textgridlab.org/index.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/index.html',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/favicon.ico':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/favicon.ico',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/jira.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/jira.html',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/404.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/404.html',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/50x.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/50x.html',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/img':
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/img/Buch-Eule.png':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/img/Buch-Eule.png',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/img'],
  }
  file { '/var/www/nginx-root/textgridlab.org/img/Drunk-Eule.png':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/img/Drunk-Eule.png',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/img'],
  }
  file { '/var/www/nginx-root/textgridlab.org/img/Release-Eule.png':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/img/Release-Eule.png',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/img'],
  }
  file { '/var/www/nginx-root/textgridlab.org/img/Schraub-Eule.png':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/img/Schraub-Eule.png',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/img'],
  }

  #
  # Repstatus
  #
  file { '/var/www/nginx-root/textgridlab.org/repstatus.html':
    source => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/repstatus.html',
    mode   => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }
  file { '/var/www/nginx-root/textgridlab.org/repstatus.css':
    source => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/repstatus.css',
    mode   => '0644',
    require => File['/var/www/nginx-root/textgridlab.org'],
  }

  #
  # TODO Update site
  #

  #
  # TODO TG-lab download files
  #

}
