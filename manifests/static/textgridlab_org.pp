# == Class: dhrep::static::textgridlab_org
#
# Class to install and configure the textgridlab.org static sites.
#
class dhrep::static::textgridlab_org(
) {

  include dhrep::nginx

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

  #
  # Clone metadata schemas from GIT and copy tp car/www/
  #
  # TODO Get files from a certain 1.0 tag!
  # TODO Cloning does not yield automatic updates via pull!!
  #
  -> exec { 'git_clone_textgrid_metadata':
    command => 'git clone https://gitlab.gwdg.de/dariah-de/textgridrep/textgrid-metadata.git /usr/local/src/textgrid-metadata-git',
    creates => '/usr/local/src/textgrid-metadata-git',
    require => Package['git'],
  }
  -> file { '/var/www/nginx-root/textgridlab.org/schema':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/rdf.xsd':
    source  => 'file:///usr/local/src/textgrid-metadata-git/rdf.xsd',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/textgrid-metadata_2010.xsd':
    source  => 'file:///usr/local/src/textgrid-metadata-git/textgrid-metadata_2010.xsd',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/textgrid-metadata-agent_2010.xsd':
    source  => 'file:///usr/local/src/textgrid-metadata-git/textgrid-metadata-agent_2010.xsd',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/textgrid-metadata-language_v2_2010.xsd':
    source  => 'file:///usr/local/src/textgrid-metadata-git/textgrid-metadata-language_v2_2010.xsd',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/textgrid-metadata-script_2010.xsd':
    source  => 'file:///usr/local/src/textgrid-metadata-git/textgrid-metadata-script_2010.xsd',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/textgrid-metadata-genre_2015.xml':
    source  => 'file:///usr/local/src/textgrid-metadata-git/textgrid-metadata-genre_2015.xml',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }
  file { '/var/www/nginx-root/textgridlab.org/schema/textgrid-metadata-genre_2015.xsl':
    source  => 'file:///usr/local/src/textgrid-metadata-git/textgrid-metadata-genre_2015.xsl',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/schema'],
  }

  #
  # TextGridRep Documentation (common index file and folder)
  #
  file { '/var/www/nginx-root/textgridlab.org/doc':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }
  file { '/var/www/nginx-root/textgridlab.org/doc/index.html':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/doc/index.html',
    mode    => '0644',
    require => File['/var/www/nginx-root/textgridlab.org/doc'],
  }

  #
  # TextGridRep API Documentation DEB package (Sphinx-based)
  #
  package { 'textgrid-doc':
    ensure  => latest,
    require => Exec['update_dariah_apt_repository'],
  }
  -> file { '/var/www/nginx-root/textgridlab.org/doc/services':
    ensure => link,
    target => '/var/www/doc/services',
  }

  #
  # TODO Automated Puppet documentation!
  #

  #
  # HTML files: index.html, favicon.ico, jira.html, error sites, robots.txt and images
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
  file { '/var/www/nginx-root/textgridlab.org/robots.txt':
    source  => 'puppet:///modules/dhrep/var/www/nginx-root/textgridlab.org/robots.txt',
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
  $repstatus_target='/var/www/nginx-root/textgridlab.org';
  file { '/opt/dhrep/update-textgridrep-status.sh':
    content => template('dhrep/opt/dhrep/update-textgridrep-status.sh.erb'),
    mode    => '0755',
    require => File[$repstatus_target],
  }
  # run every two minutes
  -> cron { 'update-textgridrep-status' :
    command => '/opt/dhrep/update-textgridrep-status.sh > /dev/null 2>&1',
    user    => 'root',
    minute  => '*/2',
  }


  #
  # Update site: put into netapp right now, so no StorNext mount is needed anymore!
  #
  file { '/var/www/nginx-root/textgridlab.org/updates':
    ensure => link,
    target => '/media/netapp/www/tglab/updates',
  }

  #
  # TG-lab download files: put into netapp right now, so no StorNext mount is needed anymore!
  #
  file { '/var/www/nginx-root/textgridlab.org/download':
    ensure => link,
    target => '/media/netapp/www/tglab/download',
  }
}
